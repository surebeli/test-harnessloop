# Goal Breakdown

> **状态标注**：本文件为需求分析（Requirement Analysis）阶段进阶计划，替换此前基于旧业务身份（AgentOps 控制台）的 S1-S7 dev 分解草案。**dev 分解（原型/编码/集成/收口等具体执行子目标）明确推迟，待需求达 dev-readiness gate 并经用户签署后，再次执行 `$harnessloop-goal update` 注入。** 本文件当前只覆盖需求分析各级（RA-L1 → RA-L4），不含任何编码任务。

## Long-Term Goal

以三插件（harnessloop/hopper/kata）全栈驱动，探索性设计并开发一款 agent app（仿 codex app 的消息流客户端）+ console 管理端 + server 后端，全程插件实时进化、里程碑连载直播（详见 goal.md）。

## Requirement Analysis Plan（逐级展开，每级用户确认后再下一级）

- **RA-L1**：顶层域分解（2026-07-18 用户确认，confirmed）——见下方「L1 七支柱」
- **RA-L2**：各支柱逐一展开（每支柱一轮，逐级确认门）；首轮范围：架构核心 P1-P3（用户指定优先，2026-07-18 决策，详见 goal.md「RA-L1 确认与决策」）**——2026-07-18 用户确认，confirmed**，并同步锁定架构决策 X1（本地内核优先）/ X2（统一经 newapi，详见 goal.md「RA-L2 确认与架构决策」）；P4–P7 顺延至后续轮次
- **RA-L3**：关键设计决策与技术选型，细化为 7 项决策议程（2026-07-18 细化，见下方「RA-L3 议程」）
- **RA-L4**：需求规格成型 → **dev-readiness gate**（用户签署）

### RA-L3 议程（7 项决策，2026-07-18 细化）

| ID | 决策项 | 说明 |
| --- | --- | --- |
| D1 | 内核抽象接口规格 | agent 内核抽象接口设计（openclaw 默认 / hermas 等可切 / codex app sdk·claude code sdk 兼容） |
| D2 | 消息 schema 规格 | UI 消息流数据源 与 agent 输入输出消息源 之间的屏障层 schema 设计 |
| D3 | Server 技术选型 | **需调研·已授权 hopper research**；X1 确定后 server 收敛为瘦控制面（license/租户/坐席/能力开关/费用/newapi 设置），选型范围随之收窄 |
| D4 | Mac→Windows 跟随开发机制 | 保留平台特点的同时保证功能与交互细节对齐 |
| D5 | 仿 codex app 产品规格 | 功能与交互参照（不做代码级复制），产品规格落地 |
| D6 | newapi 集成方式 | X2 确定后，内核 LLM 调用统一经 newapi 网关的具体接入方式 |
| D7 | 本地内核分发打包 | X1 确定后，客户端本地内核的分发打包机制 |

**外部资料依赖标注**：D1 / D6 / D7 依赖 openclaw / hermas / newapi / codex app sdk / claude code sdk 的真实资料（接口文档、能力范围、集成方式等），资料**待用户提供或 hopper 调研**，调研完成前不得臆造（见 data-contract.md）。

### 架构骨架（2026-07-18，随 RA-L2 确认 + X1/X2 决策落盘）

客户端本地运行 agent 内核（openclaw 默认，hermas 等可切换）+ 内核抽象层（D1）+ 消息屏障（D2，隔离 UI 消息流数据源 与 内核输入输出消息源，使内核切换对 UI 透明）+ UI（消息流为核心，仿 codex app 产品形态）；内核的 LLM 调用统一经 newapi 网关（X2，计费/成本/能力开关统一入口）。Server 收敛为瘦业务控制面（X1）：只管 license / 租户 / 坐席 / 能力开关 / 费用 / newapi 设置，不跑 agent 本体。Console 是 server 数据面的管理界面，管理端功能面对应上述 server 职责。

**横切（按触发发生，不占级编号）**：

- **插件进化流**：由 RA-L1–L4 各级实战触发的三插件改进，沿用 TH-xxxx 编号与版本发布留痕惯例，发布节奏不与 RA 级绑定
- **连载内容流**：里程碑驱动的文章连载，成稿至 PR wiki `drafts/`，发布节奏不与 RA 级绑定

## L1 七支柱（2026-07-18 用户确认，confirmed）

