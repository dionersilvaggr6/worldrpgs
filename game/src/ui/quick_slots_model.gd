class_name QuickSlotsModel
extends RefCounted
## Nucleo determinista da caixa. Recebe catalogos em vez de procurar autoloads,
## para que saves, UI e testes usem exactamente a mesma regra.

const SLOT_NAMES := ["right_hand", "left_hand", "spell", "item"]
const FLASK_ITEM_KEY := "consumivel:frasco_bruma"
const FREE_HAND_KEY := "estado:mao_livre"
const NO_SPELL_KEY := "estado:sem_feitico"


static func normalise_state(state: Dictionary, weapons: Dictionary,
		default_spells: Array) -> bool:
	if state.is_empty():
		return false
	var changed := false
	var character: Dictionary = state.get("character", {}) as Dictionary
	var identity: Dictionary = character.get("identity", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	var items: Dictionary = inventory.get("items", {}) as Dictionary
	var inventory_was_empty := items.is_empty()
	var favorites: Array = inventory.get("favorite_items", []) as Array
	var loadout: Dictionary = ((weapons.get("loadouts", {}) as Dictionary).get(
		String(identity.get("class_id", "")), {}) as Dictionary)

	if not equipment.has("main") or (inventory_was_empty \
			and (equipment.get("main") == null or String(equipment.get("main")) == "")):
		equipment["main"] = loadout.get("main", null)
		changed = true
	if not equipment.has("offhand") or (inventory_was_empty \
			and (equipment.get("offhand") == null or String(equipment.get("offhand")) == "")):
		equipment["offhand"] = loadout.get("offhand", null)
		changed = true
	if not equipment.has("armor") or (inventory_was_empty \
			and (equipment.get("armor", []) as Array).is_empty()):
		equipment["armor"] = (loadout.get("pecas", []) as Array).duplicate()
		changed = true
	var spell_favorites: Array = equipment.get("spell_favorites", []) as Array
	if spell_favorites.is_empty():
		equipment["spell_favorites"] = default_spells.duplicate()
		changed = true

	for slot_name: String in ["main", "offhand"]:
		var equipped_value: Variant = equipment.get(slot_name)
		if equipped_value != null and String(equipped_value) != "":
			changed = _claim(items, "arma:%s" % String(equipped_value)) or changed
		var loadout_value: Variant = loadout.get(slot_name)
		if loadout_value != null and String(loadout_value) != "":
			changed = _claim(items, "arma:%s" % String(loadout_value)) or changed
	for armor_value: Variant in equipment.get("armor", []):
		changed = _claim(items, "armadura:%s" % String(armor_value)) or changed
	for armor_value: Variant in loadout.get("pecas", []):
		changed = _claim(items, "armadura:%s" % String(armor_value)) or changed
	for ring_value: Variant in equipment.get("rings", []):
		changed = _claim(items, "anel:%s" % String(ring_value)) or changed
	changed = _claim(items, FLASK_ITEM_KEY) or changed

	if not inventory.has("favorite_items"):
		changed = true
	if not favorites.has(FLASK_ITEM_KEY):
		favorites.append(FLASK_ITEM_KEY)
		changed = true
	var quick_slots: Array = []
	var stored_quick_slots: Variant = inventory.get("quick_slots", [])
	if typeof(stored_quick_slots) == TYPE_ARRAY:
		var seen_quick_keys: Dictionary = {}
		for quick_value: Variant in (stored_quick_slots as Array):
			var quick_key := String(quick_value)
			# Saves do primeiro editor guardavam apenas o id. A autoridade da
			# mochila e do runtime e a chave completa `tipo:id`.
			if quick_key != "" and not quick_key.contains(":"):
				quick_key = "consumivel:%s" % quick_key
			if not quick_key.begins_with("consumivel:") \
					or seen_quick_keys.has(quick_key):
				quick_key = ""
			if quick_key != "":
				seen_quick_keys[quick_key] = true
			quick_slots.append(quick_key)
	# Uma lista vazia e um save ainda nao configurado. Depois de o jogador
	# editar, o ecran guarda todas as posicoes (inclusive vazias), portanto
	# limpar um atalho nao faz o frasco reaparecer por surpresa.
	if quick_slots.is_empty():
		quick_slots.append(FLASK_ITEM_KEY)
		changed = true
	if typeof(stored_quick_slots) != TYPE_ARRAY \
			or quick_slots != (stored_quick_slots as Array):
		changed = true

	inventory["items"] = items
	inventory["favorite_items"] = favorites
	inventory["equipment"] = equipment
	inventory["quick_slots"] = quick_slots
	character["inventory"] = inventory
	state["character"] = character
	return changed


static func slot_keys(state: Dictionary, selected_spell := "") -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	var quick_slots: Array = inventory.get("quick_slots", []) as Array
	var spell_id := selected_spell
	if spell_id == "":
		var spell_favorites: Array = equipment.get("spell_favorites", []) as Array
		spell_id = String(spell_favorites[0]) if not spell_favorites.is_empty() else ""
	return {
		"right_hand": _weapon_key(equipment.get("main")),
		"left_hand": _weapon_key(equipment.get("offhand")),
		"spell": "magia:%s" % spell_id if spell_id != "" else NO_SPELL_KEY,
		"item": String(quick_slots[0]) if not quick_slots.is_empty() else "",
	}


static func _weapon_key(value: Variant) -> String:
	return FREE_HAND_KEY if value == null or String(value) == "" \
		else "arma:%s" % String(value)


static func _claim(items: Dictionary, key: String) -> bool:
	if int(items.get(key, 0)) > 0:
		return false
	items[key] = 1
	return true
