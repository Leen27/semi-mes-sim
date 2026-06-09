# 半导体 MES 领域专家 — 最小原子任务清单

> 本文件是 `@semi/core` 包所有开发任务的唯一真实来源。
> **规则**: 每个任务必须是单一职责、独立验证、可回滚的原子单元。

---

## 任务状态图例

| 状态 | 图标 | 说明 |
|------|------|------|
| pending | ⏸ | 等待执行 |
| active | 🔄 | 正在执行 |
| passing | ✅ | 验证通过 |
| blocked | 🔒 | 依赖未满足 |

---

## Phase 0: 现有代码梳理（已完成）

> 以下任务在创建本 Agent 之前已由其他开发者完成：

| 任务 | 内容 | 状态 |
|------|------|------|
| M000-A | Lot 模型 (`models/lot.ts`) | ✅ passing |
| M000-B | Equipment 模型 (`models/equipment.ts`) | ✅ passing |
| M000-C | Recipe 模型 (`models/recipe.ts`) | ✅ passing |
| M000-D | ProcessStep/Route 模型 (`models/process-step.ts`) | ✅ passing |
| M000-E | EventQueue (`engine/event-queue.ts`) | ✅ passing |
| M000-F | SimulationEngine 骨架 (`engine/simulation-engine.ts`) | ✅ passing |

**注意**: SimulationEngine 的 `processEvent()` 方法是 TODO，将在 Phase 4 实现。

---

## Phase 1: 物流实体模型

### M001 — Buffer 缓冲领域模型
```yaml
name: Buffer 缓冲领域模型
description: |
  定义 Buffer（缓冲）领域模型，包括 Buffer 接口、BufferType 枚举、状态管理。
  Buffer 是产线中 Lot 暂存等待加工的关键实体。
scope:
  do:
    - 定义 Buffer 接口（id, name, type, capacity, queuedLotIds, associatedEquipmentId, workAreaId, position）
    - 定义 BufferType 枚举（Input, Output, Intermediate, Stocker）
    - 定义 BufferConfig 配置接口（供 JSON 解析）
    - 实现 validateBufferConfig() 验证函数
    - 编写 buffer.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不包含 3D 渲染相关属性
    - 不处理 Lot 进出队列的业务逻辑（那是仿真引擎的职责）
files:
  - src/models/buffer.ts
  - src/models/buffer.test.ts
  - src/models/index.ts  # 更新导出
dependencies: []
  # M000-B Equipment 模型（已存在）
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/buffer.test.ts
    check:
      - Buffer 接口所有字段类型正确
      - BufferType 枚举值正确
      - validateBufferConfig 验证必填字段
      - validateBufferConfig 验证 type 枚举值
      - 默认值填充正确
status: pending
```

### M002 — Stocker 中央仓储领域模型
```yaml
name: Stocker 中央仓储领域模型
description: |
  定义 Stocker（中央仓储）领域模型。Stocker 是大容量跨区缓冲，
  与 Buffer 的区别是：Stocker 有分层货架，服务多个 WorkArea。
scope:
  do:
    - 定义 Stocker 接口（id, name, capacity, levels, levelLotIds, servesWorkAreaIds, position）
    - 定义 StockerConfig 配置接口
    - 实现 validateStockerConfig() 验证函数
    - 编写 stocker.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不处理出入库业务逻辑
    - 不与 Buffer 合并（它们是不同概念）
files:
  - src/models/stocker.ts
  - src/models/stocker.test.ts
  - src/models/index.ts  # 更新导出
dependencies:
  - M001  # Buffer（参考其设计模式）
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/stocker.test.ts
    check:
      - Stocker 接口字段完整
      - levelLotIds 是二维数组（层 × Lot）
      - validateStockerConfig 验证 capacity > 0
      - validateStockerConfig 验证 levels > 0
status: pending
```

