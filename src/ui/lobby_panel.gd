extends CanvasLayer

class_name LobbyPanel

## Displayed over the 3D board while the game is in LOBBY phase.
## Hides automatically when game_started fires.

const PANEL_W: float = 540.0
const PANEL_H: float = 460.0

const PLAYER_COLORS: Array = [
	Color(0.90, 0.20, 0.20),
	Color(0.20, 0.52, 0.92),
	Color(0.20, 0.80, 0.30),
	Color(0.92, 0.72, 0.08),
	Color(0.72, 0.18, 0.92),
	Color(0.95, 0.50, 0.08),
	Color(0.08, 0.82, 0.82),
	Color(0.92, 0.38, 0.72),
]

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

	# Centred card panel
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.12, 0.96)
	style.set_corner_radius_all(14)
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.28, 0.28, 0.50, 0.9)
	style.content_margin_left   = 28.0
	style.content_margin_right  = 28.0
	style.content_margin_top    = 24.0
	style.content_margin_bottom = 24.0
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
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "DROID-CLASH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.08))
	vbox.add_child(title)

	# Sub-heading
	var sub := Label.new()
	sub.text = "L  O  B  B  Y"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60))
	vbox.add_child(sub)

	vbox.add_child(_make_separator())

	# Section label
	var section := Label.new()
	section.text = "CONNECTED PLAYERS"
	section.add_theme_font_size_override("font_size", 11)
	section.add_theme_color_override("font_color", Color(0.40, 0.40, 0.55))
	vbox.add_child(section)

	# Player rows
	_player_list = VBoxContainer.new()
	_player_list.add_theme_constant_override("separation", 8)
	vbox.add_child(_player_list)
	_show_empty_state()

	vbox.add_child(_make_separator())

	# Footer count
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", 13)
	_count_label.add_theme_color_override("font_color", Color(0.60, 0.60, 0.72))
	vbox.add_child(_count_label)
	_refresh_count()

	# Big countdown number — hidden until countdown starts
	_countdown_label = Label.new()
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 120)
	_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.08))
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_countdown_label.custom_minimum_size = Vector2(200, 160)
	_countdown_label.visible = false
	root.add_child(_countdown_label)

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.25, 0.25, 0.40, 0.6)
	sep_style.content_margin_top = 1.0
	sep.add_theme_stylebox_override("separator", sep_style)
	return sep

# --- Player row helpers ---

func _show_empty_state() -> void:
	var empty := Label.new()
	empty.name = "EmptyLabel"
	empty.text = "No players connected yet…"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.add_theme_font_size_override("font_size", 13)
	empty.add_theme_color_override("font_color", Color(0.32, 0.32, 0.42))
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
		swatch_color = PLAYER_COLORS[(player_id - 1) % PLAYER_COLORS.size()]
	var swatch := ColorRect.new()
	swatch.color = swatch_color
	swatch.custom_minimum_size = Vector2(14, 14)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(swatch)

	# Player number
	var num_label := Label.new()
	num_label.text = "P%d" % player_id
	num_label.custom_minimum_size.x = 30
	num_label.add_theme_font_size_override("font_size", 14)
	num_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	row.add_child(num_label)

	# Name
	var name_label := Label.new()
	name_label.text = player_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_label)

	# Ready status
	var status := Label.new()
	status.name = "StatusLabel"
	status.text = "○  WAITING"
	status.custom_minimum_size.x = 110
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 13)
	status.add_theme_color_override("font_color", Color(0.40, 0.40, 0.52))
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
		_count_label.add_theme_color_override("font_color", Color(0.60, 0.60, 0.72))
	else:
		_count_label.text = "%d / %d players  —  waiting for all to ready up" % [count, max_p]
		_count_label.add_theme_color_override("font_color", Color(0.20, 0.88, 0.35))

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
	status.text = "✓  READY"
	status.add_theme_color_override("font_color", Color(0.18, 0.88, 0.32))

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
