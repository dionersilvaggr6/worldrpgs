class_name NecromancyRuntime
extends Node
## Ponte entre mortes no mundo e o estado data-driven de DarkMage. A autoridade
## do dono e a autoridade de simulação ficam separadas para não fechar a tensão
## de rede antes de Mateus e Rico decidirem.

const DarkMageScript := preload("res://src/classes/dark_mage.gd")
const RaisedCorpseScript := preload("res://src/enemies/raised_corpse.gd")
const RaisedEnemyScript := preload("res://src/enemies/raised_enemy.gd")
const NecromancyAudioScript := preload("res://src/summons/necromancy_audio.gd")

var _caster: Node3D
var _world_root: Node
var _controller
var _caster_owner_id := &""
var _simulation_authority_id := &""
var _corpses: Dictionary = {}
var _corpse_id_by_enemy_instance: Dictionary = {}
var _summons: Dictionary = {}
var _spells: Dictionary = {}
var _palette: Dictionary = {}
var _base_max_health := 0.0
var _pending_cast_spell_id := ""
var _ability: Dictionary = {}
var _ability_cooldown_remaining := 0.0
var _audio


func _physics_process(delta: float) -> void:
	if is_instance_valid(_caster):
		_ability_cooldown_remaining = maxf(
			_ability_cooldown_remaining - delta, 0.0)
		_read_origin_ability_input()
		refresh_summon_targets()


func setup(caster: Node3D, world_root: Node, caster_owner_id: StringName,
		simulation_authority_id: StringName, attributes: Dictionary,
		abilities: Dictionary, spells: Dictionary,
		palette: Dictionary = {}, presentation: Dictionary = {}) -> bool:
	if not is_instance_valid(caster) or not is_instance_valid(world_root):
		return false
	if String(caster.get("class_id")) != DarkMageScript.ORIGIN_ID:
		return false
	_caster = caster
	_world_root = world_root
	_caster_owner_id = caster_owner_id
	_simulation_authority_id = simulation_authority_id
	_base_max_health = float(caster.get("max_health"))
	_spells = spells
	_palette = palette
	_ability = (abilities.get(DarkMageScript.ORIGIN_ID, {}) as Dictionary).duplicate(true)
	_controller = DarkMageScript.new()
	if not _controller.configure(attributes, abilities, spells):
		return false
	_audio = NecromancyAudioScript.new()
	add_child(_audio)
	_audio.configure(presentation)
	if caster.has_signal("state_changed"):
		caster.connect("state_changed", _on_caster_state_changed)
	return true


func _read_origin_ability_input() -> void:
	if not bool(_caster.get("input_enabled")) or _ability_cooldown_remaining > 0.0:
		return
	if _caster.has_method("is_alive") and not bool(_caster.call("is_alive")):
		return
	if _caster.has_method("state_name") \
			and String(_caster.call("state_name")) != "livre":
		return
	var action_name := String(_ability.get("input_action", ""))
	if action_name.is_empty() or not Input.is_action_just_pressed(action_name):
		return
	var result := use_origin_ability()
	if bool(result.get("accepted", false)):
		_ability_cooldown_remaining = float(_ability.get("cooldown_s", 0.0))


func watch_enemy(enemy: Node3D, stable_corpse_id: String = "") -> void:
	if not is_instance_valid(enemy) or not enemy.has_signal("died"):
		return
	_corpse_id_by_enemy_instance[enemy.get_instance_id()] = stable_corpse_id
	var callback := _on_enemy_died
	if not enemy.is_connected("died", callback):
		enemy.connect("died", callback)


func corpse_count() -> int:
	return corpses().size()


func summon_count() -> int:
	return _summons.size()


func summons() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for summon_value: Variant in _summons.values():
		if not is_instance_valid(summon_value):
			continue
		var summon := summon_value as Enemy
		if summon != null:
			result.append(summon)
	return result


