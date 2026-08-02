extends "res://src/tests/self_test.gd"
## Guarda de integração: antes dos contratos puros, arranca a cena jogável e
## observa a apresentação que chega ao ecrã. O estado fica só em memória e é
## limpo antes de libertar o jogo, para nunca tocar nos saves do Mateus/Rico.

const GAMEPLAY := preload("res://scenes/gameplay.tscn")


func _ready() -> void:
	_test_world_bounds_suite()
	await _test_integrations_in_real_game()
	super._ready()


func _test_world_bounds_suite() -> void:
	var result := BoundsSelfTest.run_suite()
	var failures: Array = result.get("failures", []) as Array
	_check(failures.is_empty(),
		"VERIFICAR inclui as faixas segura, dano e mortal dos limites verticais")


func _test_integrations_in_real_game() -> void:
	var previous_state := GameData.save_state_snapshot()
	var previous_slot := SaveSystem.active_slot
	var previous_scene := Bench.scene_arg
	var state := SaveSystem.create_save("selftest-integrador", "warrior", {
		"name": "Prova visual",
		"appearance": (GameData.appearance.get("default", {}) as Dictionary).duplicate(true),
	})
	InventorySystem.normalise_state(state)
	GameData.replace_save_state(state)
	Bench.scene_arg = "zone"

	var gameplay: Node = GAMEPLAY.instantiate()
	add_child(gameplay)
	for _frame: int in 4:
		await get_tree().physics_frame

	var actor := gameplay.get("player") as Player
	var armor := actor.get("_visual") as ArmorVisual if actor != null else null
	var weapon := actor.get_node_or_null("WeaponAttach") as WeaponAttach \
			if actor != null else null
	_check(armor != null and armor.equipped_piece_ids().has("couro_peitoral") \
			and armor.armor_mesh_count() > 0,
		"jogo real: Guerreiro aparece com peitoral vestido")
	_check(weapon != null and weapon.has_visible_weapon("longsword") \
			and weapon.visible_mesh_count() > 0,
		"jogo real: Guerreiro aparece com espada na mao")

	var world := gameplay.get("world") as Greybox
	var lair := world.get_node_or_null("Lair") as Lair if world != null else null
	var lair_audit := lair.audit() if lair != null else {}
	_check(lair != null and int(lair_audit.get("module_instances", 0)) > 0 \
			and int(lair_audit.get("collision_shapes", 0)) > 0,
		"jogo real: a Toca modular aparece no mundo e e navegavel")
	# ⚠️ 02-08: isto exigia um CORPO em cada marcador da Toca ao frame zero. A
	# populacao passou a ser virtualizada — todas as colocacoes existem no plano
	# e so as proximas do jogador recebem corpo, por causa do tecto de oito
	# actores animados (Lei 4). A Toca fica longe do arranque, logo os corpos
	# ainda nao existem, e o teste falhava por descrever o mundo antigo.
	#
	# ⭐ A garantia que interessa NAO mudou: cada marcador tem de ter uma
	# colocacao PLANEADA — e isso que se verifica agora, que ninguem se perdeu
	# no caminho.
	# ⛔ Nao voltar a exigir corpos aqui: obrigaria a instanciar a Toca inteira a
	# distancia e partia a Lei 4 so para pintar um teste de verde.
	# Ha DUAS maneiras legitimas de um marcador estar servido, e as duas contam:
	# o inimigo ja tem corpo no mundo, ou tem colocacao no plano da populacao
	# virtualizada. Exigir so uma delas era o que fazia este teste mentir.
	var populacao := gameplay.get_node_or_null("SpawnPopulation")
	var plano: Array = []
	if populacao != null:
		plano = populacao.call("plan_snapshot")
	var servidos := 0
	if lair != null:
		for marker: Marker3D in lair.get_enemy_markers():
			var alvo := Vector2(marker.global_position.x, marker.global_position.z)
			var servido := false
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				var enemy: Enemy = node as Enemy
				if enemy != null and gameplay.is_ancestor_of(enemy) 						and Vector2(enemy.global_position.x, enemy.global_position.z)							.distance_to(alvo) < maxf(enemy.body_radius * 2.0, 2.5):
					servido = true
					break
			if not servido:
				for colocacao: Dictionary in plano:
					var pos := colocacao.get("position", Vector3.ZERO) as Vector3
					if Vector2(pos.x, pos.z).distance_to(alvo) < 2.5:
						servido = true
						break
			if servido:
				servidos += 1
	_check(lair != null and servidos == lair.get_enemy_markers().size(),
		"jogo real: os marcadores da Toca tem encontro (com corpo ou planeado)")
	var world_environment := world.get_node_or_null("WorldEnvironment") as WorldEnvironment \
			if world != null else null
	_check(world_environment != null and world_environment.environment != null \
			and world_environment.environment.fog_enabled \
			and world_environment.environment.sky != null \
			and world_environment.has_meta("environment_atmosphere"),
		"jogo real: Brumal mostra a atmosfera integrada")
	_prove_monsters(gameplay)
	await _prove_first_boss_defeat(gameplay, actor)
	await _prove_network_hud(gameplay)
	await _prove_network_menu(gameplay, actor)

	# main.gd grava ao sair se existir estado. Esvaziar antes de remover o nó é
	# o que torna esta prova incapaz de ocupar ou alterar um slot real.
	GameData.replace_save_state({})
	remove_child(gameplay)
	gameplay.queue_free()
	await get_tree().process_frame
	GameData.replace_save_state(previous_state)
	SaveSystem.active_slot = previous_slot
	Bench.scene_arg = previous_scene


