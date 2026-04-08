extends Card

class_name CardSprint

func _init() -> void:
	type_id     = TYPE_SPRINT
	card_name   = "Sprint"
	icon        = "🦅"
	description = "Move your robot 2 hexes forward. Stops early if blocked or fallen."

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var steps: Array = []

	for _i in range(2):
		var from_pos := robot.position
		var result := robot.move_forward(grid, all_robots, false)

		match result["result"]:
			"moved":
				steps.append({
					"success": true,
					"from":    from_pos,
					"to":      robot.position,
				})
			"fell":
				var fell_pos := grid.get_neighbor_in_direction(from_pos, robot.direction)
				steps.append({
					"success": false,
					"fell":    true,
					"from":    from_pos,
					"fell_to": fell_pos,
				})
				break  # robot is gone — stop immediately
			_:  # "blocked"
				steps.append({
					"success": false,
					"message": "Blocked",
				})
				break  # no point trying again if blocked

	return {
		"type":    type_id,
		"success": steps.any(func(s): return s.get("success", false)),
		"message": "Rushed forward",
		"steps":   steps,
	}
