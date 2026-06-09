# 前端 UI 开发专家 — 最小原子任务清单

> 本文件是 `@semi/ui` 和 `apps/web` UI 层所有开发任务的唯一真实来源。
> **规则**: 每个任务必须是单一职责、独立验证、可回滚的原子单元。

---

## 任务状态图例

| 状态 | 图标 | 说明 |
|------|------|------|
| pending | ⏸ | 等待执行 |
| active | 🔄 | 正在执行 |
| passing | ✅ | 验证通过 |
| blocked | 🔒 | 依赖未满足 |

---

## Phase 0: 现有代码梳理（已完成）

> 以下任务在创建本 Agent 之前已由其他开发者完成：

| 任务 | 内容 | 状态 |
|------|------|------|
| U000-A | EquipmentCard.vue | ✅ passing |
| U000-B | SimulationPanel.vue | ✅ passing |
| U000-C | StatusBadge.vue | ✅ passing |
| U000-D | App.vue（基础布局） | ✅ passing |
| U000-E | index.d.ts（3 个组件） | ✅ passing |
| U000-F | index.ts（3 个导出） | ✅ passing |

---

## Phase 1: 样式系统基础设施

### U001 — TailwindCSS 引入与配置
```yaml
name: TailwindCSS 引入与配置
description: |
  在 packages/ui 中引入 TailwindCSS，配置半导体 MES 主题。
  这是所有后续组件样式的基础。
scope:
  do:
    - 安装 tailwindcss + postcss + autoprefixer
    - 创建 tailwind.config.js（含 MES 主题色）
    - 创建 postcss.config.js
    - 创建 src/styles/global.css（@tailwind directives）
    - 在 vite.config.ts 中配置 CSS 处理
    - 导出主题 token（colors, spacing, borderRadius）
    - 编写 tailwind.config.test.ts 验证配置
  dont:
    - 不创建具体组件
    - 不修改现有组件的 scoped CSS
files:
  - packages/ui/tailwind.config.js
  - packages/ui/postcss.config.js
  - packages/ui/src/styles/global.css
  - packages/ui/src/styles/tokens.ts
  - packages/ui/vite.config.ts  # 修改
dependencies: []
verification:
  - cmd: cd packages/ui && pnpm install
  - cmd: cd packages/ui && pnpm lint && pnpm type-check
  - cmd: cd packages/ui && pnpm build
    check:
      - 构建成功，CSS 包含 Tailwind 工具类
      - tokens.ts 可正确导入
status: pending
```

### U002 — 基础组件套件（Base）
```yaml
name: 基础组件套件 Button + Modal + Input
description: |
  创建基础组件套件，供上层业务组件使用。
  每个组件都是原子级的，无业务逻辑。
scope:
  do:
    - Button.vue（primary/secondary/danger/ghost 变体）
    - Modal.vue（弹窗容器，支持 Teleport + Transition）
    - Input.vue（文本输入，支持 v-model）
    - 同步更新 index.ts 导出
    - 同步更新 index.d.ts 类型声明
    - 编写基础组件单元测试
  dont:
    - 不包含业务逻辑
    - 不依赖 @semi/core
files:
  - packages/ui/src/components/base/Button.vue
  - packages/ui/src/components/base/Modal.vue
  - packages/ui/src/components/base/Input.vue
  - packages/ui/src/components/base/Button.test.ts
  - packages/ui/src/components/base/Modal.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check
  - cmd: cd packages/ui && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/base/
    check:
      - Button 渲染正确
      - Modal 打开/关闭动画正常
      - Input v-model 双向绑定正常
      - index.d.ts 包含新组件声明
status: pending
```

---

## Phase 2: 数据展示组件扩展

### U003 — LotItem 组件
```yaml
name: LotItem Lot 信息项组件
description: |
  创建 LotItem 组件，显示单个 Lot 的基本信息。
scope:
  do:
    - LotItem.vue 组件
    - Props: id, name, waferCount, status, currentStepName, priority, waitTime
    - 状态颜色映射（复用 StatusBadge 逻辑）
    - 优先级指示器
    - 等待时间显示
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不包含批量操作逻辑
    - 不直接调用仿真引擎
files:
  - packages/ui/src/components/data-display/LotItem.vue
  - packages/ui/src/components/data-display/LotItem.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
  - U000-C  # StatusBadge（已有）
  - @semi/core 的 LotStatus 类型
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check
  - cmd: cd packages/ui && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/data-display/LotItem.test.ts
    check:
      - 正确显示 Lot 信息
      - 状态颜色正确
      - 点击触发 click 事件
status: pending
```

