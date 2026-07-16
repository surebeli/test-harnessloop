# hopper-plugin 能力图谱

- **插件**：hopper-plugin @ `eceee81`（v0.30.0）
- **图谱生成日期**：2026-07-16
- **来源**：3 路并行深读（并非 3 次独立单读，而是同一批读取任务的 3 个视角）
  - Area A — README/AGENTS.md/架构文档等整体架构精读
  - Area B — `skills/` 全部 10 个 SKILL + `commands/` 全部 12 个 slash 命令定义逐个精读
  - Area C — 根目录全部 ISSUE-*.md 账本 + `cli/`/`hosts/`/`monitors/` 结构 + 测试命令预读
- **性质**：使用前快照（pre-use snapshot），不是使用后的验证结论——见文末说明

## 定位

hopper-plugin 是一个 **vendor 中立的任务后台分发层**：基于 `llm-hopper` 文件协议（一切状态是 `.hopper/` 目录下的 markdown + JSONL，可 grep、可 git、可审计，无隐藏数据库），把任务从 `.hopper/queue.md` 单次派发给第三方 agent CLI（codex / kimi / opencode / copilot / grok / mimo / claude / agy），全程无自动重试、无自动回退、无软编排。它是 test-harnessloop 项目里继 harnessloop 之后**第二个被"边用边验证"方法论覆盖的插件**——本图谱是正式使用前的能力盘点，实战中的真实行为以 `docs/validation-log.md` 的实测记录为准。

---

## 边用边验证观察点（严重度排序，前置）

以下汇总三路读取各自的 `validation_watchpoints`，按"未修高危 → 状态存疑待实测 → 已修待复发观察 → 操作纪律类"排序。每条注明出处（ISSUE 文件名或审计记录名，原始数据里给出的都保留）。

### A. 未修 · 高危（真实派发前先假设这些成立）

1. **codex 跨仓审查不可靠，可能虚假报告成功** — `ISSUE-codex-review-hijack.md`（高严重度，3+ 次复现，待修）。codex 全局 gstack/superpowers skill 会劫持任务语义、workdir 锚在 hopper 项目根导致 `git diff` 审错仓、产物写到 `.triage/` 而非 brief 指定路径，但 `adapter_status` 仍报 success。**跨仓 review 必须核对实际审查对象和产物落点，别信 exit 0。**
2. **monitor 跨会话串扰** — `ISSUE-monitor-cross-session-crosstalk.md`（open）。`monitors.json` 是项目级注册，`output.md` 的 `session_id` 恒为 `null` 无法过滤；代码复核确认 `cli/src/background.js:494-497` 仍写 `session_id: null`，`runWatchEvents` 无任何按会话过滤逻辑——同目录第二个 Claude 会话会收到别的会话的 terminal event。只有"启动时回放历史事件"这半（据 `handoff-archival.md`）已 baseline 修复，**按会话过滤仍缺**。验证法：双会话同目录，A 派发 B 观察，收到别人的完成通知即该缺陷复现，不要误判为自己的任务完成。
3. **queue.md 终态后状态不一致** — 关联 `ISSUE-codex-callchain-windows.md`（bypass-flag issue）的次生发现，作者明确"另行跟踪"、未见独立修复记录。permission-fail 等终态后 `queue.md` 行可能仍留 `pending`，而 `--jobs`/`--watch` 已报 `failed`。**以 output.md frontmatter / `--jobs` 为准，queue 行状态仅在用户手动更新后可信。**
4. **codex 假成功检测覆盖不全** — 关联 `ISSUE-codex-review-hijack.md` 与 `ISSUE-codex-callchain-windows.md`。`parseResult` 只识别 Windows `CreateProcessWithLogonW` 1326 这一种模式；不含 1326 的劫持/离题运行仍可能报 `done`/`exit0`（作者建议的"校验声明输出路径已写入"未实现）。**每次 codex 派发后必须自查 brief 要求的产物文件是否真实存在且在正确路径。**
5. **ad-hoc 派发散落文件** — 见 `ISSUE-grok-claude-buffered-output-idle-falsekill.md` 附带发现 a（仅记录未修）。`--adhoc` 的通用 frame 会诱导有文件写权限的 vendor（如 kimi）在项目根写一个字面 `output.md`。**跑 `prd-research`/`market-research` 类 ad-hoc 后检查仓库根有无 stray output.md。**
6. **mimo 长任务硬超时** — `ISSUE-mimo-codeimpl-timeout.md`。`code-impl` 硬编码 180s 基线且无 env 覆盖，几十处机械编辑类任务必超时。**该场景改派 grok/deepseek。**
7. **kimi 静默失败前科** — `T-AUDIT-PH5-kimi` 审计记录（非独立 ISSUE 文件）。曾出现 0 字节 log + 180s SIGTERM 无任何输出；`kimi-thinking` 别名需要用户先在 `~/.kimi/config.toml` 配 `[models.kimi-thinking]`，否则仍失败（soft-warn 会打印 TOML 片段）；kimi 无 per-call effort flag。
8. **agy 子代理谎报审查完成** — `T-AUDIT-PH6C-agy` 审计记录（非独立 ISSUE 文件）。历史上发生过 copilot 子代理谎报 agy 完成审查、污染 queue 行。**vendor 自述完成不可信，以 output.md frontmatter `adapter_status` 为 ground truth。**

### B. 状态存疑 · 文档/任务追踪与代码复核不一致（先实测再下结论）

1. **`--watch-events --once` 是否真的会挂死，两路信号矛盾**：Area A/来源判定为"未 bounded exit，只有观察到 terminal event 才 `cleanup(0)`，工作区里没有任务到终态就永远挂"（`ISSUE-progress-watch-hang.md` 标 `open`，对应修复任务 `T-FIX-PWHANG` 仍 pending；同一 ISSUE 提到 `tests/unit/progress-watch.test.js` 泄漏 handle 挂死整个 `npm test`）。但 Area C 的代码复核给出相反结论："`--once` 有界退出默认 30min（`HOPPER_WATCH_ONCE_TIMEOUT_MS` 可调），`hopper-dispatch:1183-1313` 已实现"，判定该 ISSUE 状态行已过期、实为已修。**两个来源直接矛盾，不要预设任何一方为真——真实使用 `--watch-events --once` 前必须亲自验证一次有界退出是否成立，并留意跑测试套件时是否仍需排除该文件。**
2. **ISSUE 账本本身的可信度问题**：根目录实际只有 9 个 ISSUE 文件（并非某处引用的 10 个），其中至少 2 个（`monitor-crosstalk`、`progress-watch-hang`）的 `Status` 行被判定为"过期"——即文件写的状态和代码实际行为对不上。**"是否已修"要对照代码，不能只读 ISSUE 文件的 Status 字段。**

