extends Node3D

class_name HexGridRenderer

## Owns all hex tile geometry: spawning, materials, coordinate conversion.
## GameBoard3D holds one instance and delegates all grid operations here.

const HEX_SIZE: float = 1.2      # circumradius
const HEX_HEIGHT: float = 0.15   # tile thickness
const TILE_GAP: float = 0.03     # visual gap between tiles

const FLOOR_TINTS: Array[Color] = [
	Color(0.18, 0.20, 0.24),  # cool dark steel
	Color(0.16, 0.22, 0.20),  # teal-grey
	Color(0.22, 0.20, 0.18),  # warm gunmetal
	Color(0.16, 0.18, 0.24),  # indigo-grey
	Color(0.20, 0.22, 0.18),  # olive-grey
]

const WALL_MODEL := "res://assets/scifi/glTF/Columns/Column_Hollow.gltf"

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

# --- Tile spawning ---

func _spawn_floor_tile(q: int, r: int) -> void:
	var root := Node3D.new()
	root.rotation_degrees.y = 30.0
	root.position = hex_to_world(q, r)
	add_child(root)
	_tiles[Vector2i(q, r)] = root

	var tint: Color = FLOOR_TINTS[posmod(q * 3 + r * 7, FLOOR_TINTS.size())]

	var tile := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius    = HEX_SIZE - TILE_GAP
	mesh.bottom_radius = HEX_SIZE - TILE_GAP
	mesh.height        = HEX_HEIGHT
	mesh.radial_segments = 6
	tile.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness    = 0.55
	mat.metallic     = 0.60
	tile.material_override = mat
	root.add_child(tile)

	var ring := MeshInstance3D.new()
	var rmesh := CylinderMesh.new()
	rmesh.top_radius    = HEX_SIZE - TILE_GAP
	rmesh.bottom_radius = HEX_SIZE - TILE_GAP
	rmesh.height        = 0.012
	rmesh.radial_segments = 6
	ring.mesh = rmesh
	ring.position.y = HEX_HEIGHT * 0.5 + 0.006
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color               = Color(0.4, 0.6, 1.0)
	rmat.emission_enabled           = true
	rmat.emission                   = Color(0.2, 0.45, 1.0)
	rmat.emission_energy_multiplier = 0.9
	ring.material_override = rmat
	root.add_child(ring)

func _spawn_wall_tile(q: int, r: int) -> void:
	var packed := load(WALL_MODEL) as PackedScene
	var root := Node3D.new()
	root.position = hex_to_world(q, r)
	add_child(root)
	_tiles[Vector2i(q, r)] = root

	var tint: Color = FLOOR_TINTS[posmod(q * 3 + r * 7, FLOOR_TINTS.size())]

	var base_tile := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius    = HEX_SIZE - TILE_GAP
	base_mesh.bottom_radius = HEX_SIZE - TILE_GAP
	base_mesh.height        = HEX_HEIGHT
	base_mesh.radial_segments = 6
	base_tile.mesh = base_mesh
	base_tile.rotation_degrees.y = 30.0
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = tint
	bmat.roughness    = 0.55
	bmat.metallic     = 0.60
	base_tile.material_override = bmat
	root.add_child(base_tile)

	var ring := MeshInstance3D.new()
	var rmesh := CylinderMesh.new()
	rmesh.top_radius    = HEX_SIZE - TILE_GAP
	rmesh.bottom_radius = HEX_SIZE - TILE_GAP
	rmesh.height        = 0.012
	rmesh.radial_segments = 6
	ring.mesh = rmesh
	ring.rotation_degrees.y = 30.0
	ring.position.y = HEX_HEIGHT * 0.5 + 0.006
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color               = Color(0.4, 0.6, 1.0)
	rmat.emission_enabled           = true
	rmat.emission                   = Color(0.2, 0.45, 1.0)
	rmat.emission_energy_multiplier = 0.9
	ring.material_override = rmat
	root.add_child(ring)

	if packed == null:
		_spawn_wall_column_fallback(root)
		return

	var col := packed.instantiate() as Node3D
	col.scale    = Vector3(1.0, 0.22, 1.0)
	col.position.y = -HEX_HEIGHT * 0.5
	root.add_child(col)

func _spawn_wall_column_fallback(root: Node3D) -> void:
	const WALL_H: float = 1.1
	var wall_mesh := MeshInstance3D.new()
	var wmesh := CylinderMesh.new()
	wmesh.top_radius    = HEX_SIZE * 0.82 - TILE_GAP
	wmesh.bottom_radius = HEX_SIZE * 0.82 - TILE_GAP
	wmesh.height        = WALL_H
	wmesh.radial_segments = 6
	wall_mesh.mesh = wmesh
	wall_mesh.rotation_degrees.y = 30.0
	wall_mesh.position.y = HEX_HEIGHT * 0.5 + WALL_H * 0.5
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.14, 0.13, 0.17)
	wmat.roughness    = 0.92
	wmat.metallic     = 0.12
	wall_mesh.material_override = wmat
	root.add_child(wall_mesh)

func _spawn_pit_marker(q: int, r: int) -> void:
	var root := Node3D.new()
	root.position = hex_to_world(q, r)
	add_child(root)
	_tiles[Vector2i(q, r)] = root
