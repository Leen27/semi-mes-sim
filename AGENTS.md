# AGENTS.md - Semi-MES-Sim 智能体操作手册

> 本文件是 Harness Engineering 的核心基础设施。
> 任何在此仓库工作的 AI 智能体都必须阅读并遵守本手册。
> **修改本文件必须经过人类确认** —— 因为这里是所有智能体的行为约束边界。
> 
> **系统记录声明**：本仓库是项目决策、架构约束、执行状态和验证标准的唯一权威来源。不在仓库里的知识对 agent 来说等于不存在。

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

## 全新会话测试

任何智能体在首次接入本仓库时，必须仅凭仓库内容回答以下五个问题。答不上来 = 地图有缺口。

| # | 问题 | 答案位置 |
|---|------|----------|
| 1 | 这是什么项目？ | 本文件「项目背景」 |
| 2 | 怎么运行？ | `Makefile` / `init.sh` |
| 3 | 怎么验证？ | `make check`（lint + type-check + test） |
| 4 | 架构约束是什么？ | 本文件「目录职责边界」+ 各包 `ARCHITECTURE.md` |
| 5 | 当前进度和下一步是什么？ | `PROGRESS.md` + `feature_list.json` |

**自检规则**：如果你需要问人类以上任何问题，说明仓库地图有缺口。优先补全文档，而不是口头询问。

## 技术栈（固定，不可擅自更改）

| 层级 | 技术 | 版本 | 说明 |
|------|------|------|------|
| 包管理 | pnpm + workspace | 9.x | 必须使用 workspace 协议引用本地包 |
| 构建管道 | Turbo | 2.x | pipeline 已改名为 tasks |
| 前端框架 | Vue 3 + TypeScript | 3.4+ | script setup lang="ts" |
| 3D 引擎 | **Babylon.js** | 7.x | **不是 Three.js** |
| 状态管理 | Pinia | 2.x | 组合式 API 风格 |
| 构建工具 | Vite | 5.x | |
| 测试 | Vitest | 1.x | 空测试套件用 --passWithNoTests |
| 代码规范 | ESLint | **10.x** | **Flat Config 格式** |
| TypeScript | 5.4+ | 严格模式 | |

## 仓库结构

```
semi-mes-sim/
├── AGENTS.md              <- 你正在阅读的文件
├── init.sh                <- 一键自举脚本
├── feature_list.json      <- 功能清单与进度
├── eslint.config.shared.js <- ESLint 共享配置（根目录）
├── package.json           <- workspace root，type: "module"
├── apps/
│   └── web/               <- 3D 仿真主应用（Vite + Vue3 + Babylon.js）
│       ├── src/
│       │   ├── main.ts
│       │   ├── App.vue
│       │   ├── stores/    <- Pinia 状态管理
│       │   └── ...
│       ├── eslint.config.js
│       ├── tsconfig.json
│       └── package.json
└── packages/
    ├── config/            <- 共享配置（TS、ESLint、Vite）
    │   ├── tsconfig.base.json
    │   └── package.json   <- type: "module"（ESM 包）
    ├── core/              <- MES 核心领域逻辑（纯 TypeScript）
    │   ├── src/
    │   ├── eslint.config.js
    │   └── package.json
    ├── 3d-engine/         <- Babylon.js 封装与 3D 资产
    │   ├── src/
    │   │   ├── scene/     <- SceneManager
    │   │   ├── assets/    <- 设备模型、工厂布局
    │   │   └── animation/ <- 动画系统
    │   ├── eslint.config.js
    │   └── package.json
    └── ui/                <- 共享 Vue UI 组件库
        ├── src/components/
        ├── index.d.ts     <- 类型声明文件（必须存在）
        ├── eslint.config.js
        └── package.json
```

### 目录职责边界

