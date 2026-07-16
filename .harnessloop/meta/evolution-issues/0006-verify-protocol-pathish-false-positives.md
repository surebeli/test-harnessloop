# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0006
- Issue class: skill-gap
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-sonnet-5 subagent (scribe), orchestrated by claude-fable-5
- Fixed by: claude-sonnet-5 subagent (independent fix task, orchestrated by claude-fable-5)
- Created at: 2026-07-16

分类说明：选择 skill-gap 而非 validation-drift——该问题不是验证脚本行为随时间偏离正确基线（drift），而是 verify_protocol.py 的 Rule B（悬空引用检测）自设计之初就未覆盖正则模式/glob/笔误原文引述/submodule 相对路径这几类合法引用书写方式，是一项既有能力缺口，在首个真实轮次中被实战坐实（作者已知缺陷 nm11）。

## Redaction Boundary

- Secrets removed: n/a（无涉密内容）
- Private data removed: n/a
- Raw logs omitted: n/a
- Safe evidence summaries only: yes

## Context

- Active goal path: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Active round path: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/
- State files: .harnessloop/state/current.md；.harnessloop/meta/self-audit.md（Audit ID: AUDIT-20260716-ROUND0001-NEGATIVE，round 0001 negative 反馈触发审计条目）
- Related handoffs: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/archive/0001-02-review-adversarial-design-closed.md
- Related evidence: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/reviews/adversarial-review.md（被 verify_protocol.py 判定 6 条 dangling-citation，全部为误报）
- Related reviews: rounds/0001/reviews/adversarial-review.md 对设计稿的对抗性评审（评审自身结论为 negative，与本 issue 无因果关系；评审文件被机械门误报是独立的机械门问题）

## Expected Harnessloop Behavior

verify_protocol.py Rule B（悬空引用检测）应仅对真正未落地的引用报错；对包含正则元字符/glob 模式的引用示例、对设计稿笔误路径的原文引述、以及 submodule 相对路径解析等合法书写方式，应予以豁免或正确解析，不应把评审文件中合法的引用性文本判定为悬空引用。

## Actual Harnessloop Behavior

round 0001 对抗性设计评审文件（rounds/0001/reviews/adversarial-review.md）运行 verify_protocol.py 后 exit=1，报告 6 条 dangling-citation，逐条核实全部为误报：evidence 段落中作为示例引用的正则模式字符串（如 `^_?\s*(no|none)\b.*declared.*_?$`）、对设计稿笔误路径的原文引述（如 S2 指出的 `harnessloop-loop/skills/harnessloop-loop/scripts/check_setup.py`，本身是对设计稿笔误的原文引述而非真实引用目标）、submodule 相对路径解析方式，均被 Rule B 误判为悬空引用。这是作者已知缺陷 nm11 在首个真实轮次中的实战坐实。

## Minimal Reproduction From Files

1. Read: .harnessloop/goals/20260716-001-setup-wizard/rounds/0001/reviews/adversarial-review.md（Evidence Used 表与 Finding 段落中含正则/glob/笔误路径引用的行）
2. Observe: 对该文件运行 `python3 <plugin-cache>/skills/harnessloop-loop/scripts/verify_protocol.py --project <本项目>` 返回 exit=1，Rule B 报告 6 条 dangling-citation
3. Expected next protocol action: 若引用为合法的正则模式/glob/笔误原文引述/submodule 相对路径，机械门应豁免或正确解析，不阻断 positive 判定
4. Actual next protocol action: 6 条全部被判定为悬空引用；本轮因评审本身结论已是 negative，机械门误报未实际改变轮次判定，但若某轮评审结论恰为 positive，将被此误报错误阻断

## Attempted Local Mitigation

- Evidence refresh: n/a
- Scope narrowing: n/a
- Contract revision: n/a
- Handoff change: n/a
- Rollback: n/a
- Human confirmation: 无需（依据既有 nm11 记录判定 6 条为误报，不影响本轮 negative 决策的有效性）

