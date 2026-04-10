extends Card

class_name CardStrafeRight

func _init() -> void:
	type_id     = TYPE_STRAFE_RIGHT
	card_name   = "Strafe Right"
	icon        = "➡"
	description = "Sidestep one hex to the right without turning."

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var from_pos := robot.position
	var strafe_dir := (robot.direction - 1 + 6) % 6
	var target_pos := grid.get_neighbor_in_direction(from_pos, strafe_dir)

	if not grid.is_valid(target_pos) or not grid.has_tile(target_pos):
		robot.take_damage(robot.max_health)
		return {
			"type":    type_id,
			"success": false,
			"fell":    true,
			"message": "Strafed off the edge",
			"from":    from_pos,
			"fell_to": target_pos,
		}

	if not grid.is_walkable(target_pos):
		return {
			"type":    type_id,
			"success": false,
			"message": "Blocked — cannot strafe",
		}

	for other in all_robots.values():
		if other != robot and other.is_alive() and other.position == target_pos:
			return {
				"type":    type_id,
				"success": false,
				"message": "Blocked by %s" % other.bot_name,
			}

	robot.position = target_pos
	return {
		"type":    type_id,
		"success": true,
		"message": "Strafed right",
		"from":    from_pos,
		"to":      robot.position,
	}
