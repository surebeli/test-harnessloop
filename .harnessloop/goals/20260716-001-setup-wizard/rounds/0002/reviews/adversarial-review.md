# Adversarial Review

## Review Scope

- Goal: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Round: 0002（设计修订轮复审；评审对象为 v2 设计稿，非实现代码）
- Scope lock: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/scope-lock.md
- Reviewer: 独立对抗性复审子代理（claude-fable-5，与 0001 轮评审同源、独立于 0002-01 修订者）
- Timestamp: 2026-07-16

评审对象：`rounds/0002/evidence/dynamic/setup-wizard-design-v2.md`（935 行）。复审语义：positive=可进入实现轮；negative=列必须修复项并按 scope-lock Rollback Condition 升级 human-decision-required。核对基线：`rounds/0001/reviews/adversarial-review.md`（M1-M3+S1-S10）、`rounds/0001/decision.md`（修复方向定案）。所有判定均对照 v2 正文验证，不采信 §0 变更表的自我声明。

## Evidence Used

| Evidence ID | Path | What it proves | Limitations |
| --- | --- | --- | --- |
| E1 | rounds/0002/evidence/dynamic/setup-wizard-design-v2.md | 被复审 v2 全文（行号引用以本文件为准） | — |
| E2 | rounds/0001/reviews/adversarial-review.md | M1-M3 + S1-S10 原始清单与判定依据 | — |
| E3 | rounds/0001/decision.md | 修复方向权威（:18-21 M1 双层门/M2 作用域/M3 对齐条款原文；:23-31 开放问题裁决） | — |
| E4 | harnessloop/plugins/harnessloop/skills/harnessloop-continue/SKILL.md:26/:88 | continue 第 1 步实际读取清单：current/control-contract/environment/evidence-index/**self-check**/self-audit/goal/round/handoffs/decision——用于证伪 v2 §4.4 理由文本 | — |
| E5 | harnessloop/plugins/harnessloop/skills/harnessloop-delegation/SKILL.md:19/:29 | `$harnessloop-delegation` 直接读取 `setup/cost-context-policy.md`（expected-model/effort 权威来源）与 `state/self-check.md`——用于评估 gate_blocking 三文件集合的实质依据 | — |
| E6 | harnessloop/plugins/harnessloop/skills/harnessloop-evidence/SKILL.md:31/:49；harnessloop-loop/SKILL.md:186/:428-430/:459-461 | M3 对齐目标的硬约束原文（round 0001 已核实，本轮复核未变） | — |
| E7 | goal.md、thresholds.md | 8 条 AC 与验收阈值 | — |
| E8 | round 0001 评审时的实测数据（模板字段亲数 21/29/24/12、cost-context-policy 重复标签行号 :11/:26-27/:55-58/:62-65、validate.py [N/7] 硬编码 7 处 :64/:110/:131/:206/:236/:290/:425、5c35a22 先例、本项目 5 文件 4/5 filled） | v2 中引用这些数字的段落逐一与实测比对 | 数据来自 0001 轮实测，模板/源码在两轮之间无变更（submodule HEAD 仍 66093fd） |

## Checks

