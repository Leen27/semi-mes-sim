# 会话交接

> 规则来源：resources/templates/session-handoff.md
>
> 较长会话结束时填写，下一轮会话开始时阅读。
> 让接手的 agent 在 3 分钟内了解现状，无需猜测。

## 当前已验证

- `make check`（lint + type-check + test）全部通过
- `scripts/verify-layers.sh` 四层验证（Layer 0-3）全部通过
- `scripts/verify-architecture.sh` 7 条架构边界检查全部通过
- `scripts/session-exit-check.sh` 五维度干净状态检查全部通过

### 已通过的功能（passing）

| ID | 功能 | 领域 | 验证状态 |
|----|------|------|----------|
| F002 | MES 核心数据模型 | core | passing |
| F001 | 3D 晶圆厂场景基础框架 | 3d-engine | passing |
| F003 | 设备 3D 资产与布局 | 3d-engine | passing |
| F005 | Web 主应用界面 | web | passing |
| F006 | 设备状态可视化 | 3d-engine | passing |

### 活跃的 Harness 基础设施

- 四层验证体系（Layer 0-3）+ 架构边界检查
- 任务追踪系统（.harness/traces/）
- Sprint Contract 模板 + Evaluator Rubric（五维度评分）
- 幂等清理脚本 + 会话退出检查

## 本轮改动

- 新增 `scripts/session-exit-check.sh` — 五维度干净状态检查
- 新增 `scripts/session-cleanup.sh` — 幂等熵减清理
- 新增 `docs/quality.md` — 模块质量追踪文档
- 更新 `AGENTS.md` — 新增干净状态硬约束
- 更新 `docs/workflow.md` — 扩展 Clock Out 为五维度检查清单
- 更新 `DECISIONS.md` — 新增 ADR-011

## 仍损坏或未验证

| 问题 | 影响 | 状态 |
|------|------|------|
| F004 processEvent 是 TODO | 仿真引擎无法处理事件 | `not_started`，阻塞 F007/F008 |
| 3d-engine/ui/web 无单元测试 | 测试覆盖 D 级 | 长期技术债 |
| F005 依赖声明包含 F004 | 依赖关系与实际状态不符 | 初始化阶段遗留债务 |

## 下一步最佳动作

1. **启动 F004（MES 仿真引擎）** — 实现 processEvent() 的事件处理逻辑
   - 已有 EventQueue 和 SimulationEngine 类框架
   - 已有 event-queue.test.ts 和 simulation-engine.test.ts 单元测试
   - 需要实现：LotArrival、EquipmentReady、ProcessComplete、EquipmentBreakdown、EquipmentRepair
   - 需要编写 simulation-end-to-end.test.ts

2. **F004 passing 后，启动 F007（Lot 流转动画）**
   - 补充 AnimationSystem 的 pause()、setSpeed()、reverse() 方法

3. **然后按优先级启动 F008 → F009 → F010**

## 命令速查

```bash
# 启动验证
make check              # lint + type-check + test
make dev                # 启动开发服务器

# 功能验证
bash scripts/verify-layers.sh F004
bash scripts/evaluate-feature.sh F004

# 会话收尾
bash scripts/session-cleanup.sh
bash scripts/session-exit-check.sh
```
