# Adversarial Review

## Review Scope

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Round: 0003（实现轮；评审对象 = harnessloop submodule 全部未提交改动）
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/scope-lock.md
- Reviewer: 独立实现级对抗评审子代理（claude-fable-5，与 0001/0002 轮评审同源、独立于 0003-01/02/03 实现者）
- Timestamp: 2026-07-16

规格基准：design-v2 + R1-R4 修正（rounds/0002/decision.md 裁决 (c)：实现落地时应用，不修订 v2 文件）+ 两项本轮已批准偏离：(a) todo 双字段 `field_todo_count`/`selfcheck_todo_count`；(b) check_setup 导出定位函数供 validate 复用。结论语义：positive=可验收进入 S4 live acceptance；negative=列必须修复项（按 feedback-policy 走 minimal-fix，不升级用户）。

## Evidence Used

| Evidence ID | Path | What it proves | Limitations |
| --- | --- | --- | --- |
| E1 | git -C harnessloop status/diff（9 个修改 + 3 个新建，全清单见 Checks） | 评审对象全集；改动均落在 scope-lock Allowed Changes 表内，无越界文件、无 .tmp 残留 | 未提交工作树快照 |
| E2 | plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py（659 行全文） | manifest/判定算法/双层门/退出码/导出函数实现 | — |
| E3 | plugins/harnessloop/skills/harnessloop-setup/SKILL.md（215 行全文） | 五步向导、跳过语义、密钥红线、gate 语义解说（:119-131 含 R2 修正后的三文件理由） | — |
| E4 | plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md（68 行全文） | 三档 24 字段全量预设 + M3 措辞（:26/:32） | — |
| E5 | 四个接线 SKILL diff（init:35/:90、status、continue、loop）+ validate.py diff + 四个版本文件 diff | 接线与 v2 §6/§7/§8 逐行比对 | — |
| E6 | 实测：python3（实为 pyenv 3.9.4）-B 运行 check_setup 于 fresh-init fixture 与本项目 | 骨架：0/5、gate BLOCKING（environment.md）、exit 1；本项目：4/5、data-sources partial [External Tools And Platforms]、gate WARNING（非阻断）、field_todo=13/self-check=0、exit 1——两项 scope-lock Verification 预期全命中；与 0001 轮独立模拟（4/5、同一缺口）交叉一致 | — |
| E7 | 实测：npm run validate（cwd=harnessloop/）完整运行 | 8/8 全绿，"Plugin framework validation passed"，[8/8] Claude strict ×2 ok；`[N/7]` 全仓 grep 零残留 | — |
| E8 | 实测：verify_protocol.py（插件缓存 0.10.0 路径，per scope-lock）--project 本项目 | exit 0，"All mechanical protocol gates passed"（TH-0006 nm11 修复已生效） | — |
| E9 | 实验：scratchpad 边界测试 18 项（重复标签切片求值、模板枚举抄录判空、单枚举值判满、哨兵正/反例、R4 粗体空字段、next_step 规则探针） | 16/18 通过；2 项失败为实现缺陷实锤（见 M-B） | 评审者脚本，session 级 scratchpad，随会话回收 |
| E10 | 实验：validate 阶段 3 证伪力（scratchpad 最小镜像树上先跑基线、再注入两种 gate_blocking 回归） | 基线 25 断言全 ok；破坏 A（门恒 false）被 2 条断言拦截；破坏 B（旧 M1"任意 incomplete 阻断"）被 M1 回归守卫断言拦截——断言有真实拦截力 | 同上 |
| E11 | docs/harnessloop-review-20260716.findings.json（skill-ux lens description 相关 4 条）；git show 5c35a22；plugins/harnessloop/skills/*/agents/ 目录枚举 | frontmatter 触发面评估基准；新技能家族先例（先例含 agents/openai.yaml 与 README/docs 同步更新）；12 个既有 skill 全部有 agents/ 目录、唯 harnessloop-setup 缺失 | — |
| E12 | rounds/0002/decision.md（裁决 (a)-(d)）；rounds/0002/reviews/adversarial-review.md | R1-R4 应用口径与判定基线 | — |

## Checks

| Check | Result | Evidence path | Notes |
| --- | --- | --- | --- |
| Goal alignment | pass | E5/E6/E7、goal.md | 8 条 AC 实现证据全部落位（逐条见 Finding 四）；criterion 2/3 的对话流走查部分待 S4 live |
| Scope-lock compliance | pass | E1 | 12 处改动逐一对照 Allowed Changes 表：全部在内；harnessloop-setup/ 目录仅含 SKILL.md（表内唯一允许项）；无 mock-project/证据枚举触碰；无临时文件残留。本评审只写本文件 |
| Data thresholds | pass | E2:86-205、E9 | 90 槽位 manifest 与模板实际结构逐项一致（21/4/29/24/12）；重复标签切片求值实测正确（只填 Model Policy > Codex > Adversarial review 时，另两个同名槽位仍列 missing、fields_filled=1）；模板枚举抄录判空/单枚举值判满实测正确 |
| Verification thresholds | pass | E6/E7/E8 | scope-lock 五条 Verification 全部实测命中：validate 8/8、verify_protocol exit 0、骨架 gate_blocking=true、本项目 partial 且 gate_blocking=false、python 3.9.4 实跑无异常 |
| Runtime validation | pass | E6/E7/E10 | 全部运行于 pyenv 3.9.4（兼容性下限实测，含 `(?i:...)` 局部正则旗标编译通过）；validate 断言经注坏实验证实有拦截力 |
| Source/source-data consistency | partial | E3:32/:80/:114/:123-124 vs E2:582-583 | **harnessloop-setup/SKILL.md 引用不存在的 JSON 字段 `todo_count`**（实现按已批准偏离输出 `field_todo_count`/`selfcheck_todo_count`，无合并字段），且 :124 描述的正是被该偏离废弃的"合并计数"语义；status/continue/loop 三处接线均已正确使用双字段——三方一致性唯独在 wizard 自身断裂（M-A） |
| Drift or contradiction risk | fail | E9（2 项失败实测）、E2:431-435 vs design-v2 §4.3/§2.1:170-171、E3:76 | `_resolve_table` 把分隔行之后**任意非空行**计为数据行：在空表小节写一句 "not sure yet..." 或 "no such tools declared yet, need review" 实测即被判"已回答"——S1 哨兵锚定被旁路，违背 v2 与新 SKILL 自身的明文行为承诺（M-B）。另有两处非阻断口径差异见 Finding 三 |

## Finding

### 一、必须修复项（negative 依据；均为小改动，走 minimal-fix，无需设计决策）

**M-A：harnessloop-setup/SKILL.md 的 `todo_count` 字段漂移（M1 端到端一致性断裂点，S4 前必须修复）。**

- 证据：SKILL.md:32（声称从 JSON 读取 `todo_count`——该键不存在）、:80（"a `todo_count` increment"）、:114（"warning (todo_count: K)"）、:123-124（:124 整段定义"literal-TODO 字段数 **plus** self-check Action 认领条目数"的合并语义——这正是 0003-02 handoff 批准偏离所废弃的单字段方案）、:211（示例 "warning (todo_count: 1)"）。实现实际输出：check_setup.py:582-583 的 `field_todo_count`/`selfcheck_todo_count`，人可读输出为 "TODO count: field=N, self-check=M"（E6 实测）。
- 三方一致性核对：status SKILL（diff 新步骤 2 与 Input Contract）、continue SKILL（diff 步骤 1、Input Contract、Output Contract 的 `field todo count`/`selfcheck todo count` 两行）、loop SKILL 接线——**全部已正确使用双字段**；唯 wizard 自身 SKILL 仍是旧的合并字段。这恰是本轮点名的"任何一处漂移即必须修复"类别：S4 live 验收时执行 wizard 的 agent 按 :32 去 JSON 里找 `todo_count` 会落空，:124 的语义解说与脚本行为矛盾。
- 修复（机械替换，约 7 处）：:32 字段清单改双字段；:80 改"`selfcheck_todo_count` increment"（跳过记入 self-check Action）；:114/:147/:178/:197/:211-212 的 "todo count" 呈现行定义为并列展示（field=N, self-check=M，与脚本人可读输出一致）；:123-124 拆开为双字段各自语义（并注明二者从不合并、均不参与 gate_blocking/complete——与 check_setup.py 模块 docstring:36-46 的偏离声明对齐）。

**M-B：`_resolve_table` 数据行判定过松，S1 哨兵锚定可被任意杂文本旁路（实测证伪）。**

- 证据：check_setup.py:431-435——分隔行之后、切片内**任意** `lines[j].strip()` 非空的行都计为数据行。E9 实测：在 fresh fixture 的 External Tools And Platforms 空表下分别写入 "not sure yet, need to think about external tools" 与 0001 轮的假阳性原句 "no such tools declared yet, need review"，两者均使该槽位被判"已回答"（从 missing_sections 消失）。
- 违背的明文承诺：design-v2 §4.3（数据行计数 + S1 锚定的存在意义）、§2.1:170-171（"正则锚定固定短语……不会误吃普通叙述句"）、新 SKILL.md:76 自己写的"vaguer answer ... must **not** ... it is not yet a confirmed 'none'"。S1 收紧的正则本身实现正确（E9 五条正/反例全过），但松散行计数在其上游把关口挖穿了——含糊表述不再需要冒充哨兵，只要存在于小节内就算答过。后果：`complete`/N-of-5 虚高 + wizard 审阅模式会跳过本应重问的类别（state 误判 filled/partial）。
- 修复（一行）：`_resolve_table` 的数据行判定改为 `lines[j].strip().startswith("|")`（模板表格数据行均以管道符起始；哨兵行走 `has_sentinel` 分支不受影响——fixture 里哨兵插在分隔行后，实测 `has_sentinel` 独立命中）。同时在 validate 阶段 3 增补一条回归断言：空表 + 非哨兵杂文本 → 该槽位仍 unfilled（防止此松散判定回潮）。

**M-C：新技能家族配套缺口（不阻塞 S4 live，但 0.11.0 push/发布前必须补齐；需主会话按控制契约扩一次 scope-lock）。**

<!-- verify:ignore -->
- (1) `plugins/harnessloop/skills/harnessloop-setup/agents/openai.yaml` 缺失：既有 12 个 skill 全部带 `agents/` 目录（E11 枚举），5c35a22 先例新增 secrets 时同 commit 附带该文件；本轮 `.codex-plugin/plugin.json` 的 `defaultPrompt` 已宣传 `$harnessloop-setup`，codex 侧却缺少该技能的界面元数据——宣传与配套不一致由本轮改动自身造成。
- (2) README.md 与 docs/usage.md:21（"exposes explicit skills named ... 12 个枚举"）、docs/harnessloop-framework.md 的技能清单均未含 `$harnessloop-setup`：5c35a22 先例是同 commit 更新这三处文档；本轮 scope-lock Allowed Changes 未列文档文件，实现者合规未动，但发布 0.11.0 时文档将与插件自述（defaultPrompt 13 技能）矛盾。
- 定性：两项均为 scope-lock 规划遗漏而非实现者违规；修复动作机械（4-6 行 yaml + 三处文档清单加一行），建议与 M-A/M-B 同批处理或在 push 前独立小轮补齐。

### 二、实测通过项（对抗验证明细）

- **check_setup.py 核心算法**（E6/E9）：90 槽位 manifest 与五份模板逐项一致；重复标签切片求值精确（Codex/Claude Code/Delegation Rules 三处同名槽位互不串扰）；模板枚举提示原样抄录判空、合法单枚举值（如 `unknown`）判满；R4 粗体 `**Action:**` 空字段判空；哨兵正则五条正/反例全过（含大小写边界：短语部分区分大小写、No/None 不区分）；gate_blocking 三文件 ANY 规则、退出码 0/1/2、`sys.dont_write_bytecode` + 调用方 `-B` 双保险——全部与 v2 §4.3-4.6 一致。
- **M1 双层门端到端**（除 M-A 一点外）：check_setup 输出 ↔ status/continue/loop 接线文本对 `gate_blocking`/`complete`/`partial` 三信号语义完全一致；continue 的 needs-setup 短路仅由 `gate_blocking: true` 触发、warning 放行路径明文；本项目实测 4/5 + WARNING 非阻断（v1 M1 死锁场景不再复现）。
- **R1-R4 落地口径**（E12 裁决 (c)）：R1——SKILL 示例二（cc=template → `setup gate: blocking`）与 ANY 规则一致，v2 §2.2 示例错误未被带入实现；R2——SKILL.md:126-129 逐句落地修正后理由（env/cc 直读、ccp 经 `$harnessloop-delegation` 一跳、self-check 排除的"认领台账自指死锁"理由）；R3——v2 文件层勘误，无实现面；R4——`_label_pattern` 冒号后 `\**` 已实现并实测。
- **validate.py**（E7/E10）：新阶段 3 六项断言与 v2 §7.2 一一对应（含双字段适配）；`[N/7]`→`[N/8]` 七处改毕、全仓零残留；fixture 由 `check_setup.MANIFEST` + 导出定位函数程序化生成（批准偏离 (b)，杜绝 fixture 与检测器漂移）；注坏实验证实断言可拦截"门恒不阻断"与"旧 M1 任意阻断"两类回归。
- **三档 profiles**（E4）：24 字段 × 3 档与 control-contract-template 标签逐一对应（5+6+6+3+4）；M3 措辞完整落地（:26 四条件 + :32 归属说明"protocol-level hard constraint owned by `$harnessloop-evidence`，no profile may turn this off"）；Failed review acceptance 三档均 required；与 0001/0002 轮核实的协议硬约束（evidence SKILL:31/:49、loop:428-430/:459-461、continue:90）无一违反。
- **协议硬原则遵守**（E3）：不虚构（:55/:57/:58/:107/:155/:158 委派探针无证据必写 unknown、Evidence index 等不得凭空 pass）；跳过必记 TODO 至 self-check Action 且字段留空（:45/:119）；密钥红线双保险（:46 + :133-135 专节，只记参数名转交 `$harnessloop-secrets`）；AskUserQuestion 优先（:47/:95）；展示→提议→确认唯一交互模式（:43/:154）；S4 跳过必须明示短路后果（:98，v2 §3 S4 的强化要求逐字落地）。
- **frontmatter 触发面**（E11）：description 三个触发子句均带 Harnessloop 限定（"references harnessloop:setup"/"runs $harnessloop-setup"/"Harnessloop project setup"），不复现 skill-ux high 发现（loop 无关键词门槛）的模式；家族别名消歧 boilerplate 句在位（:12）；结构五段式（Input/Processing/Output Contract + Safety Rules + Examples）与家族一致。
- **版本与清单**（E5）：四文件 0.10.0→0.11.0、defaultPrompt 插入位置与 v2 §8.3 逐字一致；`.agents/plugins/marketplace.json` 未动（正确，无 version 字段）；skills 目录通配自动纳入经 validate 阶段 1/8 全绿佐证。

### 三、非阻断口径差异与建议项

- S-i：`next_step` 取"FILES_ORDER 中首个非 filled 文件"（E9 探针：ds partial + cc/ccp template 时返回 data-sources.md），与 v2 §4.4 示例（同状态下示例给 control-contract.md）不一致，但与 v2 §6.2/实现后 status 接线文本（"the first non-`filled` file"）一致，且人可读输出单独有 "Setup gate: BLOCKING — <file>" 行点名阻断文件、continue 接线自行点名核心文件不依赖 next_step。定性：v2 示例自身与其 §6.2 正文不一致，实现选择了正文口径。建议：维持现实现，在实现说明/收盘记录中注明该示例勘误；或改为 gate_blocking 时 next_step 优先指向阻断文件（二选一，不阻塞）。
- S-ii：self-check.md 的 `Action` 字段值若以 TODO 字面量起始，会同时计入 `field_todo_count`（作为 leaf 字段值）与 `selfcheck_todo_count`（作为 Action 条目）——双计数器按偏离声明"从不合并"，重叠无害，但建议在 M-A 修复 :124 时顺带一句说明，防止使用者把两数相加当总数。
- S-iii：description 的 "check Harnessloop project setup" 与 status 的 setup 完整度呈现存在轻度语域重叠（用户只想"看看 setup 状态"时可能落入向导而非只读 status）；wizard 幂等步骤 2（complete 即停）与审阅模式缓解了代价，暂不需改，S4 live 时留意实际路由。
- S-iv：continue SKILL 步骤 3 的 verify_protocol 调用仍用裸 `python`（对照新步骤 1 的 `python3 -B`）——既有文本，非本轮引入，与 findings #17（裸 python DX）同族，随该 deferred 项处理即可。

### 四、Acceptance Criteria 逐条判定

| # | 验收标准 | 判定 | 实现证据 | 待 S4 live 部分 |
| --- | --- | --- | --- | --- |
| 1 | skill 存在且过 claude plugin validate --strict | covered | skills/harnessloop-setup/SKILL.md 存在；E7 阶段 [8/8] strict ×2 ok | 无 |
| 2 | 五步流程（含三档预设、N/5 报告） | covered（文本级） | SKILL S1-S5 全文 + profiles 68 行 + Output Contract 的 N/5 与 gate 状态呈现 | 五步对话流走通 = live acceptance 本体（goal Required Human Decisions）；dry-run transcript 亦未在本轮产出，验收时一并补 |
| 3 | 每步可跳过且跳过必记 TODO 到 self-check | covered（文本级，M-A 措辞修复后） | SKILL:45/:58/:80/:90/:98/:119 统一跳过语义 + 分档阻断预告 | 实际跳过 → self-check Action 写入 = live 走查 |
| 4 | check_setup 返回机器可读完整度 | covered（M-B 修复后完整） | E6：骨架 incomplete/gate_blocking=true/exit 1，本项目 partial 4/5/非阻断/exit 1，JSON 双层门字段齐备；E9 算法边界 16/18 | "本项目返回 complete" 待 live 首跑补 External Tools 哨兵行（0001 decision 已裁，非本轮缺陷） |
| 5 | status 输出 setup-incomplete 与缺什么/下一步 | covered | status diff：状态枚举、setup completeness/gate/双 todo/next step 字段、`-B` 只读说明、Safety Rule 补丁 | 骨架项目上实际跑一次 status（agent 行为验证） |
| 6 | continue 门返回 needs-setup | covered | continue diff：步骤 1 短路、decision 枚举、setup gate 输出、Safety Rule 双向表述 | 骨架项目上实际跑一次 continue |
| 7 | init 交接语指向 setup wizard | covered | init diff :35/:90 与 v2 §6.1 逐字一致 | 无 |
| 8 | loop 触发条件修正 | covered | loop diff :69、新增完整度检查段、:114 句（现 :122）、profiles 引用行（:40）；goal.md 行号勘误已由 0002 收盘执行（R5） | 无 |

汇总：8/8 实现证据落位；其中 #2/#3/#5/#6 的 agent 行为面按验收方法设计即属 S4 live/dry-run 范围，非本轮缺口。goal Success Condition 四项中：validate 全绿 ✓、3.9 兼容 ✓（实测 3.9.4）、骨架 incomplete ✓；"本项目 complete" 与 "wizard 五步走通" 待 live。

## Feedback

negative

（实现质量整体高：M1/M2/M3/R1-R4/两项批准偏离全部正确落地并经实测与注坏实验背书，8 条 AC 证据齐位，validate 8/8、verify_protocol exit 0、3.9.4 实测通过。但存在两处必须先修的实现缺陷——M-A：wizard SKILL 引用不存在的 `todo_count` JSON 字段并保留已废弃的合并语义，恰是本轮点名的 M1 端到端一致性断裂，直接影响 S4 live 时执行 wizard 的 agent；M-B：表格数据行判定过松使 S1 哨兵锚定可被任意杂文本旁路，实测证伪且违背实现自身的明文承诺。二者均为机械小改（文本替换 + 一行代码 + 一条回归断言），按 feedback-policy 走 minimal-fix 即可，无需回滚整轮。M-C 为 push 前必须补齐的 scope-lock 外配套（agents/openai.yaml + 三处文档技能清单），不阻塞修复后的 S4。）

## Required Next Action

1. minimal-fix（同轮或 0003 修复批）：M-A——harnessloop-setup/SKILL.md 约 7 处 `todo_count` 措辞按双字段方案替换（:32/:80/:114/:123-124/:147 及示例区），语义对齐 check_setup.py docstring 的偏离声明；M-B——check_setup.py:433 数据行判定加 `startswith("|")` 约束，并在 validate 阶段 3 增补"空表 + 非哨兵杂文本仍 unfilled"回归断言。
2. 修复后复跑：npm run validate（8/8）+ 本评审 E9 两条失败用例（应转为通过）；主会话走查 M-A 替换文本即可，无需再开完整对抗评审轮。
<!-- verify:ignore -->
3. M-C（push 0.11.0 前）：主会话按控制契约扩 scope-lock 后补 `harnessloop-setup/agents/openai.yaml`（对照 secrets/status 先例格式）与 README.md、docs/usage.md:21、docs/harnessloop-framework.md 技能清单三处 `$harnessloop-setup` 条目（5c35a22 先例为同 commit 更新）。
4. S-i/S-ii 建议随 M-A/M-B 顺带处理或在收盘记录中注明口径；S-iii/S-iv 记录后不动。
5. 完成 1-2 后进入 S4：用户 live 首跑 wizard（含本项目 External Tools 哨兵补齐、dry-run transcript 归档、thresholds "本项目=complete" 复验、"7/7→8/8" 阈值文本人工确认）。
