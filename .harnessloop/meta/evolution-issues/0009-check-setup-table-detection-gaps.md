# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0009
- Issue class: validation-drift
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-sonnet-5 (main session), fixing findings from an independent hopper T-001 third-party review
- Created at: 2026-07-17

## Redaction Boundary

- Secrets removed: n/a（无涉密内容）
- Private data removed: n/a
- Raw logs omitted: 仅引用评审 Verdict 段落摘要，未整段粘贴 T-001 完整 transcript
- Safe evidence summaries only: yes

## Context

- Active goal path: 无（本次为独立 hopper 评审后续修复任务，非常规 goal/round 流程）
- Active round path: 无
- State files: plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py（修复对象：`_resolve_table`、新增 `_sentinel_pattern`）、scripts/validate.py（`validate_check_setup_smoke()`，仅该函数新增两组负向断言 + 头部已知局限注释）
- Related handoffs: .hopper/handoffs/T-001-output-raw.txt（Verdict: REWORK，末尾 Verdict 段，`sed -n '4260,4340p'` 可读）
- Related evidence: 本次独立复现的 `_resolve_table` 三案例（见下方 Minimal Reproduction）；`validate_check_setup_smoke` 注坏验证（临时还原修复前逻辑，确认新增断言必挂，随后恢复）
- Related reviews: hopper T-001（`code-review-adversarial`，vendor: codex，model: gpt-5.5，对 commit `6936fbc63497ba7619acaccc177a13c976f4202e` 的只读对抗性评审，Verdict: REWORK）

## Expected Harnessloop Behavior

`check_setup.py` 对 `setup/data-sources.md` 等文件里的表格类目（Static Sources / Dynamic Or Generated Sources / Runtime Validation Systems / External Tools And Platforms）判定"是否已填"时，应当：(1) 只把至少含一个非空单元格的表格行算作真实数据行，不能把模板自带的全空管道行（`|  |  |`）误判为已答；(2) "无此类目"哨兵行必须与其所在的 `## heading` 类目匹配，不能接受写在错误类目下的哨兵句（如 Static Sources 小节下出现"Dynamic Or Generated Sources"的哨兵）。同时 `scripts/validate.py` 第三阶段（`validate_check_setup_smoke`）的合成 fixture 应当覆盖这两类负向场景，确保回归时能挂住。

## Actual Harnessloop Behavior

- 缺陷 1（`check_setup.py` `_resolve_table`，原第 441 行附近）：分隔行之后只要某行 `.strip().startswith("|")` 就判定 `has_rows = True`，不检查单元格内容。模板自带的全空行 `|  |  |` 满足这一条件，导致从未被回答的表格类目被误判为"已填"。
- 缺陷 2（`check_setup.py` `_SENTINEL_RE`，原第 224/445 行附近）：哨兵正则是模块级常量，只匹配通用的"No/None ... (confirmed via setup wizard)"文案，不绑定当前 `## heading`。任何类目下写错类目的哨兵句都会被接受，与 `harnessloop-setup/SKILL.md`（S2 步骤，:70-:76）"必须使用当前类目自身的小写 heading 文本"的要求不符。
- 缺陷 3（`scripts/validate.py` `validate_check_setup_smoke`，第三阶段 fixture）：既有回归只覆盖了散文行（"not sure yet..."）这一种负向场景（M-B 修复遗留的既有断言），未覆盖上述两个新发现的缺陷；且"已填"/"partial"两类正向 fixture 由 `check_setup.MANIFEST` + `locate_field_line`/`locate_table_bounds` 自身生成，manifest 遗漏或 locator bug 可能在 fixture 与被测代码之间自证一致而不被发现（本批不做结构性重构，仅记录）。

发现渠道：hopper T-001 第三方独立评审（vendor: codex，model: gpt-5.5，`code-review-adversarial` 任务，只读，未修改任何文件，Verdict: REWORK）。评审对上述两处检测缺陷分别给出了 in-memory 复现输出：空行案例 `(True, False)`，错类别哨兵案例 `(False, True)`，均在本次修复前于本机独立复现确认一致。

## Minimal Reproduction From Files

1. Read: `harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（修复前版本）`_resolve_table` 函数与模块级 `_SENTINEL_RE`
2. Observe（修复前，本机独立复现，Python 3.9.4）：
   - `_resolve_table("## Static Sources\n\n| Source | Access |\n| --- | --- |\n|  |  |\n\n## Next\n", "Static Sources")` → `(True, False)`（应为 `(False, False)`）
   - 错类别哨兵：`## Static Sources` 小节下插入 `render_sentinel_line("Dynamic Or Generated Sources")` 产出的句子 → `_resolve_table(..., "Static Sources")` → `(False, True)`（应为 `(False, False)`）
   - 正确类别哨兵（对照组，修复前后均应为 `(False, True)`）：`## Static Sources` 小节下插入 `render_sentinel_line("Static Sources")` → `(False, True)`
3. Expected next protocol action: `_resolve_table` 收紧为"至少一个单元格去空白后非空才算数据行"；哨兵匹配绑定 `render_sentinel_line(heading)` 生成的当前类目规范文本，容忍首尾斜体下划线与 No/None 首词大小写，但类目名必须等于 `heading.lower()`
4. Actual next protocol action（修复前）：两类缺陷都会让 `setup/data-sources.md` 的某个类目被误判为"已回答"，从而拉高 `fields_filled` 计数，掩盖用户实际从未填写该类目的事实——这类误判在 `filled`/`gate_blocking` 判定链路上是静默的（不报错、不产生任何可见信号），只能靠对抗性评审或手工构造这类边界 fixture 才能发现

