import type { DefineComponent } from 'vue'

declare const EquipmentCard: DefineComponent<{
  name: string
  type: string
  status: string
  currentLotId?: string
  throughput: number
}>

declare const SimulationPanel: DefineComponent<{
  currentTime: number
  speed: number
  isRunning: boolean
  equipmentCount: number
  lotCount: number
  completedCount: number
}>

declare const StatusBadge: DefineComponent<{
  status: string
}>

export { EquipmentCard, SimulationPanel, StatusBadge }
