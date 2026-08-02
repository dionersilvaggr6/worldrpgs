extends Node
## Prova jogavel da magia: casca + cena real + Player + inimigo real.
## Main persiste a normalizacao do inventario ao arrancar. Por isso esta prova
## reserva um slot alto que nao exista, valida-o e apaga-o no fim.

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const TEST_TIMEOUT_MULTIPLIER := 3.0
const TEST_SLOT_MIN := 9000
const TEST_SLOT_MAX := 9999
const TEST_PROFILE_ID := "prova-magia-em-memoria"

var _passed := 0
var _failed := 0
var _previous_state: Dictionary = {}
var _previous_scene_arg := ""
var _previous_slot := -1
var _test_slot := -1
var _gameplay: Node3D


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_previous_state = GameData.save_state_snapshot()
	_previous_scene_arg = Bench.scene_arg
	_previous_slot = SaveSystem.active_slot
	if "--capture-spell-game" in OS.get_cmdline_user_args():
		var benchmark: Dictionary = (GameData.spells.get("_vfx", {}) as Dictionary).get(
			"benchmark", {}) as Dictionary
		DisplayServer.window_set_size(Vector2i(int(benchmark.get("width", 0)),
			int(benchmark.get("height", 0))))
	_test_slot = _find_unused_test_slot()
	if _test_slot < 0:
		_check(false, "isolamento encontra um slot temporario livre")
		await _finish()
		return
	SaveSystem.active_slot = _test_slot
	var test_state := SaveSystem.create_save(TEST_PROFILE_ID, "evil_mage")
	# null e mao livre no catalogo; a casca antiga tenta String(null). O repro
	# normaliza apenas a copia temporaria e deixa a lacuna documentada ao dono.
	var character: Dictionary = test_state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	if equipment.get("offhand") == null:
		equipment["offhand"] = ""
	GameData.replace_save_state(test_state)
	Bench.scene_arg = "combat"

	_gameplay = GAMEPLAY_SCENE.instantiate()
	add_child(_gameplay)
	for _frame: int in 3:
		await get_tree().physics_frame

	var player := _gameplay.get("player") as Player
	var enemy := _first_live_enemy()
	_check(is_instance_valid(player) and is_instance_valid(enemy),
		"a cena real monta Player, mundo e inimigo")
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		await _finish()
		return

	var spell: Dictionary = GameData.spell(player.selected_spell)
	_check(player.class_id == "evil_mage", "a prova arranca como Mago do Mal real")
	_check(player.main_weapon == "staff" and player.offhand_weapon.is_empty(),
		"o kit real reproduz cajado principal sem catalisador secundario")
	_check(not spell.is_empty(), "o favorito visivel resolve no catalogo")
	if spell.is_empty():
		await _finish()
		return

	var first_result := await _cast_at_enemy(player, enemy, player.selected_spell)
	_check(bool(first_result.get("cast_started", false)),
		"carregar em cast com o kit real inicia a magia e mostra o custo de mana")
	_check(bool(first_result.get("staff_visible", false))
		and bool(first_result.get("flash_at_tip", false)),
		"o cajado aparece e o clarao nasce exactamente no foco")
	_check(bool(first_result.get("trail_visible", false)),
		"o projectil atravessa o mundo real com rasto visivel")
	_check(bool(first_result.get("truthful_clock", false)),
		"o nucleo visivel e a hitbox partilham o mesmo relogio")
	_check(bool(first_result.get("damaged", false)),
		"o projectil acerta no inimigo real e tira vida")
	_check(bool(first_result.get("impact_visible", false))
		and bool(first_result.get("impact_same_frame", false))
		and bool(first_result.get("closed_together", false)),
		"o dano e o impacto visivel acontecem no mesmo frame")

	var red_spell_id := _first_red_projectile_id()
	var red_enemy := _first_live_enemy(enemy)
	_check(not red_spell_id.is_empty() and is_instance_valid(red_enemy),
		"o catalogo fornece uma magia vermelha e outro alvo real")
	if not red_spell_id.is_empty() and is_instance_valid(red_enemy):
		if not player.favorite_spells.has(red_spell_id):
			player.favorite_spells.append(red_spell_id)
		player.select_spell(red_spell_id)
		var red_result := await _cast_at_enemy(player, red_enemy, red_spell_id)
		_check(bool(red_result.get("damaged", false)),
			"o Mago do Mal lanca a magia vermelha pela mesma tecla e ela acerta")
		_check(bool(red_result.get("diseased_trail", false))
			and bool(red_result.get("diseased_impact", false)),
			"a magia vermelha usa rasto caido e veios escuros, nunca aura heroica")

	await _finish()


