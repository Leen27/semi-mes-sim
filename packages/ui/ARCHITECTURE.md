# @semi/ui — 共享 Vue UI 组件库

## 职责

可复用的 Vue 3 组件，供 `apps/web` 消费。包含：
- 业务通用组件（EquipmentCard、SimulationPanel、StatusBadge 等）
- 组件对应的类型声明

## 目录结构

```
src/
├── components/   # Vue 单文件组件
└── index.ts      # 组件导出

index.d.ts        # 手动维护的组件类型声明（必须存在）
```

## 关键约束

- 每个组件必须是独立的 `.vue` 文件，使用 `<script setup lang="ts">`
- **组件修改后必须同步更新 `index.d.ts`**（`@semi/ui` 的类型入口指向此文件）
- 不依赖 `apps/web` 的任何代码
- 样式使用 scoped CSS 或 Tailwind（如有引入）

## 类型声明

`packages/ui/index.d.ts` 是 `tsconfig.json` 中 `@semi/ui` 的解析目标：

```typescript
import type { DefineComponent } from 'vue'
declare const EquipmentCard: DefineComponent<...>
export { EquipmentCard }
```

## 变更影响检查清单

修改本包代码后，必须检查以下文档和依赖项：

- [ ] **必须同步更新 `index.d.ts`** —— 新增/删除/重命名组件、修改 props 类型时，类型声明文件必须同步
- [ ] 本文件中的组件列表是否仍然准确
- [ ] 组件变更是否影响 `apps/web` 中的引用？如是，检查 `apps/web/ARCHITECTURE.md`

## 对外接口

通过 `index.ts` 和 `index.d.ts` 导出组件。

## 依赖

- `vue`
- `@semi/config`
- `@semi/core`（仅类型）
