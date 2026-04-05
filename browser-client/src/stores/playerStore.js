import { defineStore } from 'pinia'
import { ref } from 'vue'

export const usePlayerStore = defineStore('player', () => {
  const playerId = ref(null)
  const playerName = ref('')
  const isConnected = ref(false)

  const setPlayer = (id, name) => {
    playerId.value = id
    playerName.value = name
  }

  const setConnected = (connected) => {
    isConnected.value = connected
  }

  const reset = () => {
    playerId.value = null
    playerName.value = ''
    isConnected.value = false
  }

  return {
    playerId,
    playerName,
    isConnected,
    setPlayer,
    setConnected,
    reset,
  }
})
