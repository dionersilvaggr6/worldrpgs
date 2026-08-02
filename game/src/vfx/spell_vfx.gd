class_name SpellVfx
extends Node3D
## Desenha a forma de entrega com camadas emissivas partilhadas.
## O núcleo de contacto recebe exactamente o snapshot/relógio da hitbox;
## rasto e veios apenas tornam esse movimento legível, sem criar dano próprio.

var _bundle: Dictionary = {}
var _contract: Dictionary = {}
var _core := MultiMeshInstance3D.new()
var _halo := MultiMeshInstance3D.new()
var _trail := MultiMeshInstance3D.new()
var _veins := MultiMeshInstance3D.new()
var _contact_visible := false
var _rendered_instances := 0
var _rendered_trail_instances := 0
var _audio_started := false
var _audio_position := Vector3.ZERO


func _ready() -> void:
	_play_audio_cue()


func configure(bundle: Dictionary, contract: Dictionary) -> void:
	_bundle = bundle.duplicate()
	_contract = contract.duplicate(true)
	top_level = true
	name = "SpellVfx_%s" % String(bundle.get("spell_id", "unknown"))
	add_to_group("spell_delivery_vfx")
	if _core.get_parent() == null:
		add_child(_core)
		add_child(_halo)
		add_child(_trail)
		add_child(_veins)
	var mesh := bundle.get("mesh") as Mesh
	var core_material := bundle.get("material") as StandardMaterial3D
	var halo_material := core_material.duplicate() as StandardMaterial3D
	var render: Dictionary = bundle.get("render", {}) as Dictionary
	var halo_color := halo_material.albedo_color
	halo_color.a = float(render.get("halo_alpha", 0.0))
	halo_material.albedo_color = halo_color
	halo_material.emission = Color(halo_color, halo_color.a)
	_core.multimesh = _new_multimesh(mesh)
	_halo.multimesh = _new_multimesh(mesh)
	_trail.multimesh = _new_multimesh(mesh)
	_veins.multimesh = _new_multimesh(mesh)
	_core.material_override = core_material
	_halo.material_override = halo_material
	var trail_material := core_material.duplicate() as StandardMaterial3D
	var trail_color := trail_material.albedo_color
	trail_color.a = float(render.get("halo_alpha", 0.0))
	trail_material.albedo_color = trail_color
	trail_material.emission = trail_color
	_trail.material_override = trail_material
	var vein_material := trail_material.duplicate() as StandardMaterial3D
	var vein_color := vein_material.albedo_color.darkened(
		float(render.get("core_scale", 0.0)))
	vein_material.albedo_color = vein_color
	vein_material.emission = vein_color
	_veins.material_override = vein_material
	var casts_shadow := bool(render.get("cast_shadow", false))
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.cast_shadow = _core.cast_shadow
	_trail.cast_shadow = _core.cast_shadow
	_veins.cast_shadow = _core.cast_shadow
	_core.visible = false
	_halo.visible = false
	_trail.visible = false
	_veins.visible = false


func sync(snapshot: Dictionary) -> void:
	_audio_position = snapshot.get("primary_position", Vector3.ZERO) as Vector3
	var has_contact := String(snapshot.get("contact_type", "")) != "nenhum"
	_contact_visible = has_contact \
		and bool(snapshot.get("hitbox_active", false)) \
		and bool(snapshot.get("contact_visual_visible", false))
	var effect_visible := _contact_visible if has_contact else bool(snapshot.get("alive", false))
	var transforms := _transforms_for(snapshot)
	var trail_transforms := _trail_transforms_for(snapshot)
	_rendered_instances = transforms.size() if effect_visible else 0
	_rendered_trail_instances = trail_transforms.size() if effect_visible else 0
	_write_layer(_core, transforms, float((_bundle.get("render", {}) as Dictionary).get(
		"core_scale", 0.0)), effect_visible)
	_write_layer(_halo, transforms, float((_bundle.get("render", {}) as Dictionary).get(
		"halo_scale", 0.0)), effect_visible)
	_write_layer(_trail, trail_transforms, float((_bundle.get("render", {}) as Dictionary).get(
		"core_scale", 0.0)), effect_visible and not trail_transforms.is_empty())
	_write_layer(_veins, trail_transforms, float((_bundle.get("render", {}) as Dictionary).get(
		"core_scale", 0.0)), effect_visible and not trail_transforms.is_empty() \
		and String(_bundle.get("school", "")) == "mal")
	_play_audio_cue()


func is_contact_visible() -> bool:
	return _contact_visible


func rendered_instance_count() -> int:
	return _rendered_instances


func rendered_trail_instance_count() -> int:
	return _rendered_trail_instances


func has_visible_trail() -> bool:
	return _trail.visible and _rendered_trail_instances > 0


func is_diseased_style_visible() -> bool:
	return _veins.visible and _rendered_trail_instances > 0


func has_started_audio_cue() -> bool:
	return _audio_started


