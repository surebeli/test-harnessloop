---
task_id: T-003
adapter: grok
model: grok-4.5
status: done
task_type: prd-research
language: zh-CN
researched_at: 2026-07-18
phase: done
last_progress_at: "2026-07-18T04:10:25.288Z"
last_progress: Task completed successfully.
progress_seq: 6
terminal_event_emitted: true
end_time: "2026-07-18T04:10:25.287Z"
exit_code: 0
signal: null
timed_out: null
duration_ms: 226934
adapter_status: success
---

# T-003 — Agent 内核与网关生态实况调研（PRD 输入）

## Summary

本任务对 openclaw、hermes（任务名 hermas 的最合理对应）、new-api/newapi、Codex SDK/App Server、Claude Agent SDK 做了只读 web 调研，确认各自**真实当前形态**与**集成面**（本地进程型 vs SDK/库型），并为 P2 内核抽象窄腰（会话 start/send/interrupt/stop、流式订阅、工具协商、审批回调、能力声明）建立事实对照。结论：**openclaw / hermes 是同类「本地 Gateway + 多通道 agent 运行时」**；**Codex / Claude Agent SDK 是可嵌入的编码 agent 运行时（库/app-server）**；**new-api 是 one-api 系 LLM 网关，不是 agent 内核**。信息稀缺处已标「未能确认」，未臆造接口。

## Files touched

- `.hopper/handoffs/T-003-output.md` — 任务指定的唯一落盘产出（调研结论）

## Acceptance verification (6/6)

| # | 准则 | 证据 |
|---|------|------|
| 1 | 逐项给出确认到的事实（附来源 URL） | 见下文 §1–§5 各节「来源」 |
| 2 | 每个内核标出集成模型（本地进程 vs 托管 SDK）与关键接口 | 见 §0 总表 + 各节「集成模型」 |
| 3 | 「抽象窄腰 × 各内核落地/缺口」对照表 | 见 §6 |
| 4 | 信息稀缺处标「未能确认」 | 见各节末尾「未能确认」列表与 §7 |
| 5 | 只读研究，结论落盘本文件 | 本文件为唯一写路径；未改业务代码 |
| 6 | 语言：中文 | 全文中文 |

## Decisions / deviations

1. **「hermas」按 Hermes Agent 处理**：公开检索无独立项目名为 `hermas`；与 openclaw 同赛道、且提供 `hermes claw migrate` 的项目是 **Nous Research Hermes Agent**（`NousResearch/hermes-agent`）。若指其他同名物，需二次核对。
2. **「codex app sdk」拆成两层**：官方对外有 **Codex SDK**（TS `@openai/codex-sdk` / Python `openai-codex`）与底层 **App Server**（JSON-RPC 双向协议）；SDK 是 App Server 的友好封装。
3. **「claude code sdk」现名 Claude Agent SDK**：官方文档为 Agent SDK（`@anthropic-ai/claude-agent-sdk` / `claude-agent-sdk`），能力等同 Claude Code 的 agent loop，而非旧的「仅 CLI 包装」表述。
4. **new-api 管理面端点**：对外推理入口可确认；完整 admin REST 路径表公开文档浏览不完整，未逐条臆造，仅给可确认行为面 + one-api 系惯例。

## Open questions

1. openclaw 与 hermes 的 **Gateway WS 方法全集 / 稳定版本兼容策略** 是否有跨项目可对齐的子集（除「都是本地长驻进程 + 消息通道」外）？
2. Hermes **api_server / webhook 平台适配器** 是否对外部编排暴露完整会话生命周期 API（公开架构提到入口，具体协议细节需读源码）？
3. new-api 是否提供与 OpenAI Usage API 对等的 **机器可读计费 webhook / 实时额度推送**（公开描述偏管理后台 + 日志）？
4. Codex App Server 的 **approval 服务端请求** 在 Python/TS SDK 高层 API 上是否已稳定暴露回调（部分博客称 ApprovalMode 类型存在但用法不清晰）？
5. Claude Agent SDK 在 **进程内嵌** 时，与 hopper 侧「spawn CLI 子进程」集成模型如何统一 abort/timeout 语义？

## Verdict

**PASS**

## Next recommendation

