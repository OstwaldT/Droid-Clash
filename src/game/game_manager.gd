extends Node

class_name GameManager

signal game_started
signal game_ended
signal game_resetting
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)
signal player_ready(player_id: int)
signal player_submitted(player_id: int)
signal turn_changed(turn_number: int)

enum GamePhase { LOBBY, PLAYING, GAME_OVER }


var phase: GamePhase = GamePhase.LOBBY
var current_turn: int = 0
var max_players: int = 8
var turn_timeout: float = 30.0
var map_size: int = 5  # HexGrid side length: 3=Small, 4=Medium, 5=Large
## Set by TurnManager when exactly one robot remains alive mid-round.
var provisional_winner_id: int = -1

var players: Dictionary = {}       # player_id -> {name, client_id, submitted, color, submitted_instance_ids}
var robots: Dictionary = {}        # player_id -> Robot
var player_decks: Dictionary = {}  # player_id -> Deck
var grid: HexGrid

func _init() -> void:
	grid = HexGrid.new(5)  # hexagonal board, side length 5 (radius 4, 61 tiles)
	grid.generate_map()
	set_process(true)

func add_player(player_id: int, player_name: String, client_id: PackedByteArray) -> bool:
	if players.size() >= max_players:
		return false
	
	# Assign a distinct color by slot index (before the player is added)
	var color: String = ColorPalette.hex_for(players.size())

	players[player_id] = {
		"name": player_name,
		"client_id": client_id,
		"submitted": false,
		"color": color,
		"submitted_instance_ids": []
	}
	
	# Spawn robot at a random valid position on the hex board
	var start_pos := grid.get_random_valid_hex()
	robots[player_id] = Robot.new(player_id, player_name, start_pos, color)
	robots[player_id].direction = randi() % 6
	player_decks[player_id] = Deck.new()
	
	player_joined.emit(player_id, player_name)
	print("Player %d (%s) joined" % [player_id, player_name])
	
	return true

func remove_player(player_id: int) -> void:
	if player_id in players:
		players.erase(player_id)
		robots.erase(player_id)
		player_decks.erase(player_id)
		player_left.emit(player_id)
		print("Player %d left" % player_id)
		
		if get_alive_players().size() < 2 and phase == GamePhase.PLAYING:
			end_game()

## Change map size — only allowed while in the lobby.
func set_map_size(side_length: int) -> void:
	if phase != GamePhase.LOBBY:
		return
	map_size = side_length

func start_game() -> void:
	if phase != GamePhase.LOBBY or players.size() < 1:
		return

	# Rebuild grid with the chosen map size and reassign all player positions
	grid = HexGrid.new(map_size)
	grid.generate_map()
	var occupied: Array = []
	for player_id in players.keys():
		var pos := grid.get_spawn_hex(occupied)
		occupied.append(pos)
		robots[player_id].position  = pos
		robots[player_id].direction = randi() % 6

	phase = GamePhase.PLAYING
	current_turn = 1
	game_started.emit()
	print("Game started — map size %d, %d players" % [map_size, players.size()])

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

## Record a player's card submission. Called by TurnManager; does not trigger
## round execution — TurnManager owns that decision.
func record_submission(player_id: int, instance_ids: Array) -> bool:
	if player_id not in players:
		return false

	players[player_id]["submitted"] = true
	players[player_id]["submitted_instance_ids"] = instance_ids
	player_submitted.emit(player_id)
	return true

func are_all_turns_submitted() -> bool:
	for player_id in get_alive_players():
		if not players[player_id].get("submitted", false):
			return false
	return true

func reset_turn_submissions() -> void:
	for player_id in players.keys():
		players[player_id]["submitted"] = false
		# submitted_instance_ids is NOT cleared here — resolve_and_redraw_player_hand
		# reads them AFTER this runs (via the turn_executed signal) and clears them itself.

## Look up the instruction type ID for a card instance in a player's current hand.
func get_card_type_id(player_id: int, instance_id: int) -> int:
	var deck: Deck = player_decks.get(player_id)
	return deck.get_type_id(instance_id) if deck else -1

## Draw the initial hand for a player (called at game start).
func deal_player_hand(player_id: int) -> Array:
	var deck: Deck = player_decks.get(player_id)
	return deck.draw_hand() if deck else []

## Serialised hand data for sending to the client.
func get_player_hand_data(player_id: int) -> Array:
	var deck: Deck = player_decks.get(player_id)
	return deck.hand_to_array() if deck else []

## Draw pile and discard pile counts for the HUD, plus shuffle info if applicable.
func get_player_deck_counts(player_id: int) -> Dictionary:
	var deck: Deck = player_decks.get(player_id)
	if not deck:
		return {"draw": 0, "discard": 0}
	var counts := {"draw": deck.get_draw_pile_size(), "discard": deck.get_discard_pile_size()}
	var shuffle := deck.get_last_shuffle_info()
	if shuffle.get("shuffled", false):
		counts["shuffled"] = true
		counts["cardsBeforeShuffle"] = shuffle["cards_before_shuffle"]
	return counts

## Resolve the played hand (discard played cards, return unchosen ones),
## then draw a fresh hand. Call this after turn_manager.execute_round().
func resolve_and_redraw_player_hand(player_id: int) -> Array:
	var deck: Deck = player_decks.get(player_id)
	if not deck:
		return []
	var played: Array = players[player_id].get("submitted_instance_ids", [])
	deck.resolve_hand(played)
	players[player_id]["submitted_instance_ids"] = []  # clear after use
	return deck.draw_hand()

## Reset all game state for a rematch while keeping the same players.
## Robots are re-spawned at new positions; decks and turn order are refreshed.
func reset_for_rematch() -> void:
	phase = GamePhase.LOBBY
	current_turn = 0
	provisional_winner_id = -1
	grid = HexGrid.new(map_size)
	grid.generate_map()  # fresh map layout each rematch
	var occupied: Array = []
	for player_id in players.keys():
		var start_pos := grid.get_spawn_hex(occupied)
		occupied.append(start_pos)
		var pdata: Dictionary = players[player_id]
		robots[player_id] = Robot.new(player_id, pdata["name"], start_pos, pdata["color"])
		robots[player_id].direction = randi() % 6
		var arch: String = pdata.get("archetype", "standard")
		player_decks[player_id] = Deck.new(DeckConfig.preset(arch))
		players[player_id]["submitted"] = false
		players[player_id]["submitted_instance_ids"] = []
	print("Game reset for rematch with %d players" % players.size())
	game_resetting.emit()

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
