---
task_id: T-007
adapter: grok
model: grok-4.5
status: done
mode: background
phase: done
task_type: code-review-adversarial
review_object: /Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v3.md
vendor: grok
last_progress: Task completed successfully.
terminal_event_emitted: true
end_time: "2026-07-21T08:56:33.614Z"
exit_code: 0
signal: null
timed_out: null
duration_ms: 168222
adapter_status: success
---

# T-007 — D1 KernelPort Spec v3 定向对抗复核（只读）

## Summary

对 `d1-kernelport-spec-v3.md`（715 行）做**定向**对抗复核：对照 `kernel-ecosystem-facts.md`、`d1-v2-review-dual-track.md`（含本轨 T-006 抓到的 openclaw `sessions.steer` 事实回退）与被 superseded 的 v2。结论：**§12 宣称的 6 处修复均真实落地**——openclaw 恢复原生 `sessions.steer` 直映射、cancel+resend 收窄仅 hermes、INV-5/`nextRunId` 死结溶解、审批超时权威/零 active run 保护/审批定序补齐、`protocolVersion` + F-05/F-11 诚实降级均对上。官方文档交叉核查后，`sessions.steer`/`queueMode:steer` 的产品语义已**部分可确认**（注入 active run、不 abort 在途 tool、接受时不另起 run），但 RPC 参数/返回字段形状仍**未能确认**；v3 整体诚实，仅 INV-5 一处「无损」措辞略过硬。无新 BLOCKER 级文内互斥。**Verdict: PASS_WITH_NOTE**。

## Files touched

- `.hopper/handoffs/T-007-output.md`：本对抗复核交付物（只写此处；**未**改 `~/.llm-wiki/` 或任何源码/spec）。

## Acceptance verification (5/5)

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | 6 处修复是否真落对（§6.1/§6.1a/§6.2/§9.3/§10/§12；尤其 openclaw 原生 steer） | **通过** | Findings A1–A6；§5 L455 / §6.1 L466–481 / §8 L568–569 |
| 2 | openclaw `sessions.steer` 精确语义 web 核实 | **部分确认 + 部分未能确认** | Finding B1；官方 protocol/queue/steer/queue-steering |
| 3 | v3 新引入矛盾（steerResendRunId / 审批定序 / 零 active run） | **无 BLOCKER；2 处 NOTE** | Findings C1–C3 |
| 4 | 5 残留点严重性（blocker 前必解 vs defer） | **0 blocker-必解；5 均可 defer 或本轮已覆盖** | Findings D1–D5 |
| 5 | 事实基线一致性 / 无新「未能确认当已落地」 | **通过（1 处措辞过硬 NOTE）** | Finding E1–E2 |

机器可检：

```bash
test -f .hopper/handoffs/T-007-output.md
wc -l /Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v3.md   # 715
rg -n "sessions\.steer|steerResendRunId|steer_in_progress|timeoutAuthority|protocolVersion|steerNative|nextRunId" \
  /Users/litianyi/.llm-wiki/agent-app-design/kernel/d1-kernelport-spec-v3.md | head -40
rg -n "^(## Summary|## Files touched|## Acceptance|## Decisions|## Open questions|## Verdict|## Next|### A|### B|### C|### D|### E)" \
  .hopper/handoffs/T-007-output.md
```

## Decisions / deviations

- 行号以 `d1-kernelport-spec-v3.md` 当前 715 行文本为准。
- web-search/open_page 仅用于核实 openclaw 官方文档；**不写回** `~/.llm-wiki/`。
- 定向任务：不重审 v2 已稳的 F-02/F-03/F-09/F-10/F-14/scope 收窄等，只盯 6 处修复 + 新矛盾 + 残留严重性 + 事实纪律。
- 假定：`sessions.steer` 与 `chat.send(queueMode:'steer')` / `/steer` / queue-mode steer 属同一产品语义族（协议文案将前者标为 interrupt-and-steer variant）；精确 RPC schema 仍以「未能确认」处理。

## Open questions

