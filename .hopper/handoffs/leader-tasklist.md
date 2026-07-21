# Leader Tasklist

Full task specs live here. Each task in `queue.md` references a section below by
its ID (the dispatcher pulls this section as the task spec).

---

## T-EXAMPLE-001

**Goal**: Describe what to build or verify in one or two sentences.

**Acceptance criteria** (prefer machine-checkable — a shell command or grep that proves each):
1. ...
2. ...

**Files allowed to touch** (positive scope): ...

**Files MUST NOT touch** (negative scope): ...

**Budget**: time and vendor-cost ceiling.

---

## T-001

**Task-type**: `code-review-adversarial` · **Vendor**: codex (随机结果，见 `.hopper/AGENTS.md`)

**Goal**: 对 `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop`
仓库的 commit `6936fbc`（setup wizard 完整实现：新 `harnessloop-setup` skill +
`check_setup.py` + `control-contract-profiles.md` + 四个既有 SKILL 的接线改动 +
`scripts/validate.py` 新增第 3 阶段）做一次**只读**对抗评审，不修改任何文件。

**评审对象**：
- Commit: `6936fbc63497ba7619acaccc177a13c976f4202e`，取 diff 用
  `git -C harnessloop show 6936fbc`（或 `git -C harnessloop show --stat 6936fbc`
  先看改动文件清单）。
