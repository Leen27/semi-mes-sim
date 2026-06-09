# 前端 UI 开发专家 — UI 架构设计文档

> 版本：v1.0 | 日期：2026-06-07
> 适用范围：`packages/ui` + `apps/web` 的 UI 层
> 技术栈：Vue 3 + TailwindCSS + TypeScript

---

## 1. 系统定位

### 1.1 分层架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         用户界面层                                │
│                                                                  │
│   ┌────────────────────────┐    ┌────────────────────────┐     │
│   │    @semi/ui            │    │    apps/web            │     │
│   │   (可复用组件库)        │    │   (应用页面)            │     │
│   │                        │    │                        │     │
│   │ • 通用/业务组件         │    │ • 页面布局              │     │
│   │ • Composables          │    │ • 路由视图              │     │
│   │ • 样式系统             │    │ • 状态绑定 (Pinia)      │     │
│   │ • 类型声明             │    │ • 3D 场景桥接           │     │
│   └────────────────────────┘    └────────────────────────┘     │
│            │                              │                     │
│            └──────────────┬───────────────┘                     │
│                           │                                      │
│              Vue 3 + TailwindCSS + TypeScript                   │
└─────────────────────────────────────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
      @semi/core (类型)        Pinia Store (状态)
```

### 1.2 包间关系

| 包 | 角色 | 对 @semi/ui 的使用方式 |
|----|------|----------------------|
| `apps/web` | 消费者 | `import { Xxx } from '@semi/ui'` |
| `@semi/core` | 类型提供 | `@semi/ui` 导入类型 |
| `@semi/3d-engine` | 无直接关系 | `apps/web` 桥接两者 |

### 1.3 核心原则

- **单一职责**：每个组件只做一件事
- **Props 向下，Events 向上**：单向数据流
- **可复用优先**：可复用的逻辑放 `packages/ui`
- **暗色主题**：所有组件默认暗色风格
- **Tailwind 优先**：样式优先使用 Tailwind 工具类

---

## 2. 组件体系

### 2.1 组件分类

```
packages/ui/src/components/
│
├── base/                    # 基础组件（原子级，无业务逻辑）
│   ├── Button.vue
│   ├── Input.vue
│   ├── Select.vue
│   ├── Modal.vue
│   ├── Tooltip.vue
│   └── Loading.vue
│
├── data-display/            # 数据展示（业务相关，纯展示）
│   ├── EquipmentCard.vue    # ✅ 已有
│   ├── LotItem.vue
│   ├── StatusBadge.vue      # ✅ 已有
│   ├── ProgressBar.vue
│   └── DataTable.vue
│
├── feedback/                # 反馈（弹窗、提示）
│   ├── Alert.vue
│   ├── Toast.vue
│   └── ConfirmDialog.vue
│
├── navigation/              # 导航
│   ├── Sidebar.vue
│   ├── Tabs.vue
│   └── Breadcrumb.vue
│
├── simulation/              # 仿真专用组件
│   ├── SimulationPanel.vue  # ✅ 已有
│   ├── SimulationControl.vue # F008 需求
│   ├── TimeDisplay.vue
│   ├── SpeedSlider.vue
│   └── EventLog.vue
│
└── dashboard/               # 看板/监控
    ├── WipDashboard.vue     # F010 需求
    ├── OeeCard.vue
    └── SchedulerInfo.vue
```

### 2.2 组件依赖规则

```
base/ ←────┬────┬────┬────┬────┐
           │    │    │    │    │
data-display/   │    │    │    │
feedback/      │    │    │    │
navigation/    │    │    │    │
simulation/    │    │    │    │
dashboard/     │    │    │    │
               │    │    │    │
               ▼    ▼    ▼    ▼
            所有上层可依赖下层
            下层不可依赖上层
```

---

## 3. 组件详细设计

### 3.1 基础组件（base/）

#### Button.vue

```typescript
interface Props {
  /** 按钮类型 */
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost'
  /** 尺寸 */
  size?: 'sm' | 'md' | 'lg'
  /** 是否禁用 */
  disabled?: boolean
  /** 是否加载中 */
  loading?: boolean
}

interface Emits {
  click: [event: MouseEvent]
}

// Slots: default (按钮文字/内容), icon (图标)
```

#### Modal.vue

```typescript
interface Props {
  /** 是否可见 */
  visible: boolean
  /** 标题 */
  title: string
  /** 点击遮罩是否关闭 */
  closeOnOverlay?: boolean
  /** 是否显示关闭按钮 */
  showClose?: boolean
}

