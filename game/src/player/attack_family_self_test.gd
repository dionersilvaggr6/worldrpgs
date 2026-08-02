extends SceneTree
## Contrato dos golpes do jogador + prova da geometria inimiga no jogo real.
##
## Corre sem editar o agregador que pertence a outro agente:
## godot --headless --audio-driver Dummy --path game/ --script res://src/player/attack_family_self_test.gd

const CONTROLLER_PATH := "res://src/player/attack_animation_controller.gd"
const GAMEPLAY_PATH := "res://scenes/gameplay.tscn"
const AttackCoordinator = preload("res://src/ai/enemy_attack_coordinator.gd")
const CONTROL_TRIALS := 10
const TECHNICAL_SAVE_SLOT := 99

class MockAttackActor extends Node3D:
	var state_frame := 0
	var _atk_weapon := "longsword"
	var _atk_kind := "light"
	var _combo_index := 1
	var _sprinting := false
	var _charging := false
	var _charge_frames := 0
	var _atk: Dictionary = {}

	func state_name() -> String:
		return "ataque"

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var weapon_data := _read_json("res://data/weapons.json")
	var family_ids := PackedStringArray()
	for family_value: Variant in (weapon_data.get("familias", {}) as Dictionary).keys():
		var family_id := String(family_value)
		if not family_id.begins_with("_"):
			family_ids.append(family_id)
	family_ids.sort()

	var controller_script := load(CONTROLLER_PATH) as Script
	_check(controller_script != null, "controlador de animacao dos golpes existe")
	if controller_script != null:
		var controller := controller_script.new() as Node
		var declarations: Dictionary = controller.call("declared_family_animations") as Dictionary
		for family_id: String in family_ids:
			_check(declarations.has(family_id), "%s declara animacoes" % family_id)
		_test_generated_motion(controller, declarations)
		await _test_playback_api(controller_script, weapon_data)
		await _test_runtime_arbitration(controller_script, weapon_data)
		controller.free()
	await _test_real_game_damage_geometry()

	print("\n=== GOLPES POR FAMILIA: %d passaram, %d falharam ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_real_game_damage_geometry() -> void:
	var game_data := root.get_node_or_null("GameData")
	var save_system := root.get_node_or_null("SaveSystem")
	if game_data == null or save_system == null:
		_check(false, "autoloads do jogo existem na prova real")
		return
	var previous_state := game_data.call("save_state_snapshot") as Dictionary
	var previous_slot := int(save_system.get("active_slot"))
	var previous_scene := current_scene
	# Se o motor cair, Main nunca pode gravar por cima dos tres slots jogaveis.
	_delete_geometry_proof_files(save_system)
	save_system.set("active_slot", TECHNICAL_SAVE_SLOT)
	game_data.call("replace_save_state", save_system.call("create_save",
		"geometry-proof", "warrior", {"name": "Geometria", "appearance": {}}))
	var fresh_start := _start_gameplay_in_fresh_process()
	var compile_log := String(fresh_start.get("log", ""))
	var gameplay_compiled := int(fresh_start.get("exit_code", -1)) == 0 \
		and "SCRIPT ERROR:" not in compile_log \
		and "Failed to load script" not in compile_log
	_check(gameplay_compiled,
		"cena de gameplay real arranca com Main compilado")
	if not gameplay_compiled:
		printerr(compile_log)
		_delete_geometry_proof_files(save_system)
		game_data.call("replace_save_state", previous_state)
		save_system.set("active_slot", previous_slot)
		return
	var gameplay_scene := load(GAMEPLAY_PATH) as PackedScene
	_check(gameplay_scene != null, "cena de gameplay real e importavel")
	if gameplay_scene == null:
		_delete_geometry_proof_files(save_system)
		game_data.call("replace_save_state", previous_state)
		save_system.set("active_slot", previous_slot)
		return
	var gameplay := gameplay_scene.instantiate()
	root.add_child(gameplay)
	current_scene = gameplay
	for _frame: int in 3:
		await physics_frame

	var player := gameplay.get("player") as Node3D
	var hud := gameplay.get("hud") as Node
	var enemy: Node3D
	for node: Node in get_nodes_in_group("enemies"):
		var candidate := node as Node3D
		if candidate == null or bool(candidate.get("is_boss")) \
				or not bool(candidate.call("is_alive")):
			continue
		candidate.set_physics_process(false)
		if enemy == null:
			enemy = candidate
	if player == null or hud == null or enemy == null:
		_check(false, "jogo real cria jogador, HUD e inimigo para provar a geometria")
		_cleanup_gameplay_proof(gameplay, game_data, save_system,
			previous_state, previous_slot, previous_scene)
		return

	var attack := _first_declared_weapon_attack(enemy)
	if attack.is_empty():
		_check(false, "inimigo real declara um golpe de arma com alcance")
		_cleanup_gameplay_proof(gameplay, game_data, save_system,
			previous_state, previous_slot, previous_scene)
		return

	player.set("input_enabled", true)
	player.set_physics_process(true)
	enemy.set("target", player)
	var camera := player.get("camera") as Node3D
	if camera != null:
		camera.rotation = Vector3.ZERO
	var free_state := int(player.get("state"))
	var arena_point := enemy.global_position
	enemy.rotation = Vector3.ZERO
	var declared_reach := float(attack.get("range"))
	var hidden_reach := declared_reach + float(enemy.get("body_radius"))
	var contact_point := arena_point + Vector3.FORWARD * declared_reach * 0.5
	var health_bar := hud.get("_health") as ColorRect
	_check(health_bar != null, "jogo real apresenta a barra de vida observavel")
	if health_bar == null:
		_cleanup_gameplay_proof(gameplay, game_data, save_system,
			previous_state, previous_slot, previous_scene)
		return

	await _reset_player_trial(player, free_state, arena_point + Vector3.FORWARD * (
		lerpf(declared_reach, hidden_reach, 0.5)))
	player.global_position = enemy.global_position + Vector3.FORWARD * (
		lerpf(declared_reach, hidden_reach, 0.5))
	_begin_observed_enemy_attack(enemy, attack, arena_point)
	await process_frame
	if "--capture-geometry" in OS.get_cmdline_user_args():
		var proof_position := player.global_position
		player.global_position += Vector3.RIGHT * declared_reach
		await _capture_geometry_if_requested(camera, enemy)
		player.global_position = proof_position
	var visible_health_before := health_bar.size.x
	await _run_enemy_until_after_strike(enemy, attack)
	await _wait_process(2)
	_check(is_equal_approx(health_bar.size.x, visible_health_before),
		"jogo real: golpe para alem da forma visivel nao reduz a barra de vida")
	await _reset_player_trial(player, free_state, contact_point)
	_begin_observed_enemy_attack(enemy, attack, arena_point)
	var removed_cue := enemy.get("_active_gameplay_cue") as Node
	if removed_cue != null:
		removed_cue.free()
	visible_health_before = health_bar.size.x
	await _run_enemy_until_after_strike(enemy, attack)
	await _wait_process(2)
	_check(is_equal_approx(health_bar.size.x, visible_health_before),
		"jogo real: sem forma visivel nao existe dano alternativo")

	var lateral_misses := 0
	for _trial: int in CONTROL_TRIALS:
		await _reset_player_trial(player, free_state, contact_point)
		_begin_observed_enemy_attack(enemy, attack, arena_point)
		var before := health_bar.size.x
		Input.action_press("move_right")
		enemy.set_physics_process(true)
		await _wait_physics(int(attack.get("startup")) + int(attack.get("active")) + 1)
		enemy.set_physics_process(false)
		Input.action_release("move_right")
		await _wait_process(2)
		if is_equal_approx(health_bar.size.x, before):
			lateral_misses += 1
	_check(lateral_misses == CONTROL_TRIALS,
		"jogo real: move_right faz o golpe passar ao lado 10/10 sem perder barra")

	var dodge := game_data.call("section", "dodge") as Dictionary
	var correct_dodges := 0
	for _trial: int in CONTROL_TRIALS:
		await _reset_player_trial(player, free_state, contact_point)
		_begin_observed_enemy_attack(enemy, attack, arena_point)
		var before := health_bar.size.x
		var pre_dodge_frames := maxi(int(attack.get("startup")) \
			- int(dodge.get("iframe_start_frame")) - 2, 0)
		enemy.set_physics_process(true)
		await _wait_physics(pre_dodge_frames)
		await _tap_action("dodge_sprint")
		player.global_position = contact_point
		player.set("velocity", Vector3.ZERO)
		await _wait_physics(int(attack.get("startup")) + 2 \
			- pre_dodge_frames - 2)
		enemy.set_physics_process(false)
		await _wait_process(2)
		if is_equal_approx(health_bar.size.x, before):
			correct_dodges += 1
	_check(correct_dodges == CONTROL_TRIALS,
		"jogo real: esquiva no momento visivel evita o golpe 10/10")

	var early_hits := 0
	for _trial: int in CONTROL_TRIALS:
		await _reset_player_trial(player, free_state, contact_point)
		_begin_observed_enemy_attack(enemy, attack, arena_point)
		var before := health_bar.size.x
		enemy.set_physics_process(true)
		await _tap_action("dodge_sprint")
		await _wait_physics(maxi(int(attack.get("startup")) - 2, 0))
		player.global_position = contact_point
		player.set("velocity", Vector3.ZERO)
		await _wait_physics(2)
		enemy.set_physics_process(false)
		await _wait_process(2)
		if health_bar.size.x < before:
			early_hits += 1
	_check(early_hits == CONTROL_TRIALS,
		"jogo real: esquiva cedo demais recebe o golpe visivel %d/10" % early_hits)

	var late_hits := 0
	for _trial: int in CONTROL_TRIALS:
		await _reset_player_trial(player, free_state, contact_point)
		_begin_observed_enemy_attack(enemy, attack, arena_point)
		var before := health_bar.size.x
		enemy.set_physics_process(true)
		await _wait_physics(int(attack.get("startup")) + 2)
		enemy.set_physics_process(false)
		await _tap_action("dodge_sprint")
		await _wait_process(2)
		if health_bar.size.x < before:
			late_hits += 1
	_check(late_hits == CONTROL_TRIALS,
		"jogo real: esquiva tarde demais recebe o golpe visivel 10/10")
	Input.action_release("move_right")
	Input.action_release("dodge_sprint")
	_cleanup_gameplay_proof(gameplay, game_data, save_system,
		previous_state, previous_slot, previous_scene)


func _first_declared_weapon_attack(enemy: Node) -> Dictionary:
	var enemy_data := enemy.get("data") as Dictionary
	for value: Variant in enemy_data.get("attacks", []):
		var attack := value as Dictionary
		if attack.has("range") and not bool(attack.get("is_aoe", false)):
			return attack
	return {}


func _begin_observed_enemy_attack(enemy: Node3D, attack: Dictionary,
		arena_point: Vector3) -> void:
	enemy.set_physics_process(false)
	enemy.global_position = arena_point
	enemy.rotation = Vector3.ZERO
	enemy.set("velocity", Vector3.ZERO)
	enemy.call("_begin_attack", attack)


func _run_enemy_until_after_strike(enemy: Node, attack: Dictionary) -> void:
	enemy.set_physics_process(true)
	await _wait_physics(int(attack.get("startup")) + int(attack.get("active")) + 1)
	enemy.set_physics_process(false)


func _reset_player_trial(player: Node3D, free_state: int,
		position: Vector3) -> void:
	Input.action_release("move_right")
	Input.action_release("dodge_sprint")
	player.set("health", float(player.get("max_health")))
	player.set("hitstop_frames", 0)
	player.set("velocity", Vector3.ZERO)
	player.global_position = position
	var stamina := player.get("stamina") as RefCounted
	if stamina != null:
		stamina.call("refill")
	player.call("_change_state", free_state)
	AttackCoordinator.forget_target(player)
	await _wait_process(2)


func _tap_action(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _wait_physics(frames: int) -> void:
	for _frame: int in maxi(frames, 0):
		await physics_frame


func _wait_process(frames: int) -> void:
	for _frame: int in maxi(frames, 0):
		await process_frame


func _start_gameplay_in_fresh_process() -> Dictionary:
	var isolated_root := OS.get_temp_dir().path_join(
		"worldrpgs-geometry-startup-%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(isolated_root)
	var environment_names := PackedStringArray(["APPDATA", "WORLDRPGS_TEST_USER_ROOT"])
	var previous_environment := {}
	for environment_name: String in environment_names:
		previous_environment[environment_name] = {
			"exists": OS.has_environment(environment_name),
			"value": OS.get_environment(environment_name),
		}
		OS.set_environment(environment_name, isolated_root)
	var output := []
	var exit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless", "--audio-driver", "Dummy", "--path",
		ProjectSettings.globalize_path("res://"), "--quit-after", "2", GAMEPLAY_PATH,
	]), output, true)
	for environment_name: String in environment_names:
		var previous: Dictionary = previous_environment[environment_name] as Dictionary
		if bool(previous.get("exists", false)):
			OS.set_environment(environment_name, String(previous.get("value", "")))
		else:
			OS.unset_environment(environment_name)
	var log := ""
	for line: String in output:
		log += line
	_remove_isolated_tree(isolated_root)
	return {"exit_code": exit_code, "log": log}


