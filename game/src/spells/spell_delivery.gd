class_name SpellDelivery
extends Node3D
## Runtime data-driven das formas de entrega. Não contém afinação de combate:
## movimento, alcance, contacto, contagem e duração vêm de spells.json.

signal contacted(target: Node3D, payload: Dictionary)
signal impact_shown(target: Node3D, contact_position: Vector3)
signal delivery_expired(spell_id: String)

const SpellVfxScript = preload("res://src/vfx/spell_vfx.gd")
const SpellImpactVfxScript = preload("res://src/vfx/spell_impact_vfx.gd")

var _spell_id := ""
var _spell: Dictionary = {}
var _contract: Dictionary = {}
var _context: Dictionary = {}
var _instances: Array[Dictionary] = []
var _elapsed_s := 0.0
var _physics_frames := 0
var _next_pulse_s := 0.0
var _emitted_count := 0
var _next_emit_s := 0.0
var _alive := false
var _hitbox_active := false
var _contact_visual_visible := false
var _vfx: Node3D
var _vfx_bundle: Dictionary = {}


func configure(spell_id: String, spell: Dictionary, contract: Dictionary,
		context: Dictionary) -> void:
	_spell_id = spell_id
	_spell = spell.duplicate(true)
	_contract = contract.duplicate(true)
	_context = context.duplicate()
	position = context.get("origin", Vector3.ZERO) as Vector3
	var direction := (context.get("direction", Vector3.FORWARD) as Vector3).normalized()
	_initialize_instances(direction)
	_alive = true
	_hitbox_active = String(_contract.get("contact_type", "")) != "nenhum"
	_contact_visual_visible = _hitbox_active
	var declared_pulse := float(_contract.get("pulse_s", 0.0))
	_next_pulse_s = declared_pulse if declared_pulse > 0.0 \
		else float(_contract.get("cadence_s", 0.0))
	set_physics_process(not bool(context.get("manual", false)))
	var vfx_bundle: Dictionary = context.get("vfx_bundle", {}) as Dictionary
	if not vfx_bundle.is_empty():
		attach_vfx(vfx_bundle)


func _physics_process(delta: float) -> void:
	advance(delta, _runtime_targets())


func advance(delta: float, targets: Array) -> void:
	if not _alive:
		return
	_elapsed_s += delta
	_physics_frames += 1
	_emit_due_instances()
	for instance: Dictionary in _instances:
		if not bool(instance.get("alive", false)):
			continue
		var previous_position := instance.get("position", Vector3.ZERO) as Vector3
		if String(_contract.get("delivery_form", "")) == "onda_sem_dano":
			var previous_radius := float(instance.get("wave_radius_m", 0.0))
			var wave_radius := float(_contract.get("speed_m_s", 0.0)) * _elapsed_s
			instance["wave_radius_m"] = wave_radius
			instance["position"] = _context.get("origin", Vector3.ZERO) as Vector3
			instance["age_s"] = float(instance.get("age_s", 0.0)) + delta
			_evaluate_wave_contacts(instance, previous_radius, wave_radius, targets)
			continue
		if String(_contract.get("delivery_form", "")) == "orbitante":
			_update_orbit(instance, delta)
			instance["age_s"] = float(instance.get("age_s", 0.0)) + delta
			_evaluate_moving_contacts(instance, previous_position,
				instance.get("position", previous_position) as Vector3, targets)
			continue
		_update_ground_beam_direction(instance, delta)
		_update_hunter_direction(instance, delta)
		_update_carrier_seeker_direction(instance, delta)
		var velocity := instance.get("velocity", Vector3.ZERO) as Vector3
		velocity.y -= float(_contract.get("gravity_m_s2", 0.0)) * delta
		instance["velocity"] = velocity
		instance["position"] = previous_position + velocity * delta
		instance["age_s"] = float(instance.get("age_s", 0.0)) + delta
		if not (String(_contract.get("delivery_form", "")) == "portador" \
				and String(instance.get("role", "")) == "carrier"):
			_evaluate_moving_contacts(instance, previous_position,
				instance.get("position", previous_position) as Vector3, targets)
	if not _instances.is_empty():
		global_position = _instances[0].get("position", global_position) as Vector3
	_evaluate_instant_contacts(targets)
	_evaluate_persistent_contacts(targets)
	if String(_contract.get("contact_type", "")) == "instantaneo" \
			and _physics_frames >= int(_contract.get("active_frames", 0)):
		expire()
		return
	var lifetime := float(_contract.get("lifetime_s", 0.0))
	if lifetime > 0.0 and _elapsed_s >= lifetime:
		expire()
	else:
		_sync_vfx()


