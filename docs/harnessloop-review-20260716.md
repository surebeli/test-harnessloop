# harnessloop 插件严格审查报告

- **审查对象**：harnessloop 0.10.0（submodule @ `7e25e84`，即 Python 3.9 修复后）
- **日期**：2026-07-16
- **方法**：10 个独立审查视角（7 常规 + 3 主动性/易用性专项）并行深挖，每条发现由独立怀疑者 agent 实际读文件/构造 fixture 复现或证伪，severity 经复核校准。共 97 个 agent、约 470 万 token。
- **结果**：**80 条确认**（high 8 / medium 40 / low 32；实现成本 S 55 / M 24 / L 1），7 条被证伪剔除，0 条存疑。
- **机器可读全文**：`docs/harnessloop-review-20260716.findings.json`（含每条的 claim/evidence/suggestion/复核理由）

## 总体判断

框架的协议设计是认真的，作者的自我认知（adversarial-review-p0.md）大体诚实——m7、nm11 复测仍在，与作者声明一致。但审查暴露出三个**系统性**问题，都不是单点 bug：

1. **"代码保证下限"的主线没有兑现到运行时**——机械校验工具随插件发行，但在已安装项目中要么零触发路径、要么路径不可解析。协议的机械下限实际为零。
2. **文本多副本已经产生规范分叉**——同一语义（证据枚举、feedback 允许动作、委派矩阵、子命令语义）在 2–4 处重复维护，且已实际漂移；作为参考范例的 mock-project 系统性落后模板 12+ 处。
3. **协议是纯被动的**——init 之后 12 个空模板无人认领，没有 setup 完成度概念，可自动检测的信息（环境、git、测试命令）反而要求用户手填，blocked 时的提问无结构化格式。

## 十大优先建议（合并去重后）

### P0 —— 修复后才适合开始实战（影响正确性/可信度）

**1. 把 verify_protocol.py 接入运行时协议**（3 视角命中；S）
机械门存在但 12 个 SKILL.md 无一指示在真实项目中运行它，cost-model.md 却把它列为运行时拦截来源。最小改动：loop SKILL.md 的 Loop Continuation 步骤 1 前增加"运行 `verify_protocol.py --project <target>`，非零即本轮 blocked(contract-insufficient)"；continue 门同样前置。

**2. 修复 round_cost.py 重复计费**（2 视角独立实测 2.3–4.1x 虚高；M）
同一条 assistant message 的多行 transcript usage 记录被重复累加。成本模型是 0.10.0 的招牌能力，账单虚高 2–4 倍会让"由数据决定 ROI"的立论直接失效。按 message id 去重即可，需补 fixture 断言。

**3. 修复安装后脚本路径不可解析**（2 视角命中；S）
harnessloop-secrets SKILL 硬编码仓库相对路径，在已安装项目中 channel_params.py 不可达——模型将退回手工编辑 JSON，**丧失全部机械 redaction 保证**；round_cost/init 的调用写法三种并存。统一改为 `<plugin-root>` 相对定位并在 validate 中断言。

**4. secrets 机械保证补洞**（S×3 + M×1）
明文值 0644 权限 + 非原子写入；set→add 转换存储方式时明文残留且 sensitivity 静默降级；audit 只查 .gitignore 文本行，store 已被 git 跟踪时仍报 protected；被跟踪工件（transfer packet、evolution issue）的"无密钥"约束纯靠散文自报。前三条各为小修；第四条建议加一个对被跟踪 `.harnessloop/**` 文件的正则 secret 扫描（token/PEM/AKIA 等特征）进 verify_protocol。

### P1 —— 协议一致性与主动性（影响可用性/一致性）

**5. Setup 漏斗重建：init 后的引导式配置**（4 视角、6 条发现合并；L，唯一的 L）
根因：loop SKILL 唯一的填表指令位于"若 .harnessloop/ 不存在"分支内，init 成功后永远短路。建议新增 setup wizard 环节（五步：自动检测环境 → AskUserQuestion 引导 data-sources → cost-context-policy 默认值确认 → control-contract 选项式确认 → 写 self-check 并报完成度 N/5）+ status/continue 增加 `setup-incomplete` 状态 + 机械可检的"模板未填"判定（模板全为空冒号行，可脚本检测）。这是主动性方向的核心工程。

**6. environment.md 自动检测 + control-contract 预设档位**（S + M）
环境分类/可用委派机制/模型名是会话内零成本可知的事实，却以空模板交给用户；control-contract 约 20 个策略字段无 lite/standard/strict 预设（协议全文无 profile 概念，对应作者 P1-3 未兑现）。

**7. 枚举统一 + 跨文件断言**（S×4）
证据类型三套并存（loop 正文漏 runtime、human-confirmation 无落盘目录）；evidence SKILL 输出契约与 evidence-index 模板取值几乎零重叠（acceptance effect: allow/block/needs-review/no-change vs pass/fail/neutral/blocked）；issue record（11 类）与 analyze（7 类）分类法不兼容；decision.md 枚举零校验且 shipped 示例自用非法值 `local-write`。修法：以模板为唯一权威 + validate.py 增加跨文件枚举断言。

**8. mock-project 重生成**（M）
12+ 处结构漂移（eval 矩阵 10 维 vs 模板 13 维、self-check 7 字段 vs 12、round-summary 缺 ## Cost……）。实战项目照抄 mock 会学到过时协议。用 init_project.py 重生成骨架再填样例值，validate 增加 mock-vs-template 小节标题断言防再漂移。

**9. loop SKILL.md 去重瘦身**（M）
500 行中约 1/3 与 9 个独立 skill、模板重复，且已产生实际分叉（negative feedback 允许动作集三处不一致）。收敛为"loop 只保留协议主干 + 指针"，子命令语义以各 skill 为唯一权威。顺带解决 12 条 description ~1.05k token 常驻成本与 loop description 无关键词门槛导致的误触发面。

