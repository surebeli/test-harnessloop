# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0008
- Issue class: skill-gap
- Status: open
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-sonnet-5 subagent (scribe), orchestrated by claude-fable-5
- Created at: 2026-07-16

分类说明：第三类 Rule B 误报模式，与 TH-0006（判定"引用是否应被当作路径"）、TH-0007（判定为路径后解析基准缺 `<project>/.harnessloop`）均不同根因——本条误报源于评审散文的自然行文习惯：先在句子/段落中建立完整路径语境（如 `plugins/harnessloop/skills/harnessloop-setup/agents/openai.yaml`），后续文字承接该语境使用省略前缀的短片段（如单独提到 `agents/` 或 `.codex-plugin/plugin.json`）指代同一目录树下的其它文件。片段对应的真实文件/目录确实存在，但 Rule B 现有解析基准集合（project root、goal dir、round dir、submodule roots、`.harnessloop` root）都不包含"当前讨论语境的中间目录"这一动态基准，因此每一轮评审只要使用这种（相当常见的）行文习惯就会再生一批新的同类误报，是持续性维护负担而非一次性缺陷。

## Redaction Boundary

- Secrets removed: n/a（无涉密内容）
- Private data removed: n/a
- Raw logs omitted: n/a
- Safe evidence summaries only: yes

## Context

- Active goal path: .harnessloop/goals/20260716-001-setup-wizard/goal.md
- Active round path: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/
- State files: 本次记录不涉及项目状态文件写入，仅涉及 rounds/0003/reviews/adversarial-review.md 的豁免标记与本 evolution issue 文件
- Related handoffs: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/handoffs/0003-04-review-adversarial-implementation-open.md
- Related evidence: .harnessloop/goals/20260716-001-setup-wizard/rounds/0003/reviews/adversarial-review.md（M-C 段落，三处片段引用：`agents/`、`.codex-plugin/plugin.json`、`harnessloop-setup/agents/openai.yaml`，均已加 `<!-- verify:ignore -->` 标记）
- Related reviews: rounds/0003/reviews/adversarial-review.md 本身（实现级对抗评审，M-C 判定为 scope-lock 规划遗漏而非实现违规，与本 issue 的机械误报无因果关系）
- Related evolution issues: .harnessloop/meta/evolution-issues/0006-verify-protocol-pathish-false-positives.md（Rule B 第一批：正则/glob/裸域名/占位符/显式豁免语法）；.harnessloop/meta/evolution-issues/0007-verify-rule-b-missing-harnessloop-base.md（Rule B 第二批：解析基准缺 `.harnessloop` 根）；本条为第三批（讨论语境中间目录相对片段）

## Expected Harnessloop Behavior

Rule B 应能正确处理评审/设计文档行文中常见的"承接上文语境、省略已建立的中间目录前缀"的路径片段引用——只要该片段作为路径后缀在项目内能唯一定位到真实存在的文件或目录，就不应判定为悬空引用。

## Actual Harnessloop Behavior

round 0003 实现级对抗评审文件（rounds/0003/reviews/adversarial-review.md）M-C 段落中三处引用——`agents/`（讨论"每个 skill 目录下的 agents/ 子目录"时使用的裸目录名片段）、`.codex-plugin/plugin.json`（承接"本轮"语境省略 `plugins/harnessloop/` 前缀的片段）、`harnessloop-setup/agents/openai.yaml`（Required Next Action 段落中省略 `plugins/harnessloop/skills/` 前缀的片段）——均为相对于当前讨论语境中间目录的路径片段。三者对应的真实文件/目录结构（`harnessloop/plugins/harnessloop/skills/*/agents/`、`harnessloop/plugins/harnessloop/.codex-plugin/plugin.json`、`harnessloop/plugins/harnessloop/skills/harnessloop-setup/agents/openai.yaml` 的父目录）确实存在，但 Rule B 现有解析基准集合都不能直接匹配这些省略前缀的片段，导致三条被判定为 dangling-citation，只能逐条手工加 `<!-- verify:ignore -->` 止血（本次任务已完成）。

