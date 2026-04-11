extends RefCounted

class_name DeckConfig

## Defines the card composition and hand size for a deck.

var composition: Dictionary  ## { Card.TYPE_* : count }
var hand_size:   int

func _init(comp: Dictionary, hs: int = 9) -> void:
	composition = comp
	hand_size   = hs

## Return a named preset. Keys: "brawler", "sniper", "snake".
static func preset(key: String) -> DeckConfig:
	match key:
		"brawler":
			return DeckConfig.new({
				Card.TYPE_MOVE:          3,
				Card.TYPE_TURN_LEFT:     2,
				Card.TYPE_TURN_RIGHT:    2,
				Card.TYPE_SPRINT:        1,
				Card.TYPE_180:           1,
				Card.TYPE_ATTACK:        5,
				Card.TYPE_SHOOT:         1,
				Card.TYPE_STRAFE_LEFT:   1,
				Card.TYPE_STRAFE_RIGHT:  1,
				Card.TYPE_SWEEP:         3,
				Card.TYPE_SLAM:          2,
				Card.TYPE_SHOCKWAVE:     2,
				Card.TYPE_DISORIENT:     0,
			}, 9)
		"sniper":
			return DeckConfig.new({
				Card.TYPE_MOVE:          3,
				Card.TYPE_TURN_LEFT:     3,
				Card.TYPE_TURN_RIGHT:    3,
				Card.TYPE_SPRINT:        2,
				Card.TYPE_180:           1,
				Card.TYPE_ATTACK:        1,
				Card.TYPE_SHOOT:         5,
				Card.TYPE_STRAFE_LEFT:   2,
				Card.TYPE_STRAFE_RIGHT:  2,
				Card.TYPE_SWEEP:         0,
				Card.TYPE_SLAM:          0,
				Card.TYPE_SHOCKWAVE:     1,
				Card.TYPE_DISORIENT:     3,
			}, 9)
		"snake":
			return DeckConfig.new({
				Card.TYPE_MOVE:          4,
				Card.TYPE_TURN_LEFT:     3,
				Card.TYPE_TURN_RIGHT:    3,
				Card.TYPE_SPRINT:        2,
				Card.TYPE_180:           2,
				Card.TYPE_ATTACK:        1,
				Card.TYPE_SHOOT:         1,
				Card.TYPE_STRAFE_LEFT:   3,
				Card.TYPE_STRAFE_RIGHT:  3,
				Card.TYPE_SWEEP:         1,
				Card.TYPE_SLAM:          0,
				Card.TYPE_SHOCKWAVE:     2,
				Card.TYPE_DISORIENT:     2,
			}, 9)
		_:
			push_error("DeckConfig.preset: unknown key '%s'" % key)
			return null
