import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useGameStore = defineStore('game', () => {
  // Game state
  const gameId = ref(null)
  const phase = ref('lobby') // lobby, card_selection, executing, game_over
  const turnNumber = ref(0)
  const maxPlayers = ref(8)
  const boardWidth = ref(10)
  const boardHeight = ref(10)

  // Players & robots
  const players = ref([])
  const robots = ref([])
  const availableCards = ref([])
  const selectedCards = ref([])

  // Turn submission state
  const turnSubmitted = ref(false)

  // Per-player status map: { [playerId]: 'selecting' | 'submitted' | 'acting' }
  const playerStatuses = ref({})

  // Actions
  const setGameState = (state) => {
    gameId.value = state.gameId
    phase.value = state.phase
    turnNumber.value = state.turnNumber
    boardWidth.value = state.boardWidth
    boardHeight.value = state.boardHeight
    players.value = state.players
    robots.value = state.robots
  }

  const setAvailableCards = (cards) => {
    availableCards.value = cards
  }

  const selectCard = (cardId) => {
    const card = availableCards.value.find(c => c.id === cardId)
    if (!card) return

    // Remove if already selected
    const index = selectedCards.value.findIndex(c => c.id === cardId)
    if (index !== -1) {
      selectedCards.value.splice(index, 1)
      return
    }

    // Add if not at limit
    if (selectedCards.value.length < 3) {
      selectedCards.value.push(card)
    }
  }

  const clearSelectedCards = () => {
    selectedCards.value = []
    turnSubmitted.value = false
  }

  const setTurnSubmitted = (val) => {
    turnSubmitted.value = val
  }

  const setPlayerStatuses = (statusArray) => {
    const map = {}
    for (const entry of statusArray) {
      map[entry.playerId] = entry.status
    }
    playerStatuses.value = map
  }

  const resetPlayerStatuses = () => {
    const map = {}
    for (const id of Object.keys(playerStatuses.value)) {
      map[id] = 'selecting'
    }
    playerStatuses.value = map
  }

  const isCardSelected = (cardId) => {
    return selectedCards.value.some(c => c.id === cardId)
  }

  const canSubmitTurn = computed(() => {
    return selectedCards.value.length === 3
  })

  return {
    gameId,
    phase,
    turnNumber,
    maxPlayers,
    boardWidth,
    boardHeight,
    players,
    robots,
    availableCards,
    selectedCards,
    turnSubmitted,
    playerStatuses,
    setGameState,
    setAvailableCards,
    setTurnSubmitted,
    setPlayerStatuses,
    resetPlayerStatuses,
    selectCard,
    clearSelectedCards,
    isCardSelected,
    canSubmitTurn,
  }
})
