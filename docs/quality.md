# 质量文档（Quality Document）

> 规则来源：Maintain a Quality Document
>
> 本文档是**主动 artifact**，持续记录每个模块的质量评级。不是一次性评估，而是跟踪代码库是变强还是变弱的追踪器。
> 
> **更新时机**：每次功能达到 `passing` 时更新对应模块；每月第一周进行全量审查。

---

## 质量评级定义

| 评级 | 含义 | 行动建议 |
|------|------|----------|
| **A** | 优秀 | 无需干预，可作为其他模块的标杆 |
| **B** | 良好 | 轻微改进空间，不阻塞新功能 |
| **C** | 需关注 | 存在可修复的问题，应在下个清理循环中处理 |
| **D** | 不合格 | 严重问题，新功能开发前应优先修复 |

## 评分维度

每个模块从五个维度评估：

1. **验证通过率** — 该模块的 verificationCommand 历史通过比例
2. **Agent 可理解性** — 代码结构是否清晰，新会话能否快速理解
3. **测试稳定性** — 测试是否 flaky，是否覆盖主流程 + 边界情况
4. **架构合规性** — 是否遵守 AGENTS.md 的架构边界
5. **代码规范遵循度** — 命名、注释、文件组织是否符合 coding-standards.md

---

## 模块质量矩阵

### @semi/core — MES 核心领域逻辑

| 维度 | 评级 | 说明 |
|------|------|------|
| 验证通过率 | A | 23/23 测试通过，EventQueue 和 SimulationEngine 测试稳定 |
| Agent 可理解性 | A | 纯 TypeScript，无框架依赖，领域模型清晰 |
| 测试稳定性 | B | 已有单元测试，但缺少边界情况覆盖（如空队列、极大时间值） |
| 架构合规性 | A | 纯 TypeScript，无 Vue/Babylon.js 依赖 |
| 代码规范遵循度 | A | 命名一致，类型定义完整 |
| **综合评级** | **A** | |

**已知问题**：
- `simulation-engine.ts` 的 `processEvent()` 是 TODO(F004) — 不影响 core 包自身质量，但阻塞下游功能

---

### @semi/3d-engine — 3D 引擎与资产

| 维度 | 评级 | 说明 |
|------|------|------|
| 验证通过率 | B | lint + type-check + build 通过，但**无单元测试** |
| Agent 可理解性 | B | Babylon.js API 调用密集，需要一定 3D 图形学背景 |
| 测试稳定性 | D | **无任何测试** — 3d-engine 是完全的测试盲区 |
| 架构合规性 | A | 纯 Babylon.js + TypeScript，无 Vue 依赖 |
| 代码规范遵循度 | A | MeshBuilder 使用规范，所有对象有 name 属性 |
| **综合评级** | **C** | |

**已知问题**：
- 测试覆盖是最大短板（D 级）。SceneManager、AnimationSystem、FabLayout 均无测试
- 建议优先级：为 SceneManager 生命周期和 AnimationSystem 状态机添加单元测试

---

### @semi/ui — 共享 Vue UI 组件库

| 维度 | 评级 | 说明 |
|------|------|------|
| 验证通过率 | B | lint + type-check + build 通过，但**无单元测试** |
| Agent 可理解性 | A | Vue 单文件组件，<script setup> 格式统一 |
| 测试稳定性 | D | **无任何测试** |
| 架构合规性 | A | 独立的组件库，不依赖 apps/web |
| 代码规范遵循度 | A | 组件命名规范，index.d.ts 已维护 |
| **综合评级** | **C** | |

**已知问题**：
- 测试覆盖缺失（D 级）
- 当前组件数量少，随着组件增加需要引入组件测试（Vitest + Vue Test Utils）

---

### @semi/web — 主应用

| 维度 | 评级 | 说明 |
|------|------|------|
| 验证通过率 | B | lint + type-check + build 通过，但**无单元测试** |
| Agent 可理解性 | B | App.vue 逻辑较复杂（3D 场景初始化 + store 绑定 + FPS 计数） |
| 测试稳定性 | D | **无任何测试** |
| 架构合规性 | A | 正确消费 core/3d-engine/ui，无反向依赖 |
| 代码规范遵循度 | A | Vue SFC 格式规范，Pinia store 组织良好 |
| **综合评级** | **C** | |

**已知问题**：
- 测试覆盖缺失（D 级）
- App.vue 的 `onMounted` 逻辑较重，可考虑抽取为组合式函数
- F005 的依赖声明包含 F004（仿真引擎），但 F004 尚未 passing — 这是初始化阶段遗留的技术债务

---

### 基础设施 / 配置

| 维度 | 评级 | 说明 |
|------|------|------|
| 验证通过率 | A | verify-layers.sh 四层全部通过，verify-architecture.sh 7 条检查通过 |
| Agent 可理解性 | A | Makefile 标准化命令，AGENTS.md 约束清晰 |
| 测试稳定性 | A | Harness 脚本自身有明确的通过/失败标准 |
| 架构合规性 | A | Monorepo 结构清晰，包间依赖方向正确 |
| 代码规范遵循度 | A | ESLint 10 Flat Config，scripts 格式规范 |
| **综合评级** | **A** | |

---

## 质量趋势

```
Week 1 (初始化完成):  core=A, 3d-engine=C, ui=C, web=C, infra=A
Week 4 (当前):        core=A, 3d-engine=C, ui=C, web=C, infra=A
```

**趋势分析**：基础设施质量稳定，但三个前端相关包（3d-engine、ui、web）的**测试覆盖始终是 D 级**。这是项目当前最大的质量缺口。

## 行动项（按优先级排序）

1. **【高】为 3d-engine 添加基础测试**
   - SceneManager 生命周期测试（init/dispose）
   - AnimationSystem 状态机测试（play/stop/isAnimating）
   - FabLayout 布局测试（createLayout/updateEquipmentPosition）

2. **【高】为 web 应用添加集成测试**
   - simulation store 行为测试（start/pause/reset/setSpeed）
   - App.vue 挂载测试（Canvas 创建、SceneManager 初始化）

3. **【中】为 ui 组件添加组件测试**
   - EquipmentCard props 渲染测试
   - SimulationPanel 事件发射测试

4. **【低】定期运行 session-cleanup.sh**
   - 建议频率：每次会话结束时
   - 目标：保持 repo 无临时文件、无 debug 代码、无空目录

## 更新记录

| 日期 | 更新者 | 变更 |
|------|--------|------|
| 2026-06-07 | agent | 初始版本 |
