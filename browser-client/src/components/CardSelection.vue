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
    >{{ flyCard.icon }}</div>
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
    >{{ ghost.icon }}</div>
  </Teleport>

  <div class="card-selection flex flex-col items-center justify-center min-h-screen p-4">
    <div
      class="bg-white rounded-lg shadow-xl p-6 w-full max-w-md"
      :style="{ border: `3px solid ${playerStore.playerColor}` }"
    >
      <!-- Turn order strip -->
      <TurnOrderDisplay class="mb-5" />

      <!-- Loading spinner (before first hand arrives) -->
      <div v-if="gameStore.availableCards.length === 0 && !gameStore.turnSubmitted"
           class="flex flex-col items-center gap-3 py-10 text-gray-400">
        <span class="text-4xl animate-spin">⏳</span>
        <span class="text-sm">Receiving new hand…</span>
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
              <span v-if="gameStore.selectedCards[i] && !isFlying(gameStore.selectedCards[i]?.id)" class="text-4xl select-none">
                {{ gameStore.selectedCards[i].icon }}
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
            <span class="text-4xl select-none">{{ gameStore.turnSubmitted || !gameStore.canSubmitTurn ? '🔒' : '🔓' }}</span>
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
              <span class="text-3xl select-none leading-none">{{ card.icon }}</span>
              <span class="card-name">{{ card.name }}</span>
            </button>
          </div>

          <!-- Waiting overlay: spinning hourglass centred over the greyed-out hand -->
          <div v-if="gameStore.turnSubmitted" class="hand-overlay">
            <span class="spin-slow" style="display:inline-block; font-size:3rem">⏳</span>
          </div>
        </div>
      </template>

      <!-- Pile row — always rendered so refs are stable for animations -->
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
import websocket from '@/api/websocket'
import TurnOrderDisplay from '@/components/TurnOrderDisplay.vue'

const gameStore   = useGameStore()
const playerStore = usePlayerStore()

// DOM refs
const slotRefs        = ref([])
const cardRefs        = ref([])
const drawPileRef     = ref(null)
const discardPileRef  = ref(null)

// Single-card selection fly state
const flyCard   = ref(null)
const flyingIds = ref(new Set())

// Batch fly ghosts (deal / discard animations)
const flyCards   = ref([])
const dealingSet = ref(new Set())   // card IDs hidden while their deal ghost is in flight

// Tracks the first card ID of the last dealt hand to avoid re-animating the same hand
const dealtPhaseKey = ref(null)
// CSS class toggled on discard pile during shuffle animation
const discardShuffling = ref(false)

const isTaken  = (id) => flyingIds.value.has(id) || gameStore.isCardSelected(id)
const isFlying = (id) => id && flyingIds.value.has(id)

// ── Discard animation ─────────────────────────────────────────────────────────
async function runDiscardAnimation(selectedCards, handCards) {
  if (!discardPileRef.value) return

  const discardRect = discardPileRef.value.getBoundingClientRect()
  const discardCx = discardRect.left + discardRect.width  / 2
  const discardCy = discardRect.top  + discardRect.height / 2

  const ghosts = []

  // Selected cards fly from their slots
  for (let i = 0; i < selectedCards.length; i++) {
    const slotEl = slotRefs.value[i]
    if (!slotEl) continue
    const rect = slotEl.getBoundingClientRect()
    ghosts.push({
      id:   `discard-slot-${Date.now()}-${i}`,
      icon: selectedCards[i].icon,
      w: rect.width, h: rect.height,
      left: rect.left + rect.width  / 2 - rect.width  / 2,
      top:  rect.top  + rect.height / 2 - rect.height / 2,
      tx: 0, ty: 0,
    })
  }

  // Unselected cards fly from their grid positions
  const allCards = gameStore.availableCards
  for (let i = 0; i < handCards.length; i++) {
    const cardIdx = allCards.findIndex(c => c.id === handCards[i].id)
    const cardEl  = cardRefs.value[cardIdx]
    if (!cardEl) continue
    const rect = cardEl.getBoundingClientRect()
    ghosts.push({
      id:   `discard-hand-${Date.now()}-${i}`,
      icon: handCards[i].icon,
      w: rect.width, h: rect.height,
      left: rect.left,
      top:  rect.top,
      tx: 0, ty: 0,
    })
  }

  if (!ghosts.length) return

  flyCards.value = [...flyCards.value, ...ghosts]
  await nextTick()

  return new Promise(resolve => {
    ghosts.forEach((ghost, i) => {
      setTimeout(() => {
        const g = flyCards.value.find(x => x.id === ghost.id)
        if (g) {
          g.tx = (discardCx - g.w / 2) - g.left
          g.ty = (discardCy - g.h / 2) - g.top
        }
      }, i * 45)
    })
    setTimeout(() => {
      flyCards.value = flyCards.value.filter(g => !ghosts.some(x => x.id === g.id))
      resolve()
    }, ghosts.length * 45 + 360)
  })
}

// ── Deal animation ─────────────────────────────────────────────────────────────

