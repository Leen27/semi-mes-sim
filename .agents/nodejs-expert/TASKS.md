# Node.js 后端开发专家 — 最小原子任务清单

> 本文件是 `apps/server` 所有开发任务的唯一真实来源。
> **规则**: 每个任务必须是单一职责、独立验证、可回滚的原子单元。

---

## 任务状态图例

| 状态 | 图标 | 说明 |
|------|------|------|
| pending | ⏸ | 等待执行 |
| active | 🔄 | 正在执行 |
| passing | ✅ | 验证通过 |
| blocked | 🔒 | 依赖未满足 |

---

## Phase 0: 项目脚手架（基础设施）

### B001 — 项目初始化与依赖安装
```yaml
name: 项目初始化与依赖安装
description: |
  创建 apps/server 目录结构，安装所有依赖，配置 TypeScript、ESLint、Vitest。
  这是所有后续任务的基础。
scope:
  do:
    - 创建 apps/server/ 目录及子目录结构
    - 初始化 package.json（type: module, workspace:* 引用 @semi/core）
    - 安装 Fastify + 插件（cors, swagger, swagger-ui）
    - 安装 Prisma + @prisma/client
    - 安装 Socket.IO
    - 安装 Zod + nanoid
    - 安装开发依赖（tsx, typescript, vitest, supertest, @types/node）
    - 创建 tsconfig.json（NodeNext 模块解析）
    - 创建 eslint.config.js
    - 创建 vitest.config.ts
    - 创建 .env.example
    - 验证 pnpm install 成功
  dont:
    - 不写业务代码
    - 不创建 Prisma schema
    - 不写测试
files:
  - apps/server/package.json
  - apps/server/tsconfig.json
  - apps/server/eslint.config.js
  - apps/server/vitest.config.ts
  - apps/server/.env.example
  - apps/server/.env
dependencies:
  - @semi/core 已存在（packages/core）
verification:
  - cmd: cd apps/server && pnpm install
  - cmd: cd apps/server && pnpm type-check
    check:
      - 安装无错误
      - 类型检查通过（空项目也应有 tsc --noEmit 成功）
status: pending
```

### B002 — Prisma Schema 定义与数据库初始化
```yaml
name: Prisma Schema 定义与数据库初始化
description: |
  定义所有 Prisma 数据模型，创建初始迁移，生成 Prisma Client。
  数据库模型映射 MES 领域概念（Lot, Equipment, Recipe, ProcessStep, Event, StatusHistory, FabLayout, SimulationSession, ProcessRoute）。
scope:
  do:
    - 创建 prisma/schema.prisma
    - 定义所有模型（见 DESIGN.md 第 3 节）
    - 运行 prisma migrate dev --name init
    - 运行 prisma generate
    - 验证 SQLite 数据库文件创建成功
    - 验证 Prisma Client 类型生成正确
    - 编写 schema 验证测试（确认所有表存在）
  dont:
    - 不写业务逻辑
    - 不创建 seed 数据
files:
  - apps/server/prisma/schema.prisma
  - apps/server/prisma/migrations/
  - apps/server/tests/unit/schema.test.ts
dependencies:
  - B001  # 项目初始化
  - @semi/core 的 Lot, Equipment, Recipe, ProcessStep 类型已定义
verification:
  - cmd: cd apps/server && pnpm db:generate
  - cmd: cd apps/server && pnpm db:migrate
  - cmd: cd apps/server && pnpm test tests/unit/schema.test.ts
    check:
      - migrate 成功
      - dev.db 文件创建
      - Prisma Client 类型正确生成
      - schema 测试通过（查询所有表结构）
status: pending
```

