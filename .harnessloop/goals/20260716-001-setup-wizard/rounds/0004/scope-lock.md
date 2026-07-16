# Scope Lock

Version: v2

Change Log:

- 2026-07-16 — v1 → v2：主会话按 control-contract.md「Scope-lock mutation: main session 自主（版本递增留痕）」条款自主扩围。原因：用户已在本轮 wizard live 首跑中确认"npm run validate 7/7→8/8"验证阈值表述修订（thresholds.md 仅验证阈值表述行），该修订属本轮执行范围，纳入 Allowed Changes 以完成落盘。授权来源：control-contract.md scope-lock mutation 条款 + 用户 2026-07-16 确认。

## Round Objective

S4 live acceptance：用户在本项目亲自首跑 setup wizard 五步（环境自动检测→data-sources 引导→cost-context-policy 确认→control-contract 档位选择→self-check 汇总+完成度 N/5 报告），wizard 运行期间为 `.harnessloop/setup/data-sources.md` 补齐 none 哨兵与既有缺口条目，走完后由 `check_setup.py` 机械复核本项目返回 `complete=true`。本轮不做实现改动，仅验收 round 0003 交付的 wizard 能力在真实项目上的端到端可用性（见 rounds/0003/round-summary.md Next Proposed Scope、goal.md Required Human Decisions）。

## Allowed Changes

| Path/data/tool | Allowed action | Limit |
| --- | --- | --- |
| .harnessloop/setup/data-sources.md | 修改（wizard 运行时写入） | 仅 wizard data-sources 引导步骤补齐 none 哨兵与缺口条目，遵循既有表格结构，不改变本 goal 既定的需求依据/格式权威等既有条目内容 |
| .harnessloop/setup/cost-context-policy.md | 修改（wizard 运行时写入） | 仅 wizard cost-context-policy 确认步骤补齐/确认既有 TODO 项 |
| .harnessloop/state/environment.md | 修改（wizard 运行时写入） | 仅 wizard 环境自动检测步骤更新检测结果 |
| .harnessloop/state/control-contract.md | 修改（wizard 运行时写入） | 仅 wizard control-contract 档位选择步骤按所选 lite/standard/strict 预设写入（预设内容取自 control-contract-profiles.md） |
| .harnessloop/state/self-check.md | 修改（wizard 运行时写入） | 仅 wizard self-check 汇总步骤写入完成度 N/5 报告与跳过步骤的 TODO 认领标记 |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0004/ | 写 | 本轮协议文件（handoffs/evidence/reviews；scope-lock 自身版本迭代） |
| .harnessloop/goals/20260716-001-setup-wizard/thresholds.md | 修改 | v2 追加：仅验证阈值表述行（"npm run validate 7/7"→"npm run validate 全部阶段全绿（当前 8 阶段）"），user-confirmed 2026-07-16，不得触及本文件其他内容 |

这五个文件是 wizard 五步流程按设计各自管辖并在 wizard 运行时合法写入的落点（design-v2 §2/§3/§5；rounds/0003 交付的 `harnessloop-setup/SKILL.md` 五步分别对应这五个文件）。

## Disallowed Changes

- harnessloop/ submodule 任何文件（本轮为验收轮，不做实现改动；实现改动已在 round 0003 完成）
- 上表五个 wizard 管辖文件与 rounds/0004/ 目录之外的任何项目文件（轮次收盘时的 state/goal 更新除外，如 state/current.md、meta/self-audit.md、state/evidence-index.md 的收盘态更新）
- goal.md、thresholds.md、data-contract.md、feedback-policy.md、goal-breakdown.md 的内容性改动（三档默认值最终措辞与"7/7→8/8"阈值表述更新属 Required Human Decisions，需用户确认后另行走轮次收盘更新流程，非本轮 wizard 运行期间的写入范围）
- rounds/0001/、rounds/0002/、rounds/0003/ 内任何文件（保留审计链，不得回改）

## One-Variable Strict Mode

- Enabled: no
- Variable: 不适用
- Reason: 本轮验收目标本身即为多步骤端到端走通（五步交互流 + none 哨兵补齐 + check_setup 复核），非单变量隔离验证场景；各子目标分别由下方 Verification Commands 机械核验，用户 live 确认覆盖整体一致性

## Verification Commands Or Checks

| Check | Command or method | Expected result | Evidence path |
| --- | --- | --- | --- |
| wizard 五步人工首跑 | 用户重启会话，运行 `$harnessloop-setup` | 五步全部完成无中断，用户确认通过 | 用户确认记录（human-confirmation）；若产出 transcript 则一并归档至 rounds/0004/evidence/dynamic/ |
| check_setup 机械复核 | `python3 <plugin-cache>/harnessloop/harnessloop/<version>/skills/harnessloop-loop/scripts/check_setup.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop --json`（当前已知 cache 版本 0.10.0；若 wizard 首跑前完成插件重装至本轮验收对应版本，路径版本段随之更新，见 setup/data-sources.md submodule HEAD 记录） | JSON 输出 `complete: true` | check_setup 输出 |
| 机械协议门 | `python3 <plugin-cache>/harnessloop/harnessloop/<version>/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop` | exit 0（TH-0008 相关误报按既有 `verify:ignore` 豁免规则处理，不阻断） | 脚本输出 |

## Runtime Recovery Limits

- Recovery round: no
- Blocker type: 不适用
- Allowed observation targets: 不适用
- Disallowed triggers or writes: 不适用
- Cleanup/write confirmation required before: 不适用

## Rollback Condition

`git checkout -- .harnessloop` 撤销本轮未提交改动（wizard 写入五文件的改动若需撤回，走此路径；harnessloop/ submodule 本轮未涉及改动，无需回滚）。

## Human Confirmation Required

是——本轮核心动作（wizard 五步首跑本身、三档预设默认值最终措辞确认、"7/7→8/8"阈值表述更新确认）均为 goal.md Required Human Decisions，须用户亲自执行/确认，主会话不可代为完成或自主判定通过（见 rounds/0003/decision.md Next Action：Human confirmation required = yes）。
