# 半导体 MES 领域专家 — 领域架构设计文档

> 版本：v1.0 | 日期：2026-06-07
> 适用范围：`packages/core` 包
> 定位：整个 Semi-MES-Sim 项目的**领域层权威**

---

## 1. 系统定位

### 1.1 核心职责

`@semi/core` 是 Semi-MES-Sim 的**纯 TypeScript 领域层**。它是整个系统的"大脑"：

- 定义所有半导体 MES 业务概念的数据结构
- 管理仿真状态的生命周期和转换规则
- 驱动离散事件仿真（DES）的时间推进
- 提供调度策略接口和实现
- 定义所有 JSON 配置的数据 Schema 和验证规则

### 1.2 包间关系

```
┌─────────────────────────────────────────────────────────────────┐
│                        @semi/core (领域层)                       │
│                                                                  │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│   │   models/     │    │   engine/     │    │   config/     │    │
│   │  领域模型     │    │  仿真引擎     │    │  配置验证     │    │
│   │  Lot/Equipment│    │  EventQueue   │    │  Schema       │    │
│   │  /Recipe/...  │    │  Simulation   │    │  Validation   │    │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    │
│          │                   │                   │             │
│   ┌──────┴───────────────────┴───────────────────┴──────┐     │
│   │                    scheduling/                       │     │
│   │                 调度策略接口与实现                    │     │
│   └────────────────────────┬─────────────────────────────┘     │
│                            │                                     │
│                            ▼                                     │
│              导出：类型 + 引擎接口 + 配置验证                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
   @semi/3d-engine    @semi/ui           apps/web
   (导入类型+配置)    (导入类型)         (导入类型+引擎)
```

### 1.3 所有权声明

| 内容 | 所有者 | 其他包的权利 |
|------|--------|-----------|
| 领域模型（Lot/Equipment/Recipe 等） | `@mes-expert` | **只读导入**，不可重新定义 |
| 状态枚举（EquipmentStatus 等） | `@mes-expert` | **只读导入**，不可扩展 |
| 状态转换规则 | `@mes-expert` | **调用规则函数**，不可修改 |
| JSON 配置 Schema | `@mes-expert` | **消费验证后的配置**，不可定义新 Schema |
| 仿真引擎（EventQueue/SimulationEngine） | `@mes-expert` | **使用引擎实例**，不可修改引擎 |
| 调度策略接口 | `@mes-expert` | **实现策略**（如需要自定义） |
| 配置验证函数 | `@mes-expert` | **调用验证函数**，不可绕过 |

---

## 2. 领域模型全景

### 2.1 模型分类

```
MES 领域模型
│
├── 生产实体（直接参与生产流程）
│   ├── Lot（晶圆批次）
│   ├── Equipment（生产设备）
│   ├── Recipe（工艺配方）
│   └── ProcessRoute（工艺路线）
│
├── 物流实体（Lot 流转的支撑）
│   ├── Buffer（缓冲）
│   ├── InputBank（输入缓冲）
│   ├── OutputBank（输出缓冲）
│   ├── Stocker（中央仓储）
│   ├── TransportPath（传输路径）
│   └── TransportVehicle（传输车辆）
│
├── 空间实体（工厂空间组织）
│   ├── Fab（晶圆厂）
│   ├── WorkArea（工作区/工艺区）
│   └── EquipmentGroup（设备组）
│
├── MES 系统实体
│   ├── MESState（MES 系统状态）
│   ├── EventDefinition（事件定义）
│   ├── SchedulingRule（调度规则）
│   └── FaultDefinition（故障定义）
│
└── 统计实体
    ├── OEEMetrics（设备综合效率）
    └── WIPStatistics（WIP 统计）
```

### 2.2 模型关系图

