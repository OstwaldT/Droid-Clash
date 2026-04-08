extends Node

class_name TurnManager

signal turn_executed(events: Array)
signal round_complete
signal round_starting

var game_manager: GameManager
var card_submissions: Dictionary = {}  # player_id -> [instance_id, ...]

## Rotating priority queue: the player at index 0 goes first.
## After each round the first player is moved to the back.
var _priority_order: Array = []

func _init(manager: GameManager) -> void:
	game_manager = manager
	manager.player_joined.connect(_on_player_joined)
	manager.player_left.connect(_on_player_left)
	manager.game_resetting.connect(_on_game_resetting)

## Register a new player into the priority order (called when they join).
func register_player(player_id: int) -> void:
	if player_id not in _priority_order:
		_priority_order.append(player_id)

## Remove a player from the priority order (called when they leave/die).
func unregister_player(player_id: int) -> void:
	_priority_order.erase(player_id)

## Return the execution order for the upcoming round (copy to prevent mutation).
func get_priority_order() -> Array:
	return _priority_order.duplicate()

## Accept a player's card submission. Records state on GameManager, then
## fires the round if every alive player has now submitted.
func submit_turn(player_id: int, card_ids: Array) -> bool:
	if player_id not in game_manager.robots:
		return false
	if not game_manager.record_submission(player_id, card_ids):
		return false
	card_submissions[player_id] = card_ids
	if game_manager.are_all_turns_submitted():
		round_starting.emit()
		execute_round()
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
	game_manager.provisional_winner_id = -1
	var winner_locked := false

	for player_id in players_to_execute:
		# Once a winner is locked, skip all players except the winner
		if winner_locked and player_id != game_manager.provisional_winner_id:
			continue

		var instance_ids = card_submissions.get(player_id, [])
		var robot = game_manager.robots[player_id]

		for instance_id in instance_ids:
			# Skip remaining cards if this robot died and is NOT the locked winner.
			# The winner continues executing (even unto death) so their cards are animated.
			if not robot.is_alive() and not (winner_locked and player_id == game_manager.provisional_winner_id):
				break

			var type_id := game_manager.get_card_type_id(player_id, instance_id)
			if type_id == -1:
				continue

			var card := CardRegistry.create(type_id)
			if card == null:
				continue

			var result := card.execute(robot, game_manager.grid, game_manager.robots)

			var event := {"playerId": player_id, "instanceId": instance_id, "typeId": type_id}
			event.merge(result)
			events.append(event)

			# Lock in provisional winner the first time exactly one robot remains alive
			if game_manager.provisional_winner_id == -1:
				var alive_now := game_manager.get_alive_players()
				if alive_now.size() == 1:
					game_manager.provisional_winner_id = alive_now[0]
					winner_locked = true

	# Rotate priority: first player this round goes last next round
	if _priority_order.size() > 1:
		var first: int = _priority_order[0]
		_priority_order.remove_at(0)
		_priority_order.append(first)

	# Clear submissions for next round
	card_submissions.clear()
	game_manager.reset_turn_submissions()
	game_manager.current_turn += 1

	turn_executed.emit(events)
	round_complete.emit()

	return events

## Reset priority order and submissions for a rematch.
func reset_priority() -> void:
	_priority_order.clear()
	card_submissions.clear()

# --- GameManager signal handlers ---

func _on_player_joined(player_id: int, _player_name: String) -> void:
	register_player(player_id)

func _on_player_left(player_id: int) -> void:
	unregister_player(player_id)

func _on_game_resetting() -> void:
	reset_priority()
	for player_id in game_manager.players.keys():
		register_player(player_id)
