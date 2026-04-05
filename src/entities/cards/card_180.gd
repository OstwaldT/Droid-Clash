extends Card

class_name Card180

func _init() -> void:
	type_id     = TYPE_180
	card_name   = "180"
	icon        = "🔄"
	description = "Spin your robot 180 degrees."

func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var old_dir := robot.direction
	robot.direction = (robot.direction + 3) % 6
	return {
		"type":          type_id,
		"success":       true,
		"message":       "180 spin",
		"old_direction": old_dir,
		"new_direction": robot.direction,
	}