```
Fab (1)
  │
  ├───> WorkArea (N)
  │       │
  │       ├───> EquipmentGroup (N)
  │       │       └───> Equipment (N)
  │       │
  │       ├───> Buffer (N)
  │       │       ├───> InputBank (N) ──关联──> Equipment
  │       │       └───> OutputBank (N) ──关联──> Equipment
  │       │
  │       └───> TransportPath (N)
  │               └───> TransportVehicle (N)
  │
  ├───> Stocker (N) ──服务──> WorkArea (N)
  │
  └───> MESState (1)
          │
          ├───> EventDefinition (N)
          ├───> SchedulingRule (N)
          └───> FaultDefinition (N)

ProcessRoute (1)
  │
  └───> ProcessStep (N) ──引用──> Recipe (1)

Lot (N)
  │
  ├───> 当前步骤：ProcessStep
  ├───> 当前设备：Equipment（可选）
  ├───> 当前缓冲：Buffer（可选）
  └───> 工艺路线：ProcessRoute
```

---

## 3. 领域模型详细设计

### 3.1 生产实体

#### Lot（晶圆批次）

```typescript
export interface Lot {
  /** 批次唯一标识 */
  id: string
  /** 批次名称/编号 */
  name: string
  /** 晶圆数量（通常 25 片/批） */
  waferCount: number
  /** 当前工艺步骤索引 */
  currentStepIndex: number
  /** 工艺路线 ID */
  routeId: string
  /** 当前所在设备 ID（如果在设备上） */
  currentEquipmentId?: string
  /** 当前所在缓冲 ID（如果在缓冲中） */
  currentBufferId?: string
  /** 批次优先级（数字越小优先级越高） */
  priority: number
  /** 批次状态 */
  status: LotStatus
  /** 创建时间戳（仿真时间） */
  createdAt: number
  /** 进入当前步骤的时间 */
  enteredStepAt?: number
  /** 预计完成时间 */
  dueTime?: number
  /** 当前 Layer（多层工艺） */
  currentLayer?: number
  /** 总 Layer 数 */
  totalLayers?: number
}

export enum LotStatus {
  Waiting = 'waiting',
  Processing = 'processing',
  Completed = 'completed',
  OnHold = 'on_hold'
}

// 状态转换规则
export const LOT_STATUS_TRANSITIONS: Record<LotStatus, LotStatus[]> = {
  [LotStatus.Waiting]: [LotStatus.Processing, LotStatus.OnHold],
  [LotStatus.Processing]: [LotStatus.Completed, LotStatus.OnHold],
  [LotStatus.OnHold]: [LotStatus.Waiting],
  [LotStatus.Completed]: []
}

export function canLotTransition(from: LotStatus, to: LotStatus): boolean {
  return LOT_STATUS_TRANSITIONS[from]?.includes(to) ?? false
}
```

#### Equipment（生产设备）

```typescript
export interface Equipment {
  /** 设备唯一标识 */
  id: string
  /** 设备名称 */
  name: string
  /** 设备类型 */
  type: EquipmentType
  /** 设备状态 */
  status: EquipmentStatus
  /** 当前加工的 Lot ID */
  currentLotId?: string
  /** 当前使用的 Recipe ID */
  currentRecipeId?: string
  /** 支持的工艺配方 IDs */
  supportedRecipeIds: string[]
  /** 3D 场景中的位置（业务坐标，供下游使用） */
  position: Position3D
  /** 加工能力（单位：晶圆/小时） */
  throughput: number
  /** 平均故障间隔 MTBF（秒） */
  mtbf?: number
  /** 平均修复时间 MTTR（秒） */
  mttr?: number
  /** 当前控制状态（GEM） */
  controlState?: ControlState
  /** 当前加工状态（GEM） */
  processState?: ProcessState
  /** 关联的输入缓冲 ID */
  inputBankId?: string
  /** 关联的输出缓冲 ID */
  outputBankId?: string
}

export enum EquipmentType {
  Lithography = 'lithography',
  Etching = 'etching',
  Deposition = 'deposition',
  Implantation = 'implantation',
  Cleaning = 'cleaning',
  Inspection = 'inspection',
  Annealing = 'annealing',
  CMP = 'cmp'
}

export enum EquipmentStatus {
  Idle = 'idle',
  Loading = 'loading',
  Processing = 'processing',
  Unloading = 'unloading',
  Error = 'error',
  Maintenance = 'maintenance'
}

// GEM 控制状态
export enum ControlState {
  Offline = 'offline',
  OnlineLocal = 'online_local',
  OnlineRemote = 'online_remote'
}

// GEM 加工状态
export enum ProcessState {
  Idle = 'idle',
  Setup = 'setup',
  Processing = 'processing',
  Paused = 'paused'
}

export interface Position3D {
  x: number
  y: number
  z: number
}
```

