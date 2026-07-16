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

## 2026-07-16 P0 修复批次：审查驱动的四组框架缺陷闭环（Sonnet 执行 / Fable 审查模式首次运行）

- **场景**：docs/harnessloop-review-20260716.md 严格审查（80 条确认发现）后的 P0 修复批次；首次采用「写入任务委派 Sonnet 5 子代理、主会话 Fable 5 只读审查验收」工作模式，三个子代理并行修复
- **现象（修复前）**：①verify_protocol.py 机械门在已安装项目中零触发路径（12 个 SKILL.md 无一运行它）；②round_cost.py 按行累加同一 message 的多行 usage，实测 3.03x 虚高（审查报告区间 2.3–4.1x）；③secrets SKILL 硬编码仓库相对路径在安装后不可达，脚本调用写法三种并存；④channel_params.py 明文 store 0644 非原子写、二次 add 重置元数据、set→add 转换残留明文、audit 对 git 已跟踪 store 全盲
- **预期**：机械门在每轮收盘与 continue 门运行；成本账单按 message 计费一次；所有脚本路径用 <skill-dir>/<plugin-root> 占位符可解析；明文值 0600 原子落盘且绝不进入 git 可见区
- **插件改动**：submodule 三个 commit——0829b03（A 组：verify_protocol 接线 + 路径统一）、c221273（B 组：message.id 分组去重 + marker v2 跨窗口 pending 携带 + validate 阶段 6 回归断言）、66093fd（C 组：channel_params 加固 + channel-params.json.* 通配 ignore）
- **审查交互**：主会话审查共退回三轮补修——A 组 2 处同主题路径残留 + evolution issue 的 Created by 元数据不实（写成 fable-5，实为 sonnet-5 执行）；B 组 1 处注释与行为不符（stale pending 实为携带而非丢弃）；C 组 3 处新引入的泄露面（临时文件/损坏备份/.bak 均不被 gitignore 模式覆盖、备份继承 0644 权限）。三个代理均一次性完成补修
- **复验结果**：✅ 通过。`npm run validate` 7/7 全绿（含 B 组 6 条新增去重断言，修复前必挂）；plugin-reinstall.sh 重装后缓存与 submodule 工作区内容级一致（sha 66093fd）；B 组用本机真实 transcript 独立复算与修复后输出精确一致
- **遗留**：channel_params 并发写为 last-writer-wins（无文件锁，超出本批范围）；round_cost 尾部开放 message 延迟计费为有意取舍；validate 阶段 3 尚无 C 组五项新行为的固定 fixture；对应 evolution issue：TH-0002~TH-0005（.harnessloop/meta/evolution-issues/0002-0005）

## 2026-07-16 init 首触即崩：init_project.py 不兼容 Python 3.9

- **场景**：首次执行 `harnessloop:harnessloop-init` skill，按其 Preferred Setup 调用插件缓存内的 `init_project.py --project <本项目>`
- **现象**：`TypeError: write_text() got an unexpected keyword argument 'newline'`（init_project.py:76），退出码 1；7 个目录已建、0 个文件写入，项目半初始化。本机 python3 = 3.9.4（pyenv）
- **预期**：init 一次成功，产出 7 目录 + 12 文件骨架（依据 harnessloop-init SKILL.md Output Contract 与 init_project.py 设计）
- **插件改动**：init_project.py:76 改用 `path.open("w", encoding="utf-8", newline="\n")` 写入（`Path.write_text(newline=)` 是 3.10+ API，`open(newline=)` 全版本可用且语义等价）；submodule 内 commit 见 git log
- **复验结果**：✅ 通过。harnessloop 自身 `npm run validate` 7/7（其中第 2 关 init 冒烟正是用本机 3.9.4 执行，修复前必挂）；`scripts/plugin-reinstall.sh` 重装后重跑 initializer，12 个文件全部写入、幂等补齐半初始化状态、退出 0
- **遗留**：上游未声明最低 Python 版本（作者对抗性审查中的已知问题 n9），本例实际把隐性门槛抬到了 3.10；已记 evolution issue `.harnessloop/meta/evolution-issues/0001-init-project-py39-write-text-crash.md`，submodule 修复待 push 上游