func _prove_monsters(gameplay: Node) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var visible_monsters := 0
	for node: Node in enemies:
		var enemy: Enemy = node as Enemy
		if enemy == null or not gameplay.is_ancestor_of(enemy):
			continue
		var visual := enemy.get("_visual") as MonsterVisual
		if visual != null and not visual.silhouette_signature().is_empty() \
				and not visual.find_children("*", "MeshInstance3D", true, false).is_empty():
			visible_monsters += 1
	_check(visible_monsters == enemies.filter(func(node: Node) -> bool:
		return node is Enemy and gameplay.is_ancestor_of(node)).size(),
		"jogo real: todos os inimigos usam MonsterVisual visivel")


func _prove_first_boss_defeat(gameplay: Node, actor: Player) -> void:
	# ⚠️ 02-08: isto exigia o chefe carregado ao frame zero. Com a populacao
	# virtualizada, o Vorgar so ganha corpo quando o jogador se aproxima — que e
	# o que respeita o tecto de oito actores animados (Lei 4).
	# ⭐ A garantia continua a mesma e passa a ser provada como o jogador a prova:
	# ANDA-SE ATE LA e o chefe tem de estar vivo. Se nao aparecer, o teste falha
	# na mesma — e por boa razao, porque o jogador tambem nao o encontraria.
	var vorgar := gameplay.get("boss") as Enemy
	if vorgar == null and actor != null:
		var mundo := gameplay.get("world") as Greybox
		if mundo != null:
			actor.global_position = mundo.arena_center + Vector3(0.0, 0.6, 6.0)
			# Tempo para o produtor de populacao materializar o guardiao.
			for _f: int in 90:
				await get_tree().process_frame
			vorgar = gameplay.get("boss") as Enemy
	_check(vorgar != null and vorgar.is_inside_tree() and vorgar.is_alive(),
		"jogo real: chega-se a arena e o primeiro chefe esta la vivo")
	if vorgar == null or actor == null:
		return
	var persistence_handler := Callable(gameplay, "_on_boss_died")
	if vorgar.died.is_connected(persistence_handler):
		vorgar.died.disconnect(persistence_handler)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy != null and gameplay.is_ancestor_of(enemy):
			enemy.target = null
			enemy.set_physics_process(false)

	var weapon: Dictionary = GameData.weapon(actor.main_weapon)
	var light_attack: Dictionary = weapon.get("light", {}) as Dictionary
	var strike_damage := GameData.compute_damage(
		float(light_attack.get("mv")), actor.main_weapon, actor.attrs, vorgar.defense)
	vorgar.health = strike_damage
	var reach := float(weapon.get("range"))
	actor.global_position = vorgar.global_position + Vector3.BACK * reach * 0.5
	actor.rotation.y = 0.0
	var hud := gameplay.get("hud") as Hud
	var boss_bar := hud.get("_boss_bar") as ColorRect if hud != null else null
	for _frame: int in 2:
		await get_tree().process_frame
	var bar_was_visible := boss_bar != null and boss_bar.visible

	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")
	var attack_frames := int(light_attack.get("startup")) + int(light_attack.get("active")) \
		+ int(light_attack.get("recovery"))
	for _frame: int in attack_frames * 2:
		await get_tree().physics_frame
		if not vorgar.is_alive():
			break
	Input.action_release("attack")
	for _frame: int in 2:
		await get_tree().process_frame
	_check(bar_was_visible and not vorgar.is_alive() and boss_bar != null \
			and not boss_bar.visible,
		"jogo real: carregar em ataque mata Vorgar e esconde a barra visivel")


func _prove_network_hud(gameplay: Node) -> void:
	var net_hud := gameplay.get_node_or_null("NetHud") as NetHud
	_check(net_hud != null, "jogo real: o HUD de rede entra na cena jogavel")
	if net_hud == null:
		return
	var message := "Ligacao instavel na prova integrada"
	NetSession.link_warning.emit(message)
	for _frame: int in 2:
		await get_tree().process_frame
	var label := net_hud.get("_label") as Label
	_check(label != null and label.visible and label.text == message,
		"jogo real: o aviso de rede aparece visivel no ecra")
	NetSession.link_warning.emit("")


func _prove_network_menu(gameplay: Node, actor: Player) -> void:
	var menu := gameplay.get_node_or_null("NetMenu") as NetMenu
	var hud := gameplay.get("hud") as Hud
	var launcher := hud.get_node_or_null("JogarADois") as Button if hud != null else null
	_check(menu != null and launcher != null and launcher.visible,
		"jogo real: o HUD mostra a entrada Jogar a dois")
	if menu == null or launcher == null or actor == null:
		return
	launcher.grab_focus()
	await _activate_focused_control()
	for _frame: int in 2:
		await get_tree().process_frame
	var host_button := menu.get("_host_button") as Button
	var join_button := menu.get("_join_button") as Button
	var close_button := menu.get_node_or_null("Fechar") as Button
	_check(menu.visible and host_button != null and host_button.visible \
			and join_button != null and join_button.visible \
			and not actor.input_enabled,
		"jogo real: confirmar Jogar a dois abre Hospedar e Entrar")
	if close_button != null:
		close_button.grab_focus()
		await _activate_focused_control()
		for _frame: int in 2:
			await get_tree().process_frame
	_check(not menu.visible and actor.input_enabled,
		"jogo real: Fechar devolve o controlo ao jogador")


func _activate_focused_control() -> void:
	await get_tree().process_frame
	var pressed := InputEventAction.new()
	pressed.action = "ui_accept"
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await get_tree().process_frame
	var released := InputEventAction.new()
	released.action = "ui_accept"
	released.pressed = false
	Input.parse_input_event(released)
