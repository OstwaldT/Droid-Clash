extends Node

class_name HexGrid

## Hexagonal grid system using axial coordinates (q, r)
## Reference: https://www.redblobgames.com/grids/hexagons/

const DIRECTIONS = [
	Vector2i(1, 0),    # 0: East
	Vector2i(1, -1),   # 1: Northeast
	Vector2i(0, -1),   # 2: Northwest
	Vector2i(-1, 0),   # 3: West
	Vector2i(-1, 1),   # 4: Southwest
	Vector2i(0, 1)     # 5: Southeast
]

var width: int
var height: int
var obstacles: Array = []

func _init(grid_width: int = 10, grid_height: int = 10) -> void:
	width = grid_width
	height = grid_height

## Get distance between two hex coordinates
func get_distance(from: Vector2i, to: Vector2i) -> int:
	var q_diff = abs(from.x - to.x)
	var r_diff = abs(from.y - to.y)
	var s_diff = abs(-from.x - from.y - (-to.x - to.y))
	return (q_diff + r_diff + s_diff) / 2

## Get all neighbors of a hex coordinate
func get_neighbors(hex: Vector2i) -> Array:
	var neighbors: Array = []
	for direction in DIRECTIONS:
		var neighbor = hex + direction
		if is_valid(neighbor):
			neighbors.append(neighbor)
	return neighbors

## Check if a coordinate is valid within grid bounds
func is_valid(hex: Vector2i) -> bool:
	return hex.x >= 0 and hex.x < width and hex.y >= 0 and hex.y < height

## Check if a hex is an obstacle
func is_obstacle(hex: Vector2i) -> bool:
	return hex in obstacles

## Check if a hex is walkable (valid and not an obstacle)
func is_walkable(hex: Vector2i) -> bool:
	return is_valid(hex) and not is_obstacle(hex)

## Add an obstacle to the grid
func add_obstacle(hex: Vector2i) -> void:
	if is_valid(hex) and hex not in obstacles:
		obstacles.append(hex)

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
func get_range(center: Vector2i, radius: int) -> Array:
	var result: Array = []
	for q in range(-radius, radius + 1):
		for r in range(max(-radius, -q - radius), min(radius, -q + radius) + 1):
			var hex = center + Vector2i(q, r)
			if is_valid(hex):
				result.append(hex)
	return result

## Simple pathfinding using BFS
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
			# Reconstruct path
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
