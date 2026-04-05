<template>
  <div class="game-over flex flex-col items-center justify-center min-h-screen p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md text-center">
      <h1 class="text-4xl font-bold mb-2" :class="isVictory ? 'text-yellow-500' : 'text-gray-500'">
        {{ isVictory ? '🏆 Victory!' : '💀 Defeat' }}
      </h1>
      <p v-if="gameStore.winnerName" class="text-gray-500 mb-6 text-sm">
        {{ isVictory ? 'You won!' : `${gameStore.winnerName} wins` }}
      </p>

      <!-- Final standings -->
      <div v-if="gameStore.robots.length > 0" class="mb-6">
        <div class="space-y-2">
          <div
            v-for="robot in sortedRobots"
            :key="robot.playerId"
            class="flex items-center gap-3 p-3 rounded-lg"
            :class="robot.health > 0 ? 'bg-green-50 border border-green-200' : 'bg-gray-50 border border-gray-200'"
          >
            <span
              class="inline-block w-3 h-3 rounded-full flex-shrink-0"
              :style="{ backgroundColor: robot.color }"
            ></span>
            <span class="font-bold flex-1 text-left">
              {{ robot.name || robot.bot_name || 'Player' }}
              <span v-if="robot.playerId === playerStore.playerId" class="text-xs font-normal text-gray-400 ml-1">(you)</span>
              <span v-if="robot.health > 0" class="text-yellow-500 ml-1">🏆</span>
              <span v-else class="text-gray-400 ml-1">💀</span>
            </span>
            <span class="text-sm font-mono" :class="robot.health > 0 ? 'text-green-600' : 'text-gray-400'">
              {{ robot.health }} HP
            </span>
          </div>
        </div>
      </div>

      <!-- Action button -->
      <button
        v-if="!hasRequestedRematch"
        @click="requestRematch"
        class="w-full py-3 bg-purple-600 text-white font-bold rounded-lg hover:bg-purple-700 transition"
      >
        🔄 Let's Go Again!
      </button>
      <div
        v-else
        class="w-full py-3 bg-gray-100 text-gray-500 font-semibold rounded-lg text-center"
      >
        ⏳ Waiting for others…
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'
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
.game-over {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
</style>
