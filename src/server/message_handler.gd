extends Node

class_name MessageHandler

signal handle_join(client_id: int, data: Dictionary)
signal handle_turn_submit(client_id: int, data: Dictionary)
signal handle_ready(client_id: int, data: Dictionary)
signal handle_leave(client_id: int, data: Dictionary)

var ws_server: WebSocketServer
var game_manager: GameManager
var client_to_player: Dictionary = {}  # Maps client_id to player_id

func _init(server: WebSocketServer, manager: GameManager, tm: TurnManager) -> void:
	ws_server = server
	game_manager = manager

	# Register message handlers
	ws_server.add_message_handler("join", _on_join_message)
	ws_server.add_message_handler("turn_submit", _on_turn_submit_message)
	ws_server.add_message_handler("ready", _on_ready_message)
	ws_server.add_message_handler("leave", _on_leave_message)

	# Connect signals
	ws_server.client_connected.connect(_on_client_connected)
	ws_server.client_disconnected.connect(_on_client_disconnected)
	tm.turn_executed.connect(_on_turn_executed)

func _on_join_message(client_id: PackedByteArray, message: Dictionary) -> void:
	var data = message.get("data", {})
	var player_name = data.get("playerName", "").strip_edges()
	
	if player_name.is_empty() or player_name.length() > 20:
		ws_server._send_error(client_id, "INVALID_NAME", "Player name must be 1-20 characters")
		return
	
	# Ensure unique name
	for player in game_manager.players.values():
		if player.name == player_name:
			ws_server._send_error(client_id, "DUPLICATE_NAME", "Name already taken")
			return
	
	var player_id = ws_server.register_client(client_id)
	if not game_manager.add_player(player_id, player_name, client_id):
		ws_server._send_error(client_id, "GAME_FULL", "Game is full")
		return
	
	client_to_player[client_id] = player_id
	
	# Send connection confirmation
	ws_server.send_to_player(client_id, {
		"type": "connect",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"playerId": player_id,
			"wsUrl": "ws://localhost:8080",
			"status": "connected"
		}
	})
	
	# Broadcast player joined
	_broadcast_player_list()

func _on_turn_submit_message(client_id: PackedByteArray, message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id == -1:
		ws_server._send_error(client_id, "PLAYER_NOT_FOUND", "Player not found")
		return
	
	var data = message.get("data", {})
	var card_ids = data.get("cardIds", [])
	var turn_number = data.get("turnNumber", -1)
	
	# Validate turn number
	if turn_number != game_manager.current_turn:
		ws_server._send_error(client_id, "INVALID_TURN", "Wrong turn number")
		return
	
	# Validate card selection
	if card_ids.size() != 3:
		ws_server._send_error(client_id, "INVALID_CARDS", "Must select exactly 3 cards")
		return
	
	if card_ids.size() != card_ids.size():  # Check for duplicates
		ws_server._send_error(client_id, "DUPLICATE_CARDS", "Cannot select same card twice")
		return
	
	# Accept turn
	if game_manager.submit_turn(player_id, card_ids):
		ws_server.send_to_player(client_id, {
			"type": "turn_accepted",
			"timestamp": Time.get_ticks_msec(),
			"data": {
				"playerId": player_id,
				"turnNumber": turn_number,
				"message": "Turn submitted"
			}
		})

func _on_ready_message(client_id: PackedByteArray, message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id == -1:
		return
	
	# Mark player as ready
	if player_id in game_manager.players:
		game_manager.players[player_id]["ready"] = true
		_broadcast_player_list()  # Broadcast updated player list
		
		# Check if all players ready
		var all_ready = true
		for player in game_manager.players.values():
			if not player.get("ready", false):
				all_ready = false
				break
		
		if all_ready and game_manager.players.size() >= 2:
			game_manager.start_game()
			_broadcast_game_start()

func _on_leave_message(client_id: PackedByteArray, message: Dictionary) -> void:
	var player_id = client_to_player.get(client_id, -1)
	if player_id != -1:
		game_manager.remove_player(player_id)
		client_to_player.erase(client_id)
		ws_server.unregister_client(client_id)
		_broadcast_player_list()

func _on_client_connected(_player_id: int) -> void:
	pass

func _on_client_disconnected(player_id: int) -> void:
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

	ws_server.broadcast({
		"type": "game_start",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"gameId": game_state["gameId"],
			"boardRadius": game_state["boardRadius"],
			"turnNumber": game_state["turnNumber"],
			"phase": "card_selection",
			"robots": game_state["robots"],
			"availableCards": [
				{"id": 1, "name": "Move Forward", "instruction": "move", "icon": "🔼"},
				{"id": 2, "name": "Turn Left", "instruction": "turn_left", "icon": "↶"},
				{"id": 3, "name": "Turn Right", "instruction": "turn_right", "icon": "↷"},
				{"id": 4, "name": "Attack", "instruction": "attack", "icon": "💥"}
			],
			"turnTimeoutSeconds": 30
		}
	})

func _on_turn_executed(events: Array) -> void:
	var game_state := game_manager.to_dict()

	ws_server.broadcast({
		"type": "game_state_update",
		"timestamp": Time.get_ticks_msec(),
		"data": {
			"turnNumber": game_state["turnNumber"],
			"currentPhase": "card_selection",
			"robots": game_state["robots"],
			"events": _serialize_events(events)
		}
	})

	# Check win condition after every round
	var alive := game_manager.get_alive_players()
	if alive.size() <= 1 and game_manager.phase == GameManager.GamePhase.PLAYING:
		game_manager.end_game()
		var winner_id: int = alive[0] if alive.size() == 1 else -1
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

## Serialize event array for JSON — converts Vector2i values to {q, r} dicts.
func _serialize_events(events: Array) -> Array:
	var out: Array = []
	for event in events:
		var e: Dictionary = {}
		for key in event.keys():
			var val = event[key]
			if val is Vector2i:
				e[key] = {"q": val.x, "r": val.y}
			else:
				e[key] = val
		out.append(e)
	return out
