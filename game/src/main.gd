extends Node3D
## Monta a cena. Tudo em codigo — o greybox nao tem arte, e assim nao ha ficheiros
## binarios no repositorio e cada mudanca de mundo e uma linha de diff legivel.
##
## Cenarios (--scene=):
##   perf    marco 1: zona pequena com nevoa + 3 inimigos a patrulhar (teste de desempenho)
##   combat  arena limpa: lanceiro + brutamontes, para afinar o combate
##   vorgar  arena final real: 2 jogadores + chefe + 2 orcs, para medir o pior caso
##   zone    a fatia: Brumal -> Toca -> Vorgar   (defeito)

const NAVIGATION_HUD_SCRIPT = preload("res://src/ui/navigation_hud.gd")
const NECROMANCY_RUNTIME_SCRIPT = preload("res://src/summons/necromancy_runtime.gd")
const INTEGRATED_WORLD_SCRIPT = preload("res://scenes/integrated_world.gd")
const LAIR_SCRIPT = preload("res://src/world/lair.gd")
const ENVIRONMENT_ATMOSPHERE_SCRIPT = preload("res://src/visual/environment_atmosphere.gd")

var world: Greybox
var lair: Lair
var player: Player
var partner: Player
var hud: Hud
var boss: Enemy
var navigation: CanvasLayer
var necromancy_runtime: NecromancyRuntime
var net_menu: NetMenu
var net_hud: NetHud
var pickup_manager: WorldPickupManager
var starting_loadout_contract_errors: Array[String] = []

var _preset: Dictionary = {}
var _palette: Dictionary = {}
var _graphics: Dictionary = {}
var _scene_kind := "zone"
var _respawn_point := Vector3.ZERO
var _respawning := false
var _rest_points: Dictionary = {}
var _bonfires: Dictionary = {}
var _nearest_rest_id := ""
var _learning_points: Dictionary = {}
var _learning_elapsed := 0.0
var _wake_layer: CanvasLayer
var _net_launcher: Button
var _net_close: Button
var _net_menu_was_visible := false

const REST_SPAWN_OFFSET := Vector3(1.8, 0.6, 0.8)


func _ready() -> void:
	_ensure_runtime_save()
	_validate_starting_loadout_contract()
	InventorySystem.normalise_current()
	_graphics = _load_graphics()
	_palette = _graphics.get("palette", {})
	_preset = _pick_preset()
	_scene_kind = Bench.scene_arg

	_build_world()
	_build_rest_points()
	_build_player()
	_build_hud()
	_build_network_ui()
	_build_pickup_manager()
	_build_necromancy_runtime()
	_populate()
	SettingsSystem.graphics_changed.connect(_apply_graphics_live)
	_build_navigation()

	if "--photos" in OS.get_cmdline_user_args():
		# A primeira fotografia canonica olha do sul para o ponto de descanso.
		# Virar o actor apenas neste modo torna peito e armas observaveis na prova.
		player.rotation.y = PI
		var tour: Node = load("res://src/tools/photo_tour.gd").new()
		add_child(tour)
		tour.run(self)
		return

	if not Bench.is_benchmarking():
		# À entrada o jogador pode escolher co-op com o rato. Um clique no mundo
		# captura-o; depois a tecla indicada no HUD abre directamente o mesmo menu.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_sync_network_launcher()
	else:
		_run_benchmark_pilot()


func _load_graphics() -> Dictionary:
	var text := FileAccess.get_file_as_string("res://data/graphics.json")
	var parsed: Variant = JSON.parse_string(text)
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _pick_preset() -> Dictionary:
	var presets: Dictionary = _graphics.get("presets", {})
	var name := SettingsSystem.graphics_preset_name()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--quality="):
			name = a.split("=")[1]
	var p: Dictionary = presets.get(name, {})
	p = p.duplicate()
	p["_name"] = name
	return p


func _apply_graphics_live(preset_name: String) -> void:
	var presets: Dictionary = _graphics.get("presets", {}) as Dictionary
	var next: Dictionary = (presets.get(preset_name, {}) as Dictionary).duplicate(true)
	if next.is_empty():
		return
	next["_name"] = preset_name
	_preset = next
	get_viewport().scaling_3d_scale = float(next.get("render_scale", 1.0))
	if is_instance_valid(player) and player.camera != null:
		player.camera.set_view_distance(float(next.get("view_distance", 70.0)))
	var world_environment := world.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		var environment := world_environment.environment
		environment.fog_density = float(next.get("fog_density", 0.032))
		environment.adjustment_brightness = float(next.get("grade_brightness", 0.95))
		environment.adjustment_contrast = float(next.get("grade_contrast", 1.14))
		environment.adjustment_saturation = float(next.get("grade_saturation", 0.82))
	var sun := world.get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.shadow_enabled = bool(next.get("shadows", false))
		sun.directional_shadow_max_distance = float(next.get("shadow_distance", 30.0))
	var vignette := world.get_node_or_null("ScreenGrade/Vignette") as ColorRect
	if vignette != null and vignette.material is ShaderMaterial:
		(vignette.material as ShaderMaterial).set_shader_parameter(
			"strength", float(next.get("vignette_strength", 0.12)))
	if is_instance_valid(hud):
		hud.toast("Gráficos: %s · efeito aplicado" % preset_name, 2.0)