func _remove_isolated_tree(path: String) -> void:
	var temp_root := OS.get_temp_dir().simplify_path()
	var safe_path := path.simplify_path()
	if safe_path.get_base_dir() != temp_root \
			or not safe_path.get_file().begins_with("worldrpgs-geometry-startup-"):
		_check(false, "limpeza da prova fica confinada a pasta temporaria propria")
		return
	if not DirAccess.dir_exists_absolute(safe_path):
		return
	var directory := DirAccess.open(safe_path)
	if directory == null:
		_check(false, "pasta temporaria da prova pode ser limpa")
		return
	for file_name: String in directory.get_files():
		DirAccess.remove_absolute(safe_path.path_join(file_name))
	for directory_name: String in directory.get_directories():
		_remove_isolated_tree_contents(safe_path.path_join(directory_name))
	DirAccess.remove_absolute(safe_path)


func _remove_isolated_tree_contents(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for directory_name: String in directory.get_directories():
		_remove_isolated_tree_contents(path.path_join(directory_name))
	DirAccess.remove_absolute(path)


func _capture_geometry_if_requested(camera: Node3D, enemy: Node3D) -> void:
	if "--capture-geometry" not in OS.get_cmdline_user_args():
		return
	var previous_pitch: Variant = camera.get("_pitch") if camera != null else null
	if camera != null:
		camera.set("lock_target", enemy)
		camera.set("_pitch", -0.55)
	await _wait_physics(12)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var relative_path := "res://captures/geometria-honesta.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures"))
	var error := image.save_png(relative_path)
	if error != OK:
		_check(false, "captura da geometria visivel foi escrita")
	else:
		print("[geometria] captura: %s" % relative_path)
	if camera != null:
		camera.set("lock_target", null)
		camera.set("_pitch", previous_pitch)


