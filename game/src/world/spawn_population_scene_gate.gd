extends Node
## Guarda da sessao jogada: conta os tipos no plano real de povoamento.
## O plano representa o mundo inteiro mesmo quando so os corpos proximos existem.

const MINIMUM_DISTINCT_WORLD_TYPES := 6
const MAXIMUM_ANIMATED_ACTORS := 8
const MAXIMUM_ACTIVE_ENEMIES := 5


func _ready() -> void:
	call_deferred("_verify_population")


func _verify_population() -> void:
	var managers := get_tree().get_nodes_in_group("spawn_population")
	if managers.size() != 1:
		_fail("foram encontrados %d/1 gestores SpawnPopulation" % managers.size())
		return
	var manager: Node = managers[0] as Node
	var contract_errors: PackedStringArray = manager.get_meta(
		"population_contract_errors", PackedStringArray()) as PackedStringArray
	if not contract_errors.is_empty():
		_fail("; ".join(contract_errors))
		return
	var distinct_types := int(manager.get_meta("distinct_world_types", 0))
	if distinct_types < MINIMUM_DISTINCT_WORLD_TYPES:
		_fail("Brumal tem %d/%d tipos distintos no mundo" % [
			distinct_types, MINIMUM_DISTINCT_WORLD_TYPES])
		return
	var actor_limit := int(manager.get_meta("animated_actor_limit", 0))
	if actor_limit != MAXIMUM_ANIMATED_ACTORS:
		_fail("o tecto declara %d/%d actores animados" % [
			actor_limit, MAXIMUM_ANIMATED_ACTORS])
		return
	var enemy_limit := int(manager.get_meta("active_enemy_limit", 0))
	if enemy_limit != MAXIMUM_ACTIVE_ENEMIES:
		_fail("o tecto permite %d/%d inimigos animados" % [
			enemy_limit, MAXIMUM_ACTIVE_ENEMIES])
		return
	var active_actors := int(manager.call("active_animated_actor_count"))
	if active_actors > actor_limit:
		_fail("a cena arrancou com %d/%d actores animados" % [
			active_actors, actor_limit])
		return
	print("[sessao]   ok   variedade: %d tipos distintos no mundo; tecto %d actores" % [
		distinct_types, actor_limit])


func _fail(message: String) -> void:
	printerr("[sessao] FALHA povoamento: %s" % message)
	get_tree().quit(1)