func _build_world() -> void:
	world = INTEGRATED_WORLD_SCRIPT.new() as Greybox
	world.name = "World"
	add_child(world)
	world.call("configure_integrations", LAIR_SCRIPT, ENVIRONMENT_ATMOSPHERE_SCRIPT)
	world.build(_preset, _palette, "arena" if _scene_kind == "combat" else "brumal")
	lair = world.call("integrated_lair") as Lair

	var scale := float(_preset.get("render_scale", 1.0))
	if scale < 1.0:
		get_viewport().scaling_3d_scale = scale


func _build_player() -> void:
	var identity: Dictionary = ((GameData.save_state.get("character", {}) as Dictionary).get(
		"identity", {}) as Dictionary)
	var class_id := String(identity.get("class_id", "warrior"))
	var appearance: Dictionary = identity.get("appearance", {}) as Dictionary
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.setup(class_id, _palette, String(appearance.get("body_id", "body_male")))
	_attach_player_equipment_visual(
		player, String(appearance.get("body_id", "body_male")), class_id)
	refresh_inventory_state()
	var checkpoint: Dictionary = ((GameData.save_state.get("character", {}) as Dictionary).get(
		"checkpoint", {}) as Dictionary)
	var rest_id := String(checkpoint.get("rest_point_id", "brumal_clareira"))
	# O id guarda a fogueira; o corpo renasce ao lado dela, nunca dentro da chama.
	player.global_position = (_rest_points.get(rest_id, world.spawn_point) as Vector3) \
		+ REST_SPAWN_OFFSET
	_respawn_point = player.global_position

	var cam := PlayerCamera.new()
	cam.name = "PlayerCamera"
	add_child(cam)
	cam.target = player
	cam.set_view_distance(float(_preset.get("view_distance", 70.0)))
	player.camera = cam

	player.died.connect(_on_player_died)


func _attach_player_equipment_visual(actor: Player, body_id: String, class_id: String) -> void:
	# Player conserva a capsula e toda a logica de combate. Aqui trocamos apenas
	# o renderer-base pelo renderer modular que ja existe e prendemos os props ao
	# mesmo Skeleton3D; nao ha uma segunda silhueta sobreposta.
	var previous_visual := actor.get("_visual") as CharacterVisual
	if is_instance_valid(previous_visual):
		actor.remove_child(previous_visual)
		previous_visual.queue_free()

	var armor := ArmorVisual.new()
	armor.name = "ArmorVisual"
	actor.add_child(armor)
	var height := float(GameData.section("player").get("capsule_height", 1.8))
	armor.setup(height, Color.WHITE, true, body_id, class_id)
	actor.set("_visual", armor)

	var weapon := WeaponAttach.new()
	actor.add_child(weapon)
	if not weapon.setup(actor, armor):
		weapon.queue_free()

	# O controlador existente observa o ataque real do Player e move o mesmo
	# esqueleto ao qual a arma ficou presa.
	var attacks := AttackAnimationController.new()
	attacks.name = "AttackAnimationController"
	actor.add_child(attacks)
	if not attacks.setup(actor, armor):
		attacks.queue_free()


func _build_hud() -> void:
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.player = player
	SaveSystem.save_completed.connect(_on_save_completed)
	if not Bench.is_benchmarking():
		hud.toast(GameData.ui_text("toast.start") % [
			SettingsSystem.binding_label("toggle_help"), _preset.get("_name", "?")], 6.0)


func _build_network_ui() -> void:
	net_hud = NetHud.new()
	net_hud.name = "NetHud"
	add_child(net_hud)

	net_menu = NetMenu.new()
	net_menu.name = "NetMenu"
	add_child(net_menu)

	_net_launcher = Button.new()
	_net_launcher.name = "JogarADois"
	_net_launcher.text = "JOGAR A DOIS"
	_net_launcher.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_net_launcher.offset_left = -188.0
	_net_launcher.offset_top = 318.0
	_net_launcher.offset_right = -24.0
	_net_launcher.offset_bottom = 362.0
	_net_launcher.pressed.connect(_toggle_network_menu)
	hud.add_child(_net_launcher)

	_net_close = Button.new()
	_net_close.name = "Fechar"
	_net_close.text = "Fechar"
	_net_close.set_anchors_preset(Control.PRESET_CENTER)
	_net_close.offset_left = -210.0
	_net_close.offset_top = 166.0
	_net_close.offset_right = 210.0
	_net_close.offset_bottom = 208.0
	_net_close.pressed.connect(_toggle_network_menu)
	net_menu.add_child(_net_close)