func _initialize_instances(direction: Vector3) -> void:
	_instances.clear()
	var origin := _context.get("origin", Vector3.ZERO) as Vector3
	var form := String(_contract.get("delivery_form", ""))
	if form == "portador":
		_instances.append(_new_instance(origin, direction, "carrier"))
		_emitted_count = 0
		_next_emit_s = float(_contract.get("cadence_s", 0.0))
		return
	if form in ["barragem_cone", "chuva"]:
		_emitted_count = 0
		_spawn_scheduled_instance(direction)
		_next_emit_s = float(_contract.get("cadence_s", 0.0))
		return
	var instance_count := int(_contract.get("count", 1)) if form == "orbitante" else 1
	var orbit_radius := float(_contract.get("collision_radius_m", 0.0)) \
		* float(instance_count)
	for index: int in instance_count:
		var angle := TAU * float(index) / float(instance_count)
		var instance_position := origin
		if form == "orbitante":
			instance_position += Vector3(cos(angle) * orbit_radius, orbit_radius,
				sin(angle) * orbit_radius)
		var instance := _new_instance(instance_position, direction)
		instance["orbit_angle"] = angle
		instance["orbit_radius"] = orbit_radius
		_instances.append(instance)
	_emitted_count = _instances.size()


func _emit_due_instances() -> void:
	var form := String(_contract.get("delivery_form", ""))
	if not form in ["barragem_cone", "chuva", "portador"]:
		return
	var cadence := float(_contract.get("cadence_s", 0.0))
	var count := int(_contract.get("count", 0))
	while cadence > 0.0 and _emitted_count < count \
			and (_elapsed_s >= _next_emit_s or is_equal_approx(_elapsed_s, _next_emit_s)):
		if form == "portador":
			_spawn_carrier_seeker()
		else:
			_spawn_scheduled_instance((
				_context.get("direction", Vector3.FORWARD) as Vector3).normalized())
		_next_emit_s += cadence


func _spawn_carrier_seeker() -> void:
	var carrier: Dictionary = _instances[0] as Dictionary
	if not bool(carrier.get("alive", false)):
		_emitted_count = int(_contract.get("count", 0))
		_expire_if_fully_spent()
		return
	var direction := carrier.get("direction", Vector3.FORWARD) as Vector3
	var target := _context.get("target") as Node3D
	if target != null and is_instance_valid(target):
		direction = (_target_position(target) \
			- (carrier.get("position", position) as Vector3)).normalized()
	_instances.append(_new_instance(carrier.get("position", position) as Vector3,
		direction, "seeker"))
	_emitted_count += 1


func _spawn_scheduled_instance(base_direction: Vector3) -> void:
	var form := String(_contract.get("delivery_form", ""))
	var count := int(_contract.get("count", 0))
	if _emitted_count >= count:
		return
	var origin := _context.get("origin", Vector3.ZERO) as Vector3
	var direction := base_direction
	var instance_position := origin
	if form == "barragem_cone":
		var arc := deg_to_rad(float(_contract.get("arc_deg", 0.0)))
		var amount := float(_emitted_count) / float(maxi(count - 1, 1))
		direction = base_direction.rotated(Vector3.UP,
			lerpf(-arc / 2.0, arc / 2.0, amount)).normalized()
	elif form == "chuva":
		var area_radius := float(_contract.get("area_radius_m", 0.0))
		var amount := sqrt(float(_emitted_count + 1) / float(maxi(count, 1)))
		var angle := TAU * float(_emitted_count) / float(maxi(count, 1))
		var centre := _context.get("target_point", origin) as Vector3
		instance_position = centre + Vector3(cos(angle) * area_radius * amount,
			area_radius, sin(angle) * area_radius * amount)
		direction = Vector3.DOWN
	_instances.append(_new_instance(instance_position, direction))
	_emitted_count += 1


