# 3D 半导体工厂场景专家 — 架构设计文档

> 版本：v1.1 | 日期：2026-06-07
> 适用范围：`packages/3d-engine` 包
> 目标：为 Semi-MES-Sim 提供 JSON 驱动的 3D 场景创建、Entity 动画编排、MES 抽象可视化与性能优化

---

## 1. 系统定位

### 1.1 角色定义
`@semi/3d-engine` 是 Semi-MES-Sim 项目的 **Babylon.js 场景封装层**。它：
- 接收来自 `@semi/core` 的领域模型数据
- 将其映射为 3D 可视化场景
- 驱动动画反馈和交互响应
- 对 `apps/web` 提供纯净的 3D API（无 Vue 依赖）

### 1.2 与其他包的关系

```
┌─────────────────────────────────────────────────────────┐
│                    apps/web (Vue + Pinia)                │
│              挂载 3D Canvas、UI 控制面板                  │
├─────────────────────────────────────────────────────────┤
│                    ↓ 调用                                │
│              @semi/3d-engine (本包)                      │
│         3D 场景、资产、动画、可视化                        │
├─────────────────────────────────────────────────────────┤
│                    ↑ 仅类型引用                          │
│              @semi/core (纯 TypeScript)                  │
│         Lot、Equipment、Recipe、仿真引擎                  │
└─────────────────────────────────────────────────────────┘
```

### 1.3 核心职责

| 职责 | 说明 |
|------|------|
| **场景层级构建** | Fab → WorkArea → EquipmentGroup → Equipment 的层级化 3D 场景 |
| **Buffer/Stocker 可视化** | 缓冲区/中央仓储的容量、排队状态、FIFO 队列的 3D 表达 |
| **传输系统可视化** | AMHS 天车轨道、AGV 路径、人工搬运路径的 3D 表达 |
| **JSON 配置驱动** | 通过 JSON 配置描述整个 3D 场景，支持热更新 |
| **物理设备资产** | 光刻机、刻蚀机等 3D 模型 |
| **抽象系统可视化** | MES 事件队列、WIP 看板、调度规则、OEE、故障注入、数据流 |
| **多层工艺循环可视化** | Layer 循环的 3D 表达（沉积→光刻→刻蚀循环 20-100+ 次） |
| **Entity-Animation 绑定** | 每个领域 Entity 对应一个 3D Entity，状态变化自动触发对应动画 |
| **性能保障** | 确保 20-50 台设备场景下 >30fps |

---

## 2. 场景层级模型

### 2.1 完整层级

```
Fab (晶圆厂)
├── WorkArea (工作区) — e.g. "光刻区 Lithography Bay"
│   ├── EquipmentGroup (设备组) — e.g. "Litho-Cluster-A"
│   │   └── Equipment (设备) — e.g. "Litho-01"
│   ├── BufferGroup (缓冲组)
│   │   ├── InputBank (输入缓冲) — 等待进入设备的 Lot 队列
│   │   ├── OutputBank (输出缓冲) — 加工完成等待搬运的 Lot
│   │   └── Stocker (中央仓储) — 大容量跨区缓冲
│   └── TransportPath (传输路径/AMHS 轨道)
├── MESVisualization (MES 系统可视化层)
│   ├── EventQueueVisualization (事件队列)
│   ├── WIPVisualization (在制品追踪)
│   ├── SchedulerVisualization (调度规则)
│   ├── OEEDashboard (设备综合效率)
│   ├── FaultInjectionVisualization (故障注入)
│   └── DataFlowVisualization (数据流粒子)
├── LayerCycleVisualization (多层工艺循环)
│   ├── LayerIndicator (当前 Layer 层级)
│   └── LoopProgress (循环进度)
└── Environment (环境)
    ├── Ground / Grid
    └── Lighting / Fog
```

### 2.2 领域概念映射

