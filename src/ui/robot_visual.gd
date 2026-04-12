extends RobotVisualBase

class_name RobotVisual

## One-shot animation effects triggered by RoundAnimationOrchestrator.
## State sync and build logic live in RobotVisualBase.

const FALL_SLIDE_DURATION: float = RobotVisualBase.MOVE_DURATION
const FALL_DROP_DURATION: float = 0.70

const DEBRIS_SIZE := Vector3(0.12, 0.12, 0.12)

## Spawn a single cube debris piece that flies out and shrinks to nothing.
func _spawn_cube_debris(origin: Vector3, color: Color, angle: float,
		spread: float, peak: float, duration: float, emissive: bool = true) -> void:
	var mi   := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = DEBRIS_SIZE
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if emissive:
		mat.emission_enabled = true
		mat.emission         = color
	mi.material_override = mat
	mi.position = origin
	get_parent().add_child(mi)
	var dest := origin + Vector3(sin(angle) * spread, peak, cos(angle) * spread)
	var t    := mi.create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(mi, "position", dest,         duration)
	t.tween_property(mi, "scale",    Vector3.ZERO, duration * 0.9)
	get_tree().create_timer(duration + 0.05).timeout.connect(mi.queue_free)

func bump_blocked() -> void:
	if _is_dead:
		return
	var fwd := position + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 0.22
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", fwd, 0.12)
	tween.tween_property(self, "position", position, 0.18)

## Slam into a wall during a shockwave push: nudge toward the wall then shake.
func wall_slam(wall_world: Vector3) -> void:
	if _is_dead:
		return
	var origin := position
	var dir    := (wall_world - origin)
	dir.y = 0.0
	dir    = dir.normalized() if dir.length_squared() > 0.001 else Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	var perp   := Vector3(-dir.z, 0.0, dir.x)
	var tween  := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", origin + dir * 0.30, 0.11)
	tween.tween_property(self, "position", origin,              0.09)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", origin + perp * 0.09, 0.06)
	tween.tween_property(self, "position", origin - perp * 0.09, 0.08)
	tween.tween_property(self, "position", origin + perp * 0.04, 0.06)
	tween.tween_property(self, "position", origin,               0.07)

## Red fire donut spawned on a target that is slammed into a wall.
## Centred on this robot's current position; expands and fades out.
func fire_ring() -> void:
	var ring  := MeshInstance3D.new()
	var rmesh := TorusMesh.new()
	rmesh.inner_radius  = 0.18
	rmesh.outer_radius  = 0.36
	rmesh.ring_segments = 20
	rmesh.rings         = 4
	ring.mesh = rmesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color               = Color(1.0, 0.18, 0.05, 0.95)
	rmat.emission_enabled           = true
	rmat.emission                   = Color(1.0, 0.10, 0.0)
	rmat.emission_energy_multiplier = 3.0
	rmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = rmat
	ring.position  = position + Vector3(0.0, 0.08, 0.0)
	ring.rotation.x = PI / 2.0
	ring.scale = Vector3(0.25, 0.25, 0.25)
	get_parent().add_child(ring)
	var rt := ring.create_tween()
	rt.set_parallel(true)
	rt.tween_property(ring, "scale",             Vector3(2.8, 2.8, 0.6), 0.38)
	rt.tween_property(rmat, "albedo_color:a",    0.0,                    0.42)
	rt.tween_property(rmat, "emission_energy_multiplier", 0.0,           0.38)
	get_tree().create_timer(0.50).timeout.connect(ring.queue_free)

## Attack: quick lunge forward and snap back.
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

