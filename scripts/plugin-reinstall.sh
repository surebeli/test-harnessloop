#!/usr/bin/env bash
# 从本项目的 harnessloop submodule 重装 harnessloop 插件。
#
# 作用：把全局 marketplace `harnessloop` 的源指向本地 submodule，
# 然后卸载并重新安装插件，使 submodule 中的最新编辑生效
# （安装复制的是工作区内容，编辑无需先 commit）。
# 注意：安装完成后需要重启 Claude Code 会话才会加载新版本。
#
# 前提：claude CLI（支持 `claude plugin` 子命令）、python3。
#
# 用法: scripts/plugin-reinstall.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE="$REPO_ROOT/harnessloop"

command -v claude >/dev/null || { echo "error: 未找到 claude CLI" >&2; exit 1; }

if [[ ! -f "$SUBMODULE/.claude-plugin/marketplace.json" ]]; then
  echo "error: $SUBMODULE 不是有效的 marketplace（缺少 .claude-plugin/marketplace.json）" >&2
  echo "提示: 先执行 git submodule update --init" >&2
  exit 1
fi

# 卸载/移除之后、安装成功之前中断，系统会处于「无插件」中间态——给出恢复指引。
on_error() {
  echo >&2
  echo "error: 重装中断，harnessloop 插件可能处于已卸载/未注册状态。" >&2
  echo "恢复: 修复上方报错后重跑 scripts/plugin-reinstall.sh；" >&2
  echo "      或回退到 GitHub 源: claude plugin marketplace add surebeli/harnessloop && claude plugin install harnessloop@harnessloop" >&2
}
trap on_error ERR

echo "==> 校验 manifest"
claude plugin validate "$SUBMODULE"
claude plugin validate "$SUBMODULE/plugins/harnessloop"

echo "==> 卸载旧插件并重指 marketplace 到本地 submodule"
# 「本来就未安装/未注册」是正常情况，其余失败原因保留 stderr 供排查。
claude plugin uninstall harnessloop@harnessloop \
  || echo "warn: uninstall 未成功（若本来未安装可忽略，否则看上方报错）"
claude plugin marketplace remove harnessloop \
  || echo "warn: marketplace remove 未成功（若本来未注册可忽略，否则看上方报错）"
claude plugin marketplace add "$SUBMODULE"

echo "==> 从本地 marketplace 安装"
claude plugin install harnessloop@harnessloop

trap - ERR
"$REPO_ROOT/scripts/plugin-status.sh" || echo "warn: 状态展示失败（不影响上面已完成的安装）"
echo
echo "完成。重启 Claude Code 会话后生效。"