| ID | 支柱 | 概要 | 状态 |
| --- | --- | --- | --- |
| P1 | 产品形态 | 仿 codex app，消息流为核心 | confirmed |
| P2 | Agent 内核抽象层 | openclaw 默认 / hermas 等可切 / codex·claude sdk 兼容 | confirmed |
| P3 | 消息流抽象屏障 | UI 消息流数据源 与 agent 输入输出消息源 之间的屏障层，使内核切换对 UI 透明 | confirmed |
| P4 | 客户端工程 | 原生优先 · Mac 优先 · Mac→Windows 跟随开发机制 | confirmed |
| P5 | 身份与商业化 | license / 租户 / 坐席 / 能力开关 / 费用 | confirmed |
| P6 | Console 管理端 | license 管理 / 租户管理 / 能力开关 / 费用管理 / 基于 newapi 的设置 | confirmed |
| P7 | Server 后端 | 完整调研选型（用户不擅长 server 开发，由我方提供） | confirmed |

## Discovery Handoffs

| Handoff | Purpose | Inputs | Output path | Status |
| --- | --- | --- | --- | --- |
| （RA-L2 尚未开启，无已派发 handoff） | | | | |

## Subgoals（需求分析阶段，非 dev 分解）

| ID | Subgoal | Depends on | Evidence required | Validation method | Risk |
| --- | --- | --- | --- | --- | --- |
| RA-L1 | 顶层域分解：七支柱（P1–P7）结构呈现 | 无 | 本文件「L1 七支柱」表 + 用户确认记录（2026-07-18） | 用户确认门（已通过，2026-07-18） | 七支柱粒度与边界经用户 2026-07-18 确认，无需调整；RA-L2 首轮（架构核心 P1-P3）已据此展开 |
| RA-L2 | 各支柱（P1–P7）逐一展开：每支柱产出细化需求点；首轮范围＝架构核心 P1-P3（用户指定优先，2026-07-18 决策） | RA-L1（已确认，2026-07-18） | 各支柱展开文档 + 架构决策 X1/X2（见 goal.md「RA-L2 确认与架构决策」） | 每支柱一轮，用户逐级确认门（首轮 P1-P3 已通过，2026-07-18） | 首轮（P1-P3）confirmed，2026-07-18；P4–P7 顺延后续轮次，展开时需标注与已确认架构（X1 本地内核优先 / X2 统一经 newapi）的交叉引用 |
| RA-L3 | 关键设计决策与技术选型：细化为 7 项决策议程 D1-D7（内核抽象接口 / 消息 schema / Server 选型 / Mac→Windows 跟随开发 / 仿 codex app 产品规格 / newapi 集成方式 / 本地内核分发打包，见上「RA-L3 议程」表） | RA-L2（已确认，2026-07-18） | 调研文档（含 hopper research 产物，D3 已授权首战）+ 设计决策记录 | 对抗性设计评审 + 用户确认技术选型 | D3 server 调研为 hopper research 首次实战，产物质量未知；D1/D6/D7 依赖 openclaw/hermas/newapi/codex-app-sdk/claude-code-sdk 真实资料，待用户提供或 hopper 调研，调研完成前禁止臆造能力（见 data-contract.md） |
| RA-L4 | 需求规格成型：汇总 RA-L1–L3 产出为 dev-ready 规格文档 | RA-L3（用户确认后） | dev-ready 规格文档 | 用户签署 dev-readiness gate | 规格可能存在遗漏或内部不一致，签署前需自洽性检查（见 thresholds.md） |

**dev 分解（原型/编码/集成/收口）**：TODO (owner: 待 RA-L4 dev-readiness gate 用户签署后，再次执行 `$harnessloop-goal update` 注入)——本次 material change 明确推迟，非遗漏。

## Tasks

| ID | Task | Parent subgoal | Scope boundary | Evidence required | Validation method |
| --- | --- | --- | --- | --- | --- |
| （RA-L1 已确认；RA-L2 首轮（架构核心 P1-P3）展开中，task 级按需补充本表） | | | | | |

## Main-Session Decision

Chosen sequence: RA-L1 → RA-L2 → RA-L3 → RA-L4 → dev-readiness gate（签署后注入 dev 分解）；插件进化流与连载内容流为横切线，随各级触发产出，不独占级编号、不阻塞需求分析主线推进。

Rejected alternatives: 已否决"直接展开全量 dev 分解（原 S1-S7）"——用户 2026-07-18 明确指令需求分析阶段逐级展开、每级用户确认后再下一级，dev 推迟至 dev-ready 后再议，故不采用一次性展开。

Reasoning: 业务与技术栈本轮经用户重定（agent app 仿 codex app + 内核抽象 + 消息流屏障 + Mac 优先原生开发 + Mac→Windows 跟随开发机制 + server 调研待定 + console 功能面锁定），此前基于旧业务身份（AgentOps 控制台）的 S1-S7 dev 分解已不适用，故整体替换为需求分析进阶计划。逐级确认门的设计目的：避免在技术栈与内核抽象等高不确定性设计决策未澄清前过早锁定 dev 分解，尤其 server（用户不擅长）与内核抽象（涉及 openclaw/hermas/两 SDK 兼容）需要 RA-L3 完整调研支撑，不能凭假设展开。
