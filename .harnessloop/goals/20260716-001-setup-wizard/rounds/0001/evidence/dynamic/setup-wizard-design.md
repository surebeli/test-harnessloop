# Setup Wizard 实现级设计文档

- Goal: `.harnessloop/goals/20260716-001-setup-wizard/goal.md`
- Round: 0001（设计轮，非实现轮；本文档不改动 `harnessloop/` submodule 任何文件）
- 需求依据：`docs/harnessloop-review-20260716.findings.json` 中 `lens: guided-setup` / `lens: auto-detection` 的 CONFIRMED 条目（共 17 条，逐条覆盖见第 9 节）
- 格式权威：`harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/` 模板目录（submodule HEAD `66093fd`）
- 交叉验证素材：本项目（test-harnessloop）自身 `.harnessloop/setup/`、`.harnessloop/state/` 文件（已按当前模板填写，作为"filled"参照）；`harnessloop/examples/mock-project/`（**不作为格式权威**——其 `data-sources.md`/`environment.md`/`control-contract.md`/`self-check.md` 结构已系统性落后当前模板，本项目自身 `data-sources.md` 明确记录了这一点）

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

`docs/harnessloop-review-20260716.findings.json` 中 guided-setup/auto-detection lens 的 17 条 CONFIRMED 发现共同指向一个缺口：`$harnessloop-init` 产出 12 个空模板文件后，**没有任何 skill 环节主动驱动逐项填写**。根因链：

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
| `check_setup.py` | `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（新，理由见 §4.1） | 机械判定 5 个 setup/state 文件的完整度，供 wizard/status/continue/loop 共用 |
| 四处接线 | init / status / continue / loop 四份 `SKILL.md` | 文本级 diff，见 §6 |
| `control-contract-profiles.md` | `harnessloop-loop/references/`（新） | lite/standard/strict 三档完整预设内容，供 wizard S4 引用 |

### 1.3 范围边界（复述 goal.md Non-Goals，防止设计蔓延）

- 不改 intake 流程。
- 不做 data-sources 的 repo 自动扫描（`.github/workflows`、`package.json` 等扫描是后续增强，本设计只做"会话内可观察事实"的自动检测，即环境/委派能力，不做仓库内容扫描）。
- 不重构 loop SKILL 全文，只改 :69 和 :114 两处直接相关语句。
- 不重生成 `examples/mock-project`。
- 不改证据枚举（`evidence-index-template.md` 结构不变）。

---

## 2. 用户旅程

### 2.1 首跑路径（骨架项目，5 个文件均为 `template` 状态）

```
用户: $harnessloop-setup

Agent: 运行 check_setup.py --project . --json → complete=false, filled=0/5。
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

Agent: 已写入 state/environment.md（21/21 字段，provenance 标注见文件）。
       [S1/5 完成] → 进入 S2。

       [S2/5 数据源引导]
       逐类询问，你可以对任意一类回答"没有"：
       Q2: Static Sources（真实静态数据，如样本文件/CSV/schema）——这个项目有吗？
           访问方式？验证方法？

用户: 有一个 docs/harnessloop-review-20260716.findings.json，本地文件读取，
      用 JSON 结构校验。

Agent: 记下。
       Q3: Dynamic Or Generated Sources（动态/生成数据）——有吗？

用户: 没有。

Agent: 好，写入 "_No dynamic or generated sources declared for this project
       (confirmed via setup wizard)._" 哨兵行，check_setup 会把这类识别为"已回答"
       而非"未触碰"。
       Q4: Runtime Validation Systems（跑测试/验证的命令）——有吗？

用户: npm run validate（仓库根）。

Agent: 记下，验证方法="7 阶段全绿"。
       Q5: External Tools And Platforms（CI、数据库、第三方 API 等）——有吗？

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

Agent: 已写入 setup/cost-context-policy.md（29/29 字段）。→ 进入 S4。

       [S4/5 Control Contract 档位选择]
       三档预设（完整内容见 references/control-contract-profiles.md）：
         - lite: 个人/低风险项目，positive 或 runtime-recoverable 类调查自动续跑，
           仅外部写/失败评审接受需人工
         - standard（默认）: positive 且证据全 valid 时自动续跑，evidence/control
           契约变更需人工
         - strict: 涉外部系统/敏感数据，即使条件全满足仍需人工确认才续跑
       选哪档？

用户: standard。

Agent: 展示 diff（当前 control-contract.md 是全空模板 → standard 档 24/24 字段）后写入。
       → 进入 S5。

       [S5/5 汇总]
       写入 state/self-check.md：
         Setup files present: pass（5/5 filled）
         Environment policy recorded: pass
         Control contract recorded: pass（standard 档）
         ...
         Action: setup 完成，无 TODO。
         Last checked: 2026-07-16

       Setup 完成度: 5/5。
       下一步: 使用 $harnessloop-goal propose 起草第一个 goal，或
       $harnessloop-loop 进入主协议。
```

### 2.2 重跑 / 审阅路径（部分已填的项目）

```
用户: $harnessloop-setup

Agent: 运行 check_setup.py --project . --json →
       complete=false, filled=2/5
       (environment.md=filled, cost-context-policy.md=filled,
        data-sources.md=partial[missing: External Tools And Platforms],
        control-contract.md=template, self-check.md=template)

       这是审阅模式：已完成 2/5，我只补缺口，不会重问已填项。

       [S1] environment.md 已 filled，跳过。
       [S2] data-sources.md 部分已填。已有 Static/Dynamic/Runtime 三类记录；
            只缺 External Tools And Platforms 一类。这个项目有外部工具/平台吗？

用户: 跳过，还没想好。

Agent: 记为 TODO。写入 self-check.md 的 Action 字段:
       "TODO (owner: user): S2 data-sources External Tools And Platforms 未确认，
        setup wizard 2026-07-16 跳过。"
       [S3] cost-context-policy.md 已 filled，跳过。
       [S4] control-contract.md 仍是原始模板，需要选择档位。三档见 references/
            control-contract-profiles.md，选哪档？

