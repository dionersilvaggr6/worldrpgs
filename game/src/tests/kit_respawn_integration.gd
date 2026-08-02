extends Node
## Prova integrada do pedido do Mateus: o kit sai dos catalogos para o jogador
## e a morte completa o percurso ate a fogueira duas vezes seguidas.
##
## Correr com:
##   godot --headless --audio-driver Dummy --path game/ \
##     src/tests/kit_respawn_integration.tscn

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const FLASK_ITEM_KEY := "consumivel:frasco_bruma"
const TEST_SLOT_MIN := 9000
const TEST_SLOT_MAX := 9999
const TEST_TIMEOUT_MULTIPLIER := 3.0
const MILLISECONDS_PER_SECOND := 1000.0

var _passed := 0
var _failed := 0
var _test_slot := -1
var _previous_slot := -1
var _previous_state := {}
var _previous_scene_arg := ""
var _gameplay: Node3D


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_previous_slot = SaveSystem.active_slot
	_previous_state = GameData.save_state_snapshot()
	_previous_scene_arg = Bench.scene_arg
	_test_slot = _find_unused_test_slot()
	if _test_slot < 0:
		_check(false, "isolamento: encontrou um slot temporario livre")
		await _finish()
		return

	_test_starting_kits()
	await _test_death_and_respawn_twice()
	await _finish()


func _test_starting_kits() -> void:
	var loadouts: Dictionary = GameData.weapons.get("loadouts", {}) as Dictionary
	var default_spells: Array = (GameData.spells.get("_rules", {}) as Dictionary).get(
		"default_favorites", []) as Array
	var origin_ids: Array[String] = []
	for origin_value: Variant in loadouts.keys():
		var origin_id := String(origin_value)
		if not origin_id.begins_with("_"):
			origin_ids.append(origin_id)
	origin_ids.sort()

	_check(not origin_ids.is_empty(), "kit: os dados declaram origens jogaveis")
	_check(not default_spells.is_empty(), "kit: os dados declaram feitico inicial")
	if origin_ids.is_empty() or default_spells.is_empty():
		return
	for origin_id: String in origin_ids:
		var state := SaveSystem.create_save("kit-%s" % origin_id, origin_id)
		InventorySystem.normalise_state(state)
		var character: Dictionary = state.get("character", {}) as Dictionary
		var progression: Dictionary = character.get("progression", {}) as Dictionary
		var inventory: Dictionary = character.get("inventory", {}) as Dictionary
		var items: Dictionary = inventory.get("items", {}) as Dictionary
		var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
		var loadout: Dictionary = loadouts.get(origin_id, {}) as Dictionary

		_check(_owns_declared_kit(items, loadout),
			"kit/%s: arma, offhand e pecas entram na mochila" % origin_id)
		_check(equipment.get("main") == loadout.get("main")
			and equipment.get("offhand") == loadout.get("offhand")
			and (equipment.get("armor", []) as Array) == (loadout.get("pecas", []) as Array),
			"kit/%s: arma, offhand e pecas arrancam equipados" % origin_id)
		_check(int(items.get(FLASK_ITEM_KEY, 0)) > 0,
			"kit/%s: o frasco entra na mochila" % origin_id)
		_check((progression.get("known_spells", []) as Array).has(default_spells[0])
			and (equipment.get("spell_favorites", []) as Array).has(default_spells[0]),
			"kit/%s: o feitico inicial e conhecido e equipado" % origin_id)

		var slots := _slots_by_name(InventorySystem.quick_slot_snapshot(state))
		_check(String((slots.get("right_hand", {}) as Dictionary).get("key", ""))
			== _weapon_key(loadout.get("main"))
			and String((slots.get("left_hand", {}) as Dictionary).get("key", ""))
			== _weapon_key(loadout.get("offhand")),
			"kit/%s: as duas maos aparecem nas ranhuras rapidas" % origin_id)
		_check(String((slots.get("spell", {}) as Dictionary).get("key", ""))
			== "magia:%s" % String(default_spells[0])
			and String((slots.get("item", {}) as Dictionary).get("key", ""))
			== FLASK_ITEM_KEY,
			"kit/%s: feitico e frasco aparecem nas ranhuras rapidas" % origin_id)


