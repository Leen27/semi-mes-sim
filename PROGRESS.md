# 项目进度

> 最后更新: 2026-06-07
> 来源: feature_list.json（harness-creator 诊断后更新）

## 项目阶段

**阶段**: 功能实现期 —— 按 WIP=1 模式逐个交付功能

## 当前状态

- **最新 commit**: `HEAD`（Lecture 12 干净状态检查引入）
- **验证状态**: lint ✅ / type-check ✅ / test ✅ / architecture ✅ / e2e ✅ / observability ✅ / clean-state ✅
- **活跃分支**: `main`
- **VCR（验证完成率）**: 5/5 = 100%
- **Back-Pressure（剩余压力）**: 5/10 = 50%（5 not_started / 10 total）
- **活跃功能**: 无

| 领域 | 进度 | 说明 |
|------|------|------|
| core (MES 核心) | 2/2 | F002 passing，F004 待启动 |
| 3d-engine (3D 引擎) | 3/3 | F001/F003/F006 passing，F007 待启动 |
| web (主应用) | 1/3 | F005 passing，F008/F009/F010 待启动 |
| ui (组件库) | 0/0 | 等待 web 需求驱动 |

## 已完成（passing）

- [x] **F002**: MES 核心数据模型 (`core`)
  - 完成证据: 类型定义完整 ✅ / 枚举测试通过 ✅ / lint+type-check+build ✅
- [x] **F001**: 3D 晶圆厂场景基础框架 (`3d-engine`)
  - 完成证据: SceneManager 导出 ✅ / Engine+Scene+Camera+Ground ✅ / lint+type-check+build ✅
- [x] **F003**: 设备 3D 资产与布局 (`3d-engine`)
  - 完成证据: 设备模型支持所有类型 ✅ / FabLayout 类 ✅ / lint+type-check+build ✅
- [x] **F005**: Web 主应用界面 (`web`)
  - 完成证据: App.vue 挂载 Canvas ✅ / store 完整行为 ✅ / lint+type-check+build ✅
  - **注意**: F005 代码已存在且验证通过，但其依赖 F004（仿真引擎）的事件处理仍是 TODO。这是初始化阶段遗留的技术债务，不影响 F005 自身的完成证据。
- [x] **F006**: 设备状态可视化 (`3d-engine`)
  - 完成证据: updateEquipmentStatus 函数 ✅ / 颜色映射覆盖 ✅ / lint+type-check+build ✅
- [x] **三层验证体系建立**（Lecture 09）
  - `scripts/verify-layers.sh` 脚本（Layer 1 lint/type-check → Layer 2 test/build → Layer 3 artifacts）
  - EventQueue 单元测试（8 tests）— 发现了排序稳定性问题
  - SimulationEngine 生命周期测试（12 tests）— **发现了 reset() 未重置 speed 的 bug**
  - 修复 reset() speed 未重置的问题
- [x] **可执行架构边界检查**（Lecture 10）
  - `scripts/verify-architecture.sh`：7 条自动检查（core 纯度、3d-engine Vue 隔离、ui 方向、workspace:*、无 .glb、命名启发式、paths 目标）
  - 所有错误消息包含 WHAT/WHY/FIX（面向 agent 的自校正设计）
  - `verify-layers.sh` 增强为四层：Layer 0 架构边界 → Layer 1 静态 → Layer 2 运行时 → Layer 3 端到端（跨组件符号检测）
  - ADR-009 记录决策
- [x] **运行时与过程可观测性**（Lecture 11）
  - `scripts/harness-trace.sh`：任务追踪记录器，生成结构化 JSON trace（.harness/traces/）
  - `.harness/contracts/template.md`：Sprint Contract 模板，编码前对齐范围与验收标准
  - `.harness/rubrics/default.json`：五维度 Evaluator Rubric（代码正确性 30%、架构合规性 25%、测试覆盖 20%、文档同步 15%、端到端验证 10%）
  - `scripts/evaluate-feature.sh`：基于 Rubric 的结构化评分工具
  - `verify-layers.sh` 自动集成 trace 记录（每层结果、耗时、错误）
  - ADR-010 记录决策
- [x] **干净状态检查与定期清理**（Lecture 12）
  - `scripts/session-exit-check.sh`：五维度干净状态检查（构建/测试/进度/产物/启动）
  - `scripts/session-cleanup.sh`：幂等清理脚本（临时文件、debug 代码、空目录、过期 trace）
  - `docs/quality.md`：模块质量追踪文档（core=A, 3d-engine=C, ui=C, web=C, infra=A）
  - Clock Out 流程扩展为五维度检查清单
  - 双模式清理策略：即时清理（每次会话）+ 定期清理（每月第一周）
  - Harness 简化机制：每月审视一个组件，验证是否可被模型自主替代
  - ADR-011 记录决策
