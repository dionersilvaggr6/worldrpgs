class_name MonsterVisual
extends Node3D
## Apresentação dos inimigos da Fatia 1.
##
## Altura, proporção, materiais e armadura vêm de um catálogo visual próprio.
## A cápsula e todos os números de combate continuam a pertencer ao Enemy.

const PROFILE_PATH := "res://assets/models/enemies/monster_visual_profiles.json"
const ENEMY_HUD_RENDERER = preload("res://src/ui/enemy_hud.gd")

const PHASE_NONE := 0
const PHASE_PREPARATION := 1
const PHASE_STRIKE := 2
const PHASE_RECOVERY := 3

static var _catalogue: Dictionary = {}
static var _animation_libraries: Dictionary = {}

var _enemy_id := ""
var _profile: Dictionary = {}
var _pose_root: Node3D
var _body: Node3D
var _body_bounds := AABB()
var _visual_bounds := AABB()
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _weapon_pivot: Node3D
var _weapon_base_transform := Transform3D.IDENTITY
var _weapon_pose_rotation := Vector3.ZERO
var _weapon_bone_index := -1
var _weapon_bone_rest := Transform3D.IDENTITY
var _attached_overlays: Array[Dictionary] = []
var _materials: Array[StandardMaterial3D] = []
var _base_colours: Array[Color] = []
var _base_emission: Array[float] = []
var _current_animation := ""
var _current_tint := Color(-1.0, -1.0, -1.0, -1.0)
var _attack_phase := PHASE_NONE
var _attack_progress := 0.0
var _hit_flash := 0.0
var _hit_side := 1.0
var _is_dead := false


## Aceita a assinatura histórica (id, altura, tinta, sombra) e a assinatura do
## renderer corrente (id, dados, perfil, sombra, semente). Em ambos os casos a
## escala visual vem exclusivamente do JSON desta classe.
func setup(enemy_id: String, target_or_enemy_data: Variant = 0.0,
		tint_or_runtime_profile: Variant = Color.WHITE, casts_shadow := false,
		_variant_seed := 0) -> void:
	name = "MonsterVisual"
	_enemy_id = enemy_id
	_profile = profile_for(enemy_id)
	if _profile.is_empty():
		push_error("[MonsterVisual] família sem perfil: %s" % enemy_id)
		return

	var initial_tint := Color.WHITE
	if tint_or_runtime_profile is Color:
		initial_tint = tint_or_runtime_profile as Color
	_validate_height_hint(target_or_enemy_data, tint_or_runtime_profile)
	_pose_root = Node3D.new()
	_pose_root.name = "PoseRoot"
	add_child(_pose_root)
	_build_body(casts_shadow)
	_build_overlay(casts_shadow)
	_configure_loops()
	_connect_enemy_signals()
	_install_enemy_hud()
	set_tint(initial_tint)
	play_animation("Idle")


static func profile_for(enemy_id: String) -> Dictionary:
	_ensure_catalogue()
	var families: Dictionary = _catalogue.get("families", {}) as Dictionary
	return (families.get(enemy_id, {}) as Dictionary).duplicate(true)


static func family_ids() -> Array[String]:
	_ensure_catalogue()
	var ids: Array[String] = []
	var families: Dictionary = _catalogue.get("families", {}) as Dictionary
	for enemy_id: String in families.keys():
		ids.append(enemy_id)
	ids.sort()
	return ids


static func audit_rules() -> Dictionary:
	_ensure_catalogue()
	return (_catalogue.get("audit", {}) as Dictionary).duplicate(true)


func target_height_m() -> float:
	return float(_profile.get("target_height_m", 0.0))


func body_bounds() -> AABB:
	return _body_bounds


func visual_bounds() -> AABB:
	return _visual_bounds


func silhouette_signature() -> String:
	return String(_profile.get("silhouette_signature", ""))


func set_tint(tint: Color) -> void:
	if tint.is_equal_approx(_current_tint):
		return
	_current_tint = tint
	_apply_material_tint()


