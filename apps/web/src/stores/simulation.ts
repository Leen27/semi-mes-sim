import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import {
  SimulationEngine,
  type SimulationConfig,
  type Lot,
  type Equipment,
  type ProcessRoute,
  LotStatus,
  EquipmentStatus,
  EquipmentType
} from '@semi/core'

// 模拟初始数据
const mockLots: Lot[] = [
  { id: 'L001', name: 'Lot-001', waferCount: 25, currentStepIndex: 0, routeId: 'R001', priority: 1, status: LotStatus.Waiting, createdAt: 0 },
  { id: 'L002', name: 'Lot-002', waferCount: 25, currentStepIndex: 0, routeId: 'R001', priority: 2, status: LotStatus.Waiting, createdAt: 0 },
  { id: 'L003', name: 'Lot-003', waferCount: 25, currentStepIndex: 0, routeId: 'R001', priority: 1, status: LotStatus.Waiting, createdAt: 0 }
]

const mockEquipments: Equipment[] = [
  { id: 'E001', name: '光刻机-01', type: EquipmentType.Lithography, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC001'], position: { x: -20, y: 0, z: -20 }, throughput: 60 },
  { id: 'E002', name: '刻蚀机-01', type: EquipmentType.Etching, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC002'], position: { x: 0, y: 0, z: -20 }, throughput: 45 },
  { id: 'E003', name: '薄膜沉积-01', type: EquipmentType.Deposition, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC003'], position: { x: 20, y: 0, z: -20 }, throughput: 50 },
  { id: 'E004', name: '离子注入-01', type: EquipmentType.Implantation, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC004'], position: { x: -20, y: 0, z: 0 }, throughput: 40 },
  { id: 'E005', name: '清洗机-01', type: EquipmentType.Cleaning, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC005'], position: { x: 0, y: 0, z: 0 }, throughput: 80 },
  { id: 'E006', name: '检测设备-01', type: EquipmentType.Inspection, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC006'], position: { x: 20, y: 0, z: 0 }, throughput: 70 },
  { id: 'E007', name: '退火炉-01', type: EquipmentType.Annealing, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC007'], position: { x: -20, y: 0, z: 20 }, throughput: 55 },
  { id: 'E008', name: '光刻机-02', type: EquipmentType.Lithography, status: EquipmentStatus.Idle, supportedRecipeIds: ['REC001'], position: { x: 0, y: 0, z: 20 }, throughput: 60 }
]

const mockRoutes: ProcessRoute[] = [
  {
    id: 'R001',
    name: '标准CMOS工艺',
    steps: [
      { id: 'S001', sequence: 1, name: '清洗', requiredEquipmentType: EquipmentType.Cleaning, recipeId: 'REC005' },
      { id: 'S002', sequence: 2, name: '氧化', requiredEquipmentType: EquipmentType.Deposition, recipeId: 'REC003' },
      { id: 'S003', sequence: 3, name: '光刻', requiredEquipmentType: EquipmentType.Lithography, recipeId: 'REC001' },
      { id: 'S004', sequence: 4, name: '刻蚀', requiredEquipmentType: EquipmentType.Etching, recipeId: 'REC002' },
      { id: 'S005', sequence: 5, name: '离子注入', requiredEquipmentType: EquipmentType.Implantation, recipeId: 'REC004' },
      { id: 'S006', sequence: 6, name: '退火', requiredEquipmentType: EquipmentType.Annealing, recipeId: 'REC007' },
      { id: 'S007', sequence: 7, name: '检测', requiredEquipmentType: EquipmentType.Inspection, recipeId: 'REC006' }
    ]
  }
]

export const useSimulationStore = defineStore('simulation', () => {
  // State
  const engine = ref<SimulationEngine | null>(null)
  const currentTime = ref(0)
  const speed = ref(1)
  const isRunning = ref(false)
  let animationFrameId: number | null = null
  let lastTime = 0

  // 初始化引擎
  const config: SimulationConfig = {
    initialLots: mockLots,
    equipments: mockEquipments,
    routes: mockRoutes,
    initialSpeed: 1
  }

  engine.value = new SimulationEngine(config, {
    onTick: (state) => {
      currentTime.value = state.currentTime
    }
  })

  // Getters
  const lots = computed(() => engine.value?.getState().lots ?? [])
  const equipments = computed(() => engine.value?.getState().equipments ?? [])
  const completedLots = computed(() => lots.value.filter(l => l.status === LotStatus.Completed))

  // Actions
  function start(): void {
    if (isRunning.value) return
    engine.value?.start()
    isRunning.value = true
    lastTime = performance.now()
    runLoop()
  }

  function pause(): void {
    isRunning.value = false
    engine.value?.pause()
    if (animationFrameId !== null) {
      cancelAnimationFrame(animationFrameId)
      animationFrameId = null
    }
  }

  function reset(): void {
    pause()
    engine.value?.reset()
    currentTime.value = 0
    speed.value = 1
  }

  function setSpeed(newSpeed: number): void {
    speed.value = newSpeed
    engine.value?.setSpeed(newSpeed)
  }

  // 仿真循环
  function runLoop(): void {
    if (!isRunning.value) return

    const now = performance.now()
    const delta = (now - lastTime) / 1000 // 转换为秒
    lastTime = now

    engine.value?.tick(delta)

    animationFrameId = requestAnimationFrame(runLoop)
  }

  return {
    currentTime,
    speed,
    isRunning,
    lots,
    equipments,
    completedLots,
    start,
    pause,
    reset,
    setSpeed
  }
})
