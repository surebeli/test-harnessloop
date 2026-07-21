# Goal

## Goal

以三插件（harnessloop 高自动化 / hopper 异构算力低成本 / kata 知识沉淀）全栈驱动，探索性设计并开发一款 **agent app**——产品形态仿照 codex app（以消息流为核心的 agent 客户端）。

- 登录需获取 license；个人用户免费；企业场景支持租户（tenant）概念，租户下坐席（seat）收费
- 配套 **console** 管理端与 **server** 后端
- 全程三插件全栈驱动、插件实时进化、里程碑连载直播
- 本 goal 为探索性项目，失败与成功皆为可接受结果

### 业务技术要点（user-specified 2026-07-18，作为 source-of-truth 锁定）

- **Agent 内核**：默认基于 openclaw 最新稳定分支；支持 hermas 等相似项目内核切换；兼容考虑 codex app sdk / claude code sdk。故需一层内核抽象接口支持核心 agent 抽象
- **消息流屏障**：app 核心 UI（消息流）数据源 与 agent 输入输出消息源 之间需抽象一层屏障，使内核切换对 UI 透明
- **Console 功能面**：license 管理 / 租户管理 / 租户下能力开关（plugin 开关、skill 开关）/ 费用管理 / 基于 newapi 的设置（系统管理员）

### 技术栈偏好与约束（user-specified 2026-07-18）

- **App**：主流做法为前端 + electron，但用户要求不牺牲性能与效果、尽可能原生开发、优先 Mac；需设计一套机制支持 Mac 开发进度同步到 Windows 跟随开发（保留平台特点的同时保证功能与交互细节对齐）
- **Server**：用户不擅长 server 开发，需由我方提供完整调研与选型
- **Console**：技术栈未定（交设计轮），功能面如上（业务技术要点节）

### RA-L1 确认与决策（user-confirmed 2026-07-18，作为 source-of-truth 锁定）

- **决策 1 — 七支柱结构确认**：`goal-breakdown.md` L1 七支柱（P1–P7）顶层域划分经用户确认，粒度与边界无需调整；状态由 pending 转为 confirmed
- **决策 2 — L2 展开顺序**：RA-L2 首轮范围为「架构核心优先」，先展开 P1（产品形态）/ P2（Agent 内核抽象层）/ P3（消息流抽象屏障）三支柱；P4–P7（客户端工程 / 身份与商业化 / Console 管理端 / Server 后端）顺延至后续轮次
- **决策 3 — 仿照 codex app 边界**：仿照对象限定为「功能与交互参照」，具体实现自主设计，不做代码级复制、反编译或资产挪用；合规风险低（仅参照公开可见的产品功能与交互形态进行独立实现，不涉及源码获取或商标冒用）

### RA-L2 确认与架构决策（user-confirmed 2026-07-18，作为 source-of-truth 锁定）

- **RA-L2 架构核心（P1-P3）已确认**：P1 产品形态 / P2 Agent 内核抽象层 / P3 消息流抽象屏障 三支柱展开细化经用户 2026-07-18 确认，状态由 pending 转为 confirmed；P4–P7 顺延至后续轮次
- **决策 X1 — 本地内核优先**：agent 内核在客户端本地运行（非 server 侧托管）。连带影响：客户端须承担本地内核分发；跨平台（Mac→Windows）双实现负担更重；server 收敛为不跑 agent 本体的瘦控制面
- **决策 X2 — 统一经 newapi**：所有内核的 LLM 调用统一经由 newapi 网关，newapi 成为计费/成本/能力开关的统一入口

这两个决策使 server 从重后台收敛为瘦业务控制面。

### RA-L3 D3 确认与决策（user-confirmed 2026-07-21，作为 source-of-truth 锁定）

- **决策 D3 — Server 技术选型确认**：RA-L3 议程 D3（Server 技术选型）经用户 2026-07-21 确认，采纳方案 A：**TypeScript + NestJS + PostgreSQL**。具体：应用内 JWT license 签发/校验/吊销；多租户采用共享库 + `tenant_id`（非独立 schema/数据库）；坐席（seat/membership）与能力开关（feature flags）自建表；new-api 仅作为 Management API 集成对象（token/channel/用量对账等），**非**多租户 SaaS 主账本。依据：T-002 grok 调研（`.hopper/handoffs/T-002-output.md`）。对应设计 wiki 页 `server/server-stack-selection.md` 的 `design_status` 同步由 draft 转 confirmed。

