# 3D 半导体工厂场景专家 — 技能定义

> 本文件定义 `@3d-expert` Agent 的详细技能、代码模式和最佳实践。
> 编写代码时以本文件为参考。

---

## 技能 1：Babylon.js 基础几何体建模

### 能力
使用 `MeshBuilder` 创建所有 3D 资产，不引入外部模型文件。

### 常用模式

```typescript
import {
  MeshBuilder,
  StandardMaterial,
  Color3,
  Color4,
  Vector3,
  TransformNode,
  Mesh
} from '@babylonjs/core'

// 模式 A：TransformNode 作为根节点，子 Mesh 组合成复杂模型
function createComplexModel(scene: Scene, id: string): TransformNode {
  const root = new TransformNode(`model-${id}`, scene)
  
  // 主体
  const body = MeshBuilder.CreateBox('body', { width: 4, height: 3, depth: 5 }, scene)
  body.material = createMaterial(scene, new Color3(0.5, 0.5, 0.5))
  body.parent = root
  
  // 顶部组件
  const top = MeshBuilder.CreateCylinder('top', { diameter: 2, height: 1 }, scene)
  top.position = new Vector3(0, 2, 0)
  top.parent = root
  
  return root
}

// 模式 B：共享材质（性能优化）
const materialCache = new Map<string, StandardMaterial>()

function getSharedMaterial(scene: Scene, name: string, color: Color3): StandardMaterial {
  const key = `${scene.uid}-${name}`
  if (!materialCache.has(key)) {
    const mat = new StandardMaterial(name, scene)
    mat.diffuseColor = color
    materialCache.set(key, mat)
  }
  return materialCache.get(key)!
}
```

### 约束
- 所有 Mesh 必须设置 `name` 属性
- 优先使用 `TransformNode` 作为组合根节点
- 相同材质复用，避免重复创建
- 静态对象调用 `freezeWorldMatrix()`

---

## 技能 2：场景图管理

### 能力
维护层级化的 3D 场景结构，支持快速查找和批量操作。

### 常用模式

```typescript
// 通过 name 查找场景中的对象
function findNodeByName(scene: Scene, name: string): TransformNode | null {
  return scene.getTransformNodeByName(name)
}

function findMeshByName(scene: Scene, name: string): Mesh | null {
  return scene.getMeshByName(name)
}

// 批量获取某类型的所有节点
function getNodesByPrefix(scene: Scene, prefix: string): TransformNode[] {
  return scene.transformNodes.filter(n => n.name.startsWith(prefix))
}

// 遍历子树
function traverseNode(node: TransformNode, callback: (n: TransformNode) => void): void {
  callback(node)
  for (const child of node.getChildren()) {
    if (child instanceof TransformNode) {
      traverseNode(child, callback)
    }
  }
}
```

---

## 技能 3：状态驱动的颜色/材质切换

### 能力
根据领域模型状态自动更新 3D 对象的视觉表现。

### 常用模式

```typescript
// 状态-颜色映射表
const STATUS_COLORS: Record<string, Color3> = {
  idle: new Color3(0.29, 0.68, 0.31),       // 绿色
  processing: new Color3(1, 0.92, 0.23),    // 黄色
  error: new Color3(0.96, 0.26, 0.21),      // 红色
  maintenance: new Color3(0.62, 0.62, 0.62) // 灰色
}

// 更新状态颜色（带动画过渡）
function updateStatusColor(
  root: TransformNode,
  status: string,
  animationSystem: AnimationSystem
): void {
  const targetColor = STATUS_COLORS[status] ?? STATUS_COLORS.idle
  
  root.getChildMeshes().forEach(mesh => {
    if (mesh.material instanceof StandardMaterial) {
      // 使用动画系统做颜色过渡
      animationSystem.play({
        target: mesh,
        type: AnimationType.Color,
        to: targetColor,
        duration: 300,
        easing: EasingType.EaseInOut
      })
    }
  })
}
```

---