### U004 — ProgressBar 组件
```yaml
name: ProgressBar 进度条组件
description: |
  创建 ProgressBar 组件，显示加工进度。
scope:
  do:
    - ProgressBar.vue 组件
    - Props: progress(0-100), label?, color?
    - 支持条纹动画（processing 状态）
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不计算进度（只接收 progress 数值）
files:
  - packages/ui/src/components/data-display/ProgressBar.vue
  - packages/ui/src/components/data-display/ProgressBar.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/data-display/ProgressBar.test.ts
    check:
      - 进度值正确映射到宽度
      - label 正确显示
status: pending
```

---

## Phase 3: 仿真控制组件（F008）

### U005 — SimulationControl 组件
```yaml
name: SimulationControl 仿真控制面板
description: |
  创建 F008 需求的 SimulationControl 组件。
  包含播放/暂停/加速/重置按钮，显示当前仿真时间。
scope:
  do:
    - SimulationControl.vue 组件
    - Props: isRunning, speed, speedOptions?
    - Events: @play, @pause, @reset, @set-speed
    - 播放/暂停按钮（图标切换）
    - 速度选择器（下拉或按钮组）
    - 重置按钮
    - 时间显示（复用 TimeDisplay 或内嵌）
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不直接操作仿真引擎（只发事件）
    - 不包含时间格式化逻辑（用 composable）
files:
  - packages/ui/src/components/simulation/SimulationControl.vue
  - packages/ui/src/components/simulation/SimulationControl.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
  - U002  # Button 组件
  - U006  # TimeDisplay 组件（如果先完成）
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/simulation/SimulationControl.test.ts
    check:
      - 点击播放触发 play 事件
      - 点击暂停触发 pause 事件
      - 速度切换触发 set-speed 事件
      - 时间正确显示
status: pending
```

### U006 — TimeDisplay 组件
```yaml
name: TimeDisplay 时间显示组件
description: |
  创建 TimeDisplay 组件，格式化显示仿真时间。
scope:
  do:
    - TimeDisplay.vue 组件
    - Props: seconds, format?
    - 格式支持：hms (HH:MM:SS), ms (MM:SS), full (含天)
    - 使用等宽字体显示
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不管理时间状态（只接收 seconds）
files:
  - packages/ui/src/components/simulation/TimeDisplay.vue
  - packages/ui/src/components/simulation/TimeDisplay.test.ts
  - packages/ui/src/composables/useTimeFormat.ts  # 提取复用逻辑
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/simulation/TimeDisplay.test.ts
    check:
      - 3600 秒显示为 01:00:00
      - 60 秒显示为 00:01:00
      - 不同 format 正确切换
status: pending
```

### U007 — EventLog 组件
```yaml
name: EventLog 事件日志组件
description: |
  创建 EventLog 组件，显示仿真事件列表。
scope:
  do:
    - EventLog.vue 组件
    - Props: events[], maxItems?
    - 事件类型颜色区分
    - 时间戳格式化
    - 自动滚动到底部（可选）
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不订阅事件源（只接收 events 数组）
files:
  - packages/ui/src/components/simulation/EventLog.vue
  - packages/ui/src/components/simulation/EventLog.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
  - U006  # TimeDisplay（可选，用于时间戳）
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/simulation/EventLog.test.ts
    check:
      - 事件列表正确渲染
      - 超出 maxItems 时截断
status: pending
```

---

## Phase 4: 设备详情与看板（F009, F010）

### U008 — EquipmentDetail 组件（F009）
```yaml
name: EquipmentDetail 设备详情弹窗
description: |
  创建 F009 需求的 EquipmentDetail 组件。
  点击设备显示详细信息：当前 Lot、Recipe、状态历史。
scope:
  do:
    - EquipmentDetail.vue 组件
    - Props: visible, equipment, currentLot?, currentRecipe?, statusHistory?
    - Events: @close, @command
    - 使用 Modal 作为容器（U002）
    - 设备基本信息区域
    - 当前 Lot 信息区域
    - 当前 Recipe 参数区域
    - 状态历史时间轴
    - 快捷操作按钮（Remote/Local/Start/Stop）
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不直接发送 GEM 指令（只发 command 事件）
    - 不修改设备状态
files:
  - packages/ui/src/components/dashboard/EquipmentDetail.vue
  - packages/ui/src/components/dashboard/EquipmentDetail.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
  - U002  # Modal + Button
  - U000-C  # StatusBadge
  - @semi/core 的 Equipment, Lot, Recipe 类型
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/dashboard/EquipmentDetail.test.ts
    check:
      - visible=true 时弹窗显示
      - 设备信息正确显示
      - 点击关闭触发 close 事件
      - 点击指令按钮触发 command 事件
status: pending
```

