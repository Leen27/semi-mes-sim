<template>
  <div class="simulation-panel">
    <div class="panel-header">
      <h3>仿真控制</h3>
    </div>
    <div class="panel-body">
      <div class="time-display">
        <span class="time-label">仿真时间:</span>
        <span class="time-value">{{ formattedTime }}</span>
      </div>
      <div class="speed-control">
        <span class="speed-label">速度: {{ speed }}x</span>
        <input
          type="range"
          min="0.1"
          max="10"
          step="0.1"
          :value="speed"
          @input="$emit('speedChange', parseFloat(($event.target as HTMLInputElement).value))"
        >
      </div>
      <div class="control-buttons">
        <button
          class="btn btn-primary"
          :disabled="isRunning"
          @click="$emit('start')"
        >
          ▶ 开始
        </button>
        <button
          class="btn btn-secondary"
          :disabled="!isRunning"
          @click="$emit('pause')"
        >
          ⏸ 暂停
        </button>
        <button
          class="btn btn-secondary"
          @click="$emit('reset')"
        >
          ↺ 重置
        </button>
      </div>
    </div>
    <div class="panel-footer">
      <div class="stats">
        <div class="stat-item">
          <span class="stat-label">设备数:</span>
          <span class="stat-value">{{ equipmentCount }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Lot 数:</span>
          <span class="stat-value">{{ lotCount }}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">完成:</span>
          <span class="stat-value">{{ completedCount }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  currentTime: number
  speed: number
  isRunning: boolean
  equipmentCount: number
  lotCount: number
  completedCount: number
}

const props = defineProps<Props>()

defineEmits<{
  start: []
  pause: []
  reset: []
  speedChange: [speed: number]
}>()

const formattedTime = computed(() => {
  const hours = Math.floor(props.currentTime / 3600)
  const minutes = Math.floor((props.currentTime % 3600) / 60)
  const seconds = Math.floor(props.currentTime % 60)
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
})
</script>

<style scoped>
.simulation-panel {
  background: #1e1e2e;
  border: 1px solid #333;
  border-radius: 8px;
  padding: 16px;
  color: #fff;
}

.panel-header {
  margin-bottom: 12px;
}

.panel-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
}

.panel-body {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.time-display {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.time-label {
  font-size: 12px;
  color: #888;
}

.time-value {
  font-family: 'Courier New', monospace;
  font-size: 18px;
  font-weight: 600;
  color: #00bcd4;
}

.speed-control {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.speed-label {
  font-size: 12px;
  color: #888;
}

.speed-control input {
  width: 100%;
}

.control-buttons {
  display: flex;
  gap: 8px;
}

.btn {
  flex: 1;
  padding: 8px 12px;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-primary {
  background: #4caf50;
  color: #fff;
}

.btn-primary:hover:not(:disabled) {
  background: #45a049;
}

.btn-secondary {
  background: #333;
  color: #ccc;
}

.btn-secondary:hover:not(:disabled) {
  background: #444;
}

.panel-footer {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #333;
}

.stats {
  display: flex;
  justify-content: space-between;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.stat-label {
  font-size: 10px;
  color: #888;
}

.stat-value {
  font-size: 14px;
  font-weight: 600;
  color: #fff;
}
</style>
