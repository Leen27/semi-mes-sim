/**
 * 工艺步骤
 */
export interface ProcessStep {
  /** 步骤唯一标识 */
  id: string
  /** 步骤序号 */
  sequence: number
  /** 步骤名称 */
  name: string
  /** 所需设备类型 */
  requiredEquipmentType: string
  /** 使用的配方 ID */
  recipeId: string
  /** 步骤描述 */
  description?: string
}

/**
 * 工艺路线（一组有序的工艺步骤）
 */
export interface ProcessRoute {
  /** 路线唯一标识 */
  id: string
  /** 路线名称 */
  name: string
  /** 步骤列表 */
  steps: ProcessStep[]
}