| 领域概念 | 3D 表达 | 业务来源 |
|---------|--------|---------|
| Equipment (设备) | 3D 几何体模型 + 状态灯 | 核心四大件：光刻、刻蚀、沉积、清洗 |
| Buffer (缓冲) | 半透明容器 + 容量指示条 | 产线三大件之一 |
| InputBank/OutputBank | 漏斗形入口/输出托盘 | SiView MES Bank 概念 |
| Stocker (中央仓储) | 多层货架 + 热力图 | 跨区大容量缓冲 |
| AMHS/AGV | 轨道 + 小车模型 | 真实 Fab 传输系统 |
| WorkArea | 半透明区域边界 + 标识 | Fab 分区管理 |
| MES EventQueue | 悬浮面板 + 条目堆叠 | MES 事件驱动架构 |
| WIP Board | 信息面板 + 状态指示 | WIP 追踪核心功能 |
| Scheduler | 规则对比面板 | FIFO/SPT/CR 调度规则 |
| OEE Dashboard | 环形图 + 实时数字 | 设备稼动率 KPI |
| Fault Injection | 故障面板 + 影响高亮 | 故障场景演练 |
| Layer Cycle | 螺旋/环形指示器 | 20-100+ 层工艺循环 |

---

## 3. 核心模块设计

### 3.1 模块关系图

```
SceneConfig (JSON)
  │
  ▼
SceneBuilder ──▶ SceneGraph
  │                │
  │    ┌───────────┼───────────┐
  │    ▼           ▼           ▼
  │ AssetFactory EntityManager AnimationOrchestrator
  │    │           │               │
  │    ▼           ▼               ▼
  │ equipment   syncEquipment  playSequence
  │ buffer      syncBuffer     animateLotTransfer
  │ transport   syncStocker    animateFaultInjected
  │ mes-viz     syncTransport  animateLayerTransition
  │    │           │
  │    └─────┬─────┘
  │          ▼
  │    VisualMES
  │    TransportSystem
  │    LayerCycleVisualization
  │
  ▼
PerformanceProfiler
```

### 3.2 模块清单

| 模块 | 文件路径 | 职责 | 依赖 |
|------|---------|------|------|
| SceneGraph | `scene-graph/scene-graph.ts` | 场景图层级管理 | — |
| SceneBuilder | `scene/scene-builder.ts` | JSON 配置解析与场景构建 | SceneGraph, AssetFactory |
| AssetFactory | `assets/asset-factory.ts` | 统一资产生成入口 | — |
| EntityManager | `entity/entity-manager.ts` | 领域-3D Entity 绑定与状态同步 | SceneGraph, AnimationOrchestrator |
| AnimationOrchestrator | `animation/animation-orchestrator.ts` | 高级动画编排 | AnimationSystem |
| TransportSystem | `transport/transport-system.ts` | 传输系统管理 | — |
| VisualMES | `visualization/` 目录 | MES 抽象系统可视化 | — |
| LayerCycleViz | `visualization/layer-cycle-viz.ts` | 多层工艺循环可视化 | — |
| PerformanceProfiler | `perf/performance-profiler.ts` | 性能监控与优化 | — |

---

## 4. 关键接口设计

### 4.1 SceneGraph

```typescript
interface SceneNode {
  id: string
  name: string
  type: SceneNodeType
  mesh: TransformNode
  parent?: SceneNode
  children: SceneNode[]
  metadata: Record<string, unknown>
}

type SceneNodeType = 
  | 'fab' | 'workArea' | 'equipmentGroup' | 'equipment'
  | 'buffer' | 'stocker' | 'inputBank' | 'outputBank'
  | 'transportPath' | 'transportVehicle'
  | 'mesSystem' | 'lot' | 'layerCycle'

class SceneGraph {
  readonly root: SceneNode
  addNode(node: SceneNode, parentId?: string): void
  removeNode(id: string): void
  findNode(id: string): SceneNode | undefined
  getNodesByType(type: SceneNodeType): SceneNode[]
  traverse(callback: (node: SceneNode) => void): void
}
```

