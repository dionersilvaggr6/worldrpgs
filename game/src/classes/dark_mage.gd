class_name DarkMage
extends RefCounted
## Estado data-driven da 7.a origem. Custos, camadas, multiplicadores, duracoes
## e limites de apresentacao vivem exclusivamente nos JSON autorizados.

const ORIGIN_ID := "evil_mage"
const SCHOOL_ID := "mal"
const RAISE_DEAD_ID := "levantar"
const RAISE_BOSS_ID := "erguer_guardiao"
const BLOOD_OATH_ID := "voto_sangue"

var _origin: Dictionary = {}
var _ability: Dictionary = {}
var _school: Dictionary = {}
var _raise_dead_effect: Dictionary = {}
var _raise_boss_effect: Dictionary = {}
var _blood_oath_effect: Dictionary = {}
var _health_budget: Dictionary = {}
var _active_summons: Dictionary = {}
var _spent_corpses: Dictionary = {}
var _oath_layer_count := 0
## 🔴 02-08: isto era "" e o Mateus disse "quando invoco os inimigos mortos eles
## nao me seguem, sao inuteis, fica parado bugado". Sem ordem, o
## necromancy_runtime cai no ramo `else` e poe `summon.target = null` — o morto
## levanta-se e fica especado. O primeiro estado tem de ser uma ordem VALIDA, e
## seguir quem o levantou e o unico defeito que faz sentido: quem acabou de
## gastar PV a levantar um cadaver quer ajuda, nao uma estatua.
## As ordens validas vivem em abilities.json: follow_caster, hold_ground.
var _summon_order := "follow_caster"
var _contract_errors: PackedStringArray = []


func configure(attributes: Dictionary, abilities: Dictionary,
		spells: Dictionary) -> bool:
	_origin = ((attributes.get("classes", {}) as Dictionary).get(
		ORIGIN_ID, {}) as Dictionary).duplicate(true)
	_ability = (abilities.get(ORIGIN_ID, {}) as Dictionary).duplicate(true)
	_school = ((spells.get("_schools", {}) as Dictionary).get(
		SCHOOL_ID, {}) as Dictionary).duplicate(true)
	_raise_dead_effect = ((spells.get(RAISE_DEAD_ID, {}) as Dictionary).get(
		"effect", {}) as Dictionary).duplicate(true)
	_raise_boss_effect = ((spells.get(RAISE_BOSS_ID, {}) as Dictionary).get(
		"effect", {}) as Dictionary).duplicate(true)
	_blood_oath_effect = ((spells.get(BLOOD_OATH_ID, {}) as Dictionary).get(
		"effect", {}) as Dictionary).duplicate(true)
	_health_budget = ((spells.get("_rules", {}) as Dictionary).get(
		"dark_mage_health_budget", {}) as Dictionary).duplicate(true)
	_contract_errors = _validate_contract(attributes, abilities, spells)
	reset_encounter_state()
	return _contract_errors.is_empty()


func contract_errors() -> PackedStringArray:
	return _contract_errors.duplicate()


func mana_capacity(base_mana: int) -> int:
	var origin_trait := _origin.get("origin_trait", {}) as Dictionary
	return roundi(float(base_mana) * float(origin_trait.get("multiplier", 0.0)))


func preview_raise_dead(corpse_id: String, body_size: String,
		original_max_health: float) -> Dictionary:
	var rejection := _raise_dead_rejection_reason(
		corpse_id, body_size, original_max_health)
	if not rejection.is_empty():
		return _rejected(rejection)
	return _preview_accepted(_raised_dead_payload(
		corpse_id, body_size, original_max_health))


func raise_dead(corpse_id: String, body_size: String,
		original_max_health: float) -> Dictionary:
	var preview := preview_raise_dead(corpse_id, body_size, original_max_health)
	if not bool(preview.get("accepted", false)):
		return preview
	var summon := _raised_dead_payload(
		corpse_id, body_size, original_max_health)
	_active_summons[corpse_id] = summon
	_spent_corpses[corpse_id] = true
	return _accepted(summon)


func preview_raise_boss(corpse_id: String,
		original_max_health: float) -> Dictionary:
	var rejection := _raise_boss_rejection_reason(corpse_id, original_max_health)
	if not rejection.is_empty():
		return _rejected(rejection)
	return _preview_accepted(_raised_boss_payload(corpse_id, original_max_health))


func raise_boss(corpse_id: String, original_max_health: float) -> Dictionary:
	var preview := preview_raise_boss(corpse_id, original_max_health)
	if not bool(preview.get("accepted", false)):
		return preview
	var summon := _raised_boss_payload(corpse_id, original_max_health)
	_active_summons[corpse_id] = summon
	_spent_corpses[corpse_id] = true
	return _accepted(summon)


