extends Card

class_name CardSweep

const SWEEP_DAMAGE := 8

func _init() -> void:
	type_id     = TYPE_SWEEP
	card_name   = "Sweep"
	icon        = "◠"
	description = "Slash the 3 hexes in front of you for %d damage each." % SWEEP_DAMAGE

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	# Forward arc: forward, forward-left, forward-right
	var dirs := [
		robot.direction,
		(robot.direction + 1) % 6,
		(robot.direction - 1 + 6) % 6,
	]

	var arc_hexes: Array = []
	for d in dirs:
		var hex := grid.get_neighbor_in_direction(robot.position, d)
		if grid.is_valid(hex):
			arc_hexes.append(hex)

	var hit_targets: Array = []
	for d in dirs:
		var hex := grid.get_neighbor_in_direction(robot.position, d)
		for r: Robot in all_robots.values():
			if r != robot and r.is_alive() and r.position == hex:
				r.take_damage(SWEEP_DAMAGE)
				hit_targets.append({
					"target":            r.player_id,
					"target_health":     r.health,
					"target_max_health": r.max_health,
					"hit_pos":           hex,
				})

	if hit_targets.is_empty():
		return {
			"type":      type_id,
			"success":   false,
			"message":   "Sweep missed",
			"damage":    0,
			"hits":      [],
			"arc_hexes": arc_hexes,
		}

	return {
		"type":      type_id,
		"success":   true,
		"message":   "Swept %d target(s) for %d damage" % [hit_targets.size(), SWEEP_DAMAGE],
		"damage":    SWEEP_DAMAGE,
		"hits":      hit_targets,
		"arc_hexes": arc_hexes,
	}