**10. 反死循环机械化**（M；协同 #1）
"相同 next action 最多 2 次、scope-lock 版本必须变化、stale evidence=0"等确定性信号全靠 agent 自评自填——用协议自身对付协议违规。这些信号可计算：作为 verify_protocol 的 Rule C/D 落地（current↔goals 对账、decision 枚举、round 完结文件完整性、handoff 命名与归档、evidence-index↔evidence/ 对账各为一条正则/os.walk 级别的检查）。

### P2 —— 设计债与平台真实性（记录在案，按需推进）

- **协议设计缺口**：多 goal 并发/依赖未定义（current.md 只有单数 Active goal）；每轮 8–10 文件的固定开销无成文裁剪路径（"single-round task"出现 3 次但零定义）；runtime-recoverable 恢复轮无"返回地址"、连续恢复轮无上限；**元任务适配**（用 harnessloop 迭代 harnessloop 时 local-repair vs evolution-issue 二分坍塌——对本项目直接相关，实战中需要自定约定）。
- **平台真实性**：round_cost 仅支持 Claude Code 但对 Codex 无条件强制执行且 README 未披露；CI 三平台矩阵只跑 Python 3.12 单版本（3.9 崩溃因此逃逸，已实证）；init-project.sh 裸 `python` 在 stock macOS 直接失败（validate.sh 已修而它漏改）。
- **运行期主动性**：blocked 七分类的提问无结构化格式（应给 AskUserQuestion 模板）；status 报"卡在哪"不报"你需要提供什么"，inconsistent 无恢复路径；self-audit 发现死循环只写文件，用户无感知；脚本 exit 1/2 的 stderr 不给下一步。
- **可发现性**：Claude Code 真实调用形态 `harnessloop:harnessloop-*` 全仓库零处文档化；27 个模板中 9 个运行时核心模板从未被任何文档点名；`harnessloop contract control` 是列为官方别名的孤儿子命令。

## 与作者已知问题的对照

| 作者已知 | 复测结论 |
| --- | --- |
| m7（scope-lock 不管 rounds/ 之外） | 仍在；本审查给出 git 快照对账的低成本机械化方案 |
| nm11（pathish 误报） | 仍在；实测裸域名 URL 引用致合规轮 EXIT 1 |
| nm12（文档骨架校验可掩蔽） | 仍在 |
| n9（最低 Python 版本未声明） | 仍在且已实际咬人（TH-0001，3.9 崩溃）；CI 单版本是根因 |
| P1-3（lite profile） | 未兑现，且固定开销问题比作者预估更重 |

## 被证伪的 7 条（透明度记录）

含"init 崩溃后无恢复路径"（重跑幂等补齐，本项目已实测）、"round_cost 归因在 dogfooding 上必然饱和失效"、"跨会话恢复无 resume brief"等——详见 findings.json 的 `refuted_titles`。证伪理由多为"协议其它文件已有覆盖"或"与实测行为不符"，说明发现层的假阳性率约 8%，复核层有效。

## 对本项目实战的直接指引

1. **修复顺序建议**：P0 的 #1/#3/#4（全是 S）+ #2（M）先行——它们影响的是"证据可信度"本身，正是我们要实战检验的核心；#5 setup wizard 建议作为第一个正式 goal 用 harnessloop 自己开发（dogfooding 元任务，同时检验 P2 记录的元任务适配缺口）。
2. **实战中的观察点**：每轮收盘时核对 round_cost 输出与直觉是否偏差 2–4 倍（#2 修复前）；review 引用外部 URL 时注意 nm11 误报；多 goal 场景主动避开（未定义行为）。
3. 所有修复在 submodule 内完成后按 TH-xxxx 序列记 evolution issue，`npm run validate` 回归，经 `scripts/plugin-reinstall.sh` 重装复验。

---

## 附录：全部 80 条确认发现


### 协议跨文件一致性（8 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| medium | M | mock-project 系统性落后模板：除已知 3 处外新增至少 12 个文件结构漂移，含非法枚举值 local-write，且 validate 无 mock-vs-template 校验 | `examples/mock-project/.harnessloop/evals/matrix.md` | 按当前模板重生成 mock-project（init_project.py 已能从模板产出正确骨架，state 类文件可直接重生成再填样例值），并在 validate.py 增加一个『mock 文件必须包含对应模板的全部小节标题/表头列』的机械断言，防止下次模板演进再次静默漂移。 |
| medium | S | 证据类型枚举三套并存：loop SKILL 正文两处规范性清单漏掉 runtime，human-confirmation 类型无落盘目录 | `…skills/harnessloop-loop/SKILL.md` | 以 evidence-index-template 的 5 类为唯一权威：修正 loop SKILL.md:57 与 :438-443 补入 runtime；在 README Evidence classes 补 human-confirmation；在 Round Structure 说明 human-conf… |
| medium | S | harnessloop-evidence 输出契约的 artifact health / claim support / acceptance effect 三个枚举与 evidence-index 模板取值表几乎零重叠 | `…skills/harnessloop-evidence/SKILL.md` | 统一为一套枚举（建议保留模板侧 pass/fail/neutral/blocked 语义，因 decision.md/feedback 已用同族词），把 SKILL 输出契约的三行改为引用 evidence-index-template 的取值；若确需区分『契约动作对继续执行的影响』与『证据对轮次验收的影响』，给… |
| medium | S | verify_protocol.py 机械门未接入任何 SKILL/模板流程：安装后的项目中永远不会运行，但 cost-model.md 把它列为运行时拦截来源 | `…skills/harnessloop-loop/SKILL.md` | 在 loop SKILL 'Loop Continuation' 第 1 步前增加一步：运行 `python <skill-dir>/scripts/verify_protocol.py --project <target-project>`，非零退出时该轮不得标记 positive、违规写入 decision.… |
| medium | S | 内置脚本调用路径三种写法并存，secrets 与 round_cost 的写法在安装后的项目中不可解析；round_cost 仅支持 Claude Code 却对 Codex 无条件要求执行 | `…skills/harnessloop-secrets/SKILL.md` | 统一为 <skill-dir>/ 或 <plugin-root>/ 占位符写法（secrets 6 条、loop:485、round-summary 模板各改一处）；在 loop SKILL 的 cost 步骤加环境条件：仅 claude-code 环境运行 round_cost.py，其余环境直接记 'cost… |
| low | S | harnessloop-issue 的 record（11 类）与 analyze（7 类）两套分类法互不兼容，analyze 产出的 3 个类别不在模板 Issue class 枚举中 | `…skills/harnessloop-issue/SKILL.md` | 把两套词表显式分层：record 侧的 11 类作为『现象分类』保留在 Issue class；analyze 侧的 7 类改名为独立字段（如 Root cause class）并加进 evolution-issue-template 的 Classification 小节，使 analyze 结果有合法落点；f… |
| low | S | harnessloop-init 同一文件内对『谁运行 intake gate』自相矛盾：line 27 说 $harnessloop-intake，line 92 说 $harnessloop-loop | `…skills/harnessloop-init/SKILL.md` | 将 init SKILL.md:92 改为与 :27 一致：'…and that `$harnessloop-intake` must pass the intake gate before business execution continues'，并可补一句 gate 通过后由 $harnessloop-lo… |
| low | S | goal.md 必填字段清单（loop SKILL 与 framework.md）缺 Acceptance Criteria，与 goal-template/intake gate 要求矛盾，mock 按弱清单写导致真缺失 | `…skills/harnessloop-loop/SKILL.md` | 把 loop SKILL.md:230 与 framework.md 的 must-state 清单补齐为 6 项（+acceptance criteria、+source of truth，或注明 source of truth 可选），并随 mock 重生成一并修复 mock goal.md。 |

