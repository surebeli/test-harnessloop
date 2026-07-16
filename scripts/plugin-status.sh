#!/usr/bin/env bash
# 对照显示：submodule 当前状态 vs 全局实际安装的 harnessloop 插件，
# 并做内容级比对（diff），确认「编辑 → 重装」是否真正生效。
#
# 用法: scripts/plugin-status.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE="$REPO_ROOT/harnessloop"
PLUGINS_DIR="$HOME/.claude/plugins"

echo "== submodule (harnessloop/) =="
if git -C "$SUBMODULE" rev-parse HEAD >/dev/null 2>&1; then
  git -C "$SUBMODULE" log -1 --format='commit   %h  %s'
  dirty=$(git -C "$SUBMODULE" status --short | wc -l | tr -d ' ')
  version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' \
    "$SUBMODULE/plugins/harnessloop/.claude-plugin/plugin.json" 2>/dev/null || echo '?')
  echo "version  $version"
  echo "dirty    $dirty 个未提交变更"
  if [[ "$dirty" != 0 ]]; then
    echo "注意     安装缓存复制的是工作区内容；上面的 commit sha 不代表缓存内容"
  fi
else
  echo "(submodule 未初始化，先执行 git submodule update --init)"
  exit 0
fi

echo
echo "== 全局安装 =="
python3 - "$PLUGINS_DIR" <<'EOF' || echo "(读取插件注册表失败，见上方诊断)"
import json, sys, os
d = sys.argv[1]

def load(name):
    p = os.path.join(d, name)
    try:
        with open(p) as f:
            return json.load(f)
    except Exception as e:
        print(f"{name}: 读取失败 ({type(e).__name__}: {e})")
        return None

mk = load('known_marketplaces.json')
if mk is not None:
    entry = mk.get('harnessloop') if isinstance(mk, dict) else None
    if entry:
        src = entry.get('source', {})
        print(f"marketplace source: {src.get('source')} {src.get('repo') or src.get('path') or ''}".rstrip())
    else:
        print("marketplace: 未注册")

inst = load('installed_plugins.json')
if inst is not None:
    entries = (inst.get('plugins') or {}).get('harnessloop@harnessloop') or []
    for e in entries:
        print(f"installed: v{e.get('version')}  sha {str(e.get('gitCommitSha'))[:7]}  at {e.get('lastUpdated')}")
    if not entries:
        print("plugin: 未安装")
EOF

echo
echo "== 内容比对 (submodule ↔ 安装缓存) =="
version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' \
  "$SUBMODULE/plugins/harnessloop/.claude-plugin/plugin.json" 2>/dev/null || echo '')
CACHE="$PLUGINS_DIR/cache/harnessloop/harnessloop/$version"
if [[ -n "$version" && -d "$CACHE" ]]; then
  if diff -rq "$SUBMODULE/plugins/harnessloop" "$CACHE" >/dev/null 2>&1; then
    echo "一致：缓存内容 == submodule 工作区"
  else
    echo "不一致（有编辑尚未重装，或安装不完整）："
    diff -rq "$SUBMODULE/plugins/harnessloop" "$CACHE" 2>&1 | head -10
  fi
else
  echo "(缓存目录不存在: $CACHE)"
fi
