---
task_id: T-005
adapter: grok
model: grok-4.5
status: done
mode: background
phase: done
last_progress_at: "2026-07-21T07:31:18.904Z"
last_progress: Task completed successfully.
progress_seq: 2
terminal_event_emitted: true
end_time: "2026-07-21T07:31:18.902Z"
exit_code: 0
signal: null
timed_out: null
duration_ms: 257821
adapter_status: success
---

# T-005 — D1 KernelPort 硬事实补齐（OpenClaw / Hermes / new-api）

## Summary

本任务对 D1 KernelPort 评审中“未能确认”的 OpenClaw、Hermes Agent、new-api 接口事实做了定向 web 调研。OpenClaw 官方协议文档可确认：`sessions.create` / `sessions.abort` / `sessions.delete` / `chat.abort`、事件 `seq` 且**不重放**、run 级 `runId` 取消、审批 first-answer-wins 与 timeout 语义；**没有**名为 `sessions.stop` 的 RPC，也**没有** `capabilities_changed` 广播事件。Hermes ACP 官方文档确认 session 动词为 new/load/resume/fork/list/cancel（无 delete/destroy/stop），审批经 ACP permission bridge，CLI 为终端交互/YOLO。new-api 可按 **user 账号下多 token** 签发（name/group/quota），有 log/self、usage/token 查询；**未能确认** per-request token、官方结算 webhook、以及客户端可注入并回查的 correlation id。信息稀缺处已诚实标注，未臆造。

## Files touched

- `.hopper/handoffs/T-005-output.md`：按任务要求写入只读研究结论（本文件）。

## Acceptance verification (5/5)

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | 按 A/B/C 分节，逐条给确认事实+URL 或“未能确认” | 见下文 **研究正文 A/B/C** |
| 2 | 每条标注对应评审 must-fix | 每条末尾 `→ must-fix: …` |
| 3 | 信息稀缺处诚实标注，宁缺毋造 | 全文凡无一手来源均标 **未能确认** |
| 4 | 语言中文 | 本文件主体中文 |
| 5 | 只读研究，结论落盘本路径 | 仅写入 `.hopper/handoffs/T-005-output.md` |

机器可检：

```bash
test -f .hopper/handoffs/T-005-output.md && rg -n "^(## Summary|## Files touched|## Acceptance|## Decisions|## Open questions|## Verdict|## Next|### A\.|### B\.|### C\.)" .hopper/handoffs/T-005-output.md
rg -n "未能确认|must-fix:|https://" .hopper/handoffs/T-005-output.md | head -80
```

## Decisions / deviations

- 假定“OpenClaw”指官方产品 `docs.openclaw.ai` Gateway（默认端口 18789），非第三方镜像文档。
- 假定“Hermes Agent”指 Nous Research 的 `hermes-agent.nousresearch.com` 文档。
- 假定“new-api / newapi”指 QuantumNous/new-api（one-api 系）及 `doc.newapi.pro` / `docs.newapi.pro` 文档。
- 第三方二次整理页（如 lzw.me 镜像 API 参考）仅作旁证，不作为唯一硬事实来源。
- 未做本地源码 checkout / 运行时 probe；事实以公开官方文档与官方 issue 为准。

## Open questions

1. OpenClaw：管理员中途 revoke/rotate device token 或收紧 scopes 后，**已连接 socket** 是否立刻 drop、还是仅对新 RPC 返回 `FORBIDDEN`/`AUTH_SCOPE_MISMATCH`——文档描述 reconnect 升级路径，**在线降权推送事件名未确认**。
2. OpenClaw：`approval.resolve` / `exec.approval.resolve` 请求体是否携带 `toolCallId`（audit 里 tool 事件有 `toolCallId`，但 resolve 公开形态主要是 approval id + kind + decision）。
3. Hermes：ACP 是否暴露标准 `session/close` 或内部 `SessionManager.remove` 的对外 RPC 名；持久化 session 删除是否仅 CLI `hermes sessions delete`。
4. Hermes：CLI 交互式审批是否有可编程 JSON/stdio 协议（除 ACP bridge 与 `--yolo` 旁路外）。
5. new-api：是否存在结算/充值 webhook；请求侧是否支持任意 correlation header 写入消费日志并可用 API 反查。
6. new-api：是否支持“单次对话即签即废”的 ephemeral token（Realtime 的 1 分钟 ephemeral token 仅见 realtime sessions 路径，不覆盖通用 chat completions）。

