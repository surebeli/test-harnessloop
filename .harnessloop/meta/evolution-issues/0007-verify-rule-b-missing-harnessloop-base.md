# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0007
- Issue class: skill-gap
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-sonnet-5 subagent (independent fix task, orchestrated by claude-fable-5)
- Created at: 2026-07-16

分类说明：与 TH-0006 同一脚本、同一 Rule B，但根因不同——TH-0006 修的是"引用是否应被当作路径"（正则/glob/裸域名/占位符/显式豁免），本条修的是"被判定为路径后，用什么基准去解析"：`verify_round` 的 `citation_bases` 缺 `<project>/.harnessloop`，导致 `PATHISH_PREFIXES` 自己声明要校验的 6 个短前缀（`goals/`、`state/`、`setup/`、`meta/`、`evals/`、`intake/`）引用真实存在的文件时必然解析失败。这条缺陷在 `docs/harnessloop-review-20260716.findings.json` 中已被 scripts-correctness 视角的独立评审精确预测（见下），今天在本项目 round 0002 的对抗性评审中实战应验。

## Redaction Boundary

- Secrets removed: n/a（无涉密内容）
- Private data removed: n/a
- Raw logs omitted: n/a
- Safe evidence summaries only: yes

## Context

- Active goal path: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Active round path: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/
- State files: 本次修复不涉及项目状态文件写入，只涉及 harnessloop submodule 内脚本
- Related handoffs: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/handoffs/0002-02-review-adversarial-design-v2-open.md
- Related evidence: .harnessloop/goals/20260716-001-setup-wizard/rounds/0002/reviews/adversarial-review.md（被 verify_protocol.py 判定 6 条 dangling-citation，全部为误报，见 Actual Behavior）
- Related reviews: docs/harnessloop-review-20260716.findings.json 中 title 含"bases 缺 project/.harnessloop"的条目（lens: scripts-correctness，verdict: CONFIRMED，corrected_severity: medium）——本 issue 是该预测的实战应验记录，非独立新发现
- Related evolution issues: .harnessloop/meta/evolution-issues/0006-verify-protocol-pathish-false-positives.md（同一脚本 Rule B 的第一轮修复：正则/glob/裸域名/submodule/显式豁免；本条是同一轮修复任务的直接延续，第二批实战误报）

## Expected Harnessloop Behavior

`verify_protocol.py` 的 `PATHISH_PREFIXES`（:26-37，原行号）显式声明 `goals/`、`state/`、`setup/`、`meta/`、`evals/`、`intake/` 六个短前缀的引用需要做存在性校验——这意味着协议作者预期评审文件可以用这些短前缀直接引用 `.harnessloop/` 下的协议文件（如 `state/self-check.md`），Rule B 应当能正确解析并确认其存在，不阻断 positive 判定。

## Actual Harnessloop Behavior

`verify_round`（原 :108）的解析基准 `bases = [project, goal_dir, round_dir]`（Rule B 复用 TH-0006 修复后的 `citation_bases`，其时为 `bases + submodule_roots(project)`）没有一个覆盖 `<project>/.harnessloop/`——而 `state/`、`setup/` 等六个短前缀所指目录唯一的真实落点就是 `<project>/.harnessloop/state/`、`<project>/.harnessloop/setup/` 等。结果：round 0002 对抗性评审文件（`rounds/0002/reviews/adversarial-review.md`）里引用真实存在的 `setup/cost-context-policy.md`、`state/self-check.md`（×2）、`state/evidence-index.md`、`setup/data-sources.md` 全部被判 dangling-citation，外加一条 `goals/<id>/data-contract.md`（goal 级证据契约路径模板，含尖括号占位符 `<id>`，不是字面引用）也被误判——合计 6 条，`verify_protocol.py --project <本项目>` exit=1。经核实这 5 个 `.harnessloop/` 下的协议文件全部真实存在（`ls .harnessloop/setup/*.md .harnessloop/state/*.md` 确认），`<id>` 占位符路径本身在任何项目里都不会字面存在。

## Minimal Reproduction From Files