### M003 — TransportPath / TransportVehicle 领域模型
```yaml
name: TransportPath / TransportVehicle 传输系统领域模型
description: |
  定义传输系统的领域模型：传输路径和传输车辆。
scope:
  do:
    - 定义 TransportPath 接口（id, type, points, speed, vehicleIds, workAreaId）
    - 定义 TransportType 枚举（AMHS, AGV, Manual, Conveyor）
    - 定义 TransportPathConfig 配置接口
    - 定义 TransportVehicle 接口（id, type, currentPathId, pathPosition, carryingLotId, status）
    - 定义 VehicleStatus 枚举（Idle, Moving, Loading, Unloading）
    - 实现 validateTransportPathConfig() 验证函数
    - 编写 transport.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不处理路径寻路算法
    - 不处理车辆调度逻辑
files:
  - src/models/transport.ts
  - src/models/transport.test.ts
  - src/models/index.ts  # 更新导出
dependencies:
  - M001  # Buffer（参考设计模式）
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/transport.test.ts
    check:
      - TransportType 枚举包含 4 种类型
      - VehicleStatus 枚举包含 4 种状态
      - validateTransportPathConfig 验证 points 至少 2 个点
      - validateTransportPathConfig 验证 speed > 0
status: pending
```

---

## Phase 2: 空间实体模型

### M004 — WorkArea / EquipmentGroup 领域模型
```yaml
name: WorkArea / EquipmentGroup 工作区领域模型
description: |
  定义工厂空间组织的领域模型：WorkArea（工作区）和 EquipmentGroup（设备组）。
scope:
  do:
    - 定义 WorkArea 接口（id, name, type, position, size, equipmentGroupIds, bufferIds, transportPathIds）
    - 定义 EquipmentGroup 接口（id, layout, equipmentIds, workAreaId）
    - 定义 GroupLayout 枚举（Linear, Grid, Cluster）
    - 定义 WorkAreaConfig 配置接口
    - 实现 validateWorkAreaConfig() 验证函数
    - 编写 work-area.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不包含 3D 区域边界等渲染属性
files:
  - src/models/work-area.ts
  - src/models/work-area.test.ts
  - src/models/index.ts  # 更新导出
dependencies:
  - M001  # Buffer（参考 position 设计）
  - M003  # TransportPath
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/work-area.test.ts
    check:
      - WorkArea size 包含 width 和 depth
      - GroupLayout 枚举值正确
      - validateWorkAreaConfig 验证 size.width > 0
status: pending
```

### M005 — Fab 工厂领域模型
```yaml
name: Fab 晶圆厂领域模型
description: |
  定义 Fab（晶圆厂）顶层领域模型。
scope:
  do:
    - 定义 Fab 接口（id, name, size, workAreaIds, stockerIds）
    - 定义 FabConfig 配置接口
    - 实现 validateFabConfig() 验证函数
    - 编写 fab.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - Fab 是聚合根，不包含具体业务逻辑
files:
  - src/models/work-area.ts  # 追加到已有文件
  - src/models/work-area.test.ts  # 追加测试
  - src/models/index.ts  # 更新导出
dependencies:
  - M004  # WorkArea
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/work-area.test.ts
    check:
      - Fab 接口字段完整
      - validateFabConfig 验证必填字段
status: pending
```

---

## Phase 3: MES 系统实体模型

### M006 — MESState / WIPStatistics 领域模型
```yaml
name: MESState / WIPStatistics MES 系统状态模型
description: |
  定义 MES 系统运行时状态的领域模型。
scope:
  do:
    - 定义 MESState 接口（id, type, activeSchedulingRule, eventQueue, wipStats）
    - 定义 WIPStatistics 接口（total, waiting, processing, completed, byWorkArea）
    - 定义 EventDefinition 接口（ceid, name, description, enabled）
    - 编写 mes-system.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不包含 3D 可视化相关属性
files:
  - src/models/mes-system.ts
  - src/models/mes-system.test.ts
  - src/models/index.ts  # 更新导出
dependencies:
  - M000-E  # SimulationEvent（已存在）
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/mes-system.test.ts
    check:
      - WIPStatistics byWorkArea 是 Record 类型
      - MESState type 是 'central' | 'distributed'
status: pending
```

