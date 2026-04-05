<template>
  <div class="lobby-screen flex flex-col items-center justify-center min-h-screen p-4">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md relative overflow-hidden">
      <h1 class="text-4xl font-bold text-center mb-8 text-purple-600">🤖 Droid-Clash</h1>

      <!-- Countdown overlay -->
      <Transition name="countdown">
        <div
          v-if="gameStore.countdown !== null"
          class="absolute inset-0 bg-white/90 flex flex-col items-center justify-center z-10 rounded-lg"
        >
          <div :key="gameStore.countdown" class="text-9xl font-black text-purple-600 countdown-number">
            {{ gameStore.countdown }}
          </div>
          <p class="text-gray-500 font-semibold mt-4 text-lg">Get ready!</p>
        </div>
      </Transition>

      <div v-if="!playerStore.isConnected" class="space-y-6">
        <div>
          <label for="playerName" class="block text-sm font-medium text-gray-700 mb-2">
            Player Name
          </label>
          <input
            id="playerName"
            v-model="playerName"
            type="text"
            placeholder="e.g. Iron Bot"
            maxlength="20"
            class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent outline-none"
            @keyup.enter="joinGame"
          />
        </div>

        <button
          @click="joinGame"
          :disabled="!playerName.trim() || isConnecting"
          class="w-full py-3 bg-purple-600 text-white font-semibold rounded-lg hover:bg-purple-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
        >
          {{ isConnecting ? 'Connecting...' : 'Join Game' }}
        </button>

        <div v-if="connectionError" class="p-4 bg-red-100 text-red-700 rounded-lg text-sm">
          {{ connectionError }}
        </div>
      </div>

      <div v-else class="space-y-6">
        <div class="text-center">
          <p class="text-green-600 font-semibold mb-2">✓ Connected</p>
          <p class="text-lg">Welcome, <span class="font-bold">{{ playerStore.playerName }}</span>!</p>
        </div>

        <div class="bg-gray-50 rounded-lg p-4">
          <h2 class="font-semibold text-gray-800 mb-3">Players</h2>
          <div class="space-y-2">
            <div
              v-for="player in gameStore.players"
              :key="player.playerId"
              class="flex items-center gap-3 p-3 bg-white rounded border-2"
              :class="player.isReady ? 'border-green-500 bg-green-50' : 'border-gray-200'"
            >
              <span
                class="inline-block w-3 h-3 rounded-full flex-shrink-0"
                :style="{ backgroundColor: player.color || '#9b59b6' }"
              ></span>
              <span class="font-medium flex-1">{{ player.name }}</span>
              <span 
                class="text-sm font-semibold"
                :class="player.isReady ? 'text-green-600' : 'text-gray-400'"
              >
                {{ player.isReady ? '✓ Ready' : '- Waiting' }}
              </span>
            </div>
          </div>
        </div>

        <button
          @click="readyUp"
          class="w-full py-3 bg-green-600 text-white font-semibold rounded-lg hover:bg-green-700 transition"
        >
          Ready
        </button>

        <button
          @click="leaveGame"
          class="w-full py-2 bg-gray-300 text-gray-800 font-semibold rounded-lg hover:bg-gray-400 transition"
        >
          Leave Game
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { usePlayerStore } from '@/stores/playerStore'
import { useGameStore } from '@/stores/gameStore'
import websocket from '@/api/websocket'

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
    data: { playerId: playerStore.playerId },
  })
}
</script>

<style scoped>
.lobby-screen {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

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
