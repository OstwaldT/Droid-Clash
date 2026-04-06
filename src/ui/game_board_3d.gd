extends Node3D

class_name GameBoard3D

## Emitted after all round animations have fully played out.
## MessageHandler listens to this to send round_ready to clients.
signal round_display_complete

var game_manager: GameManager
var game_over_panel: GameOverPanel = null  # set by main.gd after both are created
var _renderer: HexGridRenderer
var _orchestrator: RoundAnimationOrchestrator
var _robot_visuals: Dictionary = {}  # player_id -> RobotVisual

# --- Setup ---

## Call once from main.gd after game_manager and turn_manager are ready.
func setup(gm: GameManager, tm: TurnManager) -> void:
	game_manager = gm

	_renderer = HexGridRenderer.new()
	add_child(_renderer)
	_renderer.generate(gm.grid)

	_orchestrator = RoundAnimationOrchestrator.new()
	add_child(_orchestrator)
	_orchestrator.setup(_renderer, _robot_visuals, gm)

	gm.player_joined.connect(_on_player_joined)
	gm.player_left.connect(_on_player_left)
	gm.game_started.connect(_on_game_restarted)
	tm.turn_executed.connect(_on_turn_executed)

# --- Public helpers ---

func get_grid_center() -> Vector3:
	return _renderer.get_grid_center()

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

## Called on rematch — regenerate tiles and snap robots to new positions.
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
	await _orchestrator.play(events)
	if game_manager.phase == GameManager.GamePhase.GAME_OVER and game_over_panel:
		await get_tree().create_timer(0.5).timeout
		game_over_panel.show_result()
	round_display_complete.emit()
