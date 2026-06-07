<template>
  <div
    class="equipment-card"
    :class="statusClass"
  >
    <div class="equipment-header">
      <span class="equipment-name">{{ name }}</span>
      <StatusBadge :status="status" />
    </div>
    <div class="equipment-body">
      <div class="equipment-info">
        <span class="label">类型:</span>
        <span class="value">{{ type }}</span>
      </div>
      <div class="equipment-info">
        <span class="label">当前 Lot:</span>
        <span class="value">{{ currentLotId || '无' }}</span>
      </div>
      <div class="equipment-info">
        <span class="label">产能:</span>
        <span class="value">{{ throughput }} wafers/h</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import StatusBadge from './StatusBadge.vue'

interface Props {
  name: string
  type: string
  status: string
  currentLotId?: string
  throughput: number
}

const props = defineProps<Props>()

const statusClass = computed(() => ({
  'status-idle': props.status === 'idle',
  'status-processing': props.status === 'processing',
  'status-error': props.status === 'error',
  'status-maintenance': props.status === 'maintenance'
}))
</script>

<style scoped>
.equipment-card {
  background: #1e1e2e;
  border: 1px solid #333;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 8px;
  transition: all 0.3s ease;
}

.equipment-card:hover {
  border-color: #555;
}

.equipment-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.equipment-name {
  font-weight: 600;
  font-size: 14px;
  color: #fff;
}

.equipment-body {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.equipment-info {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
}

.label {
  color: #888;
}

.value {
  color: #ccc;
}

.status-idle {
  border-left: 3px solid #4caf50;
}

.status-processing {
  border-left: 3px solid #ffeb3b;
}

.status-error {
  border-left: 3px solid #f44336;
}

.status-maintenance {
  border-left: 3px solid #9e9e9e;
}
</style>