func _test_death_and_respawn_twice() -> void:
	SaveSystem.active_slot = _test_slot
	GameData.replace_save_state(SaveSystem.create_save(
		"prova-kit-morte", "assassin"))
	Bench.scene_arg = "combat"
	_gameplay = GAMEPLAY_SCENE.instantiate()
	add_child(_gameplay)
	await get_tree().physics_frame

	var player := _gameplay.get("player") as Player
	var enemy := _first_common_enemy(_gameplay)
	var rest := _gameplay.get_node_or_null("Rest_brumal_clareira") as Node3D
	_check(is_instance_valid(player) and is_instance_valid(enemy)
		and is_instance_valid(rest),
		"morte: a cena real monta jogador, inimigo e fogueira")
	if not is_instance_valid(player) or not is_instance_valid(enemy) \
			or not is_instance_valid(rest):
		return

	var quick_slots_hud := InventorySystem.get_node_or_null("QuickSlots") as CanvasLayer
	_check(is_instance_valid(quick_slots_hud) and quick_slots_hud.visible,
		"kit: as ranhuras rapidas estao visiveis no jogo real")
	var runtime_slots := _slots_by_name(
		InventorySystem.quick_slot_snapshot({}, player))
	_check(String((runtime_slots.get("right_hand", {}) as Dictionary).get("key", ""))
		== "arma:dagger"
		and String((runtime_slots.get("left_hand", {}) as Dictionary).get("key", ""))
		== "arma:dagger"
		and String((runtime_slots.get("spell", {}) as Dictionary).get("key", ""))
		.begins_with("magia:")
		and String((runtime_slots.get("item", {}) as Dictionary).get("key", ""))
		== FLASK_ITEM_KEY,
		"kit: o Assassino entra no mundo com duas adagas, magia e frasco visiveis")

	_gameplay.call("set_local_input_enabled", false)
	enemy.target = null
	var respawn_position := player.global_position
	var enemy_spawn := enemy.global_position
	_check(not respawn_position.is_equal_approx(rest.global_position),
		"morte: o ponto de regresso fica ao lado da fogueira, nao dentro da chama")

	await _run_death_cycle(player, enemy, enemy_spawn, respawn_position, rest,
		"primeira")
	var first_sequence := _death_sequence()
	await _run_death_cycle(player, enemy, enemy_spawn, respawn_position, rest,
		"segunda")
	_check(_death_sequence() > first_sequence,
		"morte: a segunda morte e gravada depois da primeira")


func _run_death_cycle(player: Player, enemy: Enemy, enemy_spawn: Vector3,
		respawn_position: Vector3, rest: Node3D, label: String) -> void:
	var enemy_damage := DamageInfo.make(enemy.health, player, "heavy")
	enemy.take_damage(enemy_damage)
	_check(not enemy.is_alive(),
		"morte/%s: um inimigo esta derrotado antes da morte do jogador" % label)

	player.global_position = enemy_spawn
	var death_position := player.global_position
	player.flask_uses = 0
	var damage_rules: Dictionary = GameData.attributes.get("damage", {}) as Dictionary
	var floor_fraction := float(damage_rules.get(
		"min_damage_fraction_after_defense", 0.0))
	if floor_fraction <= 0.0:
		_check(false, "morte/%s: os dados declaram o piso de dano" % label)
		return
	var lethal_damage := player.max_health / floor_fraction
	player.take_damage(DamageInfo.make(lethal_damage, enemy, "heavy"))
	_check(not player.is_alive(),
		"morte/%s: dano real mata o jogador de proposito" % label)

	var returned := await _wait_until_alive(player)
	_check(returned, "morte/%s: o jogador renasce" % label)
	if not returned:
		return
	var returned_ground := Vector2(player.global_position.x, player.global_position.z)
	var respawn_ground := Vector2(respawn_position.x, respawn_position.z)
	var death_ground := Vector2(death_position.x, death_position.z)
	var rest_ground := Vector2(rest.global_position.x, rest.global_position.z)
	_check(returned_ground.is_equal_approx(respawn_ground)
		and not returned_ground.is_equal_approx(death_ground)
		and is_equal_approx(returned_ground.distance_to(rest_ground),
			respawn_ground.distance_to(rest_ground)),
		"morte/%s: regressa a fogueira, nao ao lugar onde caiu" % label)
	_check(is_equal_approx(player.health, player.max_health)
		and player.flask_uses == player.flask_max,
		"morte/%s: vida e frascos ficam repostos" % label)
	_check(enemy.is_alive() and is_equal_approx(enemy.health, enemy.max_health)
		and enemy.is_in_group("enemies"),
		"morte/%s: os inimigos voltam activos e com vida cheia" % label)


