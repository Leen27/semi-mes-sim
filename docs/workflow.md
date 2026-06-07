# 工作流与智能体执行规范

> **阅读时机**：执行任务、提交代码前。包含 ACID 原则、知识衰减防护和常见错误清单。

## 添加新功能的步骤

1. 在 `feature_list.json` 中找到对应功能，确认状态为 `todo`
2. 在正确的包和目录中实现代码
3. **同步更新文档**：检查该包 `ARCHITECTURE.md`，如有接口/约束变更必须同步修改
4. **本地验证**：运行 `make check`（lint + type-check + test）
5. 确保全部通过后再提交
6. 更新 `feature_list.json` 和 `PROGRESS.md` 状态为 `done`
7. **原子提交**：一次 commit 包含代码+测试+文档的完整变更

## 遇到问题的处理

- 如果架构约束阻止你实现功能，**不要绕过约束**
- 先修改架构文档（`AGENTS.md` 或 `DECISIONS.md`），再调整代码
- 如果必须引入新依赖，在 `AGENTS.md` 中记录理由
- 如果修改了工具链配置（ESLint、TypeScript、构建脚本），必须更新 `docs/toolchain.md`

---

## ACID 状态管理（智能体工作原则）

将数据库事务原则映射到 agent 的任务执行：

| 原则 | 含义 | 执行标准 |
|------|------|----------|
| **A**tomic（原子性） | 每次提交是完整的逻辑单元 | 一个功能 = 一次 commit。不要半成品。代码+测试+文档同步更新。 |
| **C**onsistent（一致性） | 提交后仓库处于自洽状态 | 提交前必须 `make check` 全部通过。 |
| **I**solated（隔离性） | 并行任务不互相污染 | 同时处理多个功能时，使用独立分支。不要混排无关修改。 |
| **D**urable（持久性） | 关键知识必须持久化到仓库 | 架构决策、约束变更必须写入 `AGENTS.md` 或 `DECISIONS.md`。口头交接的知识在会话结束时就丢失了。 |

---

## 知识衰减防护

**过时的文档比没有文档更危险。**

### 文档-代码绑定规则

1. **修改代码时必须检查对应模块的 `ARCHITECTURE.md`** —— 如果接口、职责或约束发生变化，文档必须同步更新
2. **修改 `AGENTS.md` 或专题文档中提到的任何配置或流程时，必须同步更新对应文档**
3. **新增、删除或重命名包时，必须更新根目录仓库结构图和各包间的依赖图**

### 衰减检查清单（每次提交前）

- [ ] 我修改的代码旁边的 `ARCHITECTURE.md` 是否仍然准确？
- [ ] 我是否引入了新的工具链依赖？如果是，`docs/toolchain.md` 和 `AGENTS.md` 是否已更新？
- [ ] 我是否修改了构建脚本？如果是，`Makefile` 和 `docs/toolchain.md` 是否已同步？
- [ ] 我是否做出了需要长期记住的架构决策？如果是，是否写入了 `DECISIONS.md`？

---

## 常见错误预防清单

修改代码前，对照此清单自查：

| # | 检查项 | 验证方式 |
|---|--------|----------|
| 1 | 新增包是否有 `eslint.config.js`？ | 运行 `pnpm lint` |
| 2 | lint 脚本是否使用了 `--ext`？ | 必须是 `"eslint src"` |
| 3 | 包内 `package.json` 是否设置了 `"type": "module"`？ | 检查文件 |
| 4 | 是否引入了 `@typescript-eslint/*` 旧包？ | 必须是 `typescript-eslint` |
| 5 | `@semi/ui` 组件修改后是否同步更新 `index.d.ts`？ | 检查类型导出 |
| 6 | `tsconfig.json` 中的 `paths` 是否指向 `dist/` 或 `index.d.ts`？ | 不是 `src/` |
| 7 | vitest 脚本是否有 `--passWithNoTests`？ | 检查 `package.json` |
| 8 | 浏览器 API 是否在 ESLint globals 中声明？ | 检查 `eslint.config.shared.js` |
| 9 | 修改代码后是否同步更新了对应模块的 `ARCHITECTURE.md`？ | 检查该包文档 |
| 10 | 是否做出了新的架构决策？是否写入了 `DECISIONS.md`？ | 检查 `DECISIONS.md` |