func _toggle_network_menu() -> void:
	if not is_instance_valid(net_menu):
		return
	net_menu.toggle()
	_sync_network_focus()


func _sync_network_focus() -> void:
	_net_menu_was_visible = is_instance_valid(net_menu) and net_menu.visible
	set_local_input_enabled(not _net_menu_was_visible)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _net_menu_was_visible \
		else Input.MOUSE_MODE_CAPTURED
	_sync_network_launcher()


func _sync_network_launcher() -> void:
	if not is_instance_valid(_net_launcher):
		return
	var menu_aberto := is_instance_valid(net_menu) and net_menu.visible
	var rato_livre := Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	_net_launcher.visible = rato_livre and not menu_aberto
	if is_instance_valid(hud):
		var dica := "" if rato_livre or menu_aberto else "%s — JOGAR A DOIS" % \
			_binding_label("toggle_mouse")
		hud.set_network_hint(dica)


func _build_pickup_manager() -> void:
	pickup_manager = WorldPickupManager.new()
	pickup_manager.name = "WorldPickupManager"
	add_child(pickup_manager)
	if not pickup_manager.setup(world, player, hud, "brumal"):
		push_error("[espólio] WorldPickupManager recusou a cena jogável")
		pickup_manager.queue_free()
		pickup_manager = null


func _build_necromancy_runtime() -> void:
	_clear_necromancy_runtime()
	if not is_instance_valid(player) or player.class_id != "evil_mage":
		return
	necromancy_runtime = NECROMANCY_RUNTIME_SCRIPT.new() as NecromancyRuntime
	necromancy_runtime.name = "NecromancyRuntime"
	add_child(necromancy_runtime)
	var presentation := GameData.enemies.get("_presentation", {}) as Dictionary
	if not necromancy_runtime.setup(player, self, &"local-player", &"local-simulation",
			GameData.attributes, GameData.abilities, GameData.spells, _palette,
			presentation):
		push_error("[necromancia] o runtime recusou os catalogos da partida")
		remove_child(necromancy_runtime)
		necromancy_runtime.queue_free()
		necromancy_runtime = null
		return
	player.raise_requested.connect(_on_raise_requested)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null:
			_watch_enemy_for_necromancy(enemy)


func _clear_necromancy_runtime() -> void:
	if is_instance_valid(player) and player.raise_requested.is_connected(
			_on_raise_requested):
		player.raise_requested.disconnect(_on_raise_requested)
	if not is_instance_valid(necromancy_runtime):
		necromancy_runtime = null
		return
	remove_child(necromancy_runtime)
	necromancy_runtime.queue_free()
	necromancy_runtime = null


func _watch_enemy_for_necromancy(enemy: Enemy) -> void:
	if not is_instance_valid(necromancy_runtime):
		return
	var ability := GameData.ability("evil_mage")
	var sizes := ability.get("corpse_body_size_by_role", {}) as Dictionary
	var body_size := String(sizes.get(String(enemy.data.get("role", "")), ""))
	if not body_size.is_empty():
		enemy.data = enemy.data.duplicate(true)
		enemy.data["necromancy_body_size"] = body_size
	necromancy_runtime.watch_enemy(enemy)


func _on_raise_requested(spell_id: String) -> void:
	if not is_instance_valid(necromancy_runtime) or not is_instance_valid(player):
		return
	var preview: Dictionary = necromancy_runtime.validate_raise_target(spell_id)
	if not bool(preview.get("accepted", false)):
		_show_raise_feedback(String(preview.get("reason", "rejected")))
		return
	var base_max_health := GameData.max_health_for(int(player.attrs.get("vida", 8)))
	var health_cost := base_max_health * float(preview.get(
		"health_cost_fraction", 0.0))
	if player.health <= health_cost or is_equal_approx(player.health, health_cost):
		_show_raise_feedback("insufficient_current_health")
		return
	var health_before := player.health
	var result: Dictionary = necromancy_runtime.raise_nearest(spell_id)
	if not bool(result.get("accepted", false)):
		_show_raise_feedback(String(result.get("reason", "rejected")))
		return
	# O runtime reserva a mesma fraccao na barra maxima. Esta linha faz o custo
	# sair tambem dos PV actuais sem cobrar duas vezes quando a barra estava cheia.
	player.health = minf(player.max_health, health_before - health_cost)
	_show_raise_feedback("accepted")


func _show_raise_feedback(reason: String) -> void:
	if not is_instance_valid(hud):
		return
	var feedback := GameData.ability("evil_mage").get(
		"raise_feedback", {}) as Dictionary
	var message := String(feedback.get(reason, feedback.get("rejected", "")))
	if not message.is_empty():
		hud.toast(message, 3.0)


