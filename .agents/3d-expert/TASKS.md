# 3D 半导体工厂场景专家 — 最小原子任务清单

> 本文件是所有 3D 场景开发任务的唯一真实来源。
> **规则**: 每个任务必须是单一职责、独立验证、可回滚的原子单元。
> **禁止**: 一次执行多个任务，或跳过验证直接标记完成。

---

## 任务状态图例

| 状态 | 图标 | 说明 |
|------|------|------|
| pending | ⏸ | 等待执行 |
| active | 🔄 | 正在执行 |
| passing | ✅ | 验证通过 |
| blocked | 🔒 | 依赖未满足 |

---

## Phase 1: 场景基础设施

### T001 — SceneGraph 场景图管理
```yaml
name: SceneGraph 场景图管理
description: |
  实现场景图的数据结构，维护 3D 节点的层级父子关系。
  支持：添加节点、删除节点、按 ID 查找、按类型查找、深度/广度遍历。
scope:
  do:
    - 实现 SceneNode 接口和 SceneNodeType 类型
    - 实现 SceneGraph 类，包含 root 节点和 nodeMap
    - addNode()、removeNode()、findNode()、getNodesByType()
    - traverse() 深度遍历、traverseBreadth() 广度遍历
  dont:
    - 不实现 Mesh 创建（那是 AssetFactory 的职责）
    - 不实现渲染逻辑
    - 不处理 JSON 配置解析（那是 SceneBuilder 的职责）
files:
  - src/scene-graph/scene-graph.ts
  - src/scene-graph/scene-graph.test.ts
dependencies: []  # 无依赖，最先实现
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/scene-graph/scene-graph.test.ts
    check:
      - 可以创建 root 节点
      - 可以添加子节点并建立父子关系
      - findNode() 能按 ID 查找
      - getNodesByType() 能按类型过滤
      - removeNode() 会级联删除子节点
      - traverse() 按深度优先顺序访问所有节点
status: pending
```

### T002 — AssetFactory 注册机制
```yaml
name: AssetFactory 统一资产生成器注册表
description: |
  实现 AssetFactory 的注册表机制，允许注册和调用不同类型的资产生成器。
  这是所有 3D 资产的统一入口。
scope:
  do:
    - 定义 AssetConfig 接口和 AssetGenerator 类型
    - 实现 AssetFactory 类
    - register(type, generator) 注册生成器
    - create(scene, config) 根据 type 调用对应生成器
    - 未注册类型时抛出友好错误
    - 内置一个默认的 fallback 生成器（透明立方体）
  dont:
    - 不实现具体的资产生成器（如 createBuffer、createEquipment）
    - 那是后续任务的职责，这里只搭框架
files:
  - src/assets/asset-factory.ts
  - src/assets/asset-factory.test.ts
dependencies:
  - T001  # 需要 SceneNodeType 概念，但 AssetFactory 不直接依赖 SceneGraph
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/asset-factory.test.ts
    check:
      - 可以注册自定义生成器
      - create() 能调用已注册的生成器
      - 未注册类型抛出 SceneBuildError
      - fallback 生成器返回有效的 TransformNode
status: pending
```

### T003 — SceneBuilder 配置解析与场景构建
```yaml
name: SceneBuilder 场景构建器
description: |
  实现 SceneBuilder 类，消费 @semi/core 定义的 FabLayoutConfig，调用 AssetFactory 创建 3D 场景。
  
  ⚠️ 重要：SceneBuilder **不定义**业务配置类型（EquipmentConfig/BufferConfig 等）。
  这些类型由 @mes-expert 在 packages/core 中定义并导出。
  SceneBuilder 只导入并使用这些类型。
scope:
  do:
    - 导入 @semi/core 的配置类型（FabLayoutConfig, EquipmentConfig, BufferConfig 等）
    - 定义 Scene3DConfig 接口（3D 场景特有配置：camera, light, fog, grid）
    - 定义 VisualOverride 接口（视觉覆盖配置）
    - 定义 SceneConfig 接口（业务配置 + 3D 覆盖配置的组合）
    - 实现 SceneBuilder.build() 方法
    - 实现 SceneBuilder.buildFromLayout() 方法（只传入业务配置，使用默认 3D 参数）
    - 实现增量更新方法（updateWorkArea, updateEquipment, updateBuffer）
    - 3D 配置默认值填充
  dont:
    - ❌ 不定义业务配置类型（EquipmentConfig, BufferConfig, StockerConfig 等）
    - ❌ 不实现业务配置验证（那是 @mes-expert 的职责）
    - ❌ 不创建具体的资产（调用 AssetFactory.create 即可）
    - ❌ 不处理运行时数据同步（那是 EntityManager 的职责）
files:
  - src/scene/scene-builder.ts
  - src/scene/scene-builder.test.ts
  # ❌ 删除: src/config/scene-config.ts — 业务配置类型由 @semi/core 定义
dependencies:
  - T001  # SceneGraph
  - T002  # AssetFactory
  - @semi/core  # 业务配置类型（FabLayoutConfig 等）
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/scene/scene-builder.test.ts
    check:
      - 可以导入 @semi/core 的 FabLayoutConfig
      - build() 能解析 SceneConfig（业务配置 + 3D 配置）
      - buildFromLayout() 只接收业务配置也能工作
      - 无效配置抛出明确错误
      - 生成的 SceneGraph 包含预期的节点
status: pending
```

