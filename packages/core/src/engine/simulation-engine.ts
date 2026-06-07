import { EventQueue, type SimulationEvent, EventType } from './event-queue'
import type { Lot, Equipment, ProcessRoute } from '../models'

/**
 * 仿真引擎状态
 */
export interface SimulationState {
  /** 当前仿真时间 */
  currentTime: number
  /** 仿真是否运行中 */
  isRunning: boolean
  /** 仿真速度倍率 */
  speed: number
  /** 所有 Lot */
  lots: Lot[]
  /** 所有设备 */
  equipments: Equipment[]
  /** 工艺路线 */
  routes: ProcessRoute[]
}

/**
 * 仿真引擎配置
 */
export interface SimulationConfig {
  /** 初始 Lot 列表 */
  initialLots: Lot[]
  /** 设备列表 */
  equipments: Equipment[]
  /** 工艺路线 */
  routes: ProcessRoute[]
  /** 初始仿真速度 */
  initialSpeed?: number
}

/**
 * 仿真回调
 */
export interface SimulationCallbacks {
  /** 事件处理回调 */
  onEvent?: (event: SimulationEvent, state: SimulationState) => void
  /** 时间推进回调 */
  onTick?: (state: SimulationState) => void
}

/**
 * 离散事件仿真引擎
 * 
 * 注意：本引擎是纯逻辑层，不依赖任何浏览器 API。
 * 渲染循环由调用方（如 apps/web）通过 requestAnimationFrame 驱动，
 * 每帧调用 tick() 方法推进仿真。
 */
export class SimulationEngine {
  private eventQueue: EventQueue
  private state: SimulationState
  private config: SimulationConfig
  private callbacks: SimulationCallbacks

  constructor(config: SimulationConfig, callbacks: SimulationCallbacks = {}) {
    this.config = config
    this.callbacks = callbacks
    this.eventQueue = new EventQueue()
    this.state = {
      currentTime: 0,
      isRunning: false,
      speed: config.initialSpeed ?? 1,
      lots: [...config.initialLots],
      equipments: [...config.equipments],
      routes: [...config.routes]
    }
  }

  /**
   * 获取当前状态
   */
  getState(): Readonly<SimulationState> {
    return Object.freeze({ ...this.state })
  }

  /**
   * 启动仿真
   */
  start(): void {
    if (this.state.isRunning) return
    this.state.isRunning = true
    this.initializeEvents()
  }

  /**
   * 暂停仿真
   */
  pause(): void {
    this.state.isRunning = false
  }

  /**
   * 重置仿真
   */
  reset(): void {
    this.pause()
    this.state.currentTime = 0
    this.state.speed = this.config.initialSpeed ?? 1
    this.state.lots = [...this.config.initialLots]
    this.state.equipments = [...this.config.equipments]
    this.eventQueue.clear()
  }

  /**
   * 设置仿真速度
   */
  setSpeed(speed: number): void {
    this.state.speed = Math.max(0.1, Math.min(speed, 100))
  }

  /**
   * 推进仿真一帧
   * @param realDeltaTime 实际经过的时间（秒）
   * @returns 是否处理了事件
   */
  tick(realDeltaTime: number): boolean {
    if (!this.state.isRunning) return false

    // 根据速度倍率计算仿真时间推进量
    const simDeltaTime = realDeltaTime * this.state.speed
    const targetTime = this.state.currentTime + simDeltaTime

    let hasEvents = false

    // 处理所有在当前时间窗口内的事件
    while (true) {
      const nextEvent = this.eventQueue.peek()
      if (!nextEvent || nextEvent.time > targetTime) break

      this.eventQueue.dequeue()
      this.state.currentTime = nextEvent.time
      this.processEvent(nextEvent)
      hasEvents = true
    }

    this.state.currentTime = targetTime
    this.callbacks.onTick?.(this.getState() as SimulationState)

    return hasEvents
  }

  /**
   * 初始化事件
   */
  private initializeEvents(): void {
    // 为所有等待中的 Lot 创建到达事件
    for (const lot of this.state.lots) {
      if (lot.status === 'waiting') {
        this.eventQueue.enqueue({
          time: this.state.currentTime,
          type: EventType.LotArrival,
          entityId: lot.id
        })
      }
    }

    // 为所有设备创建就绪事件
    for (const equipment of this.state.equipments) {
      this.eventQueue.enqueue({
        time: this.state.currentTime,
        type: EventType.EquipmentReady,
        entityId: equipment.id
      })
    }
  }

  /**
   * 处理单个事件
   */
  private processEvent(event: SimulationEvent): void {
    // TODO(F004): 实现离散事件处理逻辑
    // - LotArrival: 将 Lot 分配到可用设备
    // - EquipmentReady: 设备就绪，检查是否有等待的 Lot
    // - ProcessComplete: 加工完成，Lot 移动到下一步
    // - EquipmentBreakdown: 设备故障
    // - EquipmentRepair: 设备修复

    this.callbacks.onEvent?.(event, this.getState() as SimulationState)
  }
}
