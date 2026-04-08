extends Card

class_name CardMove

func _init() -> void:
	type_id     = TYPE_MOVE
	card_name   = "March"
	icon        = "🔼"
	description = "Move your robot one hex in the direction it's facing."

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var from_pos := robot.position
	var result := robot.move_forward(grid, all_robots, true)

	match result["result"]:
		"moved":
			return {
				"type":    type_id,
				"success": true,
				"message": "Moved forward",
				"from":    from_pos,
				"to":      robot.position,
			}
		"fell":
			var fell_pos := grid.get_neighbor_in_direction(from_pos, robot.direction)
			return {
				"type":    type_id,
				"success": false,
				"fell":    true,
				"message": "Fell off the grid",
				"from":    from_pos,
				"fell_to": fell_pos,
			}
		"pushed":
			return {
				"type":        type_id,
				"success":     true,
				"message":     "Pushed a robot",
				"from":        from_pos,
				"to":          robot.position,
				"pushed":      true,
				"pushed_id":   result["pushed_id"],
				"pushed_from": result["pushed_from"],
				"pushed_to":   result["pushed_to"],
			}
		"pushed_off":
			return {
				"type":        type_id,
				"success":     true,
				"message":     "Pushed robot off the edge",
				"from":        from_pos,
				"to":          robot.position,
				"pushed_off":  true,
				"pushed_id":   result["pushed_id"],
				"pushed_from": result["pushed_from"],
				"pushed_to":   result["pushed_to"],
			}
		"slammed":
			var slammed: Robot = all_robots.get(result["slammed_id"])
			return {
				"type":               type_id,
				"success":            false,
				"message":            "Slammed robot into obstacle",
				"slammed":            true,
				"slammed_id":         result["slammed_id"],
				"slam_damage":        result["slam_damage"],
				"slammed_health":     slammed.health if slammed else 0,
				"slammed_max_health": slammed.max_health if slammed else 100,
			}
		_:  # "blocked"
			return {
				"type":    type_id,
				"success": false,
				"message": "Blocked — cannot move",
			}
