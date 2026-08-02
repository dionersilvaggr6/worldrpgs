extends Node
## Prova end-to-end carregada exclusivamente por scenes/repro-inicio.tscn.
## Usa a mochila, os botoes, InputMap, Player, inimigo e HUD reais; se falhar,
## delega a limpeza dos saves ao proprio repro antes de terminar o processo.

const InventoryMenuScript = preload("res://src/ui/inventory_menu.gd")
const EquipmentScreenScript = preload("res://src/ui/equipment_screen.gd")

var _quick_slots: Node
var _gameplay: Node
var _player: Player
var _state_before: Dictionary
var _weapon_key := ""


func setup(quick_slots: Node) -> void:
	_quick_slots = quick_slots
	call_deferred("_run")


func _run() -> void:
	_gameplay = _find_gameplay()
	if not is_instance_valid(_gameplay):
		_fail("a prova de acesso rapido nao encontrou a cena gameplay real")
		return
	_player = _gameplay.get("player") as Player
	if not is_instance_valid(_player):
		_fail("a prova de acesso rapido nao encontrou o Player real")
		return
	_state_before = GameData.save_state_snapshot()
	if not _prove_starting_loadouts():
		return
	_weapon_key = _catalogue_test_weapon_key()
	if _weapon_key == "":
		_fail("o catalogo nao forneceu uma segunda arma principal executavel")
		return
	if not _give_test_weapon():
		return
	if not _edit_from_real_backpack():
		return
	if not await _prove_selected_item_use():
		return
	await _prove_equipped_weapon_attack()


func _prove_starting_loadouts() -> bool:
	var contract_errors: Array = _gameplay.get("starting_loadout_contract_errors") as Array
	if not contract_errors.is_empty():
		return _loadout_failure("StartingLoadouts recusou o catalogo no jogo: %s" % \
			", ".join(contract_errors))
	var loadouts := GameData.weapons.get("loadouts", {}) as Dictionary
	var origin_ids: Array[String] = []
	for value: Variant in loadouts.keys():
		var origin_id := String(value)
		if not origin_id.begins_with("_"):
			origin_ids.append(origin_id)
	origin_ids.sort()
	var creation_ids: Array[String] = GameShell.CLASS_IDS.duplicate()
	creation_ids.sort()
	if origin_ids != creation_ids:
		return _loadout_failure("criacao e kits activos discordam: %s/%s" % [
			creation_ids, origin_ids])
	var armor_visual := _player.get("_visual") as ArmorVisual
	var weapon_visual := _player.get_node_or_null("WeaponAttach") as WeaponAttach
	var surface := _quick_slots.get("_surface") as Control
	if armor_visual == null or weapon_visual == null or surface == null:
		return _loadout_failure("o Player real nao expos armadura, armas e caixa visiveis")
	var default_spells: Array = (GameData.spells.get("_rules", {}) as Dictionary).get(
		"default_favorites", []) as Array
	for origin_id: String in origin_ids:
		var expected := loadouts.get(origin_id, {}) as Dictionary
		var state := SaveSystem.create_save("repro-kit-%s" % origin_id, origin_id)
		QuickSlotsModel.normalise_state(state, GameData.weapons, default_spells)
		GameData.replace_save_state(state)
		_gameplay.call("refresh_inventory_state")
		InventorySystem.emit_signal("inventory_changed")
		weapon_visual.sync_from_actor()
		_quick_slots.call("_refresh")

		var character := state.get("character", {}) as Dictionary
		var identity := character.get("identity", {}) as Dictionary
		var inventory := character.get("inventory", {}) as Dictionary
		var equipment := inventory.get("equipment", {}) as Dictionary
		var items := inventory.get("items", {}) as Dictionary
		var main_id := String(expected.get("main", ""))
		var offhand_value: Variant = expected.get("offhand", null)
		var offhand_id := "" if offhand_value == null else String(offhand_value)
		var pieces := expected.get("pecas", []) as Array
		if String(identity.get("class_id", "")) != origin_id \
				or main_id.is_empty() or _player.main_weapon != main_id \
				or _player.offhand_weapon != offhand_id:
			return _loadout_failure("%s nao chegou com as duas maos catalogadas" % origin_id)
		if int(items.get("arma:%s" % main_id, 0)) < 1 \
				or (offhand_id != "" and int(items.get("arma:%s" % offhand_id, 0)) < 1) \
				or int(items.get(QuickSlotsModel.FLASK_ITEM_KEY, 0)) < 1:
			return _loadout_failure("%s nao recebeu armas e Frasco de Bruma" % origin_id)
		for piece_value: Variant in pieces:
			if int(items.get("armadura:%s" % String(piece_value), 0)) < 1:
				return _loadout_failure("%s nao recebeu a peca %s" % [origin_id, piece_value])
		var equipped_pieces := armor_visual.equipped_piece_ids()
		for piece_value: Variant in pieces:
			if not equipped_pieces.has(String(piece_value)):
				return _loadout_failure("%s nao vestiu %s no boneco" % [origin_id, piece_value])
		if not weapon_visual.has_visible_weapon(main_id, true) \
				or (offhand_id != "" and not weapon_visual.has_visible_weapon(offhand_id, false)):
			return _loadout_failure("%s guardou o kit, mas nao o mostrou nas maos" % origin_id)
		if offhand_id == "" and not _player.is_two_handed:
			return _loadout_failure("%s nao mostrou a empunhadura catalogada a duas maos" % \
				origin_id)
		var visible_slots: Array = surface.get("slots") as Array
		var right := _slot_by_name(visible_slots, "right_hand")
		var left := _slot_by_name(visible_slots, "left_hand")
		var item := _slot_by_name(visible_slots, "item")
		var expected_left := "arma:%s" % offhand_id if offhand_id != "" \
			else QuickSlotsModel.FREE_HAND_KEY
		if not _quick_slots.visible or String(right.get("key", "")) != "arma:%s" % main_id \
				or String(left.get("key", "")) != expected_left \
				or String(item.get("key", "")) != QuickSlotsModel.FLASK_ITEM_KEY \
				or int(item.get("count", -1)) != _player.flask_uses:
			return _loadout_failure("%s nao apareceu completo no acesso rapido" % origin_id)

	GameData.replace_save_state(_state_before)
	_gameplay.call("refresh_inventory_state")
	InventorySystem.emit_signal("inventory_changed")
	weapon_visual.sync_from_actor()
	_quick_slots.call("_refresh")
	print(("[repro] kits iniciais: %d origens com arma, armadura, frasco, " \
		+ "offhand ou duas maos, caixa e boneco") % origin_ids.size())
	return true


