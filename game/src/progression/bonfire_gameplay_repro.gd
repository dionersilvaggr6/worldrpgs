extends Node
## Reproducao jogavel da fogueira. Instancia a mesma cena que JOGAR.bat,
## carrega na accao configurada e observa apenas resultados apresentados pelo
## jogo. Recusa correr sem um user:// isolado para nunca tocar nos saves reais.

const GAMEPLAY := preload("res://scenes/gameplay.tscn")

var _passed := 0
var _failed := 0
var _isolated_user_dir := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _test_user_dir_is_isolated():
		await _finish()
		return
	if not SaveSystem.new_game("bonfire-gameplay-repro", "warrior", 0, {
			"name": "Fogueira", "appearance": {},
		}):
		_fail("arranque: nao foi possivel criar o save isolado: %s" % SaveSystem.last_error)
		await _finish()
		return

	var game: Node = GAMEPLAY.instantiate()
	add_child(game)
	for _frame: int in 4:
		await get_tree().physics_frame

	var player := game.get("player") as Player
	var rest := game.get_node_or_null("Rest_brumal_clareira") as Node3D
	var enemy := _first_common_enemy()
	_check(player != null and rest != null and enemy != null,
		"cena real: monta jogador, fogueira e inimigo comum")
	if player == null or rest == null or enemy == null:
		await _finish()
		return

	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		candidate.set_physics_process(false)
	player.health = player.max_health / float(maxi(player.flask_max, 1))
	player.flask_uses = 0
	enemy.set_meta("placement_id", "brumal:repro_producao")
	enemy.take_damage(DamageInfo.make(enemy.health + enemy.max_health, player, "light"))
	await get_tree().process_frame
	_check(not enemy.is_alive(), "jogador: mata um inimigo antes de descansar")

	# O corpo percorre o ultimo troco ate ao circulo de interaccao. A posicao
	# inicial da cena ja nasce ao lado deste descanso; os frames de movimento
	# exercitam a entrada publica em vez de chamar _rest_at().
	player.global_position = rest.global_position + Vector3(0.0,
		player.global_position.y - rest.global_position.y, 1.0)
	Input.action_press("move_back")
	for _frame: int in 8:
		await get_tree().physics_frame
	Input.action_release("move_back")
	Input.action_press("move_forward")
	for _frame: int in 8:
		await get_tree().physics_frame
	Input.action_release("move_forward")

	Input.action_press("interact")
	await get_tree().process_frame
	Input.action_release("interact")
	for _frame: int in 3:
		await get_tree().physics_frame

	_check(is_equal_approx(player.health, player.max_health),
		"resultado visivel: a barra de vida fica cheia")
	_check(player.flask_uses == player.flask_max,
		"resultado visivel: os frascos ficam repostos")
	_check(enemy.is_alive(),
		"resultado visivel: o inimigo derrotado esta vivo outra vez")
	var production_respawns: Dictionary = ((GameData.save_state.get(
		"world", {}) as Dictionary).get("enemy_respawns", {}) as Dictionary)
	_check(int(production_respawns.get("brumal:repro_producao", 0)) == 1,
		"save: a reposicao real gasta uma das dez vidas da colocacao")
	var animation := _current_player_animation(player)
	_check(animation == "Sitting_Idle",
		"resultado visivel: o jogador fica sentado (actual: %s)" % animation)
	var level_screen := _visible_level_screen(game)
	_check(level_screen != null,
		"resultado visivel: o ecrã de subir de nivel abre no descanso")
	var checkpoint: Dictionary = ((GameData.save_state.get("character", {}) as Dictionary).get(
		"checkpoint", {}) as Dictionary)
	_check(String(checkpoint.get("rest_point_id", "")) == "brumal_clareira",
		"save: descansar grava a fogueira como ponto de regresso")
	var production_bonfire := _find_bonfire_controller(game)
	_check(production_bonfire != null,
		"fio: a cena real instancia o controlador Bonfire")
	if production_bonfire == null:
		await _prove_controller_after_explicit_wiring(game, player, rest, enemy)
	await _finish()


