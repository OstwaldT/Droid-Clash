extends Node

class_name MainServer

var ws_server: WebSocketServer
var game_manager: GameManager
var message_handler: MessageHandler
var turn_manager: TurnManager
var status_panel: ServerStatusPanel
var game_board: GameBoard3D
var lobby_panel: LobbyPanel
var player_status_hud: PlayerStatusHUD
var game_over_panel: GameOverPanel

func _ready() -> void:
	print("Initializing Droid-Clash Server...")

	# Core game logic
	game_manager = GameManager.new()
	add_child(game_manager)

	turn_manager = TurnManager.new(game_manager)
	add_child(turn_manager)

	# Wire TurnManager into GameManager so submit_turn can trigger execution
	game_manager.turn_manager = turn_manager

	# Network layer
	ws_server = WebSocketServer.new()
	add_child(ws_server)

	message_handler = MessageHandler.new(ws_server, game_manager, turn_manager)

	# 3D game board
	game_board = GameBoard3D.new()
	add_child(game_board)
	game_board.setup(game_manager, turn_manager)
	# Wire board animation-complete signal to message_handler so it can send round_ready
	game_board.round_display_complete.connect(message_handler._broadcast_round_ready)

	_setup_3d_scene()

	# 2D overlay (renders on top of the 3D world)
	status_panel = ServerStatusPanel.new()
	add_child(status_panel)

	# Lobby overlay (hides when game starts)
	lobby_panel = LobbyPanel.new()
	add_child(lobby_panel)
	lobby_panel.setup(game_manager)

	# Player status HUD (top-right, visible during gameplay)
	player_status_hud = PlayerStatusHUD.new()
	add_child(player_status_hud)
	player_status_hud.setup(game_manager, turn_manager)

	# Game over overlay (hidden until game ends; shown by game_board after animations)
	game_over_panel = GameOverPanel.new()
	add_child(game_over_panel)
	game_over_panel.setup(game_manager)
	game_board.game_over_panel = game_over_panel

	print("Server initialized and ready for connections")

func _setup_3d_scene() -> void:
	# --- Camera ---
	var camera := Camera3D.new()
	add_child(camera)

	# Position camera after board exists so we can use grid centre
	var center := game_board.get_grid_center()
	camera.position = center + Vector3(0.0, 17.0, -11.0)
	camera.look_at(center, Vector3.UP)
	camera.fov = 55.0
	camera.make_current()

	# --- Lighting ---
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true

	# Soft fill light from below-left
	var fill := DirectionalLight3D.new()
	add_child(fill)
	fill.rotation_degrees = Vector3(40.0, -140.0, 0.0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.7, 0.8, 1.0)

	# --- World environment (sky + ambient) ---
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.32, 0.4)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

func _process(_delta: float) -> void:
	pass

