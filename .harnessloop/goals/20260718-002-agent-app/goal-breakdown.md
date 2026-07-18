# Goal Breakdown

> **状态标注**：本文件为需求分析（Requirement Analysis）阶段进阶计划，替换此前基于旧业务身份（AgentOps 控制台）的 S1-S7 dev 分解草案。**dev 分解（原型/编码/集成/收口等具体执行子目标）明确推迟，待需求达 dev-readiness gate 并经用户签署后，再次执行 `$harnessloop-goal update` 注入。** 本文件当前只覆盖需求分析各级（RA-L1 → RA-L4），不含任何编码任务。

## Long-Term Goal

以三插件（harnessloop/hopper/kata）全栈驱动，探索性设计并开发一款 agent app（仿 codex app 的消息流客户端）+ console 管理端 + server 后端，全程插件实时进化、里程碑连载直播（详见 goal.md）。

## Requirement Analysis Plan（逐级展开，每级用户确认后再下一级）

- **RA-L1**：顶层域分解（2026-07-18 用户确认，confirmed）——见下方「L1 七支柱」
- **RA-L2**：各支柱逐一展开（每支柱一轮，逐级确认门）；首轮范围：架构核心 P1-P3（用户指定优先，2026-07-18 决策，详见 goal.md「RA-L1 确认与决策」）；P4–P7 顺延至后续轮次
- **RA-L3**：关键设计决策与技术选型，含：
  - server 完整调研（hopper research 实战）
  - agent 内核抽象接口设计
  - 消息流屏障设计
  - Mac→Windows 跟随开发机制设计
  - 仿 codex app 的产品规格
- **RA-L4**：需求规格成型 → **dev-readiness gate**（用户签署）

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
| RA-L2 | 各支柱（P1–P7）逐一展开：每支柱产出细化需求点；首轮范围＝架构核心 P1-P3（用户指定优先，2026-07-18 决策） | RA-L1（已确认，2026-07-18） | 各支柱展开文档 | 每支柱一轮，用户逐级确认门 | 支柱间可能存在依赖或冲突（如 P2 内核抽象 与 P3 消息流屏障 强耦合），需在展开时标注交叉引用 |
| RA-L3 | 关键设计决策与技术选型：server 调研 / 内核抽象接口 / 消息流屏障 / Mac→Windows 跟随开发机制 / 仿 codex app 产品规格 | RA-L2（用户确认后） | 调研文档（含 hopper research 产物）+ 设计决策记录 | 对抗性设计评审 + 用户确认技术选型 | server 调研为 hopper research 首次实战，产物质量未知；openclaw/hermas/newapi/codex-app-sdk 等外部项目实际形态未经调研确认，禁止臆造能力（见 data-contract.md） |
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
