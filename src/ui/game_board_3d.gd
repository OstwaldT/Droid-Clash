extends Node3D

class_name GameBoard3D

## Emitted after all round animations have fully played out.
## MessageHandler listens to this to send round_ready to clients.
signal round_display_complete

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
var game_over_panel: GameOverPanel = null  # set by main.gd after both are created
var _robot_visuals: Dictionary = {}  # player_id -> RobotVisual
var _hex_tiles: Dictionary = {}      # Vector2i -> Node3D (for rematch regeneration)

# --- Setup ---

## Call once from main.gd after game_manager and turn_manager are ready.
func setup(gm: GameManager, tm: TurnManager) -> void:
	game_manager = gm
	gm.player_joined.connect(_on_player_joined)
	gm.player_left.connect(_on_player_left)
	gm.game_started.connect(_on_game_restarted)
	tm.turn_executed.connect(_on_turn_executed)
	_generate_hex_grid()

# --- Hex grid generation ---

func _generate_hex_grid() -> void:
	var grid: HexGrid = game_manager.grid
	for hex in grid.get_all_hexes():
		if grid.is_hole(hex):
			_spawn_pit_marker(hex.x, hex.y)
		elif grid.is_obstacle(hex):
			_spawn_wall_tile(hex.x, hex.y)
		else:
			_spawn_floor_tile(hex.x, hex.y)

## Regular walkable floor tile.
func _spawn_floor_tile(q: int, r: int) -> void:
	var tile := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = HEX_SIZE - TILE_GAP
	mesh.bottom_radius = HEX_SIZE - TILE_GAP
	mesh.height = HEX_HEIGHT
	mesh.radial_segments = 6
	tile.mesh = mesh

	var mat := StandardMaterial3D.new()
	var base: float = 0.22 if (q + r) % 2 == 0 else 0.30
	mat.albedo_color = Color(base, base + 0.04, base + 0.02)
	mat.roughness = 0.85
	tile.material_override = mat

	tile.rotation_degrees.y = 30.0
	tile.position = hex_to_world(q, r)
	add_child(tile)
	_hex_tiles[Vector2i(q, r)] = tile

## Tall wall/obstacle tile — blocks movement.
func _spawn_wall_tile(q: int, r: int) -> void:
	const WALL_H: float = 1.1
	var root := Node3D.new()
	root.position = hex_to_world(q, r)
	add_child(root)
	_hex_tiles[Vector2i(q, r)] = root

	# Base flush with floor
	var base_mesh := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = HEX_SIZE - TILE_GAP
	bmesh.bottom_radius = HEX_SIZE - TILE_GAP
	bmesh.height = HEX_HEIGHT
	bmesh.radial_segments = 6
	base_mesh.mesh = bmesh
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.10, 0.10, 0.13)
	bmat.roughness = 1.0
	base_mesh.material_override = bmat
	base_mesh.rotation_degrees.y = 30.0
	root.add_child(base_mesh)

	# Tall wall block sitting on top of the base
	var wall_mesh := MeshInstance3D.new()
	var wmesh := CylinderMesh.new()
	wmesh.top_radius = HEX_SIZE * 0.82 - TILE_GAP
	wmesh.bottom_radius = HEX_SIZE * 0.82 - TILE_GAP
	wmesh.height = WALL_H
	wmesh.radial_segments = 6
	wall_mesh.mesh = wmesh
	wall_mesh.rotation_degrees.y = 30.0
	wall_mesh.position.y = HEX_HEIGHT * 0.5 + WALL_H * 0.5
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.14, 0.13, 0.17)
	wmat.roughness = 0.92
	wmat.metallic = 0.12
	wall_mesh.material_override = wmat
	root.add_child(wall_mesh)

	# Glowing top cap — marks it clearly as a wall
	var cap_mesh := MeshInstance3D.new()
	var cmesh := CylinderMesh.new()
	cmesh.top_radius = HEX_SIZE * 0.82 - TILE_GAP
	cmesh.bottom_radius = HEX_SIZE * 0.82 - TILE_GAP
	cmesh.height = 0.04
	cmesh.radial_segments = 6
	cap_mesh.mesh = cmesh
	cap_mesh.rotation_degrees.y = 30.0
	cap_mesh.position.y = HEX_HEIGHT * 0.5 + WALL_H + 0.02
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.30, 0.28, 0.40)
	cmat.emission_enabled = true
	cmat.emission = Color(0.18, 0.15, 0.35)
	cmat.emission_energy_multiplier = 1.2
	cap_mesh.material_override = cmat
	root.add_child(cap_mesh)