### B003 — Prisma Client 封装与事务工具
```yaml
name: Prisma Client 封装与事务工具
description: |
  创建 Prisma Client 单例封装，提供类型安全的事务工具函数。
  为后续所有 Service 提供统一的数据库访问入口。
scope:
  do:
    - 创建 src/db/client.ts（PrismaClient 单例 + 扩展）
    - 创建 src/db/transaction.ts（事务包装器）
    - 在 Fastify 中注册 prisma 装饰器（fastify.decorate）
    - 编写 db client 单元测试
    - 验证生命周期钩子（onClose 时断开连接）
  dont:
    - 不写 Service 逻辑
files:
  - apps/server/src/db/client.ts
  - apps/server/src/db/transaction.ts
  - apps/server/tests/unit/db-client.test.ts
dependencies:
  - B002  # Prisma Schema 已定义
verification:
  - cmd: cd apps/server && pnpm type-check
  - cmd: cd apps/server && pnpm test tests/unit/db-client.test.ts
    check:
      - Prisma Client 可正确实例化
      - 事务包装器正常工作
      - 生命周期钩子正确触发
status: pending
```

---

## Phase 1: 核心 API 基础设施

### B004 — Fastify 应用骨架与插件系统
```yaml
name: Fastify 应用骨架与插件系统
description: |
  创建 Fastify 应用实例，注册核心插件（CORS, Swagger, 错误处理, Prisma, Socket.IO）。
  建立分层架构的基础。
scope:
  do:
    - 创建 src/config/env.ts（环境变量校验，使用 Zod）
    - 创建 src/config/logger.ts（Pino 日志配置）
    - 创建 src/plugins/cors.ts
    - 创建 src/plugins/swagger.ts（OpenAPI 文档）
    - 创建 src/plugins/error-handler.ts（RFC 7807 Problem Details）
    - 创建 src/plugins/socketio.ts（Socket.IO 集成）
    - 创建 src/plugins/prisma.ts（Prisma 装饰器注册）
    - 创建 src/app.ts（Fastify 实例组装）
    - 创建 src/main.ts（入口，启动服务器）
    - 创建 src/utils/errors.ts（自定义错误类）
    - 创建 src/utils/nanoid.ts（ID 生成）
    - 创建 src/utils/problem-details.ts（错误响应格式）
    - 创建 src/utils/validation.ts（Zod 校验工具）
    - 验证服务器可正常启动
    - 验证 Swagger UI 可访问 (/api/v1/docs)
    - 验证健康检查端点 (/health) 返回 200
  dont:
    - 不注册业务路由
    - 不写 Service 逻辑
files:
  - apps/server/src/config/env.ts
  - apps/server/src/config/logger.ts
  - apps/server/src/plugins/*.ts
  - apps/server/src/app.ts
  - apps/server/src/main.ts
  - apps/server/src/utils/*.ts
  - apps/server/src/routes/health.ts
dependencies:
  - B001  # 项目初始化
  - B003  # Prisma Client 封装
verification:
  - cmd: cd apps/server && pnpm lint && pnpm type-check
  - cmd: cd apps/server && pnpm dev &
  - cmd: sleep 3 && curl -s http://localhost:3001/health | grep -q "ok"
  - cmd: curl -s http://localhost:3001/api/v1/docs/static/index.html | grep -q "swagger"
    check:
      - 服务器启动无错误
      - 健康检查返回 200
      - Swagger UI 可访问
      - 所有类型检查通过
status: pending
```

### B005 — 通用 DTO 与类型定义
```yaml
name: 通用 DTO 与类型定义
description: |
  创建所有 API 共享的 DTO（Data Transfer Object）和类型定义。
  为后续业务路由提供类型安全的数据校验。
scope:
  do:
    - 创建 src/dto/common.dto.ts（分页、ID 参数、Problem Details）
    - 创建 src/types/socket-events.ts（WebSocket 事件类型）
    - 创建 src/types/index.ts（扩展类型导出）
    - 使用 Zod 定义所有 Schema
    - 导出 TypeScript 类型（z.infer<typeof schema>）
    - 编写 DTO 验证测试
  dont:
    - 不写业务 DTO（Equipment, Lot 等留到后续任务）
files:
  - apps/server/src/dto/common.dto.ts
  - apps/server/src/types/socket-events.ts
  - apps/server/src/types/index.ts
  - apps/server/tests/unit/dto-common.test.ts
dependencies:
  - B004  # Fastify 骨架
verification:
  - cmd: cd apps/server && pnpm lint && pnpm type-check
  - cmd: cd apps/server && pnpm test tests/unit/dto-common.test.ts
    check:
      - 所有 Zod Schema 可正确编译
      - 分页 DTO 默认值正确
      - Problem Details 格式正确
status: pending
```

