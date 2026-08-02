extends Node
## Estado mutavel da mochila. A mochila nao tem limite: este sistema nunca
## rejeita uma recolha por peso ou espaco. A carga deriva apenas do equipamento.

signal inventory_changed

const FILTERS := ["todos", "armas", "armadura", "aneis", "magias", "consumiveis", "materiais", "favoritos"]
const MAX_SPELL_FAVORITES := 8
const QuickSlotsModelScript = preload("res://src/ui/quick_slots_model.gd")
const QUICK_SLOT_NAMES := QuickSlotsModelScript.SLOT_NAMES
const FLASK_ITEM_KEY := QuickSlotsModelScript.FLASK_ITEM_KEY
const FREE_HAND_KEY := QuickSlotsModelScript.FREE_HAND_KEY
const QUICK_SLOT_ACTIONS := {
	"right_hand": "loadout_next",
	"left_hand": "loadout_prev",
	"spell": "next_spell",
	"item": "next_item",
}
const QuickSlotsScript = preload("res://src/ui/quick_slots.gd")

var _quick_slots_hud: CanvasLayer


func normalise_state(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	var defaults: Array = (GameData.spells.get("_rules", {}) as Dictionary).get(
		"default_favorites", []) as Array
	var changed: bool = QuickSlotsModelScript.normalise_state(
		state, GameData.weapons, defaults)
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	var items: Dictionary = inventory.get("items", {}) as Dictionary
	var known: Array = progression.get("known_spells", []) as Array
	if known.is_empty():
		known = defaults.duplicate()
		progression["known_spells"] = known
		changed = true
	inventory["items"] = items
	inventory["equipment"] = equipment
	character["progression"] = progression
	character["inventory"] = inventory
	state["character"] = character
	return changed


func normalise_current(persist := true) -> bool:
	_ensure_quick_slots_hud()
	var state := GameData.save_state_snapshot()
	if not normalise_state(state):
		return true
	GameData.replace_save_state(state)
	var saved := not persist or SaveSystem.save_current()
	if saved:
		inventory_changed.emit()
	return saved


func entries(state := {}) -> Array[Dictionary]:
	var working: Dictionary = state if not (state as Dictionary).is_empty() \
		else GameData.save_state_snapshot()
	normalise_state(working)
	var character: Dictionary = working.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var items: Dictionary = inventory.get("items", {}) as Dictionary
	var result: Array[Dictionary] = []
	for raw_key: Variant in items.keys():
		var entry := describe_item(String(raw_key), int(items.get(raw_key, 0)), working)
		if not entry.is_empty() and int(entry.get("count", 0)) > 0:
			result.append(entry)
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	for spell_value: Variant in progression.get("known_spells", []):
		var entry := describe_item("magia:%s" % String(spell_value), 1, working)
		if not entry.is_empty():
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", "")))
	return result


func describe_item(item_key: String, count := 1, state := {}) -> Dictionary:
	var parts := item_key.split(":", false, 1)
	var kind := String(parts[0]) if parts.size() == 2 else "desconhecido"
	var item_id := String(parts[1]) if parts.size() == 2 else item_key
	var data := {}
	var name := item_id.replace("_", " ").capitalize()
	match kind:
		"arma":
			data = GameData.equipment_weapon(item_id)
			if data.is_empty():
				data = GameData.weapon(item_id)
			name = String(data.get("nome", data.get("display_name", name)))
		"armadura":
			data = GameData.equipment_armor(item_id)
			if data.is_empty():
				data = (GameData.armor.get("pieces", {}) as Dictionary).get(item_id, {}) as Dictionary
			name = String(data.get("nome", name))
		"anel":
			data = GameData.ring(item_id)
			name = String(data.get("nome", name))
		"magia":
			data = GameData.spell(item_id)
			name = String(data.get("display_name", name))
		"material":
			data = GameData.material(item_id)
			name = String(data.get("display_name", name))
		"consumivel":
			if item_key == FLASK_ITEM_KEY:
				data = GameData.section("flask").duplicate(true)
				name = "Frasco de Bruma"
			else:
				data = GameData.consumable(item_id)
				name = String(data.get("display_name", name))
		_:
			return {}
	var actual_state: Dictionary = state if not (state as Dictionary).is_empty() \
		else GameData.save_state_snapshot()
	return {
		"key": item_key, "id": item_id, "kind": kind, "name": name,
		"count": count, "data": data, "equipped": is_equipped(item_key, actual_state),
		"favorite": is_favorite(item_key, actual_state),
	}


func filtered_entries(filter_name: String, state := {}) -> Array[Dictionary]:
	var aliases := {"armas": "arma", "armadura": "armadura", "aneis": "anel",
		"magias": "magia", "consumiveis": "consumivel", "materiais": "material"}
	var result: Array[Dictionary] = []
	for entry: Dictionary in entries(state):
		if filter_name == "todos" or (filter_name == "favoritos" and bool(entry.favorite)) \
				or String(entry.kind) == String(aliases.get(filter_name, "")):
			result.append(entry)
	return result


## Fronteira pura usada por recolhas e transaccoes compostas. A mochila nao
## tem capacidade maxima; a unica recusa e um ID inexistente ou quantidade
## invalida. Feiticos entram na lista canonica em vez de fingirem uma pilha.
func add_item_to_state(state: Dictionary, item_key: String, count := 1) -> Dictionary:
	if state.is_empty() or count <= 0:
		return {"ok": false, "message": "Recolha invalida."}
	if not _catalog_has_item(item_key):
		return {"ok": false, "message": "Objecto desconhecido."}
	normalise_state(state)
	var entry := describe_item(item_key, count, state)
	if entry.is_empty():
		return {"ok": false, "message": "Objecto desconhecido."}
	var character: Dictionary = state.get("character", {}) as Dictionary
	if item_key.begins_with("magia:"):
		var progression: Dictionary = character.get("progression", {}) as Dictionary
		var known: Array = (progression.get("known_spells", []) as Array).duplicate()
		var spell_id := item_key.trim_prefix("magia:")
		if not known.has(spell_id):
			known.append(spell_id)
		progression["known_spells"] = known
		character["progression"] = progression
		state["character"] = character
		return {"ok": true, "key": item_key, "count": 1, "total": 1,
			"message": "%s aprendido." % String(entry.get("name", spell_id))}
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var items: Dictionary = inventory.get("items", {}) as Dictionary
	var total := int(items.get(item_key, 0)) + count
	items[item_key] = total
	inventory["items"] = items
	character["inventory"] = inventory
	state["character"] = character
	return {"ok": true, "key": item_key, "count": count, "total": total,
		"message": "%s x%d recolhido." % [String(entry.get("name", item_key)), count]}


## Acrescenta e grava uma recolha real. O chamador recebe falha se o save nao
## for publicado; nesse caso `_commit` devolve exactamente ao snapshot anterior.
func add_item(item_key: String, count := 1) -> Dictionary:
	var before := GameData.save_state_snapshot()
	var working := before.duplicate(true)
	var result := add_item_to_state(working, item_key, count)
	if not bool(result.get("ok", false)):
		return result
	var committed := _commit(before, working, String(result.get("message", "Objecto recolhido.")))
	for key: String in ["key", "count", "total"]:
		committed[key] = result.get(key)
	return committed


## Descreve as quatro leituras simultaneas da caixa. Equipamento e favoritos
## continuam a ser as autoridades; a UI nao mantem uma segunda mochila.
func quick_slot_snapshot(state := {}, runtime_player: Node = null) -> Array[Dictionary]:
	var working: Dictionary = state if not (state as Dictionary).is_empty() \
		else GameData.save_state_snapshot()
	normalise_state(working)
	var spell_id := ""
	if is_instance_valid(runtime_player):
		spell_id = String(runtime_player.get("selected_spell"))
	var keys: Dictionary = QuickSlotsModelScript.slot_keys(working, spell_id)
	var slots: Array[Dictionary] = []
	for slot_name: String in QUICK_SLOT_NAMES:
		slots.append(_quick_descriptor(slot_name, String(keys.get(slot_name, "")),
			working, runtime_player))
	return slots


func quick_slot_action(slot_name: String) -> String:
	var action := String(QUICK_SLOT_ACTIONS.get(slot_name, ""))
	var actions: Dictionary = GameData.controls.get("actions", {}) as Dictionary
	return action if action != "" and actions.has(action) else ""


## Favoritar na mochila e a operacao que torna uma recolha candidata a caixa.
## A mao respeita o slot declarado no catalogo; consumiveis entram na lista de
## atalhos persistida por spec/59.
func quick_slot_candidates(slot_name: String, state := {}) -> Array[String]:
	var working: Dictionary = state if not (state as Dictionary).is_empty() \
		else GameData.save_state_snapshot()
	normalise_state(working)
	var character: Dictionary = working.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	var items: Dictionary = inventory.get("items", {}) as Dictionary
	var favorites: Array = inventory.get("favorite_items", []) as Array
	var result: Array[String] = []
	match slot_name:
		"right_hand", "left_hand":
			var equipped_key := _weapon_key(equipment.get(
				"main" if slot_name == "right_hand" else "offhand"))
			_append_unique(result, equipped_key)
			for favorite_value: Variant in favorites:
				var favorite_key := String(favorite_value)
				if favorite_key.begins_with("arma:") \
						and _weapon_matches_hand(favorite_key, slot_name, equipped_key):
					_append_unique(result, favorite_key)
			if slot_name == "left_hand":
				_append_unique(result, FREE_HAND_KEY)
		"spell":
			for spell_value: Variant in equipment.get("spell_favorites", []):
				_append_unique(result, "magia:%s" % String(spell_value))
		"item":
			for quick_value: Variant in inventory.get("quick_slots", []):
				var quick_key := String(quick_value)
				if int(items.get(quick_key, 0)) > 0:
					_append_unique(result, quick_key)
			for favorite_value: Variant in favorites:
				var favorite_key := String(favorite_value)
				if favorite_key.begins_with("consumivel:") \
						and int(items.get(favorite_key, 0)) > 0:
					_append_unique(result, favorite_key)
	return result


## Variante pura para testes e transaccoes compostas. Muda o Dictionary dado,
## mas nunca escreve no disco nem toca no singleton global.
func cycle_quick_slot_in_state(state: Dictionary, slot_name: String,
		direction := 1) -> Dictionary:
	if slot_name not in QUICK_SLOT_NAMES or state.is_empty():
		return {"ok": false, "changed": false, "message": "Ranhura invalida."}
	normalise_state(state)
	var candidates := quick_slot_candidates(slot_name, state)
	if candidates.is_empty():
		return {"ok": false, "changed": false, "message": "Nao ha objectos nessa ranhura."}
	var current := _current_quick_key(slot_name, state)
	var current_index := candidates.find(current)
	var next_index := wrapi(current_index + direction, 0, candidates.size()) \
		if current_index >= 0 else 0
	var next_key := candidates[next_index]
	if next_key == current:
		return {"ok": true, "changed": false, "slot": slot_name, "key": next_key}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	match slot_name:
		"right_hand":
			equipment["main"] = null if next_key == FREE_HAND_KEY \
				else next_key.trim_prefix("arma:")
		"left_hand":
			equipment["offhand"] = null if next_key == FREE_HAND_KEY \
				else next_key.trim_prefix("arma:")
		"spell":
			var favorites: Array = (equipment.get("spell_favorites", []) as Array).duplicate()
			var next_spell := next_key.trim_prefix("magia:")
			favorites.erase(next_spell)
			favorites.push_front(next_spell)
			equipment["spell_favorites"] = favorites
		"item":
			var quick_slots: Array = (inventory.get("quick_slots", []) as Array).duplicate()
			quick_slots.erase(next_key)
			quick_slots.push_front(next_key)
			inventory["quick_slots"] = quick_slots
	inventory["equipment"] = equipment
	character["inventory"] = inventory
	state["character"] = character
	return {"ok": true, "changed": true, "slot": slot_name, "key": next_key}


func cycle_quick_slot(slot_name: String, direction := 1) -> Dictionary:
	var before := GameData.save_state_snapshot()
	var working := before.duplicate(true)
	var result := cycle_quick_slot_in_state(working, slot_name, direction)
	if not bool(result.get("ok", false)) or not bool(result.get("changed", false)):
		return result
	var committed := _commit(before, working, "Acesso rapido actualizado.")
	committed["slot"] = result.get("slot", slot_name)
	committed["key"] = result.get("key", "")
	committed["changed"] = bool(committed.get("ok", false))
	return committed


func is_equipped(item_key: String, state: Dictionary) -> bool:
	var equipment := _equipment(state)
	var parts := item_key.split(":", false, 1)
	if parts.size() != 2:
		return false
	match String(parts[0]):
		"arma": return String(equipment.get("main", "")) == parts[1] \
			or String(equipment.get("offhand", "")) == parts[1]
		"armadura": return (equipment.get("armor", []) as Array).has(parts[1])
		"anel": return (equipment.get("rings", []) as Array).has(parts[1])
		"magia": return (equipment.get("spell_favorites", []) as Array).has(parts[1])
	return false


func is_favorite(item_key: String, state: Dictionary) -> bool:
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	if item_key.begins_with("magia:"):
		return (_equipment(state).get("spell_favorites", []) as Array).has(item_key.trim_prefix("magia:"))
	return (inventory.get("favorite_items", []) as Array).has(item_key)


func equip(item_key: String) -> Dictionary:
	var before := GameData.save_state_snapshot()
	var working := before.duplicate(true)
	normalise_state(working)
	var entry := describe_item(item_key, 1, working)
	if entry.is_empty() or not String(entry.kind) in ["arma", "armadura", "anel"]:
		return {"ok": false, "message": "Este objecto não se equipa."}
	var equipment := _equipment(working)
	match String(entry.kind):
		"arma":
			if GameData.weapon(String(entry.id)).is_empty():
				return {"ok": false, "message": "A ficha existe, mas o moveset ainda não está ligado ao combate."}
			var weapon := GameData.weapon(String(entry.id))
			if String(weapon.get("slot", "main")) == "offhand" or weapon.has("familia_escudo"):
				equipment["offhand"] = entry.id
			else:
				equipment["main"] = entry.id
				if int(weapon.get("hands", 1)) >= 2:
					equipment["offhand"] = null
		"armadura":
			var armor: Array = (equipment.get("armor", []) as Array).duplicate()
			var slot := String((entry.data as Dictionary).get("slot", ""))
			for i: int in range(armor.size() - 1, -1, -1):
				if _armor_slot(String(armor[i])) == slot:
					armor.remove_at(i)
			armor.append(entry.id)
			equipment["armor"] = armor
		"anel":
			var rings: Array = (equipment.get("rings", []) as Array).duplicate()
			if not rings.has(entry.id):
				if rings.size() >= 2:
					rings.pop_front()
				rings.append(entry.id)
			equipment["rings"] = rings
	_set_equipment(working, equipment)
	return _commit(before, working, "%s equipado." % String(entry.name))


func unequip(item_key: String) -> Dictionary:
	var before := GameData.save_state_snapshot()
	var working := before.duplicate(true)
	var equipment := _equipment(working)
	var parts := item_key.split(":", false, 1)
	if parts.size() != 2:
		return {"ok": false, "message": "Objecto inválido."}
	var item_id := String(parts[1])
	match String(parts[0]):
		"arma":
			if String(equipment.get("main", "")) == item_id: equipment["main"] = null
			if String(equipment.get("offhand", "")) == item_id: equipment["offhand"] = null
		"armadura":
			var armor: Array = (equipment.get("armor", []) as Array).duplicate()
			armor.erase(item_id)
			equipment["armor"] = armor
		"anel":
			var rings: Array = (equipment.get("rings", []) as Array).duplicate()
			rings.erase(item_id)
			equipment["rings"] = rings
		_:
			return {"ok": false, "message": "Este objecto não se desequipa."}
	_set_equipment(working, equipment)
	return _commit(before, working, "Objecto desequipado.")


func toggle_favorite(item_key: String, can_change_spells := true) -> Dictionary:
	var before := GameData.save_state_snapshot()
	var working := before.duplicate(true)
	normalise_state(working)
	var character: Dictionary = working.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	if item_key.begins_with("magia:"):
		if not can_change_spells:
			return {"ok": false, "message": "Os 8 favoritos de magia só mudam fora de combate ou ao descansar."}
		var spell_id := item_key.trim_prefix("magia:")
		var equipment := inventory.get("equipment", {}) as Dictionary
		var favorites: Array = (equipment.get("spell_favorites", []) as Array).duplicate()
		if favorites.has(spell_id):
			favorites.erase(spell_id)
		elif favorites.size() >= MAX_SPELL_FAVORITES:
			return {"ok": false, "message": "A roda já tem 8 feitiços."}
		else:
			favorites.append(spell_id)
		equipment["spell_favorites"] = favorites
		inventory["equipment"] = equipment
	else:
		var favorites: Array = (inventory.get("favorite_items", []) as Array).duplicate()
		var quick_slots: Array = (inventory.get("quick_slots", []) as Array).duplicate()
		if favorites.has(item_key):
			favorites.erase(item_key)
			if item_key != FLASK_ITEM_KEY:
				quick_slots.erase(item_key)
		else:
			favorites.append(item_key)
			if item_key.begins_with("consumivel:") and not quick_slots.has(item_key):
				quick_slots.append(item_key)
		inventory["favorite_items"] = favorites
		inventory["quick_slots"] = quick_slots
	character["inventory"] = inventory
	working["character"] = character
	return _commit(before, working, "Favorito actualizado.")


func load_profile(state := {}) -> Dictionary:
	var working: Dictionary = state if not (state as Dictionary).is_empty() \
		else GameData.save_state_snapshot()
	var equipment := _equipment(working)
	var weight := 0.0
	for armor_value: Variant in equipment.get("armor", []):
		weight += float(_armor_data(String(armor_value)).get("peso", 0.0))
	for weapon_slot: String in ["main", "offhand"]:
		var weapon_id := String(equipment.get(weapon_slot, ""))
		var weapon := GameData.weapon(weapon_id)
		var runtime_weapons: Dictionary = (GameData.weapons.get(
			"_catalogo_runtime", {}) as Dictionary).get("weapons", {}) as Dictionary
		var runtime_weapon: Dictionary = runtime_weapons.get(weapon_id, {}) as Dictionary
		if not runtime_weapon.is_empty():
			weight += float(runtime_weapon.get("peso", 0.0))
		else:
			var shield_family := String(weapon.get("familia_escudo", ""))
			if shield_family == "":
				continue
			weight += float(((GameData.weapons.get("familias_escudo", {}) as Dictionary).get(
				shield_family, {}) as Dictionary).get("peso", 0.0))
	var character: Dictionary = working.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var attrs: Dictionary = progression.get("attributes", {}) as Dictionary
	var capacity := GameData.load_capacity_for(int(attrs.get("carga", 8)))
	var fraction := weight / maxf(capacity, 0.001)
	var load_class := "sobrecarregado"
	var rules: Dictionary = GameData.armor.get("carga", {}) as Dictionary
	for candidate: String in ["leve", "medio", "pesado"]:
		if fraction <= float((rules.get(candidate, {}) as Dictionary).get("max_fraccao", 1.0)):
			load_class = candidate
			break
	var rule: Dictionary = rules.get(load_class, {}) as Dictionary
	return {"weight": weight, "capacity": capacity, "fraction": fraction,
		"class": load_class, "recovery_frames": int(rule.get("recuperacao_esquiva_frames", 0)),
		"regen_multiplier": float(rule.get("regen_stamina_mult", 1.0)),
		"can_dodge": bool(rule.get("pode_esquivar", true)),
		"can_run": bool(rule.get("pode_correr", true)),
		"can_sprint": bool(rule.get("pode_sprintar", true)),
		"max_speed": float(rule.get("velocidade_maxima_m_s", 999.0))}


func _quick_descriptor(slot_name: String, item_key: String, state: Dictionary,
		runtime_player: Node) -> Dictionary:
	var entry := describe_item(item_key, 1, state)
	if item_key == FREE_HAND_KEY:
		entry = {"key": FREE_HAND_KEY, "id": "mao_livre", "kind": "estado",
			"name": "Mao livre", "count": 0, "data": {}}
	elif item_key == "estado:sem_feitico":
		entry = {"key": item_key, "id": "sem_feitico", "kind": "estado",
			"name": "Sem feitico", "count": 0, "data": {}}
	if entry.is_empty():
		entry = {"key": item_key, "id": item_key.get_slice(":", 1),
			"kind": item_key.get_slice(":", 0),
			"name": item_key.replace("_", " ").capitalize(), "count": 0, "data": {}}
	entry["slot"] = slot_name
	entry["cycle_action"] = quick_slot_action(slot_name)
	entry["show_count"] = false
	if item_key == FLASK_ITEM_KEY and is_instance_valid(runtime_player):
		entry["count"] = int(runtime_player.get("flask_uses"))
		entry["show_count"] = true
	elif String(entry.get("kind", "")) == "consumivel":
		entry["show_count"] = true
	elif String(entry.get("kind", "")) == "arma":
		var ammo_key := String((entry.get("data", {}) as Dictionary).get("ammo_item_key", ""))
		if ammo_key != "":
			var character: Dictionary = state.get("character", {}) as Dictionary
			var inventory: Dictionary = character.get("inventory", {}) as Dictionary
			entry["count"] = int((inventory.get("items", {}) as Dictionary).get(ammo_key, 0))
			entry["show_count"] = true
	return entry


func _weapon_key(value: Variant) -> String:
	return FREE_HAND_KEY if value == null or String(value) == "" \
		else "arma:%s" % String(value)


func _weapon_matches_hand(item_key: String, slot_name: String,
		current_key: String) -> bool:
	if item_key == current_key:
		return true
	var weapon := GameData.weapon(item_key.trim_prefix("arma:"))
	if weapon.is_empty():
		return false
	var declared_slot := String(weapon.get("slot", "main"))
	return declared_slot != "offhand" if slot_name == "right_hand" \
		else declared_slot == "offhand"


func _append_unique(values: Array[String], value: String) -> void:
	if value != "" and not values.has(value):
		values.append(value)


func _current_quick_key(slot_name: String, state: Dictionary) -> String:
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	match slot_name:
		"right_hand": return _weapon_key(equipment.get("main"))
		"left_hand": return _weapon_key(equipment.get("offhand"))
		"spell":
			var favorites: Array = equipment.get("spell_favorites", []) as Array
			return "magia:%s" % String(favorites[0]) if not favorites.is_empty() \
				else "estado:sem_feitico"
		"item":
			var quick_slots: Array = inventory.get("quick_slots", []) as Array
			return String(quick_slots[0]) if not quick_slots.is_empty() else FLASK_ITEM_KEY
	return ""


func _ensure_quick_slots_hud() -> void:
	if is_instance_valid(_quick_slots_hud) or not is_inside_tree():
		return
	_quick_slots_hud = QuickSlotsScript.new()
	_quick_slots_hud.name = "QuickSlots"
	add_child(_quick_slots_hud)
	_quick_slots_hud.call("setup", self)


func _equipment(state: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	return (inventory.get("equipment", {}) as Dictionary).duplicate(true)


func _set_equipment(state: Dictionary, equipment: Dictionary) -> void:
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	inventory["equipment"] = equipment
	character["inventory"] = inventory
	state["character"] = character


func _armor_data(item_id: String) -> Dictionary:
	var data := GameData.equipment_armor(item_id)
	if data.is_empty():
		data = (GameData.armor.get("pieces", {}) as Dictionary).get(item_id, {}) as Dictionary
	return data


func _armor_slot(item_id: String) -> String:
	return String(_armor_data(item_id).get("slot", ""))


func _catalog_has_item(item_key: String) -> bool:
	var parts := item_key.split(":", false, 1)
	if parts.size() != 2:
		return false
	var item_id := String(parts[1])
	match String(parts[0]):
		"arma":
			return not GameData.equipment_weapon(item_id).is_empty() \
				or not GameData.weapon(item_id).is_empty()
		"armadura":
			return not _armor_data(item_id).is_empty()
		"anel":
			return not GameData.ring(item_id).is_empty()
		"magia":
			return not GameData.spell(item_id).is_empty()
		"material":
			return not GameData.material(item_id).is_empty()
		"consumivel":
			return item_key == FLASK_ITEM_KEY \
				or not GameData.consumable(item_id).is_empty()
	return false


func _commit(before: Dictionary, working: Dictionary, message: String) -> Dictionary:
	GameData.replace_save_state(working)
	if not SaveSystem.save_current():
		GameData.replace_save_state(before)
		return {"ok": false, "message": "Não foi possível guardar a alteração."}
	inventory_changed.emit()
	return {"ok": true, "message": message, "load": load_profile(working)}
