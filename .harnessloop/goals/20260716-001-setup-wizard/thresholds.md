# Thresholds

## Data Thresholds

| Threshold | Applies to | Required state | Freshness | Drift check | Evidence |
| --- | --- | --- | --- | --- | --- |
| findings.json 相关条目为需求冻结基线 | 需求定义（guided-setup/auto-detection lens） | 条目状态 = CONFIRMED | 冻结 2026-07-16，不刷新 | 与 findings.json JSON 结构比对 | docs/harnessloop-review-20260716.findings.json |
| references/ 模板为格式权威且实现不得与其漂移 | 所有新建 skill/文件格式 | 与模板结构一致 | 随 submodule HEAD 刷新 | diff 对比模板目录 | harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ |
| submodule HEAD 为源码基线 | 插件源码 | HEAD = 66093fd（或更新的 commit） | 刷新 = git commit | git log 比对 | harnessloop/（git HEAD） |

## Verification Thresholds

| Threshold | Applies to | Command/check | Pass condition | Fail condition | Evidence path |
| --- | --- | --- | --- | --- | --- |
| npm run validate 7/7 + 新增断言全绿 | 整体插件 | npm run validate（cwd=harnessloop/） | exit 0，7/7 阶段全绿 | 任一阶段失败 | npm run validate 输出 |
| check_setup 在两种项目状态返回正确结果 | check_setup.py | 骨架项目 vs 本项目（已填）分别运行 | 骨架=incomplete，本项目=complete | 返回结果不符 | check_setup 输出 |
| claude plugin validate --strict 通过 | harnessloop-setup skill | claude plugin validate --strict | exit 0 | 非 0 | 命令输出 |
| 所有新 python 代码 3.9.4 实测可运行 | 新增 python 脚本 | python3 3.9.4（pyenv）实测运行 | 无异常，exit 0 | TypeError/异常退出 | 命令输出 |
| wizard 五步 dry-run 全走通 | wizard 脚本 | 脚本化 dry-run | 五步全部完成无中断 | 任一步骤中断/异常 | dry-run transcript |
| 用户 live run 确认 | wizard 交互 | 用户亲自运行 | 用户确认通过 | 用户反馈 negative | 用户确认记录（human-confirmation） |

## Runtime Thresholds

| Runtime surface | Validation method | Pass condition | Observation window | Evidence path |
| --- | --- | --- | --- | --- |
| npm run validate | 本地命令 | exit 0 全绿 | 每次代码变更后 | validate 输出 |
| verify_protocol.py | 本地命令（机械协议门） | exit 0 | 每轮收盘/continue 门 | 脚本输出 |
| plugin-reinstall.sh | 重装回路 | 内容比对一致 | 每次插件改动后 | 比对输出 |

## Threshold Change Policy

- Requires human confirmation: yes（档位预设默认值等实质性阈值变更需用户，见 goal.md Required Human Decisions）
- Requires new round: TODO (owner: user)
- Drift risk: TODO (owner: user)