func _slot_by_name(slots: Array, slot_name: String) -> Dictionary:
	for value: Variant in slots:
		var slot := value as Dictionary
		if String(slot.get("slot", "")) == slot_name:
			return slot
	return {}


func _loadout_failure(message: String) -> bool:
	GameData.replace_save_state(_state_before)
	if is_instance_valid(_gameplay):
		_gameplay.call("refresh_inventory_state")
	InventorySystem.emit_signal("inventory_changed")
	_fail("kits iniciais: %s" % message)
	return false


func _give_test_weapon() -> bool:
	var state := GameData.save_state_snapshot()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var items: Dictionary = inventory.get("items", {}) as Dictionary
	items[_weapon_key] = maxi(1, int(items.get(_weapon_key, 0)))
	inventory["items"] = items
	character["inventory"] = inventory
	state["character"] = character
	GameData.replace_save_state(state)
	if SaveSystem.save_current():
		return true
	_fail("nao foi possivel preparar a arma catalogada da prova na mochila")
	return false


func _edit_from_real_backpack() -> bool:
	var input_before := bool(_player.input_enabled)
	_player.input_enabled = false
	var menu := InventoryMenuScript.new()
	menu.name = "InventoryMenuProof"
	get_tree().current_scene.add_child(menu)
	menu.open(null, _gameplay)
	# Forca o mesmo ponto de montagem que corre automaticamente no fim do frame;
	# o clique e toda a edicao abaixo continuam a usar os controlos reais.
	_quick_slots.call("_install_backpack_entry")
	var edit_button := menu.find_child(
		EquipmentScreenScript.BACKPACK_BUTTON_NAME, true, false) as Button
	if edit_button == null or not edit_button.visible:
		menu.queue_free()
		_player.input_enabled = input_before
		_fail("a mochila real nao mostrou EDITAR ACESSO RAPIDO")
		return false
	edit_button.pressed.emit()
	var screen := menu.get_parent().find_child("EquipmentScreen", false, false) \
		as EquipmentScreen
	if screen == null or not screen.visible:
		menu.queue_free()
		_player.input_enabled = input_before
		_fail("o botao da mochila nao abriu o editor de equipamento")
		return false
	if not _choose(screen, "quick:1", QuickSlotsModel.FLASK_ITEM_KEY):
		menu.queue_free()
		_player.input_enabled = input_before
		return false
	if not _choose(screen, "main", _weapon_key):
		menu.queue_free()
		_player.input_enabled = input_before
		return false
	var state := GameData.save_state_snapshot()
	var quick_slots: Array = _inventory(state).get("quick_slots", []) as Array
	if quick_slots.size() <= 1 or String(quick_slots[0]) != "" \
			or String(quick_slots[1]) != QuickSlotsModel.FLASK_ITEM_KEY:
		_fail("confirmar no editor nao guardou o frasco no atalho exacto")
		return false
	if _player.main_weapon != _weapon_key.trim_prefix("arma:"):
		_fail("a troca confirmada nao chegou ao boneco real")
		return false
	var back := _button_with_text(screen, "VOLTAR")
	if back == null:
		_fail("o editor nao permite voltar a mochila")
		return false
	back.pressed.emit()
	menu.queue_free()
	_player.input_enabled = input_before
	return true


