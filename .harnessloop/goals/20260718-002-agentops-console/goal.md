# Goal

## Goal

以三插件（harnessloop/hopper/kata）全栈驱动，探索性设计并开发 **AgentOps 控制台**——一个 app-server-console 三端系统：

- **server**：聚合多机 agent 工作流状态，数据源为三源——`.hopper/`（hopper 派发队列与产物）、`.harnessloop/`（goal/round 协议状态）、kata wiki（知识沉淀）
- **console（Web）**：提供四类运营视图——任务流水、成本账本、评审漏斗、知识图谱
- **app（轻客户端）**：提供终态通知（terminal event 推送）与 human-decision 移动审批

开发过程同步实时完善三插件自身能力（插件进化为本 goal 的横切产出，非独立 goal）。全程以里程碑驱动的文章连载对外公开。

用户 2026-07-18 决策（四项，构成本 goal 边界）：

1. 域 = AgentOps 控制台（非通用运维平台、非商业产品）
2. 技术栈交由 S2 设计轮决定（本 goal 提出阶段不预设技术栈）
3. 发布节奏 = 里程碑驱动（非固定周更）
4. 成本记账（round_cost/异构算力性价比）不设硬性数值目标，仅要求记账完整与如实报告

## Non-Goals

- 不承诺生产级上线或商业化——本 goal 是探索性实验，失败与成功皆为可接受的结果
- 不做多租户 SaaS
- 不自研 agent 执行能力——AgentOps 控制台只做运营面（观测/记账/审批/通知），不替代或包装 agent 本身的执行
- 插件（harnessloop/hopper/kata）的进化仅由本 goal 的实战需求驱动，不做推测性功能开发
- 不承诺固定周更的连载节奏（见用户决策 3）

## Success Condition

本 goal 为探索性 goal，成功定义为「探索定义」：以下三项皆有落盘证据即视为成功（包括证据充分的失败/否定结论）。

1. **可行性结论**——三端（server/console/app）达到首个端到端 demo 流：一条真实 dispatch 任务从 server 聚合 → console 展示 → app 终态通知，并得出有证据支撑的可行性结论（结论为“不可行”且证据充分，同样计入成功，见 feedback-policy.md 探索性否定结论条款）
2. **插件进化**——≥ 5 项由本 goal 实战触发的改进发布至上游三插件（沿用 TH-xxxx 编号与版本发布留痕惯例）
3. **内容连载**——≥ 3 篇里程碑文章成稿至 PR wiki `drafts/`（首篇 = 首个 feature 全栈闭环）

## Acceptance Criteria

| Criterion | Evidence required | Verification method | Human confirmation required |
| --- | --- | --- | --- |
| 1. 设计轮技术选型决策记录（候选对比 + hopper 研究佐证）经用户确认 | S2 技术选型决策记录文档（含候选对比表 + hopper 研究任务产物引用） | 对抗性设计评审 + 用户确认 | 是 |
| 2. server 聚合本机三源状态并提供 API | server 代码 + API 响应记录 | TODO (owner: 待 S2 技术选型后具体化验证命令) | 否 |
| 3. console 四视图（任务流水/成本账本/评审漏斗/知识图谱）至少两个以真实数据渲染 | console 代码 + 真实数据渲染记录（截图/日志） | TODO (owner: 待 S2 具体化) | 否 |
| 4. app 收到真实 terminal event 通知打通一条 | app 代码 + 真实通知接收记录 | TODO (owner: 待 S2 具体化) | 否 |
| 5. human-decision 审批闭环 demo（console 内审批为基线，app 端为 stretch） | 审批闭环 demo transcript/记录 | TODO (owner: 待 S2 具体化) | 否 |
| 6. 每轮 round_cost 记账完整 + 最终异构算力性价比实测报告 | 各轮 round_cost 记账记录 + PR wiki metrics 页最终实测报告 | 与各轮 round-summary.md Cost 节比对 + 用户复核实测报告 | 否 |
| 7. 四条前瞻预测逐条对账 | PR wiki predictions 页（`~/.llm-wiki/surebeli-ip/milestones/2026-07-18-app-phase-predictions.md`）状态字段从 `pending` 更新为 `confirmed`/`refuted`（预测②另有 `confirmed-sequence`/`confirmed-disorder`） | 逐条对照该页“可验证范围”与本 goal 实际产出证据 | 否 |
| 8. 里程碑文章 ≥ 3 篇成稿至 PR wiki `drafts/` | ≥ 3 篇文章成稿文件（PR wiki `drafts/` 下） | 用户发布确认 | 是 |

## Required Human Decisions

- 技术选型确认（S2 末，见 Acceptance Criteria #1）
- 每篇连载文章的发布确认（见 Acceptance Criteria #8）
- feature 级里程碑验收（每个 S3 起子目标完成一个可独立发布的 feature 时）
- 可行性最终结论签署（S7 收口，见 Success Condition ①）

## Source Of Truth

| Document or system | Path or URL | Trust level | Last verified |
| --- | --- | --- | --- |
| 用户决策记录 | 本 `goal.md`（本节 Goal 中列出的四项用户决策）+ AskUserQuestion 留痕（2026-07-17/18 会话） | 权威 | 2026-07-18 |
| 预测基线 | `~/.llm-wiki/surebeli-ip/milestones/2026-07-18-app-phase-predictions.md`（四条可验证预测 + 四条 PR 叙事线，冻结基线，pending 待对账） | 权威（冻结基线） | 2026-07-18 |
| 插件能力基线 | `docs/hopper-capability-map.md`（2026-07-17）+ `docs/kata-capability-map.md`（2026-07-17）+ `~/.llm-wiki/test-harnessloop/plugins/harnessloop-design-debt.md`（harnessloop 自身无独立 docs/ capability-map，以此 design-debt wiki 页作为其能力/债务基线，updated 2026-07-17） | 权威 | 2026-07-18（三份基线文件本身更新于 2026-07-17，本次核实于 2026-07-18） |

## Status

**proposed（2026-07-18）**

本 goal 处于 propose 阶段：五份契约文件（本文件 + goal-breakdown.md + thresholds.md + data-contract.md + feedback-policy.md）已落盘，无 `rounds/` 目录、无执行轮。下一步需经 `$harnessloop-continue` 门后方可开启 S1 discovery round 0001（见 goal-breakdown.md）。
