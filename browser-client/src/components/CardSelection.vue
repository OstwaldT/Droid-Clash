<template>
  <div class="card-selection flex flex-col items-center justify-center min-h-screen p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-2xl">
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
    </div>
  </div>
</template>

<script setup>
import { useGameStore } from '@/stores/gameStore'
import websocket from '@/api/websocket'

const gameStore = useGameStore()

const submitTurn = () => {
  if (!gameStore.canSubmitTurn.value) return

  websocket.send({
    type: 'turn_submit',
    data: {
      playerId: usePlayerStore().playerId,
      turnNumber: gameStore.turnNumber,
      cardIds: gameStore.selectedCards.map(c => c.id),
    },
  })

  gameStore.clearSelectedCards()
}
</script>

<style scoped>
.card-selection {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
</style>