用户: lite。

Agent: 展示 diff（全空 → lite 档 24/24 字段）后写入。
       [S5] 汇总:
       Setup 完成度: 4/5（filled 文件计数；data-sources.md 因跳过一类仍算 partial）
       Action: "1 项 TODO 待补：S2 External Tools And Platforms（owner: user）"
       下一步: 该 TODO 不阻塞 $harnessloop-loop 主协议执行（External Tools 不是
       任何已声明 goal 的强制依赖），但下次 $harnessloop-status 会持续提示。
```

---

## 3. 五步详细设计

通用规则（跨全部 5 步）：

- **展示现状 → 提议 → 用户确认/修改/跳过** 是唯一交互模式；不得先写入再询问。
- 每个 agent 自动填的值必须标注 provenance：`detected`（会话内零成本可观察）/ `user-confirmed`（用户对提议的确认或修改）/ `default-accepted`（用户接受协议默认策略而未定制）。写法是在字段值后追加 `(detected)` / `(user-confirmed)` / `(default-accepted)`，不改变字段本身的可解析性（check_setup 的空白判定看的是冒号后是否有内容，不受后缀影响）。
- 跳过 = 不写入该字段的编造值；改为在 `state/self-check.md` 的 `Action` 字段追加一条 `TODO (owner: user): <step> <what> — skipped at setup wizard on <date>`。字段本身留空（模板原状），使 check_setup 能如实识别为未完成。
- 涉及凭证/密钥的字段：wizard 自身不接收、不写入任何密钥值；一旦用户表示某数据源/工具需要凭证，转交 `$harnessloop-secrets add channel <id> key <NAME> --sensitivity secret --storage <...>`，`data-sources.md` 里只记参数名/存储方式，不记值。
- 幂等：wizard 每次调用先跑 `check_setup.py --json`。若 `complete: true`，直接报告"已完整，5/5"并停止（不重复提问）。若部分完整，进入审阅模式：`state == filled` 的文件整段跳过（仅报告一行"已完整，跳过"）；`state == partial` 的文件只问 `missing_sections` 里列出的缺口；`state == template` 或 `missing` 的文件走完整首跑对话。

### S1 环境自动检测 → `state/environment.md`

对照 `environment-self-check-template.md` 的 4 个小节、21 个字段：

- **可自动检测（provenance=detected，零成本，来自本会话可观察事实）**：
  - `Detection` 全部 4 个字段：Detected environment（来自系统提示/运行时标识）、Detected from、Available tools（当前会话工具枚举）、Unavailable tools。
  - `Delegation` 的 `Expected mechanism`/`Observed mechanism`（Agent/Task 工具是否存在）。
  - `Model And Effort` 的 `Observed model`（系统提示自证的模型 ID）。
  - `Result` 的 `Last checked`（当前时间戳）。
- **需要一次委派探针才能验证（不得凭空声称）**：`Can create independent task` / `Can constrain read/write scope` / `Can require output path` / `Can verify evidence citations` 四项。wizard 若在本会话内已有过一次真实委派（例如本轮设计本身就是一次子代理委派），可引用该次委派的实际产出作为证据（provenance=detected，附引用路径）；若没有可引用证据，如实写 `unknown`，不得推断为 `pass`。**局限如实记录**：委派探针只能验证"这次委派做到了什么"，不能验证"每次都会做到"，`Residual risk` 字段必须写明这一点。
- **必须问用户（provenance=user-confirmed 或 default-accepted）**：`Expected model`/`Expected effort/reasoning`（来自 S3 定的 cost-context-policy，若 S3 未跑则先问）、`Mismatch action`。
- **写死值**：`Verification method` 写实际使用的检测方式（如"系统提示自证 + 一次委派探针"），不得写"未执行"这类占位（除非确实没有委派证据）。
- 跳过：只允许跳过 `Expected model/effort` 与 `Mismatch action`（其余是零成本检测，没有"跳过"的意义，若确实检测不到就如实写 `unknown` 并非"跳过"）。跳过时记 TODO。

### S2 data-sources 引导 → `setup/data-sources.md`

按 4 类分别问（不含 `Local Channel Parameters`——那张表由 `$harnessloop-secrets` 管理，不由 wizard 直接询问填写；也不含 `Secret Handling` 说明段——协议固定文案，非用户输入）：

1. **Static Sources**：真实静态数据源。逐个问：来源、访问方式、新鲜度要求、漂移风险、验证方法、凭证需求。
2. **Dynamic Or Generated Sources**：动态/生成数据。同上字段（用 Generator/tool 代替访问方式）。
3. **Runtime Validation Systems**：跑测试/验证的命令或系统。问：访问方式、验证方法、通过条件、失败处理、凭证需求、本地参数引用。
4. **External Tools And Platforms**：CI、数据库、第三方 API、账号体系。问：用途、读写范围、账号角色、验证方法、失败处理、本地参数键名。

每一类允许回答"没有"；回答"没有"时，wizard 必须在该表下方写入固定哨兵行（check_setup 依赖这行区分"未触碰"与"确认为空"）：

```
_No <category> declared for this project (confirmed via setup wizard)._
```

`<category>` 用该类别的模板小节标题（如 `dynamic or generated sources`）。

若某数据源提到需要凭证：不在本文件记录任何值，转交 `$harnessloop-secrets`；本文件对应行的"Credential requirement"列只记参数名/是否需要，格式与既有约定一致。

跳过：允许对任意一类整体跳过（不问、不写哨兵行），此时该类保持模板原状（0 行），并在 self-check.md 记 TODO。

### S3 cost-context-policy 默认值展示与确认 → `setup/cost-context-policy.md`

不是询问式，是**展示式**：把协议 `Role And Model Rules`/`Core Contract` 里已经写死的默认策略（Main Session 职责、不得占用上下文的三类、可委派/不可委派清单、Codex/Claude Code 模型偏好）渲染成 `cost-context-policy-template.md` 的 29 个字段值，一次性展示给用户确认或点名修改。这不是虚构项目事实——协议自身的 `Role And Model Rules` 一节就是这些默认值的来源（可引用 `harnessloop-loop/SKILL.md:381-422` 作为出处）。

不覆盖的部分：`Execution Delegation Matrix` 表（8 行 Decision 列本就是模板自带的协议级预填内容，非本步骤的问答对象，直接原样写入不算"用户输入"）。

用户确认路径：全部接受（provenance=default-accepted）或逐项修改（provenance=user-confirmed）。跳过：整节跳过则该文件保持模板原状，记 TODO；不支持部分字段跳过（29 个字段一次性展示，逐项确认/修改的交互粒度已经足够低摩擦，不需要更细的跳过语义）。

### S4 control-contract 档位选择 → `state/control-contract.md`

1. 展示三档摘要（完整内容见 §5，运行时引用 `references/control-contract-profiles.md`）。
2. `AskUserQuestion` 单选：lite / standard / strict。
3. 选定后，生成"当前文件（模板原状或已有内容）→ 该档位完整内容"的 diff，展示后再写入（不静默覆盖）。
4. 若这是重跑且文件已部分手填（不太可能，因为这是唯一没有"部分回答"概念的步骤——24 个字段要么整档套用要么维持原样），仍先展示 diff。
5. 跳过：不选档位，文件保持原状，记 TODO；下次重跑视为 `template` 状态重新进入本步骤。

### S5 汇总 → `state/self-check.md`

1. 重新跑一次 `check_setup.py --project <target> --json`（S1-S4 写入后的最终态）。
2. 按 `self-check-template.md` 的 12 个字段填值：
   - `Setup files present`: pass/partial + 本次 5 文件的 filled 计数。
   - `Environment policy recorded` / `Control contract recorded` / `Evidence index recorded` / `Self-audit present` / `Runtime validation described` / `Data/tool access described` / `Local channel parameter store protected` / `Delegation model verified` / `Intake gate required`：分别引用 S1-S4 的产出状态（`Evidence index recorded`/`Self-audit present`/`Intake gate required` 不属于 wizard 五步范围，如实写"不适用于 setup 阶段，由 loop 首轮维护"或按现状读取，不得凭空写 pass）。
   - `Action`: 若全部完成写"setup 完成，无 TODO"；否则列出每条 TODO（含 owner、跳过的具体子项、时间戳）。
   - `Last checked`: 当前时间戳。
3. 输出对用户可见的完成度：`Setup 完成度: N/5`（N = check_setup 报告的 `filled` 计数），并给出下一步：
   - `N == 5`：建议 `$harnessloop-goal propose <一句话目标>` 或 `$harnessloop-loop`。
   - `N < 5`：列出仍缺的具体文件+缺口，建议"下次运行 $harnessloop-setup 会自动进入审阅模式，只问剩余项"。

---

## 4. check_setup 规则与接口

### 4.1 放置位置：`harnessloop-loop/skills/harnessloop-loop/scripts/check_setup.py`（不放 `harnessloop-setup/scripts/`）

理由：

1. **复用已验证的路径解析模式，直接规避 TH-0003**：`init_project.py`/`verify_protocol.py`/`round_cost.py` 均已用 `SKILL_DIR = Path(__file__).resolve().parents[1]` 定位自身技能目录，`check_setup.py` 放在同目录可原样复用这一行，不引入新的相对路径写法。
2. **单一事实来源**：`check_setup.py` 需要"文件 → 模板"的映射，`init_project.py` 里的 `BASE_FILES` 字典已经是这份映射的权威来源；同目录下可以直接 `import init_project` 复用其 `read_template()`（模板围栏代码块提取逻辑）与 `BASE_FILES`，避免维护第二份可能漂移的映射表。
3. **跨技能调用方向一致**：当前协议里被 `status`/`continue`/`loop` 三个技能共同引用的机械脚本只有 `harnessloop-loop/scripts/` 下的几支（`verify_protocol.py`、`round_cost.py`）；把 `check_setup.py` 放进同一目录延续了"被多个技能读取的机械脚本统一放 loop/scripts/"的现有惯例。若放进 `harnessloop-setup/scripts/`，会引入一个新方向的跨技能依赖（其它技能反过来读取 `harnessloop-setup` 的脚本），协议里目前没有这种先例（`harnessloop-secrets/scripts/channel_params.py` 只被 secrets 自己使用）。
4. `harnessloop-setup` 技能本身定位是"纯 SKILL.md 驱动的对话"，不需要专属脚本目录；它只是 `check_setup.py` 的众多调用方之一。

### 4.2 字段清单（manifest）：5 个文件、90 个可判定槽位

不采用"通用 markdown 语义 diff"，而是对每个文件的模板结构做穷举式字段清单（analogous to `verify_protocol.py` 只做机械规则，不做通用语义判断）。清单与模板结构一一对应，模板变更时需同步更新（见 §10 风险）。

两类槽位：

- **leaf 字段槽位**：模板里"以冒号结尾、其后为待填内容"的行（可能是裸行 `Label:`，也可能是列表项 `- Label:`），且**不是**紧跟一个子列表/表格的"容器行"（容器行只是分组标题，如 `Allowed when:`、`Responsibilities:`，本身不计入槽位，只计其子项）。
- **表格槽位**：模板里的一张 markdown 表。若该表在**原始模板**中的数据行数即为 0（即需要用户/wizard 填入至少一行，或写入 §3 定义的 none 哨兵行才算"已回答"），计入槽位；若原始模板本身就自带非空数据行（即协议级预填的样板内容，如 `control-contract-template.md` 的 Blocker Classification 表、`cost-context-policy-template.md` 的 Execution Delegation Matrix 表），**不计入槽位**（这类表不是用户决策点，永远视为已满足，不参与完整度计分）。

逐文件槽位清单：

| 文件 | 模板 | leaf 字段数 | 表格槽位 | 合计 |
| --- | --- | --- | --- | --- |
| `state/environment.md` | environment-self-check-template.md | 21（Detection 4 + Delegation 6 + Model And Effort 7 + Result 4） | 0 | 21 |
| `setup/data-sources.md` | data-sources-template.md | 0 | 4（Static / Dynamic Or Generated / Runtime Validation Systems / External Tools And Platforms；`Local Channel Parameters` 与 `Secret Handling` 明确排除，前者归 `$harnessloop-secrets` 管理，后者是协议固定说明文字） | 4 |
| `setup/cost-context-policy.md` | cost-context-policy-template.md | 29（Main Session 3+3 + Delegation Rules 5+5 + Model Policy 4+4 + Handoff Budget Rules 5；Execution Delegation Matrix 表排除——模板自带 8 行预填 Decision 列，非用户决策点） | 0 | 29 |
| `state/control-contract.md` | control-contract-template.md | 24（Auto-Continue 5 + Human Confirmation Required 6 + Stop Conditions 6 + Delegation Boundaries 3 + Acceptance Authority 4；Blocker Classification 表排除——模板自带 7 行预填） | 0 | 24 |
| `state/self-check.md` | self-check-template.md | 12 | 0 | 12 |
| **合计** | | **86** | **4** | **90** |

交叉验证：control-contract 的 24 个 leaf 字段与本设计所依据的 CONFIRMED 发现（auto-detection lens，"control-contract 没有 lite/standard/strict 预设档位"条目）独立统计的"24 个空政策字段"完全一致，佐证清单未遗漏或多算。

### 4.3 空/满判定算法

对每个 leaf 字段：

- 在目标文件中定位与模板同名的 `Label:` 行（裸行或 `- Label:`，允许前导 `#`/`-`/空格差异）。
- 取冒号后剩余文本，去除首尾空白。
- 判定为空（blank），当且仅当：(a) 剩余文本为空字符串；或 (b) 剩余文本与**模板原文**该行冒号后的文本逐字相同（覆盖模板自带枚举提示如 `codex | claude-code | other | unknown` 被原样抄录、从未替换的情况）。
- 否则判定为已填（filled）——**注意**：值为字面 `TODO (owner: user)` 也算"已填"，因为这是协议认可的显式声明（"检测不到就问，问不到就 TODO"），区别于"从未触碰"的空白模板行。这与本项目自身 `state/current.md` 等文件里大量出现 `TODO (owner: user)` 但整体被视为"已建立、非骨架状态"的既有事实一致。
- 若目标文件中完全找不到该 `Label`（结构被破坏/字段被删除），判定为 missing，计入未填。

