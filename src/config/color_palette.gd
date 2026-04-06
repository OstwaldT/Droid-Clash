extends Node

## Singleton: autoloaded as "ColorPalette"
## Single source of truth for all player slot colours.
##
## game_manager.gd uses .as_hex()  → "#rrggbb" strings
## game_board_3d.gd / lobby_panel.gd use .as_color() → Color objects

const _HEX: Array = [
	"#e63333",  # 0 Red
	"#3385eb",  # 1 Blue
	"#33cc4d",  # 2 Green
	"#ebb814",  # 3 Yellow
	"#b82eeb",  # 4 Purple
	"#f28014",  # 5 Orange
	"#14d1d1",  # 6 Cyan
	"#eb61b8",  # 7 Pink
]

## Hex strings — use for storing/sending colours over the network.
const PLAYER_COLORS_HEX: Array = _HEX

## Color objects — use for rendering (materials, labels, swatches).
var PLAYER_COLORS: Array = []

func _ready() -> void:
	for h in _HEX:
		PLAYER_COLORS.append(Color(h))

## Return the Color for a given player slot index (wraps around).
func color_for(slot: int) -> Color:
	return PLAYER_COLORS[slot % PLAYER_COLORS.size()]

## Return the hex string for a given player slot index (wraps around).
func hex_for(slot: int) -> String:
	return _HEX[slot % _HEX.size()]