---

## Phase 2: 设备与区域资产

### T004 — WorkArea 区域资产
```yaml
name: WorkArea 工作区 3D 资产
description: |
  实现 WorkArea 的 3D 资产：半透明边界框 + 区域标识牌 + 地面色块。
scope:
  do:
    - createWorkArea() 生成器
    - 半透明边界框（CreateBox + alpha 材质）
    - 区域名称标签（billboard 平面）
    - 地面色块区分（CreateGround 局部覆盖）
    - 注册到 AssetFactory
  dont:
    - 不创建设备（已有 equipment-models.ts）
    - 不处理 WorkArea 内部的布局逻辑
files:
  - src/assets/work-area-models.ts
  - src/assets/work-area-models.test.ts
dependencies:
  - T002  # AssetFactory 注册机制
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/work-area-models.test.ts
    check:
      - 创建的工作区有正确的 name
      - 边界框可见且半透明
      - 标签 billboard 正确设置
      - 注册到 AssetFactory 后可通过 create() 调用
status: pending
```

### T005 — Buffer 基础 3D 资产
```yaml
name: Buffer 缓冲 3D 资产
description: |
  实现 Buffer 的 3D 资产：半透明容器造型 + 容量指示条。
  颜色根据填充比例变化：空=灰色，半满=黄色，满=红色。
scope:
  do:
    - createBuffer() 生成器
    - 容器造型（CreateBox 或组合几何体）
    - 容量指示条（可缩放高度的 CreateBox）
    - 颜色映射：fillRatio 0→0.5→1 对应 灰→黄→红
    - updateBufferFill() 方法更新填充状态
    - 注册到 AssetFactory
  dont:
    - 不实现 InputBank/OutputBank 的特殊造型（T006）
    - 不实现 Lot 在 Buffer 中的堆叠显示（T012）
files:
  - src/assets/buffer-models.ts
  - src/assets/buffer-models.test.ts
dependencies:
  - T002  # AssetFactory
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/buffer-models.test.ts
    check:
      - Buffer 容器有正确 name
      - 容量条初始高度为 0
      - updateBufferFill(5, 10) 容量条高度变为 50%
      - updateBufferFill(10, 10) 颜色变为红色
      - 注册到 AssetFactory
status: pending
```

### T006 — InputBank / OutputBank 3D 资产
```yaml
name: InputBank 和 OutputBank 3D 资产
description: |
  实现 InputBank（漏斗形入口）和 OutputBank（输出托盘）的 3D 资产。
  继承 Buffer 的基础能力，添加特殊造型。
scope:
  do:
    - createInputBank() 生成器（漏斗造型：CreateCylinder + CreateBox 组合）
    - createOutputBank() 生成器（托盘造型：扁平 CreateBox + 边框）
    - 复用 Buffer 的容量指示逻辑
    - 注册到 AssetFactory
  dont:
    - 不实现 Lot 排队动画
    - 不关联到具体 Equipment
files:
  - src/assets/buffer-models.ts  # 追加到已有文件
  - src/assets/buffer-models.test.ts  # 追加测试
dependencies:
  - T005  # Buffer 基础资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/buffer-models.test.ts
    check:
      - InputBank 有漏斗造型特征
      - OutputBank 有托盘边框特征
      - 都支持 updateBufferFill()
      - 都注册到 AssetFactory
status: pending
```

### T007 — Stocker 中央仓储 3D 资产
```yaml
name: Stocker 中央仓储 3D 资产
description: |
  实现 Stocker 的 3D 资产：多层货架造型 + 每层 Lot 密度热力图。
scope:
  do:
    - createStocker() 生成器
    - 多层货架（多个 CreateBox 堆叠）
    - 每层独立的密度指示（颜色深浅反映 Lot 数量）
    - 输入/输出端口标识
    - updateStockerLevel(levelIndex, lotCount, capacity) 更新单层状态
    - 注册到 AssetFactory
  dont:
    - 不实现 Stocker 的出入库动画（T016）
    - 不实现跨区传输逻辑（T009）
files:
  - src/assets/buffer-models.ts  # 追加到已有文件
  - src/assets/buffer-models.test.ts  # 追加测试
dependencies:
  - T005  # Buffer 基础资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/buffer-models.test.ts
    check:
      - Stocker 有正确层数
      - 每层可独立更新密度颜色
      - 注册到 AssetFactory
status: pending
```