### 4.2 AssetFactory

```typescript
interface AssetConfig {
  id: string
  type: string
  position: Vector3
  size?: { width: number; depth: number; height?: number }
  color?: Color3 | Color4
  label?: string
  metadata?: Record<string, unknown>
}

class AssetFactory {
  register(type: string, generator: AssetGenerator): void
  create(scene: Scene, config: AssetConfig): TransformNode
  
  // 设备资产
  createEquipment(scene, config): TransformNode
  
  // Buffer/Stocker 资产
  createBuffer(scene, config): TransformNode
  createStocker(scene, config): TransformNode
  createInputBank(scene, config): TransformNode
  createOutputBank(scene, config): TransformNode
  
  // 传输系统资产
  createTransportPath(scene, config): TransformNode
  createTransportVehicle(scene, config): TransformNode
  
  // MES 可视化资产
  createMESNode(scene, config): TransformNode
  createEventQueueViz(scene, config): TransformNode
  createWIPBoard(scene, config): TransformNode
  createSchedulerViz(scene, config): TransformNode
  createOEEDashboard(scene, config): TransformNode
  createFaultInjectionPanel(scene, config): TransformNode
  createDataFlowParticles(scene, config): TransformNode
  
  // 多层工艺循环资产
  createLayerIndicator(scene, config): TransformNode
}
```

### 4.3 EntityManager

```typescript
interface EntityBinding<T> {
  domainId: string
  domainType: string
  sceneNodeId: string
  mesh: TransformNode
  currentState: string
  activeAnimations: string[]
}

class EntityManager {
  bind<T>(domainEntity: T, sceneNode: SceneNode): EntityBinding<T>
  unbind(domainId: string): void
  getBinding(domainId: string): EntityBinding | undefined
  
  // 状态同步
  syncEquipmentState(equipment: Equipment): void
  syncBufferState(bufferId: string, lots: Lot[], capacity: number): void
  syncStockerState(stockerId: string, lots: Lot[], capacity: number): void
  syncTransportVehicleState(vehicleId: string, position: Position3D, carryingLotId?: string): void
  syncLayerCycleState(currentLayer: number, totalLayers: number): void
  syncMESState(mesState: MESVisualizationState): void
  syncSchedulerState(rule: string, queueSnapshot: QueueSnapshot[]): void
  
  // 批量更新
  syncBatch(updates: Array<{ type: string; entity: unknown }>): void
}
```

### 4.4 AnimationOrchestrator

```typescript
interface AnimationSequence {
  id: string
  steps: AnimationStep[]
  loop?: boolean
  speed?: number
  onComplete?: () => void
}

interface AnimationStep {
  targetId: string
  type: AnimationType
  to: Vector3 | Color3
  duration: number
  easing?: EasingType
  waitFor?: string
  delay?: number
}

class AnimationOrchestrator {
  playSequence(sequence: AnimationSequence): string
  stopSequence(sequenceId: string): void
  
  // Lot 流转
  animateLotTransfer(lotId: string, fromEqId: string, toEqId: string): Promise<void>
  animateLotToBuffer(lotId: string, equipmentId: string, bufferId: string): Promise<void>
  animateLotFromBuffer(lotId: string, bufferId: string, equipmentId: string): Promise<void>
  animateLotToStocker(lotId: string, fromPosition: Position3D, stockerId: string): Promise<void>
  
  // 设备状态
  animateEquipmentStatusChange(equipmentId: string, from: EquipmentStatus, to: EquipmentStatus): void
  animateEquipmentControlStateChange(equipmentId: string, from: ControlState, to: ControlState): void
  
  // Buffer
  animateBufferFillChange(bufferId: string, oldCount: number, newCount: number, capacity: number): void
  
  // 传输
  animateVehicleMove(vehicleId: string, pathId: string, fromPoint: number, toPoint: number): void
  
  // MES 事件
  animateMESEvent(event: SimulationEvent): void
  animateDataFlow(fromNodeId: string, toNodeId: string, dataType: DataFlowType): void
  
  // 故障
  animateFaultInjected(equipmentId: string, faultType: FaultType): void
  animateFaultCleared(equipmentId: string): void
  
  // 多层循环
  animateLayerTransition(fromLayer: number, toLayer: number): void
  
  // 调度
  animateSchedulerDecision(equipmentId: string, selectedLotId: string, rule: string, candidates: string[]): void
  
  // 全局控制
  pauseAll(): void
  resumeAll(): void
  setGlobalSpeed(speed: number): void
  seekTo(timeMs: number): void
}
```