---

## Phase 2: 设备管理 API

### B006 — Equipment Service + CRUD API
```yaml
name: Equipment Service + CRUD API
description: |
  实现设备管理的完整 CRUD：Service 层 + Route 层 + DTO + 测试。
  包含状态变更历史记录。
scope:
  do:
    - 创建 src/dto/equipment.dto.ts（Create, Update, Query, Response）
    - 创建 src/services/equipment.service.ts（CRUD + 状态历史）
    - 创建 src/routes/v1/equipment.ts（RESTful 路由）
    - 在 src/routes/v1/index.ts 注册设备路由
    - 编写 Service 单元测试
    - 编写 API 集成测试（supertest）
    - 验证 Swagger 文档自动生成
  dont:
    - 不涉及 Lot 关联逻辑（留到 B009）
    - 不涉及 WebSocket 推送（留到 B014）
files:
  - apps/server/src/dto/equipment.dto.ts
  - apps/server/src/services/equipment.service.ts
  - apps/server/src/routes/v1/equipment.ts
  - apps/server/src/routes/v1/index.ts  # 更新
  - apps/server/tests/unit/equipment.service.test.ts
  - apps/server/tests/integration/equipment.api.test.ts
dependencies:
  - B003  # Prisma Client
  - B004  # Fastify 骨架
  - B005  # 通用 DTO
verification:
  - cmd: cd apps/server && pnpm lint && pnpm type-check
  - cmd: cd apps/server && pnpm test tests/unit/equipment.service.test.ts
  - cmd: cd apps/server && pnpm test tests/integration/equipment.api.test.ts
    check:
      - GET /api/v1/equipment 返回列表
      - GET /api/v1/equipment/:id 返回详情
      - POST /api/v1/equipment 创建设备
      - PUT /api/v1/equipment/:id 更新设备
      - DELETE /api/v1/equipment/:id 删除设备
      - 状态变更时记录 StatusHistory
      - 404 返回正确 Problem Details
status: pending
```

---

## Phase 3: Lot 与工艺管理 API

### B007 — Lot Service + CRUD API
```yaml
name: Lot Service + CRUD API
description: |
  实现 Lot（晶圆批次）管理的完整 CRUD。
scope:
  do:
    - 创建 src/dto/lot.dto.ts
    - 创建 src/services/lot.service.ts
    - 创建 src/routes/v1/lot.ts
    - 在 src/routes/v1/index.ts 注册
    - 编写 Service 单元测试
    - 编写 API 集成测试
  dont:
    - 不实现状态流转逻辑（留到 B011）
    - 不涉及设备分配逻辑（留到 B009）
files:
  - apps/server/src/dto/lot.dto.ts
  - apps/server/src/services/lot.service.ts
  - apps/server/src/routes/v1/lot.ts
  - apps/server/src/routes/v1/index.ts  # 更新
  - apps/server/tests/unit/lot.service.test.ts
  - apps/server/tests/integration/lot.api.test.ts
dependencies:
  - B003  # Prisma Client
  - B004  # Fastify 骨架
  - B005  # 通用 DTO
verification:
  - cmd: cd apps/server && pnpm test tests/unit/lot.service.test.ts
  - cmd: cd apps/server && pnpm test tests/integration/lot.api.test.ts
    check:
      - Lot CRUD 全部通过
      - 关联 route 正确返回
      - 分页查询正常
status: pending
```

