# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0002
- Issue class: skill-gap
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-sonnet-5 subagent (P0 fix group A, orchestrated by claude-fable-5)
- Created at: 2026-07-16

## Redaction Boundary

- Secrets removed: n/a (无涉密内容)
- Private data removed: n/a
- Raw logs omitted: n/a
- Safe evidence summaries only: yes

## Context

- Active goal path: 无（框架级审查修复任务，未绑定项目内 goal）
- Active round path: 无
- State files: 未涉及本项目 `.harnessloop/state/`
- Related handoffs: 无
- Related evidence: 全仓 `grep -rn verify_protocol plugins/harnessloop/skills/*/SKILL.md` 审查前 0 命中；`docs/cost-model.md:89` 把 `verify_protocol.py flags a scope violation` 列为运行期 gate 拦截事件
- Related reviews: 外部审查 P0 组 A 的 3 条独立发现（同一问题，不同 lens：protocol-consistency、enforcement-gap、skill-ux），均判定 CONFIRMED

## Expected Harnessloop Behavior

插件的核心卖点之一是"代码保证协议下限"：`verify_protocol.py` 对 scope-lock 越界（Rule A）与悬空引用（Rule B）做机械校验，支持 `--project <any-project>` 且违规时非零退出。协议文档（`docs/cost-model.md:88-91`）承诺把它列为运行期 payout 记账来源之一，隐含前提是该脚本会在真实项目的 loop 中被调用。

## Actual Harnessloop Behavior

`harnessloop-loop/SKILL.md` 的"Loop Continuation"七步（修复前 481-491 行）与 `harnessloop-continue/SKILL.md` 的 Processing Contract 十一步中，均无一步运行 `verify_protocol.py`。插件 `plugin.json` 只声明 `skills`，无 hooks/commands，不存在任何自动调用路径。脚本唯一的实际执行场景是框架仓库自身 `scripts/validate.py` 对 `examples/mock-project` 的 CI 检查——安装到真实项目后，机械下限在实战场景中强制力为 0，round 验收完全回退到 LLM 自觉，而 `docs/cost-model.md:89` 描述的 payout 记账在结构上永远不会产生数据。

## Minimal Reproduction From Files

1. Read: `plugins/harnessloop/skills/harnessloop-loop/SKILL.md`（修复前 481-491 行，Loop Continuation）与 `plugins/harnessloop/skills/harnessloop-continue/SKILL.md`（Processing Contract 11 步）
2. Observe: 两处均只驱动 `round_cost.py` 或 LLM 判断步骤，无 `verify_protocol.py` 调用；`grep -rn verify_protocol plugins/harnessloop/skills/*/SKILL.md` 命中 0
3. Expected next protocol action: round 结束前机械门先跑一次，非零退出即阻断 positive 判定
4. Actual next protocol action: round 直接进入 `decision.md` 写入与 positive/negative 分类，机械门从未参与

## Attempted Local Mitigation

- Evidence refresh: n/a（框架级缺口，非项目内证据问题）
- Scope narrowing: n/a
- Contract revision: n/a
- Handoff change: n/a
- Rollback: n/a
- Human confirmation: 无需（依据审查发现的既定 suggestion 做最小接线修复）

## Suggested Upstream Improvement

- Candidate target: main skill（harnessloop-loop、harnessloop-continue 两份 SKILL.md）
- Proposed smallest change: 在 `harnessloop-loop/SKILL.md` "Loop Continuation" 第 1 步前插入机械门调用（非零退出不得标记 positive，写入 `decision.md` 并按 `contract-insufficient` 处理）；在 `harnessloop-continue/SKILL.md` Processing Contract 中加对应前置检查；在 "Verification Phase" 节说明机械门（machine-checkable rules）与模型判断门（adversarial review）的分工，明确机械 pass 不等于协议 pass
- Why this generalizes beyond this project: 任何安装该插件的项目都会遇到同一接线缺口，不是本项目特有问题
- Risks of overfitting: 低——修复只在既有的 skill-dir 占位符调用惯例上增加一行调用，不引入新脚本或新语义

## Resolution

- Resolution status: fixed（submodule 内已修）
- Upstream change: `harnessloop/plugins/harnessloop/skills/harnessloop-loop/SKILL.md`（"Verification Phase" 新增机械门/模型判断门分工说明；"Loop Continuation" 步骤 1 新增机械门调用，原 1-7 步顺延为 2-8 步）、`harnessloop/plugins/harnessloop/skills/harnessloop-continue/SKILL.md`（Processing Contract 新增步骤 2：positive 判定前确认或运行 `verify_protocol.py`，原 2-11 步顺延为 3-12 步）
- Backported to local policy: yes
- Backport path: harnessloop（submodule，未 commit，等待上游/主会话统一处理）
- Follow-up required: 上游发布时运行 `npm run validate` 确认 7 阶段仍全绿；后续可考虑随插件发布 Stop/PostToolUse hook 示例作为更强保障（本次只做 S 量级的 SKILL.md 接线修复）
