# Droid-Clash Development Setup Guide

## Environment Setup

### 1. Godot Server Setup

#### Prerequisites
- Godot 4.2+ (download from https://godotengine.org)
- GDScript extensions for your editor (VS Code: godottools)

#### Initialize Godot Project
```bash
# The Godot project is already initialized in this folder
# Open Godot and select this folder as the project
```

**Project Structure to Create:**
```
godot/
├── src/
│   ├── server/
│   │   ├── websocket_server.gd       # WebSocket listener
│   │   └── message_handler.gd        # Message processing
│   ├── game/
│   │   ├── game_manager.gd           # Game state & loop
│   │   ├── game_state.gd             # State definitions
│   │   └── turn_manager.gd           # Turn sequencing
│   └── entities/
│       ├── hexgrid.gd                # Hex grid logic
│       ├── robot.gd                  # Robot entity
│       └── instructions.gd           # Card instructions
└── scenes/
    ├── main.tscn                     # Main server scene
    └── hex_grid.tscn                 # Grid visualization
```

#### Key Configuration (project.godot)
```ini
[application]
run/main_scene="res://scenes/main.tscn"

[network]
websocket/timeout_ms=5000

[debug]
gdscript/warnings/unused_variable=warn
```

### 2. Browser Client Setup

#### Prerequisites
- Node.js 18+ (download from https://nodejs.org)
- npm (comes with Node.js)

#### Create Vue 3 Project
```bash
# From project root
npm create vite@latest browser-client -- --template vue
cd browser-client
npm install

# Install additional dependencies
npm install tailwindcss postcss autoprefixer pinia axios
npx tailwindcss init -p
```

**Project Structure:**
```
browser-client/
├── src/
│   ├── components/
│   │   ├── CardSelection.vue        # Card picker UI
│   │   ├── HexBoard.vue             # Board display
│   │   ├── LobbyScreen.vue          # Player setup
│   │   └── GameUI.vue               # HUD & status
│   ├── stores/
│   │   ├── gameStore.js             # Pinia state
│   │   └── playerStore.js           # Player data
│   ├── api/
│   │   └── websocket.js             # WebSocket client
│   ├── App.vue
│   └── main.js
├── public/
├── package.json
├── vite.config.js
├── tailwind.config.js
└── postcss.config.js
```

#### Configure Vite (vite.config.js)
```javascript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5173,
    strictPort: false
  }
})
```

### 3. Network Configuration

#### Godot WebSocket Server
- **Bind Address**: `localhost` (127.0.0.1)
- **Port**: `8080`
- **Protocol**: WebSocket (ws://)
- **SSL**: Not required for local dev (wss:// for production)

#### Vue 3 Client Connection
```javascript
// browser-client/src/api/websocket.js
const WS_URL = import.meta.env.DEV 
  ? 'ws://localhost:8080'
  : process.env.VITE_WS_URL
```

#### Message Format
All WebSocket messages are JSON:
```json
{
  "type": "message_type",
  "timestamp": 1234567890,
  "data": { }
}
```

See [API.md](API.md) for complete message specification.

### 4. Development Workflow

#### Terminal 1: Start Godot Server
```bash
# Run Godot from command line (headless mode in CI, GUI for dev)
godot --path . --scene scenes/main.tscn
# Or open Godot IDE and hit Play
```

#### Terminal 2: Start Vue Dev Server
```bash
cd browser-client
npm run dev
```

#### Terminal 3: Optional - Monitor Logs
```bash
# Watch Godot output
tail -f ~/.godot/editor_output.log

# Or use Godot's debug panel (View > Debug)
```

### 5. Testing Locally

#### Single Player Test
1. Open browser to `http://localhost:5173`
2. Enter player name
3. Watch as client connects to WebSocket server
4. Verify connection message in Godot console

#### Multi-Player Test (Same Machine)
1. Open 2+ browser tabs/windows to `http://localhost:5173`
2. Enter different names in each
3. Godot server should show all connections
4. Start game in Godot; clients should sync

#### Mobile Testing
```bash
# Get your machine's local IP
ipconfig getifaddr en0  # macOS/Linux
# or
ipconfig  # Windows (find IPv4 address)

# Open on mobile: http://YOUR_IP:5173
```

### 6. Code Style & Linting

#### Godot (GDScript)
```bash
# Use Godot's built-in linter
# Set in Editor → Editor Layout → Output for warnings/errors
```

#### Vue 3
```bash
cd browser-client
npm install --save-dev eslint prettier
npm run lint
npm run format
```

### 7. Build for Production

#### Godot Server Export
```bash
# Set up export templates in Godot
godot --export-release "Linux Server" builds/server.x86_64

# For different platforms:
godot --export-release "Windows Desktop" builds/server.exe
godot --export-release "macOS" builds/server.app
```

#### Vue 3 Client Build
```bash
cd browser-client
npm run build
# Output: dist/ folder (ready for hosting)
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| WebSocket connection refused | Ensure Godot server is running on port 8080 |
| CORS errors in browser | Not applicable for WebSocket; check WS_URL config |
| Vue components not updating | Check Pinia store setup & message handlers |
| Grid rendering issues | Verify hex coordinates system & canvas size |

### Next Steps

1. Read [ARCHITECTURE.md](ARCHITECTURE.md) for system design
2. Review [API.md](API.md) for message protocol
3. Start with Phase 1 tasks from [../plan.md](../plan.md)
