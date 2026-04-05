extends RefCounted

class_name Deck

## Per-player shuffled deck of cards.
## Each card in the deck is identified by a unique instance ID so that
## duplicate card types in the same hand can be told apart.

const HAND_SIZE := 6

## Distribution: moves are common, attacks are rare.
const COMPOSITION := {
	1: 5,  # Move Forward
	2: 3,  # Turn Left
	3: 3,  # Turn Right
	4: 2,  # Attack
}  # 13 cards total

const CARD_DEFINITIONS := {
	1: {"name": "Move Forward", "icon": "🔼"},
	2: {"name": "Turn Left",    "icon": "↶"},
	3: {"name": "Turn Right",   "icon": "↷"},
	4: {"name": "Attack",       "icon": "💥"},
}

var _draw_pile:    Array = []   # Array of type_id ints
var _discard_pile: Array = []   # Array of type_id ints
var _current_hand: Array = []   # Array of {instance_id, type_id}
var _next_id:      int   = 0    # monotonically increasing instance ID counter

func _init() -> void:
	_build_and_shuffle()

## Build a fresh draw pile from COMPOSITION and shuffle it.
func _build_and_shuffle() -> void:
	var cards: Array = []
	for type_id in COMPOSITION:
		for _i in COMPOSITION[type_id]:
			cards.append(type_id)
	cards.shuffle()
	_draw_pile = cards

## Draw HAND_SIZE cards from the top of the draw pile.
## Reshuffles the discard pile if the draw pile runs low.
func draw_hand() -> Array:
	_ensure_enough_cards()
	_current_hand = []
	for i in HAND_SIZE:
		_current_hand.append({
			"instance_id": _next_id,
			"type_id": _draw_pile[i],
		})
		_next_id += 1
	_draw_pile = _draw_pile.slice(HAND_SIZE)
	return _current_hand.duplicate()

func _ensure_enough_cards() -> void:
	while _draw_pile.size() < HAND_SIZE:
		if _discard_pile.is_empty():
			_build_and_shuffle()
			break
		_draw_pile.append_array(_discard_pile)
		_discard_pile.clear()
		_draw_pile.shuffle()

## After a player submits 3 cards, discard those 3 and return the
## remaining 3 unchosen cards to the bottom of the draw pile.
func resolve_hand(played_instance_ids: Array) -> void:
	var to_match := played_instance_ids.duplicate()
	for card in _current_hand:
		var idx := to_match.find(card["instance_id"])
		if idx != -1:
			to_match.remove_at(idx)
			_discard_pile.append(card["type_id"])
		else:
			_draw_pile.append(card["type_id"])
	_current_hand.clear()

## Look up the type_id for a given instance_id in the current hand.
## Returns -1 if not found.
func get_type_id(instance_id: int) -> int:
	for card in _current_hand:
		if card["instance_id"] == instance_id:
			return card["type_id"]
	return -1

## Returns the set of instance IDs currently in hand (for validation).
func get_hand_instance_ids() -> Array:
	var ids: Array = []
	for card in _current_hand:
		ids.append(card["instance_id"])
	return ids

## Serialise the current hand for network transmission.
func hand_to_array() -> Array:
	var out: Array = []
	for card in _current_hand:
		var defn: Dictionary = CARD_DEFINITIONS.get(card["type_id"], {})
		out.append({
			"id":     card["instance_id"],
			"typeId": card["type_id"],
			"name":   defn.get("name", "Unknown"),
			"icon":   defn.get("icon", "?"),
		})
	return out
