# Thresholds

> **阶段标注**：本 goal 当前处于需求分析（Requirement Analysis）阶段。本文件的验证口径按阶段区分——**需求分析阶段（RA-L1–L4）验证 = 用户逐级确认 + 各级规格自洽性检查**；**dev 阶段（原型/编码/集成）具体验证命令待 RA-L4 dev-readiness gate 后定**，技术栈未选型前无法预先写死。

## Data Thresholds

| Threshold | Applies to | Required state | Freshness | Drift check | Evidence |
| --- | --- | --- | --- | --- | --- |
| 需求分析产出以用户确认留痕为准 | RA-L1–L4 各级展开文档 | 各级展开文档 + 对应用户确认记录（非会话内转述，须落盘） | 每级用户确认时冻结，不回改已确认级 | 与 `goal-breakdown.md` 各级状态字段（pending/confirmed）比对 | 各级展开文档路径 + AskUserQuestion 留痕 |
| RA-L3 设计研究以 hopper 产物文件为证据 | RA-L3 技术选型决策记录（goal.md Acceptance Criteria #3） | hopper dispatch 产物文件存在且非占位（非会话内转述） | RA-L3 轮次内新鲜产出，不复用旧研究 | 产物文件时间戳 vs RA-L3 轮次时间窗对比 | hopper 产物文件路径（`.hopper/` 下具体路径，RA-L3 执行时确定并回填本表） |
| 外部项目基线待确认 | openclaw / hermas / newapi / codex-app-sdk / claude-code-sdk 相关声称 | 不得凭记忆或训练知识臆造这些项目的能力、接口或版本；须以 RA-L3 调研产物为准（见 data-contract.md Invalid Evidence） | RA-L3 调研时确定，随外部项目自身版本变化需重新核实 | 调研产物 vs 实际项目文档/仓库比对 | RA-L3 调研文档（路径待 RA-L3 执行时回填） |

## Verification Thresholds

| Threshold | Applies to | Command/check | Pass condition | Fail condition | Evidence path |
| --- | --- | --- | --- | --- | --- |
| 需求分析阶段验证 | RA-L1–L4 全部 | 用户逐级确认门 + 各级规格自洽性走查（无跨级矛盾、TODO 均有明确 owner、无未标注的臆造能力声称） | 用户明确确认通过，且自洽性走查未发现未解决冲突 | 用户要求修改，或自洽性走查发现矛盾/遗漏/臆造声称 | 各级展开文档 + 用户确认记录 |
| dev 阶段验证命令 | dev 分解（RA-L4 后注入，原型/编码/集成/收口） | TODO (owner: 待 RA-L4 dev-readiness gate 用户签署后定，属预期而非缺口——技术栈尚未选型，无法预先写死具体命令) | TODO (owner: 待定) | TODO (owner: 待定) | TODO (owner: 命令确定后回填本行) |
| 每轮 adversarial review 引用证据路径 | 每个执行轮（RA-L1 起所有 round） | 对抗性评审走查证据路径是否可达、是否为本 goal 实际产出 | 证据路径存在且可验证，无臆测/未落盘结论 | 证据路径缺失、不可达，或引用未经调研的外部项目能力假设 | 各轮 `rounds/NNNN/reviews/adversarial-review.md` |
| 连载文章成稿需用户发布确认 | goal.md Acceptance Criteria #6（里程碑文章 ≥ 3 篇） | 用户逐篇确认发布 | 用户明确确认通过 | 用户未确认、要求修改，或未走确认流程即视为发布 | PR wiki `drafts/` 文件 + 用户确认记录（human-confirmation） |
| 协议门 | 每轮收盘/continue 门 | `verify_protocol.py`（本项目协议门） | exit 0 | 非 0 或协议门报错 | `verify_protocol.py` 命令输出 |

## Runtime Thresholds

| Runtime surface | Validation method | Pass condition | Observation window | Evidence path |
| --- | --- | --- | --- | --- |
| `verify_protocol.py` | 本地命令（机械协议门） | exit 0 | 每轮收盘/continue 门 | 脚本输出 |
| server API（技术栈待 RA-L3 调研选型） | TODO (owner: 待 RA-L4 dev-readiness 后定) | TODO (owner: 待定) | TODO (owner: 待定) | TODO (owner: 待定) |
| agent app 消息流屏障 / 内核切换（技术栈待 RA-L3 定） | TODO (owner: 待 RA-L4 dev-readiness 后定) | TODO (owner: 待定) | TODO (owner: 待定) | TODO (owner: 待定) |
| console（技术栈待 RA-L3/RA-L4 定） | TODO (owner: 待 RA-L4 dev-readiness 后定) | TODO (owner: 待定) | TODO (owner: 待定) | TODO (owner: 待定) |

## Threshold Change Policy

- Requires human confirmation: yes（技术选型与阈值变更需用户确认，见 goal.md Required Human Decisions）
- Requires new round: TODO (owner: 待 RA-L3 定)
- Drift risk: TODO (owner: 待 RA-L3 定，需评估技术选型对既有阈值的漂移影响)