func fall_off(edge_pos: Vector3, slide_to_edge: bool = true) -> void:
	if _is_dead:
		return
	_is_dead = true
	if slide_to_edge and not position.is_equal_approx(edge_pos):
		var slide := create_tween()
		slide.set_ease(Tween.EASE_IN_OUT)
		slide.set_trans(Tween.TRANS_CUBIC)
		slide.tween_property(self, "position", edge_pos, FALL_SLIDE_DURATION)
		await slide.finished
	var fall := create_tween()
	fall.set_parallel(true)
	fall.set_ease(Tween.EASE_IN)
	fall.set_trans(Tween.TRANS_QUAD)
	fall.tween_property(self, "position:y", position.y - 6.0, FALL_DROP_DURATION)
	fall.tween_property(self, "rotation:y",  rotation.y + TAU * 1.5, FALL_DROP_DURATION)
	fall.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.65)
	await fall.finished
	visible = false

func shoot_rocket(target_world_pos: Vector3) -> void:
	var rocket := MeshInstance3D.new()
	var rmesh  := BoxMesh.new()
	rmesh.size = Vector3(0.10, 0.10, 0.16)
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
	rocket.queue_free()

## Orange burst explosion when a rocket hits a wall tile.
func rocket_wall_hit(wall_world: Vector3) -> void:
	for i in range(10):
		var angle  := TAU * float(i) / 10.0 + randf_range(-0.3, 0.3)
		var spread := randf_range(0.25, 0.60)
		var peak   := randf_range(0.10, 0.45)
		_spawn_cube_debris(wall_world, Color(1.0, randf_range(0.2, 0.7), 0.0),
				angle, spread, peak, 0.35)

## Disorient: spinning purple orb flies toward target hex.
func shoot_disorient(target_world_pos: Vector3) -> void:
	var proj  := MeshInstance3D.new()
	var pmesh := TorusMesh.new()
	pmesh.inner_radius  = 0.12
	pmesh.outer_radius  = 0.24
	pmesh.ring_segments = 14
	pmesh.rings         = 5
	proj.mesh = pmesh
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color               = Color(0.72, 0.18, 1.0, 0.92)
	pmat.emission_enabled           = true
	pmat.emission                   = Color(0.50, 0.05, 0.90)
	pmat.emission_energy_multiplier = 3.5
	pmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	proj.material_override = pmat
	var fwd_dir := Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	proj.position = position + fwd_dir * 0.55 + Vector3(0.0, 0.20, 0.0)
	get_parent().add_child(proj)
	var dest := target_world_pos + Vector3(0.0, 0.20, 0.0)
	var fly := proj.create_tween()
	fly.set_parallel(true)
	fly.set_ease(Tween.EASE_IN)
	fly.set_trans(Tween.TRANS_QUAD)
	fly.tween_property(proj, "position",             dest,   0.30)
	fly.tween_property(proj, "rotation_degrees:y",   1800.0, 0.30)
	get_tree().create_timer(0.34).timeout.connect(proj.queue_free)

## Purple burst explosion when a disorient pulse hits a wall tile.
func disorient_wall_hit(wall_world: Vector3) -> void:
	for i in range(6):
		var angle  := TAU * float(i) / 6.0 + randf_range(-0.3, 0.3)
		var spread := randf_range(0.20, 0.55)
		var peak   := randf_range(0.10, 0.40)
		_spawn_cube_debris(wall_world, Color(0.72, randf_range(0.05, 0.35), 1.0),
				angle, spread, peak, 0.30)