func _new_instance(instance_position: Vector3, direction: Vector3,
		role := "body") -> Dictionary:
	return {
		"position": instance_position,
		"direction": direction,
		"velocity": direction * float(_contract.get("speed_m_s", 0.0)),
		"age_s": 0.0,
		"alive": true,
		"hits": {},
		"role": role,
	}


func _update_orbit(instance: Dictionary, delta: float) -> void:
	var angle := float(instance.get("orbit_angle", 0.0)) \
		+ deg_to_rad(float(_contract.get("turn_deg_s", 0.0))) * delta
	var radius := float(instance.get("orbit_radius", 0.0))
	var caster := _context.get("caster") as Node3D
	var centre := caster.global_position if caster != null and is_instance_valid(caster) \
		else _context.get("origin", Vector3.ZERO) as Vector3
	instance["orbit_angle"] = angle
	instance["position"] = centre + Vector3(cos(angle) * radius, radius,
		sin(angle) * radius)


func _evaluate_persistent_contacts(targets: Array) -> void:
	if not _hitbox_active \
			or String(_contract.get("contact_type", "")) != "volume_persistente" \
			or _next_pulse_s <= 0.0:
		return
	var interval := float(_contract.get("pulse_s", 0.0))
	if interval <= 0.0:
		interval = float(_contract.get("cadence_s", 0.0))
	while interval > 0.0 and (_elapsed_s >= _next_pulse_s \
			or is_equal_approx(_elapsed_s, _next_pulse_s)):
		for target_value: Variant in targets:
			var target := target_value as Node3D
			if target != null and is_instance_valid(target) and _persistent_contains(target):
				_emit_contact(target)
		_next_pulse_s += interval


func _evaluate_instant_contacts(targets: Array) -> void:
	if not _hitbox_active or String(_contract.get("contact_type", "")) != "instantaneo" \
			or _instances.is_empty():
		return
	var instance: Dictionary = _instances[0] as Dictionary
	var hits: Dictionary = instance.get("hits", {}) as Dictionary
	var origin := _context.get("origin", position) as Vector3
	var endpoint := origin + _primary_direction() \
		* float(_contract.get("max_range_m", 0.0))
	var radius := float(_contract.get("collision_radius_m", 0.0))
	for target_value: Variant in targets:
		var target := target_value as Node3D
		if target == null or not is_instance_valid(target) or hits.has(target.get_instance_id()):
			continue
		if _distance_to_segment(_target_position(target), origin, endpoint) \
				> radius + _target_radius(target):
			continue
		hits[target.get_instance_id()] = true
		instance["hits"] = hits
		_emit_contact(target)


func _update_hunter_direction(instance: Dictionary, delta: float) -> void:
	if String(_contract.get("delivery_form", "")) != "perseguidor":
		return
	var target := _context.get("target") as Node3D
	if target == null or not is_instance_valid(target):
		return
	var current_position := instance.get("position", Vector3.ZERO) as Vector3
	var current_direction := (instance.get("direction", Vector3.FORWARD) as Vector3).normalized()
	var desired_direction := (_target_position(target) - current_position).normalized()
	var angle := current_direction.angle_to(desired_direction)
	if is_zero_approx(angle):
		return
	var turn := deg_to_rad(float(_contract.get("turn_deg_s", 0.0))) * delta
	var direction := current_direction.slerp(desired_direction, minf(turn / angle, 1.0)).normalized()
	instance["direction"] = direction
	instance["velocity"] = direction * float(_contract.get("speed_m_s", 0.0))


func _update_ground_beam_direction(instance: Dictionary, delta: float) -> void:
	if String(_contract.get("delivery_form", "")) != "feixe_rasteiro":
		return
	var direction := (instance.get("direction", Vector3.FORWARD) as Vector3).normalized()
	direction = direction.rotated(Vector3.UP,
		deg_to_rad(float(_contract.get("turn_deg_s", 0.0))) * delta).normalized()
	instance["direction"] = direction


