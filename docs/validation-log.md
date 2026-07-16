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

## 2026-07-17 hopper-plugin 0.31.0 发布：首次授权 push，政策层从纪律升级为机制

- **场景**：hopper 边用边验证进入迭代阶段——用户采纳"effort 预制 + model 选择规则"三层政策方案并授权 push（附版本同步硬条件）；同一发布收拢三个批次：脚手架抽象档位化、--check-model 三档断言器、政策层机械化四项（dispatcher 政策消费/clamp 可见化/verified-latest 哨兵/setup 政策 lint）
- **现象**：①全 vendor probe 实测 8/8 连通，codex bundled 目录含本机旧 CLI 不可用的 5.6 代——"目录收录≠本机可用"成为 --check-model 三档语义的设计依据 ②codex CLI 升级到 0.144.5 后 gpt-5.6-sol/terra/luna 三模型 live 微测全部可用，knownGood 更新（版本门槛注记）③项目 AGENTS.md 政策列迁移为机器语法后 lint 零 unparseable 零警告，迁移中发现两个真实解析陷阱（转义竖线列错位、反引号破坏 OOB 判定）④批次 2 顺带修复 --write frontmatter 记录未解析字面量的真 bug ⑤API 中断两次（会话额度/服务端错误），SendMessage 续跑机制两次成功恢复
- **预期**：政策三层结构（frame 抽象档位 → AGENTS.md 项目政策 → 派发实例落盘）自洽运转
- **插件改动**：hopper-plugin 6fbcf3a（v0.31.0，首次授权 push eceee81..6fbcf3a）；定向单测批次合计 250+ 全绿，全量回归 845/852（7 失败为环境缺 express 的既有 dashboard 测试）
- **复验结果**：✅ 重装 v0.31.0 内容级一致；--setup 政策段在真实项目三态判定正确；--check-model 六案例全对；回落链/clamp/哨兵实跑验证
- **遗留**：评审行 Effort policy 静态 lint 显示 unbound（设计使然——vendor 派发时随机绑定，届时 per-vendor 表生效）；dashboard 测试的 express 环境缺口（上游既有）；README 版本徽章 0.12.0 历史遗留漂移（未在本批范围）

---

## 2026-07-17 hopper 首次实战：T-001 第三方对抗评审全链路走通，抓到 harnessloop 两个真缺陷

- **场景**：hopper 引入后首个真实派发——`.hopper/queue.md` T-001，codex 对 harnessloop submodule commit 6936fbc（setup wizard 完整实现）做只读对抗评审，兼验证 `hopper-plugin/ISSUE-codex-review-hijack.md` 记录的观察点
- **现象**：①首派 400 失败——vendor 默认模型 `gpt-5.6-sol` 超出本机 codex CLI 版本；新观察点：vendor 默认模型不可信，须钉缓存模型名而非依赖 vendor 默认值 ②重派 `--model gpt-5.5`（xhigh）成功，5 分钟（299.8s），结果 REWORK + 3 findings，107,893 tokens ③派发方按 `.hopper/AGENTS.md`「Codex 评审强制核对」三项逐一核对，全部通过：审查对象确为 brief 指定的目标（真实 commit/路径）、产物落在 brief 指定路径、两条 findings 经独立复现成立 ④跨仓劫持（ISSUE-codex-review-hijack 记录的已知问题）本次未复发——EXECUTION MODE 前导有效 ⑤同时坐实该 ISSUE 的另一半已知问题：review 任务在 codex 落地时仍是 `danger-full-access`，实证「不可靠地降级为只读」——只读性目前只能靠 brief 约定，没有机械保证 ⑥`--watch` 两次（首派失败、重派成功）均在终态正确退出，无悬挂
- **预期**：hopper 的 dispatch 生命周期（init-tasks → 预检三连 → dispatch → watch → result → 强制核对）应在真实任务上端到端可用，且暴露的观察点应可沉淀为后续验证清单（依据 `.hopper/AGENTS.md` Codex 评审强制核对条款、`hopper-plugin/ISSUE-codex-review-hijack.md`）
- **插件改动**：hopper 无改动（本轮为纯使用验证，未触及 hopper-plugin/ 任何文件）；harnessloop 因本次 findings 另开修复任务 TH-0009（见对应 evolution issue）
- **复验结果**：✅ 全链路走通——init-tasks → 预检三连 → dispatch → watch → result → 三项强制核对，均按预期完成
- **遗留**：finding 3（validate fixture 自证性问题）记录为已知局限，暂不重构；codex 默认模型不可信问题可考虑上报 hopper 上游，建议增加缓存模型名的 fallback 机制，避免 vendor 端默认值漂移导致派发直接 400

---

## 2026-07-17 setup wizard goal 完结：S4 live 验收通过，首个 dogfooding goal 达成

