<template>
  <!-- Flying card overlay (teleported to body so it can cross layout boundaries) -->
  <Teleport to="body">
    <!-- Single-card selection ghost -->
    <div
      v-if="flyCard"
      class="fly-card"
      :style="{
        left: flyCard.left + 'px',
        top:  flyCard.top  + 'px',
        transform: `translate(${flyCard.tx}px, ${flyCard.ty}px)`,
        borderColor: playerStore.playerColor,
      }"
    >
      <PixelIcon :name="flyCard.iconKey" :size="36" />
    </div>
    <!-- Batch deal / discard ghosts -->
    <div
      v-for="ghost in flyCards"
      :key="ghost.id"
      class="fly-card fly-card--batch"
      :style="{
        left:        ghost.left + 'px',
        top:         ghost.top  + 'px',
        width:       ghost.w    + 'px',
        height:      ghost.h    + 'px',
        transform: `translate(${ghost.tx}px, ${ghost.ty}px)`,
        borderColor: playerStore.playerColor,
      }"
    >
      <PixelIcon :name="ghost.iconKey" :size="28" />
    </div>
  </Teleport>

  <div class="card-selection ui-screen flex flex-col items-center justify-center p-4">
    <div
      class="ui-panel p-6 w-full max-w-md"
      :style="{ border: `3px solid ${playerStore.playerColor}` }"
    >
      <!-- Turn order strip -->
      <TurnOrderDisplay class="mb-5" />

      <!-- Defeat overlay -->
      <div v-if="isDefeated" class="defeat-overlay flex flex-col items-center justify-center py-12 gap-4">
        <div class="text-[#a84b63] text-lg tracking-widest">DEFEATED</div>
        <p class="text-[0.55rem] text-[#88889a] text-center leading-[1.9]">Waiting for<br>the round to end</p>
      </div>

      <!-- Loading spinner (before first hand arrives) -->
      <template v-if="!isDefeated">
      <div v-if="gameStore.availableCards.length === 0 && !gameStore.turnSubmitted"
           class="flex flex-col items-center gap-4 py-10 text-center ui-copy">
        <div class="pixel-loader"></div>
        <span class="text-[0.65rem]">Receiving new hand...</span>
      </div>

      <template v-else>
        <!-- 3 target slots + padlock submit — always visible -->
        <div class="flex justify-center items-center gap-4 mb-6">
          <div
            v-for="(slot, i) in 3"
            :key="i"
            ref="slotRefs"
            class="slot"
            :class="gameStore.selectedCards[i] ? 'slot--filled' + (gameStore.turnSubmitted ? '' : ' cursor-pointer') : 'slot--empty'"
            :style="gameStore.selectedCards[i]
              ? { borderColor: playerStore.playerColor, backgroundColor: playerStore.playerColor + '18' }
              : {}"
            @click="!gameStore.turnSubmitted && gameStore.selectedCards[i] && deselectSlot(i)"
          >
            <transition name="pop">
              <span v-if="gameStore.selectedCards[i] && !isFlying(gameStore.selectedCards[i]?.id)" class="slot-icon">
                <PixelIcon :name="cardIconKey(gameStore.selectedCards[i])" :size="32" />
              </span>
            </transition>
          </div>
          <button
            class="slot transition-opacity"
            :class="gameStore.turnSubmitted
              ? 'slot--filled opacity-50 cursor-not-allowed'
              : gameStore.canSubmitTurn
                ? 'slot--filled cursor-pointer hover:scale-110 active:scale-95'
                : 'slot--empty opacity-30 cursor-not-allowed'"
            :style="(gameStore.canSubmitTurn || gameStore.turnSubmitted)
              ? { borderColor: playerStore.playerColor, backgroundColor: playerStore.playerColor + '33' }
              : {}"
            :disabled="!gameStore.canSubmitTurn || gameStore.turnSubmitted"
            @click="submitTurn"
          >
            <PixelIcon
              :name="gameStore.turnSubmitted || !gameStore.canSubmitTurn ? 'lock' : 'unlock'"
              :size="30"
            />
          </button>
        </div>

        <!-- Hand grid — always present; overlay shown when waiting -->
        <div class="hand-wrapper">
          <div class="hand-grid">
            <button
              v-for="(card, idx) in gameStore.availableCards"
              :key="card.id"
              :ref="el => { if (el) cardRefs[idx] = el }"
              class="hand-card"
              :class="[
                isTaken(card.id) || gameStore.turnSubmitted ? 'opacity-20 pointer-events-none' : 'hover:scale-105 active:scale-95',
              ]"
              :style="{
                ...(dealingSet.has(card.id) ? { visibility: 'hidden' } : {}),
                ...(!isTaken(card.id) && !gameStore.turnSubmitted && !dealingSet.has(card.id)
                  ? { borderColor: playerStore.playerColor + '88' }
                  : {}),
              }"
              @click="onCardClick(card, idx)"
            >
              <span class="card-icon">
                <PixelIcon :name="cardIconKey(card)" :size="30" />
              </span>
              <span class="card-name">{{ card.name }}</span>
            </button>
          </div>

          <!-- Waiting overlay: spinning hourglass centred over the greyed-out hand -->
          <div v-if="gameStore.turnSubmitted" class="hand-overlay">
            <div class="pixel-loader"></div>
          </div>
        </div>
      </template>

      <!-- Pile row — always rendered so refs are stable for animations -->
      </template> <!-- /v-if="!isDefeated" -->
      <div class="pile-row">
        <div class="pile-stack pile-stack--draw" ref="drawPileRef">
          <span class="pile-count">{{ gameStore.drawCount }}</span>
        </div>
        <div class="pile-stack pile-stack--discard" ref="discardPileRef" :class="{ 'pile-shuffle': discardShuffling }">
          <span class="pile-count">{{ gameStore.discardCount }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, watch } from 'vue'
