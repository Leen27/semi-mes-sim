# 半导体 MES 领域专家 — 技能定义

> 本文件定义 `@mes-expert` Agent 的详细技能、代码模式和最佳实践。
> 编写代码时以本文件为参考。

---

## 技能 1：领域模型设计

### 能力
设计表达半导体 MES 业务概念的 TypeScript 接口和类型。

### 设计原则

```typescript
// ✅ 好的领域模型：聚焦业务属性，不包含技术实现细节
export interface Equipment {
  id: string
  name: string
  type: EquipmentType
  status: EquipmentStatus
  currentLotId?: string
  supportedRecipeIds: string[]
  position: Position3D        // 业务位置，不是 3D 场景位置
  throughput: number          // 加工能力，单位：晶圆/小时
  mtbf?: number               // 平均故障间隔，单位：秒
  mttr?: number               // 平均修复时间，单位：秒
}

// ❌ 坏的领域模型：混入 3D/UI 实现细节
export interface Equipment {
  id: string
  meshName: string            // ❌ 3D 细节，不属于领域层
  cssColor: string            // ❌ UI 细节，不属于领域层
  cameraTarget: boolean       // ❌ 3D 细节
}
```

### 模型设计检查清单

每个新模型必须通过以下检查：
- [ ] 是否表达了真实的 MES 业务概念？
- [ ] 是否不包含 3D/UI/网络等技术细节？
- [ ] 是否有清晰的 JSDoc 注释说明每个字段的业务含义？
- [ ] 是否有配套的状态枚举（如需要）？
- [ ] 是否有配套的配置接口（供 JSON 解析）？
- [ ] 是否考虑了扩展性（后续版本可能新增的字段）？

### 常用模式：值对象 vs 实体

```typescript
// 实体（有唯一标识，生命周期长）
export interface Equipment {
  id: string      // 唯一标识
  // ... 其他属性
}

// 值对象（无唯一标识，可替换）
export interface Position3D {
  x: number
  y: number
  z: number
}

// 值对象可以用 Readonly 表示不可变性
export interface RecipeParameter {
  readonly name: string
  readonly value: number
  readonly unit: string
}
```

---

## 技能 2：状态机设计

### 能力
设计半导体设备、Lot、Buffer 等业务实体的状态转换规则。

### 设备状态机（GEM 标准简化版）

```typescript
// Communication State（通信层）
export enum CommunicationState {
  Disabled = 'disabled',
  Enabled = 'enabled',
  Communicating = 'communicating'
}

// Control State（控制层）
export enum ControlState {
  Offline = 'offline',
  OnlineLocal = 'online_local',    // 本地模式，拒绝远程指令
  OnlineRemote = 'online_remote'   // 远程模式，接受 host 指令
}

// Process State（加工层）
export enum ProcessState {
  Idle = 'idle',
  Setup = 'setup',
  Processing = 'processing',
  Paused = 'paused'
}

// 组合状态（供外部使用）
export interface EquipmentState {
  communication: CommunicationState
  control: ControlState
  process: ProcessState
}

// 状态转换规则（纯函数，无副作用）
export function canTransitionTo(
  current: EquipmentState,
  target: EquipmentState
): boolean {
  // 通信层必须先建立才能进入控制层
  if (current.communication !== CommunicationState.Communicating) {
    if (target.control !== ControlState.Offline) return false
  }
  
  // 控制层必须在 OnlineRemote 才能加工
  if (target.process === ProcessState.Processing) {
    if (current.control !== ControlState.OnlineRemote) return false
  }
  
  // ... 其他规则
  return true
}
```

### Lot 状态机

```typescript
export enum LotStatus {
  Waiting = 'waiting',        // 等待加工
  Processing = 'processing',  // 加工中
  Completed = 'completed',    // 已完成所有步骤
  OnHold = 'on_hold'          // 暂停/保持
}

// 允许的状态转换
const ALLOWED_LOT_TRANSITIONS: Record<LotStatus, LotStatus[]> = {
  [LotStatus.Waiting]: [LotStatus.Processing, LotStatus.OnHold],
  [LotStatus.Processing]: [LotStatus.Completed, LotStatus.OnHold],
  [LotStatus.OnHold]: [LotStatus.Waiting],
  [LotStatus.Completed]: []
}

export function canLotTransition(from: LotStatus, to: LotStatus): boolean {
  return ALLOWED_LOT_TRANSITIONS[from]?.includes(to) ?? false
}
```