1. Read: `.harnessloop/goals/20260716-001-setup-wizard/rounds/0002/reviews/adversarial-review.md`（:21 E5 行、:74 self-check.md 引用、:78 evidence-index.md/data-sources.md/data-contract.md 引用）
2. Observe: 对该文件运行 `python3 harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop`（修复前）返回 exit=1，报告 6 条 dangling-citation：`setup/cost-context-policy.md`、`state/self-check.md`×2、`state/evidence-index.md`、`setup/data-sources.md`、`goals/<id>/data-contract.md`
3. Expected next protocol action: 5 条协议相对路径引用真实存在的 `.harnessloop/` 下文件，应通过；1 条占位符路径不应被当作字面引用
4. Actual next protocol action（修复前）：6 条全部报错；本轮评审自身结论是否受影响需另行核实，但机械门本身在合规引用下产生噪声，与 TH-0006 记录的"红灯变噪声"风险同源

## Attempted Local Mitigation

- Evidence refresh: 用本机项目实测（`ls .harnessloop/setup/*.md .harnessloop/state/*.md`）确认 5 个被误报的路径全部真实存在
- Scope narrowing: 仅修改 verify_protocol.py 的 `citation_bases`（Rule B）与 `pathish_citations` 的豁免规则，未改动 Rule A 的 `bases`
- Contract revision: 无
- Handoff change: 无
- Rollback: 无
- Human confirmation: 无需（有实测证据支撑的确定性修复，且修复方案与 findings.json 中的既有 suggestion 一致）

## Suggested Upstream Improvement

- Candidate target: main skill（harnessloop-loop 的 verify_protocol.py 脚本）
- Proposed smallest change（与 findings.json 原 suggestion 一致）：`verify_round` 内 `citation_bases` 增加 `project / '.harnessloop'`（只加给 Rule B 引用存在性检查，避免放宽 Rule A 的 scope-lock 判定）；另需为"引用含尖括号占位符"这类模板路径增加豁免（findings.json 原条目未覆盖此点，属本轮实战新增的第二个根因）。
- Why this generalizes beyond this project: 任何安装该插件的项目，评审/设计文档但凡用 `PATHISH_PREFIXES` 声明支持的短前缀（`state/`、`setup/` 等）引用协议文件、或在描述 goal 级证据契约路径规范时使用 `<id>` 占位符模板，都会撞上同一误报——这是协议自身文档惯例与脚本实现之间的系统性缺口，不是本项目特有
- Risks of overfitting: 低——`.harnessloop` 是协议唯一保留的状态根目录名，新增该 base 不依赖本项目任何具体约定；占位符豁免（含 `<`/`>` 即豁免）同样是通用书写惯例，风险与 TH-0006 中已采用的其余豁免规则同级

## Resolution

- Resolution status: fixed（本项目 submodule 内已修）
- Upstream change: `harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/verify_protocol.py`——(1) `verify_round()` 的 `citation_bases` 由 `bases + submodule_roots(project)` 扩展为 `bases + [project / ".harnessloop"] + submodule_roots(project)`（仅 Rule B，`bases` 本身不动，Rule A scope-lock 判定不受影响）；(2) 新增 `_looks_like_placeholder(cleaned)`：span 内任意位置含 `<` 或 `>` 即豁免（原有 `cleaned.startswith(("-", "$", "<"))` 只查开头，无法覆盖 `goals/<id>/data-contract.md` 这类前缀之后出现占位符的情形）；模块 docstring 与 `--help` 均已补充说明两处修复。`harnessloop/scripts/validate.py` 第 5 阶段 `validate_protocol_gates()` 新增第三组 fixture（`harnessloop_base_root`），断言覆盖：PATHISH_PREFIXES 短前缀引用可解析到 `.harnessloop/` 下真实文件；`.harnessloop/` 下确实缺失的文件仍报 dangling（防止新 base 变成万能豁免）；占位符路径豁免生效。
- Backported to local policy: yes
- Backport path: harnessloop（submodule，未 commit，等待上游/主会话统一处理）
- Follow-up required:
  1. 复跑复现命令 `python3 harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop`：修复前 6 violation(s)/exit=1，修复后 "All mechanical protocol gates passed."/exit=0（已实测确认，无需人工进一步标记——与 TH-0006 遗留的 verify:ignore 标记事项不同，本轮 6 条误报无需协议产物层面的额外动作）
  2. 上游发布前运行 `npm run validate` 确认全部阶段仍绿（本次修复任务未运行该命令，由主会话统一执行）
  3. TH-0006 遗留事项（round 0001 评审 S2 行需补 `<!-- verify:ignore -->` 标记）仍未处理，与本条互不影响，继续等待 scribe/后续 round 处理
