# Droid-Clash: Implementation Reference

**Status**: Feature-complete and playable  
**Engine**: Godot 4.2+ (server + 3D display) · Vue 3 (browser clients)

For architecture overview and system design, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).  
For the WebSocket protocol, see [docs/API.md](docs/API.md).  
For setup instructions, see [docs/SETUP.md](docs/SETUP.md).

---

## Source Files

### Godot Server

| File | Purpose |
|------|---------|
| `src/main.gd` | Bootstrap, scene wiring, camera/lighting |
| `src/server/websocket_server.gd` | WebSocket listener, broadcast helpers |
| `src/server/message_handler.gd` | Message routing, validation, hand/status broadcasts |
| `src/game/game_manager.gd` | State machine, player/deck management, color assignment |
| `src/game/turn_manager.gd` | Round execution, randomised player order, CardRegistry integration |
| `src/entities/hexgrid.gd` | Axial hex grid, neighbours, BFS, boundary check |
| `src/entities/robot.gd` | Robot state, movement, combat, serialisation |
| `src/entities/deck.gd` | Per-player shuffled deck, draw pile, instance IDs |
| `src/entities/cards/card_base.gd` | Base class, TYPE_* constants, virtual `execute()` |
| `src/entities/cards/card_move.gd` | Move Forward — moves one hex forward |
| `src/entities/cards/card_turn_left.gd` | Turn Left — rotates robot CCW |
| `src/entities/cards/card_turn_right.gd` | Turn Right — rotates robot CW |
| `src/entities/cards/card_attack.gd` | Attack — 15 damage to robot directly ahead |
| `src/entities/cards/card_registry.gd` | Factory (`create(type_id)`) + deck `COMPOSITION` |
| `src/ui/game_board_3d.gd` | 3D hex board, sequential animation, event playback |
| `src/ui/robot_visual.gd` | Per-robot Node3D, health bar, movement/attack tweens |
| `src/ui/lobby_panel.gd` | Lobby CanvasLayer overlay (player list, ready status) |
| `src/ui/player_status_hud.gd` | In-game HUD (Selecting / Submitted / Acting per player) |
| `src/ui/server_status_panel.gd` | Debug overlay (phase, turn, health) |

### Browser Client

| File | Purpose |
|------|---------|
| `browser-client/src/api/websocket.js` | WS client, reconnect, message handlers |
| `browser-client/src/stores/gameStore.js` | Phase, robots, cards, player statuses |
| `browser-client/src/stores/playerStore.js` | Identity, color, connection state |
| `browser-client/src/components/LobbyScreen.vue` | Name entry, player list, ready button |
| `browser-client/src/components/CardSelection.vue` | 6-card hand, pick 3, submit |
| `browser-client/src/components/HexBoard.vue` | SVG hex grid with robot positions |
| `browser-client/src/components/GameOverScreen.vue` | Winner announcement |

---

## Completed Features

| Feature | Notes |
|---------|-------|
| Core game loop | Turn-based, randomised execution order |
| Card system | Self-contained entity classes; per-player shuffled 13-card deck |
| Hex grid | Regular board, radius 4, 61 tiles, axial coordinates |
| 3D server visualisation | Sequential card animations, colored robots, health bars |
| Player colors | 8 distinct palette colors, assigned by join order |
| Player status HUD | Godot CanvasLayer — Selecting / Submitted / Acting |
| Lobby panel | Player list with color swatches and ready status |
| WebSocket protocol | Full event payloads; `hand_update` before `game_state_update` |
| INVALID_CARD fix | Race condition resolved: hand sent before enabling client UI |
| Browser client | Tailwind UI, Pinia, card description display, loading state |

---

## Known Limitations

| Issue | Notes |
|-------|-------|
| Turn timeout | `_check_timeout()` always returns false — not yet implemented |
| WS URL | Dev hardcoded to `ws://192.168.1.32:8080` — set `VITE_WS_URL` for local |
| HexBoard | SVG client view is approximate; Godot 3D is authoritative |
| No unit tests | No GUT or Vitest suites exist yet |