---

## 技能 3：JSON 配置 Schema 设计

### 能力
设计可验证的 JSON 配置数据结构，提供类型安全和运行时验证。

### 配置设计原则

```typescript
// 1. 配置接口与领域模型分离
// 配置用于 JSON 解析，可能包含字符串/简化结构
// 领域模型用于运行时，使用枚举/复杂类型

export interface EquipmentConfig {
  id: string
  name: string
  type: string           // JSON 中是字符串
  position: { x: number; y?: number; z: number }
  orientation?: number
  inputBank?: string     // 关联的缓冲 ID
  outputBank?: string
  throughput?: number
  mtbf?: number          // 秒
  mttr?: number          // 秒
  supportedRecipeIds?: string[]
}

// 2. 默认值处理
const EQUIPMENT_CONFIG_DEFAULTS = {
  throughput: 60,
  mtbf: 7200,
  mttr: 1800,
  supportedRecipeIds: [],
  orientation: 0
}

export function fillEquipmentDefaults(
  config: Partial<EquipmentConfig>
): EquipmentConfig {
  return {
    ...EQUIPMENT_CONFIG_DEFAULTS,
    ...config,
    id: config.id!,
    name: config.name!,
    type: config.type!
  } as EquipmentConfig
}

// 3. 验证函数
export function validateEquipmentConfig(config: unknown): EquipmentConfig {
  if (typeof config !== 'object' || config === null) {
    throw new ValidationError('EquipmentConfig must be an object', 'equipment', 'object', config)
  }
  
  const c = config as Partial<EquipmentConfig>
  
  if (!c.id) throw new ValidationError('id is required', 'equipment.id', 'string', c.id)
  if (!c.name) throw new ValidationError('name is required', 'equipment.name', 'string', c.name)
  if (!c.type) throw new ValidationError('type is required', 'equipment.type', 'string', c.type)
  
  // 验证 type 是否有效
  const validTypes = Object.values(EquipmentType)
  if (!validTypes.includes(c.type as EquipmentType)) {
    throw new ValidationError(
      `type must be one of ${validTypes.join(', ')}`,
      'equipment.type',
      validTypes.join('|'),
      c.type
    )
  }
  
  return fillEquipmentDefaults(c)
}
```

### 配置版本管理

```typescript
// 配置支持版本号，便于升级
export interface VersionedConfig {
  version: string  // semver，如 "1.0.0"
}

// 版本迁移函数（当格式变更时）
export function migrateConfig(
  config: VersionedConfig,
  targetVersion: string
): VersionedConfig {
  switch (config.version) {
    case '0.9.0':
      // 从 0.9.0 迁移到 1.0.0 的转换逻辑
      return { ...config, version: '1.0.0' }
    case '1.0.0':
      return config
    default:
      throw new ValidationError(
        `Unsupported config version: ${config.version}`,
        'version',
        '0.9.0 | 1.0.0',
        config.version
      )
  }
}
```

---

## 技能 4：离散事件仿真（DES）

### 能力
设计和实现离散事件仿真引擎的核心逻辑。

### 事件设计模式

```typescript
// 事件基接口
export interface SimulationEvent {
  time: number           // 仿真时间戳（秒）
  type: EventType
  entityId: string       // 关联实体 ID
  data?: Record<string, unknown>
}

// 事件类型枚举
export enum EventType {
  LotArrival = 'lot_arrival',
  EquipmentReady = 'equipment_ready',
  ProcessComplete = 'process_complete',
  EquipmentBreakdown = 'equipment_breakdown',
  EquipmentRepair = 'equipment_repair',
  LotMoveToBuffer = 'lot_move_to_buffer',
  LotMoveToEquipment = 'lot_move_to_equipment',
  SchedulerDispatch = 'scheduler_dispatch'
}

// 事件处理器签名
export type EventHandler = (
  event: SimulationEvent,
  state: SimulationState,
  context: SimulationContext
) => SimulationEvent[]  // 返回新产生的事件

// 仿真上下文（提供辅助方法）
export interface SimulationContext {
  getEquipment(id: string): Equipment | undefined
  getLot(id: string): Lot | undefined
  getBuffer(id: string): Buffer | undefined
  getRecipe(id: string): Recipe | undefined
  scheduleEvent(event: SimulationEvent): void
  log(message: string): void
}
```

