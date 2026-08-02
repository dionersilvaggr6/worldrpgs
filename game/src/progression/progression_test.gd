extends SceneTree
## Prova isolada do ciclo de fogueira, morte e almas.
## Corre com:
## godot --headless --audio-driver Dummy --path game/ --script res://src/progression/progression_test.gd

const RULES_PATH := "res://src/progression/progression_rules.gd"
const RUNTIME_PATH := "res://src/progression/progression_runtime.gd"
const BONFIRE_PATH := "res://src/world/bonfire.gd"
const SOUL_STAIN_PATH := "res://src/progression/soul_stain.gd"


class FakeMeter extends RefCounted:
	var current := 1.0
	var maximum := 9.0

	func refill() -> void:
		current = maximum


class FakePlayer extends Node:
	var health := 1.0
	var max_health := 12.0
	var stamina := FakeMeter.new()
	var mana := 2.0
	var max_mana := 15.0
	var flask_uses := 0
	var flask_max := 4

	func flask_refill() -> void:
		flask_uses = flask_max


class FakeEnemy extends Node:
	var is_boss := false
	var alive := false
	var reset_count := 0

	func _init(placement_id: String, p_alive: bool, p_is_boss: bool = false) -> void:
		set_meta("placement_id", placement_id)
		alive = p_alive
		is_boss = p_is_boss

	func is_alive() -> bool:
		return alive

	func full_reset() -> void:
		alive = true
		reset_count += 1

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_soul_budget_belongs_to_each_placement()
	_test_loot_deck_and_soul_budget_are_independent()
	_test_second_death_replaces_the_old_stain()
	_test_reaching_the_stain_recovers_souls_once()
	_test_rest_respawns_a_placement_only_ten_times()
	_test_level_up_uses_the_canonical_cubic_cost()
	_test_ember_raises_only_its_zone_without_resetting_rewards()
	_test_ember_is_a_unique_placed_reward()
	_test_ember_initialises_zone_cycle_for_old_saves()
	_test_bonfire_restores_player_and_only_allowed_enemies()
	_test_soul_stain_has_procedural_presentation_and_recovers_on_reach()
	print("\n=== PROGRESSAO: %d passaram, %d falharam ===\n" % [_passed, _failed])
	await process_frame
	await process_frame
	quit(1 if _failed > 0 else 0)


func _test_soul_budget_belongs_to_each_placement() -> void:
	var rules_script: Variant = load(RULES_PATH)
	_check(rules_script != null, "almas: regras de progressao carregam")
	if rules_script == null:
		return
	var state := _state_fixture()
	var config := _progression_section("enemy_lifecycle")
	var reward_limit := int(config.get("rewarded_defeats_per_placement", 0))
	var game_data: Node = root.get_node("GameData")
	var base_souls := int((game_data.call("enemy", "orc_spearman") as Dictionary).get("souls", 0))
	for placement_id: String in ["brumal:lanceiro_01", "brumal:lanceiro_02"]:
		for defeat_index: int in range(reward_limit):
			var result: Dictionary = rules_script.award_enemy_souls(
				state, placement_id, "orc_spearman", "%s:%d" % [placement_id, defeat_index], base_souls, config)
			_check(String(result.get("status", "")) == "awarded",
				"almas/%s: derrota %d paga" % [placement_id, defeat_index + 1])
	var progression: Dictionary = (state.get("character", {}) as Dictionary).get(
		"progression", {}) as Dictionary
	_check(int(progression.get("souls_held", 0)) == base_souls * reward_limit * 2,
		"almas: duas colocacoes do mesmo tipo pagam dez derrotas cada")