#### Recipe（工艺配方）

```typescript
export interface Recipe {
  /** 配方唯一标识 */
  id: string
  /** 配方名称 */
  name: string
  /** 适用设备类型 */
  equipmentType: EquipmentType
  /** 加工时间（秒） */
  processTime: number
  /** 加工时间变异系数（如 0.05 表示 ±5%） */
  timeVariance?: number
  /** 工艺参数 */
  parameters: RecipeParameter[]
  /** 所需 Setup 时间（换型时间，秒） */
  setupTime?: number
}

export interface RecipeParameter {
  /** 参数名 */
  name: string
  /** 参数值 */
  value: number
  /** 单位 */
  unit: string
  /** 最小值 */
  min?: number
  /** 最大值 */
  max?: number
}
```

#### ProcessStep / ProcessRoute（工艺步骤/路线）

```typescript
export interface ProcessStep {
  /** 步骤唯一标识 */
  id: string
  /** 步骤序号（在路线中的顺序） */
  sequence: number
  /** 步骤名称 */
  name: string
  /** 所需设备类型 */
  requiredEquipmentType: EquipmentType
  /** 使用的配方 ID */
  recipeId: string
  /** 步骤描述 */
  description?: string
  /** 是否为检测步骤 */
  isInspection?: boolean
}

export interface ProcessRoute {
  /** 路线唯一标识 */
  id: string
  /** 路线名称 */
  name: string
  /** 产品类型 */
  productType?: string
  /** 步骤列表（已排序） */
  steps: ProcessStep[]
  /** 是否为循环工艺（多层） */
  isCyclic?: boolean
  /** 循环次数（Layer 数） */
  cycleCount?: number
}
```

### 3.2 物流实体

#### Buffer（缓冲）

```typescript
export interface Buffer {
  /** 缓冲唯一标识 */
  id: string
  /** 缓冲名称 */
  name: string
  /** 缓冲类型 */
  type: BufferType
  /** 最大容量（Lot 数量） */
  capacity: number
  /** 当前排队 Lot IDs */
  queuedLotIds: string[]
  /** 关联设备 ID（如有） */
  associatedEquipmentId?: string
  /** 所属工作区 ID */
  workAreaId?: string
  /** 位置（业务坐标） */
  position: Position3D
}

export enum BufferType {
  Input = 'input',
  Output = 'output',
  Intermediate = 'intermediate',
  Stocker = 'stocker'
}
```

#### Stocker（中央仓储）

```typescript
export interface Stocker {
  /** 仓储唯一标识 */
  id: string
  /** 仓储名称 */
  name: string
  /** 最大容量（Lot 数量） */
  capacity: number
  /** 货架层数 */
  levels: number
  /** 每层当前存放的 Lot IDs */
  levelLotIds: string[][]
  /** 服务的 WorkArea IDs */
  servesWorkAreaIds: string[]
  /** 位置（业务坐标） */
  position: Position3D
}
```

#### TransportPath（传输路径）