对每个表格槽位：

- 定位模板中对应 `## Heading`（或表格紧邻的小节标题）在目标文件中的同名小节。
- 统计表头分隔行（`| --- | ... |`）之后、下一个 `##` 标题之前的非空数据行数。
- 若 ≥ 1 行 → 已填。
- 若 0 行，检查同一区间内是否存在匹配 `^_?\s*(no|none)\b.*declared.*_?$`（忽略大小写、忽略首尾的 markdown 斜体下划线）的哨兵行 → 已填（"显式确认为空"）。
- 否则 → 未填。

文件级状态：

- `template`：该文件全部槽位为未填（近似等于 `init_project.py` 刚写入时的原始状态）。
- `filled`：该文件全部槽位为已填。
- `partial`：介于两者之间。
- `missing`：文件不存在。

`missing_sections`：未填槽位的人类可读路径列表，如 `["Model And Effort > Observed model", "Runtime Validation Systems"]`。

### 4.4 CLI 与输出

```bash
python <plugin-root>/skills/harnessloop-loop/scripts/check_setup.py --project <target-project> [--json]
```

人可读输出（默认）：

```text
Harnessloop setup check: <project>
  state/environment.md: filled (21/21)
  setup/data-sources.md: partial (3/4) — missing: External Tools And Platforms
  setup/cost-context-policy.md: filled (29/29)
  state/control-contract.md: template (0/24)
  state/self-check.md: template (0/12)
Setup completeness: 2/5 files fully filled.
Next setup step: state/control-contract.md (run $harnessloop-setup)
```