1. 用本对照表起草 P2 **KernelPort** 最小契约：`startSession / send / interrupt / stop / subscribe(events) / resolveApproval / describeCapabilities`。
2. 适配优先级建议：**Claude Agent SDK + Codex App Server/SDK**（编码内核，接口清晰）→ **openclaw/hermes**（Gateway 适配器，WS/ACP）→ **new-api**（只做 LLM 传输/计费边车，不进 KernelPort）。
3. 对 hermes `api_server` 与 openclaw `tools.invoke`/`approval.*` 做一轮源码级接口清单（本任务 web 层已够设计，实现前再钉死字段）。

---

## §0 总览：集成模型

| 对象 | 是什么 | 集成模型 | 主要控制面 | 是否 agent 内核 |
|------|--------|----------|------------|-----------------|
| **OpenClaw** | 自托管个人 AI 助手 + 多消息通道 | **本地进程型**（Gateway 守护进程） | WebSocket JSON RPC（默认 `127.0.0.1:18789`）+ CLI | 是（通用 agent，非仅编码） |
| **Hermes Agent**（hermas） | 自改进个人 AI agent（Nous Research） | **本地进程型**（CLI / Gateway / ACP stdio） | CLI、Messaging Gateway、**ACP JSON-RPC/stdio**、Python 库入口 | 是（与 openclaw 同赛道） |
| **new-api / New API** | one-api 系统一 LLM 网关与资产/计费管理 | **HTTP 网关服务**（非 agent 内核） | OpenAI/Claude/Gemini 兼容 HTTP + 管理后台/API | **否**（模型入口与计费层） |
| **Codex SDK + App Server** | 编码 agent 程序化控制面 | **本地进程/库混合**：SDK 驱动本地 Codex runtime / app-server | TS/Python SDK；底层 JSON-RPC（thread/turn） | 是（编码专用） |
| **Claude Agent SDK** | 把 Claude Code agent loop 当库用 | **进程内 SDK**（可捆绑原生 CLI 二进制） | `query()` 异步流 + options（权限/会话/工具） | 是（编码专用） |

---

## §1 OpenClaw

### 1.1 它是什么

- **自托管个人 AI 助手**，在自有设备上常驻运行；通过 WhatsApp/Telegram/Slack/Discord/Signal 等**已有聊天通道**交互，并支持语音、Canvas、节点设备（macOS/iOS/Android）。
- **不是**「纯编码 agent SDK」产品定位；更接近 **always-on personal agent runtime**。编码/工具能力通过 tools、skills、browser、sessions 等获得。
- 核心组件是 **Gateway**：单一长驻控制面，拥有会话、通道、工具与事件。

来源：
- https://openclaw.ai/
- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai/concepts/architecture

### 1.2 最新稳定分支 / 发布通道

- 开发主线：GitHub 默认分支 **`main`**。
- 官方文档定义发布通道：
  - **stable**：带标签发布（`vYYYY.M.D` 或带 patch），npm dist-tag `latest`
  - **beta**：prerelease（`vYYYY.M.D-beta.N`），npm dist-tag `beta`
  - **dev**：`main` 移动头，npm dist-tag `dev`
- 切换：`openclaw update --channel stable|beta|dev`
- Releases 页可见 2026.7.x beta 系列标签（如 `v2026.7.2-beta.2`）；**「最新稳定」应以 npm `latest` / 文档 stable 通道为准**，不宜默认 `main` 即生产稳定。

来源：
- https://github.com/openclaw/openclaw （README「Development channels」）
- https://github.com/openclaw/openclaw/releases
- https://docs.openclaw.ai/install/development-channels （README 链接）

### 1.3 如何被外部控制或嵌入

| 路径 | 形态 | 说明 |
|------|------|------|
| **Gateway WebSocket** | 主集成面 | 控制面客户端（CLI/mac app/web UI/自动化）连 WS；默认 bind `127.0.0.1:18789` |
| **CLI** | 进程包装 | `openclaw gateway`、`openclaw agent --message ...`、`openclaw message send`、`openclaw onboard` |
| **HTTP（Gateway 同源）** | Canvas/A2UI 静态与部分宿主 | `/__openclaw__/canvas/` 等与 Gateway 同端口 |
| **stdio JSON-RPC** | 用于**出站**接外部 CLI（如 imsg），不是 openclaw 自身被嵌入的主模型 | Pattern B：line-delimited JSON-RPC over stdin/stdout |
| **Nodes** | 设备侧 WS 角色 | `role: node`，暴露 camera/canvas/screen 等命令 |