### 事件处理器注册

```typescript
// 事件处理器注册表
export class EventHandlerRegistry {
  private handlers = new Map<EventType, EventHandler>()
  
  register(type: EventType, handler: EventHandler): void {
    if (this.handlers.has(type)) {
      throw new Error(`Handler for ${type} already registered`)
    }
    this.handlers.set(type, handler)
  }
  
  get(type: EventType): EventHandler | undefined {
    return this.handlers.get(type)
  }
}

// 注册示例
const registry = new EventHandlerRegistry()

registry.register(EventType.LotArrival, (event, state, ctx) => {
  const lot = ctx.getLot(event.entityId)
  if (!lot) return []
  
  // 找到下一步需要的设备类型
  const nextStep = getNextStep(lot, state.routes)
  if (!nextStep) return []
  
  // 找到可用的设备
  const availableEquipment = findAvailableEquipment(
    state.equipments,
    nextStep.requiredEquipmentType
  )
  
  if (availableEquipment) {
    // 直接分配
    return [{
      time: event.time,
      type: EventType.LotMoveToEquipment,
      entityId: lot.id,
      data: { targetEquipmentId: availableEquipment.id }
    }]
  } else {
    // 进入缓冲等待
    const buffer = findBufferForEquipmentType(
      state.buffers,
      nextStep.requiredEquipmentType
    )
    if (buffer) {
      return [{
        time: event.time,
        type: EventType.LotMoveToBuffer,
        entityId: lot.id,
        data: { targetBufferId: buffer.id }
      }]
    }
  }
  
  return []
})
```

---

## 技能 5：调度策略接口

### 能力
设计可插拔的调度策略接口，支持 FIFO、SPT、CR 等规则。

### 策略接口设计

```typescript
// 调度决策上下文
export interface DispatchContext {
  waitingLots: Lot[]                    // 等待派工的 Lot
  availableEquipments: Equipment[]       // 可用设备
  currentTime: number                    // 当前仿真时间
  wipStats: WIPStatistics                // WIP 统计
}

// 调度决策结果
export interface DispatchDecision {
  lotId: string
  equipmentId: string
  rule: string                           // 使用的规则名称
  reason: string                         // 决策原因
  candidates: Array<{                    // 其他候选
    lotId: string
    score: number
  }>
}

// 调度策略接口
export interface SchedulingStrategy {
  readonly name: string
  readonly description: string
  
  /**
   * 评估候选 Lot 的优先级分数
   * 分数越高，优先级越高
   */
  scoreLot(lot: Lot, context: DispatchContext): number
  
  /**
   * 选择设备（当多个设备可用时）
   */
  selectEquipment(lot: Lot, equipments: Equipment[], context: DispatchContext): Equipment
  
  /**
   * 执行派工决策
   */
  dispatch(context: DispatchContext): DispatchDecision | null
}

// FIFO 策略实现
export class FIFOStrategy implements SchedulingStrategy {
  readonly name = 'FIFO'
  readonly description = 'First In First Out'
  
  scoreLot(lot: Lot, context: DispatchContext): number {
    // 越早等待的 Lot 分数越高
    const waitTime = context.currentTime - (lot.enteredStepAt ?? lot.createdAt)
    return waitTime
  }
  
  selectEquipment(lot: Lot, equipments: Equipment[], context: DispatchContext): Equipment {
    // 选择第一个可用设备（简单实现）
    return equipments[0]
  }
  
  dispatch(context: DispatchContext): DispatchDecision | null {
    if (context.waitingLots.length === 0 || context.availableEquipments.length === 0) {
      return null
    }
    
    // 按等待时间排序
    const scored = context.waitingLots.map(lot => ({
      lot,
      score: this.scoreLot(lot, context)
    }))
    scored.sort((a, b) => b.score - a.score)
    
    const selected = scored[0]
    const equipment = this.selectEquipment(
      selected.lot,
      context.availableEquipments,
      context
    )
    
    return {
      lotId: selected.lot.id,
      equipmentId: equipment.id,
      rule: this.name,
      reason: `Waited ${(selected.score / 60).toFixed(1)} minutes`,
      candidates: scored.slice(1, 4).map(s => ({ lotId: s.lot.id, score: s.score }))
    }
  }
}

// SPT 策略（最短加工时间优先）
export class SPTStrategy implements SchedulingStrategy {
  readonly name = 'SPT'
  readonly description = 'Shortest Processing Time'
  
  scoreLot(lot: Lot, context: DispatchContext): number {
    const nextStep = getNextStep(lot, context.routes)
    if (!nextStep) return -Infinity
    
    const recipe = context.getRecipe(nextStep.recipeId)
    const processTime = recipe?.processTime ?? Infinity
    
    // 加工时间越短，分数越高（取倒数）
    return 1 / processTime
  }
  
  // ... selectEquipment 和 dispatch 类似 FIFO
}

// CR 策略（关键比率）
export class CRStrategy implements SchedulingStrategy {
  readonly name = 'CR'
  readonly description = 'Critical Ratio'
  
  scoreLot(lot: Lot, context: DispatchContext): number {
    if (!lot.dueTime) return -Infinity
    
    const remainingTime = lot.dueTime - context.currentTime
    const remainingSteps = getRemainingSteps(lot, context.routes)
    
    // CR = 剩余时间 / 剩余工序数
    // CR 越小越紧急，分数越高
    const cr = remainingTime / (remainingSteps || 1)
    return 1 / cr
  }
}
```