```typescript
export interface TransportPath {
  /** 路径唯一标识 */
  id: string
  /** 路径类型 */
  type: TransportType
  /** 路径点序列（业务坐标） */
  points: Position3D[]
  /** 传输速度（米/秒） */
  speed: number
  /** 路径上的车辆 IDs */
  vehicleIds: string[]
  /** 所属工作区 ID */
  workAreaId?: string
}

export enum TransportType {
  AMHS = 'amhs',       // 天车系统
  AGV = 'agv',         // 自动导引车
  Manual = 'manual',   // 人工搬运
  Conveyor = 'conveyor' // 传送带
}
```

#### TransportVehicle（传输车辆）

```typescript
export interface TransportVehicle {
  /** 车辆唯一标识 */
  id: string
  /** 车辆类型 */
  type: TransportType
  /** 当前所在路径 ID */
  currentPathId?: string
  /** 路径上的位置进度（0.0 ~ 1.0） */
  pathPosition: number
  /** 当前携带的 Lot ID */
  carryingLotId?: string
  /** 车辆状态 */
  status: VehicleStatus
}

export enum VehicleStatus {
  Idle = 'idle',
  Moving = 'moving',
  Loading = 'loading',
  Unloading = 'unloading'
}
```

### 3.3 空间实体

```typescript
export interface Fab {
  /** 工厂唯一标识 */
  id: string
  /** 工厂名称 */
  name: string
  /** 工厂尺寸（米） */
  size: { width: number; depth: number }
  /** 工作区 IDs */
  workAreaIds: string[]
  /** 中央仓储 IDs */
  stockerIds: string[]
}

export interface WorkArea {
  /** 工作区唯一标识 */
  id: string
  /** 工作区名称 */
  name: string
  /** 工艺类型标识 */
  type: string
  /** 位置（业务坐标，左下角） */
  position: Position3D
  /** 尺寸（米） */
  size: { width: number; depth: number }
  /** 设备组 IDs */
  equipmentGroupIds: string[]
  /** 缓冲 IDs */
  bufferIds: string[]
  /** 传输路径 IDs */
  transportPathIds: string[]
}

export interface EquipmentGroup {
  /** 设备组唯一标识 */
  id: string
  /** 布局类型 */
  layout: GroupLayout
  /** 设备 IDs */
  equipmentIds: string[]
  /** 所属工作区 ID */
  workAreaId: string
}

export enum GroupLayout {
  Linear = 'linear',
  Grid = 'grid',
  Cluster = 'cluster'
}
```

### 3.4 MES 系统实体

```typescript
export interface MESState {
  /** 系统 ID */
  id: string
  /** 系统类型 */
  type: 'central' | 'distributed'
  /** 当前激活的调度规则 */
  activeSchedulingRule: string
  /** 当前事件队列 */
  eventQueue: SimulationEvent[]
  /** 当前 WIP 统计 */
  wipStats: WIPStatistics
}

export interface WIPStatistics {
  /** 总 WIP 数量 */
  total: number
  /** 等待中数量 */
  waiting: number
  /** 加工中数量 */
  processing: number
  /** 已完成数量 */
  completed: number
  /** 各区域 WIP 分布 */
  byWorkArea: Record<string, number>
}

export interface EventDefinition {
  /** 事件类型 ID */
  ceid: number
  /** 事件名称 */
  name: string
  /** 触发时机描述 */
  description: string
  /** 是否启用 */
  enabled: boolean
}

export interface FaultDefinition {
  /** 故障唯一标识 */
  id: string
  /** 故障名称 */
  name: string
  /** 故障描述 */
  description: string
  /** 故障分类 */
  category: FaultCategory
  /** 严重级别 */
  severity: FaultSeverity
  /** 影响的设备类型 */
  affectedEquipmentTypes?: EquipmentType[]
  /** 平均修复时间（秒） */
  mttr: number
}

export enum FaultCategory {
  Communication = 'communication',
  Equipment = 'equipment',
  Process = 'process',
  MES = 'mes'
}

export enum FaultSeverity {
  Warning = 'warning',
  Error = 'error',
  Fatal = 'fatal'
}
```

