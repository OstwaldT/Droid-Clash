extends CanvasLayer

class_name PlayerStatusHUD

## Compact player-status overlay shown on the 3D board during gameplay.
## Anchored to the top-right corner.
## Statuses:  "…  Selecting"  |  "✓  Submitted"  |  "⚡  Acting"

const PANEL_W: float  = 270.0
const ROW_H:   float  = 34.0
const PADDING: float  = 12.0

# Status colors
const COLOR_SELECTING := Color(0.50, 0.50, 0.62)
const COLOR_SUBMITTED := Color(0.15, 0.88, 0.32)
const COLOR_ACTING    := Color(0.95, 0.62, 0.08)

var game_manager: GameManager

var _player_list: VBoxContainer
var _row_map: Dictionary = {}  # player_id -> Label (the status label in that row)

# --- Setup ---

func setup(gm: GameManager, tm: TurnManager) -> void:
	game_manager = gm
	gm.player_joined.connect(_on_player_joined)
	gm.player_left.connect(_on_player_left)
	gm.player_submitted.connect(_on_player_submitted)
	tm.round_starting.connect(_on_round_starting)
	gm.game_started.connect(_on_game_started)
	tm.turn_executed.connect(_on_turn_executed)
	layer = 10
	_build_ui()
	visible = false  # hidden until the game starts

# --- UI construction ---

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Panel background
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.12, 0.88)
	style.set_corner_radius_all(10)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color        = Color(0.25, 0.25, 0.42, 0.80)
	style.content_margin_left   = PADDING
	style.content_margin_right  = PADDING
	style.content_margin_top    = PADDING
	style.content_margin_bottom = PADDING
	panel.add_theme_stylebox_override("panel", style)

	# Anchor top-right
	panel.anchor_left   = 1.0
	panel.anchor_top    = 0.0
	panel.anchor_right  = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left   = -PANEL_W - 12.0
	panel.offset_right  = -12.0
	panel.offset_top    = 12.0
	panel.offset_bottom = 12.0  # panel grows downward automatically
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Section header
	var header := Label.new()
	header.text = "PLAYERS"
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", Color(0.40, 0.40, 0.56))
	vbox.add_child(header)

	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.22, 0.22, 0.38, 0.70)
	sep_style.content_margin_top = 1.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	_player_list = VBoxContainer.new()
	_player_list.add_theme_constant_override("separation", 4)
	vbox.add_child(_player_list)

# --- Row management ---

func _add_player_row(player_id: int, player_name: String) -> void:
	if player_id in _row_map:
		return

	var robot: Robot = game_manager.robots.get(player_id)
	var color: Color = Color.html(robot.color) \
		if robot and not robot.color.is_empty() \
		else Color.WHITE

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = ROW_H

	# Colored swatch
	var swatch := ColorRect.new()
	swatch.color = color
	swatch.custom_minimum_size = Vector2(10, 10)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = player_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.clip_text = true
	row.add_child(name_lbl)

	# Status badge
	var status_lbl := Label.new()
	status_lbl.text = "…  Selecting"
	status_lbl.custom_minimum_size.x = 108
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", COLOR_SELECTING)
	row.add_child(status_lbl)

	_player_list.add_child(row)
	_row_map[player_id] = status_lbl

func _set_status(player_id: int, text: String, color: Color) -> void:
	var lbl: Label = _row_map.get(player_id)
	if not lbl:
		return
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)

# --- Signal handlers ---

func _on_player_joined(player_id: int, player_name: String) -> void:
	_add_player_row(player_id, player_name)

func _on_player_left(player_id: int) -> void:
	var lbl: Label = _row_map.get(player_id)
	if lbl and lbl.get_parent():
		lbl.get_parent().queue_free()
	_row_map.erase(player_id)

func _on_player_submitted(player_id: int) -> void:
	_set_status(player_id, "✓  Submitted", COLOR_SUBMITTED)

func _on_round_starting() -> void:
	for player_id in _row_map.keys():
		_set_status(player_id, "⚡  Acting", COLOR_ACTING)

func _on_game_started() -> void:
	# Populate rows for players who joined before game_started fired
	for player_id in game_manager.players.keys():
		var robot: Robot = game_manager.robots.get(player_id)
		var name: String = robot.bot_name if robot else "Player %d" % player_id
		_add_player_row(player_id, name)
	visible = true

func _on_turn_executed(_events: Array) -> void:
	# New turn begins — reset everyone to Selecting
	for player_id in _row_map.keys():
		_set_status(player_id, "…  Selecting", COLOR_SELECTING)