**集成模型判定**：**本地进程型内核**（长驻 Gateway + 可选 companion apps）。远程访问推荐 Tailscale/VPN 或 SSH 隧道转发 18789。

来源：
- https://docs.openclaw.ai/concepts/architecture
- https://docs.openclaw.ai/gateway/protocol
- https://docs.openclaw.ai/reference/rpc
- https://github.com/openclaw/openclaw README

### 1.4 会话 / 流式 / 工具 / 审批接口形态

**会话生命周期（WS 方法族，已文档化）**

- 握手：首帧必须 `connect`；服务端 `connect.challenge` → 客户端签名 → `hello-ok`（含 `features.methods/events`、policy、snapshot）。
- 会话：`sessions.create` / `sessions.list` / `sessions.send` / `sessions.steer`（打断并转向）/ `sessions.abort` / `sessions.reset|delete|compact` / `sessions.subscribe` 等。
- 聊天执行：`chat.send`、`chat.abort`、`chat.history`、`chat.inject`；`agent` 请求有 ack + 流式 event + final。
- 任务：`tasks.list|get|cancel`。

**流式输出**

- 服务端 push event：`{type:"event", event, payload, seq?}`。
- Agent/chat 流：`event:agent` 流式；协议 v4 chat delta 使用 `deltaText`；可订阅 `session.message` / `session.tool` / `session.operation`。
- 事件**不重放**；客户端断线后需 refresh。

**工具调用**

- 运行时工具目录：`tools.catalog`、`tools.effective`（按 session）。
- 调用：`tools.invoke`（走与 `/tools/invoke` 相同策略管线）。
- 客户端能力声明：`connect.params.caps` 如 `tool-events`、`inline-widgets`；影响工具是否对某客户端可见。
- 节点可发布 plugin/MCP 工具描述符：`node.pluginTools.update`。

**审批（human-in-the-loop）**

- 通用：`approval.get` / `approval.resolve`（scope `operator.approvals`）。
- Exec：`exec.approval.request|list|resolve|waitDecision`；策略 `exec.approvals.get|set`。
- Plugin：`plugin.approval.*`。
- 会话订阅可 `includeApprovals: true` 接收 `session.approval` 事件。
- 安全默认：main session 工具可在 host 上跑；非 main 可 sandbox；DM pairing 默认。

来源：
- https://docs.openclaw.ai/gateway/protocol
- https://docs.openclaw.ai/concepts/architecture

### 1.5 未能确认

- 每一个 `features.methods` 未列出的内部方法的完整 schema（文档明确 discovery 不是全集）。
- Plugin SDK 对外发布包的稳定 npm 契约细节（仓库有 `tsconfig.plugin-sdk.dts.json`，公开产品文档未在本调研中完整展开）。
- 生产环境「稳定」当前精确 tag 号（随时间变化，需查 npm `latest`）。

---

## §2 Hermes Agent（任务中的 hermas）

### 2.1 它是什么

- **Nous Research 的 self-improving AI agent**：内建学习环（从经验创建/改进 skills、跨会话记忆/搜索、用户建模）。
- 与 OpenClaw **同赛道**：CLI + Messaging Gateway + 多平台；并提供 **`hermes claw migrate`** 从 OpenClaw 迁移配置/记忆/skills/密钥。
- 不是「只做 coding 的 SDK 产品」；是 **个人/服务器常驻 agent**，同时具备研究轨迹生成、子 agent 并行、cron 等。
- 默认分支 **`main`**；Releases 有版本标签（调研时最新示例：`v2026.7.7.2` / Hermes Agent v0.18.2）。

来源：
- https://github.com/NousResearch/hermes-agent
- https://hermes-agent.nousresearch.com/
- https://hermes-agent.nousresearch.com/docs/developer-guide/architecture

### 2.2 集成接口形态

| 入口 | 形态 | 说明 |
|------|------|------|
| **CLI / TUI** | 本地交互进程 | `hermes`；支持 interrupt-and-redirect、流式工具输出 |
| **Messaging Gateway** | 长驻进程 | `hermes gateway`；Telegram/Discord/Slack/WhatsApp/Signal 等 |
| **ACP adapter** | **stdio JSON-RPC** | 面向 VS Code / Zed / JetBrains；`hermes acp` / `hermes-acp` |
| **Python 库 / run_agent** | 进程内调用 AIAgent | 架构图：Entry Points 含 Python Library、Batch、API Server |
| **API Server 平台适配** | gateway/platforms 之一 | 架构目录列出 `api_server`；**具体 HTTP 契约未在本调研中完整确认** |
| **MCP** | 客户端扩展能力 | 可连接 MCP server；另有 `mcp_serve.py` |