interface Emits {
  close: []
  confirm: []
}

// Slots: default (内容), footer (底部按钮区)
```

### 3.2 数据展示组件（data-display/）

#### EquipmentCard.vue（已有）

```typescript
import type { Equipment, EquipmentStatus } from '@semi/core'

interface Props {
  /** 设备名称 */
  name: string
  /** 设备类型 */
  type: string
  /** 设备状态 */
  status: string
  /** 当前 Lot ID */
  currentLotId?: string
  /** 加工能力 */
  throughput: number
}

interface Emits {
  /** 点击卡片 */
  click: [equipmentId: string]
}
```

#### LotItem.vue

```typescript
import type { Lot, LotStatus } from '@semi/core'

interface Props {
  /** Lot ID */
  id: string
  /** Lot 名称 */
  name: string
  /** 晶圆数量 */
  waferCount: number
  /** 当前状态 */
  status: LotStatus
  /** 当前步骤名称 */
  currentStepName?: string
  /** 优先级 */
  priority: number
  /** 等待时间（秒） */
  waitTime?: number
}

interface Emits {
  click: [lotId: string]
}
```

#### StatusBadge.vue（已有）

```typescript
interface Props {
  /** 状态值 */
  status: string
  /** 尺寸 */
  size?: 'sm' | 'md' | 'lg'
}
```

### 3.3 仿真组件（simulation/）

#### SimulationPanel.vue（已有）

```typescript
interface Props {
  /** 当前仿真时间（秒） */
  currentTime: number
  /** 仿真速度倍率 */
  speed: number
  /** 是否运行中 */
  isRunning: boolean
  /** 设备总数 */
  equipmentCount: number
  /** Lot 总数 */
  lotCount: number
  /** 已完成 Lot 数 */
  completedCount: number
}

interface Emits {
  start: []
  pause: []
  reset: []
  speedChange: [speed: number]
}
```

#### SimulationControl.vue（F008 需求）

```typescript
interface Props {
  /** 是否运行中 */
  isRunning: boolean
  /** 当前速度 */
  speed: number
  /** 可用速度选项 */
  speedOptions?: number[]
}

interface Emits {
  /** 开始/继续 */
  play: []
  /** 暂停 */
  pause: []
  /** 重置 */
  reset: []
  /** 设置速度 */
  setSpeed: [speed: number]
}
```

#### TimeDisplay.vue

```typescript
interface Props {
  /** 时间（秒） */
  seconds: number
  /** 格式 */
  format?: 'hms' | 'ms' | 'full'
}
```

### 3.4 看板组件（dashboard/）

#### WipDashboard.vue（F010 需求）

```typescript
import type { Lot, WIPStatistics } from '@semi/core'

interface Props {
  /** WIP 统计 */
  stats: WIPStatistics
  /** Lot 列表 */
  lots: Lot[]
  /** 是否自动刷新 */
  autoRefresh?: boolean
  /** 刷新间隔（秒） */
  refreshInterval?: number
}

interface Emits {
  /** 点击 Lot */
  lotClick: [lotId: string]
  /** 筛选变化 */
  filterChange: [filter: WipFilter]
}

interface WipFilter {
  status?: string
  workArea?: string
  priority?: number
}
```

#### EquipmentDetail.vue（F009 需求）

```typescript
import type { Equipment, Lot, Recipe } from '@semi/core'

interface Props {
  /** 是否可见 */
  visible: boolean
  /** 设备信息 */
  equipment: Equipment | null
  /** 当前加工 Lot */
  currentLot?: Lot
  /** 当前 Recipe */
  currentRecipe?: Recipe
  /** 状态历史 */
  statusHistory?: Array<{ time: number; status: string }>
}

interface Emits {
  close: []
  command: [command: string]
}
```

---

## 4. 组合式函数设计

### 4.1 Composables 目录

```
packages/ui/src/composables/
├── index.ts
├── useEquipmentStatus.ts     # 设备状态辅助
├── useTimeFormat.ts          # 时间格式化
├── useListFilter.ts          # 列表筛选
├── usePagination.ts          # 分页
├── useModal.ts               # 弹窗控制
├── useToast.ts               # Toast 提示
└── useTheme.ts               # 主题（暗/亮）
```

### 4.2 详细设计

```typescript
// useEquipmentStatus.ts
export function useEquipmentStatus(status: EquipmentStatus) {
  const color = computed(() => { ... })
  const label = computed(() => { ... })
  const isActive = computed(() => { ... })
  return { color, label, isActive }
}