func _build_navigation() -> void:
	if _scene_kind == "combat":
		return
	navigation = NAVIGATION_HUD_SCRIPT.new()
	navigation.name = "Orientacao"
	add_child(navigation)
	navigation.call("initialize", player, partner, world, "brumal")


# --- Povoamento ---------------------------------------------------------------

func _spawn(enemy_id: String, at: Vector3, actor: Enemy = null) -> Enemy:
	var e := actor if actor != null else Enemy.new()
	add_child(e)
	e.global_position = at
	e.set_meta("placement_id", _placement_id(enemy_id, at))
	e.setup(enemy_id, _palette)
	_attach_monster_visual(e)
	e.target = player
	e.home = at
	e.died.connect(_on_enemy_died)
	_watch_enemy_for_necromancy(e)
	return e


func _placement_id(enemy_id: String, at: Vector3) -> String:
	# A posição de autoria é estável entre sessões e não depende da ordem em que
	# o povoamento cria os corpos. É a mesma identidade usada por descanso/loot.
	return "brumal:%s:%.3f:%.3f:%.3f" % [enemy_id, at.x, at.y, at.z]


func _attach_monster_visual(enemy: Enemy) -> void:
	if MonsterVisual.profile_for(enemy.enemy_id).is_empty():
		return
	var previous_visual := enemy.get("_visual") as Node3D
	if is_instance_valid(previous_visual):
		enemy.remove_child(previous_visual)
		previous_visual.queue_free()
	var visual := MonsterVisual.new()
	enemy.add_child(visual)
	visual.setup(enemy.enemy_id, enemy.data, enemy.get("_visual_profile"),
		bool(_preset.get("shadows", true)), int(enemy.get_instance_id()))
	enemy.set("_visual", visual)


func _populate() -> void:
	match _scene_kind:
		"perf":
			# Marco 1: tres inimigos a patrulhar dentro da zona com nevoa.
			var p := world.path_points
			_spawn("orc_spearman", p[1] + Vector3(4, 0.5, 0))
			_spawn("orc_spearman", p[2] + Vector3(-5, 0.5, 2))
			_spawn("orc_brute", p[3] + Vector3(3, 0.5, -3))
		"lei4":
			# O criterio 5 da fatia, a letra: "2 jogadores + 3 inimigos no ecra",
			# na resolucao nativa. O pior caso de render que a spec exige.
			var c := world.path_points[2]
			_spawn("orc_spearman", c + Vector3(6, 0.5, 2))
			_spawn("orc_spearman", c + Vector3(-4, 0.5, 6))
			_spawn("orc_brute", c + Vector3(2, 0.5, -6))
			partner = Player.new()
			partner.name = "Parceiro"
			add_child(partner)
			partner.setup("sorcerer", _palette)
			partner.global_position = c + Vector3(2.5, 0.6, 1.0)
		"combat":
			_spawn("orc_spearman", Vector3(4, 0.5, -6))
			_spawn("orc_brute", Vector3(-5, 0.5, -8))
		"vorgar":
			# Prova repetível dentro da arena final, não numa arena cinzenta que
			# omite as paredes, tochas e os detritos que o jogador vê.
			var c := _vorgar_spawn_position()
			player.global_position = c + Vector3(0.0, 0.6, 8.0)
			_respawn_point = player.global_position
			_register_boss(_spawn("vorgar", c, BossVorgar.new()))
			_spawn("orc_spearman", c + Vector3(6.0, 0.5, 1.5))
			_spawn("orc_brute", c + Vector3(-6.0, 0.5, -2.0))
			var partner := Player.new()
			partner.name = "Parceiro"
			add_child(partner)
			partner.setup("sorcerer", _palette)
			partner.global_position = c + Vector3(2.5, 0.6, 6.5)
		_:
			# O catalogo descreve a zona inteira; o produtor materializa apenas
			# as colocacoes proximas para respeitar o tecto global de actores.
			var population_script := load("res://src/world/spawn_population.gd") as Script
			var population := population_script.new() as Node
			population.name = "SpawnPopulation"
			add_child(population)
			population.call("initialize", self, player, world, lair, _palette, "brumal")

			# O tutorial continua ancorado no mesmo percurso, sem possuir uma
			# segunda lista de inimigos que possa divergir do budget da zona.
			var p := world.path_points
			_learning_points = {
				"attack": p[1],
				"dodge": p[2],
				"parry": p[3],
				"flask": p[4],
			}


func _vorgar_spawn_position() -> Vector3:
	if is_instance_valid(lair):
		var marker := lair.get_node_or_null("Boss_Vorgar") as Marker3D
		if marker != null:
			return marker.global_position
	return world.arena_center


func _register_boss(spawned: Enemy) -> void:
	boss = spawned
	hud.boss = boss
	if not boss.died.is_connected(_on_boss_died):
		boss.died.connect(_on_boss_died)


