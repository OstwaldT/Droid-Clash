extends Node3D

class_name RobotVisualBase

## Handles construction and state-sync for a robot's 3D representation.
## Animation effects are in the RobotVisual subclass.
## Robot body is built procedurally from BoxMesh parts (voxel style).

const MOVE_DURATION: float = 0.75
const LABEL_Y:   float = 1.70
const HP_BAR_Y:  float = 2.00
const HP_BAR_W:  float = 1.40
const HP_BAR_H:  float = 0.12

var player_id:   int
var robot_color: Color

var _model_root:   Node3D         = null
var _eyes_root:    Node3D         = null
var _hp_bar_bg:    MeshInstance3D
var _hp_bar_fill:  MeshInstance3D
var _name_label:   Label3D
var _is_dead:      bool = false

# --- Setup ---

func setup(pid: int, pname: String, color: Color) -> void:
	player_id   = pid
	robot_color = color
	name        = "Robot_%d" % pid
	_build_model(pid, color)
	_build_health_bar()
	_build_label(pname)
	rotation.y = 0.0  # direction set by set_robot_direction()

# --- Build helpers ---

func _build_model(_pid: int, color: Color) -> void:
	_model_root = Node3D.new()
	add_child(_model_root)

	# Parts use a neutral grey base stored on the mesh's own material so that
	# _tint_meshes(color) multiplies it cleanly: grey 1.0 = full player color,
	# grey 0.55 = dark shadow tone, etc.
	_model_root.add_child(_make_box(Vector3(1.00, 0.60, 0.76), Vector3( 0.00, 0.40, 0.00), 1.00))  # body
	_model_root.add_child(_make_box(Vector3(0.60, 0.48, 0.56), Vector3( 0.00, 0.98, 0.00), 0.82))  # head
	_model_root.add_child(_make_box(Vector3(0.20, 0.20, 1.10), Vector3(-0.44, 0.10, 0.00), 0.55))  # left track
	_model_root.add_child(_make_box(Vector3(0.20, 0.20, 1.10), Vector3( 0.44, 0.10, 0.00), 0.55))  # right track
	_model_root.add_child(_make_box(Vector3(0.08, 0.30, 0.08), Vector3( 0.20, 1.38, 0.00), 0.65))  # antenna
	_tint_meshes(_model_root, color)

	# Eyes: emissive cyan glow — stored separately so _tint_meshes ignores them.
	_eyes_root = Node3D.new()
	add_child(_eyes_root)
	_eyes_root.add_child(_make_eye(Vector3(-0.16, 0.98, 0.29)))
	_eyes_root.add_child(_make_eye(Vector3( 0.16, 0.98, 0.29)))

## Create a tintable voxel part. The grey value sets the neutral base color so
## _tint_meshes can multiply it by the player color to get relative shading.
func _make_box(size: Vector3, pos: Vector3, gray: float) -> MeshInstance3D:
	var mi  := MeshInstance3D.new()
	var bm  := BoxMesh.new()
	bm.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(gray, gray, gray)
	mat.roughness    = 0.95
	mat.metallic     = 0.05
	bm.material = mat  # on mesh (not override) so _tint_meshes reads it via surface_get_material
	mi.mesh     = bm
	mi.position = pos
	return mi

## Create an emissive eye box — fixed cyan glow, never tinted by player color.
func _make_eye(pos: Vector3) -> MeshInstance3D:
	var mi  := MeshInstance3D.new()
	var bm  := BoxMesh.new()
	bm.size = Vector3(0.14, 0.10, 0.06)
	var mat := StandardMaterial3D.new()
	mat.albedo_color               = Color(0.85, 0.95, 1.00)
	mat.emission_enabled           = true
	mat.emission                   = Color(0.40, 0.75, 1.00)
	mat.emission_energy_multiplier = 2.5
	mi.material_override = mat  # override so _tint_meshes (which walks _model_root) ignores it
	mi.mesh     = bm
	mi.position = pos
	return mi

func _build_health_bar() -> void:
	_hp_bar_bg = MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(HP_BAR_W + 0.06, HP_BAR_H + 0.04)
	_hp_bar_bg.mesh = bg_mesh
	_hp_bar_bg.position = Vector3(0.0, HP_BAR_Y, 0.0)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color   = Color(0.10, 0.10, 0.10)
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bg_mat.no_depth_test  = true
	_hp_bar_bg.material_override = bg_mat
	add_child(_hp_bar_bg)

	_hp_bar_fill = MeshInstance3D.new()
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(HP_BAR_W, HP_BAR_H)
	_hp_bar_fill.mesh = fill_mesh
	_hp_bar_fill.position = Vector3(0.0, HP_BAR_Y, 0.0)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color    = Color(0.18, 0.88, 0.32)
	fill_mat.billboard_mode  = BaseMaterial3D.BILLBOARD_ENABLED
	fill_mat.no_depth_test   = true
	fill_mat.render_priority = 1
	_hp_bar_fill.material_override = fill_mat
	add_child(_hp_bar_fill)

