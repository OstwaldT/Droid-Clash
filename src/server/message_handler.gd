extends Node

class_name MessageHandler

## Emitted whenever the rematch request set changes. Carries a copy of the
## requests Dictionary (player_id -> true) so the game-over panel can update.
signal rematch_status_updated(requests: Dictionary)
## Emitted each second of the pre-game countdown (3, 2, 1) and once with 0 when done.
signal countdown_tick(seconds: int)

var ws_server: WebSocketServer
var game_manager: GameManager
var turn_manager: TurnManager
var client_to_player: Dictionary = {}  # client_id (int) -> player_id
var _player_to_client: Dictionary = {}  # player_id -> client_id (int)
var rematch_requests: Dictionary = {}  # player_id -> true
var _countdown_active: bool = false

func _init(server: WebSocketServer, manager: GameManager, tm: TurnManager) -> void:
	ws_server = server
	game_manager = manager
	turn_manager = tm

	# Register message handlers
	ws_server.add_message_handler("join", _on_join_message)
	ws_server.add_message_handler("turn_submit", _on_turn_submit_message)
	ws_server.add_message_handler("ready", _on_ready_message)
	ws_server.add_message_handler("leave", _on_leave_message)
	ws_server.add_message_handler("rematch", _on_rematch_message)

	# Connect signals
	ws_server.client_connected.connect(_on_client_connected)
	ws_server.client_disconnected.connect(_on_client_disconnected)
	tm.turn_executed.connect(_on_turn_executed)
	tm.round_starting.connect(_on_round_starting)

func _on_join_message(client_id: int, message: Dictionary) -> void:
	var data = message.get("data", {})
	var player_name = data.get("playerName", "").strip_edges()

	if player_name.is_empty() or player_name.length() > 20:
		ws_server._send_error(client_id, "INVALID_NAME", "Player name must be 1-20 characters")
		return

	# Reject if a game is already in progress or countdown has started
	if _countdown_active or game_manager.phase != GameManager.GamePhase.LOBBY:
		ws_server._send_error(client_id, "GAME_LOCKED", "A game is already in progress")
		return
	
	# Ensure unique name
	for player in game_manager.players.values():
		if player.name == player_name:
			ws_server._send_error(client_id, "DUPLICATE_NAME", "Name already taken")
			return
	
	var player_id = ws_server.register_client(client_id)
	if not game_manager.add_player(player_id, player_name):
		ws_server._send_error(client_id, "GAME_FULL", "Game is full")
		return
	
	client_to_player[client_id] = player_id
	_player_to_client[player_id] = client_id
	
	# Send connection confirmation
	ws_server.send_to_player(client_id, {
		"type": "connect",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"playerId": player_id,
			"color": game_manager.robots[player_id].color,
			"wsUrl": "ws://localhost:8080",
			"status": "connected"
		}
	})
	
	# Broadcast player joined
	_broadcast_player_list()