**集成模型判定**：**本地进程型内核**（与 openclaw 同类），外加 **ACP stdio** 与可选 **Python 嵌入**。

来源：
- https://hermes-agent.nousresearch.com/docs/developer-guide/architecture
- https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals
- https://github.com/NousResearch/hermes-agent README

### 2.3 会话 / 流式 / 工具 / 审批

**会话**

- 存储：SQLite + FTS5（`hermes_state.py`）；跨平台 session key。
- CLI：`/new` `/reset` `/retry` `/undo` `/compress` 等。
- ACP：`new/load/resume/fork/list/cancel session`；`SessionManager` 持有 session_id、history、cancel_event、cwd、model。
- Gateway：按平台消息 → 授权 → 解析 session → `AIAgent.run_conversation()`。

**流式 / 进度**

- CLI：streaming tool output、spinner。
- ACP：将 tool_progress / step 等 callback 桥为 ACP `session_update` 事件。
- 设计原则写明：**Interruptible**——API 与 tool 执行可中途取消。

**工具**

- 中央 registry，70+ tools / ~28 toolsets；终端 6 后端（local/docker/ssh/singularity/modal/daytona）。
- MCP 动态工具；skills 系统（agentskills.io 兼容）。
- ACP 有 tool kind 映射（patch→diff、terminal→command 等）。

**审批**

- CLI：`hermes_cli/callbacks.py`（clarify、sudo、approval）。
- 安全文档宣称 **command approval**、DM pairing、容器隔离。
- ACP：`permissions.py` 把危险终端审批映射为 ACP permission request（`allow_once`/`allow_always`/reject → Hermes once/always/deny）；超时默认 deny。

**中断**

- CLI：`Ctrl+C` 或新消息打断；消息侧 `/stop`。
- ACP：`cancel(session_id)` → cancel event + `agent.interrupt()` → `stop_reason="cancelled"`。

来源：
- https://hermes-agent.nousresearch.com/docs/developer-guide/architecture
- https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals
- https://github.com/NousResearch/hermes-agent README（CLI vs Messaging 表、Security 链接）

### 2.4 未能确认

- **公开稳定的「Hermes Kernel HTTP API」**完整 OpenAPI（api_server 细节）。
- 与 openclaw Gateway WS 是否存在协议级互通（仅有迁移工具，**不是** runtime 兼容）。
- 精确的工具审批策略配置 schema（需读 `tools/approval.py` / security 文档全文）。

---

## §3 new-api / newapi

### 3.1 它是什么

- **QuantumNous/new-api（New API）**：新一代 **LLM 网关 + AI 资产管理系统**。
- 明确是 **one-api 系二次开发/演进**：统一多厂商模型为 OpenAI / Claude / Gemini 等格式；做鉴权、渠道、路由、限流、日志、配额与计费。
- **不是 agent 内核**：不提供会话级 tool loop / 本地 workspace agent；提供的是 **统一 LLM 调用入口与用量/计费/模型管理**。

来源：
- https://github.com/QuantumNous/new-api
- https://www.newapi.ai/
- https://github.com/songquanpeng/one-api （谱系对照）
- 行业说明：https://www.cnblogs.com/rongfengliang/p/19931841

### 3.2 作为统一 LLM 入口

- 客户端把 `base_url` 指到 New API 实例，使用 **兼容 OpenAI 的调用方式**（令牌/Key + `/v1/...` 风格路径为 one-api 生态惯例）。
- 支持多格式互转（OpenAI / Claude / Gemini 等）、智能路由、负载与故障切换（产品宣传面）。
- 用户侧：令牌（额度、过期、模型限制、IP）、模型定价页、订阅等。

来源：
- https://www.newapi.ai/zh/docs/guide/feature-guide
- https://github.com/QuantumNous/new-api README（Permission / Billing 特性列表）

### 3.3 用量统计 / 计费 / 模型管理 API（已确认的能力面）