### RA-L3 D1 评审结论与决策（2026-07-21）

- **决策 D1（阶段性）— 首版 spec 双轨对抗评审 REWORK，不予确认**：RA-L3 议程 D1（内核抽象接口规格）的首版正式 spec（设计 wiki `kernel/d1-kernelport-spec.md`）经**双轨对抗评审**——第三方轨（codex，hopper 派发任务 T-004，`.hopper/handoffs/T-004-output.md`）Verdict **REWORK**，15 findings，5 BLOCKER；内部轨（Sonnet，本会话独立执行）Verdict **negative**，11 项 must-fix——**双双否决**。两轨互相独立执行、互不参照产生内容，仍收敛到同一组 **7 条交集硬伤**：Claude 生命周期不同构 / INV-5 自相矛盾（裂缝下推给 UI/P3 违反自身不变量）/ newapi 计费不可归因到具体 run / capabilities 静态声明违反 INV-4（能力显式声明不变量）/ canUseTool 回调桥接可致永久挂起 / Hermes stop 能力"未能确认"被对照表当作"已确认" / seq 断线重放语义存在悬空引用。评审综合与各自独有发现（codex 8 项 + Sonnet 4 项）详见设计 wiki `research/d1-review-dual-track.md`。
- **核心诊断**："单一窄腰无缝跨四内核"这一核心主张被过度声称；Claude Agent SDK 的生命周期不同构（`query()` 单阶段 vs `createSession()`/`send()` 两阶段）是四内核间最深的一条裂缝，不是字段级适配能抹平的；多个已在 RA-L2/X1/X2 层面确认的架构职责（计费权威在 newapi、内核切换对 UI 透明）在 D1 当前设计里找不到生效路径。
- **落盘处置**：设计 wiki `kernel/d1-kernelport-spec.md` 的 `design_status` 已由 `draft` 改为 `superseded`（正文未删除，保留作审计与 v2 重设计对照基线）；`goal-breakdown.md` RA-L3 议程表 D1 行状态标注同步改为 `negative-rework`。
- **Next（待用户决定）**：D1 v2 重设计方向——是先做 **conformance spike**（锁定四个具体 adapter profile/版本做 7 方法逐项验证，参考 codex Next recommendation）优先验证，还是**直接按两轨建议重构**（生命周期分离 Claude 特例、审批状态机、能力协商模型、newapi 关联字段等）——留待用户在下一轮确认。
- **feedback-policy 适用性说明**：本次 D1 否决属于 `feedback-policy.md`「补充条款：探索性否定结论」的适用范围——D1 是 RA-L3 关键设计决策之一，本次评审否决是**有充分证据支撑的阶段性否定结论**（证据路径可追溯至 `.hopper/handoffs/T-004-output.md` 与设计 wiki `research/d1-review-dual-track.md`，结论基于实际评审产出而非臆测），按该条款应作为**正常迭代（探索成功的一种形式）处理，不计为 negative/失败**；不适用于协议执行故障（本次评审派发与落盘过程本身无执行故障）。

### RA-L3 D1 rework 决策（user-confirmed 2026-07-21，作为 source-of-truth 锁定）