| 目录 | 职责 | 禁止事项 |
|------|------|----------|
| apps/web | 主应用入口、页面布局、3D 画布挂载 | 不能包含可复用的领域逻辑 |
| packages/core | MES 领域模型、仿真引擎、算法 | **不能依赖 Vue、Babylon.js 等 UI 库** |
| packages/3d-engine | Babylon.js 场景、相机、模型、动画 | **不能依赖 Vue** |
| packages/ui | 可复用 Vue 组件 | 不能依赖 apps/web |
| packages/config | 共享配置文件 | 不能依赖任何业务包 |

### 包间依赖规则

```
apps/web --> packages/core
         --> packages/3d-engine
         --> packages/ui

packages/ui --> packages/core (仅类型)

packages/3d-engine --> packages/core (仅类型)

packages/core --> 纯 TypeScript，无 UI 依赖
```

**核心包 @semi/core 必须是纯 TypeScript，不能依赖任何 UI 库。**

## 工具链配置规范（强制）

### ESLint 10 Flat Config

**这是本仓库最频繁出错的领域。以下规范基于实际踩坑经验，必须严格遵守。**

#### 1. 版本约束
- **ESLint 必须使用 10.x**（根目录 package.json 已安装）
- **配套包**：typescript-eslint（不是 @typescript-eslint/*）、eslint-plugin-vue、vue-eslint-parser
- **版本匹配**：@eslint/js 版本必须与 eslint 主版本一致（如 eslint@10 配 @eslint/js@10）

#### 2. Flat Config 格式（与 ESLint 8 完全不同）

```javascript
// 正确：Flat Config 格式（ESLint 9/10）
import js from '@eslint/js'
import ts from 'typescript-eslint'
import pluginVue from 'eslint-plugin-vue'

export default [
  js.configs.recommended,
  ...ts.configs.recommended,        // 注意展开运算符！
  ...pluginVue.configs['flat/recommended'],
  {
    files: ['**/*.vue'],
    languageOptions: {
      parserOptions: {
        parser: ts.parser,
        extraFileExtensions: ['.vue']
      }
    }
  },
  {
    rules: {
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'no-console': 'warn',
      'vue/multi-word-component-names': 'off'
    }
  }
]
```

```javascript
// 错误：这是 ESLint 8 的 legacy 格式，绝对不能用
import tsPlugin from '@typescript-eslint/eslint-plugin'
import tsParser from '@typescript-eslint/parser'
// 任何使用 eslint-plugin/parser 的代码都是错的
```

#### 3. 关键规则
- **禁止使用 --ext**：Flat Config 不支持 --ext .ts,.vue。在 eslint.config.js 中用 files: ['**/*.ts', '**/*.vue'] 指定
- **lint 脚本格式**："lint": "eslint src"（不是 "eslint src --ext .ts"）
- **共享配置位置**：eslint.config.shared.js 放在根目录，各包用相对路径 ../../eslint.config.shared.js 引用
- **浏览器全局变量**：必须在 languageOptions.globals 中声明 performance、HTMLCanvasElement、requestAnimationFrame、console 等
- **ESM 要求**：任何包含 ESM import/export 的配置文件所在目录，其 package.json 必须设置 "type": "module"

#### 4. 现有配置文件（不要重复创建）
- 根目录：eslint.config.shared.js —— 共享配置定义
- 各包：eslint.config.js —— 引用共享配置

### TypeScript 配置

#### 1. tsconfig.json 结构
- **根目录**：tsconfig.json 仅用于编辑器支持，不直接编译
- **各包**：独立的 tsconfig.json，extends: "../../packages/config/tsconfig.base.json"
- **apps/web 特殊处理**：使用 "outDir": "./dist"、"rootDir": "./src"

#### 2. Workspace 包引用（apps/web 的关键配置）

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["src/*"],
      "@semi/ui": ["../../packages/ui/index.d.ts"],
      "@semi/core": ["../../packages/core/dist/index.d.ts"],
      "@semi/3d-engine": ["../../packages/3d-engine/dist/index.d.ts"]
    }
  }
}
```

