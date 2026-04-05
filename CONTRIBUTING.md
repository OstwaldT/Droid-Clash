# Contributing to Droid-Clash

## Code Style Guide

### GDScript (Godot)

**Naming Conventions**:
- Classes: `PascalCase` (e.g., `HexGrid`, `RobotEntity`)
- Functions/Methods: `snake_case` (e.g., `get_neighbors`, `execute_instruction`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `MAX_PLAYERS`, `GRID_WIDTH`)
- Private properties: prefix with `_` (e.g., `_current_turn`)
- Signals: use `snake_case` (e.g., `turn_completed`, `player_eliminated`)

**Function Structure**:
```gdscript
# Public methods first, then private
# Each class: signals → constants → properties → _ready → methods

class_name GameManager
extends Node

signal turn_completed
signal game_ended

const MAX_PLAYERS = 8
const GRID_WIDTH = 10

var current_turn: int = 0
var _game_state: Dictionary = {}

func _ready() -> void:
  _initialize_game()

func start_turn() -> void:
  # Implementation
  pass

func _initialize_game() -> void:
  # Private method
  pass
```

**Comments**:
- Only comment complex logic or non-obvious decisions
- Use `#` for single-line comments
- Avoid obvious comments like `# increment counter`

**Type Hints**:
```gdscript
# Always use type hints
func calculate_distance(from: Vector2, to: Vector2) -> float:
  return from.distance_to(to)

var players: Array[Dictionary] = []
```

---

### Vue 3 & JavaScript

**Naming Conventions**:
- Components: `PascalCase` (e.g., `CardSelection.vue`, `HexBoard.vue`)
- Functions/Methods: `camelCase` (e.g., `submitTurn`, `calculateDistance`)
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `WS_URL`, `MAX_CARDS`)
- Private functions: prefix with `_` (e.g., `_initializeConnection`)
- Store actions: `camelCase` (e.g., `updateGameState`)

**Component Structure**:
```vue
<template>
  <div class="card-selection">
    <h2>Select 3 Cards</h2>
    <div class="cards">
      <button 
        v-for="card in availableCards"
        :key="card.id"
        :disabled="isCardSelected(card.id)"
        @click="selectCard(card)"
      >
        {{ card.name }}
      </button>
    </div>
    <button @click="submitTurn" :disabled="selectedCards.length !== 3">
      Submit
    </button>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useGameStore } from '@/stores/gameStore'

const gameStore = useGameStore()

const selectedCards = computed(() => gameStore.selectedCards)
const availableCards = computed(() => gameStore.availableCards)

const selectCard = (card) => {
  gameStore.selectCard(card.id)
}

const isCardSelected = (cardId) => {
  return selectedCards.value.some(c => c.id === cardId)
}

const submitTurn = () => {
  gameStore.submitTurn()
}
</script>

<style scoped>
.card-selection {
  padding: 1rem;
}

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
  gap: 0.5rem;
  margin: 1rem 0;
}

button {
  padding: 0.5rem;
  border-radius: 0.25rem;
  border: 2px solid #ccc;
  cursor: pointer;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
```

**Import Organization** (in order):
```javascript
// 1. Vue imports
import { ref, computed } from 'vue'

// 2. Store imports
import { useGameStore } from '@/stores/gameStore'

// 3. Component imports
import CardList from '@/components/CardList.vue'

// 4. Local files
import { formatTime } from '@/utils/format'
```

**Type Hints** (JSDoc for critical functions):
```javascript
/**
 * Submit the player's turn with selected cards
 * @param {number[]} cardIds - Array of 3 card IDs
 * @returns {Promise<void>}
 */
const submitTurn = async (cardIds) => {
  // ...
}
```

---

### CSS & Tailwind

**Tailwind First**:
- Use Tailwind utility classes instead of custom CSS
- Only write scoped CSS for complex animations or overrides
- Avoid color hex codes; use Tailwind color palette

**Good**:
```vue
<div class="flex justify-center items-center gap-4 p-6 bg-gray-50 rounded-lg">
  <button class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
    Submit
  </button>
</div>
```

