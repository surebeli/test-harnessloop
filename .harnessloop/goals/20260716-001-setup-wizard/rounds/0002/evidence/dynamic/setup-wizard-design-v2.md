# Setup Wizard 实现级设计文档 v2

- Goal: `.harnessloop/goals/20260716-001-setup-wizard/goal.md`
- Round: 0002（设计修订轮；本文档不改动 `harnessloop/` submodule、不改动 `rounds/0001/` 下任何文件）
- 本文档是 v1（`rounds/0001/evidence/dynamic/setup-wizard-design.md`）的**完整独立修订版**，非补丁；v1 原稿保留不动，审计链完整
- 修订依据：`rounds/0001/reviews/adversarial-review.md`（M1-M3 必须修复 + S1-S10 建议修复）、`rounds/0001/decision.md`（主会话修复方向定案）
- 需求依据：`docs/harnessloop-review-20260716.findings.json` 中 `lens: guided-setup`（8 条）/ `lens: auto-detection`（9 条）的 17 条 CONFIRMED 条目（逐条处置见 §1.4，纠正 v1 §1 的失实表述，S3）
- 格式权威：`harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/` 模板目录（submodule HEAD `66093fd`）

## 记法说明：verify:ignore 豁免语法

`verify_protocol.py` Rule B（悬空引用检测）正在并行修复已知缺陷 nm11（见 `.harnessloop/meta/evolution-issues/0006-verify-protocol-pathish-false-positives.md`，TH-0006，状态 open）：修复落地后将支持正则/glob 元字符豁免、submodule 根路径解析、URL 豁免、以及显式 `<!-- verify:ignore -->` 注释豁免语法。本文档中凡引用**正则模式字符串本身**（如哨兵行判定正则）或**笔误路径的原文引述**（如 v1 标题笔误示例），均不是真实文件引用，属于 TH-0006 覆盖的豁免场景；在下方对应位置以 `<!-- verify:ignore -->` 标注，供 nm11 修复落地后的 `verify_protocol.py` 识别。修复落地前，`rounds/0002/scope-lock.md` 已将这类已归档误报类别排除在本轮机械门判定之外。

---

## 0. 版本说明（v2 相对 v1 的变更）

| 变更 ID | 类别 | v1 问题 | v2 修复 | 涉及章节 |
| --- | --- | --- | --- | --- |
| M1 | 必须修复 | §2.2"跳过不阻塞"与 §6.3 无条件短路自相矛盾；字面 `TODO` 值可零成本刷穿完整度门；实测锁死本项目自身 continue | 双层门：`check_setup` 新增 `gate_blocking`（仅 3 个核心文件 template/missing 时为真）与 `todo_count`（显性呈现，消除静默）；continue/loop 短路条件改用 `gate_blocking` 而非 `complete` | §2.2、§4.4、§6.2、§6.3、§6.4、§9 |
| M2 | 必须修复 | §4.3 判定算法对 cost-context-policy 模板重复 leaf 标签（如 `Core decisions:` ×3）未定义匹配作用域，29 槽位不可无歧义求值 | 匹配改为"小节容器路径"作用域：manifest 条目携带完整 heading path，匹配限定在该 heading 到下一同级/更高级 heading（或容器行到下一容器行）之间；给出 29 条完整路径清单 | §4.2、§4.3 |
| M3 | 必须修复 | lite 档 "Evidence contract revision: 不需要，除非改变验收标准的实质含义" 与 harnessloop-evidence SKILL:31/:49 的硬性人工确认约束冲突 | lite 档措辞对齐 evidence SKILL 四条件（验收标准变更/降低验证门槛/扩大证据范围/影响续跑判定），四条件命中一律需要人工确认，档位不可关闭该约束 | §5.2 |
| S1 | 建议 | none 哨兵正则 `^_?\s*(no|none)\b.*declared.*_?$` 假阳性（"no such tools declared yet, need review"类叙述句被误判为已确认） | 收紧为要求固定字面短语 `(confirmed via setup wizard)` | §4.3 |
| S2 | 建议 | §4.1 标题笔误 `harnessloop-loop/skills/harnessloop-loop/scripts/check_setup.py` | 更正为 `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py` | §4.1 |
| S3 | 建议 | §1"17 条逐条覆盖见第 9 节"失实（第 9 节只是 8 条 AC 对照表） | 更正表述；新增 17 条 findings 逐条处置表（covered / out-of-scope-by-goal / deferred） | §1.4 |
| S4 | 建议 | `[N/7]→[N/8]` 重编号未提示连带更新：`thresholds.md:15`、本项目 `setup/data-sources.md:16/:24` 的"7/7"文本会过期，且该变更按 Threshold Change Policy 需人工确认 | §7.1 补充连带更新清单；新增至 Required Human Decisions | §7.1、§10 |
| S5 | 建议 | 表格槽位排除规则文本（"原始模板数据行数为 0 才计入"）与实际排除的 Local Channel Parameters 表（原始行数同样为 0）自相矛盾 | 排除规则改写为"默认全部计入，仅显式所有权豁免清单排除"，给出三张豁免表及各自的归属理由 | §4.2 |
| S6 | 建议 | `check_setup.py import init_project` 在脚本目录可写时可能生成 `__pycache__/*.pyc`，与 status 的"零写入"字面表述有像素级缝隙 | 明确 status/continue 调用时使用 `python3 -B`（或 `PYTHONDONTWRITEBYTECODE=1`），并在脚本内设 `sys.dont_write_bytecode = True` | §4.6、§6.2 |
| S7 | 建议 | §8.2 先例叙述失实："四处从 0.7.0 统一提升"，实际 `.claude-plugin/marketplace.json` 原值为 0.1.0 | 更正为：三处 0.7.0→0.8.0，`.claude-plugin/marketplace.json` 插件条目 0.1.0→0.8.0 | §8.2 |
| S8 | 建议 | §2.1 首跑 transcript 只问了 Expected model/effort，未问 Mismatch action，但结论写"21/21 字段" | 补一轮 Mismatch action 问答 | §2.1 |
| S9 | 建议 | §4.6 未说明"同目录 `import init_project`"为何在 3.9 下可行 | 补充 sys.path 机制说明，引用 `validate.py:32-34` 先例 | §4.6 |
| S10 | 建议 | §4.3 判定容差未覆盖粗体标签（`**Label:**`）与冒号前多余空格 | 补入容差规则 | §4.3 |
| 追加 1 | 主会话批准纳入 | v1 §10 列为"待确认是否本批处理"的四项 | 版本 bump 0.11.0、codex `defaultPrompt` 追加 `$harnessloop-setup`、`harnessloop-init:35` 同步修正、`control-contract-profiles.md` 在 loop SKILL.md 的引用行——均已获批准，移入正式接线/AC 范围 | §6.1、§6.4、§8.3、§9 |
| 追加 2 | 吸收 nm11/TH-0006 | — | 引用 `verify_protocol.py` 悬空引用豁免语法进展；v2 中的正则/笔误引述统一标注 `<!-- verify:ignore -->` | 本文档开头记法说明、§4.3、§10 |

---

## 目录

1. 概述
2. 用户旅程（首跑 / 重跑对话示例）
3. 五步详细设计
4. check_setup 规则与接口
5. 三档预设完整内容（lite / standard / strict）
6. 接线点精确 diff 方案
7. validate.py 新断言清单
8. plugin.json / marketplace.json 处置
9. Acceptance Criteria 覆盖对照表
10. 风险与开放问题

---

## 1. 概述

### 1.1 问题

`docs/harnessloop-review-20260716.findings.json` 中 guided-setup（8 条）/auto-detection（9 条）共 17 条 CONFIRMED 发现共同指向一个缺口：`$harnessloop-init` 产出 12 个空模板文件后，**没有任何 skill 环节主动驱动逐项填写**。根因链：

```
harnessloop-init/SKILL.md:90 交接语只提 goal，不提 setup
  → harnessloop-loop/SKILL.md:69 "If .harnessloop/ does not exist" 为假（目录已存在）
    → :114 唯一的填表指令（"ask the user to fill in data-source connection
       requirements"）不可达，且只覆盖 data-sources 一项
      → control-contract（24 个策略字段）、cost-context-policy（29 个字段）、
        environment（21 个字段，且几乎全部可自动检测）均无人问津
        → status 无法报告"缺什么"，continue 无法识别"setup 未完成"这一状态
```

### 1.2 方案总览

四个交付物，边界如下：

| 交付物 | 位置 | 性质 |
| --- | --- | --- |
| `harnessloop-setup` skill | `plugins/harnessloop/skills/harnessloop-setup/SKILL.md`（新） | 纯对话驱动的五步向导，机械脚本背书 |
| `check_setup.py` | `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（新，理由见 §4.1） | 机械判定 5 个 setup/state 文件的完整度，并输出双层门信号（`gate_blocking`/`todo_count`），供 wizard/status/continue/loop 共用 |
| 四处接线 | init / status / continue / loop 四份 `SKILL.md` | 文本级 diff，见 §6 |
| `control-contract-profiles.md` | `harnessloop-loop/references/`（新） | lite/standard/strict 三档完整预设内容，供 wizard S4 引用；已获批准在 loop SKILL.md 增加一行引用（§6.4） |

### 1.3 范围边界（复述 goal.md Non-Goals，防止设计蔓延）

- 不改 intake 流程。
- 不做 data-sources 的 repo 自动扫描（`.github/workflows`、`package.json` 等扫描是后续增强，本设计只做"会话内可观察事实"的自动检测，即环境/委派能力，不做仓库内容扫描）。
- 不重构 loop SKILL 全文，只改 :69 和 :114 两处直接相关语句（另加 §6.4 批准的 profiles 引用行）。
- 不重生成 `examples/mock-project`。
- 不改证据枚举（`evidence-index-template.md` 结构不变）。

### 1.4 17 条 CONFIRMED 发现逐条处置表（修正 v1 S3 失实表述）

v1 §1 声称"逐条覆盖见第 9 节"，经评审核实为失实——原第 9 节只是 8 条 acceptance criteria 对照表，与 17 条 findings 并非一一对应。以下是 17 条 CONFIRMED 发现的逐条处置，`covered` = 本设计已处置，`out-of-scope-by-goal` = goal.md Non-Goals 或范围边界明确排除，`deferred` = 真实缺口但不在本 goal 的四个接线点/五步范围内，留作后续独立任务：

| # | Lens | 发现摘要 | 处置 | 依据/章节 |
| --- | --- | --- | --- | --- |
| 1 | guided-setup | init 后 12 个空模板无人认领；loop:69 短路条件使 :114 填表指令不可达 | covered | §3、§6.4 |
| 2 | guided-setup | 全协议无 `setup-incomplete` 状态，status/continue 无法报告"缺什么" | covered | §6.2、§6.3 |
| 3 | guided-setup | `environment.md` 要求记录检测结果，但无环节指示自动检测填写 | covered | §3 S1 |
| 4 | guided-setup | control-contract 无初始确认环节驱动，continue 门评估空契约 | covered | §3 S4、§5 |
| 5 | guided-setup | 第一个 goal 无引导式访谈（init 交接语只指向 `$harnessloop-loop`，不指向 `$harnessloop-goal propose`） | out-of-scope-by-goal | goal.md 未列为 acceptance criteria；本设计只改 init 交接语指向 `$harnessloop-setup`（§6.1），不涉及 goal 访谈流程重构（Non-Goals 相邻但非本条） |
| 6 | guided-setup | askuserquestion 强制点集中在中期阻塞路径，setup 漏斗零覆盖 | covered（setup 漏斗部分） | 五步设计全程使用 `AskUserQuestion`（§3）；init 自身 `--force` 确认分叉的 askuserquestion 化不在本设计范围 |
| 7 | guided-setup | init 产出报告未按"需用户输入/可自动填/自然产生"分层 | out-of-scope-by-goal | 不在 goal.md 8 条 AC 或 4 个接线点内；本设计只改 init 的 `Next recommended prompt` 一行（§6.1） |
| 8 | guided-setup | 填表时无 `examples/mock-project` 参照引导 | out-of-scope-by-goal | goal.md Non-Goals 明确"不重生成 mock-project"；且 mock-project 已知结构落后当前模板，本设计明确排除其作为参照（§7.2） |
| 9 | auto-detection | init 后无引导式逐文件补全流程 | covered | 整个 `harnessloop-setup` skill 即为该流程 |
| 10 | auto-detection | `environment.md` 字段几乎全可自动检测，却无自动填充步骤 | covered | §3 S1 |
| 11 | auto-detection | `data-sources.md` 完全靠手填，无 repo 扫描候选 | out-of-scope-by-goal | goal.md Non-Goals 明确"不做 data-sources 的 repo 自动扫描" |
| 12 | auto-detection | control-contract 无 lite/standard/strict 预设档位 | covered | §5 |
| 13 | auto-detection | `self-check.md` 字段机械可计算，却无脚本计算 | covered | §4（check_setup.py） |
| 14 | auto-detection | `cost-prices.json` 无引导创建 | deferred | 不在五步范围或 4 个接线点内；与 `round_cost.py` 定价文件相关，独立于 setup wizard |
| 15 | auto-detection | `init_project.py` 不检测目标项目是否为 git 仓库 | deferred | 不在五步范围；goal.md Non-Goals 未明确排除但也未纳入，留作独立 P2（同 v1 §10 风险 10） |
| 16 | auto-detection | 脚本直跑路径（`init-project.sh`）结束后零后续指引 | deferred | 低优先级 polish，与 #7 同类，可合并后续处理 |
| 17 | auto-detection | `init-project.sh` 使用裸 `python`，无解释器版本预检 | deferred | 独立 DX 修复，与 setup wizard 无直接关系 |

covered 8 / out-of-scope-by-goal 5 / deferred 4，合计 17，与 findings.json 实数一致。

---

## 2. 用户旅程

### 2.1 首跑路径（骨架项目，5 个文件均为 `template` 状态）

```
用户: $harnessloop-setup

