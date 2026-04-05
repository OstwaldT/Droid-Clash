# Droid-Clash: Setup Guide

## Prerequisites

| Tool | Minimum version | Download |
|------|----------------|---------|
| Godot | 4.2 | https://godotengine.org |
| Node.js | 18 | https://nodejs.org |

---

## 1. Godot Server

1. Open Godot 4.2+
2. **Import Project** → select this folder
3. Press **F5** (or the ▶ Play button)

The game window opens with the 3D board and the console prints:
```
Initializing Droid-Clash Server...
WebSocket server listening on port 8080
Server initialized and ready for connections
```

**Headless mode** (no window, e.g. CI):
```bash
godot --headless --path .
```

---

## 2. Browser Client

```bash
cd browser-client
npm install
npm run dev
# → http://localhost:5173
```

### WebSocket URL

The client connects to the Godot server via WebSocket. Configure the URL:

```bash
# Local-only testing
VITE_WS_URL=ws://localhost:8080 npm run dev

# LAN play (default dev fallback, edit websocket.js to match your IP)
# ws://192.168.1.32:8080
```

The URL is read in `browser-client/src/api/websocket.js`:
```javascript
const WS_URL = import.meta.env.VITE_WS_URL ?? 'ws://192.168.1.32:8080'
```

---

## 3. Multi-Player Testing

### Same machine (2+ browser tabs)
1. Start Godot server
2. Start Vue dev server (`npm run dev`)
3. Open `http://localhost:5173` in two or more tabs
4. Enter different names → Join → Ready in each tab

### LAN (phone/other devices)
1. Find your machine's LAN IP: `ipconfig getifaddr en0` (macOS)
2. Set `VITE_WS_URL=ws://<your-ip>:8080` in the dev command
3. On each device, open `http://<your-ip>:5173`

---

## 4. Production Build

### Godot server (headless export)
```bash
# Requires export templates installed in Godot
godot --export-release "Linux Server" builds/server.x86_64
```

### Vue client
```bash
cd browser-client
npm run build
# Output: browser-client/dist/  (static files, host anywhere)
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| WebSocket refused | Godot must be running first; check `lsof -i :8080` |
| Wrong IP / can't connect from phone | Set `VITE_WS_URL` to your LAN IP |
| `npm run dev` fails | Run `npm install` in `browser-client/` |
| Cards not executing | All alive players must submit; check Godot console output |
| GDScript type error at startup | Ensure Godot 4.2+ (not 3.x) |

---

## Editor Tips

- **VS Code + GDScript**: install the **godot-tools** extension
- **Godot built-in editor**: use the Script tab for `.gd` files; Output tab for runtime logs
- All GDScript files use `class_name` declarations — Godot's autocompletion works without manual imports
