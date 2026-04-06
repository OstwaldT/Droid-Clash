extends RefCounted

class_name DeckConfig

## Defines the card composition and hand size for a deck.
## Create a preset with DeckConfig.make() or use one of the named statics below.

var composition: Dictionary  ## { Card.TYPE_* : count }
var hand_size:   int

func _init(comp: Dictionary, hs: int = 9) -> void:
	composition = comp
	hand_size   = hs

## Instantiate a named preset by key string, e.g. DeckConfig.preset("standard").
## Returns null and logs an error if the key is unknown.
static func preset(key: String) -> DeckConfig:
	match key:
		"standard":   return _standard()
		"brawler":    return _brawler()
		"speedster":  return _speedster()
	_:
		push_error("DeckConfig.preset: unknown key '%s'" % key)
		return null

# ---------------------------------------------------------------------------
# Presets
# ---------------------------------------------------------------------------

## Standard balanced deck — mix of movement, turning, and combat.
static func _standard() -> DeckConfig:
	return DeckConfig.new({
		Card.TYPE_MOVE:       5,
		Card.TYPE_TURN_LEFT:  3,
		Card.TYPE_TURN_RIGHT: 3,
		Card.TYPE_RUSH:       2,
		Card.TYPE_180:        2,
		Card.TYPE_ATTACK:     3,
		Card.TYPE_SHOOT:      3,
	}, 9)

## Brawler — heavy on close-range attack, light on movement.
static func _brawler() -> DeckConfig:
	return DeckConfig.new({
		Card.TYPE_MOVE:       3,
		Card.TYPE_TURN_LEFT:  3,
		Card.TYPE_TURN_RIGHT: 3,
		Card.TYPE_RUSH:       1,
		Card.TYPE_180:        2,
		Card.TYPE_ATTACK:     7,
		Card.TYPE_SHOOT:      2,
	}, 9)

## Speedster — lots of movement and sprint, fewer attacks.
static func _speedster() -> DeckConfig:
	return DeckConfig.new({
		Card.TYPE_MOVE:       7,
		Card.TYPE_TURN_LEFT:  3,
		Card.TYPE_TURN_RIGHT: 3,
		Card.TYPE_RUSH:       5,
		Card.TYPE_180:        2,
		Card.TYPE_ATTACK:     1,
		Card.TYPE_SHOOT:      1,
	}, 9)
