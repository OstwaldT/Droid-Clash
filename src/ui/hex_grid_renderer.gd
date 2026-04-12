extends Node3D

class_name HexGridRenderer

## Owns all hex tile geometry: spawning, materials, coordinate conversion.
## GameBoard3D holds one instance and delegates all grid operations here.

const HEX_SIZE: float = 1.2      # circumradius
const HEX_HEIGHT: float = 0.15   # tile thickness
const TILE_GAP: float = 0.03     # visual gap between tiles

const FLOOR_TINTS: Array[Color] = [
	Color("#7A6A52"),  # sandstone
	Color("#4A6741"),  # mossy green
	Color("#5C4033"),  # clay brown
	Color("#3D4A5C"),  # slate blue
	Color("#586645"),  # fern
]

var _tiles: Dictionary = {}  # Vector2i -> Node3D

# --- Public API ---

## Spawn all tiles for the given grid. Call once on setup, and again after clear() on rematch.
func generate(grid: HexGrid) -> void:
	for hex in grid.get_all_hexes():
		if grid.is_hole(hex):
			_spawn_pit_marker(hex.x, hex.y)
		elif grid.is_obstacle(hex):
			_spawn_wall_tile(hex.x, hex.y)
		else:
			_spawn_floor_tile(hex.x, hex.y)

## Remove all tile nodes and clear the lookup dict.
func clear() -> void:
	for tile in _tiles.values():
		tile.queue_free()
	_tiles.clear()

# --- Coordinate conversion (flat-top axial) ---

## Convert axial (q, r) to a world Vector3 at ground level.
func hex_to_world(q: int, r: int) -> Vector3:
	var x: float = HEX_SIZE * (3.0 / 2.0 * q)
	var z: float = HEX_SIZE * (sqrt(3.0) / 2.0 * q + sqrt(3.0) * r)
	return Vector3(x, 0.0, z)

## World position of a robot standing on a tile (y = tile top surface).
func hex_to_robot_pos(q: int, r: int) -> Vector3:
	var pos := hex_to_world(q, r)
	pos.y = HEX_HEIGHT
	return pos

## Centre of the board in world space (axial origin is always centre).
func get_grid_center() -> Vector3:
	return hex_to_world(0, 0)

# --- Helpers ---

func _floor_tint(q: int, r: int) -> Color:
	return FLOOR_TINTS[posmod(q * 3 + r * 7, FLOOR_TINTS.size())]

func _matte_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = 1.0
	mat.metallic     = 0.0
	return mat

func _hex_cylinder() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius    = HEX_SIZE - TILE_GAP
	mesh.bottom_radius = HEX_SIZE - TILE_GAP
	mesh.height        = HEX_HEIGHT
	mesh.radial_segments = 6
	return mesh

func _add_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _matte_mat(color)
	parent.add_child(mi)

# --- Tile spawning ---

func _spawn_floor_tile(q: int, r: int) -> void:
	var root := Node3D.new()
	root.rotation_degrees.y = 30.0
	root.position = hex_to_world(q, r)
	add_child(root)
	_tiles[Vector2i(q, r)] = root

	var tile := MeshInstance3D.new()
	tile.mesh = _hex_cylinder()
	tile.material_override = _matte_mat(_floor_tint(q, r))
	root.add_child(tile)

func _spawn_wall_tile(q: int, r: int) -> void:
	var root := Node3D.new()
	root.position = hex_to_world(q, r)
	add_child(root)
	_tiles[Vector2i(q, r)] = root

	var tint: Color = _floor_tint(q, r)

	var base_tile := MeshInstance3D.new()
	base_tile.mesh = _hex_cylinder()
	base_tile.rotation_degrees.y = 30.0
	base_tile.material_override = _matte_mat(tint)
	root.add_child(base_tile)

	# Voxel tower: base slab → mid block → top cap
	_add_box(root, Vector3(0.80, 0.15, 0.80), Vector3(0.0, 0.08, 0.0), tint)
	_add_box(root, Vector3(0.60, 0.50, 0.60), Vector3(0.0, 0.40, 0.0), tint.lightened(0.15))
	_add_box(root, Vector3(0.50, 0.18, 0.50), Vector3(0.0, 0.74, 0.0), Color("#F0C050"))

func _spawn_pit_marker(q: int, r: int) -> void:
	var root := Node3D.new()
	root.position = hex_to_world(q, r)
	add_child(root)
	_tiles[Vector2i(q, r)] = root

	# Sunken dark floor marks the void
	var pit := MeshInstance3D.new()
	pit.mesh = _hex_cylinder()
	pit.rotation_degrees.y = 30.0
	pit.position.y = -HEX_HEIGHT
	pit.material_override = _matte_mat(Color("#0F0F12"))
	root.add_child(pit)
