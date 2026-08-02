class_name SpellImpactVfx
extends Node3D
## Confirmacao visual de um contacto que ja aconteceu. Nao e uma promessa de
## dano futuro e, por isso, nunca tem hitbox propria.

var _bundle: Dictionary = {}
var _lifetime_s := 0.0
var _elapsed_s := 0.0
var _burst := MultiMeshInstance3D.new()
var _veins := MultiMeshInstance3D.new()
var _visible_instances := 0
var _spawn_physics_frame := 0


func configure(bundle: Dictionary, contract: Dictionary,
		contact_position: Vector3, incoming_direction: Vector3) -> void:
	_bundle = bundle.duplicate()
	top_level = true
	name = "SpellImpactVfx_%s" % String(bundle.get("spell_id", "unknown"))
	global_position = contact_position
	add_to_group("spell_impact_vfx")
	_spawn_physics_frame = Engine.get_physics_frames()

	var render: Dictionary = bundle.get("render", {}) as Dictionary
	var active_frames := int(contract.get("active_frames", 0))
	var visual_frames := maxi(active_frames, int(render.get("rings", 0)))
	_lifetime_s = float(visual_frames) / float(Engine.physics_ticks_per_second)
	if visual_frames <= 0:
		_lifetime_s = maxf(float(contract.get("pulse_s",
			contract.get("cadence_s", 0.0))),
			1.0 / float(Engine.physics_ticks_per_second))

	var mesh := bundle.get("mesh") as Mesh
	var material := bundle.get("material") as StandardMaterial3D
	var count := maxi(int(render.get("rings", 0)), 1)
	_burst.multimesh = _make_multimesh(mesh, count)
	_burst.material_override = material
	_burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_burst)

	var vein_material := material.duplicate() as StandardMaterial3D
	var vein_color := vein_material.albedo_color.darkened(
		float(render.get("core_scale", 0.0)))
	vein_material.albedo_color = vein_color
	vein_material.emission = vein_color
	_veins.multimesh = _make_multimesh(mesh, count)
	_veins.material_override = vein_material
	_veins.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_veins.visible = String(bundle.get("school", "")) == "mal"
	add_child(_veins)

	var forward := incoming_direction.normalized()
	if forward.is_zero_approx():
		forward = Vector3.FORWARD
	var right := Vector3.UP.cross(forward).normalized()
	if right.is_zero_approx():
		right = Vector3.RIGHT
	var spacing := float(render.get("base_diameter_m", 0.0))
	for index: int in count:
		var amount := float(index + 1) / float(count + 1)
		var angle := TAU * amount
		var radial := right.rotated(forward, angle)
		var burst_direction := (radial - forward).normalized()
		var basis := _basis_for_direction(burst_direction).scaled(
			Vector3.ONE * lerpf(float(render.get("halo_scale", 0.0)),
				float(render.get("core_scale", 0.0)), amount))
		_burst.multimesh.set_instance_transform(index,
			Transform3D(basis, radial * spacing * amount))
		var sick_direction := (radial - Vector3.UP * amount).normalized()
		_veins.multimesh.set_instance_transform(index, Transform3D(
			_basis_for_direction(sick_direction).scaled(Vector3.ONE *
			float(render.get("core_scale", 0.0))),
			(radial - Vector3.UP) * spacing * amount))
	_visible_instances = count + (count if _veins.visible else 0)
	_play_impact_audio()


func _process(delta: float) -> void:
	_elapsed_s += delta
	var amount := clampf(_elapsed_s / maxf(_lifetime_s, delta), 0.0, 1.0)
	scale = Vector3.ONE * (1.0 + amount * float(
		(_bundle.get("render", {}) as Dictionary).get("halo_scale", 0.0)))
	if _elapsed_s >= _lifetime_s:
		queue_free()


func visible_instance_count() -> int:
	return _visible_instances if visible else 0


func spawn_physics_frame() -> int:
	return _spawn_physics_frame


func _play_impact_audio() -> void:
	var sfx := get_node_or_null("/root/Sfx")
	var profile := String(_bundle.get("audio_profile", ""))
	if sfx != null and not profile.is_empty() and sfx.has_method("play"):
		sfx.call("play", profile, global_position)


func _make_multimesh(mesh: Mesh, count: int) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = count
	return multimesh


func _basis_for_direction(direction: Vector3) -> Basis:
	var forward := direction.normalized()
	var reference_up := Vector3.UP
	if absf(forward.dot(reference_up)) > 0.99:
		reference_up = Vector3.RIGHT
	var right := reference_up.cross(forward).normalized()
	var local_up := forward.cross(right).normalized()
	return Basis(right, local_up, forward)