## Disorient hit: dizzy orbiting sparks around the robot's head.
func disorient_wobble() -> void:
	if _is_dead:
		return
	# Body stutter — quick confused jerk
	var origin_y := rotation.y
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation:y", origin_y + 0.40, 0.08)
	tween.tween_property(self, "rotation:y", origin_y - 0.40, 0.10)
	tween.tween_property(self, "rotation:y", origin_y + 0.20, 0.08)
	tween.tween_property(self, "rotation:y", origin_y,        0.07)
	# Four dizzy cube-stars orbiting the head
	for i in range(4):
		var star  := MeshInstance3D.new()
		var smesh := BoxMesh.new()
		smesh.size = Vector3(0.08, 0.08, 0.08)
		star.mesh = smesh
		var smat := StandardMaterial3D.new()
		smat.albedo_color               = Color(0.72, 0.18, 1.0, 0.90)
		smat.emission_enabled           = true
		smat.emission                   = Color(0.50, 0.05, 0.90)
		smat.emission_energy_multiplier = 2.5
		smat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		star.material_override = smat
		var a0    := TAU * float(i) / 4.0
		var a1    := a0 + PI          # orbit to opposite side
		var r     := 0.50
		star.position = position + Vector3(sin(a0) * r, 0.75, cos(a0) * r)
		get_parent().add_child(star)
		var dest := position + Vector3(sin(a1) * r, 0.90, cos(a1) * r)
		var st := star.create_tween()
		st.set_parallel(true)
		st.tween_property(star, "position",           dest, 0.50)
		st.tween_property(smat, "albedo_color:a",     0.0,  0.50)
		get_tree().create_timer(0.60).timeout.connect(star.queue_free)


func sweep_slash() -> void:
	if _is_dead:
		return
	var origin := position
	var fwd := position + Vector3(sin(rotation.y), 0.0, cos(rotation.y)) * 0.45
	# Lunge forward
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", fwd, 0.10)
	# Quick rotation jab (±15°) for a slash feel
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", rotation.y + 0.26, 0.08)
	tween.tween_property(self, "rotation:y", rotation.y - 0.26, 0.08)
	tween.tween_property(self, "rotation:y", rotation.y, 0.06)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", origin, 0.22)
	# Spawn a fading arc mesh in front
	var arc := MeshInstance3D.new()
	var amesh := TorusMesh.new()
	amesh.inner_radius = 0.40
	amesh.outer_radius = 0.70
	amesh.ring_segments = 12
	amesh.rings = 3
	arc.mesh = amesh
	var amat := StandardMaterial3D.new()
	amat.albedo_color               = Color(1.0, 0.45, 0.15, 0.85)
	amat.emission_enabled           = true
	amat.emission                   = Color(1.0, 0.35, 0.05)
	amat.emission_energy_multiplier = 2.0
	amat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc.material_override = amat
	arc.position = fwd + Vector3(0.0, 0.30, 0.0)
	arc.rotation.x = PI / 2.0
	arc.scale = Vector3(0.3, 0.3, 0.3)
	get_parent().add_child(arc)
	var at := arc.create_tween()
	at.set_parallel(true)
	at.tween_property(arc, "scale", Vector3(1.4, 1.4, 0.5), 0.30)
	at.tween_property(amat, "albedo_color:a", 0.0, 0.35)
	get_tree().create_timer(0.40).timeout.connect(arc.queue_free)

## Sweep: fire pillars and ground rings at each of the three arc hex world positions.
func sweep_arc_fire(arc_world_positions: Array) -> void:
	for wp in arc_world_positions:
		# Fire pillar — tall tapered cylinder
		var col  := MeshInstance3D.new()
		var cmesh := CylinderMesh.new()
		cmesh.height        = 1.0
		cmesh.top_radius    = 0.06
		cmesh.bottom_radius = 0.24
		col.mesh = cmesh
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color               = Color(1.0, 0.38, 0.05, 0.92)
		cmat.emission_enabled           = true
		cmat.emission                   = Color(1.0, 0.22, 0.0)
		cmat.emission_energy_multiplier = 5.0
		cmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		col.material_override = cmat
		col.position = Vector3(wp.x, 0.50, wp.z)
		col.scale    = Vector3(0.3, 0.3, 0.3)
		get_parent().add_child(col)
		var ct := col.create_tween()
		ct.set_parallel(true)
		ct.set_ease(Tween.EASE_OUT)
		ct.set_trans(Tween.TRANS_QUART)
		ct.tween_property(col,  "scale",              Vector3(1.8, 1.6, 1.8), 0.22)
		ct.tween_property(cmat, "albedo_color:a",     0.0,                   0.38)
		get_tree().create_timer(0.44).timeout.connect(col.queue_free)
		# Ground burn ring
		var ring  := MeshInstance3D.new()
		var rmesh := TorusMesh.new()
		rmesh.inner_radius  = 0.16
		rmesh.outer_radius  = 0.34
		rmesh.ring_segments = 14
		rmesh.rings         = 4
		ring.mesh = rmesh
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color               = Color(1.0, 0.55, 0.10, 1.0)
		rmat.emission_enabled           = true
		rmat.emission                   = Color(1.0, 0.28, 0.0)
		rmat.emission_energy_multiplier = 4.5
		rmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = rmat
		ring.position = Vector3(wp.x, 0.06, wp.z)
		ring.scale    = Vector3(0.25, 0.25, 0.25)
		get_parent().add_child(ring)
		var rt := ring.create_tween()
		rt.set_parallel(true)
		rt.set_ease(Tween.EASE_OUT)
		rt.tween_property(ring, "scale",          Vector3(2.2, 2.2, 2.2), 0.32)
		rt.tween_property(rmat, "albedo_color:a", 0.0,                   0.42)
		get_tree().create_timer(0.48).timeout.connect(ring.queue_free)

