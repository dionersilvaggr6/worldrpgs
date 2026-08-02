extends SceneTree
## Prova dedicada do ecrã de nível. Corre separado da suite canónica porque este
## agente não é dono de game/src/tests/self_test.gd.
##
## godot --headless --audio-driver Dummy --path game/ \
##   --script res://src/ui/levelup_self_test.gd

const LevelModel = preload("res://src/ui/levelup_model.gd")
const LevelScreen = preload("res://src/ui/levelup_screen.gd")

var _passed := 0
var _failed := 0
var _original_state: Dictionary = {}
var _game_data: Node
var _save_system: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_data = root.get_node("GameData")
	_save_system = root.get_node("SaveSystem")
	_original_state = _game_data.call("save_state_snapshot") as Dictionary
	_test_catalogue_contract()
	_test_shared_currency_and_purchase()
	_test_refusals_do_not_mutate()
	_test_breakpoints_change_the_gain()
	_test_numeric_preview()
	await _test_screen_contract()
	_measure_model_cost()
	_game_data.call("replace_save_state", _original_state)
	print("\n=== SUBIR DE NÍVEL: %d passaram, %d falharam ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_catalogue_contract() -> void:
	var attributes := _game_data.get("attributes") as Dictionary
	var economy := _game_data.get("economy") as Dictionary
	var ui: Dictionary = attributes.get("level_up_ui", {}) as Dictionary
	var rows: Array = ui.get("attribute_rows", []) as Array
	var row_ids: Array = []
	for row_value: Variant in rows:
		row_ids.append(String((row_value as Dictionary).get("id", "")))
	_check(row_ids == (attributes.get("attribute_ids", []) as Array),
		"catálogo: o ecrã cobre os oito atributos na ordem canónica")
	var delivery: Dictionary = ui.get("_entrega", {}) as Dictionary
	_check(delivery.size() == 4 and not String(delivery.get("como_o_jogador_usa", "")).is_empty()
		and not String(delivery.get("como_se_prova", "")).is_empty()
		and not String(delivery.get("arte_e_som", "")).is_empty()
		and not String(delivery.get("custo_na_maquina_do_rico", "")).is_empty(),
		"fio solto: as quatro perguntas têm resposta executável")
	var level_cfg: Dictionary = attributes.get("level", {}) as Dictionary
	var published: Dictionary = level_cfg.get("published_curve_context", {}) as Dictionary
	var early_total := int(published.get("level_1_to_70", 0))
	var late_total := int(published.get("level_71_to_100", 0))
	var published_ratio := float(published.get("late_to_early_ratio", 0.0))
	_check(early_total > 0 and late_total > early_total
		and is_equal_approx(snappedf(float(late_total) / float(early_total), 0.01),
			published_ratio),
		"curva: conserva 680 663 / 1 308 518 e o rácio corrigido 1,92x")
	_check(String(level_cfg.get("currency", "")) == String(
		(economy.get("rules", {}) as Dictionary).get("currency_id", "")),
		"economia: nível e vendedores partilham a moeda almas")


func _test_shared_currency_and_purchase() -> void:
	var state := _state_with_souls("warrior", int(_game_data.call("level_cost", 2)) + 77)
	var before := state.duplicate(true)
	var model := LevelModel.build(state, "vida")
	_check(int(model.get("cost", -1)) == int(_game_data.call("level_cost", 2))
		and String(model.get("currency_id", "")) == "almas",
		"custo: compra exactamente o nível seguinte na fonte económica")
	var result := LevelModel.purchase(state, "vida")
	var working: Dictionary = result.get("state", {}) as Dictionary
	var progression := _progression(working)
	var attrs: Dictionary = progression.get("attributes", {}) as Dictionary
	var before_attrs: Dictionary = _progression(before).get("attributes", {}) as Dictionary
	_check(bool(result.get("ok", false))
		and int(progression.get("level", 0)) == int(_progression(before).get("level", 0))
			+ int(((_game_data.get("attributes") as Dictionary).get(
				"level", {}) as Dictionary).get("points_per_level", 0))
		and int(attrs.get("vida", 0)) == int(before_attrs.get("vida", 0)) + 1
		and int(progression.get("souls_held", -1))
			== int(_progression(before).get("souls_held", 0)) - int(result.get("cost", 0)),
		"transacção: um ponto sobe nível/atributo e cobra as mesmas almas")
	var other_unchanged := true
	for attribute_value: Variant in (_game_data.get("attributes") as Dictionary).get(
			"attribute_ids", []):
		var attribute_id := String(attribute_value)
		if attribute_id != "vida" and attrs.get(attribute_id) != before_attrs.get(attribute_id):
			other_unchanged = false
	_check(other_unchanged and state == before,
		"transacção: os sete atributos não escolhidos e o estado de entrada não mudam")


func _test_refusals_do_not_mutate() -> void:
	var poor := _state_with_souls("warrior", 0)
	var poor_before := poor.duplicate(true)
	var refused := LevelModel.purchase(poor, "vida")
	_check(not bool(refused.get("ok", true))
		and String(refused.get("status", "")) == "insufficient_currency"
		and poor == poor_before
		and (refused.get("state", {}) as Dictionary) == poor_before,
		"recusa: almas insuficientes não alteram nem cobram o save")
	var capped_attribute := _state_with_souls("warrior", 999999)
	_progression(capped_attribute).attributes["vida"] = int(
		(_game_data.get("attributes") as Dictionary).get("max_per_attribute", 0))
	var capped_before := capped_attribute.duplicate(true)
	var attribute_refused := LevelModel.purchase(capped_attribute, "vida")
	_check(String(attribute_refused.get("status", "")) == "attribute_cap"
		and capped_attribute == capped_before,
		"recusa: o máximo 70 do atributo não é ultrapassado")
	var capped_level := _state_with_souls("warrior", 999999)
	_progression(capped_level)["level"] = int(
		((_game_data.get("attributes") as Dictionary).get("level", {}) as Dictionary).get(
			"max_level", 0))
	var level_before := capped_level.duplicate(true)
	var level_refused := LevelModel.purchase(capped_level, "stamina")
	_check(String(level_refused.get("status", "")) == "level_cap"
		and capped_level == level_before,
		"recusa: o nível máximo 100 não é ultrapassado")
	var invalid := LevelModel.purchase(poor, "abre_porta")
	_check(String(invalid.get("status", "")) == "invalid_attribute",
		"Lei 1: o modelo só aceita atributos; não existe compra de acesso")


func _test_breakpoints_change_the_gain() -> void:
	var state := _state_with_souls("warrior", 999999)
	_check(_piecewise_preview_matches(state, "vida", "health", "health"),
		"Vida: o ganho muda em 20/50 e não é uma recta")
	_check(_piecewise_preview_matches(state, "stamina", "stamina", "stamina"),
		"Stamina: o ganho muda em 20/40 e mostra o rendimento tardio")
	_check(_piecewise_preview_matches(state, "constituicao", "defense", "defense"),
		"Constituição: o ganho muda em 25/50")
	_check(_piecewise_preview_matches(state, "carga", "load_capacity", "load_capacity"),
		"Carga: o ganho muda em 30/50 e termina no marco 70")
	var attrs: Dictionary = _progression(state).get("attributes", {}) as Dictionary
	var damage_bands: Array = (((_game_data.get("attributes") as Dictionary).get(
		"damage", {}) as Dictionary).get("scale_bands", []) as Array)
	var damage_changes_match := true
	for index: int in range(damage_bands.size() - 1):
		var boundary := int((damage_bands[index] as Dictionary).get("until", 0))
		attrs["forca"] = boundary - 1
		var before_boundary := float((LevelModel.preview_attribute(
			state, "forca").get("delta", {}) as Dictionary).get("damage", 0.0))
		attrs["forca"] = boundary
		var after_boundary := float((LevelModel.preview_attribute(
			state, "forca").get("delta", {}) as Dictionary).get("damage", 0.0))
		var expected_ratio := float((damage_bands[index] as Dictionary).get(
			"per_point", 0.0)) / float((damage_bands[index + 1] as Dictionary).get(
				"per_point", 1.0))
		if not is_equal_approx(before_boundary, after_boundary * expected_ratio):
			damage_changes_match = false
	_check(damage_changes_match,
		"Dano: o ganho por Força cai no marco 40 e conserva a curva 40/60/70")
	var model := LevelModel.build(state, "vida")
	var markers_match_catalogue := true
	for row: Dictionary in model.get("attribute_rows", []):
		var row_cfg := _attribute_row_config(String(row.get("id", "")))
		if row.get("curve_markers", []) != _expected_markers(row_cfg):
			markers_match_catalogue = false
	_check(markers_match_catalogue,
		"ecrã: publica os marcos reais de cada curva, incluindo 20/40/70")


func _test_numeric_preview() -> void:
	var warrior := _state_with_souls("warrior", 999999)
	var vida := LevelModel.preview_attribute(warrior, "vida")
	var vida_before: Dictionary = vida.get("before", {}) as Dictionary
	var vida_after: Dictionary = vida.get("after", {}) as Dictionary
	_check(float(vida_after.get("health", 0.0)) > float(vida_before.get("health", 0.0))
		and is_equal_approx(float(vida_after.get("damage", 0.0)),
			float(vida_before.get("damage", 0.0)))
		and int(vida_after.get("dodges", -1)) == int(vida_before.get("dodges", -2)),
		"pré-visualização: Vida mostra mais PV e zero dano/esquivas inventados")
	var stamina := LevelModel.preview_attribute(warrior, "stamina")
	var stamina_before: Dictionary = stamina.get("before", {}) as Dictionary
	var stamina_after: Dictionary = stamina.get("after", {}) as Dictionary
	var dodge_cost := float((_game_data.call("section", "dodge") as Dictionary).get(
		"stamina_cost", 0.0))
	_check(int(stamina_before.get("dodges", -1)) == floori(
		float(stamina_before.get("stamina", 0.0)) / dodge_cost)
		and int(stamina_after.get("dodges", -1)) == floori(
			float(stamina_after.get("stamina", 0.0)) / dodge_cost),
		"pré-visualização: quanto rola vem da stamina e do custo actual da esquiva")
	var strength := LevelModel.preview_attribute(warrior, "forca")
	var strength_before: Dictionary = strength.get("before", {}) as Dictionary
	var strength_after: Dictionary = strength.get("after", {}) as Dictionary
	_check(String(strength_before.get("weapon_id", "")) == "longsword"
		and float(strength_after.get("damage", 0.0)) > float(strength_before.get("damage", 0.0)),
		"pré-visualização: quanto dano ganha usa o golpe leve da arma equipada")
	var sorcerer := _state_with_souls("sorcerer", 999999)
	var intelligence := LevelModel.preview_attribute(sorcerer, "inteligencia")
	var faith := LevelModel.preview_attribute(sorcerer, "fe")
	var mana_cfg: Dictionary = (((_game_data.get("attributes") as Dictionary).get(
		"formulas", {}) as Dictionary).get("mana", {}) as Dictionary)
	_check(is_equal_approx(float((intelligence.get("delta", {}) as Dictionary).get("mana", 0.0)),
			float(mana_cfg.get("per_point", 0.0)))
		and is_equal_approx(float((faith.get("delta", {}) as Dictionary).get("mana", 1.0)), 0.0),
		"pré-visualização: mana usa o maior de Inteligência/Fé e mostra +0 quando é real")


func _test_screen_contract() -> void:
	var state := _state_with_souls("warrior", int(_game_data.call("level_cost", 2)))
	_game_data.call("replace_save_state", state)
	var screen := LevelScreen.new()
	root.add_child(screen)
	screen.open_for_current()
	await process_frame
	var focused := root.gui_get_focus_owner()
	var texture_nodes := screen.find_children("*", "TextureRect", true, false)
	var audio_nodes := screen.find_children("*", "AudioStreamPlayer", true, false)
	var audio_ok := false
	if not audio_nodes.is_empty():
		var player := audio_nodes[0] as AudioStreamPlayer
		var stream := player.stream as AudioStreamWAV
		audio_ok = stream != null and stream.mix_rate == 22050 and not stream.stereo
	_check(screen.visible and screen.attribute_button_count() == ((
		(_game_data.get("attributes") as Dictionary).get("attribute_ids", []) as Array).size()),
		"ecrã: abre com os oito atributos e a pré-visualização visível")
	_check(focused is Button,
		"input: abrir entrega foco navegável a teclado/comando")
	_check(screen.select_attribute("forca")
		and String(screen.view_model().get("selected_attribute", "")) == "forca",
		"input: a escolha explícita muda o atributo pendente sem o comprar")
	_check(texture_nodes.is_empty() and audio_ok,
		"arte/som: zero textura nova e confirmação mono sintetizada em código")
	var before := _game_data.call("save_state_snapshot") as Dictionary
	_check(_progression(before).get("level") == _progression(state).get("level"),
		"confirmação: navegar e pré-visualizar não mutam o save")
	screen.close_screen()
	_check(not screen.visible, "input: cancelar/voltar fecha o ecrã")
	screen.free()


func _measure_model_cost() -> void:
	var state := _state_with_souls("warrior", 999999)
	for _warmup: int in range(20):
		LevelModel.build(state, "vida")
	var samples: Array[float] = []
	for _sample: int in range(9):
		var started := Time.get_ticks_usec()
		for _iteration: int in range(100):
			LevelModel.build(state, "vida")
		samples.append(float(Time.get_ticks_usec() - started) / 100.0)
	samples.sort()
	print("=== CUSTO MODELO NÍVEL: %.2f us mediana por pré-visualização (%.2f–%.2f) ===" % [
		samples[4], samples.front(), samples.back()])


func _state_with_souls(class_id: String, souls: int) -> Dictionary:
	var state := _save_system.call("create_save", "levelup-self-test", class_id) as Dictionary
	_progression(state)["souls_held"] = souls
	return state


func _delta_at(state: Dictionary, attribute_id: String, value: int, metric: String) -> float:
	var attrs: Dictionary = _progression(state).get("attributes", {}) as Dictionary
	attrs[attribute_id] = value
	var preview := LevelModel.preview_attribute(state, attribute_id)
	return float((preview.get("delta", {}) as Dictionary).get(metric, 0.0))


func _piecewise_preview_matches(state: Dictionary, attribute_id: String,
		metric: String, formula_id: String) -> bool:
	var attributes := _game_data.get("attributes") as Dictionary
	var formula: Dictionary = ((attributes.get("formulas", {}) as Dictionary).get(
		formula_id, {}) as Dictionary)
	var bands: Array = formula.get("bands", []) as Array
	if bands.size() < 2:
		return false
	for index: int in range(bands.size() - 1):
		var boundary := int((bands[index] as Dictionary).get("until", 0))
		var before_boundary := _delta_at(state, attribute_id, boundary - 1, metric)
		var after_boundary := _delta_at(state, attribute_id, boundary, metric)
		if not is_equal_approx(before_boundary,
				float((bands[index] as Dictionary).get("per_point", 0.0))):
			return false
		if not is_equal_approx(after_boundary,
				float((bands[index + 1] as Dictionary).get("per_point", 0.0))):
			return false
	return true


func _attribute_row_config(attribute_id: String) -> Dictionary:
	var ui: Dictionary = ((_game_data.get("attributes") as Dictionary).get(
		"level_up_ui", {}) as Dictionary)
	for row_value: Variant in ui.get("attribute_rows", []):
		var row := row_value as Dictionary
		if String(row.get("id", "")) == attribute_id:
			return row
	return {}


func _expected_markers(row_cfg: Dictionary) -> Array[int]:
	var attributes := _game_data.get("attributes") as Dictionary
	var result: Array[int] = []
	for key: String in ["curve_path", "secondary_curve_path"]:
		var value: Variant = _value_at_path(attributes, String(row_cfg.get(key, "")))
		if value is Array:
			for band_value: Variant in value as Array:
				var marker := int((band_value as Dictionary).get("until", 0))
				if marker > 0 and not result.has(marker):
					result.append(marker)
		elif value is int or value is float:
			var marker := int(value)
			if marker > 0 and not result.has(marker):
				result.append(marker)
	var maximum_attribute := int(attributes.get("max_per_attribute", 0))
	if not result.has(maximum_attribute):
		result.append(maximum_attribute)
	result.sort()
	return result


func _value_at_path(source: Dictionary, path: String) -> Variant:
	var current: Variant = source
	for part: String in path.split("/", false):
		if not current is Dictionary:
			return null
		current = (current as Dictionary).get(part)
	return current


func _progression(state: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	return character.get("progression", {}) as Dictionary


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % label)
	else:
		_failed += 1
		push_error("  FALHA %s" % label)
