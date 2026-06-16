# Node.js 后端开发专家 — 后端架构设计文档

> 版本：v1.0 | 日期：2026-06-07
> 适用范围：`apps/server`
> 技术栈：Node.js 20 + TypeScript + Fastify + Prisma + SQLite + Socket.IO

---

## 1. 系统定位

### 1.1 在整体架构中的位置

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           用户交互层                                      │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  apps/web (Vue 3 + Vite)                                        │   │
│   │  - 3D 可视化 (Babylon.js)                                       │   │
│   │  - UI 组件 (@semi/ui)                                           │   │
│   └──────────────────────────────┬──────────────────────────────────┘   │
│                                  │ HTTP / WebSocket                     │
│                                  ▼                                     │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  apps/server (Fastify + Prisma)  ◄─── 你在这里                    │   │
│   │  - REST API                                                     │   │
│   │  - WebSocket 实时推送                                           │   │
│   │  - 业务逻辑编排                                                 │   │
│   │  - 数据持久化 (SQLite → PostgreSQL)                             │   │
│   └──────────────────────────────┬──────────────────────────────────┘   │
│                                  │ import type                          │
│                                  ▼                                     │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │  packages/core (纯 TypeScript)                                   │   │
│   │  - 领域模型接口 (Lot, Equipment, Recipe...)                      │   │
│   │  - 配置类型 (FabLayoutConfig, EquipmentConfig...)                │   │
│   │  - 离散事件仿真引擎 (SimulationEngine)                           │   │
│   └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 职责边界

| 职责 | apps/server 负责 | 不负责 |
|------|-----------------|--------|
| 数据存储 | ✅ SQLite/PostgreSQL 数据库管理 | ❌ 3D 渲染 |
| 业务逻辑 | ✅ Lot 状态流转、设备调度 | ❌ 前端 UI |
| 接口协议 | ✅ RESTful API + WebSocket | ❌ 核心仿真算法 |
| 数据验证 | ✅ 请求参数校验 (Zod) | ❌ 构建配置 |
| 实时推送 | ✅ Socket.IO 事件广播 | ❌ 路由管理 |

---

## 2. 分层架构

### 2.1 目录结构

```
apps/server/
├── prisma/
│   ├── schema.prisma           # 数据库模型定义
│   ├── migrations/             # 数据库迁移文件
│   └── seed.ts                 # 种子数据脚本
├── src/
│   ├── main.ts                 # 应用入口
│   ├── app.ts                  # Fastify 应用实例
│   ├── config/
│   │   ├── env.ts              # 环境变量配置
│   │   └── logger.ts           # 日志配置
│   ├── db/
│   │   ├── client.ts           # Prisma Client 单例
│   │   └── transaction.ts      # 事务工具
│   ├── plugins/
│   │   ├── cors.ts             # CORS 插件
│   │   ├── swagger.ts          # OpenAPI/Swagger 文档
│   │   ├── socketio.ts         # Socket.IO 集成
│   │   └── error-handler.ts    # 全局错误处理
│   ├── routes/
│   │   ├── v1/
│   │   │   ├── index.ts        # v1 路由注册
│   │   │   ├── equipment.ts    # 设备路由
│   │   │   ├── lot.ts          # Lot 路由
│   │   │   ├── recipe.ts       # Recipe 路由
│   │   │   ├── process-step.ts # 工艺步骤路由
│   │   │   ├── simulation.ts   # 仿真控制路由
│   │   │   ├── event.ts        # 事件日志路由
│   │   │   └── fab-layout.ts   # 工厂布局路由
│   │   └── health.ts           # 健康检查
│   ├── services/
│   │   ├── equipment.service.ts
│   │   ├── lot.service.ts
│   │   ├── recipe.service.ts
│   │   ├── process-step.service.ts
│   │   ├── simulation.service.ts
│   │   └── event.service.ts
│   ├── dto/
│   │   ├── equipment.dto.ts
│   │   ├── lot.dto.ts
│   │   ├── recipe.dto.ts
│   │   └── common.dto.ts       # 分页、排序等通用 DTO
│   ├── types/
│   │   └── index.ts            # 扩展类型定义
│   └── utils/
│       ├── nanoid.ts           # ID 生成
│       ├── problem-details.ts  # RFC 7807 错误格式
│       └── validation.ts       # Zod 校验工具
├── tests/
│   ├── unit/
│   │   ├── equipment.service.test.ts
│   │   ├── lot.service.test.ts
│   │   └── simulation.service.test.ts
│   └── integration/
│       ├── equipment.api.test.ts
│       ├── lot.api.test.ts
│       └── simulation.api.test.ts
├── .env.example
├── .env
├── package.json
├── tsconfig.json
├── vite.config.ts              # Vitest 配置
└── eslint.config.js
```