### B008 — Recipe + ProcessStep + ProcessRoute API
```yaml
name: Recipe + ProcessStep + ProcessRoute API
description: |
  实现配方、工艺步骤和工艺路线的管理 API。
scope:
  do:
    - 创建 src/dto/recipe.dto.ts, process-step.dto.ts
    - 创建 src/services/recipe.service.ts, process-step.service.ts
    - 创建 src/routes/v1/recipe.ts, process-step.ts
    - 在 src/routes/v1/index.ts 注册
    - 编写单元测试 + 集成测试
    - 验证工艺路线包含完整步骤链
  dont:
    - 不实现工艺验证逻辑（留到 B011）
files:
  - apps/server/src/dto/recipe.dto.ts
  - apps/server/src/dto/process-step.dto.ts
  - apps/server/src/services/recipe.service.ts
  - apps/server/src/services/process-step.service.ts
  - apps/server/src/routes/v1/recipe.ts
  - apps/server/src/routes/v1/process-step.ts
  - apps/server/tests/unit/recipe.service.test.ts
  - apps/server/tests/unit/process-step.service.test.ts
  - apps/server/tests/integration/recipe.api.test.ts
dependencies:
  - B003  # Prisma Client
  - B004  # Fastify 骨架
  - B005  # 通用 DTO
verification:
  - cmd: cd apps/server && pnpm test tests/unit/recipe.service.test.ts
  - cmd: cd apps/server && pnpm test tests/integration/recipe.api.test.ts
    check:
      - Recipe CRUD 通过
      - ProcessStep CRUD 通过
      - ProcessRoute 包含完整步骤列表
status: pending
```

---

## Phase 4: 仿真控制 API

### B009 — Simulation Service + 控制 API
```yaml
name: Simulation Service + 控制 API
description: |
  实现仿真控制的核心 API：启动、暂停、停止、单步推进、重置、调速。
  管理 SimulationSession 状态。
scope:
  do:
    - 创建 src/services/simulation.service.ts
    - 创建 src/routes/v1/simulation.ts
    - 在 src/routes/v1/index.ts 注册
    - 实现状态机（stopped → running → paused → stopped）
    - 实现单步事件处理（读取 Event 表，按时间顺序处理）
    - 实现重置（清理所有状态，恢复初始数据）
    - 编写 Service 单元测试
    - 编写 API 集成测试
  dont:
    - 不实现复杂调度算法（由 @mes-expert 的 core 引擎指导）
    - 不涉及 WebSocket 推送（留到 B014）
files:
  - apps/server/src/services/simulation.service.ts
  - apps/server/src/routes/v1/simulation.ts
  - apps/server/tests/unit/simulation.service.test.ts
  - apps/server/tests/integration/simulation.api.test.ts
dependencies:
  - B003  # Prisma Client
  - B004  # Fastify 骨架
  - B006  # Equipment Service
  - B007  # Lot Service
verification:
  - cmd: cd apps/server && pnpm test tests/unit/simulation.service.test.ts
  - cmd: cd apps/server && pnpm test tests/integration/simulation.api.test.ts
    check:
      - POST /simulation/start 启动成功
      - POST /simulation/pause 暂停成功
      - POST /simulation/stop 停止成功
      - POST /simulation/step 单步推进
      - POST /simulation/reset 重置所有状态
      - POST /simulation/speed 调速成功
      - GET /simulation/status 返回当前状态
status: pending
```

### B010 — Event Log API
```yaml
name: Event Log API
description: |
  实现仿真事件日志的查询 API，支持按类型、时间范围筛选。
scope:
  do:
    - 创建 src/services/event.service.ts
    - 创建 src/routes/v1/event.ts
    - 在 src/routes/v1/index.ts 注册
    - 支持分页查询
    - 支持按 eventType 筛选
    - 支持按时间范围筛选
    - 编写集成测试
  dont:
    - 不实现事件自动创建（由仿真流程触发）
files:
  - apps/server/src/services/event.service.ts
  - apps/server/src/routes/v1/event.ts
  - apps/server/tests/integration/event.api.test.ts
dependencies:
  - B003  # Prisma Client
  - B004  # Fastify 骨架
verification:
  - cmd: cd apps/server && pnpm test tests/integration/event.api.test.ts
    check:
      - 事件列表分页查询
      - 按类型筛选正常
      - 按时间范围筛选正常
status: pending
```

---

## Phase 5: 工厂布局与配置