### 3.5 统计实体

```typescript
export interface OEEMetrics {
  /** 设备 ID */
  equipmentId: string
  /** 可用率 */
  availability: number
  /** 性能率 */
  performance: number
  /** 良品率 */
  quality: number
  /** OEE = 可用率 × 性能率 × 良品率 */
  oee: number
  /** 统计时间范围 */
  period: { start: number; end: number }
}

export interface EquipmentTimeLog {
  equipmentId: string
  periods: TimePeriod[]
}

export interface TimePeriod {
  start: number
  end: number
  type: 'running' | 'idle' | 'breakdown' | 'maintenance' | 'setup'
}
```

---

## 4. 仿真引擎架构

### 4.1 事件系统

```typescript
// 仿真事件（运行时）
export interface SimulationEvent {
  /** 事件触发时间（仿真时间，秒） */
  time: number
  /** 事件类型 */
  type: EventType
  /** 关联实体 ID */
  entityId: string
  /** 事件附加数据 */
  data?: Record<string, unknown>
}

export enum EventType {
  // Lot 生命周期
  LotArrival = 'lot_arrival',
  LotMoveToBuffer = 'lot_move_to_buffer',
  LotMoveToEquipment = 'lot_move_to_equipment',
  LotMoveToStocker = 'lot_move_to_stocker',
  
  // 设备生命周期
  EquipmentReady = 'equipment_ready',
  EquipmentSetup = 'equipment_setup',
  EquipmentStartProcessing = 'equipment_start_processing',
  EquipmentProcessComplete = 'equipment_process_complete',
  EquipmentBreakdown = 'equipment_breakdown',
  EquipmentRepair = 'equipment_repair',
  
  // 调度
  SchedulerDispatch = 'scheduler_dispatch',
  
  // 传输
  VehicleArrive = 'vehicle_arrive',
  VehicleLoadComplete = 'vehicle_load_complete',
  VehicleUnloadComplete = 'vehicle_unload_complete'
}

// 事件处理器注册表
export class EventHandlerRegistry {
  private handlers = new Map<EventType, EventHandler>()
  register(type: EventType, handler: EventHandler): void
  get(type: EventType): EventHandler | undefined
}

export type EventHandler = (
  event: SimulationEvent,
  state: SimulationState,
  context: SimulationContext
) => SimulationEvent[]

// 仿真上下文
export interface SimulationContext {
  getEquipment(id: string): Equipment | undefined
  getLot(id: string): Lot | undefined
  getBuffer(id: string): Buffer | undefined
  getStocker(id: string): Stocker | undefined
  getRecipe(id: string): Recipe | undefined
  getRoute(id: string): ProcessRoute | undefined
  scheduleEvent(event: SimulationEvent): void
}
```

### 4.2 仿真引擎

```typescript
export interface SimulationState {
  currentTime: number
  isRunning: boolean
  speed: number
  lots: Lot[]
  equipments: Equipment[]
  buffers: Buffer[]
  stockers: Stocker[]
  routes: ProcessRoute[]
  vehicles: TransportVehicle[]
  mesState: MESState
}

export interface SimulationConfig {
  initialLots: Lot[]
  equipments: Equipment[]
  buffers: Buffer[]
  stockers: Stocker[]
  routes: ProcessRoute[]
  vehicles: TransportVehicle[]
  schedulingStrategy: SchedulingStrategy
  initialSpeed?: number
  faultInjection?: FaultInjectionConfig
}

export interface SimulationCallbacks {
  onEvent?: (event: SimulationEvent, state: SimulationState) => void
  onTick?: (state: SimulationState) => void
  onStateChange?: (state: SimulationState) => void
}

export class SimulationEngine {
  constructor(config: SimulationConfig, callbacks?: SimulationCallbacks)
  
  getState(): Readonly<SimulationState>
  start(): void
  pause(): void
  reset(): void
  setSpeed(speed: number): void
  tick(realDeltaTime: number): boolean
  
  // 故障注入
  injectFault(equipmentId: string, faultId: string): void
  resolveFault(equipmentId: string): void
  
  // 手动控制
  dispatchLot(lotId: string, equipmentId: string): boolean
  moveLotToBuffer(lotId: string, bufferId: string): boolean
}
```

