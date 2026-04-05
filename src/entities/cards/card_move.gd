extends Card

class_name CardMove

func _init() -> void:
	type_id     = TYPE_MOVE
	card_name   = "Move Forward"
	icon        = "🔼"
	description = "Move your robot one hex in the direction it's facing."

func execute(robot: Robot, grid: HexGrid, _all_robots: Dictionary) -> Dictionary:
	var from_pos := robot.position
	var success  := robot.move_forward(grid)
	var result   := {"type": type_id, "success": success}

	if success:
		result["message"] = "Moved forward"
		result["from"]    = from_pos
		result["to"]      = robot.position
	else:
		result["message"] = "Blocked — cannot move"

	return result