| 能力面 | 已确认事实 | 备注 |
|--------|------------|------|
| **推理入口** | OpenAI 兼容（及 Claude/Gemini 格式支持）作为统一调用面 | 与 one-api 相同使用模式 |
| **令牌/Key** | 创建/管理访问令牌；额度、模型限制；技能侧有 models/tokens/create-token 等运维命令 | https://docs.newapi.pro/en/docs/skills/newapi |
| **用量/计费** | 按请求/用量/缓存命中等核算；支持充值与企业配额场景；日志含 token/费用估算 | GitHub README「Authorized Usage Accounting and Billing」 |
| **模型管理** | 渠道模型列表、定价、上游价格同步等管理能力 | 管理 UI + 后端；精确 REST 路径见下「未能确认」 |
| **管理自动化** | 官方提及 newapi skill；`newapi-admin` skill **Coming Soon** | 说明 admin 机器接口仍在产品化中 |

**one-api 谱系下常见管理 REST 习惯（作线索，非 new-api 逐条验证）**：用户/令牌/日志/渠道等 `/api/...` 路由；**new-api 是否 100% 兼容 one-api 管理路径 = 未能确认**，实现前应以目标版本 OpenAPI 或源码 `router` 为准。

来源：
- https://github.com/QuantumNous/new-api
- https://docs.newapi.pro/en/docs/skills/newapi
- https://github.com/songquanpeng/one-api

### 3.4 集成模型判定

- **HTTP 托管网关服务**（可自建 Docker/二进制）。
- 对 P2 窄腰的角色：**LLM Transport / Metering Sidecar**，不是 KernelPort 的 agent 端。
- 适配方式：所有内核的「模型提供方」配置 `base_url` + key 指向 new-api；用量从网关日志/管理 API 拉取。

### 3.5 未能确认

- new-api **完整 admin REST 路径表**与鉴权头（公开 API 索引页未能在本轮稳定展开为可引用清单）。
- 是否提供 **WebSocket 流式管理事件**或计费 webhook。
- 与「newapi」商品名/镜像名变体是否完全同一代码线（默认按 QuantumNous/new-api）。

---

## §4 Codex App SDK / Codex SDK + App Server

### 4.1 它是什么

- **Codex**：OpenAI 的 coding agent（CLI / IDE / cloud / desktop）。
- **程序化集成两层**：
  1. **Codex SDK**（高层）：TypeScript `@openai/codex-sdk`；Python `openai-codex`（控制本地 app-server）。
  2. **App Server**（底层）：双向 **JSON-RPC 2.0**（wire 常为 JSONL），支撑 rich client（VS Code 扩展等）。

来源：
- https://learn.chatgpt.com/docs/codex-sdk
- https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md
- 协议解读：https://gist.github.com/oneryalcin/ee2c27e2d8aa040da8fbe7eebcc2ecea

### 4.2 集成模型

- **本地进程型 runtime + SDK 封装**：SDK/app-server 在用户机器上跑 Codex harness（非纯远程「无状态 HTTP agent」）。
- 认证可走 ChatGPT/Codex 订阅体系（与纯 API key Agents SDK 不同路径；细节以官方 auth 文档为准）。
- 另：OpenAI **Agents SDK** 可把 Codex 当 experimental tool 包装——那是编排层，不是 Codex 本体。

### 4.3 会话生命周期 / 流式 / 工具 / 审批

**会话（Thread / Turn / Item 三层）**

- SDK：`startThread()` / `resumeThread(id)` → `thread.run(prompt)`；同一 thread 多次 `run` 延续上下文。
- Python：`thread_start(model=..., sandbox=...)`；`Sandbox.read_only | workspace_write | full_access`。
- App Server：`thread/start` | `thread/resume`；`turn/start` 发送用户输入；可覆盖 model/cwd/sandbox/approval policy。

**流式**

- App Server 在 turn 期间推送 notification：`turn/started|completed`、`item/started|completed`、`item/agentMessage/delta`、工具进度、`thread/tokenUsage/updated` 等。
- SDK 高层示例以 `finalResponse` 为主；细粒度流式以 app-server 事件或 SDK 进阶 API 为准。

**工具**

- 内建 coding tools（shell、文件编辑、MCP、app connectors 等）由 harness 执行，不要求宿主实现 tool loop。
- 可配置 sandbox 与 approval_policy（CLI/config 层：`untrusted` 等；app-server turn 可覆盖）。

**审批（HITL）**

- 产品层：命令/沙箱外写/网络、destructive MCP 等可触发 approval。
- App Server：**服务器发起请求**做审批（双向 JSON-RPC 的关键能力）；客户端需响应 approval。
- SDK 是否把所有 approval 都暴露为稳定回调：**公开高层文档示例未完整展示 → 部分「未能确认」**（底层协议有，高层封装完整度需查 SDK 源码/版本说明）。