---

## 5. 调度策略架构

### 5.1 策略接口

```typescript
export interface SchedulingStrategy {
  readonly name: string
  readonly description: string
  scoreLot(lot: Lot, context: DispatchContext): number
  selectEquipment(lot: Lot, equipments: Equipment[], context: DispatchContext): Equipment
  dispatch(context: DispatchContext): DispatchDecision | null
}

export interface DispatchContext {
  waitingLots: Lot[]
  availableEquipments: Equipment[]
  currentTime: number
  routes: ProcessRoute[]
  wipStats: WIPStatistics
}

export interface DispatchDecision {
  lotId: string
  equipmentId: string
  rule: string
  reason: string
  candidates: Array<{ lotId: string; score: number }>
}
```

### 5.2 内置策略

| 策略 | 名称 | 算法 | 适用场景 |
|------|------|------|---------|
| FIFO | 先进先出 | 等待时间最长的优先 | 默认公平调度 |
| SPT | 最短加工时间 | 加工时间最短的优先 | 减少 WIP |
| CR | 关键比率 | (剩余时间/剩余工序)最小的优先 | 紧急订单 |
| EDD | 最早交期 | 交期最早的优先 | 满足交付 |
| HotLot | 热批优先 | priority 值最小的优先 | 特殊批次 |

---

## 6. JSON 配置 Schema

### 6.1 配置体系

```
配置体系
│
├── 工厂布局配置（FabLayoutConfig）
│   ├── FabConfig
│   ├── WorkAreaConfig[]
│   │   ├── EquipmentGroupConfig[]
│   │   │   └── EquipmentConfig[]
│   │   ├── BufferConfig[]
│   │   └── TransportPathConfig[]
│   ├── StockerConfig[]
│   └── MESSystemConfig
│
├── 工艺配置（ProcessConfig）
│   ├── RecipeConfig[]
│   └── ProcessRouteConfig[]
│
├── 仿真配置（SimulationConfig）
│   ├── InitialLotConfig[]
│   ├── SchedulingRuleConfig
│   └── FaultInjectionConfig
│
└── 系统配置（SystemConfig）
    ├── version
    └── logging
```

### 6.2 核心配置接口

