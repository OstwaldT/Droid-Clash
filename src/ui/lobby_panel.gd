extends CanvasLayer

class_name LobbyPanel

## Displayed over the 3D board while the game is in LOBBY phase.
## Hides automatically when game_started fires.

const PANEL_W: float = 560.0
const PANEL_H: float = 680.0
const PLAYER_LIST_MAX_H: float = 260.0

## Player colours come from the ColorPalette singleton.

var game_manager: GameManager

var _player_list: VBoxContainer
var _count_label: Label
var _row_map: Dictionary = {}  # player_id -> HBoxContainer
var _countdown_label: Label    # big centred number shown during pre-game countdown

# --- Setup ---

func setup(gm: GameManager) -> void:
	game_manager = gm
	gm.player_joined.connect(_on_player_joined)
	gm.player_left.connect(_on_player_left)
	gm.player_ready.connect(_on_player_ready)
	gm.game_started.connect(_on_game_started)
	layer = 10  # render above everything else
	_build_ui()

# --- UI construction ---

func _build_ui() -> void:
	# Full-screen root so anchors work against the viewport
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Semi-transparent dim over the 3D board
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.04, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	# CenterContainer reliably centres its child regardless of content size
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	# Centred card panel — width driven by content, min PANEL_W
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	panel.add_theme_stylebox_override("panel",
		UITheme.make_panel_style(Vector4(28, 28, 24, 24), 8))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	vbox.add_child(UITheme.make_title("DROID-CLASH", 52))
	vbox.add_child(UITheme.make_subtitle("L  O  B  B  Y", 18))
	vbox.add_child(UITheme.make_separator())

	# Map size selector
	vbox.add_child(_build_map_size_row())

	vbox.add_child(UITheme.make_separator())

	# Player rows — inside a scroll container so large lobbies don't overflow
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, PLAYER_LIST_MAX_H)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_player_list = VBoxContainer.new()
	_player_list.add_theme_constant_override("separation", 8)
	_player_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_player_list)
	_show_empty_state()

	vbox.add_child(UITheme.make_separator())

	# Footer count
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(_count_label, 19, UITheme.MUTED)
	vbox.add_child(_count_label)
	_refresh_count()

	# Big countdown number — hidden until countdown starts
	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	UITheme.apply_font(_countdown_label, 120, UITheme.HIGHLIGHT)
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_countdown_label.custom_minimum_size = Vector2(200, 160)
	_countdown_label.visible = false
	root.add_child(_countdown_label)

## Map size options: [label, side_length, tile_count, player_hint]
const MAP_SIZES := [
	["SMALL",  3, 19, "2–3"],
	["MEDIUM", 4, 37, "3–5"],
	["LARGE",  5, 61, "5–8"],
]
var _map_size_buttons: Array = []

func _build_map_size_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := UITheme.make_section_header("MAP SIZE")
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl.custom_minimum_size.x = 100
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)

	_map_size_buttons.clear()
	for entry in MAP_SIZES:
		var btn := Button.new()
		btn.text = entry[0]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_font(btn, 18)
		btn.set_meta("side_length", entry[1])
		btn.pressed.connect(_on_map_size_pressed.bind(btn))
		_map_size_buttons.append(btn)
		row.add_child(btn)

	_refresh_map_buttons()
	return row

func _on_map_size_pressed(btn: Button) -> void:
	if not game_manager:
		return
	game_manager.set_map_size(btn.get_meta("side_length"))
	_refresh_map_buttons()

func _refresh_map_buttons() -> void:
	var current: int = game_manager.map_size if game_manager else 5
	for btn in _map_size_buttons:
		var selected: bool = btn.get_meta("side_length") == current
		var style: StyleBoxFlat
		if selected:
			style = UITheme.make_button_style(UITheme.HIGHLIGHT, UITheme.HIGHLIGHT)
		else:
			style = UITheme.make_button_style()
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color",
			UITheme.BG if selected else Color(0.55, 0.55, 0.70))

# --- Player row helpers ---

func _show_empty_state() -> void:
	var empty := Label.new()
	empty.name = "EmptyLabel"
	empty.text = "No players connected yet..."
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.apply_font(empty, 17, Color(0.32, 0.32, 0.42))
	_player_list.add_child(empty)

func _add_player_row(player_id: int, player_name: String) -> void:
	# Remove empty-state label on first player
	var empty := _player_list.get_node_or_null("EmptyLabel")
	if empty:
		empty.queue_free()

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Colored identity swatch — read from robot if available, fallback to palette index
	var robot_ref: Robot = game_manager.robots.get(player_id) if game_manager else null
	var swatch_color: Color
	if robot_ref and not robot_ref.color.is_empty():
		swatch_color = Color.html(robot_ref.color)
	else:
		swatch_color = ColorPalette.color_for(player_id - 1)
	row.add_child(UITheme.make_swatch(swatch_color, 14.0))

	# Player number
	var num_label := Label.new()
	num_label.text = "P%d" % player_id
	num_label.custom_minimum_size.x = 30
	UITheme.apply_font(num_label, 20, Color(0.55, 0.55, 0.65))
	row.add_child(num_label)

	# Name
	var name_label := Label.new()
	name_label.text = player_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_font(name_label, 22, UITheme.TEXT)
	row.add_child(name_label)

	# Ready status
	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "○  WAITING"
	status.custom_minimum_size.x = 130
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_font(status, 19, Color(0.40, 0.40, 0.52))
	row.add_child(status)

	_player_list.add_child(row)
	_row_map[player_id] = row

func _remove_player_row(player_id: int) -> void:
	if player_id in _row_map:
		_row_map[player_id].queue_free()
		_row_map.erase(player_id)

	if _row_map.is_empty():
		_show_empty_state()

func _refresh_count() -> void:
	var count: int = game_manager.players.size() if game_manager else 0
	var max_p: int  = game_manager.max_players   if game_manager else 8
	var need: int   = max(0, 2 - count)

	if need > 0:
		_count_label.text = "%d / %d players  —  need %d more to start" % [count, max_p, need]
		_count_label.add_theme_color_override("font_color", UITheme.MUTED)
	else:
		_count_label.text = "%d / %d players  —  waiting for all to ready up" % [count, max_p]
		_count_label.add_theme_color_override("font_color", UITheme.SUCCESS)

# --- Signal handlers ---

func _on_player_joined(player_id: int, player_name: String) -> void:
	_add_player_row(player_id, player_name)
	_refresh_count()

func _on_player_left(player_id: int) -> void:
	_remove_player_row(player_id)
	_refresh_count()

func _on_player_ready(player_id: int) -> void:
	var row: HBoxContainer = _row_map.get(player_id)
	if not row:
		return
	var status := row.get_node("StatusLabel") as Label
	status.text = ">  READY"
	status.add_theme_color_override("font_color", UITheme.SUCCESS)

func _on_game_started() -> void:
	visible = false

## Called each second by MessageHandler.countdown_tick (3, 2, 1, then 0 when done).
func show_countdown(seconds: int) -> void:
	if seconds == 0:
		_countdown_label.visible = false
		return
	_countdown_label.text = str(seconds)
	_countdown_label.visible = true
	# Pulse: scale up briefly then back to normal
	_countdown_label.scale = Vector2(1.4, 1.4)
	var tween := create_tween()
	tween.tween_property(_countdown_label, "scale", Vector2(1.0, 1.0), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
