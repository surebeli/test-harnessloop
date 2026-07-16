# test-harnessloop

通过开发一个真实 app 来验证 harnessloop 插件能力的实验项目。**app 是手段，harnessloop 的迭代验证才是目的。**

## 目录结构

- `harnessloop/` — git submodule，指向 `surebeli/harnessloop`。这是插件源码，发现框架问题时**直接在这里改**。
- `app/` — 被开发的验证 app（需求见 `docs/app-requirements.md`）。
- `docs/validation-log.md` — 每一轮「发现问题 → 改插件 → 重装 → 复验」的记录，是本项目的核心产出。
- `scripts/` — 插件迭代回路脚本。

## 插件迭代回路

`scripts/plugin-reinstall.sh` 每次运行都会把全局 marketplace `harnessloop` 重指到本项目的 submodule（不是 GitHub），所以插件改动不需要 push 就能生效（当前指向用 `scripts/plugin-status.sh` 确认）：

1. 直接编辑 `harnessloop/plugins/harnessloop/` 下的源码（skills 等）。**不需要先 commit**——已实测：安装复制的是 submodule 工作区（含未提交改动）。
2. 运行 `scripts/plugin-reinstall.sh`（校验 manifest → 卸载 → 重装）。
3. **重启 Claude Code 会话**后新版本才会加载。
4. 复验之前失败的场景，结果记入 `docs/validation-log.md`。
5. 验证通过的插件改动在 `harnessloop/` 内 commit；push 到 `surebeli/harnessloop` 属于插件自己的发布流程，由用户决定。

用 `scripts/plugin-status.sh` 可对照 submodule 状态与全局实际安装的版本。

## 约束

- app 的开发过程必须走 harnessloop 框架（skill 真实调用名带双前缀：`harnessloop:harnessloop-init` → `harnessloop:harnessloop-loop` / `harnessloop:harnessloop-continue` 等；`harnessloop:init` 这类短写只是触发短语，不是合法 skill 名），不要绕开框架直接开发——绕开就失去了验证意义。
- 遇到框架缺陷、协议疑问，先用 `harnessloop:harnessloop-issue` 记录，再动手改源码。
- `.harnessloop/` 状态文件是被测行为的一部分，纳入 git 提交，不要 gitignore。
- 主仓库 commit 时注意 submodule 指针：只有当 `harnessloop/` 内的改动已在 submodule 里 commit 后，主仓库才应更新指针。
