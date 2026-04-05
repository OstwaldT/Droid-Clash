extends Node

class_name TurnManager

signal turn_executed(events: Array)
signal round_complete

var game_manager: GameManager
var grid: HexGrid
var card_submissions: Dictionary = {}  # player_id -> [instance_id, ...]

## Rotating priority queue: the player at index 0 goes first.
## After each round the first player is moved to the back.
var _priority_order: Array = []

func _init(manager: GameManager) -> void:
	game_manager = manager
	grid = manager.grid

## Register a new player into the priority order (called when they join).
func register_player(player_id: int) -> void:
	if player_id not in _priority_order:
		_priority_order.append(player_id)

## Remove a player from the priority order (called when they leave/die).
func unregister_player(player_id: int) -> void:
	_priority_order.erase(player_id)

## Submit cards for a player's turn
func submit_turn(player_id: int, card_ids: Array) -> bool:
	if player_id not in game_manager.robots:
		return false
	
	card_submissions[player_id] = card_ids
	return true

## Execute all submitted turns in order
func execute_round() -> Array:
	var events: Array = []

	# Build execution order: follow _priority_order, skip dead/missing players
	var players_to_execute: Array = []
	for player_id in _priority_order:
		if player_id in card_submissions \
				and player_id in game_manager.robots \
				and game_manager.robots[player_id].is_alive():
			players_to_execute.append(player_id)

	# Execute each player's cards in sequence
	for player_id in players_to_execute:
		var instance_ids = card_submissions.get(player_id, [])
		var robot = game_manager.robots[player_id]
		
		for instance_id in instance_ids:
			var type_id := game_manager.get_card_type_id(player_id, instance_id)
			if type_id == -1:
				continue

			var card := CardRegistry.create(type_id)
			if card == null:
				continue

			var result := card.execute(robot, grid, game_manager.robots)

			var event := {"playerId": player_id, "instanceId": instance_id, "typeId": type_id}
			event.merge(result)
			events.append(event)

	# Rotate priority: first player this round goes last next round
	if _priority_order.size() > 1:
		var first := _priority_order[0]
		_priority_order.remove_at(0)
		_priority_order.append(first)

	# Clear submissions for next round
	card_submissions.clear()
	game_manager.reset_turn_submissions()
	game_manager.current_turn += 1

	turn_executed.emit(events)
	round_complete.emit()

	return events

## Check if round is ready to execute
func is_ready_to_execute() -> bool:
	return game_manager.are_all_turns_submitted() or _check_timeout()

## Check for timeout (placeholder)
func _check_timeout() -> bool:
	return false

## Get events that occurred during a turn
func get_turn_events() -> Array:
	return []