func _enemy_id_for_lair_marker(marker: Marker3D) -> String:
	var architecture_role := String(marker.get_meta("architecture_role", ""))
	var archetype := architecture_role.get_slice("_", 0).to_lower()
	if archetype.is_empty():
		return ""
	var enemy_ids: Array[String] = []
	for value: Variant in GameData.enemies.keys():
		var enemy_id := String(value)
		if not enemy_id.begins_with("_"):
			enemy_ids.append(enemy_id)
	enemy_ids.sort()
	for enemy_id: String in enemy_ids:
		var display_name := String(GameData.enemy(enemy_id).get("display_name", "")).to_lower()
		if display_name.contains(archetype):
			return enemy_id
	push_warning("A Toca nao encontrou no catalogo o papel '%s'" % architecture_role)
	return ""


# --- Morte e recomeco ---------------------------------------------------------

func _validate_starting_loadout_contract() -> void:
	# O contrato recebe os catalogos inteiros. Uma origem nova entra na mesma
	# execucao sem precisar de ser repetida numa lista de compatibilidade.
	starting_loadout_contract_errors = StartingLoadouts.contract_errors(
		GameData.weapons, GameData.equipment, GameData.attributes)
	for error: String in starting_loadout_contract_errors:
		push_error("[starting-loadouts] %s" % error)


func _ensure_runtime_save() -> void:
	if not GameData.save_state.is_empty():
		return
	var path := SaveSystem.slot_path(0)
	if not FileAccess.file_exists(path):
		SaveSystem.new_game("local-prototype", "warrior", 0)
		return
	var loaded := SaveSystem.load_slot(0)
	if loaded.is_empty():
		SaveSystem.new_game("local-prototype", "warrior", 0)


func _on_enemy_died(defeated: Enemy) -> void:
	if defeated.is_boss:
		return
	var snapshot := GameData.save_state_snapshot()
	var world_state: Dictionary = snapshot.get("world", {}) as Dictionary
	var deck_state: Dictionary = ((world_state.get("loot_decks", {}) as Dictionary).get(
		defeated.enemy_id, {}) as Dictionary)
	var next_index := int(deck_state.get("next_index", 0))
	var event_id := "enemy:%s:%d" % [defeated.enemy_id, next_index]
	var character: Dictionary = snapshot.get("character", {}) as Dictionary
	var identity: Dictionary = character.get("identity", {}) as Dictionary
	var class_id := String(identity.get("class_id", "warrior"))
	var seed_value := hash(String(world_state.get("owner_profile_id", "local-prototype")))
	var receipt := SaveSystem.commit_enemy_defeat(
		defeated.enemy_id, event_id, seed_value, class_id)
	match String(receipt.get("status", "")):
		"awarded":
			var card := String(receipt.get("resolved_card", ""))
			if is_instance_valid(pickup_manager):
				pickup_manager.present_enemy_reward(
					receipt, defeated.global_position, snapshot)
			hud.toast(GameData.ui_text("toast.reward") % [int(receipt.get("souls_awarded", 0)), card], 3.0)
		"exhausted":
			hud.toast(GameData.ui_text("toast.loot_exhausted"), 2.5)
		"save_failed":
			hud.toast(GameData.ui_text("toast.reward_save_failed"), 3.0)

func _on_player_died() -> void:
	if _respawning:
		return
	_respawning = true
	if not SaveSystem.commit_death("brumal", player.global_position):
		hud.toast("A morte não foi gravada: %s" % SaveSystem.last_error, 4.0)
	hud.toast(GameData.ui_text("toast.death"), 1.5)
	await get_tree().create_timer(
		float(GameData.section("death").get("respawn_fade_seconds", 1.2))).timeout
	_respawn()


## Vida, stamina e mana restauradas; o chefe faz reset TOTAL.
## O alvo da spec e nova tentativa em menos de 30 s — aqui e ~1,2 s.
func _respawn() -> void:
	player.respawn_at(_respawn_point)
	player.flask_refill()
	if is_instance_valid(pickup_manager):
		pickup_manager.set_player(player)
	for node in get_children():
		var e := node as Enemy
		if e != null:
			e.full_reset()
	_respawning = false
	hud.toast(GameData.ui_text("toast.respawn"), 2.0)


func _on_boss_died(_e: Enemy) -> void:
	var cycle := int((GameData.save_state.get("world", {}) as Dictionary).get("cycle", 0))
	if not SaveSystem.commit_boss_defeat("vorgar", "boss:vorgar:%d" % cycle):
		hud.toast("Vorgar caiu, mas o progresso não foi gravado.", 4.0)
		return
	hud.toast(GameData.ui_text("toast.boss_defeated"), 12.0)


func _on_save_completed(_path: String) -> void:
	if is_instance_valid(hud):
		hud.indicate_save()