### C. 已修 · 需观察复发

1. **grok/claude 端缓冲输出被 idle 看门狗误杀** — `ISSUE-grok-claude-buffered-output-idle-falsekill.md` 已标 **FIXED**。原因：grok/claude 因 `--output-format json` 端缓冲，idle 看门狗在 ~idleMs 处无条件杀；已用 `bufferedOutput:true` 禁用 idle 检测、只留绝对 ceiling。**复发特征易识别**：`adapter_status: timeout`、kill 时刻 ≈ idleMs + 一次 5s poll tick（作者实测 +5053ms/+5213ms）、raw log 0 字节。任何新 vendor 或 vendor 换输出格式导致尾部一次性输出，都会原样复发。代价：真挂死的 grok/claude 现在要熬满 ≥30min ceiling 才被收割，**等结果时不要提前判死**。
2. **Windows codex sandbox bypass flag 曾整体丢失** — argv 里没有 `-s`/`--dangerously-bypass-approvals-and-sandbox`，0.14.0 commit `a0c4eff` 已修复。验证时仍应看 banner 的 sandbox 模式是否符合预期；`HOPPER_VENDOR_CWD` 指向非 git 父目录会触发 codex "not inside a trusted directory" 拒绝。
3. **monitor 启动历史事件回放刷屏** — 据 `handoff-archival.md`，`--watch-events` 启动只记 seq（baseline-prime）不发通知，防止历史事件回放刷屏，已修复。**注意这只解决了"回放"问题，不解决"跨会话过滤"（见 A2）。**

### D. 操作纪律类观察点（非缺陷，但每次验证都要盯）

- `--model` 与 `--reasoning` 是两个独立旋钮，绝不能拼接（`gpt-5.5-xhigh` 会被 vendor 当未知模型拒绝）；`--reasoning` 默认 `xhigh`，grok/copilot 会钳到 `high`，mimo `xhigh`→`--variant max`，kimi/claude/agy 无 effort flag 静默忽略；codex ChatGPT 账户只收裸模型名，provider 前缀被拒。
- **sandbox 真实性分层**：只有 `Sandbox=argv` 的 vendor（codex 等）read-only 是 flag 强制的；kimi 是 `native`、不可 argv 降级——给 kimi 派 review 时 read-only 不被保证，验证时检查它有没有写文件；mimo read-only 走 `--agent plan` 是另一套机制。`--sandbox` 对 native 类 vendor 完全不生效，但派发头仍会打印请求值（作者自认未修）。
- **`--result` 退出码语义**：0=done、1=failed/orphaned、2=in-progress——脚本化验证按此断言；存在 `orphaned` 终态（进程失联），验证后台任务异常退出时 frontmatter 是否正确翻转。
- **codex/copilot 的最终结论常写在 `.log` 尾部而非 `output.md` 正文**——body 为空不等于失败，先看 LOG TAIL 段；结果正文有预览截断（后台约 8000/同步约 4096 字符），review/research/market 结果必须 `--full` 或读 `<id>-output-raw.txt` 才是全文。
- **web search 实际只有 codex 高置信验证过**（headless 可用，research.md/market.md 明说）；`--setup` 表里 claude/grok/kimi 也标 `WebSrch=yes` 但未 smoke 验证——非 codex vendor 接 research/market 任务时验证输出里是否真有带引用的检索结果。
- `--setup --deep` 的 DRIFT 是 advisory：活模型目录可能与账户实际可用不一致，`driftExpected` 名单被抑制——DRIFT 行提示去 review adapter 的 knownGood，不要当成错误；`--deep` 是 setup 里唯一会 spawn 子进程的模式。
- **轮询纪律**：间隔 ≥10s（更快浪费 Bash 预算）；`--watch` 会阻塞最长 30min，绝不在 slash 命令回合内自动 watch；>1min 的任务用同步模式会冻住会话——kimi thinking / codex xhigh / 长推理任务一律 `--background`。
- 模型缓存约 14 天标 `[STALE]`；copilot 模型数为 0 是正常（server-side per-tier）不是探测失败；kimi 0.14+ 与旧版走不同 introspection 路径（`provider list --json` vs 读 `config.toml`）——probe 结果异常时先确认 kimi 版本。
- **逃生门环境变量污染**：派发前确认 shell 环境没有残留 `HOPPER_CODEX_SANDBOX_BYPASS=0` / `HOPPER_CODEX_KEEP_ORCHESTRATION=1` / `HOPPER_COPILOT_EFFORT` / `HOPPER_OPENCODE_VARIANT` / `HOPPER_IDLE_TIMEOUT_MS`——它们会静默改变派发行为，且不体现在命令行上。
- **双副本漂移**：改动 `cli/` 后必须 `npm run sync:plugin`，否则 `plugins/hopper` 下 vendored 副本漂移（`vendored-plugin-sync.test.js` 会抓）；历史上"bin 加载旧副本"曾是 bypass-flag 缺陷的候选根因。
- **测试基线数字本身在不同来源间就不一致**：README 徽章称 626 tests / 0 fail；`ISSUE-progress-watch-hang.md` 实测口径是排除 `progress-watch` 后 616 tests / 590 pass / 26 skipped；Area C 另一处审计记录又称 `npm test` 应 ~806 用例全绿、`tests/integration/*.test.js` 应 33 通过。**三个数字互不相同，全绿声明与已知挂死文件也存在矛盾，复核时以本机实跑为准**；已知 flake：`runner-single-spawn.test.js` 的"appends exactly one timeout terminal progress event"硬编码 500ms 预算，高负载机上约 1/7 概率误挂，非回归信号。

---

## 按 Area 分节详情

> 三个 Area 的原始读取视角不同（架构 / 技能命令 / ISSUE 与代码），内容有重叠但各有侧重，为保证技术细节完整不做跨 Area 删减；`validation_watchpoints` 已抽取到上一节，此处不再重复列出。

### Area A — 整体架构（vendor 中立文件协议分发层）