---

## Phase 3: 传输系统资产

### T008 — TransportPath 传输路径 3D 资产
```yaml
name: TransportPath 传输路径 3D 资产
description: |
  实现传输路径的 3D 资产：轨道/路径线条。
  支持 AMHS（高架轨道）、AGV（地面路径）、人工搬运（虚线）。
scope:
  do:
    - createTransportPath() 生成器
    - AMHS 轨道（CreateTube 或 CreateLines + 粗线条）
    - AGV 路径（地面线条 + 方向箭头）
    - 人工搬运路径（虚线线条）
    - 路径点标记（小圆球）
    - 注册到 AssetFactory
  dont:
    - 不创建移动的车辆（T008）
    - 不实现路径寻路算法
files:
  - src/assets/transport-models.ts
  - src/assets/transport-models.test.ts
dependencies:
  - T002  # AssetFactory
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/transport-models.test.ts
    check:
      - AMHS 轨道有正确 name
      - AGV 路径有方向箭头
      - 人工路径是虚线
      - 注册到 AssetFactory
status: pending
```

### T009 — TransportVehicle 传输车辆 3D 资产
```yaml
name: TransportVehicle 传输车辆 3D 资产
description: |
  实现 AMHS 天车小车和 AGV 小车的 3D 资产。
scope:
  do:
    - createTransportVehicle() 生成器
    - AMHS 小车（小型 CreateBox + 悬挂臂）
    - AGV 小车（扁平 CreateBox + 轮子）
    - 车辆状态灯（Idle=绿, Moving=黄, Loading=蓝）
    - updateVehicleStatus() 更新状态
    - 注册到 AssetFactory
  dont:
    - 不实现沿路径移动（T017）
    - 不实现装载/卸载 Lot 动画
files:
  - src/assets/transport-models.ts  # 追加到已有文件
  - src/assets/transport-models.test.ts  # 追加测试
dependencies:
  - T008  # TransportPath
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/transport-models.test.ts
    check:
      - AMHS 小车有悬挂臂特征
      - AGV 小车有扁平造型
      - 状态灯颜色正确切换
      - 注册到 AssetFactory
status: pending
```

### T010 — TransportSystem 传输系统管理模块
```yaml
name: TransportSystem 传输系统管理
description: |
  实现 TransportSystem 类，管理传输路径和车辆。
  提供车辆移动、装载、卸载的 API。
scope:
  do:
    - TransportSystem 类
    - addPath() / removePath()
    - addVehicle() / removeVehicle()
    - moveVehicle() — 计算路径进度
    - loadLot() / unloadLot() — 更新车辆携带状态
    - getVehicleAt() — 按位置查找附近车辆
    - highlightPath() — 高亮路径
  dont:
    - 不实现动画（那是 AnimationOrchestrator 的职责）
    - 不处理碰撞检测
files:
  - src/transport/transport-system.ts
  - src/transport/transport-system.test.ts
dependencies:
  - T008  # TransportPath
  - T009  # TransportVehicle
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/transport/transport-system.test.ts
    check:
      - 可以添加/删除路径
      - 可以添加/删除车辆
      - moveVehicle 更新 pathPosition
      - loadLot/unloadLot 更新 carryingLotId
      - getVehicleAt 能按位置查找
status: pending
```

---

## Phase 4: Entity 绑定与状态同步

### T011 — EntityManager 基础绑定框架
```yaml
name: EntityManager 基础绑定框架
description: |
  实现 EntityManager 的核心框架：bind()、unbind()、getBinding()。
  建立领域模型 ID 与 3D SceneNode 的映射关系。
scope:
  do:
    - EntityBinding 接口定义
    - EntityManager 类
    - bind(domainEntity, sceneNode) — 创建绑定
    - unbind(domainId) — 移除绑定
    - getBinding(domainId) — 按领域 ID 查找
    - getBindingBySceneNodeId(nodeId) — 按场景节点 ID 查找
    - 内部维护 bindings Map
  dont:
    - 不实现具体的状态同步方法（T012-T015）
    - 不直接操作 Mesh 材质
files:
  - src/entity/entity-manager.ts
  - src/entity/entity-manager.test.ts
dependencies:
  - T001  # SceneGraph
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/entity/entity-manager.test.ts
    check:
      - bind() 创建正确的 EntityBinding
      - getBinding() 能按 domainId 查找
      - unbind() 正确移除
      - getBindingBySceneNodeId() 反向查找正确
status: pending
```