func _play_audio_cue() -> void:
	if _audio_started or _bundle.is_empty() or not is_inside_tree():
		return
	var sfx := get_node_or_null("/root/Sfx")
	var profile := String(_bundle.get("audio_profile", ""))
	if sfx == null or profile.is_empty() or not sfx.has_method("play"):
		return
	sfx.call("play", profile, _audio_position)
	_audio_started = true


func _new_multimesh(mesh: Mesh) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	return multimesh


func _write_layer(layer: MultiMeshInstance3D, transforms: Array[Transform3D],
		scale_factor: float, layer_visible: bool) -> void:
	layer.visible = layer_visible
	layer.multimesh.instance_count = transforms.size() if layer_visible else 0
	if not layer_visible:
		return
	for index: int in transforms.size():
		var source := transforms[index]
		var scaled := Transform3D(source.basis.scaled(Vector3.ONE * scale_factor), source.origin)
		layer.multimesh.set_instance_transform(index, scaled)


func _transforms_for(snapshot: Dictionary) -> Array[Transform3D]:
	var form := String(snapshot.get("delivery_form", ""))
	if form in ["feixe", "feixe_rasteiro", "forma_arma"]:
		return [_line_transform(snapshot)]
	if form == "onda_sem_dano":
		var wave_radius := float(snapshot.get("wave_radius_m", 0.0))
		return [Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * wave_radius),
			snapshot.get("primary_position", Vector3.ZERO) as Vector3)]
	var transforms: Array[Transform3D] = []
	for raw_instance: Variant in snapshot.get("instances", []):
		var instance := raw_instance as Dictionary
		if not bool(instance.get("alive", false)):
			continue
		var direction := (instance.get("direction", Vector3.FORWARD) as Vector3).normalized()
		transforms.append(Transform3D(_basis_for_direction(direction),
			instance.get("position", Vector3.ZERO) as Vector3))
	if transforms.is_empty() and bool(snapshot.get("alive", false)):
		transforms.append(Transform3D(_basis_for_direction(
			snapshot.get("primary_direction", Vector3.FORWARD) as Vector3),
			snapshot.get("primary_position", Vector3.ZERO) as Vector3))
	return transforms


func _trail_transforms_for(snapshot: Dictionary) -> Array[Transform3D]:
	if String(snapshot.get("contact_type", "")) != "volume_movel" \
			or not bool(snapshot.get("alive", false)):
		return []
	var render: Dictionary = _bundle.get("render", {}) as Dictionary
	var segment_count := maxi(int(render.get("rings", 0)), 1)
	var spacing := maxf(float(render.get("shard_length_m",
		render.get("base_diameter_m", 0.0))), 0.0)
	var diseased := String(_bundle.get("school", "")) == "mal"
	var transforms: Array[Transform3D] = []
	for raw_instance: Variant in snapshot.get("instances", []):
		var instance := raw_instance as Dictionary
		if not bool(instance.get("alive", false)):
			continue
		var direction := (instance.get("direction", Vector3.FORWARD) as Vector3).normalized()
		var origin := instance.get("position", Vector3.ZERO) as Vector3
		var side := Vector3.UP.cross(direction).normalized()
		if side.is_zero_approx():
			side = Vector3.RIGHT
		for index: int in segment_count:
			var amount := float(index + 1) / float(segment_count + 1)
			var trail_position := origin - direction * spacing * float(index + 1)
			if diseased:
				# O vermelho cai e serpenteia como tecido doente, nao como aura heroica.
				trail_position += side * sin(float(index + 1)) * spacing * amount
				trail_position -= Vector3.UP * spacing * amount
			var taper := lerpf(float(render.get("halo_scale", 0.0)),
				float(render.get("core_scale", 0.0)), amount)
			transforms.append(Transform3D(_basis_for_direction(direction).scaled(
				Vector3.ONE * taper), trail_position))
	return transforms


func _line_transform(snapshot: Dictionary) -> Transform3D:
	var start := snapshot.get("primary_position", Vector3.ZERO) as Vector3
	var endpoint := snapshot.get("beam_endpoint", start) as Vector3
	var direction := endpoint - start
	var length := direction.length()
	if is_zero_approx(length):
		direction = snapshot.get("primary_direction", Vector3.FORWARD) as Vector3
	var basis := _basis_for_direction(direction.normalized()).scaled(Vector3(1.0, 1.0, length))
	return Transform3D(basis, start + direction.normalized() * length * 0.5)


func _basis_for_direction(direction: Vector3) -> Basis:
	var forward := direction.normalized()
	if forward.is_zero_approx():
		forward = Vector3.FORWARD
	var reference_up := Vector3.UP
	if absf(forward.dot(reference_up)) > 0.99:
		reference_up = Vector3.RIGHT
	var right := reference_up.cross(forward).normalized()
	var local_up := forward.cross(right).normalized()
	return Basis(right, local_up, forward)
