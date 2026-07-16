# Adversarial Review

## Review Scope

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Round: 0001（设计轮；评审对象为设计文档，非实现代码）
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/scope-lock.md
- Reviewer: 独立对抗性设计评审子代理（claude-fable-5，独立于 0001-01 设计者）
- Timestamp: 2026-07-16

评审对象：`.harnessloop/goals/20260716-001-setup-wizard/rounds/0001/evidence/dynamic/setup-wizard-design.md`（706 行）。评审语义（设计轮）：positive=设计可进入实现；negative=需最小修复后才可实现；neutral=证据不足；blocked=无法评审。

## Evidence Used

| Evidence ID | Path | What it proves | Limitations |
| --- | --- | --- | --- |
| E1 | rounds/0001/evidence/dynamic/setup-wizard-design.md | 被评审设计全文（行号引用以本文件为准） | — |
| E2 | .harnessloop/goals/20260716-001-setup-wizard/goal.md | 8 条 acceptance criteria、Success Condition、Non-Goals | — |
| E3 | .harnessloop/goals/20260716-001-setup-wizard/thresholds.md | 验收阈值；:15 硬编码 "npm run validate 7/7 阶段全绿" | — |
| E4 | docs/harnessloop-review-20260716.findings.json | guided-setup 8 条 + auto-detection 9 条 = 17 条 CONFIRMED（脚本实数核实） | — |
| E5 | harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/{environment-self-check,cost-context-policy,control-contract,self-check,data-sources}-template.md | 字段数逐行亲数：21 / 29 / 24 / 12 / 4 张空表；容器行、预填表结构 | — |
| E6 | harnessloop/plugins/harnessloop/skills/{harnessloop-init,harnessloop-status,harnessloop-continue,harnessloop-loop,harnessloop-evidence}/SKILL.md | 设计引用行号逐一核对（init:35/:90、status:20/22-28/34-55/59-63、continue:22/24-37/55-77/81-90、loop:69/:100/:114/:186/:304/:381-430/:455-463）；协议硬约束原文 | — |
| E7 | harnessloop/scripts/validate.py（:32-34/:64/:110/:131/:173/:206/:236/:290/:425）；skills/harnessloop-loop/scripts/init_project.py（:4/:13-14/:26/:48）；verify_protocol.py（:189） | import 机制、[N/7] 硬编码位置、SKILL_DIR 模式、removeprefix 3.9 下限、2 号退出码语义 | — |
| E8 | git show 5c35a22（harnessloop submodule） | 先例：新增 secrets skill 时 4 处 version 同步 bump 至 0.8.0 + codex defaultPrompt 同步；plugin.json skills 字段未动 | marketplace.json 原值为 0.1.0（非设计声称的 0.7.0） |
| E9 | .harnessloop/{state/environment.md,setup/data-sources.md,setup/cost-context-policy.md,state/control-contract.md,state/self-check.md}（本项目自身） | 按设计 §4.2/§4.3 算法实测本项目状态：4/5 filled；data-sources.md:30 之下 External Tools 表 0 行、无哨兵行 → partial | — |
| E10 | /private/tmp/claude-501/-Users-litianyi-Documents-Code--ai-goods-test-harnessloop/b39f5bf8-f328-41b3-b5fd-eb01a465a399/scratchpad/sim_check_setup.py | 设计判定算法的可执行复现 + none 哨兵正则鲁棒性实测 | 评审者对设计算法的近似复刻，非最终实现；session 级临时目录，随会话回收 |

## Checks