- **决策 ①（v1 scope 收敛）— KernelPort v1 聚焦本地进程内核**：v1 抽象接口范围收敛为 **openclaw（默认）+ hermes** 两个本地进程内核——二者同属本地进程、Gateway 结构契合，可在同一窄腰下合理适配；**codex app sdk / claude code sdk 两内核降为后续 profile**（不在 v1 scope 内，是否及何时展开留待后续轮次视需要另起议程）。此举消解评审对"单一窄腰无缝跨四内核"的"过度声称"批评——SDK 内核在 goal.md「业务技术要点」节原文措辞即为"兼容**考虑**"，非"必须支持"，v1 收窄不违背既有 source-of-truth。
- **决策 ②（rework 方式）— spike-first：先补事实、再重设计**：D1 v2 不直接在 v1 spec 上打补丁重构，而是先执行 **conformance spike**——针对 openclaw + hermes 两个内核，逐项补齐双轨评审标出的"未能确认"事实缺口（如 Hermes stop 能力、newapi 计费查询接口、事件 seq/时间戳原生支持等），落盘为可验证的硬事实基线；再在该硬事实基线上重设计 D1 v2。目的：避免 v2 重蹈 v1"未验证先声称"的覆辙。
- **SDK profile 化对 5 BLOCKER 的消解与残留**：v1 spec 双轨评审第三方轨（codex T-004，`.hopper/handoffs/T-004-output.md`）标出 5 项 BLOCKER。SDK 内核降为后续 profile、不在 v1 scope 后，其中 2 项因"争议主体本轮不在 scope 内"而随之消解：
  - **F-01（Claude 生命周期不同构：`query()` 单阶段 vs `createSession()`/`send()` 两阶段）—— 消解**
  - **F-04（`canUseTool` 回调桥接可致永久挂起）—— 消解**

  其余仍需在 D1 v2（scope=openclaw+hermes）中解决，且对 openclaw+hermes 同样成立、不因 SDK 延后而消解：
  - F-07 — INV-5 自相矛盾（裂缝下推给 UI/P3 违反自身不变量）
  - F-09 — newapi 计费不可归因到具体 run
  - F-11 — capabilities 静态声明违反 INV-4（缺 `capabilities_changed` 事件）
  - F-02 — Hermes stop 能力"未能确认"被对照表当作"已确认"
  - F-12/F-13 — seq / 断线重放语义存在悬空引用
  - error code 枚举不完整（源自内部 Sonnet 轨 11 项 must-fix）
  - run 串行化 / stop 时序（cancel+resend 无 run 级寻址或完成屏障；对应 F-08 及 codex Next recommendation 中"run-targeted cancel 与 terminal barrier"）
  - 多 session 场景未覆盖（源自内部 Sonnet 轨 11 项 must-fix）

### RA-L3 D1 v2 双轨复核决策（2026-07-21）

