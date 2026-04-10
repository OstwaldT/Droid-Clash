class_name UITheme

## Shared UI palette and factory helpers for all server HUD panels.
## Color values kept in sync with browser-client/src/style.css.
## Font: Press Start 2P — same as browser-client (Google Fonts).

# ── Font ─────────────────────────────────────────────────────────────────────
## Shared pixel font used across all server HUD panels and 3D labels.
static var FONT: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# ── Palette ──────────────────────────────────────────────────────────────────
const BG        := Color(0.06, 0.06, 0.10)   # #0f0f18  — page / dim background
const PANEL     := Color(0.10, 0.10, 0.18)   # #1a1a2e  — .ui-panel
const SECTION   := Color(0.08, 0.08, 0.14)   # #141425  — .ui-section (slightly darker)
const BORDER    := Color(0.23, 0.23, 0.36)   # #3a3a5c  — .ui-panel border
const HIGHLIGHT := Color(0.94, 0.75, 0.31)   # #f0c050  — .ui-button--accent, gold
const TEXT      := Color(0.91, 0.91, 0.94)   # #e8e8f0  — default text
const MUTED     := Color(0.40, 0.40, 0.55)   #          — section headers, sub-text
const DIM       := Color(0.03, 0.03, 0.06)   # #080810  — box-shadow
const BTN_BG    := Color(0.14, 0.14, 0.23)   # #23233a  — .ui-button default bg
const SUCCESS   := Color(0.25, 0.78, 0.38)   # #40c860  — .ui-button--success
const DANGER    := Color(0.66, 0.29, 0.39)   # #a84b63  — .ui-section--danger


# ── StyleBox factories ───────────────────────────────────────────────────────

## Standard panel background: square corners, 2px border, drop shadow.
static func make_panel_style(
	margins: Vector4 = Vector4(12, 12, 12, 12),
	shadow_sz: int = 8,
	border_col: Color = BORDER
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PANEL
	s.set_corner_radius_all(0)
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.border_color  = border_col
	s.shadow_color  = DIM
	s.shadow_size   = shadow_sz
	s.shadow_offset = Vector2(shadow_sz, shadow_sz)
	s.content_margin_left   = margins.x
	s.content_margin_right  = margins.y
	s.content_margin_top    = margins.z
	s.content_margin_bottom = margins.w
	return s

## Button-style box: solid bg, square corners, 2px border.
static func make_button_style(bg: Color = BTN_BG, border: Color = BORDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(0)
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.border_color = border
	s.content_margin_left   = 8
	s.content_margin_right  = 8
	s.content_margin_top    = 6
	s.content_margin_bottom = 6
	return s


# ── Font helper ───────────────────────────────────────────────────────────────

## Apply the shared pixel font (and optionally size + color) to any Control.
static func apply_font(ctrl: Control, size: int = -1, color: Color = Color(-1, -1, -1)) -> void:
	if ctrl is RichTextLabel:
		ctrl.add_theme_font_override("normal_font", FONT)
		if size > 0:
			ctrl.add_theme_font_size_override("normal_font_size", size)
	else:
		ctrl.add_theme_font_override("font", FONT)
		if size > 0:
			ctrl.add_theme_font_size_override("font_size", size)
	if color.r >= 0.0:
		ctrl.add_theme_color_override("font_color", color)


# ── Widget factories ─────────────────────────────────────────────────────────

## Thin horizontal separator using the border color at the given opacity.
static func make_separator(opacity: float = 0.6) -> HSeparator:
	var sep := HSeparator.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(BORDER.r, BORDER.g, BORDER.b, opacity)
	s.content_margin_top = 1.0
	sep.add_theme_stylebox_override("separator", s)
	return sep

## Section header label (e.g. "CONNECTED PLAYERS", "FINAL STANDINGS").
static func make_section_header(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	apply_font(lbl, 13, MUTED)
	return lbl

## Large centred title (e.g. "DROID-CLASH", ">> GAME OVER <<").
static func make_title(text: String, size: int = 42, color: Color = HIGHLIGHT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl, size, color)
	return lbl

## Centred subtitle (e.g. "L  O  B  B  Y").
static func make_subtitle(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font(lbl, 14, MUTED)
	return lbl

## Small square color swatch used in player rows.
static func make_swatch(color: Color, size: float = 12.0) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.custom_minimum_size = Vector2(size, size)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect
