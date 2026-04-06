# Droid-Clash: System Architecture

## Overview

```
┌─────────────────────────────────────────────────────────┐
│                   Browser Clients                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  Player 1   │  │  Player 2   │  │  Player N   │     │
│  │  (Vue 3)    │  │  (Vue 3)    │  │  (Vue 3)    │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
└─────────┼─────────────────┼─────────────────┼──────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │  WebSocket JSON (port 8080)
┌─────────────────────────────────────────────────────────┐
│         Godot 4.2 Game Server (GDScript)                │
│  ┌────────────────────┐  ┌──────────────────────────┐  │
│  │ WebSocket Server   │  │ Message Handler          │  │
│  │ (port 8080)        │  │ (routing, validation)    │  │
│  └────────────────────┘  └──────────────────────────┘  │
│  ┌────────────────────┐  ┌──────────────────────────┐  │
│  │ Game Manager       │  │ Turn Manager             │  │
│  │ (state, players,   │  │ (round execution,        │  │
│  │  colors, decks)    │  │  CardRegistry, events)   │  │
│  └────────────────────┘  └──────────────────────────┘  │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Entities                                           │ │
│  │  HexGrid · Robot · Deck                            │ │
│  │  Cards: CardBase / Move / TurnL / TurnR / Attack   │ │
│  │  CardRegistry (factory + COMPOSITION)              │ │
│  └────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────┐ │
│  │ UI (Godot 3D display, shared screen)               │ │
│  │  GameBoard3D · RobotVisual · LobbyPanel            │ │
│  │  PlayerStatusHUD · ServerStatusPanel               │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Data Flow: One Turn

### 1. New hand delivered privately
```
Server (after previous round resolved)
  → resolve_and_redraw_player_hand()
  → deck.draw_hand() → 6 cards with fresh instance IDs
  → hand_update (private) → player's browser
  → game_state_update (broadcast) → all browsers
    (order matters: hand sent BEFORE game_state_update
     so client never shows old cards)
```

### 2. Player selects and submits
```
Browser (CardSelection.vue)
  → pick 3 cards (instance IDs, not type IDs)
  → { type: "turn_submit", playerId, turnNumber, cardIds: [instId, ...] }
  → WebSocket → message_handler.gd
  → validates instance IDs against player's current hand
  → game_manager.submit_turn()
  → server: player_statuses_update broadcast (status = "submitted")
  → browser: turn_accepted (private)
```

### 3. Round executes
```
game_manager (when all alive players submitted)
  → turn_manager.execute_round()
    → randomise player order
    → for each player × 3 cards:
        CardRegistry.create(type_id).execute(robot, grid, robots)
        → appends event dict to events array
  → emits turn_executed(events)
  → message_handler._on_turn_executed:
      1. resolve all player hands (hand_update private per player)
      2. game_state_update broadcast (robots, events, playerStatuses)
  → game_board_3d._on_turn_executed:
      sequential await-based animation per event
```

---

## Key Components

### `game_manager.gd`
- State machine: `LOBBY → PLAYING → GAME_OVER`
- Holds `players`, `robots`, `player_decks` dicts
- Assigns a distinct colour via `ColorPalette.hex_for()` on join
- Signals: `player_joined`, `player_left`, `player_ready`, `player_submitted`, `round_starting`, `game_started`, `game_ended`

### `turn_manager.gd`
- Collects `card_submissions[player_id] = [instance_id, ...]`
- `execute_round()`: resolves instance IDs → type IDs via deck, calls `CardRegistry.create(type_id).execute()`
- `submitted_instance_ids` cleared **after** resolve (not before) to prevent INVALID_CARD race

### `game_board_3d.gd`
- Thin coordinator: manages player join/leave lifecycle, owns `HexGridRenderer` and `RoundAnimationOrchestrator`
- On `turn_executed`: awaits orchestrator, then handles game-over overlay and emits `round_display_complete`

### `hex_grid_renderer.gd`
- Spawns all hex tile geometry (floor, wall, pit) with procedural scifi materials
- Owns coordinate conversion: `hex_to_world()`, `hex_to_robot_pos()`
- `generate(grid)` / `clear()` called by `GameBoard3D` on setup and rematch

### `round_animation_orchestrator.gd`
- Receives shared references to renderer and robot-visual dict
- `play(events)` is awaitable — sequences all per-event animations (move, rush, turn, attack, shoot)
- `_sync_all_visuals()` snaps all robots to authoritative state after animations

### Card Entity System (`src/entities/cards/`)
```
card_base.gd          Base class, TYPE_* constants (1–6), virtual execute()
  ├── card_move.gd          TYPE_MOVE=1    🔼 Move forward one hex
  ├── card_turn_left.gd     TYPE_TURN_LEFT=2   ↶ Rotate CCW
  ├── card_turn_right.gd    TYPE_TURN_RIGHT=3  ↷ Rotate CW
  ├── card_attack.gd        TYPE_ATTACK=4  💥 15 damage to robot ahead
  ├── card_rush.gd          TYPE_RUSH=5    ⚡ Move forward two hexes
  └── card_shoot.gd         TYPE_SHOOT=6   🚀 Ranged attack along facing axis

card_registry.gd      static create(type_id) → Card
deck_config.gd        preset(key) → DeckConfig  (standard / brawler / speedster)
```

### `deck.gd`
- Per-player shuffled draw pile + discard pile + current 6-card hand
- Each drawn card gets a unique monotonic `instance_id`
- `resolve_hand(played_ids)`: discards the 3 played, returns unchosen 3 to draw pile
- `hand_to_array()`: serialises hand including `id` (instance), `typeId`, `name`, `icon`, `description`

### `message_handler.gd`
- Delegates card validation to `CardValidator.validate()` (game-rule logic lives in game layer)
- Guards against duplicate submissions per turn
- `_on_turn_executed`: sends `hand_update` to each player first, then `game_state_update` broadcast
- `_broadcast_player_statuses()` called after each submission and on `round_starting`

### `game_board_3d.gd` + `hex_grid_renderer.gd` + `round_animation_orchestrator.gd`
- 61 flat-top hexagonal tiles generated as `CylinderMesh` with scifi metallic materials
- Sequential event animation via `await` timer: MOVE 0.85s, TURN 0.45s, ATTACK 0.90s
- `RobotVisual`: speeder GLB model, billboard health bar, movement/attack tweens
- `match Card.TYPE_*` dispatches animation type in `RoundAnimationOrchestrator._play_*()`

### `player_status_hud.gd`
- `CanvasLayer` top-right of Godot window
- One row per player: color swatch · name · badge (Selecting / Submitted / Acting)
- Connected to `player_submitted`, `round_starting`, `turn_executed` signals

---

## Hexagonal Grid

Flat-top hexagons, axial coordinates (q, r). Board radius = 4 (side 5, 61 tiles).

**Boundary**: `max(|q|, |r|, |q+r|) ≤ 4`

**Directions (0–5 clockwise from top-right):**
```
    0: (q+1, r-1)   1: (q+1, r)
5: (q, r-1)              2: (q, r+1)
    4: (q-1, r)   3: (q-1, r+1)
```

**Distance**: `max(|q1-q2|, |r1-r2|, |q1+r1 - q2-r2|)`

---

## Browser Client (Vue 3)

| Store | Key state |
|-------|-----------|
| `gameStore` | `phase`, `turnNumber`, `robots`, `availableCards`, `selectedCards`, `playerStatuses` |
| `playerStore` | `playerId`, `playerName`, `color`, `isConnected` |

`clearSelectedCards()` also clears `availableCards` — ensures client never submits stale instance IDs from previous hand.

`websocket.js` message flow:
```
connect           → playerStore (id, color)
player_joined     → gameStore (player list)
game_start        → gameStore (phase, robots, boardRadius, playerStatuses)
hand_update       → gameStore.availableCards  (private, per player)
turn_accepted     → gameStore.turnSubmitted = true
player_statuses_update → gameStore.playerStatuses
game_state_update → gameStore (robots, events, phase, playerStatuses)
game_over         → gameStore (winner, finalPlayers)
```

---

## Error Handling

| Scenario | Behaviour |
|----------|-----------|
| Invalid card instance ID | `INVALID_CARD` error → client; submission rejected |
| Duplicate submission | Silently ignored (guard in message_handler) |
| Player disconnects | Robot removed; game continues if ≥ 2 remain |
| Stale hand race | Prevented: `hand_update` always sent before `game_state_update` |