### M007 — FaultDefinition / FaultEvent 领域模型
```yaml
name: FaultDefinition / FaultEvent 故障领域模型
description: |
  定义故障库和故障事件的领域模型。
scope:
  do:
    - 定义 FaultCategory 枚举（Communication, Equipment, Process, MES）
    - 定义 FaultSeverity 枚举（Warning, Error, Fatal）
    - 定义 FaultDefinition 接口（故障库条目）
    - 定义 FaultEvent 接口（运行时故障实例）
    - 定义 FaultInjectionConfig 配置接口
    - 定义 FaultScriptStep 接口
    - 提供 DEFAULT_FAULT_LIBRARY 默认故障库
    - 编写 fault.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不实现故障注入的业务逻辑（那是仿真引擎的职责）
files:
  - src/models/mes-system.ts  # 追加到已有文件
  - src/models/mes-system.test.ts  # 追加测试
  - src/models/index.ts  # 更新导出
dependencies:
  - M006  # MESState
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/mes-system.test.ts
    check:
      - DEFAULT_FAULT_LIBRARY 非空
      - FaultSeverity 枚举值正确
      - FaultEvent isActive 字段存在
status: pending
```

---

## Phase 4: 统计实体模型

### M008 — OEEMetrics / EquipmentTimeLog 统计模型
```yaml
name: OEEMetrics / EquipmentTimeLog 设备效率统计模型
description: |
  定义 OEE（设备综合效率）统计的领域模型。
scope:
  do:
    - 定义 OEEMetrics 接口（equipmentId, availability, performance, quality, oee, period）
    - 定义 EquipmentTimeLog 接口（equipmentId, periods）
    - 定义 TimePeriod 接口（start, end, type）
    - 定义 TimePeriodType 类型
    - 实现 calculateOEE() 计算函数
    - 编写 statistics.test.ts 单元测试
    - 更新 models/index.ts 导出
  dont:
    - 不实现时间记录的数据收集（那是仿真引擎的职责）
    - 只提供计算函数
files:
  - src/models/statistics.ts
  - src/models/statistics.test.ts
  - src/models/index.ts  # 更新导出
dependencies: []
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/models/statistics.test.ts
    check:
      - calculateOEE 返回正确值
      - oee = availability × performance × quality
      - 边界情况处理（除零等）
status: pending
```

---

## Phase 5: 配置验证层

### M009 — ValidationError 和版本迁移基础设施
```yaml
name: ValidationError 验证错误类 + 版本迁移
description: |
  实现配置验证的基础设施：ValidationError 类和版本迁移函数。
scope:
  do:
    - 定义 ValidationError 类（继承 Error，包含 path, expected, actual）
    - 定义 VersionedConfig 接口
    - 实现 migrateConfig() 版本迁移函数
    - 编写 validation.test.ts 单元测试
    - 创建 config/index.ts 导出
  dont:
    - 不实现具体配置的验证逻辑（后续任务）
files:
  - src/config/validation-error.ts
  - src/config/version-migration.ts
  - src/config/index.ts
  - src/config/validation.test.ts
dependencies: []
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/config/validation.test.ts
    check:
      - ValidationError 包含 path/expected/actual
      - migrateConfig 正确升级版本
      - 不支持版本抛出错误
status: pending
```

### M010 — FabLayoutConfig 验证
```yaml
name: FabLayoutConfig 工厂布局配置验证
description: |
  实现工厂布局配置的完整验证：FabLayoutConfig 及所有子配置类型。
  这是核心配置，供 3D 引擎和仿真引擎共同消费。
scope:
  do:
    - 定义 FabLayoutConfig 接口（extends VersionedConfig）
    - 定义 FabConfig 接口
    - 定义 WorkAreaConfig 接口
    - 定义 EquipmentGroupConfig 接口
    - 定义 EquipmentConfig 接口
    - 定义 BufferConfig 接口
    - 定义 StockerConfig 接口
    - 定义 TransportPathConfig 接口
    - 定义 MESSystemConfig 接口
    - 实现 validateFabLayoutConfig() 验证函数
    - 编写 fab-layout-config.test.ts 单元测试
    - 更新 config/index.ts 导出
  dont:
    - 不包含 3D 场景特有的配置（camera、light、backgroundColor）
    - 那些属于 @3d-expert 的职责
files:
  - src/config/fab-layout-config.ts
  - src/config/fab-layout-config.test.ts
  - src/config/index.ts  # 更新导出
dependencies:
  - M009  # ValidationError
  - M000  # 所有现有模型（了解字段类型）
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/config/fab-layout-config.test.ts
    check:
      - validateFabLayoutConfig 验证 version 必填
      - validateFabLayoutConfig 验证 fab 必填
      - validateFabLayoutConfig 验证 workAreas 是数组
      - EquipmentConfig type 验证为有效 EquipmentType
      - BufferConfig type 验证为有效 BufferType
      - TransportPathConfig points 至少 2 个点
      - 错误信息包含具体路径
status: pending
```