### 4.5 TransportSystem

> **类型来源**: `TransportVehicle`、`TransportPath`、`VehicleStatus` 由 `@semi/core` 定义。
> 3D 专家只导入这些类型。

```typescript
import type {
  TransportPath,
  TransportVehicle,
  VehicleStatus
} from '@semi/core'

class TransportSystem {
  addPath(path: TransportPath): void
  removePath(id: string): void
  addVehicle(pathId: string, vehicle: TransportVehicle): string
  removeVehicle(id: string): void
  moveVehicle(vehicleId: string, toPathPosition: number): Promise<void>
  loadLot(vehicleId: string, lotId: string): void
  unloadLot(vehicleId: string, lotId: string): void
}
```

---

## 5. JSON 配置格式

> **⚠️ 架构边界声明**
>
> 以下所有**业务配置类型**（FabLayoutConfig、EquipmentConfig、BufferConfig 等）
> **必须由 `@mes-expert` 在 `packages/core` 中定义**。
>
> `@3d-expert` **禁止**在 `packages/3d-engine` 中定义这些类型。
> 3D 专家只能：
> 1. **导入** `@semi/core` 导出的配置类型
> 2. 定义 **3D 场景特有的覆盖配置**（camera、light、fog、grid 等）
> 3. 定义 **视觉覆盖配置**（颜色映射、透明度等）
>
> 这是为了保证业务数据结构的单一来源，避免类型不一致。

### 5.1 配置来源关系

```
业务配置（@semi/core 定义）          3D 覆盖配置（@3d-expert 定义）
├─ FabLayoutConfig                    ├─ Scene3DConfig
│  ├─ FabConfig                       │  ├─ backgroundColor
│  ├─ WorkAreaConfig                  │  ├─ fog
│  │  ├─ EquipmentConfig              │  ├─ lighting
│  │  ├─ BufferConfig                 │  ├─ grid
│  │  ├─ TransportPathConfig          │  └─ camera
│  ├─ StockerConfig                   │
│  └─ MESSystemConfig                 └─ VisualOverride
│                                      ├─ equipmentColors
├─ ProcessConfig                       ├─ statusColors
│  ├─ RecipeConfig                     └─ workAreaOpacity
│  └─ ProcessRouteConfig
│
└─ SimulationRuntimeConfig
   ├─ InitialLotConfig
   └─ FaultInjectionConfig
```

### 5.2 3D 场景配置类型

