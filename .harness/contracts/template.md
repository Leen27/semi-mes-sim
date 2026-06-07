# Sprint Contract Template

> 规则来源：Lecture 11 — Sprint contracts front-load alignment.
> 每个功能在开始实现前，必须基于本模板生成具体的 Sprint Contract。

---

## Feature: `<FEATURE_ID> — <FEATURE_NAME>`

## Scope（范围）

### 必须实现
- [ ] 具体条目 1
- [ ] 具体条目 2
- [ ] 具体条目 3

### 明确排除（Exclusions）
- [ ] 不在本 sprint 范围内的事项 1
- [ ] 不在本 sprint 范围内的事项 2

> **为什么需要 Exclusions**：防止 agent "多做一点"导致范围蔓延。明确的排除项让 evaluator 有依据拒绝超出范围的代码。

## Verification Standards（验证标准）

### Layer 0 — 架构边界
- [ ] 未违反任何 `scripts/verify-architecture.sh` 检查项
- [ ] 修改的包符合 AGENTS.md 目录职责表

### Layer 1 — 静态分析
- [ ] `pnpm lint` 通过（该功能涉及的包）
- [ ] `pnpm type-check` 通过（该功能涉及的包）

### Layer 2 — 运行时行为
- [ ] 新增/修改的代码有对应的单元测试
- [ ] 所有单元测试通过
- [ ] `pnpm build` 通过（该功能涉及的包）

### Layer 3 — 端到端集成
- [ ] 如涉及跨包变更：`scripts/verify-layers.sh` Layer 3 通过
- [ ] web bundle 包含相关跨组件符号（如适用）

### 功能级验证
- [ ] `feature_list.json` 中该功能的所有 `verificationCommand` 通过

## Acceptance Criteria（验收标准）

| 维度 | A（优秀） | B（合格） | C（不合格） |
|------|----------|----------|------------|
| 代码正确性 | 所有测试通过，包括边界情况 | 主流程测试通过 | 构建失败或主流程测试失败 |
| 架构合规性 | 完全符合 AGENTS.md 约束 | 轻微偏差（如命名不规范） | 明显违反架构边界 |
| 测试覆盖 | 主流程 + 边界情况均有测试 | 仅主流程有测试 | 无测试或测试骨架 |
| 文档同步 | ARCHITECTURE.md + AGENTS.md + PROGRESS.md 全部同步 | 部分同步 | 未同步 |
| 端到端验证 | Layer 3 完全通过 | Layer 3 有警告但无错误 | Layer 3 失败 |

## Risk & Assumptions（风险与假设）

- **假设**：列出实现本功能依赖的外部条件
- **风险**：列出可能导致延期或失败的因素
- **回退方案**：如果无法按时完成，最小可接受产出是什么

## Notes（备注）

- 任何偏离本 contract 的决策必须记录原因
- 如发现 contract 本身有问题，更新 contract 并记录变更