```typescript
// 工厂布局配置（这是核心配置，供 3D 引擎和仿真引擎共同消费）
export interface FabLayoutConfig extends VersionedConfig {
  fab: FabConfig
  workAreas: WorkAreaConfig[]
  stockers?: StockerConfig[]
  mesSystem?: MESSystemConfig
}

export interface FabConfig {
  id: string
  name: string
  size: { width: number; depth: number }
}

export interface WorkAreaConfig {
  id: string
  name: string
  type: string
  position: { x: number; z: number }
  size: { width: number; depth: number }
  equipmentGroups: EquipmentGroupConfig[]
  buffers?: BufferConfig[]
  transportPaths?: TransportPathConfig[]
}

export interface EquipmentGroupConfig {
  id: string
  layout: 'linear' | 'grid' | 'cluster'
  spacing?: number | { x: number; z: number }
  equipment: EquipmentConfig[]
}

export interface EquipmentConfig {
  id: string
  name: string
  type: string  // EquipmentType 的字符串值
  position: { x: number; z: number }
  orientation?: number
  throughput?: number
  mtbf?: number
  mttr?: number
  supportedRecipeIds?: string[]
  inputBankId?: string
  outputBankId?: string
}

export interface BufferConfig {
  id: string
  name: string
  type: 'input' | 'output' | 'intermediate'
  position: { x: number; z: number }
  capacity: number
  associatedEquipmentId?: string
}

export interface StockerConfig {
  id: string
  name: string
  position: { x: number; z: number }
  capacity: number
  levels: number
  servesWorkAreaIds: string[]
}

export interface TransportPathConfig {
  id: string
  points: Array<{ x: number; z: number }>
  type: 'amhs' | 'agv' | 'manual' | 'conveyor'
  speed: number
  vehicles?: number
}

export interface MESSystemConfig {
  id: string
  type: 'central' | 'distributed'
  schedulingRule?: string
}

// 工艺配置
export interface ProcessConfig extends VersionedConfig {
  recipes: RecipeConfig[]
  routes: ProcessRouteConfig[]
}

export interface RecipeConfig {
  id: string
  name: string
  equipmentType: string
  processTime: number
  timeVariance?: number
  setupTime?: number
  parameters?: Array<{
    name: string
    value: number
    unit: string
    min?: number
    max?: number
  }>
}

export interface ProcessRouteConfig {
  id: string
  name: string
  productType?: string
  steps: Array<{
    sequence: number
    name: string
    requiredEquipmentType: string
    recipeId: string
    isInspection?: boolean
  }>
  isCyclic?: boolean
  cycleCount?: number
}

// 仿真配置
export interface SimulationRuntimeConfig {
  initialLots: Array<{
    id: string
    name: string
    waferCount: number
    routeId: string
    priority?: number
  }>
  schedulingRule: string
  initialSpeed?: number
  faultInjection?: {
    enabled: boolean
    randomMode?: { enabled: boolean; mtbf: number }
    script?: Array<{
      time: number
      action: 'inject' | 'resolve'
      equipmentId: string
      faultId: string
    }>
  }
}
```

### 6.3 配置验证

```typescript
// 统一的验证入口
export function validateFabLayoutConfig(config: unknown): FabLayoutConfig
export function validateProcessConfig(config: unknown): ProcessConfig
export function validateSimulationRuntimeConfig(config: unknown): SimulationRuntimeConfig

// 验证错误
export class ValidationError extends Error {
  constructor(
    message: string,
    public readonly path: string,
    public readonly expected: string,
    public readonly actual: unknown
  )
}

// 版本迁移
export interface VersionedConfig {
  version: string
}

export function migrateConfig(config: VersionedConfig, targetVersion: string): VersionedConfig
```

---

## 7. 文件结构规划

```
packages/core/src/
├── models/                        # 领域模型（已有）
│   ├── index.ts                   # 模型统一导出
│   ├── lot.ts                     # Lot 模型 + 状态机
│   ├── equipment.ts               # Equipment 模型 + 状态机
│   ├── recipe.ts                  # Recipe 模型
│   ├── process-step.ts            # ProcessStep/Route 模型
│   ├── buffer.ts                  # Buffer/Stocker 模型 ★新增
│   ├── transport.ts               # TransportPath/Vehicle 模型 ★新增
│   ├── work-area.ts               # Fab/WorkArea/EquipmentGroup 模型 ★新增
│   ├── mes-system.ts              # MESState/Event/Fault 模型 ★新增
│   └── statistics.ts              # OEE/WIP 统计模型 ★新增
│
├── engine/                        # 仿真引擎（已有，需扩展）
│   ├── index.ts
│   ├── event-queue.ts             # 事件队列
│   ├── simulation-engine.ts       # 仿真引擎核心
│   ├── event-handlers.ts          # 事件处理器集合 ★新增
│   └── simulation-context.ts      # 仿真上下文 ★新增
│
├── scheduling/                    # 调度策略（新增目录）★
│   ├── index.ts
│   ├── strategy-interface.ts      # 策略接口
│   ├── fifo-strategy.ts           # FIFO 实现
│   ├── spt-strategy.ts            # SPT 实现
│   ├── cr-strategy.ts             # CR 实现
│   └── strategy-registry.ts       # 策略注册表
│
├── config/                        # 配置验证（新增目录）★
│   ├── index.ts
│   ├── validation-error.ts        # 验证错误类
│   ├── fab-layout-config.ts       # 工厂布局配置
│   ├── process-config.ts          # 工艺配置
│   ├── simulation-config.ts       # 仿真运行时配置
│   └── version-migration.ts       # 版本迁移
│
└── index.ts                       # 公共 API 导出
```