func _test_loot_deck_and_soul_budget_are_independent() -> void:
	var runtime_script: Variant = load(RUNTIME_PATH)
	_check(runtime_script != null, "almas: transaccao integrada carrega")
	if runtime_script == null:
		return
	var state := _state_fixture()
	var config := _progression_section("enemy_lifecycle")
	var reward_limit := int(config.get("rewarded_defeats_per_placement", 0))
	var enemy_id := "orc_spearman"
	var game_data: Node = root.get_node("GameData")
	var base_souls := int((game_data.call("enemy", enemy_id) as Dictionary).get("souls", 0))
	var base_total := 0
	for placement_id: String in ["brumal:lanceiro_01", "brumal:lanceiro_02"]:
		for defeat_index: int in range(reward_limit):
			var result: Dictionary = runtime_script.apply_enemy_defeat_to_state(
				state, placement_id, enemy_id, "%s:%d" % [placement_id, defeat_index],
				1234, "warrior", config)
			base_total += int(result.get("base_souls_awarded", 0))
	_check(base_total == base_souls * reward_limit * 2,
		"almas: vinte colocacoes recompensadas pagam vinte bases")
	var deck_state: Dictionary = ((state.get("world", {}) as Dictionary).get(
		"loot_decks", {}) as Dictionary).get(enemy_id, {}) as Dictionary
	_check(int(deck_state.get("next_index", 0)) == reward_limit,
		"espolio: baralho do tipo fecha em dez sem duplicar cartas")
	var receipt_souls := 0
	for receipt_value: Variant in (state.get("world", {}) as Dictionary).get(
			"reward_receipts", []):
		receipt_souls += int((receipt_value as Dictionary).get("souls_awarded", 0))
	var held := int(((state.get("character", {}) as Dictionary).get(
		"progression", {}) as Dictionary).get("souls_held", 0))
	_check(receipt_souls == held,
		"recibos: soma publicada corresponde exactamente ao bolso")


func _test_second_death_replaces_the_old_stain() -> void:
	var rules_script: Variant = load(RULES_PATH)
	var state := _state_fixture()
	var character: Dictionary = state.get("character", {}) as Dictionary
	character["profile_id"] = "rico"
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	progression["souls_held"] = 120
	character["progression"] = progression
	character["death"] = {"soul_stain": null}
	state["character"] = character
	rules_script.record_death(state, "brumal", Vector3(1, 2, 3))
	progression = character.get("progression", {}) as Dictionary
	progression["souls_held"] = 45
	character["progression"] = progression
	rules_script.record_death(state, "toca", Vector3(7, 8, 9))
	var stain: Dictionary = ((character.get("death", {}) as Dictionary).get(
		"soul_stain", {}) as Dictionary)
	_check(int(stain.get("amount", 0)) == 45
		and int(stain.get("death_sequence", 0)) == 2
		and String(stain.get("zone_id", "")) == "toca"
		and int(progression.get("souls_held", -1)) == 0,
		"morte: segunda queda apaga a mancha antiga e larga apenas o bolso novo")


func _test_reaching_the_stain_recovers_souls_once() -> void:
	var rules_script: Variant = load(RULES_PATH)
	var state := _state_fixture()
	var character: Dictionary = state.get("character", {}) as Dictionary
	character["profile_id"] = "mateus"
	character["death"] = {"soul_stain": {
		"stain_id": "mateus:4", "amount": 321, "zone_id": "brumal",
		"position": [1.0, 0.0, 2.0], "death_sequence": 4,
	}}
	state["character"] = character
	var first: Dictionary = rules_script.recover_soul_stain(state, "mateus:4")
	var second: Dictionary = rules_script.recover_soul_stain(state, "mateus:4")
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	_check(String(first.get("status", "")) == "recovered"
		and int(first.get("souls_recovered", 0)) == 321
		and int(progression.get("souls_held", 0)) == 321
		and (character.get("death", {}) as Dictionary).get("soul_stain") == null
		and String(second.get("status", "")) == "missing",
		"mancha: chegar recupera as almas e a mesma mancha nao paga duas vezes")


func _test_rest_respawns_a_placement_only_ten_times() -> void:
	var rules_script: Variant = load(RULES_PATH)
	var state := _state_fixture()
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	world_state["enemy_respawns"] = {}
	world_state["rest_points_discovered"] = []
	state["world"] = world_state
	var placement_id := "brumal:lanceiro_01"
	var config := _progression_section("enemy_lifecycle")
	var respawn_limit := int(config.get("respawns_per_placement", 0))
	for rest_index: int in range(respawn_limit):
		var result: Dictionary = rules_script.rest(
			state, "brumal", "brumal_clareira", [placement_id], config)
		_check((result.get("respawned", []) as Array).has(placement_id),
			"descanso: reposicao %d ainda ressuscita a colocacao" % (rest_index + 1))
	var exhausted: Dictionary = rules_script.rest(
		state, "brumal", "brumal_clareira", [placement_id], config)
	var character: Dictionary = state.get("character", {}) as Dictionary
	var checkpoint: Dictionary = character.get("checkpoint", {}) as Dictionary
	_check(not (exhausted.get("respawned", []) as Array).has(placement_id)
		and (exhausted.get("exhausted", []) as Array).has(placement_id)
		and String(checkpoint.get("rest_point_id", "")) == "brumal_clareira",
		"descanso: depois de dez reposicoes o inimigo para e o checkpoint fica")


