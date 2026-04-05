import { defineStore } from 'pinia'
import { ref } from 'vue'

export const usePlayerStore = defineStore('player', () => {
  const playerId = ref(null)
  const playerName = ref('')
  const playerColor = ref('#9b59b6')
  const isConnected = ref(false)

  const setPlayer = (id, name) => {
    playerId.value = id
    playerName.value = name
  }

  const setColor = (color) => {
    playerColor.value = color
  }

  const setConnected = (connected) => {
    isConnected.value = connected
  }

  const reset = () => {
    playerId.value = null
    playerName.value = ''
    playerColor.value = '#9b59b6'
    isConnected.value = false
  }

  return {
    playerId,
    playerName,
    playerColor,
    isConnected,
    setPlayer,
    setColor,
    setConnected,
    reset,
  }
})