来源：
- https://learn.chatgpt.com/docs/codex-sdk
- https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md
- https://learn.chatgpt.com/docs/agent-approvals-security （产品审批语义）
- https://www.promptfoo.dev/docs/providers/openai-codex-app-server/

### 4.4 未能确认

- TS SDK 对 app-server 全量 notification 的类型覆盖率与版本绑定策略。
- `ApprovalMode` 在 TS 包内的官方推荐用法（第三方文章曾抱怨难找到入口）。
- Cloud Codex 与 local app-server 协议是否 100% 同构。

---

## §5 Claude Code SDK → Claude Agent SDK

### 5.1 它是什么

- 官方名称：**Claude Agent SDK**——把 **Claude Code 同款 tools + agent loop + context management** 以库形式提供。
- 包名：TS `@anthropic-ai/claude-agent-sdk`；Python `claude-agent-sdk`。
- TS 可捆绑平台原生 Claude Code 二进制（optional dependency），不必单独装 CLI；也可用 CLI headless `-p` + JSON 输出。

来源：
- https://code.claude.com/docs/en/agent-sdk/overview

### 5.2 集成模型

- **进程内 SDK（库型内核）**：agent loop 跑在宿主进程（或 SDK 拉起的捆绑 CLI 子进程——实现细节以 SDK 版本为准）。
- 对比 Claude **Managed Agents**（托管 REST）：Agent SDK 是本地/自有基础设施；Managed Agents 是 Anthropic 托管会话与沙箱。
- 鉴权：官方主推 `ANTHROPIC_API_KEY`；并支持 Bedrock/Vertex/Foundry 等环境变量切换。文档声明：**未批准时第三方产品不得用 claude.ai 登录额度包装 Agent SDK**。

### 5.3 会话 / 流式 / 工具 / 审批

**会话生命周期**

- 主 API：`query({ prompt, options })` 异步迭代消息。
- 会话：`SystemMessage` init 带 `session_id`；后续 `options.resume = session_id` 恢复；可 fork（文档 sessions 章）。
- 支持 subagents（`Agent` tool + `agents` 定义）、hooks（PreToolUse/PostToolUse/Stop/SessionStart…）、skills/plugins/CLAUDE.md 文件系统配置。

**流式**

- `async for message in query(...)` / `for await (const message of query(...))` 流式产出消息与结果。
- 可观测：消息流 + hooks；含 tool 使用与最终 `result`。

**工具**

- 内建：Read/Write/Edit/Bash/Glob/Grep/WebSearch/WebFetch/AskUserQuestion/Monitor 等；MCP servers 可配。
- **宿主不必实现 tool executor**（与 Anthropic Client SDK 的手动 tool loop 对比是核心差异）。
- `allowed_tools` / `disallowed_tools` 控制预批准与禁用。

**审批（HITL）**

- **Permission modes**：`default` / `plan` / `acceptEdits` / `bypassPermissions` / `dontAsk` / `auto` 等（文档 permissions 页）。
- **`canUseTool` / `can_use_tool` 回调**：运行时 allow/deny，可改写 input；deny 可带 message 回模型，可 interrupt。
- Hooks 与 permission pipeline 组合（PreToolUse → 规则 → mode → canUseTool）。
- 用户澄清：`AskUserQuestion` 工具。

来源：
- https://code.claude.com/docs/en/agent-sdk/overview
- https://code.claude.com/docs/en/agent-sdk/permissions
- https://code.claude.com/docs/en/agent-sdk/user-input （文档交叉引用）

### 5.4 未能确认

- SDK 内部「捆绑 CLI 子进程 vs 纯库」在当前版本的默认执行拓扑（影响 abort 信号传播）。
- 与 hopper 现有 `claude` vendor CLI 参数（`--permission-mode` 等）的字段一一映射表（需对照本机 DISPATCH 与 SDK options）。

---

## §6 抽象窄腰 × 各内核落地 / 缺口

> 建议的最小契约（P2 KernelPort）：  
> `describeCapabilities` · `startSession` · `send` · `interrupt` · `stop` · `subscribe(events)` · `listTools/negotiateTools` · `resolveApproval` · `getUsage?`