### 2.2 依赖方向

```
┌──────────────────────────────────────────┐
│              routes/                      │  ← HTTP 请求入口
│         (Fastify Route Handlers)          │
└─────────────────┬────────────────────────┘
                  │ 调用 Service
                  ▼
┌──────────────────────────────────────────┐
│             services/                     │  ← 业务逻辑层
│         (Service Classes)                 │
│  - 业务流程编排                            │
│  - 数据转换 (DTO ↔ Entity)                │
│  - 事务边界                                │
└─────────────────┬────────────────────────┘
                  │ 调用 Prisma
                  ▼
┌──────────────────────────────────────────┐
│               db/                         │  ← 数据访问层
│         (Prisma Client)                   │
└──────────────────────────────────────────┘
                  ▲
                  │ import type
┌─────────────────┴────────────────────────┐
│         @semi/core (packages/core)        │  ← 类型参照
│    (Lot, Equipment, Recipe, Config...)    │
└──────────────────────────────────────────┘
```

**铁律**：
- `routes` 只能调用 `services`，不能调用 `db`
- `services` 只能调用 `db`，不能调用 `routes`
- `routes` 和 `services` 都可以 `import type` 从 `@semi/core`
- 不允许跨层调用（Service 不能调用另一个 Service 的私有方法，只能通过公开接口）

---

## 3. 数据库设计

### 3.1 Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

// ─────────────────────────────────────────
// 设备 Equipment
// ─────────────────────────────────────────
model Equipment {
  id            String          @id @default(cuid())
  name          String
  type          String          // EquipmentType enum 值
  status        String          @default("Idle") // EquipmentStatus enum 值
  positionX     Float
  positionY     Float
  positionZ     Float           @default(0)
  throughput    Int             @default(1)
  currentLotId  String?
  recipeId      String?
  config        String?         // JSON: EquipmentConfig
  createdAt     DateTime        @default(now())
  updatedAt     DateTime        @updatedAt

  // 关系
  currentLot    Lot?            @relation("EquipmentCurrentLot", fields: [currentLotId], references: [id])
  assignedLots  Lot[]           @relation("EquipmentAssignedLot")
  events        Event[]         @relation("EquipmentEvents")
  statusHistory StatusHistory[]

  @@index([type])
  @@index([status])
}

// ─────────────────────────────────────────
// Lot 批次
// ─────────────────────────────────────────
model Lot {
  id              String      @id @default(cuid())
  name            String
  waferCount      Int         @default(25)
  currentStepIndex Int        @default(0)
  routeId         String
  currentEquipmentId String?
  priority        Int         @default(0)
  status          String      @default("Waiting") // LotStatus enum 值
  createdAt       DateTime    @default(now())
  enteredStepAt   DateTime    @default(now())

  // 关系
  currentEquipment Equipment?  @relation("EquipmentCurrentLot", fields: [currentEquipmentId], references: [id])
  assignedTo      Equipment?  @relation("EquipmentAssignedLot", fields: [currentEquipmentId], references: [id])
  events          Event[]     @relation("LotEvents")
  route           ProcessRoute @relation(fields: [routeId], references: [id])

  @@index([status])
  @@index([routeId])
}

// ─────────────────────────────────────────
// 工艺路线 ProcessRoute
// ─────────────────────────────────────────
model ProcessRoute {
  id          String        @id @default(cuid())
  name        String
  description String?
  steps       ProcessStep[]
  lots        Lot[]
  createdAt   DateTime      @default(now())
}

// ─────────────────────────────────────────
// 工艺步骤 ProcessStep
// ─────────────────────────────────────────
model ProcessStep {
  id          String      @id @default(cuid())
  routeId     String
  name        String
  stepIndex   Int
  equipmentType String    // EquipmentType enum 值
  duration    Int         // 加工时长（秒）
  recipeId    String?
  description String?
  
  route       ProcessRoute @relation(fields: [routeId], references: [id], onDelete: Cascade)
  recipe      Recipe?      @relation(fields: [recipeId], references: [id])

  @@index([routeId])
}

