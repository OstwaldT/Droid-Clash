extends Node

class_name RoundAnimationOrchestrator

## Plays back one round's worth of card-execution events as 3-D animations.
##
## Receives shared references to the renderer and robot-visual dict so it
## always sees the latest state without needing to be re-initialised.
##
## Usage:
##   await orchestrator.play(events)   # returns when all animations are done

const MOVE_STEP    := 0.85
const TURN_STEP    := 0.45
const ATTACK_STEP  := 0.90
const BLOCKED_STEP := 0.35
const FALL_STEP    := 1.10

var _renderer: HexGridRenderer
var _visuals: Dictionary   # player_id -> RobotVisual  (live ref from GameBoard3D)
var _game_manager: GameManager

func setup(renderer: HexGridRenderer, visuals: Dictionary, gm: GameManager) -> void:
	_renderer    = renderer
	_visuals     = visuals
	_game_manager = gm

## Animate every event in sequence. Awaitable — returns when the last timer fires.
func play(events: Array) -> void:
	for event in events:
		var pid: int = event.get("playerId", -1)
		var visual: RobotVisual = _visuals.get(pid)
		if not visual:
			continue

		match int(event.get("type", -1)):

			Card.TYPE_MOVE:
				await _play_move(visual, event)

			Card.TYPE_SPRINT:
				await _play_rush(visual, event)

			Card.TYPE_TURN_LEFT, \
			Card.TYPE_TURN_RIGHT, \
			Card.TYPE_180:
				visual.set_robot_direction(event.get("new_direction", 0), true)
				await get_tree().create_timer(TURN_STEP).timeout

			Card.TYPE_ATTACK:
				await _play_attack(visual, event)

			Card.TYPE_SHOOT:
				await _play_shoot(visual, event)

	_sync_all_visuals()

# --- Per-card-type helpers ---

func _play_move(visual: RobotVisual, event: Dictionary) -> void:
	if event.get("fell", false):
		var fell_to: Vector2i = event.get("fell_to", Vector2i.ZERO)
		var edge_world := _renderer.hex_to_world(fell_to.x, fell_to.y)
		edge_world.y = HexGridRenderer.HEX_HEIGHT
		visual.fall_off(edge_world)
		await get_tree().create_timer(FALL_STEP).timeout
	elif event.get("pushed_off", false):
		var to: Vector2i        = event.get("to",        Vector2i.ZERO)
		var pushed_to: Vector2i = event.get("pushed_to", Vector2i.ZERO)
		var pushed_id: int      = event.get("pushed_id", -1)
		var pushed_visual: RobotVisual = _visuals.get(pushed_id)
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
		var pushed_visual: RobotVisual = _visuals.get(pushed_id)
		visual.move_to(_renderer.hex_to_robot_pos(to.x, to.y))
		if pushed_visual:
			pushed_visual.move_to(_renderer.hex_to_robot_pos(pushed_to.x, pushed_to.y))
		await get_tree().create_timer(MOVE_STEP).timeout
	elif event.get("slammed", false):
		visual.bump_blocked()
		var slammed_id: int = event.get("slammed_id", -1)
		var slammed_visual: RobotVisual = _visuals.get(slammed_id)
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

func _play_rush(visual: RobotVisual, event: Dictionary) -> void:
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

func _play_attack(visual: RobotVisual, event: Dictionary) -> void:
	visual.strike_forward()
	if event.get("success", false):
		var target_id: int = event.get("target", -1)
		var target_visual: RobotVisual = _visuals.get(target_id)
		if target_visual:
			var target_robot: Robot = _game_manager.robots.get(target_id)
			if target_robot and not target_robot.is_alive():
				# Snap to correct tile before exploding so drift doesn't make it
				# look like the robot is sinking below the floor.
				target_visual.move_to(_renderer.hex_to_robot_pos(target_robot.position.x, target_robot.position.y), false)
				target_visual.explode()
			else:
				target_visual.flash_hit()
				if target_robot:
					target_visual.update_health(target_robot.health, target_robot.max_health)
	await get_tree().create_timer(ATTACK_STEP).timeout

func _play_shoot(visual: RobotVisual, event: Dictionary) -> void:
	var hit_pos: Vector2i = event.get("hit_pos", Vector2i.ZERO)
	var target_world := _renderer.hex_to_robot_pos(hit_pos.x, hit_pos.y)
	visual.shoot_rocket(target_world)
	await get_tree().create_timer(0.35).timeout
	if event.get("success", false):
		var target_id: int = event.get("target", -1)
		var target_visual: RobotVisual = _visuals.get(target_id)
		if target_visual:
			var target_robot: Robot = _game_manager.robots.get(target_id)
			if target_robot and not target_robot.is_alive():
				target_visual.move_to(_renderer.hex_to_robot_pos(target_robot.position.x, target_robot.position.y), false)
				target_visual.explode()
			else:
				target_visual.flash_hit()
				if target_robot:
					target_visual.update_health(target_robot.health, target_robot.max_health)
	await get_tree().create_timer(0.50).timeout

## Snap all visuals to the authoritative post-round robot state.
func _sync_all_visuals() -> void:
	for player_id in _game_manager.robots.keys():
		var robot: Robot = _game_manager.robots[player_id]
		var visual: RobotVisual = _visuals.get(player_id)
		if not visual:
			continue
		visual.set_robot_direction(robot.direction)
		visual.update_health(robot.health, robot.max_health)
		if not robot.is_alive():
			visual.mark_dead()
		else:
			# Hard-snap position to the authoritative tile so any positional
			# drift from tweens (e.g. strike_forward, timing edge-cases) is
			# corrected before the next round begins.
			visual.move_to(_renderer.hex_to_robot_pos(robot.position.x, robot.position.y), false)
