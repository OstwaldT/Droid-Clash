<template>
  <div class="game-over ui-screen flex flex-col items-center justify-center p-4 h-screen">
    <div class="ui-panel p-8 w-full max-w-md text-center">
      <div class="flex justify-center mb-4" :class="isVictory ? 'text-[#f0c050]' : 'text-[#8d8da6]'">
        <PixelIcon :name="isVictory ? 'attack' : 'lock'" :size="28" />
      </div>
      <h1 class="text-xl mb-2" :class="isVictory ? 'text-[#f0c050]' : 'text-[#8d8da6]'">
        {{ isVictory ? 'Victory' : 'Defeat' }}
      </h1>
      <p v-if="gameStore.winnerName" class="ui-copy mb-6 text-[0.58rem]">
        {{ isVictory ? 'You won!' : `${gameStore.winnerName} wins` }}
      </p>

      <!-- Final standings -->
      <div v-if="gameStore.robots.length > 0" class="mb-6">
        <div class="space-y-2">
          <div
            v-for="robot in sortedRobots"
            :key="robot.playerId"
            class="flex items-center gap-3 p-3 border-2"
            :class="robot.health > 0 ? 'bg-[#102116] border-[#40c860]' : 'bg-[#141425] border-[#3a3a5c]'"
          >
            <span
              class="ui-status-square"
              :style="{ backgroundColor: robot.color }"
            ></span>
            <span class="flex-1 text-left text-[0.58rem] leading-[1.7]">
              {{ robot.name || robot.bot_name || 'Player' }}
              <span v-if="robot.playerId === playerStore.playerId" class="text-[#8d8da6] ml-1">(you)</span>
            </span>
            <span class="text-[0.58rem]" :class="robot.health > 0 ? 'text-[#40c860]' : 'text-[#8d8da6]'">
              {{ robot.health }} HP
            </span>
          </div>
        </div>
      </div>

      <!-- Action button -->
      <button
        v-if="!hasRequestedRematch"
        @click="requestRematch"
        class="ui-button ui-button--accent w-full py-3 text-[0.62rem]"
      >
        Play Again
      </button>
      <div
        v-else
        class="ui-section w-full py-3 text-[#b7b7ca] text-[0.58rem] text-center"
      >
        Waiting for others...
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'
import PixelIcon from '@/components/PixelIcon.vue'
import websocket from '@/api/websocket'

const gameStore = useGameStore()
const playerStore = usePlayerStore()

const hasRequestedRematch = ref(false)

const isVictory = computed(() => gameStore.winnerId === playerStore.playerId)

const sortedRobots = computed(() => {
  return [...gameStore.robots].sort((a, b) => b.health - a.health)
})

const requestRematch = () => {
  hasRequestedRematch.value = true
  websocket.send({ type: 'rematch', data: {} })
}
</script>

<style scoped>
</style>