### Python 脚本正确性（8 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | M | round_cost 对同一 assistant message 的多行 usage 重复累加，成本高估 2.3x–4.1x | `…skills/harnessloop-loop/scripts/round_cost.py` | 在 settle() 内维护 seen_message_ids 集合（settlement 窗口内），对 message.get('id') 已见过的行跳过累加（重复行的 usage 逐字段相同，取任一即可）；无 id 的行保持现状。因重复行相邻，需与 marker 推进逻辑配合：确保同一 message 的多行… |
| medium | S | verify_protocol Rule B 的 bases 缺 project/.harnessloop，6/10 个 PATHISH_PREFIXES 的引用必然误报 dangling-citation | `…skills/harnessloop-loop/scripts/verify_protocol.py` | 在 verify_round 为 Rule B 使用 citation_bases = [project, project/'.harnessloop', goal_dir, round_dir]（只加给引用存在性检查，避免顺带放宽 Rule A 的 allowed 判定），并为 6 个短前缀各加一条正向 fix… |
| medium | S | channel_params 把明文 secrets 写成 0644 且非原子写入；store 损坏后包括 init 在内所有子命令都无法恢复 | `…skills/harnessloop-secrets/scripts/channel_params.py` | write_json 改为：写临时文件（os.open 带 0o600 或写后 chmod）→ os.replace 原子替换；对已存在的 store 在写前 chmod 0600。read_json 遇损坏时保留 .corrupt 备份并提示恢复命令，至少让 init 能重建空 store 而不是死锁。 |
| low | M | round_cost 行数 marker 会吞掉未写完的尾行，该 turn 的 usage 永久丢失 | `…skills/harnessloop-loop/scripts/round_cost.py` | marker 改存字节偏移而非行数：读取时记录最后一个以 \n 结尾的完整行的 f.tell()，未终止的尾行不消费、留给下一窗口（与重复计数修复一并处理，保证同一 message 的相邻多行不被窗口劈开）。 |
| low | M | verify_protocol 对 scope-lock 里的 glob 通配符按字面比较，合规文件被误报 scope-lock-violation | `…skills/harnessloop-loop/scripts/verify_protocol.py` | 在 allowed 判定中对含 */? 的 span 走 fnmatch/pathlib.match 分支（对 norm 后的相对路径匹配）；或最小改动：检测到含通配符的 span 时报专门的 'unsupported-glob-in-scope-lock' violation，把静默作废变成显式报错。 |
| low | S | channel_params add 的'更新'语义破坏：二次 add 把已有 sensitivity/storage 静默重置为 unknown | `…skills/harnessloop-secrets/scripts/channel_params.py` | 与 cmd_set 对齐：把 add 的 --sensitivity/--storage 默认值改为 None，构造 param 时用 `args.sensitivity or existing.get('sensitivity', 'unknown')`（storage 同理），仅在显式传参时覆盖。 |
| low | S | verify_protocol 遇非 UTF-8 的 scope-lock/review 文件直接裸 UnicodeDecodeError traceback，--json 消费者拿不到结构化输出 | `…skills/harnessloop-loop/scripts/verify_protocol.py` | 两处 read_text 改为 errors='replace'（与 round_cost 一致），或 try/except UnicodeDecodeError 转成 kind='unreadable-file' 的 violation，保证 --json 契约在任何输入下成立。 |
| low | S | init_project 纯 CJK/非 ASCII intake slug 直接未捕获 ValueError traceback，中文 slug 完全不可用 | `…skills/harnessloop-loop/scripts/init_project.py` | 最小改法：slug 归一为空时回退为纯时间戳目录名（如 20260716-1810-intake）并在输出中提示；或把字符白名单放宽为 \w（unicode）保留 CJK；同时在 main() 捕获 ValueError 输出单行错误并 return 2。 |

