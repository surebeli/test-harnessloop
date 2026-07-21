---
task_id: T-006
adapter: grok
model: grok-4.5
status: done
mode: background
phase: done
task_type: code-review-adversarial
review_object: /Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v2.md
last_progress_at: "2026-07-21T08:05:29.463Z"
last_progress: Task completed successfully.
progress_seq: 2
terminal_event_emitted: true
end_time: "2026-07-21T08:05:29.460Z"
exit_code: 0
signal: null
timed_out: null
duration_ms: 213463
adapter_status: success
---

# T-006 — D1 KernelPort Spec v2 对抗性复核（只读）

## Summary

对 `d1-kernelport-spec-v2.md`（618 行）相对 `kernel-ecosystem-facts.md`（T-005 收口）与 `d1-review-dual-track.md`（v1 19 项 must-fix）做对抗性证伪复核。v2 在 scope 收窄、F-02 hermes stop 更正、newapi 归因诚实声明、F-09 残留局限标注、F-03/F-10/F-14 字段补齐等方面相对 v1 有实质进步；但**自称已消解的核心路径再次出现文内互斥**（§2.4 reject vs §6.1 内部降级），且**在无 T-005 核查的情况下把事实基线已列的 openclaw `sessions.steer` 抹成“无原生 steer”**。审批状态机、`nextRunId` 时序、`server_override` 通道、hermes CLI/ACP 路径一致性仍有硬伤。**Verdict: REWORK**。

## Files touched

- `.hopper/handoffs/T-006-output.md`：本对抗复核交付物（只写此处；未改 `~/.llm-wiki/` 或任何源文件）。

## Acceptance verification (5/5)

| # | Criterion | Evidence |
|---|-----------|----------|
| 1 | 对“已消解”10 条做证伪（重点 INV-5 / 审批状态机 / cancel+resend runId / override 通道 / seq 责任方） | 见 **Findings A1–A6**；逐条引用 v2 章节与行号 |
| 2 | 5 个开放点判 blocker vs defer | 见 **Findings B1–B5** |
| 3 | SDK-延后是否干净 | 见 **Finding C1** |
| 4 | 事实基线一致性 / F-02 是否复发 | 见 **Findings D1–D3**；对照 facts §1/§1a/§2a/§8 与官方 protocol |
| 5 | v2 新引入缺陷 | 见 **Findings E1–E5**；产出结构含 Summary/Findings/Verdict/Next；中文；只读 |

机器可检：

```bash
test -f .hopper/handoffs/T-006-output.md
rg -n "^(## Summary|## Files touched|## Acceptance|## Decisions|## Open questions|## Verdict|## Next|### A\.|### B\.|### C\.|### D\.|### E\.)" .hopper/handoffs/T-006-output.md
rg -n "REWORK|§2\.4|§6\.1|sessions\.steer|nextRunId|server_override" .hopper/handoffs/T-006-output.md | head -40
```

## Decisions / deviations

- 假定 v2 行号以 `/Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v2.md` 当前 618 行文本为准。
- 对 openclaw `sessions.steer`：除 facts 基线外，另用官方 `docs.openclaw.ai/gateway/protocol` 交叉确认（web-search 可用，任务允许）；**未**把该确认写回 wiki。
- “10 条已消解”按 v2 §10 自述的 F-02/03/05/06/07/08/10/11/12/14 十条完全消解项逐条打分；F-09 单独按“部分化解”处理。
- 假设：若作者意图是“`interruptModes` 声明的是**体验无损 steer**，而 API 仍接受 `mode:'steer'` 走降级”，则必须改写 §2.4/§4/§9.1 的 reject 语义；当前文本未建立这套双层词汇，按字面互斥判定。

## Open questions

1. openclaw `sessions.steer` / `chat.send(queueMode:'steer')` 的精确语义是否“保留已产出并注入新指令”，还是接近 interrupt+followup？（T-005 未查；阻塞 v2 对 openclaw `interruptModes` 的定论。）
2. openclaw `approval.resolve` 是否接受改写后的执行参数（对应 `updatedInput` 的 Transport 映射）？
3. hermes 生产路径是否强制 ACP-only？若允许 CLI createSession，审批桥如何附着？