func play_animation(semantic_name: String, speed := 1.0) -> void:
	if _animation_player == null:
		return
	var animation_name := _animation_for(semantic_name)
	if not _animation_player.has_animation(animation_name):
		animation_name = _animation_for("Idle")
	if not _animation_player.has_animation(animation_name):
		return
	if _current_animation == animation_name:
		# A morte toca uma vez e fica na pose final. Reinicia-la todos os frames era
		# a origem do cadaver que continuava a mexer-se.
		if semantic_name == "Death01" or _animation_player.is_playing():
			return
	_current_animation = animation_name
	_animation_player.play(animation_name,
		float(_catalogue.get("animation_blend_s", 0.0)), speed)


func _build_body(casts_shadow: bool) -> void:
	var scene_path := String(_profile.get("scene_path", ""))
	var body_scene := load(scene_path) as PackedScene
	if body_scene == null:
		push_error("[MonsterVisual] modelo em falta: %s (%s)" % [_enemy_id, scene_path])
		return
	_body = body_scene.instantiate() as Node3D
	if _body == null:
		push_error("[MonsterVisual] raiz 3D inválida: %s" % scene_path)
		return
	_body.name = "Body"
	_pose_root.add_child(_body)
	_hide_declared_meshes(_body)
	var source_bounds := _descendant_mesh_bounds(_body)
	if source_bounds.size.y <= 0.0:
		push_error("[MonsterVisual] modelo sem volume: %s" % _enemy_id)
		return

	var measured_height := source_bounds.size.y
	var expected_height := float(_profile.get("source_height_m", 0.0))
	var source_tolerance := float(_profile.get("source_height_tolerance_m", 0.0))
	if absf(measured_height - expected_height) > source_tolerance:
		push_error("[MonsterVisual] fonte %s mede %.6f m; JSON declara %.6f m" % [
			_enemy_id, measured_height, expected_height])

	var target_height := target_height_m()
	var scale_factor := target_height / measured_height
	_body.rotation_degrees.y = float(_profile.get("body_yaw_deg", 0.0))
	_body.scale = Vector3(
		scale_factor * float(_profile.get("width_scale", 1.0)),
		scale_factor,
		scale_factor * float(_profile.get("depth_scale", 1.0)))
	# O pivot é derivado dos pés reais do mesh. Assim, trocar ou reimportar o
	# modelo não volta a enterrar o corpo nem exige um offset adivinhado.
	_body.position.y = -source_bounds.position.y * scale_factor
	_body_bounds = _body.transform * source_bounds
	var skeletons := _body.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		_skeleton = skeletons[0] as Skeleton3D
	_collect_body_materials(_body, casts_shadow)
	_animation_player = _build_animation_player()


func _build_overlay(casts_shadow: bool) -> void:
	var geometry: Array = _profile.get("geometry", []) as Array
	var material_profiles: Dictionary = _profile.get("materials", {}) as Dictionary
	var groups: Dictionary = {}
	for part_value: Variant in geometry:
		var part := part_value as Dictionary
		var role := String(part.get("role", ""))
		var attachment_bone := String(part.get("attachment_bone", ""))
		if role.is_empty() or not material_profiles.has(role):
			continue
		groups[role + "|" + attachment_bone] = {
			"role": role,
			"attachment_bone": attachment_bone,
		}
	var group_keys: Array[String] = []
	for group_key: String in groups.keys():
		group_keys.append(group_key)
	group_keys.sort()
	for group_key: String in group_keys:
		var group: Dictionary = groups.get(group_key, {}) as Dictionary
		var role := String(group.get("role", ""))
		_build_overlay_group(geometry, role,
			String(group.get("attachment_bone", "")),
			material_profiles.get(role, {}) as Dictionary, casts_shadow)
	if _visual_bounds.size == Vector3.ZERO:
		_visual_bounds = _body_bounds


