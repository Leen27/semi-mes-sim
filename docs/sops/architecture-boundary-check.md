# SOP：架构边界检查

## 目标

确保代码变更没有违反项目中定义的架构约束。

## 检查脚本

```bash
bash scripts/verify-architecture.sh
```

## 检查的 7 条规则

| 规则 | 检查内容 | 违规示例 |
|------|----------|----------|
| Rule 1 | `@semi/core` 无 Vue/Babylon.js/Pinia 依赖 | 在 core 中 import 'vue' |
| Rule 2 | `@semi/3d-engine` 无 Vue 依赖 | 在 3d-engine 中 import 'vue' |
| Rule 3 | `@semi/ui` 不依赖 `apps/web` | ui 的 package.json 中出现 @semi/web |
| Rule 4 | 本地包引用使用 `workspace:*` | 使用版本号而非 workspace:* |
| Rule 5 | 无外部 .glb/.gltf 文件 | 引入外部 3D 模型文件 |
| Rule 6 | 3D 对象命名规范 | MeshBuilder 调用第一个参数是对象字面量 |
| Rule 7 | tsconfig paths 指向 dist/ 或 index.d.ts | paths 指向 src/ 目录 |

## 错误消息格式

每条违规都包含三个要素：

```
ERROR: <发现了什么问题>
WHY: <为什么这是问题>
FIX: <具体怎么修改>
```

## 什么时候运行

- **每次 `scripts/verify-layers.sh` 运行时自动执行**（作为 Layer 0）
- **手动运行**：当你修改了包依赖、tsconfig 或跨包引用时
- **CI 中**：应该在每次 push 前运行

## 处理违规

1. 阅读错误消息中的 FIX 指令
2. 按指令修改代码
3. 不得绕过约束
4. 如果约束本身有问题：
   - 更新 `AGENTS.md` 说明新约束和理由
   - 更新 `scripts/verify-architecture.sh` 添加/修改检查
   - 记录决策到 `DECISIONS.md`
5. 重新运行验证确认修复

## 添加新规则

当发现新的反复出现的架构违规时：

1. 在 `scripts/verify-architecture.sh` 中添加新的 Rule
2. 错误消息必须包含 WHAT/WHY/FIX
3. 更新本文档的"检查的 N 条规则"表格
4. 运行 `make check` 确保脚本本身无语法错误