## Verdict

**PASS**

（研究项已按 A/B/C 逐条落实；硬事实足够支撑 D1 v2 收窄后的 openclaw+hermes 重设计输入。残留缺口已列入 Open questions，不阻塞把本调研标为完成。）

## Next recommendation

1. 将本文件中 **已确认** 条款回写 `kernel-ecosystem-facts.md`（或 D1 v2 事实基线），替换评审中的“未能确认”。
2. D1 v2 契约建议：
   - OpenClaw：`stop` 不要映射为不存在的 `sessions.stop`；拆成 `sessions.abort`/`chat.abort`（可选 `runId`）与 `sessions.delete`/`sessions.reset`。
   - 不要依赖 `capabilities_changed` 事件；改为 reconnect + `hello-ok` / scope 错误驱动刷新，或 KernelPort 自维护 revision。
   - 事件恢复：官方明确 **不重放** → `chat.history` + re-subscribe + `inFlightRun` 采纳。
   - Hermes：`stop` 用 ACP `cancel`（中断当前 prompt）+ 进程级/CLI 持久删除，不要伪造 delete 动词。
   - new-api 成本归因：v1 用 **per-session 专用 token（name=sessionId）** + `/api/log/self?token_name=` 聚合，不假设 per-request token 或 webhook。
3. 可选二次探针（非本任务）：本地装 OpenClaw/Hermes/new-api 跑一次 connect/abort/approval/token-create 对照。

---

# 研究正文

## A. OpenClaw（Gateway WS JSON-RPC，默认 18789）

**背景来源**：Gateway 单端口复用 WS control/RPC + HTTP；默认端口 18789。  
- https://docs.openclaw.ai/gateway  
- https://docs.openclaw.ai/gateway/protocol  

### A1. Session 生命周期：create / stop / delete 确切 RPC；`sessions.delete`；stop 语义

**确认到的事实**

| 动作 | 确切方法名 | 说明 |
|------|------------|------|
| 创建 | `sessions.create` | 创建 session entry；可选 `model`/`thinkingLevel`；可挂 worktree；可嵌套初始 `chat.send`（失败时 `runStarted:false` + `runError`） |
| 取消活跃工作 | `sessions.abort` | 传 `key` + 可选 `runId`，或仅 `runId`（网关可反查 session） |
| 聊天层取消 | `chat.abort` | UI Stop 调用；支持 `{ sessionKey }` 无 `runId` 时 abort 该 session 全部 active runs；有 `runId` 可取消排队/活跃 turn |
| 删除 | `sessions.delete` | 与 `sessions.reset`、`sessions.compact` 同属 session maintenance |
| 重置 | `sessions.reset` | 维护/滚动新 sessionId（与 chat `/new` `/reset` 概念一致） |

- **有 `sessions.delete`**：官方协议 Session control 明确列出。  
  来源：https://docs.openclaw.ai/gateway/protocol  
- **没有名为 `sessions.stop` 的 RPC**（公开协议列表中未见 `stop` 方法名）。概念上的 “stop” = abort 活跃 run，**不是** delete。  
- **abort 与 delete 不是原子一步**：  
  - `sessions.abort` / `chat.abort`：取消活跃（及授权范围内的排队）工作；aborted 部分 assistant 文本可保留进 transcript。  
    来源：https://docs.openclaw.ai/web/control-ui 、https://docs.openclaw.ai/concepts/queue  
  - `sessions.delete`：维护删除/归档；sub-agent 文档写 auto-archive 使用 `sessions.delete` 并把 transcript rename 为 `*.deleted.<timestamp>`。  
    来源：https://docs.openclaw.ai/tools/subagents  
- **abort 后能否 resume**：  
  - abort **不销毁** session；session 行与 transcript 仍在，后续可再 `chat.send` / `sessions.send`。  
  - Control UI 在 reconnect 时用 `chat.history` 返回的 `sessionId` 继续同一 conversation。  
    来源：https://docs.openclaw.ai/web/webchat 、https://docs.openclaw.ai/gateway/clients  
  - **delete 之后**再 send 同一 key：**未能确认** 是否自动重建 vs 必须 `sessions.create`（公开 docs 强调 delete 为 maintenance/archive，未给 resume-after-delete 合同）。

