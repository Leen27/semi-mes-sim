# 标准操作流程（SOP）

> 规则来源：resources/openai-advanced/sops/
>
> 这些 SOP 把项目中反复执行的操作标准化为可重复、可验证的流程。
> 新 agent 遇到对应场景时，可以直接按 SOP 执行，不需要从对话历史中推断。

## 包含的 SOP

| SOP | 适用场景 | 文件 |
|-----|----------|------|
| 会话开始与结束 | 每轮会话的 Clock In / Clock Out | [clock-in-out.md](./clock-in-out.md) |
| 验证层级执行 | 运行四层验证（Layer 0-3） | [verification-layers.md](./verification-layers.md) |
| 架构边界检查 | 检查是否违反架构约束 | [architecture-boundary-check.md](./architecture-boundary-check.md) |

## 什么时候使用 SOP

- **重复性操作**：每轮会话都要做的事 → 写成 SOP
- **跨会话一致性**：不同 agent 应该做相同的事 → 写成 SOP
- **容易遗漏的步骤**： agent 经常忘记的 → 写成 SOP

## 新增 SOP 的流程

1. 发现某个操作被反复执行但无文档
2. 把操作步骤写成 SOP 文件放入本目录
3. 在 `AGENTS.md` 或相关文档中引用该 SOP
4. 运行 `make check` 确保无破坏
