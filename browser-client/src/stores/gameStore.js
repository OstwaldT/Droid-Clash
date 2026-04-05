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

  // Execution order for the upcoming round: array of player IDs
  const turnOrder = ref([])

  // Player IDs who have requested a rematch (shown on game-over screen)
  const rematchPlayers = ref([])

  // Countdown value (3/2/1) shown in the lobby before a game starts; null = no countdown
  const countdown = ref(null)

  // Deck pile counts (updated each hand_update)
  const drawCount = ref(0)
  const discardCount = ref(0)

  // Cards being animated to the discard pile at end of round (snapshot of selectedCards)
  const discardingCards = ref([])
  // Unselected hand cards also flying to discard (snapshot of availableCards minus selected)
  const discardingHandCards = ref([])

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

  const setAvailableCards = (cards, counts = null) => {
    availableCards.value = cards
    if (counts) {
      drawCount.value = counts.draw ?? 0
      discardCount.value = counts.discard ?? 0
    }
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
    availableCards.value = []   // also wipe the hand — new one arrives via hand_update
    turnSubmitted.value = false
  }

  // Reset selection state between rounds WITHOUT wiping availableCards.
  // Used by handleGameStateUpdate: the fresh hand already arrived via hand_update
  // (sent by the server before game_state_update), so clearing availableCards here
  // would discard the new hand and leave the UI stuck on the loading spinner.
  const resetRoundState = () => {
    selectedCards.value = []
    turnSubmitted.value = false
  }

  // Snapshot selectedCards so CardSelection can animate them out.
  // If there's nothing to animate, resets immediately.
  const snapshotDiscardCards = () => {
    if (selectedCards.value.length === 0) {
      turnSubmitted.value = false
      return
    }
    discardingCards.value = [...selectedCards.value]
    const selectedIds = new Set(selectedCards.value.map(c => c.id))
    discardingHandCards.value = availableCards.value.filter(c => !selectedIds.has(c.id))
  }

  // Called by CardSelection after the discard animation completes.
  const finishDiscard = () => {
    discardingCards.value = []
    discardingHandCards.value = []
    selectedCards.value = []
    turnSubmitted.value = false
  }

  const reset = () => {
    gameId.value = null
    phase.value = 'lobby'
    turnNumber.value = 0
    players.value = []
    robots.value = []
    availableCards.value = []
    selectedCards.value = []
    turnSubmitted.value = false
    playerStatuses.value = {}
    turnOrder.value = []
    rematchPlayers.value = []
    countdown.value = null
    drawCount.value = 0
    discardCount.value = 0
    discardingCards.value = []
    discardingHandCards.value = []
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
    turnOrder,
    rematchPlayers,
    countdown,
    drawCount,
    discardCount,
    discardingCards,
    discardingHandCards,
    snapshotDiscardCards,
    finishDiscard,
    setGameState,
    setAvailableCards,
    setTurnSubmitted,
    setPlayerStatuses,
    resetPlayerStatuses,
    selectCard,
    clearSelectedCards,
    resetRoundState,
    reset,
    isCardSelected,
    canSubmitTurn,
  }
})