> 原始定位：基于 llm-hopper 文件协议的 vendor 中立后台分发层 —— 把任务从 `.hopper/queue.md` 单次派发给第三方 agent CLI（codex/kimi/opencode/copilot/grok/mimo/claude/agy），全部状态落盘 `.hopper/` markdown+JSONL，无隐藏数据库、无自动重试/回退

**capabilities**

- 文件协议 `.hopper/` 目录：`queue.md`（v2 schema 任务表，列 ID/Task-type/Status/Depends/Priority/Brief/可选 Vendor；Status ∈ pending/in-progress/done/failed/removed）+ `AGENTS.md`（nickname→vendor 绑定表 + task-type→vendor 默认偏好表）+ `tasks/<task-type>.md`（6 种任务框架 frame）+ `handoffs/`（产物）+ `COST-LOG.md`/`MANIFEST.md`/`PING.md`
- dispatch 生命周期：读 queue.md 校验（pending + deps done）→ resolveVendor 四步确定性路由（queue 行 Vendor 列 override → task-vendor-preference 表 → agent 偏好 → throw）→ 加载 `.hopper/tasks/<task-type>.md` frame → 组合 prompt（可叠加 GOVERNANCE.md 宪法 overlay）→ 单次 spawn vendor CLI（不 retry 不 fallback，spec §3#4）→ parseResult 分类 success/auth-fail/timeout/permission-fail/unknown-fail → `--write` 时写 output.md 并打印"建议的" queue/COST-LOG 编辑（不自动应用，用户确认才改）
- 后台模式（`--background`）：dispatcher <100ms 返回 runner PID，hopper-runner detached 运行；每次 dispatch 落 5 文件产物集 `.hopper/handoffs/<id>-output.md`（frontmatter: status/phase/last_progress/progress_seq/terminal_event_emitted）、`-output.log`（raw stdout/stderr）、`-output-raw.txt`（完整 vendor 回答）、`-progress.log`（JSONL 生命周期事件，seq 单调）、`-prompt.md`（组合后的 prompt）
- 两平面进度架构：Progress plane（coarse phase 全 vendor 通用 queued/starting/running/done/failed/timeout/cancelled/orphaned；fine phase investigating/editing/verifying/finalizing 仅 codex+app-server）；Notification plane（进入终态时恰好一条 terminal event，frontmatter `terminal_event_emitted` 去重，writer 幂等）
- 观察命令：`--progress <id>`（快照：phase/elapsed/最近5条事件）、`--watch <id>`（阻塞到终态，带 exit code 适合 CI）、`--watch-events [--once]`（stdout JSONL 流 hopper.task.terminal 事件 + OS toast）、`--result <id> [--full]`（verdict + log tail，自动回落 archive）
- Claude Code 原生 wake：`monitors/monitors.json`（插件根目录，非 `.claude-plugin/` 下）自动跑 `--watch-events`，terminal event 作为 Monitor 事件唤醒会话；其它 host（codex CLI/opencode/standalone）无原生 wake，靠 OS toast 或手动 pull
- vendor 适配器模型：每个 adapter ~55-115 行，声明 model/effort/sandbox 的 argv 映射与能力（modelArg.accepted、streaming、idleHeartbeatRe（mimo 心跳）、bufferedOutput:true（grok/claude 端缓冲输出，禁用 idle watchdog 只留绝对 ceiling））；`--model` 与 `--reasoning` 是两个独立旋钮；`--model` 值做 V4 vendor 域规范化（GPT-5.5→gpt-5.5 等），brief 正文里的模型名从不改写
- sandbox 控制：默认 danger-full-access；review/research task-type（code-review-*、prd-research、market-research）或 brief/spec 出现 'read-only'/'只读' 时自动降级 read-only；`--sandbox` 显式覆盖；各 vendor 映射不同（codex `-s` / Windows 上 danger 用 `--dangerously-bypass-approvals-and-sandbox`；opencode/agy → `--dangerously-skip-permissions`；copilot → `--allow-all-tools --allow-all-paths`；grok → `--always-approve`；mimo → `--agent build/plan`；kimi 不转发）
- host 适配：7 条 host 路由（Claude Code slash、hopper-codex、hopper-opencode、copilot CLI、Grok Build、Cursor CLI、standalone）汇聚同一 hopper-dispatch，强制 host != vendor（host 会话不能派回同一 vendor 身份）
- 零 spawn 预检（`--dry-run` 工作流）：`--resolve <id>`（能否解析：queue 行 + vendor + prompt 长度）、`--check <vendor>`（本机安装+认证）、`--status`（队列汇总+确认项目根）、`--capabilities <vendor>`（静态 model/effort/perms 契约）、`--models`（读缓存）、`--rules`（生成式全 vendor 矩阵，写入 `.hopper/DISPATCH.md`）；`--probe` 是唯一会 spawn vendor 的发现命令
- 运维：`--jobs` 列后台任务、`--reap` 把 stale/死 PID 任务幂等标为 orphaned 并补一条 terminal event、`--stop <id>` 杀进程树标 cancelled、`--archive [--older-than N|--keep N|--only-status s|--dry-run]` 把终态任务 5 文件集移到 `.hopper/archive/<date>/`（永不动 pending/in-progress/活 PID；queue.md 不动）、`--init-tasks` 脚手架新项目 `.hopper/`
- 治理 overlay（opt-in）：`--init-governance --from <constitution.md>` 写 `.hopper/GOVERNANCE.md` + 盖章副本，之后每次 dispatch 在 prompt 前拼宪法+per-vendor overlay；queue.md 加 Govern 列=off 可按任务关闭；纯 prompt 层，不改 sandbox/timeout/路由/单 spawn 保证
- dashboard：`127.0.0.1:7777` 只读消费同一 `.hopper/` 状态（chokidar+SSE），probe 按钮是唯一写路径且有 vendor 白名单
- 环境变量调参：`HOPPER_DEFAULT_REASONING`（全局 effort 默认，否则 xhigh）、`HOPPER_DEFAULT_SANDBOX`、`HOPPER_IDLE_TIMEOUT_MS`（后台 idle 看门狗）、`HOPPER_VENDOR_CWD`（拓宽 vendor 工作目录到共同祖先）、`HOPPER_DIR`（指定 .hopper 路径）、`HOPPER_COPILOT_EFFORT`/`HOPPER_GROK_EFFORT`/`HOPPER_OPENCODE_VARIANT`（raw effort 逃生口）、`HOPPER_ENABLE_AGY=1`（解禁 agy）、`HOPPER_NOTIFY=0`（关 OS toast）

