#!/usr/bin/env bash
# 从本项目的 harnessloop submodule 重装 harnessloop 插件。
#
# 作用：把全局 marketplace `harnessloop` 的源指向本地 submodule，
# 然后卸载并重新安装插件，使 submodule 中的最新编辑生效。
# 注意：安装完成后需要重启 Claude Code 会话才会加载新版本。
#
# 用法: scripts/plugin-reinstall.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE="$REPO_ROOT/harnessloop"

if [[ ! -f "$SUBMODULE/.claude-plugin/marketplace.json" ]]; then
  echo "error: $SUBMODULE 不是有效的 marketplace（缺少 .claude-plugin/marketplace.json）" >&2
  echo "提示: 先执行 git submodule update --init" >&2
  exit 1
fi

echo "==> 校验 manifest"
claude plugin validate "$SUBMODULE"
claude plugin validate "$SUBMODULE/plugins/harnessloop"

echo "==> 卸载旧插件并重指 marketplace 到本地 submodule"
claude plugin uninstall harnessloop@harnessloop 2>/dev/null || true
claude plugin marketplace remove harnessloop 2>/dev/null || true
claude plugin marketplace add "$SUBMODULE"

echo "==> 从本地 marketplace 安装"
claude plugin install harnessloop@harnessloop

"$REPO_ROOT/scripts/plugin-status.sh"
echo
echo "完成。重启 Claude Code 会话后生效。"