### M011 — ProcessConfig 工艺配置验证
```yaml
name: ProcessConfig 工艺配置验证
description: |
  实现工艺配方和工艺路线的配置验证。
scope:
  do:
    - 定义 ProcessConfig 接口
    - 定义 RecipeConfig 接口
    - 定义 ProcessRouteConfig 接口
    - 实现 validateProcessConfig() 验证函数
    - 编写 process-config.test.ts 单元测试
    - 更新 config/index.ts 导出
  dont:
    - 不包含 3D 渲染相关配置
files:
  - src/config/process-config.ts
  - src/config/process-config.test.ts
  - src/config/index.ts  # 更新导出
dependencies:
  - M009  # ValidationError
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/config/process-config.test.ts
    check:
      - RecipeConfig processTime > 0
      - ProcessRouteConfig steps 非空
      - steps sequence 无重复
status: pending
```

### M012 — SimulationRuntimeConfig 仿真运行时配置验证
```yaml
name: SimulationRuntimeConfig 仿真运行时配置验证
description: |
  实现仿真运行时配置的验证。
scope:
  do:
    - 定义 SimulationRuntimeConfig 接口
    - 实现 validateSimulationRuntimeConfig() 验证函数
    - 编写 simulation-config.test.ts 单元测试
    - 更新 config/index.ts 导出
  dont:
    - 不包含 3D 场景配置
files:
  - src/config/simulation-config.ts
  - src/config/simulation-config.test.ts
  - src/config/index.ts  # 更新导出
dependencies:
  - M009  # ValidationError
  - M007  # FaultInjectionConfig
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/config/simulation-config.test.ts
    check:
      - schedulingRule 必填
      - faultInjection script 时间非负
status: pending
```

---

## Phase 6: 调度策略

### M013 — SchedulingStrategy 接口定义
```yaml
name: SchedulingStrategy 调度策略接口
description: |
  定义调度策略的接口和基础类型。
scope:
  do:
    - 定义 SchedulingStrategy 接口（name, description, scoreLot, selectEquipment, dispatch）
    - 定义 DispatchContext 接口
    - 定义 DispatchDecision 接口
    - 创建 scheduling/index.ts 导出
    - 编写 strategy-interface.test.ts（接口类型测试）
  dont:
    - 不实现具体策略（后续任务）
files:
  - src/scheduling/strategy-interface.ts
  - src/scheduling/index.ts
  - src/scheduling/strategy-interface.test.ts
dependencies:
  - M000  # 现有模型
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/scheduling/strategy-interface.test.ts
    check:
      - SchedulingStrategy 接口字段完整
      - DispatchDecision candidates 是数组
status: pending
```

### M014 — FIFO 调度策略
```yaml
name: FIFO 先进先出调度策略
description: |
  实现 FIFO（First In First Out）调度策略。
scope:
  do:
    - FIFOStrategy 类实现 SchedulingStrategy
    - scoreLot: 按等待时间排序
    - selectEquipment: 选择第一个可用设备
    - dispatch: 返回 DispatchDecision
    - 编写 fifo-strategy.test.ts
    - 更新 scheduling/index.ts 导出
  dont:
    - 不与仿真引擎直接耦合
files:
  - src/scheduling/fifo-strategy.ts
  - src/scheduling/fifo-strategy.test.ts
  - src/scheduling/index.ts  # 更新导出
dependencies:
  - M013  # SchedulingStrategy 接口
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/scheduling/fifo-strategy.test.ts
    check:
      - 等待时间最长的 Lot 被选中
      - dispatch 返回正确 rule 名称 'FIFO'
      - 无等待 Lot 时返回 null
status: pending
```

