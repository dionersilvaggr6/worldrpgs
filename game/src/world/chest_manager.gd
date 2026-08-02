class_name WorldChestManager
extends Node
## Monta os baus de uma zona, escolhe apenas o mais proximo para a accao
## contextual e publica recompensa + estado aberto na mesma gravacao.

const LootPolicyScript = preload("res://src/loot/loot_policy.gd")
const ChestRewardServiceScript = preload("res://src/loot/chest_reward_service.gd")
const WorldChestScript = preload("res://src/world/chest.gd")
const LootFeedbackScript = preload("res://src/loot/loot_feedback.gd")

var _world: Node3D
var _player: Node3D
var _hud: Node
var _economy: Dictionary = {}
var _policy: RefCounted
var _service: RefCounted
var _chests: Dictionary = {}
var _test_state: Dictionary = {}
var _uses_injected_state := false
var _owns_prompt := false


## dependencies serve apenas testes/sondas. No jogo, a chamada curta usa os
## catalogos e o save correntes dos autoloads.
func setup(world_root: Node3D, player_node: Node3D, hud_node: Node,
		zone_id: String, dependencies := {}) -> bool:
	_world = world_root
	_player = player_node
	_hud = hud_node
	var game_data := _autoload("GameData")
	var default_economy := game_data.get("economy") as Dictionary \
		if game_data != null else {}
	var default_enemies := game_data.get("enemies") as Dictionary \
		if game_data != null else {}
	var default_equipment := game_data.get("equipment") as Dictionary \
		if game_data != null else {}
	_economy = dependencies.get("economy", default_economy) as Dictionary
	var enemies: Dictionary = dependencies.get("enemies", default_enemies) as Dictionary
	var equipment: Dictionary = dependencies.get("equipment", default_equipment) as Dictionary
	_uses_injected_state = dependencies.has("state")
	if _uses_injected_state:
		_test_state = dependencies.get("state", {}) as Dictionary
	_policy = LootPolicyScript.new()
	if not bool(_policy.call("configure", enemies, _economy, equipment)):
		return false
	_service = ChestRewardServiceScript.new()
	if not bool(_service.call("configure", _economy, _policy)):
		return false
	_spawn_zone_chests(zone_id)
	set_process(true)
	return true


func chest_count() -> int:
	return _chests.size()


func set_player(player_node: Node3D) -> void:
	_player = player_node


func open_chest(chest_id: String) -> Dictionary:
	var chest: Node3D = _chests.get(chest_id) as Node3D
	if chest == null:
		return {"status": "invalid", "chest_id": chest_id}
	var before := _state_snapshot()
	var working := before.duplicate(true)
	var result: Dictionary = _service.call("open_chest", working, chest_id) as Dictionary
	if String(result.get("status", "")) != "opened":
		return result
	if not _publish_state(before, working):
		return {"status": "save_failed", "chest_id": chest_id}
	chest.call("open_visual")
	var inventory_system := _autoload("InventorySystem")
	if inventory_system != null:
		inventory_system.emit_signal("inventory_changed")
	var messages := PackedStringArray()
	var reward_index := 0
	for reward_value: Variant in result.get("rewards", []) as Array:
		var reward: Dictionary = reward_value as Dictionary
		var item_key := String(reward.get("item", ""))
		var interest: Dictionary = _policy.call(
			"describe_interest", item_key, before) as Dictionary
		if interest.is_empty():
			continue
		messages.append("%s x%d — %s" % [String(interest.get("name", item_key)),
			int(reward.get("count", 0)), String(interest.get("reason", ""))])
		_spawn_feedback(interest, chest.global_position + Vector3.UP * (1.0
			+ float(reward_index) * float((_economy.get("loot_presentation", {}) as Dictionary).get(
				"feedback_spacing_m", 0.38))))
		reward_index += 1
	if is_instance_valid(_hud) and not messages.is_empty():
		_hud.call("toast", "\n".join(messages), 4.5)
	return result