func _prove_controller_after_explicit_wiring(game: Node, player: Player,
		rest: Node3D, defeated_enemy: Enemy) -> void:
	# Esta fase nao conta como ligacao de producao: torna explicito quanto fica
	# verde assim que a casca acrescentar o controlador ao no Rest_*. O primeiro
	# bloco acima continua vermelho enquanto o jogador real nao receber esse fio.
	game.set_process(false)
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	for index: int in enemies.size():
		var candidate := enemies[index] as Node
		candidate.set_meta("placement_id", "brumal:repro_%d" % index)
	defeated_enemy.set_meta("placement_id", "brumal:repro_derrotado")
	defeated_enemy.take_damage(DamageInfo.make(
		defeated_enemy.health + defeated_enemy.max_health, player, "light"))
	await get_tree().process_frame
	player.health = player.max_health / float(maxi(player.flask_max, 1))
	player.flask_uses = 0

	var controller := Bonfire.new()
	controller.name = "BonfireControllerRepro"
	rest.add_child(controller)
	controller.configure("brumal", "brumal_clareira")
	Input.action_press(controller.input_action())
	var result := controller.process_input(player, enemies)
	await get_tree().process_frame
	Input.action_release(controller.input_action())
	for _frame: int in 3:
		await get_tree().physics_frame

	_check(String(result.get("status", "")) == "rested",
		"controlador ligado: interact executa a transaccao de descanso")
	_check(_current_player_animation(player) == "Sitting_Idle",
		"controlador ligado: o jogador fica visivelmente sentado")
	var screen := _visible_level_screen(game)
	_check(screen != null,
		"controlador ligado: reutiliza e abre LevelUpScreen")
	var respawns: Dictionary = ((GameData.save_state.get("world", {}) as Dictionary).get(
		"enemy_respawns", {}) as Dictionary)
	_check(int(respawns.get("brumal:repro_derrotado", 0)) == 1,
		"controlador ligado: grava a reposicao da colocacao")
	_check(not get_tree().paused,
		"co-op: o descanso nao pausa nem prende a arvore do parceiro")
	if screen != null:
		screen.close_screen()
		await get_tree().physics_frame
		_check(player.input_enabled,
			"descanso: fechar o ecrã levanta o jogador e devolve controlo")

	var lifecycle: Dictionary = (GameData.progression.get(
		"enemy_lifecycle", {}) as Dictionary)
	var respawn_limit := int(lifecycle.get("respawns_per_placement", 0))
	for _respawn_index: int in range(1, respawn_limit):
		defeated_enemy.take_damage(DamageInfo.make(
			defeated_enemy.health + defeated_enemy.max_health, player, "light"))
		await get_tree().process_frame
		Input.action_press(controller.input_action())
		controller.process_input(player, enemies)
		await get_tree().process_frame
		Input.action_release(controller.input_action())
		await get_tree().physics_frame
		if controller.rest_menu_is_open():
			controller.close_rest_menu()
			await get_tree().physics_frame
	_check(defeated_enemy.is_alive(),
		"tecto: as primeiras %d reposicoes mantêm o inimigo no jogo" % respawn_limit)

	defeated_enemy.take_damage(DamageInfo.make(
		defeated_enemy.health + defeated_enemy.max_health, player, "light"))
	await get_tree().process_frame
	Input.action_press(controller.input_action())
	var exhausted_result := controller.process_input(player, enemies)
	await get_tree().process_frame
	Input.action_release(controller.input_action())
	await get_tree().physics_frame
	respawns = ((GameData.save_state.get("world", {}) as Dictionary).get(
		"enemy_respawns", {}) as Dictionary)
	_check(not defeated_enemy.is_alive()
		and int(respawns.get("brumal:repro_derrotado", 0)) == respawn_limit
		and (exhausted_result.get("exhausted", []) as Array).has(
			"brumal:repro_derrotado"),
		"tecto: a tentativa seguinte nao ressuscita o inimigo")
	controller.close_rest_menu()


func _test_user_dir_is_isolated() -> bool:
	var expected_root := OS.get_environment("WORLDRPGS_TEST_USER_ROOT")
	var actual_root := ProjectSettings.globalize_path("user://")
	var normalized_expected := expected_root.replace("\\", "/").trim_suffix("/")
	var normalized_actual := actual_root.replace("\\", "/")
	_isolated_user_dir = not normalized_expected.is_empty() \
		and normalized_actual.begins_with(normalized_expected + "/")
	_check(_isolated_user_dir, "seguranca: user:// pertence ao APPDATA temporario")
	return _isolated_user_dir


func _first_common_enemy() -> Enemy:
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Enemy
		if enemy != null and enemy.is_alive() and not enemy.is_boss:
			return enemy
	return null


func _current_player_animation(player: Player) -> String:
	var visual := player.get("_visual") as Node
	return String(visual.get("_current_animation")) if visual != null else ""


func _visible_level_screen(root_node: Node) -> LevelUpScreen:
	for candidate: Node in root_node.find_children("*", "LevelUpScreen", true, false):
		var screen := candidate as LevelUpScreen
		if screen != null and screen.visible:
			return screen
	return null


func _find_bonfire_controller(root_node: Node) -> Bonfire:
	for candidate: Node in root_node.find_children("*", "Bonfire", true, false):
		var bonfire := candidate as Bonfire
		if bonfire != null:
			return bonfire
	return null


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % description)
	else:
		_failed += 1
		printerr("  FALHA %s" % description)


func _fail(description: String) -> void:
	_check(false, description)


func _finish() -> void:
	Input.action_release("move_back")
	Input.action_release("move_forward")
	Input.action_release("interact")
	_cleanup_test_save()
	for child: Node in get_children():
		child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("\n=== FOGUEIRA NO JOGO: %d passaram, %d falharam ===\n" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _cleanup_test_save() -> void:
	if not _isolated_user_dir:
		return
	for suffix: String in ["", ".bak", ".tmp", ".corrupt"]:
		var path := SaveSystem.slot_path(0) + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