### U009 — WipDashboard 组件（F010）
```yaml
name: WipDashboard 在制品追踪看板
description: |
  创建 F010 需求的 WipDashboard 组件。
  实时显示所有在制品的位置和状态。
scope:
  do:
    - WipDashboard.vue 组件
    - Props: stats, lots, autoRefresh?, refreshInterval?
    - Events: @lot-click, @filter-change
    - 统计数字卡片（总 WIP / 等待中 / 加工中 / 已完成）
    - Lot 列表（复用 LotItem）
    - 筛选器（状态 / 区域 / 优先级）
    - 排序功能
    - 同步更新 index.ts + index.d.ts
    - 编写单元测试
  dont:
    - 不轮询数据（由父组件通过 props 传入）
    - 不直接调用仿真引擎
files:
  - packages/ui/src/components/dashboard/WipDashboard.vue
  - packages/ui/src/components/dashboard/WipDashboard.test.ts
  - packages/ui/src/index.ts  # 更新
  - packages/ui/index.d.ts  # 更新
dependencies:
  - U001  # TailwindCSS
  - U003  # LotItem
  - U002  # Input（筛选器）
  - @semi/core 的 Lot, WIPStatistics 类型
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/components/dashboard/WipDashboard.test.ts
    check:
      - 统计数据正确显示
      - Lot 列表正确渲染
      - 筛选器过滤正确
      - 点击 Lot 触发 lot-click 事件
status: pending
```

---

## Phase 5: Composables

### U010 — useEquipmentStatus + useTimeFormat
```yaml
name: Composables：useEquipmentStatus + useTimeFormat
description: |
  提取可复用的 Vue 逻辑到组合式函数。
scope:
  do:
    - useEquipmentStatus.ts（状态→颜色/标签/是否活跃）
    - useTimeFormat.ts（秒数→格式化字符串）
    - useListFilter.ts（列表筛选）
    - 同步更新 composables/index.ts 导出
    - 编写单元测试
  dont:
    - 不依赖 Vue 实例外的副作用
files:
  - packages/ui/src/composables/useEquipmentStatus.ts
  - packages/ui/src/composables/useTimeFormat.ts
  - packages/ui/src/composables/useListFilter.ts
  - packages/ui/src/composables/useEquipmentStatus.test.ts
  - packages/ui/src/composables/useTimeFormat.test.ts
  - packages/ui/src/composables/index.ts
  - packages/ui/src/index.ts  # 更新导出
dependencies:
  - @semi/core 的 EquipmentStatus 类型
verification:
  - cmd: cd packages/ui && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/ui && npx vitest run src/composables/
    check:
      - useEquipmentStatus 返回正确颜色
      - useTimeFormat 3600 → "01:00:00"
      - useListFilter 正确过滤
status: pending
```

---

## Phase 6: apps/web 页面集成

### U011 — App.vue 布局重构
```yaml
name: App.vue 布局重构与组件集成
description: |
  重构 apps/web/src/App.vue，集成新开发的 UI 组件。
scope:
  do:
    - 重构 App.vue 布局（响应式 Grid）
    - 集成 SimulationControl（替换/增强 SimulationPanel）
    - 集成 EquipmentDetail 弹窗
    - 集成 WipDashboard（可选面板）
    - 添加设备点击 → 打开 EquipmentDetail 的交互
    - 添加 3D 场景桥接（通过 Pinia Store）
    - 保持现有 FPS 计数和 3D Canvas
  dont:
    - 不修改 Pinia Store 逻辑（只使用已有接口）
    - 不修改 3D 引擎初始化代码
files:
  - apps/web/src/App.vue
  - apps/web/src/components/EquipmentList.vue  # 可能新增
  - apps/web/src/layouts/DefaultLayout.vue  # 可能新增
dependencies:
  - U005  # SimulationControl
  - U008  # EquipmentDetail
  - U009  # WipDashboard（可选）
  - @semi/ui 的所有新组件
verification:
  - cmd: cd apps/web && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd apps/web && pnpm dev  # 手动验证 UI 正常
    check:
      - 页面正常渲染
      - 控制按钮可点击
      - 弹窗正常打开/关闭
      - 3D Canvas 不受影响
status: pending
```

