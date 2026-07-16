# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0005
- Issue class: packaging-gap
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-fable-5 (P0 fix group C, background session)
- Created at: 2026-07-16

## Redaction Boundary

- Secrets removed: yes — all example values in this issue are synthetic placeholders (`supersecret-token-value`, `super-secret-token-AKIA123`, etc.) generated during self-test, never real credentials
- Private data removed: n/a
- Raw logs omitted: only relevant JSON output snippets kept, full stdout not pasted
- Safe evidence summaries only: yes

## Context

- Active goal path: n/a (framework self-audit / adversarial review follow-up, not a project goal round)
- Active round path: n/a
- State files: n/a — this is a submodule (`harnessloop/`) code fix, not a `.harnessloop/` protocol-state change
- Related handoffs: P0 fix group C task brief (channel_params.py hardening, 5 confirmed findings from adversarial re-review of harnessloop-secrets)
- Related evidence: self-test transcripts in `/private/tmp/.../scratchpad/fx-*` (permissions, corruption/recovery, repeat-add, set→add conversion, audit git-tracking + example scan)
- Related reviews: adversarial-review-p0.md (upstream repo), corrected-severity findings in `p0-groups.json` key "C" (5 CONFIRMED findings, severities corrected to medium/low by reviewer)

## Expected Harnessloop Behavior

`channel_params.py` is documented (SKILL.md Safety Rules) as the mechanical guarantor that channel secrets are: (a) never printed, (b) never committed, (c) tracked with accurate sensitivity/storage metadata across repeated `add` calls, and (d) protected by a working `.gitignore`/audit story. The tool's own local JSON store should follow ordinary local-secret-file hygiene (owner-only permissions, atomic writes, recoverable from corruption) since it is the one file in the protocol allowed to hold plaintext values.

## Actual Harnessloop Behavior

Five confirmed defects in `plugins/harnessloop/skills/harnessloop-secrets/scripts/channel_params.py` (pre-fix state), all reproduced locally:

1. **Permissions/atomicity/corruption (was line ~78-80, `write_json`)**: the store was written via `Path.write_text()` — default-umask permissions (0644, world-readable on multi-user hosts) and non-atomic (truncate-then-write, so an interrupted write left valid-looking-but-truncated JSON). Once corrupted, `read_json` raised a bare `SystemExit` with only the JSON parser's error text, and `cmd_init` also called `read_json` first — so `init`, `check`, `add`, `set`, and `audit` all crashed with no recovery path.
2. **Repeat-`add` metadata reset (was line ~212-214)**: `cmd_add` built the parameter dict directly from `args.sensitivity`/`args.storage`, whose argparse defaults were the literal string `"unknown"`. A second `add` call that only wanted to append a `--required-for` value silently reset a previously-declared `sensitivity: secret` / `storage: env` back to `unknown`, re-blocking a resolved parameter and discarding its classification.
3. **`set` → `add` conversion residue (was line ~217, ~213)**: converting a parameter from a locally-set plaintext value (`set --value-stdin`) to an env/reference-backed one (`add --storage env`) unconditionally carried the old `"value"` forward into the JSON (`existing.get("value")`) regardless of the new storage, and (compounding with #2) silently downgraded `sensitivity` to `unknown` in the same call — so a real secret value stayed at rest in `channel-params.json` under a storage type that `audit` did not scan for values, with no signal to the user that anything had changed.
4. **Audit blind spots (was `cmd_audit`, line ~443-472)**: the only protection check was a text-line membership test on `.gitignore`. A store that was `git add -f`'d (or committed before the `.gitignore` existed) stayed reported as `gitignore_protects_store: true, findings: [], exit_code: 0` forever, regardless of actual git tracking state. `channel-params.example.json` — a file meant to be committed with `null` placeholders — was never scanned, so a user pasting a real value into the example would go undetected.
5. **`DEFAULT_IGNORE_LINES` drift (line 18-25, now 20-33)**: the script's embedded ignore-list (6 entries) had drifted from `references/local-gitignore-template.txt` (7 entries, includes `cost-marker.json`) used by `init_project.py`. Whenever `channel_params.py init` ran before `init_project.py` (a supported order per SKILL.md, since `init_project.py` skips files that already exist), the resulting `.gitignore` never gained the `cost-marker.json` line, so `round_cost.py`'s marker file (containing session transcript filenames/UUIDs) could be committed by a later `git add -A`.

## Minimal Reproduction From Files

1. Read: `plugins/harnessloop/skills/harnessloop-secrets/scripts/channel_params.py` (pre-fix), functions `write_json`, `read_json`, `cmd_init`, `cmd_add`, `cmd_audit`, and constant `DEFAULT_IGNORE_LINES`.
2. Observe (pre-fix, reproduced in scratchpad fixtures): `init` + `set` → store mode `0644` with plaintext `value`; truncating the JSON mid-file → every subcommand including `init` exits non-zero with only a bare parser error, no recovery command; two `add` calls on the same key with the second omitting `--sensitivity/--storage` → both fields reset to `"unknown"` in the stored JSON; `set` then `add --storage env` → `value` field still present in JSON and `audit`'s `local_value_count` reports `0`/`findings: []`/`exit_code: 0` for it; `git init` + `git add -f` + commit the store → `audit` still reports `gitignore_protects_store: true, findings: [], exit_code: 0`.
3. Expected next protocol action: the mechanical secrets manager either enforces its documented guarantees automatically, or fails loudly with a recovery path — never silently degrades metadata or reports "protected" when it is not.
4. Actual next protocol action (pre-fix): silent metadata downgrade on repeat `add`, silent plaintext residue after storage conversion, false-positive "protected" audit result, and total lockout (all subcommands) on a torn write with no rebuild path.

## Attempted Local Mitigation

- Evidence refresh: n/a
- Scope narrowing: fix scoped to a single file (`channel_params.py`) per task brief; SKILL.md's separate hardcoded-script-path packaging defect (group A findings) intentionally left untouched
- Contract revision: n/a
- Handoff change: n/a
- Rollback: not needed — all changes additive/corrective, existing CLI surface and exit-code semantics (`exit 2` = blocked/missing) preserved and re-verified against `scripts/validate.py`'s existing secrets-smoke assertions (replicated manually, not via full `npm run validate`, per task constraint)
- Human confirmation: not required for this pass (mechanical script fix); flagged in Resolution below for upstream review

## Suggested Upstream Improvement

- Candidate target: main skill (harnessloop-secrets script) — already applied in this submodule checkout
- Proposed smallest change (as implemented):
  1. `write_json`: write to a same-directory temp file via `os.open(..., 0o600)`, then `os.replace()` for atomic rename; defensive `os.chmod(path, 0o600)` after. `read_json` now emits an actionable recovery hint (back up + `init --force`) instead of a bare parser error. `cmd_init` gained a `--force` flag: on a corrupted/invalid store it renames the corrupt file aside to `<name>.corrupt-<UTC-timestamp>` and rebuilds an empty store, reporting `recovered_from_corrupt_store` in its JSON output.
  2. `cmd_add`: `--sensitivity`/`--storage` argparse defaults changed from `"unknown"` to `None`; resolved value is `args.X or existing.get("X", "unknown")` (mirrors the pattern already used by `cmd_set`). Fixing this surfaced a second latent bug in the same line (env name defaulting to the key name whenever resolved storage was `"env"`, previously masked because storage always reset to `"unknown"` first) — also fixed: env name now resolves as `args.env or existing.get("env") or (args.key if storage == "env" else None)`.
  3. `cmd_add`: `value` is now `existing.get("value") if storage == "local-file" else None` — any storage conversion away from `local-file` clears the stored plaintext. A new `notices` field in the `add` JSON output announces the clear (`"Cleared the previously stored local value for <channel>.<key> because storage changed to '<storage>'..."`).
  4. `cmd_audit`: added `audit_git_tracking()` (runs `git rev-parse --is-inside-work-tree` then `git ls-files --error-unmatch <store>`; any tracked result is a finding regardless of `.gitignore` text; gracefully returns a `"skipped (...)"` status with no finding when there is no `.git` or no `git` executable) and `audit_example_file()` (parses `channel-params.example.json`, flags any non-null `value`). `local_value_count` redefined to count *all* non-empty values (previously only `storage == "local-file"` ones), with a new finding raised for each non-local-file key still holding a value (defense-in-depth catching both the fixed conversion path and any pre-existing/manually-edited residue).
  5. `DEFAULT_IGNORE_LINES` updated to match `references/local-gitignore-template.txt` exactly (added `cost-marker.json`, matched ordering). Decision: kept as a literal list (not read from the template file at runtime) because `channel_params.py` lives in a different skill directory (`harnessloop-secrets`) than the template (`harnessloop-loop/references/`), and relying on that cross-skill relative path was judged more fragile than a hand-synced literal list, given the packaging fragility already flagged in the group-A findings about cross-skill path assumptions. Added a code comment pointing at the authoritative template so future edits know to sync both.
- Why this generalizes beyond this project: any project using `harnessloop-secrets` on a multi-user machine, hitting an interrupted write (disk full, process killed), doing incremental `add` calls to build up channel declarations, or converting a locally-set value to an env-var reference is exposed to these same failure modes — none of them require an unusual setup.
- Risks of overfitting: low. All fixes use only Python 3.9-compatible stdlib APIs (`os.open`/`os.fdopen`/`os.replace`/`Path.unlink(missing_ok=True)`, all available since 3.8); `subprocess` calls to `git` degrade gracefully by design when git is absent or the directory isn't a repo, so no new hard dependency is introduced.

## Resolution

- Resolution status: fixed in this submodule checkout (`harnessloop/plugins/harnessloop/skills/harnessloop-secrets/scripts/channel_params.py`); **not yet pushed upstream** to surebeli/harnessloop
- Upstream change: pending — this is a local submodule edit only, per task instructions (no commit/push performed)
- Backported to local policy: yes (the fix *is* the backport — this repository consumes the submodule directly)
- Backport path: `harnessloop/plugins/harnessloop/skills/harnessloop-secrets/scripts/channel_params.py`
- Follow-up required:
  - No file-level advisory lock was added for concurrent `read-modify-write` races (two simultaneous CLI invocations can still lose one writer's update — last-writer-wins). Out of scope for the 5 confirmed findings but worth a future look if multi-agent concurrent secret writes become a real usage pattern.
  - `scripts/validate.py`'s secrets smoke test (stage 3) was deliberately left unmodified — its existing assertions were manually replicated against the fixed script and all passed, so no smoke-test edit was needed for compatibility. A follow-up could add explicit fixtures for repeat-add preservation, set→add clearing, corrupted-store recovery, and the new audit checks (git-tracked store, example-file scan) to lock in this behavior going forward.
  - `harnessloop-secrets/SKILL.md`'s hardcoded repo-relative script invocation paths (a separate, already-identified group-A packaging defect) were intentionally not touched by this fix and remain open.

### Post-review corrections (same-topic leakage surfaces found on re-review, before commit)

A subsequent review of this same fix caught three leakage surfaces the first pass introduced or left uncovered — all in the same "plaintext-at-rest" theme as findings #1 and #3 above, all corrected in the same uncommitted working tree:

1. **Temp-file name not covered by any ignore pattern**: `write_json`'s atomic-write temp file was named `.channel-params.json.tmp-<pid>` (leading dot). None of `DEFAULT_IGNORE_LINES`' patterns match a leading-dot name (`channel-params.json` is an exact match only). A `SIGKILL`/power-loss during a write left this temp file — containing a full plaintext copy of the store — on disk, un-ignored, so a later `git add .`/`git add -A` would stage it. Fixed: dropped the leading dot (`channel-params.json.tmp-<pid>`, no functional change to the atomic-rename logic — same directory, same `os.replace` target) so it falls under the new glob pattern in fix #2.
2. **`.corrupt-<timestamp>` and suggested `.bak` backups not ignored**: `backup_corrupt_store`'s `channel-params.json.corrupt-<UTC-timestamp>` (which can carry partially-intact plaintext from a corrupted store) and the `.bak` filename suggested in `RECOVERY_HINT`'s recovery instructions were both un-ignored for the same "no glob, only exact match" reason. Fixed by adding one line, `channel-params.json.*`, positioned directly after the exact `channel-params.json` line, in **both** places per the manual-sync contract already documented in the code comment: `DEFAULT_IGNORE_LINES` in `channel_params.py`, and the authoritative `references/local-gitignore-template.txt` in `harnessloop-loop`. Verified via `git check-ignore` that this one pattern covers all three artifact classes (tmp, corrupt-backup, .bak) without matching the real store name itself. `scripts/validate.py`'s stage-3 check only asserts the substring `"channel-params.json"` appears in the gitignore text, so this is a pure addition — confirmed not to require any `validate.py` change.
3. **Corrupt backup inherited the pre-hardening store's 0644 mode**: `backup_corrupt_store` uses `os.replace()` to rename the corrupt store aside, which preserves the source file's mode bits rather than resetting them — so a store created before this hardening pass (still 0644) would produce a world-readable `.corrupt-*` backup even after the hardening fix. Fixed: added a best-effort `os.chmod(backup, 0o600)` (wrapped in `try/except OSError: pass`, consistent with the same pattern already used elsewhere in the file) immediately after the rename.

All three re-verified in scratchpad fixtures: an orphaned tmp file and a `.corrupt-*` backup are both reported as ignored by `git check-ignore -v`, the backup is `-rw-------` (0600) even when derived from a 0644 source, and `git add -A` in a fixture repo stages only `.gitignore` and `channel-params.example.json` (the two files meant to be committed) — never the store, its temp file, or its corrupt backup.