---

# Findings（对抗性证伪正文）

## A. “已消解”10 条是否真消解

### A1. F-07 / INV-5 — **未消解（BLOCKER，复发型自相矛盾）**

**声称**（§1 INV-5，约 L59–62；§10 F-07）：执行收敛进适配器，UI/P3 只展示 `degraded`，“两者不再矛盾”。

**证伪**：

| 位置 | 字面规则 |
|------|----------|
| §2.4 L177–178 | `interruptModes` 不含 `opts.mode` → **必须 reject**（`unsupported_interrupt_mode`），**不得静默降级**——“降级逻辑见 §6.1” |
| §4 L396 | 适配器兜底：`interrupt(mode:'steer')` 能力不支持时 **必须 reject**，见 §2.4 |
| §9.1 L535 | `unsupported_interrupt_mode` 注释仍写：`interrupt({mode:'steer'})` 但 caps 不含 steer |
| §6.1 L420–425 | 同一条件（caps 不含 steer）→ **不 reject**，适配器内部 cancel+resend |
| §6.1 L429 | openclaw/hermes 的 `interruptModes` **只含 `'cancel'`** |

在 L429 前提下，任何 `mode:'steer'` 调用**同时**命中 §2.4 的必 reject 与 §6.1 的必降级。§6.1 成为死代码，或 §2.4/§4/§9.1 成为死代码——实现者无法二选一而不违反契约。

这与 v1 F-07 同构：不变量/总规则与落地节互相否决，只是责任主体从“UI 执行降级”翻转为“适配器执行降级”，**文内一致性仍未收口**。

**判定**：F-07 **未消解**。不得计入“10 条已消解”。

---

### A2. F-08 / cancel+resend 是否真用 openclaw `runId` — **部分消解，完成屏障有硬伤（HIGH）**

**进步**：§2.4 L168–169、§6.1 L422 明确 openclaw 用 `sessions.abort`/`chat.abort` 携 `runId`（对齐 T-005 / facts §1a）。`affectedRunId` 返回值改善了竞态可观测性。

**未闭合**：

1. **`nextRunId` 时序悖论（E1）** — §6.1 L424：
   - 先等 `turn_complete`（已带 `degraded.nextRunId`），
   - **再** `send(newInput)`，并声称 `nextRunId` 即新 run 的 `runId`。  
   openclaw 的 `runId` 由 agent/chat RPC **接受后返回**（facts §1a），适配器在 abort 完成、send 之前**不可能**合法填入真实 `nextRunId`。可选修复（均未写明）：预分配本地 id / 先 send 再补事件 / 拆成两条事件。**当前算法不可实现。**

2. **完成屏障无失败路径** — “待 `turn_complete` 后 resend”无超时、无 abort 失败、无“cancelled 事件丢失”处理；F-08 原诉“无完成屏障”只补了寻址，未补屏障失败语义。

3. **hermes** — 靠 §9.3 单 active run 把 session 级 cancel 等价 run 级，逻辑自洽，但依赖并发收窄前提；与 openclaw 排队模型不对称（见 E3）。

**判定**：F-08 **部分消解**（runId 寻址有事实），**不可标完全消解**。

---

### A3. F-06 / 审批状态机闭合性 — **部分消解（HIGH）**

**进步**：§6.2 四终态、exactly-once、`forceResolvedApprovals`、reqId=approval id（非 toolCallId）均对齐 T-005。

**未闭合**：

1. **`allow_session` 丢失**（facts §2a 确认 hermes 有 `allow_session`；§5 L411 文字提到；`ApprovalDecision` §2.6 L192–195 仅 `allow_once`/`allow_always`/`deny`）。归一表写了输入，类型无输出位 → 永久 allowlist 与 session 级 allow 在窄腰上不可区分，或静默降成 `allow_always`（语义错误）。

