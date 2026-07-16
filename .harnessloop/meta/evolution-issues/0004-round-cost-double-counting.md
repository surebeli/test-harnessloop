# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0004
- Issue class: validation-drift
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-fable-5 (background P0 fix group B)
- Created at: 2026-07-16

## Redaction Boundary

- Secrets removed: n/a (无涉密内容)
- Private data removed: 本机真实 transcript 中的 token 数值仅用作规模验证，未包含对话内容/文件路径以外的敏感信息
- Raw logs omitted: 仅保留聚合后的 token 统计数字，未粘贴任何 transcript 原始行
- Safe evidence summaries only: yes

## Context

- Active goal path: 无（本次为独立 P0 修复任务，非常规 goal/round 流程）
- Active round path: 无
- State files: plugins/harnessloop/skills/harnessloop-loop/scripts/round_cost.py（修复对象）、scripts/validate.py 第 6 阶段（回归测试扩展对象）
- Related handoffs: 两份独立对抗性审查（lens: scripts-correctness、docs-truthfulness）均标记 CONFIRMED，corrected_severity 定为 high
- Related evidence: 本机 6 个真实项目 transcript 目录实测复现；harnessloop 仓库自测脚本（scratchpad 临时 fixture + 真实 transcript 只读验证）

## Expected Harnessloop Behavior

`round_cost.py` 对同一 assistant message（同一 `message.id`）只应结算一次 usage，`## Cost` 输出的 token 数应等于该结算窗口内实际消耗的 token 数，供 round-summary.md 如实记录成本。

## Actual Harnessloop Behavior

`settle()`（round_cost.py 原 93-104 行）对每条 `type=assistant` 且带 `usage` 的 JSONL 记录无条件累加，从未读取 `message.id`。Claude Code 对同一条 assistant message 按 content block（thinking/tool_use/text）拆成多行 JSONL，每行重复携带同一份 message 级 usage（少数情况下前几行是流式部分值或全零占位值，真实值落在该 message 最后一行附近）。结果是同一 message 被计费 2-4 次：本机对多个真实项目 transcript 的实测显示 output token 虚高比例在 2.0x-4.14x 之间（对 test-harnessloop 自身某会话文件按 message.id 去重前后对比：output 273,987 vs 90,552，约 3.03x）。这直接击穿该脚本"成本结算"的唯一存在目的，并污染了已发布文档（docs/cost-model.md 的"14% of output tokens protocol-attributed (33 of 435 assistant turns)"实测数字，435 是记录数而非去重后的 turn 数）。

## Minimal Reproduction From Files

1. Read: plugins/harnessloop/skills/harnessloop-loop/scripts/round_cost.py（修复前版本，`git show HEAD~1` 或修复前 diff）第 93-104 行 `settle()`
2. Observe: 循环对每条 assistant+usage 记录直接 `totals["input"] += usage.get(...)`，无 `message.get("id")` 相关代码；同一 message.id 的多行会被计算 N 次（N = 该 message 的 content block 数）
3. Expected next protocol action: 对同一 `message.id` 的多行 usage 只计一次，跨结算窗口（marker 偏移落在同一 message 中间）时仍只计一次
4. Actual next protocol action: 每行独立累加，成本高估且随 message 被 content block 拆分得越碎（thinking + 多个 tool_use + text）而越严重；round_cost.py 本身是唯一被两次独立审查判定 severity=high 的实现类缺陷（其余高优先级发现多为协议接线/文档一致性问题）

## Attempted Local Mitigation

- Evidence refresh: 用本机 6 个真实项目的 `~/.claude/projects/*/*.jsonl` 只读复现比例（2.0x-4.14x），并用 test-harnessloop 自身会话文件做端到端修复前/后对比
- Scope narrowing: 仅修改 round_cost.py 的 `settle()` 及配套 marker 读写逻辑，未改动 render()/main() 的输出格式，未触碰 verify_protocol.py / channel_params.py（并行修复组的范围）
- Contract revision: 无（不涉及 goal/scope-lock）
- Handoff change: 无
- Rollback: 未回滚，已用 scratchpad 临时 fixture + 真实只读 transcript 双重验证后确认修复正确
- Human confirmation: 无需（有实测证据支撑的确定性修复）

## Suggested Upstream Improvement

- Candidate target: validation script（round_cost.py）+ scripts/validate.py 第 6 阶段合成 fixture
- Proposed smallest change: `settle()` 按 `message.id` 分组，组内 usage 取逐字段 element-wise max（而非任取一条或求和）；因为观察到的三种真实形态——(a) 完全相同的重复行，(b) 前置全零占位行 + 末尾真实值，(c) output_tokens 随流式增长的部分值——max 对三者都正确。跨结算窗口边界（本脚本常在自己所属的那条 assistant message 内部被调用，marker 偏移天然会落在该 message 中间）通过把"仍未见到后继不同 id"的 message 状态（pending_id/pending_usage/pending_attributed）写入 marker 延后到下次结算时才计费来解决——只有当观察到一个不同的后续 message.id 时，才认为上一个 message 已"关闭"并计费一次。marker schema 从 `files: {name: <int offset>}` 升级为 `files: {name: {offset, pending_id, pending_usage, pending_attributed}}`（version 2），同时保留对旧版纯 int marker 的向后兼容读取。
- Why this generalizes beyond this project: 任何读取 Claude Code transcript 做 usage/成本统计的脚本都会撞上同样的"一条 message 多行 JSONL"结构；这不是 harnessloop 特有的数据问题，而是 Claude Code 转录格式的通用行为，凡是按行而非按 message.id 聚合 usage 的实现都会重复计费
- Risks of overfitting: 低——message.id 分组 + 组内 max 是基于观测到的三种真实形态归纳出的通用规则，不依赖 harnessloop 自身的任何约定；唯一的行为取舍是"transcript 末尾仍处于 open 状态的 message 会被推迟到下次结算才计费"，这是有意的保守选择（宁可轻微低估尾部，不可再次系统性高估）

## Resolution

- Resolution status: fixed（本项目 submodule 内已修：plugins/harnessloop/skills/harnessloop-loop/scripts/round_cost.py 重写 `settle()` 及配套 `_read_usage`/`_merge_usage_max`/`_mentions_harnessloop`/`_load_file_state` 辅助函数；scripts/validate.py 第 6 阶段合成 fixture 新增同 id 多行 usage 场景，含跨结算窗口断言）
- Upstream change: 待 push 到 surebeli/harnessloop（submodule commit 见 git log，本次任务未提交，由主会话统一处理）
- Backported to local policy: yes
- Backport path: harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/round_cost.py；harnessloop/scripts/validate.py（`validate_round_cost_smoke()`，仅该函数）
- Follow-up required: 上游发布前需在真实项目上多轮验证 pending 延后计费不会在长期运行中系统性漏记（例如项目长期不再有新 assistant message 的极端情况下，最后一条 message 的 usage 会一直停留在 marker 的 pending 字段中未计费，属已知、可接受的保守权衡，但值得在 docs/cost-model.md 中补一句说明）
