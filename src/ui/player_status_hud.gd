extends CanvasLayer

class_name PlayerStatusHUD

## Compact player-status overlay shown on the 3D board during gameplay.
## Anchored to the top-right corner.
## Statuses:  "..  Selecting"  |  ">  Submitted"  |  ">> Acting"

const PANEL_W: float  = 280.0
const ROW_H:   float  = 48.0
const PADDING: float  = 12.0

# Status colors
const COLOR_SELECTING := Color(0.50, 0.50, 0.62)
const COLOR_SUBMITTED := Color(0.25, 0.78, 0.38)   # UITheme.SUCCESS
const COLOR_ACTING    := Color(0.94, 0.75, 0.31)   # UITheme.HIGHLIGHT
const COLOR_DEAD      := Color(0.50, 0.50, 0.50)

var game_manager: GameManager

var _player_list: VBoxContainer
var _row_map: Dictionary = {}  # player_id -> {status: Label, hp_bar: ProgressBar, hp_label: Label}

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

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UITheme.make_panel_style(Vector4(PADDING, PADDING, PADDING, PADDING), 6))

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

	# Section header — slightly smaller than the default factory produces
	var header := Label.new()
	header.text = "PLAYERS"
	UITheme.apply_font(header, 12, UITheme.MUTED)
	vbox.add_child(header)

	vbox.add_child(UITheme.make_separator(0.70))

	_player_list = VBoxContainer.new()
	_player_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_player_list)

# --- Row management ---

func _add_player_row(player_id: int, player_name: String) -> void:
	if player_id in _row_map:
		return

	var robot: Robot = game_manager.robots.get(player_id)
	var color: Color = Color.html(robot.color) \
		if robot and not robot.color.is_empty() \
		else Color.WHITE

	# ── Outer row ──────────────────────────────────────────────────────
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = ROW_H

	row.add_child(UITheme.make_swatch(color, 10.0))

	# ── Centre column: name + HP bar ───────────────────────────────────
	var centre := VBoxContainer.new()
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 3)
	row.add_child(centre)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = player_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_font(name_lbl, 16, UITheme.TEXT)
	name_lbl.clip_text = true
	centre.add_child(name_lbl)

	# HP row: bar + value label
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 5)
	centre.add_child(hp_row)

	# Custom bar: Control containing bg + fill ColorRects
	var bar_bg := Control.new()
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_bg.custom_minimum_size   = Vector2(0, 7)
	bar_bg.clip_contents         = true
	hp_row.add_child(bar_bg)

	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = UITheme.SECTION
	bar_bg.add_child(bg_rect)

	var hp_ratio: float = clampf(float(robot.health if robot else 100) / 100.0, 0.0, 1.0)
	var fill_rect := ColorRect.new()
	fill_rect.anchor_left   = 0.0
	fill_rect.anchor_right  = hp_ratio
	fill_rect.anchor_top    = 0.0
	fill_rect.anchor_bottom = 1.0
	fill_rect.offset_left   = 0
	fill_rect.offset_right  = 0
	fill_rect.offset_top    = 0
	fill_rect.offset_bottom = 0
	fill_rect.color = Color(0.18, 0.88, 0.32)
	bar_bg.add_child(fill_rect)

	var hp_lbl := Label.new()
	hp_lbl.text = "%d" % (robot.health if robot else 100)
	hp_lbl.custom_minimum_size.x = 28
	hp_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_font(hp_lbl, 13, Color(0.75, 0.75, 0.75))
	hp_row.add_child(hp_lbl)

	# ── Status badge ───────────────────────────────────────────────────
	var status_lbl := Label.new()
	status_lbl.text = "..  Selecting"
	status_lbl.custom_minimum_size.x = 108
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_lbl.size_flags_vertical  = Control.SIZE_SHRINK_CENTER
	UITheme.apply_font(status_lbl, 15, COLOR_SELECTING)
	row.add_child(status_lbl)

	_player_list.add_child(row)
	_row_map[player_id] = {
		"status":    status_lbl,
		"fill_rect": fill_rect,
		"hp_label":  hp_lbl,
	}

func _set_status(player_id: int, text: String, color: Color) -> void:
	var entry: Dictionary = _row_map.get(player_id, {})
	var lbl: Label = entry.get("status")
	if not lbl:
		return
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)

func _update_health(player_id: int) -> void:
	var entry: Dictionary  = _row_map.get(player_id, {})
	var fill_rect: ColorRect = entry.get("fill_rect")
	var hp_label: Label      = entry.get("hp_label")
	if not fill_rect or not hp_label:
		return
	var robot: Robot = game_manager.robots.get(player_id)
	if not robot:
		return
	var ratio: float = clampf(float(robot.health) / float(robot.max_health), 0.0, 1.0)
	fill_rect.anchor_right = ratio
	hp_label.text = "%d" % robot.health
	if ratio > 0.6:
		fill_rect.color = Color(0.18, 0.88, 0.32)
	elif ratio > 0.3:
		fill_rect.color = Color(0.90, 0.80, 0.05)
	else:
		fill_rect.color = Color(0.90, 0.15, 0.05)
	if not robot.is_alive():
		hp_label.add_theme_color_override("font_color", COLOR_DEAD)

# --- Signal handlers ---

func _on_player_joined(player_id: int, player_name: String) -> void:
	_add_player_row(player_id, player_name)

func _on_player_left(player_id: int) -> void:
	var entry: Dictionary = _row_map.get(player_id, {})
	var lbl: Label = entry.get("status")
	if lbl and lbl.get_parent():
		lbl.get_parent().queue_free()
	_row_map.erase(player_id)

func _on_player_submitted(player_id: int) -> void:
	_set_status(player_id, ">  Submitted", COLOR_SUBMITTED)

func _on_round_starting() -> void:
	for player_id in _row_map.keys():
		_set_status(player_id, ">> Acting", COLOR_ACTING)

func _on_game_started() -> void:
	# Populate rows for players who joined before game_started fired
	for player_id in game_manager.players.keys():
		var robot: Robot = game_manager.robots.get(player_id)
		var pname: String = robot.bot_name if robot else "Player %d" % player_id
		_add_player_row(player_id, pname)
	visible = true

func _on_turn_executed(_events: Array) -> void:
	# Update health for all players then reset status to Selecting
	for player_id in _row_map.keys():
		_update_health(player_id)
		_set_status(player_id, "..  Selecting", COLOR_SELECTING)
