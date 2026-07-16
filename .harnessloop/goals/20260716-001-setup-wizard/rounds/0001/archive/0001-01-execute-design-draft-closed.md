# 0001-01-execute-design-draft-closed

## Objective

撰写 setup wizard 设计文档：五步交互流、check_setup 机械检测规则、lite/standard/strict 档位预设内容、四处接线点（init/status/continue/loop）文本变更方案、validate 新断言清单。

## Inputs

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/scope-lock.md
- Evidence paths: docs/harnessloop-review-20260716.findings.json（guided-setup/auto-detection lens 的 CONFIRMED 条目）；harnessloop/plugins/harnessloop/skills/ 全部 SKILL.md；harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ 模板目录
- External tools: 无
- Credential names only: 无
- Local parameter references: 无
- Expected model/effort: claude-sonnet-5

## Scope Boundaries

Allowed:

- 写 .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/evidence/dynamic/setup-wizard-design.md
- 只读 docs/harnessloop-review-20260716.findings.json、harnessloop/plugins/harnessloop/skills/ 下全部 SKILL.md、harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ 模板目录

Disallowed:

- 写入 harnessloop/ submodule 任何文件
- 写入 rounds/0001/evidence/dynamic/setup-wizard-design.md 之外的任何文件

## Tool And Access Contract

| Tool/system | Purpose | Read/write scope | Account role | Credential name | Local parameter references | Verification method | Failure handling |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 本地文件系统 | 读取需求与模板、写入设计文档 | 只读（需求/模板）+ 写（设计文档单文件） | 无 | 无 | 无 | 人工/评审代理走查设计文档内容 | 无法写入时报告并停止 |

Do not include secret values. Use local parameter keys or provider references only.

## Budget And Context Limits

- Max input scope: findings.json 中 guided-setup/auto-detection lens 相关条目 + 全部 SKILL.md + references/ 模板目录
- Max output length: TODO (owner: user)
- Raw logs allowed in output: no
- Evidence paths required: yes

## Required Work

基于 findings.json 中 guided-setup/auto-detection lens 的 CONFIRMED 条目与 references/ 模板目录格式权威，撰写覆盖 goal.md 全部 8 条 acceptance criteria 实现方案的设计文档，明确五步交互流、check_setup 检测规则、档位预设内容、四处接线点文本变更方案、validate 新断言清单。

## Required Outputs

.harnessloop/goals/20260716-001-setup-wizard/rounds/0001/evidence/dynamic/setup-wizard-design.md

## Verification Condition

设计文档覆盖 goal.md 全部 8 条 acceptance criteria 的实现方案，且不违反协议硬原则（不虚构事实、跳过必记 TODO、密钥红线）。

## Closeout Summary

Status: closed
Evidence produced: rounds/0001/evidence/dynamic/setup-wizard-design.md（706 行）
Open risks: 经独立对抗性评审判定 negative——3 必须修复项 M1-M3 + 10 建议修复项 S1-S10（见 rounds/0001/reviews/adversarial-review.md），设计需在 round 0002 修订后另存为 v2
Next handoff: 0002-01-execute-design-revision-open（round 0002）
Observed model/effort: claude-sonnet-5（按委派参数指定，无独立运行时探针核实实际使用模型，见 state/environment.md 局限）