**HTTP 旁路（非 WS 主路径）**：第三方 API 参考页写 `DELETE /v1/sessions/{id}`——与 WS `sessions.delete` 语义相近，但 D1 窄腰应以 Gateway protocol 为准。  
旁证：https://lzw.me/docs/opencodedocs/openclaw/openclaw/appendix/api-reference/

→ **must-fix**：T-004 F-02/F-08 类 stop 语义、`sessions.delete` 是否存在、abort≠destroy。

### A2. Capabilities / scopes 协商；中途变化；是否有变更事件

**确认到的事实**

1. **连接时协商**  
   - 首帧必须 `connect`；参数含 `role`、`scopes`、`caps`（client capabilities）、节点还可有 `commands`/`permissions`。  
   - 成功返回 `hello-ok`：`features.methods` / `features.events`（**保守发现列表，非全量**）、`auth.role` / `auth.scopes`、`policy`、`snapshot`。  
   来源：https://docs.openclaw.ai/gateway/protocol 、https://docs.openclaw.ai/gateway  

2. **`caps` vs `scopes`**  
   - `scopes`：授权（`operator.read|write|admin|approvals|pairing|…`）。  
   - `caps`：客户端能力声明（如 `tool-events`），**不是**权限；Gateway 按 caps 决定是否投递 tool 事件 / 是否对 agent 暴露某工具。  
   来源：https://docs.openclaw.ai/gateway/protocol 、https://docs.openclaw.ai/gateway/clients  

3. **中途能否变化**  
   - **扩大** scopes/role：已配对设备 reconnect 请求更广 scopes 会生成 **pending upgrade pairing**，不会静默放宽。  
     来源：https://docs.openclaw.ai/gateway/operator-scopes  
   - **Token rotate**：`openclaw devices rotate … [--scope …]` 可替换后续 cached-token reconnect 的 scope 集，**不能** mint 未批准 role。  
     来源：https://docs.openclaw.ai/cli/devices  
   - **同一条已连接 WS 上是否可热更新 scopes**：文档路径是 reconnect/pairing/rotate，**未能确认** 有 in-session re-auth RPC。

4. **有没有 `capabilities_changed` / scope 变更事件**  
   - 协议列出的广播事件族：`chat`、`session.*`、`sessions.changed`、`presence`、`tick`、`health`、`heartbeat`、`config.changed`、`exec.approval.*`、`plugin.approval.*`、`device.pair.*`、`shutdown` 等。  
   - **未发现** `capabilities_changed` / `scopes.changed` 类事件。  
   - 客户端感知路径：  
     - 后续 RPC 收到 `FORBIDDEN` / `MISSING_SCOPE` / `AUTH_SCOPE_MISMATCH`；  
     - 或 reconnect 走 pairing/token 流程；  
     - `config.changed` 仅表示配置写入（不含 config 内容，需 `config.get` 刷新）。  
   来源：https://docs.openclaw.ai/gateway/protocol 、https://docs.openclaw.ai/gateway/troubleshooting  

→ **must-fix**：capabilities_changed / INV-4 静态 capabilities 不可靠；A2 确认应 **自建 revision 或 reconnect 驱动**，勿依赖不存在的 capabilities 事件。

### A3. 事件流 `seq`；断线是否重放；恢复机制

**确认到的事实**

1. **事件帧形状**含可选 `seq` / `stateVersion`：  
   `{type:"event", event, payload, seq?, stateVersion?}`  
   来源：https://docs.openclaw.ai/gateway/protocol  

2. **两层序号**  
   - **连接级** outer `seq`：每客户端连接单调；**新连接重置**。  
   - **`agent` 事件 payload 内 `seq`**：按 **run** 分配，排序该 run 的 lifecycle/assistant/tool 流。  
   来源：https://docs.openclaw.ai/gateway/clients  

3. **不重放**（官方明文）：  
   > Events are not replayed. On sequence gaps, refresh state (`health`, `system-presence`) before continuing.  
   来源：https://docs.openclaw.ai/gateway  

