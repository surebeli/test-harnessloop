# Harnessloop Evolution Issue

## Summary

- Issue ID: TH-0001
- Issue class: packaging-gap
- Status: fixed
- Source project: test-harnessloop (/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop)
- Created by: claude-fable-5 (main session)
- Created at: 2026-07-16

## Redaction Boundary

- Secrets removed: n/a (无涉密内容)
- Private data removed: n/a
- Raw logs omitted: 仅保留关键 traceback 一行
- Safe evidence summaries only: yes

## Context

- Active goal path: 无（初始化阶段，goal 尚未创建）
- Active round path: 无
- State files: .harnessloop/ 目录已建、文件全部未写入（崩溃发生在首个 write_file）
- Related handoffs: 无
- Related evidence: harnessloop 仓库 `npm run validate` 修复后 7/7 通过（含 init 冒烟）
- Related reviews: 无

## Expected Harnessloop Behavior

`$harnessloop-init` 调用捆绑 initializer `init_project.py --project <target>` 后创建 7 目录 + 12 文件的完整协议骨架并退出 0。

## Actual Harnessloop Behavior

在 Python 3.9.4（pyenv shim）上 `init_project.py:76` 抛出
`TypeError: write_text() got an unexpected keyword argument 'newline'`，
退出码 1；目录已创建但 0 个文件写入，项目处于半初始化状态。
`Path.write_text()` 的 `newline` 参数为 Python 3.10 新增。

## Minimal Reproduction From Files

1. Read: plugins/harnessloop/skills/harnessloop-loop/scripts/init_project.py:76
2. Observe: `path.write_text(content, encoding="utf-8", newline="\n")` 在 python3 = 3.9.x 时必然 TypeError
3. Expected next protocol action: init 完成，报告 created 清单，建议 `$harnessloop-loop`
4. Actual next protocol action: init 崩溃，留下空目录树

## Attempted Local Mitigation

- Evidence refresh: n/a
- Scope narrowing: n/a
- Contract revision: n/a
- Handoff change: n/a
- Rollback: 未回滚（半初始化目录对重跑无害，重跑已验证幂等补齐）
- Human confirmation: 无需（单点兼容性修复）

## Suggested Upstream Improvement

- Candidate target: validation script（init_project.py）+ docs
- Proposed smallest change: `path.write_text(...)` 改为 `with path.open("w", encoding="utf-8", newline="\n") as handle: handle.write(content)`（保留强制 LF 语义，兼容 3.9）；并在 README/AGENTS.md 声明最低 Python 版本（关联作者已知未修问题 n9：validate.py 用 removeprefix 需 ≥3.9，本例说明实际门槛曾被隐性抬到 3.10）
- Why this generalizes beyond this project: macOS/pyenv/系统 python3 停留在 3.9 的环境很常见；init 是所有用户的第一个接触点，首触即崩直接阻断采用
- Risks of overfitting: 无——open(newline=) 自 Python 3 起可用，行为等价

## Resolution

- Resolution status: fixed（本项目 submodule 内已修，`npm run validate` 7/7 通过，重装插件后 init 成功产出 12 文件）
- Upstream change: 待 push 到 surebeli/harnessloop（submodule commit 见 git log）
- Backported to local policy: yes
- Backport path: harnessloop/plugins/harnessloop/skills/harnessloop-loop/scripts/init_project.py:76
- Follow-up required: 上游发布时同步声明最低 Python 版本（建议 ≥3.9），并考虑给 validate.py 增加多版本 CI 矩阵（3.9 会直接抓住此类问题）