1. `sessions.steer` RPC 请求体是否接受 `runId`/`key` 及返回 payload 字段名？（协议页仅一句话，无 schema 表。）
2. 适配器在 openclaw 上若 `sessions.steer` 因 runtime 拒收而退化为 followup，是否应合成 `degraded` 或 ErrorEvent？（v3 未定义该边角。）
3. hermes 审批定序步骤①「确认 deny 已生效」失败时：阻塞 abort 还是 fail-closed 推进？（§6.2 未钉失败路径。）

---

# Findings（定向对抗正文）

## A. 6 处修复是否真落对

### A1. 修复① openclaw 恢复原生 `sessions.steer`；cancel+resend 仅 hermes — **已落地**

| 检查点 | v2（错误） | v3 | 判定 |
|--------|------------|-----|------|
| openclaw interrupt 映射 | §5 仅 abort；§6.1 走 cancel+resend；§8「无原生保留产出」 | §5 L455：`mode:'steer'→**原生 sessions.steer**`；§6.1 L468 一次原生 RPC；§8 L568 ✅ 原生 steer | **真改** |
| hermes | cancel+resend | 仍 cancel+resend，`steerNative:false`，必带 `degraded`（§6.1 L472–477、§8 L569） | **收窄正确** |
| caps | 两内核 `interruptModes` 仅 `cancel` | 均含 `steer` + `steerNative` 区分质量（§4.1 L413–420、§6.1 L481） | **真改** |
| INV-5 叙述 | openclaw 也 cancel+resend | openclaw 直映射、不产生 `degraded`（§1 L63–65） | **真改** |

对照事实基线：`kernel-ecosystem-facts.md` §1 L42 列出 `sessions.steer（打断并转向）`；v3 与之对齐，不再静默否定。官方 `docs.openclaw.ai/gateway/protocol` 亦明文：`sessions.steer is the interrupt-and-steer variant for an active session`。

### A2. 修复② 溶解 INV-5 / F-07 三处互斥 — **已落地**

v2 互斥结构：§2.4/§4/§9.1「caps 无 steer → must reject」vs §6.1「同一条件 → 内部降级」且两内核 caps 均无 steer。

v3 消解结构（§2.4 L193–199、§6.1 L481）：

- 两内核 `interruptModes` **均含** `steer` → scope 内 `mode:'steer'` **不会**走 `unsupported_interrupt_mode`；
- openclaw 原生 / hermes 适配器降级的分支在 §6.1，不在 reject 规则上打架；
- reject 规则保留为「未来无兜底内核」的一般条款，当前 scope 不适用。

§10 F-07 L651 标 **已消解（v3 更正）**，并诚实写明 v2 的「已消解」曾建立在事实回退上。**互斥前提已拆除，判真消解。**

### A3. 修复③ 溶解 `nextRunId` 时序；改 `steerResendRunId` — **已落地**

| 项 | v2 | v3 |
|----|----|----|
| `TurnCompleteEvent.degraded` | `{ kind, nextRunId }` 要求 turn_complete 时刻已知未来 runId | 仅 `{ kind: 'steer_via_cancel_resend' }`，移除 `nextRunId`（§3 L356–364） |
| 关联 | 事件预置 nextRunId | `interrupt()` 返回 `steerResendRunId?`；Promise 在内部 resend 的 `send()` 返回后 resolve（§2.4 L167–174、§6.1a L483–490） |
| 旁路消费者 | 无合法方案 | 靠 §9.3「steer 降级进行中」标记 + 其后首个新 `runId`（§6.1a L489） |

时序悖论（cancel 完成 → turn_complete → 才 send → 才有 runId）在字段层消除。**真消解。**

### A4. 修复④ 审批超时终态由内核信号驱动 — **已落地**

- §3 L331–335：`timeoutAuthority: 'documented' | 'best_effort'`
- §6.2 L510：`PENDING → TIMED_OUT_DENY` **必须**由内核 fail-closed 信号驱动；本地计时器仅辅助，**不得**单方终态化
- openclaw `'documented'` / hermes `'best_effort'` 与 facts §1a/§2a 一致

### A5. 修复⑤ 零 active run 竞态 + 审批定序 — **已落地**

