extends Node

class_name TurnManager

signal turn_executed
signal round_complete

var game_manager: GameManager
var grid: HexGrid
var instructions: Instructions
var card_submissions: Dictionary = {}  # player_id -> [card_ids]

func _init(manager: GameManager) -> void:
	game_manager = manager
	grid = manager.grid
	instructions = Instructions.new()

## Submit cards for a player's turn
func submit_turn(player_id: int, card_ids: Array) -> bool:
	if player_id not in game_manager.robots:
		return false
	
	card_submissions[player_id] = card_ids
	return true

## Execute all submitted turns in order
func execute_round() -> Array:
	var events: Array = []
	
	# Get alive players in submission order
	var players_to_execute: Array = []
	for player_id in card_submissions.keys():
		if game_manager.robots[player_id].is_alive():
			players_to_execute.append(player_id)
	
	# Execute each player's cards in sequence
	for player_id in players_to_execute:
		var card_ids = card_submissions.get(player_id, [])
		var robot = game_manager.robots[player_id]
		
		# Execute each card in order
		for card_id in card_ids:
			var result = instructions.execute_instruction(card_id, robot, grid, game_manager.robots)
			
			# Record event
			var event = {
				"playerId": player_id,
				"cardId": card_id,
				"type": "instruction_executed"
			}
			event.merge(result)
			events.append(event)
	
	# Clear submissions for next round
	card_submissions.clear()
	game_manager.reset_turn_submissions()
	game_manager.current_turn += 1
	
	turn_executed.emit()
	round_complete.emit()
	
	return events

## Check if round is ready to execute
func is_ready_to_execute() -> bool:
	return game_manager.are_all_turns_submitted() or _check_timeout()

## Check for timeout (placeholder)
func _check_timeout() -> bool:
	return false  # Implement timeout logic

## Get events that occurred during a turn
func get_turn_events() -> Array:
	return []  # Can be enhanced to track more detailed events