func refresh_summon_targets() -> void:
	var hostiles := get_tree().get_nodes_in_group("enemies")
	for summon: Enemy in summons():
		if not summon.is_alive():
			continue
		var nearest: Node3D
		var nearest_distance := INF
		for hostile_value: Variant in hostiles:
			var hostile := hostile_value as Node3D
			if hostile == null or (hostile.has_method("is_alive")
					and not bool(hostile.call("is_alive"))):
				continue
			var distance := summon.global_position.distance_squared_to(
				hostile.global_position)
			if distance < nearest_distance:
				nearest = hostile
				nearest_distance = distance
		if nearest != null:
			summon.target = nearest
		elif String(summon.get("order")) == "follow_caster":
			summon.target = summon.get("summoner") as Node3D
		else:
			summon.target = null


func use_origin_ability() -> Dictionary:
	var result: Dictionary = _controller.use_origin_ability()
	if not bool(result.get("accepted", false)):
		return result
	var next_order := String(result.get("order", ""))
	for summon: Enemy in summons():
		summon.call("set_order", next_order)
		summon.call("show_order_pulse")
	_audio.play_cue("order")
	return result


func audio_cues_ready() -> bool:
	return is_instance_valid(_audio) and _audio.cue_count() == 2


func rest() -> Dictionary:
	_clear_corpses()
	return _dismiss_all_summons()


func _dismiss_all_summons() -> Dictionary:
	var active := summons()
	_summons.clear()
	for summon: Enemy in active:
		summon.call("dismiss")
	var result: Dictionary = _controller.reset_encounter_state()
	_apply_health_reservation()
	return result


func leave_zone(new_world_root: Node = null) -> Array[String]:
	_clear_corpses()
	var dismissed: Array[String] = _controller.leave_zone()
	for summon_id: String in dismissed:
		var summon := _summons.get(summon_id) as Enemy
		_summons.erase(summon_id)
		if is_instance_valid(summon):
			summon.call("dismiss")
	if is_instance_valid(new_world_root):
		_world_root = new_world_root
		for summon: Enemy in summons():
			summon.reparent(_world_root, true)
	_apply_health_reservation()
	return dismissed


func apply_blood_oath() -> Dictionary:
	var result: Dictionary = _controller.apply_blood_oath()
	if bool(result.get("accepted", false)):
		_apply_health_reservation()
	return result


func corpses() -> Array[RaisedCorpse]:
	var result: Array[RaisedCorpse] = []
	for corpse_value: Variant in _corpses.values():
		if not is_instance_valid(corpse_value):
			continue
		var corpse := corpse_value as RaisedCorpse
		if corpse != null:
			result.append(corpse)
	return result


func validate_raise_target(spell_id: String) -> Dictionary:
	var spell := _spells.get(spell_id, {}) as Dictionary
	var effect_type := String(spell.get("effect_type", ""))
	if effect_type not in ["raise_dead", "raise_boss"]:
		return _rejected("not_a_raise_spell")
	var corpse := _nearest_corpse(spell, effect_type == "raise_boss")
	if corpse == null:
		return _rejected("no_eligible_corpse")
	if not corpse.is_boss and corpse.body_size.is_empty():
		return _rejected("missing_body_size_data")
	var original_max_health := float(corpse.source_body.get("max_health"))
	if corpse.is_boss:
		return _controller.preview_raise_boss(
			corpse.corpse_id, original_max_health)
	return _controller.preview_raise_dead(
		corpse.corpse_id, corpse.body_size, original_max_health)


func raise_nearest(spell_id: String) -> Dictionary:
	var spell := _spells.get(spell_id, {}) as Dictionary
	var effect_type := String(spell.get("effect_type", ""))
	if effect_type not in ["raise_dead", "raise_boss"]:
		return _rejected("not_a_raise_spell")
	var corpse := _nearest_corpse(spell, effect_type == "raise_boss")
	if corpse == null:
		return _rejected("no_eligible_corpse")
	if not corpse.is_boss and corpse.body_size.is_empty():
		return _rejected("missing_body_size_data")
	var original_max_health := float(corpse.source_body.get("max_health"))
	if not corpse.try_claim(_caster_owner_id, _simulation_authority_id):
		return _rejected("corpse_already_claimed")
	var result: Dictionary = _controller.raise_boss(
		corpse.corpse_id, original_max_health) if corpse.is_boss else \
		_controller.raise_dead(corpse.corpse_id, corpse.body_size,
			original_max_health)
	if not bool(result.get("accepted", false)):
		corpse.release_claim()
		return result
	var raised = RaisedEnemyScript.new()
	_world_root.add_child(raised)
	raised.global_position = corpse.global_position
	raised.setup_raised(corpse.enemy_id, _palette, result, _caster,
		_caster_owner_id, _simulation_authority_id)
	raised.died.connect(_on_summon_fell)
	raised.dismissed.connect(_on_summon_dismissed)
	_summons[raised.summon_id] = raised
	_corpses.erase(corpse.corpse_id)
	corpse.consume()
	_apply_health_reservation()
	_audio.play_cue("raise")
	return result