### 机械强制力缺口（9 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | S | verify_protocol.py 在用户项目中零触发路径：机械门存在但协议从不运行它 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 最小改动（S）：在 harnessloop-loop/SKILL.md『Loop Continuation』第 1 步前插入『run python <skill-dir>/scripts/verify_protocol.py --project <target-project>; 非零退出时本轮不得 accept… |
| medium | M | m7 复测仍在：scope-lock 对 rounds/ 之外的写入（含真实源码）完全不可见，可用 git 低成本机械化 | `plugins/harnessloop/…skills/harnessloop-loop/scripts/verify_protocol.py` | 低成本 git 地基方案（项目本就是 git 仓库）：round 开始时在 .harnessloop/local/round-marker.json 记录 HEAD sha（仿照 round_cost.py 的 cost-marker.json 增量窗口模式）；verify 新增 Rule A2——`git di… |
| medium | M | self-audit 触发条件与 Deterministic Signals 完全可计算却全靠模型手填 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 两步机械化：(1) Rule G 触发校验——扫描全部 decision.md，最新一条 negative/neutral/blocked 之后 self-audit.md 若无匹配 `Active round:` 的条目则报 `self-audit-missing`；(2) 让 verify --json 直接… |
| medium | S | decision.md 的 feedback/blocker/accepted 枚举零校验，且 shipped 示例自身已用非法枚举值 | `plugins/harnessloop/…skills/harnessloop-loop/scripts/verify_protocol.py` | 新增 Rule C（纯正则，约 30 行）：对每个 rounds/*/decision.md 解析 `- Feedback:`/`- Blocker type:`/`- Accepted:` 行，值不在 SKILL.md 声明的闭集内即报 `invalid-decision-enum`；字段缺失报 `missin… |
| medium | S | state/current.md 与 goals/ 实际状态零对账：指针悬空、feedback 互相矛盾均通过 | `plugins/harnessloop/…skills/harnessloop-loop/scripts/verify_protocol.py` | 新增 Rule D：(1) current.md 中 Active goal/Active round/Imported intake path 的反引号路径必须存在（复用现成 pathish 存在性机制）；(2) Current feedback 必须等于 Active round 下 decision.md … |
| medium | S | evidence-index 与 evidence/ 文件不对账：幽灵证据标 valid 通过，且 mock 索引表比模板少一列 | `plugins/harnessloop/…skills/harnessloop-loop/references/evidence-index-template.md` | 新增 Rule E：解析 evidence-index.md 表格行，取 Path 列反引号 span 做存在性校验（复用 Rule B 基建）；`Artifact health` 为 valid 但文件缺失 → `ghost-evidence` violation；反向对账（evidence/ 下未索引文件）先… |
| medium | S | round 完结所需文件/章节无机械校验，shipped mock 自己就缺 ## Cost 且 scope-lock 节名偏离模板 | `plugins/harnessloop/examples/mock-project/.harnessloop/goals/20260629-001-runtime-quality/rounds/0001/round-summary.md` | 新增 Rule F（约 20 行）：decision.md 存在（round 已完结）时要求 scope-lock.md 与 round-summary.md 存在，round-summary 必含 `## Cost`，scope-lock 必含 `## Disallowed Changes` 与 `## Rol… |
| low | S | nm11 复测仍在：裸域名 URL 引用被误报 dangling-citation，合规轮 EXIT 1，将反噬机械门可信度 | `plugins/harnessloop/…skills/harnessloop-loop/scripts/verify_protocol.py` | 在 :98 的 `if "/" in cleaned` 分支前加域名豁免：首段匹配 `^[a-z0-9-]+(\.[a-z0-9-]+)+$`（如 docs.python.org、github.com）则跳过并计入『N 条引用未校验』告警计数；绝对路径（以 / 开头且在项目外）同样降级为告警而非硬失败。 |
| low | S | handoff 命名规范与 closed-必归档规则无校验（一条正则可锁定） | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 新增 Rule H：对 rounds/*/handoffs/ 与 rounds/*/archive/ 下的 .md 文件套用正则 `^\d{4}-\d{2}-[a-z0-9]+-[a-z0-9-]+-(open\|closed)\.md$`，不匹配报 `handoff-naming`；decision.md 存在… |

### 协议架构设计（7 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | M | 反死循环机制全部由 agent 自评自填，negative→investigation→negative 循环没有任何机械中断点 | `…skills/harnessloop-loop/SKILL.md` | 给 verify_protocol.py 加 Rule C：读取 rounds/*/decision.md 的 feedback 序列与 scope-lock.md 内容哈希，'连续 N 轮非 positive 且 scope-lock 哈希未变'即非零退出（N 写入 control-contract.md，默认… |
| medium | M | 多 goal 并发与 goal 间依赖完全未定义：state/current.md 只有单数 Active goal，goal A 被 block 时 goal B 的转移不存在 | `…skills/harnessloop-loop/references/current-state-template.md` | 最小改动：current-state-template 把 'Active goal:' 扩为 goal 表（id / lifecycle / blocked-on / depends-on / has-open-round），continue gate 增加一条 goal 选择规则：'active goal 处… |
| medium | M | 每轮 8-10 个文件写入 + 强制委派 review + 跑成本脚本的固定下限没有任何成文裁剪路径，'single-round task' 出现 3 次但零定义（lite profile P1-3 承诺至今未落地） | `…skills/harnessloop-loop/SKILL.md` | 落实作者自己的 P1-3 但下沉到协议文件而非只写文档：control-contract-template 加 'Profile: lite\|standard\|strict' 字段；在 SKILL.md 每个 gate 处标注 lite 档行为（如 lite：review 可由主会话完成、handoff 三态… |
| medium | M | 500 行 loop SKILL.md 约 1/3 是子技能与模板内容的重复，且重复已产生实际规范分叉：negative feedback 的允许动作集在三处互相不一致 | `…skills/harnessloop-loop/SKILL.md` | Control Commands 段收缩为每个子技能一行摘要+指针（省约 40 行）；State Files 段删除字段清单只留模板指针（省约 30 行）；把 blocker 枚举、feedback 允许动作集、委派矩阵收敛到单一 references/protocol-enums.md，其余位置引用；valid… |
| medium | S | runtime-recoverable 恢复支路没有'返回地址'：恢复轮结束后四个 feedback 类没有一个语义正确，连续恢复轮次数也无上限 | `…skills/harnessloop-loop/SKILL.md` | 小改动闭合：current-state-template 加 'Resume target (goal/subgoal/round):' 字段，进入恢复轮时必填；给恢复轮定义专用出口语义——decision.md 中 positive 对恢复轮解释为'返回 resume target 而非下一个 subgoal'… |
| medium | S | 元任务（用 harnessloop 迭代 harnessloop/插件自身）时 local-repair vs evolution-issue 的上下游二分坍塌，且协议状态无版本钉扎、无法察觉'规则在脚下变了' | `…skills/harnessloop-loop/SKILL.md` | 两个 S 级动作：(a) init_project.py 在 state/current.md 或独立 state/protocol-version.md 写入插件版本与模板哈希，continue gate 加一条'版本不匹配→先跑 drift 确认再继续'；(b) 在 framework.md 加一节元任务约定… |
| low | S | 状态机边角未定义集合：goal-breakdown 耗尽但 success condition 未达时 positive 无处可去；feedback-policy 在 SKILL.md 中被定义为 3 类而 decision.md 收 4 类 | `…skills/harnessloop-loop/SKILL.md` | SKILL.md:252 后补一句：'Blocked feedback handling must also be defined; see feedback-policy template'；SKILL.md:489 补分支：'若无剩余 subgoal 而 success condition 未满足，路由 $h… |