func _update_carrier_seeker_direction(instance: Dictionary, delta: float) -> void:
	if String(_contract.get("delivery_form", "")) != "portador" \
			or String(instance.get("role", "")) != "seeker":
		return
	var target := _context.get("target") as Node3D
	if target == null or not is_instance_valid(target):
		return
	var current_position := instance.get("position", Vector3.ZERO) as Vector3
	var current_direction := (instance.get("direction", Vector3.FORWARD) as Vector3).normalized()
	var desired_direction := (_target_position(target) - current_position).normalized()
	var angle := current_direction.angle_to(desired_direction)
	if is_zero_approx(angle):
		return
	var turn := deg_to_rad(float(_contract.get("turn_deg_s", 0.0))) * delta
	var direction := current_direction.slerp(desired_direction, minf(turn / angle, 1.0)).normalized()
	instance["direction"] = direction
	instance["velocity"] = direction * float(_contract.get("speed_m_s", 0.0))


func _persistent_contains(target: Node3D) -> bool:
	var form := String(_contract.get("delivery_form", ""))
	if form in ["feixe", "feixe_rasteiro"]:
		var origin := _context.get("origin", global_position) as Vector3
		var direction := _primary_direction()
		var endpoint := origin + direction * float(_contract.get("max_range_m", 0.0))
		return _distance_to_segment(_target_position(target), origin, endpoint) \
			<= float(_contract.get("collision_radius_m", 0.0)) + _target_radius(target)
	var centre := _context.get("target_point", global_position) as Vector3
	var radius := float(_contract.get("area_radius_m",
		_contract.get("collision_radius_m", 0.0)))
	return _target_position(target).distance_to(centre) <= radius + _target_radius(target)


func _primary_direction() -> Vector3:
	if _instances.is_empty():
		return (_context.get("direction", Vector3.FORWARD) as Vector3).normalized()
	return (_instances[0].get("direction", Vector3.FORWARD) as Vector3).normalized()


func _evaluate_moving_contacts(instance: Dictionary, from: Vector3, to: Vector3,
		targets: Array) -> void:
	if not _hitbox_active or String(_contract.get("contact_type", "")) != "volume_movel":
		return
	var hits: Dictionary = instance.get("hits", {}) as Dictionary
	var collision_radius := float(_contract.get("collision_radius_m", 0.0))
	for target_value: Variant in targets:
		var target := target_value as Node3D
		if target == null or not is_instance_valid(target) or hits.has(target.get_instance_id()):
			continue
		if _distance_to_segment(_target_position(target), from, to) \
				> collision_radius + _target_radius(target):
			continue
		hits[target.get_instance_id()] = true
		instance["hits"] = hits
		_emit_contact(target)
		if String(_contract.get("hit_policy", "")).begins_with("first_body_or_solid"):
			instance["alive"] = false
			_expire_if_fully_spent()
			return
		var max_target_hits := int(_contract.get("max_target_hits", 0))
		if max_target_hits > 0 and hits.size() >= max_target_hits:
			instance["alive"] = false
			_expire_if_fully_spent()
			return


func _evaluate_wave_contacts(instance: Dictionary, from_radius: float,
		to_radius: float, targets: Array) -> void:
	if not _hitbox_active:
		return
	var hits: Dictionary = instance.get("hits", {}) as Dictionary
	var centre := _context.get("origin", Vector3.ZERO) as Vector3
	var thickness := float(_contract.get("collision_radius_m", 0.0))
	for target_value: Variant in targets:
		var target := target_value as Node3D
		if target == null or not is_instance_valid(target) or hits.has(target.get_instance_id()):
			continue
		var distance := _target_position(target).distance_to(centre)
		var target_radius := _target_radius(target)
		if distance + target_radius < from_radius - thickness \
				or distance - target_radius > to_radius + thickness:
			continue
		hits[target.get_instance_id()] = true
		instance["hits"] = hits
		_emit_contact(target)


func _emit_contact(target: Node3D) -> void:
	var contact_position := _target_position(target)
	var payload := {
		"spell_id": _spell_id,
		"delivery_form": String(_contract.get("delivery_form", "")),
		"contact_type": String(_contract.get("contact_type", "")),
		"damage_enabled": float(_spell.get("base_damage", 0.0)) > 0.0,
		"spell": _spell.duplicate(true),
		"contact_position": contact_position,
	}
	_show_impact(target, contact_position)
	contacted.emit(target, payload)
	if target.has_method("receive_spell_contact"):
		target.call("receive_spell_contact", payload)