图例：**✅ 可直接落地** · **🟡 可适配但语义不齐** · **❌ 不适用/无** · **❓ 未能确认**

| 窄腰能力 | OpenClaw | Hermes | new-api | Codex SDK/App Server | Claude Agent SDK |
|----------|----------|--------|---------|----------------------|------------------|
| **集成模型** | 本地 Gateway 进程 | 本地 CLI/Gateway/ACP | HTTP 网关服务 | 本地 runtime + SDK | 进程内 SDK |
| **startSession** | ✅ `sessions.create` / connect 后 chat | ✅ CLI session / ACP `new_session` | ❌ 无 agent 会话（仅 chat completion 无状态或厂商会话） | ✅ `startThread` / `thread/start` | ✅ `query` 首次 + session_id |
| **send** | ✅ `chat.send` / `sessions.send` / `agent` | ✅ prompt / 平台消息 / ACP prompt | 🟡 `/v1/chat/completions` 等（非 agent turn） | ✅ `thread.run` / `turn/start` | ✅ 再次 `query(resume=...)` 或同流多轮 |
| **interrupt / steer** | ✅ `sessions.steer` / `sessions.abort` / `chat.abort` | ✅ Ctrl+C、`/stop`、ACP cancel + `interrupt` | ❌ | 🟡 turn 取消能力在 app-server 有相关语义；SDK 高层 ❓ | 🟡 流取消 / canUseTool interrupt；完整 abort API 需版本确认 |
| **stop / 销毁会话** | ✅ `sessions.delete` 等 | ✅ session remove / process stop | ❌（关连接即可） | 🟡 thread archive 等 app-server 能力 | 🟡 会话落在本地 JSONL；显式 destroy 语义视版本 |
| **流式订阅** | ✅ WS events（agent/chat/session.*） | ✅ CLI stream；ACP session_update | 🟡 HTTP SSE/stream tokens | ✅ item/delta notifications | ✅ async iterator messages |
| **工具协商 / 目录** | ✅ `tools.catalog` / `tools.effective` / caps | ✅ toolsets + registry；ACP tool render | ❌（模型 function call 透传，非 agent 工具面） | 🟡 harness 内建工具为主；MCP/connectors | ✅ allowed_tools + MCP + tools 清单在 init 消息 |
| **工具执行所有权** | Gateway/host/sandbox | Hermes 工具后端 | 无 | Codex harness | Claude agent loop |
| **审批回调** | ✅ `approval.*` / `exec.approval.*` + events | ✅ CLI approval + ACP permission bridge | ❌ | ✅ app-server 双向 approval 请求；SDK 封装 🟡/❓ | ✅ permissionMode + canUseTool + hooks |
| **能力声明** | ✅ connect caps/scopes/role；hello-ok features | 🟡 ACP initialize 能力；CLI 无统一 machine caps 文档 | 🟡 `/v1/models` 模型列表 | 🟡 initialize/experimentalApi capability（app-server） | 🟡 init 消息含 tools/model；无统一 caps 枚举 |
| **用量/计费** | 🟡 `usage.*` / `sessions.usage`（运行时用量） | 🟡 `/usage` 类命令 | ✅ 核心职责（配额/日志/定价） | 🟡 token usage events | 🟡 消息级 usage/cost 字段（SDK 支持追踪） |
| **统一抽象贴合度** | 高（显式控制面） | 高（ACP 最接近可嵌入协议） | **应排除在 KernelPort 外** | 高（Thread/Turn 清晰） | 高（query 流 + 权限回调清晰） |

### 6.1 对齐结论（设计含义）

1. **两类内核，一种窄腰，两套 Transport**  
   - **Daemon/Gateway 型**（openclaw、hermes）：长连接 + 显式 session id + 服务端 push。  
   - **Library 型**（Claude Agent SDK、Codex SDK）：宿主进程驱动；事件来自 async stream / JSON-RPC child。  
   - 窄腰应 **只描述语义**，Transport 插件化（`WsGatewayTransport` / `StdioJsonRpcTransport` / `InProcessSdkTransport`）。

2. **new-api 不应实现 KernelPort**  
   - 应作为 **ModelProvider / BillingMeter** 接口：`chat/completions`、模型列表、令牌与日志查询。  
   - 与内核抽象正交；所有内核可共享同一 new-api base_url。

