<template>
  <div class="game-over flex flex-col items-center justify-center min-h-screen p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md text-center">
      <h1 class="text-4xl font-bold mb-4 text-purple-600">🎉 Game Over!</h1>
      
      <div v-if="gameStore.robots.length > 0" class="mb-8">
        <p class="text-2xl font-bold text-green-600 mb-2">Winner: Player 1</p>
        <div class="space-y-2">
          <div
            v-for="robot in gameStore.robots"
            :key="robot.playerId"
            class="p-3 bg-gray-50 rounded"
          >
            <div class="font-semibold">{{ robot.name || `Player ${robot.playerId}` }}</div>
            <div class="text-sm text-gray-600">Health: {{ robot.health }}</div>
          </div>
        </div>
      </div>

      <button
        @click="returnToLobby"
        class="w-full py-3 bg-purple-600 text-white font-bold rounded-lg hover:bg-purple-700 transition"
      >
        Return to Lobby
      </button>
    </div>
  </div>
</template>

<script setup>
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'
import websocket from '@/api/websocket'

const gameStore = useGameStore()
const playerStore = usePlayerStore()

const returnToLobby = () => {
  gameStore.reset()
  playerStore.reset()
  websocket.disconnect()
}
</script>

<style scoped>
.game-over {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
</style>
