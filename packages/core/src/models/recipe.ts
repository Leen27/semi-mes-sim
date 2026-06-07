/**
 * 工艺配方
 */
export interface Recipe {
  /** 配方唯一标识 */
  id: string
  /** 配方名称 */
  name: string
  /** 适用设备类型 */
  equipmentType: string
  /** 加工时间（单位：秒） */
  processTime: number
  /** 工艺参数 */
  parameters: RecipeParameter[]
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
