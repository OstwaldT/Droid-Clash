import { ref, nextTick } from 'vue'
import { useGameStore } from '@/stores/gameStore'
import { getCardIconKey } from '@/utils/iconKeys'

/**
 * Manages all card animation state and logic for CardSelection.
 *
 * @param {object} refs - DOM refs owned by the parent component
 * @param {import('vue').Ref} refs.slotRefs
 * @param {import('vue').Ref} refs.cardRefs
 * @param {import('vue').Ref} refs.drawPileRef
 * @param {import('vue').Ref} refs.discardPileRef
 */
export function useCardAnimations({ slotRefs, cardRefs, drawPileRef, discardPileRef }) {
  const gameStore = useGameStore()

  // ── State ────────────────────────────────────────────────────────────────────

  // Single-card selection fly ghost
  const flyCard   = ref(null)
  const flyingIds = ref(new Set())

  // Batch deal / discard ghosts
  const flyCards   = ref([])
  const dealingSet = ref(new Set())   // card IDs hidden while their deal ghost is in flight

  // Tracks the first card ID of the last dealt hand to avoid re-animating the same hand
  const dealtPhaseKey = ref(null)

  // CSS class toggled on discard pile during shuffle animation
  const discardShuffling = ref(false)

  // ── Helpers ──────────────────────────────────────────────────────────────────

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
        id: `discard-slot-${Date.now()}-${i}`,
        iconKey: getCardIconKey(selectedCards[i]),
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
        id: `discard-hand-${Date.now()}-${i}`,
        iconKey: getCardIconKey(handCards[i]),
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

  // ── Deal animation ────────────────────────────────────────────────────────────

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
        id: `deal-${Date.now()}-${startIndex + i}`,
        iconKey: getCardIconKey(cards[i]),
        cardId: cards[i].id,
        w, h,
        left: drawCx - w / 2,
        top: drawCy - h / 2,
        tx: 0, ty: 0,
        destLeft: cardRect.left,
        destTop: cardRect.top,
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

  // ── Single-card fly (card click → slot) ──────────────────────────────────────

  // Animate a single card flying from its hand position to a slot.
  // Caller should commit gameStore.selectCard(card.id) after awaiting.
  async function flyCardToSlot(card, cardEl, slotEl) {
    const from = cardEl.getBoundingClientRect()
    const to   = slotEl.getBoundingClientRect()

    flyCard.value = {
      iconKey: getCardIconKey(card),
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

    await new Promise(resolve => setTimeout(resolve, 380))
    flyingIds.value = new Set([...flyingIds.value].filter(id => id !== card.id))
    flyCard.value = null
  }

  return {
    // State (needed by template)
    flyCard,
    flyingIds,
    flyCards,
    dealingSet,
    dealtPhaseKey,
    discardShuffling,
    // Helpers
    isTaken,
    isFlying,
    // Animation functions
    runDiscardAnimation,
    runDealAnimation,
    flyCardToSlot,
  }
}
