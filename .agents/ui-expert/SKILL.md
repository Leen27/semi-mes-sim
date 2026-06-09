# 前端 UI 开发专家 — 技能定义

> 本文件定义 `@ui-expert` Agent 的详细技能、代码模式和最佳实践。
> 编写 Vue/TailwindCSS 代码时以本文件为参考。

---

## 技能 1：Vue 3 组件设计

### 能力
使用 Vue 3 Composition API + `<script setup>` 设计可复用、类型安全的组件。

### 组件设计原则

```vue
<!-- ✅ 好的组件：单一职责、类型安全、自文档化 -->
<template>
  <div class="equipment-card" :class="statusClass">
    <div class="equipment-header">
      <span class="equipment-name">{{ name }}</span>
      <StatusBadge :status="status" />
    </div>
    <div class="equipment-body">
      <slot name="extra" />
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * EquipmentCard — 设备信息卡片
 *
 * @example
 * <EquipmentCard
 *   name="光刻机-01"
 *   type="lithography"
 *   status="processing"
 *   :throughput="60"
 * />
 */
import { computed } from 'vue'
import StatusBadge from './StatusBadge.vue'

// ===== Props 定义 =====
interface Props {
  /** 设备名称 */
  name: string
  /** 设备类型 */
  type: string
  /** 设备状态 */
  status: string
  /** 当前加工 Lot ID */
  currentLotId?: string
  /** 加工能力（晶圆/小时） */
  throughput: number
}

const props = defineProps<Props>()

// ===== 事件定义 =====
const emit = defineEmits<{
  /** 点击卡片时触发 */
  click: [equipmentId: string]
  /** 状态变更请求 */
  statusChange: [status: string]
}>()

// ===== 计算属性 =====
const statusClass = computed(() => ({
  'status-idle': props.status === 'idle',
  'status-processing': props.status === 'processing',
  'status-error': props.status === 'error'
}))

// ===== 方法 =====
function handleClick() {
  emit('click', props.name)
}
</script>
```

### Props 设计检查清单

- [ ] 每个 prop 都有 JSDoc 注释说明
- [ ] 必填/可选明确（`?` 标记可选）
- [ ] 有合理的默认值（使用 `withDefaults`）
- [ ] 类型精确（不用 `any`）
- [ ] 从 `@semi/core` 导入业务类型（如 `EquipmentType`）

### 事件命名规范

```typescript
// ✅ 好的事件命名
const emit = defineEmits<{
  click: [id: string]           // 点击
  update: [value: string]       // 更新（配合 v-model）
  change: [value: string]       // 值变化
  submit: [data: FormData]      // 提交
  close: []                     // 关闭
  open: []                      // 打开
}>()

// ❌ 避免的事件命名
const emit = defineEmits<{
  doSomething: []      // 太模糊
  handleClick: []       // 像回调函数名
  onUpdate: []          // 不需要 on 前缀
}>()
```

---

## 技能 2：TailwindCSS 样式系统

### 能力
使用 TailwindCSS 工具类构建一致的视觉系统。

### 当前状态

项目尚未引入 TailwindCSS。引入后将使用 Tailwind 替代大部分 scoped CSS。

### 引入计划

```bash
# 待执行（由需求触发）
cd packages/ui && pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

### Tailwind 配置

```typescript
// tailwind.config.js (packages/ui)
export default {
  content: [
    './src/**/*.{vue,ts,js}',
    '../apps/web/src/**/*.{vue,ts,js}'
  ],
  theme: {
    extend: {
      // 半导体 MES 主题色
      colors: {
        'semi-bg': {
          DEFAULT: '#0f0f1e',
          light: '#1e1e2e',
          lighter: '#2a2a3e'
        },
        'semi-border': '#333',
        'semi-text': {
          primary: '#fff',
          secondary: '#ccc',
          muted: '#888'
        },
        // 设备状态色
        'status': {
          idle: '#4caf50',
          processing: '#ffeb3b',
          error: '#f44336',
          maintenance: '#9e9e9e',
          waiting: '#2196f3'
        }
      },
      fontFamily: {
        mono: ['"Courier New"', 'monospace']
      }
    }
  }
}
```

### 样式编写模式

```vue
<!-- 模式 A：纯 Tailwind（推荐） -->
<template>
  <div class="bg-semi-bg-light border border-semi-border rounded-lg p-3 mb-2">
    <div class="flex justify-between items-center mb-2">
      <span class="font-semibold text-sm text-white">{{ name }}</span>
      <StatusBadge :status="status" />
    </div>
  </div>
