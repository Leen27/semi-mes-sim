/**
 * 生产设备
 */
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
  /** 支持的工艺配方 IDs */
  supportedRecipeIds: string[]
  /** 3D 场景中的位置 */
  position: Position3D
  /** 加工能力（单位：晶圆/小时） */
  throughput: number
}

export enum EquipmentType {
  Lithography = 'lithography',
  Etching = 'etching',
  Deposition = 'deposition',
  Implantation = 'implantation',
  Cleaning = 'cleaning',
  Inspection = 'inspection',
  Annealing = 'annealing'
}

export enum EquipmentStatus {
  /** 空闲 */
  Idle = 'idle',
  /** 加载中 */
  Loading = 'loading',
  /** 加工中 */
  Processing = 'processing',
  /** 卸载中 */
  Unloading = 'unloading',
  /** 故障 */
  Error = 'error',
  /** 维护中 */
  Maintenance = 'maintenance'
}

export interface Position3D {
  x: number
  y: number
  z: number
}