## Dark pit marker shown where a hole tile would be.
func _spawn_pit_marker(q: int, r: int) -> void:
	var pit := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = HEX_SIZE * 0.85
	mesh.bottom_radius = HEX_SIZE * 0.75
	mesh.height = 0.06
	mesh.radial_segments = 6
	pit.mesh = mesh
	pit.rotation_degrees.y = 30.0
	pit.position = hex_to_world(q, r)
	pit.position.y = -0.22

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.01, 0.01)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.05, 0.0)
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 1.0
	pit.material_override = mat
	add_child(pit)
	_hex_tiles[Vector2i(q, r)] = pit

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

## Called when the game restarts (rematch). Reset all robot visuals to their
## new positions without re-creating them, and hide the game-over overlay.
func _on_game_restarted() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	# Tear down and regenerate tiles (map layout changes each rematch)
	for tile in _hex_tiles.values():
		tile.queue_free()
	_hex_tiles.clear()
	_generate_hex_grid()
	# Reposition robots
	for player_id in game_manager.robots.keys():
		var robot: Robot = game_manager.robots[player_id]
		var visual: RobotVisual = _robot_visuals.get(player_id)
		if not visual:
			continue
		visual.revive()
		visual.move_to(hex_to_robot_pos(robot.position.x, robot.position.y), false)
		visual.set_robot_direction(robot.direction)
		visual.update_health(robot.health, robot.max_health)

