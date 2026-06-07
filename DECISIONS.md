# 架构决策记录（Architecture Decision Records）

> 本文件是系统记录的一部分。任何影响项目方向、技术选型或模块边界的重要决策都必须记录在此。
> 
> **规则**：
> - 决策一旦记录，状态变为「已接受」后不可删除，只能通过新的 ADR 推翻
> - 每条 ADR 必须包含：背景、决策、后果、状态
> - 口头讨论的结论必须在 24 小时内写入本文件

---

## ADR-001：3D 引擎从 Three.js 迁移到 Babylon.js

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: 项目早期使用 Three.js，但在场景管理、动画系统和 TypeScript 支持方面遇到瓶颈
- **决策**: 全面迁移到 Babylon.js 9.x
- **拒绝的替代方案**: 继续使用 Three.js + 自研动画管理器（场景生命周期维护成本高，TypeScript 类型不完整）
- **后果**: 
  - 获得更完善的场景生命周期管理
  - 原生动画系统支持暂停/加速/回退
  - 更好的 TypeScript 类型定义
  - 需要重写所有 3D 资产创建逻辑

## ADR-002：采用 ESLint 10 Flat Config 格式

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: ESLint 8 的 legacy 格式（plugins/parsers）与 ESLint 10 不兼容，且 Flat Config 是官方推荐方向
- **决策**: 全仓库统一使用 Flat Config，彻底弃用 `@typescript-eslint/eslint-plugin` 和 `@typescript-eslint/parser`
- **拒绝的替代方案**: 继续使用 ESLint 8 legacy 格式（与 ESLint 10 不兼容，长期维护成本更高）
- **后果**:
  - 使用 `typescript-eslint` 替代旧包
  - lint 脚本不再使用 `--ext`
  - 浏览器全局变量必须在 `languageOptions.globals` 中显式声明
  - 配置文件必须是 ESM（`"type": "module"`）

## ADR-003：Monorepo + pnpm workspace 结构

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: 项目涉及 MES 领域逻辑、3D 引擎、UI 组件和主应用四个独立演进维度
- **决策**: 使用 pnpm workspace + Turbo 构建管道，按职责拆分为 `apps/web` + `packages/*`
- **拒绝的替代方案**: 单仓库不分包（领域逻辑与渲染/UI 耦合，无法独立复用和测试）
- **后果**:
  - 明确的包间依赖边界（见 AGENTS.md 包间依赖规则）
  - `@semi/core` 必须保持纯 TypeScript，禁止 UI 依赖
  - workspace 包引用必须使用 `workspace:*` 协议

## ADR-004：纯 TypeScript 核心包设计

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: 领域模型和仿真引擎是项目的知识核心，不应与任何前端框架绑定
- **决策**: `@semi/core` 严格限制为纯 TypeScript，仅通过类型和事件接口与上层交互
- **拒绝的替代方案**: 允许 `@semi/core` 依赖 Vue/Pinia（领域逻辑与前端框架绑定，丧失跨平台复用能力）
- **后果**:
  - `@semi/3d-engine` 和 `@semi/ui` 只能消费 `@semi/core` 的类型
  - 仿真状态变更通过事件/回调驱动，不直接调用渲染逻辑
  - 确保领域逻辑可以在非 Web 环境（如 Node.js CLI 仿真）中复用

## ADR-006：拆分 AGENTS.md 为入口文件 + 专题文档

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: AGENTS.md 膨胀到 361 行，超出 50-200 行的推荐范围。agent 处理长指令文件时出现「中间迷失」效应，关键约束被忽略
- **决策**: 将 AGENTS.md 拆分为不超过 100 行的入口文件（概览 + 硬约束 + 专题索引），工具链/编码/工作流规范独立到 `docs/*.md`
- **拒绝的替代方案**: 保持单文件 361 行（agent 处理长指令时出现「中间迷失」，关键约束被忽略）
- **后果**:
  - 提升指令信噪比，agent 按需加载专题文档
  - 关键硬约束集中在入口文件顶部，降低被忽略概率
  - 专题文档可按主题独立维护，减少知识衰减
  - 新增 `docs/toolchain.md`、`docs/coding-standards.md`、`docs/workflow.md`

## ADR-005：引入 Harness Engineering 规则体系

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: AI 智能体频繁因「知识可见性缺口」导致错误决策，仓库文档与代码脱节严重
- **决策**: 正式引入 Harness Engineering 规则：AGENTS.md 作为入口、模块级 ARCHITECTURE.md、DECISIONS.md 持久化决策、ACID 工作原则、知识衰减防护
- **拒绝的替代方案**: 依赖 agent 内部记忆和口头交接（会话边界导致知识丢失，产生理解漂移）
- **后果**:
  - 每次代码变更必须检查对应模块文档
  - 架构决策必须书面化，禁止口头传递
  - 新会话可通过「全新会话测试」自检仓库质量

## ADR-007：全仓库依赖大版本升级

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: 项目初始化时的依赖版本已落后，TypeScript 5.4、Vite 5、Vitest 1、Pinia 2、Vue 3.4 均已有较新的大版本发布
- **决策**: 一次性将所有非 workspace 依赖升级到最新稳定版本，Babylon.js 同步升级到 9.x
- **升级清单**:
  - TypeScript: 5.4.2 → 6.0.3
  - Vue: 3.4.0 → 3.5.35
  - Vite: 5.2.0 → 8.0.16
  - Vitest: 1.6.0 → 4.1.8
  - Pinia: 2.1.0 → 3.0.4
  - vue-tsc: 2.2.8 → 3.3.3
  - @vitejs/plugin-vue: 5.0.0 → 6.0.7
  - @babylonjs/core/gui: 7.0.0 → 9.11.0
  - turbo: 2.0.0 → 2.9.16
- **兼容性处理**:
  - TypeScript 6 弃用 `baseUrl`，移除 `apps/web/tsconfig.json` 中的 `baseUrl`，并将 `paths` 中的值改为相对路径（`./src/*`）
- **拒绝的替代方案**: 保持旧版本（无法获得性能优化，长期技术债务累积）
- **后果**:
  - 获得各依赖的最新性能优化和 bug 修复
  - TypeScript 6 的 `baseUrl` 弃用需要所有 `paths` 使用相对路径
  - Babylon.js 从 7 升级到 9 是大版本跳跃，需关注后续 breaking changes
