<template>
  <div id="app">
    <LobbyScreen v-if="!playerStore.isConnected || gameStore.phase === 'lobby'" />
    <CardSelection v-else-if="gameStore.phase === 'card_selection'" />
    <HexBoard v-else-if="gameStore.phase === 'executing' || gameStore.phase === 'playing'" />
    <GameOverScreen v-else-if="gameStore.phase === 'game_over'" />

    <!-- Player status HUD — visible during card selection and execution -->
    <div
      v-if="gameStore.phase === 'card_selection' || gameStore.phase === 'executing' || gameStore.phase === 'playing'"
      class="hud-overlay"
    >
      <PlayerStatusHUD />
    </div>
  </div>
</template>

<script setup>
import { usePlayerStore } from '@/stores/playerStore'
import { useGameStore } from '@/stores/gameStore'
import LobbyScreen from '@/components/LobbyScreen.vue'
import CardSelection from '@/components/CardSelection.vue'
import HexBoard from '@/components/HexBoard.vue'
import GameOverScreen from '@/components/GameOverScreen.vue'
import PlayerStatusHUD from '@/components/PlayerStatusHUD.vue'

const playerStore = usePlayerStore()
const gameStore = useGameStore()
</script>

<style>
#app {
  width: 100%;
  height: 100%;
  position: relative;
}

.hud-overlay {
  position: fixed;
  top: 12px;
  right: 12px;
  z-index: 100;
  pointer-events: none;
  max-width: 320px;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}
</style>