**usage_entrypoints**

- Claude Code 斜杠/skill：`/hopper:dispatch <task-id> [--background] [--write] [--model <name>] [--reasoning minimal|low|medium|high|xhigh] [--sandbox <mode>] [--vendor <name>] [--web-search]` —— 一次 slash 只派一个任务；后台必须用 `Bash run_in_background=true` 调 `node "$CLAUDE_PLUGIN_ROOT/cli/bin/hopper-dispatch" <id> --background`
- 预检三连（真实派发前先跑，全部零 spawn 只读）：`hopper-dispatch --resolve <id>`；`hopper-dispatch --check <vendor>`；`hopper-dispatch --status`
- 结果链路：`/hopper:status`（队列计数）→ `hopper-dispatch --progress <id>`（进行中快照，或 `head -20 .hopper/handoffs/<id>-output.md` 看 status 行）→ `/hopper:result <id>`（`--full` 取全文）；轮询间隔 ≥10s
- ad-hoc 免 queue 行入口：`/hopper:review`（只读 code review diff/path/PR）、`/hopper:research`、`/hopper:market`（web-search 自动开）、`/hopper:swarm`（多 vendor 面板扇出+综合，扇出是显式逐任务的，hopper 本体不自动 fan-out）
- vendor 就绪与模型：`/hopper:setup`（= `hopper-dispatch --setup/--doctor`，`--deep` 查漂移）、`/hopper:probe <vendor>`（刷新缓存，会 spawn）、`/hopper:models`（只读缓存）、`/hopper:vendors`、`/hopper:smoke`；权威矩阵 `hopper-dispatch --rules` 或 `--capabilities <vendor>`
- CLI 直连（standalone/脚本）：`hopper-dispatch <id> --background`；`--watch <id>`（CI 阻塞+exit code）；`--watch-events --once`（拿一条 terminal event 就退——但见 watchpoint 挂死风险）；`--jobs` / `--reap`（清孤儿）；`--stop <id>`；`--archive --older-than 7 --dry-run` 先预览
- 运行位置：在含 `.hopper/` 的项目根运行，或 `export HOPPER_DIR=/path/to/project/.hopper`；vendor 子进程锚定拥有 `.hopper/` 的 repo root，与 shell CWD 无关，永远不需要 cd 进插件目录
- `$CLAUDE_PLUGIN_ROOT` 可能 unset 或错值（实测曾=`/`）：用 `commands/dispatch.md` Mode C 的 resolver——先验证 `$CLAUDE_PLUGIN_ROOT/cli/bin/hopper-dispatch` 存在，否则回落 `~/.claude/plugins/hopper{,-plugin}/cli/bin/hopper-dispatch`
- 任务 ID 校验后再上 shell：`^[A-Za-z][A-Za-z0-9._-]{0,99}$`，拒绝 `/`、`\`、`..`、shell 元字符；flags 白名单校验，不 splat `$ARGUMENTS`

**key_concepts**

- llm-hopper 文件协议：一切状态是 `.hopper/` 下的 markdown + JSONL，可 grep、可 git、可审计；无 reaction core、无自动编排
- queue.md v2 schema：Task-type 列驱动路由（取代 v1 的 Role）；activity log 尾部追加派发/完成记录
- handoffs 5 文件产物集：`<id>-output.md`（frontmatter 是权威状态）/`-output.log`/`-output-raw.txt`/`-progress.log`/`-prompt.md`；`terminal_event_emitted` 是 exactly-once 去重旗标
- vendor 路由确定性四步解析：queue 行 Vendor override → task-vendor-preference → agent 偏好 → throw；vendor 来自 `.hopper/AGENTS.md` 而非 host、也不由 `--model` 决定
- 单 spawn 不变量：一次 dispatch 恰好 spawn 一次 vendor，无 retry 无 fallback 无软编排（失败只 surface，用户明确要求才诊断）
- host ≠ vendor 强制：host 会话不能派回自身 vendor 身份；wrapper 完成 ≠ vendor job 完成，runner terminal state 才是权威
- Progress plane / Notification plane 分层：同源 `.hopper/handoffs` 文件；coarse phase 通用，fine phase 仅 codex app-server 能力门控
- adapter-declared hooks：适配器自声明行为特征（mimo idleHeartbeatRe、grok/claude bufferedOutput），runner 按声明调整看门狗——扩展 vendor 时的既定模式
- 零 spawn 预检 vs `--probe`：resolve/check/status/capabilities/models/rules 全只读；probe 是唯一显式 spawn 发现面
- sandbox 自动降级：review/research task-type 或 brief 含 read-only/只读 → read-only；默认 danger-full-access
- governance overlay：prompt 级宪法注入，不动运行时语义
- archival：显式 `--archive` 把终态产物移 `.hopper/archive/<date>/`，queue.md 作为历史台账永不动，`--result` 自动回落

**gotchas**

- `--model` 和 `--reasoning` 是两个旋钮，拼在一起（`gpt-5.5-xhigh`）会被 vendor 当未知模型拒绝；`--reasoning` 默认 xhigh，grok/copilot 会 clamp 到 high，mimo xhigh→`--variant max`，kimi/claude 无 effort flag 静默忽略
- 后台派发在 Claude Code 里必须 `Bash run_in_background=true`，否则冻结会话；dispatcher 返回的是 runner PID，不代表 vendor 完成
- `monitors/monitors.json` 在插件仓库根（commands/、cli/ 的同级），不在 `.claude-plugin/` 下；`.claude-plugin/plugin.json` 仅元数据——symlink 安装时路径解析依赖这一点
- vendor 要读仓外路径时：`HOPPER_VENDOR_CWD` 拓宽到共同祖先（注意会破坏 codex 的 git trust 检查）、或在 vendor 侧配 permission（opencode external_directory）、或最简单把证据复制进仓
- copilot 每次调用消耗 premium quota——省着用；opencode 建议 pin 0.14.7（已知回归 #3213）
- dashboard 是只读消费者，永远绑 `127.0.0.1`；别把它当写入口
- queue.md 的 push 权限归 Leader、任务标 done 归用户——agent 侧只建议不落笔
- 跑插件自身测试套件时必须 bound（套件会挂）：`node --test` 加 `--test-timeout` 并排除 `progress-watch.test.js`
- `--archive` 任何时刻可安全跑（不动 pending/in-progress/活 PID），但先 `--dry-run` 预览；归档后 `--result` 仍可取
- `.hopper/` 在插件仓库里是活的 dogfood 状态（真实队列+handoffs），不是文档样例——参考其格式但别把它当模板直接改

---

### Area B — Claude Code 集成面（10 个 SKILL + 12 个 slash 命令）

> 原始定位：Claude Code → 第三方 vendor agent CLI 的文件协议分发器；`hopper-plugin/` 下 10 个 SKILL（`skills/hopper*/SKILL.md`）+ 12 个 slash 命令（`commands/*.md`）

**capabilities**

- 队列分发（`/hopper:dispatch`，`skills/hopper-dispatch`）：从 `.hopper/queue.md` 取一个 pending 且依赖已 done 的任务，按 `.hopper/AGENTS.md` 路由 vendor（优先级：queue.md 行内 override > task-vendor-preference 表 > taskType 默认 > Active Agent Instances 表），加载 `.hopper/tasks/<task-type>.md` 任务框架，单次 spawn vendor 子进程（严格 single-spawn：不重试、不 fallback、不换 vendor），结果分类为 success/auth-fail/timeout/permission-fail/unknown-fail
- 后台分发（`--background`，spec §14）：dispatcher <100ms 返回 PID，vendor 进程 detached 运行，结果写 `.hopper/handoffs/<task-id>-output.md`（frontmatter status: in-progress→done/failed/orphaned）+ 同名 `.log`；宿主侧必须用 `Bash run_in_background:true` 调用避免冻结会话；`--stop <task-id>` 杀进程树并标记 cancelled
- 进度监控（`skills/hopper-progress`，无独立 slash 命令）：`--progress <id>` 快照、`--watch <id>` 阻塞跟踪至终态（最长 30min，勿在 slash 命令内自动 watch）、`--watch-events` 跨任务事件流（`--once` 用于脚本）；也可直接 `head -20 output.md` 读 frontmatter status 行
- 结果取回（`/hopper:result`）：`--result <id>` 打印 frontmatter 摘要（vendor/status/duration/exit code）+ output.md 正文 + log 尾部约 4000 字节（codex/copilot 的最终结论常在 log tail 而非 output.md）；正文是预览（后台约 8000 字符/同步约 4096 字符截断），完整文本在 `<task-id>-output-raw.txt`，加 `--full` 输出全文（research/market 默认应加 `--full`）；退出码：0=done、1=failed/orphaned、2=in-progress；`HOPPER_OUTPUT_PREVIEW_MAX` 可全局调预览上限
- 能力探测（`/hopper:probe`）：唯一会 spawn vendor CLI 的发现面（全量约 11 个子进程：codex 2 + kimi 2 + opencode 3 + copilot 1 + mimo 3；agy/grok 零 spawn），原子写机器级缓存 `~/.hopper/cache/vendor-capabilities.json`；常规 dispatch/`--check`/`--capabilities` 均零 spawn
- 模型清单（`/hopper:models`）：只读缓存，不 spawn；introspection 级别 full(codex/opencode/mimo)/partial(kimi 0.14+ `provider list --json`、copilot)/config-only(kimi fallback 读 `~/.kimi-code/config.toml`)/none(agy/grok 静态)；超约 14 天标 `[STALE]`，提示用 probe 刷新；可完全省略 `--model` 用账户默认
- vendor 注册表（`/hopper:vendors`）：8 个 adapter — codex、kimi、opencode、copilot、agy、grok、mimo、claude；agy 默认 DISABLED（1.0.12 `--print` 仅 TUI 输出，`HOPPER_ENABLE_AGY=1` 强开）；claude vendor spawn `claude -p`，host≠vendor 规则禁止 Claude Code 宿主派给它（仅供其他宿主用）；vendor 名归一化去掉尾部 `-cli`/`_cli`
- 就绪诊断（`/hopper:setup`，别名 `--doctor`）：每 vendor 一行 Installed/Auth/Sandbox(argv=可用 flag 强制 read-only，native=不可 argv 降级如 kimi)/WebSrch(yes: codex,claude,grok,kimi；manual: copilot,mimo；no: opencode,agy)/Models 缓存数/Caps stale 日期；`--deep` 额外做 flag 漂移检查（vendor `--help` vs adapter 发出的 flag）+ 活模型目录 vs 硬编码 knownGood 的 DRIFT 对比（advisory，driftExpected 名单被抑制）；只读不自动安装/认证
- 冒烟（`/hopper:smoke`）：跑 `hopper-dispatch --smoke`，期望横幅 `hopper standalone (CLI v0.30.0)` + exit 0；验证 T-PLUGIN-00 Prong 1 插件宿主生命周期，不碰 `.hopper/`
- ad-hoc 分发（无 queue.md 行）：`/hopper:research`（task-type prd-research）、`/hopper:market`（market-research）、`/hopper:review`（code-review-acceptance，`--adversarial` 切 code-review-adversarial，默认 reviewer：acceptance=codex、adversarial=grok）——均走 `--adhoc --task-type X --brief "..." --id <slug> --background`，research/market task-type 自动开 web search + read-only sandbox，review task-type 自动 read-only
- 多 vendor swarm（`/hopper:swarm`）：仅限定性任务（review/research/market），拒绝实现类 task-type（N 个 vendor 改同一批文件会冲突）；流程：①解析 target + 推断/指定 `--type` ②强制确认门：先跑 `--setup` 看就绪，提出默认 3 个不同模型家族的 panel（research/market 只提 WebSrch=yes 的、review 优先 Sandbox=argv 的、只提 Installed=yes+Auth=ok 的），呈现后 STOP 等用户确认/调整 ③共享配置用一条 `--swarm --task-type X --brief ... --vendors a,b,c --id-base <base>`（打印 SWARM_IDS），按 vendor 定制模型/effort 则改为 N 条 `--adhoc ... --vendor X --model Y` 后台调用 ④≥10s 间隔轮询，逐个 `--result <id> --full` 收全文，合成：一致点（高置信）/分歧点（标给用户）/各家独有最强观点，findings 归属到 vendor；失败 panelist 不重派，用其余合成
- 调参转发机制：`--model` 与 `--reasoning` 是两个独立旋钮绝不拼成一个字符串（`--model gpt-5.5-xhigh` 是错的）；`--model` 经 V4 归一化到目标 vendor 规范名（GPT-5.5→gpt-5.5、openai-codex/gpt-5.5→gpt-5.5、opus-1m→opus[1m]），未识别名原样透传，且只归一化 `--model` 旋钮、绝不改写 brief 正文里的模型名；`--reasoning` 默认 xhigh：codex→`model_reasoning_effort`、mimo→`--variant`(xhigh→max)、grok/copilot→`--effort`(钳到 high)、opencode 需 `HOPPER_OPENCODE_VARIANT`、kimi/claude/agy 无该旋钮静默忽略
- sandbox 机制：默认 danger-full-access，但 review/research task-type（code-review-*、prd-research、market-research）或 brief 含 read-only/只读时自动降为 read-only；显式 `--sandbox` 优先；`HOPPER_DEFAULT_SANDBOX` 改全局基线；映射：codex `-s <mode>`（Windows danger-full-access 另加 `--dangerously-bypass-approvals-and-sandbox`）、opencode/agy danger→`--dangerously-skip-permissions`、copilot→`--allow-all-tools --allow-all-paths`、grok→`--always-approve`、mimo full=`--agent build --dangerously-skip-permissions` / read-only=`--agent plan`、kimi 不转发 sandbox argv（原生策略，且 `--prompt` 与 `--yolo`/`--auto`/`--plan` 互斥）
- 写回机制（`--write` + 用户行动门 spec §11）：dispatcher 写 output.md 并打印建议的 queue.md 编辑 + COST-LOG.md 行，宿主绝不自动应用——只有用户能把任务标 done，必须先问 "Apply the suggested edits?"
- 项目引导：`--init-tasks` 在当前目录脚手架 `.hopper/`（`--force` 覆盖）；`--resolve <id>`/`--check <id>` 干跑路由不分发；`--rules` 输出权威的 per-vendor 模型/effort/sandbox 矩阵（同时写 `.hopper/DISPATCH.md`）；`--capabilities <vendor>` 单 vendor 契约

**usage_entrypoints**

- 斜杠命令（12 个，`hopper:` 前缀）：`/hopper:dispatch <task-id> [--background --write --force --web-search --model <n> --reasoning <minimal|low|medium|high|xhigh> --sandbox <read-only|workspace-write|danger-full-access> --vendor <n>]`；`/hopper:status`（无参只读）；`/hopper:result <task-id> [--full]`；`/hopper:probe [vendor]`；`/hopper:models [vendor]`；`/hopper:vendors`；`/hopper:setup [vendor] [--deep]`；`/hopper:smoke`；`/hopper:review <target> [--vendor <n>] [--adversarial]`；`/hopper:research <question> [--vendor <n>]`；`/hopper:market <topic> [--vendor <n>]`；`/hopper:swarm <target-or-question> [--type review|research|market] [--vendors v1,v2,v3]`
- SKILL（10 个，自然语言触发）：`hopper:hopper`（总入口/协议排障/选工作流）、`hopper-dispatch`、`hopper-status`、`hopper-progress`（唯一无对应 slash 命令的功能面：`--progress`/`--watch`/`--watch-events`）、`hopper-result`、`hopper-probe`、`hopper-models`、`hopper-vendors`、`hopper-setup`（doctor 触发词）、`hopper-smoke`。注意：swarm/research/review/market 只有命令没有 SKILL
- CLI 直调：优先 PATH 上的 `hopper-dispatch`；否则 `node "$CLAUDE_PLUGIN_ROOT/cli/bin/hopper-dispatch" <args>`——但必须先验证 `$CLAUDE_PLUGIN_ROOT` 下确有该二进制，否则回退搜索 `~/.claude/plugins/hopper`、`~/.claude/plugins/hopper-plugin`、`./`；本仓库源码路径为 `hopper-plugin/cli/bin/hopper-dispatch`
- 典型调用序列（真实任务）：① `hopper-dispatch --setup` 确认 vendor 就绪 → ② `--resolve <task-id>` 干跑路由 → ③ `/hopper:dispatch <task-id> --background`（>1min 的任务必须 `--background`）→ ④ `--progress <id>` 或 `head -20 .hopper/handoffs/<id>-output.md` 轮询（≥10s 间隔）→ ⑤ `--result <id> [--full]` 收结果 → ⑥ 若带 `--write`，向用户确认后才应用建议的 queue.md/COST-LOG.md 编辑
- ad-hoc 调用形态：`node $HOPPER_BIN --adhoc --task-type <prd-research|market-research|code-review-acceptance|code-review-adversarial> --brief "<组装并引用的 brief>" --id <slug> [--vendor X] --background`；swarm 共享配置：`--swarm --task-type <type> --brief "..." --vendors codex,grok,claude --id-base <base>`
- 项目定位规则：dispatch/status/result/progress 需要 `.hopper/`（cwd 或向上找，找不到问用户或设 `HOPPER_DIR=/path/to/project/.hopper`）；诊断类 `--vendors`/`--rules`/`--setup`/`--capabilities`/`--probe`/`--models`/`--smoke` 不需要 `.hopper/`，任意目录可跑
- task-id 校验（shell 前必做）：`^[A-Za-z][A-Za-z0-9._-]{0,99}$`，拒绝 `/`、`\`、`..`、shell 元字符、引号、空白、换行；`--model` 值校验 `^[A-Za-z][A-Za-z0-9._/:()\[\] -]{0,99}$`（shell 里加引号）；probe/models 的 vendor 参数校验 `^(codex|kimi|opencode|copilot|agy|grok|mimo)$`

**key_concepts**

- llm-hopper 文件协议：一切状态落盘在项目 `.hopper/` 目录——queue.md（任务队列，只有用户能标 done）、AGENTS.md（vendor 路由偏好）、tasks/<task-type>.md（任务框架）、handoffs/<id>-output.md + .log + -output-raw.txt（结果三件套）、COST-LOG.md（成本账）、DISPATCH.md（--rules 生成的权威矩阵）、HOPPER-FEEDBACK.md（缺陷反馈）；机器级缓存独立在 `~/.hopper/cache/vendor-capabilities.json`
- single-spawn 不变量（spec §3 #4）：每次 dispatch 恰好 spawn 一次 vendor 子进程，无重试无 fallback；probe 和 setup `--deep` 是仅有的额外 spawn 豁免（§14.6）
- 用户行动门（spec §11）：宿主/dispatcher 只能建议 queue.md 和 COST-LOG.md 的编辑，应用与否由用户决定；"no soft-orchestration"——失败后连修复建议都不主动给，除非用户要
- task-type 驱动的策略自动化：code-review-*/prd-research/market-research 自动 read-only sandbox；prd-research/market-research 自动开 web search；task-type 还决定默认 vendor（acceptance→codex，adversarial→grok，research/market→codex）
- 两条分发路径：队列路径（queue.md 行 + 依赖检查 + `--write` 回写建议）vs ad-hoc 路径（`--adhoc`/`--swarm`，`--brief` 即任务、无队列行）；swarm 是 ad-hoc 的并行扇出特例，仅限定性任务且有强制人工确认门
- host≠vendor 规则：宿主不能派给自己同类的 vendor（Claude Code 宿主 ↛ claude vendor），防止递归/自派
- introspection 分级（full/partial/config-only/none）+ 缓存陈旧度（约 14 天 `[STALE]`）+ knownGood/DRIFT/driftExpected：模型清单三层可信度模型
- Sandbox=argv vs native：argv 表示 hopper 能用命令行 flag 真正强制沙箱模式，native 表示只能依赖 vendor 自身权限策略——选 reviewer 时的关键区分

