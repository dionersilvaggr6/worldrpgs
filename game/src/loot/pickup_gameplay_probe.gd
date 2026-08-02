extends Node
## Prova o fio de producao, nao uma classe isolada:
## gameplay.tscn -> Player ataca -> inimigo morre -> objecto no chao -> Player
## anda -> interact -> inventario/feedback -> bau fixo abre.
##
## Corre com:
## godot --headless --audio-driver Dummy --path game/ src/loot/pickup_gameplay_probe.tscn

const GAMEPLAY := preload("res://scenes/gameplay.tscn")
const PICKUP_MANAGER := preload("res://src/world/pickup_manager.gd")

var _save_system: Node
var _game_data: Node
var _inventory_system: Node
var _test_user_dir := ""
var _game_instance: Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_save_system = get_tree().root.get_node("SaveSystem")
	_game_data = get_tree().root.get_node("GameData")
	_inventory_system = get_tree().root.get_node("InventorySystem")
	if not _isolate_user_data():
		_fail("user:// de teste nao ficou isolado; nenhum save foi escrito")
		return
	var profile := _profile_with_first_consumable_drop("orc_spearman", "warrior")
	if profile.is_empty() or not bool(_save_system.call(
			"new_game", profile, "warrior", 0, {"name": "Loot Probe"})):
		_fail("nao foi possivel criar o save isolado")
		return

	var game: Node = GAMEPLAY.instantiate()
	_game_instance = game
	add_child(game)
	for _startup_frame: int in 4:
		await get_tree().physics_frame
	var player := game.get("player") as Player
	var hud: Node = game.get("hud") as Node
	var manager := game.get_node_or_null("WorldPickupManager")
	var diagnostic_injection := "--inject-pickup-manager" in OS.get_cmdline_user_args()
	if player == null or hud == null:
		_fail("gameplay.tscn nao criou jogador e HUD reais")
		return
	if manager == null and diagnostic_injection:
		manager = PICKUP_MANAGER.new()
		manager.name = "WorldPickupManager"
		game.add_child(manager)
		if not bool(manager.call("setup", game.get("world"), player, hud, "brumal")):
			_fail("a injecao diagnostica nao conseguiu montar espolio e baus")
			return
		print("[loot-probe] diagnostico: costura de main.gd injectada pelo teste")
	if manager == null:
		_fail("gameplay.tscn nao instancia WorldPickupManager")
		return
	if int(manager.call("chest_count")) < 3:
		_fail("a cena real nao montou os tres baus desenhados de Brumal")
		return

	var victim := _first_living_enemy("orc_spearman")
	if victim == null:
		_fail("a cena real nao criou um lanceiro para a prova")
		return
	var item_key := _first_resolved_card("orc_spearman", profile, "warrior")
	var before_count := _inventory_count(item_key)
	var state_before: Dictionary = _game_data.call("save_state_snapshot") as Dictionary
	if not await _attack_until_dead(player, victim):
		_fail("carregar em attack nao matou o inimigo colocado ao alcance")
		return
	await get_tree().process_frame
	var pickups: Array = manager.call("active_pickups") as Array
	if pickups.is_empty() and diagnostic_injection:
		var current: Dictionary = _game_data.call("save_state_snapshot") as Dictionary
		var receipts: Array = (current.get("world", {}) as Dictionary).get(
			"reward_receipts", []) as Array
		if not receipts.is_empty():
			manager.call("present_enemy_reward", receipts.back(),
				victim.global_position, state_before)
			pickups = manager.call("active_pickups") as Array
	if pickups.size() != 1:
		_fail("a morte real nao deixou exactamente um objecto visivel no chao")
		return
	var pickup := pickups[0] as Node3D
	var audit: Dictionary = pickup.call("audit") as Dictionary
	if int(audit.get("mesh_instances", 0)) != 2 \
			or int(audit.get("dynamic_lights", -1)) != 0 \
			or int(audit.get("audio_voices", 0)) != 1:
		_fail("a queda nao apresentou silhueta, brilho e som dentro do custo")
		return
	var count_after_death := _inventory_count(item_key)
	if count_after_death != before_count + 1:
		_fail("a transaccao da morte nao publicou a carta uma unica vez")
		return
	if not await _walk_to(player, pickup.global_position):
		_fail("o jogador nao conseguiu andar ate ao objecto no chao")
		return
	Input.action_press("interact")
	await get_tree().physics_frame
	Input.action_release("interact")
	await get_tree().process_frame
	if int(manager.call("pickup_count")) != 0 \
			or _inventory_count(item_key) != count_after_death:
		_fail("interact nao confirmou a recolha ou duplicou o recibo")
		return
	var favorite: Dictionary = _inventory_system.call("toggle_favorite", item_key) as Dictionary
	var candidates: Array = _inventory_system.call(
		"quick_slot_candidates", "item") as Array
	if not bool(favorite.get("ok", false)) or not candidates.has(item_key):
		_fail("o consumivel recolhido nao pode ir para o acesso rapido")
		return
	if not await _open_first_chest(player, game, manager):
		return

	print("=== JOGO REAL: DROP + ANDAR + INTERACT + INVENTARIO + BAU OK ===")
	await _finish(0)