// useTimeFormat.ts
export function useTimeFormat(seconds: number) {
  const formatted = computed(() => { ... })
  const hours = computed(() => { ... })
  const minutes = computed(() => { ... })
  return { formatted, hours, minutes }
}

// useListFilter.ts
export function useListFilter<T>(
  items: Ref<T[]>,
  searchFields: (keyof T)[]
) {
  const filterText = ref('')
  const filtered = computed(() => { ... })
  return { filterText, filtered }
}

// useModal.ts
export function useModal() {
  const visible = ref(false)
  const open = () => { visible.value = true }
  const close = () => { visible.value = false }
  return { visible, open, close }
}

// useToast.ts
export function useToast() {
  const toasts = ref<Toast[]>([])
  const show = (message: string, type?: ToastType) => { ... }
  const remove = (id: string) => { ... }
  return { toasts, show, remove }
}
```

---

## 5. 样式系统设计

### 5.1 设计 Token

```typescript
// packages/ui/src/styles/tokens.ts

export const colors = {
  // 背景
  bg: {
    primary: '#0f0f1e',
    secondary: '#1e1e2e',
    tertiary: '#2a2a3e',
    overlay: 'rgba(0, 0, 0, 0.7)'
  },
  // 边框
  border: {
    DEFAULT: '#333',
    hover: '#555',
    active: '#777'
  },
  // 文字
  text: {
    primary: '#fff',
    secondary: '#ccc',
    muted: '#888',
    disabled: '#666'
  },
  // 设备状态
  status: {
    idle: '#4caf50',
    processing: '#ffeb3b',
    loading: '#ff9800',
    error: '#f44336',
    maintenance: '#9e9e9e',
    waiting: '#2196f3',
    completed: '#9c27b0',
    onHold: '#795548'
  },
  // 功能色
  accent: {
    primary: '#00bcd4',
    success: '#4caf50',
    warning: '#ff9800',
    danger: '#f44336'
  }
}

export const spacing = {
  xs: '4px',
  sm: '8px',
  md: '12px',
  lg: '16px',
  xl: '24px',
  xxl: '32px'
}

export const borderRadius = {
  sm: '4px',
  md: '8px',
  lg: '12px',
  xl: '16px',
  full: '9999px'
}

export const fontSize = {
  xs: '10px',
  sm: '12px',
  md: '14px',
  lg: '16px',
  xl: '18px',
  xxl: '24px'
}
```

### 5.2 Tailwind 预设

```typescript
// tailwind.config.js
export default {
  content: [
    './src/**/*.{vue,ts,js}',
    '../../apps/web/src/**/*.{vue,ts,js}'
  ],
  theme: {
    extend: {
      colors: {
        'semi-bg': {
          DEFAULT: '#0f0f1e',
          light: '#1e1e2e',
          lighter: '#2a2a3e'
        },
        'semi-border': {
          DEFAULT: '#333',
          hover: '#555'
        },
        'semi-text': {
          primary: '#fff',
          secondary: '#ccc',
          muted: '#888'
        },
        'status-idle': '#4caf50',
        'status-processing': '#ffeb3b',
        'status-error': '#f44336',
        'status-maintenance': '#9e9e9e',
        'status-waiting': '#2196f3'
      },
      fontFamily: {
        mono: ['"Courier New"', 'monospace']
      }
    }
  }
}
```

### 5.3 全局样式

```css
/* packages/ui/src/styles/global.css */

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    background: #0f0f1e;
    color: #fff;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
  }

  /* 滚动条样式 */
  ::-webkit-scrollbar {
    width: 6px;
    height: 6px;
  }

  ::-webkit-scrollbar-track {
    background: transparent;
  }

  ::-webkit-scrollbar-thumb {
    background: #444;
    border-radius: 3px;
  }

  ::-webkit-scrollbar-thumb:hover {
    background: #555;
  }
}