| Check | Result | Evidence path | Notes |
| --- | --- | --- | --- |
| Goal alignment | pass | E1 §9、E7 | 8/8 AC 判定成立（v1 的 3 个 partial 经 M1/M2 修复转 covered，逐条复核见 Finding）；无新增范围蔓延 |
| Scope-lock compliance | pass | rounds/0002/scope-lock.md | v2 只写了允许的单文件；本复审只写本文件；v2 §7.1 对 scope-lock 外文件（thresholds.md 等）仅记录待办不修改，处理正确 |
| Data thresholds | pass | E1 §1.4、E8 | 17 条 findings 逐条处置表已补（S3 修复）；总数 17 与实测一致；但表格实际 covered 9 / oos 4 / deferred 4，汇总行误写 8/5/4（勘误 R3） |
| Verification thresholds | pass | E1 §7.2、§10.2、§10.4 | validate 断言 1-6 覆盖双层门正反例（断言 5 直接钉死 ANY 规则）；"本项目=complete"与 live-run 补哨兵的时序依赖已由 decision.md 裁决并在 §10.2 解耦说明；7/7→8/8 连带更新列为 Required Human Decision（S4 修复） |
| Runtime validation | pass | E1 §4.5、§4.6 | 设计轮无运行时面；退出码语义不变、`python3 -B` 零写入方案、3.9 兼容声明（新增正则构造在 3.9 可实现，无 3.10+ 特性）复核通过 |
| Source/source-data consistency | partial | E1:524/:292 vs E4、E5 | v2 §4.4/§3 的 gate_blocking 理由文本两处与源码不符：self-check.md 被称"非任何 continue 门的输入"——continue:26 第 1 步明确读取它（证伪）；cost-context-policy 被称 continue 的 delegation gate"直接读取的策略来源"——continue 自身不读它，实为经 continue 第 13 步路由的 `$harnessloop-delegation`（SKILL:19/:29）直接读取，"直接"一词失准（一跳间接成立）。其余源引用（行号、字段数、先例、[N/7] 位置）与 0001 轮实测全部吻合 |
| Drift or contradiction risk | partial | E1:237/:242-247 vs E1:524 | v2 新引入一处内部矛盾：§2.2 示例首段 JSON 写 `gate_blocking=false`，而该时点 control-contract.md=template，按 §4.4 规范定义（任一核心文件 template/missing 即 true）应为 **true**；同段解说自相矛盾（先说 false、又说"此刻跑 continue 会因 control-contract=template 被短路"——被短路即 true）。规范层（§4.4、§3、§6.3、§6.4、§7.2 断言 5、§2.1、§2.2 的 S5 段）全部一致采用 ANY 规则，意图无歧义，属示例段笔误（勘误 R1）；无规范层矛盾残留 |

## Finding

### 一、M1-M3 逐项判定

| 项 | v1 缺陷 | v2 修复情况 | 判定 |
| --- | --- | --- | --- |
| M1 | §2.2"不阻塞"与 §6.3 无条件短路矛盾；TODO 刷门静默；实测锁死本项目 | 双层门落地：`gate_blocking`（E1:524，三核心文件 template/missing 才 true）+ `todo_count`（E1:525）+ `complete` 保持严格语义（E1:526-527）；continue/loop 短路条件全部改用 gate_blocking（E1:722/:742/:783/:792/:806）；跳过后果按文件精确分层并要求 wizard 主动预告（E1:291-294/:349）；TODO 算 filled 但计入 todo_count 由 status 显性呈现（E1:488/:525），validate 断言 6 直接回归此行为（E1:857）；本项目场景（data-sources partial）明确不再阻断（E1:527/:916）。与 decision.md:18 方向吻合 | **已修复**（理由文本两处失实见勘误 R2，属叙述层非行为层） |
| M2 | 重复 leaf 标签无作用域，29 槽位不可无歧义求值 | 小节容器路径作用域匹配算法（E1:475-479：heading 切片→容器切片→切片内首匹配）；29/24/21/12 全部路径清单落盘（E1:416-471）；重复标签的路径去重标注（#2/#20/#24、#9/#18/#22、#10/#19/#23、#17/#21）与 0001 轮实测重复次数（cost-context-policy-template.md :11/:26-27/:55-58/:62-65）逐条吻合；90 槽位总数不变 | **已修复** |
| M3 | lite 档 Evidence contract revision 与 evidence SKILL:31/:49 冲突 | 四条件完整对齐（E1:609"当且仅当变更改变验收标准、降低验证门槛、扩大证据范围或影响续跑判定"），lite 宽松度收敛到四条件之外的维护性变更——evidence SKILL 对该区间本就不施加强制人工确认，无冲突；§2.1 transcript 的 lite 摘要同步更新（E1:204）；其余硬约束行（Failed review acceptance 三档需要、Rollback、Scope-lock mutation）复核与 0001 轮结论一致，未回退 | **已修复** |