## Robot hops up then smashes down with a ring burst.
func slam_pound() -> void:
	if _is_dead:
		return
	var origin := position
	var tween := create_tween()
	# Hop up
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", origin.y + 0.60, 0.15)
	# Slam down
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position:y", origin.y, 0.10)
	# Squash on impact
	tween.tween_property(self, "scale", Vector3(1.15, 0.80, 1.15), 0.06)
	tween.tween_property(self, "scale", Vector3.ONE, 0.12)
	# Spawn a ground shockwave ring
	var ring := MeshInstance3D.new()
	var rmesh := TorusMesh.new()
	rmesh.inner_radius = 0.15
	rmesh.outer_radius = 0.30
	rmesh.ring_segments = 18
	rmesh.rings = 3
	ring.mesh = rmesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color               = Color(1.0, 0.70, 0.10, 0.90)
	rmat.emission_enabled           = true
	rmat.emission                   = Color(1.0, 0.55, 0.0)
	rmat.emission_energy_multiplier = 2.5
	rmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = rmat
	ring.position = origin + Vector3(0.0, 0.05, 0.0)
	ring.rotation.x = PI / 2.0
	ring.scale = Vector3(0.2, 0.2, 0.2)
	get_parent().add_child(ring)
	# Delay the ring until the robot lands (~0.25s into the animation)
	var rt := ring.create_tween()
	rt.tween_interval(0.25)
	rt.set_parallel(true)
	rt.tween_property(ring, "scale", Vector3(3.5, 3.5, 1.0), 0.40)
	rt.tween_property(rmat, "albedo_color:a", 0.0, 0.45)
	get_tree().create_timer(0.75).timeout.connect(ring.queue_free)