`--json` 输出（与 handoff 指定的机器格式一致，另附字段级细节作为非破坏性补充）：

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
  "next_step": ".harnessloop/state/control-contract.md"
}
```

`files`/`complete`/`filled`/`total` 四个键是 handoff 硬性要求的最小机器格式；`fields_filled`/`fields_total`/`next_step` 是附加细节，供 status/continue/wizard 复用，不破坏最小契约。

### 4.5 退出码

- `0`：`complete: true`（5/5 filled）。
- `1`：`complete: false`（至少一个文件非 filled）。
- `2`：用法/环境错误——项目目录不存在、`references/` 目录不存在、目标模板文件缺失（这些是打包/环境问题，不是"未完成"，与 `verify_protocol.py` 现有的 2 号退出码语义一致）。

### 4.6 Python 3.9 兼容性与路径解析（吸取 TH-0001/TH-0003）

- 顶部 `from __future__ import annotations`，沿用 `init_project.py` 现有写法。
- 不使用 `Path.write_text(..., newline=...)`（3.10+ 独有）——`check_setup.py` 本身不写任何文件（纯读取判定），此条主要作为约束记录，防止后续给它加"自动补哨兵行"之类功能时重蹈 TH-0001。
- 不使用 `match`/`case`（3.10+）、不使用仅 3.10+ 的 `X | Y` 写法在需要运行时求值的位置（配合 `from __future__ import annotations` 可用在类型注解位置）。
- `str.removeprefix`/`str.removesuffix` 可用（3.9+ 已支持，`validate.py` 已依赖此下限）。
- 模板目录解析：`SKILL_DIR = Path(__file__).resolve().parents[1]`；`REFERENCES_DIR = SKILL_DIR / "references"`——与 `init_project.py:13-14` 完全一致，不依赖 cwd 或仓库根。

---

## 5. 三档预设完整内容（lite / standard / strict）

存放位置：`harnessloop-loop/references/control-contract-profiles.md`（新文件，实现轮创建；本设计给出全部落地文本）。三档均覆盖 `control-contract-template.md` 的全部 24 个 leaf 字段，`Blocker Classification` 表三档一致，直接照录协议原有 7 类（不新增/不删减，档位差异只体现在 Auto-Continue/Human Confirmation/Stop Conditions/Delegation Boundaries/Acceptance Authority）。

### 5.1 Auto-Continue（Allowed when）

| 字段 | lite | standard（默认） | strict |
| --- | --- | --- | --- |
| Feedback class | positive；或 negative/neutral 且下一步是只读调查/最小修复/本轮 scope-lock 内回滚 | positive | positive，且本轮若涉及外部系统写操作需已获独立人工验收 |
| Evidence health | 无 stale 证据即可，inconclusive 允许存在但不得单独支撑验收 | 全部 evidence-index 条目 artifact health = valid | 全部条目 valid；含 secret/敏感 sensitivity 的证据一律不支持自动续跑 |
| Environment self-check | pass，或 unknown 但委派仅限只读发现 | pass | pass 且 Observed model/effort 已过 `$harnessloop-delegation` 验证（非仅 expected 值） |
| Open handoffs | 无处于 blocked 的 open handoff | 无 open handoff | 无 open handoff，且上一轮 adversarial review 结论为 positive |
| Human confirmation | 不需要——条件满足即自动进入下一子目标/下一只读调查轮 | 不需要——条件满足即自动进入下一子目标/任务 | 需要——即使以上全满足，仍需人工确认后才进入下一子目标 |

### 5.2 Human Confirmation Required（Required for）

| 字段 | lite | standard | strict |
| --- | --- | --- | --- |
| Scope-lock mutation | 不需要（main session 自主收窄/扩大，需在 decision.md 留痕） | 扩大范围需要；收窄不需要 | 需要（任何方向变更） |
| Evidence contract revision | 不需要，除非改变验收标准实质含义 | 需要 | 需要 |
| Control contract revision | 需要 | 需要 | 需要 |
| Failed review acceptance | 需要（协议硬约束，任何档位不可关闭） | 需要 | 需要 |
| Rollback | 不需要（main session 可对已分类为错误的执行自主回滚，需记录） | 需要 | 需要，且需说明回滚范围是否触及外部系统 |
| Irreversible or external-system write | 需要 | 需要 | 需要，且需提前声明 dry-run/回滚方案 |

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

位置：`## After Initialization` 报告清单，第 90 行。