// Fly a batch of cards from the draw pile to their grid positions.
async function dealBatch(cards, startIndex) {
  if (!drawPileRef.value || !cards.length) return
  const drawRect = drawPileRef.value.getBoundingClientRect()
  const drawCx   = drawRect.left + drawRect.width  / 2
  const drawCy   = drawRect.top  + drawRect.height / 2

  const ghosts = []
  for (let i = 0; i < cards.length; i++) {
    const el = cardRefs.value[startIndex + i]
    if (!el) continue
    const cardRect = el.getBoundingClientRect()
    const w = cardRect.width, h = cardRect.height
    ghosts.push({
      id:       `deal-${Date.now()}-${startIndex + i}`,
      icon:     cards[i].icon,
      cardId:   cards[i].id,
      w, h,
      left:     drawCx - w / 2,
      top:      drawCy - h / 2,
      tx: 0, ty: 0,
      destLeft: cardRect.left,
      destTop:  cardRect.top,
    })
  }
  if (!ghosts.length) return

  flyCards.value = [...flyCards.value, ...ghosts]
  await nextTick()

  return new Promise(resolve => {
    ghosts.forEach((ghost, i) => {
      setTimeout(() => {
        const g = flyCards.value.find(x => x.id === ghost.id)
        if (g) { g.tx = ghost.destLeft - ghost.left; g.ty = ghost.destTop - ghost.top }
        setTimeout(() => {
          dealingSet.value = new Set([...dealingSet.value].filter(id => id !== ghost.cardId))
        }, 300)
      }, i * 75)
    })
    setTimeout(() => {
      flyCards.value = flyCards.value.filter(g => !ghosts.some(x => x.id === g.id))
      resolve()
    }, ghosts.length * 75 + 380)
  })
}

// Shuffle animation on the discard pile, then "move" it to draw pile.
async function runShuffleAnimation() {
  discardShuffling.value = true
  await new Promise(resolve => setTimeout(resolve, 650))
  discardShuffling.value = false
}

async function runDealAnimation(cards) {
  if (!cards.length) return
  dealingSet.value = new Set(cards.map(c => c.id))
  await nextTick()

  const info = gameStore.shuffleInfo  // { cardsBeforeShuffle } or null
  if (info) {
    const splitAt = info.cardsBeforeShuffle
    if (splitAt > 0) {
      await dealBatch(cards.slice(0, splitAt), 0)
    }
    await runShuffleAnimation()
    await dealBatch(cards.slice(splitAt), splitAt)
  } else {
    await dealBatch(cards, 0)
  }

  dealingSet.value = new Set()
}

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
  // If the player has already submitted (or has cards selected), a round_ready /
  // discard sequence is coming — let the discardingCards watcher deal the new hand.
  if (gameStore.turnSubmitted || gameStore.selectedCards.length > 0) return
  const key = cards[0]?.id ?? null
  if (dealtPhaseKey.value === key) return
  dealtPhaseKey.value = key
  await nextTick()
  await runDealAnimation(cards)
})

// ── Card selection (single fly) ───────────────────────────────────────────────

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

  const from = cardEl.getBoundingClientRect()
  const to   = slotEl.getBoundingClientRect()

  flyCard.value = {
    icon: card.icon,
    left: from.left + from.width  / 2 - 32,
    top:  from.top  + from.height / 2 - 32,
    tx: 0,
    ty: 0,
  }
  flyingIds.value = new Set([...flyingIds.value, card.id])

  await nextTick()
  requestAnimationFrame(() => {
    flyCard.value.tx = (to.left + to.width  / 2 - 32) - flyCard.value.left
    flyCard.value.ty = (to.top  + to.height / 2 - 32) - flyCard.value.top
  })

  setTimeout(() => {
    gameStore.selectCard(card.id)
    flyingIds.value = new Set([...flyingIds.value].filter(id => id !== card.id))
    flyCard.value = null
  }, 380)
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
}

@keyframes spin-slow {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}
.spin-slow {
  animation: spin-slow 2.8s linear infinite;
}

.hand-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 8px 6px 6px;
  border-radius: 12px;
  border: 2px solid #e5e7eb;
  background: #f9fafb;
  transition: transform 0.15s, opacity 0.2s;
  cursor: pointer;
  height: 80px;
}

.card-name {
  font-size: 0.62rem;
  font-weight: 600;
  color: #374151;
  text-align: center;
  line-height: 1.1;
  white-space: normal;
  word-break: break-word;
  max-width: 100%;
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
  border-radius: 6px;
  border: 2px solid #4b5563;
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
  border-radius: 5px;
  border: 2px solid #4b5563;
  transform: translate(-3px, 3px);
  z-index: -1;
}
.pile-stack::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 5px;
  border: 2px solid #4b5563;
  transform: translate(-6px, 6px);
  z-index: -2;
}

.pile-stack--draw    { background: #1e293b; }
.pile-stack--discard { background: #374151; }
.pile-stack--draw::before,
.pile-stack--draw::after    { background: #1e293b; }
.pile-stack--discard::before,
.pile-stack--discard::after { background: #374151; }

.pile-count {
  font-size: 0.9rem;
  font-weight: 700;
  color: #f9fafb;
  position: relative;
  z-index: 1;
}

/* Flying ghosts */
.fly-card {
  position: fixed;
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

.fly-card--batch {
  font-size: 1.8rem;
  transition: transform 0.30s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Shuffle animation on discard pile */
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
