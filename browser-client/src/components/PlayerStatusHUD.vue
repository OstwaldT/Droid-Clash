<template>
  <div class="player-status-hud flex flex-wrap gap-2 p-2">
    <div
      v-for="robot in gameStore.robots"
      :key="robot.playerId"
      class="flex items-center gap-2 px-3 py-1.5 rounded-full text-sm font-semibold shadow transition-all duration-300"
      :style="pillStyle(robot)"
    >
      <!-- Color dot -->
      <span
        class="inline-block w-2.5 h-2.5 rounded-full flex-shrink-0"
        :style="{ backgroundColor: robot.color || '#888' }"
      ></span>

      <!-- Name (truncated) -->
      <span class="max-w-[80px] truncate leading-tight">{{ robot.name || `P${robot.playerId}` }}</span>

      <!-- Status icon + label -->
      <span class="flex items-center gap-1 leading-tight" :style="{ color: statusColor(robot.playerId, robot.color) }">
        <span>{{ statusIcon(robot.playerId) }}</span>
        <span class="text-xs uppercase tracking-wide">{{ statusLabel(robot.playerId) }}</span>
      </span>
    </div>
  </div>
</template>

<script setup>
import { useGameStore } from '@/stores/gameStore'

const gameStore = useGameStore()

function getStatus(playerId) {
  return gameStore.playerStatuses[playerId] ?? 'selecting'
}

function statusIcon(playerId) {
  const s = getStatus(playerId)
  if (s === 'submitted') return '✓'
  if (s === 'acting')    return '⚡'
  return '…'
}

function statusLabel(playerId) {
  const s = getStatus(playerId)
  if (s === 'submitted') return 'Ready'
  if (s === 'acting')    return 'Acting'
  return 'Selecting'
}

function statusColor(playerId, robotColor) {
  const s = getStatus(playerId)
  if (s === 'submitted') return '#22c55e'  // green-500
  if (s === 'acting')    return '#f59e0b'  // amber-500
  return '#9ca3af'                          // gray-400
}

function pillStyle(robot) {
  const s = getStatus(robot.playerId)
  const color = robot.color || '#888'
  const bg = s === 'submitted'
    ? color + '30'   // tinted green-ish
    : s === 'acting'
      ? '#f59e0b22'
      : '#ffffff18'
  return {
    backgroundColor: bg,
    border: `1px solid ${color}55`,
    color: '#f1f5f9',
  }
}
</script>