// ─────────────────────────────────────────
// Recipe 配方
// ─────────────────────────────────────────
model Recipe {
  id          String        @id @default(cuid())
  name        String
  equipmentType String      // EquipmentType enum 值
  parameters  String        // JSON: Recipe 参数对象
  duration    Int           // 加工时长（秒）
  description String?
  steps       ProcessStep[]
  createdAt   DateTime      @default(now())
}

// ─────────────────────────────────────────
// 仿真事件 Event
// ─────────────────────────────────────────
model Event {
  id            String    @id @default(cuid())
  type          String    // 事件类型: LotArrival, EquipmentReady, ProcessComplete...
  equipmentId   String?
  lotId         String?
  timestamp     DateTime  @default(now())
  data          String?   // JSON: 事件附加数据
  processed     Boolean   @default(false)

  equipment     Equipment? @relation("EquipmentEvents", fields: [equipmentId], references: [id])
  lot           Lot?       @relation("LotEvents", fields: [lotId], references: [id])

  @@index([type])
  @@index([timestamp])
  @@index([processed])
}

// ─────────────────────────────────────────
// 状态历史 StatusHistory
// ─────────────────────────────────────────
model StatusHistory {
  id          String    @id @default(cuid())
  equipmentId String
  oldStatus   String
  newStatus   String
  timestamp   DateTime  @default(now())
  reason      String?

  equipment   Equipment @relation(fields: [equipmentId], references: [id], onDelete: Cascade)

  @@index([equipmentId])
}

