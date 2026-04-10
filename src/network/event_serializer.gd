class_name EventSerializer

## Static helpers — convert domain objects to JSON-safe dictionaries.
##
## All wire-format decisions (key names, Vector2i encoding, etc.) live here.
## MessageHandler and Robot delegate to these rather than hand-rolling dicts.

## Convert a Vector2i hex coordinate to a JSON-safe {q, r} dict.
static func hex_to_dict(v: Vector2i) -> Dictionary:
	return { "q": v.x, "r": v.y }

## Recursively convert a value, replacing Vector2i with {q, r} dicts.
static func _serialize_value(val: Variant) -> Variant:
	if val is Vector2i:
		return hex_to_dict(val)
	if val is Dictionary:
		var d: Dictionary = {}
		for key in val.keys():
			d[key] = _serialize_value(val[key])
		return d
	if val is Array:
		var a: Array = []
		for item in val:
			a.append(_serialize_value(item))
		return a
	return val

## Convert an event array to a JSON-safe array.
## Recursively replaces any Vector2i values with {q, r} dicts.
static func serialize_events(events: Array) -> Array:
	var out: Array = []
	for event in events:
		out.append(_serialize_value(event))
	return out