import { useGameStore } from '@/stores/gameStore'
import { usePlayerStore } from '@/stores/playerStore'
import TurnOrderDisplay from '@/components/TurnOrderDisplay.vue'
import PixelIcon from '@/components/PixelIcon.vue'
import websocket from '@/api/websocket'
import { getCardIconKey } from '@/utils/iconKeys'
import { useCardAnimations } from '@/composables/useCardAnimations'

const gameStore   = useGameStore()
const playerStore = usePlayerStore()
const cardIconKey = getCardIconKey

const isDefeated = computed(() => {
  const robot = gameStore.robots.find(r => r.playerId === playerStore.playerId)
  return robot?.status === 'dead'
})

// DOM refs (passed into the composable)
const slotRefs       = ref([])
const cardRefs       = ref([])
const drawPileRef    = ref(null)
const discardPileRef = ref(null)

const {
  flyCard, flyCards, dealingSet, discardShuffling,
  isTaken, isFlying,
  runDiscardAnimation, runDealAnimation, flyCardToSlot,
  dealtPhaseKey,
} = useCardAnimations({ slotRefs, cardRefs, drawPileRef, discardPileRef })

// ── Watchers ──────────────────────────────────────────────────────────────────

// Round 2+: discardingCards populated → animate out → reset → animate in
watch(() => gameStore.discardingCards, async (cards) => {
  if (!cards.length) return
  await runDiscardAnimation(cards, gameStore.discardingHandCards)
  gameStore.finishDiscard()
  await nextTick()
  const newCards = gameStore.availableCards
  dealtPhaseKey.value = newCards[0]?.id ?? null
  await runDealAnimation(newCards)
})

// Round 1 / game start: phase transitions to card_selection
watch(() => gameStore.phase, (phase) => {
  if (phase !== 'card_selection') { dealtPhaseKey.value = null }
})

// First hand only: availableCards populated for the first time (no turn in flight).
// Rounds 2+ are handled by the discardingCards watcher after the discard animation.
watch(() => gameStore.availableCards, async (cards) => {
  if (gameStore.phase !== 'card_selection') return
  if (!cards.length) return
  if (gameStore.turnSubmitted || gameStore.selectedCards.length > 0) return
  const key = cards[0]?.id ?? null
  if (dealtPhaseKey.value === key) return
  dealtPhaseKey.value = key
  await nextTick()
  await runDealAnimation(cards)
})

// ── Card interaction ──────────────────────────────────────────────────────────

const onCardClick = async (card, idx) => {
  if (isTaken(card.id)) return
  const targetSlotIdx = gameStore.selectedCards.length
  if (targetSlotIdx >= 3) return

  const cardEl = cardRefs.value[idx]
  const slotEl = slotRefs.value[targetSlotIdx]
  if (!cardEl || !slotEl) {
    gameStore.selectCard(card.id)
    return
  }

  await flyCardToSlot(card, cardEl, slotEl)
  gameStore.selectCard(card.id)
}