2. **pending 上限 1 + 串行呈现**（§6.2 L448）未定义：第二笔内核审批在 UI 仍处理第一笔时，适配器是本地排队、对内核立即 deny、还是让内核超时？openclaw 可存在多笔 pending exec；串行 UI 与内核时钟脱节会制造**静默 timeout deny**。

3. **`updatedInput`（F-05）** — 类型字段已加，但 §5 respondApproval 映射未给出 openclaw resolve / hermes ACP 是否接受改写 input 的证据；facts **未确认**。属“类型消解、传输未消解”。

4. **超时时钟所有权** — openclaw 30min 文档保证 vs hermes ~60s 实现风险；状态机写 `TIMED_OUT_DENY` 由“内核侧 fail-closed 到达适配器”，但 `timeoutMs` 又给 UI 倒计时——双时钟谁权威未钉死。

5. **与 steer 降级交叉** — 作者自列 §11.2；见 B4。未定序则 `FORCE_DENIED_ON_STOP` 与 abort 竞态下可能双 resolve 或漏 deny。

**判定**：F-06 **框架在，闭合不够**；不得算干净消解。

---

### A4. F-11 / capabilities 变更与“我方 override 通道” — **部分消解（HIGH，偏 BLOCKER 于主路径宣称）**

**进步**：承认无原生 `capabilities_changed`（对齐 T-005）；`capabilities(session?)`；合成 `CapabilityChangedEvent` 双来源（§3 L339–352、§4）。

**未闭合**：

1. **`server_override` 下发协议未定义**（作者自承 §11.1）——“我方自己的推送通道”无消息形状、无多实例一致性、无适配器订阅 API。事件**消费**形状有了，**生产**路径空洞 → INV-4 中途刷新主路径之一不可实现。

2. **§4 L396 与 §6.1 再次冲突**（steer reject vs 降级），能力门控叙事自打脸。

3. **连接级 caps 变更**（无 session 的 `capabilities()`）无事件注入点；仅 session `subscribe()` 可收 `capability_changed`。

4. **`kernel_error_inferred` 滞后**：只能在 RPC 失败后合成，UI 在失败前仍持过期快照——可接受若写明，但与“已消解 INV-4”的强度不匹配。

**判定**：F-11 **叙事消解 > 机制消解**；override 通道清不出来则不应标“已消解”。

---

### A5. F-12 / seq 与断线恢复责任方 — **基本消解，残留 MEDIUM**

**进步**：删除“session 内全局单调唯一”；run 内排序；不重放；§9.2 划分适配器内部重连 vs 调用方重 `subscribe()`——对齐 facts §1a（history 替换、inFlightRun）。

**残留**：

- “重连原则上对调用方不可见”与“可合成 `network_lost`”并存，**MUST vs MAY** 未钉死；UI 是否必须刷新局部 delta 投影不清晰。
- hermes 适配器本地 seq 与 openclaw 双层 seq 混在同一 `KernelEvent.seq` 字段，跨内核调试/对账语义弱（已承认，可接受）。

**判定**：F-12 **大致消解**；建议把 gap → `network_lost` 升为 MUST，并要求 UI 做 history 级 resync。

---

### A6. 其余“已消解”快评

| 项 | 判定 | 一句话 |
|----|------|--------|
| **F-02** hermes stop | **真消解** | §5/§6.3/§8 改为 CLI delete + ACP cancel 双路径，纠正 v1 误标；轻微：hermes stop 仍打 ✅，更宜 🟡（非原子/双路径） |
| **F-03** newapiEndpoint | **真消解** | 收窄为 baseUrl；token 变输出 artifact；不再假装注入内核凭证 |
| **F-05** updatedInput | **类型消解 / 映射未证** | 见 A3.3 |
| **F-10** billing 记录 | **真消解（在承认局限内）** | `queryBilling` + `correlatable:false` 诚实 |
| **F-14** 审批关联字段 | **真消解** | `toolCallId`/`runId` 必填；主键仍 reqId |
| **F-09** 部分化解 | **诚实，维持部分** | session 级可做；run 级不能；未包装成无损 |

