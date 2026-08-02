extends RefCounted
## Fachada executavel: combina as regras de progressao com os catalogos e com a
## fronteira atomica do SaveSystem, sem obrigar esses autoloads a conhecerem UI.

const ProgressionRules = preload("res://src/progression/progression_rules.gd")


static func apply_enemy_defeat_to_state(state: Dictionary, placement_id: String,
		enemy_id: String, event_id: String, seed_value: int, receiver_class_id: String,
		config: Dictionary) -> Dictionary:
	var previous := _receipt_for(state, event_id)
	if not previous.is_empty():
		previous["status"] = "already_committed"
		previous["souls_awarded"] = int(previous.get(
			"operation_souls_awarded", previous.get("souls_awarded", 0)))
		return previous
	var game_data := _autoload("GameData")
	if game_data == null:
		return {"status": "missing_game_data"}
	var enemy_data: Dictionary = game_data.call("enemy", enemy_id) as Dictionary
	var base_souls := int(enemy_data.get("souls", 0))
	if base_souls < 0:
		return {"status": "invalid"}

	# O baralho continua por tipo e conserva a garantia visual. Usa um recibo
	# subordinado para a recompensa-base por colocacao nao bloquear a carta.
	var loot_event_id := "%s:loot" % event_id
	var loot_result: Dictionary = game_data.call("reward_enemy_defeat", state,
		enemy_id, loot_event_id, seed_value, receiver_class_id) as Dictionary
	var loot_status := String(loot_result.get("status", ""))
	var loot_souls := int(loot_result.get("souls_awarded", 0))
	var loot_bonus := 0
	if loot_status == "awarded":
		# reward_enemy_defeat ainda soma base+bonus. Retira apenas a base; a regra
		# por colocacao volta a soma-la abaixo se este corpo ainda tiver orcamento.
		loot_bonus = maxi(0, loot_souls - base_souls)
		var character: Dictionary = state.get("character", {}) as Dictionary
		var progression: Dictionary = character.get("progression", {}) as Dictionary
		progression["souls_held"] = maxi(0,
			int(progression.get("souls_held", 0)) - base_souls)
		character["progression"] = progression
		state["character"] = character
		_update_receipt(state, loot_event_id, {
			"souls_awarded": loot_bonus,
			"base_souls_moved_to_placement_budget": base_souls,
		})

	var soul_result := ProgressionRules.award_enemy_souls(
		state, placement_id, enemy_id, event_id, base_souls, config)
	var base_awarded := int(soul_result.get("souls_awarded", 0))
	var status := "awarded" if loot_status == "awarded" or base_awarded > 0 else "exhausted"
	if status == "awarded":
		_upsert_public_defeat_receipt(state, event_id, {
			"kind": "enemy_defeat",
			"placement_id": placement_id,
			"enemy_id": enemy_id,
			"souls_awarded": base_awarded,
			"operation_souls_awarded": base_awarded + loot_bonus,
			"base_souls_awarded": base_awarded,
			"loot_bonus_souls_awarded": loot_bonus,
			"loot_status": loot_status,
			"resolved_card": String(loot_result.get("resolved_card", "")),
		})
	return {
		"status": status,
		"event_id": event_id,
		"placement_id": placement_id,
		"enemy_id": enemy_id,
		"base_souls_awarded": base_awarded,
		"loot_bonus_souls_awarded": loot_bonus,
		"souls_awarded": base_awarded + loot_bonus,
		"loot_status": loot_status,
		"resolved_card": String(loot_result.get("resolved_card", "")),
	}


static func apply_level_up_to_state(state: Dictionary, attribute_id: String) -> Dictionary:
	var game_data := _autoload("GameData")
	if game_data == null:
		return {"status": "missing_game_data"}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var level_to_buy := int(progression.get("level", 0)) + 1
	var cost := int(game_data.call("level_cost", level_to_buy))
	var attribute_config: Dictionary = game_data.get("attributes") as Dictionary
	return ProgressionRules.purchase_level(
		state, attribute_id, cost, attribute_config)