### T012 — EntityManager 设备状态同步
```yaml
name: EntityManager 设备状态同步
description: |
  实现 syncEquipmentState()，根据 Equipment 状态更新 3D 模型。
  包含 EquipmentStatus 和 ControlState 两层状态。
scope:
  do:
    - syncEquipmentState(equipment) 方法
    - EquipmentStatus → 颜色映射（Idle=绿, Processing=黄, Error=红...）
    - ControlState 可视化（OFFLINE=灰, LOCAL=蓝, REMOTE=绿）
    - 状态变化时触发动画（通过 AnimationOrchestrator）
    - 设备标签更新（显示当前 Lot、Recipe）
  dont:
    - 不实现设备加工动画（T014）
    - 不修改 equipment-models.ts 的创建逻辑
files:
  - src/entity/entity-manager.ts  # 追加方法
  - src/entity/entity-manager.test.ts  # 追加测试
dependencies:
  - T011  # EntityManager 框架
  - 已有: equipment-models.ts  # updateEquipmentStatus
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/entity/entity-manager.test.ts
    check:
      - syncEquipmentState 更新设备颜色
      - ControlState 变化有可视化反馈
      - 绑定不存在的设备抛出错误
status: pending
```

### T013 — EntityManager Buffer/Stocker 状态同步
```yaml
name: EntityManager Buffer/Stocker 状态同步
description: |
  实现 syncBufferState() 和 syncStockerState()，更新缓冲区的 3D 可视化。
scope:
  do:
    - syncBufferState(bufferId, lots, capacity) 方法
    - 更新容量指示条高度
    - 更新颜色（空/半满/满）
    - syncStockerState(stockerId, lots, capacity) 方法
    - 更新每层密度热力图
    - Buffer 满时闪烁警告
  dont:
    - 不实现 Lot 在 Buffer 中的逐个堆叠（那是动画）
    - 不处理 Buffer 的出入库逻辑
files:
  - src/entity/entity-manager.ts  # 追加方法
  - src/entity/entity-manager.test.ts  # 追加测试
dependencies:
  - T011  # EntityManager 框架
  - T005  # Buffer 资产
  - T007  # Stocker 资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/entity/entity-manager.test.ts
    check:
      - syncBufferState 更新容量条
      - 满容量时 Buffer 变红
      - syncStockerState 更新多层密度
status: pending
```

### T014 — EntityManager 传输状态同步
```yaml
name: EntityManager 传输状态同步
description: |
  实现 syncTransportVehicleState()，更新传输车辆的位置和状态。
scope:
  do:
    - syncTransportVehicleState(vehicleId, position, carryingLotId) 方法
    - 更新车辆位置
    - 显示/隐藏携带的 Lot
    - 更新车辆状态灯
  dont:
    - 不实现车辆移动动画（T017）
    - 不处理路径计算
files:
  - src/entity/entity-manager.ts  # 追加方法
  - src/entity/entity-manager.test.ts  # 追加测试
dependencies:
  - T011  # EntityManager 框架
  - T009  # TransportVehicle 资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/entity/entity-manager.test.ts
    check:
      - syncTransportVehicleState 更新位置
      - carryingLotId 存在时显示 Lot 附着
status: pending
```

### T015 — EntityManager 批量同步
```yaml
name: EntityManager 批量同步机制
description: |
  实现 syncBatch()，在一帧内合并多个状态更新，避免逐帧闪烁。
scope:
  do:
    - syncBatch(updates) 方法
    - 收集同一帧内的所有更新
    - 按类型分组处理
    - 一帧结束时统一应用
    - 提供 beginBatch() / endBatch() 手动控制
  dont:
    - 不改变单个 syncXxx 方法的行为
files:
  - src/entity/entity-manager.ts  # 追加方法
  - src/entity/entity-manager.test.ts  # 追加测试
dependencies:
  - T012  # 设备同步
  - T013  # Buffer 同步
  - T014  # 传输同步
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/entity/entity-manager.test.ts
    check:
      - syncBatch 合并多个更新
      - 批量更新只触发一次渲染
status: pending
```

---

## Phase 5: 动画编排系统

### T016 — AnimationOrchestrator 基础框架
```yaml
name: AnimationOrchestrator 动画编排基础
description: |
  实现 AnimationOrchestrator 的核心框架：序列动画定义、播放、停止。
  在现有 AnimationSystem 之上封装高级编排能力。
scope:
  do:
    - AnimationSequence 和 AnimationStep 接口
    - AnimationOrchestrator 类
    - playSequence() — 播放序列动画
    - stopSequence() — 停止序列
    - 序列步骤的 waitFor 依赖解析
    - 全局控制：pauseAll()、resumeAll()、setGlobalSpeed()
  dont:
    - 不实现具体的预设动画（T017-T021）
    - 不修改 AnimationSystem 本身
files:
  - src/animation/animation-orchestrator.ts
  - src/animation/animation-orchestrator.test.ts
dependencies:
  - 已有: animation-system.ts
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/animation/animation-orchestrator.test.ts
    check:
      - playSequence 返回序列 ID
      - 序列步骤按顺序执行
      - waitFor 正确等待前置步骤
      - pauseAll 暂停所有动画
      - setGlobalSpeed 改变播放速度
status: pending
```