</template>

<!-- 模式 B：Tailwind + scoped CSS（复杂样式时） -->
<template>
  <div class="equipment-card">
    <!-- ... -->
  </div>
</template>

<style scoped>
/* 只有 Tailwind 无法表达的复杂样式才用 scoped CSS */
.equipment-card {
  /* 复杂动画、伪元素等 */
}
</style>
```

### 暗色主题优先

本项目是暗色主题 UI。所有组件默认暗色：

```css
/* 全局基础样式 */
html {
  background: #0f0f1e;
  color: #fff;
}
```

---

## 技能 3：组件分类体系

### 能力
按职责将组件分类，保持清晰的架构。

### 组件分类

```
packages/ui/src/components/
│
├── base/                    # 基础组件（原子级）
│   ├── Button.vue           # 按钮
│   ├── Input.vue            # 输入框
│   ├── Select.vue           # 选择器
│   ├── Modal.vue            # 弹窗容器
│   ├── Tooltip.vue          # 提示
│   └── Loading.vue          # 加载
│
├── data-display/            # 数据展示
│   ├── EquipmentCard.vue    # 设备卡片
│   ├── LotItem.vue          # Lot 项
│   ├── StatusBadge.vue      # 状态标签
│   ├── ProgressBar.vue      # 进度条
│   └── DataTable.vue        # 数据表格
│
├── feedback/                # 反馈
│   ├── Alert.vue            # 警告提示
│   ├── Toast.vue            # 轻提示
│   └── ConfirmDialog.vue    # 确认对话框
│
├── navigation/              # 导航
│   ├── Sidebar.vue          # 侧边栏
│   ├── Tabs.vue             # 标签页
│   └── Breadcrumb.vue       # 面包屑
│
├── simulation/              # 仿真专用
│   ├── SimulationPanel.vue  # 仿真面板
│   ├── SimulationControl.vue # 控制按钮组
│   ├── TimeDisplay.vue      # 时间显示
│   └── SpeedSlider.vue      # 速度滑块
│
└── dashboard/               # 看板
    ├── WipDashboard.vue     # WIP 看板
    ├── OeeCard.vue          # OEE 卡片
    └── EventLog.vue         # 事件日志
```

### 组件依赖规则

```
基础组件 (base/) ← 被所有上层组件依赖
数据展示 (data-display/) ← 可依赖 base/
反馈 (feedback/) ← 可依赖 base/
导航 (navigation/) ← 可依赖 base/
仿真专用 (simulation/) ← 可依赖 base/ + data-display/
看板 (dashboard/) ← 可依赖所有下层
```

**禁止**：下层组件依赖上层组件（如 `base/Button.vue` 不能 import `dashboard/OeeCard.vue`）

---

## 技能 4：组合式函数（Composables）

### 能力
提取可复用的 Vue 逻辑到组合式函数。

### 常用 Composables

```typescript
// src/composables/useEquipmentStatus.ts

import { computed } from 'vue'
import { EquipmentStatus } from '@semi/core'

export function useEquipmentStatus(status: EquipmentStatus) {
  const color = computed(() => {
    switch (status) {
      case EquipmentStatus.Idle: return 'text-status-idle'
      case EquipmentStatus.Processing: return 'text-status-processing'
      case EquipmentStatus.Error: return 'text-status-error'
      default: return 'text-status-maintenance'
    }
  })

  const label = computed(() => {
    const map: Record<string, string> = {
      idle: '空闲',
      processing: '加工中',
      error: '故障'
    }
    return map[status] || status
  })

  const isActive = computed(() => 
    status === EquipmentStatus.Processing
  )

  return { color, label, isActive }
}
```

```typescript
// src/composables/useTimeFormat.ts

import { computed } from 'vue'

export function useTimeFormat(seconds: number) {
  const formatted = computed(() => {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    const s = Math.floor(seconds % 60)
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
  })

  return { formatted }
}
```

```typescript
// src/composables/useListFilter.ts

import { ref, computed } from 'vue'

