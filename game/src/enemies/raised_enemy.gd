class_name RaisedEnemy
extends Enemy
## O mesmo inimigo, agora aliado: conserva ataques e telegrafias, sai do grupo
## hostil e recebe vida/custo apenas do resultado data-driven de DarkMage.

signal dismissed(summon_id: String)

var summon_id := ""
var caster_owner_id := &""
var simulation_authority_id := &""
var summoner: Node3D
var order := ""
var _raised_animation_speed := 1.0

const ROTTEN_TINT := Color("695c52")
const ALLY_RED := Color("b91f3d")


func setup_raised(p_enemy_id: String, palette: Dictionary,
		summon_data: Dictionary, caster: Node3D, owner_id: StringName,
		authority_id: StringName) -> void:
	summoner = caster
	caster_owner_id = owner_id
	simulation_authority_id = authority_id
	summon_id = String(summon_data.get("summon_id", ""))
	order = String(summon_data.get("order", ""))
	super.setup(p_enemy_id, palette, false, hash(summon_id))
	max_health = float(summon_data.get("max_health", max_health))
	health = max_health
	data = data.duplicate(true)
	var original_chase_speed := float(data.get("chase_speed", 0.0))
	data["chase_speed"] = data.get("patrol_speed")
	if original_chase_speed > 0.0:
		_raised_animation_speed = float(data.get("patrol_speed", 0.0)) \
			/ original_chase_speed
	remove_from_group("enemies")
	add_to_group("summons")
	add_to_group("summons_owned_by:%s" % String(caster_owner_id))
	_apply_wrong_posture()
	_build_ally_marker()


func set_order(next_order: String) -> void:
	order = next_order
	if order != "follow_caster" and target == summoner:
		target = null


func show_order_pulse() -> void:
	var marker := get_node_or_null("RaisedAllyMarker") as Node3D
	if marker == null:
		return
	marker.scale = Vector3.ONE
	var tween := create_tween()
	tween.tween_property(marker, "scale", Vector3.ONE * 1.45, 0.15)
	tween.tween_property(marker, "scale", Vector3.ONE, 0.20)


func _tick_chase(delta: float) -> void:
	if target != summoner:
		super._tick_chase(delta)
		return
	if order != "follow_caster":
		target = null
		_change_state(State.IDLE)
		return
	var follow_distance := float(data.get("preferred_distance", 0.0))
	if _distance_to_target() > follow_distance:
		_face_target(delta)
		_walk_towards(summoner.global_position,
			float(data.get("patrol_speed", 0.0)))
	else:
		_brake(delta)


func _try_hit() -> void:
	var hostile := target as Enemy
	super._try_hit()
	if is_instance_valid(hostile) and hostile.is_alive():
		hostile.target = self


func _refresh_colour() -> void:
	super._refresh_colour()
	if _visual != null and state in [State.IDLE, State.PATROL, State.CHASE]:
		_visual.call("set_tint", ROTTEN_TINT)


func _refresh_animation() -> void:
	if _visual == null:
		return
	match state:
		State.DEAD:
			_visual.call("play_animation", "Death01")
		State.ATTACK:
			_visual.call("play_animation", "Sword_Attack")
		State.STAGGER, State.BROKEN:
			_visual.call("play_animation", "Hit_Chest")
		State.CHASE:
			_visual.call("play_animation", "Jog_Fwd", _raised_animation_speed)
		State.PATROL:
			_visual.call("play_animation", "Walk", _raised_animation_speed)
		_:
			_visual.call("play_animation", "Idle")


func full_reset() -> void:
	dismiss()


func dismiss() -> void:
	if state != State.DEAD:
		state = State.DEAD
		collision_layer = 0
		dismissed.emit(summon_id)
	queue_free()


func _apply_wrong_posture() -> void:
	if _visual == null:
		return
	# O conceito aprovado do Peregrino Caído pede peso frontal e assimetria; a
	# colisão continua direita para a pose nunca mudar alcance nem passagem.
	_visual.rotation_degrees.x = -11.0
	_visual.rotation_degrees.z = -5.0 if hash(summon_id) % 2 == 0 else 5.0
	_visual.position.y = -0.08


func _build_ally_marker() -> void:
	var marker := Node3D.new()
	marker.name = "RaisedAllyMarker"
	add_child(marker)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = maxf(body_radius * 1.15, 0.1)
	ring_mesh.outer_radius = ring_mesh.inner_radius + maxf(body_radius * 0.10, 0.02)
	ring_mesh.rings = 12
	ring_mesh.ring_segments = 24
	var ring := MeshInstance3D.new()
	ring.mesh = ring_mesh
	ring.position.y = 0.035
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(ALLY_RED, 0.82)
	material.emission_enabled = true
	material.emission = ALLY_RED
	material.emission_energy_multiplier = 1.35
	ring.material_override = material
	marker.add_child(ring)
	var body_height := float(_visual_profile.get("target_height_m", 0.0))
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = maxf(body_radius * 0.48, 0.08)
	halo_mesh.outer_radius = halo_mesh.inner_radius + maxf(body_radius * 0.08, 0.02)
	halo_mesh.rings = 10
	halo_mesh.ring_segments = 18
	var halo := MeshInstance3D.new()
	halo.mesh = halo_mesh
	halo.position.y = body_height * 1.08
	halo.rotation_degrees.z = 12.0
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.material_override = material
	marker.add_child(halo)
	for strand_index: int in 3:
		var strand_mesh := BoxMesh.new()
		strand_mesh.size = Vector3(maxf(body_radius * 0.045, 0.015),
			body_height * (0.28 + float(strand_index) * 0.07),
			maxf(body_radius * 0.045, 0.015))
		var strand := MeshInstance3D.new()
		strand.mesh = strand_mesh
		var angle := TAU * float(strand_index) / 3.0
		strand.position = Vector3(sin(angle) * body_radius * 1.15,
			body_height * 0.52, cos(angle) * body_radius * 1.15)
		strand.rotation_degrees.z = -9.0 + float(strand_index) * 9.0
		strand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		strand.material_override = material
		marker.add_child(strand)
