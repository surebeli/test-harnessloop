# Hopper Cost Log

Append one row per dispatch. `hopper-dispatch --write` prints a suggested row.

| Date | Task | Task-type | Vendor | Tokens | $ | Wall | Notes |
|------|------|-----------|--------|--------|---|------|-------|
| 2026-07-17 | T-001 | code-review-adversarial | codex | 0 | n/a | 6.9s | 首派失败：vendor 默认模型 gpt-5.6-sol 超出本机 codex CLI 版本，400；计费不明按 0 记 |
| 2026-07-17 | T-001 | code-review-adversarial | codex/gpt-5.5/xhigh | 107,893 | n/a | 299.8s | 重派 `--model gpt-5.5` 成功；结果=REWORK，3 findings（2 confirmed by independent repro） |