**“10 条已消解”复核计数（对抗后）**：

| 真消解 | 部分/附条件 | 未消解 |
|--------|-------------|--------|
| F-02, F-03, F-10, F-14（+F-12 基本） | F-05, F-06, F-08, F-11 | **F-07** |
| ≈4–5 | ≈4 | **1 BLOCKER** |

作者统计“10 完全 + 1 部分”**不成立**；至少 F-07 必须打回，F-06/08/11 应降为部分。

---

## B. 自评 5 开放点：blocker vs defer

### B1. newapi 请求级 correlation 未确认 — **DEFER（带产品门闩）**

- 位置：§7 局限①、§11.6；facts §3a/§6a 唯一未收口事实。
- v2 已 `correlatable: false`，不假装 run 级计费。
- **判定**：**DEFER**。仅当产品 PRD 强制“单 run 花了多少钱”时升 **BLOCKER**；否则不阻挡 draft→下一轮，但需在 P3/计费 UX 写明 session 聚合。

### B2. `server_override` 下发协议未定义 — **BLOCKER（相对 F-11 收口宣称）**

- 位置：§4、§11.1。
- 若 F-11 保持“已消解”，本项是实现缺口伪装成 P7 后续；能力中途变更是 INV-4 主路径。
- **判定**：**BLOCKER**（对“能力变更模型已闭环”的主张）；若降级 F-11 为部分并砍掉 server_override 叙事、只保留 error-inferred + 重查 `capabilities()`，可 **DEFER 到 P7**。

### B3. hermes 审批超时非官方承诺 — **DEFER（契约需加可靠度标注）**

- 位置：§3 `timeoutMs`、§6.2、§11.3；facts §2a。
- fail-closed 有确认；倒计时 UX 不可靠。
- **判定**：**DEFER**。建议 schema 增加 `timeoutAuthority: 'documented'|'best_effort'`，禁止 UI 在 best_effort 上做精确倒计时。非实现 blocker。

### B4. `degraded` + `forceResolvedApprovals` 定序 — **BLOCKER（审批安全）**

- 位置：§11.2 自承；交叉 §6.1/§6.2。
- steer 降级必 abort run；若同 run 有 pending approval，未定义先 force-deny 再 abort 还是相反；叠加 A1 使路径更乱。
- **判定**：**BLOCKER**（在启用内部 steer 降级的前提下）。最小钉死：`interrupt/stop` 路径 **先** 本地 `FORCE_DENIED_ON_STOP` + 向内核 deny，**再** abort/cancel，最后（若 steer 降级）resend；`TurnCompleteEvent` 允许两字段同现且 deny 列表完备。

### B5. 契约无版本治理（S-09） — **DEFER（HIGH 风险，非本轮实现 blocker）**

- 位置：§11.5；v2 自身已是无过渡 breaking（如 approval 新必填字段）。
- 绿地上可先实现；多客户端/多插件版本并存时爆炸。
- **判定**：**DEFER 实现，但下一轮优先**；建议最低加 `contractVersion: 2` 于 `CapabilityDescriptor` 与事件 envelope。

---

## C. SDK-延后是否干净

### C1. 总体干净，有轻微词汇泄漏（MEDIUM）

**干净处**：

- `KernelKind` 仅 `'openclaw' \| 'hermes'`（§1 L41–47），不留 SDK 占位符。
- F-01/F-04/S-10 明确 SDK-延后；无 `canUseTool`、无 InProcessTransport。
- 生命周期保持 createSession/send 两阶段，与 Daemon 模型同构。

**泄漏/继承嫌疑**：

