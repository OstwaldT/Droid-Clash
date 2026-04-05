<template>
  <div v-if="orderedRobots.length > 0" class="turn-order flex items-center gap-1.5 px-3 py-2 rounded-lg">
    <span class="text-xs font-semibold uppercase tracking-widest text-gray-400 mr-1 whitespace-nowrap">Act order</span>

    <template v-for="(robot, index) in orderedRobots" :key="robot.playerId">
      <!-- Arrow between entries -->
      <span v-if="index > 0" class="text-gray-500 text-xs select-none">›</span>

      <!-- Player pill -->
      <span
        class="flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold whitespace-nowrap transition-all duration-300"
        :class="robot.playerId === playerStore.playerId ? 'ring-2 ring-offset-1 ring-offset-transparent' : ''"
        :style="pillStyle(robot, index)"
      >
        <!-- Position badge -->
        <span
          class="inline-flex items-center justify-center w-4 h-4 rounded-full text-[10px] font-bold leading-none"
          :style="{ backgroundColor: robot.color + '44', color: robot.color }"
        >{{ index + 1 }}</span>

        <!-- Color dot -->
        <span
          class="inline-block w-1.5 h-1.5 rounded-full flex-shrink-0"
          :style="{ backgroundColor: robot.color }"
        ></span>

        <!-- Name, truncated -->
        <span class="max-w-[56px] truncate leading-none">
          {{ robot.playerId === playerStore.playerId ? 'You' : (robot.name || robot.bot_name || `P${robot.playerId}`) }}
        </span>
      </span>
    </template>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'

const gameStore = useGameStore()
const playerStore = usePlayerStore()

// Map turn order IDs to full robot objects for display
const orderedRobots = computed(() => {
  return gameStore.turnOrder
    .map(id => gameStore.robots.find(r => r.playerId === id))
    .filter(Boolean)
})

function pillStyle(robot, index) {
  const isFirst = index === 0
  const isMe = robot.playerId === playerStore.playerId
  const color = robot.color || '#888'
  return {
    backgroundColor: isFirst ? color + '33' : color + '18',
    border: `1px solid ${color}${isFirst ? 'aa' : '44'}`,
    color: '#f1f5f9',
    ...(isMe ? { ringColor: color } : {}),
  }
}
</script>

<style scoped>
.turn-order {
  background: rgba(0, 0, 0, 0.15);
}
</style>