- **决策 D1（v2 阶段）— v2 spec 双轨复核 REWORK，两轨分歧，不予确认**：RA-L3 议程 D1 的 v2 正式 spec（设计 wiki `kernel/d1-kernelport-spec-v2.md`，scope=openclaw+hermes）经**双轨复核**——第三方轨（grok，hopper 派发任务 T-006，`.hopper/handoffs/T-006-output.md`）Verdict **REWORK**（3 处 BLOCKER + 2 处 HIGH）；内部轨（Sonnet，本会话独立执行）Verdict **positive-可小修**（对 v2 §10 自评"10 条已消解"逐条复核，判 7 条真消解、3 条部分消解，未判出任何一条未消解）。**两轨 verdict 分歧**——不同于 v1 spec 双轨评审的"双双否决、收敛出交集硬伤"，本次是"一负一正"。
- **分歧的核心与价值**：分歧集中在 F-07（INV-5 自相矛盾）一项，根源是一处**事实回退**——grok 核实出 openclaw 原生支持 `sessions.steer`（设计 wiki `kernel-ecosystem-facts.md` 第 42 行明确列出，且与 T-003 原始研究产物一致），但 v2 spec §5/§6.1/§8 在没有新否定证据的情况下，把这一已确认事实静默抹除，断言 openclaw 无原生 steer、仅走 abort，进而设计了内部 cancel+resend 降级路径整条替代覆盖 openclaw——grok 判定这是 v1 F-02 类问题（"未能确认"当"已确认"处理）的同类复发，方向相反但性质相同（这次是把"已确认"当"不存在"处理）。**内部 Sonnet 复核未做独立的官方文档/事实基线交叉核查，沿用了 v2 正文的表述，因而漏掉了这条事实回退**，误判 F-07 为真消解，是两轨分歧的根本原因。这一分歧证明：第三方异构复核（不同 vendor、强制 web-search 交叉官方文档）能够抓到同源内部复核（未独立核查事实、容易沿用被评审对象自身叙事）的系统性盲区——分歧本身不是噪声，而是保留双轨复核流程（尤其保留异构第三方轨）的直接证据与理由。
- **落盘处置**：设计 wiki `kernel/d1-kernelport-spec-v2.md` 的 `design_status` 已由 `draft` 改为 `superseded`（正文未删除，保留作审计与 v3 修订对照基线），顶部已加双轨复核 REWORK 通知；综合复核结论见设计 wiki `research/d1-v2-review-dual-track.md`；`goal-breakdown.md` RA-L3 议程表 D1 行状态标注同步更新为"D1 v2 双轨复核 REWORK→D1 v3"。
- **D1 v3 局部修复清单（6 条，非推倒重来）**：两轨均认为 v2 的 scope 收窄、F-02/F-03/F-09/F-10/F-14、SDK 延后方向正确，只需局部修复：① openclaw 采用原生 `sessions.steer`（cancel+resend 降级路径收窄为仅 hermes）→ 同时溶解 INV-5/F-07 三处互斥与 `nextRunId` 时序悖论；② 审批超时终态触发机制（`timeoutAuthority` 字段钉死 openclaw/hermes 双时钟权威）；③ cancel+resend（收窄后）完成屏障零 active run 竞态（补超时与失败路径）；④ `degraded`↔`forceResolvedApprovals` 定序（grok 独立同判 BLOCKER，两轨在此项收敛）；⑤ F-05（`updatedInput`）/F-11（capabilities override 通道）从"已消解"降级为"部分化解"的诚实表述；⑥ 加 `protocolVersion`/`contractVersion` 字段（呼应 v1 遗留 S-09，两轮独立评审均指出但未落地）。详见设计 wiki `research/d1-v2-review-dual-track.md` 第 4 节。
- **feedback-policy 探索条款适用性说明**：本次 v2 复核分歧属于 `feedback-policy.md`「补充条款：探索性否定结论」的适用范围——D1 是 RA-L3 关键设计决策之一，本次复核（含其内部分歧）是**有充分证据支撑的阶段性结论**（证据路径可追溯至 `.hopper/handoffs/T-006-output.md` 与设计 wiki `research/d1-v2-review-dual-track.md`，结论基于实际复核产出而非臆测，且两轨分歧本身已被溯源到具体可核验的事实回退，不是主观判断分歧），按该条款应作为**正常迭代（探索成功的一种形式）处理，不计为 negative/失败**；不适用于协议执行故障（本次两轮 hopper 派发与设计 wiki 落盘过程本身均无执行故障）。

## Non-Goals

- 不承诺生产级上线或商业化——本 goal 是探索性实验，失败与成功皆为可接受的结果
- 需求分析阶段不跳级展开——须逐级（RA-L1 → RA-L2 → RA-L3 → RA-L4）用户确认后再进入下一级
- 不在需求达 dev-ready 前进入编码——dev 分解推迟至 dev-readiness gate 后注入（见 goal-breakdown.md）
- 不自研 LLM
- 插件（harnessloop/hopper/kata）的进化仅由本 goal 的实战需求驱动，不做推测性功能开发

## Success Condition

本 goal 为探索性 goal，成功定义为「探索定义」：以下三项皆有落盘证据即视为成功（包括证据充分的失败/否定结论）。

1. **可行性结论**（含失败分析亦可）
2. **插件进化**——≥ 5 项由本 goal 实战触发的改进发布至上游三插件（沿用 TH-xxxx 编号与版本发布留痕惯例）
3. **内容连载**——≥ 3 篇里程碑文章成稿至 PR wiki `drafts/`

**近期里程碑**：需求设计逐级展开至 dev-readiness 并经用户签署，届时再次执行 `$harnessloop-goal update` 注入 dev 子目标。当前阶段仅做需求分析，不做编码。

## Acceptance Criteria

