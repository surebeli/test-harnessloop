# Data Sources

## Static Sources

| Source | Access method | Freshness requirement | Drift risk | Validation method | Credential requirement |
| --- | --- | --- | --- | --- | --- |
| docs/harnessloop-review-20260716.md + docs/harnessloop-review-20260716.findings.json | 本地文件读取 | 80 条确认发现的审查快照，冻结基线（2026-07-16），不刷新——被新一轮审查取代时整体作废 | 修复推进后条目逐渐过时 | 与 findings.json 的 JSON 结构比对 | 无 |
| harnessloop/ submodule 源码 @ git HEAD（当前 66093fd） | 本地文件读取（git 工作树） | 刷新 = git commit | 会话内已加载的 SKILL 文本钉在会话启动快照，落后于磁盘（2026-07-16 实测：重装后 Skill 工具仍返回修复前 loop SKILL 文本） | git log + scripts/plugin-status.sh 内容级 diff | 无 |
| harnessloop/adversarial-review-p0.md 等作者自评文档 | 本地文件读取 | 基线 v0.9.0，已知落后当前版本，仅作历史对照 | 落后当前版本，不代表当前状态 | TODO (owner: user) | 无 |
| harnessloop/examples/mock-project/ | 本地文件读取 | 已知系统性落后模板 12+ 处（审查发现） | 禁止作为格式权威，模板目录 references/ 才是权威 | TODO (owner: user) | 无 |

## Dynamic Or Generated Sources

| Source | Generator/tool | Refresh expectation | Drift risk | Validation method | Credential requirement |
| --- | --- | --- | --- | --- | --- |
| npm run validate 输出 | npm run validate（harnessloop 仓库根运行） | 每次运行重新生成 | TODO (owner: user) | 7/7 阶段全绿 | 无 |
| scripts/plugin-status.sh 输出 | scripts/plugin-status.sh | TODO (owner: user) | TODO (owner: user) | 安装状态与内容级比对 | 无 |
| wizard 模拟运行 transcript（本 goal 的产物） | 脚本化 dry-run | 本 goal 的产物 | TODO (owner: user) | TODO (owner: user) | 无 |

## Runtime Validation Systems

| System | Access method | Validation method | Pass condition | Failure handling | Credential requirement | Local parameter reference |
| --- | --- | --- | --- | --- | --- | --- |
| npm run validate（cwd=harnessloop/，7 阶段） | 本地命令 | 7 阶段全绿 | pass=exit 0 全绿 | 定位失败阶段修复后重跑 | 无 | 无 |
| python3 <plugin-cache>/skills/harnessloop-loop/scripts/verify_protocol.py --project 本项目 | 本地命令 | 机械协议门 | pass=exit 0 | TODO (owner: user) | 无 | 无 |
| scripts/plugin-reinstall.sh（重装回路） | 本地命令 | 内容比对 | pass=内容比对一致 | TODO (owner: user) | 无 | 无 |

注：本机 python3 = 3.9.4（pyenv），为本 goal 所有新增 python 代码的兼容性下限约束。

## External Tools And Platforms

| Tool/platform | Purpose | Read/write scope | Account role | Verification method | Failure handling | Local parameter keys |
| --- | --- | --- | --- | --- | --- | --- |

## Local Channel Parameters

Store reusable channel parameter keys in `.harnessloop/local/channel-params.json`, which must be ignored by `.harnessloop/local/.gitignore`.

| Channel ID | Parameter key | Sensitivity | Storage | Reference | Required for | Status |
| --- | --- | --- | --- | --- | --- | --- |

本 goal 无外部凭证需求：`.harnessloop/local/channel-params.example.json` 存在，无需填入真实参数。

## Secret Handling

Do not write secret values here. Record only secret names, storage locations, required scopes, and verification commands.