Agent: 运行 check_setup.py --project . --json →
       complete=false, filled=0/5, gate_blocking=true（environment/control-contract/
       cost-context-policy 均为 template）, todo_count=0。
       这是一次全新 setup。我会走 5 步：环境检测 → 数据源 → 成本/上下文策略
       → 控制契约档位 → 汇总。每步都可以跳过，跳过的项会记为 TODO。

       [S1/5 环境检测]
       我在这次会话里能直接观察到（无需你确认，均标注 provenance=detected）：
         - Detected environment: claude-code（检测依据：系统提示声明模型 claude-sonnet-5）
         - Available tools: Agent 工具（子代理，支持 model 参数）、Bash、Read/Write/Edit
         - Delegation mechanism: subagent（Agent 工具）
         - Observed model: claude-sonnet-5（系统提示自证）
       以下无法在会话内零成本确认，需要你回答：
         - Expected model/effort（成本策略期望值，通常来自 cost-context-policy）
         - Mismatch action（模型不符时怎么办）

       [AskUserQuestion]
       Q1: 这次委派的目标模型/effort 期望是什么？
           选项: (a) 与主会话一致  (b) 自定义  (c) 暂不确定，标记 TODO

用户: (a)

Agent: 记下 Expected model/effort = 与主会话一致（provenance=user-confirmed）。
       Q2: 如果后续委派实际观察到的模型/effort 与期望不符，你希望怎么处理？
           选项: (a) 回退主会话执行  (b) 仅记录不阻断  (c) 停下来问你

用户: (a)

Agent: 记下 Mismatch action = 回退主会话执行（provenance=user-confirmed）。
       已写入 state/environment.md（21/21 字段，provenance 标注见文件）。
       [S1/5 完成] → 进入 S2。

       [S2/5 数据源引导]
       逐类询问，你可以对任意一类回答"没有"：
       Q3: Static Sources（真实静态数据，如样本文件/CSV/schema）——这个项目有吗？
           访问方式？验证方法？

用户: 有一个 docs/harnessloop-review-20260716.findings.json，本地文件读取，
      用 JSON 结构校验。

Agent: 记下。
       Q4: Dynamic Or Generated Sources（动态/生成数据）——有吗？

用户: 没有。

Agent: 好，写入 "_No dynamic or generated sources declared for this project
       (confirmed via setup wizard)._" 哨兵行，check_setup 会把这类识别为"已回答"
       而非"未触碰"（正则锚定固定短语 `(confirmed via setup wizard)`，不会误吃
       普通叙述句，见 §4.3 S1 修复）。
       Q5: Runtime Validation Systems（跑测试/验证的命令）——有吗？

用户: npm run validate（仓库根）。

Agent: 记下，验证方法="8 阶段全绿"（本批新增 check_setup 断言使 validate 阶段数由
       7 变为 8，见 §7.1；若你的项目验证阈值文档写死了"7/7"，这次也需要你确认更新）。
       Q6: External Tools And Platforms（CI、数据库、第三方 API 等）——有吗？

用户: 没有外部账号需求。

Agent: 写入 none 哨兵行。
       [S2/5 完成，4/4 类已回答] → 进入 S3。

       [S3/5 Cost And Context Policy 默认值]
       这是协议给出的默认策略（非项目事实，是你可确认/修改的策略选择）：
         - Main session: 编排、核心决策、最终验收
         - 不得占用主会话上下文: 大段原始日志、完整外部报告、重复源码摘录
         - 委派: 只读发现/证据收集/低风险实现/对抗性评审/验收测试 可委派；
           目标解释/breakdown 审批/scope-lock 变更/业务决策/失败评审后接受 不可委派
         - Codex: 优先 gpt-5.5 中等推理；Claude Code: 优先 swarm/subagent + Sonnet
           高/超高推理
       是否按默认值写入，还是需要调整？

用户: 按默认值。

Agent: 已写入 setup/cost-context-policy.md（29/29 字段，按 §4.2 的小节容器路径
       写入，Model Policy 下 Codex/Claude Code 两组各自独立写满，不互相覆盖）。
       → 进入 S4。

       [S4/5 Control Contract 档位选择]
       三档预设（完整内容见 references/control-contract-profiles.md）：
         - lite: 个人/低风险项目，positive 或 runtime-recoverable 类调查自动续跑，
           仅外部写/失败评审接受/证据契约实质变更需人工
         - standard（默认）: positive 且证据全 valid 时自动续跑，evidence/control
           契约变更需人工
         - strict: 涉外部系统/敏感数据，即使条件全满足仍需人工确认才续跑
       选哪档？

用户: standard。

Agent: 展示 diff（当前 control-contract.md 是全空模板 → standard 档 24/24 字段）后写入。
       → 进入 S5。

       [S5/5 汇总]
       重新运行 check_setup.py --json →
       complete=true, filled=5/5, gate_blocking=false, todo_count=0。
       写入 state/self-check.md：
         Setup files present: pass（5/5 filled）
         Environment policy recorded: pass
         Control contract recorded: pass（standard 档）
         ...
         Action: setup 完成，无 TODO。
         Last checked: 2026-07-16

       Setup 完成度: 5/5。setup gate: complete（不阻塞、无警告）。
       下一步: 使用 $harnessloop-goal propose 起草第一个 goal，或
       $harnessloop-loop 进入主协议。
```

### 2.2 重跑 / 审阅路径（部分已填的项目，双层门生效）

```
用户: $harnessloop-setup

Agent: 运行 check_setup.py --project . --json →
       complete=false, filled=2/5, gate_blocking=false, todo_count=0
       (environment.md=filled, cost-context-policy.md=filled,
        data-sources.md=partial[missing: External Tools And Platforms],
        control-contract.md=template, self-check.md=template)

       注意：gate_blocking=false——因为 3 个核心文件（environment/control-contract/
       cost-context-policy）里只有 control-contract.md 处于 template，其余两个已 filled；
       按双层门规则（见 §4.4），只要 environment/control-contract/cost-context-policy
       任一为 template/missing 就会短路 continue/loop 为 needs-setup，所以此刻若你去跑
       $harnessloop-continue，会因 control-contract.md=template 被短路（这是"核心策略
       未建立"，不是"跳过被惩罚"）。

       这是审阅模式：已完成 2/5，我只补缺口，不会重问已填项。

       [S1] environment.md 已 filled，跳过。
       [S2] data-sources.md 部分已填。已有 Static/Dynamic/Runtime 三类记录；
            只缺 External Tools And Platforms 一类。这个项目有外部工具/平台吗？

用户: 跳过，还没想好。

Agent: 记为 TODO。写入 self-check.md 的 Action 字段:
       "TODO (owner: user): S2 data-sources External Tools And Platforms 未确认，
        setup wizard 2026-07-16 跳过。"
       这一项跳过**不会**让 continue/loop 短路——data-sources.md 不在 gate_blocking
       的核心文件集合里，partial 只会被 status/continue 显性标记为警告
       （todo_count 会 +1），不阻断执行。
       [S3] cost-context-policy.md 已 filled，跳过。
       [S4] control-contract.md 仍是原始模板，需要选择档位。三档见 references/
            control-contract-profiles.md，选哪档？

用户: lite。

Agent: 展示 diff（全空 → lite 档 24/24 字段）后写入。
       [S5] 重新运行 check_setup.py --json →
       complete=false, filled=4/5, gate_blocking=false（3 个核心文件现在全部 filled），
       todo_count=1。
       汇总:
       Setup 完成度: 4/5（filled 文件计数；data-sources.md 因跳过一类仍算 partial）。
       setup gate: warning（1 项已确认的 TODO，不阻塞）。
       Action: "1 项 TODO 待补：S2 External Tools And Platforms（owner: user）"
       下一步: 该 TODO 不阻塞 $harnessloop-loop/$harnessloop-continue（gate_blocking=false，
       三个核心策略文件均已建立）；下次 $harnessloop-status 会持续显性提示
       todo_count=1，直到你回来补答。