# --- Pontos de descanso ------------------------------------------------------

func _build_rest_points() -> void:
	_rest_points = {
		"brumal_clareira": world.spawn_point,
		"toca_entrada": world.lair_entrance + Vector3(0, 0.0, 7.0),
	}
	_bonfires.clear()
	for rest_id: String in _rest_points:
		_build_bonfire(rest_id, _rest_points[rest_id])


func _build_bonfire(rest_id: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Rest_%s" % rest_id
	root.position = at
	add_child(root)
	for index: int in range(8):
		var stone := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.22
		mesh.height = 0.34
		stone.mesh = mesh
		var angle := TAU * float(index) / 8.0
		stone.position = Vector3(sin(angle) * 0.7, 0.18, cos(angle) * 0.7)
		root.add_child(stone)
	var ember := MeshInstance3D.new()
	var ember_mesh := CylinderMesh.new()
	ember_mesh.top_radius = 0.16
	ember_mesh.bottom_radius = 0.42
	ember_mesh.height = 0.75
	ember.mesh = ember_mesh
	ember.position.y = 0.4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("d57635")
	material.emission_enabled = true
	material.emission = Color("d65a24")
	material.emission_energy_multiplier = 2.5
	ember.material_override = material
	root.add_child(ember)
	var light := OmniLight3D.new()
	light.position.y = 1.1
	light.light_color = Color("ff9a55")
	light.light_energy = 1.8
	light.omni_range = 7.0
	light.shadow_enabled = false
	root.add_child(light)
	var controller := Bonfire.new()
	controller.name = "BonfireController"
	root.add_child(controller)
	controller.configure("brumal", rest_id)
	controller.rest_completed.connect(_on_bonfire_rest_completed.bind(rest_id))
	controller.operation_failed.connect(_on_bonfire_operation_failed)
	_bonfires[rest_id] = controller


func _tick_rest_points() -> void:
	if not is_instance_valid(player) or player.state == Player.State.DEAD:
		return
	var nearest := ""
	var nearest_distance := 9999.0
	for rest_id: String in _rest_points:
		var distance := player.global_position.distance_to(_rest_points[rest_id])
		if distance < nearest_distance:
			nearest = rest_id
			nearest_distance = distance
	# ⚠️ 02-08: eram 2,5 m medidos ao CENTRO da fogueira — e a fogueira e um monte
	# de pedras com mais de um metro de raio, que impede o jogador de la chegar.
	# Resultado: ficava-se encostado ao fogo e o jogo dizia "nao foi possivel
	# descansar agora". O Mateus: "nao da pra senta nas outras fogueiras".
	# 4,5 m e a distancia a que se ESTA na fogueira, nao a que se esta dentro dela.
	_nearest_rest_id = nearest if nearest_distance <= 4.5 else ""
	if _nearest_rest_id == "":
		hud.set_prompt("")
		return
	var controller := _bonfires.get(_nearest_rest_id) as Bonfire
	if controller == null:
		hud.set_prompt("")
		return
	var action := controller.input_action()
	hud.set_prompt("%s — descansar" % _binding_label(action))
	controller.process_input(player, _enemies_for_rest())


func _enemies_for_rest() -> Array:
	var enemies: Array = []
	for child: Node in get_children():
		var enemy := child as Enemy
		if enemy != null:
			enemies.append(enemy)
	return enemies


func _on_bonfire_rest_completed(_result: Dictionary, rest_id: String) -> void:
	_respawn_point = (_rest_points[rest_id] as Vector3) + REST_SPAWN_OFFSET
	if is_instance_valid(necromancy_runtime):
		necromancy_runtime.rest()
	# ⭐ 02-08: A FOGUEIRA GRAVA. Antes so se gravava ao SAIR do jogo — o Mateus
	# disse "nunca salva o jogo", e tinha razao: quem fechasse a janela a bruta
	# perdia tudo. Num souls-like a fogueira e o ponto de gravacao, e e por isso
	# que descansar tem peso: e o momento em que o progresso fica seguro.
	if SaveSystem.save_current():
		hud.toast("Descansaste. Progresso guardado neste ponto de regresso.", 3.0)
	else:
		# ⚠️ Nunca em silencio: se a gravacao falhar, o jogador TEM de saber,
		# senao continua a jogar a pensar que esta seguro.
		hud.toast("Descansaste, mas NAO foi possivel gravar: %s" % SaveSystem.last_error, 6.0)


func _on_bonfire_operation_failed(_result: Dictionary) -> void:
	hud.toast("Não foi possível descansar agora.", 3.0)


func _binding_label(action_name: String) -> String:
	return SettingsSystem.binding_label(action_name)


func set_local_input_enabled(enabled: bool) -> void:
	if is_instance_valid(player):
		player.input_enabled = enabled


func begin_wake_sequence(capture_mode := false) -> void:
	if not is_instance_valid(player) or is_instance_valid(_wake_layer):
		return
	player.set_waking_up(true)
	if is_instance_valid(hud):
		hud.visible = false
	_wake_layer = CanvasLayer.new()
	_wake_layer.layer = 280
	_wake_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_wake_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_wake_layer.add_child(root)
	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.color = Color(0.0, 0.0, 0.0, 0.48 if capture_mode else 0.88)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(veil)
	var title := Label.new()
	title.text = "CLAREIRA DE BRUMAL"
	title.position = Vector2(0, 420)
	title.size = Vector2(1920, 76)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("eadbb9"))
	root.add_child(title)
	var rule := ColorRect.new()
	rule.color = Color("9a743d")
	rule.position = Vector2(900, 505)
	rule.size = Vector2(120, 2)
	root.add_child(rule)
	var context := Label.new()
	context.text = "A fogueira ainda arde.  Levanta-te."
	context.position = Vector2(0, 540)
	context.size = Vector2(1920, 52)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context.add_theme_font_size_override("font_size", 19)
	context.add_theme_color_override("font_color", Color("aab4b3"))
	root.add_child(context)
	if capture_mode:
		return
	await get_tree().create_timer(0.7).timeout
	var tween := create_tween().set_parallel(true)
	tween.tween_property(veil, "color:a", 0.0, 2.2)
	tween.tween_property(title, "modulate:a", 0.0, 1.4).set_delay(0.8)
	tween.tween_property(rule, "modulate:a", 0.0, 1.4).set_delay(0.8)
	tween.tween_property(context, "modulate:a", 0.0, 1.4).set_delay(0.8)
	await tween.finished
	_end_wake_sequence()