func _build_overlay_group(parts: Array, role: String, attachment_bone: String,
		material_profile: Dictionary, casts_shadow: bool) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var appended := false
	for part_value: Variant in parts:
		var part := part_value as Dictionary
		if String(part.get("role", "")) != role \
			or String(part.get("attachment_bone", "")) != attachment_bone:
			continue
		var primitive := _primitive_for(part)
		if primitive == null:
			continue
		var transform := Transform3D(Basis.from_euler(_vec3(part.get("rotation_deg", [])) * PI / 180.0),
			_vec3(part.get("position_ratio", [])) * target_height_m())
		var part_scale := _vec3(part.get("scale", []))
		if part_scale == Vector3.ZERO:
			part_scale = Vector3.ONE
		transform.basis = transform.basis.scaled(part_scale * target_height_m())
		surface.append_from(primitive, 0, transform)
		appended = true
	if not appended:
		return
	var overlay_mesh := surface.commit()
	if overlay_mesh == null:
		return
	var overlay := MeshInstance3D.new()
	overlay.name = String(material_profile.get("node_name", role.to_pascal_case())) \
		+ ("_%s" % attachment_bone if not attachment_bone.is_empty() else "")
	overlay.mesh = overlay_mesh
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	var base_colour := Color(String(material_profile.get("colour", "#777777")))
	base_colour = _lift_colour(base_colour,
		float(material_profile.get("minimum_value", 0.0)))
	material.albedo_color = base_colour
	material.roughness = float(material_profile.get("roughness", 1.0))
	material.metallic = float(material_profile.get("metallic", 0.0))
	material.metallic_specular = float(material_profile.get("specular", 0.1))
	overlay.material_override = material
	_register_material(material, base_colour,
		float(material_profile.get("emission_energy", 0.0)))
	if bool(material_profile.get("moves_with_attack", false)):
		var bounds := overlay.get_aabb()
		var pivot_position := _vec3(_profile.get("weapon_pivot_ratio", [])) \
			* target_height_m()
		if pivot_position == Vector3.ZERO:
			pivot_position = bounds.get_center()
		_weapon_pivot = Node3D.new()
		_weapon_pivot.name = "WeaponPosePivot"
		_weapon_pivot.position = pivot_position
		_weapon_base_transform = _weapon_pivot.transform
		_pose_root.add_child(_weapon_pivot)
		overlay.position = -pivot_position
		_weapon_pivot.add_child(overlay)
		_configure_weapon_attachment(String(material_profile.get("attachment_bone", "")))
	else:
		_pose_root.add_child(overlay)
		_configure_overlay_attachment(overlay, attachment_bone)
	_visual_bounds = _body_bounds.merge(overlay.get_aabb()) \
		if _visual_bounds.size == Vector3.ZERO else _visual_bounds.merge(overlay.get_aabb())


func _configure_overlay_attachment(overlay: MeshInstance3D, bone_name: String) -> void:
	if bone_name.is_empty():
		return
	var bone_index := _bone_index(bone_name)
	if bone_index < 0:
		return
	_attached_overlays.append({
		"node": overlay,
		"bone_index": bone_index,
		"rest": _bone_transform_in_pose_root(bone_index),
	})


func _configure_weapon_attachment(bone_name: String) -> void:
	if bone_name.is_empty():
		return
	_weapon_bone_index = _bone_index(bone_name)
	if _weapon_bone_index >= 0:
		_weapon_bone_rest = _bone_transform_in_pose_root(_weapon_bone_index)


func _bone_index(bone_name: String) -> int:
	if _skeleton == null:
		push_error("[MonsterVisual] modelo sem esqueleto para ligar %s" % bone_name)
		return -1
	var bone_index := _skeleton.find_bone(bone_name)
	if bone_index < 0:
		push_error("[MonsterVisual] osso em falta: %s (%s)" % [_enemy_id, bone_name])
	return bone_index


func _bone_transform_in_pose_root(bone_index: int) -> Transform3D:
	var bone_global := _skeleton.global_transform \
		* _skeleton.get_bone_global_pose(bone_index)
	return _pose_root.global_transform.affine_inverse() * bone_global


