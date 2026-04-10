extends Card

class_name CardSlam

const SLAM_DAMAGE := 6

func _init() -> void:
	type_id     = TYPE_SLAM
	card_name   = "Slam"
	icon        = "⬡"
	description = "Smash all 6 adjacent hexes for %d damage each." % SLAM_DAMAGE

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var hit_targets: Array = []

	for d in range(6):
		var hex := grid.get_neighbor_in_direction(robot.position, d)
		for r: Robot in all_robots.values():
			if r != robot and r.is_alive() and r.position == hex:
				r.take_damage(SLAM_DAMAGE)
				hit_targets.append({
					"target":            r.player_id,
					"target_health":     r.health,
					"target_max_health": r.max_health,
					"hit_pos":           hex,
				})

	if hit_targets.is_empty():
		return {
			"type":    type_id,
			"success": false,
			"message": "Slam — no targets nearby",
			"damage":  0,
			"hits":    [],
		}

	return {
		"type":    type_id,
		"success": true,
		"message": "Slammed %d target(s) for %d damage" % [hit_targets.size(), SLAM_DAMAGE],
		"damage":  SLAM_DAMAGE,
		"hits":    hit_targets,
	}
