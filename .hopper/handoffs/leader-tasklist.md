# Leader Tasklist

Full task specs live here. Each task in `queue.md` references a section below by
its ID (the dispatcher pulls this section as the task spec).

---

## T-EXAMPLE-001

**Goal**: Describe what to build or verify in one or two sentences.

**Acceptance criteria** (prefer machine-checkable — a shell command or grep that proves each):
1. ...
2. ...

**Files allowed to touch** (positive scope): ...

**Files MUST NOT touch** (negative scope): ...

**Budget**: time and vendor-cost ceiling.

---

## T-001

**Task-type**: `code-review-adversarial` · **Vendor**: codex (随机结果，见 `.hopper/AGENTS.md`)

**Goal**: 对 `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop`
仓库的 commit `6936fbc`（setup wizard 完整实现：新 `harnessloop-setup` skill +
`check_setup.py` + `control-contract-profiles.md` + 四个既有 SKILL 的接线改动 +
`scripts/validate.py` 新增第 3 阶段）做一次**只读**对抗评审，不修改任何文件。

**评审对象**：
- Commit: `6936fbc63497ba7619acaccc177a13c976f4202e`，取 diff 用
  `git -C harnessloop show 6936fbc`（或 `git -C harnessloop show --stat 6936fbc`
  先看改动文件清单）。
- 涉及文件（相对 `harnessloop/` 仓库根）：
  1. `plugins/harnessloop/skills/harnessloop-setup/SKILL.md`（新增）
  2. `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py`（新增）
  3. `plugins/harnessloop/skills/harnessloop-loop/references/control-contract-profiles.md`（新增）
  4. 四个既有 SKILL 的接线改动：
     `plugins/harnessloop/skills/harnessloop-continue/SKILL.md`、
     `plugins/harnessloop/skills/harnessloop-init/SKILL.md`、
     `plugins/harnessloop/skills/harnessloop-loop/SKILL.md`、
     `plugins/harnessloop/skills/harnessloop-status/SKILL.md`
  5. `scripts/validate.py`（新增 stage 3）

**评审焦点**（按重要性排序）：
1. **`check_setup.py` 的判定算法边界**：字段切片匹配逻辑、TODO/none-哨兵正则
   的边界条件（漏检/误检）、`gate_blocking` 判定的两档（模板/缺失 vs
   advisory-complete）是否有遗漏或误判分支。
2. **SKILL 文本与脚本行为的一致性**：`harnessloop-setup/SKILL.md`、
   `harnessloop-status/SKILL.md`、`harnessloop-continue/SKILL.md` 等文本描述
   的行为，是否与 `check_setup.py` 的实际输出（`--json` 契约、exit
   码 0/1/2、字段计数）一致，有无文档与实现漂移。
3. **`scripts/validate.py` 新增断言的证伪力**：新 stage 3 的 28 项断言是否
   真能在对应缺陷注入时失败（而非无论实现对错都通过的"假阳性绿灯"）。
4. **Python 3.9 兼容性**：`check_setup.py` 及 `validate.py` 改动是否使用了
   3.9 之后才引入的语法/标准库特性（本机 `python3 = 3.9.4`，见
   `.harnessloop/setup/data-sources.md` 底部注）。

**Read-only 要求（硬约束）**：
- 不得修改、创建或删除 `harnessloop/` 仓库或本仓库中的任何文件。
- 结论写入 hopper 产物文件——由 hopper 自动落盘到
  `.hopper/handoffs/T-001-output.md`，不要求 codex 自行创建该路径以外的文件。
- 结论中每一条问题必须引用具体 `文件路径:行号`（例如
  `plugins/harnessloop/skills/harnessloop-loop/scripts/check_setup.py:123`）。
- 语言：中文或英文均可。

**Files allowed to touch**：无（本任务是只读评审，不写任何文件；产物由 hopper
落盘机制处理，非评审者本人写文件）。

**Files MUST NOT touch**：`harnessloop/` 仓库全部文件、本仓库（test-harnessloop）
全部文件——评审者不得对任一文件做写操作。

**Budget**：单次 codex 评审，正常优先级；无额外时间/成本上限设定，超时按
hopper 默认 timeout 处理。

**元目的（本任务的第二重目标）**：本任务同时用于验证 hopper 的 codex 评审通路
本身是否可靠。评审完成后，派发方必须对照
`hopper-plugin/ISSUE-codex-review-hijack.md` 记录的已知问题，核对以下三项
（详见 `.hopper/AGENTS.md` 的"Codex 评审强制核对"一节）：
1. 实际审查对象是否确为上面列出的 commit `6936fbc` 及其涉及文件，而非被全局
   skill 劫持后审查的其他仓/其他 diff。
2. 产物是否落在 `.hopper/handoffs/T-001-output.md`，而非 codex 自身 skill
   约定的其他路径。
3. 不得仅凭 `adapter_status: success` / exit 0 / codex 自述完成即采信——以上
   两项核对通过之前，本任务视为未完成。
