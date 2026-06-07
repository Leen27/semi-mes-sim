import {
  Animation,
  TransformNode,
  Mesh,
  Vector3,
  Color3,
  StandardMaterial,
  Scene,
  EasingFunction,
  CubicEase,

  BackEase,
  ElasticEase
} from '@babylonjs/core'

/**
 * 动画类型
 */
export enum AnimationType {
  Move = 'move',
  Rotate = 'rotate',
  Scale = 'scale',
  Color = 'color'
}

/**
 * 缓动类型
 */
export enum EasingType {
  Linear = 'linear',
  EaseInOut = 'easeInOut',
  EaseOut = 'easeOut',
  EaseIn = 'easeIn',
  BackOut = 'backOut',
  ElasticOut = 'elasticOut'
}

/**
 * 动画定义
 */
export interface AnimationDef {
  target: TransformNode | Mesh
  type: AnimationType
  to: Vector3 | Color3
  duration: number // 毫秒
  easing?: EasingType
  onComplete?: () => void
}

/**
 * Babylon.js 动画系统封装
 */
export class AnimationSystem {
  private scene: Scene
  private activeAnimations: Map<string, Animation> = new Map()
  private idCounter = 0

  constructor(scene: Scene) {
    this.scene = scene
  }

  /**
   * 播放动画
   */
  play(def: AnimationDef): string {
    const id = `anim-${++this.idCounter}`

    let animation: Animation

    switch (def.type) {
      case AnimationType.Move:
        animation = this.createPositionAnimation(def)
        break
      case AnimationType.Rotate:
        animation = this.createRotationAnimation(def)
        break
      case AnimationType.Scale:
        animation = this.createScalingAnimation(def)
        break
      case AnimationType.Color:
        animation = this.createColorAnimation(def)
        break
      default:
        throw new Error(`Unknown animation type: ${def.type}`)
    }

    // 设置缓动函数
    const easingFunction = this.getEasingFunction(def.easing ?? EasingType.Linear)
    animation.setEasingFunction(easingFunction)

    // 播放动画
    const animatable = this.scene.beginDirectAnimation(
      def.target,
      [animation],
      0,
      def.duration,
      false,
      1,
      () => {
        this.activeAnimations.delete(id)
        def.onComplete?.()
      }
    )

    if (animatable) {
      this.activeAnimations.set(id, animation)
    }

    return id
  }

  /**
   * 停止动画
   */
  stop(id: string): void {
    this.scene.stopAnimation(this.activeAnimations.get(id))
    this.activeAnimations.delete(id)
  }

  /**
   * 停止目标对象的所有动画
   */
  stopByTarget(target: TransformNode | Mesh): void {
    this.scene.stopAnimation(target)
    for (const id of this.activeAnimations.keys()) {
      // 简化处理：无法直接关联 animation 和目标，通过其他方式清理
      this.activeAnimations.delete(id)
    }
  }

  /**
   * 是否有正在运行的动画
   */
  get isAnimating(): boolean {
    return this.scene.animatables.length > 0
  }

  private createPositionAnimation(def: AnimationDef): Animation {
    const anim = new Animation(
      'positionAnim',
      'position',
      60,
      Animation.ANIMATIONTYPE_VECTOR3,
      Animation.ANIMATIONLOOPMODE_CONSTANT
    )
    const toVec = def.to as Vector3
    anim.setKeys([
      { frame: 0, value: def.target.position.clone() },
      { frame: def.duration, value: toVec }
    ])
    return anim
  }

  private createRotationAnimation(def: AnimationDef): Animation {
    const anim = new Animation(
      'rotationAnim',
      'rotation',
      60,
      Animation.ANIMATIONTYPE_VECTOR3,
      Animation.ANIMATIONLOOPMODE_CONSTANT
    )
    const toVec = def.to as Vector3
    anim.setKeys([
      { frame: 0, value: def.target.rotation.clone() },
      { frame: def.duration, value: toVec }
    ])
    return anim
  }

  private createScalingAnimation(def: AnimationDef): Animation {
    const anim = new Animation(
      'scalingAnim',
      'scaling',
      60,
      Animation.ANIMATIONTYPE_VECTOR3,
      Animation.ANIMATIONLOOPMODE_CONSTANT
    )
    const toVec = def.to as Vector3
    anim.setKeys([
      { frame: 0, value: def.target.scaling.clone() },
      { frame: def.duration, value: toVec }
    ])
    return anim
  }

  private createColorAnimation(def: AnimationDef): Animation {
    const mesh = def.target as Mesh
    const anim = new Animation(
      'colorAnim',
      'material.diffuseColor',
      60,
      Animation.ANIMATIONTYPE_COLOR3,
      Animation.ANIMATIONLOOPMODE_CONSTANT
    )
    const toColor = def.to as Color3
    const mat = mesh.material as StandardMaterial | null
    const fromColor = mat?.diffuseColor?.clone() ?? new Color3(1, 1, 1)
    anim.setKeys([
      { frame: 0, value: fromColor },
      { frame: def.duration, value: toColor }
    ])
    return anim
  }

  private getEasingFunction(type: EasingType): EasingFunction {
    switch (type) {
      case EasingType.Linear:
        return new EasingFunction()
      case EasingType.EaseInOut: {
        const ease = new CubicEase()
        ease.setEasingMode(EasingFunction.EASINGMODE_EASEINOUT)
        return ease
      }
      case EasingType.EaseOut: {
        const ease = new CubicEase()
        ease.setEasingMode(EasingFunction.EASINGMODE_EASEOUT)
        return ease
      }
      case EasingType.EaseIn: {
        const ease = new CubicEase()
        ease.setEasingMode(EasingFunction.EASINGMODE_EASEIN)
        return ease
      }
      case EasingType.BackOut: {
        const ease = new BackEase(0.3)
        ease.setEasingMode(EasingFunction.EASINGMODE_EASEOUT)
        return ease
      }
      case EasingType.ElasticOut: {
        const ease = new ElasticEase()
        ease.setEasingMode(EasingFunction.EASINGMODE_EASEOUT)
        return ease
      }
      default:
        return new EasingFunction()
    }
  }
}