4. **恢复机制（官方客户端指南）**  
   每次成功 reconnect：  
   1. 重建 `sessions.subscribe` / `sessions.messages.subscribe`  
   2. `chat.history` **替换**本地投影  
   3. 若有 `inFlightRun`，采纳其 `runId`/buffered text  
   4. 用 `sessionInfo.hasActiveRun` / `activeRunIds` 判断  
   5. 后续按 `payload.runId` + per-run `seq` 调和；前向 gap → **reload history**  
   审批：连上后 `exec.approval.list` backfill + 监听 `exec.approval.requested/resolved`  
   来源：https://docs.openclaw.ai/gateway/clients  

→ **must-fix**：事件 envelope `seq` 可选且不重放；KernelPort 不得要求“原生全量可重放 seq 流”。

### A4. 审批 RPC 形态、关联 id、超时

**确认到的事实**

**方法族（协议）**

| 方法 | 作用 |
|------|------|
| `approval.get` / `approval.resolve` | kind-agnostic 持久审批；resolve 接受 **canonical approval id** + **kind** + **decision**；**first-answer-wins** |
| `approval.history` | 终端审批历史（30 天） |
| `exec.approval.request` / `get` / `list` / `resolve` / `waitDecision` | exec 专用适配层（同一 durable registry） |
| `plugin.approval.*` | 插件审批 |
| 事件 | `exec.approval.requested` / `resolved`；`plugin.approval.*`；可选 `session.approval`（需 `sessions.messages.subscribe` + `includeApprovals:true`） |

来源：https://docs.openclaw.ai/gateway/protocol  

**请求/响应形态（公开文档粒度）**

- 广播：`exec.approval.requested` → 客户端 `exec.approval.resolve`（或统一 `approval.resolve`）。  
- **关联 id**：审批以 **approval id** 为主键；gateway 用 approval id 关联后续 `Exec finished/denied (gateway id=…)`。  
  来源：https://docs.openclaw.ai/tools/exec-approvals  
- **toolCallId**：audit `tool_action` 事件可含 `toolCallId`；**resolve 方法公开签名是否强制携带 toolCallId → 未能确认**（以 approval id 为准即可闭环）。  
- 决策值（chat/native）：`allow-once` / `allow-always` / `deny`（`/approve <id> …`）。  
  来源：https://docs.openclaw.ai/tools/exec-approvals-advanced  

**超时**

- 无决策直到 timeout → **approval timeout = 终端 deny**（host-command denial）；main-agent async 会对 originating session 发 internal followup。  
- Pending exec approvals **默认 30 分钟**后过期。  
- `askFallback`：无 UI / 超时策略 `deny | allowlist | full`（默认 deny）。  
- 社区/issue 提到约 2 分钟类超时可配置诉求——**默认精确秒数以安装配置为准；协议层保证的是 timeout→deny 语义**。  
  来源：https://docs.openclaw.ai/tools/exec-approvals 、https://docs.openclaw.ai/tools/exec-approvals-advanced 、https://github.com/openclaw/openclaw/issues/51287  

**权限**：resolve 需要 `operator.approvals`（`operator.write` **不能** subsume）。  
来源：https://docs.openclaw.ai/tools/exec-approvals-advanced  

→ **must-fix**：审批状态机、timeout fail-closed、关联 id（approval id）；支撑 T-004 F-04/F-06 类设计约束。

### A5. Run 寻址：能否取消指定 run；事件是否有 run/turn id

**确认到的事实**

- **可以按 run 取消**：  
  - `sessions.abort`：`key` + 可选 `runId`，或仅 `runId`。  
  - `chat.abort`：特定 `runId` 可取消仍在 queue 的 turn；无 `runId` 则先清授权排队再 abort active。  
  来源：https://docs.openclaw.ai/gateway/protocol 、https://docs.openclaw.ai/concepts/queue  
- **runId 的产生**：`agent` RPC 立即返回 `{ runId, acceptedAt }`；agent 事件按 `payload.runId` 调和。  
  来源：https://docs.openclaw.ai/concepts/agent-loop 、https://docs.openclaw.ai/gateway/clients  
- **turn**：队列文档称 queued **turn** 与 client `runId` 绑定；公开 API 主键是 **runId**，未见独立 `turnId` 字段作为取消句柄。  
- Audit：`agent_run` / `tool_action` 均要求 `runId`。  
  来源：https://docs.openclaw.ai/gateway/protocol  