```

---

## 3. 五步详细设计

通用规则（跨全部 5 步）：

- **展示现状 → 提议 → 用户确认/修改/跳过** 是唯一交互模式；不得先写入再询问。
- 每个 agent 自动填的值必须标注 provenance：`detected`（会话内零成本可观察）/ `user-confirmed`（用户对提议的确认或修改）/ `default-accepted`（用户接受协议默认策略而未定制）。写法是在字段值后追加 `(detected)` / `(user-confirmed)` / `(default-accepted)`，不改变字段本身的可解析性（check_setup 的空白判定看的是冒号后是否有内容，不受后缀影响）。
- 跳过 = 不写入该字段的编造值；改为在 `state/self-check.md` 的 `Action` 字段追加一条 `TODO (owner: user): <step> <what> — skipped at setup wizard on <date>`。字段本身留空（模板原状），使 check_setup 能如实识别为未完成。
- **跳过的实际后果由双层门决定，而非"一律不阻塞"或"一律阻塞"**（吸收 M1 修复）：
  - 若跳过发生在 `state/environment.md`、`state/control-contract.md`、`setup/cost-context-policy.md` 三者之一，且导致该文件仍处于 `template`（一个字段都没填）——`gate_blocking=true`，continue/loop 会短路为 `needs-setup`，用户必须回来完成该文件才能推进业务执行。这不是"跳过被惩罚"，而是这三个文件代表 continue 自身的 control/environment/delegation 门所依赖的核心策略，未建立时门本来就无法评估。
  - 若这三个核心文件已至少部分建立（不再是 `template`，哪怕不是 100% `filled`），或者跳过发生在 `setup/data-sources.md`/`state/self-check.md`——`gate_blocking=false`，不阻断，只在 `todo_count` 与 `missing_sections` 里显性呈现，供 status/wizard 持续提示。
  - 因此"每步可跳过"的真实语义是："跳过永远合法且被记录；跳过是否阻断后续执行，取决于被跳过的字段是否属于三个核心策略文件里唯一决定该文件从 `template` 状态解脱的那一部分"。wizard 在建议用户跳过 S1/S3/S4 时，应主动提示"这一步跳过会让 environment/control-contract/cost-context-policy 保持空白，继续会被 continue 短路"；建议用户跳过 S2 的具体类别时，应提示"这类跳过不会阻断，只会持续提醒"。
- 涉及凭证/密钥的字段：wizard 自身不接收、不写入任何密钥值；一旦用户表示某数据源/工具需要凭证，转交 `$harnessloop-secrets add channel <id> key <NAME> --sensitivity secret --storage <...>`，`data-sources.md` 里只记参数名/存储方式，不记值。
- 幂等：wizard 每次调用先跑 `check_setup.py --json`。若 `complete: true`，直接报告"已完整，5/5"并停止（不重复提问）。若部分完整，进入审阅模式：`state == filled` 的文件整段跳过（仅报告一行"已完整，跳过"）；`state == partial` 的文件只问 `missing_sections` 里列出的缺口；`state == template` 或 `missing` 的文件走完整首跑对话。

### S1 环境自动检测 → `state/environment.md`

对照 `environment-self-check-template.md` 的 4 个小节、21 个字段（完整路径清单见 §4.2）：

- **可自动检测（provenance=detected，零成本，来自本会话可观察事实）**：
  - `Detection` 全部 4 个字段：Detected environment（来自系统提示/运行时标识）、Detected from、Available tools（当前会话工具枚举）、Unavailable tools。
  - `Delegation` 的 `Expected mechanism`/`Observed mechanism`（Agent/Task 工具是否存在）。
  - `Model And Effort` 的 `Observed model`（系统提示自证的模型 ID）。
  - `Result` 的 `Last checked`（当前时间戳）。
- **需要一次委派探针才能验证（不得凭空声称）**：`Can create independent task` / `Can constrain read/write scope` / `Can require output path` / `Can verify evidence citations` 四项。wizard 若在本会话内已有过一次真实委派，可引用该次委派的实际产出作为证据（provenance=detected，附引用路径）；若没有可引用证据，如实写 `unknown`，不得推断为 `pass`。**局限如实记录**：委派探针只能验证"这次委派做到了什么"，不能验证"每次都会做到"，`Residual risk` 字段必须写明这一点。
- **必须问用户（provenance=user-confirmed 或 default-accepted）**：`Expected model`/`Expected effort/reasoning`（来自 S3 定的 cost-context-policy，若 S3 未跑则先问）、`Mismatch action`（§2.1 transcript 已补此问答，S8 修复）。
- **写死值**：`Verification method` 写实际使用的检测方式（如"系统提示自证 + 一次委派探针"），不得写"未执行"这类占位（除非确实没有委派证据）。
- 跳过：只允许跳过 `Expected model/effort` 与 `Mismatch action`（其余是零成本检测，没有"跳过"的意义，若确实检测不到就如实写 `unknown` 并非"跳过"）。跳过时记 TODO；因 `state/environment.md` 属于 gate_blocking 三文件之一，若跳过导致该文件仍是全空 `template`，会短路 continue/loop（见通用规则）。

### S2 data-sources 引导 → `setup/data-sources.md`

按 4 类分别问（不含 `Local Channel Parameters`——那张表由 `$harnessloop-secrets` 管理，不由 wizard 直接询问填写；也不含 `Secret Handling` 说明段——协议固定文案，非用户输入；排除理由见 §4.2 的"所有权豁免清单"，S5 修复）：

1. **Static Sources**：真实静态数据源。逐个问：来源、访问方式、新鲜度要求、漂移风险、验证方法、凭证需求。
2. **Dynamic Or Generated Sources**：动态/生成数据。同上字段（用 Generator/tool 代替访问方式）。
3. **Runtime Validation Systems**：跑测试/验证的命令或系统。问：访问方式、验证方法、通过条件、失败处理、凭证需求、本地参数引用。
4. **External Tools And Platforms**：CI、数据库、第三方 API、账号体系。问：用途、读写范围、账号角色、验证方法、失败处理、本地参数键名。

每一类允许回答"没有"；回答"没有"时，wizard 必须在该表下方写入固定哨兵行（**紧格式**，check_setup 的正则依赖固定字面短语，S1 修复）：

```
_No <category> declared for this project (confirmed via setup wizard)._
```

`<category>` 用该类别的模板小节标题小写形式（如 `dynamic or generated sources`）。哨兵行必须逐字包含 `(confirmed via setup wizard)`——这不是风格要求，而是 §4.3 判定正则的匹配锚点；缺少这个固定短语的其它"没有"表述（如"目前没有想好""暂不确定"）不会被判定为已确认，会继续显示为未填。

若某数据源提到需要凭证：不在本文件记录任何值，转交 `$harnessloop-secrets`；本文件对应行的"Credential requirement"列只记参数名/是否需要，格式与既有约定一致。

跳过：允许对任意一类整体跳过（不问、不写哨兵行），此时该类保持模板原状（0 行），并在 self-check.md 记 TODO。因 `setup/data-sources.md` 不在 gate_blocking 的核心文件集合内，此类跳过**不会**短路 continue/loop，只会计入 `todo_count` 并在 status 中持续显性提示。

### S3 cost-context-policy 默认值展示与确认 → `setup/cost-context-policy.md`

不是询问式，是**展示式**：把协议 `Role And Model Rules`/`Core Contract` 里已经写死的默认策略（Main Session 职责、不得占用上下文的三类、可委派/不可委派清单、Codex/Claude Code 模型偏好）渲染成 `cost-context-policy-template.md` 的 29 个字段值，一次性展示给用户确认或点名修改。这不是虚构项目事实——协议自身的 `Role And Model Rules` 一节就是这些默认值的来源（可引用 `harnessloop-loop/SKILL.md:381-422` 作为出处）。

**写入时必须按小节容器路径分别落位**（M2 修复，防止重复标签互相覆盖）：`Model Policy > Codex > Core decisions` 与 `Model Policy > Claude Code > Core decisions` 是两个独立槽位，`Main Session > Responsibilities > Core decisions` 是第三个独立槽位；三者分别取自协议默认值的不同来源（Main Session 的来自 `Core Contract`，Codex/Claude Code 的分别来自 `Role And Model Rules` 里对应模型的分段描述），不得三处写同一句话了事。完整 29 条路径清单见 §4.2。

不覆盖的部分：`Execution Delegation Matrix` 表（8 行 Decision 列本就是模板自带的协议级预填内容，非本步骤的问答对象，直接原样写入不算"用户输入"；排除理由见 §4.2 所有权豁免清单）。

用户确认路径：全部接受（provenance=default-accepted）或逐项修改（provenance=user-confirmed）。跳过：整节跳过则该文件保持模板原状，记 TODO；不支持部分字段跳过（29 个字段一次性展示，逐项确认/修改的交互粒度已经足够低摩擦，不需要更细的跳过语义）。因 `setup/cost-context-policy.md` 属于 gate_blocking 三文件之一，若跳过导致该文件仍是全空 `template`，会短路 continue/loop。

### S4 control-contract 档位选择 → `state/control-contract.md`

1. 展示三档摘要（完整内容见 §5，运行时引用 `references/control-contract-profiles.md`）。
2. `AskUserQuestion` 单选：lite / standard / strict。
3. 选定后，生成"当前文件（模板原状或已有内容）→ 该档位完整内容"的 diff，展示后再写入（不静默覆盖）。
4. 若这是重跑且文件已部分手填（不太可能，因为这是唯一没有"部分回答"概念的步骤——24 个字段要么整档套用要么维持原样），仍先展示 diff。
5. 跳过：不选档位，文件保持原状，记 TODO；下次重跑视为 `template` 状态重新进入本步骤。因 `state/control-contract.md` 属于 gate_blocking 三文件之一，跳过会使该文件保持 `template`，短路 continue/loop——这是双层门里**最容易被用户实际触发**的短路场景，wizard 在此步的跳过确认提示必须显式说明这一后果（不能只说"记为 TODO"，要说"这会让 continue/loop 在你回来选档之前一直返回 needs-setup"）。

### S5 汇总 → `state/self-check.md`

1. 重新跑一次 `check_setup.py --project <target> --json`（S1-S4 写入后的最终态），读取 `complete`/`filled`/`total`/`gate_blocking`/`todo_count`/`next_step`。
2. 按 `self-check-template.md` 的 12 个字段填值：
   - `Setup files present`: pass/partial + 本次 5 文件的 filled 计数。
   - `Environment policy recorded` / `Control contract recorded` / `Evidence index recorded` / `Self-audit present` / `Runtime validation described` / `Data/tool access described` / `Local channel parameter store protected` / `Delegation model verified` / `Intake gate required`：分别引用 S1-S4 的产出状态（`Evidence index recorded`/`Self-audit present`/`Intake gate required` 不属于 wizard 五步范围，如实写"不适用于 setup 阶段，由 loop 首轮维护"或按现状读取，不得凭空写 pass）。
   - `Action`: 若全部完成写"setup 完成，无 TODO"；否则列出每条 TODO（含 owner、跳过的具体子项、时间戳），且明确标注每条 TODO 是否会导致 `gate_blocking=true`（即是否属于三个核心文件的 template 状态）。
   - `Last checked`: 当前时间戳。
3. 输出对用户可见的完成度：`Setup 完成度: N/5`（N = check_setup 报告的 `filled` 计数）+ `setup gate: complete | warning (todo_count: K) | blocking`，并给出下一步：
   - `N == 5`（等价于 `gate_blocking=false` 且 `todo_count=0`）：建议 `$harnessloop-goal propose <一句话目标>` 或 `$harnessloop-loop`。
   - `N < 5` 且 `gate_blocking=false`：列出仍缺的具体文件+缺口，声明"不阻塞 continue/loop，下次运行 $harnessloop-setup 会自动进入审阅模式，只问剩余项"。
   - `gate_blocking=true`：明确指出哪个核心文件仍是 `template`/`missing`，声明"continue/loop 在此文件补齐前会返回 needs-setup"。

---

## 4. check_setup 规则与接口

### 4.1 放置位置：`plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（不放 `harnessloop-setup/scripts/`）

<!-- verify:ignore --> （v1 §4.1 标题曾笔误为 `harnessloop-loop/skills/harnessloop-loop/scripts/check_setup.py`，缺少 `plugins/harnessloop/` 前缀；本节标题及正文已更正，S2 修复。）

理由：

1. **复用已验证的路径解析模式，直接规避 TH-0003**：`init_project.py`/`verify_protocol.py`/`round_cost.py` 均已用 `SKILL_DIR = Path(__file__).resolve().parents[1]` 定位自身技能目录，`check_setup.py` 放在同目录可原样复用这一行，不引入新的相对路径写法。
2. **单一事实来源**：`check_setup.py` 需要"文件 → 模板"的映射，`init_project.py` 里的 `BASE_FILES` 字典已经是这份映射的权威来源；同目录下可以直接 `import init_project` 复用其 `read_template()`（模板围栏代码块提取逻辑）与 `BASE_FILES`，避免维护第二份可能漂移的映射表。
3. **跨技能调用方向一致**：当前协议里被 `status`/`continue`/`loop` 三个技能共同引用的机械脚本只有 `harnessloop-loop/scripts/` 下的几支（`verify_protocol.py`、`round_cost.py`）；把 `check_setup.py` 放进同一目录延续了"被多个技能读取的机械脚本统一放 loop/scripts/"的现有惯例。若放进 `harnessloop-setup/scripts/`，会引入一个新方向的跨技能依赖（其它技能反过来读取 `harnessloop-setup` 的脚本），协议里目前没有这种先例（`harnessloop-secrets/scripts/channel_params.py` 只被 secrets 自己使用）。
4. `harnessloop-setup` 技能本身定位是"纯 SKILL.md 驱动的对话"，不需要专属脚本目录；它只是 `check_setup.py` 的众多调用方之一。

### 4.2 字段清单（manifest）：5 个文件、90 个可判定槽位（M2/S5 修订）

不采用"通用 markdown 语义 diff"，而是对每个文件的模板结构做穷举式字段清单（analogous to `verify_protocol.py` 只做机械规则，不做通用语义判断）。清单与模板结构一一对应，模板变更时需同步更新（见 §10 风险）。

**每个 manifest 条目携带完整"小节容器路径"（heading path），而非裸标签**（M2 修复的核心）。路径的构成规则：

