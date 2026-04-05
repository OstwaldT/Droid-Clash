# Droid-Clash: WebSocket API Reference

## Connection

**Endpoint**: `ws://<server-ip>:8080`  
**Local dev**: `ws://localhost:8080` (set `VITE_WS_URL=ws://localhost:8080`)

All messages are flat JSON objects — no wrapper envelope:
```json
{ "type": "message_type", "field1": ..., "field2": ... }
```

---

## Client → Server

### `join`
```json
{ "type": "join", "playerName": "Alice" }
```

**Errors**: `GAME_FULL`, `INVALID_NAME`, `DUPLICATE_NAME`

---

### `ready`
```json
{ "type": "ready" }
```

Game starts automatically when all joined players send `ready`.

---

### `turn_submit`
```json
{
  "type": "turn_submit",
  "playerId": "player_1",
  "turnNumber": 3,
  "cardIds": [12, 7, 19]
}
```

`cardIds` are **instance IDs** from the most recent `hand_update` — not card type IDs. Must be exactly 3 unique IDs from the player's current hand.

**Errors**: `PLAYER_NOT_FOUND`, `INVALID_TURN`, `INVALID_CARD`, `INVALID_CARDS`, `DUPLICATE_CARDS`

---

### `leave`
```json
{ "type": "leave" }
```

---

## Server → Client

### `connect` *(private — sent only to the joining client)*
```json
{
  "type": "connect",
  "playerId": "player_1",
  "color": "#e74c3c",
  "wsUrl": "ws://192.168.1.32:8080",
  "status": "connected"
}
```

`color` is a hex string assigned by the server based on join order. Store it in `playerStore`.

---

### `player_joined` *(broadcast)*
```json
{
  "type": "player_joined",
  "players": [
    { "playerId": "player_1", "name": "Alice", "color": "#e74c3c", "isReady": false, "health": 100 },
    { "playerId": "player_2", "name": "Bob",   "color": "#3498db", "isReady": false, "health": 100 }
  ],
  "playerCount": 2,
  "maxPlayers": 8
}
```

---

### `game_start` *(broadcast)*
```json
{
  "type": "game_start",
  "gameId": "game_abc123",
  "boardRadius": 4,
  "turnNumber": 1,
  "phase": "card_selection",
  "robots": [
    { "playerId": "player_1", "name": "Alice", "color": "#e74c3c",
      "position": { "q": -2, "r": -1 }, "health": 100, "direction": 0 },
    { "playerId": "player_2", "name": "Bob",   "color": "#3498db",
      "position": { "q": 2,  "r": 1  }, "health": 100, "direction": 3 }
  ],
  "turnTimeoutSeconds": 30,
  "playerStatuses": [
    { "playerId": "player_1", "status": "selecting" },
    { "playerId": "player_2", "status": "selecting" }
  ]
}
```

After `game_start`, each player immediately receives a private `hand_update` with their initial hand.

---

### `hand_update` *(private — sent only to the addressed player)*
```json
{
  "type": "hand_update",
  "hand": [
    { "id": 12, "typeId": 1, "name": "Move Forward", "icon": "🔼", "description": "Move one hex forward" },
    { "id": 7,  "typeId": 2, "name": "Turn Left",    "icon": "↶", "description": "Rotate 60° counter-clockwise" },
    { "id": 19, "typeId": 3, "name": "Turn Right",   "icon": "↷", "description": "Rotate 60° clockwise" },
    { "id": 3,  "typeId": 1, "name": "Move Forward", "icon": "🔼", "description": "Move one hex forward" },
    { "id": 21, "typeId": 4, "name": "Attack",       "icon": "💥", "description": "Deal 15 damage to robot directly ahead" },
    { "id": 8,  "typeId": 2, "name": "Turn Left",    "icon": "↶", "description": "Rotate 60° counter-clockwise" }
  ]
}
```

`id` is the **instance ID** — use this in `turn_submit.cardIds`. Multiple cards of the same type have different instance IDs.

**Timing**: sent to each player BEFORE the `game_state_update` broadcast so clients always have a valid hand when the UI re-enables.

---

### `turn_accepted` *(private)*
```json
{
  "type": "turn_accepted",
  "playerId": "player_1",
  "turnNumber": 3,
  "message": "Turn submitted! Waiting for other players..."
}
```

---

### `player_statuses_update` *(broadcast)*

Sent whenever any player's status changes (e.g., after each submission).

```json
{
  "type": "player_statuses_update",
  "playerStatuses": [
    { "playerId": "player_1", "status": "submitted" },
    { "playerId": "player_2", "status": "selecting" }
  ]
}
```