| Check | Result | Evidence path | Notes |
| --- | --- | --- | --- |
| Goal alignment | partial | E1 §9、E2 | 8 条 AC 均有对应章节，但 AC3（跳过语义）与 AC6（needs-setup 短路）在设计内部互相矛盾（见 Finding M1）；goal Success Condition"本项目返回 complete"按设计现行规则实测不成立（E9） |
| Scope-lock compliance | pass | rounds/0001/scope-lock.md | 设计轮只写了允许的单文件；本评审也只写本文件 |
| Data thresholds | partial | E4、E1:5 | findings 基线引用属实（17 条 CONFIRMED 实数核实）；但 E1:5 宣称"逐条覆盖见第 9 节"失实——§9 是 8 条 AC 对照表，17 条 findings 并无逐条处置映射（如 cost-prices.json 引导、goal 引导式访谈、init 报告分类等条目在设计中无显式处置） |
| Verification thresholds | fail | E3:15-16、E9 | thresholds.md:16 要求"本项目（已填）返回 complete"，实测本项目 data-sources.md 为 partial（External Tools 0 行无哨兵）→ 按设计规则 complete=false；设计 §10.2 已自知但未解决，且未提示 [N/7]→[N/8] 重编号会使 thresholds.md:15 与本项目 data-sources.md:16/:24 的"7/7 阶段"文本过期 |
| Runtime validation | pass | E7、E10 | 设计轮无运行时面；可机验的声明（import 机制、退出码、3.9 兼容先例、路径解析模式）逐一核实属实；判定算法经 E10 可执行复现基本可实现 |
| Source/source-data consistency | pass | E5、E6、E8 | 字段数 21/29/24/12 亲数全部吻合；全部行号引用核对属实；先例 commit 5c35a22 的 version bump 与 defaultPrompt 同步属实（仅 marketplace.json 原值 0.1.0 一处笔误，见 S7） |
| Drift or contradiction risk | fail | E1:193-194 vs E1:518/:538/:578/:595-601、E1:416 vs harnessloop-evidence/SKILL.md:31/:49、E5 cost-context-policy-template.md:11/:26-27/:55-58/:62-65 | 三处实质矛盾/歧义：M1 门语义自相矛盾、M2 重复标签使 §4.3 算法不可无歧义求值、M3 lite 档条款与 evidence skill 硬性人工确认冲突 |

## Finding

### 必须修复项（negative 的依据；均为设计文本级最小修复，不推翻架构）

**M1（主会话疑点证实）：§2.2"跳过不阻塞"与 §6.3 无条件短路直接矛盾，且实测会锁死本项目自己的 continue。**

- 矛盾原文：E1:193-194 宣称"该 TODO 不阻塞 $harnessloop-loop 主协议执行……但下次 $harnessloop-status 会持续提示"；而 E1:518（continue Input Contract 补丁）、E1:538（Processing Contract 新第 1 步）、E1:578（Safety Rules 补丁）对 `complete: false` **无条件**短路返回 `needs-setup`，"stop before evaluating any other gate. Do not execute business work"；E1:595-601（loop 接线）同样要求 complete:false 时先交给 wizard 才能建 goal/进轮次。跳过语义（E1:205）= 字段留空 → 文件必为 partial → complete:false → 门永远短路。"每步可跳过"（goal AC3）在门层面被 AC6 的实现完全抵消：跳过后 loop/continue 双双锁死，唯一出路是回头补答，"可跳过"名存实亡。
- 实测后果（E9/E10）：本项目当前即为此状态——data-sources.md:30 之下 External Tools 表 0 行、无哨兵行，5 文件实测 filled 4/5、data-sources=partial → 实现落地当轮，本项目自己的 `$harnessloop-continue` 返回 needs-setup，本 goal 无法经 continue 推进；goal.md Success Condition"check_setup 在本项目（已填）返回 complete"同时不成立。设计 §10.2（E1:698）承认此差距但把它归为"本项目文件问题"，没有意识到这与 §2.2 的承诺、§6.3 的门设计构成三角矛盾。
- 连带缺陷（同一语义结）：§4.3（E1:314）规定字面 `TODO (owner: user)` 算 filled——于是"诚实跳过留空"被门惩罚（锁死），而"往字段里塞 TODO"反被放行（complete=true 可达），门可被零成本刷穿。跳过与 TODO 两条路径的完整度语义相反，属于同一处设计矛盾的两面。
- 最小修复（两条择一或并用，需主会话/用户拍板）：
  - (a) 短路条件收窄：仅当 environment.md / control-contract.md / cost-context-policy.md 任一处于 `template` 或 `missing`（核心策略未建立）时短路 needs-setup；对 `partial` 且其缺口在 self-check.md Action 中有对应 `TODO (owner: user)` 记录的情况，降级为警告（`setup gate: incomplete (TODO acknowledged)`）并继续评估后续门。
  - (b) check_setup 增加"acknowledged"层：缺口若被 self-check.md 的 TODO 显式认领，输出 `complete_for_gate: true` 与 `complete_strict: false` 两级结论；continue/loop 门用 complete_for_gate，status 与 wizard 用 complete_strict 持续提示。同时把"字面 TODO 值"从 filled 改判为 acknowledged，消除刷门通道。
  - 另外无论选哪条：实现轮应按 §10.2 方案 (a) 给本项目 External Tools 表补 none 哨兵行（这解决 Success Condition，但**不能替代**门语义修复——未来任何用户一旦跳过仍会锁死）。