```diff
- - Next recommended prompt: `Use $harnessloop-loop to define the goal and start the evidence-backed loop.`
+ - Next recommended prompt: `Use $harnessloop-setup to walk through environment detection, data sources, cost/context policy, and control-contract profile before defining a goal.`
```

（第 35 行"若 `.harnessloop/` 已存在……建议 `$harnessloop-loop`"与本行语义重复但不在本次 4 个强制接线点之列，列入 §10 开放问题。）

### 6.2 `harnessloop-status/SKILL.md`

**Input Contract**（第 20 行后追加一句）：

```diff
  If `.harnessloop/` is missing, report `not-initialized` and suggest `$harnessloop-init`. Do not initialize it from this skill.
+
+ If `.harnessloop/` exists but `check_setup.py` reports incomplete, report `setup-incomplete` and suggest `$harnessloop-setup`. Do not run the wizard from this skill.
```

**Processing Contract**（第 22-28 行，插入新步骤 2，原 2-5 顺延为 3-6）：

```diff
  1. Read `.harnessloop/state/current.md` first when present.
- 2. Follow only the source paths referenced by current state, active goal, active round, open handoffs, latest decision, evidence index, control contract, environment self-check, and self-audit.
- 3. Summarize evidence health without revalidating external systems unless the user explicitly asks for evidence checking; route that to `$harnessloop-evidence`.
- 4. Report contradictions, missing state files, stale pointers, unresolved human decisions, intake blockers, blocker type, recovery eligibility, and next action safety.
- 5. Do not mutate any file, run continuation gates, execute tests as business work, or change feedback classification.
+ 2. Run `python <plugin-root>/skills/harnessloop-loop/scripts/check_setup.py --project <target-project> --json`. This is a read-only local script invocation, not a mutation or continuation gate. If it reports `complete: false`, set state to `setup-incomplete` and record the first non-`filled` file and its `missing_sections` as the setup completeness and next setup step.
+ 3. Follow only the source paths referenced by current state, active goal, active round, open handoffs, latest decision, evidence index, control contract, environment self-check, and self-audit.
+ 4. Summarize evidence health without revalidating external systems unless the user explicitly asks for evidence checking; route that to `$harnessloop-evidence`.
+ 5. Report contradictions, missing state files, stale pointers, unresolved human decisions, intake blockers, blocker type, recovery eligibility, and next action safety.
+ 6. Do not mutate any file, run continuation gates, execute tests as business work, or change feedback classification.
```

**Output Contract**（第 34-55 行代码块）：

```diff
  Harnessloop status:
  - project:
- - state: initialized | not-initialized | inconsistent | blocked
+ - state: initialized | not-initialized | setup-incomplete | inconsistent | blocked
+ - setup completeness:
+ - setup next step:
  - active goal:
  - active round:
  ...（其余字段不变）
```

**Safety Rules**（第 59-63 行，追加一条）：

```diff
  - External systems and named tools are not probed from status; ask the user to use `$harnessloop-evidence` or `$harnessloop-continue` when action is required.
+ - Running `check_setup.py` satisfies the read-only mandate above: it performs no writes, no external probing, and no continuation decision.
```

### 6.3 `harnessloop-continue/SKILL.md`

**Input Contract**（第 22 行后追加一句）：