Status values: `"selecting"` · `"submitted"` · `"acting"`

---

### `game_state_update` *(broadcast)*

Sent after each round resolves.

```json
{
  "type": "game_state_update",
  "turnNumber": 4,
  "currentPhase": "card_selection",
  "robots": [
    { "playerId": "player_1", "name": "Alice", "color": "#e74c3c",
      "position": { "q": -1, "r": 0 }, "health": 85, "direction": 1, "status": "alive" },
    { "playerId": "player_2", "name": "Bob",   "color": "#3498db",
      "position": { "q": 2,  "r": 1 }, "health": 100, "direction": 3, "status": "alive" }
  ],
  "events": [
    {
      "playerId": "player_1", "instanceId": 12, "typeId": 1, "type": 1,
      "success": true, "message": "Moved forward",
      "from": { "q": -2, "r": 0 }, "to": { "q": -1, "r": 0 }
    },
    {
      "playerId": "player_2", "instanceId": 7, "typeId": 4, "type": 4,
      "success": true, "message": "Attack hit!",
      "damage": 15, "target": "player_1"
    },
    {
      "playerId": "player_1", "instanceId": 19, "typeId": 1, "type": 1,
      "success": false, "message": "Blocked by boundary"
    }
  ],
  "playerStatuses": [
    { "playerId": "player_1", "status": "selecting" },
    { "playerId": "player_2", "status": "selecting" }
  ]
}
```

**Event `type` field** is a card type ID integer (matches `Card.TYPE_*`):
- `1` = Move Forward
- `2` = Turn Left  
- `3` = Turn Right
- `4` = Attack

Additional event fields by type:

| Type | Extra fields |
|------|-------------|
| Move (success) | `from: {q,r}`, `to: {q,r}` |
| Move (blocked) | `success: false` only |
| Turn Left/Right | `new_direction: 0–5` |
| Attack (hit) | `target: playerId`, `damage: 15` |
| Attack (miss) | `success: false` |

---

### `game_over` *(broadcast)*
```json
{
  "type": "game_over",
  "winner": "player_1",
  "winnerName": "Alice",
  "finalPlayers": [
    { "playerId": "player_1", "name": "Alice", "health": 45 },
    { "playerId": "player_2", "name": "Bob",   "health": 0  }
  ]
}
```

---

### `error` *(private)*
```json
{
  "type": "error",
  "code": "INVALID_CARD",
  "message": "Card 12 not in your hand",
  "severity": "error"
}
```

**Error codes**:

| Code | Meaning |
|------|---------|
| `PLAYER_NOT_FOUND` | Player ID not recognized |
| `GAME_FULL` | Max players reached |
| `INVALID_NAME` | Name empty or too long |
| `DUPLICATE_NAME` | Name already taken |
| `ALREADY_SUBMITTED` | Turn already submitted this round |
| `INVALID_TURN` | `turnNumber` doesn't match server |
| `INVALID_CARD` | Instance ID not in player's current hand |
| `INVALID_CARDS` | Wrong number of cards |
| `DUPLICATE_CARDS` | Same instance ID submitted twice |

---

## Card Types Reference

| Type ID | Name | Icon | Effect |
|---------|------|------|--------|
| 1 | Move Forward | 🔼 | Move one hex in facing direction |
| 2 | Turn Left | ↶ | Rotate 60° CCW |
| 3 | Turn Right | ↷ | Rotate 60° CW |
| 4 | Attack | 💥 | Deal 15 damage to robot directly ahead |

**Deck composition per player**: 5× Move, 3× Turn Left, 3× Turn Right, 2× Attack = 13 cards total.

---

## Connection Flow

```
Client connects
  ← connect  (private: playerId, color)

Client sends join
  → join { playerName }
  ← player_joined (broadcast: full player list)

All players send ready
  → ready
  ← player_joined updates as each player readies

When all ready:
  ← game_start (broadcast: board, robots, playerStatuses)
  ← hand_update (private: 6-card hand with instance IDs)

Each turn:
  → turn_submit { playerId, turnNumber, cardIds: [instanceId×3] }
  ← turn_accepted (private)
  ← player_statuses_update (broadcast: someone submitted)

When all alive players submitted:
  [server executes round]
  ← hand_update (private, new hand for next turn) ← FIRST
  ← game_state_update (broadcast: events, new positions)
  (or ← game_over if ≤1 robot alive)
```

---

## Testing

```bash
# Using websocat
websocat ws://localhost:8080

# Join
{"type":"join","playerName":"TestPlayer"}
```

