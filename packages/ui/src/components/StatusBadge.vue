<template>
  <span class="status-badge" :class="statusClass">
    {{ displayText }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  status: string
}

const props = defineProps<Props>()

const statusMap: Record<string, { text: string; class: string }> = {
  idle: { text: '空闲', class: 'badge-idle' },
  loading: { text: '加载中', class: 'badge-loading' },
  processing: { text: '加工中', class: 'badge-processing' },
  unloading: { text: '卸载中', class: 'badge-loading' },
  error: { text: '故障', class: 'badge-error' },
  maintenance: { text: '维护', class: 'badge-maintenance' },
  waiting: { text: '等待中', class: 'badge-waiting' },
  completed: { text: '已完成', class: 'badge-completed' },
  on_hold: { text: '暂停', class: 'badge-hold' }
}

const displayText = computed(() => statusMap[props.status]?.text || props.status)
const statusClass = computed(() => statusMap[props.status]?.class || '')
</script>

<style scoped>
.status-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
}

.badge-idle {
  background: rgba(76, 175, 80, 0.2);
  color: #4caf50;
}

.badge-loading {
  background: rgba(255, 152, 0, 0.2);
  color: #ff9800;
}

.badge-processing {
  background: rgba(255, 235, 59, 0.2);
  color: #ffeb3b;
}

.badge-error {
  background: rgba(244, 67, 54, 0.2);
  color: #f44336;
}

.badge-maintenance {
  background: rgba(158, 158, 158, 0.2);
  color: #9e9e9e;
}

.badge-waiting {
  background: rgba(33, 150, 243, 0.2);
  color: #2196f3;
}

.badge-completed {
  background: rgba(156, 39, 176, 0.2);
  color: #9c27b0;
}

.badge-hold {
  background: rgba(121, 85, 72, 0.2);
  color: #795548;
}
</style>