- §9.3 L622：hermes cancel→resend 窗口标记「steer 降级进行中」；外部 `send`/`interrupt` → `steer_in_progress`（§9.1 L599–600）
- §9.3 L624：完成屏障失败路径（cancel 失败 / 等 turn_complete 超时 → ErrorEvent、清标记、不 resend、调用方必得结果）
- §6.2 L511：唯一顺序 ① `FORCE_DENIED_ON_STOP`+向内核 deny 并确认 → ② abort/cancel → ③（hermes steer）resend；`degraded` 与 `forceResolvedApprovals` 允许同现
- §11 #2 划掉为已解决（L681）

### A6. 修复⑥ `protocolVersion` + F-05/F-11 降级 — **已落地**

- §3 L264–270、§4.1 L399–400：`protocolVersion` 上事件与 capabilities
- §10 F-05 L649：**部分化解**（类型有 `updatedInput`，传输/执行层无 facts）
- §10 F-11 L655：**部分化解**（消费形状有，`server_override` 生产通道无）
- §10 S-09 L661：**部分化解**（字段有，协商流程无）
- §10 收口统计 L670–673 从「10 完全 + 1 部分」改为 **8 完全 + 3 部分（F 系）+ S-09 部分**，与 T-006/双轨综合清单一致

---

## B. openclaw `sessions.steer` 精确语义（web 核实）

### B1. 核实结论（相对 v3「诚实标注」§6.1 L470 / §11 #7）

| 问题 | 官方证据 | 结论 |
|------|----------|------|
| 是否存在 `sessions.steer` | protocol：「interrupt-and-steer variant for an active session」；与 facts L42 / T-003 一致 | **确认存在**（v3 映射正确） |
| 是否「打断并保留已产出再注入」 | **queue** 默认 `mode: steer`：「inject into the active runtime… so no second session run is started」；**queue-steering**：「Steering does **not** interrupt a tool call already running」；在 tool batch 结束后、下一 LLM 调用前 drain steering 消息并 append 为 user messages；**不可** accept 时 wait 至 run 结束再当 followup。**interrupt** 是另一 mode：abort active run 再跑最新消息 | **产品语义大体可确认：同 run 注入、不 abort 在途 tool、接受时不另起 run**——比 pure cancel+resend **更接近「保留产出+注入」**。协议标题用 interrupt-and-steer，实现上 **steer ≠ abort** |
| 显式 `runId` | protocol 对 `sessions.abort` 写清 key+optional runId；对 `sessions.steer` **未**给出参数表 | **未能确认** |
| 返回字段形状 | 公开 protocol 无 `sessions.steer` result schema；`talk.client.steer` 另有 accepted/rejected 结构，**不可**直接套用 | **未能确认** |

**对 v3 的评价**：

- 把精确语义标「未能确认」在 **RPC schema / runId / return** 维度仍正确；
- 但在 **产品行为** 维度，v3 仍把「是否保留已产出」整条标未能确认，**略偏保守**——本轮官方 queue/steer 文档已提供可引用的同 run 注入语义；
- **不得**据此把「未能确认」改写成「已落地无损契约」而不做定向 conformance（仍缺 RPC schema 与 edge：runtime 拒收 → followup）。

**建议写入下一版 facts/spec 的措辞方向**（本任务只建议、不改 wiki）：「openclaw steer = 尝试注入当前 active run（model boundary 后、不中断在途 tool）；accept 时无第二 run；不可 accept 时退化为 run 结束后的 followup。RPC 参数/返回值仍未能确认。」

---

## C. v3 是否新引入矛盾

### C1. `steerResendRunId` 关联 — **自洽（NOTE：旁路推导依赖）**

- 主路径：持有 `interrupt()` Promise 的调用方在 resolve 时拿到真实 `steerResendRunId`——与「send 返回后才有 runId」一致。
- 旁路：依赖 §9.3 标记期间无并发 send，故 `turn_complete(degraded)` 后首个新 runId = resend。在标记清除条件（resend 返回，含失败）下逻辑闭环。
- **NOTE**：resend 失败时无 `steerResendRunId`、有 ErrorEvent——正确；但旁路消费者若只看事件流、不看 ErrorEvent，可能误等「永远不来的下一 run」。属实现/文档消费约定，非文内互斥。