func apply_blood_oath() -> Dictionary:
	var layers := _blood_oath_effect.get("layers", []) as Array
	if _oath_layer_count >= layers.size():
		return _rejected("maximum_oath_layers")
	var next_layer := layers[_oath_layer_count] as Dictionary
	var next_oath_reservation := float(
		next_layer.get("health_cost_fraction_total", 0.0))
	if not _can_replace_oath_reservation(next_oath_reservation):
		return _rejected("insufficient_health_budget")
	_oath_layer_count += 1
	return _accepted({
		"layer": next_layer.get("layer"),
		"health_cost_fraction_total": next_oath_reservation,
		"damage_multiplier": blood_oath_damage_multiplier(),
	})


func blood_oath_damage_multiplier() -> float:
	var layer := _current_oath_layer()
	return 1.0 + float(layer.get("damage_bonus_fraction_total", 0.0))


func blood_oath_layer_count() -> int:
	return _oath_layer_count


func reserved_health_fraction() -> float:
	return _summon_reservation() + float(
		_current_oath_layer().get("health_cost_fraction_total", 0.0))


func available_health_fraction() -> float:
	return maxf(float(_health_budget.get("total_fraction", 0.0))
		- reserved_health_fraction(), 0.0)


func effective_max_health(base_max_health: float) -> float:
	return base_max_health * available_health_fraction()


func active_summon_count() -> int:
	return _active_summons.size()


func has_active_summon(summon_id: String) -> bool:
	return _active_summons.has(summon_id)


func active_summon_ids() -> Array[String]:
	var ids: Array[String] = []
	for summon_id: Variant in _active_summons.keys():
		ids.append(String(summon_id))
	return ids


func summon_fell(summon_id: String) -> Dictionary:
	if not _active_summons.has(summon_id):
		return _rejected("summon_not_active")
	var removed := _active_summons.get(summon_id, {}) as Dictionary
	_active_summons.erase(summon_id)
	return _accepted({
		"summon_id": summon_id,
		"released_health_fraction": removed.get("health_cost_fraction"),
		"corpse_remains_spent": true,
	})


func leave_zone() -> Array[String]:
	var dismissed: Array[String] = []
	for summon_id: Variant in _active_summons.keys().duplicate():
		var summon := _active_summons.get(summon_id, {}) as Dictionary
		if not bool(summon.get("portable", false)):
			dismissed.append(String(summon_id))
			_active_summons.erase(summon_id)
	return dismissed


func use_origin_ability() -> Dictionary:
	if bool(_ability.get("requires_active_summon", false)) \
			and _active_summons.is_empty():
		return _rejected("no_active_summon")
	var orders := _ability.get("orders", []) as Array
	if orders.is_empty():
		return _rejected("missing_orders")
	var current_index := orders.find(_summon_order)
	_summon_order = String(orders[(current_index + 1) % orders.size()])
	for summon_id: Variant in _active_summons.keys():
		(_active_summons[summon_id] as Dictionary)["order"] = _summon_order
	return _accepted({
		"order": _summon_order,
		"presentation": (_ability.get("presentation", {}) as Dictionary).duplicate(true),
	})


func summon_order() -> String:
	return _summon_order


func reset_encounter_state() -> Dictionary:
	var released := reserved_health_fraction()
	_active_summons.clear()
	_oath_layer_count = 0
	_summon_order = String(_ability.get("default_order", ""))
	return {
		"released_health_fraction": released,
		"healed_health": false,
	}


func start_new_world_cycle() -> void:
	reset_encounter_state()
	_spent_corpses.clear()