func _attack_until_dead(player: Player, victim: Enemy) -> bool:
	victim.set_physics_process(false)
	var weapon_id := String(player.get("main_weapon"))
	var weapon: Dictionary = _game_data.call("weapon", weapon_id) as Dictionary
	var reach := float(weapon.get("range", 0.0))
	var attack: Dictionary = weapon.get("light", {}) as Dictionary
	var attack_mv := float(attack.get("mv", 0.0))
	if reach <= 0.0 or attack_mv <= 0.0:
		return false
	victim.global_position = player.global_position - player.global_transform.basis.z * reach
	player.look_at(Vector3(victim.global_position.x, player.global_position.y,
		victim.global_position.z), Vector3.UP)
	var attrs: Dictionary = player.get("attrs") as Dictionary
	var damage := float(_game_data.call("compute_damage", attack_mv, weapon_id, attrs,
		float(victim.get("defense"))))
	victim.health = damage
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	var total_frames := int(attack.get("startup", 0)) \
		+ int(attack.get("active", 0)) + int(attack.get("recovery", 0))
	for _attack_frame: int in total_frames + 1:
		await get_tree().physics_frame
	return not victim.is_alive()


func _walk_to(player: Player, destination: Vector3) -> bool:
	var rules: Dictionary = (_game_data.get("economy") as Dictionary).get(
		"loot_presentation", {}) as Dictionary
	var radius := float(rules.get("interaction_radius_m", 0.0))
	player.global_position = destination + Vector3.BACK * (radius + radius)
	player.look_at(Vector3(destination.x, player.global_position.y, destination.z), Vector3.UP)
	var movement: Dictionary = _game_data.call("section", "movement") as Dictionary
	var speed := float(movement.get("walk_speed", 0.0))
	var reference_fps := float((_game_data.get("combat") as Dictionary).get(
		"reference_fps", 0.0))
	if radius <= 0.0 or speed <= 0.0 or reference_fps <= 0.0:
		return false
	var frame_budget := ceili((radius + radius) / speed * reference_fps) \
		+ ceili(reference_fps)
	var before := player.global_position.distance_to(destination)
	Input.action_press("move_forward")
	for _walk_frame: int in frame_budget:
		await get_tree().physics_frame
		if player.global_position.distance_to(destination) <= radius:
			break
	Input.action_release("move_forward")
	return player.global_position.distance_to(destination) < before \
		and player.global_position.distance_to(destination) <= radius