func _test_level_up_uses_the_canonical_cubic_cost() -> void:
	var runtime_script: Variant = load(RUNTIME_PATH)
	var game_data: Node = root.get_node("GameData")
	var state := _state_fixture()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	progression["level"] = 19
	progression["attributes"] = {"vida": 12}
	var cost := int(game_data.call("level_cost", 20))
	progression["souls_held"] = cost
	character["progression"] = progression
	state["character"] = character
	var result: Dictionary = runtime_script.apply_level_up_to_state(state, "vida")
	_check(String(result.get("status", "")) == "purchased"
		and int(result.get("cost", 0)) == cost
		and int(progression.get("level", 0)) == 20
		and int((progression.get("attributes", {}) as Dictionary).get("vida", 0)) == 13
		and int(progression.get("souls_held", -1)) == 0,
		"nivel: custo cubico compra exactamente um nivel e um ponto")


func _test_ember_raises_only_its_zone_without_resetting_rewards() -> void:
	var rules_script: Variant = load(RULES_PATH)
	var state := _state_fixture()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	progression["embers_held"] = 1
	character["progression"] = progression
	state["character"] = character
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	world_state["zone_cycles"] = {"brumal": 1, "toca": 1}
	world_state["embers_kindled"] = []
	world_state["enemy_respawns"] = {"brumal:lanceiro_01": 10, "toca:bruto_01": 10}
	world_state["enemy_soul_rewards"] = {"brumal:lanceiro_01": 10, "toca:bruto_01": 10}
	world_state["loot_decks"] = {"orc_spearman": {"next_index": 10}}
	world_state["bosses_defeated"] = ["vorgar", "chefe_toca"]
	state["world"] = world_state
	var before_souls: Dictionary = (world_state.get("enemy_soul_rewards", {}) as Dictionary).duplicate(true)
	var before_decks: Dictionary = (world_state.get("loot_decks", {}) as Dictionary).duplicate(true)
	var config := _progression_section("ember")
	var cycles := _progression_section("cycles")
	config["minimum_zone_cycle"] = int(cycles.get("min", 0))
	config["maximum_zone_cycle"] = int(cycles.get("max", 0))
	var result: Dictionary = rules_script.kindle_ember(state, "brumal",
		["brumal:lanceiro_01"], ["vorgar"], config)
	var zone_cycles: Dictionary = world_state.get("zone_cycles", {}) as Dictionary
	var respawns: Dictionary = world_state.get("enemy_respawns", {}) as Dictionary
	var bosses: Array = world_state.get("bosses_defeated", []) as Array
	_check(String(result.get("status", "")) == "kindled"
		and int(zone_cycles.get("brumal", 0)) == 2
		and int(zone_cycles.get("toca", 0)) == 1
		and not respawns.has("brumal:lanceiro_01")
		and respawns.has("toca:bruto_01")
		and world_state.get("enemy_soul_rewards", {}) == before_souls
		and world_state.get("loot_decks", {}) == before_decks
		and not bosses.has("vorgar") and bosses.has("chefe_toca")
		and int(progression.get("embers_held", -1)) == 0,
		"Brasa: sobe so uma zona e nao reabre almas nem baralho")


func _test_ember_is_a_unique_placed_reward() -> void:
	var rules_script: Variant = load(RULES_PATH)
	var state := _state_fixture()
	var first: Dictionary = rules_script.collect_placed_ember(state, "brumal:brasa_01")
	var second: Dictionary = rules_script.collect_placed_ember(state, "brumal:brasa_01")
	var progression: Dictionary = ((state.get("character", {}) as Dictionary).get(
		"progression", {}) as Dictionary)
	_check(String(first.get("status", "")) == "collected"
		and String(second.get("status", "")) == "already_collected"
		and int(progression.get("embers_held", 0)) == 1,
		"Brasa: recompensa colocada paga uma vez e nunca vira loja ou farm")


