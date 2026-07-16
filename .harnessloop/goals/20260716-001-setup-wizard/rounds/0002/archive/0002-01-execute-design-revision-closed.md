# 0002-01-execute-design-revision-closed

## Objective

按 rounds/0001/decision.md 确定的修复方向修订 setup wizard 设计稿：M1 双层门方案、M2 小节作用域匹配规则、M3 lite 档对齐 evidence SKILL 硬约束，并采纳 S1-S10 全部建议修复。

## Inputs

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/scope-lock.md
- Evidence paths: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/evidence/dynamic/setup-wizard-design.md（原稿，只读，不可修改）；.harnessloop/goals/20260716-001-setup-wizard/rounds/0001/reviews/adversarial-review.md（M1-M3+S1-S10 依据）；.harnessloop/goals/20260716-001-setup-wizard/rounds/0001/decision.md（修复方向决定）
- External tools: 无
- Credential names only: 无
- Local parameter references: 无
- Expected model/effort: claude-sonnet-5

## Scope Boundaries

Allowed:

- 写 .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/evidence/dynamic/setup-wizard-design-v2.md
- 只读 rounds/0001/evidence/dynamic/setup-wizard-design.md、rounds/0001/reviews/adversarial-review.md、rounds/0001/decision.md、goal.md、thresholds.md

Disallowed:

- 修改 rounds/0001/ 内任何文件（含原设计稿）
- 写入 harnessloop/ submodule 任何文件
- 写入 rounds/0002/evidence/dynamic/setup-wizard-design-v2.md 之外的任何文件

## Tool And Access Contract

| Tool/system | Purpose | Read/write scope | Account role | Credential name | Local parameter references | Verification method | Failure handling |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 本地文件系统 | 读取原稿/评审/决定，写入修订版设计稿 | 只读（原稿/评审/决定）+ 写（v2 设计稿单文件） | 无 | 无 | 无 | 独立复审子代理走查 v2 设计文档内容 | 无法写入时报告并停止 |

Do not include secret values. Use local parameter keys or provider references only.

## Budget And Context Limits

- Max input scope: rounds/0001/evidence/dynamic/setup-wizard-design.md 全文 + rounds/0001/reviews/adversarial-review.md 全文 + rounds/0001/decision.md
- Max output length: TODO (owner: user)
- Raw logs allowed in output: no
- Evidence paths required: yes

## Required Work

逐项落实 M1（双层门 gate_blocking + self-check TODO 认领降级 + todo_count 显性呈现方案）、M2（§4.3 补充按小节容器路径的作用域匹配规则）、M3（lite 档 Evidence contract revision 条款对齐 harnessloop-evidence SKILL:31/:49 硬约束）以及 S1-S10 全部建议修复，产出可实现的设计修订稿 v2，不改动 rounds/0001 原稿（保留审计链）。

## Required Outputs

.harnessloop/goals/20260716-001-setup-wizard/rounds/0002/evidence/dynamic/setup-wizard-design-v2.md

## Verification Condition

v2 设计稿逐项对应 M1-M3 的最小修复方案与 S1-S10 建议，不引入新的与协议硬原则或已核实事实的矛盾；独立复审子代理据此判定 positive/negative。

## Closeout Summary

Status: closed
Evidence produced: rounds/0002/evidence/dynamic/setup-wizard-design-v2.md（934 行）
Open risks: 复审发现 R1-R5 勘误级新问题（R1 为唯一实质新矛盾）；R1-R4 作为 round 0003 实现入场条件处理（不修订 v2 本身），R5（goal.md 行号勘误）已随收盘执行
Next handoff: 0003-01-execute-new-skill-and-profiles-open（round 0003）
Observed model/effort: claude-sonnet-5（按委派参数指定，无独立运行时探针核实实际使用模型，见 state/environment.md 局限）
