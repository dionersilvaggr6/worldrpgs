extends SceneTree
## Ensaio focado, executado com:
## godot --headless --audio-driver Dummy --path game/ --script res://src/enemies/boss_vorgar_self_test.gd
##
## Os valores de combate vêm todos dos JSON; este ficheiro só compara contrato
## com comportamento e termina com código diferente de zero se algo divergir.

var _passed := 0
var _failed := 0


class FakeStamina extends RefCounted:
	var current := 0.0


class FakePlayer extends Node3D:
	var health := 0.0
	var max_health := 0.0
	var mana := 0.0
	var meditation_uses := 0
	var stamina := FakeStamina.new()
	var _alive := true
	var last_attack_id := ""

	func configure(value: float) -> void:
		max_health = value
		health = value
		mana = value
		stamina.current = value

	func is_alive() -> bool:
		return _alive

	func take_damage(info: Variant) -> void:
		last_attack_id = String(info.attack_id)
		health = maxf(0.0, health - float(info.amount))
		_alive = health > 0.0

	func kill() -> void:
		health = 0.0
		_alive = false

	func restore() -> void:
		health = max_health
		_alive = true
		last_attack_id = ""

	func respawn_at(at: Vector3) -> void:
		global_position = at
		health = max_health
		stamina.current = max_health
		mana = max_health
		_alive = true


class FakeBoss extends Node3D:
	var data: Dictionary = {}
	var target: Node3D

	func taunt(by: Node3D, _seconds: float) -> void:
		target = by


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_data := root.get_node_or_null("GameData")
	_check(game_data != null, "autoload GameData está disponível no ensaio")
	if game_data == null:
		_finish()
		return

	var raw_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/enemies.json"))
	_check(typeof(raw_value) == TYPE_DICTIONARY, "enemies.json é JSON válido")
	if typeof(raw_value) != TYPE_DICTIONARY:
		_finish()
		return
	var raw := raw_value as Dictionary
	var raw_vorgar := raw.get("vorgar", {}) as Dictionary
	var runtime_vorgar: Dictionary = game_data.call("enemy", "vorgar")
	var encounter := raw_vorgar.get("vorgar_encounter", {}) as Dictionary
	var sequences := encounter.get("coop_sequences", {}) as Dictionary

	_test_catalogue(raw_vorgar, runtime_vorgar, encounter, sequences)
	await _test_runtime(game_data, runtime_vorgar, encounter, sequences)
	_finish()


func _test_catalogue(raw_vorgar: Dictionary, runtime_vorgar: Dictionary,
		encounter: Dictionary, sequences: Dictionary) -> void:
	var attacks := raw_vorgar.get("attacks", []) as Array
	var attack_ids: Array[String] = []
	for attack_value: Variant in attacks:
		attack_ids.append(String((attack_value as Dictionary).get("id", "")))
	_check(attack_ids == ["cleave", "wide_sweep", "overhead_crush", "shoulder_charge",
		"ground_pound"], "os cinco ataques de Vorgar conservam identidade e ordem")
	_check(sequences.keys().size() == 2 and sequences.has("separar") and sequences.has("juntar"),
		"há exactamente uma sequência SEPARAR e uma JUNTAR")
	var phase_plan := encounter.get("coop_phase_plan", {}) as Dictionary
	_check(String((phase_plan.get("1", {}) as Dictionary).get("sequence_id")) == "separar"
		and String((phase_plan.get("2", {}) as Dictionary).get("sequence_id")) == "juntar",
		"fase 1 separa e fase 2 junta")

	var honesty := encounter.get("honesty_contract", {}) as Dictionary
	for attack_value: Variant in runtime_vorgar.get("attacks", []):
		_check_attack_contract(attack_value as Dictionary, honesty)
	for sequence_value: Variant in sequences.values():
		_check_attack_contract(sequence_value as Dictionary, honesty)

	var controls_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/controls.json"))
	var controls := controls_value as Dictionary
	var input_action := String((encounter.get("resurrection", {}) as Dictionary).get(
		"input_action"))
	var bindings := ((controls.get("actions", {}) as Dictionary).get(input_action, [])) as Array
	var input_types := {}
	for binding_value: Variant in bindings:
		input_types[String((binding_value as Dictionary).get("type", ""))] = true
	_check(input_types.has("key") and input_types.has("joypad_button"),
		"ressurreição usa a interação remapeável no teclado e comando")

	var resurrection := encounter.get("resurrection", {}) as Dictionary
	_check(String(resurrection.get("cost", "")) != "" and String(resurrection.get("risk", "")) != "",
		"ressurreição declara custo e risco")
	_check(String(raw_vorgar.get("coop_health_status", "")).contains("[TENSÃO]")
		and String(raw_vorgar.get("coop_health_status", "")).contains("[PROTO]"),
		"×1,8 herdado continua marcado como tensão/protótipo")
	var boss_source := FileAccess.get_file_as_string("res://src/enemies/boss_vorgar.gd")
	_check(not boss_source.contains("coop_health_multiplier"),
		"as mecânicas co-op novas não escalam PV")