已另派独立修复任务处理 verify_protocol.py Rule B 本身（与本记录任务分离，本文件仅记录问题、不直接执行修复）。

## Suggested Upstream Improvement

- Candidate target: main skill（harnessloop-loop 的 verify_protocol.py 脚本）
- Proposed smallest change: Rule B 悬空引用检测增加豁免规则——(a) 含正则元字符（如 `^`、`$`、`\s`、`.*`、`\b` 等）或 glob 通配符的引用文本视为示例/模式字符串而非真实路径引用，跳过悬空检测；(b) 支持 submodule 相对路径的正确根解析（相对于 submodule 根而非仅项目根）；(c) 提供显式 code-span 豁免语法，供评审/设计文档在引用正则模式或笔误原文时主动声明豁免
- Why this generalizes beyond this project: 任何安装该插件的项目在撰写对抗性评审或设计文档时都会引用代码模式、正则表达式、glob 或 submodule 内路径，Rule B 现行逻辑对这类合法书写普遍误判，不是本项目特有
- Risks of overfitting: 中——豁免规则需谨慎设计（正则元字符豁免过宽可能反向放过真正的悬空引用），建议先以 code-span 显式豁免语法（风险最低）落地，再评估自动豁免规则

## Resolution

- Resolution status: fixed（本项目 submodule 内已修）
- Upstream change: `harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/verify_protocol.py`（Rule B 的 `pathish_citations` 改为逐行处理，新增：(a) `_looks_like_pattern` 对含正则/glob 元字符 `^ $ * ? | ( ) [ ] { } \ +` 的引用一律不判为 pathish；(c) `_looks_like_bare_domain` 对形如 `docs.python.org/...`、`github.com/...` 的裸域名 URL 豁免；(d) `IGNORE_MARKER = "<!-- verify:ignore -->"`——引用行同行或紧邻上一行带该 HTML 注释即跳过该行全部引用，模块 docstring 与 `--help` 均已补充说明。新增 `submodule_roots()` 读取项目根 `.gitmodules` 取一级 submodule 目录，`verify_round()` 内新增 `citation_bases`（= 原 `bases` + submodule 根，仅用于 Rule B 存在性检查，不放宽 Rule A scope-lock 判定）实现 (b)。`harnessloop/scripts/validate.py` 第 5 阶段 `validate_protocol_gates()` 新增第二组 fixture（`exempt_root`），断言覆盖 a/c/d 三类豁免、b 类 submodule 解析（含"submodule 内确实缺失的文件仍报错"的负向断言）、以及一条完全不符合任何豁免条件的真实悬空引用仍被抓（防漏报回归）。
- Backported to local policy: yes
- Backport path: harnessloop（submodule，未 commit，等待上游/主会话统一处理）
- Follow-up required:
  1. 复跑复现命令 `python3 harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/verify_protocol.py --project /Users/litianyi/Documents/Code/_ai-goods/test-harnessloop` 确认：6 条误报中 5 条（正则模式、`plugins/harnessloop/`、`__pycache__/*.pyc`、两条 marketplace.json submodule 相对路径）已消除；第 6 条（S2 段对设计稿笔误路径 `harnessloop-loop/skills/harnessloop-loop/scripts/check_setup.py` 的原文引述）机械上无法与"真实引用"区分，仍会报 dangling-citation——这不是本次修复遗漏，而是本 issue 自己在 Suggested Upstream Improvement (c) 里提出的"需要显式豁免语法"场景，修复已提供该语法（`<!-- verify:ignore -->`），已用独立 fixture（非本评审文件）验证该语法生效（同一份笔误路径原文加标记后 exit=0）。
  2. 待 scribe 或后续 round 在 `rounds/0001/reviews/adversarial-review.md` 的 S2 引用行（同行或上一行）补 `<!-- verify:ignore -->` 标记后，本项目复现命令才能达到 exit=0（该文件是协议产物，本次修复任务未修改它）。
  3. 上游发布前运行 `npm run validate` 确认全部阶段仍绿（本次修复任务未运行该命令，由主会话统一执行）。
