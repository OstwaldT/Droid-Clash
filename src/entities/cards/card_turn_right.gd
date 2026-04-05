extends Card

class_name CardTurnRight

func _init() -> void:
	type_id     = TYPE_TURN_RIGHT
	card_name   = "Turn Right"
	icon        = "↻"
	description = "Rotate your robot 60° clockwise."

func execute(robot: Robot, _grid: HexGrid, _all_robots: Dictionary) -> Dictionary:
	robot.turn_right()
	return {
		"type":          type_id,
		"success":       true,
		"message":       "Turned right",
		"new_direction": robot.direction,
	}