- [x] 项目脚手架与 Monorepo 结构
- [x] ESLint 10 Flat Config 配置
- [x] TypeScript Workspace 路径配置
- [x] AGENTS.md 入口文件（<100 行，硬约束 + 专题索引）
- [x] Harness Engineering 规则体系（ACID、知识衰减防护、全新会话测试）
- [x] DECISIONS.md 架构决策记录
- [x] 各包 ARCHITECTURE.md 模块级文档
- [x] 专题文档拆分（docs/toolchain.md、coding-standards.md、workflow.md）
- [x] Makefile 标准化命令
- [x] **WIP=1 工作流引入** — `feature_list.json` 重构为范围表面，含完成证据、DAG、四状态
- [x] **harness-creator skill** — 项目内置 skill，支持初始化、验证、维护 Harness 控制

## 进行中（active）

无 —— VCR = 1.0，可启动下一个任务

## 待办（按 WIP=1 规则排序）

### 可立即启动（依赖已满足）

| 优先级 | ID | 名称 | 领域 | 依赖 | 说明 |
|--------|-----|------|------|------|------|
| high | **F004** | MES 仿真引擎 | core | F002 ✅ | 引擎框架已有，processEvent 仍是 TODO，缺 event-queue.test.ts 和 simulation-engine.test.ts |
| medium | **F007** | Lot 流转动画 | 3d-engine | F003 ✅, F004 ❌ | 动画系统已有基础，缺 pause/speed/reverse 控制 |

### 阻塞中（依赖未满足）

| 优先级 | ID | 名称 | 领域 | 阻塞原因 |
|--------|-----|------|------|----------|
| medium | F008 | 仿真控制面板 | web | 等待 F005 ✅（已满足，但需 F004 稳定后启动） |
| low | F009 | 设备详情弹窗 | web | 等待 F003 ✅（已满足，但需 F005 稳定后启动） |
| low | F010 | WIP 追踪看板 | web | 等待 F005 ✅（已满足） |

> **注意**: F008/F009/F010 的依赖在代码层面已满足（F003/F005 均已 passing），但按照 WIP=1 规则，应先完成 F004 再启动它们。

## 已知问题

1. **F004 processEvent 是 TODO** — `packages/core/src/engine/simulation-engine.ts` 第 136-146 行的事件处理逻辑为空实现。需要实现 LotArrival、EquipmentReady、ProcessComplete、EquipmentBreakdown、EquipmentRepair 五种事件的处理逻辑。
2. **F007 动画系统缺控制功能** — `packages/3d-engine/src/animation/animation-system.ts` 有 `play()` 和 `stop()`，但没有 `pause()`、`setSpeed()`、`reverse()` 方法。

## 验证债务（Lecture 09）

> 验证债务 = passing 的功能中，verificationCommand 以 Layer 1（grep/静态检查）为主的数量。

| Feature | 状态 | Layer 1 | Layer 2 | Layer 3 | 债务 |
|---------|------|---------|---------|---------|------|
| F001 | passing | ✅ grep | ⚠️ 无单元测试 | ⚠️ 无端到端 | 中 |
| F002 | passing | ✅ grep | ✅ 单元测试 | ⚠️ 无端到端 | 低 |
| F003 | passing | ✅ grep | ⚠️ 无单元测试 | ⚠️ 无端到端 | 中 |
| F005 | passing | ✅ grep | ⚠️ 无单元测试 | ⚠️ 无端到端 | 中 |
| F006 | passing | ✅ grep | ⚠️ 无单元测试 | ⚠️ 无端到端 | 中 |
| F004 | not_started | — | ✅ EventQueue+SimEngine 测试已写 | — | — |

**行动**：F004 完成（含 processEvent + 端到端测试）后，应按优先级为 F001/F003/F005/F006 补充 Layer 2/3 测试。

## 阻塞项

无外部阻塞项。

## 下一步

1. **启动 F004（MES 仿真引擎）**
   - 已有基础代码（EventQueue、SimulationEngine 类）
   - 需要完成：
     - 实现 `processEvent()` 中的具体事件处理逻辑（非 TODO）
     - 编写 `event-queue.test.ts`（最小堆行为测试）
     - 编写 `simulation-engine.test.ts`（start/pause/reset/tick/setSpeed 行为测试）
2. **F004 passing 后，启动 F007（Lot 流转动画）**
   - 补充 `AnimationSystem` 的 `pause()`、`setSpeed()`、`reverse()` 方法
3. **然后按优先级启动 F008 → F009 → F010**

> **WIP=1 提醒**: 一次只启动一个。不要同时做 F004 和 F007。
> **会话交接提示**: 新会话请从「下一步」开始执行。若已完成某项，请将其移到「已完成」并更新上方的「最新 commit」和「验证状态」。