func wake_sequence_active() -> bool:
	return is_instance_valid(_wake_layer)


func _end_wake_sequence() -> void:
	if is_instance_valid(_wake_layer):
		# ⚠️ queue_free(), nunca free(). Isto pode ser chamado de dentro de um
		# sinal (tecla, temporizador, fim de animacao) e o free() imediato mata o
		# emissor a meio da emissao — use-after-free, e a janela fecha sem dizer
		# nada. Foi o que fechava o jogo ao iniciar (01-08). Ver _fechar_no() no
		# game_shell.gd, que tem a explicacao completa.
		var pai: Node = _wake_layer.get_parent()
		if pai != null:
			pai.remove_child(_wake_layer)
		_wake_layer.queue_free()
	_wake_layer = null
	if is_instance_valid(player):
		player.set_waking_up(false)
	if is_instance_valid(hud):
		hud.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sync_network_launcher()


func refresh_inventory_state() -> void:
	if not is_instance_valid(player):
		return
	var state := GameData.save_state_snapshot()
	var readable_state := state.duplicate(true)
	var character: Dictionary = readable_state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment := (inventory.get("equipment", {}) as Dictionary).duplicate(true)
	for hand: String in ["main", "offhand"]:
		if equipment.get(hand) == null:
			equipment[hand] = ""
	inventory["equipment"] = equipment
	character["inventory"] = inventory
	readable_state["character"] = character
	player.apply_inventory_state(equipment,
		InventorySystem.load_profile(readable_state))
	var armor := player.get("_visual") as ArmorVisual
	if armor != null:
		armor.apply_equipment(equipment.get("armor", []) as Array)


func can_change_spell_favorites() -> bool:
	return not _combat_is_active()


func spell_favorites() -> Array[String]:
	return player.favorite_spells.duplicate() if is_instance_valid(player) else []


func selected_spell_id() -> String:
	return player.selected_spell if is_instance_valid(player) else ""


func cycle_spell() -> void:
	if is_instance_valid(player):
		player.cycle_spell()


func select_and_cast_spell(spell_id: String) -> bool:
	return is_instance_valid(player) and player.select_spell(spell_id) \
		and player.cast_selected_spell()


# --- Aprendizagem contextual -------------------------------------------------

func _tick_learning(delta: float) -> void:
	if _scene_kind != "zone" or not SettingsSystem.context_tips_enabled() \
			or not is_instance_valid(player) or not player.input_enabled \
			or not is_instance_valid(hud) or hud.has_context_tip():
		return
	_learning_elapsed += delta
	if _combat_is_active():
		return
	if _learning_elapsed >= 1.2 and not SettingsSystem.tip_seen("movement"):
		_show_learning_tip("movement")
		return
	for tip_id: String in ["attack", "dodge", "parry"]:
		if SettingsSystem.tip_seen(tip_id) or not _learning_points.has(tip_id):
			continue
		if player.global_position.distance_to(_learning_points[tip_id] as Vector3) <= 23.0:
			_show_learning_tip(tip_id)
			return
	if not SettingsSystem.tip_seen("flask") and player.health < player.max_health \
			and player.global_position.distance_to(
				_rest_points.get("toca_entrada", Vector3(9999, 9999, 9999)) as Vector3) <= 18.0:
		_show_learning_tip("flask")