- 若字段直接位于某个 `##` 小节下（无中间容器行），路径 = `<Heading> > <Label>`。
- 若字段位于小节内的一个"容器行"（container line：以冒号结尾、其后紧跟一个缩进/子级列表、且自身不作为可填字段的行，如 `Responsibilities:`、`Allowed when:`、`Codex:`）之下，路径 = `<Heading> > <Container> > <Label>`。
- `self-check.md` 全文没有 `##` 小节（只有一个 `# Self Check` 顶层标题+12 个平级 bullet），故其 12 个字段路径退化为单段（就是标签本身），无歧义，不受本次修订影响。
- `data-sources.md` 的 4 个表格槽位路径 = 各自的 `##` 小节标题本身（`Static Sources`/`Dynamic Or Generated Sources`/`Runtime Validation Systems`/`External Tools And Platforms`），无需容器层（表格本身就是该小节唯一内容）。

两类槽位（沿用 v1 定义，排除规则改写为所有权判据，S5 修复）：

- **leaf 字段槽位**：按上述路径规则定位的、"以冒号结尾、其后为待填内容"的行。
- **表格槽位**：模板里的一张 markdown 表，默认全部计入槽位（"待填或需写 none 哨兵"）；**仅当该表出现在下方"所有权豁免清单"时才排除**——v1 用"原始模板数据行数是否为 0"作为排除判据，经复审证伪：`data-sources-template.md` 的 `Local Channel Parameters` 表原始行数同样为 0，却被 v1 口头排除而未反映在规则文本里，导致规则与清单自相矛盾（S5）。v2 改为显式所有权判据：

  | 表 | 所属文件 | 排除理由（所有权，而非"是否为空"） |
  | --- | --- | --- |
  | Blocker Classification | `control-contract.md` | 归属协议本身的固定分类法（loop SKILL.md 的 7 类 blocker taxonomy），模板已预填 7 行，非用户/wizard 决策点 |
  | Execution Delegation Matrix | `cost-context-policy.md` | 归属协议本身的委派矩阵（loop SKILL.md `Role And Model Rules` 一节），模板已预填 8 行 Decision 列，非用户/wizard 决策点 |
  | Local Channel Parameters | `data-sources.md` | 归属 `$harnessloop-secrets` 技能管辖（该技能的 Processing Contract 明确规定它负责初始化/维护此表对应的本地存储），不属于 wizard S2 的问答范围，即使模板原始行数为 0 也不计入 data-sources.md 的完整度判定 |

  `Secret Handling` 段（`data-sources.md` 末尾）不是表格，是协议固定说明文字，本来就不含任何"冒号待填"或表格结构，无需列入排除清单——它从一开始就不构成槽位。

逐文件槽位清单：

| 文件 | 模板 | leaf 字段数 | 表格槽位 | 合计 |
| --- | --- | --- | --- | --- |
| `state/environment.md` | environment-self-check-template.md | 21（Detection 4 + Delegation 6 + Model And Effort 7 + Result 4） | 0 | 21 |
| `setup/data-sources.md` | data-sources-template.md | 0 | 4（Static Sources / Dynamic Or Generated Sources / Runtime Validation Systems / External Tools And Platforms；`Local Channel Parameters` 按上表所有权豁免清单排除） | 4 |
| `setup/cost-context-policy.md` | cost-context-policy-template.md | 29（详细路径见下表） | 0（Execution Delegation Matrix 按所有权豁免清单排除） | 29 |
| `state/control-contract.md` | control-contract-template.md | 24（详细路径见下表） | 0（Blocker Classification 按所有权豁免清单排除） | 24 |
| `state/self-check.md` | self-check-template.md | 12（无小节，单段路径） | 0 | 12 |
| **合计** | | **86** | **4** | **90** |

槽位总数与 v1 一致（90），M2/S5 只改变了"如何无歧义定位/为何排除"，不改变架构或计数——符合评审"设计文本级最小修复，不推翻架构"的定性。

**cost-context-policy.md 完整 29 条路径清单**（M2 核心交付：消除重复标签歧义）：

| # | 路径 | 说明 |
| --- | --- | --- |
| 1 | Main Session > Responsibilities > Orchestration | |
| 2 | Main Session > Responsibilities > Core decisions | 与 #20、#24 同名不同路径，互不覆盖 |
| 3 | Main Session > Responsibilities > Final acceptance | |
| 4 | Main Session > Must not spend context on > Large raw logs | |
| 5 | Main Session > Must not spend context on > Full external reports | |
| 6 | Main Session > Must not spend context on > Repeated source dumps | |
| 7 | Delegation Rules > Use subagent or swarm for > Read-only discovery | |
| 8 | Delegation Rules > Use subagent or swarm for > Evidence collection | |
| 9 | Delegation Rules > Use subagent or swarm for > Low-context execution | 与 #18、#22 同名不同路径 |
| 10 | Delegation Rules > Use subagent or swarm for > Adversarial review | 与 #19、#23 同名不同路径 |
| 11 | Delegation Rules > Use subagent or swarm for > Acceptance testing | |
| 12 | Delegation Rules > Do not delegate > Goal interpretation | |
| 13 | Delegation Rules > Do not delegate > Goal breakdown approval | |
| 14 | Delegation Rules > Do not delegate > Scope-lock changes | |
| 15 | Delegation Rules > Do not delegate > Human-required product or business decisions | |
| 16 | Delegation Rules > Do not delegate > Acceptance after failed review | |
| 17 | Model Policy > Codex > Independent investigation | 与 #21 同名不同路径 |
| 18 | Model Policy > Codex > Low-context execution | |
| 19 | Model Policy > Codex > Adversarial review | |
| 20 | Model Policy > Codex > Core decisions | |
| 21 | Model Policy > Claude Code > Independent investigation | |
| 22 | Model Policy > Claude Code > Low-context execution | |
| 23 | Model Policy > Claude Code > Adversarial review | |
| 24 | Model Policy > Claude Code > Core decisions | |
| 25 | Handoff Budget Rules > Input limit | |
| 26 | Handoff Budget Rules > Output limit | |
| 27 | Handoff Budget Rules > Evidence path requirement | |
| 28 | Handoff Budget Rules > Summary requirement | |
| 29 | Handoff Budget Rules > Context that must stay out of main session | |

验证：`Core decisions` 出现于 #2/#20/#24（3 次）、`Low-context execution` 出现于 #9/#18/#22（3 次）、`Adversarial review` 出现于 #10/#19/#23（3 次）、`Independent investigation` 出现于 #17/#21（2 次）——与评审证据（cost-context-policy-template.md :11/:26-27/:55-58/:62-65 逐行核实的重复次数）完全吻合，29 条路径互不相同，M2 歧义消除。

**control-contract.md 完整 24 条路径清单**（本文件标签本身不重复，路径化主要为保持接口一致性）：

| # | 路径 |
| --- | --- |
| 1-5 | Auto-Continue > Allowed when > {Feedback class, Evidence health, Environment self-check, Open handoffs, Human confirmation} |
| 6-11 | Human Confirmation Required > Required for > {Scope-lock mutation, Evidence contract revision, Control contract revision, Failed review acceptance, Rollback, Irreversible or external-system write} |
| 12-17 | Stop Conditions > Stop when > {Blocking condition, Blocker type, Missing evidence, Environment mismatch, Model/effort mismatch, Contract cannot be evaluated} |
| 18-20 | Delegation Boundaries > {Allowed delegated work, Disallowed delegated work, Required handoff evidence} |
| 21-24 | Acceptance Authority > {Round acceptance, Failed review escalation, Blocked state unblock requirement, Recoverable blocker auto-round policy} |

**environment.md 完整 21 条路径清单**：

| # | 路径 |
| --- | --- |
| 1-4 | Detection > {Detected environment, Detected from, Available tools, Unavailable tools} |
| 5-10 | Delegation > {Expected mechanism, Observed mechanism, Can create independent task, Can constrain read/write scope, Can require output path, Can verify evidence citations} |
| 11-17 | Model And Effort > {Expected model, Observed model, Expected effort/reasoning, Observed effort/reasoning, Verification method, Mismatch action, Residual risk} |
| 18-21 | Result > {Pass/fail, Allowed next actions, Required human action, Last checked} |

**self-check.md 完整 12 条路径清单**（无小节，单段）：`Setup files present`、`Environment policy recorded`、`Control contract recorded`、`Evidence index recorded`、`Self-audit present`、`Runtime validation described`、`Data/tool access described`、`Local channel parameter store protected`、`Delegation model verified`、`Intake gate required`、`Action`、`Last checked`。

### 4.3 空/满判定算法（M2 小节作用域匹配 + S1/S10 修订）

**定位（新增，M2 核心修复）**：给定一条 manifest 路径 `H > C > L`（或 `H > L`，无容器）：

1. 在目标文件中找到 `## H`（或 `# H`，若模板本身只有一级标题如 self-check.md）所在行，截取从该行到下一个同级或更高级标题行（或文件末尾）之间的文本，得到"小节切片"。
2. 若路径含容器 `C`：在小节切片内找到容器行（匹配 `Label:` 且冒号后为空、且紧随其后的非空行是子级列表项 `- ...` 的行），从该容器行到"小节切片内下一个容器行，或小节末尾"之间的文本，得到"容器切片"。
3. 在最终切片（有容器则为容器切片，否则为小节切片）内，取**第一处**匹配叶子标签的行进行判定。这一步天然排除了同名标签出现在其它小节/容器切片中的干扰——例如判定 `Model Policy > Codex > Adversarial review` 时，切片被限定在"`Codex:` 行到`Claude Code:` 行之间"，`Delegation Rules` 小节和 `Claude Code:` 容器里同样叫 `Adversarial review:` 的行不会被扫描到。

**空/满判定**（沿用 v1 逻辑，补充 S10 容差）：

对每个 leaf 字段，在上一步定位到的切片内寻找匹配标签的行：

- 匹配容差（S10 修订）：允许前导 `#`/`-`/`*`/空格；允许标签本身被 `**` 包裹（粗体，如 `**Label:**`）；允许冒号前有多余空格（如 `Label  :`）。正则形如 `^[#\-*\s]*\**\s*{re.escape(label)}\s*\**\s*:\s*(.*)$`（大小写敏感，标签逐字匹配）。
- 取冒号后剩余文本，去除首尾空白，记为 `value`。
- 判定为空（blank），当且仅当：(a) `value` 为空字符串；或 (b) `value` 与**模板原文**该切片位置对应行冒号后的文本逐字相同（覆盖模板自带枚举提示如 `codex | claude-code | other | unknown` 被原样抄录、从未替换的情况）。
- 否则判定为已填（filled）——值为字面 `TODO (owner: user)`（含其后追加的跳过说明文本）也算"已填"，因为这是协议认可的显式声明，区别于"从未触碰"的空白模板行；这类字段应计入 §4.4 的 `todo_count`。
- 若目标文件中在正确的切片范围内完全找不到该 `Label`（结构被破坏/字段被删除，或容器行本身缺失导致无法定位切片），判定为 missing，计入未填。

对每个表格槽位：

- 定位模板中对应 `## Heading` 在目标文件中的同名小节（同上小节切片规则）。
- 统计表头分隔行（`| --- | ... |`）之后、切片末尾之前的非空数据行数。
- 若 ≥ 1 行 → 已填。
- 若 0 行，检查同一切片内是否存在匹配以下正则的哨兵行（**S1 收紧**：要求逐字包含固定短语 `(confirmed via setup wizard)`，不再用宽松的 `no|none...declared` 语义匹配，消除"No such tools declared yet, need review"这类叙述句/待办句被误判为已确认的假阳性）：

  <!-- verify:ignore -->
  ```
  ^_?\s*(?:No|None)\b[^_\n]*\(confirmed via setup wizard\)\.?_?\s*$
  ```

  （大小写不敏感匹配 `No`/`None`；`(confirmed via setup wizard)` 部分区分大小写、逐字匹配；上面的正则字符串本身是判定规则的引用性说明，不是对某个真实文件路径的引用，按本文档开头的记法说明标注 `verify:ignore`。）

- 满足上述正则 → 已填（"显式确认为空"）。否则 → 未填。

