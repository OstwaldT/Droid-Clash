<template>
  <span
    class="pixel-icon"
    :style="{ width: `${size}px`, height: `${size}px`, color: iconColor }"
    :aria-hidden="label ? undefined : 'true'"
    :aria-label="label || undefined"
    :role="label ? 'img' : undefined"
  >
    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">
      <!-- Shared glow filter — colored per icon via CSS -->
      <defs>
        <filter id="icon-glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur in="SourceGraphic" stdDeviation="1.8" result="blur" />
          <feComposite in="blur" in2="SourceGraphic" operator="over" />
        </filter>
      </defs>

      <!-- Glow layer: blurred silhouette behind the icon -->
      <g :filter="`url(#icon-glow)`" opacity="0.35">

      <!-- ─── MOVE: Bold upward arrow (one step forward) ─── -->
      <template v-if="iconName === 'move'">
        <path d="M12 2L5 10H9V21H15V10H19Z" fill="currentColor" />
      </template>

      <!-- ─── TURN-LEFT: L-bend arrow pointing left (rotate CCW) ─── -->
      <template v-else-if="iconName === 'turn-left'">
        <path d="M1 7L6 3V5H18V21H14V9H6V11Z" fill="currentColor" />
      </template>

      <!-- ─── TURN-RIGHT: L-bend arrow pointing right (rotate CW) ─── -->
      <template v-else-if="iconName === 'turn-right'">
        <path d="M23 7L18 3V5H6V21H10V9H18V11Z" fill="currentColor" />
      </template>

      <!-- ─── ATTACK: Starburst / impact explosion (melee hit) ─── -->
      <template v-else-if="iconName === 'attack'">
        <path d="M12 1L14 9L22 7L16 12L22 17L14 15L12 23L10 15L2 17L8 12L2 7L10 9Z" fill="currentColor" />
      </template>

      <!-- ─── SPRINT: Double chevron up (move 2 hexes forward) ─── -->
      <template v-else-if="iconName === 'sprint'">
        <path d="M12 2L4 10H9L12 6L15 10H20Z M12 13L4 21H9L12 17L15 21H20Z" fill="currentColor" />
      </template>

      <!-- ─── SHOOT: Crosshair / target reticle (ranged attack) ─── -->
      <template v-else-if="iconName === 'shoot'">
        <g fill="currentColor">
          <rect x="11" y="1" width="2" height="8" />
          <rect x="11" y="15" width="2" height="8" />
          <rect x="1" y="11" width="8" height="2" />
          <rect x="15" y="11" width="8" height="2" />
          <rect x="11" y="11" width="2" height="2" />
        </g>
      </template>

      <!-- ─── 180: U-turn arrow flipped ─── -->
      <template v-else-if="iconName === '180'">
        <path d="M7 22L3 17H5V4H19V17H15V8H9V17H11Z" fill="currentColor" />
      </template>

      <!-- ─── STRAFE-LEFT ─── -->
      <template v-else-if="iconName === 'strafe-left'">
        <path d="M2 12L9 5V8H22V16H9V19Z" fill="currentColor" />
      </template>

      <!-- ─── STRAFE-RIGHT ─── -->
      <template v-else-if="iconName === 'strafe-right'">
        <path d="M22 12L15 5V8H2V16H15V19Z" fill="currentColor" />
      </template>

      <!-- ─── SWEEP ─── -->
      <template v-else-if="iconName === 'sweep'">
        <path d="M4 20L2 8L12 2L22 8L20 20Z" fill="currentColor" />
      </template>

      <!-- ─── SLAM ─── -->
      <template v-else-if="iconName === 'slam'">
        <path d="M12 1L22 7V17L12 23L2 17V7Z" fill="currentColor" />
      </template>

      <!-- ─── SHOCKWAVE ─── -->
      <template v-else-if="iconName === 'shockwave'">
        <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2" />
        <circle cx="12" cy="12" r="6" fill="none" stroke="currentColor" stroke-width="2" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
      </template>

      <!-- ─── DISORIENT ─── -->
      <template v-else-if="iconName === 'disorient'">
        <!-- Two curved arrows forming a spin circle, stroke-based -->
        <path d="M12 4 A8 8 0 0 1 20 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <polygon points="20,8 20,14 16,11" fill="currentColor" />
        <path d="M12 20 A8 8 0 0 1 4 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <polygon points="4,16 4,10 8,13" fill="currentColor" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
      </template>


      <!-- ─── SNIPER ─── -->
      <template v-else-if="iconName === 'sniper'">
        <circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="2" />
        <line x1="12" y1="2" x2="12" y2="8" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <line x1="12" y1="16" x2="12" y2="22" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <line x1="2" y1="12" x2="8" y2="12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <line x1="16" y1="12" x2="22" y2="12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
      </template>

      <!-- ─── BRAWLER ─── -->
      <template v-else-if="iconName === 'brawler'">
        <path d="M7 3H17V7H19V10H17V15H15V20H9V15H7V10H5V7H7V3Z" fill="currentColor" />
      </template>

      <!-- ─── SNAKE ─── -->
      <template v-else-if="iconName === 'snake'">
        <path d="M6 4 C6 2 18 2 18 7 C18 12 6 12 6 17 C6 22 18 22 18 20" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" />
        <polyline points="14,17 18,20 14,23" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
      </template>

      <!-- ─── LOCK ─── -->
      <template v-else-if="iconName === 'lock'">
        <path d="M7 1H17V10H19V22H5V10H7Z M9 3H15V10H9Z" fill="currentColor" fill-rule="evenodd" />
      </template>

      <!-- ─── UNLOCK ─── -->
      <template v-else-if="iconName === 'unlock'">
        <path d="M7 1H17V7H15V3H9V10H19V22H5V10H7Z" fill="currentColor" />
      </template>

      <!-- ─── FALLBACK ─── -->
      <template v-else>
        <rect x="5" y="5" width="14" height="14" fill="currentColor" />
      </template>

      </g><!-- /glow -->

      <!-- Drop shadow layer — offset, darkened -->
      <!-- ─── MOVE ─── -->
      <template v-if="iconName === 'move'">
        <path d="M12 2L5 10H9V21H15V10H19Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M12 2L5 10H9V21H15V10H19Z" fill="currentColor" />
        <path d="M12 2L8 7H9V19H11V7Z" fill="#ffffff" opacity="0.30" />
      </template>

      <!-- ─── TURN-LEFT ─── -->
      <template v-else-if="iconName === 'turn-left'">
        <path d="M1 7L6 3V5H18V21H14V9H6V11Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M1 7L6 3V5H18V21H14V9H6V11Z" fill="currentColor" />
        <path d="M6 5H16V6.5H6ZM14 9H16V19H14Z" fill="#ffffff" opacity="0.30" />
      </template>

      <!-- ─── TURN-RIGHT ─── -->
      <template v-else-if="iconName === 'turn-right'">
        <path d="M23 7L18 3V5H6V21H10V9H18V11Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M23 7L18 3V5H6V21H10V9H18V11Z" fill="currentColor" />
        <path d="M8 5H18V6.5H8ZM8 9H10V19H8Z" fill="#ffffff" opacity="0.30" />
      </template>

      <!-- ─── ATTACK ─── -->
      <template v-else-if="iconName === 'attack'">
        <path d="M12 1L14 9L22 7L16 12L22 17L14 15L12 23L10 15L2 17L8 12L2 7L10 9Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M12 1L14 9L22 7L16 12L22 17L14 15L12 23L10 15L2 17L8 12L2 7L10 9Z" fill="currentColor" />
        <path d="M10 10H14V14H10Z" fill="#ffffff" opacity="0.40" />
        <path d="M12 1L10 9L8 12L10 9Z" fill="#ffffff" opacity="0.20" />
      </template>

      <!-- ─── SPRINT ─── -->
      <template v-else-if="iconName === 'sprint'">
        <path d="M12 2L4 10H9L12 6L15 10H20Z M12 13L4 21H9L12 17L15 21H20Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M12 2L4 10H9L12 6L15 10H20Z M12 13L4 21H9L12 17L15 21H20Z" fill="currentColor" />
        <path d="M12 2L8 7H9L12 4Z M12 13L8 18H9L12 15Z" fill="#ffffff" opacity="0.30" />
      </template>

      <!-- ─── SHOOT ─── -->
      <template v-else-if="iconName === 'shoot'">
        <g :fill="shadowColor" opacity="0.30" transform="translate(1,1)">
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
        <rect x="11" y="1" width="1" height="8" fill="#ffffff" opacity="0.30" />
        <rect x="1" y="11" width="8" height="1" fill="#ffffff" opacity="0.30" />
      </template>

      <!-- ─── 180 ─── -->
      <template v-else-if="iconName === '180'">
        <path d="M7 22L3 17H5V4H19V17H15V8H9V17H11Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M7 22L3 17H5V4H19V17H15V8H9V17H11Z" fill="currentColor" />
        <path d="M5 4H7V15H5Z" fill="#ffffff" opacity="0.22" />
        <path d="M5 4H17V6H5Z" fill="#ffffff" opacity="0.30" />
      </template>

      <!-- ─── STRAFE-LEFT ─── -->
      <template v-else-if="iconName === 'strafe-left'">
        <path d="M2 12L9 5V8H22V16H9V19Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M2 12L9 5V8H22V16H9V19Z" fill="currentColor" />
        <path d="M2 12L9 5V8H20V10H9V12Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── STRAFE-RIGHT ─── -->
      <template v-else-if="iconName === 'strafe-right'">
        <path d="M22 12L15 5V8H2V16H15V19Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M22 12L15 5V8H2V16H15V19Z" fill="currentColor" />
        <path d="M2 8H15V10H2Z" fill="#ffffff" opacity="0.28" />
      </template>

      <!-- ─── SWEEP ─── -->
      <template v-else-if="iconName === 'sweep'">
        <path d="M4 20L2 8L12 2L22 8L20 20Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M4 20L2 8L12 2L22 8L20 20Z" fill="currentColor" />
        <path d="M2 8L12 2L14 3L4 9Z" fill="#ffffff" opacity="0.30" />
        <rect x="8" y="10" width="8" height="2" fill="#ffffff" opacity="0.18" />
        <rect x="10" y="14" width="4" height="2" fill="#ffffff" opacity="0.12" />
      </template>

      <!-- ─── SLAM ─── -->
      <template v-else-if="iconName === 'slam'">
        <path d="M12 1L22 7V17L12 23L2 17V7Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M12 1L22 7V17L12 23L2 17V7Z" fill="currentColor" />
        <path d="M12 1L2 7V9L12 3L22 9V7Z" fill="#ffffff" opacity="0.32" />
        <circle cx="12" cy="12" r="3" fill="#ffffff" opacity="0.22" />
      </template>

      <!-- ─── SHOCKWAVE ─── -->
      <template v-else-if="iconName === 'shockwave'">
        <g :stroke="shadowColor" opacity="0.30" transform="translate(1,1)">
          <circle cx="12" cy="12" r="10" fill="none" stroke-width="2" />
          <circle cx="12" cy="12" r="6" fill="none" stroke-width="2" />
          <circle cx="12" cy="12" r="2" :fill="shadowColor" stroke="none" />
        </g>
        <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="2" />
        <circle cx="12" cy="12" r="6" fill="none" stroke="currentColor" stroke-width="2" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
        <path d="M12 2A10 10 0 0 0 2 12" fill="none" stroke="#ffffff" stroke-width="1" opacity="0.30" />
      </template>

      <!-- ─── DISORIENT ─── -->
      <template v-else-if="iconName === 'disorient'">
        <g :stroke="shadowColor" opacity="0.30" transform="translate(1,1)">
          <path d="M12 4 A8 8 0 0 1 20 12" fill="none" stroke-width="2" stroke-linecap="round" />
          <polygon points="20,8 20,14 16,11" :fill="shadowColor" stroke="none" />
          <path d="M12 20 A8 8 0 0 1 4 12" fill="none" stroke-width="2" stroke-linecap="round" />
          <polygon points="4,16 4,10 8,13" :fill="shadowColor" stroke="none" />
          <circle cx="12" cy="12" r="2" :fill="shadowColor" stroke="none" />
        </g>
        <path d="M12 4 A8 8 0 0 1 20 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <polygon points="20,8 20,14 16,11" fill="currentColor" />
        <path d="M12 20 A8 8 0 0 1 4 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <polygon points="4,16 4,10 8,13" fill="currentColor" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
        <path d="M12 4 A8 8 0 0 1 20 10" fill="none" stroke="#ffffff" stroke-width="1" opacity="0.25" />
      </template>


      <!-- ─── SNIPER ─── -->
      <template v-else-if="iconName === 'sniper'">
        <g :stroke="shadowColor" opacity="0.30" transform="translate(1,1)">
          <circle cx="12" cy="12" r="8" fill="none" stroke-width="2" />
          <line x1="12" y1="2" x2="12" y2="8" stroke-width="2" />
          <line x1="12" y1="16" x2="12" y2="22" stroke-width="2" />
          <line x1="2" y1="12" x2="8" y2="12" stroke-width="2" />
          <line x1="16" y1="12" x2="22" y2="12" stroke-width="2" />
          <circle cx="12" cy="12" r="2" :fill="shadowColor" stroke="none" />
        </g>
        <circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="2" />
        <line x1="12" y1="2" x2="12" y2="8" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <line x1="12" y1="16" x2="12" y2="22" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <line x1="2" y1="12" x2="8" y2="12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <line x1="16" y1="12" x2="22" y2="12" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
        <circle cx="12" cy="12" r="2" fill="currentColor" />
        <path d="M6 8 A8 8 0 0 1 12 4" fill="none" stroke="#ffffff" stroke-width="1" opacity="0.30" stroke-linecap="round" />
      </template>

      <!-- ─── BRAWLER ─── -->
      <template v-else-if="iconName === 'brawler'">
        <path d="M7 3H17V7H19V10H17V15H15V20H9V15H7V10H5V7H7V3Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M7 3H17V7H19V10H17V15H15V20H9V15H7V10H5V7H7V3Z" fill="currentColor" />
        <path d="M7 3H15V5H7Z" fill="#ffffff" opacity="0.32" />
        <path d="M5 7H7V9H5Z" fill="#ffffff" opacity="0.22" />
        <rect x="10" y="5" width="1" height="9" fill="currentColor" opacity="0.18" />
        <rect x="13" y="5" width="1" height="9" fill="currentColor" opacity="0.18" />
      </template>

      <!-- ─── SNAKE ─── -->
      <template v-else-if="iconName === 'snake'">
        <g :stroke="shadowColor" opacity="0.30" transform="translate(1,1)">
          <path d="M6 4 C6 2 18 2 18 7 C18 12 6 12 6 17 C6 22 18 22 18 20" fill="none" stroke-width="2.5" stroke-linecap="round" />
          <polyline points="14,17 18,20 14,23" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
        </g>
        <path d="M6 4 C6 2 18 2 18 7 C18 12 6 12 6 17 C6 22 18 22 18 20" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" />
        <polyline points="14,17 18,20 14,23" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
        <path d="M6 4 C6 2 14 2 18 6" fill="none" stroke="#ffffff" stroke-width="1" opacity="0.28" stroke-linecap="round" />
      </template>

      <!-- ─── LOCK ─── -->
      <template v-else-if="iconName === 'lock'">
        <path d="M7 1H17V10H19V22H5V10H7Z M9 3H15V10H9Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" fill-rule="evenodd" />
        <path d="M7 1H17V10H19V22H5V10H7Z M9 3H15V10H9Z" fill="currentColor" fill-rule="evenodd" />
        <path d="M7 1H15V2H7ZM5 10H19V11H5Z" fill="#ffffff" opacity="0.32" />
        <rect x="11" y="14" width="2" height="4" fill="#ffffff" opacity="0.42" />
      </template>

      <!-- ─── UNLOCK ─── -->
      <template v-else-if="iconName === 'unlock'">
        <path d="M7 1H17V7H15V3H9V10H19V22H5V10H7Z" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <path d="M7 1H17V7H15V3H9V10H19V22H5V10H7Z" fill="currentColor" />
        <path d="M7 1H15V2H7ZM5 10H19V11H5Z" fill="#ffffff" opacity="0.32" />
        <rect x="11" y="14" width="2" height="4" fill="#ffffff" opacity="0.42" />
      </template>

      <!-- ─── FALLBACK ─── -->
      <template v-else>
        <rect x="5" y="5" width="14" height="14" :fill="shadowColor" opacity="0.30" transform="translate(1,1)" />
        <rect x="5" y="5" width="14" height="14" fill="currentColor" />
        <rect x="5" y="5" width="7" height="1.5" fill="#ffffff" opacity="0.30" />
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
  color: {
    type: String,
    default: '',
  },
})