func _update_bone_attachments() -> void:
	if _skeleton == null:
		return
	for attachment: Dictionary in _attached_overlays:
		var overlay := attachment.get("node") as Node3D
		if not is_instance_valid(overlay):
			continue
		var bone_index := int(attachment.get("bone_index", -1))
		var rest := attachment.get("rest", Transform3D.IDENTITY) as Transform3D
		overlay.transform = _bone_transform_in_pose_root(bone_index) * rest.affine_inverse()
	if _weapon_pivot != null:
		var attached_base := _weapon_base_transform
		if _weapon_bone_index >= 0:
			# A mão transporta a arma; a rotação do ataque continua a vir do perfil.
			# Herdar também o pulso somava duas animações e escondia o recuo da lança.
			var bone_delta := _bone_transform_in_pose_root(_weapon_bone_index) \
				* _weapon_bone_rest.affine_inverse()
			attached_base.origin = bone_delta * _weapon_base_transform.origin
		attached_base.basis *= Basis.from_euler(_weapon_pose_rotation)
		_weapon_pivot.transform = attached_base


func _primitive_for(part: Dictionary) -> PrimitiveMesh:
	var kind := String(part.get("kind", ""))
	if kind == "box":
		var box := BoxMesh.new()
		box.size = _vec3(part.get("size_ratio", []))
		return box
	if kind == "cylinder" or kind == "cone":
		var cylinder := CylinderMesh.new()
		cylinder.height = float(part.get("height_ratio", 0.0))
		cylinder.bottom_radius = float(part.get("bottom_radius_ratio", 0.0))
		cylinder.top_radius = 0.0 if kind == "cone" else float(
			part.get("top_radius_ratio", cylinder.bottom_radius))
		cylinder.radial_segments = int(_catalogue.get("overlay_radial_segments", 8))
		return cylinder
	if kind == "sphere":
		var sphere := SphereMesh.new()
		var radius := float(part.get("radius_ratio", 0.0))
		sphere.radius = radius
		sphere.height = radius * 2.0
		sphere.radial_segments = int(_catalogue.get("overlay_radial_segments", 8))
		sphere.rings = maxi(sphere.radial_segments / 2, 3)
		return sphere
	return null


func _collect_body_materials(node: Node, casts_shadow: bool) -> void:
	var body_tint := Color(String(_profile.get("body_tint", "#ffffff")))
	var body_minimum := float(_profile.get("body_minimum_value", 0.0))
	var body_emission := float(_profile.get("body_emission_energy", 0.0))
	for descendant: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if not casts_shadow:
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface_index: int in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface_index) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			var base_colour := _lift_colour(material.albedo_color * body_tint, body_minimum)
			material.albedo_color = base_colour
			material.roughness = float(_profile.get("body_roughness", 0.94))
			material.metallic = 0.0
			material.metallic_specular = float(_profile.get("body_specular", 0.08))
			# A textura continua a dar pele/couro/metal. Uma emissao baixa usa a mesma
			# textura como preenchimento e impede que o corpo desapareca em contraluz.
			material.emission_texture = material.albedo_texture
			mesh_instance.set_surface_override_material(surface_index, material)
			_register_material(material, base_colour, body_emission)


func _register_material(material: StandardMaterial3D, base_colour: Color,
		emission_energy: float) -> void:
	material.emission_enabled = true
	material.emission = base_colour
	material.emission_energy_multiplier = emission_energy
	_materials.append(material)
	_base_colours.append(base_colour)
	_base_emission.append(emission_energy)


