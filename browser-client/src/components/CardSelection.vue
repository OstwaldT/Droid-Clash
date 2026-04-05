<template>
  <!-- Flying card overlay (teleported to body so it can cross layout boundaries) -->
  <Teleport to="body">
    <div
      v-if="flyCard"
      class="fly-card"
      :style="{
        left: flyCard.left + 'px',
        top: flyCard.top + 'px',
        transform: `translate(${flyCard.tx}px, ${flyCard.ty}px)`,
        borderColor: playerStore.playerColor,
      }"
    >{{ flyCard.icon }}</div>
  </Teleport>

  <div class="card-selection flex flex-col items-center justify-center min-h-screen p-4">
    <div
      class="bg-white rounded-lg shadow-xl p-6 w-full max-w-md"
      :style="{ border: `3px solid ${playerStore.playerColor}` }"
    >
      <!-- Turn order strip -->
      <TurnOrderDisplay class="mb-5" />

      <!-- ── WAITING STATE ── -->
      <template v-if="gameStore.turnSubmitted">
        <h2 class="text-xl font-bold text-center mb-4" :style="{ color: playerStore.playerColor }">Turn Submitted!</h2>

        <!-- Selected cards (read-only) -->
        <div class="flex justify-center gap-4 mb-6">
          <div
            v-for="card in gameStore.selectedCards"
            :key="card.id"
            class="slot slot--filled"
            :style="{ borderColor: playerStore.playerColor, backgroundColor: playerStore.playerColor + '18' }"
          >
            <span class="text-4xl">{{ card.icon }}</span>
          </div>
        </div>

        <div class="flex items-center justify-center gap-2 py-3 rounded-lg bg-gray-100 text-gray-500 font-semibold text-sm">
          <span class="animate-spin">⏳</span> Waiting for other players…
        </div>
      </template>

      <!-- ── SELECTION STATE ── -->
      <template v-else>

        <!-- Loading spinner -->
        <div v-if="gameStore.availableCards.length === 0" class="flex flex-col items-center gap-3 py-10 text-gray-400">
          <span class="text-4xl animate-spin">⏳</span>
          <span class="text-sm">Receiving new hand…</span>
        </div>

        <template v-else>
          <!-- 3 target slots -->
          <div class="flex justify-center gap-4 mb-6">
            <div
              v-for="(slot, i) in 3"
              :key="i"
              ref="slotRefs"
              class="slot"
              :class="gameStore.selectedCards[i] ? 'slot--filled cursor-pointer' : 'slot--empty'"
              :style="gameStore.selectedCards[i]
                ? { borderColor: playerStore.playerColor, backgroundColor: playerStore.playerColor + '18' }
                : {}"
              @click="gameStore.selectedCards[i] && deselectSlot(i)"
            >
              <transition name="pop">
                <span v-if="gameStore.selectedCards[i] && !isFlying(gameStore.selectedCards[i]?.id)" class="text-4xl select-none">
                  {{ gameStore.selectedCards[i].icon }}
                </span>
              </transition>
            </div>
          </div>

          <!-- Hand — icon only -->
          <div class="grid grid-cols-3 gap-3 mb-6">
            <button
              v-for="(card, idx) in gameStore.availableCards"
              :key="card.id"
              :ref="el => { if (el) cardRefs[idx] = el }"
              class="hand-card"
              :class="isTaken(card.id) ? 'opacity-20 pointer-events-none' : 'hover:scale-110 active:scale-95'"
              :style="!isTaken(card.id) ? { borderColor: playerStore.playerColor + '55' } : {}"
              @click="onCardClick(card, idx)"
            >
              <span class="text-4xl select-none">{{ card.icon }}</span>
            </button>
          </div>

          <!-- Submit -->
          <button
            @click="submitTurn"
            :disabled="!gameStore.canSubmitTurn"
            class="w-full py-3 text-white font-bold text-lg rounded-lg transition disabled:opacity-40 disabled:cursor-not-allowed"
            :style="gameStore.canSubmitTurn ? { backgroundColor: playerStore.playerColor } : { backgroundColor: '#9ca3af' }"
          >
            Submit Turn
          </button>
        </template>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick } from 'vue'
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'
import websocket from '@/api/websocket'
import TurnOrderDisplay from '@/components/TurnOrderDisplay.vue'

const gameStore = useGameStore()
const playerStore = usePlayerStore()

// DOM refs
const slotRefs = ref([])
const cardRefs = ref([])

// Flying card state
const flyCard = ref(null)
// IDs currently mid-flight (prevent double-clicks & premature slot render)
const flyingIds = ref(new Set())

const isTaken = (id) =>
  flyingIds.value.has(id) || gameStore.isCardSelected(id)

const isFlying = (id) => id && flyingIds.value.has(id)

const onCardClick = async (card, idx) => {
  if (isTaken(card.id)) return
  const targetSlotIdx = gameStore.selectedCards.length
  if (targetSlotIdx >= 3) return

  const cardEl = cardRefs.value[idx]
  const slotEl = slotRefs.value[targetSlotIdx]
  if (!cardEl || !slotEl) {
    // Fallback: no animation
    gameStore.selectCard(card.id)
    return
  }

  const from = cardEl.getBoundingClientRect()
  const to   = slotEl.getBoundingClientRect()

  // Place ghost at source (no transition yet)
  flyCard.value = {
    icon: card.icon,
    left: from.left + from.width / 2 - 32,
    top:  from.top  + from.height / 2 - 32,
    tx: 0,
    ty: 0,
  }
  flyingIds.value = new Set([...flyingIds.value, card.id])

  // Next frame: animate to target
  await nextTick()
  requestAnimationFrame(() => {
    flyCard.value.tx = (to.left + to.width  / 2 - 32) - flyCard.value.left
    flyCard.value.ty = (to.top  + to.height / 2 - 32) - flyCard.value.top
  })

  // Commit after animation (320ms transition + small buffer)
  setTimeout(() => {
    gameStore.selectCard(card.id)
    flyingIds.value = new Set([...flyingIds.value].filter(id => id !== card.id))
    flyCard.value = null
  }, 380)
}

const deselectSlot = (slotIdx) => {
  const card = gameStore.selectedCards[slotIdx]
  if (card) gameStore.selectCard(card.id)  // toggles off
}

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
}
</script>

<style scoped>
.card-selection {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.slot {
  width: 72px;
  height: 72px;
  border-radius: 12px;
  border: 2px solid;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.2s;
}
.slot--empty {
  border-style: dashed;
  border-color: #d1d5db;
  background: transparent;
}
.slot--filled {
  border-style: solid;
}

.hand-card {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  aspect-ratio: 1;
  border-radius: 12px;
  border: 2px solid;
  background: #f9fafb;
  transition: transform 0.15s, opacity 0.2s;
  cursor: pointer;
}

/* Flying ghost */
.fly-card {
  position: fixed;
  width: 64px;
  height: 64px;
  font-size: 2.2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 2px solid;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
  pointer-events: none;
  z-index: 9999;
  transition: transform 0.32s cubic-bezier(0.34, 1.4, 0.64, 1);
}

/* Slot pop-in */
.pop-enter-active { transition: transform 0.22s cubic-bezier(0.34, 1.6, 0.64, 1), opacity 0.18s; }
.pop-enter-from   { transform: scale(0.4); opacity: 0; }
.pop-enter-to     { transform: scale(1);   opacity: 1; }
</style>