@layer components {
  .panel {
    @apply bg-semi-bg-light border border-semi-border rounded-lg p-4;
  }

  .card {
    @apply bg-semi-bg-light border border-semi-border rounded-lg p-3 transition-all;
  }

  .card:hover {
    @apply border-semi-border-hover;
  }
}
```

---

## 6. 应用布局设计

### 6.1 apps/web 页面结构

```
apps/web/src/
├── main.ts                  # 入口
├── App.vue                  # 根布局
├── router/                  # 路由（如有需要）
│   └── index.ts
├── views/                   # 页面视图
│   ├── SimulationView.vue   # 仿真主页面
│   └── DashboardView.vue    # 看板页面
├── layouts/                 # 布局模板
│   └── DefaultLayout.vue    # 默认布局
├── stores/                  # Pinia Store（已有）
│   └── simulation.ts
├── components/              # 页面级组件（非复用）
│   └── EquipmentList.vue    # 设备列表容器
└── assets/                  # 静态资源
    └── icons/
```

### 6.2 App.vue 布局

```vue
<template>
  <div class="app-layout">
    <!-- 左侧边栏 -->
    <aside class="sidebar">
      <SimulationPanel ... />
      <div class="equipment-list-container">
        <h4>设备列表</h4>
        <EquipmentList ... />
      </div>
    </aside>

    <!-- 中央 3D 画布 -->
    <main class="main-content">
      <canvas ref="canvasRef" />
    </main>

    <!-- 右侧信息面板（可选） -->
    <aside v-if="showDetailPanel" class="detail-panel">
      <EquipmentDetail ... />
    </aside>

    <!-- 底部状态栏 -->
    <footer class="status-bar">
      <span>Semi-MES-Sim v0.0.1</span>
      <span>FPS: {{ fps }}</span>
    </footer>
  </div>
</template>
```

### 6.3 响应式断点

| 断点 | 宽度 | 布局变化 |
|------|------|---------|
| Desktop | >1280px | 完整三栏布局 |
| Laptop | 1024-1280px | 侧边栏 250px |
| Tablet | 768-1024px | 隐藏右侧面板 |
| Mobile | <768px | 侧边栏变为底部抽屉 |

---

## 7. 类型声明维护

### 7.1 index.d.ts 结构

```typescript
// packages/ui/index.d.ts

import type { DefineComponent } from 'vue'

// ===== Base Components =====
declare const Button: DefineComponent<{
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  loading?: boolean
}>

declare const Modal: DefineComponent<{
  visible: boolean
  title: string
  closeOnOverlay?: boolean
  showClose?: boolean
}>

// ===== Data Display =====
declare const EquipmentCard: DefineComponent<{
  name: string
  type: string
  status: string
  currentLotId?: string
  throughput: number
}>

declare const StatusBadge: DefineComponent<{
  status: string
  size?: 'sm' | 'md' | 'lg'
}>

declare const LotItem: DefineComponent<{
  id: string
  name: string
  waferCount: number
  status: string
  currentStepName?: string
  priority: number
  waitTime?: number
}>

// ===== Simulation =====
declare const SimulationPanel: DefineComponent<{
  currentTime: number
  speed: number
  isRunning: boolean
  equipmentCount: number
  lotCount: number
  completedCount: number
}>

declare const SimulationControl: DefineComponent<{
  isRunning: boolean
  speed: number
  speedOptions?: number[]
}>

// ===== Dashboard =====
declare const WipDashboard: DefineComponent<{
  stats: { total: number; waiting: number; processing: number; completed: number }
  lots: Array<{ id: string; name: string; status: string }>
  autoRefresh?: boolean
  refreshInterval?: number
}>

declare const EquipmentDetail: DefineComponent<{
  visible: boolean
  equipment: { id: string; name: string; type: string; status: string } | null
  currentLot?: { id: string; name: string }
}>