### B011 — Fab Layout API
```yaml
name: Fab Layout API
description: |
  实现工厂布局配置的 CRUD API。存储设备位置、缓冲区和仓储区配置。
scope:
  do:
    - 创建 src/services/fab-layout.service.ts
    - 创建 src/routes/v1/fab-layout.ts
    - 在 src/routes/v1/index.ts 注册
    - 支持默认布局标记
    - config 字段存储 JSON 序列化的 FabLayoutConfig
    - 编写集成测试
  dont:
    - 不验证布局的物理合理性（前端/3D 负责）
files:
  - apps/server/src/services/fab-layout.service.ts
  - apps/server/src/routes/v1/fab-layout.ts
  - apps/server/tests/integration/fab-layout.api.test.ts
dependencies:
  - B003  # Prisma Client
  - B004  # Fastify 骨架
  - @semi/core 的 FabLayoutConfig 类型
verification:
  - cmd: cd apps/server && pnpm test tests/integration/fab-layout.api.test.ts
    check:
      - 布局 CRUD 通过
      - 默认布局标记正确
      - JSON 序列化/反序列化正常
status: pending
```

---

## Phase 6: 数据种子与初始化

### B012 — Seed 数据脚本
```yaml
name: Seed 数据脚本
description: |
  创建数据库种子脚本，初始化演示数据：设备、工艺路线、Lot、配方。
  使用户启动后即可体验完整流程。
scope:
  do:
    - 创建 prisma/seed.ts
    - 定义标准 CMOS 工艺流程（7 步骤）
    - 创建设备（每种类型 1 台，带位置）
    - 创建示例 Lot
    - 创建示例 Recipe
    - 在 package.json 添加 db:seed 脚本
    - 验证种子数据导入成功
    - 编写 seed 测试（确认数据量正确）
  dont:
    - 不创建真实生产数据
files:
  - apps/server/prisma/seed.ts
  - apps/server/tests/unit/seed.test.ts
dependencies:
  - B002  # Prisma Schema
  - B006  # Equipment API
  - B007  # Lot API
  - B008  # Recipe API
verification:
  - cmd: cd apps/server && pnpm db:seed
  - cmd: cd apps/server && pnpm test tests/unit/seed.test.ts
    check:
      - 种子脚本执行成功
      - 设备数量正确（7 台）
      - 工艺路线步骤正确（7 步）
      - Lot 数量正确（1 个）
status: pending
```

---

## Phase 7: WebSocket 实时通信

### B013 — Socket.IO 集成与事件系统
```yaml
name: Socket.IO 集成与事件系统
description: |
  实现 WebSocket 实时通信层，建立命名空间和事件协议。
  为前端提供仿真状态实时推送。
scope:
  do:
    - 完善 src/plugins/socketio.ts（命名空间注册）
    - 创建 src/socket/namespaces/simulation.ts
    - 创建 src/socket/namespaces/equipment.ts
    - 创建 src/socket/namespaces/lot.ts
    - 创建 src/socket/middleware/auth.ts（简单的连接校验）
    - 创建 src/socket/events/simulation.events.ts
    - 创建 src/socket/events/equipment.events.ts
    - 创建 src/socket/events/lot.events.ts
    - 验证 Socket.IO 连接正常
    - 编写 WebSocket 集成测试
  dont:
    - 不实现业务事件触发逻辑（留到 B014）
    - 不实现复杂的认证（简单连接校验即可）
files:
  - apps/server/src/socket/namespaces/*.ts
  - apps/server/src/socket/events/*.ts
  - apps/server/src/socket/middleware/*.ts
  - apps/server/tests/integration/websocket.test.ts
dependencies:
  - B004  # Fastify 骨架（含 socketio 插件）
verification:
  - cmd: cd apps/server && pnpm test tests/integration/websocket.test.ts
    check:
      - Socket.IO 连接成功
      - 命名空间正确注册
      - 客户端可订阅事件
      - 客户端可发送命令
status: pending
```