func _show_impact(target: Node3D, contact_position: Vector3) -> void:
	if _vfx_bundle.is_empty() or not is_inside_tree():
		return
	var impact := SpellImpactVfxScript.new()
	var host := get_tree().current_scene
	if host == null:
		host = get_parent()
	if host == null:
		impact.free()
		return
	host.add_child(impact)
	impact.configure(_vfx_bundle, _contract, contact_position, _primary_direction())
	impact_shown.emit(target, contact_position)


func _target_radius(target: Node3D) -> float:
	if target.has_method("spell_contact_radius_m"):
		return float(target.call("spell_contact_radius_m"))
	for property: Dictionary in target.get_property_list():
		if String(property.get("name", "")) == "body_radius":
			return float(target.get("body_radius"))
	return 0.0


func _target_position(target: Node3D) -> Vector3:
	return target.global_position + Vector3.UP * _target_radius(target)


func _distance_to_segment(point: Vector3, from: Vector3, to: Vector3) -> float:
	var segment := to - from
	var length_squared := segment.length_squared()
	if is_zero_approx(length_squared):
		return point.distance_to(from)
	var amount := clampf((point - from).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(from + segment * amount)


func expire() -> void:
	if not _alive:
		return
	_alive = false
	_hitbox_active = false
	_contact_visual_visible = false
	_sync_vfx()
	delivery_expired.emit(_spell_id)
	if is_inside_tree():
		queue_free()


func set_line_of_sight_visible(visible: bool) -> void:
	if not visible and String(_contract.get("delivery_form", "")) == "perseguidor":
		expire()


func notify_solid_collision(instance_index: int) -> void:
	if instance_index < 0 or instance_index >= _instances.size():
		return
	(_instances[instance_index] as Dictionary)["alive"] = false
	_expire_if_fully_spent()


func _expire_if_fully_spent() -> void:
	if _emitted_count < int(_contract.get("count", 1)):
		return
	for instance: Dictionary in _instances:
		if bool(instance.get("alive", false)):
			return
	expire()


func snapshot() -> Dictionary:
	var primary_position := (_instances[0].get("position", position) as Vector3) \
		if not _instances.is_empty() else position
	var primary_direction := _primary_direction()
	var wave_radius := 0.0
	if not _instances.is_empty():
		wave_radius = float((_instances[0] as Dictionary).get("wave_radius_m", 0.0))
	var living_instances := 0
	for instance: Dictionary in _instances:
		living_instances += 1 if bool(instance.get("alive", false)) else 0
	return {
		"spell_id": _spell_id,
		"delivery_form": String(_contract.get("delivery_form", "")),
		"contact_type": String(_contract.get("contact_type", "")),
		"alive": _alive,
		"hitbox_active": _hitbox_active,
		"contact_visual_visible": _contact_visual_visible,
		"elapsed_s": _elapsed_s,
		"emitted_count": _emitted_count,
		"released_count": _emitted_count if String(_contract.get(
			"delivery_form", "")) == "portador" else 0,
		"living_instance_count": living_instances,
		"primary_position": primary_position,
		"primary_direction": primary_direction,
		"beam_endpoint": primary_position + primary_direction \
			* float(_contract.get("max_range_m", 0.0)),
		"wave_radius_m": wave_radius,
		"instances": _instances.duplicate(true),
	}


func delivery_contract() -> Dictionary:
	return _contract.duplicate(true)


func attach_vfx(bundle: Dictionary) -> Node3D:
	if _vfx != null and is_instance_valid(_vfx):
		_vfx.queue_free()
	_vfx = SpellVfxScript.new()
	_vfx_bundle = bundle.duplicate()
	add_child(_vfx)
	_vfx.configure(bundle, _contract)
	_sync_vfx()
	return _vfx


func _sync_vfx() -> void:
	if _vfx != null and is_instance_valid(_vfx):
		_vfx.sync(snapshot())


func _runtime_targets() -> Array:
	if not is_inside_tree():
		return []
	var group_name := String(_context.get("target_group", "enemies"))
	return get_tree().get_nodes_in_group(group_name)
