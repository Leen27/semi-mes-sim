# AGENTS.md - Semi-MES-Sim 智能体操作手册

> 本文件是 Harness Engineering 的核心基础设施。
> **修改本文件必须经过人类确认** —— 因为这里是所有智能体的行为约束边界。
>
> **系统记录声明**：本仓库是项目决策、架构约束、执行状态和验证标准的唯一权威来源。不在仓库里的知识对 agent 来说等于不存在。

## 项目概览

**Semi-MES-Sim** 是一个半导体制造执行系统（MES）的 3D 仿真平台。技术栈：Vue 3 + TypeScript + Babylon.js 9 + Pinia + Vite。

## 快速开始

> 首次接入请先阅读 [`docs/startup-readiness.md`](docs/startup-readiness.md) 确认环境就绪。

```bash
make setup   # 安装依赖
make dev     # 启动开发服务器（http://localhost:5173）
make check   # 完整验证：lint + type-check + test
make init    # 一键初始化（检查环境 + 安装 + 验证 + 启动）
```

## 硬约束（不可违反）

### 架构边界（Lecture 10 — 架构规则必须可执行）

1. `@semi/core` **必须是纯 TypeScript**，禁止依赖 Vue、Babylon.js 等任何 UI 库
2. **3D 引擎必须是 Babylon.js 9.x**，不是 Three.js
3. `@semi/3d-engine` **禁止依赖 Vue**（纯 Babylon.js + TypeScript）
4. `@semi/ui` **禁止依赖 `apps/web`**（UI 是被消费的库，不能反向依赖应用）
5. 本地包引用**必须使用 `workspace:*` 协议**
6. `tsconfig.json` 中的 `paths` **必须指向 `dist/` 或 `index.d.ts`**，禁止指向 `src/`
7. 设备模型使用 `MeshBuilder` 基础几何体，**禁止引入外部 `.glb`/`.gltf` 文件**
8. 所有 3D 对象**必须设置 `name` 属性**

> **架构边界是自动检查的**：`scripts/verify-architecture.sh` 会在每次 `verify-layers.sh` 时运行。任何违反都会在错误消息中说明 **WHAT / WHY / FIX**，形成自校正反馈循环。

### 工具链与代码规范

9. **ESLint 10 Flat Config**，lint 脚本格式必须是 `"eslint src"`，禁止 `--ext`
10. `@semi/ui` 组件修改后**必须同步更新 `index.d.ts`**
11. 新增包必须有 `eslint.config.js` 且 `package.json` 设置 `"type": "module"`

### 验证与完成（Lecture 10 — 只有端到端测试才是真正的验证）

12. 提交前必须 `make check`（lint + type-check + test）**全部通过**
13. **三层验证全部通过才算完成** —— Layer 0（架构边界）→ Layer 1（lint+type-check）→ Layer 2（单元测试+构建）→ Layer 3（端到端/跨组件集成）。**Layer N 未通过前不得进入 Layer N+1**
14. **跨组件变更必须通过端到端验证** —— 涉及多个包的修改，Layer 3 的跨组件符号检查（web bundle 包含 core/3d-engine/ui 的关键导出）为强制通过项
15. **Agent 不能自行宣布「完成了」** —— 完成判断由 harness 外部化执行。只有 `scripts/verify-layers.sh` 全部通过后，才能标记为 passing
16. **核心功能验证通过前禁止重构** —— 不要「顺便优化」未验证的代码。先让功能通过所有测试，再考虑优化

### 工作流与状态管理

17. **WIP = 1** —— 任何时刻只能有一个功能处于 `active` 状态。完成一个，再开始下一个
18. **完成证据必须可执行** —— 功能不是「代码写好了」，而是 `feature_list.json` 中定义的 verificationCommand 全部通过
19. **VCR < 1.0 时禁止激活新任务** —— 验证完成率低于 100% 时，必须先让活跃任务达到 `passing`
20. **Agent 不能直接修改 feature 的 `status` 字段** —— 唯一允许的状态转换路径是：先运行所有 `verificationCommand` → 全部通过 → 才能将 `active` 标记为 `passing`。禁止凭感觉改状态
21. **Feature list 是唯一真实来源** —— 所有「需要做什么」的信息必须来自 `feature_list.json`。代码中的 TODO 注释必须引用 feature ID（如 `// TODO(F004)`），禁止游离的隐式需求
22. **Back-pressure 不可忽略** —— `scopeSurface.backPressure.totalPending` > 0 时，项目未完成。Agent 不得提前宣告「项目做完了」
23. 修改代码时必须**同步更新对应包的 `ARCHITECTURE.md`**
24. 架构决策必须**写入 `DECISIONS.md`**
25. 跨会话任务**必须更新 `PROGRESS.md`**，记录当前进度、验证状态和下一步
26. 新会话开始前**必须阅读 `docs/startup-readiness.md`** 确认四项基本条件

### 可观测性（Lecture 11 — 可观测性是 Harness 的架构属性）

27. **每次会话必须生成 Task Trace** — 使用 `scripts/harness-trace.sh` 记录会话的完整决策路径。trace 文件位于 `.harness/traces/`，是会话交接的关键产物
28. **每个功能必须通过 Evaluator Rubric 评分** — 不是"看起来对了"，而是五个维度（代码正确性、架构合规性、测试覆盖、文档同步、端到端验证）的结构化评分
29. **跨会话交接必须包含 trace 文件** — 新会话通过阅读最新 trace 文件，可在 3 分钟内重建上一轮状态，避免 30-50% 的冗余诊断时间

## 目录职责

