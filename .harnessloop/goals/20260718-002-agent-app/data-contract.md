# Data Contract

标准四类证据（`static`/`dynamic`/`runtime`/`source`）+ `human-confirmation` 沿用协议既定定义（见 `harnessloop-evidence` SKILL）。下表列出本 goal 特有的具体证据源实例。

## Valid Evidence Sources

| Source | Type | Access method | Freshness | Validation method | Drift risk | Credential requirement |
| --- | --- | --- | --- | --- | --- | --- |
| `.hopper/queue.md` + 派发产物 | dynamic/source | 本地文件读取 | 随每次 dispatch 刷新 | 与 `hopper:status`/`hopper:result` 输出比对 | 中——RA-L3 调研任务量增加后需评估产物质量一致性 | 无 |
| `.harnessloop/goals/**`（本 goal 及既有 goal） | source | 本地文件读取 | 随每轮/每级刷新 | 与 `verify_protocol.py` 输出比对 | 低（单机协议门保障） | 无 |
| kata wiki（`test-harnessloop` + `surebeli-ip` 双 wiki） | source | 本地文件读取 @ git HEAD | 随 `wiki-ingest`/`wiki-sync` 刷新 | `wiki-lint`/`wiki-graph` 走查 | 中——多机 `wiki-sync` 冲突风险 | 无 |
| COST-LOG（round_cost 记账，具体路径待 dev-readiness 后确定） | dynamic | 本地文件读取 | 每轮刷新 | 与各轮 `round-summary.md` Cost 节比对 | 低 | 无 |
| PR wiki `drafts/`（里程碑连载） | dynamic/human-confirmation | 本地文件读取 + 用户发布确认 | 每次成稿刷新 | 用户确认 + diff 比对 | 低 | 无 |
| human-confirmation（用户决策记录） | human-confirmation | AskUserQuestion 留痕 + `goal.md` 引用 | 决策发生时冻结 | 与 `goal.md` Required Human Decisions 对照 | 低 | 无 |
| newapi（计费/成本证据源，待接入） | dynamic | 待接入——X2「统一经 newapi」为 2026-07-18 已锁定架构决策，但实际 API/dashboard 访问方式待 D6（newapi 集成方式）调研确认后接入 | 待接入后随每次内核 LLM 调用刷新 | 待接入后与 newapi 账单/用量数据比对 | 中——接入前 X2 仅为架构承诺，非实测证据，不可引用为已生效的计费事实 | 待接入后确定（可能需要 API key，接入后按 `harnessloop-secrets` 流程登记） |

**待定桥接约定（TODO，owner: RA-L2/RA-L3）**：hopper handoffs/T-xxx 产物作为本 goal 证据的桥接约定（谁派发、派给谁、证据落脚点的三角链条）尚未定义，将在需求分析展开过程中（RA-L2 支柱展开或 RA-L3 技术选型调研阶段）确定。此为已知摩擦点，如实标注为待定而非已解决。

**外部项目形态待确认（owner 细化，2026-07-18）**：openclaw / hermas / newapi / codex app sdk / claude code sdk 均为外部项目，其实际形态、接口、能力范围**待 RA-L3 调研确认**，在调研完成前**禁止臆造其能力**（不得凭记忆或训练知识断言这些项目具备某功能/接口，须以 RA-L3 实际调研产物——如项目仓库/文档/hopper research 产物——为准）。owner 明确落到 RA-L3 七项决策议程（见 goal-breakdown.md「RA-L3 议程」）：

| 外部项目 | 调研内容 | Owner（RA-L3 议程项） |
| --- | --- | --- |
| openclaw / hermas | 内核形态、切换机制 | D1（内核抽象接口规格） |
| openclaw / hermas | 本地分发打包方式 | D7（本地内核分发打包） |
| newapi | 网关集成方式、计费/成本/能力开关接口 | D6（newapi 集成方式） |
| newapi | server 侧对接可行性（作为瘦控制面选型的一部分） | D3（Server 技术选型） |
| codex app sdk / claude code sdk | 内核兼容性 | D1（内核抽象接口规格） |

资料**待用户提供或 hopper 调研**。

## Valid Tools And Systems

| Tool/system | Purpose | Read/write scope | Account role | Verification command | Failure handling | Local parameter reference |
| --- | --- | --- | --- | --- | --- | --- |
| hopper dispatch/probe/result | RA-L3 技术选型调研佐证（含 server 完整调研、外部项目形态调研） | 只读（研究/调研任务） | TODO (owner: user) | `hopper:status` / `hopper:result` | TODO (owner: RA-L2/RA-L3) | 无 |
| kata wiki-ingest / wiki-query | 需求分析各级展开文档与调研产物的知识沉淀 | 读写（wiki 页面） | TODO (owner: user) | kata `wiki-lint` / `wiki-query` | TODO (owner: RA-L2/RA-L3) | 无 |
| `verify_protocol.py` | 机械协议门 | 只读 | TODO (owner: user) | `python3 <plugin-cache>/skills/harnessloop-loop/scripts/verify_protocol.py --project 本项目` | 定位失败原因后修复重跑 | 无 |
| agent app / console / server 运行时（技术栈待 RA-L3/RA-L4 定） | 三端系统本体（dev 阶段，RA-L4 dev-readiness 后启动） | 读写（具体范围待 RA-L3/RA-L4 定） | TODO (owner: RA-L4) | TODO (owner: RA-L4) | TODO (owner: RA-L4) | TODO (owner: RA-L4——若涉及 license 服务/云服务，可能需要凭证) |

## Local Channel Parameter Requirements

| Channel ID | Parameter key | Sensitivity | Storage | Required for | Must be present before |
| --- | --- | --- | --- | --- | --- |

需求分析阶段暂无已知外部凭证需求。RA-L3 技术选型确定后，若涉及 license 服务、newapi、云服务或第三方 API/SDK（openclaw/hermas/codex app sdk/claude code sdk 等），按 `harnessloop-secrets` 流程补充本表并在 `.harnessloop/local/channel-params.json` 中登记本地参数引用。

## Invalid Evidence

- 未经 probe 的 vendor 能力假设（例如未经 `hopper:probe` 实测的 vendor 能力声称）
- 未落盘的口头结论（会话内讨论但未写入 goal 契约文件或 wiki 的结论，不可作为证据引用）
- openclaw / hermas / newapi / codex app sdk / claude code sdk 的能力或接口声称：均为外部项目，实际形态与接口**待 RA-L3 调研确认**，禁止凭记忆或训练知识臆造其能力（见上方「外部项目形态待确认」）
- `harnessloop/examples/mock-project/`：已知系统性落后模板（沿用既有 goal 20260716-001-setup-wizard 的既定失效判断，无需重新评估）

## Secret Handling

- Do not store secret values in Harnessloop files.
- Store secret names, local parameter keys, required scopes, configured storage, and verification commands only.
- Use `.harnessloop/local/channel-params.json` for local ignored values or provider references.

## Revision Policy

- Human confirmation required for source changes: yes
- Human confirmation required for threshold changes: yes
