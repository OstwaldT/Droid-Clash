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

const SLAM_DAMAGE := 30

## Execute a move instruction.
## can_push: if true, attempts to push an occupying robot; if false, treats it as blocked (Rush).
## Returns a Dictionary with at minimum {"result": String}.
## result values: "moved", "fell", "blocked", "pushed", "slammed"
func move_forward(grid: HexGrid, all_robots: Dictionary = {}, can_push: bool = true) -> Dictionary:
	var next_pos = grid.get_neighbor_in_direction(position, direction)
	# Off-edge OR hole → robot falls to their death
	if not grid.is_valid(next_pos) or not grid.has_tile(next_pos):
		take_damage(max_health)
		return {"result": "fell"}
	# Wall/obstacle → blocked
	if not grid.is_walkable(next_pos):
		return {"result": "blocked"}
	# Check for an occupying robot
	var occupant: Robot = null
	for other in all_robots.values():
		if other != self and other.is_alive() and other.position == next_pos:
			occupant = other
			break
	if occupant != null:
		if not can_push:
			return {"result": "blocked"}
		# Try to push the occupant one hex further in the same direction
		var push_to := grid.get_neighbor_in_direction(next_pos, direction)
		# Off the edge or into a hole → occupant falls, pusher moves in
		if not grid.is_valid(push_to) or not grid.has_tile(push_to):
			occupant.take_damage(occupant.max_health)
			occupant.position = push_to  # mark position so animation knows where to fall
			position = next_pos
			return {
				"result":      "pushed_off",
				"pushed_id":   occupant.player_id,
				"pushed_from": next_pos,
				"pushed_to":   push_to,
			}
		# Wall or another robot → slam
		var slam := false
		if not grid.is_walkable(push_to):
			slam = true
		else:
			for other in all_robots.values():
				if other != self and other != occupant and other.is_alive() and other.position == push_to:
					slam = true
					break
		if slam:
			occupant.take_damage(SLAM_DAMAGE)
			return {
				"result":      "slammed",
				"slammed_id":  occupant.player_id,
				"slam_damage": SLAM_DAMAGE,
			}
		else:
			# Push occupant forward, then move self
			var pushed_from := occupant.position
			occupant.position = push_to
			position = next_pos
			return {
				"result":      "pushed",
				"pushed_id":   occupant.player_id,
				"pushed_from": pushed_from,
				"pushed_to":   push_to,
			}
	position = next_pos
	return {"result": "moved"}

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
		"position": EventSerializer.hex_to_dict(position),
		"direction": direction,
		"health": health,
		"maxHealth": max_health,
		"status": status,
		"color": color
	}
