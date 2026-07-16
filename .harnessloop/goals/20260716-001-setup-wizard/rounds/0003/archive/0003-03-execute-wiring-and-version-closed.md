# 0003-03-execute-wiring-and-version-closed

## Objective

完成 init/status/continue/loop 四个 SKILL.md 的接线修改，并同步版本 bump（package.json、marketplace.json、plugin.json、codex plugin.json 含 defaultPrompt）。

## Inputs

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/scope-lock.md
- Evidence paths: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/evidence/dynamic/setup-wizard-design-v2.md（§6 四处接线点方案、§8 版本 bump 方案，含 R2 三文件理由修正、R5 goal.md 行号勘误已在 goal.md 执行）；harnessloop/plugins/harnessloop/skills/{harnessloop-init,harnessloop-status,harnessloop-continue,harnessloop-loop}/SKILL.md（既有文本，只读参照）；git show 5c35a22（先例，0001 轮已核实）
- External tools: 无
- Credential names only: 无
- Local parameter references: 无
- Expected model/effort: claude-sonnet-5

## Scope Boundaries

Allowed:

- 修改 harnessloop/plugins/harnessloop/skills/harnessloop-init/SKILL.md
- 修改 harnessloop/plugins/harnessloop/skills/harnessloop-status/SKILL.md
- 修改 harnessloop/plugins/harnessloop/skills/harnessloop-continue/SKILL.md
- 修改 harnessloop/plugins/harnessloop/skills/harnessloop-loop/SKILL.md
- 修改 harnessloop/package.json、harnessloop/.claude-plugin/marketplace.json、harnessloop/plugins/harnessloop/.claude-plugin/plugin.json、harnessloop/plugins/harnessloop/.codex-plugin/plugin.json
- 只读 rounds/0002/evidence/dynamic/setup-wizard-design-v2.md、rounds/0002/decision.md、rounds/0002/reviews/adversarial-review.md

Disallowed:

- 修改上表之外的任何文件（含 0003-01/0003-02 负责的新文件，除非仅为新增引用行）
- 写入 rounds/0003/ 目录之外的项目文件
- harnessloop/plugins/harnessloop/examples/mock-project/、证据枚举相关文件

## Tool And Access Contract

| Tool/system | Purpose | Read/write scope | Account role | Credential name | Local parameter references | Verification method | Failure handling |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 本地文件系统 | 读取设计稿/既有 SKILL.md/版本文件，修改四处接线 + 版本号 | 只读（设计稿/评审）+ 写（既有文件修改） | 无 | 无 | 无 | grep/diff 对比修改前后文本；npm run validate；实现级对抗评审 | 无法写入或验证失败时报告并停止 |

Do not include secret values. Use local parameter keys or provider references only.

## Budget And Context Limits

- Max input scope: setup-wizard-design-v2.md §6/§8 全节 + 四个既有 SKILL.md 全文 + 四个版本文件现有内容 + git show 5c35a22
- Max output length: TODO (owner: user)
- Raw logs allowed in output: no
- Evidence paths required: yes

## Required Work

按 design-v2 §6.1 修改 init:90（交接语指向 setup wizard）与 :35（已获批准的语义重复修正）；按 §6.2 修改 status（setup-incomplete 状态、todo_count/next-step 字段、`-B` 零写入 Safety Rule 补丁）；按 §6.3 修改 continue（`gate_blocking` 短路条件、Safety Rule 双向表述，采用 R2 修正后的三文件理由文本——self-check.md 不纳入阻断集合的正确理由是"S5 输出记录 + TODO 认领台账"而非"非任何门的输入"；cost-context-policy.md 表述为"经 `$harnessloop-delegation` 读取"而非"直接读取"）；按 §6.4 修改 loop（:69/:114 触发条件修正为感知 setup 完整度/gate_blocking，与 goal.md 更新后的 AC8 一致；新增 profiles 引用行指向 control-contract-profiles.md）。按 §8 完成四文件版本 bump（对齐 5c35a22 先例：3 处 0.7.0→0.8.0 式的同步 + marketplace.json 独立起点 + codex defaultPrompt 追加技能名，本次目标版本号已获批准为 0.11.0）。

## Required Outputs

- harnessloop/plugins/harnessloop/skills/harnessloop-init/SKILL.md（修改后）
- harnessloop/plugins/harnessloop/skills/harnessloop-status/SKILL.md（修改后）
- harnessloop/plugins/harnessloop/skills/harnessloop-continue/SKILL.md（修改后）
- harnessloop/plugins/harnessloop/skills/harnessloop-loop/SKILL.md（修改后）
- harnessloop/package.json、harnessloop/.claude-plugin/marketplace.json、harnessloop/plugins/harnessloop/.claude-plugin/plugin.json、harnessloop/plugins/harnessloop/.codex-plugin/plugin.json（版本 bump 后）

## Verification Condition

四处接线文本 diff 与 design-v2（+R2 修正）逐项对应；四个版本文件同步 bump 至 0.11.0 且 codex defaultPrompt 含新 skill 名；`npm run validate` 不因接线改动新增失败；由 0003-04 实现级对抗评审最终核实。

## Closeout Summary

Status: closed
Evidence produced: harnessloop/plugins/harnessloop/skills/{harnessloop-init,harnessloop-status,harnessloop-continue,harnessloop-loop}/SKILL.md（四处接线修改完成）；harnessloop/package.json、harnessloop/.claude-plugin/marketplace.json、harnessloop/plugins/harnessloop/.claude-plugin/plugin.json、harnessloop/plugins/harnessloop/.codex-plugin/plugin.json（四文件同步版本 bump 至 0.11.0，含 codex defaultPrompt 追加新 skill 名）；status/continue 接线正确采用 todo 双字段术语（`field_todo_count`/`selfcheck_todo_count`），经主会话集成走查先行确认与本轮已批准的规格偏离一致
Open risks: 独立实现级对抗评审（0003-04，rounds/0003/reviews/adversarial-review.md）首次判定 negative，其中必修项 M-C（新技能家族配套缺口——`agents/openai.yaml` 与三处文档技能清单，scope-lock 规划遗漏）在 scope-lock 升级至 v2（主会话按 control-contract scope-lock mutation 条款自主扩围，版本递增留痕）后，于本 handoff 范围内补齐 `harnessloop-setup/agents/openai.yaml` 与 README.md/docs/usage.md/docs/harnessloop-framework.md 三处技能清单行；修复后经主会话走查复核确认到位，未再开新评审轮
Next handoff: 0003-04-review-adversarial-implementation-open（同轮，实现级对抗评审，依赖本 handoff 产出）
Observed model/effort: claude-sonnet-5（按委派参数指定，无独立运行时探针核实实际使用模型，见 state/environment.md 局限）