---

## 技能 6：故障注入设计

### 能力
设计故障定义和故障注入机制。

```typescript
// 故障严重级别
export enum FaultSeverity {
  Warning = 'warning',
  Error = 'error',
  Fatal = 'fatal'
}

// 故障类型
export enum FaultCategory {
  Communication = 'communication',  // 通信故障
  Equipment = 'equipment',          // 设备故障
  Process = 'process',              // 工艺故障
  MES = 'mes'                       // MES 系统故障
}

// 故障定义（故障库中的条目）
export interface FaultDefinition {
  id: string
  name: string
  description: string
  category: FaultCategory
  severity: FaultSeverity
  /** 影响的设备类型（null 表示所有类型） */
  affectedEquipmentTypes?: EquipmentType[]
  /** 平均修复时间（秒） */
  mttr: number
  /** 自动恢复概率（0-1） */
  autoRecoveryChance?: number
}

// 故障事件（运行时实例）
export interface FaultEvent {
  id: string
  definitionId: string
  equipmentId: string
  startTime: number
  endTime?: number
  isActive: boolean
  injectedBy: 'manual' | 'random' | 'script'
}

// 故障库
export const DEFAULT_FAULT_LIBRARY: FaultDefinition[] = [
  {
    id: 'F101',
    name: 'PumpFail',
    description: '真空泵故障',
    category: FaultCategory.Equipment,
    severity: FaultSeverity.Fatal,
    mttr: 1800
  },
  {
    id: 'F102',
    name: 'TempHigh',
    description: '温度超限',
    category: FaultCategory.Equipment,
    severity: FaultSeverity.Error,
    mttr: 300
  },
  {
    id: 'F201',
    name: 'RecipeError',
    description: 'Recipe 参数错误',
    category: FaultCategory.Process,
    severity: FaultSeverity.Error,
    mttr: 60
  }
]

// 故障注入配置
export interface FaultInjectionConfig {
  enabled: boolean
  /** 随机故障模式 */
  randomMode?: {
    enabled: boolean
    mtbf: number  // 平均故障间隔（秒）
  }
  /** 预设故障序列 */
  script?: FaultScriptStep[]
}

export interface FaultScriptStep {
  time: number           // 仿真时间（秒）
  action: 'inject' | 'resolve'
  equipmentId: string
  faultId: string
}
```

---

## 技能 7：OEE 统计设计

### 能力
设计设备综合效率（OEE）的数据结构和计算规则。

