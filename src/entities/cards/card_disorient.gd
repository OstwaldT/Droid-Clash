extends Card

class_name CardDisorient

const DISORIENT_RANGE := 3

func _init() -> void:
	type_id     = TYPE_DISORIENT
	card_name   = "Disorient"
	icon        = "↯"
	description = "Fire a disorienting pulse up to %d hexes. Hit robot turns randomly left or right." % DISORIENT_RANGE

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var check_pos := robot.position

	for _i in range(DISORIENT_RANGE):
		var next_pos := grid.get_neighbor_in_direction(check_pos, robot.direction)

		# Off the edge — pulse flies off the board
		if not grid.is_valid(next_pos):
			break

		# Hole — pulse flies over it
		if not grid.has_tile(next_pos):
			check_pos = next_pos
			continue

		# Wall blocks the pulse
		if not grid.is_walkable(next_pos):
			return {
				"type":     type_id,
				"success":  false,
				"message":  "Disorient pulse hit a wall",
				"hit_pos":  next_pos,
				"hit_wall": true,
			}

		# Check for a robot at this hex
		for r: Robot in all_robots.values():
			if r.position == next_pos and r.is_alive() and r != robot:
				var turned_left := randf() < 0.5
				if turned_left:
					r.turn_left()
				else:
					r.turn_right()
				return {
					"type":          type_id,
					"success":       true,
					"message":       "%s was disoriented" % r.bot_name,
					"target":        r.player_id,
					"hit_pos":       next_pos,
					"turned_left":   turned_left,
					"new_direction": r.direction,
				}

		check_pos = next_pos  # nothing here — advance

	return {
		"type":    type_id,
		"success": false,
		"message": "Disorient pulse missed",
		"hit_pos": check_pos,
	}