文件级状态：

- `template`：该文件全部槽位为未填（近似等于 `init_project.py` 刚写入时的原始状态）。
- `filled`：该文件全部槽位为已填。
- `partial`：介于两者之间。
- `missing`：文件不存在。

`missing_sections`：未填槽位的完整路径列表，如 `["Model And Effort > Observed model", "Runtime Validation Systems"]`。

### 4.4 CLI 与输出（M1 双层门字段新增）

```bash
python <plugin-root>/skills/harnessloop-loop/scripts/check_setup.py --project <target-project> [--json]
```

**双层门新增字段**（M1 修复）：

- `gate_blocking`（bool）：`true` 当且仅当 `state/environment.md`、`state/control-contract.md`、`setup/cost-context-policy.md` 三者之一的 `state` ∈ `{template, missing}`。这三个文件被选中的理由：它们分别是 continue 的 environment gate、control gate、delegation gate 直接读取的策略来源；`setup/data-sources.md`（continue 的 evidence gate 实际读取的是 `state/evidence-index.md`，不是 `data-sources.md`）与 `state/self-check.md`（wizard 自身的输出记录，非任何 continue 门的输入）不参与这一判定。
- `todo_count`（int）：跨 5 个文件统计的、值等于字面 `TODO (owner: user)`（允许其后追加自由文本）的 leaf 字段个数，加上 `state/self-check.md` 的 `Action` 字段里按 `TODO (owner: user): ...` 格式列出的条目个数（若两者所指是同一份 TODO 的重复记录，实现时以 `Action` 字段的条目计数为准，避免重复计数；这一去重规则需在实现轮的单元测试中显式验证）。这个数字让"字段被填成 TODO 而非留空"这件事不再是静默的——`complete: true` 但 `todo_count > 0` 是一个完全合法且会被 status 持续展示的状态（"表面上 5/5 filled，但有 N 处只是占位"）。
- `complete`/`filled`/`total`/`next_step`：语义不变，仍然是"5 个文件是否全部 100% filled"这一**严格**判定，供 wizard 自身的 N/5 报告和 §7 的 validate.py 正向 fixture 使用；不因 M1 修复而放宽。
- **`gate_blocking` 与 `complete` 是两套独立信号，互不替代**：`complete=false` 但 `gate_blocking=false` 是完全正常的常态（如本项目自身：3 个核心文件已填，只有 `data-sources.md` 差一类未答）；`gate_blocking` 专供 continue/loop 的短路判断读取，`complete` 专供 wizard/status 的完成度报告读取。

人可读输出（默认）：

```text
Harnessloop setup check: <project>
  state/environment.md: filled (21/21)
  setup/data-sources.md: partial (3/4) — missing: External Tools And Platforms
  setup/cost-context-policy.md: filled (29/29)
  state/control-contract.md: template (0/24)
  state/self-check.md: template (0/12)
Setup completeness: 2/5 files fully filled.
Setup gate: BLOCKING — state/control-contract.md is still template.
TODO count: 0
Next setup step: state/control-contract.md (run $harnessloop-setup)
```

`--json` 输出（`files`/`complete`/`filled`/`total` 四键是 handoff 硬性要求的最小机器格式；`gate_blocking`/`todo_count`/`fields_filled`/`fields_total`/`next_step` 是本轮新增或延续的非破坏性补充）：

```json
{
  "project": "<resolved path>",
  "files": {
    ".harnessloop/state/environment.md": {
      "state": "filled",
      "missing_sections": [],
      "fields_filled": 21,
      "fields_total": 21
    },
    ".harnessloop/setup/data-sources.md": {
      "state": "partial",
      "missing_sections": ["External Tools And Platforms"],
      "fields_filled": 3,
      "fields_total": 4
    }
  },
  "complete": false,
  "filled": 2,
  "total": 5,
  "gate_blocking": true,
  "todo_count": 0,
  "next_step": ".harnessloop/state/control-contract.md"
}
```

### 4.5 退出码（不变）

- `0`：`complete: true`（5/5 filled）——**退出码语义不随 `gate_blocking` 改变**：`gate_blocking` 是 continue/loop 解析 JSON 后自行读取的字段，不是新的退出码维度。这样 §7 的 validate.py 正向/负向 fixture 断言（针对 exit code 的部分）不需要因 M1 重新设计，只需新增对 JSON 里 `gate_blocking`/`todo_count` 字段的断言。
- `1`：`complete: false`（至少一个文件非 filled）。
- `2`：用法/环境错误——项目目录不存在、`references/` 目录不存在、目标模板文件缺失（这些是打包/环境问题，不是"未完成"，与 `verify_protocol.py` 现有的 2 号退出码语义一致）。

### 4.6 Python 3.9 兼容性、路径解析与零写入保证（吸取 TH-0001/TH-0003，S6/S9 修订）

- 顶部 `from __future__ import annotations`，沿用 `init_project.py` 现有写法。
- 不使用 `Path.write_text(..., newline=...)`（3.10+ 独有）——`check_setup.py` 本身不写任何项目文件（纯读取判定），此条主要作为约束记录，防止后续给它加"自动补哨兵行"之类功能时重蹈 TH-0001。
- 不使用 `match`/`case`（3.10+）、不使用仅 3.10+ 的 `X | Y` 写法在需要运行时求值的位置（配合 `from __future__ import annotations` 可用在类型注解位置）。
- `str.removeprefix`/`str.removesuffix` 可用（3.9+ 已支持，`validate.py:173/:175` 已依赖此下限）。
- 模板目录解析：`SKILL_DIR = Path(__file__).resolve().parents[1]`；`REFERENCES_DIR = SKILL_DIR / "references"`——与 `init_project.py:13-14` 完全一致，不依赖 cwd 或仓库根。
- **同目录 import 机制说明（S9 新增）**：`check_setup.py` 与 `init_project.py` 同处 `harnessloop-loop/scripts/` 目录。当 `check_setup.py` 被直接执行（`python3 check_setup.py ...`）时，Python 会把脚本自身所在目录自动加入 `sys.path[0]`，因此文件顶部 `import init_project` 可以直接工作，无需手工操作 `sys.path`。当 `check_setup.py` 被作为模块从别处导入（例如 §7 的 `validate.py`）时，需要显式 `sys.path.insert(0, str(LOOP_SCRIPTS))`——这正是 `validate.py:32-34` 现有的写法（`sys.path.insert(0, str(LOOP_SCRIPTS)); import init_project; import verify_protocol`），`check_setup.py` 会成为这里第三个被同样方式导入的模块，不需要新写法。
- **零写入保证（S6 新增）**：`import init_project` 在某些运行环境下会在 `harnessloop-loop/scripts/__pycache__/` 生成 `.pyc` 字节码缓存文件——这不是对目标项目的写入，但会写入插件安装目录，与 `harnessloop-status` SKILL.md "read-only 意味着不写任何文件"的字面表述有一处像素级缝隙。修复：(a) `check_setup.py` 顶部设置 `sys.dont_write_bytecode = True`；(b) `harnessloop-status`/`harnessloop-continue`/`harnessloop-loop` 在 SKILL.md 里调用 `check_setup.py` 时统一使用 `python3 -B` 参数（或设置环境变量 `PYTHONDONTWRITEBYTECODE=1`），双重保证不产生任何字节码缓存写入。两处修复的具体接线见 §6.2。

---

## 5. 三档预设完整内容（lite / standard / strict）

存放位置：`harnessloop-loop/references/control-contract-profiles.md`（新文件，实现轮创建；本设计给出全部落地文本，且已获批准在 `harnessloop-loop/SKILL.md` 增加一行引用，见 §6.4）。三档均覆盖 `control-contract-template.md` 的全部 24 个 leaf 字段，`Blocker Classification` 表三档一致，直接照录协议原有 7 类（不新增/不删减，档位差异只体现在 Auto-Continue/Human Confirmation/Stop Conditions/Delegation Boundaries/Acceptance Authority）。

### 5.1 Auto-Continue（Allowed when）

| 字段 | lite | standard（默认） | strict |
| --- | --- | --- | --- |
| Feedback class | positive；或 negative/neutral 且下一步是只读调查/最小修复/本轮 scope-lock 内回滚 | positive | positive，且本轮若涉及外部系统写操作需已获独立人工验收 |
| Evidence health | 无 stale 证据即可，inconclusive 允许存在但不得单独支撑验收 | 全部 evidence-index 条目 artifact health = valid | 全部条目 valid；含 secret/敏感 sensitivity 的证据一律不支持自动续跑 |
| Environment self-check | pass，或 unknown 但委派仅限只读发现 | pass | pass 且 Observed model/effort 已过 `$harnessloop-delegation` 验证（非仅 expected 值） |
| Open handoffs | 无处于 blocked 的 open handoff | 无 open handoff | 无 open handoff，且上一轮 adversarial review 结论为 positive |
| Human confirmation | 不需要——条件满足即自动进入下一子目标/下一只读调查轮 | 不需要——条件满足即自动进入下一子目标/任务 | 需要——即使以上全满足，仍需人工确认后才进入下一子目标 |

### 5.2 Human Confirmation Required（Required for）（M3 修订：Evidence contract revision 行）

| 字段 | lite | standard | strict |
| --- | --- | --- | --- |
| Scope-lock mutation | 不需要（main session 自主收窄/扩大，需在 decision.md 留痕） | 扩大范围需要；收窄不需要 | 需要（任何方向变更） |
| Evidence contract revision | **需要人工确认，当且仅当变更改变验收标准、降低验证门槛、扩大证据范围或影响续跑判定**（对齐 `harnessloop-evidence` SKILL:31/:49 的硬性约束，四条件命中任一即需要，不因档位而放宽；lite 档下四条件之外的证据契约维护性变更——如补充引用路径、修正拼写、增加已有来源的时间戳——仍可由 main session 自主记录，无需人工确认） | 需要 | 需要 |
| Control contract revision | 需要 | 需要 | 需要 |
| Failed review acceptance | 需要（协议硬约束，任何档位不可关闭） | 需要 | 需要 |
| Rollback | 不需要（main session 可对已分类为错误的执行自主回滚，需记录） | 需要 | 需要，且需说明回滚范围是否触及外部系统 |
| Irreversible or external-system write | 需要 | 需要 | 需要，且需提前声明 dry-run/回滚方案 |

**M3 修复说明**：v1 的 lite 档原文"不需要，除非改变验收标准的实质含义"只覆盖了 `harnessloop-evidence` SKILL:31/:49 四条件中的一条（验收标准变更），遗漏了"降低验证门槛""扩大证据范围""影响续跑判定"三条——这三条是 evidence skill 处理 `revise` 动作时写死的人工确认硬约束（SKILL.md:49："require explicit human confirmation when the revision changes acceptance criteria, weakens validation, broadens evidence scope, or affects continuation"），control-contract 的档位设置无权覆盖协议 skill 层面的硬约束。v2 措辞把四条件完整对齐，lite 档的"宽松"体现在**四条件之外**的维护性变更上，不再与 evidence skill 冲突。

对照核实其余硬约束（复审已确认）：`Failed review acceptance` 三档均"需要"，与 `loop:430`（never delegate）、`continue:90` 一致，无违反；lite 的 `Rollback`"不需要（本地自主回滚需记录）"与 `loop:459-461`（negative/neutral 下 rollback 为协议允许动作）不冲突（外部系统回滚仍被 lite 的 `Irreversible/external-system write`="需要"兜住）；lite `Scope-lock mutation`"不需要"未违反任何协议硬约束（`loop:428` 只禁委派、不强制人工确认，属项目策略空间），但需用户验收确认（§10）。

### 5.3 Stop Conditions（Stop when）

