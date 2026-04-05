extends Node3D

class_name RobotVisual

const HEALTH_BAR_WIDTH: float = 0.8
const HEALTH_BAR_DEPTH: float = 0.06
const HEALTH_BAR_Y: float = 1.55
const LABEL_Y: float = 1.9

var player_id: int
var robot_color: Color

var _body_mesh: MeshInstance3D
var _head_mesh: MeshInstance3D
var _direction_indicator: MeshInstance3D
var _hp_bar_bg: MeshInstance3D
var _hp_bar_fill: MeshInstance3D
var _name_label: Label3D
var _is_dead: bool = false

func setup(pid: int, pname: String, color: Color) -> void:
	player_id = pid
	robot_color = color
	name = "Robot_%d" % pid

	_build_body(color)
	_build_head(color)
	_build_direction_indicator()
	_build_health_bar(color)
	_build_label(pname)

# --- Build helpers ---

func _build_body(color: Color) -> void:
	_body_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.35
	mesh.bottom_radius = 0.35
	mesh.height = 0.7
	mesh.radial_segments = 12
	_body_mesh.mesh = mesh
	_body_mesh.position.y = 0.35

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.metallic = 0.2
	_body_mesh.material_override = mat
	add_child(_body_mesh)

func _build_head(color: Color) -> void:
	_head_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.28, 0.28, 0.28)
	_head_mesh.mesh = mesh
	_head_mesh.position.y = 0.98

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.3)
	mat.roughness = 0.5
	mat.metallic = 0.3
	_head_mesh.material_override = mat
	add_child(_head_mesh)

func _build_direction_indicator() -> void:
	## Small white wedge/box that always shows which way the robot faces.
	_direction_indicator = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.1, 0.08, 0.3)
	_direction_indicator.mesh = mesh
	# Sit on top of body, offset forward along local +z
	_direction_indicator.position = Vector3(0.0, 0.75, 0.28)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = Color.WHITE * 0.4
	_direction_indicator.material_override = mat
	add_child(_direction_indicator)

func _build_health_bar(color: Color) -> void:
	# Dark background bar
	_hp_bar_bg = MeshInstance3D.new()
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(HEALTH_BAR_WIDTH, HEALTH_BAR_DEPTH, HEALTH_BAR_DEPTH)
	_hp_bar_bg.mesh = bg_mesh
	_hp_bar_bg.position = Vector3(0.0, HEALTH_BAR_Y, 0.0)
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.15, 0.15)
	_hp_bar_bg.material_override = bg_mat
	add_child(_hp_bar_bg)

	# Coloured fill bar (rendered slightly in front of bg)
	_hp_bar_fill = MeshInstance3D.new()
	var fill_mesh = BoxMesh.new()
	fill_mesh.size = Vector3(HEALTH_BAR_WIDTH, HEALTH_BAR_DEPTH, HEALTH_BAR_DEPTH + 0.01)
	_hp_bar_fill.mesh = fill_mesh
	_hp_bar_fill.position = Vector3(0.0, HEALTH_BAR_Y, 0.0)
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.1, 0.85, 0.2)
	fill_mat.emission_enabled = true
	fill_mat.emission = Color(0.0, 0.3, 0.0)
	_hp_bar_fill.material_override = fill_mat
	add_child(_hp_bar_fill)

	# Thin colored outline matching robot color for identity
	var outline = MeshInstance3D.new()
	var out_mesh = BoxMesh.new()
	out_mesh.size = Vector3(HEALTH_BAR_WIDTH + 0.04, HEALTH_BAR_DEPTH + 0.04, HEALTH_BAR_DEPTH * 0.5)
	outline.mesh = out_mesh
	outline.position = Vector3(0.0, HEALTH_BAR_Y, -HEALTH_BAR_DEPTH * 0.3)
	var out_mat = StandardMaterial3D.new()
	out_mat.albedo_color = color
	outline.material_override = out_mat
	add_child(outline)

