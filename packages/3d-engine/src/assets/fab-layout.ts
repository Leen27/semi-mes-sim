import {
  Scene,
  Mesh,
  MeshBuilder,
  StandardMaterial,
  Color3,
  Vector3,
  TransformNode
} from '@babylonjs/core'
import type { Equipment } from '@semi/core'
import { createEquipmentModel, updateEquipmentStatus } from './equipment-models'

/**
 * 晶圆厂布局管理器
 */
export class FabLayout {
  private equipmentModels: Map<string, TransformNode> = new Map()
  private lotModels: Map<string, Mesh> = new Map()
  private scene: Scene

  constructor(scene: Scene) {
    this.scene = scene
  }

  /**
   * 根据设备列表创建 3D 布局
   */
  createLayout(equipments: Equipment[]): void {
    // 创建设备模型
    for (const equipment of equipments) {
      const model = createEquipmentModel(
        this.scene,
        equipment.type,
        equipment.status
      )
      model.position = new Vector3(equipment.position.x, 0, equipment.position.z)
      model.name = `equipment-${equipment.id}`
      this.equipmentModels.set(equipment.id, model)

      // 添加设备标签（简化为小平面）
      this.createEquipmentLabel(equipment)
    }
  }

  /**
   * 更新设备位置
   */
  updateEquipmentPosition(
    equipmentId: string,
    position: { x: number; z: number }
  ): void {
    const model = this.equipmentModels.get(equipmentId)
    if (model) {
      model.position.x = position.x
      model.position.z = position.z
    }
  }

  /**
   * 创建 Lot 模型
   */
  createLotModel(lotId: string, position: Vector3): void {
    const lotMesh = MeshBuilder.CreateBox(
      `lot-${lotId}`,
      { width: 0.8, height: 0.2, depth: 0.8 },
      this.scene
    )
    const material = new StandardMaterial(`lot-mat-${lotId}`, this.scene)
    material.diffuseColor = new Color3(0, 0.73, 0.83)
    material.emissiveColor = new Color3(0, 0.3, 0.4)
    lotMesh.material = material
    lotMesh.position = new Vector3(position.x, 0.5, position.z)
    this.lotModels.set(lotId, lotMesh)
  }

  /**
   * 移动 Lot 模型
   */
  moveLotModel(lotId: string, targetPosition: Vector3): void {
    const lotMesh = this.lotModels.get(lotId)
    if (lotMesh) {
      lotMesh.position = new Vector3(targetPosition.x, 0.5, targetPosition.z)
    }
  }

  /**
   * 移除 Lot 模型
   */
  removeLotModel(lotId: string): void {
    const lotMesh = this.lotModels.get(lotId)
    if (lotMesh) {
      lotMesh.dispose()
      this.lotModels.delete(lotId)
    }
  }

  /**
   * 获取设备模型
   */
  getEquipmentModel(equipmentId: string): TransformNode | undefined {
    return this.equipmentModels.get(equipmentId)
  }

  /**
   * 更新设备状态
   */
  updateEquipmentState(equipmentId: string, status: Equipment['status']): void {
    const model = this.equipmentModels.get(equipmentId)
    if (model) {
      updateEquipmentStatus(model, status)
    }
  }

  private createEquipmentLabel(equipment: Equipment): void {
    // 简化标签实现 - 使用彩色小平面作为占位
    const label = MeshBuilder.CreatePlane(
      `label-${equipment.id}`,
      { width: 4, height: 0.8 },
      this.scene
    )
    const labelMat = new StandardMaterial(`label-mat-${equipment.id}`, this.scene)
    labelMat.diffuseColor = new Color3(1, 1, 1)
    labelMat.emissiveColor = new Color3(0.3, 0.3, 0.3)
    labelMat.disableLighting = true
    label.material = labelMat
    label.position = new Vector3(equipment.position.x, 6, equipment.position.z)
    label.billboardMode = Mesh.BILLBOARDMODE_ALL
  }
}
