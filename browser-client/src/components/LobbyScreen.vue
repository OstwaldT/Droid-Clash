<template>
  <div class="lobby-screen ui-screen flex flex-col items-center justify-center p-4 h-screen">
    <div class="ui-panel p-8 w-full max-w-md relative overflow-hidden">
      <h1 class="text-center mb-8 text-[#f0c050] text-xl">DROID CLASH</h1>

      <!-- Countdown overlay -->
      <Transition name="countdown">
        <div
          v-if="gameStore.countdown !== null"
          class="absolute inset-0 bg-[#1a1a2ef2] border-[2px] border-[#3a3a5c] flex flex-col items-center justify-center z-10"
        >
          <div :key="gameStore.countdown" class="text-9xl text-[#f0c050] countdown-number">
            {{ gameStore.countdown }}
          </div>
          <p class="ui-copy mt-4 text-xs">Get ready</p>
        </div>
      </Transition>

      <div v-if="!playerStore.isConnected" class="space-y-6">
        <div>
          <label for="playerName" class="block text-[0.6rem] text-[#c8c8d8] mb-2 uppercase">
            Player Name
          </label>
          <input
            id="playerName"
            v-model="playerName"
            type="text"
            placeholder="e.g. Iron Bot"
            maxlength="20"
            class="ui-input w-full px-4 py-3 text-[0.68rem]"
            @keyup.enter="joinGame"
          />
        </div>

        <button
          @click="joinGame"
          :disabled="!playerName.trim() || isConnecting"
          class="ui-button ui-button--accent w-full py-3 text-[0.68rem]"
        >
          {{ isConnecting ? 'Connecting...' : 'Join Game' }}
        </button>

        <div v-if="connectionError" class="ui-section ui-section--danger p-4 text-[#ff9ab0] text-[0.6rem] leading-[1.8]">
          {{ connectionError }}
        </div>
      </div>

      <div v-else class="space-y-6">
        <div class="ui-section p-4">
          <h2 class="text-[0.65rem] text-[#f0c050] mb-3 uppercase">Players</h2>
          <div class="space-y-2">
            <div
              v-for="player in gameStore.players"
              :key="player.playerId"
              class="flex items-center gap-3 p-3 border-2"
              :class="[
                player.isReady ? 'border-[#40c860] bg-[#102116]' : 'border-[#3a3a5c] bg-[#1a1a2e]',
                player.playerId === playerStore.playerId ? 'outline outline-1 outline-[#f0c050] outline-offset-[-2px]' : ''
              ]"
            >
              <span
                class="ui-status-square"
                :style="{ backgroundColor: player.color || '#9b59b6' }"
              ></span>
              <span class="text-[0.6rem] flex-1 leading-[1.6]">{{ player.name }}</span>
              <span 
                class="text-[0.55rem]"
                :class="player.isReady ? 'text-[#40c860]' : 'text-[#8d8da6]'"
              >
                {{ player.isReady ? 'Ready' : 'Waiting' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Deck archetype selector -->
        <div class="ui-section p-4">
          <div class="flex items-center gap-3">
            <button
              @click="prevArchetype"
              class="ui-button w-9 h-9 flex items-center justify-center text-sm flex-shrink-0"
            >&lt;</button>
            <div class="flex-1 text-center">
              <div class="text-[#f0c050] mb-3 flex justify-center">
                <PixelIcon :name="getArchetypeIconKey(currentArchetype.key)" :size="52" />
              </div>
              <div class="text-[0.65rem] text-[#f0c050] leading-[1.6]">{{ currentArchetype.label }}</div>
              <div class="text-[0.52rem] text-[#b7b7ca] mt-2 leading-[1.8]">{{ currentArchetype.desc }}</div>
            </div>
            <button
              @click="nextArchetype"
              class="ui-button w-9 h-9 flex items-center justify-center text-sm flex-shrink-0"
            >&gt;</button>
          </div>
          <div class="flex justify-center gap-1.5 mt-3">
            <span
              v-for="(a, i) in ARCHETYPES" :key="a.key"
              class="w-2 h-2 transition-colors"
              :class="i === archetypeIndex ? 'bg-[#f0c050]' : 'bg-[#3a3a5c]'"
            />
          </div>
        </div>

        <button
          @click="readyUp"
          class="ui-button ui-button--success w-full py-3 text-[0.68rem]"
        >
          Ready
        </button>

        <button
          @click="leaveGame"
          class="ui-button ui-button--muted w-full py-3 text-[0.62rem]"
        >
          Leave Game
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { usePlayerStore } from '@/stores/playerStore'
import { useGameStore } from '@/stores/gameStore'
import PixelIcon from '@/components/PixelIcon.vue'
import websocket from '@/api/websocket'
import { getArchetypeIconKey } from '@/utils/iconKeys'

const playerStore = usePlayerStore()
const gameStore = useGameStore()

const FIRST_WORDS = [
  'Iron', 'Rusty', 'Chrome', 'Steel', 'Nano', 'Cyber', 'Plasma', 'Turbo',
  'Volt', 'Sonic', 'Atomic', 'Cobalt', 'Neon', 'Laser', 'Flux', 'Binary',
  'Rogue', 'Shadow', 'Titan', 'Hyper', 'Omega', 'Delta', 'Sigma', 'Blazing',
  'Hex', 'Pixel', 'Circuit', 'Quantum', 'Photon', 'Static',
  'Glitch', 'Nitro', 'Helium', 'Molten', 'Frozen', 'Crimson', 'Obsidian',
  'Hollow', 'Wired', 'Overclocked', 'Inferno', 'Venom', 'Cryo', 'Ember',
  'Stray', 'Relic', 'Primal', 'Apex', 'Radiant', 'Phantom', 'Grim',
  'Thunder', 'Void', 'Cursed', 'Warped', 'Ancient', 'Berserk', 'Zero',
  'Blaze', 'Nexus', 'Surge', 'Lunar', 'Solar', 'Astral', 'Dark',
]
const LAST_WORDS = [
  'Unit', 'Bot', 'Core', 'Rex', 'Prime', 'Droid', 'Mech', 'Rig',
  'Claw', 'Spike', 'Storm', 'Pulse', 'Fist', 'Gear', 'Blade', 'Crusher',
  'Zapper', 'Sentinel', 'Wrecker', 'Hammer', 'Spark', 'Bolt', 'Drone',
  'Shell', 'Vortex', 'Forge', 'Crawler', 'Frame', 'Plating', 'Cannon',
  'Ruin', 'Specter', 'Marauder', 'Bastion', 'Rampage', 'Fury', 'Titan',
  'Reaper', 'Golem', 'Colossus', 'Stalker', 'Vector', 'Protocol', 'Array',
  'Warden', 'Ravager', 'Juggernaut', 'Interceptor', 'Destroyer', 'Overlord',
  'Talon', 'Harbinger', 'Tempest', 'Cyclone', 'Phantom', 'Ghoul', 'Shard',
  'Node', 'Relay', 'Carrier', 'Chassis', 'Module', 'Probe', 'Scrap',
]

function randomRobotName() {
  const first = FIRST_WORDS[Math.floor(Math.random() * FIRST_WORDS.length)]
  const last  = LAST_WORDS[Math.floor(Math.random() * LAST_WORDS.length)]
  return `${first} ${last}`
}

const ARCHETYPES = [
  { key: 'brawler', label: 'Brawler', desc: 'Dominate up close with devastating melee combos' },
  { key: 'sniper',  label: 'Sniper',  desc: 'Eliminate targets from distance before they can close in' },
  { key: 'snake',   label: 'Snake',   desc: 'Strike from unexpected angles and vanish before the counter' },
]

const archetypeIndex = ref(0)
const currentArchetype = computed(() => ARCHETYPES[archetypeIndex.value])
const prevArchetype = () => { archetypeIndex.value = (archetypeIndex.value - 1 + ARCHETYPES.length) % ARCHETYPES.length }
const nextArchetype = () => { archetypeIndex.value = (archetypeIndex.value + 1) % ARCHETYPES.length }

const playerName = ref(randomRobotName())
const isConnecting = ref(false)
const connectionError = ref('')

const joinGame = async () => {
  if (!playerName.value.trim()) return

  isConnecting.value = true
  connectionError.value = ''

  try {
    playerStore.setPlayer(null, playerName.value)
    await websocket.connect()
    websocket.send({
      type: 'join',
      data: { playerName: playerName.value },
    })
  } catch (error) {
    connectionError.value = 'Failed to connect. Please try again.'
    console.error(error)
  } finally {
    isConnecting.value = false
  }
}

const leaveGame = () => {
  websocket.send({
    type: 'leave',
    data: { playerId: playerStore.playerId },
  })
  playerStore.reset()
  gameStore.$reset()
}

const readyUp = () => {
  websocket.send({
    type: 'ready',
    data: { playerId: playerStore.playerId, archetype: currentArchetype.value.key },
  })
}
</script>

<style scoped>
/* Countdown number: pops in with a scale bounce each tick */
.countdown-number {
  animation: countdown-pop 0.35s cubic-bezier(0.34, 1.8, 0.64, 1);
}
@keyframes countdown-pop {
  from { transform: scale(0.3); opacity: 0; }
  to   { transform: scale(1);   opacity: 1; }
}

.countdown-enter-active { transition: opacity 0.2s; }
.countdown-leave-active { transition: opacity 0.15s; }
.countdown-enter-from, .countdown-leave-to { opacity: 0; }
</style>