func _choose(screen: EquipmentScreen, slot_id: String, candidate_key: String) -> bool:
	var slots := screen.find_child("EquipmentSlotList", true, false) as ItemList
	var candidates := screen.find_child("EquipmentCandidateList", true, false) as ItemList
	var confirm := screen.find_child("EquipmentConfirmButton", true, false) as Button
	if slots == null or candidates == null or confirm == null:
		_fail("o editor abriu sem os controlos de ranhura, mochila e confirmar")
		return false
	var slot_index := _metadata_index(slots, slot_id)
	if slot_index < 0:
		_fail("o editor nao mostrou a ranhura %s" % slot_id)
		return false
	slots.select(slot_index)
	slots.item_selected.emit(slot_index)
	var candidate_index := _metadata_index(candidates, candidate_key)
	if candidate_index < 0:
		_fail("a mochila nao mostrou %s como candidato de %s" % [candidate_key, slot_id])
		return false
	candidates.select(candidate_index)
	candidates.item_selected.emit(candidate_index)
	if confirm.disabled:
		_fail("a escolha %s ficou sem confirmacao" % candidate_key)
		return false
	confirm.pressed.emit()
	return true


func _prove_selected_item_use() -> bool:
	var actions := EquipmentScreenScript.quick_slot_actions()
	if actions.size() <= 1:
		_fail("controls.json nao declarou pelo menos dois atalhos seleccionaveis")
		return false
	var use_action := _configured_action("use_item")
	if use_action == "":
		_fail("controls.json nao declarou a accao de usar item")
		return false
	# Dano apenas de fixture para o frasco poder ser usado; o valor de cura e
	# todo lido pelo Player a partir dos dados reais.
	var health_before := _player.health
	var state_before := _player.state
	var flask_before := _player.flask_uses
	_player.health = _player.max_health / 2.0
	await _press_through_physics(use_action)
	var visible_feedback := String(_quick_slots.call("visible_item_feedback"))
	if _player.flask_uses != flask_before or visible_feedback == "" \
			or visible_feedback != String(_quick_slots.get("_last_item_feedback")):
		_fail("usar a ranhura vazia bebeu outro item ou nao explicou na propria caixa")
		return false
	var hotbar_action := actions[1]
	await _press_through_physics(hotbar_action)
	_quick_slots.call("_refresh")
	var selected: Dictionary = _quick_slots.call("visible_item_snapshot") as Dictionary
	if String(selected.get("key", "")) != QuickSlotsModel.FLASK_ITEM_KEY \
			or String(selected.get("select_action", "")) != hotbar_action \
			or not bool(_quick_slots.visible):
		_fail("carregar no segundo atalho nao mudou a caixa visivel: indice=%d key=%s acao=%s visivel=%s input=%s" % [
			int(_quick_slots.get("_selected_item_index")), String(selected.get("key", "")),
			String(selected.get("select_action", "")), str(_quick_slots.visible),
			str(_player.input_enabled)])
		return false
	await _press_through_physics(use_action)
	_quick_slots.call("_refresh")
	var used: Dictionary = _quick_slots.call("visible_item_snapshot") as Dictionary
	if _player.flask_uses != flask_before - 1 \
			or int(used.get("count", flask_before)) != _player.flask_uses \
			or String(used.get("key", "")) != QuickSlotsModel.FLASK_ITEM_KEY:
		_fail("usar item nao gastou o frasco seleccionado nem actualizou a contagem visivel")
		return false
	_player.health = health_before
	_player.flask_uses = flask_before
	_player.call("_change_state", state_before)
	_quick_slots.call("_refresh")
	print("[repro] acesso rapido: mochila -> atalho %s -> %s usou o frasco visivel" % [
		SettingsSystem.binding_label(hotbar_action), SettingsSystem.binding_label(use_action)])
	return true