```diff
  If `.harnessloop/` is missing, stop and suggest `$harnessloop-init`. If imported intake work is pending, route to `$harnessloop-intake`.
+
+ If `.harnessloop/` exists but setup is incomplete, stop and return `needs-setup` before evaluating any other gate (see Processing Contract step 1); suggest `$harnessloop-setup`.
```

**Processing Contract**（第 24-37 行，整体重新编号，插入新步骤 1，原 1-12 顺延为 2-13）：

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
+ 1. Run `python <plugin-root>/skills/harnessloop-loop/scripts/check_setup.py --project <target-project> --json`. If it reports `complete: false`, set decision to `needs-setup`, name the first non-`filled` file (in `environment.md → data-sources.md → cost-context-policy.md → control-contract.md → self-check.md` order) as the next setup step, and stop before evaluating any other gate. Do not execute business work.
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
+ - setup gate:
  - evidence gate:
  - control gate:
  - environment gate:
  - self-audit gate:
  - delegation gate:
  ...（其余字段不变）
```

**Safety Rules**（追加一条，置于现有列表首位或末位均可，建议末位以保持既有条目行号不变）：

```diff
  - Do not accept a round after failed adversarial review unless the control contract and human decision explicitly allow it.
+ - Do not evaluate evidence, control, environment, self-audit, or delegation gates before the setup gate; an incomplete setup gate short-circuits directly to `needs-setup`.
```

### 6.4 `harnessloop-loop/SKILL.md`

**触发条件**（第 69 行）——**注意**：goal.md 的验收标准文本写"loop SKILL:114 触发条件修正"，但实测当前文件里"若 `.harnessloop/` 不存在"这句触发条件位于第 69 行，第 114 行是另一句（"During setup, ask the user to fill in data-source connection requirements"）。本设计对两处都给出修正，覆盖两种行号理解方式，具体差异见 §10 风险 1。

```diff
- If `.harnessloop/` does not exist in the target project, propose creating:
+ If `.harnessloop/` does not exist in the target project, or `check_setup.py` reports `complete: false` for an existing `.harnessloop/`, propose creating (or completing) the following:
```

紧接骨架代码块之后、"Prefer the bundled initializer instead of hand-creating files:"之前，插入新段落：

```diff
  ```

+ If `.harnessloop/` already exists, do not re-run the initializer. Instead check completeness:
+
+ ```bash
+ python <skill-dir>/scripts/check_setup.py --project <target-project> --json
+ ```
+
+ If this reports `complete: false`, hand off to `$harnessloop-setup` to complete the remaining setup/state files before creating a goal or entering a round. Do not fill `data-sources.md`, `cost-context-policy.md`, `control-contract.md`, or `environment.md` by free-form conversation outside the wizard.
+
  Prefer the bundled initializer instead of hand-creating files:
```

**第 114 行**（"During setup, ask the user to fill in..."）：

```diff
- During setup, ask the user to fill in data-source connection requirements. Do not invent the data-source scope or content.
+ During setup, run `$harnessloop-setup` to fill in data-source connection requirements, cost/context policy, control-contract profile, and environment detection through its five-step wizard. Do not invent the data-source scope or content, and do not fill these files by ad hoc conversation outside the wizard.
```

---

## 7. validate.py 新断言清单

### 7.1 插入位置及理由

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

理由：`check_setup.py` 与 `init_project.py` 同样操作"刚初始化的骨架项目"这一对象，放在 init smoke 之后可以直接复用同一个 `smoke_root`/`init_project.initialize()` 产出，无需另建一套 fixture 目录；只需要机械地把后续阶段的 `[N/7]` 打印前缀改为 `[N/8]`，属于低风险的查找替换。

### 7.2 新增断言（`validate_check_setup_smoke`）

沿用现有风格：顶部 `import check_setup`（与已有 `import init_project`/`import verify_protocol` 一致），必要处辅以 `run_python()` 子进程调用以验证 CLI/退出码契约（`main()` 层面的行为不经由直接函数调用就无法验证）。

1. **骨架 = incomplete**：对 `validate_init_smoke` 已创建的裸骨架项目（或本阶段独立创建的同构 `smoke_root`）运行 `check_setup.py --project <smoke_root> --json`；断言 `returncode == 1`；解析 JSON 断言 `complete == False`、`filled == 0`、`total == 5`。
2. **固定 fixture 填满 = complete**：用 `check_setup` 模块自身导出的字段清单（若实现为常量，如 `WIZARD_FIELD_MANIFEST`）程序化生成"每个 leaf 字段填入占位值、每张表格填入一行合成数据（或写入 none 哨兵行）"的内容，覆盖 5 个目标文件；重跑 `check_setup.py --json`；断言 `returncode == 0`、`complete == True`、`filled == 5`、`total == 5`。**不复用 `examples/mock-project` 作为该 fixture**——已核实 mock-project 的 `data-sources.md`/`environment.md`/`control-contract.md`/`self-check.md` 结构落后当前模板（本项目自身 `setup/data-sources.md` 已记录此结论），若拿它当"填满"参照会让本断言对着一份过时结构自证通过，掩盖真实模板漂移。程序化生成 fixture 并直接从 `check_setup` 自身的字段清单派生，可保证两者永不失步。
3. **用法错误 = exit 2**：对不存在的项目路径运行 `check_setup.py --project <not-a-dir>`；断言 `returncode == 2`（与 `verify_protocol.py` 现有的错误退出码约定一致）。
4. **partial 状态断言**：在 fixture 基础上，故意清空其中一个文件的一个字段/一张表（如把 `control-contract.md` 的 `Delegation Boundaries` 三个字段清回模板原状），重跑，断言该文件 `state == "partial"` 且 `missing_sections` 命中被清空项，`complete == False`。

### 7.3 无需新增断言的部分