## A morte comum ja publica a transaccao atomica. O dono desse fluxo passa o
## snapshot anterior e o local da queda para esta chamada apresentar a razao
## sem recalcular equipamento depois do facto.
func present_enemy_reward(receipt: Dictionary, at: Vector3,
		state_before: Dictionary) -> Dictionary:
	var item_key := String(receipt.get("resolved_card", ""))
	if item_key == "" or item_key.begins_with("almas_bonus:"):
		return {"status": "no_item"}
	var interest: Dictionary = _policy.call(
		"describe_interest", item_key, state_before) as Dictionary
	if interest.is_empty():
		return {"status": "unknown_item", "item": item_key}
	_spawn_feedback(interest, at + Vector3.UP)
	if is_instance_valid(_hud):
		_hud.call("toast", "%s — %s" % [String(interest.get("name", item_key)),
			String(interest.get("reason", ""))], 3.5)
	return {"status": "presented", "interest": interest}


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_clear_owned_prompt()
		return
	var nearest_id := ""
	var nearest_distance := INF
	for chest_id: String in _chests:
		var chest: Node3D = _chests.get(chest_id) as Node3D
		if chest == null or bool(chest.call("is_opened")):
			continue
		var distance := _player.global_position.distance_to(chest.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_id = chest_id
	var presentation: Dictionary = _economy.get("loot_presentation", {}) as Dictionary
	if nearest_id == "" or nearest_distance > float(presentation.get(
			"interaction_radius_m", 2.6)):
		_clear_owned_prompt()
		return
	var definition: Dictionary = (_economy.get("chests", {}) as Dictionary).get(
		nearest_id, {}) as Dictionary
	if is_instance_valid(_hud):
		_hud.call("set_prompt", "%s — abrir %s" % [
			_binding_label(String(presentation.get("interaction_action", "interact"))),
			String(definition.get("display_name", "bau"))])
		_owns_prompt = true
	var action := String(presentation.get("interaction_action", "interact"))
	if Input.is_action_just_pressed(action):
		open_chest(nearest_id)


func _spawn_zone_chests(zone_id: String) -> void:
	var state := _state_snapshot()
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var state_key := String((_economy.get("chest_rules", {}) as Dictionary).get(
		"opened_state_key", "opened_chests"))
	var opened: Array = world_state.get(state_key, []) as Array
	var presentation: Dictionary = _economy.get("loot_presentation", {}) as Dictionary
	for chest_id: String in (_economy.get("chests", {}) as Dictionary):
		var definition: Dictionary = (_economy.get("chests", {}) as Dictionary).get(
			chest_id, {}) as Dictionary
		if String(definition.get("biome_id", "")) != zone_id \
				or not bool(definition.get("fatia_1", false)):
			continue
		var chest = WorldChestScript.new()
		_world.add_child(chest)
		chest.call("configure", chest_id, definition, presentation)
		chest.call("set_opened", opened.has(chest_id), true)
		_chests[chest_id] = chest


func _spawn_feedback(interest: Dictionary, at: Vector3) -> void:
	var feedback = LootFeedbackScript.new()
	_world.add_child(feedback)
	feedback.global_position = at
	feedback.call("configure", interest,
		_economy.get("loot_presentation", {}) as Dictionary)


func _state_snapshot() -> Dictionary:
	if _uses_injected_state:
		return _test_state.duplicate(true)
	var game_data := _autoload("GameData")
	return game_data.call("save_state_snapshot") as Dictionary \
		if game_data != null else {}


func _publish_state(before: Dictionary, working: Dictionary) -> bool:
	if _uses_injected_state:
		_test_state.clear()
		_test_state.merge(working, true)
		return true
	var game_data := _autoload("GameData")
	var save_system := _autoload("SaveSystem")
	if game_data == null or save_system == null:
		return false
	game_data.call("replace_save_state", working)
	if bool(save_system.call("save_current")):
		return true
	game_data.call("replace_save_state", before)
	return false


func _binding_label(action: String) -> String:
	if _uses_injected_state:
		return "E/X"
	var settings_system := _autoload("SettingsSystem")
	return String(settings_system.call("binding_label", action)) \
		if settings_system != null else action


func _clear_owned_prompt() -> void:
	if _owns_prompt and is_instance_valid(_hud):
		_hud.call("set_prompt", "")
	_owns_prompt = false


func _autoload(autoload_name: String) -> Node:
	return get_tree().root.get_node_or_null(autoload_name)
