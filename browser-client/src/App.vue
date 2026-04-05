<template>
  <div id="app">
    <LobbyScreen v-if="!playerStore.isConnected || gameStore.phase === 'lobby'" />
    <CardSelection v-else-if="gameStore.phase === 'card_selection'" />
    <HexBoard v-else-if="gameStore.phase === 'executing' || gameStore.phase === 'playing'" />
    <GameOverScreen v-else-if="gameStore.phase === 'game_over'" />
  </div>
</template>

<script setup>
import { usePlayerStore } from '@/stores/playerStore'
import { useGameStore } from '@/stores/gameStore'
import LobbyScreen from '@/components/LobbyScreen.vue'
import CardSelection from '@/components/CardSelection.vue'
import HexBoard from '@/components/HexBoard.vue'
import GameOverScreen from '@/components/GameOverScreen.vue'

const playerStore = usePlayerStore()
const gameStore = useGameStore()
</script>

<style>
#app {
  width: 100%;
  height: 100%;
}
</style>