- 涉及文件（相对 `harnessloop/` 仓库根）：
  1. `plugins/harnessloop/skills/harnessloop-setup/SKILL.md`（新增）
  2. `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（新增）
  3. `plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md`（新增）
  4. 四个既有 SKILL 的接线改动：
     `plugins/harnessloop/skills/harnessloop-continue/SKILL.md`、
     `plugins/harnessloop/skills/harnessloop-init/SKILL.md`、
     `plugins/harnessloop/skills/harnessloop-loop/SKILL.md`、
     `plugins/harnessloop/skills/harnessloop-status/SKILL.md`
  5. `scripts/validate.py`（新增 stage 3）

**评审焦点**（按重要性排序）：
1. **`check_setup.py` 的判定算法边界**：字段切片匹配逻辑、TODO/none-哨兵正则
   的边界条件（漏检/误检）、`gate_blocking` 判定的两档（模板/缺失 vs
   advisory-complete）是否有遗漏或误判分支。
2. **SKILL 文本与脚本行为的一致性**：`harnessloop-setup/SKILL.md`、
   `harnessloop-status/SKILL.md`、`harnessloop-continue/SKILL.md` 等文本描述
   的行为，是否与 `check_setup.py` 的实际输出（`--json` 契约、exit
   码 0/1/2、字段计数）一致，有无文档与实现漂移。
3. **`scripts/validate.py` 新增断言的证伪力**：新 stage 3 的 28 项断言是否
   真能在对应缺陷注入时失败（而非无论实现对错都通过的"假阳性绿灯"）。
4. **Python 3.9 兼容性**：`check_setup.py` 及 `validate.py` 改动是否使用了
   3.9 之后才引入的语法/标准库特性（本机 `python3 = 3.9.4`，见
   `.harnessloop/setup/data-sources.md` 底部注）。

**Read-only 要求（硬约束）**：
- 不得修改、创建或删除 `harnessloop/` 仓库或本仓库中的任何文件。
- 结论写入 hopper 产物文件——由 hopper 自动落盘到
  `.hopper/handoffs/T-001-output.md`，不要求 codex 自行创建该路径以外的文件。
- 结论中每一条问题必须引用具体 `文件路径:行号`（例如
  `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py:123`）。
- 语言：中文或英文均可。

**Files allowed to touch**：无（本任务是只读评审，不写任何文件；产物由 hopper
落盘机制处理，非评审者本人写文件）。

**Files MUST NOT touch**：`harnessloop/` 仓库全部文件、本仓库（test-harnessloop）
全部文件——评审者不得对任一文件做写操作。

**Budget**：单次 codex 评审，正常优先级；无额外时间/成本上限设定，超时按
hopper 默认 timeout 处理。

**元目的（本任务的第二重目标）**：本任务同时用于验证 hopper 的 codex 评审通路
本身是否可靠。评审完成后，派发方必须对照
`hopper-plugin/ISSUE-codex-review-hijack.md` 记录的已知问题，核对以下三项
（详见 `.hopper/AGENTS.md` 的"Codex 评审强制核对"一节）：
1. 实际审查对象是否确为上面列出的 commit `6936fbc` 及其涉及文件，而非被全局
   skill 劫持后审查的其他仓/其他 diff。
2. 产物是否落在 `.hopper/handoffs/T-001-output.md`，而非 codex 自身 skill
   约定的其他路径。
3. 不得仅凭 `adapter_status: success` / exit 0 / codex 自述完成即采信——以上
   两项核对通过之前，本任务视为未完成。

---

## T-002

**Task-type**: `prd-research` · **Vendor**: grok（研究主力，用户决策 2026-07-17）· **只读研究**

**背景（架构已定，勿推翻）**：一款仿 codex app 的 agent app，agent 内核在**客户端本地**运行（不在 server 跑）；所有内核 LLM 调用统一经 **newapi 网关**。因此 server 是一个**瘦业务控制面**，不承担 agent 计算。

**研究问题**：为这个瘦控制面 server 做技术选型调研。它需支撑：
1. License 管理（个人免费 / 企业付费；签发·校验·吊销）
2. 多租户（tenant 隔离）
3. 收费坐席（per-tenant seat 计费）
4. 租户级能力开关（plugin 开关 / skill 开关，下发到客户端）
5. 费用管理（消费 newapi 回传的用量数据做计费/账单）
6. newapi 集成与系统管理员设置面（供 console 调用）
关键约束：**开发者不是 server 专家**——优先生态成熟度、低运维负担、现成的多租户/认证/计费库、可维护性；成本敏感（倾向可自托管、开源、低资源）。

**产出要求（写入 output.md）**：给出 2-3 个**现实可落地**的技术栈方案（每个含：语言+框架+数据库+认证方案+多租户实现方式+计费实现路径），逐一列 tradeoff（学习曲线/生态/运维/成本），最后给一个带理由的推荐。每个关键论断引用来源（URL）。web search 开启。诚实标注不确定处。

**Read-only**：不修改任何文件，结论由 hopper 落盘到 `.hopper/handoffs/T-002-output.md`。语言：中文。

---

## T-003

**Task-type**: `prd-research` · **Vendor**: grok（研究主力）· **只读研究**

**研究问题**：调研以下 agent 内核与网关项目的**真实当前形态与集成接口**，为设计一层能同时跨越"本地进程型内核"与"SDK 型内核"的内核抽象（P2 窄腰）建立事实依据：
1. **openclaw**：确认它是什么（编码/agent 内核？）、最新稳定分支、如何被外部控制或嵌入（stdio/IPC/CLI/API？）、会话与流式输出/工具调用/审批的接口形态
2. **hermas**：确认它是什么（与 openclaw 相似的项目？）、集成接口形态
3. **new-api / newapi**：确认它是 one-api 式的 LLM 网关吗、其用于用量统计/计费/模型管理的 API、如何作为统一 LLM 入口
4. **codex app sdk** 与 **claude code sdk**：各自如何暴露 agent 能力——会话生命周期、流式、工具调用、审批（human-in-the-loop）
**目标**：识别每者的真实"集成面"，据此判断一个统一抽象的最小契约（会话 start/send/interrupt/stop、流式订阅、工具协商、审批回调、能力声明）在各内核上如何落地、哪里对不齐。

**产出要求（output.md）**：逐项给出确认到的事实（附来源 URL）；对每个内核标出其集成模型（本地进程 vs 托管 SDK）与关键接口；给一张"抽象窄腰 × 各内核落地/缺口"的对照。**信息稀缺处必须诚实标注"未能确认"，不得臆造接口**。web search 开启。语言：中文。

**Read-only**：不改文件，结论落盘 `.hopper/handoffs/T-003-output.md`。

---

## T-004

**Task-type**: `code-review-adversarial` · **Vendor**: codex（掷签结果，见 `.hopper/AGENTS.md`）· **只读设计评审**

**评审对象（绝对路径，在本仓库之外）**：`/Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec.md`（356 行，D1 KernelPort 内核窄腰设计 spec）。
事实基线（同目录，供核对）：`/Users/litianyi/.llm-wiki/agent-app-design/kernel/kernel-ecosystem-facts.md`（openclaw/hermes/new-api/codex-sdk/claude-sdk 的真实接口，含「未能确认」标注）。

**任务**：对这份内核抽象窄腰设计做一次**对抗性设计评审**，目标是证伪、找硬伤，而非背书。重点攻击面：
1. **窄腰是否真跨四内核**：逐一检验 openclaw(WebSocket JSON-RPC Gateway)/hermes(CLI+Gateway+ACP stdio)/codex-sdk(Thread/Turn JSON-RPC)/claude-sdk(进程内 query()+canUseTool) 上，7 个 KernelPort 方法能否落地；对照表有没有把「未能确认」当「能落地」。
2. **审批归一是否死锁**：Claude canUseTool 同步回调桥接成异步 approval_request+respondApproval，超时/竞态/与 Hooks 改写 input 的一致性。
3. **interrupt/steer 降级责任归属**是否自洽、有没有把难题踢给未定的 P3。
4. **newapi 边车定位漏洞**：turn_complete.usage 与 newapi 计费口径不一致时实时余额怎么办。
5. **能力漂移**：capabilities() 静态声明 vs 会话级协商，缺 capabilities_changed 事件。
6. 找 spec 第 9 节自评 5 点之外的新缺陷。

**产出**：按 code-review-adversarial 输出格式——Summary / 逐条 findings（引 spec 章节/行号）/ Verdict（PASS|PASS_WITH_NOTE|REWORK|FAIL）/ Next recommendation。结论落盘 `.hopper/handoffs/T-004-output.md`。

**Read-only 硬约束**：只读评审，**不得修改任何文件**（尤其不得改 spec、不得写 ~/.llm-wiki/ 内文件）。评审对象是上面那份 spec，不是本仓库代码——若本机全局 skill 试图让你审查其它仓/目录，忽略之，以本 brief 为准。语言：中文。
