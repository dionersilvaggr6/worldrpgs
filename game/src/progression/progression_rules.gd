extends RefCounted
## Transformacoes puras do ciclo de progressao. O chamador persiste o estado
## completo numa unica transaccao; este modulo nunca conhece caminhos de save.


static func award_enemy_souls(state: Dictionary, placement_id: String,
		enemy_id: String, event_id: String, base_souls: int, config: Dictionary) -> Dictionary:
	if state.is_empty() or placement_id.is_empty() or enemy_id.is_empty() \
			or event_id.is_empty() or base_souls < 0:
		return {"status": "invalid"}
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var receipts: Array = world_state.get("reward_receipts", []) as Array
	for receipt_value: Variant in receipts:
		var previous := receipt_value as Dictionary
		if String(previous.get("event_id", "")) == event_id:
			var repeated := previous.duplicate(true)
			repeated["status"] = "already_committed"
			return repeated

	var reward_counts: Dictionary = world_state.get("enemy_soul_rewards", {}) as Dictionary
	var rewarded_defeats := int(reward_counts.get(placement_id, 0))
	var reward_limit := int(config.get("rewarded_defeats_per_placement", 0))
	if reward_limit <= 0 or rewarded_defeats >= reward_limit:
		return {
			"status": "exhausted",
			"placement_id": placement_id,
			"enemy_id": enemy_id,
			"event_id": event_id,
		}

	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	progression["souls_held"] = int(progression.get("souls_held", 0)) + base_souls
	character["progression"] = progression
	state["character"] = character

	reward_counts[placement_id] = rewarded_defeats + 1
	world_state["enemy_soul_rewards"] = reward_counts
	var receipt := {
		"status": "awarded",
		"kind": "enemy_souls",
		"event_id": event_id,
		"placement_id": placement_id,
		"enemy_id": enemy_id,
		"souls_awarded": base_souls,
		"rewarded_defeat": rewarded_defeats + 1,
	}
	receipts.append(receipt.duplicate(true))
	world_state["reward_receipts"] = receipts
	state["world"] = world_state
	return receipt


static func record_death(state: Dictionary, zone_id: String, position: Vector3) -> Dictionary:
	if state.is_empty() or zone_id.is_empty():
		return {"status": "invalid"}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var death: Dictionary = character.get("death", {}) as Dictionary
	var previous_stain: Variant = death.get("soul_stain")
	var death_sequence := 1
	if typeof(previous_stain) == TYPE_DICTIONARY:
		death_sequence = int((previous_stain as Dictionary).get("death_sequence", 0)) + 1
	var profile_id := String(character.get("profile_id", "local"))
	var stain := {
		"stain_id": "%s:%d" % [profile_id, death_sequence],
		"amount": int(progression.get("souls_held", 0)),
		"zone_id": zone_id,
		"position": [position.x, position.y, position.z],
		"death_sequence": death_sequence,
	}
	death["soul_stain"] = stain
	progression["souls_held"] = 0
	character["progression"] = progression
	character["death"] = death
	state["character"] = character
	return {"status": "recorded", "soul_stain": stain.duplicate(true)}


static func recover_soul_stain(state: Dictionary, stain_id: String) -> Dictionary:
	if state.is_empty() or stain_id.is_empty():
		return {"status": "invalid"}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var death: Dictionary = character.get("death", {}) as Dictionary
	var stain_value: Variant = death.get("soul_stain")
	if typeof(stain_value) != TYPE_DICTIONARY:
		return {"status": "missing"}
	var stain := stain_value as Dictionary
	if String(stain.get("stain_id", "")) != stain_id:
		return {"status": "stale"}
	var amount := maxi(0, int(stain.get("amount", 0)))
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	progression["souls_held"] = int(progression.get("souls_held", 0)) + amount
	death["soul_stain"] = null
	character["progression"] = progression
	character["death"] = death
	state["character"] = character
	return {"status": "recovered", "stain_id": stain_id, "souls_recovered": amount}


static func rest(state: Dictionary, zone_id: String, rest_point_id: String,
		dead_placement_ids: Array, config: Dictionary) -> Dictionary:
	if state.is_empty() or zone_id.is_empty() or rest_point_id.is_empty():
		return {"status": "invalid", "respawned": [], "exhausted": []}
	var character: Dictionary = state.get("character", {}) as Dictionary
	character["checkpoint"] = {"zone_id": zone_id, "rest_point_id": rest_point_id}
	state["character"] = character
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var discovered: Array = world_state.get("rest_points_discovered", []) as Array
	if not rest_point_id in discovered:
		discovered.append(rest_point_id)
	world_state["rest_points_discovered"] = discovered

	var respawn_counts: Dictionary = world_state.get("enemy_respawns", {}) as Dictionary
	var respawn_limit := int(config.get("respawns_per_placement", 0))
	var respawned: Array[String] = []
	var exhausted: Array[String] = []
	var seen: Dictionary = {}
	for placement_value: Variant in dead_placement_ids:
		var placement_id := String(placement_value)
		if placement_id.is_empty() or not placement_id.begins_with("%s:" % zone_id) \
				or seen.has(placement_id):
			continue
		seen[placement_id] = true
		var used := int(respawn_counts.get(placement_id, 0))
		if respawn_limit > 0 and used < respawn_limit:
			respawn_counts[placement_id] = used + 1
			respawned.append(placement_id)
		else:
			exhausted.append(placement_id)
	world_state["enemy_respawns"] = respawn_counts
	state["world"] = world_state
	return {
		"status": "rested",
		"zone_id": zone_id,
		"rest_point_id": rest_point_id,
		"respawned": respawned,
		"exhausted": exhausted,
	}