- **场景**：用户亲自 live 首跑 setup wizard（goal 20260716-001-setup-wizard round 0004，S4 live acceptance）——`/reload-plugins` 热加载插件后直接运行 `$harnessloop-setup`，无需重启会话
- **现象**：wizard 审阅模式正确识别既有五文件完成度 4/5，仅追问缺失类别（External Tools），用户选择记录 GitHub 条目；哨兵写入符合设计（`.harnessloop/setup/data-sources.md` External Tools 表新增 GitHub 行，user-confirmed）；完成度报告全部符合设计预期。另有一项新发现值得记录：`/reload-plugins` 热加载即刻生效，无需重启整个会话——这是比"重启会话"更快的插件生效路径，此前 round 0002 evidence-index.md E4 曾记录"已加载的 SKILL 文本钉在会话启动快照，落后于磁盘"的局限，本次实测 `/reload-plugins` 可绕开该局限，值得在后续 dogfooding 中优先尝试
- **预期**：wizard 五步流程（含审阅模式的"仅问缺口"设计）应在真实项目上端到端可用，而非仅在骨架项目/dry-run 中验证（依据 goal.md Success Condition 与 rounds/0003 round-summary.md Next Proposed Scope）
- **插件改动**：未改动（本条为纯验收记录，round 0003 已完成全部实现交付，round 0004 仅为 S4 live 验收 + 三项 Required Human Decisions 收口，未触及 harnessloop/ submodule 任何文件）
- **复验结果**：✅ 通过。`check_setup.py` 复核本项目返回完成度 5/5、`complete: true`，exit 0；收盘门 `verify_protocol.py` exit 0
- **遗留**：无。goal 20260716-001-setup-wizard 三项 Required Human Decisions（live 首跑、三档预设默认值"保持默认"、"7/7→8/8"阈值表述更新）全部解决，goal 判定 achieved 并归档（见 `.harnessloop/goals/20260716-001-setup-wizard/goal.md` ## Status、`.harnessloop/goals/20260716-001-setup-wizard/rounds/0004/decision.md`）。TH-0008（第三类 Rule B 误报，框架级问题）仍 open，与本 goal 归档无关，留待独立处理

---

## 2026-07-16 P1 setup wizard：harnessloop 首个 dogfooding goal 三轮完成

- **场景**：用 harnessloop 自身协议开发 setup wizard（goal 20260716-001-setup-wizard，rounds 0001-0003：round 0001 design 首次对抗评审 negative → round 0002 design-v2 复审 positive → round 0003 implement 先对抗评审 negative 后 minimal-fix 复核通过）
- **现象**：对抗评审两轮 negative 各拦下真实缺陷——设计轮（round 0001）M1（continue/loop 门语义与"每步可跳过"承诺自相矛盾，实测锁死本项目自身 continue）、M2（cost-context-policy 29 槽位判定算法无小节作用域定义、不可无歧义求值）、M3（lite 档 Evidence contract revision 条款与 harnessloop-evidence SKILL 强制人工确认硬约束冲突）三处必修项，另有 S1-S10 十项建议修复；实现轮（round 0003）M-A（wizard SKILL 引用不存在的 `todo_count` 字段、保留已废弃合并语义）、M-B（表格数据行判定过松、S1 哨兵锚定被任意杂文本旁路，实测证伪）、M-C（新技能家族配套缺口——`agents/openai.yaml` 与三处文档技能清单，scope-lock 规划遗漏）三处必修项，均按 minimal-fix 修复。机械门（verify_protocol.py Rule B）三类实战误报全部处置：TH-0006（正则/glob/裸域名等 6 条误报，已修复）、TH-0007（解析基准缺 `.harnessloop` 根导致 6 条误报，已修复，且是 round 0002 严格审查提前预测方案的逐字应验）、TH-0008（第三类——讨论语境中间目录相对片段误报，仍 open，已提出"项目树后缀匹配回退"增强提案，当前以 `verify:ignore` 手工止血 3 条）。文件契约两次纠正主会话转述漂移：一次是 round 0001 对协议硬约束的核对过程中，manifest "90 槽位"总数以设计文档原文为准较正，未被会话转述带偏；另一次是 round 0002 decision.md 裁决 (a) 纠正的"等核心文件"被主会话简化转述为"任一文件"（round 0001 decision.md:18 原文核实后以文件原文为准）。scope-lock 在 round 0003 内从 v1 扩围至 v2，走的是 control-contract.md 既定的"Scope-lock mutation: main session 自主（版本递增留痕）"授权路径，而非临时越权。另沉淀一条委派模式经验：批准的规格偏离（todo 双字段方案）必须同步广播给全部并行代理——本轮因未同步广播致 3 处接缝失配，主会话集成审查抓 2 处、对抗评审补抓 1 处
- **预期**：协议各机制（评审门/机械门/scope-lock/self-audit/决策留痕）应在真实 goal 中全部被触发且有效，而非仅存在于文档描述（依据 harnessloop/AGENTS.md 与 harnessloop-loop SKILL 协议条款）
- **插件改动**：harnessloop submodule 待提交 0.11.0（新增 `harnessloop-setup` skill + `check_setup.py` + `control-contract-profiles.md`；四个既有 SKILL.md 接线；`validate.py` 新增第 3 阶段共 8 阶段 28 断言；`harnessloop-setup/agents/openai.yaml`；README.md/docs/usage.md/docs/harnessloop-framework.md 三处技能清单更新）
- **复验结果**：✅ `npm run validate` 8/8（含新增断言，合计 28 断言全绿）；`claude plugin validate --strict` 通过；`verify_protocol.py` exit 0（TH-0008 三条 `verify:ignore` 豁免不影响判定）；所有新增 Python 代码在本机 Python 3.9.4（pyenv）实测无异常
- **遗留**：S4 live acceptance 待用户重启会话运行 `$harnessloop-setup` 首跑（round 0004，见 `.harnessloop/goals/20260716-001-setup-wizard/rounds/0004/scope-lock.md`）；TH-0008 增强提案待上游评估假阴性风险后决定是否实现；三档预设（lite/standard/strict）默认值最终措辞与 thresholds.md/setup/data-sources.md 中"7/7→8/8"阈值表述两项 Required Human Decisions 待用户确认

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
