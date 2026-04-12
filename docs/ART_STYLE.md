# Droid-Clash — Art Style Guide

## Direction: Voxel / Blocky Sci-Fi

The target aesthetic is **low-poly voxel** — chunky geometry, flat matte surfaces, strong
silhouettes, and a limited warm palette. Think Crossy Road / Minecraft meets a Robo-Rally
board game. Every element should look like it was built from cubes.

---

## Implementation phases

| # | Area | Status | Notes |
|---|------|--------|-------|
| 1 | Robot models | ✅ Done | Procedural BoxMesh droid; no external assets |
| 2 | Hex tiles | ✅ Done | Flat-matte, warm earthy palette, no glow ring |
| 3 | Wall obstacles | ✅ Done | 3-box voxel tower, warm gold cap |
| 4 | Effects | Pending | Cube projectile, uniform debris |
| 5 | Browser UI | Pending | Pixel font, flat card icons |

---

## 1 — Robot models (`src/ui/robot_visual_base.gd`)

**Before:** Kenney Space-Kit speeder GLBs — smooth curved aerospace shapes.

**After:** Procedural BoxMesh droid built in `_build_model()`:

```
Part         Size (x × y × z)     Position        Base grey
Body         0.50 × 0.30 × 0.38   (0, 0.20, 0)    1.00 (full player color)
Head         0.30 × 0.24 × 0.28   (0, 0.49, 0)    0.82 (slightly darker)
Left track   0.10 × 0.10 × 0.44   (−0.22, 0.05, 0) 0.55 (dark)
Right track  0.10 × 0.10 × 0.44   (+0.22, 0.05, 0) 0.55 (dark)
Antenna      0.04 × 0.15 × 0.04   (+0.10, 0.69, 0) 0.65 (mid)
Left eye     0.07 × 0.05 × 0.03   (−0.08, 0.49, 0.145)  emissive cyan (not tinted)
Right eye    0.07 × 0.05 × 0.03   (+0.08, 0.49, 0.145)  emissive cyan (not tinted)
```

Parts use a neutral grey base color stored on the **mesh material** (not override) so that
`_tint_meshes(color)` correctly multiplies each part's grey by the player color, producing
lighter/darker shades without any extra code.

Eyes are stored in a separate `_eyes_root` node (sibling of `_model_root`) so `_tint_meshes`
ignores them. They dim on `mark_dead()` and restore on `revive()`.

**Material values:** `roughness = 0.95`, `metallic = 0.05` — pure matte, no shine.

---

## 2 — Hex tiles (`src/ui/hex_grid_renderer.gd`)

**Changes:**
- Remove glowing blue edge ring (`ring` MeshInstance3D).
- Set tile material `roughness = 1.0`, `metallic = 0.0`.
- Optionally add `shading_mode = SHADING_MODE_UNSHADED` for fully flat look.
- Swap `FLOOR_TINTS` palette from cool dark steel to earthy/warm:

| Current | Voxel replacement |
|---------|-------------------|
| `#2E333D` cool dark steel | `#7A6A52` sandstone |
| `#293830` teal-grey | `#4A6741` mossy green |
| `#383028` warm gunmetal | `#5C4033` clay brown |
| `#292D3D` indigo-grey | `#3D4A5C` slate blue |
| `#333829` olive-grey | `#586645` fern |

---

## 3 — Wall obstacles (`src/ui/hex_grid_renderer.gd`)

**Before:** `scifi/glTF/Columns/Column_Hollow.gltf` — curved, high-detail.

**After:** 3-box voxel tower:
- Base slab: `0.80 × 0.15 × 0.80` at `y=0.08` — tinted with tile color
- Mid block: `0.60 × 0.50 × 0.60` at `y=0.40` — slightly lighter
- Top cap:   `0.50 × 0.18 × 0.50` at `y=0.74` — accent color

Remove `WALL_MODEL` constant. Remove `_spawn_wall_column_fallback` (no longer needed).

---

## 4 — Effects (`src/ui/robot_visual.gd`)

| Effect | Before | After |
|--------|--------|-------|
| Rocket projectile | `SphereMesh` (round) | `BoxMesh(0.10, 0.10, 0.16)` (cube bullet) |
| Explosion debris | `BoxMesh` random sizes | Uniform `0.12 × 0.12 × 0.12` cubes, count 10 |
| Spark particles | `SphereMesh` tiny spheres | Remove — cubes only |

---

## 5 — Browser UI (`browser-client/`)

**Font:** Replace with a pixel/monospace font.
- Add `Press Start 2P` (Google Fonts, free) to `browser-client/index.html`.
- Apply via Tailwind `font-['Press_Start_2P']` or a CSS class.

**Card icons:** Replace emoji with pixel-art icons from Kenney Game Icons pack (CC0).
- Download: `kenney.nl/assets/game-icons`

**Panel style:** Replace gradient backgrounds with flat solid-color panels, 2px solid border,
no border-radius (square corners reinforce the voxel feel).

---

## Color palette

```
Player colors (fixed 6):
  P1  #E84040  Red
  P2  #4080E8  Blue
  P3  #E8C840  Yellow
  P4  #40C860  Green
  P5  #A040E8  Purple
  P6  #E87840  Orange

UI accents:
  Background  #0F0F18  near-black
  Panel bg    #1A1A2E  dark navy
  Border      #3A3A5C  muted purple
  Text        #E8E8F0  off-white
  Highlight   #F0C050  warm gold
```
