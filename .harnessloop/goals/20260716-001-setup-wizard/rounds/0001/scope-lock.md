# Scope Lock

## Round Objective

产出 setup wizard 设计文档（S1）：含五步交互流（环境自动检测→data-sources 引导→cost-context-policy 确认→control-contract 档位选择→self-check 汇总+完成度 N/5 报告）、check_setup 机械检测规则、lite/standard/strict 档位预设内容、四处接线点（init/status/continue/loop）文本变更方案、validate 新断言清单。

## Allowed Changes

| Path/data/tool | Allowed action | Limit |
| --- | --- | --- |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/evidence/dynamic/setup-wizard-design.md | 写 | 仅本文件 |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/handoffs/ | 写 | 仅本轮 handoff 文件 |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/reviews/ | 写 | 仅本轮评审文件 |

## Disallowed Changes

- harnessloop/ submodule 任何文件
- .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/ 目录之外的任何文件（轮次收盘时的 state 更新除外）

## One-Variable Strict Mode

- Enabled: no
- Variable: 不适用（设计轮）
- Reason: 设计轮，非单变量隔离验证轮

## Verification Commands Or Checks

| Check | Command or method | Expected result | Evidence path |
| --- | --- | --- | --- |
| 机械协议门 | python3 /Users/litianyi/.claude/plugins/cache/harnessloop/harnessloop/0.10.0/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop | 退出 0 | 脚本输出 |
| 对抗性设计评审 | reviews/adversarial-review.md | 结论 positive/可接受 | rounds/0001/reviews/adversarial-review.md |

## Runtime Recovery Limits

- Recovery round: no
- Blocker type: 不适用
- Allowed observation targets: 不适用
- Disallowed triggers or writes: 不适用
- Cleanup/write confirmation required before: 不适用

## Rollback Condition

设计评审结论为 negative 且不可最小修复时，废弃本轮设计稿并重开本轮。

## Human Confirmation Required

无（本轮为只读设计产出 + 独立评审，不涉及不可逆写入或外部系统变更）。
