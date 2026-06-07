import {
  Engine,
  Scene,
  ArcRotateCamera,
  HemisphericLight,
  DirectionalLight,
  ShadowGenerator,
  Vector3,
  Color3,
  Color4,

  MeshBuilder,
  StandardMaterial,

} from '@babylonjs/core'

/**
 * 场景配置
 */
export interface SceneConfig {
  /** 画布元素 */
  canvas: HTMLCanvasElement
  /** 背景色 */
  backgroundColor?: Color4
  /** 是否启用阴影 */
  enableShadows?: boolean
}

/**
 * Babylon.js 场景管理器
 */
export class SceneManager {
  readonly engine: Engine
  readonly scene: Scene
  readonly camera: ArcRotateCamera
  private shadowGenerator?: ShadowGenerator
  private renderCallbacks: Array<(delta: number) => void> = []

  constructor(config: SceneConfig) {
    const { canvas, backgroundColor, enableShadows = true } = config

    // Engine
    this.engine = new Engine(canvas, true, {
      preserveDrawingBuffer: true,
      stencil: true
    })

    // Scene
    this.scene = new Scene(this.engine)
    this.scene.clearColor = backgroundColor ?? new Color4(0.1, 0.1, 0.12, 1)

    // Camera
    this.camera = new ArcRotateCamera(
      'camera',
      -Math.PI / 4,
      Math.PI / 3,
      80,
      new Vector3(0, 0, 0),
      this.scene
    )
    this.camera.attachControl(canvas, true)
    this.camera.lowerRadiusLimit = 10
    this.camera.upperRadiusLimit = 200
    this.camera.wheelPrecision = 50

    // Lighting
    this.setupLighting(enableShadows)

    // Grid / Ground
    this.setupGround()

    // Resize handler
    window.addEventListener('resize', this.handleResize)

    // Start render loop
    this.engine.runRenderLoop(() => {
      const delta = this.engine.getDeltaTime() / 1000
      for (const callback of this.renderCallbacks) {
        callback(delta)
      }
      this.scene.render()
    })
  }

  /**
   * 添加渲染回调（每帧调用）
   */
  addRenderCallback(callback: (delta: number) => void): void {
    this.renderCallbacks.push(callback)
  }

  /**
   * 移除渲染回调
   */
  removeRenderCallback(callback: (delta: number) => void): void {
    const index = this.renderCallbacks.indexOf(callback)
    if (index !== -1) {
      this.renderCallbacks.splice(index, 1)
    }
  }

  /**
   * 销毁场景管理器
   */
  dispose(): void {
    window.removeEventListener('resize', this.handleResize)
    this.scene.dispose()
    this.engine.dispose()
  }

  private handleResize = (): void => {
    this.engine.resize()
  }

  private setupLighting(enableShadows: boolean): void {
    // Ambient light
    const hemiLight = new HemisphericLight(
      'hemiLight',
      new Vector3(0, 1, 0),
      this.scene
    )
    hemiLight.intensity = 0.6
    hemiLight.groundColor = new Color3(0.2, 0.2, 0.3)

    // Directional light (sun)
    const dirLight = new DirectionalLight(
      'dirLight',
      new Vector3(-1, -2, -1),
      this.scene
    )
    dirLight.position = new Vector3(50, 100, 50)
    dirLight.intensity = 0.8

    if (enableShadows) {
      this.shadowGenerator = new ShadowGenerator(2048, dirLight)
      this.shadowGenerator.useBlurExponentialShadowMap = true
      this.shadowGenerator.blurKernel = 32
    }
  }

  private setupGround(): void {
    const ground = MeshBuilder.CreateGround(
      'ground',
      { width: 200, height: 200, subdivisions: 2 },
      this.scene
    )
    const groundMat = new StandardMaterial('groundMat', this.scene)
    groundMat.diffuseColor = new Color3(0.16, 0.16, 0.24)
    groundMat.specularColor = new Color3(0.1, 0.1, 0.15)
    ground.material = groundMat
    ground.receiveShadows = true
    ground.position.y = -0.1

    // Grid lines
    this.createGridLines()
  }

  private createGridLines(): void {
    const gridSize = 200
    const divisions = 50
    const step = gridSize / divisions
    const halfSize = gridSize / 2

    const gridMat = new StandardMaterial('gridMat', this.scene)
    gridMat.emissiveColor = new Color3(0.15, 0.15, 0.2)
    gridMat.disableLighting = true
    gridMat.alpha = 0.5

    for (let i = 0; i <= divisions; i++) {
      const pos = -halfSize + i * step

      // X axis lines
      const lineX = MeshBuilder.CreateLines(
        `gridX-${i}`,
        {
          points: [
            new Vector3(pos, 0.01, -halfSize),
            new Vector3(pos, 0.01, halfSize)
          ]
        },
        this.scene
      )
      lineX.color = new Color3(0.2, 0.2, 0.3)

      // Z axis lines
      const lineZ = MeshBuilder.CreateLines(
        `gridZ-${i}`,
        {
          points: [
            new Vector3(-halfSize, 0.01, pos),
            new Vector3(halfSize, 0.01, pos)
          ]
        },
        this.scene
      )
      lineZ.color = new Color3(0.2, 0.2, 0.3)
    }
  }
}