func _apply_material_tint() -> void:
	if _current_tint.a < 0.0:
		return
	var tint_strength := clampf(float(_profile.get("state_tint_strength", 1.0)), 0.0, 1.0)
	for index: int in _materials.size():
		var colour := _base_colours[index].lerp(
			_base_colours[index] * _current_tint, tint_strength)
		if _is_dead:
			# Morto = frio e dessaturado, nao preto. O corpo precisa de continuar a
			# parecer um cadaver e nao uma falha de material.
			colour = colour.lerp(Color("777a76"), 0.48)
		colour = _lift_colour(colour, 0.22 if _is_dead else 0.30)
		if _hit_flash > 0.0:
			colour = colour.lerp(Color(String(_profile.get(
				"hit_flash_colour", "#fff1cf"))), _hit_flash)
		_materials[index].albedo_color = colour
		_materials[index].emission = colour
		_materials[index].emission_energy_multiplier = _base_emission[index] \
			+ _hit_flash * float(_profile.get("hit_flash_emission", 0.0))


static func _lift_colour(colour: Color, minimum_value: float) -> Color:
	var current := maxf(colour.r, maxf(colour.g, colour.b))
	if current >= minimum_value:
		return colour
	var amount := (minimum_value - current) / maxf(1.0 - current, 0.001)
	var lifted := colour.lerp(Color(1.0, 1.0, 1.0, colour.a), amount)
	lifted.a = colour.a
	return lifted


func _hide_declared_meshes(node: Node) -> void:
	var hidden_names: Array = _profile.get("hide_mesh_names", []) as Array
	for descendant: Node in node.find_children("*", "MeshInstance3D", true, false):
		if hidden_names.has(descendant.name):
			(descendant as MeshInstance3D).visible = false


func _validate_height_hint(target_or_enemy_data: Variant,
		runtime_profile_or_tint: Variant) -> void:
	var hinted_height := 0.0
	if target_or_enemy_data is float or target_or_enemy_data is int:
		hinted_height = float(target_or_enemy_data)
	elif runtime_profile_or_tint is Dictionary:
		hinted_height = float((runtime_profile_or_tint as Dictionary).get("target_height_m", 0.0))
	if hinted_height <= 0.0:
		return
	var tolerance := float(audit_rules().get("height_hint_tolerance_m", 0.0))
	if absf(hinted_height - target_height_m()) > tolerance:
		push_warning("[MonsterVisual] %s: colisão %.3f m, arte %.3f m" % [
		_enemy_id, hinted_height, target_height_m()])


func _connect_enemy_signals() -> void:
	var enemy := get_parent()
	if enemy == null:
		return
	if enemy.has_signal("attack_phase_changed"):
		enemy.connect("attack_phase_changed", _on_attack_phase_changed)
	if enemy.has_signal("health_changed"):
		enemy.connect("health_changed", _on_health_changed)
	if enemy.has_signal("state_changed"):
		enemy.connect("state_changed", _on_state_changed)
	if enemy.has_method("is_alive"):
		_is_dead = not bool(enemy.call("is_alive"))


func _install_enemy_hud() -> void:
	var enemy := get_parent()
	if enemy == null or not enemy.has_signal("health_changed"):
		return
	var scene := get_tree().current_scene
	if scene == null:
		call_deferred("_install_enemy_hud")
		return
	var hud := scene.get_node_or_null("EnemyHud")
	if hud == null:
		hud = ENEMY_HUD_RENDERER.new()
		hud.name = "EnemyHud"
		scene.add_child(hud)
	if hud.has_method("register_enemy"):
		hud.call("register_enemy", get_parent())


func _on_attack_phase_changed(phase: int, progress: float, _parryable: bool,
		_attack_id: String) -> void:
	_attack_phase = phase
	_attack_progress = progress


func _on_health_changed(_current: float, _maximum: float, delta: float,
		source: Node3D) -> void:
	if delta < 0.0:
		if is_instance_valid(source):
			_hit_side = -1.0 if to_local(source.global_position).x < 0.0 else 1.0
		_hit_flash = 1.0
		_apply_material_tint()


func _on_state_changed(_current: int, _previous: int) -> void:
	var enemy := get_parent()
	var was_dead := _is_dead
	_is_dead = enemy != null and enemy.has_method("is_alive") \
		and not bool(enemy.call("is_alive"))
	if was_dead and not _is_dead:
		_pose_root.rotation = Vector3.ZERO
		_pose_root.position = Vector3.ZERO
		_weapon_pose_rotation = Vector3.ZERO
	_apply_material_tint()