1. **`sandbox?: 'read-only' \| 'workspace-write' \| 'full-access'`**（§2.1 L110；CapabilityDescriptor L380）——词汇来自 Codex sandbox 枚举（facts §4），**openclaw/hermes 无 T-005 对照证明同构三级沙箱**。有“把 SDK 枚举当跨内核真理”的风险。
2. **`approvalProfile?: 'auto' \| 'manual' \| 'plan'`**——`plan` 更接近 Claude permission mode 语感，openclaw/hermes 映射未给。
3. **steer 策略整体**从“openclaw 原生 sessions.steer（v1）”翻转为“无人有保留产出 steer”，在未做 SDK 的同时也**误伤了 openclaw 已文档化能力**（见 D1）——不是 SDK 泄漏，是反向过度裁剪。

**判定**：SDK 延后边界**基本干净**；sandbox/approvalProfile 枚举需改为“内核原生命名 + 可选归一”或标 ❓，避免 Codex 语义偷渡。

---

## D. 事实基线一致性 / F-02 是否复发

### D1. openclaw `sessions.steer` 被抹除 — **HIGH（F-02 同类：有证据当无证据）**（BLOCKER 级事实错误）

| 来源 | 内容 |
|------|------|
| facts §1 L42 | 会话方法明确列出 **`sessions.steer`（打断并转向）** |
| T-003 / v1 §5/§8 | openclaw interrupt：steer=`sessions.steer`，cancel=`sessions.abort`，**双支持** |
| 官方 protocol（本次核查） | Session control：**`sessions.steer` is the interrupt-and-steer variant for an active session**；`chat.send` 支持 `queueMode: 'steer'\|...` |
| T-005 | **未**调研 steer 语义（T-005-output 无 steer 命中） |
| v2 §5 L409 / §6.1 L429 / §8 L506 | interrupt 只写 abort；断言 openclaw **无**“保留产出”steer；`interruptModes` 仅 `cancel` |

v2 在**没有新的否定性 conformance 证据**的情况下，把基线与 v1 已认定的原生 steer **降级为不存在**，并用 cancel+resend 整条替代路径覆盖 openclaw。这与 v1 F-02（把“未能确认”标成 ✅）方向相反但同类：**用设计叙事覆盖事实表**。

即便最终证明 `sessions.steer` 不保留产出，spec 也必须：
1. 引用核查证据；
2. 说明为何不映射 `interrupt(mode:'steer')` → `sessions.steer`；
3. 而非静默从 Transport 表删除。

**判定**：**F-02 精神复发**；openclaw steer 行必须重开为 ❓ 或 ✅ 原生映射，禁止无证据写死“仅 cancel”。

### D2. hermes stop — **未复发**

§5/§8 正确区分 ACP cancel vs CLI delete；比 v1 诚实。建议 stop 列 🟡 而非 ✅。

### D3. 其它“未能确认”处理

- resume-after-delete ❓ → reject：正确保守（§2.1）。
- newapi correlation 未确认 → 不宣称 run 级：正确。
- hermes ACP 多 session 同进程 ❓：§9.4 保守假设：正确。
- **updatedInput 无内核证据却标 F-05 已消解**：轻度 F-02 倾向（见 A3）。

---

## E. v2 新引入缺陷

### E1. `degraded.nextRunId` 与 cancel+resend 算法顺序不可实现（HIGH/BLOCKER）

见 A2。§3 L323–327 与 §6.1 L424 绑定同一错误时序。

### E2. §2.4 / §4 / §9.1 vs §6.1 三重互斥（BLOCKER）

见 A1。比 v1 更隐蔽：INV-5 散文自洽，**方法注释与错误码与算法节**互斥。

### E3. hermes 创建路径“CLI 或 ACP”与审批“仅 ACP”无绑定（HIGH）

§2.1 L122、§5 createSession/send/subscribe 均写 CLI **或** ACP；§5 respondApproval **仅 ACP**；§8 同。  
若 `createSession` 走 CLI session，可编程审批无附着点（facts：CLI TTY 无可编程协议）。  
**缺**：`CreateSessionConfig` 或适配器策略强制 `transportLine: 'acp' | 'cli'`，且 `cli` 时 `respondApproval`/`approvalKinds` 必须降级声明。

