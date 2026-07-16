# harnessloop 验证与迭代记录

每一轮「发现问题 → 改插件 → 重装 → 复验」记一条。最新的记录放最上面。

条目模板：

```markdown
## YYYY-MM-DD <一句话标题>

- **场景**：在开发 app 的哪个环节、执行哪个 skill 时触发
- **现象**：框架实际行为（贴关键输出/文件状态）
- **预期**：框架应有的行为，依据（README/AGENTS.md/协议条款）
- **插件改动**：harnessloop submodule 中的 commit（`<sha> <subject>`），或"未改动，原因"
- **复验结果**：重装重启后同场景的行为；通过/未通过
- **遗留**：后续待办或新发现的关联问题
```

---

## 2026-07-16 init 首触即崩：init_project.py 不兼容 Python 3.9

- **场景**：首次执行 `harnessloop:harnessloop-init` skill，按其 Preferred Setup 调用插件缓存内的 `init_project.py --project <本项目>`
- **现象**：`TypeError: write_text() got an unexpected keyword argument 'newline'`（init_project.py:76），退出码 1；7 个目录已建、0 个文件写入，项目半初始化。本机 python3 = 3.9.4（pyenv）
- **预期**：init 一次成功，产出 7 目录 + 12 文件骨架（依据 harnessloop-init SKILL.md Output Contract 与 init_project.py 设计）
- **插件改动**：init_project.py:76 改用 `path.open("w", encoding="utf-8", newline="\n")` 写入（`Path.write_text(newline=)` 是 3.10+ API，`open(newline=)` 全版本可用且语义等价）；submodule 内 commit 见 git log
- **复验结果**：✅ 通过。harnessloop 自身 `npm run validate` 7/7（其中第 2 关 init 冒烟正是用本机 3.9.4 执行，修复前必挂）；`scripts/plugin-reinstall.sh` 重装后重跑 initializer，12 个文件全部写入、幂等补齐半初始化状态、退出 0
- **遗留**：上游未声明最低 Python 版本（作者对抗性审查中的已知问题 n9），本例实际把隐性门槛抬到了 3.10；已记 evolution issue `.harnessloop/meta/evolution-issues/0001-init-project-py39-write-text-crash.md`，submodule 修复待 push 上游