func _process(delta: float) -> void:
	if _pose_root == null:
		return
	if _hit_flash > 0.0:
		var pose: Dictionary = _profile.get("combat_pose", {}) as Dictionary
		_hit_flash = move_toward(_hit_flash, 0.0,
			delta * float(pose.get("hit_decay_per_s", 0.0)))
		_apply_material_tint()
	_update_combat_pose(delta)
	_update_bone_attachments()


func _update_combat_pose(delta: float) -> void:
	var body_rotation := Vector3.ZERO
	var body_position := Vector3.ZERO
	var weapon_rotation := Vector3.ZERO
	var height := maxf(target_height_m(), 1.0)
	var pose: Dictionary = _profile.get("combat_pose", {}) as Dictionary
	var preparation := _pose_sample(pose, "preparation")
	var strike := _pose_sample(pose, "strike")
	if _is_dead:
		var death := _pose_sample(pose, "death")
		body_rotation = death.get("body_rotation", Vector3.ZERO) as Vector3
		body_position = (death.get("body_offset", Vector3.ZERO) as Vector3) * height
		weapon_rotation = death.get("weapon_rotation", Vector3.ZERO) as Vector3
	else:
		match _attack_phase:
			PHASE_PREPARATION:
				var ease := smoothstep(0.0, 1.0, _attack_progress)
				body_rotation = _lerp_rotation(Vector3.ZERO,
					preparation.get("body_rotation", Vector3.ZERO) as Vector3, ease)
				body_position = (preparation.get("body_offset", Vector3.ZERO) as Vector3) \
					* height * ease
				weapon_rotation = _lerp_rotation(Vector3.ZERO,
					preparation.get("weapon_rotation", Vector3.ZERO) as Vector3, ease)
			PHASE_STRIKE:
				body_rotation = _lerp_rotation(
					preparation.get("body_rotation", Vector3.ZERO) as Vector3,
					strike.get("body_rotation", Vector3.ZERO) as Vector3, _attack_progress)
				body_position = (preparation.get("body_offset", Vector3.ZERO) as Vector3).lerp(
					strike.get("body_offset", Vector3.ZERO) as Vector3, _attack_progress) * height
				weapon_rotation = _lerp_rotation(
					preparation.get("weapon_rotation", Vector3.ZERO) as Vector3,
					strike.get("weapon_rotation", Vector3.ZERO) as Vector3, _attack_progress)
			PHASE_RECOVERY:
				body_rotation = _lerp_rotation(
					strike.get("body_rotation", Vector3.ZERO) as Vector3,
					Vector3.ZERO, _attack_progress)
				body_position = (strike.get("body_offset", Vector3.ZERO) as Vector3).lerp(
					Vector3.ZERO, _attack_progress) * height
				weapon_rotation = _lerp_rotation(
					strike.get("weapon_rotation", Vector3.ZERO) as Vector3,
					Vector3.ZERO, _attack_progress)
	if _hit_flash > 0.0 and not _is_dead:
		var hit := _pose_sample(pose, "hit")
		var hit_rotation := hit.get("body_rotation", Vector3.ZERO) as Vector3
		var hit_offset := hit.get("body_offset", Vector3.ZERO) as Vector3
		hit_rotation.z *= _hit_side
		hit_offset.x *= _hit_side
		body_rotation += hit_rotation * _hit_flash
		body_position += hit_offset * height * _hit_flash
	var blend_speed := float(pose.get(
		"death_blend_speed" if _is_dead else "blend_speed", 0.0))
	var blend := clampf(delta * blend_speed, 0.0, 1.0)
	_pose_root.rotation = _lerp_rotation(_pose_root.rotation, body_rotation, blend)
	_pose_root.position = _pose_root.position.lerp(body_position, blend)
	if _weapon_pivot != null:
		_weapon_pose_rotation = _lerp_rotation(_weapon_pose_rotation,
			weapon_rotation, blend)