### skill 工程与可用性（10 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | S | verify_protocol.py 机械门从未接入运行时协议：12 个 SKILL.md 无一指示在真实项目 loop 中运行它 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 在 loop SKILL.md 的 Loop Continuation 第 1 步（与 round_cost.py 并列）加一条：round 结束前必须运行 `python <skill-dir>/scripts/verify_protocol.py --project <target> --json`，非零退出… |
| medium | M | loop SKILL.md 内嵌的 9 个子命令语义与 9 个独立 skill 是两份需同步的文本，且已实际漂移 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 把 Control Commands 段压缩为单行路由表（子命令 → 'route to harnessloop-X skill' + 一句安全边界），语义细节以各独立 SKILL.md 为唯一事实源；blocker 七分类只保留在 continue SKILL.md，其余处引用。每次 loop 加载省 ~1.5… |
| medium | S | harnessloop-loop 的 description 无 Harnessloop 关键词门槛，user-scope 安装后会对任何『长任务』误触发 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 重写 loop description 首句为双条件触发：『项目存在 .harnessloop/ 状态、或用户明确提及 Harnessloop/harnessloop:loop 时』；把 'long-running goal-driven task' 降为补充说明而非首要触发词。 |
| low | M | 三种命名形态并存，而 Claude Code 真实调用形态 harnessloop:harnessloop-init 在全仓库零处文档化 | `plugins/harnessloop/README.md` | 两选一：(a) 技能目录去掉 harnessloop- 前缀（init/loop/status...），使 Claude Code 形态自然变成 harnessloop:init——『别名』升级为真名，13 处免责句全部删除（需评估 Codex $-mention 裸名冲突风险）；(b) 保守方案：README/… |
| low | S | 27 个模板中 9 个运行时核心模板（含 scope-lock/adversarial-review）在任何 SKILL.md/docs 中从未被点名，可发现性靠猜文件名 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 在 loop SKILL.md 的 Goal Structure 与 Round Structure 段各加一个两列映射表（协议文件 → references/ 模板路径），并在 Verification Phase 点名 adversarial-review-template.md；顺带在 scope-lock… |
| low | S | 执行委派矩阵与模型策略在 4 处重复，且 SKILL.md 硬编码 gpt-5.5/Sonnet 型号会与项目自己的 cost-context-policy.md 冲突 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | loop SKILL.md 删除具体型号，改为『以项目 setup/cost-context-policy.md 的 Model Policy 为准；未填写时保守：不委派或人工确认』；矩阵在 SKILL.md 只保留列名+一行摘要，全文仅存于模板（项目文件才是运行时被读的那份）。每次 loop 加载再省 ~700… |
| low | S | 12 条 description 共 ~4.2k 字符（≈1.05k tokens）每会话常驻，channels/connectivity 两条互为近重复且枚举名词制造误触发面 | `plugins/harnessloop/…skills/harnessloop-channels/SKILL.md` | 两条 description 收敛为『Harnessloop 声明的外部通道清单（不探测）』/『Harnessloop 声明的连通性检查（缺参数必问）』量级的短句，名词枚举移入正文；家族整体以 'harnessloop' 前置限定词开头统一触发风格，目标把常驻开销压到 ~600 tokens。 |
| low | S | init→后续技能的交接路由绕过了专职技能：已初始化时指向 loop 而非 status/continue，定义目标指向 loop 而非 goal | `plugins/harnessloop/…skills/harnessloop-init/SKILL.md` | init 的两处路由改为：已初始化 → $harnessloop-status（查看）/$harnessloop-continue（推进）；初始化完成 → $harnessloop-goal propose 定义目标，goal 就绪后才进 $harnessloop-loop 开第一轮。 |
| low | S | 双 plugin.json 结构分叉（skills 字段类型不同、interface 仅 Codex 有），版本号散布 4 处且 validate.py 不校验版本一致性 | `plugins/harnessloop/plugins/harnessloop/.claude-plugin/plugin.json` | validate_manifests 增加一条断言：package.json、两个 plugin.json、claude marketplace entry 四处 version 字符串相等；顺带断言两 manifest 的 description 一致，把同步义务交给红灯。 |
| low | S | 『harnessloop contract control』是孤儿子命令：列为官方别名却无独立技能、无 $ 形态、无任何 description 提及，冷启动不可触发 | `plugins/harnessloop/…skills/harnessloop-loop/SKILL.md` | 最小改动：把 control-contract 管理语义并入 $harnessloop-continue 的 description 与正文（'update continuation rules / control contract' 触发词），loop:204 段改为指向 continue 的路由行；或删除该别… |

