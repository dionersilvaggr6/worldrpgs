class_name WorldPickupManager
extends Node
## Liga recibos de espolio a objectos legiveis no mundo. A morte comum ja
## publica o item atomicamente; por isso esse objecto apenas apresenta e
## confirma o recibo. Recolhas ainda nao comprometidas usam InventorySystem.

const LootPolicyScript = preload("res://src/loot/loot_policy.gd")
const LootFeedbackScript = preload("res://src/loot/loot_feedback.gd")
const GroundItemScript = preload("res://src/world/secrets_ground_item.gd")
const ChestManagerScript = preload("res://src/world/chest_manager.gd")

var _world: Node3D
var _player: Node3D
var _hud: Node
var _economy: Dictionary = {}
var _policy: RefCounted
var _inventory_system: Node
var _pickups: Dictionary = {}
var _chest_manager: Node
var _owns_prompt := false


## dependencies existe para provas sem save. No jogo, a chamada curta usa os
## catalogos/autoloads correntes e monta tambem os baus desenhados da zona.
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
	_inventory_system = dependencies.get("inventory_system", _autoload("InventorySystem")) as Node
	_policy = LootPolicyScript.new()
	if not is_instance_valid(_world) or not is_instance_valid(_player) \
			or not bool(_policy.call("configure", enemies, _economy, equipment)):
		return false
	if bool(dependencies.get("mount_chests", true)):
		_chest_manager = ChestManagerScript.new()
		add_child(_chest_manager)
		if not bool(_chest_manager.call("setup", _world, _player, _hud,
				zone_id, dependencies)):
			_chest_manager.queue_free()
			_chest_manager = null
			return false
	set_process(true)
	return true


## Converte a carta ja gravada pela morte num objecto de chao. Nunca volta a
## somar a carta ao inventario, evitando duplicacao se o jogador carregar duas
## vezes ou se a apresentacao for repetida pela rede.
func present_enemy_reward(receipt: Dictionary, at: Vector3,
		state_before: Dictionary) -> Dictionary:
	var item_key := String(receipt.get("resolved_card", ""))
	if item_key == "" or item_key.begins_with("almas_bonus:"):
		return {"status": "no_item"}
	var interest: Dictionary = _policy.call(
		"describe_interest", item_key, state_before) as Dictionary
	if interest.is_empty():
		return {"status": "unknown_item", "item": item_key}
	return spawn_pickup(item_key, 1, at, {
		"already_committed": true,
		"receipt_id": String(receipt.get("event_id", "")),
		"interest": interest,
	})


## Fronteira para achados colocados ou futuras transaccoes pendentes. Ao
## contrario dos recibos de inimigo, estes so entram na mochila apos interact.
func spawn_pickup(item_key: String, count: int, at: Vector3,
		options := {}) -> Dictionary:
	if not is_instance_valid(_world) or item_key == "" or count <= 0:
		return {"status": "invalid", "item": item_key}
	var interest: Dictionary = options.get("interest", {}) as Dictionary
	if interest.is_empty():
		var state_before := _current_state()
		interest = _policy.call("describe_interest", item_key, state_before) as Dictionary
	if interest.is_empty():
		return {"status": "unknown_item", "item": item_key}
	var rules: Dictionary = _economy.get("loot_presentation", {}) as Dictionary
	var pickup = GroundItemScript.new()
	_world.add_child(pickup)
	pickup.global_position = at
	var configured: bool = pickup.call("configure", item_key, {
		"receipt_id": String(options.get("receipt_id", "")),
		"display_name": String(interest.get("name", item_key)),
		"interaction_action": String(rules.get("interaction_action", "interact")),
		"interaction_radius_m": float(rules.get("interaction_radius_m", 2.6)),
		"colour": String(rules.get("pickup_colour", "#e6cf79")),
		"already_committed": bool(options.get("already_committed", false)),
	})
	if not configured:
		pickup.queue_free()
		return {"status": "invalid", "item": item_key}
	pickup.connect("claim_requested", _on_claim_requested.bind(pickup))
	pickup.connect("presentation_finished", _on_presentation_finished.bind(pickup))
	_pickups[pickup.get_instance_id()] = {
		"node": pickup,
		"count": count,
		"interest": interest.duplicate(true),
		"already_committed": bool(options.get("already_committed", false)),
	}
	return {"status": "spawned", "item": item_key, "pickup": pickup}