| 目录 | 职责 | 禁止事项 |
|------|------|----------|
| `apps/web` | 主应用入口、页面布局、3D 画布挂载 | 包含可复用领域逻辑 |
| `packages/core` | MES 领域模型、仿真引擎、算法 | 依赖 UI 库 |
| `packages/3d-engine` | Babylon.js 场景、模型、动画 | 依赖 Vue |
| `packages/ui` | 可复用 Vue 组件库 | 依赖 `apps/web` |
| `packages/config` | 共享 TS/ESLint/Vite 配置 | 依赖业务包 |

包间依赖：`apps/web` → `core` / `3d-engine` / `ui`；`3d-engine` → `core`（仅类型）；`ui` → `core`（仅类型）

## 工作规则（WIP=1 + Feature List Primitive）

> 规则来源：Lecture 07 — Draw Clear Task Boundaries for Agents + Lecture 08 — Use Feature Lists to Constrain What the Agent Does

### Feature List 是 Harness 的基础数据结构

`feature_list.json` 不是备忘录，而是整个 Harness 的 primitive：
- **调度器**依赖它选取下一个 `not_started` 任务
- **验证器**依赖它执行 `verificationCommand` 判断完成
- **交接报告**依赖它生成会话摘要
- **进度追踪器**依赖它计算 VCR 和 back-pressure

**所有「需要做什么」的信息必须来自 `feature_list.json`，不来自对话历史、不来自代码 TODO、不来自 agent 的记忆。**

### Pass-State Gating（状态门控）

状态转换不是 agent 的自由意志，而是由验证结果控制的：

| 转换 | 触发条件 | Agent 能否直接操作 |
|------|----------|-------------------|
| `not_started` → `active` | 依赖全部 `passing`，WIP=1 允许 | ✅ 是（选取任务时） |
| `active` → `passing` | **所有 `verificationCommand` 退出码 0** | ❌ 否（必须先运行验证） |
| `active` → `blocked` | 依赖变为非 `passing` 或外部阻塞 | ❌ 否 |
| `blocked` → `active` | 阻塞解除 | ✅ 是（检查依赖后） |

**禁止行为**：agent 不得在未运行 `verificationCommand` 的情况下，直接将 `active` 改为 `passing`。

### 工作循环

1. 从 `feature_list.json` 选取一个 `not_started` 任务（依赖已满足）
2. 将其标记为 `active`，设置 `activeFeatureId`
3. 实现代码 + 测试
4. **运行该功能的所有 `verificationCommand`**
5. **全部通过后**，才能将其标记为 `passing`，记录 `evidence.passedAt` 和 `evidence.output`
6. 任一命令失败 → 保持 `active`，修复后继续
7. 更新 `scopeSurface.vcr` 和 `scopeSurface.backPressure`

### 绝对禁止

- **不要凭感觉改状态** ——「代码看起来没问题」不是 passing 的理由
- **不要游离的 TODO** —— 代码中的 TODO 必须引用 feature ID：`// TODO(F004)`
- **不要从对话历史推断需求** —— 需求只在 `feature_list.json` 中
- **不要提前宣告完成** —— `backPressure.totalPending > 0` 时项目未完成

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
- [启动就绪清单](docs/startup-readiness.md) — **首次接入仓库时必读**
- [工作流与 ACID](docs/workflow.md) — **执行任务、提交代码前必读**（含端到端验证层级、审查反馈提升、Sprint Contract、Evaluator Rubric）
- [架构决策](DECISIONS.md) — **需要了解历史决策时参考**
- [架构边界检查](scripts/verify-architecture.sh) — **可执行的架构规则**（Agent 错误时直接运行查看 FIX 指令）
- [任务追踪](scripts/harness-trace.sh) — **运行时可观测性工具**（记录每次会话的决策路径）
- [功能评分](scripts/evaluate-feature.sh) — **结构化评分工具**（基于 Rubric 的多维度评估）

## 跨会话交接

上下文窗口有限。长任务跨会话时，新会话没有上一轮记忆，必须通过持久化文件快速重建状态。

**Clock In（会话开始）**：
1. 读取 `PROGRESS.md` 了解进度、阻塞项和下一步
2. 读取 `DECISIONS.md` 了解关键决策及原因
3. 读取 `feature_list.json` 确认当前活跃任务和完成证据
4. 运行 `make check` 确认仓库处于自洽状态
5. 从 `PROGRESS.md`「下一步」继续工作

**Clock Out（会话结束）**：
1. 更新 `feature_list.json`（活跃任务状态、已通过的完成证据）
2. 更新 `PROGRESS.md`（进度、验证状态、阻塞项、VCR）
3. 新决策追加到 `DECISIONS.md`
4. 运行 `make check` 确认自洽状态
5. 原子提交所有已完成的工作

> 详细策略见 [工作流文档](docs/workflow.md)

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
| **Scope Surface** | 范围表面，`feature_list.json` 中记录的任务 DAG 和状态 |
| **VCR** | Verified Completion Rate = 已验证任务 / 已激活任务 |
| **Completion Evidence** | 完成证据，可执行的验证命令 |

## 版本历史

- **v1.7.0** — 引入运行时与过程可观测性（Lecture 11）：Task Trace、Sprint Contract、Evaluator Rubric
- **v1.6.0** — 引入可执行架构边界检查（Lecture 10），端到端验证为强制门控
- **v1.5.0** — 引入 WIP=1、完成证据、VCR 监控（Lecture 07）
- **v1.4.0** — 引入跨会话交接（Clock In/Out、状态持久化）
- **v1.3.0** — 拆分 `AGENTS.md` 为入口文件 + 专题文档
- **v1.2.0** — 引入 Harness Engineering 规则体系
- **v1.1.0** — 迁移到 Babylon.js，ESLint 10 Flat Config
- **v1.0.0** — 初始版本
