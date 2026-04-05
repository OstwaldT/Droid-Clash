# Droid-Clash System Architecture

## Overview Diagram

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
                            │
                    WebSocket Protocol
                  (JSON messages, bi-directional)
                            │
┌─────────────────────────────────────────────────────────┐
│         Godot Game Server (GDScript)                    │
│  ┌──────────────────────────────────────────────────┐  │
│  │ WebSocket Server (Port 8080)                     │  │
│  │  - Accept connections                           │  │
│  │  - Route messages                               │  │
│  │  - Broadcast state updates                      │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Game Manager                                     │  │
│  │  - Lobby management                             │  │
│  │  - Turn sequencing                              │  │
│  │  - Win/lose conditions                          │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Game State                                       │  │
│  │  - Active players                               │  │
│  │  - Robot positions & health                     │  │
│  │  - Turn queue                                   │  │
│  │  - Cards played                                 │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Game Entities                                    │  │
│  │  - Hexagonal Grid (coordinates, pathfinding)    │  │
│  │  - Robots (position, health, direction)         │  │
│  │  - Instructions (move, turn, attack)            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Data Flow: A Turn Sequence

### 1. Client Selects Cards
```
Player UI (Vue) 
  → Click 3 cards
  → { type: "turn_submit", data: { playerId, cardIds: [1,2,3] } }
  → WebSocket to Server
```

### 2. Server Receives & Queues
```
WebSocket Server (Godot)
  → message_handler.gd processes message
  → Validates cards & player
  → Adds to turn queue
  → Broadcasts: { type: "turn_received", data: { playerId, accepted: true } }
```

### 3. Server Executes Turn
```
Turn Manager (Godot)
  → When all players submitted (or timeout):
    → Dequeue submitted cards
    → Execute in sequence
    → Update game state (positions, health)
  → Broadcast state: { type: "game_state_update", data: {...} }
```

### 4. Client Syncs & Renders
```
Vue Client
  → Receives game_state_update
  → Updates Pinia store
  → Re-renders board
  → Shows updated positions & health
```

---

## Key Components

### Godot Server (GDScript)

#### websocket_server.gd
```
Responsibilities:
  - Listen on port 8080
  - Accept WebSocket connections
  - Parse incoming JSON messages
  - Route to appropriate handlers
  - Broadcast to connected clients
```

#### game_manager.gd
```
Responsibilities:
  - Manage game lifecycle (lobby → play → end)
  - Add/remove players
  - Enforce turn sequencing
  - Validate card selections
  - Check win conditions
```

#### game_state.gd
```
Responsibilities:
  - Store current game state
  - Serialize to JSON for clients
  - Immutable updates (functional approach)
```

#### turn_manager.gd
```
Responsibilities:
  - Collect player card selections
  - Execute instructions in order
  - Handle collisions & attacks
  - Update positions & health
```

#### hexgrid.gd
```
Responsibilities:
  - Hex coordinate system (axial or cube)
  - Pathfinding (A* or breadth-first)
  - Distance calculations
  - Neighbor queries
  - Collision detection
```

#### robot.gd
```
Responsibilities:
  - Robot state (position, health, direction)
  - Execute instructions (move, turn, attack)
  - Collision checking
```

#### instructions.gd
```
Responsibilities:
  - Define instruction types (move, turn, attack)
  - Execute instruction logic
  - Return state changes
```

---

### Vue 3 Client

#### websocket.js (API Layer)
```javascript
Responsibilities:
  - Connect to ws://localhost:8080
  - Send messages (turn_submit, etc.)
  - Listen for messages
  - Dispatch to store on updates
  - Reconnection logic
```

#### stores/gameStore.js (Pinia)
```
State:
  - currentGame (game ID, phase, turn number)
  - players (array of player objects)
  - board (grid state, positions, health)
  - selectedCards (current player's card picks)
  
Actions:
  - submitTurn(cardIds)
  - updateGameState(newState)
  - setPlayers(players)
```

#### stores/playerStore.js (Pinia)
```
State:
  - playerId
  - playerName
  - isConnected
  
Actions:
  - setPlayer(id, name)
  - setConnected(bool)
```

#### components/LobbyScreen.vue
```
Purpose:
  - Player name input
  - Connect to server
  - Wait for others / start game
```

#### components/CardSelection.vue
```
Purpose:
  - Display available cards
  - Allow player to select 3
  - Submit turn
  - Show feedback (accepted/rejected)
```

#### components/HexBoard.vue
```
Purpose:
  - Render hexagonal grid (SVG or Canvas)
  - Display robot positions
  - Show health bars
  - Animate movement
```

#### components/GameUI.vue
```
Purpose:
  - Display player turn order
  - Show current turn
  - Display action log
  - End game screen
```

---

## Message Protocol (WebSocket)

### Connection Messages

