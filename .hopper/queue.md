# Hopper Queue

Anchor: `.hopper/queue.md::root`

- **Schema version**: 2 (Task-type column is the primary routing key)
- **Task spec source**: `.hopper/handoffs/leader-tasklist.md` (one section per task ID)
- **Status values**: `pending` / `in-progress` / `done` / `failed` / `removed`
- **Vendor routing**: each Task-type has a default vendor in `.hopper/AGENTS.md`;
  a row may override it via the optional `Vendor` column.

---

## Tasks

| ID | Task-type | Status | Depends | Priority | Brief | Vendor |
|----|-----------|--------|---------|----------|-------|--------|
| T-001 | code-review-adversarial | pending | | normal | 对 harnessloop submodule commit 6936fbc（setup wizard 完整实现：新 skill+check_setup.py+profiles+四 SKILL 接线+validate 第 3 阶段）做只读对抗评审 | codex |

---

## Activity log

- queue initialized by `hopper-dispatch --init-tasks`
- 2026-07-17: T-001 added (code-review-adversarial, vendor=codex — 随机结果，见 .hopper/AGENTS.md 的随机机制说明；用户决策 2026-07-17）。Full spec in handoffs/leader-tasklist.md#T-001。
