# Droid-Clash: Quick Reference

## Running Locally

### Godot Server
Open this project in **Godot 4.2+** and press **F5**.

```
Initializing Droid-Clash Server...
WebSocket server listening on port 8080
```

### Browser Client
```bash
cd browser-client
npm install
npm run dev
# → http://localhost:5173
```

> **Local-only**: set `VITE_WS_URL=ws://localhost:8080` before `npm run dev`.  
> **LAN**: the dev default is `ws://192.168.1.32:8080` — change the IP in `websocket.js` or use the env var.

---

## Playing

1. Open `http://localhost:5173` on each player's device
2. Enter a name → **Join**
3. Click **Ready** — game starts when all players are ready
4. Each turn: select 3 cards from your 6-card hand, in the order you want them executed
5. Click **Submit Turn** — wait for all players, then watch the board
6. Last robot alive wins

---

## Game Rules Summary

| Rule | Detail |
|------|--------|
| Players | 2 – 8 |
| Board | Hexagonal, radius 4, 61 tiles |
| Hand size | 6 cards per turn |
| Cards to play | Pick exactly 3, in order |
| Deck | 13 cards (5 Move · 3 Turn Left · 3 Turn Right · 2 Attack) |
| Execution | All players' cards resolve in randomised player order |
| Attack | Hits robot directly ahead, 15 damage flat |
| Starting health | 100 HP |
| Win | Last robot standing |

---

## Card Types

| Type ID | Name | Icon | Effect |
|---------|------|------|--------|
| 1 | Move Forward | 🔼 | Move one hex in facing direction |
| 2 | Turn Left | ↶ | Rotate 60° counter-clockwise |
| 3 | Turn Right | ↷ | Rotate 60° clockwise |
| 4 | Attack | 💥 | Deal 15 damage to robot directly ahead |

---

## Common Commands

```bash
# Start Vue dev server
cd browser-client && npm run dev

# Production build
cd browser-client && npm run build

# Godot headless server (no display)
godot --headless --path .
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| WebSocket connection fails | Confirm Godot is running; check `lsof -i :8080` |
| Wrong IP in client | Set `VITE_WS_URL=ws://localhost:8080` or edit `websocket.js` |
| Cards not executing | All alive players must submit; check Godot console |
| `npm run dev` fails | Run `npm install` in `browser-client/` first |

---

## Key Files

| File | What it does |
|------|-------------|
| `src/main.gd` | Server entry point |
| `src/server/message_handler.gd` | WS message routing & validation |
| `src/game/game_manager.gd` | State machine, player management |
| `src/entities/cards/card_registry.gd` | Card factory, deck composition |
| `browser-client/src/api/websocket.js` | Client WS connection |
| `docs/API.md` | Full message protocol |
| `docs/ARCHITECTURE.md` | System design |