func _test_ember_initialises_zone_cycle_for_old_saves() -> void:
	var rules_script: Variant = load(RULES_PATH)
	var state := _state_fixture()
	var character: Dictionary = state.get("character", {}) as Dictionary
	var progression: Dictionary = character.get("progression", {}) as Dictionary
	progression["embers_held"] = 1
	character["progression"] = progression
	state["character"] = character
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	world_state["cycle"] = 0
	state["world"] = world_state
	var cycles := _progression_section("cycles")
	var config := _progression_section("ember")
	config["minimum_zone_cycle"] = int(cycles.get("min", 0))
	config["maximum_zone_cycle"] = int(cycles.get("max", 0))
	var result: Dictionary = rules_script.kindle_ember(
		state, "brumal", [], [], config)
	var zone_cycle := int(((world_state.get("zone_cycles", {}) as Dictionary).get(
		"brumal", 0)))
	_check(String(result.get("status", "")) == "kindled"
		and zone_cycle == int(cycles.get("min", 0))
			+ int(config.get("raises_exactly_one_zone_by_cycles", 0)),
		"Brasa: save antigo inicia a zona no ciclo minimo antes de subir")


func _test_bonfire_restores_player_and_only_allowed_enemies() -> void:
	var bonfire_script: Variant = load(BONFIRE_PATH)
	_check(bonfire_script != null, "fogueira: controlador publico carrega")
	if bonfire_script == null:
		return
	var bonfire: Node = bonfire_script.new()
	root.add_child(bonfire)
	var player := FakePlayer.new()
	var allowed := FakeEnemy.new("brumal:lanceiro_01", false)
	var exhausted := FakeEnemy.new("brumal:lanceiro_02", false)
	var alive := FakeEnemy.new("brumal:lanceiro_03", true)
	var other_zone := FakeEnemy.new("toca:bruto_01", true)
	var boss := FakeEnemy.new("brumal:vorgar", false, true)
	bonfire.call("configure", "brumal", "brumal_clareira")
	bonfire.call("apply_rest_effects", player, [allowed, exhausted, alive, other_zone, boss], {
		"status": "rested",
		"respawned": ["brumal:lanceiro_01"],
		"exhausted": ["brumal:lanceiro_02"],
	})
	var audio := bonfire.find_child("BonfireAudio", true, false) as AudioStreamPlayer
	_check(player.health == player.max_health
		and player.stamina.current == player.stamina.maximum
		and player.mana == player.max_mana
		and player.flask_uses == player.flask_max
		and allowed.reset_count == 1 and exhausted.reset_count == 0
		and alive.reset_count == 1 and other_zone.reset_count == 0 and boss.reset_count == 0
		and audio != null and audio.stream != null
		and String(bonfire.call("input_action")) == String(
			_progression_section("bonfire").get("input_action", "")),
		"fogueira: cura, repoe frascos e respeita tecto/bosses")
	if audio != null:
		audio.stop()
		audio.stream = null
	bonfire.free()
	player.free()
	allowed.free()
	exhausted.free()
	alive.free()
	other_zone.free()
	boss.free()


func _test_soul_stain_has_procedural_presentation_and_recovers_on_reach() -> void:
	var stain_script: Variant = load(SOUL_STAIN_PATH)
	_check(stain_script != null, "mancha: apresentacao publica carrega")
	if stain_script == null:
		return
	var stain := stain_script.new() as Node3D
	root.add_child(stain)
	var calls := {"count": 0}
	var recover := func(stain_id: String) -> Dictionary:
		calls["count"] = int(calls["count"]) + 1
		return {"status": "recovered", "stain_id": stain_id, "souls_recovered": 88}
	stain.call("configure", {
		"stain_id": "rico:8", "amount": 88, "zone_id": "brumal",
		"position": [2.0, 0.5, -3.0], "death_sequence": 8,
	}, recover)
	var result: Dictionary = stain.call("try_recover") as Dictionary
	var has_mesh := stain.find_child("SoulStainMesh", true, false) is MeshInstance3D
	var audio := stain.find_child("SoulStainAudio", true, false) as AudioStreamPlayer3D
	_check(has_mesh and audio != null and audio.stream != null
		and String(result.get("status", "")) == "recovered"
		and int(calls["count"]) == 1 and bool(stain.get("collected")),
		"mancha: tocar recupera uma vez com malha e som sintetizados")
	if audio != null:
		audio.stop()
		audio.stream = null
	stain.free()


func _state_fixture() -> Dictionary:
	return {
		"character": {
			"progression": {"souls_held": 0},
			"inventory": {"items": {}},
		},
		"world": {
			"enemy_soul_rewards": {},
			"loot_decks": {},
			"reward_receipts": [],
		},
	}


func _progression_section(section_name: String) -> Dictionary:
	var game_data: Node = root.get_node("GameData")
	var progression_data: Dictionary = game_data.get("progression") as Dictionary
	return (progression_data.get(section_name, {}) as Dictionary).duplicate(true)


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % description)
	else:
		_failed += 1
		printerr("  FALHA %s" % description)