```typescript
// ===== 从 @semi/core 导入的业务配置 =====
// 这些类型由 @mes-expert 定义和维护
import type {
  FabLayoutConfig,
  FabConfig,
  WorkAreaConfig,
  EquipmentConfig,
  BufferConfig,
  StockerConfig,
  TransportPathConfig,
  MESSystemConfig,
  ProcessConfig,
  RecipeConfig,
  ProcessRouteConfig,
  SimulationRuntimeConfig,
  LayerCycleConfig,
  // 领域模型类型
  EquipmentType,
  EquipmentStatus,
  LotStatus,
  BufferType,
  TransportType,
  VehicleStatus,
  ControlState,
  ProcessState,
  FaultCategory,
  FaultSeverity,
  // 统计类型
  OEEMetrics,
  WIPStatistics,
  // 仿真类型
  SimulationState,
  SimulationEvent,
  EventType,
  DispatchDecision
} from '@semi/core'

// ===== 3D 专家定义的 3D 场景覆盖配置 =====
// 这些配置只影响渲染，不影响业务逻辑

interface Scene3DConfig {
  /** 背景色（hex 或 rgba） */
  backgroundColor?: string
  /** 雾效配置 */
  fog?: {
    enabled: boolean
    density: number
    color: string
  }
  /** 灯光配置 */
  lighting?: {
    ambientIntensity: number
    directionalIntensity: number
    shadows: boolean
    shadowMapSize: number
  }
  /** 地面网格配置 */
  grid?: {
    enabled: boolean
    size: number
    divisions: number
    color: string
  }
  /** 初始相机位置（可选覆盖业务配置中的位置） */
  camera?: {
    alpha: number
    beta: number
    radius: number
    target: { x: number; y: number; z: number }
  }
}

/** 视觉覆盖配置：允许在运行时动态调整视觉表现 */
interface VisualOverride {
  /** 设备类型默认颜色映射 */
  equipmentColors?: Partial<Record<EquipmentType, string>>
  /** 设备状态颜色映射 */
  statusColors?: Partial<Record<EquipmentStatus, string>>
  /** 区域边界透明度（0-1） */
  workAreaOpacity?: number
  /** Buffer 容量条颜色映射 */
  bufferFillColors?: {
    empty: string
    half: string
    full: string
  }
}

// ===== 3D 专家定义的完整场景配置 =====
// 由业务配置 + 3D 覆盖配置组合而成

interface SceneConfig {
  /** 业务配置：工厂布局（必须，由 @semi/core 定义） */
  layout: FabLayoutConfig
  /** 业务配置：工艺配方（可选） */
  process?: ProcessConfig
  /** 业务配置：仿真运行时参数（可选） */
  simulation?: SimulationRuntimeConfig
  /** 3D 特有：场景渲染配置（可选，默认提供） */
  scene3d?: Scene3DConfig
  /** 3D 特有：视觉覆盖配置（可选） */
  visual?: VisualOverride
}

// ===== 3D 专家内部使用的辅助类型 =====
// 这些类型只在 3d-engine 内部使用，不对外导出

interface AssetConfig {
  id: string
  type: string
  position: Vector3
  size?: { width: number; depth: number; height?: number }
  color?: Color3 | Color4
  label?: string
  metadata?: Record<string, unknown>
}

interface SceneNode {
  id: string
  name: string
  type: 'fab' | 'workArea' | 'equipmentGroup' | 'equipment' 
       | 'buffer' | 'stocker' | 'inputBank' | 'outputBank'
       | 'transportPath' | 'transportVehicle'
       | 'mesSystem' | 'lot' | 'layerCycle'
  mesh: TransformNode
  parent?: SceneNode
  children: SceneNode[]
  metadata: Record<string, unknown>
}
```

---

## 6. 动画设计规范

### 6.1 状态颜色映射

| 状态 | 颜色 | 说明 |
|------|------|------|
| Idle / Online | 🟢 绿色 `#4CAF50` | 空闲/在线 |
| Processing | 🟡 黄色 `#FFC107` | 加工中 |
| Loading / Unloading | 🟠 橙色 `#FF9800` | 加载/卸载 |
| Error / Alarm | 🔴 红色 `#F44336` | 故障/报警 |
| Maintenance | ⚪ 灰色 `#9E9E9E` | 维护中 |
| Offline | ⚫ 深灰 `#424242` | 离线 |
| Local Mode | 🔵 蓝色 `#2196F3` | 本地模式 |

### 6.2 动画时长规范

