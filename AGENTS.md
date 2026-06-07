# AGENTS.md - Semi-MES-Sim 智能体操作手册

> 本文件是 Harness Engineering 的核心基础设施。
> **修改本文件必须经过人类确认** —— 因为这里是所有智能体的行为约束边界。
>
> **系统记录声明**：本仓库是项目决策、架构约束、执行状态和验证标准的唯一权威来源。不在仓库里的知识对 agent 来说等于不存在。

## 项目概览

**Semi-MES-Sim** 是一个半导体制造执行系统（MES）的 3D 仿真平台。技术栈：Vue 3 + TypeScript + Babylon.js 9 + Pinia + Vite。

## 快速开始

```bash
make setup   # 安装依赖
make dev     # 启动开发服务器（http://localhost:5173）
make check   # 完整验证：lint + type-check + test
make init    # 一键初始化（检查环境 + 安装 + 验证 + 启动）
```

## 硬约束（不可违反）

1. `@semi/core` **必须是纯 TypeScript**，禁止依赖 Vue、Babylon.js 等任何 UI 库
2. **3D 引擎必须是 Babylon.js 9.x**，不是 Three.js
3. **ESLint 10 Flat Config**，lint 脚本格式必须是 `"eslint src"`，禁止 `--ext`
4. `tsconfig.json` 中的 `paths` **必须指向 `dist/` 或 `index.d.ts`**，禁止指向 `src/`
5. `@semi/ui` 组件修改后**必须同步更新 `index.d.ts`**
6. 所有 3D 对象**必须设置 `name` 属性**
7. 设备模型使用 `MeshBuilder` 基础几何体，**禁止引入外部 `.glb`/`.gltf` 文件**
8. 本地包引用**必须使用 `workspace:*` 协议**
9. 提交前必须 `make check`（lint + type-check + test）**全部通过**
10. 修改代码时必须**同步更新对应包的 `ARCHITECTURE.md`**
11. 架构决策必须**写入 `DECISIONS.md`**
12. 新增包必须有 `eslint.config.js` 且 `package.json` 设置 `"type": "module"`

## 目录职责

| 目录 | 职责 | 禁止事项 |
|------|------|----------|
| `apps/web` | 主应用入口、页面布局、3D 画布挂载 | 包含可复用领域逻辑 |
| `packages/core` | MES 领域模型、仿真引擎、算法 | 依赖 UI 库 |
| `packages/3d-engine` | Babylon.js 场景、模型、动画 | 依赖 Vue |
| `packages/ui` | 可复用 Vue 组件库 | 依赖 `apps/web` |
| `packages/config` | 共享 TS/ESLint/Vite 配置 | 依赖业务包 |

包间依赖：`apps/web` → `core` / `3d-engine` / `ui`；`3d-engine` → `core`（仅类型）；`ui` → `core`（仅类型）

## 全新会话测试

首次接入本仓库时，必须仅凭仓库内容回答以下问题：

| # | 问题 | 答案位置 |
|---|------|----------|
| 1 | 这是什么项目？ | 本文件「项目概览」 |
| 2 | 怎么运行？ | `Makefile` / `init.sh` |
| 3 | 怎么验证？ | `make check` |
| 4 | 架构约束是什么？ | 本文件「硬约束」+ 各包 `ARCHITECTURE.md` |
| 5 | 当前进度和下一步？ | `PROGRESS.md` + `feature_list.json` |

## 专题文档（按需阅读）

不要一次性加载全部。根据当前任务选择性阅读：

- [工具链配置](docs/toolchain.md) — **修改 ESLint、TypeScript、构建脚本时必读**
- [编码规范](docs/coding-standards.md) — **编写代码时参考**
- [工作流与 ACID](docs/workflow.md) — **执行任务、提交代码前必读**
- [架构决策](DECISIONS.md) — **需要了解历史决策时参考**

## 关键术语

| 术语 | 说明 |
|------|------|
| **Lot** | 晶圆批次，MES 中流转的基本单位 |
| **Equipment** | 生产设备，如光刻机（Litho）、刻蚀机（Etcher） |
| **Recipe** | 工艺配方，定义设备加工参数 |
| **ProcessStep** | 工艺步骤，Lot 需要经过的单个工序 |
| **WIP** | 在制品（Work In Process） |
| **DES** | 离散事件仿真（Discrete Event Simulation） |
| **Fab** | 晶圆厂（Fabrication Plant） |

## 版本历史

- **v1.3.0** — 拆分 `AGENTS.md`，工具链/编码/工作流独立为专题文档，避免巨型指令文件陷阱
- **v1.2.0** — 引入 Harness Engineering 规则体系（系统记录、ACID、知识衰减防护）
- **v1.1.0** — 迁移到 Babylon.js，ESLint 10 Flat Config
- **v1.0.0** — 初始版本
