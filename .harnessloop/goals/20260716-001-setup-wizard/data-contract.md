# Data Contract

## Valid Evidence Sources

| Source | Type | Access method | Freshness | Validation method | Drift risk | Credential requirement |
| --- | --- | --- | --- | --- | --- | --- |
| docs/harnessloop-review-20260716.md + docs/harnessloop-review-20260716.findings.json | static | 本地文件读取 | 冻结基线 2026-07-16，不刷新——被新一轮审查取代时整体作废 | 与 findings.json JSON 结构比对 | 修复推进后条目逐渐过时 | 无 |
| harnessloop/plugins/harnessloop/skills/harnessloop-loop/references/ 模板目录 | source | 本地文件读取 @ git HEAD（当前 66093fd） | 随 submodule HEAD 刷新 | git log + scripts/plugin-status.sh 内容级 diff | 会话内已加载 SKILL 文本落后于磁盘（2026-07-16 实测） | 无 |

## Valid Tools And Systems

| Tool/system | Purpose | Read/write scope | Account role | Verification command | Failure handling | Local parameter reference |
| --- | --- | --- | --- | --- | --- | --- |
| npm run validate | 插件级验证（7 阶段） | 只读（cwd=harnessloop/） | TODO (owner: user) | npm run validate | 定位失败阶段修复后重跑 | 无 |
| verify_protocol.py | 机械协议门 | 只读 | TODO (owner: user) | python3 <plugin-cache>/skills/harnessloop-loop/scripts/verify_protocol.py --project 本项目 | TODO (owner: user) | 无 |
| scripts/plugin-reinstall.sh | 重装回路 | 写（重装插件缓存） | TODO (owner: user) | scripts/plugin-reinstall.sh | TODO (owner: user) | 无 |

## Local Channel Parameter Requirements

| Channel ID | Parameter key | Sensitivity | Storage | Required for | Must be present before |
| --- | --- | --- | --- | --- | --- |

本 goal 无外部凭证需求：`.harnessloop/local/channel-params.example.json` 存在，无需填入真实参数。

## Invalid Evidence

- harnessloop/adversarial-review-p0.md 等作者自评文档：基线 v0.9.0，已知落后当前版本，仅作历史对照，不可作为当前状态证据
- harnessloop/examples/mock-project/：已知系统性落后模板 12+ 处（审查发现），禁止作为格式权威

## Secret Handling

- Do not store secret values in Harnessloop files.
- Store secret names, local parameter keys, required scopes, configured storage, and verification commands only.
- Use `.harnessloop/local/channel-params.json` for local ignored values or provider references.

## Revision Policy

- Human confirmation required for source changes: yes
- Human confirmation required for threshold changes: yes
