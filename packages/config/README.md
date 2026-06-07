# @semi/config — 共享配置

## 职责

提供 Monorepo 内各包共享的底层配置文件：
- TypeScript 基础配置（`tsconfig.base.json`）
- ESLint 共享配置（`eslint.config.shared.js`）
- Vite 共享配置（如有）

## 文件说明

| 文件 | 用途 | 消费者 |
|------|------|--------|
| `tsconfig.base.json` | TS 编译器共享选项 | 所有包的 `tsconfig.json` 通过 `extends` 引用 |
| `eslint.config.shared.js` | Flat Config 共享规则 | 各包 `eslint.config.js` 通过相对路径 `../../eslint.config.shared.js` 引用 |

## 关键约束

- **不包含任何业务逻辑**
- **不依赖任何 workspace 包**
- 修改配置后需全量运行 `make check` 验证所有包

## 变更影响检查清单

修改本包配置后，必须检查以下事项：

- [ ] 变更是否影响所有包？如是，必须全量运行 `make check`
- [ ] `tsconfig.base.json` 变更是否破坏 `apps/web` 的 paths 解析？
- [ ] `eslint.config.shared.js` 变更是否导致某包 lint 失败？
- [ ] 是否在 `AGENTS.md` 的「工具链配置规范」中更新了相关说明？

## 使用方式

```json
// tsconfig.json
{
  "extends": "../../packages/config/tsconfig.base.json"
}
```

```javascript
// eslint.config.js
import shared from '../../eslint.config.shared.js'
export default [ ...shared, /* 包级定制 */ ]
```
