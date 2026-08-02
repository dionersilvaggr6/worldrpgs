extends SceneTree
## Prova focada do povoamento de Brumal. Corre sem montar modelos nem animacoes:
##   godot --headless --audio-driver Dummy --path game --script src/world/spawn_population_test.gd

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var enemies := _load_json("res://data/enemies.json")
	var named := _load_json("res://data/named_encounters.json")
	var population_script := load("res://src/world/spawn_population.gd") as Script
	var plan: Array[Dictionary] = population_script.call(
		"build_plan", "brumal", enemies, named)
	var budget: Dictionary = ((enemies.get("_zone_budgets", {}) as Dictionary).get(
		"brumal", {}) as Dictionary)
	var actor_limit := int(budget.get("animated_actor_limit", 0))
	var active_enemy_limit := int(budget.get("active_enemy_limit", 0))
	var contract_errors: PackedStringArray = population_script.call(
		"catalog_contract_errors", enemies, named, plan, actor_limit,
		active_enemy_limit)
	for error: String in contract_errors:
		_check(false, error)
	var expected_population: Dictionary = budget.get("population", {}) as Dictionary
	for enemy_id: String in expected_population:
		expected_population[enemy_id] = int(expected_population[enemy_id])
	var actual_population: Dictionary = {}
	var named_count := 0
	var guardian_count := 0
	for placement: Dictionary in plan:
		var enemy_id := String(placement.get("enemy_id", ""))
		var enemy: Dictionary = enemies.get(enemy_id, {}) as Dictionary
		_check((enemy.get("biome_ids", []) as Array).has("brumal"),
			"%s nao pertence ao bioma Brumal" % enemy_id)
		match String(placement.get("kind", "")):
			"common":
				actual_population[enemy_id] = int(actual_population.get(enemy_id, 0)) + 1
			"named":
				named_count += 1
			"guardian":
				guardian_count += 1
	_check(actual_population == expected_population,
		"populacao %s diverge do budget %s" % [actual_population, expected_population])
	_check(named_count == 3, "Brumal tem %d/3 encontros nomeados" % named_count)
	_check(guardian_count == 1, "Brumal tem %d/1 guardiao" % guardian_count)
	_check(plan.size() == 12, "Brumal tem %d/12 colocacoes" % plan.size())
	_check(int(population_script.call("distinct_world_type_count", plan)) == 7,
		"Brumal nao tem os 7 tipos logicos declarados")
	_test_named_variants(enemies, named)

	_check(actor_limit == 8, "o catalogo declara tecto %d, esperado 8" % actor_limit)
	_check(active_enemy_limit == 5,
		"Brumal permite %d/5 inimigos animados" % active_enemy_limit)
	var candidates: Array[Dictionary] = []
	for index: int in range(12):
		candidates.append({
			"placement_id": "candidate_%02d" % index,
			"position": Vector3(float(index * 4), 0.0, 0.0),
		})
	var selected: Array[String] = population_script.call("select_for_activation",
		candidates, Vector3.ZERO, 1, actor_limit, active_enemy_limit, 34.0)
	_check(selected.size() == 5,
		"um jogador activa %d/5 inimigos" % selected.size())
	_check(not selected.has("candidate_09"),
		"um actor fora da distancia de activacao entrou em cena")
	var after_walking: Array[String] = population_script.call("select_for_activation",
		candidates, Vector3(44.0, 0.0, 0.0), 1, actor_limit,
		active_enemy_limit, 20.0)
	_check(after_walking.size() == 5 and after_walking.has("candidate_11") \
		and not after_walking.has("candidate_00"),
		"a proximidade nao trocou o conjunto activo ao caminhar")

	if _failures.is_empty():
		print("[spawn-population] 7 tipos; 8 comuns + 3 nomeados + 1 guardiao; 5 inimigos/8 actores OK")
		quit(0)
		return
	for failure: String in _failures:
		printerr("[spawn-population] FALHA: %s" % failure)
	quit(1)


func _test_named_variants(enemies: Dictionary, named_catalog: Dictionary) -> void:
	var named_script := load("res://src/world/spawn_named_enemy.gd") as Script
	var encounters: Dictionary = named_catalog.get("encounters", {}) as Dictionary
	for named_id: String in encounters:
		var encounter: Dictionary = encounters[named_id] as Dictionary
		if String(encounter.get("zone_id", "")) != "brumal":
			continue
		var base_id := String(encounter.get("base_enemy_id", ""))
		var base: Dictionary = enemies.get(base_id, {}) as Dictionary
		var actor := named_script.new() as Node3D
		root.add_child(actor)
		actor.call("setup", base_id, {}, false, 1)
		var configured := bool(actor.call("configure_named", named_id))
		_check(configured, "%s nao configurou como encontro nomeado" % named_id)
		if configured:
			_check(String(actor.call("display_name")) == String(
				encounter.get("display_name", "")), "%s perdeu o nome" % named_id)
			_check(is_equal_approx(float(actor.get("max_health")),
				float(base.get("health", 0.0)) * float(encounter.get(
					"health_multiplier", 0.0))), "%s perdeu o multiplicador de PV" % named_id)
			_check(is_equal_approx(float(actor.get("max_posture")),
				float(base.get("posture", 0.0)) * float(encounter.get(
					"posture_multiplier", 0.0))), "%s perdeu o multiplicador de postura" % named_id)
			var extra_id := String((encounter.get("extra_attack", {}) as Dictionary).get(
				"id", ""))
			_check((actor.get("_attacks") as Dictionary).has(extra_id),
				"%s nao recebeu o golpe %s" % [named_id, extra_id])
			_check(String(actor.get_meta("guaranteed_loot", "")) == String(
				encounter.get("guaranteed_loot", "")), "%s perdeu o espolio" % named_id)
		actor.free()


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed as Dictionary
	_failures.append("nao foi possivel ler %s" % path)
	return {}


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