| 字段 | lite | standard | strict |
| --- | --- | --- | --- |
| Blocking condition | access-missing / human-decision-required / write-safety-required 且下一动作需要外部系统写权限 | 同左，另加 contract-insufficient | 同 standard，另加：任何 external-system-unsafe 一律停止，不做 bounded observation |
| Blocker type | 协议 7 类原样采纳 | 同左 | 同左，但 external-system-unsafe 不接受"maybe"级自动续跑 |
| Missing evidence | 验收所需证据 artifact health = missing/blocked 时停止（stale/inconclusive 可继续只读调查） | 任一验收相关证据 ≠ valid 时停止 | 同 standard，另加：secret/敏感证据须人工确认后才可标记 valid |
| Environment mismatch | 仅当委派任务涉及验收/写入且 self-check=fail 时停止 | environment self-check ≠ pass 时停止 | 同 standard，另加：每轮开始前重新校验，不复用上一轮结论 |
| Model/effort mismatch | 仅高风险委派（对抗性评审/验收测试）observed≠expected 时停止 | 任何委派 observed≠expected 且未经 `$harnessloop-delegation` 复核时停止 | 任何委派（含只读发现）observed≠expected 时停止 |
| Contract cannot be evaluated | control-contract/evidence-index 关键字段缺失且无法推得时停止 | control-contract/evidence-index/goal 三者任一必填字段为空时停止 | 同 standard，另加：Acceptance Authority 字段缺失同样视为契约不完整 |

### 5.4 Delegation Boundaries

| 字段 | lite | standard | strict |
| --- | --- | --- | --- |
| Allowed delegated work | 只读发现、证据收集、低风险本地实现、对抗性评审、验收测试（委派矩阵前 7 类中除"轮次验收与控制决策"外均可） | 同 lite，但高风险/跨领域实现仅可委派其中独立子任务 | 只读发现、证据收集（不含敏感/secret 数据）、对抗性评审、验收测试；本地实现主会话完成或仅委派已获批最窄子任务 |
| Disallowed delegated work | 目标解释、breakdown 审批、scope-lock 变更、人工业务决策、失败评审后接受、轮次验收 | 同 lite | 同 standard，另加：任何外部系统写操作、任何 secret/敏感数据读取 |
| Required handoff evidence | 文件路径 + 结论摘要 | 文件路径 + 结论摘要 + 证据健康状态 | 文件路径 + 结论摘要 + 证据健康状态 + 委派模型/effort 的实际验证记录 |

### 5.5 Acceptance Authority

| 字段 | lite | standard | strict |
| --- | --- | --- | --- |
| Round acceptance | main session 自主判定 | main session 判定，需在 decision.md 引用证据路径 | 同 standard，另加：每轮验收前需确认 environment/delegation gate 均 pass |
| Failed review escalation | 仅用户 | 仅用户 | 仅用户，且需写明理由存档 |
| Blocked state unblock requirement | access-missing/human-decision-required/write-safety-required 需用户输入解除；runtime-recoverable/contract-insufficient 可自行进入恢复轮 | 同 lite | 同 standard，另加：external-system-unsafe 只能由用户解除 |
| Recoverable blocker auto-round policy | runtime-recoverable 自动开启只读调查轮，无需用户确认 | runtime-recoverable 自动开启只读调查轮；contract-insufficient 自动开启契约修复轮（不得借此执行业务写入） | 同 standard，另加：两类恢复轮产出仍需在下次验收前由用户抽查（strict 不允许连续多轮无人工介入） |

---

## 6. 接线点精确 diff 方案

### 6.1 `harnessloop-init/SKILL.md`

**第 90 行**（`## After Initialization` 报告清单）：

```diff
- - Next recommended prompt: `Use $harnessloop-loop to define the goal and start the evidence-backed loop.`
+ - Next recommended prompt: `Use $harnessloop-setup to walk through environment detection, data sources, cost/context policy, and control-contract profile before defining a goal.`
```

**第 35 行**（Initialization Decision 分支，v1 列为开放问题，本批已获批准同步修正）：

```diff
- If `.harnessloop/` already exists, do not overwrite it. Report that Harnessloop is already initialized and suggest `$harnessloop-loop` for status or continuation.
+ If `.harnessloop/` already exists, do not overwrite it. Report that Harnessloop is already initialized and suggest `$harnessloop-setup` to check/complete setup, or `$harnessloop-status` for a read-only summary.
```

### 6.2 `harnessloop-status/SKILL.md`

**Input Contract**（第 20 行后追加一句）：

```diff
  If `.harnessloop/` is missing, report `not-initialized` and suggest `$harnessloop-init`. Do not initialize it from this skill.
+
+ If `.harnessloop/` exists but `check_setup.py` reports `complete: false`, report `setup-incomplete`, surface `todo_count` and every non-`filled` file's `missing_sections`, and suggest `$harnessloop-setup`. Do not run the wizard from this skill.
```

**Processing Contract**（第 22-28 行，插入新步骤 2，原 2-5 顺延为 3-6；M1/S6 修订）：

```diff
  1. Read `.harnessloop/state/current.md` first when present.
- 2. Follow only the source paths referenced by current state, active goal, active round, open handoffs, latest decision, evidence index, control contract, environment self-check, and self-audit.
- 3. Summarize evidence health without revalidating external systems unless the user explicitly asks for evidence checking; route that to `$harnessloop-evidence`.
- 4. Report contradictions, missing state files, stale pointers, unresolved human decisions, intake blockers, blocker type, recovery eligibility, and next action safety.
- 5. Do not mutate any file, run continuation gates, execute tests as business work, or change feedback classification.
+ 2. Run `python3 -B <plugin-root>/skills/harnessloop-loop/scripts/check_setup.py --project <target-project> --json` (the `-B` flag, or `PYTHONDONTWRITEBYTECODE=1`, guarantees no `__pycache__` bytecode is written, keeping this step strictly read-only). If it reports `complete: false`, set state to `setup-incomplete` and record `todo_count`, the first non-`filled` file, and its `missing_sections` as the setup completeness and next setup step. Note whether `gate_blocking` is `true` (a core policy file — environment/control-contract/cost-context-policy — is still `template`/`missing`) or `false` (only non-blocking gaps, such as `data-sources.md` or `self-check.md`, remain); report this distinction so the user knows whether `$harnessloop-continue` will short-circuit.
+ 3. Follow only the source paths referenced by current state, active goal, active round, open handoffs, latest decision, evidence index, control contract, environment self-check, and self-audit.
+ 4. Summarize evidence health without revalidating external systems unless the user explicitly asks for evidence checking; route that to `$harnessloop-evidence`.
+ 5. Report contradictions, missing state files, stale pointers, unresolved human decisions, intake blockers, blocker type, recovery eligibility, and next action safety.
+ 6. Do not mutate any file, run continuation gates, execute tests as business work, or change feedback classification.
```

**Output Contract**（第 34-55 行代码块；M1 修订新增 `setup gate`/`todo count`）：

```diff
  Harnessloop status:
  - project:
- - state: initialized | not-initialized | inconsistent | blocked
+ - state: initialized | not-initialized | setup-incomplete | inconsistent | blocked
+ - setup completeness:
+ - setup gate: complete | warning | blocking
+ - todo count:
+ - setup next step:
  - active goal:
  - active round:
  ...（其余字段不变）
```

**Safety Rules**（第 59-63 行，追加一条）：

```diff
  - External systems and named tools are not probed from status; ask the user to use `$harnessloop-evidence` or `$harnessloop-continue` when action is required.
+ - Running `check_setup.py` with `-B`/`PYTHONDONTWRITEBYTECODE=1` satisfies the read-only mandate above: it performs no writes (including bytecode cache), no external probing, and no continuation decision.
```

### 6.3 `harnessloop-continue/SKILL.md`

**Input Contract**（第 22 行后追加一句；M1 修订短路条件）：

```diff
  If `.harnessloop/` is missing, stop and suggest `$harnessloop-init`. If imported intake work is pending, route to `$harnessloop-intake`.
+
+ If `.harnessloop/` exists and `check_setup.py` reports `gate_blocking: true` (a core policy file — environment/control-contract/cost-context-policy — is still `template` or `missing`), stop and return `needs-setup` before evaluating any other gate (see Processing Contract step 1); suggest `$harnessloop-setup`. If `gate_blocking` is `false` but `complete` is `false` (non-blocking gaps remain, e.g. in `data-sources.md` or acknowledged via TODO), do not stop; surface a warning with `todo_count` and continue evaluating the remaining gates normally.
```

**Processing Contract**（第 24-37 行，整体重新编号，插入新步骤 1，原 1-12 顺延为 2-13；M1 修订）：

```diff
  ## Processing Contract

- 1. Read `.harnessloop/state/current.md`, `state/control-contract.md`, `state/environment.md`, `state/evidence-index.md`, `state/self-check.md`, `meta/self-audit.md`, the active goal, active round, open handoffs, and latest decision.
- 2. If the latest decision treats the active round as `positive`, confirm that `python <plugin-root>/skills/harnessloop-loop/scripts/verify_protocol.py --project <target-project>` was run for that round and exited zero, or run it now. A non-zero exit means the round must not be treated as `positive`; reclassify the blocker as `contract-insufficient` and stop for evidence/contract repair instead of continuing.
- 3. Confirm the requested next action matches the control contract and latest feedback.
- 4. If feedback is `positive`, continue only to the next subgoal/task or goal completion path.
- 5. If feedback is `negative` or `neutral`, continue only with investigation, minimal fix, rollback, missing evidence repair, or human-confirmed contract revision.
- 6. If feedback is `blocked`, classify the blocker before stopping. Use `runtime-recoverable`, `access-missing`, `write-safety-required`, `human-decision-required`, `contract-insufficient`, `external-system-unsafe`, or `unknown`.
- 7. If the blocker is `runtime-recoverable` and the next action is read-only investigation with declared evidence targets, create or enter the next investigation/recovery round instead of pausing for the user.
- 8. If the blocker requires write cleanup, external mutation, missing access facts, missing local channel parameters, a named tool that is unavailable, or business judgment, stop and ask the user through `askuserquestion` when available.
- 9. If evidence contract changes are needed, route to `$harnessloop-evidence` before execution.
- 10. If active work came from `.harnessloop/intake/`, require passed intake gate and accepted intake-review round before business execution.
- 11. If self-audit, environment, delegation, named-tool, external-system, or access requirements are missing or ambiguous, ask the user for confirmation before tool use or execution. Use `askuserquestion` when available; otherwise ask directly in chat.
- 12. If the next action relies on subagent, swarm, or another delegated mechanism and model/effort or scope control is unverified, route to `$harnessloop-delegation` before execution.
+ 1. Run `python3 -B <plugin-root>/skills/harnessloop-loop/scripts/check_setup.py --project <target-project> --json`. If `gate_blocking` is `true`, set decision to `needs-setup`, name the `template`/`missing` core file (environment.md, control-contract.md, or cost-context-policy.md) as the next setup step, and stop before evaluating any other gate. Do not execute business work. If `gate_blocking` is `false` but `complete` is `false`, do not stop; record `setup gate: warning`, `todo_count`, and the `missing_sections` of any non-`filled` file, then proceed to step 2.
+ 2. Read `.harnessloop/state/current.md`, `state/control-contract.md`, `state/environment.md`, `state/evidence-index.md`, `state/self-check.md`, `meta/self-audit.md`, the active goal, active round, open handoffs, and latest decision.
+ 3. If the latest decision treats the active round as `positive`, confirm that `python <plugin-root>/skills/harnessloop-loop/scripts/verify_protocol.py --project <target-project>` was run for that round and exited zero, or run it now. A non-zero exit means the round must not be treated as `positive`; reclassify the blocker as `contract-insufficient` and stop for evidence/contract repair instead of continuing.
+ 4. Confirm the requested next action matches the control contract and latest feedback.
+ 5. If feedback is `positive`, continue only to the next subgoal/task or goal completion path.
+ 6. If feedback is `negative` or `neutral`, continue only with investigation, minimal fix, rollback, missing evidence repair, or human-confirmed contract revision.
+ 7. If feedback is `blocked`, classify the blocker before stopping. Use `runtime-recoverable`, `access-missing`, `write-safety-required`, `human-decision-required`, `contract-insufficient`, `external-system-unsafe`, or `unknown`.
+ 8. If the blocker is `runtime-recoverable` and the next action is read-only investigation with declared evidence targets, create or enter the next investigation/recovery round instead of pausing for the user.
+ 9. If the blocker requires write cleanup, external mutation, missing access facts, missing local channel parameters, a named tool that is unavailable, or business judgment, stop and ask the user through `askuserquestion` when available.
+ 10. If evidence contract changes are needed, route to `$harnessloop-evidence` before execution.
+ 11. If active work came from `.harnessloop/intake/`, require passed intake gate and accepted intake-review round before business execution.
+ 12. If self-audit, environment, delegation, named-tool, external-system, or access requirements are missing or ambiguous, ask the user for confirmation before tool use or execution. Use `askuserquestion` when available; otherwise ask directly in chat.
+ 13. If the next action relies on subagent, swarm, or another delegated mechanism and model/effort or scope control is unverified, route to `$harnessloop-delegation` before execution.
```