func _on_turn_executed(events: Array) -> void:
	# Step durations (seconds to wait after each event type)
	const MOVE_STEP    := 0.85   # move tween (0.75s) + gap
	const TURN_STEP    := 0.45   # rotation tween (0.28s) + gap
	const ATTACK_STEP  := 0.90   # lunge (0.14s) + retract (0.26s) + explosion gap
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
				elif event.get("pushed_off", false):
					# Pusher slides in; pushed robot falls off the edge simultaneously
					var to: Vector2i         = event.get("to",          Vector2i.ZERO)
					var pushed_to: Vector2i  = event.get("pushed_to",   Vector2i.ZERO)
					var pushed_id: int       = event.get("pushed_id",   -1)
					var pushed_visual: RobotVisual = _robot_visuals.get(pushed_id)
					visual.move_to(hex_to_robot_pos(to.x, to.y))
					if pushed_visual:
						var edge_world := hex_to_world(pushed_to.x, pushed_to.y)
						edge_world.y = HEX_HEIGHT
						pushed_visual.fall_off(edge_world)
					await get_tree().create_timer(FALL_STEP).timeout
				elif event.get("pushed", false):
					# Move both robots simultaneously
					var to: Vector2i        = event.get("to",        Vector2i.ZERO)
					var pushed_to: Vector2i = event.get("pushed_to", Vector2i.ZERO)
					var pushed_id: int      = event.get("pushed_id", -1)
					var pushed_visual: RobotVisual = _robot_visuals.get(pushed_id)
					visual.move_to(hex_to_robot_pos(to.x, to.y))
					if pushed_visual:
						pushed_visual.move_to(hex_to_robot_pos(pushed_to.x, pushed_to.y))
					await get_tree().create_timer(MOVE_STEP).timeout
				elif event.get("slammed", false):
					# Bump pusher, flash hit on slammed robot
					visual.bump_blocked()
					var slammed_id: int = event.get("slammed_id", -1)
					var slammed_visual: RobotVisual = _robot_visuals.get(slammed_id)
					if slammed_visual:
						slammed_visual.flash_hit()
					await get_tree().create_timer(BLOCKED_STEP).timeout
				elif event.get("success", false):
					var to: Vector2i = event.get("to", Vector2i.ZERO)
					visual.move_to(hex_to_robot_pos(to.x, to.y))
					await get_tree().create_timer(MOVE_STEP).timeout
				else:
					visual.bump_blocked()
					await get_tree().create_timer(BLOCKED_STEP).timeout

			Card.TYPE_RUSH:
				var steps: Array = event.get("steps", [])
				var s0: Dictionary = steps[0] if steps.size() > 0 else {}
				var s1: Dictionary = steps[1] if steps.size() > 1 else {}

				if s0.get("success", false) and s1.get("success", false):
					# Both hexes clear — one smooth glide over 2 hexes
					var final_to: Vector2i = s1.get("to", Vector2i.ZERO)
					visual.move_to(hex_to_robot_pos(final_to.x, final_to.y), true, 1.10)
					await get_tree().create_timer(1.20).timeout
				elif s0.get("success", false) and s1.get("fell", false):
					# First hex clear, second is a hole — glide smoothly to the edge then fall
					var fell_to: Vector2i = s1.get("fell_to", Vector2i.ZERO)
					var edge_world := hex_to_world(fell_to.x, fell_to.y)
					edge_world.y = HEX_HEIGHT
					visual.move_to(edge_world, true, 1.10)
					await get_tree().create_timer(1.10).timeout
					visual.fall_off(edge_world)
					await get_tree().create_timer(FALL_STEP).timeout
				else:
					# Partial or no movement — animate step by step
					if s0.get("fell", false):
						var fell_to: Vector2i = s0.get("fell_to", Vector2i.ZERO)
						var edge_world := hex_to_world(fell_to.x, fell_to.y)
						edge_world.y = HEX_HEIGHT
						visual.fall_off(edge_world)
						await get_tree().create_timer(FALL_STEP).timeout
					elif s0.get("success", false):
						var to: Vector2i = s0.get("to", Vector2i.ZERO)
						visual.move_to(hex_to_robot_pos(to.x, to.y))
						await get_tree().create_timer(MOVE_STEP).timeout
						visual.bump_blocked()
						await get_tree().create_timer(BLOCKED_STEP).timeout
					else:
						visual.bump_blocked()
						await get_tree().create_timer(BLOCKED_STEP).timeout

			Card.TYPE_TURN_LEFT, \
			Card.TYPE_TURN_RIGHT, \
			Card.TYPE_180:
				visual.set_robot_direction(event.get("new_direction", 0), true)
				await get_tree().create_timer(TURN_STEP).timeout

			Card.TYPE_ATTACK:
				visual.strike_forward()
				if event.get("success", false):
					var target_id: int = event.get("target", -1)
					var target_visual: RobotVisual = _robot_visuals.get(target_id)
					if target_visual:
						var target_robot: Robot = game_manager.robots.get(target_id)
						if target_robot and not target_robot.is_alive():
							# Killing blow — explode instead of flash
							target_visual.explode()
						else:
							target_visual.flash_hit()
							if target_robot:
								target_visual.update_health(target_robot.health, target_robot.max_health)
				await get_tree().create_timer(ATTACK_STEP).timeout

			Card.TYPE_SHOOT:
				var hit_pos: Vector2i = event.get("hit_pos", Vector2i.ZERO)
				var target_world := hex_to_world(hit_pos.x, hit_pos.y)
				visual.shoot_rocket(target_world)
				await get_tree().create_timer(0.35).timeout  # rocket flight time
				if event.get("success", false):
					var target_id: int = event.get("target", -1)
					var target_visual: RobotVisual = _robot_visuals.get(target_id)
					if target_visual:
						var target_robot: Robot = game_manager.robots.get(target_id)
						if target_robot and not target_robot.is_alive():
							target_visual.explode()
						else:
							target_visual.flash_hit()
							if target_robot:
								target_visual.update_health(target_robot.health, target_robot.max_health)
				await get_tree().create_timer(0.50).timeout  # impact + gap

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

	# Show game over overlay only after all animations have played out
	if game_manager.phase == GameManager.GamePhase.GAME_OVER and game_over_panel:
		await get_tree().create_timer(0.5).timeout  # brief pause before overlay
		game_over_panel.show_result()

	# Notify message_handler that animations are done — it will send round_ready to clients
	round_display_complete.emit()