func _check_attack_contract(attack: Dictionary, honesty: Dictionary) -> void:
	var label := String(attack.get("id", "?"))
	var phase_1 := int(attack.get("phase_1_frames"))
	var phase_2 := int(attack.get("phase_2_frames"))
	var startup := int(attack.get("startup"))
	var active := int(attack.get("active"))
	var recovery := int(attack.get("recovery"))
	var phase_4 := int(attack.get("phase_4_frames"))
	_check(phase_1 + phase_2 == startup,
		"%s: abertura+sinal coincidem com o aviso" % label)
	_check(startup >= int(honesty.get("minimum_warning_frames")),
		"%s: aviso cumpre o mínimo declarado" % label)
	_check(phase_4 <= recovery,
		"%s: pose final cabe antes do fim do regresso" % label)
	if attack.has("phase_5_frames"):
		_check(phase_4 + int(attack.get("phase_5_frames")) == recovery,
			"%s: fases 4+5 coincidem com a recuperação" % label)
	if String(attack.get("tipo_contacto")) == "instantaneo":
		var active_range := honesty.get("instant_active_frames_range", []) as Array
		_check(active >= int(active_range.front()) and active <= int(active_range.back()),
			"%s: contacto instantâneo vive dentro da janela declarada" % label)
	var vectors := attack.get("vectores_fuga", []) as Array
	var vector_range := honesty.get("escape_vector_count_range", []) as Array
	_check(vectors.size() >= int(vector_range.front()) and vectors.size() <= int(vector_range.back()),
		"%s: declara um ou dois vectores de fuga" % label)
	_check(attack.has("momento_compromisso_frame"),
		"%s: declara momento de compromisso" % label)
	var tracking := attack.get("curva_seguimento", {}) as Dictionary
	_check(float(tracking.get("fase_3_deg_s", INF)) == 0.0,
		"%s: seguimento pára antes da hitbox" % label)
	var sound := attack.get("som_anuncio", {}) as Dictionary
	_check(String(sound.get("cue_id", "")) != "" and String(sound.get("profile", "")) != "",
		"%s: anuncia-se por som próprio" % label)
	var visual := attack.get("sinal_visual_equivalente", {}) as Dictionary
	for field: Variant in honesty.get("visual_cue_fields", []):
		_check(String(visual.get(String(field), "")) != "",
			"%s: sinal visual declara %s" % [label, field])