### T017 — Lot 流转动画
```yaml
name: Lot 流转动画
description: |
  实现 Lot 在设备间流转的完整动画序列。
scope:
  do:
    - animateLotTransfer(lotId, fromEqId, toEqId) — 设备间转移
    - animateLotToBuffer(lotId, equipmentId, bufferId) — 到 Buffer
    - animateLotFromBuffer(lotId, bufferId, equipmentId) — 从 Buffer
    - animateLotToStocker(lotId, fromPosition, stockerId) — 到 Stocker
    - 每个动画包含：升起→移动→降下
    - 使用 Path3D 或直线移动
  dont:
    - 不处理传输车辆（T019）
    - 不处理 MES 事件响应
files:
  - src/animation/animation-orchestrator.ts  # 追加方法
  - src/animation/animation-orchestrator.test.ts  # 追加测试
dependencies:
  - T016  # AnimationOrchestrator 框架
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/animation/animation-orchestrator.test.ts
    check:
      - Lot 从 A 移动到 B 位置正确
      - 动画有升起/降下阶段
      - onComplete 回调正确触发
status: pending
```

### T018 — 设备状态动画
```yaml
name: 设备状态切换动画
description: |
  实现设备状态变化时的动画效果。
scope:
  do:
    - animateEquipmentStatusChange() — 颜色过渡 + 状态灯闪烁
    - animateEquipmentControlStateChange() — OFFLINE/LOCAL/REMOTE 可视化
    - animateLotProcessing() — Lot 进入设备 + 进度环
    - 故障状态红色脉冲
    - 维护状态灰色闪烁
  dont:
    - 不修改设备材质创建逻辑
files:
  - src/animation/animation-orchestrator.ts  # 追加方法
  - src/animation/animation-orchestrator.test.ts  # 追加测试
dependencies:
  - T016  # AnimationOrchestrator 框架
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/animation/animation-orchestrator.test.ts
    check:
      - 状态变化触发颜色动画
      - 故障状态有脉冲效果
status: pending
```

### T019 — Buffer 动画
```yaml
name: Buffer 填充与排队动画
description: |
  实现 Buffer 容量变化和 Lot 排队的动画。
scope:
  do:
    - animateBufferFillChange() — 容量条高度变化
    - animateLotQueueInBuffer() — Lot 堆叠位置动画
    - 满容量警告闪烁
    - 从 Buffer 取出 Lot 时的缩小消失
  dont:
    - 不修改 Buffer 资产创建逻辑
files:
  - src/animation/animation-orchestrator.ts  # 追加方法
  - src/animation/animation-orchestrator.test.ts  # 追加测试
dependencies:
  - T016  # AnimationOrchestrator 框架
  - T005  # Buffer 资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/animation/animation-orchestrator.test.ts
    check:
      - 容量条高度动画正确
      - 排队 Lot 位置正确
status: pending
```

### T020 — 传输系统动画
```yaml
name: 传输车辆移动动画
description: |
  实现车辆沿路径移动和装卸 Lot 的动画。
scope:
  do:
    - animateVehicleMove() — 车辆沿路径移动
    - loadLot 时装载动画（Lot 附着到车辆）
    - unloadLot 时卸载动画（Lot 从车辆分离）
    - 车辆状态灯切换动画
  dont:
    - 不处理路径寻路
files:
  - src/animation/animation-orchestrator.ts  # 追加方法
  - src/animation/animation-orchestrator.test.ts  # 追加测试
dependencies:
  - T016  # AnimationOrchestrator 框架
  - T010  # TransportSystem
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/animation/animation-orchestrator.test.ts
    check:
      - 车辆沿路径移动到正确位置
      - 装载时 Lot 变为车辆子节点
status: pending
```

### T021 — 多层工艺循环动画
```yaml
name: 多层工艺循环 (Layer) 动画
description: |
  实现 Layer 切换和循环进度的动画效果。
scope:
  do:
    - animateLayerTransition() — Layer 切换动画
    - Layer 完成时的庆祝效果（节点变绿 + 粒子）
    - 螺旋/环形指示器进度更新
  dont:
    - 不创建 LayerCycleVisualization（T028）
    - 只提供动画方法
files:
  - src/animation/animation-orchestrator.ts  # 追加方法
  - src/animation/animation-orchestrator.test.ts  # 追加测试
dependencies:
  - T016  # AnimationOrchestrator 框架
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/animation/animation-orchestrator.test.ts
    check:
      - Layer 切换动画执行
      - 完成效果触发
status: pending
```

