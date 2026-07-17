# Thresholds

## Data Thresholds

| Threshold | Applies to | Required state | Freshness | Drift check | Evidence |
| --- | --- | --- | --- | --- | --- |
| 自产真实数据为主源（`.hopper/`/`.harnessloop/`/双 wiki/COST-LOG） | 四类运营视图（任务流水/成本账本/评审漏斗/知识图谱）与三源聚合面盘点 | 真实产生的数据（非模拟/非占位），来自本项目实际运行的 `.hopper/`、`.harnessloop/`、`test-harnessloop` 与 `surebeli-ip` 双 kata wiki、COST-LOG | 随每轮/每次 dispatch/每次 wiki-ingest 实时刷新 | 与各源目录实际内容比对（`.hopper/queue.md`、`.harnessloop/goals/**`、kata wiki 页 frontmatter、COST-LOG 记账行） | 各源路径本身（见 data-contract.md Valid Evidence Sources） |
| 设计研究以 hopper 产物文件为证据 | S2 技术选型决策记录（Acceptance Criteria #1） | hopper dispatch 产物文件存在且非占位（非会话内转述） | S2 轮次内新鲜产出，不复用旧研究 | 产物文件时间戳 vs S2 轮次时间窗对比 | hopper 产物文件路径（`.hopper/` 下具体路径，S2 执行时确定并回填本表） |
| 预测对账以 PR wiki 预测页为冻结基线 | Acceptance Criteria #7 | 页面状态字段（`pending`/`confirmed`/`refuted`，预测②另含 `confirmed-sequence`/`confirmed-disorder`） | 预测原文冻结于 2026-07-18，不刷新；仅通过对账更新状态字段，不改写预测原文 | diff 比对预测原文是否被意外改写 | `~/.llm-wiki/surebeli-ip/milestones/2026-07-18-app-phase-predictions.md` |

## Verification Thresholds

| Threshold | Applies to | Command/check | Pass condition | Fail condition | Evidence path |
| --- | --- | --- | --- | --- | --- |
| S2 前用协议门 | S1 discovery round | `verify_protocol.py`（本项目协议门）+ 各插件自带验证（按需：hopper smoke / kata wiki-lint 等） | exit 0 | 非 0 或协议门报错 | `verify_protocol.py` 命令输出 |
| S2 后补技术栈具体验证命令 | S3–S7 全部（server/console/app 实现与集成） | TODO (owner: 待 S2 定，属预期而非缺口——S2 尚未选型，无法预先写死具体命令) | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定，命令确定后回填本行) |
| 每轮 adversarial review 引用证据路径 | 每个执行轮（S1 起所有 round） | 对抗性评审走查证据路径是否可达、是否为本 goal 实际产出 | 证据路径存在且可验证，无臆测/未落盘结论 | 证据路径缺失、不可达，或引用未经 probe 的假设 | 各轮 `rounds/NNNN/reviews/adversarial-review.md` |
| 连载文章成稿需用户发布确认 | Acceptance Criteria #8（里程碑文章 ≥ 3 篇） | 用户逐篇确认发布 | 用户明确确认通过 | 用户未确认、要求修改，或未走确认流程即视为发布 | PR wiki `drafts/` 文件 + 用户确认记录（human-confirmation） |

## Runtime Thresholds

| Runtime surface | Validation method | Pass condition | Observation window | Evidence path |
| --- | --- | --- | --- | --- |
| `verify_protocol.py` | 本地命令（机械协议门） | exit 0 | 每轮收盘/continue 门 | 脚本输出 |
| server API/SSE（技术栈待 S2 定） | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) |
| app 终态通知链路（技术栈待 S2 定） | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) | TODO (owner: 待 S2 定) |

## Threshold Change Policy

- Requires human confirmation: yes（技术栈相关阈值变更需用户确认，见 goal.md Required Human Decisions 第一项）
- Requires new round: TODO (owner: 待 S2 定)
- Drift risk: TODO (owner: 待 S2 定，S2 设计轮需评估技术选型对既有阈值的漂移影响)