// ─────────────────────────────────────────
// 工厂布局 FabLayout
// ─────────────────────────────────────────
model FabLayout {
  id        String   @id @default(cuid())
  name      String
  config    String   // JSON: FabLayoutConfig
  isDefault Boolean  @default(false)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

// ─────────────────────────────────────────
// 仿真会话 SimulationSession
// ─────────────────────────────────────────
model SimulationSession {
  id          String    @id @default(cuid())
  status      String    @default("stopped") // running, paused, stopped
  currentTime Int       @default(0)         // 仿真时间（秒）
  speed       Int       @default(1)         // 速度倍率
  startedAt   DateTime?
  pausedAt    DateTime?
  stoppedAt   DateTime?
  config      String?   // JSON: 仿真配置
  createdAt   DateTime  @default(now())
}
```

### 3.2 与 Core 类型的映射关系

| `@semi/core` 接口 | Prisma Model | 差异说明 |
|------------------|-------------|---------|
| `Lot` | `Lot` | 增加 `route` 关系字段 |
| `Equipment` | `Equipment` | 增加 `statusHistory` 关系 |
| `Recipe` | `Recipe` | `parameters` 为 JSON 字符串存储 |
| `ProcessStep` | `ProcessStep` | 增加 `route` 外键关联 |
| `FabLayoutConfig` | `FabLayout` | `config` 字段存储完整 JSON |
| — | `ProcessRoute` | 新增：聚合工艺步骤 |
| — | `Event` | 新增：离散事件存储 |
| — | `StatusHistory` | 新增：状态变更追踪 |
| — | `SimulationSession` | 新增：仿真会话管理 |

---

## 4. API 设计

### 4.1 路由注册表

```typescript
// src/routes/v1/index.ts

import type { FastifyInstance } from 'fastify'
import equipmentRoutes from './equipment'
import lotRoutes from './lot'
import recipeRoutes from './recipe'
import processStepRoutes from './process-step'
import simulationRoutes from './simulation'
import eventRoutes from './event'
import fabLayoutRoutes from './fab-layout'

export default async function v1Routes(fastify: FastifyInstance) {
  fastify.register(equipmentRoutes, { prefix: '/equipment' })
  fastify.register(lotRoutes, { prefix: '/lot' })
  fastify.register(recipeRoutes, { prefix: '/recipe' })
  fastify.register(processStepRoutes, { prefix: '/process-step' })
  fastify.register(simulationRoutes, { prefix: '/simulation' })
  fastify.register(eventRoutes, { prefix: '/event' })
  fastify.register(fabLayoutRoutes, { prefix: '/fab-layout' })
}
```

### 4.2 设备路由详细设计

```typescript
// src/routes/v1/equipment.ts

import type { FastifyInstance } from 'fastify'
import { EquipmentService } from '../../services/equipment.service'
import {
  CreateEquipmentDto,
  UpdateEquipmentDto,
  EquipmentResponseDto,
  EquipmentListQueryDto
} from '../../dto/equipment.dto'

export default async function equipmentRoutes(fastify: FastifyInstance) {
  const service = new EquipmentService(fastify.prisma)

  // GET /api/v1/equipment?type=&status=&page=&limit=
  fastify.get('/', {
    schema: {
      querystring: EquipmentListQueryDto,
      response: { 200: EquipmentListResponseDto }
    }
  }, async (request, reply) => {
    const result = await service.findMany(request.query)
    return reply.send(result)
  })

  // GET /api/v1/equipment/:id
  fastify.get('/:id', {
    schema: {
      params: IdParamDto,
      response: { 200: EquipmentResponseDto, 404: ProblemDetailsDto }
    }
  }, async (request, reply) => {
    const equipment = await service.findById(request.params.id)
    if (!equipment) {
      return reply.status(404).send(problemDetails.notFound('Equipment', request.params.id))
    }
    return reply.send(equipment)
  })

  // POST /api/v1/equipment
  fastify.post('/', {
    schema: {
      body: CreateEquipmentDto,
      response: { 201: EquipmentResponseDto, 400: ProblemDetailsDto }
    }
  }, async (request, reply) => {
    const equipment = await service.create(request.body)
    return reply.status(201).send(equipment)
  })

  // PUT /api/v1/equipment/:id
  fastify.put('/:id', {
    schema: {
      params: IdParamDto,
      body: UpdateEquipmentDto,
      response: { 200: EquipmentResponseDto, 404: ProblemDetailsDto }
    }
  }, async (request, reply) => {
    const equipment = await service.update(request.params.id, request.body)
    return reply.send(equipment)
  })

  // DELETE /api/v1/equipment/:id
  fastify.delete('/:id', {
    schema: {
      params: IdParamDto,
      response: { 204: {}, 404: ProblemDetailsDto }
    }
  }, async (request, reply) => {
    await service.delete(request.params.id)
    return reply.status(204).send()
  })
}
```

### 4.3 仿真控制路由

```typescript
// src/routes/v1/simulation.ts

import type { FastifyInstance } from 'fastify'
import { SimulationService } from '../../services/simulation.service'

export default async function simulationRoutes(fastify: FastifyInstance) {
  const service = new SimulationService(fastify.prisma)

  // GET /api/v1/simulation/status
  fastify.get('/status', async () => {
    return service.getStatus()
  })

  // POST /api/v1/simulation/start
  fastify.post('/start', async (request, reply) => {
    const result = await service.start()
    // 同时通过 WebSocket 广播
    fastify.io.emit('simulation:state-change', { state: 'running' })
    return reply.send(result)
  })

  // POST /api/v1/simulation/pause
  fastify.post('/pause', async (request, reply) => {
    const result = await service.pause()
    fastify.io.emit('simulation:state-change', { state: 'paused' })
    return reply.send(result)
  })

  // POST /api/v1/simulation/stop
  fastify.post('/stop', async (request, reply) => {
    const result = await service.stop()
    fastify.io.emit('simulation:state-change', { state: 'stopped' })
    return reply.send(result)
  })

  // POST /api/v1/simulation/step
  fastify.post('/step', async (request, reply) => {
    const result = await service.step()
    return reply.send(result)
  })

  // POST /api/v1/simulation/reset
  fastify.post('/reset', async (request, reply) => {
    const result = await service.reset()
    fastify.io.emit('simulation:state-change', { state: 'stopped' })
    return reply.send(result)
  })

  // POST /api/v1/simulation/speed
  fastify.post('/speed', {
    schema: {
      body: z.object({ speed: z.number().min(1).max(100) })
    }
  }, async (request, reply) => {
    const result = await service.setSpeed(request.body.speed)
    return reply.send(result)
  })
}
```

---

## 5. Service 层设计

### 5.1 设备服务

```typescript
// src/services/equipment.service.ts

import type { PrismaClient } from '@prisma/client'
import type { 
  Equipment, 
  EquipmentStatus, 
  EquipmentType 
} from '@semi/core'
import type { 
  CreateEquipmentDto, 
  UpdateEquipmentDto,
  EquipmentListQueryDto 
} from '../dto/equipment.dto'

export class EquipmentService {
  constructor(private db: PrismaClient) {}

  async findById(id: string): Promise<Equipment | null> {
    const record = await this.db.equipment.findUnique({
      where: { id },
      include: { currentLot: true }
    })
    return record ? this.toDomain(record) : null
  }

  async findMany(query: EquipmentListQueryDto): Promise<{ items: Equipment[]; total: number }> {
    const { type, status, page = 1, limit = 20 } = query
    const where = {
      ...(type && { type }),
      ...(status && { status })
    }

    const [items, total] = await Promise.all([
      this.db.equipment.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        include: { currentLot: true },
        orderBy: { name: 'asc' }
      }),
      this.db.equipment.count({ where })
    ])

    return { items: items.map(this.toDomain), total }
  }

  async create(dto: CreateEquipmentDto): Promise<Equipment> {
    const record = await this.db.equipment.create({
      data: {
        id: generateNanoid(),
        name: dto.name,
        type: dto.type,
        status: dto.status ?? 'Idle',
        positionX: dto.positionX,
        positionY: dto.positionY,
        positionZ: dto.positionZ ?? 0,
        throughput: dto.throughput ?? 1,
        config: dto.config ? JSON.stringify(dto.config) : null
      }
    })
    return this.toDomain(record)
  }

  async update(id: string, dto: UpdateEquipmentDto): Promise<Equipment> {
    const oldRecord = await this.db.equipment.findUnique({ where: { id } })
    if (!oldRecord) throw new NotFoundError('Equipment', id)

    const record = await this.db.$transaction(async (tx) => {
      // 如果状态变更，记录历史
      if (dto.status && dto.status !== oldRecord.status) {
        await tx.statusHistory.create({
          data: {
            equipmentId: id,
            oldStatus: oldRecord.status,
            newStatus: dto.status,
            reason: dto.statusChangeReason
          }
        })
      }

      return tx.equipment.update({
        where: { id },
        data: {
          ...(dto.name && { name: dto.name }),
          ...(dto.status && { status: dto.status }),
          ...(dto.currentLotId !== undefined && { currentLotId: dto.currentLotId }),
          ...(dto.config && { config: JSON.stringify(dto.config) })
        }
      })
    })

    return this.toDomain(record)
  }

  async delete(id: string): Promise<void> {
    await this.db.equipment.delete({ where: { id } })
  }

  private toDomain(record: PrismaEquipment): Equipment {
    return {
      id: record.id,
      name: record.name,
      type: record.type as EquipmentType,
      status: record.status as EquipmentStatus,
      position: {
        x: record.positionX,
        y: record.positionY,
        z: record.positionZ
      },
      throughput: record.throughput,
      currentLotId: record.currentLotId ?? undefined,
      config: record.config ? JSON.parse(record.config) : undefined
    }
  }
}
```

### 5.2 仿真服务

```typescript
// src/services/simulation.service.ts

