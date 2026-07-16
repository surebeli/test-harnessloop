# 0003-02-execute-check-setup-and-validate-closed

## Objective

新建 `check_setup.py`（机器可读完整度检测脚本）；修改 `harnessloop/scripts/validate.py`，插入 wizard/check_setup 相关验证新阶段并完成 [N/7]→[N/8] 重编号。

## Inputs

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/scope-lock.md
- Evidence paths: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/evidence/dynamic/setup-wizard-design-v2.md（§4 check_setup 接口/算法、§7.1-§7.2 连带更新与 validate 断言清单，含 R2/R4 修正方向）；harnessloop/scripts/validate.py（既有 7 阶段实现，只读参照）
- External tools: 无
- Credential names only: 无
- Local parameter references: 无
- Expected model/effort: claude-sonnet-5

## Scope Boundaries

Allowed:

- 新建 harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py
- 修改 harnessloop/scripts/validate.py（新增阶段 + 重编号）
- 只读 rounds/0002/evidence/dynamic/setup-wizard-design-v2.md、rounds/0002/decision.md、rounds/0002/reviews/adversarial-review.md

Disallowed:

- 修改上表之外的任何文件
- 写入 rounds/0003/ 目录之外的项目文件
- harnessloop/plugins/harnessloop/examples/mock-project/、证据枚举相关文件

## Tool And Access Contract

| Tool/system | Purpose | Read/write scope | Account role | Credential name | Local parameter references | Verification method | Failure handling |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 本地文件系统 | 读取设计稿/既有 validate.py，新建 check_setup.py 并修改 validate.py | 只读（设计稿/评审）+ 写（新文件 + 既有文件修改） | 无 | 无 | 无 | npm run validate（8/8）；python3 3.9.4 实测；单测覆盖 R4 等实现级修正 | 无法写入或验证失败时报告并停止 |

Do not include secret values. Use local parameter keys or provider references only.

## Budget And Context Limits

- Max input scope: setup-wizard-design-v2.md §4/§7 全节 + harnessloop/scripts/validate.py 现有全文 + adversarial-review.md 中 M2/S10/R4 相关段落
- Max output length: TODO (owner: user)
- Raw logs allowed in output: no
- Evidence paths required: yes

## Required Work

按 design-v2 §4 落地 check_setup.py：路径化 manifest、小节容器路径作用域匹配算法（M2 修复）、`gate_blocking`/`todo_count`/`complete` 三信号分离（M1 修复）、none 哨兵正则（S1 收紧版）、`sys.dont_write_bytecode`/`python3 -B` 零写入（S6）、§4.3 容差规则并应用 R4 修正（`**Label:**` 冒号在粗体内侧时的值捕获需剥离首尾 `*`）。按 §7.1/§7.2 在 validate.py 插入新验证阶段并完成 7→8 重编号，新增断言覆盖双层门正反例（含 design-v2 §7.2 断言 5 的 ANY 规则钉死）与 90 条路径的单测（§10.13）。全部新代码需在 Python 3.9.4 下无异常运行。

## Required Outputs

- harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py
- harnessloop/scripts/validate.py（修改后）

## Verification Condition

`cd harnessloop && npm run validate` 8/8 全绿；check_setup.py 对 fresh-init fixture 报 `gate_blocking=true`、对本项目报 `partial` 且 `gate_blocking=false`；所有新代码 python3 3.9.4 实测无异常；由 0003-04 实现级对抗评审最终核实与 design-v2（+R2/R4 修正）的一致性。

## Closeout Summary

Status: closed
Evidence produced: harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py（新建，659 行，机器可读完整度检测脚本）；harnessloop/scripts/validate.py（修改，新增第 3 阶段共 28 断言，完成 `[N/7]`→`[N/8]` 重编号）
Open risks: 独立实现级对抗评审（0003-04，rounds/0003/reviews/adversarial-review.md）首次判定 negative，命中本交付物一处必修项 M-B：表格数据行判定过松，S1 哨兵锚定被任意杂文本旁路，实测证伪。已按 minimal-fix 修复：加 `startswith("|")` 约束并增补回归断言，经证伪力实证（还原旧码使 3 条断言必挂，证明断言确有拦截力非摆设），修复后经主会话走查复核确认到位，未再开新评审轮
Next handoff: 0003-04-review-adversarial-implementation-open（同轮，实现级对抗评审，依赖本 handoff 产出）
Observed model/effort: claude-sonnet-5（按委派参数指定，无独立运行时探针核实实际使用模型，见 state/environment.md 局限）