func _pose_sample(pose: Dictionary, phase: String) -> Dictionary:
	var sample: Dictionary = pose.get(phase, {}) as Dictionary
	return {
		"body_rotation": _vec3(sample.get("body_rotation_deg", [])) * PI / 180.0,
		"body_offset": _vec3(sample.get("body_offset_ratio", [])),
		"weapon_rotation": _vec3(sample.get("weapon_rotation_deg", [])) * PI / 180.0,
	}


static func _lerp_rotation(from: Vector3, to: Vector3, weight: float) -> Vector3:
	return Vector3(lerp_angle(from.x, to.x, weight), lerp_angle(from.y, to.y, weight),
		lerp_angle(from.z, to.z, weight))


func _configure_loops() -> void:
	if _animation_player == null:
		return
	var looping_animations: Array = _catalogue.get("looping_animations", []) as Array
	for looping_value: Variant in looping_animations:
		var looping := String(looping_value)
		if _animation_player.has_animation(looping):
			_animation_player.get_animation(looping).loop_mode = Animation.LOOP_LINEAR


func _animation_for(semantic_name: String) -> String:
	var animations: Dictionary = _profile.get("animations", {}) as Dictionary
	return String(animations.get(semantic_name, animations.get("Idle", "Idle")))


static func _ensure_catalogue() -> void:
	if not _catalogue.is_empty():
		return
	var text := FileAccess.get_file_as_string(PROFILE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[MonsterVisual] JSON inválido: %s" % PROFILE_PATH)
		return
	_catalogue = parsed as Dictionary


static func _descendant_mesh_bounds(root_node: Node) -> AABB:
	var merged := AABB()
	var has_bounds := false
	for child: Node in root_node.get_children():
		var result := _bounds_below(child, Transform3D.IDENTITY)
		if not bool(result.get("valid", false)):
			continue
		var child_bounds: AABB = result.get("bounds", AABB()) as AABB
		merged = merged.merge(child_bounds) if has_bounds else child_bounds
		has_bounds = true
	return merged


static func _bounds_below(node: Node, parent_transform: Transform3D) -> Dictionary:
	var transform := parent_transform
	if node is Node3D:
		transform *= (node as Node3D).transform
	var merged := AABB()
	var has_bounds := false
	if node is MeshInstance3D and (node as MeshInstance3D).visible:
		merged = transform * (node as MeshInstance3D).get_aabb()
		has_bounds = true
	for child: Node in node.get_children():
		var result := _bounds_below(child, transform)
		if not bool(result.get("valid", false)):
			continue
		var child_bounds: AABB = result.get("bounds", AABB()) as AABB
		merged = merged.merge(child_bounds) if has_bounds else child_bounds
		has_bounds = true
	return {"valid": has_bounds, "bounds": merged}


func _build_animation_player() -> AnimationPlayer:
	var animation_scene_path := String(_profile.get("animation_scene_path", ""))
	if animation_scene_path.is_empty():
		return _find_animation_player(_body)
	var library := _animation_library(animation_scene_path)
	if library == null:
		push_error("[MonsterVisual] biblioteca de animação em falta: %s" \
			% animation_scene_path)
		return _find_animation_player(_body)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.root_node = NodePath("../Body")
	_pose_root.add_child(player)
	player.add_animation_library("", library)
	return player


static func _animation_library(scene_path: String) -> AnimationLibrary:
	if _animation_libraries.has(scene_path):
		return _animation_libraries.get(scene_path) as AnimationLibrary
	var source_scene := load(scene_path) as PackedScene
	if source_scene == null:
		return null
	var source_root := source_scene.instantiate()
	var source_player := _find_animation_player(source_root)
	var library: AnimationLibrary = null
	if source_player != null and source_player.has_animation_library(""):
		library = source_player.get_animation_library("")
	source_root.free()
	if library != null:
		_animation_libraries[scene_path] = library
	return library


static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


static func _vec3(value: Variant) -> Vector3:
	var raw := value as Array
	if raw.size() != 3:
		return Vector3.ZERO
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
