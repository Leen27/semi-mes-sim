# @semi/web — 3D 仿真主应用

## 职责

应用入口与页面编排。包含：
- 3D 画布挂载与 Babylon.js 场景绑定
- 页面布局、路由（如有）、全局状态（Pinia）
- 仿真控制面板、状态看板、时间轴等 UI 组装

## 目录结构

```
src/
├── components/   # 页面级组件（组合 @semi/ui 的业务组件）
├── scenes/       # 3D 场景页面/视图
├── stores/       # Pinia 状态管理（仿真状态、UI 状态）
├── types/        # 应用本地类型扩展
├── utils/        # 应用级工具函数
├── App.vue       # 根组件
└── main.ts       # 应用入口
```

## 关键约束

- **不能包含可复用的领域逻辑**（领域逻辑属于 `@semi/core`）
- **不能包含可复用的 3D 资产**（3D 封装属于 `@semi/3d-engine`）
- 状态管理使用 Pinia（组合式 API 风格）
- 3D 画布通过 `ref` 获取 DOM，传递给 `SceneManager` 初始化

## 开发命令

```bash
# 启动开发服务器
pnpm dev
# 或从根目录
make dev
```

访问 http://localhost:5173

## 构建产物

输出到 `apps/web/dist/`，由 Vite 构建。

## 变更影响检查清单

修改本包代码后，必须检查以下文档和依赖项：

- [ ] 新增的页面级组件是否属于「应用编排」范畴？如包含可复用逻辑，应下沉到 `@semi/core`
- [ ] Pinia store 中的状态结构变更是否影响其他组件？
- [ ] 本文件中的「目录结构」描述是否仍然准确

## 依赖

- `@semi/core`、`@semi/3d-engine`、`@semi/ui`
- `vue`、`pinia`、`@babylonjs/core`