## Attempted Local Mitigation

- Evidence refresh: 本机独立复现评审报告中的两处 in-memory 判定（见上方 Minimal Reproduction 第 2 步），确认与 T-001 报告数值完全一致后才动手修复
- Scope narrowing: 仅修改 `check_setup.py` 的 `_resolve_table`（+ 新增 `_sentinel_pattern`，替换模块级 `_SENTINEL_RE`）与 `scripts/validate.py` 的 `validate_check_setup_smoke()` 一个函数，未触碰其余 7 个验证阶段
- Contract revision: 无
- Handoff change: 无
- Rollback: 未回滚。修复后对 `_resolve_table` 重新跑三案例确认结果转为 `(False, False)` / `(False, False)` / `(False, True)`；随后临时程序化还原两处判定为修复前逻辑（"注坏"），重跑 `validate_check_setup_smoke()`，确认新增的两组负向断言（T-001#1、T-001#2，共 4 条 check）在还原逻辑下必然失败（`FAIL: ... got state='partial'` / `got missing_sections` 缺失该类目），而其余既有断言（bare skeleton、M-B 散文回归、filled/partial/blocking/TODO fixture）保持通过，证明新增断言确实定位到这两处缺陷而非误报；随后恢复修复后的代码，确认 `validate_check_setup_smoke()` 全部 32 条 check 均为 `ok`
- Human confirmation: 无需（有独立复现证据 + 注坏验证证据支撑的确定性修复）

## Suggested Upstream Improvement

- Candidate target: main skill（`harnessloop-loop` 的 `check_setup.py` 脚本 + `scripts/validate.py` 第三阶段回归 fixture）
- Proposed smallest change: 已实施——(1) `_resolve_table` 的 has_rows 判定改为按 `|` 切分单元格并要求至少一个单元格 `.strip()` 后非空；(2) 新增 `_sentinel_pattern(heading)`，用 `render_sentinel_line(heading)` 生成的规范句子（去除首尾下划线后）作为匹配基准，只放宽首词 No/None 大小写与首尾可选下划线，类目文本段必须逐字匹配，替换原模块级 `_SENTINEL_RE`；(3) `validate_check_setup_smoke()` 新增两组独立 fixture（T-001#1 全空行、T-001#2 错类别哨兵），并在函数头部记录 fixture 自证性已知局限（评审发现 3）
- Why this generalizes beyond this project: 任何"表格类目 + 哨兵行"式的机器可读完成度检测，只要哨兵匹配不绑定当前小节而是用一个全局正则，就会有同样的"任意类目哨兵都能冒充任意其它类目已答"的漏洞；同理，任何把"存在某种前缀字符的行"当作"数据行"而不检查内容的表格行检测逻辑，都会被模板自带的空白占位行击穿。这两类都不是 harnessloop 特有的问题，而是"结构化文本完成度检测"这一任务模式的通用陷阱
- Risks of overfitting: 低——两处修复都是收紧判定条件（要求单元格非空、要求类目文本逐字匹配），不会产生新的假阴性（不会把真正已填的表格/正确类目的哨兵误判为未填），只会消除两类已确认的假阳性
- 评审发现 3（fixture 自证性，未修）成本/收益记录：`_fill_setup_project` 依赖 `check_setup.MANIFEST`/`locate_field_line`/`locate_table_bounds` 生成"已填"/"partial" fixture，理论上 manifest 遗漏字段或 locator 的切片 bug 若在 fixture 写入端与检测端表现一致，可自证掩盖问题。本批评估后判定暂不做结构性重构：MANIFEST 已一次性手工转录了 60+ 个叶子字段（round 0003），独立构造第二套人工 fixture 会让转录面翻倍、引入新的漂移风险，用于防范一个比本批已修复的两个具体、可独立复现缺陷（空行、错类别哨兵）更窄的缺陷类别，性价比不高。已在 `validate_check_setup_smoke()` 函数头部注释中如实记录该局限与理由，留待后续按需决策，不做静默忽略

## Resolution

- Resolution status: fixed（本项目 submodule 内已修：`plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py` 的 `_resolve_table`/新增 `_sentinel_pattern`；`scripts/validate.py` 的 `validate_check_setup_smoke()` 新增两组负向断言 + 头部已知局限注释）
- Upstream change: 待 push 到 surebeli/harnessloop（submodule 内本次任务未提交，由主会话统一处理）
- Backported to local policy: yes
- Backport path: harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py；harnessloop/scripts/validate.py（`validate_check_setup_smoke()`，仅该函数）
- Follow-up required: 是——(1) 主会话统一跑一次完整 `npm run validate`（本次任务按指示未跑，仅独立驱动 `validate_check_setup_smoke()`）以确认与其余 7 个阶段无交叉影响；(2) 后续如决定处理评审发现 3（fixture 自证性），需先评估是否值得为 MANIFEST 转录做第二套独立人工 fixture，或改用更轻量的抽样交叉校验；(3) 确认修复后提交 submodule commit 并推送