static func commit_enemy_defeat(placement_id: String, enemy_id: String,
		event_id: String, seed_value: int, receiver_class_id: String,
		slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var working: Dictionary = transaction.get("working", {}) as Dictionary
	var result := apply_enemy_defeat_to_state(working, placement_id, enemy_id,
		event_id, seed_value, receiver_class_id, _progression_config("enemy_lifecycle"))
	if String(result.get("status", "")) != "awarded":
		return result
	return _commit_transaction(transaction, result, slot)


static func commit_death(zone_id: String, position: Vector3, slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var result := ProgressionRules.record_death(
		transaction.get("working", {}) as Dictionary, zone_id, position)
	if String(result.get("status", "")) != "recorded":
		return result
	return _commit_transaction(transaction, result, slot)


static func commit_soul_stain_recovery(stain_id: String, slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var result := ProgressionRules.recover_soul_stain(
		transaction.get("working", {}) as Dictionary, stain_id)
	if String(result.get("status", "")) != "recovered":
		return result
	return _commit_transaction(transaction, result, slot)


static func commit_rest(zone_id: String, rest_point_id: String,
		dead_placement_ids: Array, slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var result := ProgressionRules.rest(transaction.get("working", {}) as Dictionary,
		zone_id, rest_point_id, dead_placement_ids, _progression_config("enemy_lifecycle"))
	if String(result.get("status", "")) != "rested":
		return result
	return _commit_transaction(transaction, result, slot)


static func commit_level_up(attribute_id: String, slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var result := apply_level_up_to_state(
		transaction.get("working", {}) as Dictionary, attribute_id)
	if String(result.get("status", "")) != "purchased":
		return result
	return _commit_transaction(transaction, result, slot)


static func commit_ember(zone_id: String, zone_placement_ids: Array,
		zone_boss_ids: Array, slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var config := _progression_config("ember")
	var cycles := _progression_config("cycles")
	config["minimum_zone_cycle"] = int(cycles.get("min", 0))
	config["maximum_zone_cycle"] = int(cycles.get("max", 0))
	var result := ProgressionRules.kindle_ember(
		transaction.get("working", {}) as Dictionary, zone_id,
		zone_placement_ids, zone_boss_ids, config)
	if String(result.get("status", "")) != "kindled":
		return result
	return _commit_transaction(transaction, result, slot)


static func commit_placed_ember(placed_reward_id: String, slot: int = -1) -> Dictionary:
	var transaction := _begin_transaction()
	if transaction.is_empty():
		return {"status": "no_active_save"}
	var result := ProgressionRules.collect_placed_ember(
		transaction.get("working", {}) as Dictionary, placed_reward_id)
	if String(result.get("status", "")) != "collected":
		return result
	return _commit_transaction(transaction, result, slot)


static func active_soul_stain() -> Dictionary:
	var game_data := _autoload("GameData")
	if game_data == null:
		return {}
	var state: Dictionary = game_data.call("save_state_snapshot") as Dictionary
	var character: Dictionary = state.get("character", {}) as Dictionary
	var stain: Variant = (character.get("death", {}) as Dictionary).get("soul_stain")
	return (stain as Dictionary).duplicate(true) if typeof(stain) == TYPE_DICTIONARY else {}


static func _receipt_for(state: Dictionary, event_id: String) -> Dictionary:
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	for receipt_value: Variant in world_state.get("reward_receipts", []):
		var receipt := receipt_value as Dictionary
		if String(receipt.get("event_id", "")) == event_id:
			return receipt.duplicate(true)
	return {}


static func _update_receipt(state: Dictionary, event_id: String, patch: Dictionary) -> void:
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var receipts: Array = world_state.get("reward_receipts", []) as Array
	for index: int in receipts.size():
		var receipt := receipts[index] as Dictionary
		if String(receipt.get("event_id", "")) != event_id:
			continue
		for key: Variant in patch:
			receipt[key] = patch[key]
		receipts[index] = receipt
		world_state["reward_receipts"] = receipts
		state["world"] = world_state
		return


static func _upsert_public_defeat_receipt(state: Dictionary, event_id: String,
		patch: Dictionary) -> void:
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var receipts: Array = world_state.get("reward_receipts", []) as Array
	for index: int in receipts.size():
		var receipt := receipts[index] as Dictionary
		if String(receipt.get("event_id", "")) != event_id:
			continue
		for key: Variant in patch:
			receipt[key] = patch[key]
		receipts[index] = receipt
		world_state["reward_receipts"] = receipts
		state["world"] = world_state
		return
	var receipt := {"status": "awarded", "event_id": event_id}
	for key: Variant in patch:
		receipt[key] = patch[key]
	receipts.append(receipt)
	world_state["reward_receipts"] = receipts
	state["world"] = world_state


static func _begin_transaction() -> Dictionary:
	var game_data := _autoload("GameData")
	if game_data == null:
		return {}
	var before: Dictionary = game_data.call("save_state_snapshot") as Dictionary
	if before.is_empty():
		return {}
	return {"before": before, "working": before.duplicate(true)}


static func _commit_transaction(transaction: Dictionary, result: Dictionary,
		slot: int) -> Dictionary:
	var game_data := _autoload("GameData")
	var save_system := _autoload("SaveSystem")
	if game_data == null or save_system == null:
		return {"status": "missing_save_boundary"}
	var before: Dictionary = transaction.get("before", {}) as Dictionary
	var working: Dictionary = transaction.get("working", {}) as Dictionary
	game_data.call("replace_save_state", working)
	if bool(save_system.call("save_current", slot)):
		return result
	game_data.call("replace_save_state", before)
	return {
		"status": "save_failed",
		"operation_status": String(result.get("status", "")),
		"message": String(save_system.get("last_error")),
	}


static func _progression_config(section_name: String) -> Dictionary:
	var game_data := _autoload("GameData")
	if game_data == null:
		return {}
	var progression_data: Dictionary = game_data.get("progression") as Dictionary
	return (progression_data.get(section_name, {}) as Dictionary).duplicate(true)


static func _autoload(name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(name)
