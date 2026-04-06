extends RefCounted

class_name Deck

## Per-player shuffled deck of cards.
## Each card in the deck is identified by a unique instance ID so that
## duplicate card types in the same hand can be told apart.
## Pass a DeckConfig to use a custom composition; defaults to the standard preset.

var _config:       DeckConfig
var _draw_pile:    Array = []   # Array of type_id ints
var _discard_pile: Array = []   # Array of type_id ints
var _current_hand: Array = []   # Array of {instance_id: int, type_id: int}
var _next_id:      int   = 0    # monotonically increasing instance ID counter
## Set by draw_hand() — whether the discard was shuffled in mid-deal and at which card index.
var _last_shuffle_info: Dictionary = {"shuffled": false, "cards_before_shuffle": 0}

func _init(config = null) -> void:
	_config = config if config != null else DeckConfig.preset("standard")
	_build_and_shuffle()

## Build a fresh draw pile from the config's composition and shuffle it.
func _build_and_shuffle() -> void:
	var cards: Array = []
	for type_id in _config.composition:
		for _i in _config.composition[type_id]:
			cards.append(type_id)
	cards.shuffle()
	_draw_pile = cards

## Draw HAND_SIZE cards from the top of the draw pile.
## If the draw pile runs out mid-hand, the discard pile is shuffled into a
## fresh draw pile and drawing continues from there.
## Shuffle info is stored in _last_shuffle_info for the message handler to read.
func draw_hand() -> Array:
	_current_hand = []
	_last_shuffle_info = {"shuffled": false, "cards_before_shuffle": 0}
	var needed := _config.hand_size
	var cards_drawn := 0
	while needed > 0:
		if _draw_pile.is_empty():
			if _discard_pile.is_empty():
				_build_and_shuffle()
			else:
				_draw_pile = _discard_pile.duplicate()
				_discard_pile.clear()
				_draw_pile.shuffle()
			if not _last_shuffle_info["shuffled"]:
				_last_shuffle_info["shuffled"] = true
				_last_shuffle_info["cards_before_shuffle"] = cards_drawn
		var take := mini(needed, _draw_pile.size())
		for i in take:
			_current_hand.append({
				"instance_id": _next_id,
				"type_id":     _draw_pile[i],
			})
			_next_id += 1
		_draw_pile = _draw_pile.slice(take)
		cards_drawn += take
		needed -= take
	return _current_hand.duplicate()

## Returns shuffle info from the most recent draw_hand() call.
func get_last_shuffle_info() -> Dictionary:
	return _last_shuffle_info.duplicate()

## After a player submits 3 cards, discard all 9 cards in hand —
## both the 3 played and the 6 unchosen ones go to the discard pile.
func resolve_hand(played_instance_ids: Array) -> void:
	for card in _current_hand:
		_discard_pile.append(card["type_id"])
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

## Returns the number of cards remaining in the draw pile.
func get_draw_pile_size() -> int:
	return _draw_pile.size()

## Returns the number of cards in the discard pile.
func get_discard_pile_size() -> int:
	return _discard_pile.size()

## Serialise the current hand for network transmission.
func hand_to_array() -> Array:
	var out: Array = []
	for entry in _current_hand:
		var card: Card = CardRegistry.create(entry["type_id"])
		out.append({
			"id":          entry["instance_id"],
			"typeId":      entry["type_id"],
			"name":        card.card_name   if card else "Unknown",
			"icon":        card.icon        if card else "?",
			"description": card.description if card else "",
		})
	return out
