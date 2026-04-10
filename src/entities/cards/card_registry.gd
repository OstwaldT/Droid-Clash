extends RefCounted

class_name CardRegistry

## Central registry for all card types.
## Use create() to get a fresh Card instance by type ID.
## Deck composition is defined in DeckConfig.

## Return a fresh Card instance for [type_id], or null if unknown.
static func create(type_id: int) -> Card:
	match type_id:
		Card.TYPE_MOVE:          return CardMove.new()
		Card.TYPE_TURN_LEFT:     return CardTurnLeft.new()
		Card.TYPE_TURN_RIGHT:    return CardTurnRight.new()
		Card.TYPE_SPRINT:        return CardSprint.new()
		Card.TYPE_180:           return Card180.new()
		Card.TYPE_ATTACK:        return CardAttack.new()
		Card.TYPE_SHOOT:         return CardShoot.new()
		Card.TYPE_STRAFE_LEFT:   return CardStrafeLeft.new()
		Card.TYPE_STRAFE_RIGHT:  return CardStrafeRight.new()
		Card.TYPE_SWEEP:         return CardSweep.new()
		Card.TYPE_SLAM:          return CardSlam.new()
		Card.TYPE_SHOCKWAVE:     return CardShockwave.new()
	push_error("CardRegistry.create: unknown type_id %d" % type_id)
	return null