### 文档真实性（7 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | S | round_cost.py 对同一条 assistant message 的多条 transcript 记录重复计费，实测 token 虚高 2.6–3.1 倍 | `…skills/harnessloop-loop/scripts/round_cost.py` | settle() 内按 message.id 去重（同一 id 只计一次 usage，保留最后一条；无 id 的记录按现状计），protocol 归因改为把同一 id 的各记录 content 拼接后再判 '.harnessloop'；并在 validate.py 第 6 关合成 transcript 中加入『同… |
| medium | M | cost-model.md 判断框架以『Protocol share of round cost』为准绳，但工具只能输出『protocol share of output tokens』，协议侧 input/cache/美元份额均不可得 | `docs/cost-model.md` | usage 本就按 turn 记录，归因循环里同时累加 protocol_input/cache_write/cache_read；有价格文件时输出『protocol-attributed estimated cost: $X (Z% of round cost)』，判断表直接引用该字段；无价格时明确说明表格分档… |
| medium | S | CI 三平台矩阵只跑 Python 3.12 单版本；3.9 兼容性崩溃已实际逃逸到用户（commit 7e25e84 补救），最低 Python 版本至今未声明也未被 CI 锁定 | `.github/workflows/validate.yml` | 在 matrix 增加 python-version 轴 ["3.9", "3.12"]（至少 ubuntu 跑 3.9 即可，成本一个 job），并在 README『Validate』段声明『Requires Python >= 3.9』；validate.py 开头加 sys.version_info 检查给… |
| medium | S | init-project.sh 用裸 `python` 无任何 Python 3 探测，stock macOS 上 README 文档命令直接失败——同类问题 validate.sh 已修而此脚本漏改 | `scripts/init-project.sh` | 把 validate.sh 的 Python 3 解析循环原样复制进 init-project.sh（改为 exec "$PYTHON" .../init_project.py "$@"）；顺手在 validate.py 加一条断言防再漂移（如检查 init-project.sh 不含行首裸 `python `）。 |
| low | S | SKILL.md 强制每轮收尾运行 round_cost.py，但脚本仅支持 Claude Code transcript——Codex 平台上该协议步骤必然失败且 README 未披露 | `…skills/harnessloop-loop/SKILL.md` | 最小改动：SKILL.md 第 1 步改为『当 state/environment.md 为 claude-code 时运行 round_cost.py；其他环境记录 cost unavailable: unsupported platform』，并在 README Cost Accountability 段与 … |
| low | S | 0.10.0 新增的第 6 验证关（round-cost smoke）未同步进 README/AGENTS 的验证器描述；README 钦定的 canonical 流程图也缺每轮成本结算节点 | `README.md` | README:262 与 AGENTS.md:9 补『round cost settlement smoke test』一项；flow.mmd 在 O{Feedback}→P[Archive round] 间加一个『Settle round cost (round_cost.py)』节点并重渲染 svg；AGEN… |
| low | S | examples/mock-project 的 round-summary.md 与 scope-lock.md 偏离自家模板：缺 ## Cost/## Decision 等全部模板节、标题命名不一致，参考示例教坏 pattern-matching 的 agent | `examples/mock-project/.harnessloop/goals/20260629-001-runtime-quality/rounds/0001/round-summary.md` | 按模板重写 mock-project 的 round-summary.md（含一个真实样式的 ## Cost 块，可标注 synthetic）和 scope-lock.md 标题；在 validate.py 第 5 关加一条廉价断言：mock-project 每个 round 的 round-summary.md… |