import type { PrismaClient } from '@prisma/client'

export class SimulationService {
  constructor(private db: PrismaClient) {}

  async getStatus(): Promise<SimulationStatus> {
    const session = await this.db.simulationSession.findFirst({
      orderBy: { createdAt: 'desc' }
    })

    return {
      state: session?.status ?? 'stopped',
      currentTime: session?.currentTime ?? 0,
      speed: session?.speed ?? 1
    }
  }

  async start(): Promise<SimulationStatus> {
    return this.db.$transaction(async (tx) => {
      // 停止之前的会话
      await tx.simulationSession.updateMany({
        where: { status: { in: ['running', 'paused'] } },
        data: { status: 'stopped', stoppedAt: new Date() }
      })

      const session = await tx.simulationSession.create({
        data: {
          status: 'running',
          startedAt: new Date(),
          currentTime: 0,
          speed: 1
        }
      })

      return {
        state: session.status,
        currentTime: session.currentTime,
        speed: session.speed
      }
    })
  }

  async pause(): Promise<SimulationStatus> {
    const session = await this.db.simulationSession.updateMany({
      where: { status: 'running' },
      data: { status: 'paused', pausedAt: new Date() }
    })

    return this.getStatus()
  }

  async stop(): Promise<SimulationStatus> {
    await this.db.simulationSession.updateMany({
      where: { status: { in: ['running', 'paused'] } },
      data: { status: 'stopped', stoppedAt: new Date() }
    })

    return this.getStatus()
  }

