# 启动就绪清单（Startup Readiness Checklist）

> **阅读时机**：首次接入仓库、克隆到新环境、或怀疑项目状态是否可运行时。
>
> 本清单验证「新会话能否仅凭仓库内容就开始工作」。四项条件必须全部满足。

## 四项基本条件

| # | 条件 | 验证命令 | 状态 |
|---|------|----------|------|
| 1 | **能启动** | `make setup && make dev` | ✅ 通过 |
| 2 | **能测试** | `make test`（至少一个真实测试通过） | ✅ 通过 |
| 3 | **能看到进度** | 阅读 `PROGRESS.md` 和 `feature_list.json` | ✅ 通过 |
| 4 | **能接下一步** | `PROGRESS.md` 有明确的「下一步」清单 | ✅ 通过 |

## 环境要求

- Node.js >= 18.0.0
- pnpm >= 9.0.0（`init.sh` 会自动安装）

## 标准命令

| 命令 | 作用 |
|------|------|
| `make setup` | 安装依赖 |
| `make dev` | 启动开发服务器 |
| `make test` | 运行所有测试 |
| `make check` | lint + type-check + test（CI/提交前用） |
| `make init` | 一键完整初始化（检查环境 + 安装 + 验证 + 启动） |

## 项目结构速览

```
apps/web/           — 主应用入口（Vue 3 + Vite）
packages/core/      — MES 领域模型与仿真引擎（纯 TypeScript）
packages/3d-engine/ — Babylon.js 场景与动画
packages/ui/        — 可复用 Vue 组件库
packages/config/    — 共享 TS/ESLint/Vite 配置
```

## 初始化阶段状态

**阶段**: ✅ 已完成

初始化阶段产出：
- [x] Monorepo 结构与 workspace 配置
- [x] ESLint 10 Flat Config + TypeScript 配置
- [x] 各包构建脚本与类型检查
- [x] 示例测试通过（`packages/core/src/models/lot.test.ts`）
- [x] `AGENTS.md` / `PROGRESS.md` / `DECISIONS.md` / `feature_list.json`
- [x] `Makefile` + `init.sh` 标准化命令

> **注意**：初始化阶段已完成。新会话直接开始功能实现，不应再修改基础设施配置。
