extends RobotVisualBase

class_name RobotVisual

## One-shot animation effects triggered by RoundAnimationOrchestrator.
## State sync and build logic live in RobotVisualBase.

func bump_blocked() -> void:
	if _is_dead:
		return
	var fwd := position + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 0.22
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", fwd, 0.12)
	tween.tween_property(self, "position", position, 0.18)

func strike_forward() -> void:
	if _is_dead:
		return
	var origin := position
	var fwd := position + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 0.60
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", fwd, 0.14)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", origin, 0.26)

func flash_hit() -> void:
	if _is_dead or _model_root == null:
		return
	_walk_meshes(_model_root, func(mi: MeshInstance3D) -> void:
		if mi.mesh == null:
			return
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(i) as StandardMaterial3D
			if mat == null:
				return
			var orig := mat.albedo_color
			mat.albedo_color = Color(1.0, 0.15, 0.15)
			var tween := create_tween()
			tween.tween_property(mat, "albedo_color", orig, 0.40)
	)

func fall_off(edge_pos: Vector3) -> void:
	if _is_dead:
		return
	_is_dead = true
	var slide := create_tween()
	slide.set_ease(Tween.EASE_IN)
	slide.set_trans(Tween.TRANS_QUAD)
	slide.tween_property(self, "position", edge_pos, 0.30)
	await slide.finished
	var fall := create_tween()
	fall.set_parallel(true)
	fall.set_ease(Tween.EASE_IN)
	fall.set_trans(Tween.TRANS_QUAD)
	fall.tween_property(self, "position:y", position.y - 6.0, 0.70)
	fall.tween_property(self, "rotation:y",  rotation.y + TAU * 1.5, 0.70)
	fall.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.65)
	await fall.finished
	visible = false

func shoot_rocket(target_world_pos: Vector3) -> void:
	var rocket := MeshInstance3D.new()
	var rmesh  := SphereMesh.new()
	rmesh.radius = 0.08
	rmesh.height = 0.16
	rocket.mesh = rmesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color               = Color(1.0, 0.65, 0.1)
	rmat.emission_enabled           = true
	rmat.emission                   = Color(1.0, 0.4, 0.0)
	rmat.emission_energy_multiplier = 3.0
	rocket.material_override = rmat
	var fwd_dir := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	rocket.position = position + fwd_dir * 0.55 + Vector3(0.0, 0.20, 0.0)
	get_parent().add_child(rocket)
	var dest := target_world_pos + Vector3(0.0, 0.15, 0.0)
	var fly := rocket.create_tween()
	fly.set_ease(Tween.EASE_IN)
	fly.set_trans(Tween.TRANS_QUAD)
	fly.tween_property(rocket, "position", dest, 0.35)
	await fly.finished
	for i in range(6):
		var spark := MeshInstance3D.new()
		var smesh := SphereMesh.new()
		smesh.radius = randf_range(0.04, 0.10)
		smesh.height = smesh.radius * 2.0
		spark.mesh = smesh
		var smat := StandardMaterial3D.new()
		smat.albedo_color     = Color(1.0, randf_range(0.3, 0.7), 0.0)
		smat.emission_enabled = true
		smat.emission         = smat.albedo_color
		spark.material_override = smat
		spark.position = rocket.position
		get_parent().add_child(spark)
		var angle  := TAU * float(i) / 6.0 + randf_range(-0.3, 0.3)
		var spread := randf_range(0.2, 0.55)
		var peak   := randf_range(0.15, 0.50)
		var spark_dest := spark.position + Vector3(sin(angle) * spread, peak, cos(angle) * spread)
		var st := spark.create_tween()
		st.set_parallel(true)
		st.tween_property(spark, "position", spark_dest, 0.30)
		st.tween_property(spark, "scale", Vector3.ZERO, 0.25)
		get_tree().create_timer(0.35).timeout.connect(spark.queue_free)
	rocket.queue_free()

func explode() -> void:
	if _is_dead:
		return
	_is_dead = true
	for i in range(8):
		var debris := MeshInstance3D.new()
		var dmesh  := BoxMesh.new()
		dmesh.size = Vector3(randf_range(0.07, 0.17), randf_range(0.07, 0.17), randf_range(0.07, 0.17))
		debris.mesh = dmesh
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color     = Color(randf_range(0.8, 1.0), randf_range(0.1, 0.55), 0.0)
		dmat.emission_enabled = true
		dmat.emission         = dmat.albedo_color * 1.5
		debris.material_override = dmat
		debris.position = position + Vector3(0.0, 0.25, 0.0)
		get_parent().add_child(debris)
		var angle  := TAU * float(i) / 8.0 + randf_range(-0.4, 0.4)
		var radius := randf_range(0.7, 1.5)
		var peak_y := randf_range(0.3, 0.9)
		var dest := debris.position + Vector3(sin(angle) * radius, peak_y, cos(angle) * radius)
		var dt := debris.create_tween()
		dt.set_parallel(true)
		dt.set_ease(Tween.EASE_OUT)
		dt.set_trans(Tween.TRANS_QUAD)
		dt.tween_property(debris, "position", dest, 0.55)
		dt.tween_property(debris, "scale", Vector3.ZERO, 0.50)
		get_tree().create_timer(0.60).timeout.connect(debris.queue_free)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector3(1.7, 1.7, 1.7), 0.10)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.28)
	await tween.finished
	visible = false
	scale   = Vector3.ONE