### M015 — SPT 调度策略
```yaml
name: SPT 最短加工时间调度策略
description: |
  实现 SPT（Shortest Processing Time）调度策略。
scope:
  do:
    - SPTStrategy 类实现 SchedulingStrategy
    - scoreLot: 加工时间越短分数越高
    - dispatch: 返回 DispatchDecision
    - 编写 spt-strategy.test.ts
    - 更新 scheduling/index.ts 导出
  dont:
    - 不与仿真引擎直接耦合
files:
  - src/scheduling/spt-strategy.ts
  - src/scheduling/spt-strategy.test.ts
  - src/scheduling/index.ts  # 更新导出
dependencies:
  - M013  # SchedulingStrategy 接口
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/scheduling/spt-strategy.test.ts
    check:
      - 加工时间最短的 Lot 被选中
      - dispatch 返回正确 rule 名称 'SPT'
status: pending
```

### M016 — CR 关键比率调度策略
```yaml
name: CR 关键比率调度策略
description: |
  实现 CR（Critical Ratio）调度策略。
scope:
  do:
    - CRStrategy 类实现 SchedulingStrategy
    - scoreLot: CR = 剩余时间/剩余工序数，越小越紧急
    - dispatch: 返回 DispatchDecision
    - 编写 cr-strategy.test.ts
    - 更新 scheduling/index.ts 导出
  dont:
    - 不与仿真引擎直接耦合
files:
  - src/scheduling/cr-strategy.ts
  - src/scheduling/cr-strategy.test.ts
  - src/scheduling/index.ts  # 更新导出
dependencies:
  - M013  # SchedulingStrategy 接口
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/scheduling/cr-strategy.test.ts
    check:
      - CR 最小的 Lot 被选中
      - dispatch 返回正确 rule 名称 'CR'
status: pending
```

### M017 — StrategyRegistry 策略注册表
```yaml
name: StrategyRegistry 调度策略注册表
description: |
  实现策略注册表，支持按名称查找策略实例。
scope:
  do:
    - StrategyRegistry 类
    - register(name, strategy) 注册策略
    - get(name) 按名称获取策略
    - list() 列出所有已注册策略
    - 默认注册 FIFO、SPT、CR
    - 编写 strategy-registry.test.ts
    - 更新 scheduling/index.ts 导出
  dont:
    - 不修改策略接口
files:
  - src/scheduling/strategy-registry.ts
  - src/scheduling/strategy-registry.test.ts
  - src/scheduling/index.ts  # 更新导出
dependencies:
  - M014  # FIFO
  - M015  # SPT
  - M016  # CR
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/scheduling/strategy-registry.test.ts
    check:
      - 默认注册 3 个策略
      - get('FIFO') 返回 FIFOStrategy 实例
      - 重复注册抛出错误
status: pending
```

---

## Phase 7: 仿真引擎完善

### M018 — SimulationContext 仿真上下文
```yaml
name: SimulationContext 仿真上下文
description: |
  实现 SimulationContext 接口，为事件处理器提供实体查询和事件调度能力。
scope:
  do:
    - SimulationContext 接口（getEquipment, getLot, getBuffer, getStocker, getRecipe, getRoute, scheduleEvent）
    - SimulationContextImpl 类实现
    - 内部维护实体 Map 索引
    - 编写 simulation-context.test.ts
    - 更新 engine/index.ts 导出
  dont:
    - 不实现事件处理器（M019）
files:
  - src/engine/simulation-context.ts
  - src/engine/simulation-context.test.ts
  - src/engine/index.ts  # 更新导出
dependencies:
  - M000  # 所有现有模型
  - M001  # Buffer
  - M002  # Stocker
  - M003  # Transport
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/engine/simulation-context.test.ts
    check:
      - getEquipment 按 ID 查找正确
      - getLot 按 ID 查找正确
      - scheduleEvent 将事件加入队列
status: pending
```

