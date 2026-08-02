extends SceneTree
## Prova focal da caixa de acesso rapido. Corre sem cena nem renderer:
##   godot --headless --audio-driver Dummy --path game/ \
##     --script res://src/ui/quick_slots_self_test.gd

const QuickSlotsModelScript = preload("res://src/ui/quick_slots_model.gd")

const EXPECTED_SLOTS := ["right_hand", "left_hand", "spell", "item"]

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var weapons := _load_json("res://data/weapons.json")
	var spells := _load_json("res://data/spells.json")
	var controls := _load_json("res://data/controls.json")
	var loadouts: Dictionary = weapons.get("loadouts", {}) as Dictionary
	var default_spells: Array = (spells.get("_rules", {}) as Dictionary).get(
		"default_favorites", []) as Array
	var origin_ids: Array[String] = []
	for origin_value: Variant in loadouts.keys():
		var origin_id := String(origin_value)
		if not origin_id.begins_with("_"):
			origin_ids.append(origin_id)
	_check(not origin_ids.is_empty(), "arranque: o catalogo declara origens jogaveis")

	for origin_id: String in origin_ids:
		var loadout: Dictionary = loadouts.get(origin_id, {}) as Dictionary
		var state := _empty_save(origin_id, default_spells)
		QuickSlotsModelScript.normalise_state(state, weapons, default_spells)
		var items: Dictionary = ((state.get("character", {}) as Dictionary).get(
			"inventory", {}) as Dictionary).get("items", {}) as Dictionary
		_check(_owns_loadout(items, loadout),
			"arranque: %s recebe armas e armadura da origem" % origin_id)
		var equipment: Dictionary = ((state.get("character", {}) as Dictionary).get(
			"inventory", {}) as Dictionary).get("equipment", {}) as Dictionary
		_check(_equips_loadout(equipment, loadout),
			"arranque: %s equipa o kit declarado da origem" % origin_id)
		_check(int(items.get("consumivel:frasco_bruma", 0)) > 0,
			"arranque: %s ve o Frasco de Bruma na mochila" % origin_id)

		var slots: Dictionary = QuickSlotsModelScript.slot_keys(state)
		_check(slots.size() == EXPECTED_SLOTS.size(),
			"caixa: %s apresenta exactamente as quatro categorias" % origin_id)
		for slot_name: String in EXPECTED_SLOTS:
			_check(_filled_slot(slots, slot_name),
				"caixa: %s preenche %s" % [origin_id, slot_name])

	var actions: Dictionary = controls.get("actions", {}) as Dictionary
	_check(actions.has("next_spell") and actions.has("loadout_prev") \
		and actions.has("loadout_next") and actions.has("use_item"),
		"controlos: a caixa referencia apenas accoes declaradas nos dados")
	var hotbar_actions: Array[String] = []
	for action_value: Variant in actions.keys():
		var action := String(action_value)
		if action.begins_with("hotbar_"):
			hotbar_actions.append(action)
	_check(not hotbar_actions.is_empty(),
		"controlos: seleccao de consumivel nasce das accoes hotbar do catalogo")
	var ui_source := FileAccess.get_file_as_string("res://src/ui/quick_slots.gd")
	_check(not ui_source.contains("Engine.time_scale =") \
		and not ui_source.contains("get_tree().paused ="),
		"fluxo: trocar na caixa nao pausa nem altera o tempo do jogo")
	var unequipped_state := _empty_save("warrior", default_spells)
	QuickSlotsModelScript.normalise_state(unequipped_state, weapons, default_spells)
	var unequipped_inventory: Dictionary = ((unequipped_state.get(
		"character", {}) as Dictionary).get("inventory", {}) as Dictionary)
	var unequipped_equipment: Dictionary = unequipped_inventory.get(
		"equipment", {}) as Dictionary
	unequipped_equipment["main"] = null
	QuickSlotsModelScript.normalise_state(unequipped_state, weapons, default_spells)
	_check(unequipped_equipment.get("main") == null,
		"migracao: nao volta a equipar uma arma desequipada deliberadamente")
	var positional_state := _empty_save("warrior", default_spells)
	var positional_inventory: Dictionary = ((positional_state.get(
		"character", {}) as Dictionary).get("inventory", {}) as Dictionary)
	positional_inventory["quick_slots"] = ["", "bomba_bruma", "bomba_bruma"]
	QuickSlotsModelScript.normalise_state(positional_state, weapons, default_spells)
	var positional: Array = positional_inventory.get("quick_slots", []) as Array
	_check(positional == ["", "consumivel:bomba_bruma", ""],
		"migracao: preserva indices, completa chaves antigas e limpa duplicados")
	_check(String(QuickSlotsModelScript.slot_keys(positional_state).get("item", "x")) == "",
		"caixa: uma primeira ranhura vazia nao bebe o item de outra posicao")

	print("QUICK_SLOTS_SELF_TEST %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _empty_save(origin_id: String, default_spells: Array) -> Dictionary:
	return {
		"character": {
			"identity": {"class_id": origin_id},
			"progression": {"known_spells": default_spells.duplicate()},
			"inventory": {
				"items": {},
				"favorite_items": [],
				"equipment": {
					"main": null,
					"offhand": null,
					"armor": [],
					"rings": [],
					"spell_favorites": [],
				},
				"quick_slots": [],
			},
		},
	}


func _owns_loadout(items: Dictionary, loadout: Dictionary) -> bool:
	for weapon_slot: String in ["main", "offhand"]:
		var weapon_value: Variant = loadout.get(weapon_slot)
		if weapon_value != null and String(weapon_value) != "" \
				and int(items.get("arma:%s" % String(weapon_value), 0)) <= 0:
			return false
	for armor_value: Variant in loadout.get("pecas", []):
		if int(items.get("armadura:%s" % String(armor_value), 0)) <= 0:
			return false
	return not items.is_empty()


func _filled_slot(slots: Dictionary, slot_name: String) -> bool:
	return slots.has(slot_name) and String(slots.get(slot_name, "")) != ""


func _equips_loadout(equipment: Dictionary, loadout: Dictionary) -> bool:
	return equipment.get("main") == loadout.get("main") \
		and equipment.get("offhand") == loadout.get("offhand") \
		and (equipment.get("armor", []) as Array) == (loadout.get("pecas", []) as Array)


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % label)
	else:
		_failed += 1
		push_error("FAIL: %s" % label)