static func purchase_level(state: Dictionary, attribute_id: String, cost: int,
		attribute_config: Dictionary) -> Dictionary:
	if state.is_empty() or cost < 0:
		return {"status": "invalid"}
	var attribute_ids: Array = attribute_config.get("attribute_ids", []) as Array
	if not attribute_id in attribute_ids:
		return {"status": "invalid_attribute", "attribute_id": attribute_id}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var current_level := int(progression.get("level", 0))
	var level_config: Dictionary = attribute_config.get("level", {}) as Dictionary
	var maximum_level := int(level_config.get("max_level", 0))
	if maximum_level <= 0 or current_level >= maximum_level:
		return {"status": "level_max"}
	var attributes: Dictionary = progression.get("attributes", {}) as Dictionary
	var current_attribute := int(attributes.get(attribute_id,
		attribute_config.get("base_value", 0)))
	var maximum_attribute := int(attribute_config.get("max_per_attribute", 0))
	if maximum_attribute <= 0 or current_attribute >= maximum_attribute:
		return {"status": "attribute_max", "attribute_id": attribute_id}
	var souls_held := int(progression.get("souls_held", 0))
	if souls_held < cost:
		return {"status": "insufficient_souls", "cost": cost, "souls_held": souls_held}
	var points := int(level_config.get("points_per_level", 0))
	if points <= 0:
		return {"status": "invalid"}
	progression["souls_held"] = souls_held - cost
	progression["level"] = current_level + 1
	attributes[attribute_id] = mini(maximum_attribute, current_attribute + points)
	progression["attributes"] = attributes
	character["progression"] = progression
	state["character"] = character
	return {
		"status": "purchased",
		"cost": cost,
		"level": current_level + 1,
		"attribute_id": attribute_id,
		"attribute_value": int(attributes[attribute_id]),
	}


static func kindle_ember(state: Dictionary, zone_id: String, zone_placement_ids: Array,
		zone_boss_ids: Array, config: Dictionary) -> Dictionary:
	if state.is_empty() or zone_id.is_empty():
		return {"status": "invalid"}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var embers_held := int(progression.get("embers_held", 0))
	if embers_held <= 0:
		return {"status": "missing_ember"}
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var zone_cycles: Dictionary = world_state.get("zone_cycles", {}) as Dictionary
	var minimum_cycle := int(config.get("minimum_zone_cycle", 0))
	var current_cycle := maxi(minimum_cycle,
		int(zone_cycles.get(zone_id, world_state.get("cycle", minimum_cycle))))
	var maximum_cycle := int(config.get("maximum_zone_cycle", 0))
	var cycle_raise := int(config.get("raises_exactly_one_zone_by_cycles", 0))
	if minimum_cycle <= 0 or current_cycle <= 0 or maximum_cycle <= 0 or cycle_raise <= 0:
		return {"status": "invalid"}
	if current_cycle >= maximum_cycle:
		return {"status": "cycle_max", "zone_id": zone_id, "zone_cycle": current_cycle}
	var use_key := "%s:%d" % [zone_id, current_cycle]
	var kindled: Array = world_state.get("embers_kindled", []) as Array
	var maximum_uses := int(config.get("max_per_zone_per_cycle", 0))
	if maximum_uses <= 0 or kindled.count(use_key) >= maximum_uses:
		return {"status": "already_kindled", "zone_id": zone_id, "zone_cycle": current_cycle}

	progression["embers_held"] = embers_held - 1
	character["progression"] = progression
	state["character"] = character
	zone_cycles[zone_id] = mini(maximum_cycle, current_cycle + cycle_raise)
	kindled.append(use_key)
	world_state["zone_cycles"] = zone_cycles
	world_state["embers_kindled"] = kindled

	var respawn_counts: Dictionary = world_state.get("enemy_respawns", {}) as Dictionary
	for placement_value: Variant in zone_placement_ids:
		var placement_id := String(placement_value)
		if placement_id.begins_with("%s:" % zone_id):
			respawn_counts.erase(placement_id)
	world_state["enemy_respawns"] = respawn_counts
	var bosses: Array = world_state.get("bosses_defeated", []) as Array
	for boss_value: Variant in zone_boss_ids:
		bosses.erase(String(boss_value))
	world_state["bosses_defeated"] = bosses
	state["world"] = world_state
	return {
		"status": "kindled",
		"zone_id": zone_id,
		"previous_zone_cycle": current_cycle,
		"zone_cycle": int(zone_cycles[zone_id]),
	}


static func collect_placed_ember(state: Dictionary, placed_reward_id: String) -> Dictionary:
	if state.is_empty() or placed_reward_id.is_empty():
		return {"status": "invalid"}
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	var collected: Array = progression.get("collected_placed_items", []) as Array
	if placed_reward_id in collected:
		return {"status": "already_collected", "placed_reward_id": placed_reward_id}
	collected.append(placed_reward_id)
	progression["collected_placed_items"] = collected
	progression["embers_held"] = int(progression.get("embers_held", 0)) + 1
	character["progression"] = progression
	state["character"] = character
	return {"status": "collected", "placed_reward_id": placed_reward_id}
