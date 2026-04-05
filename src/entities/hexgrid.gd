extends Node

class_name HexGrid

## Hexagonal grid system using axial coordinates (q, r).
## The board is a regular hexagon: max(|q|, |r|, |q+r|) <= radius,
## where radius = side_length - 1.
## Reference: https://www.redblobgames.com/grids/hexagons/

const DIRECTIONS = [
	Vector2i(1, 0),    # 0: East
	Vector2i(1, -1),   # 1: Northeast
	Vector2i(0, -1),   # 2: Northwest
	Vector2i(-1, 0),   # 3: West
	Vector2i(-1, 1),   # 4: Southwest
	Vector2i(0, 1)     # 5: Southeast
]

var radius: int       # max hex distance from centre (= side_length - 1)
var obstacles: Array = []   # wall hexes: block movement, tile is rendered tall
var holes: Array = []       # pit hexes: no tile rendered, robot falls in

func _init(side_length: int = 5) -> void:
	radius = side_length - 1

# --- Geometry ---

## Get distance between two hex coordinates
func get_distance(from: Vector2i, to: Vector2i) -> int:
	var q_diff = abs(from.x - to.x)
	var r_diff = abs(from.y - to.y)
	var s_diff = abs(-from.x - from.y - (-to.x - to.y))
	return (q_diff + r_diff + s_diff) / 2

## Get all geometrically valid neighbors (inside boundary, ignores holes/walls).
func get_neighbors(hex: Vector2i) -> Array:
	var neighbors: Array = []
	for direction in DIRECTIONS:
		var neighbor = hex + direction
		if is_valid(neighbor):
			neighbors.append(neighbor)
	return neighbors

## Check if a coordinate is within the hexagonal board boundary.
func is_valid(hex: Vector2i) -> bool:
	return abs(hex.x) <= radius and abs(hex.y) <= radius and abs(hex.x + hex.y) <= radius

## Return every valid hex on the board (boundary only — includes holes/walls).
func get_all_hexes() -> Array:
	var result: Array = []
	for q in range(-radius, radius + 1):
		var r_min: int = max(-radius, -q - radius)
		var r_max: int = min(radius, -q + radius)
		for r in range(r_min, r_max + 1):
			result.append(Vector2i(q, r))
	return result

## Return every hex that has a physical tile (excludes holes).
func get_all_tiles() -> Array:
	return get_all_hexes().filter(func(h: Vector2i) -> bool: return not is_hole(h))

# --- Tile state ---

## True if hex is a hole (tile missing — robot falls in).
func is_hole(hex: Vector2i) -> bool:
	return hex in holes

## True if hex has a physical tile (valid boundary AND not a hole).
func has_tile(hex: Vector2i) -> bool:
	return is_valid(hex) and not is_hole(hex)

## True if hex is a wall/obstacle (tile exists but movement is blocked).
func is_obstacle(hex: Vector2i) -> bool:
	return hex in obstacles

## True if a robot can stand on this hex (has tile, not a wall, in bounds).
func is_walkable(hex: Vector2i) -> bool:
	return has_tile(hex) and not is_obstacle(hex)

## Pick a random walkable hex (no hole, no wall).
func get_random_valid_hex() -> Vector2i:
	var walkable: Array = get_all_hexes().filter(func(h: Vector2i) -> bool: return is_walkable(h))
	return walkable[randi() % walkable.size()]

## Add an obstacle/wall to the grid.
func add_obstacle(hex: Vector2i) -> void:
	if is_valid(hex) and hex not in obstacles:
		obstacles.append(hex)

# --- Procedural map generation ---

## Generate a random map: scatter holes (pits) and wall obstacles.
## Keeps a safe zone of distance <= safe_radius from the centre.
## Ensures all walkable tiles remain connected after each placement.
func generate_map(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	holes.clear()
	obstacles.clear()

	var safe_radius := 1
	var all := get_all_hexes()

	# Candidates: tiles outside the safe zone
	var candidates: Array = all.filter(func(h: Vector2i) -> bool:
		return get_distance(Vector2i.ZERO, h) > safe_radius
	)
	# Shuffle for random ordering
	candidates.shuffle()

	# Place holes (~15% of candidates, in organic clusters of 1-3 tiles)
	var target_holes := max(4, int(candidates.size() * 0.15))
	var i := 0
	while holes.size() < target_holes and i < candidates.size():
		var seed_hex: Vector2i = candidates[i]
		i += 1
		if seed_hex in holes:
			continue
		# Grow a small cluster from this seed
		var cluster: Array = [seed_hex]
		var cluster_size: int = rng.randi_range(1, 3)
		for _g in range(cluster_size - 1):
			var source: Vector2i = cluster[rng.randi() % cluster.size()]
			var nbrs := get_neighbors(source)
			nbrs.shuffle()
			for n in nbrs:
				if n not in cluster and n in candidates and n not in holes:
					cluster.append(n)
					break
		# Add cluster tiles one-by-one, checking connectivity each time
		for h in cluster:
			if holes.size() >= target_holes:
				break
			holes.append(h)
			if not _is_connected():
				holes.pop_back()

	# Place walls (~10% of remaining walkable candidates)
	var wall_candidates: Array = candidates.filter(func(h: Vector2i) -> bool:
		return not is_hole(h)
	)
	wall_candidates.shuffle()
	var target_walls := max(3, int(wall_candidates.size() * 0.10))
	for h in wall_candidates:
		if obstacles.size() >= target_walls:
			break
		obstacles.append(h)
		if not _is_connected():
			obstacles.pop_back()

## BFS connectivity check: all walkable hexes must be reachable from one another.
func _is_connected() -> bool:
	var all_walkable: Array = get_all_hexes().filter(func(h: Vector2i) -> bool: return is_walkable(h))
	if all_walkable.is_empty():
		return false
	var start: Vector2i = all_walkable[0]
	var visited := {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for n in get_neighbors(current):
			if n not in visited and is_walkable(n):
				visited[n] = true
				queue.append(n)
	return visited.size() == all_walkable.size()

# --- Navigation helpers ---

## Get direction from one hex to another (0-5)
func get_direction(from: Vector2i, to: Vector2i) -> int:
	var delta = to - from
	for i in range(DIRECTIONS.size()):
		if DIRECTIONS[i] == delta:
			return i
	return -1

## Get hex in a specific direction from a position
func get_neighbor_in_direction(hex: Vector2i, direction: int) -> Vector2i:
	if direction < 0 or direction >= DIRECTIONS.size():
		return hex
	return hex + DIRECTIONS[direction]

## Get all hexes within a certain distance
func get_range(center: Vector2i, dist: int) -> Array:
	var result: Array = []
	for q in range(-dist, dist + 1):
		for r in range(max(-dist, -q - dist), min(dist, -q + dist) + 1):
			var hex = center + Vector2i(q, r)
			if is_valid(hex):
				result.append(hex)
	return result

## Simple pathfinding using BFS (walkable tiles only)
func find_path(start: Vector2i, end: Vector2i) -> Array:
	if not is_walkable(end):
		return []
	if start == end:
		return [start]
	var queue: Array = [start]
	var visited = {start: true}
	var parent_map = {}
	while queue.size() > 0:
		var current = queue.pop_front()
		if current == end:
			var path: Array = []
			var node = end
			while node in parent_map:
				path.push_front(node)
				node = parent_map[node]
			path.push_front(start)
			return path
		for neighbor in get_neighbors(current):
			if neighbor not in visited and is_walkable(neighbor):
				visited[neighbor] = true
				parent_map[neighbor] = current
				queue.append(neighbor)
	return []