func _combat_is_active() -> bool:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.state in [Enemy.State.CHASE, Enemy.State.ATTACK]:
			return true
	return false


func _show_learning_tip(tip_id: String) -> void:
	var message := GameShell.tutorial_tip_text(tip_id)
	if message == "":
		return
	SettingsSystem.mark_tip_seen(tip_id)
	hud.context_tip(message, 4.0)


# --- Teclas de sessao ---------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE \
			and (not is_instance_valid(net_menu) or not net_menu.visible):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_sync_network_launcher()
		return
	if InputMap.has_action("debug_class_next") and Input.is_action_just_pressed("debug_class_next"):
		_cycle_class()
		return
	if InputMap.has_action("toggle_mouse") and Input.is_action_just_pressed("toggle_mouse"):
		_toggle_network_menu()
		return
	elif InputMap.has_action("reset_arena") and Input.is_action_just_pressed("reset_arena"):
		_respawn()
		hud.toast(GameData.ui_text("toast.arena_reset"), 2.0)


# --- Piloto automatico para a medicao -----------------------------------------

## Em modo benchmark ninguem carrega em teclas. Isto poe a camara a rodar devagar
## para o custo de render ser realista (a nevoa e as arvores entram e saem de vista)
## em vez de se medir uma cena parada, que mentiria para melhor.
func _run_benchmark_pilot() -> void:
	set_process(true)


var _pilot_t := 0.0

func _process(delta: float) -> void:
	if not Bench.is_benchmarking():
		if is_instance_valid(net_menu) and net_menu.visible != _net_menu_was_visible:
			_sync_network_focus()
		else:
			_sync_network_launcher()
		_tick_rest_points()
		_tick_learning(delta)
		return
	# Os benchmarks de UI medem o ecrã no contexto em que ele aparece. O piloto
	# 3D colocaria artificialmente o jogador no meio dos inimigos durante menus.
	if Bench.scene_arg.begins_with("ui-"):
		return
	if not is_instance_valid(player):
		return
	_pilot_t += delta
	var angle := _pilot_t * 0.35
	var centre: Vector3 = world.arena_center if _scene_kind == "vorgar" \
		else (world.path_points[2] if world.path_points.size() > 2 else Vector3.ZERO)
	player.global_position = centre + Vector3(sin(angle) * 12.0, 0.6, cos(angle) * 12.0)
	if player.camera != null:
		player.camera.rotation.y = angle + PI


func _exit_tree() -> void:
	if SaveSystem.save_completed.is_connected(_on_save_completed):
		SaveSystem.save_completed.disconnect(_on_save_completed)
	if SettingsSystem.graphics_changed.is_connected(_apply_graphics_live):
		SettingsSystem.graphics_changed.disconnect(_apply_graphics_live)
	if not GameData.save_state.is_empty():
		SaveSystem.save_current()


# --- Troca de classe (F6, ferramenta de teste) ---------------------------------
var _class_index := 0


func _cycle_class() -> void:
	var class_ids := _playable_class_ids()
	if class_ids.is_empty():
		return
	_class_index = (_class_index + 1) % class_ids.size()
	var class_id := class_ids[_class_index]
	var pos := player.global_position
	var cam := player.camera
	_clear_necromancy_runtime()
	player.died.disconnect(_on_player_died)
	player.queue_free()

	player = Player.new()
	player.name = "Player"
	add_child(player)
	var appearance: Dictionary = (((GameData.save_state.get("character", {}) as Dictionary).get(
		"identity", {}) as Dictionary).get("appearance", {}) as Dictionary)
	var body_id := String(appearance.get("body_id", "body_male"))
	player.setup(class_id, _palette, body_id)
	_attach_player_equipment_visual(player, body_id, class_id)
	refresh_inventory_state()
	player.global_position = pos
	player.camera = cam
	cam.target = player
	player.died.connect(_on_player_died)
	hud.player = player
	if is_instance_valid(pickup_manager):
		pickup_manager.set_player(player)
	_build_necromancy_runtime()
	if is_instance_valid(navigation):
		navigation.set("player", player)
		var surface: Control = navigation.get("_minimap_surface")
		if surface != null:
			surface.set("player", player)
	for node in get_children():
		var e := node as Enemy
		if e != null:
			e.target = player
	var display: String = GameData.class_attributes(class_id).get("display_name", class_id)
	hud.toast(GameData.ui_text("toast.class_changed") % display, 2.5)


func _playable_class_ids() -> Array[String]:
	var result: Array[String] = []
	var loadouts: Dictionary = GameData.weapons.get("loadouts", {}) as Dictionary
	for value: Variant in loadouts.keys():
		var class_id := String(value)
		if not class_id.begins_with("_"):
			result.append(class_id)
	result.sort()
	return result
