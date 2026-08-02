extends SceneTree
## Prova executavel da camada de espolio. Corre isolada para respeitar a
## propriedade de game/src/tests/self_test.gd de outro agente.

const LootPolicyScript = preload("res://src/loot/loot_policy.gd")
const ChestRewardServiceScript = preload("res://src/loot/chest_reward_service.gd")
const WorldChestScript = preload("res://src/world/chest.gd")
const LootFeedbackScript = preload("res://src/loot/loot_feedback.gd")
const ChestManagerScript = preload("res://src/world/chest_manager.gd")
const PickupManagerScript = preload("res://src/world/pickup_manager.gd")

var _passed := 0
var _failed := 0


class TestHud:
	extends Node
	var last_prompt := ""
	var last_toast := ""

	func set_prompt(message: String) -> void:
		last_prompt = message

	func toast(message: String, _seconds := 0.0) -> void:
		last_toast = message


class TestInventory:
	extends Node
	var added: Dictionary = {}

	func add_item(item_key: String, count: int) -> Dictionary:
		added[item_key] = int(added.get(item_key, 0)) + count
		return {"ok": true, "key": item_key, "count": count,
			"total": int(added[item_key]), "message": "recolhido"}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var enemies := _load_json("res://data/enemies.json")
	var economy := _load_json("res://data/economy.json")
	var policy = LootPolicyScript.new()
	_check(policy.configure(enemies, economy,
		_load_json("res://data/equipment.json")),
		"politica: os catalogos configuram uma fronteira publica")
	var expected: Array = (enemies.get("orc_spearman", {}) as Dictionary).get(
		"loot_cards", []) as Array
	var state := {}
	var drawn: Array[String] = []
	for draw_index: int in range(10):
		var result: Dictionary = policy.draw_common(
			state, "orc_spearman", 4301, "warrior")
		_check(String(result.get("status", "")) == "drawn",
			"baralho: compra %d existe" % (draw_index + 1))
		drawn.append(String(result.get("raw_card", "")))
	var exhausted: Dictionary = policy.draw_common(
		state, "orc_spearman", 4301, "warrior")
	_check(String(exhausted.get("status", "")) == "exhausted",
		"baralho: nao existe 11.a carta")
	_check(_same_multiset(drawn, expected),
		"baralho: as dez cartas saem uma vez sem reposicao")
	_test_all_common_decks(policy, enemies)
	_test_biome_filter(policy)
	_test_inventory_addition()
	_test_chests(policy, economy)
	_test_interest_comparison(policy)
	_test_all_item_feedback(policy, enemies)
	_test_presentation_contract(economy, _load_json("res://data/controls.json"))
	_test_world_manager(economy, enemies, policy)
	await _test_enemy_ground_pickup(economy, enemies)
	print("=== espolio: %d passaram, %d falharam ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_inventory_addition() -> void:
	var item_key := "consumivel:resina_bruma"
	var state := _inventory_state({}, "longsword")
	var inventory: Dictionary = ((state.get("character", {}) as Dictionary).get(
		"inventory", {}) as Dictionary)
	inventory["favorite_items"] = [item_key]
	inventory["quick_slots"] = [item_key]
	var inventory_system := root.get_node("InventorySystem")
	var result: Dictionary = inventory_system.call(
		"add_item_to_state", state, item_key, 2) as Dictionary
	var items: Dictionary = (((state.get("character", {}) as Dictionary).get(
		"inventory", {}) as Dictionary).get("items", {}) as Dictionary)
	_check(bool(result.get("ok", false)) and int(items.get(item_key, 0)) == 2,
		"recolha: acrescenta a quantidade ao inventario sem limite")
	_check((inventory_system.call("quick_slot_candidates", "item", state) as Array).has(item_key),
		"recolha: um consumivel favorito pode ir para o acesso rapido")
	var invalid_key := "arma:id_inexistente"
	var invalid: Dictionary = inventory_system.call(
		"add_item_to_state", state, invalid_key, 1) as Dictionary
	_check(not bool(invalid.get("ok", false)) and not items.has(invalid_key),
		"recolha: ID fora dos catalogos falha fechado")


func _test_all_common_decks(policy: RefCounted, enemies: Dictionary) -> void:
	var common_count := 0
	for enemy_id: String in enemies:
		if enemy_id.begins_with("_"):
			continue
		var enemy: Dictionary = enemies.get(enemy_id, {}) as Dictionary
		if bool(enemy.get("is_boss", false)):
			continue
		common_count += 1
		var expected: Array = enemy.get("loot_cards", []) as Array
		var state := {}
		var drawn: Array[String] = []
		for _draw_index: int in range(expected.size()):
			var result: Dictionary = policy.draw_common(
				state, enemy_id, 4300 + common_count, "warrior")
			drawn.append(String(result.get("raw_card", "")))
		_check(_same_multiset(drawn, expected),
			"baralho/%s: todas as cartas saem uma vez" % enemy_id)
		_check(String(policy.draw_common(state, enemy_id, 4300 + common_count,
			"warrior").get("status", "")) == "exhausted",
			"baralho/%s: termina depois da decima" % enemy_id)
	_check(common_count == 33, "baralho: os 33 tipos comuns foram exercitados")


func _test_biome_filter(policy: RefCounted) -> void:
	var errors: PackedStringArray = policy.validate_common_decks()
	_check(errors.is_empty(),
		"bioma: todas as cartas comuns pertencem ao bioma do tipo")
	_check(not policy.item_allowed_in_biome("material:obsidiana", "brumal"),
		"bioma: obsidiana da Fornalha e rejeitada em Brumal")
	var filtered: Dictionary = policy.resolve_card_for_biome(
		"orc_spearman", "material:obsidiana", "warrior")
	_check(String(filtered.get("status", "")) == "wrong_biome",
		"bioma: uma carta alienigena nao chega ao jogador")


func _test_chests(policy: RefCounted, economy: Dictionary) -> void:
	var service = ChestRewardServiceScript.new()
	_check(service.configure(economy, policy),
		"bau: o servico aceita o catalogo desenhado")
	var definitions: Dictionary = economy.get("chests", {}) as Dictionary
	_check(definitions.size() >= 3, "bau: Brumal tem pelo menos tres desvios pagos")
	for chest_id: String in definitions:
		var definition: Dictionary = definitions.get(chest_id, {}) as Dictionary
		_check((definition.get("rewards", []) as Array).size() >= 2,
			"bau/%s: o desvio entrega opcoes, nao lixo isolado" % chest_id)
		_check(not definition.has("seed") and not definition.has("weights"),
			"bau/%s: conteudo nao usa sorte" % chest_id)

	var state := _inventory_state({"arma:longsword": 1000000}, "longsword")
	var first_id := String(definitions.keys()[0]) if not definitions.is_empty() else ""
	var opened: Dictionary = service.open_chest(state, first_id)
	_check(String(opened.get("status", "")) == "opened",
		"bau: a abertura entrega o conjunto desenhado")
	_check(int((((state.get("character", {}) as Dictionary).get(
		"inventory", {}) as Dictionary).get("items", {}) as Dictionary).get(
		"arma:longsword", 0)) >= 1000000,
		"mochila: um inventario enorme nao impede a recolha")
	var repeated: Dictionary = service.open_chest(state, first_id)
	_check(String(repeated.get("status", "")) == "already_opened",
		"bau: reabrir nao duplica o espolio")


func _inventory_state(items: Dictionary, equipped_main: String) -> Dictionary:
	return {
		"character": {"inventory": {"items": items.duplicate(true), "equipment": {
			"main": equipped_main, "offhand": null, "armor": [], "rings": [],
			"spell_favorites": [],
		}}},
		"world": {"opened_chests": []},
	}


func _test_interest_comparison(policy: RefCounted) -> void:
	var state := _inventory_state({"arma:longsword": 1}, "longsword")
	var different: Dictionary = policy.describe_interest("arma:dagger", state)
	_check(String(different.get("name", "")) == "Adaga"
		and String(different.get("reason", "")).contains("Espada longa"),
		"feedback: item novo compara com o equipado pelo nome")
	_check(String(different.get("reason", "")).contains("conquistar as costas"),
		"feedback: a comparacao diz que nova opcao interessa")
	var duplicate: Dictionary = policy.describe_interest("arma:longsword", state)
	_check(String(duplicate.get("reason", "")).contains("voto alternativo"),
		"feedback: uma copia explica o seu uso em vez de parecer lixo")


func _test_all_item_feedback(policy: RefCounted, enemies: Dictionary) -> void:
	var state := _inventory_state({"arma:longsword": 1}, "longsword")
	var checked := {}
	for enemy_id: String in enemies:
		if enemy_id.begins_with("_"):
			continue
		var enemy: Dictionary = enemies.get(enemy_id, {}) as Dictionary
		if bool(enemy.get("is_boss", false)):
			continue
		for raw_value: Variant in enemy.get("loot_cards", []) as Array:
			var raw_card := String(raw_value)
			if raw_card.begins_with("almas_bonus:"):
				continue
			var card := raw_card
			if raw_card == "bias:classe":
				var resolved: Dictionary = policy.resolve_card_for_biome(
					enemy_id, raw_card, "warrior")
				card = String(resolved.get("card", ""))
			if checked.has(card):
				continue
			checked[card] = true
			var description: Dictionary = policy.describe_interest(card, state)
			_check(not String(description.get("name", "")).is_empty()
				and not String(description.get("reason", "")).is_empty(),
				"feedback/%s: explica a utilidade no momento da queda" % card)
	_check(checked.size() >= 150,
		"feedback: a prova percorre o catalogo comum, nao uma amostra")


func _test_presentation_contract(economy: Dictionary, controls: Dictionary) -> void:
	var rules: Dictionary = economy.get("loot_presentation", {}) as Dictionary
	var actions: Dictionary = controls.get("actions", {}) as Dictionary
	var interact_bindings: Array = actions.get("interact", []) as Array
	var has_e := false
	var has_x := false
	for binding_value: Variant in interact_bindings:
		var binding: Dictionary = binding_value as Dictionary
		has_e = has_e or (String(binding.get("type", "")) == "key"
			and String(binding.get("key", "")) == "E")
		has_x = has_x or (String(binding.get("type", "")) == "joypad_button"
			and int(binding.get("button", -1)) == 2)
	_check(String(rules.get("interaction_action", "")) == "interact"
		and has_e and has_x,
		"fio solto 1: o jogador usa E/X pela accao interact")
	var chest = WorldChestScript.new()
	root.add_child(chest)
	chest.configure("test_chest", {
		"display_name": "Bau de prova", "position": [0, 0, 0],
		"visual": "carvalho-negro e ferro rude", "rewards": [],
	}, rules)
	var chest_contract: Dictionary = chest.presentation_contract()
	_check(int(chest_contract.get("mesh_instances", 99)) == 2
		and int(chest_contract.get("lights", 99)) == 0,
		"fio solto 4: cada bau custa dois meshes e zero luzes")
	_check(String(chest_contract.get("art_source", "")).contains("codigo"),
		"fio solto 3: o bau declara arte sintetizada em codigo")
	var feedback = LootFeedbackScript.new()
	root.add_child(feedback)
	feedback.configure({"name": "Adaga", "reason": "abre outra pergunta"}, rules)
	var feedback_contract: Dictionary = feedback.presentation_contract()
	_check(bool(feedback_contract.get("visible", false))
		and bool(feedback_contract.get("audible", false)),
		"recolha: forma/glifo e som confirmam o item")
	feedback.queue_free()
	chest.queue_free()


func _test_world_manager(economy: Dictionary, enemies: Dictionary,
		policy: RefCounted) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player := Node3D.new()
	root.add_child(player)
	var hud := TestHud.new()
	root.add_child(hud)
	var state := _inventory_state({"arma:longsword": 1}, "longsword")
	var manager = ChestManagerScript.new()
	root.add_child(manager)
	var configured: bool = manager.setup(world, player, hud, "brumal", {
		"economy": economy,
		"enemies": enemies,
		"equipment": _load_json("res://data/equipment.json"),
		"state": state,
	})
	_check(configured and manager.chest_count() == 3,
		"mundo: o gestor instancia os tres baus visiveis de Brumal")
	var first_id := String((economy.get("chests", {}) as Dictionary).keys()[0])
	var opened: Dictionary = manager.open_chest(first_id)
	_check(String(opened.get("status", "")) == "opened"
		and not String(hud.last_toast).is_empty(),
		"mundo: interact abre, guarda e apresenta a recompensa")
	var before := _inventory_state({"arma:longsword": 1}, "longsword")
	manager.present_enemy_reward({"resolved_card": "arma:dagger"},
		Vector3.ZERO, before)
	_check(String(hud.last_toast).contains("conquistar as costas"),
		"comuns: a fronteira de morte apresenta a comparacao capturada")
	_check(not policy.describe_interest("arma:dagger", before).is_empty(),
		"comuns: o gestor usa a mesma politica provada")
	manager.queue_free()
	hud.queue_free()
	player.queue_free()
	world.queue_free()


func _test_enemy_ground_pickup(economy: Dictionary, enemies: Dictionary) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player := Node3D.new()
	root.add_child(player)
	var hud := TestHud.new()
	root.add_child(hud)
	var inventory := TestInventory.new()
	root.add_child(inventory)
	var manager = PickupManagerScript.new()
	root.add_child(manager)
	var configured: bool = manager.setup(world, player, hud, "brumal", {
		"economy": economy,
		"enemies": enemies,
		"equipment": _load_json("res://data/equipment.json"),
		"inventory_system": inventory,
		"mount_chests": false,
	})
	var at := Vector3(4.0, 0.0, 0.0)
	var spawned: Dictionary = manager.present_enemy_reward({
		"event_id": "enemy:orc_spearman:0",
		"resolved_card": "arma:dagger",
	}, at, _inventory_state({"arma:dagger": 1}, "longsword"))
	var pickups: Array = manager.active_pickups()
	var audit: Dictionary = pickups[0].call("audit") as Dictionary \
		if pickups.size() == 1 else {}
	_check(configured and String(spawned.get("status", "")) == "spawned"
		and pickups.size() == 1 and int(audit.get("mesh_instances", 0)) == 2
		and int(audit.get("dynamic_lights", -1)) == 0,
		"queda: morte apresenta silhueta e brilho baratos no chao")
	player.global_position = at
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")
	await process_frame
	_check(manager.pickup_count() == 0 and hud.last_toast.contains("Adaga"),
		"recolha: aproximar e carregar em interact confirma o item visivelmente")
	var consumable_key := "consumivel:resina_bruma"
	var second_at := Vector3(5.0, 0.0, 0.0)
	manager.spawn_pickup(consumable_key, 2, second_at, {"interest": {
		"name": "Resina de Bruma", "reason": "Prepara outra resposta.",
	}})
	player.global_position = second_at
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")
	await process_frame
	_check(int(inventory.added.get(consumable_key, 0)) == 2
		and manager.pickup_count() == 0,
		"recolha: item pendente entra no inventario antes de desaparecer")
	manager.queue_free()
	hud.queue_free()
	inventory.queue_free()
	player.queue_free()
	world.queue_free()
	for _cleanup_frame: int in 3:
		await process_frame


func _same_multiset(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	var counts := {}
	for value: Variant in left:
		counts[value] = int(counts.get(value, 0)) + 1
	for value: Variant in right:
		counts[value] = int(counts.get(value, 0)) - 1
	for count: Variant in counts.values():
		if int(count) != 0:
			return false
	return true


func _load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FALHOU: %s" % label)