**Avoid**:
```vue
<div style="display: flex; justify-content: center; color: #333;">
  <button style="background-color: #0066ff; padding: 10px; border-radius: 4px;">
    Submit
  </button>
</div>
```

---

## Git Workflow

### Branch Naming
- Feature: `feature/card-selection-ui`
- Bug fix: `fix/websocket-reconnection`
- Docs: `docs/api-reference`
- Chore: `chore/update-dependencies`

### Commit Messages
```
[type] Brief description (max 50 chars)

Longer explanation if needed (wrap at 72 chars).
Explain the "why", not the "what".

Closes #123
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`

### PR Template
```markdown
## Description
Brief summary of what this PR does.

## Related Issue
Closes #123

## Changes
- Change 1
- Change 2

## Testing
How was this tested? Include steps to reproduce.

## Screenshots (if applicable)
Add images for UI changes.
```

---

## Testing

### Godot (GDScript)
```gdscript
# Unit test example using Godot's testing framework
class_name TestHexGrid
extends GutTest

func test_distance_calculation() -> void:
  var hex = HexGrid.new()
  var distance = hex.get_distance(Vector2i(0, 0), Vector2i(3, 0))
  assert_eq(distance, 3)

func test_neighbor_calculation() -> void:
  var hex = HexGrid.new()
  var neighbors = hex.get_neighbors(Vector2i(0, 0))
  assert_eq(neighbors.size(), 6)
```

### Vue 3 (Vitest)
```javascript
import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useGameStore } from '@/stores/gameStore'

describe('Game Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('should submit turn with 3 cards', () => {
    const store = useGameStore()
    store.selectCard(1)
    store.selectCard(2)
    store.selectCard(3)
    
    expect(store.selectedCards).toHaveLength(3)
  })
})
```

---

## Performance Guidelines

### Godot
- Avoid `_process()` for frequent updates; use signals/timers
- Cache node references to avoid repeated `get_node()` calls
- Use `Object Pooling` for frequently created entities (robots, particles)

### Vue 3
- Use `v-show` for toggled elements; `v-if` for conditionally rendered content
- Lazy-load routes with dynamic imports
- Use `computed` properties instead of methods for derived state
- Avoid heavy DOM manipulations; let Vue's reactivity handle it

### WebSocket
- Batch messages if possible (max 100KB per message)
- Use binary format (MessagePack) if traffic is high
- Implement heartbeat/ping-pong to detect dead connections

---

## Documentation

### For Developers
- Keep README.md up-to-date
- Document public functions with JSDoc/GDScript comments
- Update ARCHITECTURE.md for major changes
- Add examples for non-obvious features

### For Godot Scripts
```gdscript
## Calculates distance between two hex coordinates using axial system.
## The distance is the number of hex steps, accounting for wraparound.
func get_distance(from: Vector2i, to: Vector2i) -> int:
  return ((abs(from.x - to.x) + abs(from.y - to.y) + abs(from.x + from.y - to.x - to.y)) / 2) as int
```

### For Vue 3
```javascript
/**
 * Submits the player's card selection for the current turn.
 * Validates that exactly 3 unique cards are selected before submission.
 * 
 * @throws {Error} If not exactly 3 cards are selected
 * @returns {Promise<void>} Resolves when server confirms
 */
const submitTurn = async () => {
  // ...
}
```

---

## Review Checklist

Before submitting a PR, ensure:

- [ ] Code follows style guide
- [ ] No console.log() or print() statements left
- [ ] Tests pass (if applicable)
- [ ] No breaking changes to existing API
- [ ] Documentation updated
- [ ] Branch is up-to-date with `main`
- [ ] Commit messages are descriptive
- [ ] No credentials/secrets in code

---

## Questions?

Refer to:
- **Architecture**: See `docs/ARCHITECTURE.md`
- **API**: See `docs/API.md`
- **Setup**: See `docs/SETUP.md`
- **Issues**: Use GitHub Issues for bugs/features
