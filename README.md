# test-harnessloop

用一个真实 app 的开发过程，端到端验证 [harnessloop](https://github.com/surebeli/harnessloop) 插件（evidence-backed long-task takeover and execution）的框架能力，并在验证中直接迭代插件本身。

## 结构

```
test-harnessloop/
├── harnessloop/            # submodule → surebeli/harnessloop（插件源码，直接迭代）
├── app/                    # 验证用 app（用 harnessloop 框架开发）
├── docs/
│   ├── app-requirements.md # app 需求
│   └── validation-log.md   # 插件验证与迭代记录（核心产出）
└── scripts/
    ├── plugin-reinstall.sh # 编辑源码后重装插件
    └── plugin-status.sh    # 对照 submodule ↔ 全局安装状态
```

## 首次克隆

```bash
git clone --recurse-submodules https://github.com/surebeli/test-harnessloop
cd test-harnessloop
scripts/plugin-reinstall.sh   # 把全局 marketplace 指向本地 submodule 并安装
```

## 迭代回路

```
用 harnessloop 框架开发 app
        │ 发现框架问题（harnessloop:issue 记录）
        ▼
直接编辑 harnessloop/plugins/harnessloop/ 源码
        ▼
scripts/plugin-reinstall.sh  →  重启 Claude Code 会话
        ▼
复验失败场景 → 记入 docs/validation-log.md → 继续开发
```
