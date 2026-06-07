import {
  Mesh,
  MeshBuilder,
  Scene,
  StandardMaterial,
  Color3,
  Vector3,
  TransformNode
} from '@babylonjs/core'
import { EquipmentType, EquipmentStatus } from '@semi/core'

/**
 * 设备颜色配置
 */
const EQUIPMENT_COLORS: Record<EquipmentStatus, Color3> = {
  [EquipmentStatus.Idle]: new Color3(0.29, 0.68, 0.31),        // 绿色
  [EquipmentStatus.Loading]: new Color3(1, 0.6, 0),             // 橙色
  [EquipmentStatus.Processing]: new Color3(1, 0.92, 0.23),      // 黄色
  [EquipmentStatus.Unloading]: new Color3(1, 0.6, 0),           // 橙色
  [EquipmentStatus.Error]: new Color3(0.96, 0.26, 0.21),       // 红色
  [EquipmentStatus.Maintenance]: new Color3(0.62, 0.62, 0.62)  // 灰色
}

/**
 * 创建设备 3D 模型
 */
export function createEquipmentModel(
  scene: Scene,
  type: EquipmentType,
  status: EquipmentStatus = EquipmentStatus.Idle
): TransformNode {
  const root = new TransformNode(`equipment-root-${type}`, scene)
  const color = EQUIPMENT_COLORS[status]
  const material = new StandardMaterial(`eq-mat-${type}`, scene)
  material.diffuseColor = color
  material.specularColor = new Color3(0.3, 0.3, 0.3)
  material.roughness = 0.3

  switch (type) {
    case EquipmentType.Lithography:
      createLithographyModel(scene, root, material)
      break
    case EquipmentType.Etching:
      createEtchingModel(scene, root, material)
      break
    case EquipmentType.Deposition:
      createDepositionModel(scene, root, material)
      break
    case EquipmentType.Implantation:
      createImplantationModel(scene, root, material)
      break
    case EquipmentType.Cleaning:
      createCleaningModel(scene, root, material)
      break
    case EquipmentType.Inspection:
      createInspectionModel(scene, root, material)
      break
    case EquipmentType.Annealing:
      createAnnealingModel(scene, root, material)
      break
    default:
      createDefaultModel(scene, root, material)
  }

  // 添加状态指示灯
  const indicatorMat = new StandardMaterial('indicator-mat', scene)
  indicatorMat.emissiveColor = color
  indicatorMat.disableLighting = true
  const indicator = MeshBuilder.CreateSphere(
    'status-indicator',
    { diameter: 0.8 },
    scene
  )
  indicator.material = indicatorMat
  indicator.position = new Vector3(0, 4.5, 0)
  indicator.parent = root

  return root
}

/**
 * 更新设备状态颜色
 */
export function updateEquipmentStatus(
  root: TransformNode,
  status: EquipmentStatus
): void {
  const color = EQUIPMENT_COLORS[status]

  // 更新主体材质
  root.getChildMeshes().forEach((mesh) => {
    if (mesh.name === 'status-indicator') return
    if (mesh.material instanceof StandardMaterial) {
      mesh.material.diffuseColor = color
    }
  })

  // 更新指示灯
  const indicator = root.getChildren().find(
    (c) => c.name === 'status-indicator'
  ) as Mesh | undefined
  if (indicator && indicator.material instanceof StandardMaterial) {
    indicator.material.emissiveColor = color
  }
}

// ========== 各类型设备模型 ==========

function createLithographyModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 主体
  const body = MeshBuilder.CreateBox('body', { width: 6, height: 5, depth: 8 }, scene)
  body.material = material
  body.position = new Vector3(0, 2.5, 0)
  body.parent = root

  // 顶部组件
  const top = MeshBuilder.CreateBox('top', { width: 5, height: 1, depth: 6 }, scene)
  top.material = material
  top.position = new Vector3(0, 5.5, 0)
  top.parent = root

  // 镜头组件
  const lensMat = new StandardMaterial('lens-mat', scene)
  lensMat.diffuseColor = new Color3(0.8, 0.8, 0.8)
  lensMat.specularColor = new Color3(0.9, 0.9, 0.9)
  const lens = MeshBuilder.CreateCylinder('lens', { diameterTop: 2, diameterBottom: 3, height: 2 }, scene)
  lens.material = lensMat
  lens.position = new Vector3(0, 7, 0)
  lens.parent = root
}

function createEtchingModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 主体 - 圆柱形腔体
  const body = MeshBuilder.CreateCylinder('body', { diameter: 6, height: 5 }, scene)
  body.material = material
  body.position = new Vector3(0, 2.5, 0)
  body.parent = root

  // 顶部盖子
  const lid = MeshBuilder.CreateCylinder('lid', { diameter: 6.4, height: 0.5 }, scene)
  lid.material = material
  lid.position = new Vector3(0, 5.25, 0)
  lid.parent = root
}

function createDepositionModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 主体
  const body = MeshBuilder.CreateBox('body', { width: 4, height: 7, depth: 4 }, scene)
  body.material = material
  body.position = new Vector3(0, 3.5, 0)
  body.parent = root

  // 气体管道
  const pipeMat = new StandardMaterial('pipe-mat', scene)
  pipeMat.diffuseColor = new Color3(0.5, 0.5, 0.5)
  const pipe = MeshBuilder.CreateCylinder('pipe', { diameter: 0.6, height: 3 }, scene)
  pipe.material = pipeMat
  pipe.position = new Vector3(2.5, 5, 0)
  pipe.parent = root
}

function createImplantationModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 主体
  const body = MeshBuilder.CreateBox('body', { width: 8, height: 4, depth: 3 }, scene)
  body.material = material
  body.position = new Vector3(0, 2, 0)
  body.parent = root

  // 离子源
  const sourceMat = new StandardMaterial('source-mat', scene)
  sourceMat.diffuseColor = new Color3(0.4, 0.4, 0.4)
  const source = MeshBuilder.CreateCylinder('source', { diameterTop: 0, diameterBottom: 2, height: 2 }, scene)
  source.material = sourceMat
  source.position = new Vector3(-4.5, 3, 0)
  source.rotation.z = -Math.PI / 2
  source.parent = root
}

function createCleaningModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 主体
  const body = MeshBuilder.CreateBox('body', { width: 5, height: 4, depth: 5 }, scene)
  body.material = material
  body.position = new Vector3(0, 2, 0)
  body.parent = root

  // 水槽
  const tankMat = new StandardMaterial('tank-mat', scene)
  tankMat.diffuseColor = new Color3(0.13, 0.59, 0.95)
  tankMat.alpha = 0.6
  const tank = MeshBuilder.CreateBox('tank', { width: 4, height: 2, depth: 4 }, scene)
  tank.material = tankMat
  tank.position = new Vector3(0, 1, 0)
  tank.parent = root
}

function createInspectionModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 底座
  const base = MeshBuilder.CreateBox('base', { width: 4, height: 1, depth: 4 }, scene)
  base.material = material
  base.position = new Vector3(0, 0.5, 0)
  base.parent = root

  // 立柱
  const pillar = MeshBuilder.CreateBox('pillar', { width: 0.5, height: 4, depth: 0.5 }, scene)
  pillar.material = material
  pillar.position = new Vector3(-1.5, 2.5, -1.5)
  pillar.parent = root

  // 镜头臂
  const arm = MeshBuilder.CreateBox('arm', { width: 3, height: 0.3, depth: 0.3 }, scene)
  arm.material = material
  arm.position = new Vector3(0, 4, -1.5)
  arm.parent = root

  // 镜头
  const lensMat = new StandardMaterial('lens-mat', scene)
  lensMat.diffuseColor = new Color3(0.8, 0.8, 0.8)
  const lens = MeshBuilder.CreateCylinder('lens', { diameterTop: 0.3, diameterBottom: 1, height: 1.5 }, scene)
  lens.material = lensMat
  lens.position = new Vector3(1.5, 3, -1.5)
  lens.parent = root
}

function createAnnealingModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  // 主体
  const body = MeshBuilder.CreateBox('body', { width: 5, height: 4, depth: 6 }, scene)
  body.material = material
  body.position = new Vector3(0, 2, 0)
  body.parent = root

  // 烟囱
  const chimney = MeshBuilder.CreateCylinder('chimney', { diameter: 1, height: 3 }, scene)
  chimney.material = material
  chimney.position = new Vector3(0, 5.5, -2)
  chimney.parent = root
}

function createDefaultModel(
  scene: Scene,
  root: TransformNode,
  material: StandardMaterial
): void {
  const body = MeshBuilder.CreateBox('body', { width: 4, height: 4, depth: 4 }, scene)
  body.material = material
  body.position = new Vector3(0, 2, 0)
  body.parent = root
}
