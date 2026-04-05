extends Node

class_name GameManager

signal game_started
signal game_ended
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)
signal player_ready(player_id: int)
signal turn_changed(turn_number: int)

enum GamePhase { LOBBY, PLAYING, GAME_OVER }

## Palette shared with game_board_3d / lobby_panel — one color per player slot.
## Hex strings match the Color(...) literals used by the 3D UI.
const PLAYER_COLORS: Array = [
	"#e63333",  # Red
	"#3385eb",  # Blue
	"#33cc4d",  # Green
	"#ebb814",  # Yellow
	"#b82eeb",  # Purple
	"#f28014",  # Orange
	"#14d1d1",  # Cyan
	"#eb61b8",  # Pink
]

var phase: GamePhase = GamePhase.LOBBY
var current_turn: int = 0
var max_players: int = 8
var turn_timeout: float = 30.0

var players: Dictionary = {}  # player_id -> {"name": str, "client_id": PackedByteArray}
var robots: Dictionary = {}   # player_id -> Robot
var grid: HexGrid
var turn_queue: Array = []
var turn_manager: TurnManager = null  # set by main.gd after TurnManager is created

func _init() -> void:
	grid = HexGrid.new(5)  # hexagonal board, side length 5 (radius 4, 61 tiles)
	set_process(true)

func add_player(player_id: int, player_name: String, client_id: PackedByteArray) -> bool:
	if players.size() >= max_players:
		return false
	
	# Assign a distinct color by slot index (before the player is added)
	var color: String = PLAYER_COLORS[players.size() % PLAYER_COLORS.size()]

	players[player_id] = {
		"name": player_name,
		"client_id": client_id,
		"submitted": false,
		"color": color
	}
	
	# Spawn robot at a random valid position on the hex board
	var start_pos := grid.get_random_valid_hex()
	robots[player_id] = Robot.new(player_id, player_name, start_pos, color)
	
	player_joined.emit(player_id, player_name)
	print("Player %d (%s) joined" % [player_id, player_name])
	
	return true

func remove_player(player_id: int) -> void:
	if player_id in players:
		players.erase(player_id)
		robots.erase(player_id)
		player_left.emit(player_id)
		print("Player %d left" % player_id)
		
		if get_alive_players().size() < 2 and phase == GamePhase.PLAYING:
			end_game()

func start_game() -> void:
	if phase != GamePhase.LOBBY or players.size() < 2:
		return
	
	phase = GamePhase.PLAYING
	current_turn = 1
	game_started.emit()
	print("Game started with %d players" % players.size())

func end_game() -> void:
	phase = GamePhase.GAME_OVER
	game_ended.emit()
	print("Game ended")

func get_alive_players() -> Array:
	var alive: Array = []
	for player_id in robots.keys():
		if robots[player_id].is_alive():
			alive.append(player_id)
	return alive

func get_all_players() -> Array:
	var result: Array = []
	for player_id in players.keys():
		var robot = robots.get(player_id)
		if robot:
			result.append(robot.to_dict())
	return result

func submit_turn(player_id: int, card_ids: Array) -> bool:
	if player_id not in players:
		return false

	players[player_id]["submitted"] = true

	# Forward card selection to TurnManager
	if turn_manager:
		turn_manager.submit_turn(player_id, card_ids)

	# Execute the round as soon as every alive player has submitted
	if turn_manager and are_all_turns_submitted():
		turn_manager.execute_round()

	return true

func are_all_turns_submitted() -> bool:
	for player_id in get_alive_players():
		if not players[player_id].get("submitted", false):
			return false
	return true

func reset_turn_submissions() -> void:
	for player_id in players.keys():
		players[player_id]["submitted"] = false

func to_dict() -> Dictionary:
	return {
		"gameId": "game_001",
		"phase": GamePhase.keys()[phase],
		"turnNumber": current_turn,
		"boardRadius": grid.radius,
		"robots": get_all_players(),
		"playerCount": players.size(),
		"maxPlayers": max_players
	}
