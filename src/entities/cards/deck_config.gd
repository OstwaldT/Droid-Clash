extends RefCounted

class_name DeckConfig

## Defines the card composition and hand size for a deck.

var composition: Dictionary  ## { Card.TYPE_* : count }
var hand_size:   int

func _init(comp: Dictionary, hs: int = 9) -> void:
	composition = comp
	hand_size   = hs

## Return a named preset. Keys: "standard", "brawler", "speedster".
static func preset(key: String) -> DeckConfig:
	match key:
		"standard":
			return DeckConfig.new({
				Card.TYPE_MOVE:          5,
				Card.TYPE_TURN_LEFT:     3,
				Card.TYPE_TURN_RIGHT:    3,
				Card.TYPE_SPRINT:        2,
				Card.TYPE_180:           2,
				Card.TYPE_ATTACK:        3,
				Card.TYPE_SHOOT:         3,
				Card.TYPE_STRAFE_LEFT:   1,
				Card.TYPE_STRAFE_RIGHT:  1,
				Card.TYPE_SWEEP:         2,
				Card.TYPE_SLAM:          1,
				Card.TYPE_SHOCKWAVE:     1,
			}, 9)
		"brawler":
			return DeckConfig.new({
				Card.TYPE_MOVE:          3,
				Card.TYPE_TURN_LEFT:     3,
				Card.TYPE_TURN_RIGHT:    3,
				Card.TYPE_SPRINT:        1,
				Card.TYPE_180:           2,
				Card.TYPE_ATTACK:        5,
				Card.TYPE_SHOOT:         2,
				Card.TYPE_STRAFE_LEFT:   1,
				Card.TYPE_STRAFE_RIGHT:  1,
				Card.TYPE_SWEEP:         3,
				Card.TYPE_SLAM:          2,
				Card.TYPE_SHOCKWAVE:     2,
			}, 9)
		"speedster":
			return DeckConfig.new({
				Card.TYPE_MOVE:          6,
				Card.TYPE_TURN_LEFT:     3,
				Card.TYPE_TURN_RIGHT:    3,
				Card.TYPE_SPRINT:        4,
				Card.TYPE_180:           2,
				Card.TYPE_ATTACK:        1,
				Card.TYPE_SHOOT:         1,
				Card.TYPE_STRAFE_LEFT:   3,
				Card.TYPE_STRAFE_RIGHT:  3,
				Card.TYPE_SWEEP:         1,
				Card.TYPE_SLAM:          0,
				Card.TYPE_SHOCKWAVE:     1,
			}, 9)
		_:
			push_error("DeckConfig.preset: unknown key '%s'" % key)
			return null
