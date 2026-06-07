# 编码规范

> **阅读时机**：编写或修改代码时。

## 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 文件（组件/类） | PascalCase | `EquipmentCard.vue` |
| 文件（工具/逻辑） | camelCase | `useSimulation.ts` |
| 类型/接口 | PascalCase，不加 I 前缀 | `Equipment`（不是 `IEquipment`） |
| 常量 | UPPER_SNAKE_CASE | `MAX_LOT_SIZE` |
| 枚举 | PascalCase | `EquipmentStatus.Idle` |
| 布尔属性 | is/has/should 前缀 | `isProcessing`, `hasError` |

## 文件组织

每个文件只做一件事：

- `.ts` → 纯逻辑/工具
- `.vue` → Vue 单文件组件
- `index.ts` → 仅用于导出，不实现逻辑

## 导入规则

- 使用 workspace 导入（`@semi/core`）而非相对路径（`../../core`）
- 类型导入使用 `import type`（`import type { Equipment } from '@semi/core'`）

## Vue 组件格式（ESLint 兼容）

```vue
<!-- ✅ 正确：多属性换行，自闭合标签 -->
<canvas
  ref="canvasRef"
  class="canvas-element"
/>

<!-- ❌ 错误：多属性在同一行 -->
<canvas ref="canvasRef" class="canvas-element"></canvas>
```

## 3D 开发规范（Babylon.js）

### 场景组织

- `scene/` 目录下管理 Scene、Camera、Engine、Light
- 使用 `SceneManager` 类封装 Babylon.js 场景生命周期
- 所有 3D 对象必须设置 `name` 属性，便于调试和交互

### 模型规范

- 设备模型使用 `MeshBuilder` 创建基础几何体（Box、Cylinder、Sphere）
- **避免外部模型文件**（`.glb`/`.gltf`），保持项目自包含
- 颜色使用 `Color3` / `StandardMaterial` 定义

### 动画系统

- 使用 Babylon.js 原生 `Animation` 类
- 动画由 `@semi/core` 的仿真事件驱动
- 所有动画必须**可暂停、可加速、可回退**
