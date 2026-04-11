extends Node

class_name RoundAnimationOrchestrator

## Plays back one round's worth of card-execution events as 3-D animations.
##
## Receives shared references to the renderer and robot-visual dict so it
## always sees the latest state without needing to be re-initialised.
##
## Usage:
##   await orchestrator.play(events)   # returns when all animations are done

const MOVE_STEP        := 0.85
const TURN_STEP        := 0.45
const ATTACK_STEP      := 0.90
const BLOCKED_STEP     := 0.35
const SWEEP_STEP       := 0.70
const SLAM_STEP        := 0.80
const SHOCKWAVE_STEP   := 0.65
const DISORIENT_STEP   := 1.05
const FALL_STEP      := RobotVisual.FALL_SLIDE_DURATION + RobotVisual.FALL_DROP_DURATION
const DROP_STEP      := RobotVisual.FALL_DROP_DURATION

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

			Card.TYPE_STRAFE_LEFT, \
			Card.TYPE_STRAFE_RIGHT:
				await _play_strafe(visual, event)

			Card.TYPE_SWEEP:
				await _play_sweep(visual, event)

			Card.TYPE_SLAM:
				await _play_slam(visual, event)

			Card.TYPE_SHOCKWAVE:
				await _play_shockwave(visual, event)

			Card.TYPE_DISORIENT:
				await _play_disorient(visual, event)

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
			slammed_visual.update_health(event.get("slammed_health", 0), event.get("slammed_max_health", 100))
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
		visual.fall_off(edge_world, false)
		await get_tree().create_timer(DROP_STEP).timeout
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
			var target_health: int     = event.get("target_health", 1)
			var target_max_hp: int     = event.get("target_max_health", 100)
			if target_health <= 0:
				var target_robot: Robot = _game_manager.robots.get(target_id)
				if target_robot:
					target_visual.move_to(_renderer.hex_to_robot_pos(target_robot.position.x, target_robot.position.y), false)
				target_visual.explode()
			else:
				target_visual.flash_hit()
				target_visual.update_health(target_health, target_max_hp)
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
			var target_health: int = event.get("target_health", 1)
			var target_max_hp: int = event.get("target_max_health", 100)
			if target_health <= 0:
				var target_robot: Robot = _game_manager.robots.get(target_id)
				if target_robot:
					target_visual.move_to(_renderer.hex_to_robot_pos(target_robot.position.x, target_robot.position.y), false)
				target_visual.explode()
			else:
				target_visual.flash_hit()
				target_visual.update_health(target_health, target_max_hp)
	elif event.get("hit_wall", false):
		var wall_world := _renderer.hex_to_world(hit_pos.x, hit_pos.y)
		wall_world.y = visual.position.y + 0.20
		visual.rocket_wall_hit(wall_world)
	await get_tree().create_timer(0.50).timeout

func _play_strafe(visual: RobotVisual, event: Dictionary) -> void:
	if event.get("fell", false):
		var fell_to: Vector2i = event.get("fell_to", Vector2i.ZERO)
		var edge_world := _renderer.hex_to_world(fell_to.x, fell_to.y)
		edge_world.y = HexGridRenderer.HEX_HEIGHT
		visual.fall_off(edge_world)
		await get_tree().create_timer(FALL_STEP).timeout
	elif event.get("success", false):
		var to: Vector2i = event.get("to", Vector2i.ZERO)
		visual.move_to(_renderer.hex_to_robot_pos(to.x, to.y))
		await get_tree().create_timer(MOVE_STEP).timeout
	else:
		visual.bump_blocked()
		await get_tree().create_timer(BLOCKED_STEP).timeout

func _play_sweep(visual: RobotVisual, event: Dictionary) -> void:
	visual.sweep_slash()
	var hits: Array = event.get("hits", [])
	var arc_hexes_raw: Array = event.get("arc_hexes", [])
	# Brief delay so the lunge lands before fire erupts
	await get_tree().create_timer(0.09).timeout
	if arc_hexes_raw.size() > 0:
		var arc_world: Array = []
		for h in arc_hexes_raw:
			arc_world.append(_renderer.hex_to_world(int(h.x), int(h.y)))
		visual.sweep_arc_fire(arc_world)
	for hit in hits:
		_apply_hit(hit)
	await get_tree().create_timer(SWEEP_STEP - 0.09).timeout