- `claude plugin validate --strict` 覆盖新 skill：`validate_claude_strict()` 已对 `REPO_ROOT` 与 `PLUGIN_ROOT` 跑严格校验，只要 `harnessloop-setup/SKILL.md` frontmatter（`name`/`description`）合规，新技能会被自动纳入，**无需修改 `validate.py` 本节代码**，只是对新 SKILL.md 的写作要求（round 2 实现时需满足）。
- `validate_doc_consistency()`：该阶段检查文档骨架树是否列全 `init_project.py` 的 `BASE_FILES`/`BASE_DIRS`。本设计不新增骨架文件/目录（`check_setup.py` 只读取既有 5 个文件），故该阶段**无需改动**。

---

## 8. plugin.json / marketplace.json 处置

### 8.1 `skills` 字段是否自动纳入新目录：是，无需改动

`plugins/harnessloop/.claude-plugin/plugin.json` 与 `.codex-plugin/plugin.json` 的 `skills` 字段均为目录级通配（`["./skills/"]` / `"./skills/"`），指向整个 `skills/` 目录而非逐个技能列举。核实方式：查看 `harnessloop-secrets` 技能被引入时的提交（`5c35a22 feat: add local channel parameter management`），该提交新增了整个 `plugins/harnessloop/skills/harnessloop-secrets/SKILL.md`，但两份 `plugin.json` 的 `skills` 字段本身**未发生任何改动**（该提交对 `plugin.json` 的唯一改动是 `version` 字段）。因此 `harnessloop-setup/` 目录只要存在且含合规 `SKILL.md`，会被同一套目录级发现机制自动纳入，**不需要修改 `skills` 字段**。

### 8.2 版本号：建议 0.10.0 → 0.11.0

理由（同一先例 `5c35a22` 提交）：该提交新增一个技能（`harnessloop-secrets`）时，同步把 `package.json`、`.claude-plugin/marketplace.json`（插件条目的 `version`）、`plugins/harnessloop/.claude-plugin/plugin.json`、`plugins/harnessloop/.codex-plugin/plugin.json` 四处 `version` 从 `0.7.0` 统一提升到 `0.8.0`（次版本号 +1，语义化为"新增技能=次版本升级"）。本批新增一个技能（`harnessloop-setup`）+ 一支新脚本（`check_setup.py`）+ 四处现有技能文本接线 + 一个新 validate 阶段，性质与该先例一致，故建议按相同幅度（+1 次版本）从 `0.10.0` 升到 `0.11.0`，需改动的 4 个文件与先例完全对应：

- `package.json`
- `.claude-plugin/marketplace.json`（`plugins[].version`，plugin 名为 `harnessloop` 的条目）
- `plugins/harnessloop/.claude-plugin/plugin.json`
- `plugins/harnessloop/.codex-plugin/plugin.json`

`.agents/plugins/marketplace.json`（codex marketplace）核实其插件条目本身**不含 `version` 字段**（只有 `name`/`license`/`source`/`policy`/`category`），故该文件**无需改动**。

### 8.3 附带发现：codex `plugin.json` 的 `defaultPrompt` 需要追加新技能名

`plugins/harnessloop/.codex-plugin/plugin.json` 的 `interface.defaultPrompt` 是一句列出全部技能名的提示语；同一先例提交（`5c35a22`）在新增 `harnessloop-secrets` 时同步把它加入了这句提示语的技能列表。本批新增 `harnessloop-setup` 后，若不同步更新，该提示语会静默漏掉新技能。建议：

```diff
- "defaultPrompt": "Use explicit skill names such as $harnessloop-init, $harnessloop-goal, $harnessloop-evidence, $harnessloop-channels, $harnessloop-connectivity, $harnessloop-secrets, $harnessloop-delegation, $harnessloop-status, $harnessloop-continue, $harnessloop-intake, $harnessloop-issue, or $harnessloop-loop. Treat harnessloop:init and other harnessloop: aliases as natural-language phrases only."
+ "defaultPrompt": "Use explicit skill names such as $harnessloop-init, $harnessloop-setup, $harnessloop-goal, $harnessloop-evidence, $harnessloop-channels, $harnessloop-connectivity, $harnessloop-secrets, $harnessloop-delegation, $harnessloop-status, $harnessloop-continue, $harnessloop-intake, $harnessloop-issue, or $harnessloop-loop. Treat harnessloop:init and other harnessloop: aliases as natural-language phrases only."
```

这不在 goal.md 列出的 4 个强制接线点之内，但属于同一 `plugin.json` 章节的直接连带项，列入 §10 供主会话确认是否本批一并处理。

---

## 9. Acceptance Criteria 覆盖对照表

| # | goal.md 验收标准 | 本设计覆盖章节 | 覆盖方式摘要 |
| --- | --- | --- | --- |
| 1 | 新 skill `harnessloop-setup` 存在且通过 `claude plugin validate --strict` | §1.2、§3、§7.3、§8.1 | 新技能目录经 `./skills/` 通配自动纳入；`validate_claude_strict()` 现有阶段自动覆盖，无需新断言，只需 SKILL.md frontmatter 合规 |
| 2 | 五步流程：环境自动检测→data-sources 引导→cost-context-policy 确认→control-contract 档位选择（lite/standard/strict 预设）→self-check 汇总+完成度 N/5 报告 | §3、§5、§2 | 五步逐一详细设计；三档预设全量文本；首跑/重跑对话示例含完成度 N/5 报告文案 |
| 3 | 每步可跳过且跳过必记 TODO 到 self-check | §3（通用规则）、§2.2 重跑示例 | 统一跳过语义：不写编造值，改为 `state/self-check.md` 的 `Action` 字段追加 `TODO (owner: user)` 记录，含步骤/子项/时间戳 |
| 4 | `check_setup.py`（或 `verify_protocol` 扩展）返回机器可读完整度 | §4 全节 | 独立脚本（非扩展 verify_protocol，理由见 §4.1）；字段清单、判定算法、CLI/JSON 接口、退出码、3.9 兼容与路径解析全部给出 |
| 5 | status 输出 setup-incomplete 状态与"缺什么/下一步" | §6.2 | `state` 枚举新增 `setup-incomplete`；Output Contract 新增 `setup completeness`/`setup next step` 字段；Processing Contract 新增调用 check_setup 的步骤 |
| 6 | continue 门对 setup-incomplete 返回 needs-setup | §6.3 | `decision` 枚举新增 `needs-setup`；Processing Contract 新增第 1 步作为最前置门（其余步骤顺延）；Output Contract 新增 `setup gate` 字段；Safety Rules 新增短路规则 |
| 7 | init 交接语指向 setup wizard | §6.1 | 第 90 行 `Next recommended prompt` 精确 diff |
| 8 | loop SKILL:114 触发条件修正为"目录不存在或 setup 未完成" | §6.4、§10 风险 1 | 对第 69 行（实际触发条件句）与第 114 行（ask-user 指令句）均给出修正 diff，并标注与 goal.md 行号引用的差异 |