func pickup_count() -> int:
	_prune_pickups()
	return _pickups.size()


func active_pickups() -> Array:
	_prune_pickups()
	var result: Array = []
	for record_value: Variant in _pickups.values():
		var pickup: Node = (record_value as Dictionary).get("node") as Node
		if is_instance_valid(pickup):
			result.append(pickup)
	return result


func chest_count() -> int:
	return int(_chest_manager.call("chest_count")) \
		if is_instance_valid(_chest_manager) else 0


func set_player(player_node: Node3D) -> void:
	_player = player_node
	if is_instance_valid(_chest_manager):
		_chest_manager.call("set_player", player_node)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_clear_owned_prompt()
		return
	var nearest: Node
	var nearest_prompt: Dictionary = {}
	var nearest_distance := INF
	for pickup_value: Variant in active_pickups():
		var pickup := pickup_value as Node3D
		var prompt: Dictionary = pickup.call(
			"prompt_state", _player.global_position) as Dictionary
		if prompt.is_empty():
			continue
		var distance := _player.global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest = pickup
			nearest_prompt = prompt
			nearest_distance = distance
	if nearest == null:
		_clear_owned_prompt()
		return
	var action := String(nearest_prompt.get("action", ""))
	if is_instance_valid(_hud):
		var prefix := _binding_label(action) if action != "" else "..."
		_hud.call("set_prompt", "%s - %s" % [prefix,
			String(nearest_prompt.get("message", "recolher"))])
		_owns_prompt = true
	if action != "" and Input.is_action_just_pressed(action):
		nearest.call("try_interact", _player.global_position, true)


func _on_claim_requested(item_key: String, _receipt_id: String,
		pickup: Node) -> void:
	var record: Dictionary = _pickups.get(pickup.get_instance_id(), {}) as Dictionary
	if record.is_empty() or not is_instance_valid(_inventory_system) \
			or not _inventory_system.has_method("add_item"):
		pickup.call("resolve_claim", false)
		_show_failure("Nao foi possivel guardar esta recolha.")
		return
	var result: Dictionary = _inventory_system.call(
		"add_item", item_key, int(record.get("count", 1))) as Dictionary
	pickup.call("resolve_claim", bool(result.get("ok", false)))
	if not bool(result.get("ok", false)):
		_show_failure(String(result.get("message", "Nao foi possivel guardar esta recolha.")))


func _on_presentation_finished(_item_key: String, _receipt_id: String,
		pickup: Node) -> void:
	var instance_id := pickup.get_instance_id()
	var record: Dictionary = _pickups.get(instance_id, {}) as Dictionary
	if record.is_empty():
		return
	_pickups.erase(instance_id)
	var interest: Dictionary = record.get("interest", {}) as Dictionary
	_spawn_feedback(interest, (pickup as Node3D).global_position + Vector3.UP)
	if is_instance_valid(_hud):
		_hud.call("toast", "%s - %s" % [
			String(interest.get("name", "Objecto")),
			String(interest.get("reason", "Nova opcao."))], 3.5)
	pickup.queue_free()
	_clear_owned_prompt()


func _spawn_feedback(interest: Dictionary, at: Vector3) -> void:
	var feedback = LootFeedbackScript.new()
	_world.add_child(feedback)
	feedback.global_position = at
	feedback.call("configure", interest,
		_economy.get("loot_presentation", {}) as Dictionary)


func _current_state() -> Dictionary:
	var game_data := _autoload("GameData")
	return game_data.call("save_state_snapshot") as Dictionary \
		if game_data != null else {}


func _binding_label(action: String) -> String:
	var settings_system := _autoload("SettingsSystem")
	return String(settings_system.call("binding_label", action)) \
		if settings_system != null else action


func _show_failure(message: String) -> void:
	if is_instance_valid(_hud):
		_hud.call("toast", message, 3.0)


func _clear_owned_prompt() -> void:
	if _owns_prompt and is_instance_valid(_hud):
		_hud.call("set_prompt", "")
	_owns_prompt = false


func _prune_pickups() -> void:
	for instance_id: Variant in _pickups.keys():
		var pickup: Node = (_pickups.get(instance_id, {}) as Dictionary).get("node") as Node
		if not is_instance_valid(pickup):
			_pickups.erase(instance_id)


func _autoload(autoload_name: String) -> Node:
	return get_tree().root.get_node_or_null(autoload_name)


func _exit_tree() -> void:
	_clear_owned_prompt()
