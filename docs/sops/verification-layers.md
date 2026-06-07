# SOP：验证层级执行

## 目标

确保每次变更都按正确的顺序通过四层验证，不跳过任何一层。

## 验证层级

```
Layer 0: Architecture Boundaries  → scripts/verify-architecture.sh
Layer 1: Syntax & Static Analysis → make lint + make type-check
Layer 2: Runtime Behavior         → make test + make build
Layer 3: System-Level Integration → scripts/verify-layers.sh Layer 3
```

## 执行流程

### 步骤 1：运行 Layer 0（架构边界）

```bash
bash scripts/verify-architecture.sh
```

**通过标准**：7 条规则全部通过，0 errors。

**失败处理**：
- 阅读错误消息中的 WHAT/WHY/FIX
- 按 FIX 指令修复
- 不得绕过架构约束
- 修复后重新运行

### 步骤 2：运行 Layer 1（静态分析）

```bash
make lint
make type-check
```

**通过标准**：lint 无 error，type-check 无类型错误。

**失败处理**：
- lint 失败 → 修复代码风格问题
- type-check 失败 → 修复类型错误
- 不得通过修改 eslint 规则来绕过问题

### 步骤 3：运行 Layer 2（运行时行为）

```bash
make test
make build
```

**通过标准**：所有测试通过，所有包构建成功。

**失败处理**：
- 测试失败 → 修复代码或更新测试
- 构建失败 → 修复编译错误
- 如果修改了公共 API，检查下游包是否受影响

### 步骤 4：运行 Layer 3（端到端集成）

```bash
bash scripts/verify-layers.sh <feature-id>
```

**通过标准**：
- 构建产物存在（apps/web/dist、packages/*/dist）
- web bundle 包含跨组件符号（SceneManager、SimulationEngine、EquipmentCard）
- packages/ui/index.d.ts 存在

**失败处理**：
- 跨组件符号缺失 → 检查导入/导出是否正确
- index.d.ts 缺失 → 创建并声明公共组件

## 关键规则

- **Layer N 未通过前不得进入 Layer N+1**
- 跨组件变更（涉及 2 个以上包）必须跑完 Layer 3
- 仅单包内部修改且不影响接口时，Layer 3 可跳过（但仍推荐运行）

## 完整验证命令

```bash
# 全量验证（推荐在会话结束时运行）
bash scripts/verify-layers.sh <feature-id>

# 快速验证（仅 Layer 1-2）
make check
```