func _cleanup_gameplay_proof(gameplay: Node, game_data: Node, save_system: Node,
		previous_state: Dictionary, previous_slot: int, previous_scene: Node) -> void:
	# Main grava no _exit_tree; esvaziar primeiro impede que a prova toque em
	# qualquer dos tres slots partilhados pelo Mateus e pelas outras arvores.
	game_data.call("replace_save_state", {})
	current_scene = previous_scene
	gameplay.free()
	_delete_geometry_proof_files(save_system)
	game_data.call("replace_save_state", previous_state)
	save_system.set("active_slot", previous_slot)


func _delete_geometry_proof_files(save_system: Node) -> void:
	var path := String(save_system.call("slot_path", TECHNICAL_SAVE_SLOT))
	for candidate: String in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(candidate))
		var state := parsed as Dictionary if parsed is Dictionary else {}
		var character: Dictionary = state.get("character", {}) as Dictionary
		if String(character.get("profile_id", "")) != "geometry-proof":
			_check(false, "slot tecnico 99 pertence a outro processo; nao foi apagado")
			continue
		DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _test_generated_motion(controller: Node, declarations: Dictionary) -> void:
	_check(controller.has_method("build_attack_animation"),
		"controlador sintetiza curvas de ossos, nao apenas velocidades")
	if not controller.has_method("build_attack_animation"):
		return
	var equipment := _read_json("res://data/equipment.json")
	var movesets: Dictionary = equipment.get("family_movesets", {}) as Dictionary
	var packed := load("res://assets/models/animations/quaternius/UAL1_Standard.glb") as PackedScene
	_check(packed != null, "biblioteca UAL CC0 e importavel")
	if packed == null:
		return
	var source_root := packed.instantiate()
	var source_player := _find_animation_player(source_root)
	_check(source_player != null, "biblioteca UAL expoe AnimationPlayer")
	if source_player == null:
		source_root.free()
		return
	for family_id: String in declarations:
		var family: Dictionary = declarations[family_id] as Dictionary
		_check(String((family.get("em_corrida", {}) as Dictionary).get("source_clip", "")) \
			!= String((family.get("leve_1", {}) as Dictionary).get("source_clip", "")),
			"%s/corrida traz locomocao, nao e o leve acelerado" % family_id)
		var signatures := {}
		for action_id: String in ["leve_1", "leve_2", "pesado", "em_corrida"]:
			_check(family.has(action_id), "%s/%s: declarada" % [family_id, action_id])
			if not family.has(action_id):
				continue
			var profile: Dictionary = family[action_id] as Dictionary
			var source_clip := String(profile.get("source_clip", ""))
			_check(source_player.has_animation(source_clip),
				"%s/%s: clip-base '%s' existe na UAL" % [family_id, action_id, source_clip])
			if not source_player.has_animation(source_clip):
				continue
			var moveset: Dictionary = movesets.get(family_id, {}) as Dictionary
			var attack_key := "pesado" if action_id == "pesado" else "leve"
			var attack: Dictionary = moveset.get(attack_key, {}) as Dictionary
			var generated := controller.call("build_attack_animation",
				source_player.get_animation(source_clip), family_id, action_id, attack) as Animation
			_check(generated != null, "%s/%s: gera Animation" % [family_id, action_id])
			if generated != null:
				_check(_has_exact_attack_window_keys(generated, attack),
					"%s/%s: arco ofensivo usa os limites dos dados" % [family_id, action_id])
				signatures[_rotation_signature(generated)] = true
		_check(signatures.size() == 4,
			"%s: leve 1, leve 2, pesado e corrida movem ossos de quatro formas" % family_id)
	source_root.free()


