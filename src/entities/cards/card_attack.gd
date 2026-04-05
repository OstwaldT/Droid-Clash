extends Card

class_name CardAttack

const BASE_DAMAGE := 15

func _init() -> void:
	type_id     = TYPE_ATTACK
	card_name   = "Attack"
	icon        = "💥"
	description = "Deal %d damage to the robot directly in front of you." % BASE_DAMAGE

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var target_pos := grid.get_neighbor_in_direction(robot.position, robot.direction)

	var target: Robot = null
	for r in all_robots.values():
		if r.position == target_pos and r.is_alive():
			target = r
			break

	if target == null:
		return {
			"type":    type_id,
			"success": false,
			"message": "No target in range",
			"damage":  0,
		}

	target.take_damage(BASE_DAMAGE)
	return {
		"type":    type_id,
		"success": true,
		"message": "Hit %s for %d damage" % [target.bot_name, BASE_DAMAGE],
		"damage":  BASE_DAMAGE,
		"target":  target.player_id,
	}