### 二、S1-S10 逐项判定

| 项 | v2 处置 | 验证 | 判定 |
| --- | --- | --- | --- |
| S1 | 正则收紧为要求逐字 `(confirmed via setup wizard)`（E1:500） | 手工推演：匹配 §2.1/§3 的全部标准哨兵行（含斜体下划线、句号变体）；不再匹配 "no such tools declared yet, need review" / "No sources are declared in CI but..."（缺锚定短语）——0001 轮实测的两类假阳性均消除；`[^_\n]*` 对现有 4 个类别名（均无下划线）无误伤 | 已修复 <!-- verify:ignore --> （上句所引 `^_?\s*(?:No|None)\b[^_\n]*\(confirmed via setup wizard\)\.?_?\s*$` 为正则模式字符串引述，非文件引用） |
| S2 | §4.1 标题更正为 `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（E1:368），v1 笔误原文以引述形式保留并标注（E1:370） | 与 §1.2（E1:76）一致 <!-- verify:ignore --> （v1 笔误原文 `harnessloop-loop/skills/harnessloop-loop/scripts/` 为引述，非文件引用） | 已修复 |
| S3 | §1.4 新增 17 条逐条处置表（E1:88-112） | 总数 17 ✓、处置归类合理（#5/#7/#8/#11 的 out-of-scope 依据均可溯 goal.md；#14-#17 deferred 定性准确）；但汇总行"covered 8 / out-of-scope-by-goal 5 / deferred 4"与表格实际（covered 9：#1-4/#6/#9/#10/#12/#13；oos 4：#5/#7/#8/#11；deferred 4）不符——#6 标为"covered（setup 漏斗部分）"应计入 covered | 已修复（遗留计数勘误 R3） |
| S4 | §7.1 连带更新清单 + §10.4 + Required Human Decisions (c)（E1:841-846/:918/:933） | thresholds.md:15 与本项目 data-sources.md:16/:24 两处"7/7"均列出；正确识别其超出本轮 scope-lock、留待实现轮且需按 Threshold Change Policy 人工确认 | 已修复 |
| S5 | 排除规则改为"默认全部计入 + 显式所有权豁免清单"（E1:393-401） | 三张豁免表（Blocker Classification / Execution Delegation Matrix / Local Channel Parameters）各有归属理由，Local Channel Parameters 明确"即使模板原始行数为 0 也不计入"；规则与清单不再矛盾 | 已修复 |
| S6 | `sys.dont_write_bytecode = True` + `python3 -B`/`PYTHONDONTWRITEBYTECODE=1` 双保险（E1:586），status/continue/loop 三处调用 diff 均带 `-B`（E1:685/:742/:803），status Safety Rules 补丁同步（E1:712） | 逐处核对 diff 文本 ✓ | 已修复 |
| S7 | §8.2 更正为三处 0.7.0→0.8.0 + marketplace.json 0.1.0→0.8.0（E1:874-879） | 与 0001 轮 git show 实测一致 | 已修复 |
| S8 | §2.1 transcript 补 Q2 Mismatch action 问答（E1:146-151） | 21/21 写入前两问齐备 | 已修复 |
| S9 | §4.6 补 sys.path 机制说明（直跑 sys.path[0] / 被导入时沿用 validate.py:32-34 先例）（E1:585） | 与 0001 轮实测的 validate.py 导入机制一致 | 已修复 |
| S10 | §4.3 容差补粗体/冒号前空格（E1:485） | 基本修复；残留一个微小形态：`**Label:**`（冒号在粗体内侧）时，所示正则的值捕获会带尾部 `**`（`\**\s*:` 只容纳冒号前的星号），空字段会被误判非空。属实现级细节，§10.13 已强制 90 路径逐条单测，可在实现轮一并收口（勘误 R4） | 已修复（留一实现级注意项） |

### 三、主会话指定审查点：gate_blocking 三文件收窄的对抗性评估

**前提核对**：协调者转述"decision.md 定的方向是'任一文件 template/missing 即阻断'"与 decision.md 原文不符——decision.md:18 原文为"仅当 environment.md / control-contract.md / cost-context-policy.md **等核心文件**任一处于 template 或 missing 时才阻断 continue"，即决定本身就点名了这 3 个文件。v2 的三文件集合是对 decision.md 的忠实执行，**不构成对修复方向的偏离**；需要对抗性检验的是 v2 自己给出的理由是否站得住、以及该集合本身是否安全。

**(a) 理由逐文件核对（对照 continue:26 实际读取清单：current / control-contract / environment / evidence-index / self-check / self-audit / goal / round / handoffs / decision）**：

| v2 声称（E1:524） | 核对结果 |
| --- | --- |
| environment.md = environment gate 直接读取 | **属实**（continue:26） |
| control-contract.md = control gate 直接读取 | **属实**（continue:26） |
| cost-context-policy.md = delegation gate 直接读取的策略来源 | **失准**：continue 自身从不读取该文件；实际链路是 continue 第 13 步路由 `$harnessloop-delegation`，该 skill 第 1 步直接读取它且以其为 expected-model/effort 权威来源（delegation SKILL:19/:29）。"直接读取"应改为"经 `$harnessloop-delegation` 读取"——一跳间接依赖成立，纳入核心集合有实质依据，但理由原文经不起对照 |
| self-check.md"非任何 continue 门的输入" | **证伪**：continue:26 第 1 步明确读取 `state/self-check.md`；`$harnessloop-delegation`:29 也读取它；continue Safety Rules:88 亦引用"file-backed environment self-check"。排除它的正确理由不是"不被读取"，而是：(1) 它是 wizard S5 / loop 轮次的**输出记录**，template 状态仅意味着 S5 未跑完，continue 第 12 步的 ambiguity 询问已提供优雅降级；(2) TODO 认领台账正存放于其 Action 字段——若它自身 template 即阻断，认领机制会先于自身可用性死锁 |

**(b) 反例推演（fresh init 后只跑 S1/S3/S4、data-sources 全程未碰 = template 时放行 continue 是否安全）**：安全，且排除是必要的。

- 证据链核实：continue 的 evidence gate 读取 `state/evidence-index.md`（continue:26），不读 `setup/data-sources.md`——v2 此句属实；goal 级证据契约载体是 `goals/<id>/data-contract.md` + evidence-index，data-sources.md 是项目级源/渠道清单，不参与任何 continue 门的机械评估。
- 缺失时的兜底路径存在：goal/round 定义阶段的数据契约环节、修正后的 loop:114（"During setup, run $harnessloop-setup to fill in data-source connection requirements..."）都会把用户引回 wizard；status 持续显性提示 todo_count 与 missing_sections。
- 反向验证：若把 data-sources.md 纳入阻断集合，S2 的"整类跳过"（AC3 明文允许的合法路径）→ 文件保持 template → continue 锁死——v1 M1 死锁原样复活，AC3 与 AC6 再度互斥。因此排除 data-sources 不是宽松化，而是 AC3 成立的必要条件。

**(c) 裁决**：**接受三文件收窄（行为层），要求改写理由文本（叙述层，勘误 R2）**。

- 行为层：集合 {environment, control-contract, cost-context-policy} 与 decision.md:18 原文一致；environment/control-contract 有 continue 直接读取的机械依据；cost-context-policy 有经 `$harnessloop-delegation` 的一跳依赖 + "S3 展示式确认成本最低、阻断代价最小"的比例性依据；排除 data-sources/self-check 分别是 AC3 成立的必要条件与认领机制自洽的必要条件。回到全 5 文件会复活 M1，折中增删任一文件都比现状差（增 self-check 死锁认领台账；删 cost-context-policy 使委派策略永远可跳过而 delegation SKILL 的 expected 值无源）。
- 另需显式记录一处 decision.md 语义解释：decision.md:18 写"partial 且 self-check.md 有对应 TODO 记录时降级为警告"，对"partial 但无 TODO 认领"（如本项目现状——data-sources partial 系手工填写遗留，self-check 无对应 TODO）未言明；v2 将其解决为"任何 partial 一律不阻断、一律显性呈现"（E1:293/:527）。这是唯一能让本项目在 live-run 前不被锁死的解释，复审认可，但应在本轮 decision/round-summary 中记为"对 decision.md 未言明情形的解释"，避免日后被自审计误判为漂移。

### 四、v2 自报 4 个薄弱点的处置判定

| 薄弱点 | 判定 |
| --- | --- |
| goal.md 行号歧义（§10.1） | 处置可接受（两处均给 diff、差异如实标注）；但 decision.md:25 期望"goal.md 行号勘误待设计修订时一并订正"，而本轮 scope-lock 未把 goal.md 列入允许写入，v2 只能沿用标注——该订正仍悬置，需主会话在实现轮开工前经 `$harnessloop-goal update` 完成或在验收时按 §10.1 口径执行（勘误 R5，流程项非设计缺陷） |
| 两层嵌套局限（§10.13） | 处置得当：当前 5 个模板实测均为两层结构（0001 轮亲数佐证），且已强制实现轮为 90 条路径各写单测；不预先解决假设性未来结构符合最小设计原则 |
| todo_count 去重算法未落地（§4.4:525） | 可接受但需在实现轮收口：`todo_count` 不是任何门的输入（gate_blocking/complete 均不依赖它），误差只影响提示文案，不影响安全性；但"以 Action 条目计数为准"的匹配谓词（如何判定 leaf TODO 与 Action 条目"所指同一"）未定义。建议实现轮二选一：(i) 定义 Action 条目的规范引用格式（文件 + §4.2 路径）作为匹配键；(ii) 更简单——leaf TODO 数与 Action 条目数分开输出两个字段，彻底回避去重。二者均须有 §7.2 要求的单测 |
| 本项目 partial 现状（§10.2） | 处置正确：与门语义解耦（gate_blocking=false 不阻断）、补齐路径按 decision.md:26 定为用户 live 首跑；与 thresholds.md"本项目=complete"的时序关系成立（live-run 的 S2 会写入哨兵行，之后该阈值才可判） |

### 五、v2 新引入问题（勘误级，均无需设计决策、可从规范文本机械推导修正）

- **R1（本轮唯一实质新矛盾）**：§2.2 示例首段（E1:237）`gate_blocking=false` 与 §4.4 规范定义矛盾——该时点 control-contract.md=template，按 ANY 规则应为 `true`；随附解说（E1:242-247）前半句支撑 false、后半句（"此刻跑 continue 会因 control-contract.md=template 被短路"）支撑 true，自相矛盾。规范层全部一致（§4.4、§3:292、§6.3:742、§6.4:792、§7.2 断言 5、§2.1:124、§2.2 后段 :271），意图无歧义，属示例笔误。修正：E1:237 改 `gate_blocking=true`，E1:242-247 改为"gate_blocking=true——因 control-contract.md 仍为 template；此刻跑 continue 会短路 needs-setup；S4 选档写入后转为 false（见下文 S5 段）"。
- **R2**：§4.4:524 与 §3:292 的三文件理由改写（见审查点 (a) 表：self-check 句证伪必改；cost-context-policy 句加"经 `$harnessloop-delegation`"限定；补排除 self-check 的真实理由）。
- **R3**：§1.4:112 汇总计数改为 covered 9 / out-of-scope-by-goal 4 / deferred 4（或将 #6 明示为部分覆盖并单列）。
- **R4**：§4.3:485 容差正则对 `**Label:**`（冒号在粗体内侧）形态的值捕获缺陷，实现轮在单测中覆盖并剥离值首尾 `*` 即可。
- **R5**：goal.md AC8 行号勘误的订正动作悬置（见上表第一行），流程项。

以上五条均不含任何待决设计问题：R1/R3 可从 v2 自身规范文本推导唯一正确值，R2 可从 continue/delegation SKILL 原文推导，R4/R5 是实现轮/流程动作。据此不构成再开一轮设计修订的理由。

### 六、Acceptance Criteria 逐条判定（v2）

| # | 验收标准 | 判定 | 依据 |
| --- | --- | --- | --- |
| 1 | harnessloop-setup skill + validate --strict | covered | §1.2/§7.3/§8.1，与 0001 轮核实结论一致 |
| 2 | 五步流程（三档预设、N/5 报告） | covered | §2/§3/§5；三档 M3 后合规；transcript 含双层门展示（§2.2 首段需按 R1 勘误后作为 dry-run 参照） |
| 3 | 每步可跳过且跳过必记 TODO | covered | §3:290-294 统一语义：跳过永远合法且记 TODO；阻断与否由 gate_blocking 精确定义且 wizard 必须预告后果（:349）；S2/S5 类跳过实测路径不再锁死 |
| 4 | check_setup 机器可读完整度 | covered | §4 全节：路径化 manifest + 切片匹配算法可无歧义实现；gate_blocking/todo_count/complete 三信号语义边界清晰（:527） |
| 5 | status 输出 setup-incomplete 与缺什么/下一步 | covered | §6.2：state 枚举、setup gate/todo count/next step 字段、`-B` 零写入 |
| 6 | continue 门返回 needs-setup | covered | §6.3：短路条件=gate_blocking、警告放行路径显式定义、Safety Rule 双向表述（:783） |
| 7 | init 交接语指向 wizard | covered | §6.1：:90 + :35（已获批）双 diff |
| 8 | loop SKILL:114 触发条件修正 | covered | §6.4：:69/:114 双修正、行号差异如实标注、profiles 引用一并落地 |

汇总：**8/8 covered，0 partial，0 missing**（v1 三个 partial 全部消除）。

## Feedback

positive

（复审语义：M1-M3 全部真实修复且与 decision.md 方向一致，S1-S10 全部落实；gate_blocking 三文件收窄经对抗推演成立（行为层接受，理由文本按 R2 改写）；v2 新引入的 5 条问题全部为勘误级——包括唯一一处实质矛盾 R1（示例段与规范定义不符）——均可从规范文本机械推导修正，不含任何待决设计问题，不构成第三次设计修订轮的理由。设计已达可实现状态。）

## Required Next Action

1. 主会话在本轮收盘前对 v2 落笔勘误 R1-R3（scope-lock 0002 允许写 v2 文件；三条均为机械推导修正，主会话走查即可，无需再开独立复审）：R1 §2.2 示例 gate_blocking 值及解说、R2 §4.4/§3 三文件理由文本、R3 §1.4 汇总计数。
2. 在本轮 decision/round-summary 中显式记录："任何 partial 一律不阻断"是对 decision.md:18 未言明情形（partial 无 TODO 认领）的解释性裁定（见 Finding 三 (c)），防止自审计误判漂移。
3. R5：实现轮开工前经 `$harnessloop-goal update` 订正 goal.md AC8 行号引用（decision.md:25 遗留动作），或在验收记录中按 §10.1 口径注明。
4. 实现轮（round 0003）落地时执行 R4（`**Label:**` 形态单测）与 todo_count 去重谓词二选一方案（Finding 四第 3 行），连同 §7.2 六条断言、§10.13 的 90 路径单测一并交付。
5. 满足以上后可开 round 0003 实现轮；档位默认值最终措辞与 7/7→8/8 阈值文本同步仍按 Required Human Decisions 在验收时由用户确认。