func _test_playback_api(controller_script: Script, weapon_data: Dictionary) -> void:
	var controller := controller_script.new() as Node
	_check(controller.has_method("setup") and controller.has_method("play_attack"),
		"Player recebe uma API pequena para ligar os golpes")
	if not controller.has_method("setup") or not controller.has_method("play_attack"):
		controller.free()
		return
	var actor := Node3D.new()
	root.add_child(actor)
	var visual := CharacterVisual.new()
	actor.add_child(visual)
	var combat := _read_json("res://data/combat.json")
	visual.setup(float((combat.get("player", {}) as Dictionary).get("capsule_height", 0.0)),
		Color.WHITE, false, "body_male", "warrior")
	actor.add_child(controller)
	_check(bool(controller.call("setup", actor, visual)),
		"controlador liga-se ao AnimationPlayer Quaternius")
	var weapon: Dictionary = weapon_data.get("longsword", {}) as Dictionary
	var played := PackedStringArray()
	for request: Dictionary in [
			{"kind": "light", "combo": 1, "running": false},
			{"kind": "light", "combo": 2, "running": false},
			{"kind": "heavy", "combo": 0, "running": false},
			{"kind": "light", "combo": 1, "running": true}]:
		var attack_key := "heavy" if String(request["kind"]) == "heavy" else "light"
		var played_name := String(controller.call("play_attack", "longsword",
			String(request["kind"]), int(request["combo"]), bool(request["running"]),
			weapon.get(attack_key, {}) as Dictionary))
		_check(not played_name.is_empty(), "playback aceita %s" % str(request))
		played.append(played_name)
	_check(_unique_strings(played) == played.size(),
		"leve 1, leve 2, pesado e corrida tocam recursos diferentes")
	var charged_attack: Dictionary = (weapon_data.get("greataxe", {}) as Dictionary).get(
		"heavy", {}) as Dictionary
	controller.call("play_attack", "greataxe", "heavy", 0, false, charged_attack)
	var animation_player := _find_animation_player(visual)
	var charge_start := int(charged_attack.get("startup", 0))
	controller.call("_sync_charge_hold", charge_start, charged_attack, true)
	_check(animation_player != null and not animation_player.is_playing(),
		"pesado carregado congela a animacao no fim do aviso")
	if animation_player != null:
		var ticks_per_second := float(ProjectSettings.get_setting(
			"physics/common/physics_ticks_per_second"))
		_check(is_equal_approx(animation_player.current_animation_position,
			float(charge_start) / ticks_per_second),
			"pose carregada fica exactamente no limite de startup")
	controller.call("_sync_charge_hold", charge_start, charged_attack, false)
	_check(animation_player != null and animation_player.is_playing(),
		"largar o pesado retoma o arco ofensivo")
	await process_frame
	actor.free()


