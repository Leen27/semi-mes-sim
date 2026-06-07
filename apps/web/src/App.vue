<template>
  <div class="app-container">
    <!-- 左侧控制面板 -->
    <aside class="sidebar">
      <SimulationPanel
        :current-time="simulationStore.currentTime"
        :speed="simulationStore.speed"
        :is-running="simulationStore.isRunning"
        :equipment-count="simulationStore.equipments.length"
        :lot-count="simulationStore.lots.length"
        :completed-count="simulationStore.completedLots.length"
        @start="simulationStore.start"
        @pause="simulationStore.pause"
        @reset="simulationStore.reset"
        @speed-change="simulationStore.setSpeed"
      />
      
      <div class="equipment-list">
        <h4>设备列表</h4>
        <EquipmentCard
          v-for="eq in simulationStore.equipments"
          :key="eq.id"
          :name="eq.name"
          :type="eq.type"
          :status="eq.status"
          :current-lot-id="eq.currentLotId"
          :throughput="eq.throughput"
        />
      </div>
    </aside>

    <!-- 中央 3D 画布 -->
    <main class="main-content">
      <canvas
        ref="canvasRef"
        class="canvas-element"
      />
    </main>

    <!-- 底部状态栏 -->
    <footer class="status-bar">
      <span>Semi-MES-Sim v0.0.1</span>
      <span>FPS: {{ fps }}</span>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { SimulationPanel, EquipmentCard } from '@semi/ui'
import { SceneManager, FabLayout } from '@semi/3d-engine'
import { useSimulationStore } from './stores/simulation'

const canvasRef = ref<HTMLCanvasElement>()
const simulationStore = useSimulationStore()
const fps = ref(0)

let sceneManager: SceneManager | null = null
let fabLayout: FabLayout | null = null
let fpsFrameCount = 0
let fpsLastTime = performance.now()

onMounted(() => {
  if (!canvasRef.value) return

  // 初始化 3D 场景
  sceneManager = new SceneManager({
    canvas: canvasRef.value,
    enableShadows: true
  })

  // 创建晶圆厂布局
  fabLayout = new FabLayout(sceneManager.scene)
  fabLayout.createLayout(simulationStore.equipments)

  // FPS 计数
  sceneManager.addRenderCallback(() => {
    fpsFrameCount++
    const now = performance.now()
    if (now - fpsLastTime >= 1000) {
      fps.value = fpsFrameCount
      fpsFrameCount = 0
      fpsLastTime = now
    }
  })
})

onUnmounted(() => {
  sceneManager?.dispose()
})
</script>

<style scoped>
.app-container {
  display: grid;
  grid-template-columns: 300px 1fr;
  grid-template-rows: 1fr 32px;
  grid-template-areas:
    'sidebar main'
    'status status';
  width: 100vw;
  height: 100vh;
}

.sidebar {
  grid-area: sidebar;
  background: #0f0f1e;
  border-right: 1px solid #222;
  padding: 16px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.equipment-list {
  flex: 1;
  overflow-y: auto;
}

.equipment-list h4 {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #888;
}

.main-content {
  grid-area: main;
  position: relative;
  overflow: hidden;
}

.canvas-element {
  width: 100%;
  height: 100%;
  outline: none;
}

.status-bar {
  grid-area: status;
  background: #0a0a1a;
  border-top: 1px solid #222;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 16px;
  font-size: 11px;
  color: #666;
}
</style>
