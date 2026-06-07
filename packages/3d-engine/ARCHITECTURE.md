# @semi/3d-engine — 3D 引擎与资产

## 职责

Babylon.js 场景封装层。包含：
- Scene、Camera、Engine、Light 的生命周期管理
- 设备 3D 模型（基础几何体构建）
- 动画系统（由仿真事件驱动的 Babylon.js Animation）

## 目录结构

```
src/
├── scene/       # SceneManager、Camera、Engine 封装
├── assets/      # 设备模型工厂（光刻机、刻蚀机等基础几何体）
├── animation/   # 动画系统（设备状态色、Lot 移动动画）
└── index.ts     # 公共 API 导出
```

## 关键约束

- **禁止依赖 Vue**（仅使用纯 Babylon.js + TypeScript）
- 模型使用 `MeshBuilder` 创建基础几何体，**不引入外部 .glb/.gltf 文件**
- 所有 3D 对象必须设置 `name` 属性
- 动画必须支持：暂停、加速、回退
- 仅通过 `@semi/core` 的**类型**了解领域模型，不直接消费仿真引擎实例

## 对外接口

```typescript
// 主要导出（设计目标，待实现）
export { SceneManager }
export { EquipmentMeshFactory }
export { AnimationController }
```

## 变更影响检查清单

修改本包代码后，必须检查以下文档和依赖项：

- [ ] 本文件中的「对外接口」描述是否仍然准确
- [ ] SceneManager/AnimationController 的公共 API 变更是否同步到 `apps/web/ARCHITECTURE.md`
- [ ] 新增 3D 对象类型时，是否遵循「所有对象必须设置 name 属性」的约束

## 依赖

- `@babylonjs/core`、`@babylonjs/gui`
- `@semi/config`、`@semi/core`（仅类型）
