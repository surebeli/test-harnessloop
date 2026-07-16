# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0003
- Issue class: packaging-gap
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-sonnet-5 subagent (P0 fix group A, orchestrated by claude-fable-5)
- Created at: 2026-07-16

## Redaction Boundary

- Secrets removed: n/a (无涉密内容)
- Private data removed: n/a
- Raw logs omitted: n/a
- Safe evidence summaries only: yes

## Context

- Active goal path: 无（框架级审查修复任务，未绑定项目内 goal）
- Active round path: 无
- State files: 未涉及本项目 `.harnessloop/state/`
- Related handoffs: 无
- Related evidence: `harnessloop-secrets/SKILL.md`（修复前 55-60 行）六条命令硬编码仓库根相对路径；`harnessloop-loop/SKILL.md`（修复前 485 行）与 `references/round-summary-template.md`（修复前 27 行）对 `round_cost.py` 用裸相对路径 `scripts/round_cost.py`；对照同仓库已有正确写法 `harnessloop-loop/SKILL.md:103`（`<skill-dir>`）、`harnessloop-init/SKILL.md:42`（`<plugin-root>`）
- Related reviews: 外部审查 P0 组 A 的 2 条独立发现（packaging、security-secrets 两个 lens），均判定 CONFIRMED；实测在本机安装缓存 `~/.claude/plugins/cache/harnessloop/harnessloop/0.10.0/` 验证 `plugins/harnessloop/` 前缀在安装树中不存在

## Expected Harnessloop Behavior

`harnessloop-secrets` 的 Deterministic Manager（`channel_params.py`）与 `harnessloop-loop` 的成本结算（`round_cost.py`）都应能在任意已安装该插件的目标项目中，按 SKILL.md 文档给出的命令原样执行成功。跨技能/同技能脚本调用应使用同仓库既有的可解析占位符写法（`<skill-dir>/scripts/...` 或 `<plugin-root>/skills/<skill>/scripts/...`）。

## Actual Harnessloop Behavior

`harnessloop-secrets/SKILL.md` 的全部 6 条命令使用 `python plugins/harnessloop/skills/harnessloop-secrets/scripts/channel_params.py ...`，该路径只在本开发仓库为 cwd 时存在；插件安装为 marketplace 缓存后，无论以目标项目还是插件根为基准都不可达。`harnessloop-loop/SKILL.md:485` 与 `references/round-summary-template.md:27` 对 `round_cost.py` 使用裸相对路径 `scripts/round_cost.py`，在目标项目 cwd 下同样不存在。同一仓库同时存在三种写法（仓库根相对路径、裸相对路径、正确的 `<skill-dir>`/`<plugin-root>` 占位符），造成不一致且部分写法在安装后必然失败。另外，`round_cost.py` 只读取 `~/.claude/projects/` 下的 Claude Code 会话转录（docstring 明示），而 loop SKILL 对每轮收尾无条件要求运行它；插件同时面向 Codex 发布（`.codex-plugin/plugin.json`），Codex 环境下该脚本每轮必然因转录目录不存在而非零退出。

## Minimal Reproduction From Files

1. Read: `plugins/harnessloop/skills/harnessloop-secrets/SKILL.md`（修复前 55-60 行）、`plugins/harnessloop/skills/harnessloop-loop/SKILL.md`（修复前 485 行）、`plugins/harnessloop/skills/harnessloop-loop/references/round-summary-template.md`（修复前 27 行）
2. Observe: 三处脚本调用路径写法互不一致，且其中两类（仓库根相对路径、裸相对路径）在安装后的目标项目 cwd 下均不可解析；`round_cost.py --project <target-project>` 在非 claude-code 环境（如 Codex）下必然因无本地转录而非零退出
3. Expected next protocol action: 按文档原样执行命令即可完成 secrets 管理与成本结算，非 claude-code 环境下能优雅降级为"cost unavailable"而非报错阻断
4. Actual next protocol action: 按文档原样执行必然 `[Errno 2] No such file or directory` 或等价失败；Codex 环境下 `round_cost.py` 无条件被要求运行，产生不必要的失败噪音

## Attempted Local Mitigation

- Evidence refresh: n/a（框架级缺口，非项目内证据问题）
- Scope narrowing: n/a
- Contract revision: n/a
- Handoff change: n/a
- Rollback: n/a
- Human confirmation: 无需（依据审查发现的既定 suggestion 做最小路径统一修复）

## Suggested Upstream Improvement

- Candidate target: main skill（harnessloop-secrets、harnessloop-loop 两份 SKILL.md）+ template（round-summary-template.md）
- Proposed smallest change: 把 `harnessloop-secrets/SKILL.md` 六条命令的路径统一改为 `<skill-dir>/scripts/channel_params.py`（该脚本属于本技能自身目录）；把 `harnessloop-loop/SKILL.md` 的 `round_cost.py` 调用与 `references/round-summary-template.md` 的对应引用统一改为 `<skill-dir>/scripts/round_cost.py`（与同文件 `init_project.py` 已有的 `<skill-dir>` 惯例一致）；并在 loop SKILL 的 cost 步骤加环境条件：仅在 `claude-code` 环境（见 `state/environment.md`）运行 `round_cost.py`，其余环境直接记 `cost unavailable: no local transcript source`，不再无条件调用
- Why this generalizes beyond this project: 任何安装该插件的项目、任何非 Claude Code 的运行环境（如 Codex）都会遇到同一路径不可解析/无条件调用问题，不是本项目特有
- Risks of overfitting: 低——`<skill-dir>` 占位符是仓库内已验证可用的既有惯例（`harnessloop-loop/SKILL.md:103,109`），只是把两处遗漏的调用点和一处模板补齐到同一惯例，未引入新语义

## Resolution

- Resolution status: fixed（submodule 内已修）
- Upstream change: `harnessloop/plugins/harnessloop/skills/harnessloop-secrets/SKILL.md`（6 条命令路径统一为 `<skill-dir>/scripts/channel_params.py`）、`harnessloop/plugins/harnessloop/skills/harnessloop-loop/SKILL.md`（`round_cost.py` 调用改为 `<skill-dir>/scripts/round_cost.py` 并加 `claude-code` 环境条件，非该环境记 `cost unavailable: no local transcript source`）、`harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/round-summary-template.md`（同步统一路径写法与环境说明）
- Backported to local policy: yes
- Backport path: harnessloop（submodule，未 commit，等待上游/主会话统一处理）
- Follow-up required: 上游发布时运行 `npm run validate` 确认 7 阶段仍全绿；`docs/cost-model.md:51` 目前使用第三种占位符写法 `<plugin>/skills/harnessloop-loop/scripts/round_cost.py`，本次为最小变更未动该文档文件，建议后续单独统一（不在本次 P0 组 A 范围内）