## 技能 4：动态纹理与 GUI

### 能力
使用 Babylon.js GUI 创建悬浮信息面板和标签。

### 常用模式

```typescript
import { AdvancedDynamicTexture, TextBlock, Rectangle } from '@babylonjs/gui'

// 创建跟随设备的标签
function createFloatingLabel(
  scene: Scene,
  parent: TransformNode,
  text: string,
  options?: { bgColor?: string; textColor?: string }
): void {
  const plane = MeshBuilder.CreatePlane('label-plane', { width: 4, height: 1 }, scene)
  plane.parent = parent
  plane.position = new Vector3(0, 5, 0)
  plane.billboardMode = Mesh.BILLBOARDMODE_ALL
  
  const adt = AdvancedDynamicTexture.CreateForMesh(plane)
  
  const rect = new Rectangle()
  rect.width = 1
  rect.height = 1
  rect.color = options?.bgColor ?? 'white'
  rect.thickness = 1
  rect.background = 'rgba(0,0,0,0.7)'
  adt.addControl(rect)
  
  const textBlock = new TextBlock()
  textBlock.text = text
  textBlock.color = options?.textColor ?? 'white'
  textBlock.fontSize = 40
  rect.addControl(textBlock)
}

// 创建动态更新的看板（如 WIP 数量）
function createDynamicBoard(
  scene: Scene,
  position: Vector3,
  size: { width: number; height: number }
): { updateText: (text: string) => void; dispose: () => void } {
  const plane = MeshBuilder.CreatePlane('board', size, scene)
  plane.position = position
  plane.billboardMode = Mesh.BILLBOARDMODE_ALL
  
  const adt = AdvancedDynamicTexture.CreateForMesh(plane, size.width * 100, size.height * 100)
  
  const textBlock = new TextBlock()
  textBlock.color = 'white'
  textBlock.fontSize = 24
  adt.addControl(textBlock)
  
  return {
    updateText: (text: string) => { textBlock.text = text },
    dispose: () => { plane.dispose(); adt.dispose() }
  }
}
```

---

## 技能 5：路径动画与移动

### 能力
实现物体沿路径移动的动画效果。

### 常用模式

```typescript
import { Path3D, Animation } from '@babylonjs/core'

// 创建路径并沿路径移动
function animateAlongPath(
  scene: Scene,
  target: TransformNode,
  points: Vector3[],
  duration: number,
  onComplete?: () => void
): void {
  const path = new Path3D(points, new Vector3(0, 1, 0), true)
  
  const frameRate = 60
  const totalFrames = (duration / 1000) * frameRate
  
  const positionAnim = new Animation(
    'pathAnim',
    'position',
    frameRate,
    Animation.ANIMATIONTYPE_VECTOR3,
    Animation.ANIMATIONLOOPMODE_CONSTANT
  )
  
  const keys: { frame: number; value: Vector3 }[] = []
  for (let i = 0; i <= totalFrames; i++) {
    const t = i / totalFrames
    keys.push({
      frame: i,
      value: path.getPointAt(t)
    })
  }
  
  positionAnim.setKeys(keys)
  
  scene.beginDirectAnimation(
    target,
    [positionAnim],
    0,
    totalFrames,
    false,
    1,
    onComplete
  )
}
```

---

## 技能 6：粒子系统

### 能力
使用粒子系统实现数据流、故障效果等视觉特效。

### 常用模式

