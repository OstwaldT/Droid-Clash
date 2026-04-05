extends RefCounted

class_name Card

## Base class for all playable cards.
## Each card subclass defines its own name, icon, description, and execute() logic.

## Numeric type IDs — used in the deck, hand serialisation, and event system.
const TYPE_MOVE       := 1
const TYPE_TURN_LEFT  := 2
const TYPE_TURN_RIGHT := 3
const TYPE_ATTACK     := 4

var type_id:     int    = 0
var card_name:   String = ""
var icon:        String = ""
var description: String = ""

## Execute this card's effect on [robot].
## Returns an event Dictionary that will be merged into the turn event log.
## Must include at minimum: {"type": type_id, "success": bool, "message": String}
func execute(robot: Robot, grid: HexGrid, all_robots: Dictionary) -> Dictionary:
	return {"type": type_id, "success": false, "message": "not implemented"}