### C2. 审批定序 — **大体自洽（NOTE：① 失败路径未钉）**

① deny 本地终态 + 向内核 deny → ② 确认生效后 abort → ③ resend，与 exactly-once / 防「cancel 后内核仍接人工审批」目标一致；`forceResolvedApprovals` + `degraded` 同现允许（L511）。

**NOTE（非 BLOCKER）**：若步骤①「内核确认 deny」失败或超时，spec 未写是：阻塞 abort、强制本地终态后仍 abort、还是整次 interrupt 失败。实现可能分叉。建议 v3.x 补一行 fail-closed 默认（倾向：本地已 FORCE_DENIED + 尽力 deny RPC + 超时后仍 abort，避免卡死）。

### C3. 零 active run 窗口保护 — **自洽（NOTE：超时上限未量化）**

- 标记从「发起 ACP cancel」起至 resend `send()` 返回，**宽于**「cancel 已完成且尚无 active run」的纯窗口，偏安全。
- 仅 hermes；openclaw 原生 steer 无此窗口（L622）。
- 完成屏障有失败路径（L624），修复了 T-006「无限悬挂」点。
- **NOTE**：超时为「适配器内部合理上限」——无数字、无与 hermes 审批 ~60s / transport 超时的关系；**defer 到实现 profile**，不阻 draft 定稿。

### C4. 文内轻微措辞张力（非结构互斥）

| 位置 | 表述 | 张力 |
|------|------|------|
| §1 INV-5 L63 | openclaw「**无损**转向路径」 | 与同节 L66「openclaw 原生 steer 是否也有类似损耗仍是未闭合事实缺口」及 §6.1 诚实标注并列 |
| §4.1 L417 | `steerNative:true` =「**原生保留产出**」 | 同上；且官方确认：不可 accept 时退化为 followup，非绝对无损 |

**判定**：不构成 v2 式 reject/降级互斥；属**过硬形容词**，建议改为「原生路径 / 非 cancel+resend 合成」并保留体验差异 TBD。

### C5. §10 统计口径

L671 写「已消解（含部分）仍为 11 条」同时 L673 又解释 S-09 会把部分桶扩到 12——作者自洽说明，**不是隐蔽错误**。

---

## D. 5 残留点严重性

| # | 残留 | 严重性 | 理由 |
|---|------|--------|------|
| D1 | openclaw steer 精确语义 | **DEFER（实现前建议 conformance；非 confirmed 阻塞项中的硬 BLOCKER）** | 存在性与产品级 inject 语义已足够支撑「直映射 sessions.steer」设计；runId/返回/拒收边角在实现 spike 收口即可。v3 已诚实标注，**未**再犯「未能确认当已落地」 |
| D2 | `server_override` 生产通道 | **DEFER** | F-11 已降为部分化解；属 P7/Server 侧，不阻塞 KernelPort 消费形状 |
| D3 | 完成屏障超时上限 | **DEFER** | 有失败路径与「不得无限悬挂」；缺数字属实现配置，非契约互斥 |
| D4 | `protocolVersion` 无协商流程 | **DEFER** | S-09 部分化解正确；字段治理起点够用，完整协商可后轮 |
| D5 | v3 未经独立复核 | **本任务（T-007）即覆盖** | 再跑异构第二轨仍建议（双轨纪律），但**不应**因「尚未双轨」单独判 REWORK——本轨已 PASS_WITH_NOTE 级收口 |

**无「blocker 前必解」残留。** 上一轮 T-006 三处 BLOCKER（INV-5 互斥 / nextRunId / 事实回退）在 v3 均已消解。

---

## E. 事实基线一致性

### E1. 无新的「未能确认当已落地」

- openclaw `sessions.steer`：**已确认存在** → 映射为原生，正确。
- 精确参数/返回/是否绝对无损：**未能确认** → §5 已知缺口、§6.1 诚实标注、§8 ❓、§11 #7 均保留，**未**写死 schema。
- hermes 无原生 steer、ACP cancel session 级、审批 fail-closed、newapi 非 run 级等与 facts 一致。
- F-05 `updatedInput` 传输层、F-11 生产通道、newapi correlation id：继续标部分/未能确认。

