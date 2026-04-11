<template>
  <div class="hex-board ui-screen flex flex-col items-center justify-center p-4 h-screen overflow-y-auto">
    <div class="ui-panel p-8 w-full max-w-4xl">
      <h1 class="text-xl text-center mb-3 text-[#f0c050]">Battle Grid</h1>
      <p class="text-center ui-copy mb-6 text-[0.65rem]">Turn {{ gameStore.turnNumber }}</p>

      <svg
        :width="canvasWidth"
        :height="canvasHeight"
        class="border-2 border-[#3a3a5c] mx-auto mb-6 bg-[#10101b]"
      >
        <!-- Grid hexagons -->
        <g v-for="(hex, index) in hexagons" :key="`hex-${index}`">
          <polygon
            :points="hexPoints(hex.q, hex.r)"
            fill="none"
            stroke="#ddd"
            stroke-width="1"
          />
        </g>

        <!-- Robots -->
        <g v-for="robot in gameStore.robots" :key="`robot-${robot.playerId}`">
          <circle
            :cx="getPixelPosition(robot.position.q, robot.position.r).x"
            :cy="getPixelPosition(robot.position.q, robot.position.r).y"
            r="15"
            :fill="getRobotColor(robot.playerId)"
            stroke="black"
            stroke-width="2"
          />
          <text
            :x="getPixelPosition(robot.position.q, robot.position.r).x"
            :y="getPixelPosition(robot.position.q, robot.position.r).y"
            text-anchor="middle"
            dominant-baseline="middle"
            class="text-xs font-bold text-white select-none"
          >
            {{ robot.playerId }}
          </text>
        </g>
      </svg>

      <!-- Player status -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="robot in gameStore.robots"
          :key="`status-${robot.playerId}`"
          :class="[
            'p-4 border-2',
            robot.status === 'alive'
              ? 'border-[#40c860] bg-[#102116]'
              : 'border-[#a84b63] bg-[#24131a]'
          ]"
        >
          <div class="text-[0.6rem] text-[#f8f8ff] leading-[1.7]">{{ robot.name || `Player ${robot.playerId}` }}</div>
          <div class="text-[0.56rem] text-[#b7b7ca] leading-[1.7]">Health: {{ robot.health }} / {{ robot.maxHealth || 100 }}</div>
          <div class="text-[0.56rem] text-[#b7b7ca] leading-[1.7]">Status: {{ robot.status }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useGameStore } from '@/stores/gameStore'

const gameStore = useGameStore()

const hexSize = 30
const canvasWidth = 600
const canvasHeight = 500

const hexagons = computed(() => {
  const hexes = []
  for (let q = 0; q < gameStore.boardWidth; q++) {
    for (let r = 0; r < gameStore.boardHeight; r++) {
      hexes.push({ q, r })
    }
  }
  return hexes
})

const getRobotColor = (playerId) => {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E2']
  return colors[playerId % colors.length]
}

const getPixelPosition = (q, r) => {
  const x = hexSize * (3/2 * q) + 50
  const y = hexSize * (Math.sqrt(3)/2 * q + Math.sqrt(3) * r) + 50
  return { x, y }
}

const hexPoints = (q, r) => {
  const { x, y } = getPixelPosition(q, r)
  const points = []
  for (let i = 0; i < 6; i++) {
    const angle = (Math.PI / 3) * i
    const px = x + hexSize * Math.cos(angle)
    const py = y + hexSize * Math.sin(angle)
    points.push([px, py])
  }
  return points.map(p => p.join(',')).join(' ')
}
</script>

<style scoped>
</style>