func _cast_at_enemy(player: Player, enemy: Enemy, spell_id: String) -> Dictionary:
	var result := {
		"cast_started": false,
		"staff_visible": false,
		"flash_at_tip": false,
		"trail_visible": false,
		"truthful_clock": true,
		"closed_together": false,
		"damaged": false,
		"impact_visible": false,
		"impact_same_frame": false,
		"diseased_trail": false,
		"diseased_impact": false,
	}
	var spell: Dictionary = GameData.spell(spell_id)
	enemy.set_physics_process(false)
	var direction := -player.global_transform.basis.z.normalized()
	var range_m := float(spell.get("range_m", spell.get("max_range", 0.0)))
	enemy.global_position = player.global_position + direction * range_m / TEST_TIMEOUT_MULTIPLIER
	player.lock_on.target = enemy
	var health_before := enemy.health
	var mana_before := player.mana

	Input.action_press("cast")
	await get_tree().physics_frame
	Input.action_release("cast")
	await get_tree().physics_frame
	result.cast_started = player.state == Player.State.CASTING and player.mana < mana_before
	var weapon_visual := _casting_weapon_visual(player)
	var flash := _latest_group_node("spell_cast_vfx")
	if is_instance_valid(weapon_visual):
		result.staff_visible = bool(weapon_visual.call("has_visible_weapon", player.main_weapon))
		if is_instance_valid(flash) and flash.has_method("tip_position"):
			var tip := weapon_visual.call("main_weapon_tip_position") as Vector3
			var flash_tip := flash.call("tip_position") as Vector3
			var render: Dictionary = (GameData.spells.get("_vfx", {}) as Dictionary).get(
				"render", {}) as Dictionary
			result.flash_at_tip = tip.distance_to(flash_tip) \
				<= float(render.get("base_diameter_m", 0.0))

	var speed_mps := float(spell.get("speed_mps", spell.get("speed", 0.0)))
	var cast_s := float(spell.get("cast_time", 0.0))
	var travel_s := range_m / maxf(speed_mps, 1.0)
	var frame_limit := ceili((cast_s + travel_s) * TEST_TIMEOUT_MULTIPLIER \
		* float(Engine.physics_ticks_per_second))
	var observed_delivery: Node3D
	var captured_trail := false
	for _frame: int in frame_limit:
		await get_tree().physics_frame
		var delivery := _delivery_for(spell_id)
		if is_instance_valid(delivery):
			var snapshot := delivery.call("snapshot") as Dictionary
			var vfx := delivery.get_node_or_null(NodePath("SpellVfx_%s" % spell_id))
			if delivery != observed_delivery:
				observed_delivery = delivery
				var expiry_delivery := delivery
				var expiry_vfx := vfx
				delivery.delivery_expired.connect(func(_expired_spell_id: String) -> void:
					var closed := expiry_delivery.call("snapshot") as Dictionary
					result.closed_together = not bool(closed.get("hitbox_active", true)) \
						and not bool(closed.get("contact_visual_visible", true)) \
						and is_instance_valid(expiry_vfx) \
						and not bool(expiry_vfx.call("is_contact_visible")), CONNECT_ONE_SHOT)
			if is_instance_valid(vfx):
				result.trail_visible = bool(result.trail_visible) \
					or bool(vfx.call("has_visible_trail"))
				result.diseased_trail = bool(result.diseased_trail) \
					or bool(vfx.call("is_diseased_style_visible"))
				result.truthful_clock = bool(result.truthful_clock) \
					and bool(snapshot.get("hitbox_active", false)) \
					== bool(vfx.call("is_contact_visible"))
				if not captured_trail and bool(vfx.call("has_visible_trail")) \
						and "--capture-spell-game" in OS.get_cmdline_user_args():
					captured_trail = true
					await _capture_frame("%s-trail" % spell_id)
		if enemy.health < health_before:
			result.damaged = true
			var impact := _latest_group_node("spell_impact_vfx")
			result.impact_visible = is_instance_valid(impact) \
				and int(impact.call("visible_instance_count")) > 0
			if is_instance_valid(impact):
				result.impact_same_frame = absi(int(impact.call("spawn_physics_frame")) \
					- Engine.get_physics_frames()) <= 1
				var render: Dictionary = (GameData.spells.get("_vfx", {}) as Dictionary).get(
					"render", {}) as Dictionary
				result.diseased_impact = int(impact.call("visible_instance_count")) \
					> int(render.get("rings", 0))
				if "--capture-spell-game" in OS.get_cmdline_user_args():
					await _capture_frame("%s-impact" % spell_id)
			break
	return result