### E4. 并发模型不对称未进入错误码（MEDIUM）

§9.3：openclaw 排队 vs hermes 直接 reject；`KernelPortRejectionCode`（§9.1）无 `run_in_progress` / `queue_not_supported`。调用方无法可移植处理。

### E5. `queryBilling` 边界与 INV-2“仅 7 方法”（LOW/MEDIUM）

§7 称非第 8 方法、属 Server 控制面，但写在 KernelPort 文档内、入参 `SessionHandle`，实现归属（适配器？计费服务？）不清；多实现时易分叉。

### E6.（附加）stop 黑名单与 resume

§6.3 黑名单拒绝 send/interrupt/respondApproval；`createSession({resume})` 是否受黑名单约束未写——stop 后立即 resume 同 id 的行为未定义。

---

# 总表：任务 1–5 结论

| 任务 | 结论 |
|------|------|
| 1. 10 条已消解？ | **否**。F-07 未消解（文内互斥）；F-06/08/11 仅部分；F-02/03/10/12/14 大体真消解；F-05 类型-only |
| 2. 5 开放点 | correlation=DEFER；server_override=**BLOCKER**（若坚持 F-11 已消解）；hermes timeout=DEFER；degraded 定序=**BLOCKER**；S-09=DEFER 优先 |
| 3. SDK 延后 | **基本干净**；sandbox/plan 枚举有 SDK 词汇泄漏 |
| 4. 事实基线 | **`sessions.steer` 抹除 = F-02 类复发**；hermes stop 未复发；newapi 诚实 |
| 5. 新缺陷 | nextRunId 悖论；reject/降级互斥；hermes 线路未钉死；reject 码缺口 |

## Verdict

**REWORK**

理由（阈值）：

1. **BLOCKER**：§2.4/§4/§9.1 与 §6.1 对 `mode:'steer'` 的 reject/降级互斥 → INV-5/F-07 未真正消解。  
2. **BLOCKER**：`degraded.nextRunId` 时序与 cancel→turn_complete→send 算法矛盾，路径不可实现。  
3. **BLOCKER（事实）**：无 T-005 否定证据却删除/否定 openclaw `sessions.steer`，违反“facts 为唯一事实基线、未能确认不臆造”的纪律。  
4. **HIGH**：审批状态机（allow_session、多 pending、updatedInput 映射、与 abort 定序）未闭合。  
5. **HIGH**：`server_override` 有事件无通道，F-11 不可标已消解。

未到 FAIL：scope 收窄正确；F-02 hermes、F-03、F-09 诚实、F-10/F-14、seq 责任方、SDK 延后等方向对，可在同一 v2 文档上修补而非推倒重来。

## Next recommendation

1. **先修文内互斥（同一 PR/同一稿）**  
   - 选定唯一策略并全局对齐：  
     - **策略 α（推荐若 `sessions.steer` 确认可用）**：openclaw `interruptModes` 含 `steer`，§5 映射 `sessions.steer`；hermes 不含 `steer` 时 **reject** 或 **显式** `degraded` 降级（二选一写死，删掉另一套）。  
     - **策略 β（坚持内部 cancel+resend）**：删除 §2.4/§4/§9.1 的“必须 reject / 不得静默降级”；`unsupported_interrupt_mode` 仅用于非法 mode 字符串；`interruptModes` 改为表达**体验档位**（如 `steer_preserve` vs `steer_degraded`）避免布尔歧义。  
   - 重写 §6.1 顺序：abort →（强制 deny pending）→ 等待 cancel 终态（**带超时**）→ `send` → 再发带真实 `nextRunId` 的信号（或 `interrupt` Promise 返回 `{ affectedRunId, nextRunId }`，`turn_complete.degraded` 可后置/分事件）。

2. **事实补丁（短 conformance）**  
   - 查 `sessions.steer` / `chat.send(queueMode:steer)` 语义与是否保留产出；回写 facts，再改 §5/§6.1/§8。  
   - 查 resolve 是否支持 input 改写 → 决定 `updatedInput` 保留或降为 openclaw-only optional。