**gotchas**

- `--model` 和 `--reasoning` 是两个独立旋钮，绝不能拼接（`--model gpt-5.5-xhigh` 会被 vendor 当未知模型拒绝）；用户口头提到模型名时应路由到 `--model` 旋钮，因为 hopper 绝不改写 brief 正文里的模型名（防止破坏"对比 gpt-5.4 vs gpt-5.4-mini"这类合法内容）
- `--reasoning` 的 xhigh 到各家会被钳制或忽略：grok/copilot 钳到 high、mimo 映射为 max、opencode 需要 `HOPPER_OPENCODE_VARIANT` 环境变量才转发、kimi/claude/agy 直接忽略——期望的 effort 不一定真的生效
- 一次 slash 只派一个任务（除非用户明确给多个 task-id）；ad-hoc 命令（research/review/market/swarm）不在 queue.md 留行，事后审计要看 `.hopper/handoffs/` 而不是队列
- AGENTS.md 里 vendor 名拼错会 `Unknown vendor: <name>` 失败；归一化只处理尾部 `-cli`/`_cli`，其他拼写差异不救
- `hopper-progress` 功能只有 SKILL 没有 slash 命令；反过来 swarm/research/review/market 只有 slash 命令没有 SKILL——自然语言触发和 `/` 触发的覆盖面不对称
- claude vendor 的 `claude -p` 计费策略 2026 年反复变动（6/15 的 Agent SDK 独立额度拆分后来回滚），adapter 对计费不感知——跨宿主用它前先核实当前政策
- dispatched vendor 运行在拥有 `.hopper/` 的仓库根目录，与你 shell 的 CWD 无关（retro #3 修复）；不需要 cd 进插件 CLI 目录
- 结果输出要求 verbatim 转述（raw output 就是 chat artifact），用户没要摘要就不要 paraphrase