func _wait_until_alive(player: Player) -> bool:
	var fade_seconds := float(GameData.section("death").get(
		"respawn_fade_seconds", 0.0))
	var deadline := Time.get_ticks_msec() + ceili(
		fade_seconds * TEST_TIMEOUT_MULTIPLIER * MILLISECONDS_PER_SECOND)
	while not player.is_alive() and Time.get_ticks_msec() <= deadline:
		await get_tree().process_frame
	return player.is_alive()


func _owns_declared_kit(items: Dictionary, loadout: Dictionary) -> bool:
	for slot_name: String in ["main", "offhand"]:
		var item_value: Variant = loadout.get(slot_name)
		if item_value != null and String(item_value) != "" \
				and int(items.get("arma:%s" % String(item_value), 0)) <= 0:
			return false
	for armor_value: Variant in loadout.get("pecas", []):
		if int(items.get("armadura:%s" % String(armor_value), 0)) <= 0:
			return false
	return true


func _slots_by_name(snapshot: Array[Dictionary]) -> Dictionary:
	var result := {}
	for slot: Dictionary in snapshot:
		result[String(slot.get("slot", ""))] = slot
	return result


func _weapon_key(value: Variant) -> String:
	return "estado:mao_livre" if value == null or String(value) == "" \
		else "arma:%s" % String(value)


func _first_common_enemy(root: Node) -> Enemy:
	for child: Node in root.get_children():
		var enemy := child as Enemy
		if enemy != null and not enemy.is_boss:
			return enemy
	return null


func _death_sequence() -> int:
	var state := GameData.save_state_snapshot()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var death: Dictionary = character.get("death", {}) as Dictionary
	var stain: Dictionary = death.get("soul_stain", {}) as Dictionary
	return int(stain.get("death_sequence", 0))


func _find_unused_test_slot() -> int:
	for candidate: int in range(TEST_SLOT_MIN, TEST_SLOT_MAX + 1):
		var path := SaveSystem.slot_path(candidate)
		if not FileAccess.file_exists(path) \
				and not FileAccess.file_exists(path + ".bak") \
				and not FileAccess.file_exists(path + ".tmp"):
			return candidate
	return -1


func _cleanup_test_slot() -> void:
	if _test_slot < 0:
		return
	var path := SaveSystem.slot_path(_test_slot)
	for suffix: String in ["", ".tmp", ".bak", ".corrupt"]:
		var candidate := path + suffix
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _finish() -> void:
	if is_instance_valid(_gameplay):
		_gameplay.queue_free()
		while is_instance_valid(_gameplay):
			await get_tree().process_frame
	await _wait_for_world_audio_cleanup()
	_cleanup_test_slot()
	GameData.replace_save_state(_previous_state)
	SaveSystem.active_slot = _previous_slot
	Bench.scene_arg = _previous_scene_arg
	print("\n=== KIT E MORTE: %d passaram, %d falharam ===\n" % [
		_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _wait_for_world_audio_cleanup() -> void:
	var fade_seconds := float(GameData.section("death").get(
		"respawn_fade_seconds", 0.0))
	var deadline := Time.get_ticks_msec() + ceili(
		fade_seconds * TEST_TIMEOUT_MULTIPLIER * MILLISECONDS_PER_SECOND)
	while (Sfx.active_ambience_layer_count() > 0
			or Sfx.active_bonfire_source_count() > 0) \
			and Time.get_ticks_msec() <= deadline:
		await get_tree().process_frame
	await get_tree().process_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % description)
	else:
		_failed += 1
		printerr("  FALHA %s" % description)
