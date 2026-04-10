<template>
  <div v-if="orderedRobots.length > 0" class="turn-order flex justify-center items-center gap-1.5 px-3 py-2">
    <template v-for="(robot, index) in orderedRobots" :key="robot.playerId">
      <!-- Chevron between entries -->
      <span v-if="index > 0" class="text-[#6f6f87] text-xs select-none">&gt;</span>

      <!-- Player pill — color dot only, background tinted with player color -->
      <span
        class="turn-pill flex items-center px-2 py-1.5 transition-all duration-300"
        :style="pillStyle(robot, index)"
      >
        <span
          class="inline-block w-2.5 h-2.5 flex-shrink-0"
          :style="{ backgroundColor: robot.color }"
        ></span>
      </span>
    </template>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useGameStore } from '@/stores/gameStore'

const gameStore = useGameStore()

const orderedRobots = computed(() => {
  return gameStore.turnOrder
    .map(id => gameStore.robots.find(r => r.playerId === id))
    .filter(r => r && r.status !== 'dead')
})

function pillStyle(robot, index) {
  const isFirst = index === 0
  const color = robot.color || '#888'
  return {
    backgroundColor: isFirst ? color + '55' : color + '28',
    border: `1px solid ${color}${isFirst ? 'cc' : '66'}`,
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
