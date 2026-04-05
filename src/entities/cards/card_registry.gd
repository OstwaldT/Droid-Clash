extends RefCounted

class_name CardRegistry

## Central registry for all card types.
## Use create() to get a card instance; COMPOSITION defines deck contents.

## How many of each card type appear in one player's deck.
const COMPOSITION: Dictionary = {
	Card.TYPE_MOVE:       5,  # Move Forward  — common
	Card.TYPE_TURN_LEFT:  3,  # Turn Left
	Card.TYPE_TURN_RIGHT: 3,  # Turn Right
	Card.TYPE_ATTACK:     2,  # Attack        — rare
}

## Return a fresh Card instance for [type_id], or null if unknown.
static func create(type_id: int) -> Card:
	match type_id:
		Card.TYPE_MOVE:       return CardMove.new()
		Card.TYPE_TURN_LEFT:  return CardTurnLeft.new()
		Card.TYPE_TURN_RIGHT: return CardTurnRight.new()
		Card.TYPE_ATTACK:     return CardAttack.new()
	push_error("CardRegistry.create: unknown type_id %d" % type_id)
	return null