### 密钥与敏感数据（7 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| medium | M | transfer packet '不含 secret 值'与 evolution issue 'Redaction Boundary' 均为纯散文自报，全仓库没有任何对被跟踪/外流工件的机械 secret 扫描 | `…skills/harnessloop-loop/scripts/verify_protocol.py` | 给 verify_protocol.py 加 Rule C：对 .harnessloop/ 下除 local/ 与 intake/*/transfer-packet.md 外的全部文本文件跑一组低误报 secret 形态正则（`AKIA[0-9A-Z]{16}`、`ghp_`/`gho_`、`xox[bap]-`… |
| medium | S | secrets SKILL 硬编码仓库相对脚本路径，在已安装项目中 channel_params.py 不可达，模型将退回手工编辑 JSON，丧失全部机械 redaction 保证 | `…skills/harnessloop-secrets/SKILL.md` | 把 secrets SKILL.md:55-60 与 loop SKILL.md:485 的脚本调用统一改为 `<skill-dir>/scripts/…` 占位（与 loop SKILL.md:103 一致），并在 SKILL 开头一句话说明 `<skill-dir>` 如何解析（插件安装目录下本技能根）；在 … |
| medium | S | set 后再 add 转换存储方式时，明文 secret 值残留在 channel-params.json 且 sensitivity 被静默降级为 unknown，audit 对此全盲 | `…skills/harnessloop-secrets/scripts/channel_params.py` | cmd_add 中当最终 storage != local-file 时将 value 置 None 并在输出的 next_action 里注明 'stale local value cleared'；sensitivity 改为 `args.sensitivity if args.sensitivity != … |
| medium | S | audit 只做 .gitignore 文本行检查，store 已被 git 跟踪（含真实值）时仍报 protected/exit 0；example 文件也从不被检查 | `…skills/harnessloop-secrets/scripts/channel_params.py` | audit 在检测到 .git 时执行 `git ls-files --error-unmatch .harnessloop/local/channel-params.json`（被跟踪即 finding+exit 2）与 `git check-ignore -q`（未生效即 finding）；并解析 examp… |
| low | S | local .gitignore 双事实源已漂移：channel_params.py 的 DEFAULT_IGNORE_LINES 缺 cost-marker.json，secrets-init-在先的顺序会让 round_cost 输出（含会话 transcript 文件名）被提交 | `…skills/harnessloop-secrets/scripts/channel_params.py` | 向 DEFAULT_IGNORE_LINES 补 `cost-marker.json`；并在 validate.py 加一条断言：`set(channel_params.DEFAULT_IGNORE_LINES) == set(local-gitignore-template.txt 非空行)`，把双源锁成单一事… |
| low | S | intake/.gitignore 只忽略 */transfer-packet.md，packet 旁的任何原始上下文附件（会话导出、粘贴日志）都会被 git 跟踪 | `…skills/harnessloop-loop/references/intake-gitignore-template.txt` | 改为白名单式：`*`、`!.gitignore`、`!*/`、`!*/intake-gate.md`、`!*/gap-review.md`（gate/review 审计产物保持跟踪，其余一律 local），并在模板注释里说明'放进 intake 子目录的任何附件默认不提交'。 |
| low | S | local/.gitignore 是枚举式黑名单，SKILL 承诺的 'other local secret material' 无机械兜底：creds.json、.env 等常见形态放进 local/ 会被提交 | `…skills/harnessloop-loop/references/local-gitignore-template.txt` | 把 local/.gitignore 反转为白名单：`*` + `!.gitignore` + `!channel-params.example.json`（如希望共享价格配置再加 `!cost-prices.json`），使 local/ 语义变为'默认全部不提交'，同时天然修复 cost-marker.jso… |

### 引导式配置（主动性）（8 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | L | init 成功后 12 个空模板无人认领：loop 的 Project Setup 节被『目录已存在』条件短路，填表对话永远不会被触发 | `…skills/harnessloop-loop/SKILL.md` | 设计一个 setup wizard 环节（可放在 init 的 After Initialization、或新增 $harnessloop-setup 动作）：固定顺序五步——(1) 自动检测环境写 state/environment.md；(2) AskUserQuestion 逐项引导 setup/data-… |
| medium | M | 全协议没有『setup-incomplete』状态：status/continue/verify_protocol 都无法告诉用户『你还差什么』 | `…skills/harnessloop-status/SKILL.md` | 定义机器可检的 setup 完成度：模板字段全部形如 '- Field:' 空冒号行和空表格，可用脚本检测（新增 scripts/check_setup.py 或扩展 verify_protocol.py 一条 Rule C：setup/ 与 state/ 关键文件不得与模板逐字节相同/不得全空字段）。statu… |
| medium | M | control-contract（何时可自动续跑、何时必须停）是影响最大的用户偏好，却没有任何 skill 驱动初始确认，continue 门直接评估一份全空契约 | `…skills/harnessloop-loop/references/control-contract-template.md` | setup wizard 中加一步『控制契约确认』：插件主动提出一套保守默认值（auto-continue 仅限 positive+evidence 健康+无 open handoff；所有外部写/回滚/failed-review 接受必须 human-confirm；stop 于 access-missing/… |
| medium | M | 第一个 goal 没有引导式访谈：init 交接语指向 $harnessloop-loop 而非 $harnessloop-goal propose，goal.md 必填字段无人负责问出来 | `…skills/harnessloop-init/SKILL.md` | 两处改动：(1) init 的 After Initialization 把推荐链改为『setup 完成后 → $harnessloop-goal propose <一句话目标>』；(2) goal skill 的 propose 动作规定结构化访谈：按固定顺序用 AskUserQuestion 问 goal →… |
| medium | S | state/environment.md 要求记录『Detected environment / Available tools』，但没有任何环节指示插件在 init/setup 时自动检测填写 | `…skills/harnessloop-loop/references/environment-self-check-template.md` | 在 init 的 After Initialization（或 setup wizard 第 1 步）中明确要求：agent 立即自检并写入 environment.md 的 Detection 与 Delegation 节——检测到自己运行在 claude-code/codex、可用的委派机制（Task/sub… |
| medium | S | askuserquestion 的强制使用点全部集中在 loop 中期阻塞路径，setup 漏斗的所有决策点（init 确认、填表、契约确认）零覆盖 | `…skills/harnessloop-loop/SKILL.md` | 把 askuserquestion 的强制点扩展到 setup 漏斗：init 的 force 确认与『initializer 失败后选 repair 还是 manual fallback』分叉、setup wizard 的每个采集步（data sources 逐类、control-contract 预设选择）、… |
| low | S | init 的产出报告只列文件路径，不区分『可直接用』与『等你输入』，用户面对 12 个文件不知道从哪个开始 | `…skills/harnessloop-loop/scripts/init_project.py` | init_project.py 的 result dict 增加 needs_user_input（setup/data-sources.md、setup/cost-context-policy.md、state/control-contract.md）与 auto_fillable（state/environm… |
| low | S | 填表时没有任何环节主动引用 examples/mock-project 作为已填好的参照，用户对『合格的填法』没有样例 | `…skills/harnessloop-init/SKILL.md` | 两处低成本改动：(1) init SKILL 的 After Initialization 报告增加一行『填写参照：<plugin-root>/../../examples/mock-project/.harnessloop/ 内有同名文件的完整填写示例』；(2) setup wizard 每步问询前，agent… |

### 主动检测与自动配置（9 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| high | M | environment.md 几乎全部字段可在 Claude Code 会话内自动检测，但协议反而禁止推断且无任何自动填充步骤 | `harnessloop/…skills/harnessloop-loop/references/environment-self-check-template.md` | 在 harnessloop-loop SKILL.md 增设『Trusted in-session signals』白名单：环境变量（CLAUDECODE 等）、系统提示自述的模型 ID、当前工具枚举、一次 bounded read-only probe 子任务的实际行为（要求写指定输出路径+引用证据，回收后即同… |
| high | M | control-contract 没有 lite/standard/strict 预设档位（已核实协议全文无 profile 概念），用户须从零填约 20 个策略字段 | `harnessloop/…skills/harnessloop-loop/references/control-contract-template.md` | 新增 references/control-contract-profiles.md 定义三档完整预设：lite（个人项目：positive+evidence-fresh 即自动续跑，仅外部写需确认）、standard（默认：模板 Blocker 表+常规确认项）、strict（涉外部系统/敏感数据：所有写操作与… |
| medium | M | init 成功后产出 12 个空模板文件，没有任何 skill 环节主动带用户逐个补全 | `harnessloop/…skills/harnessloop-init/SKILL.md` | 在 harnessloop-init 的 After Initialization 增加两个主动步骤：(1) 输出 Setup 完整度报告——逐一列出 9 个可填写文件，标记 template-empty / partially-filled / complete（与 references/ 模板原文 diff … |
| medium | M | data-sources.md 完全靠用户手填，插件不扫描 repo 提出候选（测试/CI 命令、数据库配置、env 模板均可检测） | `harnessloop/…skills/harnessloop-loop/SKILL.md` | 在 Project Setup 增加『Project scan』步骤（明确区别于 invent）：glob package.json / Makefile / pyproject.toml / pytest.ini / .github/workflows / docker-compose* / .env.exam… |
| medium | M | self-check.md 各字段是纯机械可计算的（文件存在性+是否仍为空模板），却没有脚本计算，status 也不主动报 setup 完整度 | `harnessloop/…skills/harnessloop-loop/references/self-check-template.md` | 给 harnessloop-loop/scripts 增加 check_setup.py：对 BASE_FILES 中每个文件判定 missing / template-empty（与 references 模板正文一致或空冒号行占比高）/ filled，输出 markdown 直接可贴进 state/self-… |
| low | S | cost-prices.json 无引导创建：协议强制每轮跑 round_cost.py，但价格文件缺失时每轮都只打印 unavailable，永远没人主动帮用户建 | `harnessloop/…skills/harnessloop-loop/scripts/round_cost.py` | 两层修复：(1) init_project.py 的 LOCAL_FILES 增加 .harnessloop/local/cost-prices.example.json（含 4 个键的占位结构与注释）；(2) 在 SKILL.md Loop Continuation 第 1 步补一句主动规则：首次出现 unav… |
| low | S | init 不检测目标项目是否为 git 仓库，而协议的秘密保护与回滚语义全依赖 git | `harnessloop/…skills/harnessloop-loop/scripts/init_project.py` | initialize() 增加 git_repo 检测（(project/'.git').exists()，零子进程开销）写入 result JSON；main() 在 false 时打印显式警告：『目标不是 git 仓库：local/.gitignore 无法保护 channel-params.json 不被其… |
| low | S | 脚本直跑路径（usage.md 官方推荐）结束后零后续指引：next steps 只存在于 agent skill 口头约定里 | `harnessloop/…skills/harnessloop-loop/scripts/init_project.py` | main() 在文件清单后固定打印 Next steps 段：(1) 列出需要人工/引导补全的 9 个文件（按建议顺序 environment → control-contract → data-sources → cost-context-policy）；(2) 'In your agent session, … |
| low | S | init-project.sh 使用裸 python 命令，在无 python 别名的 macOS/新 Linux 上直接失败，与 3.9 崩溃同属缺失的解释器预检 | `harnessloop/scripts/init-project.sh` | 包装脚本改为主动探测：'PY=$(command -v python3 \|\| command -v python) \|\| { echo "Python 3.9+ required but not found"; exit 1; }' 再用 "$PY" -c 'import sys; sys.exit(0 … |

### 运行期主动性（7 条）

| 严重度 | 成本 | 发现 | 主要文件 | 建议 |
| --- | --- | --- | --- | --- |
| medium | M | init 成功后留下 12 个全空模板文件，没有任何 skill 环节主动带用户逐个补全，也没有 setup 完整度报告 | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-init/SKILL.md` | 在 harnessloop-init 的 After Initialization 环节加两步：(1) 主动扫描生成文件，输出 setup completeness 清单（文件 → 必填字段 → filled/empty）；(2) 立即进入引导式问答（优先 askuserquestion），按优先级逐项补全 da… |
| medium | M | blocked 七分类要求'ask for the exact missing input'，但提问没有任何结构化格式，全靠模型散文即兴 | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-continue/SKILL.md` | 新增 references/blocker-question-template.md：按七类 blocker 定义提问结构（缺失项 \| 为什么阻塞当前轮 \| 候选选项（枚举）\| 默认值 \| 期望回答格式 \| 回答后恢复动作），并在 harnessloop-continue ¶7 与 harnessloo… |
| medium | S | $harnessloop-status 报告'卡在哪'但不报告'你需要提供什么'；inconsistent 状态无任何恢复路径 | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-status/SKILL.md` | 输出契约增加两个字段：'required user input:'（逐项列出缺失输入及期望格式，blocked 时必填）和 'unblock command:'（下一条该跑的 skill，如 $harnessloop-continue / $harnessloop-secrets）。对 state=inconsi… |
| medium | S | self-audit 发现死循环只写进 meta/self-audit.md，用户在聊天里最多看到一行 'self-audit gate: fail'，不知道协议正在原地打转 | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-loop/SKILL.md` | 在 Self-Audit 一节增加用户呈现条款：dead-loop 或任何 fail 触发时，必须在聊天输出循环诊断摘要（重复的 feedback 序列、重复动作次数、涉及的轮次编号、证据增量为零的证明路径），并以 2-4 个选项（缩小 scope-lock / 回滚某轮 / 人工修订契约 / 终止目标）用 as… |
| medium | S | round_cost.py 在非 Claude Code 环境必然 exit 2，错误信息不解释原因、不提 --transcript-dir、不给环境相关出路 | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-loop/scripts/round_cost.py` | 失败路径增强：(a) 若 ~/.claude 不存在，输出'当前环境可能不是 Claude Code（如 Codex）——成本自动结算不适用，请在 round-summary.md 的 Cost 一节手记原因'；(b) 若 ~/.claude/projects 存在，列出其中与项目名最相近的目录候选并打印 `--… |
| low | S | init_project.py 成功输出只有文件清单，直跑脚本（不经模型）的用户得不到任何'下一步做什么' | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-loop/scripts/init_project.py` | main() 成功路径末尾打印 next steps：无 --intake 时输出 'Next: 1) fill .harnessloop/setup/data-sources.md and cost-context-policy.md 2) in your agent session run $harnessl… |
| low | S | verify_protocol.py 报违规后 exit 1，但不说明违规的协议后果，也不给每类违规的修复动作 | `/Users/litianyi/Documents/Code/_ai-goods/test-harnessloop/harnessloop/…skills/harnessloop-loop/scripts/verify_protocol.py` | 每类 violation 打印后附一行 'fix:'：unparseable-allowed-changes → '在 ## Allowed Changes 下用反引号包路径或使用 scope-lock-template.md 的表格格式'；dangling-citation → '修正 review 中的引用路… |
