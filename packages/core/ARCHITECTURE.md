# @semi/core — MES 核心领域逻辑

## 职责

纯 TypeScript 领域层。包含：
- 半导体 MES 核心数据模型（Lot、Equipment、Recipe、ProcessStep）
- 离散事件仿真（DES）引擎
- 调度算法与策略接口

## 目录结构

```
src/
├── models/      # 领域类型与接口定义
├── engine/      # 仿真引擎（事件队列、时间推进、状态更新）
└── index.ts     # 公共 API 导出（仅导出类型和引擎接口）
```

## 关键约束

- **纯 TypeScript，禁止依赖任何 UI 库**（Vue、Babylon.js 等均不可引入）
- 供 `@semi/3d-engine` 和 `@semi/ui` 消费的是**类型和事件接口**，不是实例
- 仿真状态变更通过事件/回调驱动外部系统，不主动调用渲染逻辑

## 对外接口

```typescript
// 主要导出（设计目标，待实现）
export type { Lot, Equipment, Recipe, ProcessStep }
export type { SimulationEvent, SimulationState }
export { SimulationEngine }
```

## 变更影响检查清单

修改本包代码后，必须检查以下文档和依赖项：

- [ ] 本文件（ARCHITECTURE.md）中的「对外接口」描述是否仍然准确
- [ ] 导出的类型变更是否同步到 `packages/ui/index.d.ts`（如 Equipment、Lot 等类型被 UI 组件使用时）
- [ ] 仿真引擎接口变更是否通知到 `packages/3d-engine/ARCHITECTURE.md`

## 依赖

- `@semi/config`（仅 TS 配置）
- 无其他 workspace 包依赖