### M019 — EventHandlerRegistry + 核心事件处理器
```yaml
name: EventHandlerRegistry + 核心事件处理器
description: |
  实现事件处理器注册表和核心事件处理逻辑。
  替换 SimulationEngine 中的 TODO processEvent。
scope:
  do:
    - EventHandlerRegistry 类
    - LotArrival 处理器：将 Lot 分配到可用设备或 Buffer
    - EquipmentReady 处理器：设备就绪，检查是否有等待 Lot
    - EquipmentProcessComplete 处理器：加工完成，Lot 移动到下一步
    - EquipmentBreakdown 处理器：设备故障，标记状态
    - EquipmentRepair 处理器：设备修复，恢复状态
    - 注册所有处理器到 Registry
    - 修改 SimulationEngine.processEvent 使用 Registry
    - 编写 event-handlers.test.ts
    - 更新 engine/index.ts 导出
  dont:
    - 不处理 3D 动画触发（通过 callbacks.onEvent 通知外部）
    - 不处理传输系统（M020）
files:
  - src/engine/event-handlers.ts
  - src/engine/event-handlers.test.ts
  - src/engine/simulation-engine.ts  # 修改 TODO
  - src/engine/index.ts  # 更新导出
dependencies:
  - M018  # SimulationContext
  - M013  # SchedulingStrategy 接口
  - M017  # StrategyRegistry
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/engine/event-handlers.test.ts
  - cmd: cd packages/core && npx vitest run src/engine/simulation-engine.test.ts
    check:
      - LotArrival 产生 EquipmentReady 或 LotMoveToBuffer 事件
      - EquipmentProcessComplete 后设备状态变 Idle
      - EquipmentBreakdown 后设备状态变 Error
      - SimulationEngine 的 TODO 被替换
status: pending
```

### M020 — 传输系统事件处理器
```yaml
name: 传输系统事件处理器
description: |
  实现传输相关的事件处理器。
scope:
  do:
    - VehicleArrive 处理器
    - VehicleLoadComplete 处理器
    - VehicleUnloadComplete 处理器
    - LotMoveToStocker 处理器
    - 注册到 EventHandlerRegistry
    - 编写 transport-event-handlers.test.ts
    - 更新 engine/index.ts 导出
  dont:
    - 不实现路径寻路
files:
  - src/engine/event-handlers.ts  # 追加处理器
  - src/engine/event-handlers.test.ts  # 追加测试
dependencies:
  - M019  # 核心事件处理器
  - M003  # Transport 模型
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/engine/event-handlers.test.ts
    check:
      - VehicleArrive 更新车辆位置
      - VehicleLoadComplete 更新 carryingLotId
status: pending
```

### M021 — 故障注入事件处理器
```yaml
name: 故障注入事件处理器
description: |
  实现故障注入和恢复的事件处理器。
scope:
  do:
    - 故障注入逻辑（随机/手动/脚本）
    - EquipmentBreakdown 处理器完善
    - EquipmentRepair 处理器完善
    - 随机故障生成器（基于 MTBF）
    - 编写 fault-injection.test.ts
    - 更新 engine/index.ts 导出
  dont:
    - 不处理 3D 故障可视化（那是 @3d-expert 的职责）
files:
  - src/engine/event-handlers.ts  # 追加处理器
  - src/engine/fault-injection.ts  # 新增文件
  - src/engine/fault-injection.test.ts
  - src/engine/index.ts  # 更新导出
dependencies:
  - M019  # 核心事件处理器
  - M007  # FaultDefinition
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check
  - cmd: cd packages/core && npx vitest run src/engine/fault-injection.test.ts
    check:
      - 随机故障按 MTBF 概率触发
      - 故障注入后设备状态正确
      - 故障修复后设备恢复
status: pending
```

---

## Phase 8: 整合与导出

### M022 — 完善 src/index.ts 统一导出
```yaml
name: 完善 index.ts 统一导出
description: |
  更新 packages/core/src/index.ts，导出所有新增模块的公共 API。
scope:
  do:
    - 导出所有新增领域模型类型
    - 导出状态机函数
    - 导出仿真引擎
    - 导出调度策略
    - 导出配置验证函数
    - 确保不导出内部实现细节
  dont:
    - 不导出测试文件
    - 不导出未完成的内部模块
files:
  - src/index.ts
dependencies:
  - 所有前置任务
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/core && node -e "const m = require('./dist/index.js'); console.log(Object.keys(m).sort().join('\n'))"
    check:
      - 所有预期导出存在
      - 没有未定义导出
      - 构建成功
status: pending
```