### E2. 相对 facts 的唯一表述风险

facts L42「打断并转向」+ 协议「interrupt-and-steer」容易让读者以为 steer=abort。官方 queue 明确 **steer 不 abort 在途 tool**；**abort 是 interrupt mode**。v3 沿用「打断并转向」词汇与 facts 一致，但实现映射时勿把 `sessions.steer` 做成 abort+send。§6.1 已写「不经 cancel+resend」，方向正确。

---

## Verdict

**PASS_WITH_NOTE**

- **PASS 依据**：T-006 三处 BLOCKER 与双轨综合 6 条修复清单在 v3 正文中均真实、可定位落地；cancel+resend 仅 hermes；事实纪律恢复；无新结构性互斥。
- **WITH_NOTE 依据**：(1) INV-5「无损」与诚实标注轻微过硬；(2) steer RPC schema/runId/返回仍未能确认，但产品级 inject 语义本轮可部分确认，建议下一轮 conformance 收紧措辞而非再改架构；(3) 审批定序①失败路径、完成屏障超时数值、`server_override` 生产通道、protocol 协商均为 defer 级。

不判 REWORK：局部修订目标达成，无需推倒。  
不判 PASS（无 note）：「无损」与 RPC 缺口仍值得在 v3→confirmed 前小修措辞/补 spike。

## Next recommendation

1. **小修措辞（可选、低成本）**：§1 L63「无损」→「原生路径（非 cancel+resend 合成）」；§4.1 `steerNative:true` 注释与 §6.1 诚实标注对齐，引用 queue 文档的 inject / 不 abort tool / 不可 accept 则 followup。
2. **定向 conformance（建议，非架构重开）**：抓 `sessions.steer` 请求/响应 schema（或 gateway-protocol schema 包）、是否支持 `runId`、runtime 拒收时客户端可见行为；结果写回 `kernel-ecosystem-facts` 后再决定是否升级 `design_status: confirmed`。
3. **实现 profile 收口**：hermes 完成屏障超时默认值；审批定序① deny 确认失败的 fail-closed 默认；`server_override` 推送形状（可并行 P7）。
4. **状态流程**：可将 v3 维持 `draft` 直至 (2) 完成或明确接受「RPC schema TBD」风险；**不**建议因本复核 note 再开大改 v4。
5. **双轨纪律**：若要 `confirmed`，建议再跑一轮**异构**第二轨（vendor 轮换）；本 T-007 可作第三方轨 closure 之一。

---

## 对照速查：T-006 BLOCKER → v3

| T-006 | v3 结果 |
|-------|---------|
| BLOCKER：INV-5 reject vs 降级互斥 | **消解**（A2） |
| BLOCKER：`nextRunId` 时序不可实现 | **消解**（A3） |
| BLOCKER：openclaw `sessions.steer` 事实回退 | **消解**（A1）；精确语义 **部分确认+部分未能确认**（B1） |
| HIGH：审批状态机未闭合 | **显著收紧**（A4/A5）；①失败路径 NOTE（C2） |
| HIGH：`server_override` 无通道 | **诚实降级为部分化解**（A6），DEFER（D2） |

## Vendor output (parsed)