func _test_runtime_arbitration(controller_script: Script, weapon_data: Dictionary) -> void:
	var actor := MockAttackActor.new()
	root.add_child(actor)
	var visual := CharacterVisual.new()
	actor.add_child(visual)
	var combat := _read_json("res://data/combat.json")
	visual.setup(float((combat.get("player", {}) as Dictionary).get("capsule_height", 0.0)),
		Color.WHITE, false, "body_male", "warrior")
	var controller := controller_script.new() as Node
	actor.add_child(controller)
	controller.call("setup", actor, visual)
	actor._atk = (weapon_data.get("longsword", {}) as Dictionary).get("light", {}) as Dictionary
	controller.call("_process", 0.0)
	var animation_player := _find_animation_player(visual)
	var first_playback: String = animation_player.assigned_animation \
		if animation_player != null else ""
	_check(first_playback.begins_with("weapon_attacks/"),
		"estado ATTACK escolhe o recurso da familia")

	actor.state_frame = int(actor._atk.get("startup", 0)) + 1
	visual.play_animation("Sword_Attack")
	controller.call("_process", 0.0)
	_check(animation_player != null and animation_player.assigned_animation == first_playback,
		"controlador vence o Sword_Attack generico do Player sem reiniciar o golpe")
	if animation_player != null:
		var ticks_per_second := float(ProjectSettings.get_setting(
			"physics/common/physics_ticks_per_second"))
		_check(is_equal_approx(animation_player.current_animation_position,
			float(actor.state_frame) / ticks_per_second),
			"pose visual segue o state_frame autoritativo")

	actor.state_frame = 0
	actor._sprinting = true
	controller.call("_process", 0.0)
	var running_playback: String = animation_player.assigned_animation \
		if animation_player != null else ""
	actor.state_frame = 1
	actor._sprinting = false
	visual.play_animation("Sword_Attack")
	controller.call("_process", 0.0)
	_check(animation_player != null and animation_player.assigned_animation == running_playback \
		and "em_corrida" in running_playback,
		"corrida fica presa ao inicio do golpe mesmo depois de largar Space")
	await process_frame
	actor.free()