**Output Contract**（第 55-77 行代码块）：

```diff
  Harnessloop continuation:
  - project:
- - decision: allowed | blocked | needs-evidence | needs-intake | needs-human | needs-self-audit | complete
+ - decision: allowed | blocked | needs-setup | needs-evidence | needs-intake | needs-human | needs-self-audit | complete
  - active goal:
  - active round:
  - current feedback:
  - requested next action:
  - allowed next action:
+ - setup gate: complete | warning | blocking
+ - todo count:
  - evidence gate:
  - control gate:
  - environment gate:
  - self-audit gate:
  - delegation gate:
  ...（其余字段不变）
```

**Safety Rules**（追加一条，置于末位，保持既有条目行号不变）：

```diff
  - Do not accept a round after failed adversarial review unless the control contract and human decision explicitly allow it.
+ - Do not evaluate evidence, control, environment, self-audit, or delegation gates before the setup gate; `gate_blocking: true` short-circuits directly to `needs-setup`. `gate_blocking: false` with `complete: false` is not a block — surface the gap as a warning and proceed.
```

### 6.4 `harnessloop-loop/SKILL.md`

**触发条件**（第 69 行）——沿用 v1 的说明：goal.md 验收标准写"loop SKILL:114 触发条件修正"，但当前文件里"若 `.harnessloop/` 不存在"这句触发条件位于第 69 行，第 114 行是另一句；本设计对两处都给出修正，见 §10 风险 1：

```diff
- If `.harnessloop/` does not exist in the target project, propose creating:
+ If `.harnessloop/` does not exist in the target project, or `check_setup.py` reports `gate_blocking: true` for an existing `.harnessloop/`, propose creating (or completing) the following:
```

紧接骨架代码块之后、"Prefer the bundled initializer instead of hand-creating files:"之前，插入新段落（M1 修订：条件从 `complete: false` 改为 `gate_blocking: true`）：

```diff
  ```

+ If `.harnessloop/` already exists, do not re-run the initializer. Instead check completeness:
+
+ ```bash
+ python3 -B <skill-dir>/scripts/check_setup.py --project <target-project> --json
+ ```
+
+ If this reports `gate_blocking: true`, hand off to `$harnessloop-setup` to complete the blocking core file (environment.md, control-contract.md, or cost-context-policy.md) before creating a goal or entering a round. If `gate_blocking` is `false` but `complete` is `false`, proceed normally and mention the non-blocking gap (see `references/control-contract-profiles.md` for the profile options `$harnessloop-setup` uses at its control-contract step) so the user can close it later. Do not fill `data-sources.md`, `cost-context-policy.md`, `control-contract.md`, or `environment.md` by free-form conversation outside the wizard.
+
  Prefer the bundled initializer instead of hand-creating files:
```

**第 114 行**（"During setup, ask the user to fill in..."）：

```diff
- During setup, ask the user to fill in data-source connection requirements. Do not invent the data-source scope or content.
+ During setup, run `$harnessloop-setup` to fill in data-source connection requirements, cost/context policy, control-contract profile (see `references/control-contract-profiles.md` for the lite/standard/strict presets), and environment detection through its five-step wizard. Do not invent the data-source scope or content, and do not fill these files by ad hoc conversation outside the wizard.
```

上一行内联的 `references/control-contract-profiles.md` 引用，即 v1 §10 风险 4 中"是否需要在 loop SKILL.md 追加一行引用"的开放问题——已获批准，随本次 :114 修改一并落地（不再是独立开放项）。

---

## 7. validate.py 新断言清单

### 7.1 插入位置及理由（S4 修订：补充连带更新清单）

`scripts/validate.py` 当前 7 个阶段（`[1/7]`…`[7/7]`），新增 `validate_check_setup_smoke()` 作为第 3 阶段，插在 `[2/7] Init smoke test` 与 `[3/7] Secrets smoke test` 之间，其余阶段顺延，总数改为 8：

```
[1/8] Manifests and marketplace entries       (validate_manifests，不变)
[2/8] Init smoke test                          (validate_init_smoke，不变)
[3/8] Setup completeness smoke test            (validate_check_setup_smoke，新增)
[4/8] Secrets smoke test                        (validate_secrets_smoke，原 [3/7])
[5/8] Documentation skeleton consistency        (validate_doc_consistency，原 [4/7])
[6/8] Mechanical protocol gates                 (validate_protocol_gates，原 [5/7])
[7/8] Round cost settlement smoke test          (validate_round_cost_smoke，原 [6/7])
[8/8] Claude strict plugin validation           (validate_claude_strict，原 [7/7])
```

理由：`check_setup.py` 与 `init_project.py` 同样操作"刚初始化的骨架项目"这一对象，放在 init smoke 之后可以直接复用同一个 `smoke_root`/`init_project.initialize()` 产出，无需另建一套 fixture 目录；只需要机械地把后续阶段的 `[N/7]` 打印前缀改为 `[N/8]`（`validate.py` 内硬编码位置共 7 处：`:64`/`:110`/`:131`/`:206`/`:236`/`:290`/`:425`），属于低风险的查找替换。

**连带更新清单（S4 新增，之前 v1 遗漏）**：`[N/7]→[N/8]` 重编号只是 `validate.py` 内部打印文案的变化，但以下两处文本会因此过期，且按 `thresholds.md` 自身的 `Threshold Change Policy`（"Requires human confirmation: yes"）**需要人工确认**才能同步修改，本设计将其列为新增的 Required Human Decision（见 §10）：

1. `.harnessloop/goals/20260716-001-setup-wizard/thresholds.md:15`——当前文本"npm run validate 7/7 + 新增断言全绿"，需改为"npm run validate 8/8 阶段全绿"（或更通用地写"npm run validate 全部阶段全绿，阶段数以 `validate.py` 实际输出为准"，避免下次再新增阶段又要改一次数字）。
2. 本项目自身 `.harnessloop/setup/data-sources.md:16`（"每次运行重新生成……7/7 阶段全绿"）与 `:24`（"npm run validate（cwd=harnessloop/，7 阶段）"）——同样需要同步为 8。

这两处不在本轮 scope-lock 允许修改的文件范围内（scope-lock 只允许写 `rounds/0002/evidence/dynamic/setup-wizard-design-v2.md`），故本设计只记录待办，不在本轮修改；留给实现轮或后续轮次，且落地前需按 Threshold Change Policy 走一次人工确认（不能因为"只是把 7 改成 8"就跳过，阈值文本变更本身就是该 Policy 覆盖的对象）。

### 7.2 新增断言（`validate_check_setup_smoke`，含 M1 双层门断言）

沿用现有风格：顶部 `import check_setup`（与已有 `import init_project`/`import verify_protocol` 一致），必要处辅以 `run_python()` 子进程调用以验证 CLI/退出码契约（`main()` 层面的行为不经由直接函数调用就无法验证）。

1. **骨架 = incomplete + gate_blocking**：对 `validate_init_smoke` 已创建的裸骨架项目（或本阶段独立创建的同构 `smoke_root`）运行 `check_setup.py --project <smoke_root> --json`；断言 `returncode == 1`；解析 JSON 断言 `complete == False`、`filled == 0`、`total == 5`、`gate_blocking == True`（三个核心文件均为 `template`）、`todo_count == 0`。
2. **固定 fixture 填满 = complete，且无 TODO**：用 `check_setup` 模块自身导出的字段清单（若实现为常量，如 `WIZARD_FIELD_MANIFEST`，按 §4.2 的路径格式而非裸标签）程序化生成"每个 leaf 字段填入占位值、每张表格填入一行合成数据（或写入含 `(confirmed via setup wizard)` 字面短语的哨兵行）"的内容，覆盖 5 个目标文件；重跑 `check_setup.py --json`；断言 `returncode == 0`、`complete == True`、`filled == 5`、`total == 5`、`gate_blocking == False`、`todo_count == 0`。**不复用 `examples/mock-project` 作为该 fixture**——已核实 mock-project 的 `data-sources.md`/`environment.md`/`control-contract.md`/`self-check.md` 结构落后当前模板，若拿它当"填满"参照会让本断言对着一份过时结构自证通过。程序化生成 fixture 并直接从 `check_setup` 自身的字段清单派生，可保证两者永不失步。
3. **用法错误 = exit 2**：对不存在的项目路径运行 `check_setup.py --project <not-a-dir>`；断言 `returncode == 2`（与 `verify_protocol.py` 现有的错误退出码约定一致）。
4. **partial + 非核心文件缺口 = 不阻塞（M1 核心断言）**：在步骤 2 的 fixture 基础上，仅清空 `setup/data-sources.md` 的 `External Tools And Platforms` 表（去掉数据行与哨兵行，恢复模板原状），重跑；断言该文件 `state == "partial"`、`complete == False`、但 `gate_blocking == False`（因为 3 个核心文件仍 filled）、`todo_count` 不变。这是对 M1 修复的直接回归断言，防止未来改动重新引入"任意 partial 都短路"的旧 bug。
5. **核心文件 template = 阻塞（M1 核心断言）**：在步骤 2 的 fixture 基础上，改为仅清空 `state/control-contract.md`（恢复为模板原状，其余 4 个文件保持 filled），重跑；断言 `gate_blocking == True`、`next_step` 指向 `control-contract.md`。
6. **TODO 可见性断言（M1 配套）**：在步骤 2 的 fixture 基础上，把 `setup/cost-context-policy.md` 的某一个字段值改写为字面 `TODO (owner: user)`；重跑；断言该文件仍判定为 `filled`（字面 TODO 值算已填，行为不变），但 `todo_count >= 1`——证明"字面 TODO 可以让文件变 filled，但不会让这件事变得不可见"。

### 7.3 无需新增断言的部分

- `claude plugin validate --strict` 覆盖新 skill：`validate_claude_strict()` 已对 `REPO_ROOT` 与 `PLUGIN_ROOT` 跑严格校验，只要 `harnessloop-setup/SKILL.md` frontmatter（`name`/`description`）合规，新技能会被自动纳入，**无需修改 `validate.py` 本节代码**，只是对新 SKILL.md 的写作要求（round 2 实现时需满足）。
- `validate_doc_consistency()`：该阶段检查文档骨架树是否列全 `init_project.py` 的 `BASE_FILES`/`BASE_DIRS`。本设计不新增骨架文件/目录（`check_setup.py` 只读取既有 5 个文件），故该阶段**无需改动**。

---

## 8. plugin.json / marketplace.json 处置

### 8.1 `skills` 字段是否自动纳入新目录：是，无需改动

`plugins/harnessloop/.claude-plugin/plugin.json` 与 `.codex-plugin/plugin.json` 的 `skills` 字段均为目录级通配（`["./skills/"]` / `"./skills/"`），指向整个 `skills/` 目录而非逐个技能列举。核实方式：查看 `harnessloop-secrets` 技能被引入时的提交（`5c35a22 feat: add local channel parameter management`），该提交新增了整个 `plugins/harnessloop/skills/harnessloop-secrets/SKILL.md`，但两份 `plugin.json` 的 `skills` 字段本身**未发生任何改动**（该提交对 `plugin.json` 的唯一改动是 `version` 字段）。因此 `harnessloop-setup/` 目录只要存在且含合规 `SKILL.md`，会被同一套目录级发现机制自动纳入，**不需要修改 `skills` 字段**。

### 8.2 版本号：0.10.0 → 0.11.0（已获批准；S7 修正先例叙述）

理由（同一先例 `5c35a22` 提交）：该提交新增一个技能（`harnessloop-secrets`）时，同步把四处 `version` 提升：

- `package.json`：`0.7.0` → `0.8.0`
- `plugins/harnessloop/.claude-plugin/plugin.json`：`0.7.0` → `0.8.0`
- `plugins/harnessloop/.codex-plugin/plugin.json`：`0.7.0` → `0.8.0`
- `.claude-plugin/marketplace.json`（插件条目 `version`）：`0.1.0` → `0.8.0`（**S7 修正**：v1 曾误写此处原值也是 `0.7.0`，实际核实 `.claude-plugin/marketplace.json` 该字段原值是 `0.1.0`，与其余三处不同；这一笔误不影响结论——四处最终值仍统一收敛到 `0.8.0`，只是起点不同）

本批新增一个技能（`harnessloop-setup`）+ 一支新脚本（`check_setup.py`）+ 四处现有技能文本接线 + 一个新 validate 阶段，性质与该先例一致，已获主会话批准（`rounds/0001/decision.md` Open Questions Resolved），按相同幅度（+1 次版本）从 `0.10.0` 升到 `0.11.0`，需改动的 4 个文件与先例完全对应（同上列表，起点统一为 `0.10.0`）。

`.agents/plugins/marketplace.json`（codex marketplace）核实其插件条目本身**不含 `version` 字段**（只有 `name`/`license`/`source`/`policy`/`category`），故该文件**无需改动**。

### 8.3 codex `plugin.json` 的 `defaultPrompt` 需要追加新技能名（已获批准）

`plugins/harnessloop/.codex-plugin/plugin.json` 的 `interface.defaultPrompt` 是一句列出全部技能名的提示语；同一先例提交（`5c35a22`）在新增 `harnessloop-secrets` 时同步把它加入了这句提示语的技能列表。本批新增 `harnessloop-setup` 后同步更新（v1 列为待确认项，本轮已获批准，纳入正式实现范围）：

```diff
- "defaultPrompt": "Use explicit skill names such as $harnessloop-init, $harnessloop-goal, $harnessloop-evidence, $harnessloop-channels, $harnessloop-connectivity, $harnessloop-secrets, $harnessloop-delegation, $harnessloop-status, $harnessloop-continue, $harnessloop-intake, $harnessloop-issue, or $harnessloop-loop. Treat harnessloop:init and other harnessloop: aliases as natural-language phrases only."
+ "defaultPrompt": "Use explicit skill names such as $harnessloop-init, $harnessloop-setup, $harnessloop-goal, $harnessloop-evidence, $harnessloop-channels, $harnessloop-connectivity, $harnessloop-secrets, $harnessloop-delegation, $harnessloop-status, $harnessloop-continue, $harnessloop-intake, $harnessloop-issue, or $harnessloop-loop. Treat harnessloop:init and other harnessloop: aliases as natural-language phrases only."
```

---

## 9. Acceptance Criteria 覆盖对照表（M1/M2 修复后全部 covered）

| # | goal.md 验收标准 | 本设计覆盖章节 | 覆盖方式摘要 |
| --- | --- | --- | --- |
| 1 | 新 skill `harnessloop-setup` 存在且通过 `claude plugin validate --strict` | §1.2、§3、§7.3、§8.1 | 新技能目录经 `./skills/` 通配自动纳入；`validate_claude_strict()` 现有阶段自动覆盖，无需新断言，只需 SKILL.md frontmatter 合规 |
| 2 | 五步流程：环境自动检测→data-sources 引导→cost-context-policy 确认→control-contract 档位选择（lite/standard/strict 预设）→self-check 汇总+完成度 N/5 报告 | §3、§5、§2 | 五步逐一详细设计；三档预设全量文本（M3 已对齐 evidence 硬约束）；首跑/重跑对话示例含完成度 N/5 报告文案与双层门状态展示 |
| 3 | 每步可跳过且跳过必记 TODO 到 self-check | §3（通用规则）、§2.2 重跑示例 | **v1 曾判定 partial（跳过语义与门短路矛盾），v2 已修复**：统一跳过语义——不写编造值，改为 `self-check.md` 的 `Action` 字段追加 `TODO (owner: user)` 记录；跳过是否阻断由 §4.4 的 `gate_blocking` 精确定义（仅 3 个核心文件的 template 状态阻断），不再是"任意不完整都锁死" |
| 4 | `check_setup.py`（或 `verify_protocol` 扩展）返回机器可读完整度 | §4 全节 | **v1 曾判定 partial（§4.3 算法对重复标签无作用域，不可无歧义实现），v2 已修复**：M2 的小节容器路径匹配规则 + 29/24/21/12 条完整路径清单，使算法可无歧义实现；独立脚本（非扩展 verify_protocol，理由见 §4.1）；接口新增 `gate_blocking`/`todo_count`；退出码/3.9 兼容/路径解析/零写入保证全部给出 |
| 5 | status 输出 setup-incomplete 状态与"缺什么/下一步" | §6.2 | `state` 枚举新增 `setup-incomplete`；Output Contract 新增 `setup completeness`/`setup gate`/`todo count`/`setup next step` 字段；Processing Contract 新增调用 check_setup 的步骤（`-B` 保证零写入） |
| 6 | continue 门对 setup-incomplete 返回 needs-setup | §6.3 | **v1 曾判定 partial（无条件短路与"可跳过"承诺矛盾，实测锁死本项目），v2 已修复**：短路条件改为 `gate_blocking`（仅核心文件 template/missing 时短路），`complete=false` 但 `gate_blocking=false` 时降级为警告并放行；`decision` 枚举新增 `needs-setup`；Output Contract 新增 `setup gate`/`todo count` 字段 |
| 7 | init 交接语指向 setup wizard | §6.1 | 第 90 行 `Next recommended prompt` 精确 diff；第 35 行（原 v1 开放问题）已获批准同步修正 |
| 8 | loop SKILL:114 触发条件修正为"目录不存在或 setup 未完成" | §6.4、§10 风险 1 | 对第 69 行（实际触发条件句）与第 114 行（ask-user 指令句）均给出修正 diff（触发条件精确为 `gate_blocking: true`），第 114 行同步获批准加入 `control-contract-profiles.md` 引用；并如实标注与 goal.md 行号引用的差异 |

汇总：**8/8 covered**（v1 为 5 covered / 3 partial，M1/M2 修复后 AC3/AC4/AC6 三项 partial 全部转为 covered；无 missing）。

---

## 10. 风险与开放问题

1. **goal.md 行号引用与实际文件行号不一致**（沿用 v1，未变更）：验收标准第 8 条写"loop SKILL:114 触发条件修正"，但直接读取当前 `harnessloop-loop/SKILL.md` 核实，"若 `.harnessloop/` 不存在"这一触发条件句位于第 69 行；第 114 行是另一句（"During setup, ask the user to fill in data-source connection requirements"）。本设计对两处都给出了修正方案（§6.4），但最终验收时按哪一行号核对文本需要主会话或用户确认。
2. **本项目自身 `setup/data-sources.md` 的 External Tools 哨兵行缺失**（decision.md 已裁决，非本轮阻塞项）：按 §4.3 判定规则，该表 0 行且无哨兵行会判定为 partial，使 `data-sources.md` 非 filled、`complete=false`；但因该文件不在 `gate_blocking` 三文件之列，**不会**短路 continue/loop（M1 修复的直接效果）。decision.md 已裁定：这一缺口由用户 live 首跑 wizard 时补齐，非本轮设计修订的阻塞项，不再是需要设计层面解决的矛盾（v1 时这一缺口曾与门语义矛盾交织在一起，v2 修复后两者已解耦）。
3. **三档默认值文案与 lite 档最终措辞需用户验收时确认**：goal.md `Required Human Decisions` 已列；M3 修复后 lite 档的 `Evidence contract revision` 措辞已对齐协议硬约束，但整档取值（尤其"Scope-lock mutation 不需要人工确认"）仍需用户最终确认。
4. **`thresholds.md`/本项目 `data-sources.md` 的"7/7"文本需要同步更新为"8/8"，且该变更本身需要人工确认**（S4 新增）：`thresholds.md:15` 与本项目 `setup/data-sources.md:16/:24` 会因 `[N/7]→[N/8]` 重编号而过期；按 `thresholds.md` 自身的 `Threshold Change Policy`（"Requires human confirmation: yes"），这一文本同步**本身**构成一次阈值变更，需要用户确认后才能在实现轮落地，已列入本节新增的 Required Human Decision（见下）。
5. **`control-contract-profiles.md` 放置位置**：`harnessloop-loop/references/`（与其余 27 个模板同目录）；loop SKILL.md 的引用行已获批准并入 §6.4 的 :114 diff，不再是独立开放项（v1 §10 风险 4 已解决）。
6. **`harnessloop-init/SKILL.md:35` 已获批准同步修正**（v1 §10 风险 5 已解决），diff 见 §6.1。
7. **codex `plugin.json` 的 `defaultPrompt` 技能列表已获批准同步**（v1 §10 风险 6 已解决），diff 见 §8.3。
8. **字段清单（manifest）与模板耦合、无自动漂移检测**（沿用 v1，未变更）：§4.2 的 90 槽位清单（含 M2 新增的完整路径）是针对当前 `references/` 模板结构手工穷举的；日后任何模板字段增删都需要同步更新 `check_setup.py`，且目前没有机械手段检测两者是否已经不同步。建议列为后续增强方向，本轮不实现。
9. **provenance 标注是本设计新引入的约定**（沿用 v1，未变更）：`(detected)`/`(user-confirmed)`/`(default-accepted)` 后缀标注不是既有模板/协议要求，只在 wizard 新写入的内容里使用；test-harnessloop 自身现有的已填文件不追溯改造，不在本任务范围。
10. **委派探针局限的诚实边界**（沿用 v1，未变更）：S1 环境检测里"Can create independent task"等 4 项若本会话内没有可引用的真实委派证据，必须如实写 `unknown`，不得因协议描述委派可用就推断为 `pass`。这是协议反虚构原则下的必然代价，非实现缺陷。
11. **未纳入本次范围但相关的发现**（对应 §1.4 的 deferred 项）：cost-prices.json 引导创建、init 是否检测 git 仓库、脚本直跑路径后续指引、`init-project.sh` 裸 python 预检——均不在本 goal 范围，留作独立后续任务。
12. **`verify_protocol.py` nm11 修复（TH-0006）与本文档的依赖关系**：本文档及 round 0002 的对抗性复审文件中引用的正则模式字符串、笔误路径原文引述，在 nm11 修复落地前可能被 `verify_protocol.py` Rule B 误判为悬空引用（如 round 0001 评审文件已实测的 6 条误报）；`rounds/0002/scope-lock.md` 已将这类已归档误报类别排除在本轮机械门判定之外，不影响本轮 negative/positive 判定的有效性，但复审者在解读机械门输出时应对照 TH-0006 的已知误报类别，不应因误报本身而判定 negative。
13. **M2 匹配算法的性能/边界未做压力测试**（新增）：§4.3 的"容器切片"定位依赖"容器行后紧跟子级列表"这一启发式；若未来某个模板出现三层及以上嵌套（当前 5 个模板均只嵌套两层：heading > container > leaf），或容器行与叶子行的文本模式发生特殊冲突（如叶子标签本身也以冒号结尾且后面紧跟另一个列表——当前 5 个模板未出现此情况），算法可能需要扩展。建议实现轮为 §4.2 给出的全部 90 条路径各写一条单元测试，覆盖当前已知结构；不在本设计范围内预先解决假设中的未来模板结构。

### Required Human Decisions 增补（相对 goal.md 原有 2 项）

goal.md 原有：(a) 档位预设默认值内容在验收时确认；(b) live acceptance 运行。v2 新增：

- (c) `thresholds.md:15` 与本项目 `setup/data-sources.md:16/:24` 的"7/7"→"8/8"文本同步，按 Threshold Change Policy 需人工确认（本节风险 4）。
- (d) lite 档 `Evidence contract revision` 措辞（已按 M3 对齐协议硬约束，但档位整体取值仍随 (a) 一并确认）。
