# Quick Reference: Development Phases

## Phase 1: Foundation & Architecture ✓ DOCUMENTED

### Key Files Created
- ✅ README.md - Project overview & quick start
- ✅ SETUP.md - Detailed environment setup
- ✅ ARCHITECTURE.md - System design & data flow
- ✅ API.md - Complete WebSocket protocol
- ✅ CONTRIBUTING.md - Code style & guidelines
- ✅ .copilotignore - Files to ignore
- ✅ plan.md - Development plan with 6 phases

### Remaining Phase 1 Tasks
- [ ] `setup-godot-structure` - Create src/ and scenes/ directories
- [ ] `setup-vue-project` - Initialize Vue 3 project with dependencies

---

## Phase 2: Core Game Logic

### Priority Order
1. `hexgrid-system` - Hex grid foundation
2. `robot-entity` - Robot state & behavior
3. `instruction-system` - Card execution
4. `game-manager` - Game state & transitions
5. `turn-manager` - Turn sequencing & combat

### Key Implementation Notes
- Use axial coordinates (q, r) for hex system
- Robot directions: 0-5 (clockwise from top)
- Instructions execute sequentially: move → turn → attack
- See ARCHITECTURE.md for hex math formulas

---

## Phase 3: Network & Communication

### Priority Order
1. `websocket-server` - Godot WebSocket listener on port 8080
2. `message-handler` - Route & validate incoming messages
3. `websocket-client` - Vue client connection & message handling

### Key Implementation Notes
- All messages are JSON with `{ type, timestamp, data }`
- Server broadcasts state to all clients
- Implement heartbeat/ping-pong for keep-alive
- See API.md for complete message specifications

---

## Phase 4: Browser Client UI

### Priority Order
1. `game-store` - Pinia store for shared state
2. `player-store` - Pinia store for player identity
3. `lobby-ui` - Player name & connect screen
4. `card-selection-ui` - Select 3 cards per turn
5. `hex-board-ui` - Hexagonal grid visualization
6. `game-ui` - HUD, logs, end-game screen

### Key Implementation Notes
- Use Tailwind CSS for styling (mobile-first)
- Use Composition API with `<script setup>`
- Hexboard: render hex tiles in SVG or Canvas
- Show real-time position updates from server

---

## Phase 5: Polish & Testing

### Testing Priority
1. `api-validation` - Test all WebSocket messages
2. `local-test-2player` - 2-player same-machine test
3. `local-test-mobile` - Mobile browser compatibility
4. `performance-test-8players` - Stress test with 8 players

### Polish Tasks
- Add turn timeout UI (countdown timer)
- Smooth robot movement animations
- Add attack feedback (visual/audio)
- Error recovery & reconnection logic
- Mobile touch optimizations

---

## Phase 6: Deployment & DevOps

### Tasks
1. `docker-setup` - Containerize Godot server
2. `ci-pipeline` - GitHub Actions for testing & building
3. Hosting strategy (AWS, Heroku, custom VPS)
4. Client hosting (Netlify, Vercel, or same server)

---

## Development Checklist

### Before Starting
- [ ] Clone repository
- [ ] Read `SETUP.md` and follow environment setup
- [ ] Read `ARCHITECTURE.md` for system overview
- [ ] Read `CONTRIBUTING.md` for code style

### During Development
- [ ] Create feature branch: `feature/task-name`
- [ ] Update corresponding todo status: `UPDATE todos SET status = 'in_progress' WHERE id = '...'`
- [ ] Follow code style guide (CONTRIBUTING.md)
- [ ] Write tests as you go
- [ ] Commit with descriptive messages

### Before Submitting PR
- [ ] Tests pass locally
- [ ] Code follows style guide
- [ ] No console.log() or debug code
- [ ] Documentation updated
- [ ] Update todo status: `UPDATE todos SET status = 'done' WHERE id = '...'`

---

## How to View Task Progress

### See all pending tasks
```sql
SELECT id, title FROM todos WHERE status = 'pending' ORDER BY id;
```

### See ready tasks (dependencies met)
```sql
SELECT t.id, t.title FROM todos t
WHERE t.status = 'pending'
AND NOT EXISTS (
  SELECT 1 FROM todo_deps td
  JOIN todos dep ON td.depends_on = dep.id
  WHERE td.todo_id = t.id AND dep.status != 'done'
)
ORDER BY t.id;
```

### See all in-progress tasks
```sql
SELECT id, title FROM todos WHERE status = 'in_progress' ORDER BY id;
```

### Mark task as done
```sql
UPDATE todos SET status = 'done' WHERE id = 'task-id';
```

---

## Key Technologies

| Component | Tech | Purpose |
|-----------|------|---------|
| Server | Godot 4.2 + GDScript | Game loop, WebSocket, entities |
| Client | Vue 3 + Vite | Browser UI, state management |
| State Mgmt | Pinia | Reactive state in Vue |
| Styling | Tailwind CSS | Mobile-first responsive design |
| Network | WebSocket | Real-time bidirectional communication |
| Build | Vite | Fast dev server, optimized bundles |

---

## Quick Commands

```bash
# Godot
# Open in editor (interactive)
godot --path .

# Run headless (for testing)
godot --headless --path .

# Vue dev server
cd browser-client
npm run dev

# Build Vue
npm run build

# Run tests
npm run test
```

---

## Important URLs (Local Dev)

- **Godot Server**: runs locally, no URL (command line)
- **Vue Dev Server**: http://localhost:5173
- **WebSocket**: ws://localhost:8080
- **Mobile Testing**: http://YOUR_IP:5173

---

## Questions? See These Files

| Question | See File |
|----------|----------|
| How do I set up the project? | `SETUP.md` |
| How does the system work? | `ARCHITECTURE.md` |
| What messages can I send? | `API.md` |
| What code style should I use? | `CONTRIBUTING.md` |
| What should I build next? | This file + SQL todo table |
| What's the overall plan? | `plan.md` |