```
hopper-runner: idle watchdog disabled (bufferedOutput vendor) — ceiling-only timeout applies (1800000ms)
{
  "text": "I'll execute the adversarial review of D1 KernelPort v3 myself: load the review frame, the v3/v2/facts docs, and verify openclaw `sessions.steer` against the web.Next I'll verify `sessions.steer` against official docs and cross-check the six v3 fixes for consistency.I have enough evidence to write the adversarial review deliverable.## T-007 完成\n\n交付物：`.hopper/handoffs/T-007-output.md`（只读复核，未改 `~/.llm-wiki/`）\n\n### Verdict: **PASS_WITH_NOTE**\n\n**6 处修复均真落地**\n1. openclaw → 原生 `sessions.steer`；cancel+resend **仅 hermes**\n2. INV-5 / F-07 互斥前提拆除\n3. `nextRunId` 移除 → `steerResendRunId`（interrupt 返回值）\n4. `timeoutAuthority` + 超时终态由内核信号驱动\n5. `steer_in_progress` + 完成屏障失败路径 + 审批 ①deny→②abort→③resend\n6. `protocolVersion`；F-05/F-11/S-09 诚实降为部分化解\n\n**openclaw steer 语义（web）**\n| 项 | 结论 |\n|---|---|\n| 存在性 | 确认（protocol + facts） |\n| 保留产出并注入 | **产品级可部分确认**：inject active run、不 abort 在途 tool、accept 时不另起 run |\n| 显式 runId / 返回字段 | **未能确认** |\n\n**新矛盾**：无 BLOCKER；NOTE 为 INV-5「无损」略过硬、审批①失败路径、完成屏障超时未量化。\n\n**5 残留**：均可 DEFER；无「blocker 前必解」。\n\n**Next**：可选小修「无损」措辞；定向 conformance 收 RPC schema；再跑异构第二轨后再升 `confirmed`。",
  "stopReason": "EndTurn",
  "sessionId": "019f83e1-9944-7da3-9c60-88f86d8dc01a",
  "requestId": "ae6bb1ac-3054-4f2e-b396-ad4bb08dda2e",
  "thought": "The user wants me to perform an adversarial code review of a D1 KernelPort v3 specification document. This is a code-review-adversarial task where I need to:\nI have the main documents. Now I need to:Let me dig deeper into the official docs for sessions.steer semantics - specifically whether it preserves output and accepts runId.I got very useful information from the official docs. Let me dig more into the sessions.steer RPC parameters and return shape. The protocol docs say:\n**Summary**  \nI performed an adversarial read-only review of the D1 KernelPort v3 spec (§6.1/6.1a/6.2/§9.3/§10/§12) against the v2 baseline and kernel-ecosystem-facts.md. I verified the six targeted fixes ①–⑥, cross-checked openclaw sessions.steer semantics via official queue docs, and assessed new contradictions in steerResendRunId, approval sequencing, and zero-active-run protection. No edits were made.\n\n**Files touched**  \n- /Users/litianyi/.llm-wiki/agent-app-design/kernel/d 1-kernelport-spec-v3.md (read-only review)\n\n**Acceptance verification (N/N)**  \n1. 6 fixes land correctly: confirmed openclaw steerNative now maps to native sessions.steer (cancel+resend narrowed to hermes only); steerResendRunId uses interrupt return value; approval timeout driven by kernel signal; zero-active-run window + approval ordering preserved.  \n2. openclaw sessions.There's already a T-007-output.md placeholder. I need to write the full adversarial review output there. The task says to write to `.hopper/handoffs/T-007-output.md`. Writing the output file is the de...**Summary**  \nI performed an adversarial read-only review of the D1 KernelPort v3 spec (§6.1/6.1a/6.2/9.3/10/12) against the v2 baseline and ecosystem facts. I verified the six targeted fixes, cross-checked openclaw sessions.st steer semantics via official queue docs, and assessed new contradictions plus residual severity. All six fixes land correctly; steer semantics are partially confirmed at product level but still marked “未能确认” in v3; no new contradictions introduced; five residuals are deferrable. Verdict PASS_WITH_NOTE.\n\n**Files touched**  \n.I'll write the full T-007 output in the same style as T-006.The deliverable is written. Let me do a quick verification that the file structure is complete.The deliverable is complete. I should give a concise summary to the user/dispatcher as the final response.",
  "usage": {
    "input_tokens": 109010,
    "cache_read_input_tokens": 591744,
    "output_tokens": 9146,
    "reasoning_tokens": 8129,
    "total_tokens": 709900
  },
  "num_turns": 8,
  "total_cost_usd": 0.4704192,
  "total_cost_usd_ticks": 4704192000,
  "modelUsage": {
    "grok-4.5-build": {
      "inputTokens": 109010,
      "outputTokens": 9146,
      "cacheReadInputTokens": 591744,
      "modelCalls": 8,
      "costUSD": 0.4704192
    }
  }
}
```

## Status (background completion)
- queue_status: done
- adapter_status: success
- exit_code: 0
- duration_ms: 168222
- end_time: 2026-07-21T08:56:33.614Z
- log: see `T-007-output.log` for raw output
