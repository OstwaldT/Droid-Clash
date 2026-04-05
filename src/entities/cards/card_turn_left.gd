extends Card

class_name CardTurnLeft

func _init() -> void:
	type_id     = TYPE_TURN_LEFT
	card_name   = "Turn Left"
	icon        = "↺"
	description = "Rotate your robot 60° counter-clockwise."

func execute(robot: Robot, _grid: HexGrid, _all_robots: Dictionary) -> Dictionary:
	robot.turn_left()
	return {
		"type":          type_id,
		"success":       true,
		"message":       "Turned left",
		"new_direction": robot.direction,
	}
