extends SceneTree
## Prova focal da setima origem. Corre com:
##   godot --headless --audio-driver Dummy --path game \
##     --script res://src/classes/dark_mage_origin_test.gd

const ORIGIN_ID := "evil_mage"
const SORCERER_ID := "sorcerer"
const EXPECTED_ORIGIN_COUNT := 7
const DarkMageScript := preload("res://src/classes/dark_mage.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var attributes := _load_json("res://data/attributes.json")
	var classes := attributes.get("classes", {}) as Dictionary
	var origin_ids: Array[String] = []
	for raw_id: Variant in classes.keys():
		var origin_id := String(raw_id)
		if not origin_id.begins_with("_"):
			origin_ids.append(origin_id)
	_check(origin_ids.size() == EXPECTED_ORIGIN_COUNT
		and origin_ids.has(ORIGIN_ID) and origin_ids.has(SORCERER_ID),
		"criacao deriva exactamente sete origens e conserva Feiticeiro e Mago do Mal")
	_test_initial_sheet(attributes, classes.get(ORIGIN_ID, {}) as Dictionary)
	var abilities := _load_json("res://data/abilities.json")
	var spells := _load_json("res://data/spells.json")
	_test_red_school_decisions(spells)
	_test_runtime_contract(attributes, abilities, spells)
	print("[mago-do-mal] %d passaram, %d falharam" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_initial_sheet(attributes: Dictionary, origin: Dictionary) -> void:
	var base_value := int(attributes.get("base_value", 0))
	var spent := 0
	for attribute_value: Variant in attributes.get("attribute_ids", []) as Array:
		spent += int(origin.get(String(attribute_value), base_value)) - base_value
	_check(spent == int(attributes.get("class_bonus_points", -1)),
		"ficha distribui exactamente o bolo de pontos comum")

	var spells := _load_json("res://data/spells.json")
	var starting_spells := origin.get("starting_spells", []) as Array
	var all_start_in_red_school := not starting_spells.is_empty()
	for spell_value: Variant in starting_spells:
		var spell := spells.get(String(spell_value), {}) as Dictionary
		all_start_in_red_school = all_start_in_red_school \
			and String(spell.get("school", "")) == String(origin.get("starting_school", ""))
	_check(all_start_in_red_school,
		"ficha inicial aponta apenas para feiticos existentes da escola vermelha")

	var origin_trait := origin.get("origin_trait", {}) as Dictionary
	_check(String(origin_trait.get("effect_type", "")) == "max_mana_multiplier"
		and float(origin_trait.get("multiplier", 0.0)) > 1.0
		and bool(origin_trait.get("always_active", false))
		and bool(origin_trait.get("visible_in_sheet", false)),
		"traco decidido aumenta a reserva e fica visivel na ficha")

	var abilities := _load_json("res://data/abilities.json")
	var ability := abilities.get(ORIGIN_ID, {}) as Dictionary
	var controls := _load_json("res://data/controls.json")
	var actions := controls.get("actions", {}) as Dictionary
	_check(String(ability.get("id", "")) == String(origin.get("ability_id", ""))
		and actions.has(String(ability.get("input_action", "")))
		and float(ability.get("cooldown_s", 0.0)) > 0.0
		and float(ability.get("commit_point_s", -1.0)) >= 0.0
		and float(ability.get("commit_point_s", 0.0))
			<= float(ability.get("activation_s", 0.0)),
		"habilidade propria resolve uma accao remapeavel")


func _test_red_school_decisions(spells: Dictionary) -> void:
	var school := ((spells.get("_schools", {}) as Dictionary).get("mal", {})
		as Dictionary)
	var instrument_choice := school.get("instrument_choice", {}) as Dictionary
	_check(String(school.get("cor", "")) == "vermelho"
		and String(school.get("access_policy", "")) == "sem_bloqueio_de_origem"
		and String(instrument_choice.get("policy", "")) == "livre"
		and not (instrument_choice.get("roles", []) as Array).is_empty(),
		"escola e vermelha, sem gating e com escolha livre de instrumento")

	var raise_dead := spells.get("levantar", {}) as Dictionary
	var raise_dead_effect := raise_dead.get("effect", {}) as Dictionary
	_check(String(raise_dead.get("effect_type", "")) == "raise_dead"
		and String(raise_dead_effect.get("design_limit", "")) == "none"
		and not raise_dead_effect.has("max_active_summons")
		and not (raise_dead_effect.get("health_cost_fraction_by_size", {})
			as Dictionary).is_empty(),
		"Levantar nao tem tecto de desenho; o orcamento e o PV gasto")

	var raise_boss_effect := ((spells.get("erguer_guardiao", {}) as Dictionary).get(
		"effect", {}) as Dictionary)
	_check(bool(raise_boss_effect.get("portable", false))
		and String(raise_boss_effect.get("active_policy", "")) == "single_boss"
		and not (raise_boss_effect.get("ends_on", []) as Array).has("leave_zone"),
		"guardiao erguido e unico e portatil entre zonas")

	var oath := spells.get("voto_sangue", {}) as Dictionary
	var oath_effect := oath.get("effect", {}) as Dictionary
	var layers := oath_effect.get("layers", []) as Array
	var last_layer := layers.back() as Dictionary if not layers.is_empty() else {}
	var budget := ((spells.get("_rules", {}) as Dictionary).get(
		"dark_mage_health_budget", {}) as Dictionary)
	var exclusive_sum := float(raise_boss_effect.get("health_cost_fraction", 0.0)) \
		+ float(last_layer.get("health_cost_fraction_total", 0.0))
	_check(String(oath.get("effect_type", "")) == "blood_oath"
		and layers.size() > 1
		and float(last_layer.get("damage_bonus_fraction_total", 0.0)) > 0.0
		and exclusive_sum > float(budget.get("total_fraction", 1.0))
		and String(oath.get("tuning_state", "")).contains("[TENSÃO]"),
		"Voto empilha e fica matematicamente exclusivo do chefe sem resolver a tensao")


func _test_runtime_contract(attributes: Dictionary, abilities: Dictionary,
		spells: Dictionary) -> void:
	var controller = _new_controller(attributes, abilities, spells)
	_check(controller != null and controller.contract_errors().is_empty(),
		"runtime configura apenas a partir dos tres catalogos autorizados")
	if controller == null:
		return

	var origin := (attributes.get("classes", {}) as Dictionary).get(
		ORIGIN_ID, {}) as Dictionary
	var origin_trait := origin.get("origin_trait", {}) as Dictionary
	var mana_formula := (attributes.get("formulas", {}) as Dictionary).get(
		"mana", {}) as Dictionary
	var base_mana := int(mana_formula.get("base", 0))
	_check(controller.mana_capacity(base_mana) == roundi(
		float(base_mana) * float(origin_trait.get("multiplier", 0.0))),
		"traco aplica a reserva decidida sem numero duplicado no codigo")

	var raise_effect := (spells.get("levantar", {}) as Dictionary).get(
		"effect", {}) as Dictionary
	var costs := raise_effect.get("health_cost_fraction_by_size", {}) as Dictionary
	var size_id := String(costs.keys()[0]) if not costs.is_empty() else ""
	var budget := ((spells.get("_rules", {}) as Dictionary).get(
		"dark_mage_health_budget", {}) as Dictionary)
	var health_cost := float(costs.get(size_id, 0.0))
	var attempts := ceili(float(budget.get("total_fraction", 0.0)) /
		health_cost) + 1 if health_cost > 0.0 else 1
	var last_raise := {}
	for corpse_index: int in range(attempts):
		last_raise = controller.raise_dead(
			"corpse-%d" % corpse_index, size_id, float(base_mana))
		if not bool(last_raise.get("accepted", false)):
			break
	_check(String(last_raise.get("reason", "")) == "insufficient_health_budget"
		and controller.active_summon_count() > 1,
		"invocacoes acabam pelo orcamento de PV e nao por tecto de desenho")

	controller = _new_controller(attributes, abilities, spells)
	var first_raise: Dictionary = controller.raise_dead("spent-corpse", size_id,
		float(base_mana))
	controller.summon_fell(String(first_raise.get("summon_id", "")))
	var repeated_raise: Dictionary = controller.raise_dead("spent-corpse", size_id,
		float(base_mana))
	_check(bool(first_raise.get("accepted", false))
		and String(repeated_raise.get("reason", "")) == "corpse_already_spent",
		"o mesmo corpo nunca se levanta outra vez")

	controller = _new_controller(attributes, abilities, spells)
	controller.raise_dead("zone-corpse", size_id, float(base_mana))
	var first_boss: Dictionary = controller.raise_boss("boss-corpse", float(base_mana))
	var second_boss: Dictionary = controller.raise_boss("other-boss", float(base_mana))
	controller.leave_zone()
	_check(bool(first_boss.get("accepted", false))
		and String(second_boss.get("reason", "")) == "boss_already_active"
		and controller.has_active_summon(String(first_boss.get("summon_id", "")))
		and not controller.has_active_summon("zone-corpse"),
		"um unico chefe atravessa zonas e os mortos comuns nao")

	var order_before: String = controller.summon_order()
	var order_result: Dictionary = controller.use_origin_ability()
	_check(bool(order_result.get("accepted", false))
		and String(order_result.get("order", "")) != order_before
		and not (order_result.get("presentation", {}) as Dictionary).is_empty(),
		"V alterna a ordem dos invocados e publica feedback audiovisual")

	controller = _new_controller(attributes, abilities, spells)
	var oath_layers := ((spells.get("voto_sangue", {}) as Dictionary).get(
		"effect", {}) as Dictionary).get("layers", []) as Array
	var oath_result := {}
	for _layer_value: Variant in oath_layers:
		oath_result = controller.apply_blood_oath()
		if not bool(oath_result.get("accepted", false)):
			break
	var final_layer := oath_layers.back() as Dictionary if not oath_layers.is_empty() else {}
	_check(bool(oath_result.get("accepted", false))
		and is_equal_approx(controller.blood_oath_damage_multiplier(),
			1.0 + float(final_layer.get("damage_bonus_fraction_total", 0.0)))
		and String(controller.apply_blood_oath().get("reason", "")) == "maximum_oath_layers",
		"Voto sozinho chega a todas as camadas decididas e para ai")

	controller = _new_controller(attributes, abilities, spells)
	controller.raise_boss("exclusive-boss", float(base_mana))
	var all_oath_layers_with_boss := true
	var exclusive_failure := {}
	for _layer_value: Variant in oath_layers:
		exclusive_failure = controller.apply_blood_oath()
		all_oath_layers_with_boss = all_oath_layers_with_boss \
			and bool(exclusive_failure.get("accepted", false))
	_check(not all_oath_layers_with_boss
		and String(exclusive_failure.get("reason", "")) == "insufficient_health_budget",
		"chefe e Voto completo sao matematicamente exclusivos no runtime")
	var rest_result: Dictionary = controller.reset_encounter_state()
	_check(float(rest_result.get("released_health_fraction", 0.0)) > 0.0
		and not bool(rest_result.get("healed_health", true))
		and is_zero_approx(controller.reserved_health_fraction())
		and controller.active_summon_count() == 0
		and controller.blood_oath_layer_count() == 0,
		"descanso termina invocacoes e Voto, devolve a barra maxima e nao cura PV")


func _new_controller(attributes: Dictionary, abilities: Dictionary,
		spells: Dictionary):
	var controller = DarkMageScript.new()
	return controller if controller.configure(attributes, abilities, spells) else null


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("[mago-do-mal] FALHOU: %s" % label)
