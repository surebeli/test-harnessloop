# Cost And Context Policy

## Main Session

Responsibilities:

- Orchestration: 编排、goal 解释、scope-lock 制定、只读审查、轮次验收（模型 claude-fable-5，ultracode/xhigh）
- Core decisions: goal 解释、breakdown 审批、scope-lock 变更、轮次验收
- Final acceptance: main session（claude-fable-5，ultracode/xhigh）执行轮次验收；评审失败后的接受仅用户

Must not spend context on:

- Large raw logs: 原始 diff/日志走文件与 handoff，主会话只读必要部分
- Full external reports: 子代理返回结构化摘要+文件路径，而非完整报告全文
- Repeated source dumps: 主会话只读必要部分，不重复摘录源文件全文

## Delegation Rules

Use subagent or swarm for:

- Read-only discovery: 只读发现可用 Workflow 多 agent 并行
- Evidence collection: TODO (owner: user)
- Low-context execution: 一切写入类任务（代码/文档）由 claude-sonnet-5 子代理执行（用户 2026-07-16 指定的强制分工）
- Adversarial review: 独立子代理（sonnet 或 inherit）执行；只读对抗审查可用 Workflow 多 agent 并行
- Acceptance testing: TODO (owner: user)

Do not delegate:

- Goal interpretation: 不可委派
- Goal breakdown approval: 不可委派
- Scope-lock changes: 不可委派
- Human-required product or business decisions: 不可委派
- Acceptance after failed review: 不可委派，仅用户确认
- 轮次验收: 不可委派（协议附加项，与上述并列）

## Execution Delegation Matrix

| Task type | Delegation decision | Goal | Value | Preconditions | Never delegate when |
| --- | --- | --- | --- | --- | --- |
| Read-only discovery | should delegate |  |  | Workflow 多 agent 并行可用 |  |
| Evidence collection | delegate when bounded and read-only |  |  |  |  |
| External connectivity check | main gate or `$harnessloop-connectivity` |  |  |  |  |
| Low-risk local implementation | may delegate |  |  | 一切写入类任务由 claude-sonnet-5 子代理执行（强制分工） |  |
| High-risk or cross-cutting implementation | main session owns; delegate narrow subtasks only |  |  |  |  |
| Adversarial review | must delegate when verifiable |  |  | 独立子代理（sonnet 或 inherit），或 Workflow 多 agent 并行 |  |
| Acceptance testing | should delegate when independent |  |  |  |  |
| Round acceptance and control decisions | never delegate |  |  |  | 轮次验收、评审失败后接受均需 main session/用户 |

## Model Policy

Codex:

- Independent investigation: 不适用（本次 model policy 未涉及 Codex，见 state/environment.md，检测环境=claude-code）
- Low-context execution: 不适用
- Adversarial review: 不适用
- Core decisions: 不适用

Claude Code:

- Independent investigation: discovery=Workflow agents（只读）
- Low-context execution: write-implementation=claude-sonnet-5
- Adversarial review: 独立子代理（sonnet 或 inherit）
- Core decisions: main=claude-fable-5（ultracode/xhigh）

## Handoff Budget Rules

Input limit: TODO (owner: user)

Output limit: TODO (owner: user)

Evidence path requirement: 子代理返回结构化摘要+文件路径

Summary requirement: 结构化摘要（非原始日志/diff 全文）

Context that must stay out of main session: 原始 diff/日志（走文件与 handoff，主会话只读必要部分）

Session budget note: 本会话无硬性 token 上限（ultracode）；每轮收盘跑 round_cost.py 记账留痕。