**M2：§4.3 判定算法对重复 leaf 标签未定义作用域，29 槽位清单按现行算法不可无歧义求值。**

- 证据：cost-context-policy-template.md 中 `Core decisions:` 出现 3 次（:11 Main Session、:58 Codex、:65 Claude Code）、`Low-context execution:` 3 次（:26/:56/:63）、`Adversarial review:` 3 次（:27/:57/:64）、`Independent investigation:` 2 次（:55/:62）。§4.3（E1:311）只说"在目标文件中定位与模板同名的 `Label:` 行"，未规定按小节/容器行分组匹配；E10 复现时同名标签命中多行，若不带节作用域，"Codex > Adversarial review 已填、Claude Code > Adversarial review 留空"这类状态无法区分，29 字段计数会失真。§4.4 的 `missing_sections` 示例（`"Model And Effort > Observed model"`，E1:332）暗示了节路径概念，但算法正文没有落实。
- 最小修复：§4.3 明确规定匹配以（`## 小节标题`，容器行）为作用域逐段进行，manifest 存储完整路径（如 `Model Policy > Codex > Adversarial review`）而非裸标签。

**M3：lite 档 Evidence contract revision 条款与 harnessloop-evidence SKILL 的硬性人工确认要求冲突。**

- 证据：E1:416（§5.2）lite 档写"不需要，除非改变验收标准实质含义"；但 harnessloop-evidence/SKILL.md:31 规定 human-confirmation "required for **any** acceptance criteria revision, **lower validation bar, or broader evidence scope**"，:49 再加 "or affects continuation"；harnessloop-loop/SKILL.md:186 同样写死 "`revise`: change acceptance criteria; require human confirmation"。lite 条款豁免了"降低验证门槛/扩大证据范围/影响续跑"三类情形的人工确认，而这三类是 evidence skill 层面写死的行为，control-contract 无权覆盖——落地后要么 skill 不理会档位（条款失实），要么产生 loop SKILL:304 定义的"control contract 与协议自相矛盾"，成为 self-audit 必报项。
- 最小修复：lite 该格改为与 evidence SKILL:49 四条件对齐（"不需要，除非改变验收标准、降低验证门槛、扩大证据范围或影响续跑判定"——实际上等价于"需要"，或直接改"需要"并把 lite 的宽松度体现在其它字段）。
- 对照核实其余硬约束：`Failed review acceptance` 三档均"需要"，与 loop:430（never delegate）、continue:90 一致，无违反；lite 的 Rollback"不需要（本地自主回滚需记录）"与 loop:459-461（negative/neutral 下 rollback 为协议允许动作）不冲突（外部系统回滚仍被 lite 的 Irreversible/external-system write="需要"兜住）；lite Scope-lock mutation"不需要"未违反任何协议硬约束（loop:428 只禁委派、不强制人工确认，属项目策略空间），但设计 §10.3 已正确标注需用户验收确认——保持。

### 建议修复项（不阻塞进入实现，但建议随 M1-M3 一并处理）