### B014 — 实时事件广播集成
```yaml
name: 实时事件广播集成
description: |
  将 Service 层的状态变更与 WebSocket 事件广播打通。
  当数据变更时自动触发实时推送。
scope:
  do:
    - 在 EquipmentService 中集成状态变更广播
    - 在 LotService 中集成状态变更广播
    - 在 SimulationService 中集成仿真状态广播
    - 创建 src/socket/broadcaster.ts（统一广播工具）
    - 验证设备状态变更 → 前端收到 equipment:state-change
    - 验证 Lot 状态变更 → 前端收到 lot:status-change
    - 验证仿真启动 → 前端收到 simulation:state-change
    - 编写集成测试
  dont:
    - 不修改 Service 的业务逻辑（只增加广播钩子）
files:
  - apps/server/src/socket/broadcaster.ts
  - apps/server/src/services/equipment.service.ts  # 增加广播
  - apps/server/src/services/lot.service.ts  # 增加广播
  - apps/server/src/services/simulation.service.ts  # 增加广播
  - apps/server/tests/integration/broadcast.test.ts
dependencies:
  - B006  # Equipment Service
  - B007  # Lot Service
  - B009  # Simulation Service
  - B013  # Socket.IO 集成
verification:
  - cmd: cd apps/server && pnpm test tests/integration/broadcast.test.ts
    check:
      - 设备状态变更广播正确
      - Lot 状态变更广播正确
      - 仿真状态变更广播正确
status: pending
```

---

## Phase 8: 业务流程编排

### B015 — Lot 工艺流程状态流转
```yaml
name: Lot 工艺流程状态流转
description: |
  实现 Lot 在工艺流程中的状态流转逻辑：
  Waiting → Loading → Processing → Unloading → Completed（或进入下一步 Waiting）。
scope:
  do:
    - 在 LotService 中增加流程推进方法
    - 实现步骤完成检测（当前步骤 duration 到达）
    - 实现下一步分配（找到可用设备）
    - 实现流程完成检测（所有步骤执行完毕）
    - 实现等待超时检测
    - 编写单元测试（模拟完整流程）
    - 编写集成测试
  dont:
    - 不实现复杂调度算法（FIFO 简单分配即可）
    - 不涉及设备故障处理（留到 B016）
files:
  - apps/server/src/services/lot.service.ts  # 更新
  - apps/server/src/services/process-engine.ts  # 新增
  - apps/server/tests/unit/process-engine.test.ts
  - apps/server/tests/integration/process-flow.test.ts
dependencies:
  - B006  # Equipment Service
  - B007  # Lot Service
  - B008  # Recipe + ProcessStep Service
verification:
  - cmd: cd apps/server && pnpm test tests/unit/process-engine.test.ts
  - cmd: cd apps/server && pnpm test tests/integration/process-flow.test.ts
    check:
      - Lot 从 Waiting → Processing 流转正确
      - 步骤完成后进入下一步
      - 所有步骤完成后标记 Completed
      - 状态变更记录到数据库
status: pending
```

### B016 — 设备故障模拟 API
```yaml
name: 设备故障模拟 API
description: |
  实现设备故障注入 API，用于测试系统的容错能力。
scope:
  do:
    - 在 EquipmentService 中增加故障注入方法
    - 创建故障事件（状态变为 Error）
    - 实现故障恢复（状态恢复为 Idle）
    - 故障期间阻止新 Lot 分配
    - 创建 src/routes/v1/fault.ts（故障注入路由）
    - 编写单元测试 + 集成测试
  dont:
    - 不实现自动故障检测（手动触发）
files:
  - apps/server/src/services/equipment.service.ts  # 更新
  - apps/server/src/routes/v1/fault.ts
  - apps/server/src/routes/v1/index.ts  # 更新
  - apps/server/tests/integration/fault.api.test.ts
dependencies:
  - B006  # Equipment Service
  - B015  # 流程引擎
verification:
  - cmd: cd apps/server && pnpm test tests/integration/fault.api.test.ts
    check:
      - 故障注入成功（状态变为 Error）
      - 故障设备不再接收新 Lot
      - 故障恢复后设备可用
status: pending
```

---

## Phase 9: 统计与报告

