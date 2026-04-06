extends Node3D

class_name GameBoard3D

## Emitted after all round animations have fully played out.
## MessageHandler listens to this to send round_ready to clients.
signal round_display_complete

var game_manager: GameManager
var game_over_panel: GameOverPanel = null  # set by main.gd after both are created
var _renderer: HexGridRenderer
var _robot_visuals: Dictionary = {}  # player_id -> RobotVisual

# --- Setup ---

## Call once from main.gd after game_manager and turn_manager are ready.
func setup(gm: GameManager, tm: TurnManager) -> void:
	game_manager = gm
	_renderer = HexGridRenderer.new()
	add_child(_renderer)
	_renderer.generate(gm.grid)
	gm.player_joined.connect(_on_player_joined)
	gm.player_left.connect(_on_player_left)
	gm.game_started.connect(_on_game_restarted)
	tm.turn_executed.connect(_on_turn_executed)

# --- Signal handlers ---

func _on_player_joined(player_id: int, player_name: String) -> void:
	if player_id in _robot_visuals:
		return
	var robot: Robot = game_manager.robots.get(player_id)
	var color: Color = Color.html(robot.color) if robot else ColorPalette.color_for(player_id - 1)
	var visual := RobotVisual.new()
	add_child(visual)
	visual.setup(player_id, player_name, color)
	if robot:
		visual.move_to(_renderer.hex_to_robot_pos(robot.position.x, robot.position.y), false)
		visual.set_robot_direction(robot.direction)
		visual.update_health(robot.health, robot.max_health)
	_robot_visuals[player_id] = visual

func _on_player_left(player_id: int) -> void:
	if player_id in _robot_visuals:
		_robot_visuals[player_id].queue_free()
		_robot_visuals.erase(player_id)

## Called when the game restarts (rematch). Reset robot visuals and regenerate tiles.
func _on_game_restarted() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	_renderer.clear()
	_renderer.generate(game_manager.grid)
	for player_id in game_manager.robots.keys():
		var robot: Robot = game_manager.robots[player_id]
		var visual: RobotVisual = _robot_visuals.get(player_id)
		if not visual:
			continue
		visual.revive()
		visual.move_to(_renderer.hex_to_robot_pos(robot.position.x, robot.position.y), false)
		visual.set_robot_direction(robot.direction)
		visual.update_health(robot.health, robot.max_health)

func _on_turn_executed(events: Array) -> void:
	const MOVE_STEP    := 0.85
	const TURN_STEP    := 0.45
	const ATTACK_STEP  := 0.90
	const BLOCKED_STEP := 0.35
	const FALL_STEP    := 1.10

	for event in events:
		var pid: int = event.get("playerId", -1)
		var visual: RobotVisual = _robot_visuals.get(pid)
		if not visual:
			continue

		match int(event.get("type", -1)):

			Card.TYPE_MOVE:
				if event.get("fell", false):
					var fell_to: Vector2i = event.get("fell_to", Vector2i.ZERO)
					var edge_world := _renderer.hex_to_world(fell_to.x, fell_to.y)
					edge_world.y = HexGridRenderer.HEX_HEIGHT
					visual.fall_off(edge_world)
					await get_tree().create_timer(FALL_STEP).timeout
				elif event.get("pushed_off", false):
					var to: Vector2i         = event.get("to",          Vector2i.ZERO)
					var pushed_to: Vector2i  = event.get("pushed_to",   Vector2i.ZERO)
					var pushed_id: int       = event.get("pushed_id",   -1)
					var pushed_visual: RobotVisual = _robot_visuals.get(pushed_id)
					visual.move_to(_renderer.hex_to_robot_pos(to.x, to.y))
					if pushed_visual:
						var edge_world := _renderer.hex_to_world(pushed_to.x, pushed_to.y)
						edge_world.y = HexGridRenderer.HEX_HEIGHT
						pushed_visual.fall_off(edge_world)
					await get_tree().create_timer(FALL_STEP).timeout
				elif event.get("pushed", false):
					var to: Vector2i        = event.get("to",        Vector2i.ZERO)
					var pushed_to: Vector2i = event.get("pushed_to", Vector2i.ZERO)
					var pushed_id: int      = event.get("pushed_id", -1)
					var pushed_visual: RobotVisual = _robot_visuals.get(pushed_id)
					visual.move_to(_renderer.hex_to_robot_pos(to.x, to.y))
					if pushed_visual:
						pushed_visual.move_to(_renderer.hex_to_robot_pos(pushed_to.x, pushed_to.y))
					await get_tree().create_timer(MOVE_STEP).timeout
				elif event.get("slammed", false):
					visual.bump_blocked()
					var slammed_id: int = event.get("slammed_id", -1)
					var slammed_visual: RobotVisual = _robot_visuals.get(slammed_id)
					if slammed_visual:
						slammed_visual.flash_hit()
					await get_tree().create_timer(BLOCKED_STEP).timeout
				elif event.get("success", false):
					var to: Vector2i = event.get("to", Vector2i.ZERO)
					visual.move_to(_renderer.hex_to_robot_pos(to.x, to.y))
					await get_tree().create_timer(MOVE_STEP).timeout
				else:
					visual.bump_blocked()
					await get_tree().create_timer(BLOCKED_STEP).timeout

			Card.TYPE_RUSH:
				var steps: Array = event.get("steps", [])
				var s0: Dictionary = steps[0] if steps.size() > 0 else {}
				var s1: Dictionary = steps[1] if steps.size() > 1 else {}
				if s0.get("success", false) and s1.get("success", false):
					var final_to: Vector2i = s1.get("to", Vector2i.ZERO)
					visual.move_to(_renderer.hex_to_robot_pos(final_to.x, final_to.y), true, 1.10)
					await get_tree().create_timer(1.20).timeout
				elif s0.get("success", false) and s1.get("fell", false):
					var fell_to: Vector2i = s1.get("fell_to", Vector2i.ZERO)
					var edge_world := _renderer.hex_to_world(fell_to.x, fell_to.y)
					edge_world.y = HexGridRenderer.HEX_HEIGHT
					visual.move_to(edge_world, true, 1.10)
					await get_tree().create_timer(1.10).timeout
					visual.fall_off(edge_world)
					await get_tree().create_timer(FALL_STEP).timeout
				else:
					if s0.get("fell", false):
						var fell_to: Vector2i = s0.get("fell_to", Vector2i.ZERO)
						var edge_world := _renderer.hex_to_world(fell_to.x, fell_to.y)
						edge_world.y = HexGridRenderer.HEX_HEIGHT
						visual.fall_off(edge_world)
						await get_tree().create_timer(FALL_STEP).timeout
					elif s0.get("success", false):
						var to: Vector2i = s0.get("to", Vector2i.ZERO)
						visual.move_to(_renderer.hex_to_robot_pos(to.x, to.y))
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
							target_visual.explode()
						else:
							target_visual.flash_hit()
							if target_robot:
								target_visual.update_health(target_robot.health, target_robot.max_health)
					await get_tree().create_timer(ATTACK_STEP).timeout

			Card.TYPE_SHOOT:
				var hit_pos: Vector2i = event.get("hit_pos", Vector2i.ZERO)
				var target_world := _renderer.hex_to_world(hit_pos.x, hit_pos.y)
				visual.shoot_rocket(target_world)
				await get_tree().create_timer(0.35).timeout
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
					await get_tree().create_timer(0.50).timeout

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

	if game_manager.phase == GameManager.GamePhase.GAME_OVER and game_over_panel:
		await get_tree().create_timer(0.5).timeout
		game_over_panel.show_result()

	round_display_complete.emit()