| 动画类型 | 建议时长 | 缓动函数 |
|---------|---------|---------|
| 颜色过渡 | 200-300ms | EaseInOut |
| 位置移动（短距离） | 300-500ms | EaseInOut |
| 位置移动（长距离/传输） | 800-1500ms | Linear |
| 缩放（淡入/淡出） | 200-400ms | ElasticOut / BackOut |
| 状态灯闪烁 | 100ms × 3次 | Linear |
| 故障脉冲 | 500ms 循环 | Sine wave |

### 6.3 粒子效果规范

| 效果 | 粒子颜色 | 粒子数量 | 生命周期 |
|------|---------|---------|---------|
| Recipe 下发 | 蓝色 | 30 | 1s |
| Status 上报 | 绿色 | 20 | 0.8s |
| Alarm | 红色 | 50 | 2s |
| Command | 紫色 | 30 | 1s |
| 故障烟雾 | 灰色 | 100 | 3s |
| Layer 完成 | 金色 | 80 | 2s |

---

## 7. 性能设计

### 7.1 性能预算

| 指标 | 目标值 | 说明 |
|------|-------|------|
| FPS | >30 | 20-50 台设备场景 |
| Draw Calls | <200 | 合并和实例化后 |
| Mesh Count | <500 | 含环境元素 |
| Active Animations | <50 | 同时播放 |
| Texture Memory | <50MB | 动态纹理为主 |

### 7.2 优化策略

| 技术 | 应用对象 | 效果 |
|------|---------|------|
| ThinInstance | 同类型设备 | 减少 N 倍 Draw Call |
| LOD | 所有设备 | 远距离简化 |
| MergeMeshes | 静态环境 | 减少 Mesh 数量 |
| 冻结世界矩阵 | 静态对象 | 跳过变换计算 |
| Buffer 聚合 | Buffer 中 Lot | 数量多时显示计数 |
| 粒子池 | 数据流粒子 | 复用避免创建销毁 |
| 视锥剔除 | 所有动态对象 | 不在视野内暂停更新 |

---

## 8. 文件结构规划

```
packages/3d-engine/src/
├── scene/
│   ├── scene-manager.ts          # 已有（保留）
│   └── scene-builder.ts          # 新增：JSON 配置解析器
├── scene-graph/
│   └── scene-graph.ts            # 新增：场景图管理
├── assets/
│   ├── asset-factory.ts          # 新增：统一资产生成入口
│   ├── equipment-models.ts       # 已有（保留）
│   ├── work-area-models.ts       # 新增：工作区资产
│   ├── buffer-models.ts          # 新增：Buffer/Stocker 资产
│   ├── transport-models.ts       # 新增：传输系统资产
│   └── mes-visual-models.ts      # 新增：MES 可视化资产
├── entity/
│   └── entity-manager.ts         # 新增：Entity 绑定管理
├── animation/
│   ├── animation-system.ts       # 已有（保留）
│   └── animation-orchestrator.ts # 新增：动画编排器
├── visualization/
│   ├── index.ts
│   ├── event-queue-viz.ts        # 事件队列可视化
│   ├── wip-viz.ts                # WIP 看板
│   ├── scheduler-viz.ts          # 调度规则可视化
│   ├── oee-dashboard.ts          # OEE 统计看板
│   ├── fault-injection-viz.ts    # 故障注入面板
│   ├── layer-cycle-viz.ts        # 多层工艺循环
│   └── data-flow-viz.ts          # 数据流粒子
├── transport/
│   └── transport-system.ts       # 新增：传输系统管理
├── perf/
│   └── performance-profiler.ts   # 新增：性能分析器
# ❌ 3D 专家不创建 config/ 目录
# 业务配置类型（FabLayoutConfig 等）由 @semi/core 定义并导出
# 3D 专家通过 import type { ... } from '@semi/core' 消费
└── index.ts                      # 更新：导出所有公共 API
```

---

## 9. 对外 API（最终导出）

