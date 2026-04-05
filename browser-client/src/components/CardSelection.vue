<template>
  <div class="card-selection flex flex-col items-center justify-center min-h-screen p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-2xl">

      <!-- Waiting state: turn submitted, round not yet resolved -->
      <template v-if="gameStore.turnSubmitted">
        <h1 class="text-3xl font-bold text-center mb-2 text-green-600">Turn Submitted!</h1>
        <p class="text-center text-gray-500 mb-6">Waiting for other players…</p>

        <div class="grid grid-cols-3 gap-4 mb-8">
          <div
            v-for="card in gameStore.selectedCards"
            :key="card.id"
            class="p-4 rounded-lg border-2 border-green-400 bg-green-50 text-center opacity-80"
          >
            <div class="text-3xl mb-2">{{ card.icon }}</div>
            <div class="font-semibold text-green-900">{{ card.name }}</div>
          </div>
        </div>

        <div class="flex items-center justify-center gap-3 py-3 rounded-lg bg-gray-100 text-gray-500 font-semibold">
          <span class="animate-spin text-xl">⏳</span>
          Waiting for other players
        </div>
      </template>

      <!-- Normal card selection state -->
      <template v-else>
        <h1 class="text-3xl font-bold text-center mb-2 text-purple-600">Select Your Cards</h1>
        <p class="text-center text-gray-600 mb-6">Choose 3 cards for this turn ({{ gameStore.selectedCards.length }}/3)</p>

        <div class="grid grid-cols-2 gap-4 mb-8">
          <button
            v-for="card in gameStore.availableCards"
            :key="card.id"
            @click="gameStore.selectCard(card.id)"
            :class="[
              'p-4 rounded-lg font-semibold text-lg transition border-2',
              gameStore.isCardSelected(card.id)
                ? 'border-purple-600 bg-purple-100 text-purple-900'
                : 'border-gray-300 bg-gray-50 text-gray-800 hover:border-purple-400 hover:bg-purple-50'
            ]"
          >
            <div class="text-3xl mb-2">{{ card.icon }}</div>
            <div>{{ card.name }}</div>
          </button>
        </div>

        <button
          @click="submitTurn"
          :disabled="!gameStore.canSubmitTurn"
          class="w-full py-3 bg-green-600 text-white font-bold text-lg rounded-lg hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
        >
          Submit Turn
        </button>
      </template>

    </div>
  </div>
</template>

<script setup>
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'
import websocket from '@/api/websocket'

const gameStore = useGameStore()
const playerStore = usePlayerStore()

const submitTurn = () => {
  if (!gameStore.canSubmitTurn) return

  websocket.send({
    type: 'turn_submit',
    data: {
      playerId: playerStore.playerId,
      turnNumber: gameStore.turnNumber,
      cardIds: gameStore.selectedCards.map(c => c.id),
    },
  })

  gameStore.setTurnSubmitted(true)
  // selectedCards intentionally kept so the waiting view can display them
}
</script>

<style scoped>
.card-selection {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
</style>