func _prove_equipped_weapon_attack() -> void:
	var runtime := _gameplay.get("necromancy_runtime") as NecromancyRuntime
	while is_instance_valid(runtime) and runtime.summon_count() == 0:
		await get_tree().physics_frame
	if not is_instance_valid(runtime):
		_fail("o runtime desapareceu antes da prova da arma")
		return
	var boss := _gameplay.get("boss") as Enemy
	var hud := _gameplay.get("hud") as Hud
	var boss_bar := hud.get("_boss_bar") as ColorRect if hud != null else null
	if boss == null or boss_bar == null:
		_fail("a cena real nao forneceu boss e barra visivel para provar a arma")
		return
	if not boss is BossVorgar:
		_fail("o marcador final continua a criar Enemy em vez de BossVorgar")
		return
	var attack_action := _configured_action("attack")
	if attack_action == "":
		_fail("controls.json nao declarou a accao de ataque")
		return
	var weapon := GameData.weapon(_player.main_weapon)
	var light: Dictionary = weapon.get("light", {}) as Dictionary
	if weapon.is_empty() or light.is_empty():
		_fail("a arma equipada nao tem ataque leve nos dados")
		return
	var boss_health_before := boss.health
	boss.set_physics_process(false)
	boss.global_position = _player.global_position \
		- _player.global_transform.basis.z * float(weapon.get("range")) / 2.0
	await get_tree().process_frame
	var bar_width_before := boss_bar.size.x
	await _press_through_physics(attack_action)
	var frames_to_hit := int(light.get("startup")) + int(light.get("active"))
	for _frame: int in frames_to_hit:
		await get_tree().physics_frame
	await get_tree().process_frame
	if boss.health >= boss_health_before or not boss_bar.visible \
			or boss_bar.size.x >= bar_width_before:
		_fail("o ataque real nao usou a arma nova nem reduziu a barra visivel do boss")
		return
	var riposte_mv := float(GameData.section("parry").get("riposte_mv"))
	var riposte_damage := GameData.compute_damage(
		riposte_mv, _player.main_weapon, _player.attrs, boss.defense)
	# A prova de necromancia que corre em paralelo exige exactamente o segundo
	# corpo comum que ela propria cria. Confirmamos o fio do boss para o runtime,
	# mas esta morte de fixture nao lhe acrescenta um terceiro corpo.
	var corpse_callback := Callable(runtime, "_on_enemy_died")
	if not boss.died.is_connected(corpse_callback):
		_fail("BossVorgar nao estava ligado ao runtime de necromancia real")
		return
	boss.died.disconnect(corpse_callback)
	boss.health = riposte_damage
	boss.on_parried()
	var attack_rules := GameData.section("attack_rules")
	var combo_wait := ceili(float(light.get("recovery")) * (1.0 \
		- float(attack_rules.get("combo_window_fraction_of_recovery"))))
	for _frame: int in combo_wait:
		await get_tree().physics_frame
	_player.stamina.refill()
	await _press_through_physics(attack_action)
	for _frame: int in int(light.get("recovery")):
		if not boss.is_alive():
			break
		await get_tree().physics_frame
	for _frame: int in int(light.get("active")):
		if not boss_bar.visible:
			break
		await get_tree().process_frame
		await get_tree().physics_frame
	if boss.is_alive() or boss_bar.visible:
		_fail("o ataque do jogador nao matou BossVorgar nem retirou a barra do ecra " \
			+ "(vivo=%s, barra=%s, estado=%s)" % [
				str(boss.is_alive()), str(boss_bar.visible), _player.state_name()])
		return
	# A morte foi observada; termina o riposte de fixture para devolver o mesmo
	# Player livre à prova de Levantar que continua nesta cena.
	_player.call("_change_state", Player.State.FREE)
	_player.set("_buffered", "")
	_restore_save_and_player()
	print("[repro] equipamento: %s chegou ao boneco, ao ataque e a barra do boss" % \
		_weapon_key)
	print("[repro] Vorgar: BossVorgar recebeu o ataque real, morreu e saiu do HUD")