func _on_enemy_died(defeated: Node3D) -> void:
	if not is_instance_valid(defeated) or defeated.is_in_group("summons"):
		return
	var enemy_instance_id := defeated.get_instance_id()
	var stable_corpse_id := String(_corpse_id_by_enemy_instance.get(
		enemy_instance_id, ""))
	_corpse_id_by_enemy_instance.erase(enemy_instance_id)
	var shared := _shared_corpse_for(defeated)
	if shared != null:
		_corpses[shared.corpse_id] = shared
		return
	var corpse: RaisedCorpse = RaisedCorpseScript.new()
	_world_root.add_child(corpse)
	corpse.setup_from_enemy(defeated, stable_corpse_id)
	_corpses[corpse.corpse_id] = corpse


func _on_caster_state_changed(_state: int) -> void:
	if _caster.has_method("is_alive") and not bool(_caster.call("is_alive")):
		_pending_cast_spell_id = ""
		_dismiss_all_summons()
		return
	var cast_value: Variant = _caster.get("_cast_spell")
	var current_cast := cast_value as Dictionary if cast_value is Dictionary else {}
	if _pending_cast_spell_id.is_empty():
		if current_cast.is_empty():
			return
		var selected_id := String(_caster.get("selected_spell"))
		var selected := _spells.get(selected_id, {}) as Dictionary
		if String(selected.get("effect_type", "")) in [
				"raise_dead", "raise_boss", "blood_oath"]:
			_pending_cast_spell_id = selected_id
		return
	var committed_id := _pending_cast_spell_id
	_pending_cast_spell_id = ""
	if current_cast.is_empty():
		return
	var committed := _spells.get(committed_id, {}) as Dictionary
	if String(committed.get("effect_type", "")) == "blood_oath":
		apply_blood_oath()
	else:
		raise_nearest(committed_id)


func _nearest_corpse(spell: Dictionary, boss_only: bool) -> RaisedCorpse:
	var nearest: RaisedCorpse
	var nearest_distance := INF
	var maximum_distance := float(spell.get("range_m", INF))
	var forward := -_caster.global_transform.basis.z
	for corpse: RaisedCorpse in corpses():
		if not corpse.is_available():
			continue
		if corpse.is_boss != boss_only:
			continue
		var offset := corpse.global_position - _caster.global_position
		var distance := offset.length()
		if distance > maximum_distance:
			continue
		if not offset.is_zero_approx() and forward.dot(offset.normalized()) < 0.0:
			continue
		if distance < nearest_distance:
			nearest = corpse
			nearest_distance = distance
	return nearest


func _shared_corpse_for(defeated: Node3D) -> RaisedCorpse:
	for node: Node in get_tree().get_nodes_in_group("necromancy_corpses"):
		var corpse := node as RaisedCorpse
		if corpse != null and corpse.source_body == defeated:
			return corpse
	return null


func _on_summon_fell(defeated: Enemy) -> void:
	_on_summon_dismissed(String(defeated.get("summon_id")))


func _on_summon_dismissed(summon_id: String) -> void:
	if not _summons.has(summon_id):
		return
	_summons.erase(summon_id)
	_controller.summon_fell(summon_id)
	_apply_health_reservation()


func _clear_corpses() -> void:
	var discarded := corpses()
	_corpses.clear()
	for corpse: RaisedCorpse in discarded:
		corpse.queue_free()


func _rejected(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


func _apply_health_reservation() -> void:
	if not is_instance_valid(_caster):
		return
	var effective_max: float = _controller.effective_max_health(_base_max_health)
	_caster.set("max_health", effective_max)
	var current_health := float(_caster.get("health"))
	if current_health > effective_max:
		_caster.set("health", effective_max)