---

## Phase 6: MES 抽象可视化

### T022 — MES 节点基础资产
```yaml
name: MES 系统节点 3D 资产
description: |
  实现 MES 服务器/数据节点的 3D 资产：发光立方体 + 脉冲光环。
scope:
  do:
    - createMESNode() 生成器
    - 发光立方体（emissive 材质）
    - 脉冲光环（缩放动画的 torus）
    - 数据流动画粒子发射点
    - 注册到 AssetFactory
  dont:
    - 不创建具体的面板（EventQueue 等是独立任务）
files:
  - src/assets/mes-visual-models.ts
  - src/assets/mes-visual-models.test.ts
dependencies:
  - T002  # AssetFactory
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/mes-visual-models.test.ts
    check:
      - MES 节点有发光材质
      - 脉冲光环有缩放动画
      - 注册到 AssetFactory
status: pending
```

### T023 — EventQueue 可视化
```yaml
name: EventQueue 事件队列可视化
description: |
  实现事件队列的 3D 面板：悬浮面板 + 事件条目堆叠。
scope:
  do:
    - EventQueueVisualization 类
    - 悬浮面板（DynamicTexture + AdvancedDynamicTexture）
    - 事件条目堆叠（新事件在上，旧事件下移）
    - 新事件掉落动画（Bounce easing）
    - 事件处理中脉冲发光
    - 完成事件淡出销毁
    - updateQueue(events) 方法
    - setMaxVisibleEvents(n) 性能控制
  dont:
    - 不处理事件的业务逻辑
    - 不连接真实 MES
files:
  - src/visualization/event-queue-viz.ts
  - src/visualization/event-queue-viz.test.ts
dependencies:
  - T022  # MES 节点资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/event-queue-viz.test.ts
    check:
      - 面板创建成功
      - updateQueue 更新事件列表
      - 超出 maxVisibleEvents 的事件被移除
status: pending
```

### T024 — WIP 看板可视化
```yaml
name: WIP 在制品追踪看板
description: |
  实现 WIP 看板的 3D 面板：信息面板 + Lot 状态指示器。
scope:
  do:
    - WIPVisualization 类
    - 信息面板（总 WIP、各区域 WIP）
    - Lot 状态指示器列表
    - highlightLot() 高亮指定 Lot
    - setMaxVisibleLots() 性能控制
    - updateWIP(lots) 方法
  dont:
    - 不处理 Lot 的业务数据
files:
  - src/visualization/wip-viz.ts
  - src/visualization/wip-viz.test.ts
dependencies:
  - T022  # MES 节点资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/wip-viz.test.ts
    check:
      - 面板显示 WIP 数量
      - updateWIP 正确更新列表
      - highlightLot 高亮指定 Lot
status: pending
```

### T025 — 调度规则可视化
```yaml
name: Scheduler 调度规则可视化
description: |
  实现调度规则的 3D 对比面板：FIFO/SPT/CR 效果对比。
scope:
  do:
    - SchedulerVisualization 类
    - 当前规则名称显示
    - 派工决策过程可视化（候选 Lot + 选中高亮）
    - 规则效果对比（可选）
    - showDecisionSnapshot() 方法
  dont:
    - 不实现调度算法本身
files:
  - src/visualization/scheduler-viz.ts
  - src/visualization/scheduler-viz.test.ts
dependencies:
  - T022  # MES 节点资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/scheduler-viz.test.ts
    check:
      - 显示当前规则名称
      - showDecisionSnapshot 高亮选中 Lot
status: pending
```

### T026 — OEE 统计看板
```yaml
name: OEE 设备综合效率看板
description: |
  实现 OEE 统计的 3D 看板：环形图 + 实时数字。
scope:
  do:
    - OEEDashboard 类
    - 设备 OEE 环形图（Availability × Performance × Quality）
    - 全厂 OEE 总览
    - 瓶颈设备高亮
    - updateOEE() 方法
    - highlightBottleneck() 方法
  dont:
    - 不计算 OEE 数值（只负责可视化）
files:
  - src/visualization/oee-dashboard.ts
  - src/visualization/oee-dashboard.test.ts
dependencies:
  - T022  # MES 节点资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/oee-dashboard.test.ts
    check:
      - 环形图显示正确比例
      - updateOEE 更新数值
      - highlightBottleneck 高亮设备
status: pending
```

