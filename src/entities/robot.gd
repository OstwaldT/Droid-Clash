extends Node

class_name Robot

var player_id: int
var bot_name: String
var position: Vector2i
var direction: int = 0  # 0-5 (hex directions)
var health: int = 100
var max_health: int = 100
var status: String = "alive"  # alive, dead
var color: String = "#ffffff"

func _init(pid: int, pname: String, start_pos: Vector2i, pcolor: String = "#ffffff") -> void:
	player_id = pid
	bot_name = pname
	position = start_pos
	color = pcolor
	health = max_health

## Execute a move instruction.
## Returns "moved", "blocked", or "fell" (stepped off the grid).
## all_robots: Dictionary of player_id -> Robot, used to detect occupancy.
func move_forward(grid: HexGrid, all_robots: Dictionary = {}) -> String:
	var next_pos = grid.get_neighbor_in_direction(position, direction)
	if not grid.is_valid(next_pos):
		take_damage(max_health)
		return "fell"
	for other in all_robots.values():
		if other != self and other.is_alive() and other.position == next_pos:
			return "blocked"
	if grid.is_walkable(next_pos):
		position = next_pos
		return "moved"
	return "blocked"

## Turn left (counter-clockwise)
func turn_left() -> void:
	direction = (direction + 1) % 6

## Turn right (clockwise)
func turn_right() -> void:
	direction = (direction - 1 + 6) % 6

## Take damage
func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		status = "dead"

## Heal
func heal(amount: int) -> void:
	health = min(health + amount, max_health)

## Check if alive
func is_alive() -> bool:
	return status == "alive" and health > 0

## Serialize to dictionary for transmission
func to_dict() -> Dictionary:
	return {
		"playerId": player_id,
		"bot_name": bot_name,
		"position": {"q": position.x, "r": position.y},
		"direction": direction,
		"health": health,
		"maxHealth": max_health,
		"status": status,
		"color": color
	}
