# 0003-01-execute-new-skill-and-profiles-closed

## Objective

新建 `harnessloop-setup/SKILL.md`（五步向导全文）与 `control-contract-profiles.md`（lite/standard/strict 三档预设全文）。

## Inputs

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/scope-lock.md
- Evidence paths: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/evidence/dynamic/setup-wizard-design-v2.md（含 R1-R4 修正方向，见 rounds/0002/decision.md 裁决 (c) 与 rounds/0002/reviews/adversarial-review.md Finding 五 R1-R4）；harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ 模板目录
- External tools: 无
- Credential names only: 无
- Local parameter references: 无
- Expected model/effort: claude-sonnet-5

## Scope Boundaries

Allowed:

- 新建 harnessloop/plugins/harnessloop/skills/harnessloop-setup/SKILL.md
- 新建 harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md
- 只读 rounds/0002/evidence/dynamic/setup-wizard-design-v2.md、rounds/0002/decision.md、rounds/0002/reviews/adversarial-review.md、references/ 模板目录

Disallowed:

- 修改任何既有文件
- 写入 rounds/0003/ 目录之外的项目文件
- harnessloop/plugins/harnessloop/examples/mock-project/、证据枚举相关文件

## Tool And Access Contract

| Tool/system | Purpose | Read/write scope | Account role | Credential name | Local parameter references | Verification method | Failure handling |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 本地文件系统 | 读取设计稿/评审/模板，新建两个 skill 文件 | 只读（设计稿/评审/模板）+ 写（两个新文件） | 无 | 无 | 无 | claude plugin validate --strict；实现级对抗评审走查 | 无法写入时报告并停止 |

Do not include secret values. Use local parameter keys or provider references only.

## Budget And Context Limits

- Max input scope: setup-wizard-design-v2.md 全文（§1-§5 五步向导与三档预设相关章节为主）+ decision.md + adversarial-review.md 的 R1-R4 段落 + references/ 模板目录
- Max output length: TODO (owner: user)
- Raw logs allowed in output: no
- Evidence paths required: yes

## Required Work

按 design-v2 §2/§3/§5 落地五步交互流全文（环境自动检测→data-sources 引导→cost-context-policy 确认→control-contract 档位选择→self-check 汇总+完成度 N/5 报告），写成 `harnessloop-setup/SKILL.md`；按 §5 三档预设内容写成 `control-contract-profiles.md`。落地时应用 R1（§2.2 示例段 gate_blocking 值与规范定义的矛盾，采用规范定义 `gate_blocking=true` 的口径）、R3（17 条 findings 逐条处置表汇总计数以 covered 9/oos 4/deferred 4 为准）等与本 handoff 交付物相关的修正；不虚构 v2 未覆盖的内容，缺口按设计原有的 TODO/待定标注处理。

## Required Outputs

- harnessloop/plugins/harnessloop/skills/harnessloop-setup/SKILL.md
- harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md

## Verification Condition

两文件均通过 `claude plugin validate --strict`；五步交互流与三档预设内容与 design-v2（+R1、R3 等相关修正）逐项对应，不引入与协议硬原则或已核实事实的矛盾；由 0003-04 实现级对抗评审最终核实。

## Closeout Summary

Status: closed
Evidence produced: harnessloop/plugins/harnessloop/skills/harnessloop-setup/SKILL.md（新建，216 行，五步向导全文）；harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md（新建，68 行，lite/standard/strict 三档预设全文）
Open risks: 独立实现级对抗评审（0003-04，rounds/0003/reviews/adversarial-review.md）首次判定 negative，命中本交付物一处必修项 M-A：wizard SKILL 引用不存在的 `todo_count` JSON 字段、保留已废弃的合并语义（跨代理接缝失配——todo 双字段方案为本轮已批准的规格偏离，但未同步广播给本 handoff）。已按 minimal-fix 修复：约 7 处措辞改为双字段方案（`field_todo_count`/`selfcheck_todo_count`），修复后经主会话走查复核确认到位，未再开新评审轮
Next handoff: 0003-04-review-adversarial-implementation-open（同轮，实现级对抗评审，依赖本 handoff 产出）
Observed model/effort: claude-sonnet-5（按委派参数指定，无独立运行时探针核实实际使用模型，见 state/environment.md 局限）
