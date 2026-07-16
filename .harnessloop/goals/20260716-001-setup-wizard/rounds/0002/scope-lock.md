# Scope Lock

## Round Objective

按 rounds/0001/decision.md 确定的修复方向，修订 setup wizard 设计稿至可实现状态：M1（continue/loop 门双层方案——gate_blocking + self-check TODO 认领降级 + todo_count 显性呈现）、M2（cost-context-policy §4.3 判定算法补充小节容器路径作用域匹配规则）、M3（lite 档 Evidence contract revision 条款对齐 harnessloop-evidence SKILL:31/:49 硬约束），并采纳 rounds/0001/reviews/adversarial-review.md 中全部 10 项建议修复（S1-S10）。

## Allowed Changes

| Path/data/tool | Allowed action | Limit |
| --- | --- | --- |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/evidence/dynamic/setup-wizard-design-v2.md | 写 | 设计稿修订版，另存为新文件 |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/handoffs/ | 写 | 仅本轮 handoff 文件 |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/reviews/ | 写 | 仅本轮复审文件 |

## Disallowed Changes

- harnessloop/ submodule 任何文件
- .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/ 内任何文件（含原设计稿 setup-wizard-design.md，不得修改，保留审计链）
- .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/ 目录之外的任何文件（轮次收盘时的 state 更新除外）

## One-Variable Strict Mode

- Enabled: no
- Variable: 不适用
- Reason: 设计修订轮（非实现/隔离验证轮），与 round 0001 一致

## Verification Commands Or Checks

| Check | Command or method | Expected result | Evidence path |
| --- | --- | --- | --- |
| 对抗性复审 | rounds/0002/reviews/ 下复审报告（0002-02 产出） | positive | rounds/0002/reviews/ |
| 机械协议门 | python3 /Users/litianyi/.claude/plugins/cache/harnessloop/harnessloop/0.10.0/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop | 预期因 TH-0006 已记录在案的误报类别可能仍 exit=1；判定时豁免该等已归档的误报类别，不计入本轮 fail；verify_protocol.py 修复后需复跑确认 | 脚本输出；.harnessloop/meta/evolution-issues/0006-verify-protocol-pathish-false-positives.md |

## Runtime Recovery Limits

- Recovery round: no
- Blocker type: 不适用
- Allowed observation targets: 不适用
- Disallowed triggers or writes: 不适用
- Cleanup/write confirmation required before: 不适用

## Rollback Condition

复审结论再次为 negative，则升级为 human-decision-required，暂停本 goal 并等待用户介入（不再由主会话自主决定第三次修订方向）。

## Human Confirmation Required

无（本轮为设计修订 + 独立复审，不涉及不可逆写入或外部系统变更）。若复审再次 negative，按 Rollback Condition 升级需用户。