### B017 — OEE 统计 API
```yaml
name: OEE 统计 API
description: |
  实现设备综合效率（OEE）统计 API：可用率、性能率、良率。
scope:
  do:
    - 创建 src/services/statistics.service.ts
    - 实现 OEE 计算（基于 StatusHistory）
    - 实现设备利用率统计
    - 实现吞吐量统计
    - 创建 src/routes/v1/statistics.ts
    - 在 src/routes/v1/index.ts 注册
    - 编写单元测试 + 集成测试
  dont:
    - 不实现实时统计（基于历史数据计算）
files:
  - apps/server/src/services/statistics.service.ts
  - apps/server/src/routes/v1/statistics.ts
  - apps/server/tests/unit/statistics.service.test.ts
  - apps/server/tests/integration/statistics.api.test.ts
dependencies:
  - B006  # Equipment Service（StatusHistory）
verification:
  - cmd: cd apps/server && pnpm test tests/unit/statistics.service.test.ts
  - cmd: cd apps/server && pnpm test tests/integration/statistics.api.test.ts
    check:
      - OEE 计算正确
      - 设备利用率统计正确
      - 吞吐量统计正确
status: pending
```

---

## Phase 10: 整合验证

### B018 — 完整构建与类型检查
```yaml
name: 完整构建与类型检查
description: |
  验证整个 apps/server 的构建、类型检查和导出完整性。
scope:
  do:
    - 确认所有路由已注册
    - 确认所有 Service 已导出
    - 确认所有 DTO 类型正确
    - 运行完整 lint + type-check + build + test
    - 验证无未使用的导入
    - 验证无类型错误
  dont:
    - 不修改业务代码（只验证）
files:
  - apps/server/src/**/*.ts
  - apps/server/tests/**/*.ts
dependencies:
  - 所有前置任务
verification:
  - cmd: cd apps/server && pnpm lint
  - cmd: cd apps/server && pnpm type-check
  - cmd: cd apps/server && pnpm build
  - cmd: cd apps/server && pnpm test
    check:
      - lint 无错误
      - type-check 无错误
      - build 成功（dist/ 生成）
      - 所有测试通过
status: pending
```

### B019 — 跨包集成验证
```yaml
name: 跨包集成验证
description: |
  验证前端（apps/web）能正确调用后端 API。
scope:
  do:
    - 启动后端服务（pnpm dev）
    - 启动前端服务（pnpm dev）
    - 验证前端可从后端获取设备列表
    - 验证前端可控制仿真启动/停止
    - 验证 WebSocket 连接和事件接收
    - 运行 make check（项目级验证）
  dont:
    - 不修改前端代码（只验证集成）
files:
  - 依赖 apps/web 和 apps/server 同时运行
  - 使用 tests/e2e/ 目录下的端到端测试
dependencies:
  - B018  # 后端构建通过
  - apps/web 已可运行
verification:
  - cmd: make check
    check:
      - 所有包的 lint 通过
      - 所有包的 type-check 通过
      - 后端服务器启动正常
      - 前端可正常调用后端 API
      - WebSocket 实时推送正常
status: pending
```

---

## 任务依赖图

```
Phase 0 (脚手架):
  B001 (项目初始化) ──→ B002 (Prisma Schema) ──→ B003 (Prisma Client)

Phase 1 (API 基础设施):
  B003 ──→ B004 (Fastify 骨架)
  B004 ──→ B005 (通用 DTO)

Phase 2 (设备管理):
  B003 + B004 + B005 ──→ B006 (Equipment API)

Phase 3 (Lot + 工艺):
  B003 + B004 + B005 ──→ B007 (Lot API)
  B003 + B004 + B005 ──→ B008 (Recipe API)

Phase 4 (仿真控制):
  B006 + B007 ──→ B009 (Simulation API)
  B003 + B004 ──→ B010 (Event Log API)

Phase 5 (布局配置):
  B003 + B004 ──→ B011 (Fab Layout API)

Phase 6 (数据种子):
  B006 + B007 + B008 ──→ B012 (Seed 数据)

Phase 7 (WebSocket):
  B004 ──→ B013 (Socket.IO 集成)
  B006 + B007 + B009 + B013 ──→ B014 (事件广播)

Phase 8 (业务流程):
  B006 + B007 + B008 ──→ B015 (流程引擎)
  B006 + B015 ──→ B016 (故障模拟)

Phase 9 (统计):
  B006 ──→ B017 (OEE 统计)

Phase 10 (验证):
  所有 ──→ B018 (完整构建)
  B018 ──→ B019 (跨包集成)
```