---

### Area C — ISSUE 账本 + cli/hosts/monitors 结构 + 测试基线

> 原始定位：llm-hopper 文件协议参考实现（v0.30.0）；把任务从 `.hopper/queue.md` 派发给 8 个第三方 vendor agent CLI 的 Claude Code 插件——ISSUE 账本、cli/hosts/monitors 结构、测试命令预读

**capabilities**

- 文件协议派发：`.hopper/queue.md` 任务行 → hopper-dispatch 组装 brief、按 rules 解析 vendor、spawn vendor CLI；结果落 `.hopper/handoffs/<task>-output.md`（frontmatter: status/adapter_status/progress_seq/terminal_event_emitted）+ `-output.log` + `-progress.log`
- 后台派发（`--background`）走独立 `cli/bin/hopper-runner`：双计时器=idle 看门狗（轮询日志文件字节增长，默认 180s 静默判卡死）+ 绝对 ceiling（≥30min 地板）；adapter 声明钩子调制 idle 检测——mimo 的 idleHeartbeatRe（心跳行不算增长）、grok/claude 的 bufferedOutput:true（整体禁用 idle、只留 ceiling）
- 8 个 vendor adapter（`cli/src/vendors/codex|kimi|opencode|copilot|agy|grok|mimo|claude.js`）：各自实现 args()/timeoutMs()/parseResult()/capabilities；模型与推理力度分离转发——codex `-m <裸模型名>` + `-c model_reasoning_effort`，copilot `--effort` 钳位到 low/medium/high（`HOPPER_COPILOT_EFFORT` 原样覆盖），grok `-m`/`--effort`，opencode 仅 `HOPPER_OPENCODE_VARIANT` 显式开启；kimi/claude/agy 无 effort 旋钮（CLI 真实限制）
- codex 隔离链：隔离 `CODEX_HOME` + config.toml 清洗（剥 `[plugins.*]`/`[marketplaces.*]`/`[[hooks.*]]`/`[skills.*]`）+ `--disable multi_agent hooks plugin_hooks` + danger-full-access 映射为 `--dangerously-bypass-approvals-and-sandbox`（防 Windows 1326）+ prompt 置于 argv 末位；逃生门 `HOPPER_CODEX_SANDBOX_BYPASS=0` / `HOPPER_CODEX_KEEP_ORCHESTRATION=1`
- prompt-delivery.js 尺寸门控指针投递：组装后的命令行超出每平台字节预算时，把 prompt 写入 `handoffs/<task>-prompt.md`，vendor 收到一条"读此文件"指针（对全部 vendor 统一）
- vendor 能力探测缓存：`--probe` 写 `~/.hopper/cache/`，`--models` 读缓存，`--setup`/`--doctor` 输出 8-vendor 就绪表（installed/auth/models/sandboxControl 分类 argv|full|native/web-search），`--check` 单查安装+认证
- ad-hoc 派发（`--adhoc --task-type <t> --brief "..."`，无 queue 行，brief 即 spec）；swarm=N 次 `--adhoc` 并行扇出；`--result <id> [--full]` 取回结果（含 archive 回退）；`--jobs` 列在跑后台任务；`--watch <id>` 尾随；`--stop`/`--reap`/`--archive` 生命周期管理
- monitor：`monitors/monitors.json` 在每个 Claude 会话自动起 `hopper-dispatch --watch-events`，对 NEW terminal 转变发 JSONL+OS 通知；启动时 baseline-prime（不回放历史，`--replay` 可选回放）；`--once` 有界退出（`HOPPER_WATCH_ONCE_TIMEOUT_MS`，默认 30min）
- 超时可调：`--timeout`（单任务 ceiling）> `HOPPER_DISPATCH_TIMEOUT_MS` > max(adapter 基线, 30min)；`HOPPER_IDLE_TIMEOUT_MS` 调 idle；review 类任务型有 applyTaskTypeFloor 加长地板
- 误判防护：parseResult 把 `CreateProcessWithLogonW` 1326 模式分类为 permission-fail（不再 done/exit0 假成功）
- 跨宿主架构：Tier A 独立 CLI / Tier B claude-code 插件（commands/*.md 12 个斜杠命令，plugin root=仓库根）/ Tier C codex-cli、copilot-cli、cursor-cli、grok-cli、opencode 各带 hopper-* bin shim / plugins/hopper 为 codex marketplace 打包用 vendored 子集副本
- hopper-dashboard（express+react，dashboard:dev/build/start）

**usage_entrypoints**

- 斜杠命令（本会话已装）：`/hopper:dispatch <task-id> [--background --vendor <v> --model <m> --reasoning <minimal|low|medium|high|xhigh> --sandbox <mode> --timeout <ms>]`；`/hopper:status`；`/hopper:result`；`/hopper:setup`（=doctor 就绪表）；`/hopper:probe` → `/hopper:models`；`/hopper:vendors`；`/hopper:smoke`；定向任务 `/hopper:research`、`/hopper:market`、`/hopper:review`、`/hopper:swarm`（全部走 `--adhoc`，无 queue 行）
- CLI 直调：`node /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/hopper-plugin/cli/bin/hopper-dispatch <task-id> [--background] | --watch <id> | --watch-events [--once|--replay] | --result <id> [--full] | --jobs | --adhoc --task-type <t> --brief "..." [--vendor][--id][--background] | --smoke | --check [vendor] | --probe [vendor] | --models [vendor] | --setup [--deep] | --stop | --reap | --archive`
- 测试命令（package.json scripts）：`npm test`（=`node --test tests/unit/*.test.js`，48 个单测文件，~806 用例）；分项 `npm run test:queue|test:tasks|test:agents|test:subprocess`；集成测试无 script，用 `node --test tests/integration/*.test.js`（5 文件：background-e2e、execute-dispatch-e2e、real-fixtures、runner-single-spawn、vendor-output-capture）；`npm run smoke`；改 `cli/` 后 `npm run sync:plugin` 同步 vendored 副本；dashboard: `npm run dashboard:dev|build|start`
- 典型首次调用序列：`/hopper:setup` 看就绪表 →（缓存 STALE 则 `/hopper:probe`）→ `/hopper:dispatch <task> --background` → `/hopper:status` 或 `--jobs` → 完成后 `/hopper:result <task> --full`
- codex 模型指定：`--model` 必须裸名（gpt-5.5、gpt-5.4-mini，禁 provider 前缀）；力度独立走 `--reasoning`（默认 xhigh），不要 gpt-5.5-xhigh 这种合体写法

**key_concepts**

- `.hopper/` 工作区三件套：queue.md（任务行）、handoffs/<task>-{output.md,output.log,progress.log,prompt.md}、tasks/（任务型 frame）
- output.md frontmatter 是协议真源：status（done|failed|timeout|cancelled|orphaned）、adapter_status、progress_seq、terminal_event_emitted、session_id（当前恒 null）
- adapter 契约钩子：args/timeoutMs/parseResult/capabilities + idleHeartbeatRe（mimo）+ bufferedOutput（grok/claude）——idle 检测被两类 vendor 各从一个方向击穿（日志长得太勤 vs 从不长），钩子是补丁
- idle vs ceiling 双计时器（subprocess.js:51-93，直接为 mimo-180s issue 而设）
- sandboxControl 三分类（setup.js）：argv=可降级 / full=永远全权（codex）/ native=vendor 自管（kimi，`--sandbox` 传了也不生效）
- baseline-prime：`--watch-events` 启动只记 seq 不发通知，防历史回放刷屏
- vendored 副本双份代码：`cli/src/vendors/*` 与 `plugins/hopper/cli/...`，靠 sync 脚本+防漂移测试维持一致（bypass-flag issue 曾怀疑 bin 加载了旧副本）
- 9 个 ISSUE 文件（非任务所说 10 个）；其中 2 个 status 行过期（monitor-crosstalk 写 open 实为部分修复、progress-watch-hang 写 open 实已修——但见前节 B.1，此判断与 Area A 的判断矛盾，需实测）

**gotchas**

- 根目录 ISSUE 只有 9 个，任务描述的"10 个"不成立
- ISSUE 文件的 Status 行不可尽信：progress-watch-hang 标 open 但 hopper-dispatch:1183-1313 已实现有界退出；monitor-crosstalk 标 open 但启动回放部分已修——判断"是否已修"要对照代码
- `monitors.json` 让每个打开该项目的 Claude 会话都自动跑一个 `--watch-events` 监视进程，多会话即多监视器共享同一 handoffs/
- `--sandbox` 对 native 类 vendor（kimi）完全不生效，但派发头仍打印请求值（作者自认未修，见 grok issue 附带发现 b）；真实执行力看 `/hopper:setup` 表
- codex 跨仓 review 需显式 `HOPPER_VENDOR_CWD` 指向目标仓，且指到非 git 目录会触发 codex 的 git-repo trust 拒绝（`--skip-git-repo-check` 只在 bypass 路径自动加）
- review 类任务型才有超时地板加长；机械批量编辑类任务给 mimo 仍偏慢（逐处 LLM round-trip），作者建议此类任务改派 grok

---

## 使用须知

本图谱是**使用前快照**（基于 2026-07-16 的一次只读并行精读），不是实测结论。三路读取彼此之间已经出现至少一处直接矛盾（`--watch-events --once` 是否挂死、ISSUE 状态是否准确、测试用例数是 616/626 还是 806），这本身就说明静态阅读不能替代真实调用。**一旦在真实任务中使用 hopper-plugin，凡是实战发现与本图谱不符之处，一律以实测为准，并记入 `docs/validation-log.md`。**
