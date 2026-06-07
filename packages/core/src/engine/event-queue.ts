/**
 * 仿真事件
 */
export interface SimulationEvent {
  /** 事件触发时间 */
  time: number
  /** 事件类型 */
  type: EventType
  /** 关联实体 ID */
  entityId: string
  /** 事件数据 */
  data?: Record<string, unknown>
}

export enum EventType {
  LotArrival = 'lot_arrival',
  EquipmentReady = 'equipment_ready',
  ProcessComplete = 'process_complete',
  EquipmentBreakdown = 'equipment_breakdown',
  EquipmentRepair = 'equipment_repair'
}

/**
 * 离散事件队列（最小堆实现）
 */
export class EventQueue {
  private events: SimulationEvent[] = []

  /**
   * 插入事件（按时间排序）
   */
  enqueue(event: SimulationEvent): void {
    this.events.push(event)
    this.events.sort((a, b) => a.time - b.time)
  }

  /**
   * 取出下一个事件
   */
  dequeue(): SimulationEvent | undefined {
    return this.events.shift()
  }

  /**
   * 查看下一个事件（不移除）
   */
  peek(): SimulationEvent | undefined {
    return this.events[0]
  }

  /**
   * 队列是否为空
   */
  isEmpty(): boolean {
    return this.events.length === 0
  }

  /**
   * 队列长度
   */
  get length(): number {
    return this.events.length
  }

  /**
   * 清空队列
   */
  clear(): void {
    this.events = []
  }
}
