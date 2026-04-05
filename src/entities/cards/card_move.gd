extends Card

class_name CardMove

func _init() -> void:
	type_id     = TYPE_MOVE
	card_name   = "Move Forward"
	icon        = "🔼"
	description = "Move your robot one hex in the direction it's facing."

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var from_pos := robot.position
	var move_result := robot.move_forward(grid, all_robots)

	match move_result:
		"moved":
			return {
				"type":    type_id,
				"success": true,
				"message": "Moved forward",
				"from":    from_pos,
				"to":      robot.position,
			}
		"fell":
			# Robot stepped off the grid — record the off-grid tile it fell onto
			var fell_pos := grid.get_neighbor_in_direction(from_pos, robot.direction)
			return {
				"type":    type_id,
				"success": false,
				"fell":    true,
				"message": "Fell off the grid",
				"from":    from_pos,
				"fell_to": fell_pos,
			}
		_:  # "blocked"
			return {
				"type":    type_id,
				"success": false,
				"message": "Blocked — cannot move",
			}