func _play_slam(visual: RobotVisual, event: Dictionary) -> void:
	visual.slam_pound()
	var hits: Array = event.get("hits", [])
	# Wait for the robot to land before applying effects (~0.25s)
	await get_tree().create_timer(0.25).timeout
	# Compute the 6 adjacent hex world positions and shake them
	var pid: int = event.get("playerId", -1)
	var robot: Robot = _game_manager.robots.get(pid)
	if robot:
		var shake_positions: Array = []
		for d in range(6):
			var adj := _game_manager.grid.get_neighbor_in_direction(robot.position, d)
			if _game_manager.grid.is_valid(adj) and _game_manager.grid.has_tile(adj):
				shake_positions.append(_renderer.hex_to_world(adj.x, adj.y))
		if shake_positions.size() > 0:
			visual.slam_ground_shake(shake_positions)
	for hit in hits:
		_apply_hit(hit)
	await get_tree().create_timer(SLAM_STEP - 0.25).timeout

func _play_shockwave(visual: RobotVisual, event: Dictionary) -> void:
	visual.pulse_shockwave()
	var pushes: Array = event.get("pushes", [])
	# Slight delay so the ring expands before targets react
	await get_tree().create_timer(0.15).timeout
	var any_fell := false
	for push in pushes:
		var target_id: int = push.get("target", -1)
		var target_visual: RobotVisual = _visuals.get(target_id)
		if not target_visual:
			continue
		if push.get("fell", false):
			var pushed_to: Vector2i = push.get("pushed_to", Vector2i.ZERO)
			var edge_world := _renderer.hex_to_world(pushed_to.x, pushed_to.y)
			edge_world.y = HexGridRenderer.HEX_HEIGHT
			target_visual.fall_off(edge_world)
			any_fell = true
		elif push.get("blocked", false):
			var wall_hex  = push.get("wall_hex", {"x": 0, "y": 0})
			var wall_world := _renderer.hex_to_world(wall_hex.x, wall_hex.y)
			wall_world.y = target_visual.position.y
			target_visual.wall_slam(wall_world)
			if push.get("wall_hit", false):
				target_visual.fire_ring()
			_apply_hit(push)
		else:
			var pushed_to: Vector2i = push.get("pushed_to", Vector2i.ZERO)
			target_visual.move_to(_renderer.hex_to_robot_pos(pushed_to.x, pushed_to.y))
	if any_fell:
		await get_tree().create_timer(FALL_STEP).timeout
	else:
		await get_tree().create_timer(SHOCKWAVE_STEP - 0.15).timeout

## Apply a hit from sweep/slam: flash the target and update its health.
func _apply_hit(hit: Dictionary) -> void:
	var target_id: int = hit.get("target", -1)
	var target_visual: RobotVisual = _visuals.get(target_id)
	if not target_visual:
		return
	var target_health: int = hit.get("target_health", 1)
	var target_max_hp: int = hit.get("target_max_health", 100)
	if target_health <= 0:
		var target_robot: Robot = _game_manager.robots.get(target_id)
		if target_robot:
			target_visual.move_to(_renderer.hex_to_robot_pos(target_robot.position.x, target_robot.position.y), false)
		target_visual.explode()
	else:
		target_visual.flash_hit()
		target_visual.update_health(target_health, target_max_hp)

## Disorient: projectile flies toward target hex; hit robot wobbles and turns.
func _play_disorient(visual: RobotVisual, event: Dictionary) -> void:
	var success: bool = event.get("success", false)
	var hit_pos_raw: Variant = event.get("hit_pos", {"x": 0, "y": 0})
	var hit_pos := Vector2i(int(hit_pos_raw.x), int(hit_pos_raw.y))
	var dest := _renderer.hex_to_robot_pos(hit_pos.x, hit_pos.y)
	visual.shoot_disorient(dest)
	await get_tree().create_timer(0.32).timeout
	if success:
		var target_id: int = event.get("target", -1)
		var target_vis: RobotVisual = _visuals.get(target_id)
		if target_vis:
			target_vis.disorient_wobble()
			await get_tree().create_timer(0.30).timeout
			var new_dir: int = event.get("new_direction", 0)
			target_vis.set_robot_direction(new_dir, true)
	elif event.get("hit_wall", false):
		var wall_world := _renderer.hex_to_world(hit_pos.x, hit_pos.y)
		wall_world.y = visual.position.y + 0.20
		visual.disorient_wall_hit(wall_world)
	await get_tree().create_timer(DISORIENT_STEP - 0.62).timeout

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