export function useListFilter<T>(items: T[], filterKey: keyof T) {
  const filterText = ref('')
  
  const filtered = computed(() => {
    if (!filterText.value) return items
    const lower = filterText.value.toLowerCase()
    return items.filter(item => 
      String(item[filterKey]).toLowerCase().includes(lower)
    )
  })

  return { filterText, filtered }
}
```

---

## 技能 5：状态与父组件通信

### 能力
正确处理组件状态，通过 props/events 与父组件通信。

### 数据流规则

```
┌─────────────────────────────────────────┐
│           单向数据流                      │
│                                         │
│   Parent                                │
│     │  :prop="value"                    │
│     ▼                                   │
│   Child (只读 props)                     │
│     │  @event="update"                  │
│     ▼                                   │
│   Parent (更新状态)                      │
│                                         │
│   ❌ Child 禁止直接修改 props           │
│   ✅ Child 通过 emit 请求父组件修改      │
└─────────────────────────────────────────┘
```

### v-model 模式

```vue
<!-- 子组件 -->
<script setup lang="ts">
interface Props {
  modelValue: string
}
const props = defineProps<Props>()
const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

function handleInput(e: Event) {
  emit('update:modelValue', (e.target as HTMLInputElement).value)
}
</script>

<!-- 父组件 -->
<template>
  <SearchInput v-model="searchText" />
</template>
```

### Provide / Inject（深层传递）

```typescript
// 祖先组件
import { provide, readonly } from 'vue'

const simulationState = readonly(store.state)
provide('simulationState', simulationState)

// 后代组件
import { inject } from 'vue'

const state = inject('simulationState')
```

---

## 技能 6：响应式布局

### 能力
使用 CSS Grid / Flexbox + Tailwind 实现响应式布局。

### 应用布局

```vue
<!-- apps/web/src/App.vue -->
<template>
  <div class="app-layout">
    <!-- 侧边栏 -->
    <aside class="sidebar" :class="{ collapsed: isSidebarCollapsed }">
      <SimulationPanel />
      <EquipmentList />
    </aside>
    
    <!-- 主内容区 -->
    <main class="main-content">
      <canvas ref="canvasRef" />
    </main>
    
    <!-- 底部状态栏 -->
    <footer class="status-bar">
      <span>Semi-MES-Sim</span>
      <span>FPS: {{ fps }}</span>
    </footer>
  </div>
</template>

<style scoped>
.app-layout {
  display: grid;
  grid-template-columns: 300px 1fr;
  grid-template-rows: 1fr 32px;
  grid-template-areas:
    'sidebar main'
    'status status';
  width: 100vw;
  height: 100vh;
}

.sidebar {
  grid-area: sidebar;
}

.sidebar.collapsed {
  width: 48px;
}

.main-content {
  grid-area: main;
}

.status-bar {
  grid-area: status;
}

/* 移动端适配 */
@media (max-width: 768px) {
  .app-layout {
    grid-template-columns: 1fr;
    grid-template-rows: auto 1fr 32px;
    grid-template-areas:
      'sidebar'
      'main'
      'status';
  }
}
</style>
```

---

## 技能 7：弹窗/浮层设计

### 能力
实现弹窗、下拉菜单、tooltip 等浮层组件。

```vue
<!-- Modal.vue -->
<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="visible" class="modal-overlay" @click="handleOverlayClick">
        <div class="modal-content" @click.stop>
          <header class="modal-header">
            <h3>{{ title }}</h3>
            <button class="close-btn" @click="close">×</button>
          </header>
          <div class="modal-body">
            <slot />
          </div>
          <footer class="modal-footer">
            <slot name="footer">
              <button class="btn btn-primary" @click="confirm">确认</button>
              <button class="btn btn-secondary" @click="close">取消</button>
            </slot>
          </footer>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
interface Props {
  visible: boolean
  title: string
  closeOnOverlay?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  closeOnOverlay: true
})

const emit = defineEmits<{
  close: []
  confirm: []
}>()

function handleOverlayClick() {
  if (props.closeOnOverlay) close()
}

function close() { emit('close') }
function confirm() { emit('confirm') }
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #1e1e2e;
  border: 1px solid #333;
  border-radius: 8px;
  min-width: 400px;
  max-width: 90vw;
}

