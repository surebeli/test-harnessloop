# Goal Breakdown

## Long-Term Goal

为 harnessloop 插件实现 setup wizard 能力，消除审查报告 P1 #5/#6 描述的"init 后 12 个空模板无人认领"缺口：提供引导式 setup 流程、机械可检的 setup 完整度、以及 status/continue 对 setup-incomplete 状态的感知（详见 goal.md）。

## Read-Only Discovery Plan

Use subagent or swarm handoffs for independent read-only investigation.

Discovery questions:

- Current system state: TODO (owner: user)
- Relevant data and tools: references/ 模板目录、docs/harnessloop-review-20260716.findings.json 中 guided-setup/auto-detection lens 的 CONFIRMED 条目（见 goal.md Source of Truth）
- Runtime validation options: npm run validate、check_setup 机械检测、claude plugin validate --strict（见 thresholds.md）
- Constraints and risks: 设计与协议硬原则冲突（不得虚构事实）；Python 3.9.4（pyenv）兼容性下限
- Prior work or known failures: TODO (owner: user)

## Discovery Handoffs

| Handoff | Purpose | Inputs | Output path | Status |
| --- | --- | --- | --- | --- |

## Subgoals

| ID | Subgoal | Depends on | Evidence required | Validation method | Risk |
| --- | --- | --- | --- | --- | --- |
| S1 | design（round 0001）：wizard 交互流设计文档 + check_setup 检测规则设计 + 接线点清单 | 无 | design doc + 对抗性设计评审 | 评审通过 | 设计与协议硬原则冲突（不得虚构事实） |
| S2 | implement（round 0002）：harnessloop-setup skill + check_setup.py + 档位模板 | S1 | TODO (owner: user) | validate 新断言 + 3.9 兼容 | TODO (owner: user) |
| S3 | wire（round 0003，可与 S2 合并由主会话定）：status/continue/init/loop 四处接线 | S2 | TODO (owner: user) | grep + validate | TODO (owner: user) |
| S4 | acceptance（round 0004）：重装、脚本化 dry-run、用户 live run | S3 | TODO (owner: user) | 用户确认 + check_setup complete | TODO (owner: user) |

## Tasks

| ID | Task | Parent subgoal | Scope boundary | Evidence required | Validation method |
| --- | --- | --- | --- | --- | --- |

## Main-Session Decision

Chosen sequence: S1 → S2 → S3（可与 S2 合并，由主会话定）→ S4

Rejected alternatives: TODO (owner: user)

Reasoning: 委派计划——S1 设计稿与 S2/S3 实现由 claude-sonnet-5 写入代理执行；设计评审与实现评审由独立对抗代理执行；验收由 main session + 用户共同完成。
