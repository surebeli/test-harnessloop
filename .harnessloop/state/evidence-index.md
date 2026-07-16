# Evidence Index

| Evidence ID | Type | Path | Applies to | Freshness requirement | Observed timestamp | Validation method | Channel parameter references | Citation required | Artifact health | Claim support | Acceptance effect | Reproducibility | Sensitivity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| E1 | static | docs/harnessloop-review-20260716.md | goal 20260716-001-setup-wizard 需求依据（P1 #5/#6 guided-setup/auto-detection lens） | 冻结基线 2026-07-16，不刷新——被新一轮审查取代时整体作废 | 2026-07-16 | 与 findings.json 的 JSON 结构比对 | 无 | yes | valid | supports | neutral | 可重现（本地文件读取） | internal |
| E2 | static | docs/harnessloop-review-20260716.findings.json | 同 E1，80 条确认发现的机器可读版本 | 冻结基线 2026-07-16，不刷新 | 2026-07-16 | JSON 结构校验 / 与 E1 比对 | 无 | yes | valid | supports | neutral | 可重现（本地文件读取） | internal |
| E3 | source | harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ | 格式权威，本 goal 所有新文件/skill 结构依据 | 随 submodule HEAD 刷新（当前 66093fd） | 2026-07-16 | git log + scripts/plugin-status.sh 内容级 diff | 无 | yes | valid | supports | pass | 可重现（git HEAD 固定，可重新 diff） | internal |
| E4 | runtime | npm run validate 输出（cwd=harnessloop/，命令输出非固定文件） | 全部 acceptance criteria 的 validate 断言 | 每次运行重新生成，不可复用旧输出 | TODO (owner: user)（本 goal 尚未运行） | 7/7 阶段全绿 | 无 | yes | missing | unknown | blocked | 可重现（命令可重跑） | internal |
| E5 | static | docs/validation-log.md（2026-07-16 P0 修复批次条目） | state/environment.md 与 state/self-check.md 的 delegation 自检依据 | 冻结（历史记录，特定批次的实证，不随后续批次自动刷新） | 2026-07-16 | 人工读取比对（记录内容与批次审查交互一致） | 无 | yes | valid | supports | pass | 可重现（文件常驻，可重读） | internal |

## Artifact Health Values

- `valid`: evidence exists, is fresh enough, and can be cited.
- `stale`: evidence exists but violates freshness or drift rules.
- `missing`: evidence path or source is absent.
- `inconclusive`: evidence exists but cannot support acceptance.
- `blocked`: evidence requires human access or external setup.

## Claim Support Values

- `supports`: supports the claim being tested.
- `refutes`: refutes the claim being tested.
- `partial`: supports only part of the claim.
- `unrelated`: valid artifact but not relevant to the claim.
- `unknown`: claim relationship has not been assessed.

## Acceptance Effect Values

- `pass`: contributes to accepting a round.
- `fail`: contributes to rejecting a round.
- `neutral`: cited but not decisive.
- `blocked`: cannot be evaluated without access or human action.

## Evidence Types

- static
- dynamic
- runtime
- source
- human-confirmation