/* Transition */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>
```

---

## 技能 8：测试模式

### 能力
为 Vue 组件编写单元测试。

```typescript
// components/StatusBadge.test.ts
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import StatusBadge from './StatusBadge.vue'

describe('StatusBadge', () => {
  it('renders correct text for idle status', () => {
    const wrapper = mount(StatusBadge, {
      props: { status: 'idle' }
    })
    expect(wrapper.text()).toBe('空闲')
    expect(wrapper.classes()).toContain('badge-idle')
  })

  it('renders correct text for processing status', () => {
    const wrapper = mount(StatusBadge, {
      props: { status: 'processing' }
    })
    expect(wrapper.text()).toBe('加工中')
    expect(wrapper.classes()).toContain('badge-processing')
  })

  it('renders fallback for unknown status', () => {
    const wrapper = mount(StatusBadge, {
      props: { status: 'unknown' }
    })
    expect(wrapper.text()).toBe('unknown')
  })
})
```

```typescript
// components/EquipmentCard.test.ts
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import EquipmentCard from './EquipmentCard.vue'

describe('EquipmentCard', () => {
  it('emits click event with name', async () => {
    const wrapper = mount(EquipmentCard, {
      props: {
        name: 'Litho-01',
        type: 'lithography',
        status: 'idle',
        throughput: 60
      }
    })
    
    await wrapper.find('.equipment-card').trigger('click')
    
    expect(wrapper.emitted('click')).toBeTruthy()
    expect(wrapper.emitted('click')![0]).toEqual(['Litho-01'])
  })
})
```

---

## 技能 9：与 3D 场景协作

### 能力
在不直接操作 3D 引擎的情况下，实现 UI 与 3D 场景的联动。

### 正确模式

```vue
<!-- ❌ 错误：UI 组件直接操作 3D 场景 -->
<script setup>
// 禁止在 UI 组件中直接 import Babylon.js
import { SceneManager } from '@semi/3d-engine' // ❌
const scene = new SceneManager(...) // ❌
</script>

<!-- ✅ 正确：通过 props/events 与父组件通信 -->
<template>
  <div class="equipment-list">
    <EquipmentCard
      v-for="eq in equipments"
      :key="eq.id"
      :name="eq.name"
      :status="eq.status"
      @click="handleEquipmentClick(eq.id)"
    />
  </div>
</template>

<script setup lang="ts">
import type { Equipment } from '@semi/core'

interface Props {
  equipments: Equipment[]
}

defineProps<Props>()

const emit = defineEmits<{
  /** 点击设备时触发（由 apps/web 桥接到 3D 场景） */
  'equipment-click': [equipmentId: string]
}>()

function handleEquipmentClick(id: string) {
  emit('equipment-click', id)
}
</script>
```

### apps/web 中的桥接

```vue
<!-- apps/web/src/App.vue -->
<template>
  <aside class="sidebar">
    <!-- UI 组件只发事件 -->
    <EquipmentList
      :equipments="simulationStore.equipments"
      @equipment-click="focusCameraOnEquipment"
    />
  </aside>
  <main>
    <canvas ref="canvasRef" />
  </main>
</template>

<script setup>
// 3D 场景操作只在 apps/web 中进行
function focusCameraOnEquipment(equipmentId) {
  const model = fabLayout.getEquipmentModel(equipmentId)
  sceneManager.camera.setTarget(model.position)
}
</script>
```

---

## 附录：新组件模板

### 基础组件模板

```vue
<template>
  <div class="component-name">
    <!-- 模板内容 -->
  </div>
</template>

<script setup lang="ts">
/**
 * 组件名称
 * 功能描述
 *
 * @example
 * <ComponentName prop="value" @event="handler" />
 */

interface Props {
  /** 描述 */
  propName: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  /** 事件描述 */
  eventName: [payload: string]
}>()
</script>

<style scoped>
/* 仅补充 Tailwind 无法表达的样式 */
</style>
```

### 新增组件完整流程

1. 创建 `.vue` 文件
2. 定义 Props 接口 + 事件
3. 实现模板 + 逻辑
4. 编写样式（Tailwind 为主）
5. **同步更新 `index.d.ts`**
6. **同步更新 `src/index.ts`**
7. 编写单元测试
8. 运行验证命令

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