### T027 — 故障注入可视化
```yaml
name: FaultInjection 故障注入可视化
description: |
  实现故障注入的 3D 面板和效果。
scope:
  do:
    - FaultInjectionVisualization 类
    - 故障类型列表面板
    - injectFault() — 目标设备故障效果（变红 + 烟雾粒子）
    - 故障影响范围高亮（关联设备）
    - showFaultHistory() — 历史故障时间轴
  dont:
    - 不实现故障的业务逻辑
    - 不处理故障恢复流程
files:
  - src/visualization/fault-injection-viz.ts
  - src/visualization/fault-injection-viz.test.ts
dependencies:
  - T022  # MES 节点资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/fault-injection-viz.test.ts
    check:
      - 故障面板显示类型列表
      - injectFault 触发设备红色效果
status: pending
```

### T028 — 数据流粒子可视化
```yaml
name: DataFlow 数据流粒子效果
description: |
  实现 MES 与设备间的数据流粒子效果。
scope:
  do:
    - DataFlowVisualization 类
    - 曲线路径粒子流动
    - 颜色映射：Recipe=蓝, Status=绿, Alert=红, Command=紫
    - 粒子池复用
    - showFlow() / hideFlow() / setFlowSpeed()
  dont:
    - 不处理数据内容本身
files:
  - src/visualization/data-flow-viz.ts
  - src/visualization/data-flow-viz.test.ts
dependencies:
  - T022  # MES 节点资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/data-flow-viz.test.ts
    check:
      - showFlow 创建粒子效果
      - 不同 dataType 有不同颜色
      - 粒子池正确复用
status: pending
```

---

## Phase 7: 多层工艺循环

### T029 — LayerCycle 可视化资产
```yaml
name: LayerCycle 多层工艺循环可视化资产
description: |
  实现 Layer 循环指示器的 3D 资产：螺旋/环形进度条。
scope:
  do:
    - createLayerIndicator() 生成器
    - 螺旋/环形节点（CreateTorus + 小圆球）
    - 每个 Layer 一个节点
    - 当前 Layer 高亮（黄色）
    - 已完成 Layer 变绿
    - 未完成 Layer 灰色
    - 注册到 AssetFactory
  dont:
    - 不处理 Layer 切换逻辑
    - 不创建进度更新动画
files:
  - src/assets/mes-visual-models.ts  # 追加到已有文件
  - src/assets/mes-visual-models.test.ts  # 追加测试
dependencies:
  - T002  # AssetFactory
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/assets/mes-visual-models.test.ts
    check:
      - Layer 指示器有正确数量的节点
      - 节点颜色正确
      - 注册到 AssetFactory
status: pending
```

### T030 — LayerCycleVisualization 模块
```yaml
name: LayerCycleVisualization 多层工艺循环可视化模块
description: |
  实现 LayerCycleVisualization 类，管理 Layer 进度和视觉效果。
scope:
  do:
    - LayerCycleVisualization 类
    - setCurrentLayer() — 高亮当前 Layer
    - setTotalLayers() — 重新生成节点
    - animateLayerComplete() — 完成庆祝动画
    - showLayerDetail() — 展开显示某 Layer 工艺步骤
  dont:
    - 不处理 Recipe 解析
files:
  - src/visualization/layer-cycle-viz.ts
  - src/visualization/layer-cycle-viz.test.ts
dependencies:
  - T029  # LayerCycle 资产
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/visualization/layer-cycle-viz.test.ts
    check:
      - setCurrentLayer 高亮正确节点
      - animateLayerComplete 触发粒子效果
status: pending
```

---

## Phase 8: 性能优化

### T031 — PerformanceProfiler 性能分析器
```yaml
name: PerformanceProfiler 性能分析器
description: |
  实现性能监控和自动优化建议。
scope:
  do:
    - PerformanceProfiler 类
    - tick() — 每帧采样（FPS、DrawCalls、MeshCount）
    - getMetrics() — 获取当前指标
    - getOptimizationSuggestions() — 生成优化建议
    - setupLOD() — LOD 配置
    - enableInstancingForEquipmentType() — ThinInstance
    - setParticleBudget() — 粒子数量控制
    - generateReport() — 生成性能报告
  dont:
    - 不自动应用优化（只提供建议，由调用方决定）
files:
  - src/perf/performance-profiler.ts
  - src/perf/performance-profiler.test.ts
dependencies: []  # 独立模块
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check
  - cmd: cd packages/3d-engine && npx vitest run src/perf/performance-profiler.test.ts
    check:
      - tick() 采样指标正确
      - getOptimizationSuggestions 返回有效建议
      - setupLOD 正确配置层级
status: pending
```

---

## Phase 9: 整合与导出

