# AGENTS.md - Semi-MES-Sim 智能体操作手册

> 本文件是 Harness Engineering 的核心基础设施。
> 任何在此仓库工作的 AI 智能体都必须阅读并遵守本手册。

## 项目背景

**Semi-MES-Sim** 是一个半导体制造执行系统（MES）的 3D 仿真平台。

半导体晶圆厂（Fab）是世界上最复杂的制造环境之一：
- 数百台精密设备（光刻机、刻蚀机、薄膜沉积设备等）
- 数千个晶圆批次（Lot）在不同工艺步骤间流转
- 严格的工艺配方（Recipe）和调度策略

本项目通过 3D 可视化 + 离散事件仿真（DES），让用户能够：
1. **直观观察** 晶圆厂的运行状态
2. **验证调度算法** 在虚拟环境中的效果
3. **培训操作人员** 理解 MES 系统的运作逻辑

## 仓库结构

```
semi-mes-sim/
├── AGENTS.md              ← 你正在阅读的文件
├── init.sh                ← 一键自举脚本
├── feature_list.json      ← 功能清单与进度
├── apps/
│   └── web/               ← 3D 仿真主应用（Vite + Vue3 + Three.js）
│       ├── src/scenes/    ← 3D 场景定义
│       ├── src/components/← UI 组件
│       ├── src/stores/    ← Pinia 状态管理
│       └── src/types/     ← Web 应用类型
├── packages/
│   ├── @semi/config/      ← 共享配置（TS、ESLint、Vite）
│   ├── @semi/core/        ← MES 核心领域逻辑（纯 TypeScript）
│   ├── @semi/3d-engine/   ← Three.js 封装与 3D 资产
│   └── @semi/ui/          ← 共享 Vue UI 组件库
```

### 目录职责边界

| 目录 | 职责 | 禁止事项 |
|------|------|----------|
| `apps/web` | 主应用入口、页面布局、3D 画布挂载 | 不能包含可复用的领域逻辑 |
| `packages/@semi/core` | MES 领域模型、仿真引擎、算法 | 不能依赖 Vue、Three.js 等 UI 库 |
| `packages/@semi/3d-engine` | Three.js 场景、相机、模型、动画 | 不能依赖 Vue |
| `packages/@semi/ui` | 可复用 Vue 组件 | 不能依赖 apps/web |
| `packages/@semi/config` | 共享配置文件 | 不能依赖任何业务包 |

## 架构约束（强制）

### 依赖方向规则
在每个业务领域内，代码只能"向前"依赖：

```
Types → Config → Repo → Service → Runtime → UI
```

横切关注点（认证、遥测、配置）通过单一显式接口进入：**Providers**。

### 包间依赖规则
```
apps/web ──depends-on──► packages/@semi/core
         ──depends-on──► packages/@semi/3d-engine
         ──depends-on──► packages/@semi/ui
         ──depends-on──► packages/@semi/config

packages/@semi/ui ──depends-on──► packages/@semi/config

packages/@semi/3d-engine ──depends-on──► packages/@semi/config
                          ──depends-on──► packages/@semi/core (仅类型)

packages/@semi/core ──depends-on──► packages/@semi/config
```

**核心包 `@semi/core` 必须是纯 TypeScript，不能依赖任何 UI 库。**

## 编码规范

### 命名约定
- **文件**: PascalCase 用于组件/类（`EquipmentCard.vue`），camelCase 用于工具（`useSimulation.ts`）
- **类型/接口**: PascalCase，前缀不加 I（`Equipment` 而非 `IEquipment`）
- **常量**: UPPER_SNAKE_CASE（`MAX_LOT_SIZE`）
- **枚举**: PascalCase（`EquipmentStatus.Idle`）
- **布尔属性**: 前缀 is/has/should（`isProcessing`, `hasError`）

### 文件组织
每个文件只做一件事：
- `.ts` → 纯逻辑/工具
- `.vue` → Vue 单文件组件
- `index.ts` → 仅用于导出，不实现逻辑

### 导入规则
- 使用绝对导入（`@semi/core`）而非相对路径（`../../core`）
- 类型导入使用 `import type`（`import type { Equipment } from '@semi/core'`）

## 3D 开发规范

### 场景组织
- `scenes/` 目录下每个文件对应一个逻辑场景
- 使用 `SceneManager` 类封装 Three.js 场景生命周期
- 所有 3D 对象必须设置 `name` 属性，便于调试和交互

### 模型规范
- 设备模型使用基础几何体组合（Box、Cylinder、Sphere）
- 避免外部模型文件（gltf/obj），保持项目自包含
- 颜色使用常量定义，统一视觉风格

### 动画系统
- 动画由 `@semi/core` 的仿真事件驱动
- 使用 Tween 或自定义动画系统，避免直接操作 Three.js 动画循环
- 所有动画必须可暂停、可加速、可回退

## 工作流

### 添加新功能的步骤
1. 在 `feature_list.json` 中找到对应功能，确认状态为 `todo`
2. 在正确的包和目录中实现代码
3. 确保类型检查通过：`pnpm type-check`
4. 确保 Lint 通过：`pnpm lint`
5. 更新 `feature_list.json` 状态为 `done`
6. 提交代码

### 遇到问题的处理
- 如果架构约束阻止你实现功能，不要绕过约束
- 先修改架构文档（本文件），再调整代码
- 如果必须引入新依赖，在 AGENTS.md 中记录理由

## 关键术语

| 术语 | 说明 |
|------|------|
| **Lot** | 晶圆批次，MES 中流转的基本单位 |
| **Equipment** | 生产设备，如光刻机（Litho）、刻蚀机（Etcher） |
| **Recipe** | 工艺配方，定义设备加工参数 |
| **ProcessStep** | 工艺步骤，Lot 需要经过的单个工序 |
| **WIP** | 在制品（Work In Process） |
| **DES** | 离散事件仿真（Discrete Event Simulation） |
| **Fab** | 晶圆厂（Fabrication Plant） |

## 版本历史

- v1.0.0 - 初始版本，项目初始化时创建