## Slam: seismic ground crack + debris pops at each affected hex.
func slam_ground_shake(hex_world_positions: Array) -> void:
	for wp in hex_world_positions:
		# Ground impact flash — flat disc that expands and fades
		var disc  := MeshInstance3D.new()
		var dmesh := CylinderMesh.new()
		dmesh.height         = 0.04
		dmesh.top_radius     = 0.26
		dmesh.bottom_radius  = 0.26
		disc.mesh = dmesh
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color               = Color(1.0, 0.62, 0.08, 0.95)
		dmat.emission_enabled           = true
		dmat.emission                   = Color(0.9, 0.45, 0.0)
		dmat.emission_energy_multiplier = 3.5
		dmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc.material_override = dmat
		disc.position = Vector3(wp.x, 0.04, wp.z)
		disc.scale    = Vector3(0.4, 1.0, 0.4)
		get_parent().add_child(disc)
		var dt := disc.create_tween()
		dt.set_parallel(true)
		dt.set_ease(Tween.EASE_OUT)
		dt.tween_property(disc, "scale",          Vector3(1.7, 1.0, 1.7), 0.22)
		dt.tween_property(dmat, "albedo_color:a", 0.0,                   0.28)
		get_tree().create_timer(0.32).timeout.connect(disc.queue_free)
		# Debris pops — 4 small rocks that jump and fall
		for i in range(4):
			var rock  := MeshInstance3D.new()
			var rsize := randf_range(0.05, 0.09)
			var rmesh := BoxMesh.new()
			rmesh.size = Vector3(rsize, rsize, rsize)
			rock.mesh  = rmesh
			var rmat := StandardMaterial3D.new()
			rmat.albedo_color = Color(0.52, 0.42, 0.32)
			rmat.roughness    = 0.90
			rock.material_override = rmat
			var angle := TAU * float(i) / 4.0 + randf() * 0.5
			var dist  := randf_range(0.10, 0.26)
			var start := Vector3(wp.x + sin(angle) * dist, 0.06, wp.z + cos(angle) * dist)
			var peak  := start + Vector3(0.0, randf_range(0.20, 0.38), 0.0)
			var land  := start + Vector3(sin(angle) * 0.08, 0.0, cos(angle) * 0.08)
			rock.position = start
			get_parent().add_child(rock)
			var rt := rock.create_tween()
			rt.set_ease(Tween.EASE_OUT)
			rt.set_trans(Tween.TRANS_QUAD)
			rt.tween_property(rock, "position", peak, 0.12)
			rt.set_ease(Tween.EASE_IN)
			rt.tween_property(rock, "position", land, 0.14)
			get_tree().create_timer(0.30).timeout.connect(rock.queue_free)


