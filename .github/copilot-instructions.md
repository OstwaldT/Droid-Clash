# Droid-Clash — Copilot Instructions

## Architecture

Two independent components communicate exclusively over WebSocket (JSON, port 8080):

- **Godot server** (`src/`, `scenes/`) — GDScript, runs headless, owns all game logic and state. Entry point: `src/main.gd` → `MainServer`.
- **Vue 3 client** (`browser-client/`) — Vite + Pinia + Tailwind, browser-only UI. Entry point: `browser-client/src/main.js`.

### Godot server layer layout
```
src/
  main.gd              # Bootstraps all nodes
  server/
    websocket_server.gd  # TCP/WS peer management, broadcast/send helpers
    message_handler.gd   # Routes incoming JSON messages to game logic
  game/
    game_manager.gd      # Lifecycle (LOBBY→PLAYING→GAME_OVER), player/robot registry
    turn_manager.gd      # Collects submissions, executes card instructions in order
    instructions.gd      # Instruction type definitions & execution logic
  entities/
    hexgrid.gd           # Axial (q,r) coordinate system, pathfinding, neighbors
    robot.gd             # Per-robot state (position, health, direction 0-5)
  ui/                    # Optional server status panel (Godot editor only)
```

### Vue client layer layout
```
browser-client/src/
  api/websocket.js       # Singleton WebSocketClient — connect, send, on(type, handler)
  stores/
    gameStore.js         # Phase, board, robots, available/selected cards (Pinia)
    playerStore.js       # playerId, playerName, isConnected (Pinia)
  components/
    LobbyScreen.vue      # Name input + connect flow
    CardSelection.vue    # Pick 3 cards + submit turn
    HexBoard.vue         # SVG/Canvas hex grid render
    GameOverScreen.vue   # End-game results
```

### Message flow (one turn)
1. Client sends `{ type: "turn_submit", data: { playerId, cardIds: [n,n,n], turnNumber } }`
2. `message_handler.gd` validates and queues via `game_manager.submit_turn()`
3. `turn_manager.gd` executes when all alive players have submitted (or timeout)
4. Server broadcasts `game_state_update` → `websocket.js` calls `handleGameStateUpdate` → Pinia stores update → Vue re-renders

All WebSocket messages follow the envelope: `{ type: String, timestamp: int, data: {} }`.

### Hex grid
Uses **axial coordinates (q, r)**. Directions 0–5 clockwise starting from right:
- Neighbor offsets: `(+1,0), (+1,-1), (0,-1), (-1,0), (-1,+1), (0,+1)`
- Distance: `(|Δq| + |Δq+Δr| + |Δr|) / 2`

---

## Commands

### Browser client
```bash
cd browser-client
npm install        # first-time setup
npm run dev        # dev server → http://localhost:5173
npm run build      # production build
npm run test       # Vitest (all tests)
npx vitest run path/to/file.test.js   # single test file
```

### Godot server
```bash
# Open project root in Godot 4.2+ and press Play, or headless:
godot --headless --path .            # run server
godot --headless --test              # run GUT test suite
godot --headless --test res://tests/test_hexgrid.gd  # single test file
godot --export-release Linux build/server            # production export
```

### WebSocket URL
In dev, the client hardcodes `ws://192.168.1.32:8080`. For local development update `WS_URL` in `browser-client/src/api/websocket.js` or set `VITE_WS_URL` env var.

---

## Conventions

### GDScript
- Class structure order: `signal` → `const` → `var` → `_ready()` → public methods → `_private_methods()`
- Always declare type hints: `func foo(x: int) -> String:`
- Private members prefixed with `_`: `var _game_state`, `func _initialize()`
- Use signals instead of polling in `_process()` wherever possible
- Cache `get_node()` results; avoid repeated lookups in hot paths
- GDScript doc comments use `##` (double `#`) on the line above the function

### Vue 3
- All components use `<script setup>` (Composition API, no Options API)
- Import order inside `<script setup>`: Vue core → Pinia stores → child components → local utils
- Derive values with `computed` rather than methods when the result depends on reactive state
- Use `v-show` for toggled elements; `v-if` only when the subtree is truly conditional

### CSS / Tailwind
- Tailwind utility classes first; write `<style scoped>` only for animations or overrides that Tailwind cannot express
- No inline `style=""` attributes; no hardcoded hex color values

### Commits
Format: `[type] Brief description (≤50 chars)` where type is one of `feat fix docs style refactor perf test chore`.  
Branch naming: `feature/…`, `fix/…`, `docs/…`, `chore/…`.

### No-commit checklist
- No `console.log()` in Vue files; no `print()` in production GDScript paths
- No credentials or secrets in source

---

## Testing

### Godot — GUT framework
```gdscript
class_name TestHexGrid
extends GutTest

func test_distance_calculation() -> void:
    var hex = HexGrid.new()
    assert_eq(hex.get_distance(Vector2i(0, 0), Vector2i(3, 0)), 3)
```

### Vue — Vitest + Pinia
```javascript
import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useGameStore } from '@/stores/gameStore'

describe('Game Store', () => {
  beforeEach(() => setActivePinia(createPinia()))

  it('allows selecting up to 3 cards', () => {
    const store = useGameStore()
    store.selectCard(1); store.selectCard(2); store.selectCard(3)
    expect(store.canSubmitTurn).toBe(true)
  })
})
```

---

## Key reference docs
- `docs/API.md` — full WebSocket message catalogue
- `docs/ARCHITECTURE.md` — component diagrams and game state schema
- `docs/SETUP.md` — environment setup details