func _validate_contract(attributes: Dictionary, abilities: Dictionary,
		spells: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if _origin.is_empty() or not (attributes.get("classes", {}) as Dictionary).has(
		ORIGIN_ID):
		errors.append("falta a ficha da setima origem")
	if String(_origin.get("starting_school", "")) != SCHOOL_ID:
		errors.append("a origem nao aponta para a escola vermelha")
	var origin_trait := _origin.get("origin_trait", {}) as Dictionary
	if String(origin_trait.get("effect_type", "")) != "max_mana_multiplier" \
			or float(origin_trait.get("multiplier", 0.0)) <= 0.0:
		errors.append("falta o traco de mana da origem")
	if _ability.is_empty() or not abilities.has(ORIGIN_ID):
		errors.append("falta a habilidade da origem")
	elif String(_ability.get("effect_type", "")) != "toggle_summon_order" \
			or (_ability.get("orders", []) as Array).is_empty():
		errors.append("a habilidade nao declara ordens de invocacao")
	if String(_school.get("cor", "")) != "vermelho":
		errors.append("a escola do mal nao e vermelha")
	if String(_school.get("access_policy", "")) != "sem_bloqueio_de_origem":
		errors.append("a escola vermelha introduz gating de origem")
	if (spells.get(RAISE_DEAD_ID, {}) as Dictionary).get(
		"effect_type", "") != "raise_dead":
		errors.append("Levantar nao declara o consumidor dark mage")
	if _raise_dead_effect.has("max_active_summons") \
			or String(_raise_dead_effect.get("design_limit", "")) != "none":
		errors.append("Levantar introduz um tecto de desenho")
	if (spells.get(RAISE_BOSS_ID, {}) as Dictionary).get(
		"effect_type", "") != "raise_boss" \
			or not bool(_raise_boss_effect.get("portable", false)):
		errors.append("o chefe erguido nao e portatil")
	if (spells.get(BLOOD_OATH_ID, {}) as Dictionary).get(
		"effect_type", "") != "blood_oath" \
			or (_blood_oath_effect.get("layers", []) as Array).is_empty():
		errors.append("Voto de Sangue nao declara camadas")
	if float(_health_budget.get("total_fraction", 0.0)) <= 0.0 \
			or not bool(_health_budget.get("must_remain_alive", false)):
		errors.append("falta o orcamento visivel de PV")
	return errors


func _current_oath_layer() -> Dictionary:
	var layers := _blood_oath_effect.get("layers", []) as Array
	if _oath_layer_count <= 0 or _oath_layer_count > layers.size():
		return {}
	return layers[_oath_layer_count - 1] as Dictionary


func _raise_dead_rejection_reason(corpse_id: String, body_size: String,
		original_max_health: float) -> String:
	if corpse_id.is_empty():
		return "invalid_corpse"
	if _spent_corpses.has(corpse_id):
		return "corpse_already_spent"
	var costs := _raise_dead_effect.get(
		"health_cost_fraction_by_size", {}) as Dictionary
	if not costs.has(body_size):
		return "unknown_body_size"
	if original_max_health <= 0.0:
		return "invalid_original_health"
	if not _can_add_reservation(float(costs.get(body_size, 0.0))):
		return "insufficient_health_budget"
	return ""


func _raise_boss_rejection_reason(corpse_id: String,
		original_max_health: float) -> String:
	if corpse_id.is_empty():
		return "invalid_corpse"
	if _spent_corpses.has(corpse_id):
		return "corpse_already_spent"
	if _active_boss_id() != "":
		return "boss_already_active"
	if original_max_health <= 0.0:
		return "invalid_original_health"
	var health_cost := float(_raise_boss_effect.get("health_cost_fraction", 0.0))
	if not _can_add_reservation(health_cost):
		return "insufficient_health_budget"
	return ""


func _raised_dead_payload(corpse_id: String, body_size: String,
		original_max_health: float) -> Dictionary:
	var costs := _raise_dead_effect.get(
		"health_cost_fraction_by_size", {}) as Dictionary
	return {
		"summon_id": corpse_id,
		"corpse_id": corpse_id,
		"kind": "raised_dead",
		"health_cost_fraction": float(costs.get(body_size, 0.0)),
		"max_health": original_max_health * float(
			_raise_dead_effect.get("raised_health_fraction", 0.0)),
		"portable": false,
		"order": _summon_order,
	}


func _raised_boss_payload(corpse_id: String,
		original_max_health: float) -> Dictionary:
	return {
		"summon_id": corpse_id,
		"corpse_id": corpse_id,
		"kind": "raised_boss",
		"health_cost_fraction": float(
			_raise_boss_effect.get("health_cost_fraction", 0.0)),
		"max_health": original_max_health * float(
			_raise_boss_effect.get("raised_health_fraction", 0.0)),
		"portable": bool(_raise_boss_effect.get("portable", false)),
		"order": _summon_order,
	}


func _summon_reservation() -> float:
	var total := 0.0
	for summon_value: Variant in _active_summons.values():
		total += float((summon_value as Dictionary).get(
			"health_cost_fraction", 0.0))
	return total


func _can_add_reservation(additional: float) -> bool:
	return _fits_budget(reserved_health_fraction() + additional)


func _can_replace_oath_reservation(next_oath_total: float) -> bool:
	return _fits_budget(_summon_reservation() + next_oath_total)


func _fits_budget(future_total: float) -> bool:
	var total := float(_health_budget.get("total_fraction", 0.0))
	if bool(_health_budget.get("must_remain_alive", false)):
		return future_total < total and not is_equal_approx(future_total, total)
	return future_total <= total or is_equal_approx(future_total, total)


func _active_boss_id() -> String:
	for summon_id: Variant in _active_summons.keys():
		if String((_active_summons[summon_id] as Dictionary).get(
				"kind", "")) == "raised_boss":
			return String(summon_id)
	return ""


func _accepted(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	result["accepted"] = true
	result["reserved_health_fraction"] = reserved_health_fraction()
	result["available_health_fraction"] = available_health_fraction()
	return result


func _preview_accepted(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var future_reserved := reserved_health_fraction() + float(
		payload.get("health_cost_fraction", 0.0))
	result["accepted"] = true
	result["future_reserved_health_fraction"] = future_reserved
	result["future_available_health_fraction"] = maxf(float(
		_health_budget.get("total_fraction", 0.0)) - future_reserved, 0.0)
	return result


func _rejected(reason: String) -> Dictionary:
	return {
		"accepted": false,
		"reason": reason,
		"reserved_health_fraction": reserved_health_fraction(),
		"available_health_fraction": available_health_fraction(),
	}
