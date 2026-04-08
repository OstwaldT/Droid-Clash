extends Node3D

class_name RobotVisualBase

## Handles construction and state-sync for a robot's 3D representation.
## Animation effects are in the RobotVisual subclass.

const SPEEDER_MODELS: Array[String] = [
	"res://assets/kenney_space-kit/Models/GLTF format/craft_speederA.glb",
	"res://assets/kenney_space-kit/Models/GLTF format/craft_speederB.glb",
	"res://assets/kenney_space-kit/Models/GLTF format/craft_speederC.glb",
	"res://assets/kenney_space-kit/Models/GLTF format/craft_speederD.glb",
]

const MODEL_SCALE: float = 0.50
const MODEL_Y: float     = 0.05

const LABEL_Y:   float = 0.75
const HP_BAR_Y:  float = 1.05
const HP_BAR_W:  float = 0.90
const HP_BAR_H:  float = 0.09

var player_id:   int
var robot_color: Color

var _model_root:   Node3D         = null
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

func _build_model(pid: int, color: Color) -> void:
	var model_path := SPEEDER_MODELS[pid % SPEEDER_MODELS.size()]
	var packed := load(model_path) as PackedScene
	if packed == null:
		var fallback := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.8, 0.3, 1.0)
		fallback.mesh = bm
		fallback.position.y = MODEL_Y
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		fallback.material_override = mat
		_model_root = Node3D.new()
		_model_root.add_child(fallback)
		add_child(_model_root)
		return
	_model_root = packed.instantiate() as Node3D
	# Kenney GLBs have the mesh child offset by [2, 0, 1.5] in local space;
	# compensate so the model sits centered on the hex tile.
	_model_root.position = Vector3(MODEL_SCALE * 2.0, MODEL_Y, MODEL_SCALE * 1.5)
	_model_root.rotation.y = PI  # model faces -Z; our code treats +Z as forward
	_model_root.scale      = Vector3.ONE * MODEL_SCALE
	add_child(_model_root)
	_tint_meshes(_model_root, color)

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
	_name_label.font_size     = 28
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
				new_mat.roughness    = src.roughness
				new_mat.metallic     = src.metallic
				new_mat.albedo_color = src.albedo_color * color
			else:
				new_mat.albedo_color = color
			new_mat.roughness = 0.45
			new_mat.metallic  = 0.30
			mi.set_surface_override_material(i, new_mat)
	)

# --- State sync (called each time game state is applied to the visual) ---

func move_to(world_pos: Vector3, animate: bool = true, duration: float = 0.75) -> void:
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
	_name_label.modulate = Color(0.45, 0.45, 0.45)
	(_hp_bar_fill.material_override as StandardMaterial3D).albedo_color = Color(0.30, 0.30, 0.30)
	(_hp_bar_bg.material_override   as StandardMaterial3D).albedo_color = Color(0.08, 0.08, 0.08)

func revive() -> void:
	_is_dead = false
	visible  = true
	scale    = Vector3.ONE
	if _model_root:
		_tint_meshes(_model_root, robot_color)
	_name_label.modulate = Color.WHITE
	(_hp_bar_fill.material_override as StandardMaterial3D).albedo_color = Color(0.18, 0.88, 0.32)
	(_hp_bar_bg.material_override   as StandardMaterial3D).albedo_color = Color(0.10, 0.10, 0.10)