func _build_label(pname: String) -> void:
	_name_label = Label3D.new()
	_name_label.text = pname
	_name_label.position.y = LABEL_Y
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.pixel_size = 0.005
	_name_label.font_size = 28
	_name_label.outline_size = 6
	_name_label.modulate = Color.WHITE
	_name_label.no_depth_test = true
	add_child(_name_label)

# --- Public API ---

## Smoothly move the robot to a new world position.
func move_to(world_pos: Vector3, animate: bool = true) -> void:
	if animate and not _is_dead:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", world_pos, 0.75)
	else:
		position = world_pos

## Update health bar appearance based on current / max HP.
func update_health(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return

	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var fill_width: float = HEALTH_BAR_WIDTH * ratio

	var fill_mesh := _hp_bar_fill.mesh as BoxMesh
	fill_mesh.size = Vector3(fill_width, HEALTH_BAR_DEPTH, HEALTH_BAR_DEPTH + 0.01)

	# Keep left edge pinned: center_x = -half_bg + half_fill
	_hp_bar_fill.position.x = 0.4 * (ratio - 1.0)

	# Green → yellow → red gradient
	var fill_mat := _hp_bar_fill.material_override as StandardMaterial3D
	if ratio > 0.6:
		fill_mat.albedo_color = Color(0.1, 0.85, 0.2)
		fill_mat.emission = Color(0.0, 0.3, 0.0)
	elif ratio > 0.3:
		fill_mat.albedo_color = Color(0.9, 0.8, 0.05)
		fill_mat.emission = Color(0.2, 0.2, 0.0)
	else:
		fill_mat.albedo_color = Color(0.9, 0.15, 0.05)
		fill_mat.emission = Color(0.3, 0.0, 0.0)

## Smoothly rotate to face a given hex direction.
func set_robot_direction(dir: int, animate: bool = false) -> void:
	# Flat-top hex direction deltas → world (x, z) offsets
	# Dir 0 East=(1,0), 1 NE=(1,-1), 2 NW=(0,-1), 3 W=(-1,0), 4 SW=(-1,1), 5 SE=(0,1)
	const DQ := [1, 1, 0, -1, -1, 0]
	const DR := [0, -1, -1, 0, 1, 1]
	const HEX_SIZE := 1.2
	var dx: float = HEX_SIZE * 1.5 * float(DQ[dir])
	var dz: float = HEX_SIZE * (sqrt(3.0) / 2.0 * float(DQ[dir]) + sqrt(3.0) * float(DR[dir]))
	var target_angle := atan2(dz, dx) + PI / 2.0
	if animate:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "rotation:y", target_angle, 0.28)
	else:
		rotation.y = target_angle

## Brief forward-lunge to indicate a blocked move attempt.
func bump_blocked() -> void:
	if _is_dead:
		return
	var fwd := position + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 0.22
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", fwd, 0.12)
	tween.tween_property(self, "position", position, 0.18)

## Scale pulse when this robot fires an attack.
func flash_attack() -> void:
	if _is_dead:
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.18, 1.18, 1.18), 0.12)
	tween.tween_property(self, "scale", Vector3.ONE, 0.20)

## Red flash when this robot is hit.
func flash_hit() -> void:
	if _is_dead:
		return
	var mat := _body_mesh.material_override as StandardMaterial3D
	var original := robot_color
	mat.albedo_color = Color(1.0, 0.15, 0.15)
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color", original, 0.40)

## Grey out and stop the robot visually when it dies.
func mark_dead() -> void:
	_is_dead = true
	var grey := Color(0.28, 0.28, 0.28)
	(_body_mesh.material_override as StandardMaterial3D).albedo_color = grey
	(_head_mesh.material_override as StandardMaterial3D).albedo_color = grey.darkened(0.2)
	(_direction_indicator.material_override as StandardMaterial3D).albedo_color = Color(0.4, 0.4, 0.4)
	(_direction_indicator.material_override as StandardMaterial3D).emission_enabled = false
	_name_label.modulate = Color(0.45, 0.45, 0.45)