### M023 — 端到端仿真测试
```yaml
name: 端到端仿真测试
description: |
  编写完整的端到端仿真测试，验证 Lot 可在设备间流转。
scope:
  do:
    - 创建测试用 FabLayoutConfig
    - 创建测试用 ProcessConfig
    - 初始化 SimulationEngine
    - 运行仿真直到所有 Lot 完成
    - 验证 Lot 状态流转正确
    - 验证设备状态变化正确
    - 验证事件序列正确
  dont:
    - 不测试 3D 渲染
    - 不测试 UI
files:
  - src/engine/simulation-end-to-end.test.ts  # 已有骨架，完善它
dependencies:
  - M022  # 所有模块导出完成
verification:
  - cmd: cd packages/core && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/core && npx vitest run src/engine/simulation-end-to-end.test.ts
    check:
      - 仿真成功运行
      - 所有 Lot 最终状态为 Completed
      - 设备状态正确变化
      - 无未处理异常
status: pending
```

---

## 任务依赖图

```
Phase 1 (物流实体):
  M001 (Buffer) ──→ M002 (Stocker) ──→ M003 (Transport)

Phase 2 (空间实体):
  M001 ──→ M004 (WorkArea) ──→ M005 (Fab)

Phase 3 (MES 实体):
  M000-E ──→ M006 (MESState) ──→ M007 (Fault)

Phase 4 (统计):
  M008 (OEE)  # 独立

Phase 5 (配置验证):
  M009 (Validation) ──→ M010 (FabLayoutConfig)
                    ──→ M011 (ProcessConfig)
                    ──→ M012 (SimulationConfig)

Phase 6 (调度策略):
  M013 (Strategy Interface)
    │
    ├──→ M014 (FIFO)
    ├──→ M015 (SPT)
    ├──→ M016 (CR)
    │
    └──→ M017 (StrategyRegistry)

Phase 7 (仿真引擎):
  M018 (SimulationContext)
    │
    └──→ M019 (EventHandlers) ──→ M020 (TransportHandlers)
                              ──→ M021 (FaultInjection)

Phase 8 (整合):
  M022 (Index Export) ──→ M023 (E2E Test)
```

---

## 当前状态汇总

| 阶段 | 任务数 | pending | active | passing | blocked |
|------|-------|---------|--------|---------|---------|
| Phase 0 现有代码 | 6 | 0 | 0 | 6 | 0 |
| Phase 1 物流实体 | 3 | 3 | 0 | 0 | 0 |
| Phase 2 空间实体 | 2 | 2 | 0 | 0 | 0 |
| Phase 3 MES 实体 | 2 | 2 | 0 | 0 | 0 |
| Phase 4 统计 | 1 | 1 | 0 | 0 | 0 |
| Phase 5 配置验证 | 4 | 4 | 0 | 0 | 0 |
| Phase 6 调度策略 | 5 | 5 | 0 | 0 | 0 |
| Phase 7 仿真引擎 | 4 | 4 | 0 | 0 | 0 |
| Phase 8 整合 | 2 | 2 | 0 | 0 | 0 |
| **总计** | **23** | **23** | **0** | **6** | **0** |

---

## 与其他 Agent 的协作影响

当以下任务完成时，需要通知对应 Agent：

| 任务 | 影响 | 通知对象 |
|------|------|---------|
| M001 (Buffer) | Buffer 类型可用 | @3d-expert |
| M002 (Stocker) | Stocker 类型可用 | @3d-expert |
| M003 (Transport) | TransportPath/Vehicle 类型可用 | @3d-expert |
| M004 (WorkArea) | WorkArea 类型可用 | @3d-expert |
| M005 (Fab) | FabLayoutConfig 可用 | @3d-expert |
| M010 (FabLayoutConfig) | 配置 Schema 可用 | @3d-expert |
| M011 (ProcessConfig) | Recipe/Route 配置可用 | @3d-expert |
| M019 (EventHandlers) | 仿真引擎完整可用 | @3d-expert |
| M008 (OEE) | OEEMetrics 类型可用 | @ui-expert |
| M006 (MESState) | WIPStatistics 类型可用 | @ui-expert |

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次任务状态变更时更新状态汇总表