```typescript
// 场景管理
export { SceneManager } from './scene/scene-manager'
export { SceneBuilder, type SceneConfig } from './scene/scene-builder'
export { SceneGraph, type SceneNode, type SceneNodeType } from './scene-graph/scene-graph'

// 资产
export { AssetFactory, type AssetConfig, type AssetGenerator } from './assets/asset-factory'
export { createEquipmentModel, updateEquipmentStatus } from './assets/equipment-models'

// Entity
export { EntityManager, type EntityBinding } from './entity/entity-manager'

// 动画
export { AnimationSystem, AnimationType, EasingType } from './animation/animation-system'
export { AnimationOrchestrator, type AnimationSequence, type AnimationStep } from './animation/animation-orchestrator'

// 传输
export { TransportSystem, type TransportVehicle, type TransportPath } from './transport/transport-system'

// 可视化
export { EventQueueVisualization } from './visualization/event-queue-viz'
export { WIPVisualization } from './visualization/wip-viz'
export { SchedulerVisualization } from './visualization/scheduler-viz'
export { OEEDashboard, type OEEMetrics } from './visualization/oee-dashboard'
export { FaultInjectionVisualization, type FaultDefinition } from './visualization/fault-injection-viz'
export { LayerCycleVisualization } from './visualization/layer-cycle-viz'
export { DataFlowVisualization, type DataFlowType } from './visualization/data-flow-viz'

// 性能
export { PerformanceProfiler, type PerformanceMetrics, type PerformanceBudget } from './perf/performance-profiler'

// 配置
export type {
  SceneConfig,
  FabConfig,
  WorkAreaConfig,
  EquipmentConfig,
  BufferConfig,
  StockerConfig,
  TransportPathConfig,
  LayerCycleConfig,
  MESSystemConfig
} from './config/scene-config'
```

---

## 10. 业务要素对照表

| 业务要素 | 来源文档 | 3D 表达 | 优先级 |
|---------|---------|--------|-------|
| 设备（7种类型） | `fabsim_equipment_types.md` | MeshBuilder 几何体 | P0 |
| Buffer 缓冲 | `fabsim_layout_guide.md` | 半透明容器 + 容量条 | P0 |
| Stocker 中央仓储 | `fabsim_pro_design_v1.0.md` | 多层货架 + 热力图 | P1 |
| InputBank/OutputBank | `siview-interface-design.md` | 漏斗/托盘造型 | P1 |
| AMHS 天车 | `fabsim_layout_guide.md` | 轨道 + 小车 | P1 |
| AGV 小车 | `fabsim_layout_guide.md` | 路径 + 车辆 | P2 |
| WorkArea 分区 | `fabsim_pro_design_v1.0.md` | 区域边界 + 标识 | P0 |
| MES EventQueue | `mes_function_guide.md` | 悬浮面板 + 条目 | P1 |
| WIP 追踪 | `mes_function_guide.md` | 信息面板 + 指示器 | P1 |
| 调度规则 (FIFO/SPT/CR) | `fabsim_pro_design_v1.0.md` | 规则对比面板 | P2 |
| OEE 统计 | `mes_function_guide.md` | 环形图 + 数字 | P2 |
| 故障注入 | `fabsim_pro_design_v1.0.md` | 故障面板 + 高亮 | P2 |
| 数据流粒子 | `fabsim_siview_design_v0.2.md` | 粒子系统 | P2 |
| 多层工艺循环 | `fabsim_process_explained.md` | 螺旋/环形指示器 | P2 |
| GEM 状态机 | `fabsim_siview_design_v0.2.md` | 三层状态可视化 | P2 |
| Setup Time | `fabsim_process_explained.md` | 换型进度指示 | P3 |
| Batching 批次组合 | `mes_function_guide.md` | Batch 容器可视化 | P3 |

---

**文档版本**: 1.1
**创建日期**: 2026-06-07
**更新规则**: 每次重大架构变更时更新