## Forcefield ring expanding to all 6 neighbor hexes.
## neighbor_positions: Array of Vector3 world positions for the 6 surrounding hexes.
func pulse_shockwave(neighbor_positions: Array = []) -> void:
	if _is_dead:
		return
	var origin := position
	# Vertical bob
	var bob := create_tween()
	bob.set_ease(Tween.EASE_OUT)
	bob.tween_property(self, "position:y", origin.y + 0.20, 0.10)
	bob.tween_property(self, "position:y", origin.y, 0.18)

	# --- Ground-level ring (primary wave) ---
	# Neighbors are at HEX_SIZE*sqrt(3) ≈ 2.08 world units.
	# outer_radius 0.45 × scale 5.2 = 2.34 → clearly reaches past neighbors.
	var ring1 := MeshInstance3D.new()
	var rmesh1 := TorusMesh.new()
	rmesh1.inner_radius  = 0.22
	rmesh1.outer_radius  = 0.45
	rmesh1.ring_segments = 32
	rmesh1.rings         = 6
	ring1.mesh = rmesh1
	var rmat1 := StandardMaterial3D.new()
	rmat1.albedo_color               = Color(0.72, 0.18, 1.0, 0.95)
	rmat1.emission_enabled           = true
	rmat1.emission                   = Color(0.55, 0.05, 0.90)
	rmat1.emission_energy_multiplier = 4.0
	rmat1.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring1.material_override = rmat1
	ring1.position  = origin + Vector3(0.0, 0.05, 0.0)
	ring1.rotation.x = PI / 2.0
	ring1.scale = Vector3(0.12, 0.12, 0.12)
	get_parent().add_child(ring1)
	var rt1 := ring1.create_tween()
	rt1.set_parallel(true)
	rt1.set_ease(Tween.EASE_OUT)
	rt1.set_trans(Tween.TRANS_QUAD)
	rt1.tween_property(ring1, "scale",                      Vector3(5.2, 5.2, 1.2), 0.52)
	rt1.tween_property(rmat1, "albedo_color:a",             0.0,                    0.58)
	rt1.tween_property(rmat1, "emission_energy_multiplier", 0.0,                    0.52)
	get_tree().create_timer(0.65).timeout.connect(ring1.queue_free)

	# --- Mid-height ring (forcefield wall depth) ---
	var ring2 := MeshInstance3D.new()
	var rmesh2 := TorusMesh.new()
	rmesh2.inner_radius  = 0.18
	rmesh2.outer_radius  = 0.38
	rmesh2.ring_segments = 28
	rmesh2.rings         = 4
	ring2.mesh = rmesh2
	var rmat2 := StandardMaterial3D.new()
	rmat2.albedo_color               = Color(0.85, 0.40, 1.0, 0.75)
	rmat2.emission_enabled           = true
	rmat2.emission                   = Color(0.65, 0.15, 1.0)
	rmat2.emission_energy_multiplier = 2.8
	rmat2.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring2.material_override = rmat2
	ring2.position  = origin + Vector3(0.0, 0.45, 0.0)
	ring2.rotation.x = PI / 2.0
	ring2.scale = Vector3(0.10, 0.10, 0.10)
	get_parent().add_child(ring2)
	var rt2 := ring2.create_tween()
	rt2.tween_interval(0.06)
	rt2.set_parallel(true)
	rt2.set_ease(Tween.EASE_OUT)
	rt2.set_trans(Tween.TRANS_QUAD)
	rt2.tween_property(ring2, "scale",                      Vector3(5.0, 5.0, 1.0), 0.48)
	rt2.tween_property(rmat2, "albedo_color:a",             0.0,                    0.50)
	rt2.tween_property(rmat2, "emission_energy_multiplier", 0.0,                    0.46)
	get_tree().create_timer(0.65).timeout.connect(ring2.queue_free)

	# --- Impact flash at each neighbor hex (ring arrives ~0.30s in) ---
	for wp: Vector3 in neighbor_positions:
		var disc  := MeshInstance3D.new()
		var dmesh := CylinderMesh.new()
		dmesh.height        = 0.04
		dmesh.top_radius    = 0.30
		dmesh.bottom_radius = 0.30
		disc.mesh = dmesh
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color               = Color(0.85, 0.30, 1.0, 0.0)
		dmat.emission_enabled           = true
		dmat.emission                   = Color(0.65, 0.10, 0.95)
		dmat.emission_energy_multiplier = 0.0
		dmat.transparency               = BaseMaterial3D.TRANSPARENCY_ALPHA
		disc.material_override = dmat
		disc.position = Vector3(wp.x, 0.04, wp.z)
		disc.scale    = Vector3(0.6, 1.0, 0.6)
		get_parent().add_child(disc)
		# Alpha: flash in then out
		var fa := disc.create_tween()
		fa.tween_interval(0.30)
		fa.tween_property(dmat, "albedo_color:a", 0.90, 0.08)
		fa.tween_property(dmat, "albedo_color:a", 0.0,  0.22)
		# Emission: same timing
		var fb := disc.create_tween()
		fb.tween_interval(0.30)
		fb.tween_property(dmat, "emission_energy_multiplier", 3.8, 0.08)
		fb.tween_property(dmat, "emission_energy_multiplier", 0.0, 0.22)
		# Scale: expand as it lands
		var fc := disc.create_tween()
		fc.tween_interval(0.30)
		fc.tween_property(disc, "scale", Vector3(1.6, 1.0, 1.6), 0.14)
		fc.tween_property(disc, "scale", Vector3(1.8, 1.0, 1.8), 0.16)
		get_tree().create_timer(0.65).timeout.connect(disc.queue_free)

func explode() -> void:
	if _is_dead:
		return
	_is_dead = true
	for i in range(10):
		var debris := MeshInstance3D.new()
		var dmesh  := BoxMesh.new()
		dmesh.size = DEBRIS_SIZE
		debris.mesh = dmesh
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color     = Color(randf_range(0.8, 1.0), randf_range(0.1, 0.55), 0.0)
		dmat.emission_enabled = true
		dmat.emission         = dmat.albedo_color * 1.5
		debris.material_override = dmat
		debris.position = position + Vector3(0.0, 0.25, 0.0)
		get_parent().add_child(debris)
		var angle  := TAU * float(i) / 10.0 + randf_range(-0.4, 0.4)
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