### T032 — index.ts 统一导出
```yaml
name: index.ts 统一导出更新
description: |
  更新 packages/3d-engine/src/index.ts，导出所有公共 API。
scope:
  do:
    - 导出 SceneManager（已有）
    - 导出 SceneBuilder、SceneGraph
    - 导出 AssetFactory
    - 导出 EntityManager
    - 导出 AnimationSystem、AnimationOrchestrator
    - 导出 TransportSystem
    - 导出所有 Visualization 类
    - 导出 PerformanceProfiler
    - 导出所有类型定义
  dont:
    - 不导出内部实现细节
    - 不导出测试文件
files:
  - src/index.ts
dependencies:
  - 所有前置任务
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/3d-engine && node -e "const m = require('./dist/index.js'); console.log(Object.keys(m).sort().join('\n'))"
    check:
      - 所有预期导出存在
      - 没有未定义的导出
status: pending
```

### T033 — 端到端集成验证
```yaml
name: 端到端集成验证
description: |
  创建一个完整的端到端测试，验证所有模块协同工作。
scope:
  do:
    - 编写端到端测试用例
    - 加载完整 JSON 配置
    - 构建完整场景
    - 模拟 Lot 流转
    - 验证所有可视化组件正常工作
    - 验证性能指标达标
  dont:
    - 不测试 UI（Vue）层
    - 不测试仿真引擎逻辑
files:
  - src/integration.test.ts  # 或 e2e 目录
dependencies:
  - T032  # 所有模块导出完成
verification:
  - cmd: cd packages/3d-engine && pnpm lint && pnpm type-check && pnpm build
  - cmd: cd packages/3d-engine && npx vitest run src/integration.test.ts
    check:
      - 场景构建成功
      - Lot 流转动画执行
      - 所有可视化组件更新
      - FPS > 30（在测试环境可适当放宽）
status: pending
```

---

## 任务依赖图

```
Phase 1 (基础设施):
  T001 ──→ T002 ──→ T003
            │
Phase 2 (设备资产):
  T004 (WorkArea) ←── T002
  T005 (Buffer) ←── T002 ──→ T006 (Input/OutputBank) ──→ T007 (Stocker)

Phase 3 (传输系统):
  T008 (TransportPath) ←── T002 ──→ T009 (TransportVehicle) ──→ T010 (TransportSystem)

Phase 4 (Entity 绑定):
  T011 ←── T001 ──→ T012 (设备同步)
   │             → T013 (Buffer 同步) ──→ T014 (传输同步)
   │                                    → T015 (批量同步)

Phase 5 (动画编排):
  T016 ←── AnimationSystem ──→ T017 (Lot 流转)
                          → T018 (设备状态)
                          → T019 (Buffer)
                          → T020 (传输)
                          → T021 (Layer)

Phase 6 (MES 可视化):
  T022 (MES 节点) ←── T002
   │
   ├──→ T023 (EventQueue)
   ├──→ T024 (WIP)
   ├──→ T025 (Scheduler)
   ├──→ T026 (OEE)
   ├──→ T027 (FaultInjection)
   └──→ T028 (DataFlow)

Phase 7 (LayerCycle):
  T029 ←── T002 ──→ T030

Phase 8 (性能):
  T031 (独立)

Phase 9 (整合):
  T032 ←── 所有模块
   │
   └──→ T033 (E2E)
```

---

## 当前状态汇总

| 阶段 | 任务数 | pending | active | passing | blocked |
|------|-------|---------|--------|---------|---------|
| Phase 1 基础设施 | 3 | 3 | 0 | 0 | 0 |
| Phase 2 设备资产 | 4 | 4 | 0 | 0 | 0 |
| Phase 3 传输系统 | 3 | 3 | 0 | 0 | 0 |
| Phase 4 Entity 绑定 | 5 | 5 | 0 | 0 | 0 |
| Phase 5 动画编排 | 6 | 6 | 0 | 0 | 0 |
| Phase 6 MES 可视化 | 7 | 7 | 0 | 0 | 0 |
| Phase 7 LayerCycle | 2 | 2 | 0 | 0 | 0 |
| Phase 8 性能 | 1 | 1 | 0 | 0 | 0 |
| Phase 9 整合 | 2 | 2 | 0 | 0 | 0 |
| **总计** | **33** | **33** | **0** | **0** | **0** |

---

## 使用指南

### 如何开始一个任务

1. 从 pending 列表中选取一个依赖已全部 passing 的任务
2. 将其状态改为 `active`
3. 实现代码 + 测试
4. 运行 verification 命令
5. 全部通过 → 标记为 `passing`
6. 任一失败 → 保持 `active`，修复后继续

### 如何选择下一个任务

**推荐顺序**（按依赖和优先级）：
1. T001 → T002 → T003（基础设施，必须最先完成）
2. T004 → T005 → T006 → T007（核心资产）
3. T011 → T012 → T013（核心状态同步）
4. T016 → T017 → T018（核心动画）
5. 其余按需求和依赖灵活选取

---

**文档版本**: 1.0
**创建日期**: 2026-06-07
**更新规则**: 每次任务状态变更时更新本文件的状态汇总表
