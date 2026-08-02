extends Node
## Prova focal da necromancia ligada ao mundo. Corre com:
##   godot --headless --audio-driver Dummy --path game/ \
##     res://src/summons/necromancy_runtime_self_test.tscn

const NecromancyRuntimeScript := preload("res://src/summons/necromancy_runtime.gd")
const EnemyScript := preload("res://src/enemies/enemy.gd")

class FakeCaster extends Node3D:
	signal state_changed(state: int)
	var class_id := "evil_mage"
	var health := 1.0
	var max_health := 1.0
	var input_enabled := false
	var alive := true
	var selected_spell := ""
	var _cast_spell: Dictionary = {}

	func begin_cast(spell_id: String, spell: Dictionary) -> void:
		selected_spell = spell_id
		_cast_spell = spell
		state_changed.emit(5)

	func finish_cast() -> void:
		state_changed.emit(0)

	func interrupt_cast() -> void:
		_cast_spell = {}
		state_changed.emit(6)

	func state_name() -> String:
		return "livre"

	func is_alive() -> bool:
		return alive

	func die() -> void:
		alive = false
		_cast_spell = {}
		state_changed.emit(7)


class FakeEnemy extends Node3D:
	signal died(enemy: Node3D)
	var enemy_id := "orc_spearman"
	var data := {"necromancy_body_size": "medio"}
	var is_boss := false
	var max_health := 1.0
	var alive := true

	func fall() -> void:
		alive = false
		died.emit(self)

	func is_alive() -> bool:
		return alive