```typescript
// OEE 三大要素
export interface OEEMetrics {
  /** 可用率 = 实际运行时间 / 计划运行时间 */
  availability: number
  /** 性能率 = 实际产量 / 理论产量 */
  performance: number
  /** 良品率 = 合格品 / 总产量 */
  quality: number
  /** OEE = 可用率 × 性能率 × 良品率 */
  oee: number
  /** 数据时间范围 */
  period: { start: number; end: number }
}

// 设备时间记录
export interface EquipmentTimeLog {
  equipmentId: string
  periods: TimePeriod[]
}

export interface TimePeriod {
  start: number
  end: number
  type: 'running' | 'idle' | 'breakdown' | 'maintenance' | 'setup'
}

// OEE 计算函数
export function calculateOEE(log: EquipmentTimeLog, totalOutput: number, goodOutput: number): OEEMetrics {
  const totalTime = log.periods.reduce((sum, p) => sum + (p.end - p.start), 0)
  const runningTime = log.periods
    .filter(p => p.type === 'running')
    .reduce((sum, p) => sum + (p.end - p.start), 0)
  const plannedTime = log.periods
    .filter(p => p.type !== 'maintenance')
    .reduce((sum, p) => sum + (p.end - p.start), 0)
  
  const availability = plannedTime > 0 ? runningTime / plannedTime : 0
  const performance = totalTime > 0 ? totalOutput / (runningTime / 3600) : 0  // 简化计算
  const quality = totalOutput > 0 ? goodOutput / totalOutput : 0
  
  return {
    availability,
    performance,
    quality,
    oee: availability * performance * quality,
    period: {
      start: Math.min(...log.periods.map(p => p.start)),
      end: Math.max(...log.periods.map(p => p.end))
    }
  }
}
```

---

## 技能 8：测试模式

### 能力
为领域模型和仿真逻辑编写单元测试。

```typescript
import { describe, it, expect } from 'vitest'
import { canLotTransition, LotStatus } from './lot'
import { FIFOStrategy } from './scheduling/fifo'
import { validateEquipmentConfig } from './config/equipment-config'

describe('Lot 状态机', () => {
  it('Waiting 可以转移到 Processing', () => {
    expect(canLotTransition(LotStatus.Waiting, LotStatus.Processing)).toBe(true)
  })
  
  it('Completed 不能转移到任何状态', () => {
    expect(canLotTransition(LotStatus.Completed, LotStatus.Waiting)).toBe(false)
    expect(canLotTransition(LotStatus.Completed, LotStatus.Processing)).toBe(false)
  })
})

describe('FIFO 调度策略', () => {
  it('应该选择等待时间最长的 Lot', () => {
    const strategy = new FIFOStrategy()
    const context = createMockDispatchContext({
      waitingLots: [
        { id: 'L001', enteredStepAt: 0 },   // 等待 100 秒
        { id: 'L002', enteredStepAt: 50 },  // 等待 50 秒
        { id: 'L003', enteredStepAt: 80 }   // 等待 20 秒
      ],
      currentTime: 100
    })
    
    const decision = strategy.dispatch(context)
    
    expect(decision).not.toBeNull()
    expect(decision!.lotId).toBe('L001')
    expect(decision!.rule).toBe('FIFO')
  })
})

describe('配置验证', () => {
  it('应该拒绝缺少 id 的设备配置', () => {
    expect(() => validateEquipmentConfig({ name: 'Test', type: 'lithography' }))
      .toThrow('id is required')
  })
  
  it('应该拒绝无效的设备类型', () => {
    expect(() => validateEquipmentConfig({
      id: 'EQ001',
      name: 'Test',
      type: 'invalid_type'
    })).toThrow('type must be one of')
  })
})
```

---

## 附录：新模型创建模板

### 模板 1：领域模型 + 配置 + 验证

```typescript
// src/models/[entity].ts

/**
 * [业务概念描述]
 */
export interface [Entity] {
  id: string
  name: string
  // ... 业务属性
}

export enum [Entity]Status {
  // ... 状态枚举
}

// src/config/[entity]-config.ts

export interface [Entity]Config {
  id: string
  name: string
  // ... 配置属性（可能与领域模型略有不同）
}

export function validate[Entity]Config(config: unknown): [Entity]Config {
  // 验证逻辑
}

// src/models/[entity].test.ts

import { describe, it, expect } from 'vitest'

describe('[Entity]', () => {
  it('should ...', () => {
    // 测试
  })
})
```

### 模板 2：状态机

```typescript
// 状态枚举
export enum [Entity]Status {
  StateA = 'state_a',
  StateB = 'state_b'
}

// 允许转换表
const ALLOWED_TRANSITIONS: Record<[Entity]Status, [Entity]Status[]> = {
  [Entity]Status.StateA]: [Entity]Status.StateB],
  [Entity]Status.StateB]: []
}

// 转换验证函数
export function canTransition[Entity](
  from: [Entity]Status,
  to: [Entity]Status
): boolean {
  return ALLOWED_TRANSITIONS[from]?.includes(to) ?? false
}
```

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