3. **审批闭合**  
   - `ApprovalDecision` 增加 `allow_session` 或明文映射表。  
   - 钉死 B4 定序；定义第 2 笔 pending 策略。  
   - hermes：`createSession` 默认/强制 ACP，或 CLI profile 禁用审批方法。

4. **降级 F-11 表述或补齐 server_override**  
   - 最小：`CapabilityChangedEvent` 仅保证 `kernel_error_inferred`；`server_override` 标 “P7 依赖，v2 不宣称可实现”。  
   - 或补一页内部 push 契约（主题名、payload、多实例）。

5. **开放点处置**  
   - B1/B3/B5 可进 §11 保留；B2/B4 必须在确认前关闭或降级承诺。  
   - S-09：加 `contractVersion: 2`。  
   - 修完后 **再跑一轮** 对抗复核（可双轨）；在 F-07 文内互斥与 steer 事实未修前，**不要**将 `design_status` 升为 `confirmed`。

6. **本任务只读约束**  
   - 未修改 `~/.llm-wiki/**`；结论仅在本 handoff。若采纳，由主会话/作者改 v2 spec 与 facts。

## Vendor output (parsed)

```
hopper-runner: idle watchdog disabled (bufferedOutput vendor) — ceiling-only timeout applies (1800000ms)
{
  "text": "开始对 D1 KernelPort v2 做对抗性复核：先读评审对象与对照基线，再按 T-006 五条任务逐项证伪。对照事实基线继续深挖矛盾点，并核对 openclaw 的 `sessions.steer` 等关键声明。事实已齐：openclaw 官方仍有 `sessions.steer`，而 v2 内部又出现 §2.4 与 §6.1 的互斥。正在落盘对抗性复核报告。## T-006 完成\n\n对抗性复核已落盘：`.hopper/handoffs/T-006-output.md`\n\n### Verdict: **REWORK**\n\n### 核心硬伤（不可标“已消解”）\n\n1. **F-07 / INV-5 复发式自相矛盾（BLOCKER）**  \n   §2.4 / §4 / §9.1 要求 caps 无 `steer` 时 **必须 reject**；§6.1 在同一条件下 **必须内部 cancel+resend**。再叠加 §6.1 断言两内核 `interruptModes` 只有 `cancel` → 两套规则同时适用、互相否决。\n\n2. **`nextRunId` 时序不可实现（BLOCKER）**  \n   §6.1 要求先产出带 `degraded.nextRunId` 的 `turn_complete`，再 `send()`；而 openclaw 的 `runId` 只能在 send 接受后返回。\n\n3. **事实基线回退 / F-02 类问题（BLOCKER）**  \n   facts 与官方 protocol 均有 **`sessions.steer`**；T-005 未否定它；v2 却写成 openclaw 无原生 steer、只走 abort。属于“用设计叙事覆盖事实表”。\n\n### 部分消解 / 开放点\n\n| 项 | 判定 |\n|----|------|\n| F-02 hermes stop、F-03、F-10、F-14、F-12 | 大体真消解 |\n| F-06 审批机、F-08 runId、F-11 override、F-05 updatedInput | 仅部分 |\n| newapi correlation / hermes timeout / S-09 | **DEFER** |\n| `server_override` 协议、`degraded`↔审批定序 | **BLOCKER**（相对当前收口宣称） |\n| SDK 延后 | 基本干净；sandbox/`plan` 有词汇泄漏 |\n\n### 下一步（摘要）\n\n先在同一稿内消掉 reject vs 降级互斥，并按 facts/官方文档重开 openclaw `sessions.steer`；重写 cancel+resend 与 `nextRunId` 顺序；钉死审批定序与 hermes ACP 绑定。修完前不要把 v2 升为 `confirmed`。",
  "stopReason": "EndTurn",
  "sessionId": "019f83b2-27df-76b0-a290-116d117fcc41",
  "requestId": "4cb4c6e1-df00-44ca-8fd3-f13bb3f58845",
  "thought": "The user wants me to perform an adversarial code review of a design document. Let me carefully understand the task:\nI've read the main documents. Let me also check if there's an existing T-006-output.md and the design approach document. I should do a thorough adversarial review. Let me also look at specific claims ...**Summary**  \n我已完成对 `/Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v2.md` 的对抗性复核，重点针对 v2 宣称“已消解”的 10 条、5 个开放点、SDK 延后及 3 处事实基线一致性问题逐条证伪。发现至少 2 处硬伤：INV-5 自相矛盾（§2.4 要求 reject，§6.1 允许 silent degradation）和审批状态机闭合性未完全闭合（cancel+resend 责任 方未明确）。整体 verdict 为 REWORK，需重构后再通过。\n\n**Files touched**  \n- `/Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v2.md` (618 行) — 核心 spec 文件，逐条引用行号\n\n**Acceptance verification (N/N)**  \n1. 已消解 10 条：  \n   - F-07 INV-5：§2.4:177-178 vs §6.1:420-425 直接矛盾（reject vs silent degradation），未消解  \n   - F-06 审批状态 机：§5 ApprovalDecision 缺少 allow_session 映射，§6.1 未定义 cancel+resend 后 turn_complete 顺序，闭合性未达标  \n   - F-08 cancel+resend：§6.1:429 缺少 completion barrier timeout，runId 分配时机 矛盾，未消解  \n   - F-11 capabilities override：§11.1 仍未定义 server_override 协议，未消解  \n   - 其余 7 条（F-02/F-03/F-05/F-10/F-12/F-14 等）已通过 grep 确认字段 存在且逻辑闭合  \n\n2. 开放点判 blocker：  \n   - newapi 请求级 correlation 未确认 → blocker  \n   - server_override 下发协议未定义 → blocker  \n   - hermes 审批超时非官方承诺 → defer  \n   - degraded+forceResolvedApprovals 定序 → blocker 级  \n   - 契约无版本治理 → defer  \n\n3. SDK 延后：无 SDK 专属假设泄漏，干净  \n\n4. 事实基线：v1 F-02 已修正，无复发；但“未能确认”仍被当“能落地”  \n\n5. 引入新缺陷：  \n   - §6.1:429 隐含的 runId 分配与 turn_complete 顺序矛盾  \n   - §11.1 未定义的 server_override 注入路径  \n\n**Decisions / deviations**  \nnone\n\n**Open questions**  \nnone\n\n**Verdict**: RE WORK\n\n**Next recommendation**  \n重构 §2.4/§6.1 使 interruptModes 声明与降级逻辑一致，并明确 cancel+resend 的 completion barrier 及 runId 分配时机；同时补充 server_override 协议定义。建议在 v2.1 中重新提交。 落盘 `.hopper/handoffs/T-006-output.This is a goldmine. Critical findings:\n**Summary**  \n我已独立对抗性复核 `/Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v2.Confirmed from official OpenClaw docs:The deliverable is written. Let me provide a brief summary to the user - the task is complete as the EXECUTION agent.",
  "usage": {
    "input_tokens": 92307,
    "cache_read_input_tokens": 230784,
    "output_tokens": 13137,
    "reasoning_tokens": 5316,
    "total_tokens": 336228
  },
  "num_turns": 5,
  "total_cost_usd": 0.3376712,
  "total_cost_usd_ticks": 3376712000,
  "modelUsage": {
    "grok-4.5-build": {
      "inputTokens": 92307,
      "outputTokens": 13137,
      "cacheReadInputTokens": 230784,
      "modelCalls": 5,
      "costUSD": 0.3376712
    }
  }
}
```

## Status (background completion)
- queue_status: done
- adapter_status: success
- exit_code: 0
- duration_ms: 213463
- end_time: 2026-07-21T08:05:29.460Z
- log: see `T-006-output.log` for raw output
