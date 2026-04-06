class_name CardValidator

## Static helper — validates a card submission against game rules.
##
## Returns a result dict:
##   { "ok": true }
##   { "ok": false, "code": "ERROR_CODE", "message": "Human-readable reason" }
##
## All game-rule decisions live here, not in the network layer.

const REQUIRED_CARDS: int = 3

static func validate(
	card_ids: Array[int],
	turn_number: int,
	current_turn: int,
	hand_instance_ids: Array
) -> Dictionary:
	if turn_number != current_turn:
		return _fail("INVALID_TURN", "Wrong turn number")

	if card_ids.size() != REQUIRED_CARDS:
		return _fail("INVALID_CARDS", "Must select exactly %d cards" % REQUIRED_CARDS)

	var seen := {}
	for inst_id in card_ids:
		if inst_id not in hand_instance_ids:
			return _fail("INVALID_CARD", "Card %d not in your hand" % inst_id)
		if inst_id in seen:
			return _fail("DUPLICATE_CARDS", "Cannot play the same card twice")
		seen[inst_id] = true

	return { "ok": true }

static func _fail(code: String, message: String) -> Dictionary:
	return { "ok": false, "code": code, "message": message }