- S1 none 哨兵正则假阳性：`^_?\s*(no|none)\b.*declared.*_?$` 实测（E10）能匹配设计自身全部示例哨兵行，也不会误吃表格数据行（`|` 开头不匹配）；但会误匹配 "no such tools declared yet, need review"、"No sources are declared in CI but two are used at runtime" 这类行首为 No/None 且含 declared 的普通叙述/待办句，把"没想好"错判成"已确认为空"。且 `_?$` 在 `.*` 贪婪匹配下形同虚设。建议收紧为要求固定后缀（如必须含 `confirmed via setup wizard`）或整句锚定。
<!-- verify:ignore -->
- S2 §4.1 标题路径笔误证实：E1:276 写 `harnessloop-loop/skills/harnessloop-loop/scripts/check_setup.py`，首段应为 `plugins/harnessloop/`；§1.2（E1:47）等正文其它处均正确。改标题即可。
- S3 E1:5"共 17 条，逐条覆盖见第 9 节"失实：17 条 CONFIRMED 属实（E4 实数），但 §9 只是 8 条 AC 对照表；guided-setup/auto-detection 下的 cost-prices.json 引导创建、第一个 goal 引导式访谈、init 产出报告分级、askuserquestion setup 漏斗、init-project.sh 裸 python、脚本直跑零指引、mock-project 参照等条目在设计中无显式处置（部分确属 goal.md 范围外，但需写明）。建议补一张 17 条 findings 逐条处置表（covered / out-of-scope-by-goal / deferred）。
- S4 [N/7]→[N/8] 影响面：harnessloop 仓库内硬编码仅 validate.py 7 处 print（:64/:110/:131/:206/:236/:290/:425），设计"低风险查找替换"判断属实；**但**本项目侧 thresholds.md:15（"7/7 阶段全绿"）与 .harnessloop/setup/data-sources.md:16/:24（"7/7 阶段全绿"/"7 阶段"）会随之过期，且 thresholds 变更按 Threshold Change Policy 需人工确认。设计未提示此连带更新，建议补入 §7.1 或 §10。
- S5 表格槽位排除逻辑与规则文本不自洽：§4.2 规则（E1:292）写"原始模板数据行数为 0 → 计入槽位"，而 data-sources 模板的 Local Channel Parameters 表数据行数同样为 0（E5），排除仅靠清单行内的口头豁免（E1:299）。规则与清单会误导实现者数出 5 张表。建议把规则改写为"计入，除非清单显式豁免（豁免清单：Local Channel Parameters——归 $harnessloop-secrets 管理）"。Execution Delegation Matrix（8 行预填）与 Blocker Classification（7 行预填）的排除与模板实测一致，无问题；Secret Handling 段无任何可填槽位，排除自洽。
- S6 status 只读原则补丁基本自洽，留一个像素级缺口：status Safety Rules 现行三条（status/SKILL.md:59-63）禁的是"文件写入/归档/状态修复/契约变更/业务执行"与"外部系统探测"，运行纯读取的本地脚本不违反字面；设计新增的说明行（E1:508）方向正确。但 `check_setup.py import init_project` 在脚本目录可写时会生成 `__pycache__/*.pyc`（对插件安装目录的写入，非项目状态写入）。建议实现时以 `sys.dont_write_bytecode = True` 或文档说明豁免，把"no file writes"守干净。
- S7 §8.2 事实性笔误：先例 5c35a22 中 `.claude-plugin/marketplace.json` 的插件条目 version 是 0.1.0→0.8.0，并非"四处从 0.7.0 统一提升"（其余三处确为 0.7.0→0.8.0，E8）。结论（+1 次版本、四文件对应）不受影响，改叙述即可。
- S8 §2.1 首跑 transcript 与 §3/S1 规则小出入：S1 正文把 `Mismatch action` 列为必须问用户项（E1:78-80/:219），但 transcript 只问了 Q1（Expected model/effort）就写入"21/21 字段"，Mismatch action 从未被问到。示例文本需补一问或注明并入 Q1。
- S9 Python 3.9 / 同目录 import 可行性核实为真但设计未写明机制：`python3 直跑脚本时脚本所在目录进 sys.path[0]`，故 `check_setup.py import init_project` 直跑可行；validate.py 的先例是显式 `sys.path.insert(0, str(LOOP_SCRIPTS))`（validate.py:32-34），design §7.2 顶部 `import check_setup` 因此同样可行。`from __future__ import annotations`（init_project.py:4）、`removeprefix` 3.9 下限（validate.py:173/:175）、`SKILL_DIR = parents[1]`（init_project.py:13-14）、exit 2 语义（verify_protocol.py:189）全部属实。建议 §4.6 补一句 sys.path 行为说明，防实现者画蛇添足。
- S10 边界场景补记（供实现轮写断言）：字段值恰好等于模板枚举提示（如原样抄 `codex | claude-code | other | unknown`）已被 §4.3 规则 (b) 正确判空；用户合法答案恰为枚举中单值（如 `unknown`）与完整枚举串不同、判 filled，语义正确。粗体标签（`**Label:**`）与表格对齐空格未在 §4.3 容差列表（"前导 #/-/空格"）中，本项目现有文件实测均为裸标签可解析（E9 21/21、24/24、12/12），但建议实现时容差纳入粗体与冒号前空格，避免用户手编文件后误判。

### 核实为真、无需修改的设计声明（对抗性检查通过项）

- 字段数 21（4+6+7+4）/ 29（3+3+5+5+4+4+5）/ 24（5+6+6+3+4）/ 12 逐行亲数吻合（E5）；容器行（Responsibilities:、Allowed when: 等）不计数规则与模板结构自洽。
- 全部行号引用属实：init:35/:90、status:20/22-28/34-55/59-63、continue:22/24-37/55-77（Safety Rules 末条 "failed adversarial review" 在 :90）、loop:69/:100/:114、Role And Model Rules 在 loop:381（E6）。
- 先例 5c35a22：新增 skill 未改 plugin.json skills 字段（目录通配 `["./skills/"]` / `"./skills/"` 属实）、4 处 version 同步、codex defaultPrompt 同步追加技能名——设计 §8.1/§8.3 的推断成立；`.agents/plugins/marketplace.json` 条目确无 version 字段（E8/E7）。
- findings 基线 17 条 CONFIRMED 属实（guided-setup 8 + auto-detection 9，E4）。
- 三档预设除 M3 一格外未发现违反协议硬约束；`Failed review acceptance` 三档不可关闭的标注正确。

### Acceptance Criteria 逐条判定

| # | goal.md 验收标准 | 判定 | 依据 |
| --- | --- | --- | --- |
| 1 | harnessloop-setup skill 存在且过 validate --strict | covered | §1.2/§7.3/§8.1；skills 目录通配与 validate_claude_strict 自动纳入经 E7/E8 核实属实；SKILL.md 全文属实现轮产物，设计层信息足够 |
| 2 | 五步流程（含三档预设、N/5 报告） | covered | §2/§3/§5 完整；三档 24 字段全量文本给出；N/5 文案在 §2.1/§2.2/§3.S5 |
| 3 | 每步可跳过且跳过必记 TODO 到 self-check | partial | 跳过→self-check TODO 语义本身完整（E1:205）；但与 AC6 的门实现互斥（M1）：跳过即锁死 continue/loop，"可跳过"承诺落空；须按 M1 修复后才算真覆盖 |
| 4 | check_setup 返回机器可读完整度 | partial | §4 接口/退出码/JSON/3.9 兼容完备且经 E10 复现基本可实现；但 §4.3 算法对重复标签无作用域定义（M2），29 槽位按现行文本不可无歧义实现 |
| 5 | status 输出 setup-incomplete 与缺什么/下一步 | covered | §6.2 state 枚举、setup completeness/next step 字段、Processing 步骤、Safety Rules 补丁齐备；与 status 只读原则基本自洽（S6 为像素级建议） |
| 6 | continue 门对 setup-incomplete 返回 needs-setup | partial | §6.3 机制齐备（decision 枚举、前置门、setup gate 字段、短路 Safety Rule）；但无条件短路与 §2.2 承诺矛盾且实测锁死本项目（M1），门条件须最小修复 |
| 7 | init 交接语指向 setup wizard | covered | §6.1 对 init:90 的 diff 精确（行号核实属实）；:35 语义重复已如实列入开放问题（§10.5） |
| 8 | loop SKILL:114 触发条件修正 | covered | §6.4 同时给出 :69（真实触发条件句）与 :114（ask-user 句）修正，并如实标注 goal.md 行号引用偏差（§10.1）；两处行号均核实属实 |

汇总：covered 5 / partial 3 / missing 0。三个 partial 全部收敛于 M1、M2 两处设计文本缺陷，均可最小修复，不需要推翻五步架构、check_setup 接口或接线方案。

## Feedback

negative

（设计轮语义：架构与绝大多数细节经对抗核查成立，但存在 M1-M3 三处必须先修复的设计缺陷——其中 M1 会在实现落地当轮锁死本项目自身的 continue 并使 goal Success Condition 不成立——修复量为设计文本级小改，符合"negative + 可最小修复"而非废弃重开。）

## Required Next Action

1. 设计者（或主会话）修订设计文档三处必须修复项：M1 门语义（短路条件收窄或 acknowledged 两级完整度，二选一需用户/主会话拍板，并同步修正 §2.2/§6.3/§6.4 与 §4.3 的 TODO=filled 条款）、M2 §4.3 补节作用域匹配规则、M3 lite 档 Evidence contract revision 条款对齐 evidence SKILL:31/:49。
2. 建议同批处理 S1-S10（尤其 S1 正则收紧、S4 thresholds/data-sources 的 7/7 文本连带更新计划、S5 表格槽位规则改写）。
3. 实现轮开工前由用户确认：M1 修复方案选型；本项目 data-sources.md External Tools 补 none 哨兵行（§10.2 方案 a）；lite 档最终措辞（goal.md Required Human Decisions 已列）。
4. 修订完成后主会话走查复核，方可开 0002 实现轮。
