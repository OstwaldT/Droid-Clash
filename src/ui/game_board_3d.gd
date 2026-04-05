extends Node3D

class_name GameBoard3D

## Hex tile geometry constants (flat-top orientation)
const HEX_SIZE: float = 1.2      # circumradius
const HEX_HEIGHT: float = 0.15   # tile thickness
const TILE_GAP: float = 0.03     # visual gap between tiles

## One color per player slot (up to 8 players)
const PLAYER_COLORS: Array = [
	Color(0.90, 0.20, 0.20),  # Red
	Color(0.20, 0.52, 0.92),  # Blue
	Color(0.20, 0.80, 0.30),  # Green
	Color(0.92, 0.72, 0.08),  # Yellow
	Color(0.72, 0.18, 0.92),  # Purple
	Color(0.95, 0.50, 0.08),  # Orange
	Color(0.08, 0.82, 0.82),  # Cyan
	Color(0.92, 0.38, 0.72),  # Pink
]

var game_manager: GameManager
var _robot_visuals: Dictionary = {}  # player_id -> RobotVisual

# --- Setup ---

## Call once from main.gd after game_manager and turn_manager are ready.
func setup(gm: GameManager, tm: TurnManager) -> void:
	game_manager = gm
	gm.player_joined.connect(_on_player_joined)
	gm.player_left.connect(_on_player_left)
	tm.turn_executed.connect(_on_turn_executed)
	_generate_hex_grid()

# --- Hex grid generation ---

func _generate_hex_grid() -> void:
	for hex in game_manager.grid.get_all_hexes():
		_spawn_hex_tile(hex.x, hex.y)

func _spawn_hex_tile(q: int, r: int) -> void:
	var tile := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = HEX_SIZE - TILE_GAP
	mesh.bottom_radius = HEX_SIZE - TILE_GAP
	mesh.height = HEX_HEIGHT
	mesh.radial_segments = 6
	tile.mesh = mesh

	var mat := StandardMaterial3D.new()
	# Subtle alternating shading for readability without looking busy
	var base: float = 0.22 if (q + r) % 2 == 0 else 0.30
	mat.albedo_color = Color(base, base + 0.04, base + 0.02)
	mat.roughness = 0.85
	tile.material_override = mat

	# Rotate 30° so the flat edge faces forward (flat-top orientation)
	tile.rotation_degrees.y = 30.0
	tile.position = hex_to_world(q, r)
	add_child(tile)

# --- Coordinate conversion (flat-top axial) ---

## Convert axial (q, r) to a world Vector3 at tile surface height.
func hex_to_world(q: int, r: int) -> Vector3:
	var x: float = HEX_SIZE * (3.0 / 2.0 * q)
	var z: float = HEX_SIZE * (sqrt(3.0) / 2.0 * q + sqrt(3.0) * r)
	return Vector3(x, 0.0, z)

## World position of robot standing on a tile (y = tile top surface).
func hex_to_robot_pos(q: int, r: int) -> Vector3:
	var pos := hex_to_world(q, r)
	pos.y = HEX_HEIGHT
	return pos

## Centre of the hex board in world space.
## For a symmetric hexagonal board the axial origin (0,0) is always the centre.
func get_grid_center() -> Vector3:
	return hex_to_world(0, 0)

# --- Signal handlers ---

func _on_player_joined(player_id: int, player_name: String) -> void:
	if player_id in _robot_visuals:
		return

	var robot: Robot = game_manager.robots.get(player_id)
	var color: Color = Color.html(robot.color) if robot else PLAYER_COLORS[(player_id - 1) % PLAYER_COLORS.size()]
	var visual := RobotVisual.new()
	add_child(visual)
	visual.setup(player_id, player_name, color)

	if robot:
		visual.move_to(hex_to_robot_pos(robot.position.x, robot.position.y), false)
		visual.set_robot_direction(robot.direction)
		visual.update_health(robot.health, robot.max_health)

	_robot_visuals[player_id] = visual

func _on_player_left(player_id: int) -> void:
	if player_id in _robot_visuals:
		_robot_visuals[player_id].queue_free()
		_robot_visuals.erase(player_id)

func _on_turn_executed(events: Array) -> void:
	# Step durations (seconds to wait after each event type)
	const MOVE_STEP    := 0.85   # move tween (0.75s) + gap
	const TURN_STEP    := 0.45   # rotation tween (0.28s) + gap
	const ATTACK_STEP  := 0.72   # lunge (0.14s) + retract (0.26s) + gap
	const BLOCKED_STEP := 0.35   # bump anim + gap
	const FALL_STEP    := 1.10   # slide (0.30s) + plummet (0.70s) + gap

	for event in events:
		var pid: int = event.get("playerId", -1)
		var visual: RobotVisual = _robot_visuals.get(pid)
		if not visual:
			continue

		match int(event.get("type", -1)):

			Card.TYPE_MOVE:
				if event.get("fell", false):
					var fell_to: Vector2i = event.get("fell_to", Vector2i.ZERO)
					var edge_world := hex_to_world(fell_to.x, fell_to.y)
					edge_world.y = HEX_HEIGHT
					visual.fall_off(edge_world)
					await get_tree().create_timer(FALL_STEP).timeout
				elif event.get("success", false):
					var to: Vector2i = event.get("to", Vector2i.ZERO)
					visual.move_to(hex_to_robot_pos(to.x, to.y))
					await get_tree().create_timer(MOVE_STEP).timeout
				else:
					visual.bump_blocked()
					await get_tree().create_timer(BLOCKED_STEP).timeout

			Card.TYPE_TURN_LEFT, \
			Card.TYPE_TURN_RIGHT:
				visual.set_robot_direction(event.get("new_direction", 0), true)
				await get_tree().create_timer(TURN_STEP).timeout

			Card.TYPE_ATTACK:
				visual.strike_forward()
				if event.get("success", false):
					var target_id: int = event.get("target", -1)
					var target_visual: RobotVisual = _robot_visuals.get(target_id)
					if target_visual:
						target_visual.flash_hit()
						# Update HP bar immediately so it drops when the hit lands
						var target_robot: Robot = game_manager.robots.get(target_id)
						if target_robot:
							target_visual.update_health(target_robot.health, target_robot.max_health)
				await get_tree().create_timer(ATTACK_STEP).timeout

	# Final sync: snap all visuals to authoritative post-round robot state
	for player_id in game_manager.robots.keys():
		var robot: Robot = game_manager.robots[player_id]
		var visual: RobotVisual = _robot_visuals.get(player_id)
		if not visual:
			continue
		visual.set_robot_direction(robot.direction)
		visual.update_health(robot.health, robot.max_health)
		if not robot.is_alive():
			visual.mark_dead()
