# Droid-Clash

A multiplayer party game where players control robots on a hexagonal grid using card-based programming. The Godot server runs the game and renders a 3D display; players join from their browser and submit cards each turn.

## Quick Start

### Prerequisites
- Godot 4.2+
- Node.js 18+

### 1. Start the Godot Server
Open this project in Godot 4.2+ and press Play (F5). The 3D board appears in the game window.

```
Initializing Droid-Clash Server...
WebSocket server listening on port 8080
Server initialized and ready for connections
```

### 2. Start the Browser Client
```bash
cd browser-client
npm install
npm run dev
# → http://localhost:5173
```

> **LAN play**: By default the client connects to `ws://192.168.1.32:8080` in dev mode.  
> For local-only testing set `VITE_WS_URL=ws://localhost:8080` before starting Vite.

### 3. Join & Play
- Open `http://localhost:5173` on each player's device
- Enter a name and click **Join**
- All players click **Ready** — game starts automatically when everyone is ready
- Each turn: select 3 cards in order, click **Submit Turn**
- Last robot standing wins

---

## Game Rules

| Rule | Detail |
|------|--------|
| Players | 2 – 8 |
| Board | Regular hexagonal grid, radius 4 (61 tiles) |
| Turn | Each player selects 3 cards from their 6-card hand |
| Deck | 13 cards per player (5× Move, 3× Turn Left, 3× Turn Right, 2× Attack) |
| Execution | Cards play out sequentially in randomised player order |
| Win | Last robot alive wins |
| Damage | Attack deals 15 HP; robots start at 100 HP |

---

## Project Structure

```
Droid-Clash/
├── src/
│   ├── main.gd                       # Server entry point & scene wiring
│   ├── config/
│   │   └── color_palette.gd          # Autoload: player colour palette (single source)
│   ├── server/
│   │   ├── websocket_server.gd       # WebSocket listener (port 8080)
│   │   └── message_handler.gd        # Message routing & validation
│   ├── network/
│   │   └── event_serializer.gd       # Wire-format helpers (hex → {q,r}, event arrays)
│   ├── game/
│   │   ├── game_manager.gd           # State machine, player management
│   │   ├── turn_manager.gd           # Round execution pipeline
│   │   └── card_validator.gd         # Card submission rule validation
│   ├── entities/
│   │   ├── hexgrid.gd                # Axial hex grid, pathfinding
│   │   ├── robot.gd                  # Robot state & movement
│   │   ├── deck.gd                   # Per-player shuffled deck
│   │   └── cards/
│   │       ├── card_base.gd          # Base class (type IDs, execute interface)
│   │       ├── card_move.gd          # Move Forward
│   │       ├── card_turn_left.gd     # Turn Left
│   │       ├── card_turn_right.gd    # Turn Right
│   │       ├── card_attack.gd        # Attack
│   │       ├── card_registry.gd      # Card factory
│   │       └── deck_config.gd        # Deck archetypes (standard / brawler / speedster)
│   └── ui/
│       ├── game_board_3d.gd          # Player lifecycle & signal routing
│       ├── hex_grid_renderer.gd      # 3D hex tile spawning & coordinate conversion
│       ├── round_animation_orchestrator.gd  # Sequential card-event animations
│       ├── robot_visual.gd           # Per-robot 3D node + animations
│       ├── lobby_panel.gd            # Lobby overlay (2D CanvasLayer)
│       ├── player_status_hud.gd      # In-game HUD (Selecting/Submitted/Acting)
│       └── server_status_panel.gd    # Debug info overlay
├── scenes/
│   └── main.tscn
├── browser-client/
│   ├── src/
│   │   ├── App.vue
│   │   ├── api/websocket.js          # WS client + message handlers
│   │   ├── stores/
│   │   │   ├── gameStore.js          # Phase, robots, cards, player statuses
│   │   │   └── playerStore.js        # Identity, color, connection state
│   │   └── components/
│   │       ├── LobbyScreen.vue       # Name entry, archetype picker, ready button
│   │       ├── CardSelection.vue     # 6-card hand, select 3, submit
│   │       ├── HexBoard.vue          # SVG hex grid (client-side view)
│   │       └── GameOverScreen.vue    # Winner display
│   └── package.json
└── docs/
    ├── API.md          # WebSocket message reference
    ├── ARCHITECTURE.md # System design & data flow
    └── SETUP.md        # Detailed environment setup
```

---

## Documentation

- **[docs/SETUP.md](docs/SETUP.md)** — Environment setup & troubleshooting
- **[docs/API.md](docs/API.md)** — WebSocket message protocol (complete reference)
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — System design & data flow
- **[CONTRIBUTING.md](CONTRIBUTING.md)** — Code style guide

---

## Development

### Code Style
- **GDScript**: typed signals and variables, snake_case, no `var x := dict[key]` on Variant returns
- **Vue**: Composition API with `<script setup>`, Pinia stores, Tailwind CSS inline styles for dynamic colors
- **Commits**: descriptive messages; include `Co-authored-by` trailer

### Adding a New Card Type
1. Create `src/entities/cards/card_yourcard.gd` extending `Card`
2. Add it to `CardRegistry.create()` match statement
3. Add its count to the relevant archetype(s) in `DeckConfig.preset()` (`src/entities/cards/deck_config.gd`)
4. No other files need changing

---

## License

MIT