```typescript
import { ParticleSystem, Texture } from '@babylonjs/core'

// 创建数据流粒子效果
function createDataFlowParticles(
  scene: Scene,
  startPoint: Vector3,
  endPoint: Vector3,
  color: Color3,
  particleCount: number = 50
): ParticleSystem {
  const particleSystem = new ParticleSystem('dataFlow', particleCount, scene)
  
  // 粒子发射位置
  particleSystem.emitter = startPoint
  
  // 粒子朝向目标点移动
  const direction = endPoint.subtract(startPoint).normalize()
  particleSystem.direction1 = direction.scale(2)
  particleSystem.direction2 = direction.scale(3)
  
  // 粒子颜色
  particleSystem.color1 = new Color4(color.r, color.g, color.b, 1)
  particleSystem.color2 = new Color4(color.r, color.g, color.b, 0.5)
  particleSystem.colorDead = new Color4(0, 0, 0, 0)
  
  // 粒子参数
  particleSystem.minSize = 0.1
  particleSystem.maxSize = 0.3
  particleSystem.minLifeTime = 0.5
  particleSystem.maxLifeTime = 1.5
  particleSystem.emitRate = 30
  
  particleSystem.start()
  
  // 到达目标后停止
  const distance = Vector3.Distance(startPoint, endPoint)
  const duration = (distance / 5) * 1000 // 5 units/second
  
  setTimeout(() => {
    particleSystem.stop()
    setTimeout(() => particleSystem.dispose(), 2000)
  }, duration)
  
  return particleSystem
}
```

---

## 技能 7：性能优化

### 能力
使用 Babylon.js 提供的性能优化技术。

### 常用模式

```typescript
// ThinInstance：批量渲染相同几何体
function createInstancedEquipment(
  scene: Scene,
  templateMesh: Mesh,
  positions: Vector3[]
): Mesh {
  const masterMesh = templateMesh.clone('master')
  masterMesh.isVisible = false
  
  const matrices: Matrix[] = []
  for (const pos of positions) {
    const matrix = Matrix.Translation(pos.x, pos.y, pos.z)
    matrices.push(matrix)
  }
  
  masterMesh.thinInstanceAdd(matrices)
  return masterMesh
}

// LOD：远距离简化
function setupLOD(mesh: Mesh, scene: Scene): void {
  // Level 1: 简化模型（距离 30m）
  const simplified = MeshBuilder.CreateBox('lod1', { size: 2 }, scene)
  simplified.isVisible = false
  mesh.addLODLevel(30, simplified)
  
  // Level 2:  billboard（距离 80m）
  const billboard = MeshBuilder.CreatePlane('lod2', { size: 2 }, scene)
  billboard.isVisible = false
  mesh.addLODLevel(80, billboard)
}

// 冻结世界矩阵（静态对象）
function freezeStatic(mesh: Mesh): void {
  mesh.freezeWorldMatrix()
  mesh.isPickable = false // 如果不需点击
}

// 视锥剔除
function enableFrustumCulling(mesh: Mesh): void {
  mesh.alwaysSelectAsActiveMesh = false
}
```

---

## 技能 8：JSON 配置解析与验证

### 能力
解析和验证场景配置文件，提供友好的错误提示。

### 常用模式

```typescript
// 配置验证函数
function validateSceneConfig(config: unknown): SceneConfig {
  if (typeof config !== 'object' || config === null) {
    throw new Error('SceneConfig must be an object')
  }
  
  const c = config as Partial<SceneConfig>
  
  // 必需字段检查
  if (!c.version) throw new Error('SceneConfig.version is required')
  if (!c.fab) throw new Error('SceneConfig.fab is required')
  if (!Array.isArray(c.workAreas)) throw new Error('SceneConfig.workAreas must be an array')
  
  // 默认值填充
  return {
    version: c.version,
    fab: c.fab,
    workAreas: c.workAreas,
    mesSystems: c.mesSystems ?? [],
    layerCycle: c.layerCycle ?? { enabled: false, totalLayers: 1, baseProcess: [] },
    environment: {
      backgroundColor: '#1a1a2e',
      ...c.environment
    }
  } as SceneConfig
}

// 增量配置更新（热更新）
function mergeConfig(
  current: SceneConfig,
  update: Partial<SceneConfig>
): SceneConfig {
  return {
    ...current,
    ...update,
    workAreas: update.workAreas ?? current.workAreas,
    mesSystems: update.mesSystems ?? current.mesSystems
  }
}
```

---

## 技能 9：测试模式

