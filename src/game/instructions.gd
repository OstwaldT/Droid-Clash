extends Node

class_name Instructions

## Card instruction types and execution logic

enum InstructionType {
	MOVE,
	TURN_LEFT,
	TURN_RIGHT,
	ATTACK
}

const CARD_DEFINITIONS = {
	1: {"id": 1, "name": "Move Forward", "type": InstructionType.MOVE, "icon": "🔼"},
	2: {"id": 2, "name": "Turn Left", "type": InstructionType.TURN_LEFT, "icon": "↶"},
	3: {"id": 3, "name": "Turn Right", "type": InstructionType.TURN_RIGHT, "icon": "↷"},
	4: {"id": 4, "name": "Attack", "type": InstructionType.ATTACK, "icon": "💥"}
}

## Execute an instruction for a robot
func execute_instruction(instruction_id: int, robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var card = CARD_DEFINITIONS.get(instruction_id)
	if card == null:
		return {"success": false, "message": "Invalid card ID"}
	
	var result = {"success": true, "type": card["type"], "robot_id": robot.player_id}
	
	match card["type"]:
		InstructionType.MOVE:
			var from_pos := robot.position  # capture BEFORE the move mutates position
			result["success"] = robot.move_forward(grid)
			result["message"] = "Move forward" if result["success"] else "Cannot move - blocked"
			if result["success"]:
				result["from"] = from_pos
				result["to"] = robot.position
		
		InstructionType.TURN_LEFT:
			robot.turn_left()
			result["message"] = "Turn left"
			result["new_direction"] = robot.direction
		
		InstructionType.TURN_RIGHT:
			robot.turn_right()
			result["message"] = "Turn right"
			result["new_direction"] = robot.direction
		
		InstructionType.ATTACK:
			var attack_result = _execute_attack(robot, grid, all_robots)
			result["success"] = attack_result["hit"]
			result["message"] = attack_result["message"]
			result["damage"] = attack_result["damage"]
			if attack_result["hit"]:
				result["target"] = attack_result["target_id"]
	
	return result

## Execute attack instruction
func _execute_attack(attacker: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	var target_pos = grid.get_neighbor_in_direction(attacker.position, attacker.direction)
	
	# Find robot at target position
	var target = null
	for robot in all_robots.values():
		if robot.position == target_pos and robot.is_alive():
			target = robot
			break
	
	if target == null:
		return {
			"hit": false,
			"message": "No target in attack range",
			"damage": 0,
			"target_id": -1
		}
	
	var damage = 15  # Base damage
	target.take_damage(damage)
	
	return {
		"hit": true,
		"message": "Attack hit for %d damage" % damage,
		"damage": damage,
		"target_id": target.player_id
	}

## Get card definition by ID
func get_card(card_id: int) -> Dictionary:
	return CARD_DEFINITIONS.get(card_id, {})

## Get all available cards
func get_all_cards() -> Array:
	var cards: Array = []
	for card_data in CARD_DEFINITIONS.values():
		cards.append(card_data)
	return cards