const deselectSlot = (slotIdx) => {
  const card = gameStore.selectedCards[slotIdx]
  if (card) gameStore.selectCard(card.id)
}

const submitTurn = () => {
  if (!gameStore.canSubmitTurn) return
  websocket.send({
    type: 'turn_submit',
    data: {
      playerId:   playerStore.playerId,
      turnNumber: gameStore.turnNumber,
      cardIds:    gameStore.selectedCards.map(c => c.id),
    },
  })
  gameStore.setTurnSubmitted(true)
}
</script>

<style scoped>
.slot {
  width: 72px;
  height: 72px;
  border-radius: 0;
  border: 2px solid;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #121221;
  color: #f0c050;
  transition:
    background-color 0.2s,
    transform 0.15s ease;
}
.slot--empty {
  border-style: dashed;
  border-color: #515170;
  background: transparent;
}
.slot--filled {
  border-style: solid;
}

.slot-icon,
.card-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.hand-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}

.hand-wrapper {
  position: relative;
}

.hand-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  background: rgba(15, 15, 24, 0.55);
}

.hand-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 8px 6px 6px;
  border-radius: 0;
  border: 2px solid #3a3a5c;
  background: #141425;
  color: #f0c050;
  transition: transform 0.15s, opacity 0.2s;
  cursor: pointer;
  height: 80px;
}

.card-name {
  font-size: 0.62rem;
  font-weight: 600;
  color: #d8d8e8;
  text-align: center;
  line-height: 1.5;
  white-space: normal;
  word-break: break-word;
  max-width: 100%;
  text-transform: uppercase;
}

/* Pile row */
.pile-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px;
  padding: 0 4px;
}

.pile-stack {
  width: 40px;
  height: 54px;
  border-radius: 0;
  border: 2px solid #3a3a5c;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  cursor: default;
}

/* Stacked-card depth effect */
.pile-stack::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 0;
  border: 2px solid #3a3a5c;
  transform: translate(-3px, 3px);
  z-index: -1;
}
.pile-stack::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 0;
  border: 2px solid #3a3a5c;
  transform: translate(-6px, 6px);
  z-index: -2;
}

.pile-stack--draw    { background: #1f2333; }
.pile-stack--discard { background: #3a3a5c; }
.pile-stack--draw::before,
.pile-stack--draw::after    { background: #1f2333; }
.pile-stack--discard::before,
.pile-stack--discard::after { background: #3a3a5c; }

.pile-count {
  font-size: 0.9rem;
  font-weight: 700;
  color: #f8f8ff;
  position: relative;
  z-index: 1;
}

/* Flying ghosts */
.fly-card {
  position: fixed;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #141425;
  color: #f0c050;
  border: 2px solid;
  border-radius: 0;
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
  pointer-events: none;
  z-index: 9999;
  transition: transform 0.32s cubic-bezier(0.34, 1.4, 0.64, 1);
}
.fly-card--batch {
  transition: transform 0.30s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Shuffle animation on discard pile */
@keyframes defeat-flicker {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.6; }
}
.defeat-overlay {
  animation: defeat-flicker 2.4s ease-in-out infinite;
}

@keyframes pile-shuffle {
  0%   { transform: rotate(0deg)   scale(1);    }
  15%  { transform: rotate(-12deg) scale(1.15); }
  35%  { transform: rotate(10deg)  scale(1.15); }
  55%  { transform: rotate(-7deg)  scale(1.08); }
  75%  { transform: rotate(6deg)   scale(1.08); }
  90%  { transform: rotate(-2deg)  scale(1.02); }
  100% { transform: rotate(0deg)   scale(1);    }
}
.pile-shuffle {
  animation: pile-shuffle 0.65s cubic-bezier(0.34, 1.4, 0.64, 1);
}

/* Slot pop-in */
.pop-enter-active { transition: transform 0.22s cubic-bezier(0.34, 1.6, 0.64, 1), opacity 0.18s; }
.pop-enter-from   { transform: scale(0.4); opacity: 0; }
.pop-enter-to     { transform: scale(1);   opacity: 1; }
</style>