→ **must-fix**：interrupt 必须支持 run 级寻址（OpenClaw 原生已支持）；KernelPort 若只暴露 session 级 interrupt 会丢能力。

---

## B. Hermes Agent（CLI + Messaging Gateway + ACP stdio）

### B1. ACP session 动词；有无 delete/destroy/stop；如何终止

**确认到的事实**

官方 ACP Internals 明确 HermesACPAgent 职责：

> initialize / authenticate  
> **new/load/resume/fork/list/cancel** session methods  
> prompt execution …

SessionManager 内部支持：create / get / **remove** / fork / list / cleanup（**remove 是实现层**，非对外文档化的 ACP 动词 `delete`）。

**Cancelation**：

```
cancel(session_id):
  - sets the session cancel event
  - calls agent.interrupt() when available
  - prompt response → stop_reason="cancelled"
```

来源：https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals  

用户文档：

- ACP sessions 由 adapter **进程内** session manager 跟踪；`list/load/resume/fork` **scoped to currently running ACP server process**。  
- 底层 AIAgent 仍走 Hermes 正常 persistence；跨进程恢复靠 state.db / session 机制（internals 亦写 ACP sessions 可进 `~/.hermes/state.db`——与 “list scoped to process” 并存，设计时注意 **live ACP list ≠ 全库**）。  
  来源：https://hermes-agent.nousresearch.com/docs/user-guide/features/acp  

**有没有 delete/destroy/stop（ACP）**

