/**
 * 晶圆批次（Lot）- MES 中流转的基本单位
 */
export interface Lot {
  /** 批次唯一标识 */
  id: string
  /** 批次名称/编号 */
  name: string
  /** 晶圆数量 */
  waferCount: number
  /** 当前工艺步骤索引 */
  currentStepIndex: number
  /** 工艺路线 ID */
  routeId: string
  /** 当前所在设备 ID（如果在设备上） */
  currentEquipmentId?: string
  /** 批次优先级（数字越小优先级越高） */
  priority: number
  /** 批次状态 */
  status: LotStatus
  /** 创建时间戳 */
  createdAt: number
  /** 进入当前步骤的时间 */
  enteredStepAt?: number
}

export enum LotStatus {
  /** 等待中 */
  Waiting = 'waiting',
  /** 加工中 */
  Processing = 'processing',
  /** 已完成所有步骤 */
  Completed = 'completed',
  /** 暂停/保持 */
  OnHold = 'on_hold'
}
