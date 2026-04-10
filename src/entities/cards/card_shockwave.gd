extends Card

class_name CardShockwave

func _init() -> void:
	type_id     = TYPE_SHOCKWAVE
	card_name   = "Shockwave"
	icon        = "◎"
	description = "Push all adjacent robots 1 hex outward. No damage."

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var pushed_targets: Array = []

	for d in range(6):
		var hex := grid.get_neighbor_in_direction(robot.position, d)
		for r: Robot in all_robots.values():
			if r != robot and r.is_alive() and r.position == hex:
				var push_to := grid.get_neighbor_in_direction(hex, d)
				var pushed_from := r.position

				# Off edge or into a hole → target falls
				if not grid.is_valid(push_to) or not grid.has_tile(push_to):
					r.take_damage(r.max_health)
					r.position = push_to
					pushed_targets.append({
						"target":      r.player_id,
						"pushed_from": pushed_from,
						"pushed_to":   push_to,
						"fell":        true,
						"target_health":     r.health,
						"target_max_health": r.max_health,
					})
					continue

				# Wall or occupied → target stays put (no slam damage)
				var blocked := not grid.is_walkable(push_to)
				if not blocked:
					for other in all_robots.values():
						if other != robot and other != r and other.is_alive() and other.position == push_to:
							blocked = true
							break
				if blocked:
					pushed_targets.append({
						"target":      r.player_id,
						"pushed_from": pushed_from,
						"pushed_to":   pushed_from,
						"blocked":     true,
						"target_health":     r.health,
						"target_max_health": r.max_health,
					})
					continue

				# Successful push
				r.position = push_to
				pushed_targets.append({
					"target":      r.player_id,
					"pushed_from": pushed_from,
					"pushed_to":   push_to,
					"target_health":     r.health,
					"target_max_health": r.max_health,
				})

	if pushed_targets.is_empty():
		return {
			"type":    type_id,
			"success": false,
			"message": "Shockwave — no targets nearby",
			"pushes": [],
		}

	return {
		"type":    type_id,
		"success": true,
		"message": "Shockwave pushed %d target(s)" % pushed_targets.size(),
		"pushes": pushed_targets,
	}