---

## Phase 7: 整合验证

### U012 — packages/ui 完整构建与类型检查
```yaml
name: packages/ui 完整构建验证
description: |
  验证所有新增组件的构建、类型检查和导出完整性。
scope:
  do:
    - 确认 index.ts 导出所有组件
    - 确认 index.d.ts 声明所有组件
    - 运行完整 lint + type-check + build + test
    - 验证无未使用的导入
    - 验证无类型错误
  dont:
    - 不修改组件代码（只验证）
files:
  - packages/ui/src/index.ts
  - packages/ui/index.d.ts
  - 所有 .vue 文件
  - 所有 .test.ts 文件
dependencies:
  - 所有前置任务
verification:
  - cmd: cd packages/ui && pnpm lint
  - cmd: cd packages/ui && pnpm type-check
  - cmd: cd packages/ui && pnpm build
  - cmd: cd packages/ui && pnpm test
    check:
      - lint 无错误
      - type-check 无错误
      - build 成功
      - 所有测试通过
      - dist/ 包含所有组件
status: pending
```

### U013 — 跨包集成验证
```yaml
name: 跨包集成验证
description: |
  验证 apps/web 能正确消费 @semi/ui 的新组件。
scope:
  do:
    - apps/web 中 import 所有新组件
    - 验证类型提示正确
    - 构建 apps/web
    - 启动开发服务器，手动验证关键交互
  dont:
    - 不修改 core 或 3d-engine 的代码
files:
  - apps/web/src/App.vue
dependencies:
  - U011  # App.vue 重构
  - U012  # ui 包构建通过
verification:
  - cmd: cd apps/web && pnpm lint && pnpm type-check && pnpm build
  - cmd: make check  # 项目级完整验证
    check:
      - 所有包的 lint 通过
      - 所有包的 type-check 通过
      - 所有包的构建通过
status: pending
```

---

## 任务依赖图

```
Phase 1 (样式基础设施):
  U001 (Tailwind) ──→ U002 (Base 组件)

Phase 2 (数据展示):
  U001 ──→ U003 (LotItem)
  U001 ──→ U004 (ProgressBar)

Phase 3 (仿真控制):
  U002 ──→ U005 (SimulationControl)
  U001 ──→ U006 (TimeDisplay)
  U001 ──→ U007 (EventLog)

Phase 4 (详情/看板):
  U002 ──→ U008 (EquipmentDetail)
  U003 ──→ U009 (WipDashboard)

Phase 5 (Composables):
  U001 ──→ U010 (Composables)

Phase 6 (应用集成):
  U005 ──→ U011 (App.vue)
  U008 ──→ U011
  U009 ──→ U011 (可选)

Phase 7 (验证):
  U011 ──→ U012 (UI 构建)
  U012 ──→ U013 (跨包集成)
```

---

## 当前状态汇总

| 阶段 | 任务数 | pending | active | passing | blocked |
|------|-------|---------|--------|---------|---------|
| Phase 0 现有代码 | 6 | 0 | 0 | 6 | 0 |
| Phase 1 样式基础设施 | 2 | 2 | 0 | 0 | 0 |
| Phase 2 数据展示 | 2 | 2 | 0 | 0 | 0 |
| Phase 3 仿真控制 | 3 | 3 | 0 | 0 | 0 |
| Phase 4 详情/看板 | 2 | 2 | 0 | 0 | 0 |
| Phase 5 Composables | 1 | 1 | 0 | 0 | 0 |
| Phase 6 应用集成 | 1 | 1 | 0 | 0 | 0 |
| Phase 7 验证 | 2 | 2 | 0 | 0 | 0 |
| **总计** | **13** | **13** | **0** | **6** | **0** |

---

## 与其他 Agent 的协作影响

当以下任务完成时，可能需要通知对应 Agent：

| 任务 | 影响 | 通知对象 |
|------|------|---------|
| U003 (LotItem) | 需要 LotStatus 类型 | @mes-expert |
| U008 (EquipmentDetail) | 需要 Equipment/Lot/Recipe 类型 | @mes-expert |
| U009 (WipDashboard) | 需要 WIPStatistics 类型 | @mes-expert |
| U011 (App.vue) | 3D 场景交互 | @3d-expert |

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次任务状态变更时更新状态汇总表