---

## 10. 风险与开放问题

1. **goal.md 行号引用与实际文件行号不一致**：验收标准第 8 条写"loop SKILL:114 触发条件修正"，但直接读取当前 `harnessloop-loop/SKILL.md` 核实，"若 `.harnessloop/` 不存在"这一触发条件句位于第 69 行；第 114 行是另一句（"During setup, ask the user to fill in data-source connection requirements"，本身也是原 CONFIRMED 发现引用的证据行）。本设计对两处都给出了修正方案（§6.4），但最终验收时按哪一行号核对文本需要主会话或用户确认，避免验收环节出现"改对了内容但对不上行号"的争议。
2. **本项目自身 `setup/data-sources.md` 可能验不出"complete"**：check_setup 的 `External Tools And Platforms` 表判定依据是"≥1 数据行或 none 哨兵行"；核实 test-harnessloop 自身该文件此表当前是 0 行且**没有** none 哨兵行（只是留空），按本设计规则会判定该文件为 `partial` 而非 `filled`，进而使 5 个文件里这一项拖累整体 `complete` 判定。这与 goal.md 成功条件"check_setup 在本项目（已填）返回 complete"存在潜在冲突。本轮 scope-lock 禁止我写 `.harnessloop/setup/data-sources.md`（不在允许的单文件清单内），故无法在本轮验证/修补。建议实现轮先跑一次 `check_setup.py --project . --json` 针对 test-harnessloop 自身核实结果，如确实命中此差距，两个可选修复路径二选一由主会话/用户拍板：(a) 在实现轮给该文件补一行 none 哨兵句；(b) 放宽判定规则，允许"表为空且无任何后续内容"在特定宽限条件下也算已确认（会削弱哨兵行机制的必要性，不推荐）。
3. **三档默认值文案需用户验收时确认**：goal.md `Required Human Decisions` 已列"档位预设默认值内容在验收时确认"；本设计给出的 §5 全文是设计侧提案，非最终定案，尤其 lite 档"Scope-lock mutation 不需要人工确认"这类偏激进条款需要用户明确认可。
4. **`control-contract-profiles.md` 放置位置与 loop SKILL.md 引用**：建议放 `harnessloop-loop/references/`（与其余 27 个模板同目录，见 §5 开头），但是否需要在 `harnessloop-loop/SKILL.md` "For control-plane state..." 一段追加一行引用，不在本任务列出的 4 个强制接线点之内，需要主会话决定是否顺带处理（若不处理，`harnessloop-setup/SKILL.md` 内部直接引用该路径即可正常工作，不影响功能，只影响 loop SKILL.md 自身文档完整性）。
5. **`harnessloop-init/SKILL.md:35`（"若 `.harnessloop/` 已存在……建议 `$harnessloop-loop`"）与本次修改的第 90 行语义重复**：本设计只改了第 90 行（After Initialization 报告的强制接线点），第 35 行（Initialization Decision 分支里的另一处 `$harnessloop-loop` 建议）未纳入，可能导致"init 检测到已存在目录"和"init 走完全新初始化流程"两条路径给出不一致的下一步建议。是否一并修正需主会话确认。
6. **codex `plugin.json` 的 `defaultPrompt` 技能列表**（§8.3）：与版本号一样有先例支持同步更新，但不在 4 个强制接线点内，需确认是否本批处理。
7. **字段清单（manifest）与模板耦合、无自动漂移检测**：§4.2 的 90 槽位清单是针对当前 `references/` 模板结构手工穷举的；日后任何模板字段增删都需要同步更新 `check_setup.py`，且目前没有机械手段检测两者是否已经不同步（类比 `validate_doc_consistency()` 对骨架文件列表做的一致性检查，但那是针对文件级列表，不是字段级）。建议列为后续增强方向，本轮不实现。
8. **provenance 标注是本设计新引入的约定**：`(detected)`/`(user-confirmed)`/`(default-accepted)` 后缀标注不是既有模板/协议要求，只在 wizard 新写入的内容里使用；test-harnessloop 自身现有的已填文件（如 `state/environment.md`）不追溯改造，是否需要回填不在本任务范围，需用户确认。
9. **委派探针局限的诚实边界**：S1 环境检测里"Can create independent task"等 4 项若本会话内恰好有可引用的真实委派证据，可标为 `detected`；若没有，必须如实写 `unknown`，不得因为"协议描述委派可用"就推断为 `pass`。这条规则依赖执行时机——若 wizard 在项目刚初始化、还没有任何委派历史时运行，这 4 项大概率只能写 `unknown`，用户体验上会显得"检测没检测出什么"，这是协议反虚构原则下的必然代价，不是实现缺陷，需要在实现/验收时向用户说明预期。
10. **未纳入本次范围但相关的两条 CONFIRMED 发现**：(a) data-sources 的仓库自动扫描（`.github/workflows`、`package.json` 等）——goal.md Non-Goals 已明确排除；(b) `init_project.py` 检测目标项目是否为 git 仓库——不属于 setup wizard 五步范围，也不在 goal.md 非目标里明确提及，建议作为独立后续项，不在本设计中处理。