**注意**：
- @semi/ui 指向 packages/ui/index.d.ts（手动维护的 Vue 组件类型声明）
- @semi/core 和 @semi/3d-engine 指向各自 dist/index.d.ts（由 tsc 自动生成）
- **绝对不能指向源码路径**（如 src/index.ts），否则会触发 TS6059 rootDir 错误

#### 3. Vue 组件库类型声明
packages/ui/index.d.ts 必须存在且正确：

```typescript
import type { DefineComponent } from 'vue'

declare const EquipmentCard: DefineComponent<{ /* props */ }>
// ... 其他组件

export { EquipmentCard, SimulationPanel, StatusBadge }
```

### Vitest 测试

- **空测试套件策略**：所有包的 test 脚本必须是 vitest run --passWithNoTests
- 这确保了即使还没有写测试，CI pipeline 也不会失败
- 当添加第一个测试文件后，行为不变

## 编码规范

### 命名约定
- **文件**: PascalCase 用于组件/类（EquipmentCard.vue），camelCase 用于工具（useSimulation.ts）
- **类型/接口**: PascalCase，前缀不加 I（Equipment 而非 IEquipment）
- **常量**: UPPER_SNAKE_CASE（MAX_LOT_SIZE）
- **枚举**: PascalCase（EquipmentStatus.Idle）
- **布尔属性**: 前缀 is/has/should（isProcessing, hasError）

### 文件组织
每个文件只做一件事：
- .ts -> 纯逻辑/工具
- .vue -> Vue 单文件组件
- index.ts -> 仅用于导出，不实现逻辑

### 导入规则
- 使用 workspace 导入（@semi/core）而非相对路径（../../core）
- 类型导入使用 import type（import type { Equipment } from '@semi/core'）

### Vue 组件格式（ESLint 兼容）

```vue
<!-- 正确：多属性换行，自闭合标签 -->
<canvas
  ref="canvasRef"
  class="canvas-element"
/>

<!-- 错误：多属性在同一行 -->
<canvas ref="canvasRef" class="canvas-element"></canvas>
```

## 3D 开发规范（Babylon.js）

### 场景组织
- scene/ 目录下管理 Scene、Camera、Engine、Light
- 使用 SceneManager 类封装 Babylon.js 场景生命周期
- 所有 3D 对象必须设置 name 属性，便于调试和交互

### 模型规范
- 设备模型使用 MeshBuilder 创建基础几何体（Box、Cylinder、Sphere）
- 避免外部模型文件（.glb/.gltf），保持项目自包含
- 颜色使用 Color3 / StandardMaterial 定义

### 动画系统
- 使用 Babylon.js 原生 Animation 类
- 动画由 @semi/core 的仿真事件驱动
- 所有动画必须可暂停、可加速、可回退

## 工作流

### 添加新功能的步骤
1. 在 feature_list.json 中找到对应功能，确认状态为 todo
2. 在正确的包和目录中实现代码
3. **同步更新文档**：检查该包 `ARCHITECTURE.md`，如有接口/约束变更必须同步修改
4. **本地验证**：运行 `make check`（lint + type-check + test）
5. 确保全部通过后再提交
6. 更新 feature_list.json 和 PROGRESS.md 状态为 done
7. **原子提交**：一次 commit 包含代码+测试+文档的完整变更

### 遇到问题的处理
- 如果架构约束阻止你实现功能，**不要绕过约束**
- 先修改架构文档（本文件），再调整代码
- 如果必须引入新依赖，在 AGENTS.md 中记录理由
- **如果修改了工具链配置（ESLint、TypeScript、构建脚本），必须更新本文件的相关章节**

## ACID 状态管理（智能体工作原则）

将数据库事务原则映射到 agent 的任务执行：