### 能力
为 3D 模块编写单元测试（不依赖真实渲染）。

### 常用模式

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { NullEngine, Scene } from '@babylonjs/core'

// 使用 NullEngine 进行无头测试
describe('AssetFactory', () => {
  let engine: NullEngine
  let scene: Scene
  
  beforeEach(() => {
    engine = new NullEngine()
    scene = new Scene(engine)
  })
  
  afterEach(() => {
    scene.dispose()
    engine.dispose()
  })
  
  it('should create buffer model with correct name', () => {
    const factory = new AssetFactory()
    const model = factory.create(scene, {
      id: 'buf-01',
      type: 'buffer',
      position: new Vector3(0, 0, 0),
      metadata: { capacity: 10 }
    })
    
    expect(model.name).toBe('model-buf-01')
    expect(scene.getTransformNodeByName('model-buf-01')).toBe(model)
  })
  
  it('should update buffer fill visualization', () => {
    const bufferViz = new BufferVisualization(scene, 'buf-01')
    
    bufferViz.updateFill(3, 10) // 3/10 filled
    
    expect(bufferViz.getFillRatio()).toBe(0.3)
    // 验证材质颜色变化...
  })
})
```

---

## 技能 10：错误处理与调试

### 能力
优雅处理 3D 场景中的错误，提供有用的调试信息。

### 常用模式

```typescript
// 带上下文的错误
class SceneBuildError extends Error {
  constructor(
    message: string,
    public readonly context: { module: string; configId?: string }
  ) {
    super(`[SceneBuilder::${context.module}] ${message}`)
    this.name = 'SceneBuildError'
  }
}

// 安全获取节点
function safeGetNode<T extends Node>(
  scene: Scene,
  name: string,
  type: new (...args: unknown[]) => T
): T {
  const node = scene.getNodeByName(name)
  if (!node) {
    throw new SceneBuildError(`Node "${name}" not found`, { module: 'SceneGraph' })
  }
  if (!(node instanceof type)) {
    throw new SceneBuildError(
      `Node "${name}" is not of type ${type.name}`,
      { module: 'SceneGraph' }
    )
  }
  return node as T
}

// 场景诊断信息
function dumpSceneInfo(scene: Scene): string {
  return `
Scene Info:
  - Meshes: ${scene.meshes.length}
  - TransformNodes: ${scene.transformNodes.length}
  - Materials: ${scene.materials.length}
  - Animations: ${scene.animations.length}
  - ParticleSystems: ${scene.particleSystems.length}
  
Top-level nodes:
${scene.rootNodes.map(n => `  - ${n.name} (${n.getClassName()})`).join('\n')}
  `
}
```

---

## 附录：快速代码模板

### 新模块模板

```typescript
// src/[module]/[feature].ts

import { Scene, TransformNode, Vector3 } from '@babylonjs/core'

/**
 * [功能描述]
 */
export interface [Feature]Config {
  id: string
  // ...
}

/**
 * [类描述]
 */
export class [Feature] {
  private scene: Scene
  
  constructor(scene: Scene) {
    this.scene = scene
  }
  
  /**
   * [方法描述]
   */
  create(config: [Feature]Config): TransformNode {
    // 实现
  }
  
  /**
   * 更新状态
   */
  update(id: string, state: unknown): void {
    // 实现
  }
  
  /**
   * 销毁
   */
  dispose(): void {
    // 实现
  }
}
```

### 新测试模板

```typescript
// src/[module]/[feature].test.ts

import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { NullEngine, Scene } from '@babylonjs/core'
import { [Feature] } from './[feature]'

describe('[Feature]', () => {
  let engine: NullEngine
  let scene: Scene
  let feature: [Feature]
  
  beforeEach(() => {
    engine = new NullEngine()
    scene = new Scene(engine)
    feature = new [Feature](scene)
  })
  
  afterEach(() => {
    scene.dispose()
    engine.dispose()
  })
  
  it('should [测试描述]', () => {
    // 测试代码
  })
})
```