export {
  Button, Modal,
  EquipmentCard, StatusBadge, LotItem,
  SimulationPanel, SimulationControl,
  WipDashboard, EquipmentDetail
}
```

### 7.2 维护规则

| 操作 | index.d.ts 动作 | index.ts 动作 |
|------|----------------|---------------|
| 新增组件 | 添加 declare + export | 添加 export |
| 删除组件 | 删除 declare + export | 删除 export |
| 新增 Props | 添加字段到 interface | 无需修改 |
| 删除 Props | 删除字段 | 无需修改 |
| 修改 Props 类型 | 更新类型 | 无需修改 |
| 重命名组件 | 同步重命名 | 同步重命名 |

---

## 8. 文件结构规划

```
packages/ui/src/
├── components/
│   ├── base/
│   │   ├── Button.vue
│   │   ├── Input.vue
│   │   ├── Select.vue
│   │   ├── Modal.vue
│   │   ├── Tooltip.vue
│   │   └── Loading.vue
│   ├── data-display/
│   │   ├── EquipmentCard.vue       # ✅ 已有
│   │   ├── LotItem.vue
│   │   ├── StatusBadge.vue         # ✅ 已有
│   │   ├── ProgressBar.vue
│   │   └── DataTable.vue
│   ├── feedback/
│   │   ├── Alert.vue
│   │   ├── Toast.vue
│   │   └── ConfirmDialog.vue
│   ├── navigation/
│   │   ├── Sidebar.vue
│   │   ├── Tabs.vue
│   │   └── Breadcrumb.vue
│   ├── simulation/
│   │   ├── SimulationPanel.vue     # ✅ 已有
│   │   ├── SimulationControl.vue   # F008
│   │   ├── TimeDisplay.vue
│   │   ├── SpeedSlider.vue
│   │   └── EventLog.vue
│   └── dashboard/
│       ├── WipDashboard.vue        # F010
│       ├── OeeCard.vue
│       └── SchedulerInfo.vue
│
├── composables/
│   ├── index.ts
│   ├── useEquipmentStatus.ts
│   ├── useTimeFormat.ts
│   ├── useListFilter.ts
│   ├── usePagination.ts
│   ├── useModal.ts
│   ├── useToast.ts
│   └── useTheme.ts
│
├── styles/
│   ├── index.ts
│   ├── global.css
│   ├── tokens.ts
│   └── animations.css
│
└── index.ts                        # 组件导出

apps/web/src/
├── main.ts
├── App.vue                         # 根布局
├── router/
│   └── index.ts
├── views/
│   ├── SimulationView.vue
│   └── DashboardView.vue
├── layouts/
│   └── DefaultLayout.vue
├── stores/
│   └── simulation.ts               # ✅ 已有
├── components/
│   └── EquipmentList.vue           # 页面级容器
└── assets/
    └── icons/
```

---

## 9. 对外 API（最终导出）

```typescript
// packages/ui/src/index.ts

// Base
export { default as Button } from './components/base/Button.vue'
export { default as Input } from './components/base/Input.vue'
export { default as Modal } from './components/base/Modal.vue'

// Data Display
export { default as EquipmentCard } from './components/data-display/EquipmentCard.vue'
export { default as LotItem } from './components/data-display/LotItem.vue'
export { default as StatusBadge } from './components/data-display/StatusBadge.vue'
export { default as ProgressBar } from './components/data-display/ProgressBar.vue'

// Feedback
export { default as Alert } from './components/feedback/Alert.vue'
export { default as Toast } from './components/feedback/Toast.vue'

// Navigation
export { default as Sidebar } from './components/navigation/Sidebar.vue'
export { default as Tabs } from './components/navigation/Tabs.vue'

// Simulation
export { default as SimulationPanel } from './components/simulation/SimulationPanel.vue'
export { default as SimulationControl } from './components/simulation/SimulationControl.vue'
export { default as TimeDisplay } from './components/simulation/TimeDisplay.vue'
export { default as SpeedSlider } from './components/simulation/SpeedSlider.vue'
export { default as EventLog } from './components/simulation/EventLog.vue'

// Dashboard
export { default as WipDashboard } from './components/dashboard/WipDashboard.vue'
export { default as OeeCard } from './components/dashboard/OeeCard.vue'
export { default as EquipmentDetail } from './components/dashboard/EquipmentDetail.vue'

// Composables
export { useEquipmentStatus } from './composables/useEquipmentStatus'
export { useTimeFormat } from './composables/useTimeFormat'
export { useListFilter } from './composables/useListFilter'
export { useModal } from './composables/useModal'
export { useToast } from './composables/useToast'
```

---

## 10. 与 feature_list.json 的映射

| Feature ID | 名称 | UI 组件 | 位置 |
|-----------|------|---------|------|
| F005 | Web 主应用界面 | App.vue（已有） | apps/web |
| F008 | 仿真控制面板 | SimulationControl.vue | packages/ui |
| F009 | 设备详情弹窗 | EquipmentDetail.vue | packages/ui |
| F010 | WIP 追踪看板 | WipDashboard.vue | packages/ui |

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次新增/修改组件时更新
