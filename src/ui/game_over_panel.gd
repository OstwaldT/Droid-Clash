extends CanvasLayer

class_name GameOverPanel

## Full-screen overlay shown on the 3D board when the game ends.
## Displays the winner (highlighted in their color) and final health standings.

const PANEL_W: float = 520.0
const PANEL_H: float = 500.0

var game_manager: GameManager

var _winner_label:  Label
var _result_list:   VBoxContainer

# --- Setup ---

func setup(gm: GameManager) -> void:
	game_manager = gm
	gm.game_ended.connect(_on_game_ended)
	layer   = 20   # above HUD and lobby
	visible = false
	_build_ui()

# --- UI construction ---

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Full-screen dim
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.04, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	# Centred panel
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.10, 0.97)
	style.set_corner_radius_all(16)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color        = Color(1.0, 0.82, 0.08, 0.90)  # gold border
	style.content_margin_left   = 32.0
	style.content_margin_right  = 32.0
	style.content_margin_top    = 28.0
	style.content_margin_bottom = 28.0
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left   = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -PANEL_W / 2.0
	panel.offset_right  =  PANEL_W / 2.0
	panel.offset_top    = -PANEL_H / 2.0
	panel.offset_bottom =  PANEL_H / 2.0
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "💥  GAME OVER  💥"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.08))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "R  E  S  U  L  T  S"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.42, 0.42, 0.58))
	vbox.add_child(sub)

	vbox.add_child(_make_separator(Color(1.0, 0.82, 0.08, 0.50)))

	# Winner block (populated dynamically)
	_winner_label = Label.new()
	_winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_winner_label.add_theme_font_size_override("font_size", 28)
	_winner_label.add_theme_color_override("font_color", Color.WHITE)
	_winner_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_winner_label)

	vbox.add_child(_make_separator(Color(0.25, 0.25, 0.40, 0.60)))

	# Standings header
	var standings_hdr := Label.new()
	standings_hdr.text = "FINAL STANDINGS"
	standings_hdr.add_theme_font_size_override("font_size", 11)
	standings_hdr.add_theme_color_override("font_color", Color(0.42, 0.42, 0.58))
	vbox.add_child(standings_hdr)

	_result_list = VBoxContainer.new()
	_result_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_result_list)

func _make_separator(color: Color) -> HSeparator:
	var sep := HSeparator.new()
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.content_margin_top = 1.0
	sep.add_theme_stylebox_override("separator", s)
	return sep

# --- Populate on game end ---

func _on_game_ended() -> void:
	var alive := game_manager.get_alive_players()

	# Winner line
	if alive.size() == 1:
		var w_robot: Robot = game_manager.robots.get(alive[0])
		var w_color := Color.html(w_robot.color) if w_robot else Color.WHITE
		_winner_label.text = "🏆  %s  WINS!" % (w_robot.bot_name if w_robot else "???")
		_winner_label.add_theme_color_override("font_color", w_color)
	else:
		_winner_label.text = "— DRAW —"
		_winner_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

	# Clear any previous standings
	for child in _result_list.get_children():
		child.queue_free()

	# Sort: alive first (by health desc), then dead (by health desc)
	var all_robots: Array = []
	for robot in game_manager.robots.values():
		all_robots.append(robot)
	all_robots.sort_custom(func(a: Robot, b: Robot) -> bool:
		if a.is_alive() != b.is_alive():
			return a.is_alive()
		return a.health > b.health
	)

	for robot in all_robots:
		_result_list.add_child(_make_result_row(robot, alive.size() == 1 and robot.player_id == alive[0]))

	visible = true

func _make_result_row(robot: Robot, is_winner: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size.y = 36.0

	var robot_color := Color.html(robot.color) if not robot.color.is_empty() else Color.WHITE

	# Color swatch
	var swatch := ColorRect.new()
	swatch.color = robot_color
	swatch.custom_minimum_size = Vector2(12, 12)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)

	# Trophy for winner, skull for dead
	var icon_lbl := Label.new()
	if is_winner:
		icon_lbl.text = "🏆"
	elif not robot.is_alive():
		icon_lbl.text = "💀"
	else:
		icon_lbl.text = "  "
	icon_lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(icon_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = robot.bot_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color",
		robot_color if robot.is_alive() else Color(0.45, 0.45, 0.45))
	row.add_child(name_lbl)

	# HP readout
	var hp_lbl := Label.new()
	hp_lbl.text = "%d / %d HP" % [robot.health, robot.max_health]
	hp_lbl.custom_minimum_size.x = 100
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_lbl.add_theme_font_size_override("font_size", 15)
	hp_lbl.add_theme_color_override("font_color",
		Color(0.18, 0.88, 0.32) if robot.is_alive() else Color(0.60, 0.22, 0.22))
	row.add_child(hp_lbl)

	return row
