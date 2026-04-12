extends CanvasLayer

class_name GameOverPanel

## Full-screen overlay shown on the 3D board when the game ends.
## Displays the winner (highlighted in their color) and final health standings.

const PANEL_W: float = 660.0
const PANEL_H: float = 660.0

var game_manager: GameManager

var _winner_label:  Label
var _result_list:   VBoxContainer
var _rematch_icons: Dictionary = {}  # player_id -> Label, updated as players opt in

# --- Setup ---

func setup(gm: GameManager) -> void:
	game_manager = gm
	# Hide on rematch so GameBoard3D doesn't need to know about this panel
	gm.game_started.connect(func() -> void: visible = false)
	layer   = 20
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

	# Centred panel — gold border for emphasis
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UITheme.make_panel_style(Vector4(36, 36, 30, 30), 8, UITheme.HIGHLIGHT))
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
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	vbox.add_child(UITheme.make_title(">> GAME OVER <<", 51))
	vbox.add_child(UITheme.make_subtitle("R  E  S  U  L  T  S"))
	vbox.add_child(UITheme.make_separator(0.50))

	# Winner block (populated dynamically)
	_winner_label = Label.new()
	_winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_winner_label, 42, UITheme.TEXT)
	_winner_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_winner_label)

	vbox.add_child(UITheme.make_separator(0.60))
	vbox.add_child(UITheme.make_section_header("FINAL STANDINGS"))

	_result_list = VBoxContainer.new()
	_result_list.add_theme_constant_override("separation", 8)
	vbox.add_child(_result_list)

# --- Populate on game end ---

## Called by GameBoard3D after all round animations have completed.
func show_result() -> void:
	var alive := game_manager.get_alive_players()

	# Resolve winner: use alive player, or fall back to provisional winner (last standing
	# who may have later killed themselves with their own remaining cards).
	var winner_id: int = -1
	if alive.size() == 1:
		winner_id = alive[0]
	elif game_manager.provisional_winner_id != -1:
		winner_id = game_manager.provisional_winner_id

	# Winner line
	if winner_id != -1:
		var w_robot: Robot = game_manager.robots.get(winner_id)
		var w_color := Color.html(w_robot.color) if w_robot else Color.WHITE
		_winner_label.text = "[W]  %s  WINS!" % (w_robot.bot_name if w_robot else "???")
		_winner_label.add_theme_color_override("font_color", w_color)
	else:
		_winner_label.text = "— DRAW —"
		_winner_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

	# Clear any previous standings and rematch icons
	for child in _result_list.get_children():
		child.queue_free()
	_rematch_icons.clear()

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
		var pair := _make_result_row(robot, winner_id != -1 and robot.player_id == winner_id)
		_result_list.add_child(pair[0])
		_rematch_icons[robot.player_id] = pair[1]

	visible = true

## Returns [HBoxContainer, rematch_icon_label] so the caller can store the icon reference.
func _make_result_row(robot: Robot, is_winner: bool) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size.y = 45.0

	var robot_color := Color.html(robot.color) if not robot.color.is_empty() else UITheme.TEXT

	row.add_child(UITheme.make_swatch(robot_color))

	# Text badge for winner / dead
	var icon_lbl := Label.new()
	if is_winner:
		icon_lbl.text = "[W]"
		icon_lbl.add_theme_color_override("font_color", UITheme.HIGHLIGHT)
	elif not robot.is_alive():
		icon_lbl.text = "[X]"
		icon_lbl.add_theme_color_override("font_color", UITheme.DANGER)
	else:
		icon_lbl.text = "   "
	UITheme.apply_font(icon_lbl, 22)
	row.add_child(icon_lbl)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = robot.bot_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_font(name_lbl, 22)
	name_lbl.add_theme_color_override("font_color",
		robot_color if robot.is_alive() else Color(0.45, 0.45, 0.45))
	row.add_child(name_lbl)

	# HP readout
	var hp_lbl := Label.new()
	hp_lbl.text = "%d / %d HP" % [robot.health, robot.max_health]
	hp_lbl.custom_minimum_size.x = 126
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_font(hp_lbl, 22)
	hp_lbl.add_theme_color_override("font_color",
		UITheme.SUCCESS if robot.is_alive() else UITheme.DANGER)
	row.add_child(hp_lbl)

	# Rematch indicator — empty until the player opts in
	var rematch_lbl := Label.new()
	rematch_lbl.text = ""
	rematch_lbl.custom_minimum_size.x = 36
	rematch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(rematch_lbl, 22)
	row.add_child(rematch_lbl)

	return [row, rematch_lbl]

## Called by MessageHandler whenever a player opts in (or out) for a rematch.
## requests: Dictionary of player_id -> true for every player who has asked.
func update_rematch(requests: Dictionary) -> void:
	for player_id in _rematch_icons:
		var lbl: Label = _rematch_icons[player_id]
		lbl.text = "[R]" if player_id in requests else ""
		if player_id in requests:
			lbl.add_theme_color_override("font_color", UITheme.HIGHLIGHT)