## Minimal Reproduction From Files

1. Read: `.harnessloop/goals/20260716-001-setup-wizard/rounds/0003/reviews/adversarial-review.md`（M-C 段落，加标记前的原始三处引用：`agents/`、`.codex-plugin/plugin.json`、`harnessloop-setup/agents/openai.yaml`）
2. Observe: 对该文件（未加 `verify:ignore` 标记时）运行 `verify_protocol.py` 会将这三条判定为 dangling-citation，尽管对应真实文件/目录确实存在于项目内更深的路径下
3. Expected next protocol action: 若引用片段作为路径后缀在项目内唯一命中真实文件/目录，机械门应予以豁免，不阻断 positive 判定
4. Actual next protocol action: 三条全部报错，需人工逐条添加 `verify:ignore` 标记；本轮因整体评审结论仍为 positive（M-C 本身不阻塞该结论），误报未改变本轮判定，但每一轮新评审只要复用这种行文习惯都会重新产生同类误报，属持续性维护负担而非一次性问题

## Attempted Local Mitigation

- Evidence refresh: 已用本机项目实测确认三处引用对应的真实文件/目录均存在（`harnessloop/plugins/harnessloop/skills/*/agents/`、`harnessloop/plugins/harnessloop/.codex-plugin/plugin.json`、`harnessloop/plugins/harnessloop/skills/harnessloop-setup/agents/openai.yaml` 的父目录结构）
- Scope narrowing: n/a
- Contract revision: n/a
- Handoff change: n/a
- Rollback: n/a
- Human confirmation: 无需（依据 TH-0006 已提供的 `verify:ignore` 豁免语法逐条标记，不改变本轮 positive 决策）

本地缓解已执行：已在三处引用所在行的紧邻上一行插入 `<!-- verify:ignore -->`（`agents/` 与 `.codex-plugin/plugin.json` 同在一行，故合并为一处标记插入；`harnessloop-setup/agents/openai.yaml` 另在其所在行上方插入一处，合计两处物理插入覆盖三条引用）。

## Suggested Upstream Improvement

- Candidate target: main skill（harnessloop-loop 的 verify_protocol.py 脚本）
- Proposed smallest change: Rule B 在现有解析基准（project root / goal dir / round dir / submodule roots / `.harnessloop` root）全部解析失败后，增加一次"项目树后缀匹配回退"：将引用片段作为路径后缀，在项目文件树中搜索是否存在唯一命中的真实路径；若唯一命中则视为解析成功豁免，若零命中或命中多个（多义）则仍按现状报 dangling-citation，不放宽真正悬空引用的检测
- Why this generalizes beyond this project: 评审/设计文档的自然行文习惯普遍是"先建立完整路径语境，后续段落承接语境使用省略前缀的短片段"，这是任何项目、任何轮次的评审文档都会出现的书写模式，不是本项目特有；随协议使用增多，这类误报会持续复现
- Risks of overfitting: 中高——后缀匹配回退若不严格限制"唯一命中"条件，可能把真正的悬空引用（拼写错误但恰好是另一无关文件的合法后缀）误判为有效，需要谨慎评估假阴性风险（"本该报错但被后缀匹配放过"的情形）；建议先以保守实现上线（要求后缀至少含一个路径分隔符、且必须唯一命中，零命中或多义命中一律仍报错），并配合样本回归测试观察漏报率，再考虑放宽

## Resolution

- Resolution status: open
- Upstream change: 待定（尚未修复；本次仅记录问题并用 `verify:ignore` 手工止血三处引用）
- Backported to local policy: no
- Backport path: 无
- Follow-up required: 是——(1) 评估"项目树后缀匹配回退"方案的假阴性风险后再决定是否实现；(2) 若暂不实现自动回退，至少在协议文档中记录"评审文档引用建议使用完整路径或显式加 `verify:ignore`"的行文规范，减少手工止血频率；(3) 后续新评审若再出现同类片段引用，继续用 `verify:ignore` 逐条标记，不阻塞轮次判定
