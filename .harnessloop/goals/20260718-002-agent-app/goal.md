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
| AskUserQuestion 留痕（本轮及后续逐级确认） | 会话内留痕，逐级确认发生时冻结 | 权威 | 随逐级确认更新 |

## Status

**proposed（2026-07-18，material change：业务与技术栈重定）**

本 goal 处于 propose 阶段，当前子阶段为需求分析（Requirement Analysis）。五份契约文件（本文件 + goal-breakdown.md + thresholds.md + data-contract.md + feedback-policy.md）已按新业务身份重写落盘，无 `rounds/` 目录、无执行轮。dev 分解明确推迟至需求达 dev-ready 并经用户签署后注入（届时再次执行 `$harnessloop-goal update`）。RA-L1 顶层域结构（七支柱 P1–P7）已经用户 2026-07-18 确认（见 goal-breakdown.md「L1 七支柱」表，状态 confirmed）。下一步：RA-L2 首轮（架构核心 P1-P3，用户指定优先）展开中，pending 用户确认。