- 公开 ACP 动词列表：**无 delete / destroy / stop**。  
- **终止当前执行** = ACP **`cancel`**。  
- **销毁持久会话** = CLI 面 `hermes sessions`（browse/export/prune/**delete**），不是 ACP session method。  
  来源：https://hermes-agent.nousresearch.com/docs/reference/cli-commands  

→ **must-fix**：Hermes `stop` 不能 ✅ 映射为单一原生 delete；应拆 cancel（中断）vs CLI delete（持久移除）。

### B2. 审批：是否仅 ACP；CLI 能否编程捕获；请求/响应形态

**确认到的事实**

**ACP 线路**

- 危险 terminal 等走 ACP permission bridge。  
- 选项映射：  
  | ACP | Hermes 内部 |
  |-----|-------------|
  | `allow_once` | once |
  | `allow_always` | always（永久 allowlist） |
  | `allow_session` | 仅当前 ACP session 缓存 |
  | `deny` | deny |
- **Timeout / bridge 错误 → deny**（fail-closed）。  
- 已知 issue：edit approval 可能忽略配置的 `approvals.timeout`、硬编码 ~60s（实现细节风险）。  
  来源：https://hermes-agent.nousresearch.com/docs/user-guide/features/acp 、https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals 、https://github.com/NousResearch/hermes-agent/issues/63302  

**CLI 线路**

- 默认：终端 **交互式** approval dialog（TUI/CLI）。  
- 旁路：`hermes --yolo` / `hermes chat --yolo` / 环境 YOLO / 会话内 `/yolo` → **跳过**危险命令审批。  
- Messaging gateway：审批可 queue pending（与 CLI inline 不同）。  
  来源：https://hermes-agent.nousresearch.com/docs/user-guide/security 、https://hermes-agent.nousresearch.com/docs/user-guide/configuration 、https://hermes-agent.nousresearch.com/docs/reference/cli-commands  

**CLI 交互式审批能否被编程捕获**

- 公开文档 **未提供** 与 ACP 对等的“程序化 approval request/response JSON-RPC”用于经典 CLI。  
- 可编程路径：**走 ACP stdio**，或 **YOLO 关闭审批**，或 messaging 的 pending 审批命令（`/skills approve` 等 skill/memory 门控），**不是**捕获 TTY prompt。  
- 结论：**未能确认** CLI TTY 审批有稳定可编程协议；**已确认** ACP 可程序化、CLI 以交互/YOLO 为主。

→ **must-fix**：审批归一应默认 ACP（或 messaging pending），勿假设 CLI TTY 可桥。

### B3. Capabilities 协商与中途变化

**确认到的事实**

- ACP：`initialize` / `authenticate`；issue 记载 load/resume 能力声明曾有缺陷（客户端须检查 `loadSession` 等字段）。  
  来源：https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals 、https://github.com/NousResearch/hermes-agent/issues/6633  
- 工具面：ACP 使用固定 curated toolset **`hermes-acp`**（file/terminal/web/memory/skills 等；排除 messaging/cron 等）。  
  来源：https://hermes-agent.nousresearch.com/docs/user-guide/features/acp  
- CLI：`hermes tools`、session 内 `/tools enable|disable`；**移除 tool 会触发 session reset 以重建 tool manifest**（实践指南）。  
  旁证：https://blakecrosley.com/guides/hermes  
- **中途 capabilities 变更事件**：公开 ACP docs **未描述** `capabilities_changed` 推送；能力变化依赖 initialize 结果、toolset 配置、session reset。  
- **未能确认**：运行中动态 renegotiate 全量 agent capabilities 的标准 ACP 扩展。

→ **must-fix**：与 OpenClaw 类似，Hermes 也不提供通用 capabilities_changed；KernelPort 静态 descriptor 不足。

---

## C. new-api / newapi（QuantumNous/new-api，one-api 系）

### C1. Token 粒度：session/请求 vs user/tenant

**确认到的事实**

- Token 归属 **当前登录用户**；用户可 **创建多个 API Token**（`POST /api/token/`）。  
- 创建字段：`name`（≤30）、`expired_time`、`remain_quota`、`unlimited_quota`、`model_limits*`、`allow_ips`、`group`。  
- **不是** “每个 HTTP 请求自动签发临时 token” 的模型；是 **user 下的长期/配额型 key**，可用 name 区分 app/project/会话。  
  来源：https://doc.newapi.pro/en/api/fei-token-management/  
  旁证 skill：`/newapi create-token <name> [--group=xxx]` — https://docs.newapi.pro/en/docs/skills/newapi  
- **Realtime 特例**：`POST /v1/realtime/sessions` 可发 **1 分钟、单连接** ephemeral token——**仅 Realtime**，不推广到通用 chat。  
  来源：https://doc.newapi.pro/en/api/openai-realtime/  

**对成本归因的含义**

- **可行**：每 KernelPort session 创建独立 token（`name=session-…`），用 `token_name` 过滤日志 → **session 级归因**。  
- **不可默认假设**：每个 model request 自动独立 token。  
- **未能确认**：服务端“按 session_id 自动签发”的一等 API。

→ **must-fix**：C1 / T-004 F-09 newapi 归因——应用层 token-per-session，而非 per-request 原生。

### C2. 用量/计费 API；是否实时；结算 webhook

**确认到的事实（查询面存在）**

| 接口 | 鉴权 | 作用 |
|------|------|------|
| `GET /api/usage/token` | Bearer API key | 当前 token 额度：granted/used/available/limits/expires |
| `GET /api/log/self` | User + `New-Api-User` | 分页消费日志；可按 `token_name`/`model_name`/`group`/时间过滤 |
| `GET /api/log/self/stat` | User | 区间配额汇总；**rpm/tpm 为最近 60s**（近实时速率） |
| `GET /api/log/self/search` | User | 关键字搜索 |
| `GET /api/log/token?key=` | 公开（持 token key） | 按 token 查日志（CORS 友好） |
| `GET /api/log/` / `stat` / `search` | **Admin** | 全站日志与统计 |
| `DELETE /api/log/` | Admin | 按 timestamp 清理历史 |

来源：  
- https://doc.newapi.pro/en/api/token-usage/  
- https://github.com/QuantumNous/new-api-docs/blob/main/docs/en/api/fei-log.md  

**实时性**

- 消费在请求完成后写入日志（issue 中可见 `record consume log` 紧随 streaming finished）——**查询近实时，非流式 billing push**。  
  旁证：https://github.com/QuantumNous/new-api/issues/1854  
- `rpm`/`tpm` 明确 **last 60 seconds** 窗口。  

**结算 webhook**

- 公开管理/日志文档 **未描述** 官方 billing settlement webhook。  
- **未能确认** 通用“用量结算 webhook”产品能力（若私有部署自建钩子则超出本调研）。

→ **must-fix**：F-09——有 **pull** 查询，无已确认的 **push 结算 webhook**；UI 实时余额需轮询 + 接受延迟。

### C3. 请求关联 correlation id

**确认到的事实**

- 日志条目字段（文档示例）：`id`、`user_id`、`token_name`、`token_id`、`model_name`、`quota`、`prompt_tokens`、`completion_tokens`、`use_time`、`is_stream`、`channel_id`、`group`、`ip`、`other`（JSON 扩展）等。  
- 运行日志可见服务端 request id 字符串（如 `20260302054129299063706jlS7Qd1k`）用于 tracing——**是否等于客户端可设 header、是否出现在 `/api/log/self` 返回体 → 未能确认**。  
  旁证：https://github.com/QuantumNous/new-api/issues/1854  
- OpenAI 兼容调用常规 `Authorization: Bearer $NEWAPI_API_KEY`；文档 **未要求** 也 **未保证** 自定义 `X-Request-Id` / `X-Correlation-Id` 会写入可查询日志。  

**实践归因策略（基于已确认能力，非臆造 API）**

1. 每 session 独立 token → `token_name` 过滤；或  
2. 客户端记录 new-api 响应/本地时间窗 + token_name 做近似对账；  
3. **不能**在无额外约定下把任意 runId 直接 join 到 new-api 行。

→ **must-fix**：F-09 关联链路——原生 correlation 未确认；KernelPort 必须自建（token-per-session 或旁路账本）。

---

## 对 D1 v2 的浓缩映射表

| 评审痛点 | 硬事实结论 | 设计含义 |
|----------|------------|----------|
| OpenClaw stop 原子性 | abort ≠ delete；无 `sessions.stop` | 拆方法；勿写原子 stop |
| capabilities_changed | OpenClaw/Hermes 均无此事件 | 自建 revision / reconnect |
| 事件 seq 重放 | OpenClaw 明确不重放；有 history 恢复 | 契约写 refetch，不写 replay |
| run 级 cancel | OpenClaw 支持 `runId` | KernelPort interrupt 应带 runId |
| 审批 id/timeout | approval id + first-answer-wins + timeout deny | 可设计状态机；用 approval id 非空想 toolCallId |
| Hermes stop/delete | ACP 仅 cancel；delete 在 CLI sessions | 双路径适配 |
| Hermes CLI 审批可编程 | 未确认 | 生产桥走 ACP |
| newapi per-request token | 仅 user 多 token；非 per-request | token-per-session |
| newapi webhook | 未确认 | pull `/api/log/self` |
| newapi correlation | 未确认客户端可注入回查 id | 旁路账本 |

---

## 来源索引（主）

1. https://docs.openclaw.ai/gateway/protocol  
2. https://docs.openclaw.ai/gateway  
3. https://docs.openclaw.ai/gateway/clients  
4. https://docs.openclaw.ai/gateway/operator-scopes  
5. https://docs.openclaw.ai/concepts/queue  
6. https://docs.openclaw.ai/concepts/agent-loop  
7. https://docs.openclaw.ai/tools/exec-approvals  
8. https://docs.openclaw.ai/tools/exec-approvals-advanced  
9. https://docs.openclaw.ai/web/control-ui  
10. https://docs.openclaw.ai/web/webchat  
11. https://docs.openclaw.ai/tools/subagents  
12. https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals  
13. https://hermes-agent.nousresearch.com/docs/user-guide/features/acp  
14. https://hermes-agent.nousresearch.com/docs/reference/cli-commands  
15. https://hermes-agent.nousresearch.com/docs/user-guide/security  
16. https://doc.newapi.pro/en/api/fei-token-management/  
17. https://doc.newapi.pro/en/api/token-usage/  
18. https://github.com/QuantumNous/new-api-docs/blob/main/docs/en/api/fei-log.md  
19. https://docs.newapi.pro/en/docs/skills/newapi  
20. https://github.com/QuantumNous/new-api  

*调研完成时间：2026-07-21（web 公开文档；未做本地 runtime probe）。*

## Vendor output (parsed)

```
hopper-runner: idle watchdog disabled (bufferedOutput vendor) — ceiling-only timeout applies (1800000ms)
{
  "text": "I'll research OpenClaw, Hermes Agent, and new-api facts for T-005 and write findings to the required handoff output. Gathering local task context and starting targeted web searches.Writing the research deliverable with confirmed facts and sources.## T-005 完成\n\n研究结果已写入 `.hopper/handoffs/T-005-output.md`（只读调研，仅该文件）。\n\n### 核心硬事实（浓缩）\n\n| 域 | 确认 | 未能确认 |\n|----|------|----------|\n| **OpenClaw** | `sessions.create` / `sessions.abort` / `chat.abort` / `sessions.delete` / `sessions.reset`；事件有 `seq` 且**官方明文不重放**；`runId` 可取消指定 run；审批以 approval id + first-answer-wins + timeout→deny | 无 `sessions.stop`；无 `capabilities_changed` 事件；abort 与 delete 非原子 |\n| **Hermes** | ACP 动词 = new/load/resume/fork/list/**cancel**；cancel 中断当前 prompt；CLI 有 `hermes sessions delete`；ACP 审批 allow_once/session/always/deny，超时 deny | ACP 无 delete/destroy/stop；CLI TTY 审批无公开可编程协议 |\n| **new-api** | 用户可多 token（name/group/quota）；`/api/usage/token`、`/api/log/self*`、admin `/api/log/`；rpm/tpm 近 60s | 非 per-request token；无已确认结算 webhook；客户端 correlation id 回查未确认 |\n\n### Verdict\n\n**PASS** — 足以支撑 D1 v2（openclaw + hermes）重设计事实基线。\n\n### Next\n\n把已确认条款回写 facts 基线；KernelPort 勿假设 `capabilities_changed` / 事件重放 / Hermes ACP delete / newapi webhook；成本归因用 **token-per-session** + log 过滤。",
  "stopReason": "EndTurn",
  "sessionId": "019f8392-311c-7400-bf1c-2d702c7ef088",
  "requestId": "70d58ecc-eaa6-433b-88ba-a392cc4b927a",
  "thought": "The user wants me to execute a research task (T-005) as a terminal worker. I need to research OpenClaw, Hermes Agent, and new-api/newapi facts based on the specific research questions. I should:\nLet me dig deeper into OpenClaw API docs, Hermes Agent, and new-api documentation.Good findings so far on OpenClaw. Let me dig deeper into the protocol page and session methods.I have excellent OpenClaw protocol details. Let me get more specific details on:Good progress. Let me get more on:Let me get more details on new-api and OpenClaw remaining questions.Let me get more details on new-api management API for tokens and logs, and Hermes CLI sessions delete, and OpenClaw approval RPC shapes.The docs page seems incomplete (SPA). Let me try doc.newapi.pro and GitHub for new-api.Let me get more on new-api token management, logs API, and OpenClaw clients page for reconnection.Excellent - I have solid OpenClaw facts now. Let me get new-api token management and log APIs, and Hermes remaining details.Let me try browsing the new-api GitHub for API routes related to tokens and logs.Let me fetch more specific new-api docs and OpenClaw approval details.Let me fetch the new-api-docs for log and token management from GitHub raw.I have enough information to write a comprehensive research output. Let me also quickly check Hermes sessions CLI delete and whether there's mid-session capability change for Hermes ACP, and new-api t...I have comprehensive research material. Now I'll write the output file to `.hopper/handoffs/T-005-output.md`.\nThere's already a T-005-output.md with minimal content - I need to overwrite it with the full research.Now I have enough to write a comprehensive T-005-output.md. The output should follow the prd-research shape while also having the A/B/C research sections as requested.\nLet me verify the file is complete and acceptance criteria can be checked.The A/B/C headers might use different format - let me check.The deliverable is complete. I'll provide a concise final summary for the hopper dispatch return.",
  "usage": {
    "input_tokens": 163704,
    "cache_read_input_tokens": 1656576,
    "output_tokens": 10650,
    "reasoning_tokens": 2335,
    "total_tokens": 1830930
  },
  "num_turns": 19,
  "total_cost_usd": 1.1314472,
  "total_cost_usd_ticks": 11314472000,
  "modelUsage": {
    "grok-4.5-build": {
      "inputTokens": 163704,
      "outputTokens": 10650,
      "cacheReadInputTokens": 1656576,
      "modelCalls": 19,
      "costUSD": 1.1314472
    }
  }
}
```

## Status (background completion)
- queue_status: done
- adapter_status: success
- exit_code: 0
- duration_ms: 257821
- end_time: 2026-07-21T07:31:18.902Z
- log: see `T-005-output.log` for raw output