func _test_runtime(game_data: Node, runtime_vorgar: Dictionary,
		encounter: Dictionary, sequences: Dictionary) -> void:
	var arena_script: Script = load("res://src/world/arena_vorgar.gd")
	var boss_script: Script = load("res://src/enemies/boss_vorgar.gd")
	_check(arena_script != null, "ArenaVorgar compila e carrega")
	_check(boss_script != null, "BossVorgar compila e carrega")
	if arena_script == null or boss_script == null:
		return

	var boss := FakeBoss.new()
	boss.data = runtime_vorgar
	root.add_child(boss)
	var first := FakePlayer.new()
	var second := FakePlayer.new()
	first.configure(float(runtime_vorgar.get("health")))
	second.configure(float(runtime_vorgar.get("health")))
	root.add_child(first)
	root.add_child(second)
	first.add_to_group("player")
	second.add_to_group("player")
	var arena: Node3D = arena_script.new()
	root.add_child(arena)
	arena.call("setup", boss, encounter, first)
	arena.set_physics_process(false)

	var separate := sequences.get("separar", {}) as Dictionary
	var minimum := float(separate.get("minimum_player_separation_m"))
	first.global_position = Vector3.ZERO
	second.global_position = Vector3.RIGHT * (minimum / 2.0)
	var health_before := first.health
	arena.call("begin_sequence", separate)
	_tick_until_first_active(arena, separate)
	_check(first.health < health_before and second.health < health_before,
		"SEPARAR: a intersecção visível atinge ambos uma vez")
	arena.call("end_sequence")
	await process_frame
	first.restore()
	second.restore()
	second.global_position = Vector3.RIGHT * (minimum + float(separate.get("marker_radius_m")))
	health_before = first.health
	arena.call("begin_sequence", separate)
	_tick_until_first_active(arena, separate)
	_check(first.health == health_before and second.health == health_before,
		"SEPARAR: seis metros ou mais deixam ambos seguros")
	arena.call("end_sequence")
	await process_frame

	var join := sequences.get("juntar", {}) as Dictionary
	first.restore()
	second.restore()
	var width := float(encounter.get("usable_width_m"))
	var depth := float(encounter.get("usable_depth_m"))
	first.global_position = Vector3(-width / 2.0, 0.0, -depth / 2.0)
	second.global_position = Vector3(width / 2.0, 0.0, depth / 2.0)
	arena.call("begin_sequence", join)
	var reach := arena.call("join_reach_budget") as Dictionary
	_check(float(reach.get("available_m")) >= float(reach.get("required_max_m")),
		"JUNTAR: aviso cobre a distância conservadora na área 20 × 16")
	var safe: Vector3 = arena.call("join_safe_center_global")
	first.global_position = safe
	second.global_position = safe
	health_before = first.health
	_tick_until_first_active(arena, join)
	_check(first.health == health_before and second.health == health_before,
		"JUNTAR: a zona comum nunca fere")
	var visuals := arena.call("visual_cost_snapshot") as Dictionary
	_check(int(visuals.get("meshes")) <= int(visuals.get("mesh_budget"))
		and int(visuals.get("labels")) <= int(visuals.get("label_budget")),
		"arena: guias e sequência ficam no orçamento de 7 malhas/etiquetas")
	for frame: int in range(int(join.get("startup")) + 2,
		int(join.get("startup")) + int(join.get("active")) + 2):
		arena.call("tick_sequence", frame)
	_check(not bool(arena.call("sequence_visuals_visible")),
		"JUNTAR: volume visual apaga no mesmo frame em que deixa de ferir")
	arena.call("end_sequence")
	await process_frame

	first.restore()
	second.restore()
	arena.call("begin_sequence", join)
	safe = arena.call("join_safe_center_global")
	var outside := safe + Vector3.RIGHT * (
		float(join.get("safe_zone_radius_m")) + float(encounter.get("revive_radius_m")))
	first.global_position = outside
	second.global_position = outside
	health_before = first.health
	_tick_until_first_active(arena, join)
	_check(first.health < health_before and second.health < health_before,
		"JUNTAR: o exterior visível aplica o pulso declarado")
	arena.call("end_sequence")
	await process_frame

	_test_resurrection(game_data, arena, boss, first, second, encounter, runtime_vorgar)
	arena.queue_free()
	first.queue_free()
	second.queue_free()
	boss.queue_free()
	await process_frame


func _test_resurrection(game_data: Node, arena: Node3D, boss: FakeBoss,
		first: FakePlayer, second: FakePlayer, encounter: Dictionary,
		runtime_vorgar: Dictionary) -> void:
	arena.call("reset_attempt")
	first.restore()
	second.kill()
	first.global_position = Vector3.ZERO
	second.global_position = Vector3.ZERO
	arena.call("set_revive_intent", first, true)
	var fixed_delta := float(game_data.call("frames_to_seconds", 1.0))
	var channel := float((encounter.get("resurrection", {}) as Dictionary).get(
		"channel_seconds"))
	var ticks := ceili(channel / fixed_delta) + 2
	for _tick: int in ticks:
		arena.call("_physics_process", fixed_delta)
	var progression: Dictionary = game_data.get("progression")
	var resurrection_contract := progression.get("coop_resurrection", {}) as Dictionary
	_check(second.is_alive() and is_equal_approx(second.health,
		second.max_health * float(resurrection_contract.get("revived_health_fraction"))),
		"ressurreição conclui aos 6 s com 50% de vida")
	_check(bool(arena.call("resurrection_used")) and boss.target == first,
		"ressurreição consome a utilização e Vorgar fixa o ressuscitador")

	second.kill()
	for _tick: int in ticks:
		arena.call("_physics_process", fixed_delta)
	_check(not second.is_alive(),
		"custo: não há segunda ressurreição na mesma tentativa")

	arena.call("reset_attempt")
	first.restore()
	second.kill()
	arena.call("set_revive_intent", first, true)
	arena.call("_physics_process", fixed_delta)
	arena.call("_physics_process", fixed_delta)
	first.health -= float((runtime_vorgar.get("damage", {}) as Dictionary).get("light"))
	arena.call("_physics_process", fixed_delta)
	_check(float(arena.call("resurrection_progress_seconds")) == 0.0
		and not second.is_alive() and not bool(arena.call("resurrection_used")),
		"risco: dano apaga a canalização sem gastar a utilização")


func _tick_until_first_active(arena: Node3D, sequence: Dictionary) -> void:
	for frame: int in range(1, int(sequence.get("startup")) + 2):
		arena.call("tick_sequence", frame)


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % description)
	else:
		_failed += 1
		printerr("  FALHA %s" % description)


func _finish() -> void:
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		for child: Node in sfx.get_children():
			if child is AudioStreamPlayer or child is AudioStreamPlayer3D:
				child.call("stop")
				child.set("stream", null)
	print("\n=== VORGAR: %d passaram, %d falharam ===\n" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
