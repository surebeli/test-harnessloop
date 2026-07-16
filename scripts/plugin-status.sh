#!/usr/bin/env bash
# 对照显示：submodule 当前状态 vs 全局实际安装的 harnessloop 插件。
# 用于确认「编辑 → 重装」是否真正生效。
#
# 用法: scripts/plugin-status.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE="$REPO_ROOT/harnessloop"
PLUGINS_DIR="${CLAUDE_PLUGINS_DIR:-$HOME/.claude/plugins}"

echo "== submodule (harnessloop/) =="
if git -C "$SUBMODULE" rev-parse HEAD >/dev/null 2>&1; then
  git -C "$SUBMODULE" log -1 --format='commit   %h  %s'
  dirty=$(git -C "$SUBMODULE" status --short | wc -l | tr -d ' ')
  echo "version  $(python3 -c "import json;print(json.load(open('$SUBMODULE/plugins/harnessloop/.claude-plugin/plugin.json'))['version'])" 2>/dev/null || echo '?')"
  echo "dirty    $dirty 个未提交变更"
else
  echo "(submodule 未初始化，先执行 git submodule update --init)"
fi

echo
echo "== 全局安装 =="
python3 - "$PLUGINS_DIR" <<'EOF'
import json, sys, os
d = sys.argv[1]
try:
    mk = json.load(open(os.path.join(d, 'known_marketplaces.json'))).get('harnessloop')
    if mk:
        src = mk.get('source', {})
        print(f"marketplace source: {src.get('source')} {src.get('repo') or src.get('path') or ''}".rstrip())
    else:
        print("marketplace: 未注册")
except FileNotFoundError:
    print("known_marketplaces.json 不存在")
try:
    plugins = json.load(open(os.path.join(d, 'installed_plugins.json')))['plugins']
    entries = plugins.get('harnessloop@harnessloop') or []
    for e in entries:
        print(f"installed: v{e.get('version')}  sha {str(e.get('gitCommitSha'))[:7]}  at {e.get('lastUpdated')}")
    if not entries:
        print("plugin: 未安装")
except FileNotFoundError:
    print("installed_plugins.json 不存在")
EOF