| 原则 | 含义 | 执行标准 |
|------|------|----------|
| **A**tomic（原子性） | 每次提交必须是完整的逻辑单元 | 一个功能 = 一次 commit。不要半成品提交。代码+测试+文档同步更新。 |
| **C**onsistent（一致性） | 提交后仓库必须处于自洽状态 | 提交前必须运行 `make check`（lint + type-check + test）全部通过。 |
| **I**solated（隔离性） | 并行任务不互相污染 | 同时处理多个功能时，使用独立分支。不要在同一分支混排不相关的修改。 |
| **D**urable（持久性） | 关键知识必须持久化到仓库 | 架构决策、约束变更、重要发现必须写入 `AGENTS.md` 或 `DECISIONS.md`。口头交接的知识在会话结束时就丢失了。 |

## 知识衰减防护

**过时的文档比没有文档更危险。** 以下机制用于防止知识衰减：

### 文档-代码绑定规则
1. **修改代码时必须检查对应模块的 `ARCHITECTURE.md`** —— 如果接口、职责或约束发生变化，文档必须同步更新
2. **修改 `AGENTS.md` 中提到的任何配置或流程时，必须同步更新 `AGENTS.md` 的对应章节**
3. **新增、删除或重命名包时，必须更新根目录仓库结构图和各包间的依赖图**

### 衰减检查清单（每次提交前）
- [ ] 我修改的代码旁边的 `ARCHITECTURE.md` 是否仍然准确？
- [ ] 我是否引入了新的工具链依赖？如果是，`AGENTS.md` 技术栈表格是否已更新？
- [ ] 我是否修改了构建脚本？如果是，`Makefile` 和 `AGENTS.md` 是否已同步？
- [ ] 我是否做出了需要长期记住的架构决策？如果是，是否写入了 `DECISIONS.md`？

## 常见错误预防清单

智能体在修改代码前，对照此清单自查：

| # | 检查项 | 验证方式 |
|---|--------|----------|
| 1 | 新增包是否有 eslint.config.js？ | 运行 pnpm lint |
| 2 | lint 脚本是否使用了 --ext？ | 必须是 "eslint src" |
| 3 | 包内 package.json 是否设置了 "type": "module"？ | 检查文件 |
| 4 | 是否引入了 @typescript-eslint/* 旧包？ | 必须是 typescript-eslint |
| 5 | @semi/ui 组件修改后是否同步更新 index.d.ts？ | 检查类型导出 |
| 6 | tsconfig.json 中的 paths 是否指向 dist/ 或 index.d.ts？ | 不是 src/ |
| 7 | vitest 脚本是否有 --passWithNoTests？ | 检查 package.json |
| 8 | 浏览器 API（performance, HTMLCanvasElement）是否在 ESLint globals 中声明？ | 检查 eslint.config.shared.js |
| 9 | 修改代码后是否同步更新了对应模块的 ARCHITECTURE.md？ | 检查该包文档 |
| 10 | 是否做出了新的架构决策？是否写入了 DECISIONS.md？ | 检查 DECISIONS.md |

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

- **v1.2.0** - 添加 Harness Engineering 核心机制：
  - 添加「系统记录」声明与「全新会话测试」5 题
  - 添加 ACID 状态管理原则（原子性、一致性、隔离性、持久性）
  - 添加知识衰减防护机制与文档-代码绑定规则
  - 新增 DECISIONS.md 用于持久化架构决策
  - 各包新增 ARCHITECTURE.md，实现知识靠近代码
  - 工作流强制要求文档同步更新
- **v1.1.0** - 重大更新：
  - 技术栈从 Three.js 迁移到 Babylon.js
  - 添加 ESLint 10 Flat Config 完整规范（基于实际踩坑经验）
  - 添加 TypeScript workspace paths 配置规范
  - 添加 Vue 组件库类型声明规范
  - 添加常见错误预防清单
  - 修正仓库结构图（packages/* 而非 packages/@semi/*）
  - 添加 Vitest --passWithNoTests 规范
- **v1.0.0** - 初始版本，项目初始化时创建
