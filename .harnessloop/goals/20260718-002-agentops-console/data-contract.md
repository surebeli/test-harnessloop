# Data Contract

标准四类证据（`static`/`dynamic`/`runtime`/`source`）+ `human-confirmation` 沿用协议既定定义（见 `harnessloop-evidence` SKILL）。下表列出本 goal 特有的具体证据源实例。

## Valid Evidence Sources

| Source | Type | Access method | Freshness | Validation method | Drift risk | Credential requirement |
| --- | --- | --- | --- | --- | --- | --- |
| `.hopper/queue.md` + 派发产物 | dynamic/source | 本地文件读取 | 随每次 dispatch 刷新 | 与 `hopper:status`/`hopper:result` 输出比对 | 高——多机场景下 `.hopper` 状态可能不同步（S1 待评估） | 无 |
| `.harnessloop/goals/**`（本 goal 及既有 goal） | source | 本地文件读取 | 随每轮刷新 | 与 `verify_protocol.py` 输出比对 | 低（单机协议门保障） | 无 |
| kata wiki（`test-harnessloop` + `surebeli-ip` 双 wiki） | source | 本地文件读取 @ git HEAD | 随 `wiki-ingest`/`wiki-sync` 刷新 | `wiki-lint`/`wiki-graph` 走查 | 中——多机 `wiki-sync` 冲突风险 | 无 |
| COST-LOG（round_cost 记账，具体路径待 S3 确定） | dynamic | 本地文件读取 | 每轮刷新 | 与各轮 `round-summary.md` Cost 节比对 | 低 | 无 |
| PR wiki `drafts/` + `milestones/` 预测页 | dynamic/human-confirmation | 本地文件读取 + 用户发布确认 | 每次成稿/对账刷新 | 用户确认 + diff 比对 | 低 | 无 |
| human-confirmation（用户决策记录） | human-confirmation | AskUserQuestion 留痕 + `goal.md` 引用 | 决策发生时冻结 | 与 `goal.md` Required Human Decisions 对照 | 低 | 无 |

**待定桥接约定（TODO，owner: S1 discovery round）**：hopper handoffs/T-xxx 产物作为本 goal 证据的桥接约定（谁派发、派给谁、证据落脚点的三角链条）尚未定义，将在 S1 首轮讨论中确定。此为已知摩擦点——见 `~/.llm-wiki/surebeli-ip/milestones/2026-07-18-app-phase-predictions.md` 预测②摩擦点③"hopper/harnessloop 证据桥接缺口"，本 goal 是该预测的直接实战验证场域，如实标注为待定而非已解决。

## Valid Tools And Systems

| Tool/system | Purpose | Read/write scope | Account role | Verification command | Failure handling | Local parameter reference |
| --- | --- | --- | --- | --- | --- | --- |
| hopper dispatch/probe/result | 三源聚合调研 + S2 技术选型佐证 | 只读（研究/调研任务） | TODO (owner: user) | `hopper:status` / `hopper:result` | TODO (owner: S1) | 无 |
| kata `wiki-graph`/`wiki-federate` | 知识图谱视图候选数据源 | 只读 | TODO (owner: user) | kata `wiki-graph` 查询 | TODO (owner: S1) | 无 |
| `verify_protocol.py` | 机械协议门 | 只读 | TODO (owner: user) | `python3 <plugin-cache>/skills/harnessloop-loop/scripts/verify_protocol.py --project 本项目` | 定位失败原因后修复重跑 | 无 |
| server/console/app 运行时（技术栈待 S2 定） | 三端系统本体 | 读写（具体范围待 S2 定） | TODO (owner: S2) | TODO (owner: S2) | TODO (owner: S2) | TODO (owner: S2——若涉及移动推送/云服务，可能需要凭证) |

## Local Channel Parameter Requirements

| Channel ID | Parameter key | Sensitivity | Storage | Required for | Must be present before |
| --- | --- | --- | --- | --- | --- |

propose 阶段暂无已知外部凭证需求。S2 技术选型确定后，若涉及外部推送服务、云服务或第三方 API，按 `harnessloop-secrets` 流程补充本表并在 `.harnessloop/local/channel-params.json` 中登记本地参数引用。

## Invalid Evidence

- 未经 probe 的 vendor 能力假设（例如未经 `hopper:probe` 实测的 vendor 能力声称）
- 未落盘的口头结论（会话内讨论但未写入 goal 契约文件或 wiki 的结论，不可作为证据引用）
- `harnessloop/examples/mock-project/`：已知系统性落后模板（沿用既有 goal 20260716-001-setup-wizard 的既定失效判断，无需重新评估）

## Secret Handling

- Do not store secret values in Harnessloop files.
- Store secret names, local parameter keys, required scopes, configured storage, and verification commands only.
- Use `.harnessloop/local/channel-params.json` for local ignored values or provider references.

## Revision Policy

- Human confirmation required for source changes: yes
- Human confirmation required for threshold changes: yes
