# Goal Breakdown

> **状态标注**：本文件为 propose 阶段初稿。S1 只读发现轮完成后，须按协议对本文件（Discovery Handoffs / Subgoals / Tasks 三张表）进行细化更新，S3 起各子目标的具体验证命令待 S2 设计轮确定后回填。

## Long-Term Goal

以三插件（harnessloop/hopper/kata）全栈驱动，探索性设计并开发 AgentOps 控制台——app-server-console 三端系统，同步实时完善三插件能力，全程以里程碑驱动的文章连载公开（详见 goal.md）。

## Read-Only Discovery Plan

Use subagent or swarm handoffs for independent read-only investigation.

Discovery questions:

- Current system state: 三插件现状基线已有（capability-map + design-debt，见 goal.md Source of Truth）；`.hopper/`/`.harnessloop/`/kata wiki 三源的数据结构与可聚合面尚未系统盘点——TODO (owner: S1 discovery round)
- Relevant data and tools: hopper 既有 dispatch/probe/status 产物；`.harnessloop/goals/`、`rounds/` 目录结构；kata `wiki-graph`/`wiki-federate` 能力（知识图谱视图候选数据源）
- Runtime validation options: `verify_protocol.py`（协议门）；各插件自带验证（如 `npm run validate`）；S2 后需补技术栈级验证命令（TODO，见 thresholds.md）
- Constraints and risks: 多机接入形态未定（单机优先 vs 多机同步机制待调研）；hopper 研究类任务（prd-research/market 等）在本 goal 属首次实战，产物质量与 grok 佐证路径未经验证；三源（`.hopper`/`.harnessloop`/kata wiki）之间无统一 schema，聚合面盘点是首次尝试；hopper handoffs/T-xxx 产物作为证据的桥接约定尚未定义（见 data-contract.md）
- Prior work or known failures: `~/.llm-wiki/surebeli-ip/milestones/2026-07-18-app-phase-predictions.md` 预测②摩擦点③明确指出"hopper/harnessloop 证据桥接缺口"——本 goal 是该预测的首个实战验证场域；此前 goal（20260716-001-setup-wizard）未涉及跨插件聚合，无直接先例可循

## Discovery Handoffs

| Handoff | Purpose | Inputs | Output path | Status |
| --- | --- | --- | --- | --- |
| （S1 discovery round 0001 尚未开启，无已派发 handoff） | | | | |

## Subgoals

| ID | Subgoal | Depends on | Evidence required | Validation method | Risk |
| --- | --- | --- | --- | --- | --- |
| S1 | Discovery（只读）：三源可聚合面盘点 / hopper dashboard 现状复用评估 / 多机接入形态调研（含 hopper 研究任务首次实战） | 无 | discovery handoff 输出 + hopper 研究任务产物 | 只读发现轮走查 + 用户复核 | 三源无统一 schema，盘点可能低估聚合复杂度；hopper 研究任务首次实战，产物质量未知 |
| S2 | Design：架构设计 + 技术栈选型（server/console/app 三端），以 hopper prd-research 佐证 | S1 | 技术选型决策记录（候选对比 + hopper 研究产物引用） | 对抗性设计评审 + 用户确认技术选型 | 探索性项目的技术栈选型可能与既有插件假设（如证据类型、验证方式）冲突 |
| S3 | Server MVP：单机三源聚合 + API + SSE | S2 | server 代码 + API/SSE 响应记录 | TODO (owner: 待 S2 定具体验证命令) | 三源实时性/一致性未知；单机优先，多机风险推迟到 S6 |
| S4 | Console MVP：任务流水 + 成本账本两视图 | S3 | console 代码 + 真实数据渲染记录 | TODO (owner: 待 S2 定) | 真实数据量在 MVP 阶段可能不足以充分验证视图设计 |
| S5 | App MVP：终态通知打通 | S3 | app 代码 + 真实 terminal event 通知记录 | TODO (owner: 待 S2 定) | 移动端推送通道选型未定（属 S2 技术选型范围） |
| S6 | 深化：评审漏斗 + 知识图谱 + human-decision 审批闭环（console 基线 / app stretch）+ 多机接入 | S4, S5 | 视图代码 + 审批闭环 demo transcript + 多机联调记录 | TODO (owner: 待 S2 定) | 多机同步一致性/时序风险；app 端审批为 stretch，可能不达成（不影响 goal 整体成功判定，见 goal.md Acceptance Criteria #5） |
| S7 | 收口：可行性结论 + 异构算力性价比实测报告 + 连载收口（≥ 3 篇成稿） | S1–S6 | 可行性结论文档 + PR wiki metrics 页 + ≥ 3 篇里程碑文章 | 用户签署可行性结论 + 逐篇发布确认 | 探索性结论可能为否定性——按 feedback-policy.md 补充条款，充分证据支撑的否定结论按 positive 处理，非风险项 |

**横切线（不占 S 编号，按触发发生，非独立执行阶段）：**

- **插件进化流**：由 S1–S7 各阶段实战触发的三插件改进，沿用 TH-xxxx 编号与版本发布留痕惯例，发布节奏不与 S 阶段绑定
- **内容连载流**：里程碑驱动的文章连载，成稿至 PR wiki `drafts/`，发布节奏不与 S 阶段绑定，仅要求首篇覆盖首个 feature 全栈闭环（见 goal.md Success Condition ③）。**术语核实**：本条目在需求原文中表述为"直播内容流"；结合 goal.md 全篇一致使用"文章连载""PR wiki drafts/"表述，且无任何视频/直播相关的验收标准或工具引用，此处理解为"实时/持续更新的内容连载流"而非视频直播。如与用户原意有出入，留待 S1 或首次连载文章确认时澄清。

## Tasks

| ID | Task | Parent subgoal | Scope boundary | Evidence required | Validation method |
| --- | --- | --- | --- | --- | --- |
| （S1 discovery round 尚未开始，task 级尚未展开；S1 完成后按需补充本表） | | | | | |

## Main-Session Decision

Chosen sequence: S1 → S2 → S3 → S4 → S5 → S6 → S7；插件进化流与内容连载流为横切线，随各 S 阶段触发产出，不独占 S 编号、不阻塞主线推进。

Rejected alternatives: TODO (owner: user) — propose 阶段尚未展开候选序列的正式比较（例如"S4/S5 并行 MVP" vs "顺序 MVP"），留待 S1/S2 讨论时补充。

Reasoning: 探索性 goal，采用"薄 MVP 先行、深化后置"的顺序——先以最小三源聚合 + 双视图 + 单向通知验证端到端可行性（S3–S5），再深化四视图全量与审批闭环（S6），最后收口可行性结论与实测报告（S7）。委派计划细节（各 S 阶段的写入代理/评审代理分工）待 S2 设计轮确定后回填，属预期缺口而非遗漏。