**Client → Server: Join Lobby**
```json
{
  "type": "join",
  "timestamp": 1704067200000,
  "data": {
    "playerName": "Alice"
  }
}
```

**Server → Client: Player Joined**
```json
{
  "type": "player_joined",
  "timestamp": 1704067200000,
  "data": {
    "players": [
      { "playerId": 1, "name": "Alice", "ready": false },
      { "playerId": 2, "name": "Bob", "ready": false }
    ]
  }
}
```

### Game Messages

**Client → Server: Submit Turn**
```json
{
  "type": "turn_submit",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1,
    "cardIds": [5, 7, 9],
    "turnNumber": 1
  }
}
```

**Server → Client: Turn Accepted**
```json
{
  "type": "turn_accepted",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1,
    "turnNumber": 1,
    "message": "Turn submitted"
  }
}
```

**Server → All Clients: Game State Update**
```json
{
  "type": "game_state_update",
  "timestamp": 1704067200000,
  "data": {
    "turnNumber": 1,
    "phase": "executing_turn",
    "robots": [
      {
        "playerId": 1,
        "position": { "q": 0, "r": 0 },
        "health": 100,
        "direction": 0
      },
      {
        "playerId": 2,
        "position": { "q": 1, "r": 0 },
        "health": 100,
        "direction": 1
      }
    ],
    "events": [
      { "type": "move", "playerId": 1, "from": { "q": -1, "r": 0 }, "to": { "q": 0, "r": 0 } },
      { "type": "attack", "playerId": 1, "target": 2, "damage": 10 }
    ]
  }
}
```

**Server → All Clients: Game Over**
```json
{
  "type": "game_over",
  "timestamp": 1704067200000,
  "data": {
    "winner": 1,
    "winnerName": "Alice",
    "finalPlayers": [
      { "playerId": 1, "name": "Alice", "health": 45, "rank": 1 },
      { "playerId": 2, "name": "Bob", "health": 0, "rank": 2 }
    ]
  }
}
```

---

## Game State Schema

```javascript
{
  gameId: String,
  phase: "lobby" | "playing" | "game_over",
  turnNumber: Number,
  maxPlayers: Number,
  
  players: [
    {
      playerId: Number,
      name: String,
      isConnected: Boolean,
      hasTurnSubmitted: Boolean,
      isAlive: Boolean
    }
  ],
  
  robots: [
    {
      playerId: Number,
      position: { q: Number, r: Number },
      direction: Number, // 0-5 (hex directions)
      health: Number,
      maxHealth: Number,
      status: String // "alive", "dead"
    }
  ],
  
  board: {
    width: Number,
    height: Number,
    obstacles: [] // list of obstacle coordinates
  },
  
  cardsDef: [
    {
      id: Number,
      name: String,
      instruction: "move" | "turn_left" | "turn_right" | "attack",
      cooldown: Number
    }
  ]
}
```

---

## Hexagonal Grid System

Using **axial coordinates (q, r)**:
- q: column (increases to the right)
- r: row (increases downward)

### Directions (0-5, clockwise)
```
      /\    
    /5  0\
   |      |
   |4    1|
    \    /
    3\2/
     \/
```

### Distance Calculation
```
distance = (|q1 - q2| + |q1 + r1 - q2 - r2| + |r1 - r2|) / 2
```

### Neighbor Offsets
```
Direction 0: (q+1, r)
Direction 1: (q+1, r-1)
Direction 2: (q, r-1)
Direction 3: (q-1, r)
Direction 4: (q-1, r+1)
Direction 5: (q, r+1)
```

---

## Error Handling & Resilience

### WebSocket Disconnect
- **Client**: Auto-reconnect with exponential backoff
- **Server**: Remove player, end game if insufficient players

### Invalid Card Selection
- **Server**: Reject with error message
- **Client**: Show error toast, allow re-selection

### Collision During Move
- **Server**: Cancel move, keep robot in place, continue with next instruction

### Network Latency
- **Client**: Optimistic updates (show card selection immediately)
- **Server**: Authoritative (updates only when server confirms)

---

## Performance Considerations

### Scalability (Target: 8 Players)
- WebSocket messages: ~100KB per turn
- Server process: One game instance per game
- Client rendering: Canvas or SVG, optimize for mobile

### Optimization
1. **Message Compression**: Use binary format (MessagePack) if needed
2. **Delta Updates**: Only send changed state, not entire state
3. **Lazy Rendering**: Only render visible hex tiles
4. **Debounce**: Throttle animation updates to 60fps

---

## Future Extensions

1. **Persistence**: Save games to database
2. **Replays**: Record & playback turns
3. **Spectators**: Allow non-playing observers
4. **Chat**: In-game messaging
5. **Custom Cards**: Let players design cards
6. **Different Maps**: Multiple board configurations
7. **Power-ups**: Special items on grid