---

## 8. 对外 API（最终导出）

```typescript
// === 领域模型 ===
export type {
  Lot, LotStatus,
  Equipment, EquipmentType, EquipmentStatus,
  ControlState, ProcessState,
  Position3D,
  Recipe, RecipeParameter,
  ProcessStep, ProcessRoute,
  Buffer, BufferType,
  Stocker,
  TransportPath, TransportType,
  TransportVehicle, VehicleStatus,
  Fab, WorkArea, EquipmentGroup, GroupLayout,
  MESState, WIPStatistics, EventDefinition,
  FaultDefinition, FaultCategory, FaultSeverity,
  OEEMetrics, EquipmentTimeLog, TimePeriod
} from './models'

// === 状态机函数 ===
export {
  canLotTransition, LOT_STATUS_TRANSITIONS
} from './models/lot'

// === 仿真引擎 ===
export {
  SimulationEngine,
  SimulationState, SimulationConfig, SimulationCallbacks
} from './engine/simulation-engine'

export {
  EventQueue,
  SimulationEvent, EventType,
  EventHandler, EventHandlerRegistry,
  SimulationContext
} from './engine'

// === 调度策略 ===
export type {
  SchedulingStrategy, DispatchContext, DispatchDecision
} from './scheduling/strategy-interface'

export {
  FIFOStrategy, SPTStrategy, CRStrategy
} from './scheduling'

export { StrategyRegistry } from './scheduling/strategy-registry'

// === 配置验证 ===
export type {
  FabLayoutConfig, FabConfig, WorkAreaConfig,
  EquipmentGroupConfig, EquipmentConfig,
  BufferConfig, StockerConfig,
  TransportPathConfig, MESSystemConfig,
  ProcessConfig, RecipeConfig, ProcessRouteConfig,
  SimulationRuntimeConfig,
  VersionedConfig
} from './config'

export {
  validateFabLayoutConfig,
  validateProcessConfig,
  validateSimulationRuntimeConfig,
  migrateConfig,
  ValidationError
} from './config'
```

---

## 9. 与下游的协作契约

### 9.1 向 @3d-expert 提供

| 提供内容 | 文件 | 用途 |
|---------|------|------|
| 领域模型类型 | `models/*.ts` | 3D 引擎创建 Entity 绑定 |
| 配置类型 | `config/*.ts` | SceneBuilder 解析 JSON |
| 仿真状态 | `SimulationState` | EntityManager 同步状态 |
| 仿真事件 | `SimulationEvent` | 驱动 3D 动画 |
| 状态枚举 | `EquipmentStatus`, `LotStatus` | 颜色映射和状态可视化 |

**重要**：`Position3D` 是**业务坐标**（米），不是 3D 场景坐标。`@3d-expert` 可以根据需要将其映射到 3D 空间。

### 9.2 向 @ui-expert 提供

| 提供内容 | 文件 | 用途 |
|---------|------|------|
| Lot/Equipment 类型 | `models/lot.ts`, `models/equipment.ts` | UI 组件类型定义 |
| OEE 统计 | `models/statistics.ts` | 报表组件 |
| WIP 统计 | `models/mes-system.ts` | 看板组件 |

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次新增/修改领域模型时更新
