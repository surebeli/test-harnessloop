# test-harnessloop

通过开发一个真实 app 来验证 harnessloop 插件能力的实验项目。**app 是手段，harnessloop 的迭代验证才是目的。**

## 目录结构

- `harnessloop/` — git submodule，指向 `surebeli/harnessloop`。这是插件源码，发现框架问题时**直接在这里改**。
- `hopper-plugin/` — git submodule，指向 `surebeli/hopper-plugin`（marketplace 名 `agent-hopper`，插件 id `hopper@agent-hopper`）。第二个被测插件，任务分发到第三方 agents，同样直接迭代。
- `app/` — 被开发的验证 app（需求见 `docs/app-requirements.md`）。
- `docs/validation-log.md` — 每一轮「发现问题 → 改插件 → 重装 → 复验」的记录，是本项目的核心产出。
- `scripts/` — 插件迭代回路脚本（覆盖 harnessloop 与 hopper 两个被测插件）。

## 插件迭代回路

`scripts/plugin-reinstall.sh [harnessloop|hopper|all]` 每次运行都会把对应插件的全局 marketplace 重指到本项目的 submodule（不是 GitHub），所以插件改动不需要 push 就能生效（不带参数默认 `all`，两个插件依次重装；当前指向用 `scripts/plugin-status.sh [harnessloop|hopper|all]` 确认）：

1. 直接编辑源码：harnessloop 在 `harnessloop/plugins/harnessloop/`（skills 等）；hopper 在 `hopper-plugin/`（marketplace.json 里 `source` 是 `./`，即 submodule 根目录本身就是插件源码目录，不是子目录）。**不需要先 commit**——已实测：安装复制的是 submodule 工作区（含未提交改动）。
2. 运行 `scripts/plugin-reinstall.sh harnessloop`、`scripts/plugin-reinstall.sh hopper` 或不带参数一次重装两者（校验 manifest → 卸载 → 重装）。
3. **重启 Claude Code 会话**后新版本才会加载。
4. 复验之前失败的场景，结果记入 `docs/validation-log.md`。
5. 验证通过的插件改动在对应 submodule（`harnessloop/` 或 `hopper-plugin/`）内 commit；push 到各自 GitHub 仓库已是既定授权流程（`surebeli/harnessloop`、`surebeli/test-harnessloop`、`surebeli/hopper-plugin` 三仓同权，批次验收通过后无需逐次确认，见 `.harnessloop/state/control-contract.md`）——但 hopper-plugin push 前必须先 bump 插件版本信息，保持 `.claude-plugin/marketplace.json`、`package.json` 及 CLI 版本串等多处版本文件一致，未 bump 不得 push（对照 harnessloop 的先例：版本 bump 是发布提交的一部分）。

用 `scripts/plugin-status.sh [harnessloop|hopper|all]` 可对照 submodule 状态与全局实际安装的版本。

## Hopper vendor 角色

（用户决策 2026-07-17，详见 `.hopper/AGENTS.md`、`.harnessloop/setup/data-sources.md`、`.harnessloop/setup/cost-context-policy.md`）

- **入选 vendor 只有 `codex` 与 `grok`**，其余 hopper 已注册的 vendor（kimi/opencode/copilot/agy/mimo/claude 等）未入选，暂不路由。
  - `codex`：对抗/验收评审随机池成员 + 研究备选。
  - `grok`：对抗/验收评审随机池成员 + 研究主力。
- **对抗评审（`code-review-adversarial`/`code-review-acceptance`）** 从 codex/grok 中随机挑一家；随机发生在主会话写 queue.md 该任务行 `Vendor` 列的那一刻，hopper 的路由逻辑本身仍是确定性的静态查表。
- **实现类（写代码，`code-impl`）绝不派第三方 vendor**——一律由主会话的 claude-sonnet-5 子代理执行，hopper 不参与实现类任务的派发。
- **codex 评审三项强制核对**：codex 沙箱不可靠地降级为只读、且存在跨仓 review 被全局 skill 劫持的已知问题（`hopper-plugin/ISSUE-codex-review-hijack.md`，未修）。每次 codex 评审完成后必须核对：(a) 实际审查对象是否为 brief 指定目标；(b) 产物是否落在 brief 指定路径；(c) 不得仅凭 exit 0 / codex 自述 success 采信。

> Dispatch contract (per-vendor --model/--reasoning/--sandbox/--timeout, perms, cwd): see `.hopper/DISPATCH.md` (hopper-generated, do not hand-edit). Never hand-copy vendor invocation strings.

- hopper-plugin push 前必须 bump 插件版本信息、保持多处版本文件一致，否则不得 push：见「插件迭代回路」第 5 步与 `.harnessloop/state/control-contract.md`（Irreversible or external-system write 例外条款，user-confirmed 2026-07-17）。

## 约束

- app 的开发过程必须走 harnessloop 框架（skill 真实调用名带双前缀：`harnessloop:harnessloop-init` → `harnessloop:harnessloop-loop` / `harnessloop:harnessloop-continue` 等；`harnessloop:init` 这类短写只是触发短语，不是合法 skill 名），不要绕开框架直接开发——绕开就失去了验证意义。
- 遇到框架缺陷、协议疑问，先用 `harnessloop:harnessloop-issue` 记录，再动手改源码。
- `.harnessloop/` 状态文件是被测行为的一部分，纳入 git 提交，不要 gitignore。
- 主仓库 commit 时注意 submodule 指针：只有当 `harnessloop/` 或 `hopper-plugin/` 内的改动已在各自 submodule 里 commit 后，主仓库才应更新指针。
- hopper 的验证方式是边用边验证：后续任务中实际调用其 dispatch/monitor 能力并记录问题。
