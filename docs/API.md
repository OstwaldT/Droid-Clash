# WebSocket API Reference

## Connection

### Endpoint
- **Local Dev**: `ws://localhost:8080`
- **Production**: `wss://your-domain.com` (secure WebSocket)

### Connection Flow

1. Client connects to WebSocket server
2. Server accepts and assigns player ID
3. Client sends `join` message with player name
4. Server broadcasts `player_joined` to all clients

---

## Message Format

All messages are JSON with this structure:

```json
{
  "type": "message_type",
  "timestamp": 1704067200000,
  "data": { }
}
```

**Fields:**
- `type` (string): Message type identifier
- `timestamp` (number): Unix timestamp in milliseconds
- `data` (object): Message-specific payload

---

## Client → Server Messages

### 1. Join Lobby

**Type**: `join`

**Purpose**: Player joins the game lobby

**Payload**:
```json
{
  "type": "join",
  "timestamp": 1704067200000,
  "data": {
    "playerName": "Alice"
  }
}
```

**Response**: Server broadcasts `player_joined`

**Error Responses**:
- Game full: `{ "type": "error", "data": { "code": "GAME_FULL", "message": "..." } }`
- Invalid name: `{ "type": "error", "data": { "code": "INVALID_NAME", "message": "..." } }`

---

### 2. Ready / Start Game

**Type**: `ready`

**Purpose**: Player signals they're ready to play

**Payload**:
```json
{
  "type": "ready",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1
  }
}
```

**Response**: Server broadcasts `players_ready` when all are ready

---

### 3. Submit Turn (Card Selection)

**Type**: `turn_submit`

**Purpose**: Player submits their 3 card selections for the turn

**Payload**:
```json
{
  "type": "turn_submit",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1,
    "turnNumber": 5,
    "cardIds": [2, 5, 7]
  }
}
```

**Validation**:
- `cardIds` must be array of exactly 3 unique card IDs
- `turnNumber` must match server's current turn
- `playerId` must match authenticated player

**Response**: Server broadcasts `turn_accepted` to player, then `game_state_update` to all when turn executes

**Error Responses**:
- Wrong turn number: `{ "type": "error", "data": { "code": "INVALID_TURN", "message": "..." } }`
- Invalid cards: `{ "type": "error", "data": { "code": "INVALID_CARDS", "message": "..." } }`
- Duplicate cards: `{ "type": "error", "data": { "code": "DUPLICATE_CARDS", "message": "..." } }`

---

### 4. Disconnect / Leave

**Type**: `leave`

**Purpose**: Player leaves game

**Payload**:
```json
{
  "type": "leave",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1,
    "reason": "user_requested"
  }
}
```

**Response**: Server broadcasts `player_left` to remaining players

---

## Server → Client Messages

### 1. Connection Established

**Type**: `connect`

**Payload**:
```json
{
  "type": "connect",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1,
    "wsUrl": "ws://localhost:8080",
    "status": "connected"
  }
}
```

---

### 2. Player Joined Lobby

**Type**: `player_joined`

**Payload**:
```json
{
  "type": "player_joined",
  "timestamp": 1704067200000,
  "data": {
    "players": [
      {
        "playerId": 1,
        "name": "Alice",
        "isReady": false,
        "health": 100
      },
      {
        "playerId": 2,
        "name": "Bob",
        "isReady": false,
        "health": 100
      }
    ],
    "playerCount": 2,
    "maxPlayers": 8
  }
}
```

---

### 3. All Players Ready

**Type**: `players_ready`

**Payload**:
```json
{
  "type": "players_ready",
  "timestamp": 1704067200000,
  "data": {
    "message": "All players ready! Game starting...",
    "countdownSeconds": 3
  }
}
```

---

### 4. Game Started

**Type**: `game_start`

**Payload**:
```json
{
  "type": "game_start",
  "timestamp": 1704067200000,
  "data": {
    "gameId": "game_abc123",
    "boardWidth": 10,
    "boardHeight": 10,
    "turnNumber": 1,
    "phase": "card_selection",
    "robots": [
      {
        "playerId": 1,
        "name": "Alice",
        "position": { "q": 0, "r": 0 },
        "health": 100,
        "direction": 0
      },
      {
        "playerId": 2,
        "name": "Bob",
        "position": { "q": 9, "r": 9 },
        "health": 100,
        "direction": 3
      }
    ],
    "availableCards": [
      { "id": 1, "name": "Move Forward", "instruction": "move", "icon": "🔼" },
      { "id": 2, "name": "Turn Left", "instruction": "turn_left", "icon": "↶" },
      { "id": 3, "name": "Turn Right", "instruction": "turn_right", "icon": "↷" },
      { "id": 4, "name": "Attack", "instruction": "attack", "icon": "💥" }
    ],
    "turnTimeoutSeconds": 30
  }
}
```

---

### 5. Turn Accepted

**Type**: `turn_accepted`

**Payload**:
```json
{
  "type": "turn_accepted",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 1,
    "turnNumber": 5,
    "message": "Your turn submitted! Waiting for others..."
  }
}
```

---

### 6. Game State Update (Broadcast)

**Type**: `game_state_update`

**Payload**:
```json
{
  "type": "game_state_update",
  "timestamp": 1704067200000,
  "data": {
    "turnNumber": 5,
    "phase": "executing",
    "robots": [
      {
        "playerId": 1,
        "name": "Alice",
        "position": { "q": 1, "r": 0 },
        "health": 90,
        "direction": 0,
        "status": "alive"
      },
      {
        "playerId": 2,
        "name": "Bob",
        "position": { "q": 8, "r": 8 },
        "health": 85,
        "direction": 3,
        "status": "alive"
      }
    ],
    "events": [
      {
        "playerId": 1,
        "type": "move",
        "from": { "q": 0, "r": 0 },
        "to": { "q": 1, "r": 0 },
        "instruction": 1
      },
      {
        "playerId": 2,
        "type": "move",
        "from": { "q": 9, "r": 9 },
        "to": { "q": 8, "r": 8 },
        "instruction": 1
      },
      {
        "playerId": 1,
        "type": "attack",
        "target": 2,
        "damage": 15,
        "hit": false,
        "instruction": 4
      }
    ],
    "currentPhase": "card_selection",
    "nextTurnTimeout": 30
  }
}
```

---

### 7. Game Over

**Type**: `game_over`

**Payload**:
```json
{
  "type": "game_over",
  "timestamp": 1704067200000,
  "data": {
    "winner": {
      "playerId": 1,
      "name": "Alice",
      "health": 45
    },
    "finalRanking": [
      { "rank": 1, "playerId": 1, "name": "Alice", "health": 45 },
      { "rank": 2, "playerId": 2, "name": "Bob", "health": 0 }
    ],
    "totalTurns": 12,
    "gameDuration": 300
  }
}
```

---

### 8. Player Left

**Type**: `player_left`

**Payload**:
```json
{
  "type": "player_left",
  "timestamp": 1704067200000,
  "data": {
    "playerId": 2,
    "name": "Bob",
    "remainingPlayers": 1,
    "message": "Bob disconnected. Game will end if fewer than 2 players remain."
  }
}
```

---

### 9. Error Message

**Type**: `error`

**Payload**:
```json
{
  "type": "error",
  "timestamp": 1704067200000,
  "data": {
    "code": "INVALID_TURN",
    "message": "Turn number mismatch. Expected 5, got 3.",
    "severity": "error"
  }
}
```

**Common Error Codes**:
- `GAME_FULL`: Game has reached max players
- `INVALID_NAME`: Player name is empty or too long
- `INVALID_TURN`: Wrong turn number submitted
- `INVALID_CARDS`: Cards don't exist or invalid selection
- `DUPLICATE_CARDS`: Same card selected twice
- `PLAYER_NOT_FOUND`: Player ID doesn't exist
- `UNAUTHORIZED`: Player not authenticated
- `SERVER_ERROR`: Internal server error

---

### 10. Ping / Heartbeat

**Type**: `ping`

**Payload** (sent by server):
```json
{
  "type": "ping",
  "timestamp": 1704067200000,
  "data": {}
}
```

**Response** (client sends back):
```json
{
  "type": "pong",
  "timestamp": 1704067200000,
  "data": {}
}
```

**Purpose**: Keep-alive mechanism to detect disconnects

---

## State Transitions

```
LOBBY:
  join → JOINED
  
JOINED:
  ready → READY
  
READY (all players ready):
  → GAME_START → CARD_SELECTION
  
CARD_SELECTION:
  turn_submit → AWAITING_OTHER_PLAYERS
  
AWAITING_OTHER_PLAYERS:
  all players submitted → EXECUTING → CARD_SELECTION (next turn)
  
CARD_SELECTION or EXECUTING:
  player eliminated → check win condition
  
WIN_CONDITION_MET:
  → GAME_OVER
  
GAME_OVER:
  (game can be reset to LOBBY for next match)
```

---

## Rate Limiting

- **Per-player message rate**: Max 10 messages/second
- **Duplicate messages**: Ignored if same message sent within 100ms
- **Turn submission**: Only one per turn allowed

---

## Implementation Notes

### Client (Vue 3)
```javascript
// Example connection setup
const ws = new WebSocket('ws://localhost:8080')

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'join',
    timestamp: Date.now(),
    data: { playerName: 'Alice' }
  }))
}

ws.onmessage = (event) => {
  const message = JSON.parse(event.data)
  handleMessage(message)
}
```

### Server (Godot GDScript)
```gdscript
# Example message handling
func _on_message_received(message_json: String):
  var message = JSON.parse_string(message_json)
  match message['type']:
    'join':
      handle_join(message['data'])
    'turn_submit':
      handle_turn_submit(message['data'])
    # ... etc
```

---

## Testing the API

### Using websocat
```bash
# Install: cargo install websocat

# Connect to server
websocat ws://localhost:8080

# Send message (paste and press Enter)
{"type":"join","timestamp":1704067200000,"data":{"playerName":"TestPlayer"}}
```

### Using curl (for HTTP endpoints if added)
```bash
curl -X POST http://localhost:8080/api/game/state
```