func _restore_save_and_player() -> void:
	GameData.replace_save_state(_state_before)
	SaveSystem.save_current()
	InventorySystem.emit_signal("inventory_changed")
	EquipmentScreenScript.apply_state_to_gameplay(_gameplay, _state_before)


func _find_gameplay() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	for candidate: Node in scene.get_children():
		var script := candidate.get_script() as Script
		if script != null and script.resource_path == "res://src/main.gd":
			return candidate
	return null


func _catalogue_test_weapon_key() -> String:
	var ids: Array[String] = []
	for id_value: Variant in GameData.weapons.keys():
		var weapon_id := String(id_value)
		if not weapon_id.begins_with("_"):
			ids.append(weapon_id)
	ids.sort()
	for weapon_id: String in ids:
		var data := GameData.weapon(weapon_id)
		if weapon_id != _player.main_weapon \
				and String(data.get("slot", "main")) != "offhand" \
				and not (data.get("light", {}) as Dictionary).is_empty() \
				and float(data.get("range", 0.0)) > 0.0:
			return "arma:%s" % weapon_id
	return ""


func _metadata_index(list: ItemList, wanted: String) -> int:
	for index: int in list.item_count:
		if String(list.get_item_metadata(index)) == wanted:
			return index
	return -1


func _button_with_text(root: Node, wanted: String) -> Button:
	for candidate: Node in root.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.text == wanted:
			return button
	return null


func _configured_action(action: String) -> String:
	var actions: Dictionary = GameData.controls.get("actions", {}) as Dictionary
	return action if actions.has(action) and InputMap.has_action(action) else ""


func _press_through_physics(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	# Mantem a tecla premida ate todos os _physics_process desse frame a terem
	# observado, independentemente da ordem do sinal physics_frame no runner.
	await get_tree().process_frame
	Input.action_release(action)


func _inventory(state: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	return character.get("inventory", {}) as Dictionary


func _exit_tree() -> void:
	# repro-inicio limpa antes de quit(), mas Main._exit_tree() grava de novo o
	# slot activo. Como este nó vive num autoload, sai depois da cena e remove
	# exclusivamente ficheiros ainda identificados como perfis de reproducao.
	for slot: int in [0, 1, 2]:
		for path: String in [SaveSystem.slot_path(slot), "%s.bak" % SaveSystem.slot_path(slot)]:
			if _is_repro_save(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _is_repro_save(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var character: Dictionary = (parsed as Dictionary).get("character", {}) as Dictionary
	return String(character.get("profile_id", "")).begins_with("repro-")


func _fail(message: String) -> void:
	Input.action_release("use_item")
	for action: String in EquipmentScreenScript.quick_slot_actions():
		Input.action_release(action)
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_falhar"):
		scene.call("_falhar", "acesso rapido: %s" % message)
	else:
		push_error("[repro] FALHOU acesso rapido: %s" % message)
		get_tree().quit(1)