3. **审批是最大语义裂缝**  
   - openclaw：独立 approval registry + scopes。  
   - hermes：命令审批 + ACP permission。  
   - codex：policy + server-originated approval requests。  
   - claude：permission modes + canUseTool 回调。  
   - 窄腰建议统一为：`ApprovalRequest{id, kind, payload}` → `resolve(id, decision)`，kind 枚举可扩展（exec / tool / mcp / sandbox）。

4. **interrupt 语义不齐**  
   - openclaw `steer`（打断并注入）vs abort（停）vs claude/hermes cancel。  
   - 窄腰宜拆：`interrupt(mode: abort|steer, text?)`。

5. **能力声明**  
   - 仅 openclaw 的 connect `caps/scopes` 与 app-server experimental capability 较机器化。  
   - 抽象层应 **主动探测** + 静态 manifest，而不是假设所有内核支持 steer/approval/mcp。

---

## §7 信息稀缺汇总（诚实清单）

| 项 | 状态 |
|----|------|
| 名为「hermas」的独立项目 | 未找到；按 Hermes Agent 处理 |
| new-api 全量 admin REST 路径与鉴权 | 未能确认（仅确认能力面与 OpenAI 兼容入口） |
| Hermes api_server 对外 HTTP 会话 API | 未能确认完整契约 |
| Codex TS SDK 对 approval 回调的稳定高层 API | 未能完全确认 |
| OpenClaw 当前 npm `latest` 精确版本号 | 动态；未锁定 |
| 两家个人 agent（openclaw/hermes）运行时协议互通 | 不存在；仅有迁移工具 |

---

## §8 对 P2 窄腰的最小建议契约（PRD 输入草稿）

```text
KernelPort
  describeCapabilities() -> {
    model: "daemon-gateway" | "library-sdk" | "cli-subprocess",
    supports: { steer, abort, approvals, toolCatalog, mcp, sessionResume, usageEvents }
  }
  startSession(opts: { cwd, model, sandbox?, permissionProfile? }) -> SessionId
  send(session, message, opts?: { queueMode? }) -> RunId
  interrupt(session, { mode: "abort"|"steer", text? })
  stop(session)
  subscribe(session, onEvent: (KernelEvent) => void) -> Unsubscribe
  // KernelEvent: text-delta | tool-start|tool-end | approval-needed | usage | run-finished | error
  resolveApproval(approvalId, decision: "allow-once"|"allow-always"|"deny", note?)
  getToolCatalog?(session) -> ToolDescriptor[]
```

**映射优先级（实现顺序）**

1. Claude Agent SDK（库事件 → KernelEvent；canUseTool → approval）  
2. Codex App Server/SDK（thread/turn → session/run；notifications → stream）  
3. OpenClaw WS（sessions/chat/approval 方法族）  
4. Hermes ACP stdio（最接近标准 agent 协议）或 CLI/PTY 降级  
5. new-api → `ModelRouter` / `UsageLedger`，不进 KernelPort  

---

## 主要来源索引

| 主题 | URL |
|------|-----|
| OpenClaw 官网 | https://openclaw.ai/ |
| OpenClaw GitHub | https://github.com/openclaw/openclaw |
| OpenClaw 架构 | https://docs.openclaw.ai/concepts/architecture |
| OpenClaw Gateway 协议 | https://docs.openclaw.ai/gateway/protocol |
| Hermes GitHub | https://github.com/NousResearch/hermes-agent |
| Hermes 架构 | https://hermes-agent.nousresearch.com/docs/developer-guide/architecture |
| Hermes ACP | https://hermes-agent.nousresearch.com/docs/developer-guide/acp-internals |
| new-api GitHub | https://github.com/QuantumNous/new-api |
| New API 功能指南 | https://www.newapi.ai/zh/docs/guide/feature-guide |
| one-api | https://github.com/songquanpeng/one-api |
| Codex SDK | https://learn.chatgpt.com/docs/codex-sdk |
| Codex App Server README | https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md |
| Claude Agent SDK Overview | https://code.claude.com/docs/en/agent-sdk/overview |
| Claude Agent SDK Permissions | https://code.claude.com/docs/en/agent-sdk/permissions |

## Vendor output (parsed)

```
Couldn't set model 'grok-build': Invalid params: "unknown model id". Run 'grok models' to see available models.
```

## Status (background completion)
- queue_status: done
- adapter_status: success
- exit_code: 0
- duration_ms: 226934
- end_time: 2026-07-18T04:10:25.287Z
- log: see `T-003-output.log` for raw output