| Criterion | Evidence required | Verification method | Human confirmation required |
| --- | --- | --- | --- |
| 1. RA-L1 顶层域（七支柱）结构经用户确认 | goal-breakdown.md RA-L1 表 + 用户确认记录 | 用户逐级确认门 | 是 |
| 2. RA-L2 各支柱展开逐一经用户确认 | 各支柱展开文档 + 用户确认记录 | 用户逐级确认门（每支柱一轮） | 是 |
| 3. RA-L3 关键设计决策与技术选型经用户确认（server 完整调研 / 内核抽象接口设计 / 消息流屏障设计 / Mac→Windows 跟随开发机制设计 / 仿 codex app 产品规格） | 调研文档 + 设计决策记录 | 对抗性设计评审 + 用户确认技术选型 | 是 |
| 4. 需求规格成型并达 dev-readiness，用户签署 | dev-readiness 规格文档 + 用户签署记录 | 用户签署门 | 是 |
| 5. 插件进化 ≥ 5 项发布（横切，不受需求分析进度阻塞） | 各插件版本发布记录（TH-xxxx 编号） | 与插件仓库/CHANGELOG 比对 | 否 |
| 6. 里程碑文章 ≥ 3 篇成稿至 PR wiki `drafts/`（横切） | ≥ 3 篇文章成稿文件 | 用户发布确认 | 是 |

## Required Human Decisions

- 每一级需求展开的确认（逐级门）
- 技术选型确认
- dev-readiness 签署
- 每篇连载发布确认

## Source Of Truth

本 goal.md 的 user-specified 段（Goal / 业务技术要点 / 技术栈偏好与约束 三节，2026-07-18 用户重定）+ 本轮及后续 AskUserQuestion 留痕。

| Document or system | Path or URL | Trust level | Last verified |
| --- | --- | --- | --- |
| 用户业务与技术栈重定指令 | 本 `goal.md`（Goal / 业务技术要点 / 技术栈偏好与约束 三节） | 权威（source-of-truth 锁定） | 2026-07-18 |
| RA-L1 确认与三项决策（七支柱确认 / L2 展开顺序 / 仿照 codex app 边界） | 本 `goal.md`（RA-L1 确认与决策节）+ `goal-breakdown.md`（L1 七支柱表 confirmed / RA-L2 首轮范围） | 权威（source-of-truth 锁定） | 2026-07-18 |
| RA-L2 架构核心确认 + 架构决策 X1/X2（本地内核优先 / 统一经 newapi） | 本 `goal.md`（RA-L2 确认与架构决策节）+ `goal-breakdown.md`（RA-L2 confirmed / RA-L3 七项议程 D1-D7） | 权威（source-of-truth 锁定） | 2026-07-18 |
| RA-L3 D3 确认（Server 技术选型 = TypeScript+NestJS+PostgreSQL） | 本 `goal.md`（RA-L3 D3 确认与决策节）+ `goal-breakdown.md`（RA-L3 议程表 D3 confirmed）+ `.hopper/handoffs/T-002-output.md`（T-002 grok 研究） | 权威（source-of-truth 锁定） | 2026-07-21 |
| AskUserQuestion 留痕（本轮及后续逐级确认） | 会话内留痕，逐级确认发生时冻结 | 权威 | 随逐级确认更新 |

## Status

**proposed（2026-07-18，material change：业务与技术栈重定）**

本 goal 处于 propose 阶段，当前子阶段为需求分析（Requirement Analysis）。五份契约文件（本文件 + goal-breakdown.md + thresholds.md + data-contract.md + feedback-policy.md）已按新业务身份重写落盘，无 `rounds/` 目录、无执行轮。dev 分解明确推迟至需求达 dev-ready 并经用户签署后注入（届时再次执行 `$harnessloop-goal update`）。RA-L1 顶层域结构（七支柱 P1–P7）已经用户 2026-07-18 确认（见 goal-breakdown.md「L1 七支柱」表，状态 confirmed）。RA-L2 首轮（架构核心 P1-P3）已经用户 2026-07-18 确认（见上「RA-L2 确认与架构决策」节），并同步锁定两项架构级决策 X1（本地内核优先）/ X2（统一经 newapi），server 由此收敛为瘦业务控制面。下一步：RA-L3 议程（7 项决策 D1-D7，见 goal-breakdown.md）确认中，pending 用户确认。
