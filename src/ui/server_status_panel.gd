extends CanvasLayer

class_name ServerStatusPanel

var game_manager: GameManager
var ws_server: WebSocketServer
var status_label: RichTextLabel

func _ready() -> void:
	var root = get_tree().root
	game_manager = root.find_child("GameManager", true, false)
	ws_server = root.find_child("WebSocketServer", true, false)

	if not game_manager or not ws_server:
		push_error("Failed to find GameManager or WebSocketServer!")
		return

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UITheme.make_panel_style(Vector4(15, 15, 15, 15), 6))

	status_label = RichTextLabel.new()
	status_label.bbcode_enabled = true
	status_label.fit_content = true
	status_label.scroll_active = false
	UITheme.apply_font(status_label, 18)
	status_label.add_theme_color_override("default_color", UITheme.TEXT)
	panel.add_child(status_label)

	# Position top-left
	panel.anchor_left = 0
	panel.anchor_top = 0
	panel.offset_right = 510
	panel.offset_bottom = 384

	add_child(panel)
	set_process(true)

func _process(_delta: float) -> void:
	if not game_manager or not ws_server or not status_label:
		return

	var phase_name = GameManager.GamePhase.keys()[game_manager.phase]
	var player_count = game_manager.players.size()
	var connected_clients = ws_server.websocket_peers.keys().size()
	var text = ""
	text += "[color=#f0c050]=== DROID-CLASH SERVER ===[/color]\n"
	text += "\n"
	text += "Phase: [color=#50c8f0]%s[/color]\n" % phase_name
	text += "Turn: [color=#50c8f0]%d[/color]\n" % game_manager.current_turn
	text += "\n"
	text += "Players: [color=#40c860]%d[/color]\n" % player_count
	text += "Connected: [color=#40c860]%d[/color]\n" % connected_clients
	text += "\n"

	if player_count > 0:
		text += "[color=#f0c050]Player Status:[/color]\n"
		for player_id in game_manager.players.keys():
			var player_info = game_manager.players[player_id]
			var ready_status = ">" if player_info.get("ready", false) else "-"
			var robot = game_manager.robots.get(player_id)
			if robot:
				text += "  %s P%d: %s (HP: %d)\n" % [ready_status, player_id, robot.bot_name, robot.health]

	status_label.text = text