func _open_first_chest(player: Player, game: Node, manager: Node) -> bool:
	var world := game.get("world") as Node
	var chests := world.find_children("Chest_*", "Node3D", true, false)
	if chests.is_empty():
		_fail("os baus declarados nao existem como geometria na cena")
		return false
	var chest := chests[0] as Node3D
	var definition: Dictionary = chest.get("definition") as Dictionary
	var before := {}
	for reward_value: Variant in definition.get("rewards", []) as Array:
		var reward := reward_value as Dictionary
		var key := String(reward.get("item", ""))
		before[key] = _inventory_count(key)
	if not await _walk_to(player, chest.global_position):
		_fail("o jogador nao conseguiu andar ate ao bau")
		return false
	Input.action_press("interact")
	await get_tree().physics_frame
	Input.action_release("interact")
	var presentation: Dictionary = (_game_data.get("economy") as Dictionary).get(
		"loot_presentation", {}) as Dictionary
	var reference_fps := float((_game_data.get("combat") as Dictionary).get(
		"reference_fps", 0.0))
	var animation_frames := ceili(float(presentation.get(
		"chest_open_seconds", 0.0)) * reference_fps)
	for _animation_frame: int in animation_frames + 1:
		await get_tree().physics_frame
	if not bool(chest.call("is_opened")):
		_fail("interact nao abriu nem animou o bau")
		return false
	for reward_value: Variant in definition.get("rewards", []) as Array:
		var reward := reward_value as Dictionary
		var key := String(reward.get("item", ""))
		if _inventory_count(key) != int(before.get(key, 0)) + int(reward.get("count", 0)):
			_fail("o bau nao entregou exactamente o conjunto desenhado")
			return false
	return int(manager.call("chest_count")) >= 3


func _profile_with_first_consumable_drop(enemy_id: String, class_id: String) -> String:
	var enemy: Dictionary = _game_data.call("enemy", enemy_id) as Dictionary
	var cards: Array = enemy.get("loot_cards", []) as Array
	for candidate_index: int in cards.size() * cards.size():
		var candidate := "loot-probe-%d" % candidate_index
		if _first_resolved_card(enemy_id, candidate, class_id).begins_with("consumivel:"):
			return candidate
	return ""


func _first_resolved_card(enemy_id: String, profile_id: String,
		class_id: String) -> String:
	var order: Array = _game_data.call("loot_draw_order", enemy_id, hash(profile_id)) as Array
	if order.is_empty():
		return ""
	return String(_game_data.call(
		"resolve_loot_card", enemy_id, String(order[0]), class_id))


func _first_living_enemy(enemy_id: String) -> Enemy:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.enemy_id == enemy_id and enemy.is_alive():
			return enemy
	return null


func _inventory_count(item_key: String) -> int:
	var state: Dictionary = _game_data.call("save_state_snapshot") as Dictionary
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	return int((inventory.get("items", {}) as Dictionary).get(item_key, 0))


func _isolate_user_data() -> bool:
	var before := OS.get_user_data_dir()
	_test_user_dir = "WorldRPGs-Testes/loot-%d" % OS.get_process_id()
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", _test_user_dir)
	var isolated := OS.get_user_data_dir()
	print("[loot-probe] user:// isolado: %s" % isolated)
	return isolated != before and isolated.replace("\\", "/").ends_with(_test_user_dir)


func _cleanup_test_saves() -> void:
	if _test_user_dir.is_empty():
		return
	for slot: int in 3:
		var path := String(_save_system.call("slot_path", slot))
		for exact_path: String in [path, path + ".bak"]:
			if FileAccess.file_exists(exact_path):
				var error := DirAccess.remove_absolute(
					ProjectSettings.globalize_path(exact_path))
				if error != OK:
					printerr("[loot-probe] nao limpou %s: erro %d" % [exact_path, error])
	var isolated_root := OS.get_user_data_dir()
	var settings_path := isolated_root.path_join("settings.json")
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)
	DirAccess.remove_absolute(isolated_root.path_join("saves"))
	DirAccess.remove_absolute(isolated_root)


func _finish(exit_code: int) -> void:
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("_stop_brumal"):
		sfx.call("_stop_brumal")
	if is_instance_valid(_game_instance):
		_game_instance.queue_free()
		for _teardown_frame: int in 4:
			await get_tree().process_frame
	_cleanup_test_saves()
	get_tree().quit(exit_code)


func _fail(message: String) -> void:
	printerr("[loot-probe] FALHOU: %s" % message)
	await _finish(1)
