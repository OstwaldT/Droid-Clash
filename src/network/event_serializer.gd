class_name EventSerializer

## Static helpers — convert domain objects to JSON-safe dictionaries.
##
## All wire-format decisions (key names, Vector2i encoding, etc.) live here.
## MessageHandler and Robot delegate to these rather than hand-rolling dicts.

## Convert a Vector2i hex coordinate to a JSON-safe {q, r} dict.
static func hex_to_dict(v: Vector2i) -> Dictionary:
	return { "q": v.x, "r": v.y }

## Convert an event array to a JSON-safe array.
## Replaces any Vector2i values with {q, r} dicts; all other types pass through.
static func serialize_events(events: Array) -> Array:
	var out: Array = []
	for event in events:
		var e: Dictionary = {}
		for key in event.keys():
			var val = event[key]
			e[key] = hex_to_dict(val) if val is Vector2i else val
		out.append(e)
	return out
