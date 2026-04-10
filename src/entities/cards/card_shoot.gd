extends Card

class_name CardShoot

const SHOOT_DAMAGE := 10
const SHOOT_RANGE  := 6

func _init() -> void:
	type_id     = TYPE_SHOOT
	card_name   = "Shoot"
	icon        = "🚀"
	description = "Fire a rocket up to %d hexes forward. Deals %d damage on hit." % [SHOOT_RANGE, SHOOT_DAMAGE]

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var check_pos := robot.position

	for _i in range(SHOOT_RANGE):
		var next_pos := grid.get_neighbor_in_direction(check_pos, robot.direction)

		# Rocket flies off the map edge — misses
		if not grid.is_valid(next_pos):
			break

		# Hole in the ground — rocket flies over it
		if not grid.has_tile(next_pos):
			check_pos = next_pos
			continue

		# Wall blocks the rocket
		if not grid.is_walkable(next_pos):
			break

		# Check for a robot at this tile
		for r: Robot in all_robots.values():
			if r.position == next_pos and r.is_alive() and r != robot:
				r.take_damage(SHOOT_DAMAGE)
				return {
					"type":              type_id,
					"success":           true,
					"message":           "Rocket hit %s for %d damage" % [r.bot_name, SHOOT_DAMAGE],
					"damage":            SHOOT_DAMAGE,
					"target":            r.player_id,
					"hit_pos":           next_pos,
					"target_health":     r.health,
					"target_max_health": r.max_health,
				}

		check_pos = next_pos  # advance — nothing hit this hex

	return {
		"type":    type_id,
		"success": false,
		"message": "Rocket missed",
		"damage":  0,
		"hit_pos": check_pos,
	}
