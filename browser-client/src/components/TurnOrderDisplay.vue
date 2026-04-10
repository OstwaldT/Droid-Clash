<template>
  <div v-if="orderedRobots.length > 0" class="turn-order flex justify-center items-center gap-1.5 px-3 py-2">
    <template v-for="(robot, index) in orderedRobots" :key="robot.playerId">
      <!-- Arrow between entries -->
      <span v-if="index > 0" class="text-[#6f6f87] text-xs select-none">&gt;</span>

      <!-- Player pill -->
      <span
        class="turn-pill flex items-center gap-1 px-2 py-1 text-xs whitespace-nowrap transition-all duration-300"
        :style="pillStyle(robot, index)"
      >
        <!-- Position badge -->
        <span
          class="inline-flex items-center justify-center w-4 h-4 text-[10px] leading-none border border-current"
          :style="{ backgroundColor: robot.color + '44', color: robot.color }"
        >{{ index + 1 }}</span>

        <!-- Color dot -->
        <span
          class="inline-block w-1.5 h-1.5 flex-shrink-0"
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
  const color = robot.color || '#888'
  return {
    backgroundColor: isFirst ? color + '33' : color + '18',
    border: `1px solid ${color}${isFirst ? 'aa' : '44'}`,
    color: '#f1f5f9',
  }
}
</script>

<style scoped>
.turn-order {
  background: #141425;
  border: 2px solid #3a3a5c;
}

.turn-pill {
  border-radius: 0;
}
</style>
