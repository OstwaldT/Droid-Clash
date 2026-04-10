<template>
  <span
    class="pixel-icon"
    :style="{ width: `${size}px`, height: `${size}px` }"
    :aria-hidden="label ? undefined : 'true'"
    :aria-label="label || undefined"
    :role="label ? 'img' : undefined"
  >
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
      <!-- ─── MOVE: Bold upward arrow (one step forward) ─── -->
      <template v-if="iconName === 'move'">
        <path d="M12 2L5 10H9V21H15V10H19Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M12 2L5 10H9V21H15V10H19Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M12 2L5 10H9V21H15V10H19Z" fill="currentColor" />
        <path d="M12 2L8 7H9V19H11V7Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── TURN-LEFT: L-bend arrow pointing left (rotate CCW) ─── -->
      <template v-else-if="iconName === 'turn-left'">
        <path d="M1 7L6 3V5H18V21H14V9H6V11Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M1 7L6 3V5H18V21H14V9H6V11Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M1 7L6 3V5H18V21H14V9H6V11Z" fill="currentColor" />
        <path d="M6 5H16V6H6V5ZM14 9H16V19H14V9Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── TURN-RIGHT: L-bend arrow pointing right (rotate CW) ─── -->
      <template v-else-if="iconName === 'turn-right'">
        <path d="M23 7L18 3V5H6V21H10V9H18V11Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M23 7L18 3V5H6V21H10V9H18V11Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M23 7L18 3V5H6V21H10V9H18V11Z" fill="currentColor" />
        <path d="M8 5H18V6H8V5ZM8 9H10V19H8V9Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── ATTACK: Starburst / impact explosion (melee hit) ─── -->
      <template v-else-if="iconName === 'attack'">
        <path d="M12 1L14 9L22 7L16 12L22 17L14 15L12 23L10 15L2 17L8 12L2 7L10 9Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M12 1L14 9L22 7L16 12L22 17L14 15L12 23L10 15L2 17L8 12L2 7L10 9Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M12 1L14 9L22 7L16 12L22 17L14 15L12 23L10 15L2 17L8 12L2 7L10 9Z" fill="currentColor" />
        <path d="M10 10H14V14H10Z" fill="#ffffff" opacity="0.38" />
      </template>

      <!-- ─── SPRINT: Double chevron up (move 2 hexes forward) ─── -->
      <template v-else-if="iconName === 'sprint'">
        <path d="M12 2L4 10H9L12 6L15 10H20Z M12 13L4 21H9L12 17L15 21H20Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M12 2L4 10H9L12 6L15 10H20Z M12 13L4 21H9L12 17L15 21H20Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M12 2L4 10H9L12 6L15 10H20Z M12 13L4 21H9L12 17L15 21H20Z" fill="currentColor" />
        <path d="M12 2L8 7H9L12 4Z M12 13L8 18H9L12 15Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── SHOOT: Crosshair / target reticle (ranged attack) ─── -->
      <template v-else-if="iconName === 'shoot'">
        <g fill="currentColor" opacity="0.10" transform="translate(2,2)">
          <rect x="11" y="1" width="2" height="8" />
          <rect x="11" y="15" width="2" height="8" />
          <rect x="1" y="11" width="8" height="2" />
          <rect x="15" y="11" width="8" height="2" />
          <rect x="11" y="11" width="2" height="2" />
        </g>
        <g fill="currentColor" opacity="0.22" transform="translate(1,1)">
          <rect x="11" y="1" width="2" height="8" />
          <rect x="11" y="15" width="2" height="8" />
          <rect x="1" y="11" width="8" height="2" />
          <rect x="15" y="11" width="8" height="2" />
          <rect x="11" y="11" width="2" height="2" />
        </g>
        <g fill="currentColor">
          <rect x="11" y="1" width="2" height="8" />
          <rect x="11" y="15" width="2" height="8" />
          <rect x="1" y="11" width="8" height="2" />
          <rect x="15" y="11" width="8" height="2" />
          <rect x="11" y="11" width="2" height="2" />
        </g>
        <rect x="11" y="1" width="1" height="8" fill="#ffffff" opacity="0.28" />
        <rect x="1" y="11" width="8" height="1" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── 180: U-turn arrow flipped (spin 180°, arrowhead pointing down) ─── -->
      <template v-else-if="iconName === '180'">
        <path d="M7 22L3 17H5V4H19V17H15V8H9V17H11Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M7 22L3 17H5V4H19V17H15V8H9V17H11Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M7 22L3 17H5V4H19V17H15V8H9V17H11Z" fill="currentColor" />
        <path d="M5 4H7V15H5V4Z" fill="#ffffff" opacity="0.22" />
        <path d="M5 4H17V6H5V4Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── STRAFE-LEFT: Sideways arrow pointing left (sidestep) ─── -->
      <template v-else-if="iconName === 'strafe-left'">
        <path d="M2 12L9 5V8H22V16H9V19Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M2 12L9 5V8H22V16H9V19Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M2 12L9 5V8H22V16H9V19Z" fill="currentColor" />
        <path d="M2 12L9 5V8H20V10H9V12Z" fill="#ffffff" opacity="0.25" />
        <rect x="12" y="10" width="8" height="1" fill="currentColor" opacity="0.15" />
      </template>

      <!-- ─── STRAFE-RIGHT: Sideways arrow pointing right (sidestep) ─── -->
      <template v-else-if="iconName === 'strafe-right'">
        <path d="M22 12L15 5V8H2V16H15V19Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M22 12L15 5V8H2V16H15V19Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M22 12L15 5V8H2V16H15V19Z" fill="currentColor" />
        <path d="M2 8H15V10H2V8Z" fill="#ffffff" opacity="0.25" />
        <rect x="4" y="10" width="8" height="1" fill="currentColor" opacity="0.15" />
      </template>

      <!-- ─── SWEEP: Forward arc / fan slash (3 hexes in front) ─── -->
      <template v-else-if="iconName === 'sweep'">
        <path d="M4 20L2 8L12 2L22 8L20 20Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M4 20L2 8L12 2L22 8L20 20Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M4 20L2 8L12 2L22 8L20 20Z" fill="currentColor" />
        <path d="M2 8L12 2L14 3L4 9Z" fill="#ffffff" opacity="0.28" />
        <rect x="8" y="10" width="8" height="2" fill="#ffffff" opacity="0.18" />
        <rect x="10" y="14" width="4" height="2" fill="#ffffff" opacity="0.12" />
      </template>

      <!-- ─── SLAM: Hexagon burst (all 6 adjacent hexes) ─── -->
      <template v-else-if="iconName === 'slam'">
        <path d="M12 1L22 7V17L12 23L2 17V7Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M12 1L22 7V17L12 23L2 17V7Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M12 1L22 7V17L12 23L2 17V7Z" fill="currentColor" />
        <path d="M12 1L2 7V9L12 3L22 9V7Z" fill="#ffffff" opacity="0.30" />
        <circle cx="12" cy="12" r="3" fill="#ffffff" opacity="0.20" />
      </template>

      <!-- ─── SHOCKWAVE: Concentric rings / push outward ─── -->
      <template v-else-if="iconName === 'shockwave'">
        <g opacity="0.10" transform="translate(2,2)">
          <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2" />
          <circle cx="12" cy="12" r="6" fill="none" stroke="currentColor" stroke-width="2" />
          <circle cx="12" cy="12" r="2" fill="currentColor" />
        </g>
        <g opacity="0.22" transform="translate(1,1)">
          <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2" />
          <circle cx="12" cy="12" r="6" fill="none" stroke="currentColor" stroke-width="2" />
          <circle cx="12" cy="12" r="2" fill="currentColor" />
        </g>
        <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2" />
        <circle cx="12" cy="12" r="6" fill="none" stroke="currentColor" stroke-width="2" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
        <path d="M12 2A10 10 0 0 0 2 12" fill="none" stroke="#ffffff" stroke-width="1" opacity="0.28" />
      </template>

      <!-- ─── STANDARD: Shield (balanced deck) ─── -->
      <template v-else-if="iconName === 'standard'">
        <path d="M12 2L4 7V16L12 23L20 16V7Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M12 2L4 7V16L12 23L20 16V7Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M12 2L4 7V16L12 23L20 16V7Z" fill="currentColor" />
        <path d="M12 2L6 6V14L12 21V2Z" fill="#ffffff" opacity="0.2" />
      </template>

      <!-- ─── BRAWLER: Raised fist (close-combat deck) ─── -->
      <template v-else-if="iconName === 'brawler'">
        <path d="M7 3H17V7H19V10H17V15H15V20H9V15H7V10H5V7H7V3Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M7 3H17V7H19V10H17V15H15V20H9V15H7V10H5V7H7V3Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M7 3H17V7H19V10H17V15H15V20H9V15H7V10H5V7H7V3Z" fill="currentColor" />
        <path d="M7 3H15V5H7V3Z" fill="#ffffff" opacity="0.30" />
        <path d="M5 7H7V9H5V7Z" fill="#ffffff" opacity="0.22" />
        <rect x="10" y="5" width="1" height="9" fill="currentColor" opacity="0.18" />
        <rect x="13" y="5" width="1" height="9" fill="currentColor" opacity="0.18" />
      </template>

      <!-- ─── SPEEDSTER: Lightning bolt (speed deck) ─── -->
      <template v-else-if="iconName === 'speedster'">
        <path d="M6 1H16L11 10H20L10 23L13 12H5Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M6 1H16L11 10H20L10 23L13 12H5Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M6 1H16L11 10H20L10 23L13 12H5Z" fill="currentColor" />
        <path d="M6 1H12L9 7H5Z" fill="#ffffff" opacity="0.25" />
      </template>

      <!-- ─── LOCK: Closed padlock with shackle (slot locked) ─── -->
      <template v-else-if="iconName === 'lock'">
        <path d="M7 1H17V10H19V22H5V10H7Z M9 3H15V10H9Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" fill-rule="evenodd" />
        <path d="M7 1H17V10H19V22H5V10H7Z M9 3H15V10H9Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" fill-rule="evenodd" />
        <path d="M7 1H17V10H19V22H5V10H7Z M9 3H15V10H9Z" fill="currentColor" fill-rule="evenodd" />
        <path d="M7 1H15V2H7V1ZM5 10H19V11H5V10Z" fill="#ffffff" opacity="0.30" />
        <rect x="11" y="14" width="2" height="4" fill="#ffffff" opacity="0.42" />
      </template>

      <!-- ─── UNLOCK: Open padlock, shackle raised (slot unlocked) ─── -->
      <template v-else-if="iconName === 'unlock'">
        <path d="M7 1H17V7H15V3H9V10H19V22H5V10H7Z" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <path d="M7 1H17V7H15V3H9V10H19V22H5V10H7Z" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <path d="M7 1H17V7H15V3H9V10H19V22H5V10H7Z" fill="currentColor" />
        <path d="M7 1H15V2H7V1ZM5 10H19V11H5V10Z" fill="#ffffff" opacity="0.30" />
        <rect x="11" y="14" width="2" height="4" fill="#ffffff" opacity="0.42" />
      </template>

      <!-- ─── FALLBACK: generic square ─── -->
      <template v-else>
        <rect x="5" y="5" width="12" height="12" fill="currentColor" opacity="0.10" transform="translate(2,2)" />
        <rect x="5" y="5" width="12" height="12" fill="currentColor" opacity="0.22" transform="translate(1,1)" />
        <rect x="5" y="5" width="12" height="12" fill="currentColor" />
        <rect x="5" y="5" width="6" height="1" fill="#ffffff" opacity="0.28" />
      </template>
    </svg>
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  name: {
    type: String,
    default: 'move',
  },
  size: {
    type: Number,
    default: 24,
  },
  label: {
    type: String,
    default: '',
  },
})

const iconName = computed(() => props.name.toLowerCase())
</script>

<style scoped>
.pixel-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: currentColor;
}

.pixel-icon svg {
  width: 100%;
  height: 100%;
  display: block;
}
</style>
