extends CanvasLayer

class_name ServerStatusPanel

var game_manager: GameManager
var ws_server: WebSocketServer
var status_label: Label

func _ready() -> void:
	# Get references to game manager and websocket server
	var root = get_tree().root
	game_manager = root.find_child("GameManager", true, false)
	ws_server = root.find_child("WebSocketServer", true, false)
	
	if not game_manager or not ws_server:
		push_error("Failed to find GameManager or WebSocketServer!")
		return
	
	# Create UI
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	var style = panel.get_theme_stylebox("panel")
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.set_corner_radius_all(10)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	
	status_label = Label.new()
	margin.add_child(status_label)
	
	# Style the label
	var font_size = Label.new()
	font_size.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_font_size_override("font_size", 14)
	
	var font_color = Color.WHITE
	status_label.add_theme_color_override("font_color", font_color)
	
	# Position top-left
	panel.anchor_left = 0
	panel.anchor_top = 0
	panel.offset_right = 400
	panel.offset_bottom = 300
	
	add_child(panel)
	set_process(true)

func _process(_delta: float) -> void:
	if not game_manager or not ws_server or not status_label:
		return
	
	var phase_name = GameManager.GamePhase.keys()[game_manager.phase]
	var player_count = game_manager.players.size()
	var connected_clients = ws_server.websocket_peers.keys().size()
	var text = ""
	text += "[color=yellow]=== DROID-CLASH SERVER ===[/color]\n"
	text += "\n"
	text += "Phase: [color=cyan]%s[/color]\n" % phase_name
	text += "Turn: [color=cyan]%d[/color]\n" % game_manager.current_turn
	text += "\n"
	text += "Players: [color=lime]%d[/color]\n" % player_count
	text += "Connected: [color=lime]%d[/color]\n" % connected_clients
	text += "\n"
	
	if player_count > 0:
		text += "[color=yellow]Player Status:[/color]\n"
		for player_id in game_manager.players.keys():
			var player_info = game_manager.players[player_id]
			var ready_status = "✓" if player_info.get("ready", false) else "✗"
			var robot = game_manager.robots.get(player_id)
			if robot:
				text += "  %s P%d: %s (HP: %d)\n" % [ready_status, player_id, robot.bot_name, robot.health]
	
	status_label.text = text