  async step(): Promise<SimulationStatus> {
    // 单步推进：处理下一个事件
    const nextEvent = await this.db.event.findFirst({
      where: { processed: false },
      orderBy: { timestamp: 'asc' }
    })

    if (nextEvent) {
      await this.processEvent(nextEvent.id)
    }

    return this.getStatus()
  }

  async reset(): Promise<SimulationStatus> {
    return this.db.$transaction(async (tx) => {
      // 重置所有状态
      await tx.simulationSession.updateMany({
        where: { status: { in: ['running', 'paused'] } },
        data: { status: 'stopped', stoppedAt: new Date() }
      })

      await tx.event.deleteMany({})
      await tx.statusHistory.deleteMany({})

      await tx.lot.updateMany({
        data: {
          status: 'Waiting',
          currentStepIndex: 0,
          currentEquipmentId: null
        }
      })

      await tx.equipment.updateMany({
        data: {
          status: 'Idle',
          currentLotId: null
        }
      })

      return this.getStatus()
    })
  }

  async setSpeed(speed: number): Promise<SimulationStatus> {
    await this.db.simulationSession.updateMany({
      where: { status: { in: ['running', 'paused'] } },
      data: { speed }
    })

    return this.getStatus()
  }

  private async processEvent(eventId: string): Promise<void> {
    // 事件处理逻辑 —— 由 @mes-expert 的 SimulationEngine 算法指导
    // 这里只是数据库状态更新
  }
}
```

---

## 6. WebSocket 实时通信

### 6.1 Socket.IO 命名空间设计

```
/simulation    — 仿真状态相关事件
/equipment     — 设备状态相关事件
/lot           — Lot 状态相关事件
/system        — 系统级事件（告警、通知）
```

### 6.2 事件类型定义

```typescript
// src/types/socket-events.ts

export interface ServerToClientEvents {
  'simulation:tick': (data: {
    time: number
    delta: number
    speed: number
  }) => void

  'simulation:event': (data: {
    type: string
    data: unknown
    timestamp: number
  }) => void

  'simulation:state-change': (data: {
    state: 'running' | 'paused' | 'stopped'
    currentTime: number
  }) => void

  'equipment:state-change': (data: {
    equipmentId: string
    oldStatus: string
    newStatus: string
    timestamp: number
  }) => void

  'lot:status-change': (data: {
    lotId: string
    oldStatus: string
    newStatus: string
    stepIndex: number
    equipmentId?: string
  }) => void

  'system:alert': (data: {
    level: 'info' | 'warning' | 'error'
    message: string
    timestamp: number
  }) => void
}

export interface ClientToServerEvents {
  'simulation:command': (data: {
    action: 'start' | 'pause' | 'reset' | 'step'
    params?: Record<string, unknown>
  }) => void

  'equipment:command': (data: {
    equipmentId: string
    action: 'load' | 'start' | 'unload' | 'maintenance'
    params?: Record<string, unknown>
  }) => void
}
```

### 6.3 广播触发点

| 触发场景 | 广播事件 | 发送目标 |
|---------|---------|---------|
| 仿真启动/暂停/停止 | `simulation:state-change` | 所有客户端 |
| 仿真时间推进 | `simulation:tick` | 所有客户端 |
| 设备状态变更 | `equipment:state-change` | 所有客户端 |
| Lot 状态变更 | `lot:status-change` | 所有客户端 |
| 系统异常 | `system:alert` | 所有客户端 |

---

## 7. DTO 设计

### 7.1 通用 DTO

```typescript
// src/dto/common.dto.ts

import { z } from 'zod'

export const IdParamDto = z.object({
  id: z.string().min(1)
})

export const PaginationQueryDto = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(20)
})

export const ProblemDetailsDto = z.object({
  type: z.string().url(),
  title: z.string(),
  status: z.number(),
  detail: z.string().optional(),
  instance: z.string().optional()
})
```

### 7.2 设备 DTO

```typescript
// src/dto/equipment.dto.ts

import { z } from 'zod'
import { EquipmentType, EquipmentStatus } from '@semi/core'

export const CreateEquipmentDto = z.object({
  name: z.string().min(1).max(100),
  type: z.enum(['Lithography', 'Etching', 'Deposition', 'Implantation', 'Cleaning', 'Inspection', 'Annealing']),
  status: z.enum(['Idle', 'Loading', 'Processing', 'Unloading', 'Error', 'Maintenance']).optional(),
  positionX: z.number(),
  positionY: z.number(),
  positionZ: z.number().optional(),
  throughput: z.number().int().positive().optional(),
  config: z.record(z.unknown()).optional()
})

