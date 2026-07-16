# Feedback Policy

## Feedback Classes

Positive:

- Expected behavior: 验收标准（见 goal.md Acceptance Criteria）全部满足，无新证据缺口
- Required evidence: 各验收标准对应的验证方法产出（见 thresholds.md Verification Thresholds）
- Next action: 归档进下一子目标（按 goal-breakdown.md 的 S1→S2→S3→S4 顺序推进）

Negative:

- Execution-fault checks: 先查本轮执行（本轮改动/脚本/委派是否有误）
- Goal/business-fault checks: 再查契约（goal.md/thresholds.md/data-contract.md 是否本身有缺陷）
- Default priority: 先排查执行故障，后排查契约故障

Neutral:

- Why evidence may be inconclusive: TODO (owner: user)
- Treat as negative until: 证据被证实为 conclusive 之前，按 negative 处理

## Negative Feedback Actions

Allowed next actions:

- continue-investigation
- minimal-fix
- rollback-prior-execution
- revise-contract-with-human-confirmation
- blocked-human-decision

## Blocked Feedback Actions

Classify before stopping:

- runtime-recoverable: enter read-only investigation or recovery-planning round.
- access-missing: ask for missing endpoint, credential reference, local parameter, permission, account role, or tool.
- write-safety-required: ask for dry-run, test resource, rollback path, and human confirmation before mutation.
- human-decision-required: ask for product, business, risk, policy, acceptance, or cleanup decision.
- contract-insufficient: repair goal, threshold, evidence, or control contract.
- external-system-unsafe: allow only bounded observation until safety is established.
- unknown: ask for facts needed to classify.

## Round Decision Format

Feedback class:

Blocker type:

Recovery eligible:

Evidence paths:

Fault hypothesis:

Chosen next action:

Next scope-lock:
