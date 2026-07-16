# Scope Lock

Version: v2

Change Log:

- 2026-07-16 — v1 → v2：主会话按 control-contract.md「Scope-lock mutation: main session 自主（版本递增留痕）」条款自主扩围。原因：实现级对抗评审（rounds/0003/reviews/adversarial-review.md :58/:107，Finding M-C）判定新技能家族配套（agents/openai.yaml + 三处文档技能清单）属 scope-lock 规划遗漏，非实现违规。授权来源：control-contract.md scope-lock mutation 条款 + rounds/0003/reviews/adversarial-review.md M-C。

## Round Objective

按 design-v2（rounds/0002/evidence/dynamic/setup-wizard-design-v2.md，含 R1-R4 修正，见 rounds/0002/decision.md 裁决 (c) 与 rounds/0002/reviews/adversarial-review.md Finding 五）在 harnessloop submodule 中实现 setup wizard 能力的全部交付物。

## Allowed Changes

| Path/data/tool | Allowed action | Limit |
| --- | --- | --- |
| harnessloop/plugins/harnessloop/skills/harnessloop-setup/SKILL.md | 新建 | 五步向导全文 |
| harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py | 新建 | 机器可读完整度检测脚本 |
| harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md | 新建 | lite/standard/strict 三档预设全文 |
| harnessloop/plugins/harnessloop/skills/harnessloop-init/SKILL.md | 修改 | 交接语接线（指向 setup wizard） |
| harnessloop/plugins/harnessloop/skills/harnessloop-status/SKILL.md | 修改 | setup-incomplete 状态与缺口/下一步呈现接线 |
| harnessloop/plugins/harnessloop/skills/harnessloop-continue/SKILL.md | 修改 | setup gate（needs-setup 短路）接线 |
| harnessloop/plugins/harnessloop/skills/harnessloop-loop/SKILL.md | 修改 | :69/:114 触发条件修正 + profiles 引用行 |
| harnessloop/scripts/validate.py | 修改 | 新增 wizard/check_setup 相关验证阶段，[N/7]→[N/8] 重编号 |
| harnessloop/package.json | 修改 | 版本 bump |
| harnessloop/.claude-plugin/marketplace.json | 修改 | 版本 bump |
| harnessloop/plugins/harnessloop/.claude-plugin/plugin.json | 修改 | 版本 bump |
| harnessloop/plugins/harnessloop/.codex-plugin/plugin.json | 修改 | 版本 bump + defaultPrompt 同步 |
| .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/ | 写 | 本轮协议文件（handoffs/evidence/reviews） |
| harnessloop/plugins/harnessloop/skills/harnessloop-setup/agents/openai.yaml | 新建 | v2 追加（M-C）：对照 secrets/status 先例格式 |
| harnessloop/README.md | 修改 | v2 追加（M-C）：仅 Skills 清单行，追加 `$harnessloop-setup` 条目 |
| harnessloop/docs/usage.md | 修改 | v2 追加（M-C）：仅技能清单行（:21），追加 `$harnessloop-setup` 条目 |
| harnessloop/docs/harnessloop-framework.md | 修改 | v2 追加（M-C）：仅技能清单行，追加 `$harnessloop-setup` 条目 |

## Disallowed Changes

- harnessloop/plugins/harnessloop/examples/mock-project/ 任何文件
- 证据枚举相关文件（P1 #7，独立范围，见 goal.md Non-Goals）
- 上表之外的 harnessloop/ submodule 任何文件
- rounds/0003/ 目录之外的项目文件（轮次收盘时的 state/goal 更新除外）

## One-Variable Strict Mode

- Enabled: no
- Variable: 不适用
- Reason: 实现轮涉及多个协同交付物（新 skill、新脚本、四处接线、版本号同步），非单变量隔离验证场景；各交付物的正确性由下方 Verification Commands 分别机械核验，实现级对抗评审（0003-04）再做整体一致性核对

## Verification Commands Or Checks

| Check | Command or method | Expected result | Evidence path |
| --- | --- | --- | --- |
| npm run validate | cd harnessloop && npm run validate | 8/8 全绿 | validate 输出 |
| 机械协议门 | python3 /Users/litianyi/.claude/plugins/cache/harnessloop/harnessloop/0.10.0/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop | exit 0 | 脚本输出 |
| check_setup（fresh-init fixture） | 对 fresh-init fixture 运行 check_setup.py | gate_blocking=true | check_setup 输出 |
| check_setup（本项目） | 对本项目运行 check_setup.py | partial 且 gate_blocking=false | check_setup 输出 |
| Python 3.9 兼容性 | python3 3.9.4（pyenv）实测运行新增代码 | 无异常，exit 0 | 命令输出 |

## Runtime Recovery Limits

- Recovery round: no
- Blocker type: 不适用
- Allowed observation targets: 不适用
- Disallowed triggers or writes: 不适用
- Cleanup/write confirmation required before: 不适用

## Rollback Condition

`git -C harnessloop checkout` 撤销本轮未提交改动。

## Human Confirmation Required

无（本轮改动限于 harnessloop submodule 本地工作树；提交与推送遵循 control-contract.md 既定授权流程——批次验收通过后可 push 到 surebeli/harnessloop，无需逐次确认）。若实现级对抗评审（0003-04）结论为 negative，按 feedback-policy.md 走 minimal-fix/回滚路径，不自动升级为需用户。
