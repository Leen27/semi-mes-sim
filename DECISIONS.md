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
- **决策**: 全面迁移到 Babylon.js 7.x
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
- **后果**:
  - 明确的包间依赖边界（见 AGENTS.md 包间依赖规则）
  - `@semi/core` 必须保持纯 TypeScript，禁止 UI 依赖
  - workspace 包引用必须使用 `workspace:*` 协议

## ADR-004：纯 TypeScript 核心包设计

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: 领域模型和仿真引擎是项目的知识核心，不应与任何前端框架绑定
- **决策**: `@semi/core` 严格限制为纯 TypeScript，仅通过类型和事件接口与上层交互
- **后果**:
  - `@semi/3d-engine` 和 `@semi/ui` 只能消费 `@semi/core` 的类型
  - 仿真状态变更通过事件/回调驱动，不直接调用渲染逻辑
  - 确保领域逻辑可以在非 Web 环境（如 Node.js CLI 仿真）中复用

## ADR-005：引入 Harness Engineering 规则体系

- **状态**: 已接受
- **日期**: 2026-06-07
- **背景**: AI 智能体频繁因「知识可见性缺口」导致错误决策，仓库文档与代码脱节严重
- **决策**: 正式引入 Harness Engineering 规则：AGENTS.md 作为入口、模块级 ARCHITECTURE.md、DECISIONS.md 持久化决策、ACID 工作原则、知识衰减防护
- **后果**:
  - 每次代码变更必须检查对应模块文档
  - 架构决策必须书面化，禁止口头传递
  - 新会话可通过「全新会话测试」自检仓库质量
