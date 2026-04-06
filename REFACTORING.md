# Droid-Clash — Refactoring Roadmap

This file tracks structural improvements identified in April 2026.
Each item has a priority, a description, and the files affected.

---

## Priority 1 — ColorPalette singleton ✅
**Status:** Done

**Problem:** `PLAYER_COLORS` is defined three times, in different formats:
- `game_manager.gd` — hex strings (`"#e63333"`)
- `game_board_3d.gd` — `Color(r, g, b)` float literals
- `lobby_panel.gd` — `Color(r, g, b)` float literals

**Fix:** `src/config/color_palette.gd` — autoloaded singleton `ColorPalette`.
All callers use `ColorPalette.PLAYER_COLORS`.

---

## Priority 2 — CardValidator
**Status:** Pending

**Problem:** Card submission validation ("must pick exactly 3 unique cards") lives
in `MessageHandler`, which is a network layer. Game rules should live in the game layer.

**Fix:** `src/game/card_validator.gd` — static helper class.
`MessageHandler` calls `CardValidator.validate(cards, deck)` and only handles
the network response.

---

## Priority 3 — EventSerializer
**Status:** Pending

**Problem:** Network serialization (dict → JSON payload) is scattered across
`MessageHandler` and `Robot.to_dict()`. No single place owns the wire format.

**Fix:** `src/network/event_serializer.gd` — converts domain objects to
broadcast-ready dicts. MessageHandler becomes a thin router.

---

## Priority 4 — HexGridRenderer
**Status:** Pending

**Problem:** `GameBoard3D` (~406 lines) handles tile spawning, material creation,
animation orchestration, player lifecycle, and signal routing — 7 responsibilities.

**Fix:** Extract lines 44–199 (tile spawning, hex geometry, materials) into
`src/ui/hex_grid_renderer.gd`. `GameBoard3D` holds a reference and delegates.

---

## Priority 5 — RoundAnimationOrchestrator
**Status:** Pending

**Problem:** `_on_turn_executed()` in `GameBoard3D` is ~150 lines of sequential
animation logic mixed with game-state interpretation.

**Fix:** `src/ui/round_animation_orchestrator.gd` — takes a turn-event array and
runs the animation sequence. `GameBoard3D` just calls `orchestrator.play(events)`.

---

## Priority 6 — Remove dead code
**Status:** Pending

**Candidates:**
- `TurnManager.get_turn_events()` — always returns `[]`
- `TurnManager._check_timeout()` — always returns `false`
- `Robot.status` — redundant string, replaced by `is_alive()`

---

## Signal naming convention
All signals should use **past tense** (event already happened):
- ✅ `player_joined`, `game_started`, `game_ended`
- ❌ `round_starting` → should be `round_started`
- ❌ `turn_changed` → acceptable (state change), but consider `turn_advanced`