---

## 当前状态汇总

| 阶段 | 任务数 | pending | active | passing | blocked |
|------|-------|---------|--------|---------|---------|
| Phase 0 脚手架 | 3 | 3 | 0 | 0 | 0 |
| Phase 1 API 基础设施 | 2 | 2 | 0 | 0 | 0 |
| Phase 2 设备管理 | 1 | 1 | 0 | 0 | 0 |
| Phase 3 Lot + 工艺 | 2 | 2 | 0 | 0 | 0 |
| Phase 4 仿真控制 | 2 | 2 | 0 | 0 | 0 |
| Phase 5 布局配置 | 1 | 1 | 0 | 0 | 0 |
| Phase 6 数据种子 | 1 | 1 | 0 | 0 | 0 |
| Phase 7 WebSocket | 2 | 2 | 0 | 0 | 0 |
| Phase 8 业务流程 | 2 | 2 | 0 | 0 | 0 |
| Phase 9 统计 | 1 | 1 | 0 | 0 | 0 |
| Phase 10 验证 | 2 | 2 | 0 | 0 | 0 |
| **总计** | **19** | **19** | **0** | **0** | **0** |

---

## 与其他 Agent 的协作影响

| 任务 | 影响 | 通知对象 |
|------|------|---------|
| B002 (Prisma Schema) | 需要 core 的类型定义 | @mes-expert |
| B006 (Equipment API) | 提供设备数据给 3D/UI | @3d-expert, @ui-expert |
| B007 (Lot API) | 提供 Lot 数据给 3D/UI | @3d-expert, @ui-expert |
| B009 (Simulation API) | 仿真控制接口 | @ui-expert |
| B014 (事件广播) | WebSocket 协议定义 | @ui-expert |
| B015 (流程引擎) | 状态流转逻辑 | @mes-expert |
| B017 (OEE 统计) | 统计数据接口 | @ui-expert |

---

## 接口协议速查表

### RESTful API

| 方法 | 路径 | 功能 |
|------|------|------|
| GET | /api/v1/equipment | 设备列表 |
| GET | /api/v1/equipment/:id | 设备详情 |
| POST | /api/v1/equipment | 创建设备 |
| PUT | /api/v1/equipment/:id | 更新设备 |
| DELETE | /api/v1/equipment/:id | 删除设备 |
| GET | /api/v1/lot | Lot 列表 |
| GET | /api/v1/lot/:id | Lot 详情 |
| POST | /api/v1/lot | 创建 Lot |
| PUT | /api/v1/lot/:id | 更新 Lot |
| DELETE | /api/v1/lot/:id | 删除 Lot |
| GET | /api/v1/recipe | Recipe 列表 |
| POST | /api/v1/recipe | 创建 Recipe |
| GET | /api/v1/process-step | 工艺步骤列表 |
| GET | /api/v1/simulation/status | 仿真状态 |
| POST | /api/v1/simulation/start | 启动仿真 |
| POST | /api/v1/simulation/pause | 暂停仿真 |
| POST | /api/v1/simulation/stop | 停止仿真 |
| POST | /api/v1/simulation/step | 单步推进 |
| POST | /api/v1/simulation/reset | 重置仿真 |
| POST | /api/v1/simulation/speed | 调速 |
| GET | /api/v1/event | 事件日志 |
| GET | /api/v1/fab-layout | 工厂布局 |
| GET | /api/v1/statistics/oee | OEE 统计 |

### WebSocket Events

| 方向 | 事件名 | 数据 |
|------|--------|------|
| S→C | simulation:tick | { time, delta, speed } |
| S→C | simulation:state-change | { state, currentTime } |
| S→C | equipment:state-change | { equipmentId, oldStatus, newStatus } |
| S→C | lot:status-change | { lotId, oldStatus, newStatus, stepIndex } |
| S→C | system:alert | { level, message } |
| C→S | simulation:command | { action, params? } |
| C→S | equipment:command | { equipmentId, action, params? } |

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次任务状态变更时更新状态汇总表