export const UpdateEquipmentDto = z.object({
  name: z.string().min(1).max(100).optional(),
  status: z.enum(['Idle', 'Loading', 'Processing', 'Unloading', 'Error', 'Maintenance']).optional(),
  currentLotId: z.string().nullable().optional(),
  config: z.record(z.unknown()).optional(),
  statusChangeReason: z.string().optional()
})

export const EquipmentListQueryDto = z.object({
  type: z.string().optional(),
  status: z.string().optional(),
  ...PaginationQueryDto.shape
})

export const EquipmentResponseDto = z.object({
  id: z.string(),
  name: z.string(),
  type: z.string(),
  status: z.string(),
  position: z.object({ x: z.number(), y: z.number(), z: z.number() }),
  throughput: z.number(),
  currentLotId: z.string().optional(),
  currentLot: z.object({ id: z.string(), name: z.string() }).optional(),
  createdAt: z.string().datetime()
})
```

---

## 8. 错误处理

### 8.1 全局错误处理器

```typescript
// src/plugins/error-handler.ts

import type { FastifyInstance } from 'fastify'

export default async function errorHandlerPlugin(fastify: FastifyInstance) {
  fastify.setErrorHandler((error, request, reply) => {
    fastify.log.error(error)

    if (error instanceof NotFoundError) {
      return reply.status(404).send({
        type: 'https://api.semi-mes.dev/errors/not-found',
        title: 'Resource not found',
        status: 404,
        detail: error.message,
        instance: request.url
      })
    }

    if (error instanceof ValidationError) {
      return reply.status(400).send({
        type: 'https://api.semi-mes.dev/errors/validation-error',
        title: 'Validation error',
        status: 400,
        detail: error.message,
        instance: request.url
      })
    }

    // 未知错误
    return reply.status(500).send({
      type: 'https://api.semi-mes.dev/errors/internal-error',
      title: 'Internal server error',
      status: 500,
      detail: process.env.NODE_ENV === 'development' ? error.message : 'An unexpected error occurred',
      instance: request.url
    })
  })
}
```

### 8.2 自定义错误类

```typescript
// src/utils/errors.ts

export class NotFoundError extends Error {
  constructor(resource: string, id: string) {
    super(`${resource} with id '${id}' not found`)
    this.name = 'NotFoundError'
  }
}

export class ValidationError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ValidationError'
  }
}

export class ConflictError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ConflictError'
  }
}
```

---

## 9. 数据种子（Seed）

### 9.1 初始数据脚本

```typescript
// prisma/seed.ts

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  // 清空现有数据
  await prisma.statusHistory.deleteMany()
  await prisma.event.deleteMany()
  await prisma.lot.deleteMany()
  await prisma.equipment.deleteMany()
  await prisma.processStep.deleteMany()
  await prisma.processRoute.deleteMany()
  await prisma.recipe.deleteMany()
  await prisma.simulationSession.deleteMany()
  await prisma.fabLayout.deleteMany()

  // 创建示例工艺路线
  const route = await prisma.processRoute.create({
    data: {
      name: 'Standard CMOS Process',
      description: '标准 CMOS 工艺流程',
      steps: {
        create: [
          { name: 'Cleaning', stepIndex: 0, equipmentType: 'Cleaning', duration: 300 },
          { name: 'Oxidation', stepIndex: 1, equipmentType: 'Deposition', duration: 1800 },
          { name: 'Photolithography', stepIndex: 2, equipmentType: 'Lithography', duration: 1200 },
          { name: 'Etching', stepIndex: 3, equipmentType: 'Etching', duration: 900 },
          { name: 'Ion Implantation', stepIndex: 4, equipmentType: 'Implantation', duration: 600 },
          { name: 'Annealing', stepIndex: 5, equipmentType: 'Annealing', duration: 2400 },
          { name: 'Inspection', stepIndex: 6, equipmentType: 'Inspection', duration: 600 }
        ]
      }
    }
  })

  // 创建示例设备
  const equipmentTypes = ['Cleaning', 'Deposition', 'Lithography', 'Etching', 'Implantation', 'Annealing', 'Inspection']
  const positions = [
    { x: 0, y: 0 }, { x: 10, y: 0 }, { x: 20, y: 0 },
    { x: 0, y: 10 }, { x: 10, y: 10 }, { x: 20, y: 10 },
    { x: 30, y: 5 }
  ]

  for (let i = 0; i < equipmentTypes.length; i++) {
    await prisma.equipment.create({
      data: {
        name: `${equipmentTypes[i]}-01`,
        type: equipmentTypes[i],
        status: 'Idle',
        positionX: positions[i].x,
        positionY: positions[i].y,
        throughput: 1 + Math.floor(Math.random() * 3)
      }
    })
  }

  // 创建示例 Lot
  await prisma.lot.create({
    data: {
      name: 'LOT-2024001',
      waferCount: 25,
      routeId: route.id,
      priority: 1,
      status: 'Waiting'
    }
  })

  console.log('✅ Seed data created successfully')
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
```

---

## 10. 测试策略

### 10.1 测试结构

```
tests/
├── unit/
│   ├── equipment.service.test.ts     # 设备服务单元测试
│   ├── lot.service.test.ts           # Lot 服务单元测试
│   ├── simulation.service.test.ts    # 仿真服务单元测试
│   └── recipe.service.test.ts        # Recipe 服务单元测试
└── integration/
    ├── equipment.api.test.ts         # 设备 API 集成测试
    ├── lot.api.test.ts               # Lot API 集成测试
    ├── simulation.api.test.ts        # 仿真 API 集成测试
    └── setup.ts                      # 测试环境初始化