func _has_exact_attack_window_keys(animation: Animation, attack: Dictionary) -> bool:
	var ticks_per_second := float(ProjectSettings.get_setting(
		"physics/common/physics_ticks_per_second"))
	var startup_s := float(int(attack.get("startup", 0))) / ticks_per_second
	var active_end_s := float(int(attack.get("startup", 0)) \
		+ int(attack.get("active", 0))) / ticks_per_second
	for track: int in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		if not String(animation.track_get_path(track)).ends_with(":upperarm_r"):
			continue
		var has_startup := false
		var has_active_end := false
		for key: int in animation.track_get_key_count(track):
			var time := animation.track_get_key_time(track, key)
			has_startup = has_startup or is_equal_approx(time, startup_s)
			has_active_end = has_active_end or is_equal_approx(time, active_end_s)
		return has_startup and has_active_end
	return false


func _unique_strings(values: PackedStringArray) -> int:
	var unique := {}
	for value: String in values:
		unique[value] = true
	return unique.size()


func _rotation_signature(animation: Animation) -> String:
	var values := PackedStringArray()
	for track: int in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var path := String(animation.track_get_path(track))
		if not ("spine_03" in path or "upperarm_" in path or "lowerarm_" in path):
			continue
		values.append(path)
		for key: int in animation.track_get_key_count(track):
			values.append(str(animation.track_get_key_value(track, key)))
	return "|".join(values)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok    ", label)
	else:
		_failed += 1
		printerr("  FALHA ", label)