func _on_turn_submit_message(client_id: int, message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id == -1:
		ws_server._send_error(client_id, "PLAYER_NOT_FOUND", "Player not found")
		return

	# Reject if already submitted this round
	if game_manager.players.get(player_id, {}).get("submitted", false):
		ws_server._send_error(client_id, "ALREADY_SUBMITTED", "Turn already submitted")
		return

	var data = message.get("data", {})
	# JSON sends numbers as float — cast to int for correct Array lookup
	var card_ids: Array[int] = []
	for raw_id in data.get("cardIds", []):
		card_ids.append(int(raw_id))
	var turn_number: int = int(data.get("turnNumber", -1))
	
	# Validate turn number, card count, hand membership, and duplicates
	var valid_hand_ids: Array = game_manager.player_decks[player_id].get_hand_instance_ids()
	var result := CardValidator.validate(card_ids, turn_number, game_manager.current_turn, valid_hand_ids)
	if not result["ok"]:
		ws_server._send_error(client_id, result["code"], result["message"])
		return
	
	# Accept turn
	if turn_manager.submit_turn(player_id, card_ids):
		ws_server.send_to_player(client_id, {
			"type": "turn_accepted",
			"timestamp": Time.get_ticks_msec(),
			"data": {
				"playerId": player_id,
				"turnNumber": turn_number,
				"message": "Turn submitted"
			}
		})
		# Broadcast updated statuses so other clients see this player as "submitted"
		_broadcast_player_statuses()

func _on_ready_message(client_id: int, message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id == -1:
		return

	# Mark player as ready and apply chosen deck archetype
	if player_id in game_manager.players:
		game_manager.players[player_id]["ready"] = true
		var archetype: String = message.get("data", {}).get("archetype", "standard")
		game_manager.players[player_id]["archetype"] = archetype
		game_manager.player_decks[player_id] = Deck.new(DeckConfig.preset(archetype))
		game_manager.player_ready.emit(player_id)
		_broadcast_player_list()

		# Check if all players ready
		var all_ready := true
		for player in game_manager.players.values():
			if not player.get("ready", false):
				all_ready = false
				break

		if all_ready and game_manager.players.size() >= 1 and not _countdown_active:
			_start_countdown()

## Broadcast a 3-second countdown then start the game.
func _start_countdown() -> void:
	_countdown_active = true
	for tick: int in [3, 2, 1]:
		countdown_tick.emit(tick)
		ws_server.broadcast({
			"type": "countdown",
			"timestamp": Time.get_ticks_msec(),
			"data": { "seconds": tick }
		})
		await get_tree().create_timer(1.0).timeout
	countdown_tick.emit(0)
	_countdown_active = false
	game_manager.start_game()
	_broadcast_game_start()

func _on_leave_message(client_id: int, message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id != -1:
		game_manager.remove_player(player_id)
		client_to_player.erase(client_id)
		_player_to_client.erase(player_id)
		ws_server.unregister_client(client_id)
		_broadcast_player_list()

func _on_client_connected(_player_id: int) -> void:
	pass

func _on_client_disconnected(player_id: int) -> void:
	var client_id = _player_to_client.get(player_id, -1)
	if client_id != -1:
		client_to_player.erase(client_id)
		_player_to_client.erase(player_id)
	game_manager.remove_player(player_id)
	_broadcast_player_list()

func _broadcast_player_list() -> void:
	var players_data: Array = []
	for player_id in game_manager.players.keys():
		var robot = game_manager.robots.get(player_id)
		var player_info = game_manager.players.get(player_id, {})
		if robot:
			players_data.append({
				"playerId": player_id,
				"name": robot.bot_name,
				"color": robot.color,
				"isReady": player_info.get("ready", false),
				"health": robot.health
			})
	
	ws_server.broadcast({
		"type": "player_joined",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"players": players_data,
			"playerCount": game_manager.players.size(),
			"maxPlayers": game_manager.max_players
		}
	})

func _broadcast_game_start() -> void:
	var game_state = game_manager.to_dict()

	# Broadcast common game state to all players
	ws_server.broadcast({
		"type": "game_start",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"gameId": game_state["gameId"],
			"boardRadius": game_state["boardRadius"],
			"turnNumber": game_state["turnNumber"],
			"phase": "card_selection",
			"robots": game_state["robots"],
			"turnTimeoutSeconds": 30,
			"playerStatuses": _build_player_statuses(),
			"turnOrder": turn_manager.get_priority_order()
		}
	})

	# Deal initial hands and send each player their private 6-card hand
	for player_id in game_manager.players.keys():
		game_manager.deal_player_hand(player_id)
		_send_hand_update(player_id)

func _on_turn_executed(events: Array) -> void:
	var game_state := game_manager.to_dict()

	# Check win condition first — if game is over, don't deal new hands
	var alive := game_manager.get_alive_players()
	if alive.size() <= 1 and game_manager.phase == GameManager.GamePhase.PLAYING:
		# Broadcast final state before ending the game
		ws_server.broadcast({
			"type": "game_state_update",
			"timestamp": Time.get_ticks_msec(),
			"data": {
				"turnNumber": game_state["turnNumber"],
				"currentPhase": "game_over",
				"robots": game_state["robots"],
				"events": EventSerializer.serialize_events(events),
				"playerStatuses": _build_player_statuses("selecting")
			}
		})
		game_manager.end_game()
		# Use provisional winner if the last survivor later killed themselves
		var winner_id: int
		if alive.size() == 1:
			winner_id = alive[0]
		elif game_manager.provisional_winner_id != -1:
			winner_id = game_manager.provisional_winner_id
		else:
			winner_id = -1
		var winner_robot: Robot = game_manager.robots.get(winner_id)
		ws_server.broadcast({
			"type": "game_over",
			"timestamp": Time.get_ticks_msec(),
			"data": {
				"winner": winner_id,
				"winnerName": winner_robot.bot_name if winner_robot else "No winner",
				"finalPlayers": game_state["robots"]
			}
		})
		return

	# Resolve played cards and deal new hands BEFORE broadcasting game_state_update.
	# This ensures hand_update arrives at each client before the phase switches back
	# to card_selection — preventing stale-ID submissions when players click fast.
	for player_id in game_manager.players.keys():
		game_manager.resolve_and_redraw_player_hand(player_id)
		_send_hand_update(player_id)

	ws_server.broadcast({
		"type": "game_state_update",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"turnNumber": game_state["turnNumber"],
			"currentPhase": "card_selection",
			"robots": game_state["robots"],
			"events": EventSerializer.serialize_events(events),
			"playerStatuses": _build_player_statuses("selecting"),
			"turnOrder": turn_manager.get_priority_order()
		}
	})