```

### 10.2 测试工具配置

```typescript
// tests/setup.ts

import { PrismaClient } from '@prisma/client'

export const prisma = new PrismaClient()

export async function setupTestDatabase() {
  // 每次测试前清理数据
  await prisma.$transaction([
    prisma.statusHistory.deleteMany(),
    prisma.event.deleteMany(),
    prisma.lot.deleteMany(),
    prisma.equipment.deleteMany(),
    prisma.processStep.deleteMany(),
    prisma.processRoute.deleteMany(),
    prisma.recipe.deleteMany()
  ])
}
```

---

## 11. 与 feature_list.json 的映射

| Feature ID | 名称 | 后端任务 | 说明 |
|-----------|------|---------|------|
| F005 | Web 主应用界面 | — | 纯前端，不涉及 |
| F006 | 3D 场景构建 | — | 纯 3D，不涉及 |
| F007 | 工艺流程仿真 | B004-B006 | 仿真数据接口 |
| F008 | 仿真控制面板 | B007 | 仿真控制 API |
| F009 | 设备详情弹窗 | B002 | 设备 CRUD API |
| F010 | WIP 追踪看板 | B003 | Lot 状态查询 API |
| F011 | OEE 看板 | B008 | 统计数据 API |
| F012 | 故障注入测试 | B009 | 故障模拟 API |

---

## 12. 环境配置

### 12.1 package.json

```json
{
  "name": "@semi/server",
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "tsx watch src/main.ts",
    "build": "tsc",
    "start": "node dist/main.js",
    "db:migrate": "prisma migrate dev",
    "db:generate": "prisma generate",
    "db:seed": "tsx prisma/seed.ts",
    "db:studio": "prisma studio",
    "lint": "eslint src",
    "type-check": "tsc --noEmit",
    "test": "vitest run",
    "test:watch": "vitest"
  },
  "dependencies": {
    "@fastify/cors": "^9.0.0",
    "@fastify/swagger": "^8.0.0",
    "@fastify/swagger-ui": "^3.0.0",
    "@prisma/client": "^6.0.0",
    "@semi/core": "workspace:*",
    "fastify": "^5.0.0",
    "nanoid": "^5.0.0",
    "socket.io": "^4.0.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "prisma": "^6.0.0",
    "supertest": "^7.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.4.0",
    "vitest": "^1.0.0"
  }
}
```

### 12.2 tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

---

## 13. 与其他 Agent 的协作

| Agent | 交互方式 | 内容 |
|-------|---------|------|
| `@mes-expert` | `import type` | 导入 Lot, Equipment, Recipe 等类型定义 |
| `@ui-expert` | HTTP API + WebSocket | 提供 RESTful 接口和实时事件 |
| `@3d-expert` | HTTP API + WebSocket | 提供设备/Lot 位置数据和状态变更事件 |

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次新增/修改 API 或数据库模型时更新