func _first_live_enemy(excluded: Enemy = null) -> Enemy:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy != excluded and enemy.is_alive() and not enemy.is_boss:
			return enemy
	return null


func _first_red_projectile_id() -> String:
	for spell_value: Variant in GameData.spells.get("order", []):
		var spell_id := String(spell_value)
		var spell: Dictionary = GameData.spell(spell_id)
		if String(spell.get("school", "")) == "mal" \
				and String(spell.get("contact_type", "")) == "volume_movel" \
				and float(spell.get("base_damage", 0.0)) > 0.0:
			return spell_id
	return ""


func _delivery_for(spell_id: String) -> Node3D:
	for node: Node in get_tree().get_nodes_in_group("spell_deliveries"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if String((node.call("snapshot") as Dictionary).get("spell_id", "")) == spell_id:
			return node as Node3D
	return null


func _latest_group_node(group_name: StringName) -> Node3D:
	var nodes := get_tree().get_nodes_in_group(group_name)
	for index: int in range(nodes.size() - 1, -1, -1):
		var node := nodes[index] as Node3D
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			return node
	return null


func _casting_weapon_visual(player: Player) -> Node3D:
	for node: Node in player.find_children("*", "Node3D", true, false):
		if node.has_method("main_weapon_tip_position") \
				and node.has_method("visible_mesh_count"):
			return node as Node3D
	return null


func _capture_frame(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "user://spell-game-%s.png" % label
	var error := get_viewport().get_texture().get_image().save_png(path)
	print("[magia-jogo] CAPTURE %s %s" % [
		"OK" if error == OK else "FALHOU", ProjectSettings.globalize_path(path)])


func _finish() -> void:
	Input.action_release("cast")
	if is_instance_valid(_gameplay):
		_gameplay.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	_cleanup_test_slot()
	GameData.replace_save_state(_previous_state)
	SaveSystem.active_slot = _previous_slot
	Bench.scene_arg = _previous_scene_arg
	print("\n=== MAGIA NO JOGO: %d passaram, %d falharam ===\n" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _find_unused_test_slot() -> int:
	for candidate: int in range(TEST_SLOT_MIN, TEST_SLOT_MAX + 1):
		var path := SaveSystem.slot_path(candidate)
		if not FileAccess.file_exists(path) \
				and not FileAccess.file_exists(path + ".bak") \
				and not FileAccess.file_exists(path + ".tmp"):
			return candidate
	return -1


func _cleanup_test_slot() -> void:
	if _test_slot < TEST_SLOT_MIN or _test_slot > TEST_SLOT_MAX:
		return
	var path := SaveSystem.slot_path(_test_slot)
	for suffix: String in ["", ".tmp", ".bak", ".corrupt"]:
		var candidate := path + suffix
		if not FileAccess.file_exists(candidate):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		if parsed is Dictionary:
			var character: Dictionary = (parsed as Dictionary).get(
				"character", {}) as Dictionary
			if String(character.get("profile_id", "")) != TEST_PROFILE_ID:
				push_error("[magia-jogo] recusa limpar slot temporario com outro perfil")
				continue
		DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % description)
	else:
		_failed += 1
		printerr("  FALHA %s" % description)
