# 工具链配置规范

> **阅读时机**：修改 ESLint 配置、TypeScript 配置、构建脚本、或新增包时。

## ESLint 10 Flat Config

**这是本仓库最频繁出错的领域。以下规范基于实际踩坑经验，必须严格遵守。**

### 版本约束

- **ESLint 必须使用 10.x**（根目录 package.json 已安装）
- **配套包**：`typescript-eslint`（不是 `@typescript-eslint/*`）、`eslint-plugin-vue`、`vue-eslint-parser`
- **版本匹配**：`@eslint/js` 版本必须与 eslint 主版本一致（如 eslint@10 配 @eslint/js@10）

### Flat Config 格式（与 ESLint 8 完全不同）

```javascript
// ✅ 正确：Flat Config 格式（ESLint 9/10）
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
// ❌ 错误：这是 ESLint 8 的 legacy 格式，绝对不能用
import tsPlugin from '@typescript-eslint/eslint-plugin'
import tsParser from '@typescript-eslint/parser'
```

### 关键规则

- **禁止 `--ext`**：Flat Config 不支持 `--ext .ts,.vue`。在 `eslint.config.js` 中用 `files: ['**/*.ts', '**/*.vue']` 指定
- **lint 脚本格式**：`"lint": "eslint src"`（不是 `"eslint src --ext .ts"`）
- **共享配置位置**：`eslint.config.shared.js` 放在根目录，各包用相对路径 `../../eslint.config.shared.js` 引用
- **浏览器全局变量**：必须在 `languageOptions.globals` 中声明 `performance`、`HTMLCanvasElement`、`requestAnimationFrame`、`console` 等
- **ESM 要求**：任何包含 ESM import/export 的配置文件所在目录，其 `package.json` 必须设置 `"type": "module"`

### 现有配置文件（不要重复创建）

- 根目录：`eslint.config.shared.js` —— 共享配置定义
- 各包：`eslint.config.js` —— 引用共享配置

---

## TypeScript 配置

### tsconfig.json 结构

- **根目录**：`tsconfig.json` 仅用于编辑器支持，不直接编译
- **各包**：独立的 `tsconfig.json`，`extends: "../../packages/config/tsconfig.base.json"`
- **apps/web 特殊处理**：使用 `"outDir": "./dist"`、`"rootDir": "./src"`

### Workspace 包引用（apps/web 的关键配置）

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
- `@semi/ui` 指向 `packages/ui/index.d.ts`（手动维护的 Vue 组件类型声明）
- `@semi/core` 和 `@semi/3d-engine` 指向各自 `dist/index.d.ts`（由 tsc 自动生成）
- **绝对不能指向源码路径**（如 `src/index.ts`），否则会触发 TS6059 `rootDir` 错误

### Vue 组件库类型声明

`packages/ui/index.d.ts` 必须存在且正确：

```typescript
import type { DefineComponent } from 'vue'

declare const EquipmentCard: DefineComponent<{ /* props */ }>
// ... 其他组件

export { EquipmentCard, SimulationPanel, StatusBadge }
```

---

## Vitest 测试

- **空测试套件策略**：所有包的 test 脚本必须是 `vitest run --passWithNoTests`
- 这确保了即使还没有写测试，CI pipeline 也不会失败
- 当添加第一个测试文件后，行为不变