const CATEGORY_COLORS = {
  // Movement — cyan
  'move':          '#50c8f0',
  'sprint':        '#50c8f0',
  'strafe-left':   '#50c8f0',
  'strafe-right':  '#50c8f0',
  // Rotation — gold
  'turn-left':     '#f0c050',
  'turn-right':    '#f0c050',
  '180':           '#f0c050',
  // Melee — red-orange
  'attack':        '#e86040',
  'sweep':         '#e86040',
  'slam':          '#e86040',
  // Ranged / utility — violet / purple
  'shoot':         '#a070e0',
  'shockwave':     '#a070e0',
  'disorient':     '#c040ff',
  // Archetypes
  'brawler':       '#e86040',
  'sniper':        '#40c8e0',
  'snake':         '#70e060',
  // UI elements — muted
  'lock':          '#7b7b93',
  'unlock':        '#7b7b93',
}

const iconName = computed(() => props.name.toLowerCase())

const iconColor = computed(() => {
  if (props.color) return props.color
  return CATEGORY_COLORS[iconName.value] || '#f0c050'
})

// Darkened version of the icon color for drop shadows
const shadowColor = computed(() => {
  const hex = iconColor.value.replace('#', '')
  const r = Math.round(parseInt(hex.substring(0, 2), 16) * 0.3)
  const g = Math.round(parseInt(hex.substring(2, 4), 16) * 0.3)
  const b = Math.round(parseInt(hex.substring(4, 6), 16) * 0.3)
  return `rgb(${r}, ${g}, ${b})`
})
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
