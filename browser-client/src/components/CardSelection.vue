<template>
  <div class="card-selection flex flex-col items-center justify-center min-h-screen p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-2xl">

      <!-- Player identity bar, colored to this player's assigned color -->
      <div
        class="flex items-center gap-3 mb-6 px-4 py-2 rounded-lg"
        :style="{ backgroundColor: playerStore.playerColor + '22', borderLeft: `4px solid ${playerStore.playerColor}` }"
      >
        <span
          class="inline-block w-4 h-4 rounded-full flex-shrink-0"
          :style="{ backgroundColor: playerStore.playerColor }"
        ></span>
        <span class="font-bold text-gray-800">{{ playerStore.playerName }}</span>
      </div>

      <!-- Waiting state: turn submitted, round not yet resolved -->
      <template v-if="gameStore.turnSubmitted">
        <h1 class="text-3xl font-bold text-center mb-2" :style="{ color: playerStore.playerColor }">Turn Submitted!</h1>
        <p class="text-center text-gray-500 mb-6">Waiting for other players…</p>

        <div class="grid grid-cols-3 gap-4 mb-8">
          <div
            v-for="card in gameStore.selectedCards"
            :key="card.id"
            class="p-4 rounded-lg border-2 text-center opacity-80"
            :style="{ borderColor: playerStore.playerColor, backgroundColor: playerStore.playerColor + '18' }"
          >
            <div class="text-3xl mb-2">{{ card.icon }}</div>
            <div class="font-semibold text-gray-800">{{ card.name }}</div>
          </div>
        </div>

        <div class="flex items-center justify-center gap-3 py-3 rounded-lg bg-gray-100 text-gray-500 font-semibold">
          <span class="animate-spin text-xl">⏳</span>
          Waiting for other players
        </div>
      </template>

      <!-- Normal card selection state -->
      <template v-else>
        <h1 class="text-3xl font-bold text-center mb-2" :style="{ color: playerStore.playerColor }">Select Your Cards</h1>
        <p class="text-center text-gray-600 mb-6">Choose 3 cards for this turn ({{ gameStore.selectedCards.length }}/3)</p>

        <!-- Loading state while waiting for new hand after a round -->
        <div v-if="gameStore.availableCards.length === 0" class="flex flex-col items-center justify-center gap-3 py-10 text-gray-400">
          <span class="text-4xl animate-spin">⏳</span>
          <span class="text-sm font-medium">Receiving new hand…</span>
        </div>

        <div v-else class="grid grid-cols-3 gap-3 mb-8">
          <button
            v-for="card in gameStore.availableCards"
            :key="card.id"
            @click="gameStore.selectCard(card.id)"
            class="p-3 rounded-lg font-semibold transition border-2 flex flex-col items-center text-center"
            :style="gameStore.isCardSelected(card.id)
              ? { borderColor: playerStore.playerColor, backgroundColor: playerStore.playerColor + '22', color: '#1a1a2e' }
              : {}"
            :class="gameStore.isCardSelected(card.id) ? '' : 'border-gray-300 bg-gray-50 text-gray-800 hover:border-gray-400 hover:bg-gray-100'"
          >
            <div class="text-3xl mb-1">{{ card.icon }}</div>
            <div class="text-sm font-bold">{{ card.name }}</div>
            <div v-if="card.description" class="mt-1 text-xs text-gray-500 leading-tight">{{ card.description }}</div>
            <div
              v-if="gameStore.isCardSelected(card.id)"
              class="mt-1 text-xs font-bold"
              :style="{ color: playerStore.playerColor }"
            >
              #{{ gameStore.selectedCards.findIndex(c => c.id === card.id) + 1 }}
            </div>
          </button>
        </div>

        <button
          v-if="gameStore.availableCards.length > 0"
          @click="submitTurn"
          :disabled="!gameStore.canSubmitTurn"
          class="w-full py-3 text-white font-bold text-lg rounded-lg transition disabled:bg-gray-400 disabled:cursor-not-allowed"
          :style="gameStore.canSubmitTurn ? { backgroundColor: playerStore.playerColor } : {}"
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