func _build_label(pname: String) -> void:
	_name_label = Label3D.new()
	_name_label.text          = pname
	_name_label.position.y    = LABEL_Y
	_name_label.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.pixel_size    = 0.005
	_name_label.font          = UITheme.FONT
	_name_label.font_size     = 32
	_name_label.outline_size  = 6
	_name_label.modulate      = Color.WHITE
	_name_label.no_depth_test = true
	add_child(_name_label)

# --- Mesh helpers ---

func _walk_meshes(node: Node, cb: Callable) -> void:
	if node is MeshInstance3D:
		cb.call(node as MeshInstance3D)
	for child in node.get_children():
		_walk_meshes(child, cb)

func _tint_meshes(node: Node, color: Color) -> void:
	_walk_meshes(node, func(mi: MeshInstance3D) -> void:
		if mi.mesh == null:
			return
		var surf_count: int = mi.mesh.get_surface_count()
		for i in surf_count:
			var mat := mi.mesh.surface_get_material(i)
			var new_mat := StandardMaterial3D.new()
			if mat is StandardMaterial3D:
				var src := mat as StandardMaterial3D
				new_mat.albedo_color = src.albedo_color * color
				new_mat.roughness    = src.roughness
				new_mat.metallic     = src.metallic
			else:
				new_mat.albedo_color = color
				new_mat.roughness    = 0.95
				new_mat.metallic     = 0.05
			mi.set_surface_override_material(i, new_mat)
	)

# --- State sync (called each time game state is applied to the visual) ---

func move_to(world_pos: Vector3, animate: bool = true, duration: float = MOVE_DURATION) -> void:
	if animate and not _is_dead:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", world_pos, duration)
	else:
		position = world_pos

func update_health(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var fill_mesh := _hp_bar_fill.mesh as QuadMesh
	fill_mesh.size = Vector2(HP_BAR_W * ratio, HP_BAR_H)
	_hp_bar_fill.position.x = HP_BAR_W * (ratio - 1.0) / 2.0
	var fill_mat := _hp_bar_fill.material_override as StandardMaterial3D
	if ratio > 0.6:
		fill_mat.albedo_color = Color(0.18, 0.88, 0.32)
	elif ratio > 0.3:
		fill_mat.albedo_color = Color(0.90, 0.80, 0.05)
	else:
		fill_mat.albedo_color = Color(0.90, 0.15, 0.05)

func set_robot_direction(dir: int, animate: bool = false) -> void:
	const DQ := [1, 1, 0, -1, -1, 0]
	const DR := [0, -1, -1, 0, 1, 1]
	const HEX_SIZE := 1.2
	var dx: float = HEX_SIZE * 1.5 * float(DQ[dir])
	var dz: float = HEX_SIZE * (sqrt(3.0) / 2.0 * float(DQ[dir]) + sqrt(3.0) * float(DR[dir]))
	var target_angle := atan2(dx, dz)
	if animate:
		var delta := fmod(target_angle - rotation.y + TAU + PI, TAU) - PI
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "rotation:y", rotation.y + delta, 0.28)
	else:
		rotation.y = target_angle

func mark_dead() -> void:
	if _is_dead:
		return
	_is_dead = true
	if _model_root:
		_walk_meshes(_model_root, func(mi: MeshInstance3D) -> void:
			if mi.mesh == null:
				return
			for i in mi.mesh.get_surface_count():
				var mat := mi.get_surface_override_material(i) as StandardMaterial3D
				if mat:
					mat.albedo_color = Color(0.28, 0.28, 0.28)
		)
	if _eyes_root:
		_walk_meshes(_eyes_root, func(mi: MeshInstance3D) -> void:
			var mat := mi.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color     = Color(0.15, 0.15, 0.15)
				mat.emission_enabled = false
		)
	_name_label.modulate = Color(0.45, 0.45, 0.45)
	(_hp_bar_fill.material_override as StandardMaterial3D).albedo_color = Color(0.30, 0.30, 0.30)
	(_hp_bar_bg.material_override   as StandardMaterial3D).albedo_color = Color(0.08, 0.08, 0.08)

func revive() -> void:
	_is_dead = false
	visible  = true
	scale    = Vector3.ONE
	if _model_root:
		_tint_meshes(_model_root, robot_color)
	if _eyes_root:
		_walk_meshes(_eyes_root, func(mi: MeshInstance3D) -> void:
			var mat := mi.material_override as StandardMaterial3D
			if mat:
				mat.albedo_color     = Color(0.85, 0.95, 1.00)
				mat.emission_enabled = true
		)
	_name_label.modulate = Color.WHITE
	(_hp_bar_fill.material_override as StandardMaterial3D).albedo_color = Color(0.18, 0.88, 0.32)
	(_hp_bar_bg.material_override   as StandardMaterial3D).albedo_color = Color(0.10, 0.10, 0.10)