## Send a player their current 6-card hand as a private message.
func _send_hand_update(player_id: int) -> void:
	var client_id: int = _player_to_client.get(player_id, -1)
	if client_id == -1:
		return
	ws_server.send_to_player(client_id, {
		"type": "hand_update",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"hand":    game_manager.get_player_hand_data(player_id),
			"counts":  game_manager.get_player_deck_counts(player_id),
		}
	})

## Build a status array for all connected players.
## Pass override_status to force a specific status for everyone (e.g. "acting").
## Otherwise status is derived from each player's submitted flag.
func _build_player_statuses(override_status: String = "") -> Array:
	var statuses: Array = []
	for player_id in game_manager.players.keys():
		var status: String
		if override_status != "":
			status = override_status
		elif game_manager.players[player_id].get("submitted", false):
			status = "submitted"
		else:
			status = "selecting"
		statuses.append({"playerId": player_id, "status": status})
	return statuses

## Broadcast current player statuses to all clients.
func _broadcast_player_statuses(override_status: String = "") -> void:
	ws_server.broadcast({
		"type": "player_statuses_update",
		"timestamp": Time.get_ticks_msec(),
		"data": {"playerStatuses": _build_player_statuses(override_status)}
	})

## Called by GameBoard3D after all round animations finish.
## Signals clients that they may now transition to the next phase.
func on_round_display_complete() -> void:
	ws_server.broadcast({
		"type": "round_ready",
		"timestamp": Time.get_ticks_msec(),
		"data": {}
	})

## Called when all players have submitted and the round is about to execute.
func _on_round_starting() -> void:
	_broadcast_player_statuses("acting")

## Handle a rematch request from a client.
func _on_rematch_message(client_id: int, _message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id == -1 or game_manager.phase != GameManager.GamePhase.GAME_OVER:
		return
	rematch_requests[player_id] = true
	_broadcast_rematch_status()
	# When all connected players agree, reset and restart immediately.
	if rematch_requests.size() >= game_manager.players.size():
		_trigger_rematch()

## Broadcast who has (and hasn't) requested a rematch.
func _broadcast_rematch_status() -> void:
	var requesting: Array = rematch_requests.keys()
	ws_server.broadcast({
		"type": "rematch_status",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"requestingPlayers": requesting,
			"totalPlayers": game_manager.players.size()
		}
	})
	rematch_status_updated.emit(rematch_requests.duplicate())

## Reset the game state and start a fresh round with the same players.
func _trigger_rematch() -> void:
	rematch_requests.clear()
	game_manager.reset_for_rematch()
	game_manager.start_game()
	_broadcast_game_start()