var _passed := 0
var _failed := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node3D.new()
	add_child(stage)
	var caster := FakeCaster.new()
	stage.add_child(caster)
	var runtime = NecromancyRuntimeScript.new()
	stage.add_child(runtime)
	_check(runtime.setup(caster, stage, &"caster-local", &"sim-local",
		_load_json("res://data/attributes.json"),
		_load_json("res://data/abilities.json"),
		_load_json("res://data/spells.json"), {},
		(_load_json("res://data/enemies.json").get("_presentation", {})
			as Dictionary)),
		"runtime aceita a origem e os catálogos reais")
	_check(runtime.audio_cues_ready(),
		"levantamento e ordem têm som sintetizado sem binário externo")
	var partner_caster := FakeCaster.new()
	stage.add_child(partner_caster)
	var partner_runtime = NecromancyRuntimeScript.new()
	stage.add_child(partner_runtime)
	partner_runtime.setup(partner_caster, stage, &"caster-partner",
		&"sim-host", _load_json("res://data/attributes.json"),
		_load_json("res://data/abilities.json"),
		_load_json("res://data/spells.json"))

	var enemy := FakeEnemy.new()
	stage.add_child(enemy)
	enemy.position = Vector3.FORWARD
	var visible_body := MeshInstance3D.new()
	visible_body.mesh = BoxMesh.new()
	enemy.add_child(visible_body)
	runtime.watch_enemy(enemy, "test-zone:enemy-0")
	partner_runtime.watch_enemy(enemy, "test-zone:enemy-0")
	enemy.fall()
	await get_tree().process_frame
	_check(runtime.corpse_count() == 1 and partner_runtime.corpse_count() == 1
		and runtime.corpses()[0] == partner_runtime.corpses()[0]
		and runtime.corpses()[0].corpse_id == "test-zone:enemy-0",
		"uma morte deixa um único cadáver partilhado entre dois necromantes")
	_check(runtime.corpses()[0].is_visible_corpse(),
		"o cadáver conserva no mundo o corpo que o jogador viu cair")
	var preview: Dictionary = runtime.validate_raise_target("levantar")
	_check(bool(preview.get("accepted", false))
		and runtime.summon_count() == 0 and runtime.corpse_count() == 1
		and is_equal_approx(caster.max_health, 1.0),
		"pré-validar alvo e orçamento não consome corpo, PV nem invocação")
	var raised: Dictionary = runtime.raise_nearest("levantar")
	await get_tree().process_frame
	_check(bool(raised.get("accepted", false)) and runtime.summon_count() == 1
		and runtime.corpse_count() == 0 and not is_instance_valid(enemy),
		"Levantar consome e liberta o corpo velho ao materializar o aliado")
	var duplicate: Dictionary = partner_runtime.raise_nearest("levantar")
	_check(not bool(duplicate.get("accepted", false))
		and partner_runtime.summon_count() == 0,
		"o claim atómico impede dois necromantes de levantarem o mesmo corpo")
	_check(is_equal_approx(caster.max_health,
		float(raised.get("available_health_fraction", 0.0))),
		"o custo do invocado aparece imediatamente na vida máxima visível")
	var allies: Array = runtime.call("summons") if runtime.has_method("summons") else []
	var ally = allies[0] if not allies.is_empty() else null
	_check(ally != null and ally.is_in_group("summons")
		and not ally.is_in_group("enemies")
		and ally.caster_owner_id == &"caster-local"
		and ally.simulation_authority_id == &"sim-local",
		"o invocado não recebe fogo amigo e separa dono de autoridade co-op")
	var hostile = EnemyScript.new()
	stage.add_child(hostile)
	hostile.setup("orc_spearman", {})
	hostile.set_physics_process(false)
	var chase_distance := float(ally.data.get("preferred_distance", 0.0)) \
		+ float(ally.data.get("attack_range", 0.0))
	hostile.global_position = ally.global_position + Vector3.FORWARD * chase_distance
	if runtime.has_method("refresh_summon_targets"):
		runtime.call("refresh_summon_targets")
	var walk_start := Vector2(ally.global_position.x, ally.global_position.z) \
		.distance_to(Vector2(hostile.global_position.x, hostile.global_position.z))
	for _frame: int in 20:
		await get_tree().physics_frame
	var walk_end := Vector2(ally.global_position.x, ally.global_position.z) \
		.distance_to(Vector2(hostile.global_position.x, hostile.global_position.z))
	_check(walk_end < walk_start,
		"o levantado anda lentamente na direcção do inimigo escolhido")
	var hostile_health_before: float = hostile.health
	var attacks := ally.data.get("attacks", []) as Array if ally != null else []
	if ally != null and not attacks.is_empty():
		hostile.global_position = ally.global_position \
			+ Vector3.FORWARD * ally.body_radius
		ally.look_at(hostile.global_position, Vector3.UP)
		ally.set("_atk", attacks[0] as Dictionary)
		ally.call("_try_hit")
	_check(ally != null and ally.target == hostile
		and hostile.health < hostile_health_before and hostile.target == ally,
		"o levantado escolhe, fere e chama a resposta de um inimigo vivo")
	var second_enemy := FakeEnemy.new()
	stage.add_child(second_enemy)
	second_enemy.position = Vector3.FORWARD * 2.0
	var second_body := MeshInstance3D.new()
	second_body.mesh = BoxMesh.new()
	second_enemy.add_child(second_body)
	runtime.watch_enemy(second_enemy)
	second_enemy.fall()
	var raise_spell := _load_json("res://data/spells.json").get(
		"levantar", {}) as Dictionary
	caster.begin_cast("levantar", raise_spell)
	caster.finish_cast()
	await get_tree().process_frame
	_check(runtime.summon_count() == 2,
		"C materializa Levantar apenas quando a conjuração termina")
	var order_before := String(ally.order)
	caster.input_enabled = true
	Input.action_press("ability")
	await get_tree().physics_frame
	await get_tree().process_frame
	Input.action_release("ability")
	_check(String(ally.order) != order_before,
		"V alterna a ordem de todos os bichinhos pela ação remapeável")
	var interrupted_enemy := FakeEnemy.new()
	stage.add_child(interrupted_enemy)
	interrupted_enemy.position = Vector3.FORWARD * 3.0
	var interrupted_body := MeshInstance3D.new()
	interrupted_body.mesh = BoxMesh.new()
	interrupted_enemy.add_child(interrupted_body)
	runtime.watch_enemy(interrupted_enemy)
	interrupted_enemy.fall()
	caster.begin_cast("levantar", raise_spell)
	caster.interrupt_cast()
	await get_tree().process_frame
	_check(runtime.summon_count() == 2 and runtime.corpse_count() == 1,
		"interromper a conjuração conserva o cadáver e não cria aliado")
	var health_before_rest := caster.health
	var rest_result: Dictionary = runtime.rest()
	await get_tree().process_frame
	_check(float(rest_result.get("released_health_fraction", 0.0)) > 0.0
		and runtime.summon_count() == 0
		and runtime.corpse_count() == 0 and is_instance_valid(interrupted_enemy)
		and is_equal_approx(caster.max_health, 1.0)
		and is_equal_approx(caster.health, health_before_rest),
		"descansar limpa corpos/invocados, devolve a barra e não cura PV")
	var death_enemy := FakeEnemy.new()
	stage.add_child(death_enemy)
	death_enemy.position = Vector3.FORWARD
	death_enemy.add_child(MeshInstance3D.new())
	runtime.watch_enemy(death_enemy)
	death_enemy.fall()
	runtime.raise_nearest("levantar")
	caster.die()
	await get_tree().process_frame
	_check(runtime.summon_count() == 0 and runtime.corpse_count() == 0
		and is_equal_approx(caster.max_health, 1.0),
		"morrer limpa automaticamente invocações e reservas antes do respawn")

	stage.queue_free()
	for _cleanup_frame: int in 3:
		await get_tree().process_frame
	print("[necromancia-runtime] %d passaram, %d falharam" % [_passed, _failed])
	get_tree().quit(0 if _failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("[necromancia-runtime] FALHOU: %s" % label)


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}
