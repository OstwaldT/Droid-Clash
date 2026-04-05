# Droid-Clash

A multiplayer browser-based party game where players control robots/tanks on a hexagonal grid through card-based programming.

## Quick Start

### Prerequisites
- Godot 4.2+
- Node.js 18+ (for Vue 3 client)
- Git

### Setup

1. **Godot Server**
   ```bash
   # Open this folder in Godot 4.2
   # The server will run on localhost:8080 (WebSocket)
   ```

2. **Browser Client**
   ```bash
   cd browser-client
   npm install
   npm run dev
   # Client runs on http://localhost:5173
   ```

3. **Connect**
   - Open browser to `http://localhost:5173`
   - Enter player name
   - Godot server will send `ws://localhost:8080` connection

## Game Rules

- **2-8 Players**: Each player controls one robot
- **Turn-Based**: Each turn, select 3 instruction cards
- **Instructions**: Move forward, turn left, turn right, attack
- **Win Condition**: Last robot standing wins
- **Hexagonal Grid**: 10x10 grid for movement & combat

## Project Structure

```
Droid-Clash/
├── godot/                    # Godot 4.2 server code
│   ├── src/
│   │   ├── server/          # WebSocket server implementation
│   │   ├── game/            # Game logic & state
│   │   └── entities/        # Robot, hexgrid, etc.
│   └── scenes/
├── browser-client/          # Vue 3 browser client
│   ├── src/
│   │   ├── components/      # Vue components
│   │   ├── stores/          # Pinia state management
│   │   └── api/             # WebSocket client
│   └── package.json
└── docs/                    # Documentation
```

## Development

### Code Style
- **Godot**: GDScript (use existing Godot conventions)
- **Vue**: Composition API, script setup syntax
- **Formatting**: Prettier (Vue), GDScript linter in editor

### Running Tests
```bash
# Godot tests
godot --headless --test

# Vue tests
cd browser-client
npm run test
```

### Building for Production
```bash
# Godot export
godot --export-release Linux build/server

# Vue build
cd browser-client
npm run build
```

## Documentation

- **[SETUP.md](docs/SETUP.md)** - Detailed environment setup
- **[API.md](docs/API.md)** - WebSocket message protocol
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design & data flow

## Contributing

1. Create feature branch from `main`
2. Follow code style guides (see above)
3. Test locally before pushing
4. Submit PR with description

## License

MIT (update as needed)
