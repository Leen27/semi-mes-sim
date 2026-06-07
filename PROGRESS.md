# 项目进度

> 最后更新: 2026-06-07
> 来源: feature_list.json

## 项目阶段

**阶段**: 基础建设期 —— 核心框架与类型系统搭建

## 当前状态

| 领域 | 进度 | 说明 |
|------|------|------|
| core (MES 核心) | 0/2 | 数据模型与仿真引擎待实现 |
| 3d-engine (3D 引擎) | 0/3 | 场景框架、设备资产、动画系统待实现 |
| web (主应用) | 0/3 | 界面、控制面板、看板待实现 |
| ui (组件库) | 0/0 | 等待 web 需求驱动 |

## 已完成

- [x] 项目脚手架与 Monorepo 结构
- [x] ESLint 10 Flat Config 配置
- [x] TypeScript Workspace 路径配置
- [x] AGENTS.md 项目规范文档
- [x] Harness Engineering 规则体系（ACID、知识衰减防护、全新会话测试）
- [x] DECISIONS.md 架构决策记录
- [x] 各包 ARCHITECTURE.md 模块级文档
- [x] Makefile 标准化命令

## 进行中

无 —— 等待功能开发启动

## 待办（按优先级）

### High
- [ ] **F001**: 3D 晶圆厂场景基础框架 (`3d-engine`)
- [ ] **F002**: MES 核心数据模型 (`core`)
- [ ] **F004**: MES 仿真引擎 (`core`)
- [ ] **F005**: Web 主应用界面 (`web`)

### Medium
- [ ] **F003**: 设备 3D 资产与布局 (`3d-engine`)
- [ ] **F006**: 设备状态可视化 (`3d-engine`)
- [ ] **F007**: Lot 流转动画 (`3d-engine`)
- [ ] **F008**: 仿真控制面板 (`web`)

### Low
- [ ] **F009**: 设备详情弹窗 (`web`)
- [ ] **F010**: WIP 追踪看板 (`web`)

## 文档同步状态

| 文档 | 对应代码 | 同步状态 |
|------|----------|----------|
| `AGENTS.md` | 全仓库规范 | ✅ 最新 |
| `DECISIONS.md` | 架构决策 | ✅ 最新 |
| `packages/core/ARCHITECTURE.md` | `packages/core/src/` | ✅ 最新（待代码填充） |
| `packages/3d-engine/ARCHITECTURE.md` | `packages/3d-engine/src/` | ✅ 最新（待代码填充） |
| `packages/ui/ARCHITECTURE.md` | `packages/ui/src/components/` | ✅ 最新（待代码填充） |
| `packages/config/README.md` | `packages/config/` | ✅ 最新 |
| `apps/web/ARCHITECTURE.md` | `apps/web/src/` | ✅ 最新（待代码填充） |

> **知识衰减警告**：以上「同步状态」仅表示文档与当前空代码结构一致。一旦开始功能开发，每次代码变更都必须重新验证对应行的状态。

## 阻塞项

无

## 下一步建议

1. 优先实现 `packages/core/src/models/` 中的领域类型（Lot、Equipment、Recipe、Step）
2. 同步搭建 `packages/3d-engine/src/scene/` 的基础 SceneManager
3. 确保两个包之间的类型契约稳定后，再启动 `apps/web` 的界面开发
