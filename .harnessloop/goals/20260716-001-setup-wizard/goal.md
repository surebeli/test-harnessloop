# Goal

## Goal

为 harnessloop 插件实现 setup wizard 能力，消除审查报告 P1 #5/#6 描述的"init 后 12 个空模板无人认领"缺口：提供引导式 setup 流程、机械可检的 setup 完整度、以及 status/continue 对 setup-incomplete 状态的感知。

## Non-Goals

- 不改 intake 流程
- 不做 data-sources 的 repo 自动扫描（后续增强）
- 不重构 loop SKILL 全文（P1 #9 独立）
- 不重生成 mock-project（P1 #8 独立）
- 不改证据枚举（P1 #7 独立）

## Success Condition

用户在本项目亲自运行首次 wizard（live acceptance）五步可走通；check_setup 机械检测在骨架项目返回 incomplete、在本项目（已填）返回 complete；npm run validate 全绿含新增 wizard 断言；Python 3.9 兼容。

## Acceptance Criteria

| Criterion | Evidence required | Verification method | Human confirmation required |
| --- | --- | --- | --- |
| 新 skill harnessloop-setup 存在且通过 claude plugin validate --strict | skill 目录 + SKILL.md | claude plugin validate --strict | 否 |
| 五步流程：环境自动检测→data-sources 引导→cost-context-policy 确认→control-contract 档位选择（lite/standard/strict 预设）→self-check 汇总+完成度 N/5 报告 | wizard 脚本/dry-run transcript | transcript 走查 | 否 |
| 每步可跳过且跳过必记 TODO 到 self-check | self-check.md 内容 | 检查跳过步骤是否留下 TODO 标记 | 否 |
| check_setup.py（或 verify_protocol 扩展）返回机器可读完整度 | 脚本输出 | 分别在骨架项目与本项目运行并对比结果 | 否 |
| status 输出 setup-incomplete 状态与"缺什么/下一步" | status 命令输出 | 在骨架项目上运行 status | 否 |
| continue 门对 setup-incomplete 返回 needs-setup | continue 命令输出 | 在骨架项目上运行 continue | 否 |
| init 交接语指向 setup wizard | init SKILL.md 文本 | grep 交接语内容 | 否 |
| loop SKILL "Project Setup" 节触发条件（现 :69 "If .harnessloop/ does not exist..."）与 :114 填表指令均修正为感知 setup 完整度（gate_blocking） | loop SKILL.md 文本 diff | diff/grep 对比修改前后文本 | 否 |

## Required Human Decisions

- 档位预设默认值内容（lite/standard/strict）在验收时确认
- live acceptance 运行（用户亲自执行首次 wizard）
- thresholds.md 与 setup/data-sources.md 中"npm run validate 7/7"表述随 validate 增至 8 阶段的更新，属验证阈值变更，待用户确认（见 round 0002 复审 S4/decision.md）

## Source Of Truth

| Document or system | Path or URL | Trust level | Last verified |
| --- | --- | --- | --- |
| 需求依据 | docs/harnessloop-review-20260716.findings.json 中 guided-setup/auto-detection lens 的 CONFIRMED 条目 | 权威（需求冻结基线，2026-07-16） | 2026-07-16 |
| 格式权威 | harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ 模板目录 | 权威 | 2026-07-16（submodule HEAD 66093fd） |

## Status

**achieved（2026-07-17）**

Goal 全生命周期四轮完成：round 0001 design 首次对抗评审 negative → round 0002 design-v2 复审 positive → round 0003 implement 首次对抗评审 negative→minimal-fix→positive → round 0004 S4 live acceptance positive。8 条 acceptance criteria 全部落位、Success Condition 三项全部达成（详见 rounds/0004/decision.md）。

Required Human Decisions 三项解决方式逐条记录：

1. **档位预设默认值内容（lite/standard/strict）**——用户 2026-07-17 明确"保持默认"：round 0003 交付的 `control-contract-profiles.md` 三档预设内容无需改动，直接确认为最终版本。
2. **live acceptance 运行（用户亲自执行首次 wizard）**——用户 2026-07-16 亲自完成：`/reload-plugins` 热加载插件后（无需重启会话）运行 `$harnessloop-setup`，审阅模式正确识别既有完成度 4/5、仅追问缺失类别（External Tools），用户选择记录 GitHub 条目；`check_setup.py` 复核本项目达成 complete=true（5/5），exit 0。
3. **thresholds.md 与 setup/data-sources.md 中"npm run validate 7/7"随 validate 增至 8 阶段的表述更新**——用户已确认更新，已按 round 0004 scope-lock v2 授权落盘至两处文件（均标注 user-confirmed 2026-07-16）。

三项均已解决，无遗留 Required Human Decisions。goal 归档，见 `.harnessloop/state/current.md`。
