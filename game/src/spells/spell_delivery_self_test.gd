extends SceneTree
## Prova focal das formas de magia. Corre sem tocar no self_test global:
##   godot --headless --audio-driver Dummy --path game \
##     --script res://src/spells/spell_delivery_self_test.gd

const SpellDelivery = preload("res://src/spells/spell_delivery.gd")
const SpellDeliveryFactory = preload("res://src/spells/spell_delivery_factory.gd")
const SpellVfxResidency = preload("res://src/vfx/spell_vfx_residency.gd")
const SpellVfx = preload("res://src/vfx/spell_vfx.gd")

var _passed := 0
var _failed := 0
var _catalog: Dictionary = {}


class TestTarget extends Node3D:
	var contacts: Array[Dictionary] = []

	func spell_contact_radius_m() -> float:
		return 0.0

	func receive_spell_contact(payload: Dictionary) -> void:
		contacts.append(payload)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_catalog = _load_catalog()
	_test_projectile_moves_from_catalogue()
	_test_moving_volume_hits_once_per_passage()
	_test_instant_contact_closes_with_visible_effect()
	_test_persistent_volume_pulses_only_while_visible()
	_test_factory_builds_every_declared_form()
	_test_piercing_stops_after_declared_targets()
	_test_hunter_turns_and_breaks_on_line_of_sight()
	_test_orbiting_form_keeps_declared_bodies_around_caster()
	_test_beams_keep_their_distinct_geometry()
	_test_cone_emits_declared_arc_over_cadence()
	_test_one_cone_impact_does_not_cancel_the_barrage()
	_test_rain_falls_and_dies_on_ceiling()
	_test_solid_collision_closes_a_spent_delivery()
	_test_carrier_moves_and_releases_seekers()
	_test_non_damage_wave_expands_once_through_target()
	_test_bait_stays_and_lures_on_declared_pulse()
	_test_vfx_residency_keeps_only_equipped_spells()
	_test_contact_geometry_shares_the_hitbox_clock()
	print("[magia+vfx] %d passaram, %d falharam" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_projectile_moves_from_catalogue() -> void:
	var delivery := SpellDelivery.new()
	root.add_child(delivery)
	var spell: Dictionary = _catalog.get("dardo", {}) as Dictionary
	var contract := _contract_for(spell)
	delivery.configure("dardo", spell, contract, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"manual": true,
	})
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	delivery.advance(tick, [])
	var snapshot: Dictionary = delivery.snapshot()
	var expected := Vector3.FORWARD * float(contract.get("speed_m_s")) * tick
	_check((snapshot.get("primary_position", Vector3.ZERO) as Vector3).is_equal_approx(expected),
		"projéctil simples percorre velocidade × tempo declarados no catálogo")
	_check(String(snapshot.get("delivery_form", "")) == "projectil_simples",
		"projéctil simples conserva a forma pública")
	delivery.queue_free()


func _test_instant_contact_closes_with_visible_effect() -> void:
	var instant_contract: Dictionary = ((_catalog.get("_contact_contracts", {}) as Dictionary).get(
		"instantaneo", {}) as Dictionary)
	var active_frames := int(instant_contract.get("active_frames", 0))
	_check(active_frames >= 3 and active_frames <= 6,
		"contacto instantâneo declara exactamente 3–6 frames")
	if active_frames <= 0:
		return
	var delivery := SpellDelivery.new()
	root.add_child(delivery)
	var spell: Dictionary = _catalog.get("lamina_astral", {}) as Dictionary
	var contract := _contract_for(spell)
	contract.merge(instant_contract, true)
	var target := TestTarget.new()
	root.add_child(target)
	target.global_position = Vector3.FORWARD * float(contract.get("max_range_m"))
	delivery.configure("lamina_astral", spell, contract, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"manual": true,
	})
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	for frame: int in active_frames:
		var snapshot: Dictionary = delivery.snapshot()
		_check(bool(snapshot.get("hitbox_active", false))
			and bool(snapshot.get("contact_visual_visible", false)),
			"instantâneo frame %d mostra exactamente a hitbox viva" % (frame + 1))
		delivery.advance(tick, [target])
	var closed: Dictionary = delivery.snapshot()
	_check(not bool(closed.get("hitbox_active", true))
		and not bool(closed.get("contact_visual_visible", true))
		and not bool(closed.get("alive", true)),
		"instantâneo fecha visual e hitbox no mesmo frame")
	_check(target.contacts.size() == 1,
		"forma de arma contacta uma vez durante os frames visíveis")
	target.queue_free()
	delivery.queue_free()


func _test_moving_volume_hits_once_per_passage() -> void:
	var delivery := SpellDelivery.new()
	root.add_child(delivery)
	var spell: Dictionary = _catalog.get("dardo", {}) as Dictionary
	var contract := _contract_for(spell)
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var target := TestTarget.new()
	root.add_child(target)
	target.global_position = Vector3.FORWARD * float(contract.get("speed_m_s")) * tick
	delivery.configure("dardo", spell, contract, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"manual": true,
	})
	delivery.advance(tick, [target])
	delivery.advance(tick, [target])
	_check(target.contacts.size() == 1,
		"volume móvel acerta o alvo uma vez por passagem")
	var snapshot: Dictionary = delivery.snapshot()
	_check(not bool(snapshot.get("alive", true))
		and not bool(snapshot.get("hitbox_active", true))
		and not bool(snapshot.get("contact_visual_visible", true)),
		"projéctil termina hitbox e visual no mesmo contacto")
	target.queue_free()
	delivery.queue_free()


func _test_persistent_volume_pulses_only_while_visible() -> void:
	var delivery := SpellDelivery.new()
	root.add_child(delivery)
	var spell: Dictionary = _catalog.get("chama_faminta", {}) as Dictionary
	var contract := _contract_for(spell)
	contract.merge(((_catalog.get("_contact_contracts", {}) as Dictionary).get(
		"volume_persistente", {}) as Dictionary), false)
	var target := TestTarget.new()
	root.add_child(target)
	target.global_position = Vector3.FORWARD * float(contract.get("max_range_m"))
	delivery.configure("chama_faminta", spell, contract, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"manual": true,
	})
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var lifetime := float(contract.get("lifetime_s"))
	var elapsed := 0.0
	while elapsed < lifetime:
		var snapshot: Dictionary = delivery.snapshot()
		_check(bool(snapshot.get("hitbox_active", false))
			== bool(snapshot.get("contact_visual_visible", true)),
			"volume persistente mantém hitbox e efeito no mesmo relógio")
		delivery.advance(tick, [target])
		elapsed += tick
	var pulse := float(contract.get("pulse_s"))
	var expected_contacts := roundi(lifetime / pulse)
	_check(target.contacts.size() == expected_contacts,
		"volume persistente aplica exactamente um contacto por intervalo declarado (%d/%d)" % [
			target.contacts.size(), expected_contacts])
	var closed: Dictionary = delivery.snapshot()
	_check(not bool(closed.get("alive", true))
		and not bool(closed.get("hitbox_active", true))
		and not bool(closed.get("contact_visual_visible", true)),
		"volume persistente desaparece quando deixa de contactar")
	target.queue_free()
	delivery.queue_free()


func _test_factory_builds_every_declared_form() -> void:
	var representatives := {
		"projectil_simples": "dardo",
		"perfurante": "lanca_fulgor",
		"perseguidor": "cacador_azul",
		"orbitante": "coroa_brasa",
		"feixe": "chama_faminta",
		"feixe_rasteiro": "rasto_carvao",
		"barragem_cone": "chuva_cinzenta",
		"chuva": "granizo_carmim",
		"forma_arma": "lamina_astral",
		"portador": "ruina",
		"onda_sem_dano": "peso",
		"isco": "coro",
	}
	_check(representatives.keys().size() == (_catalog.get("_delivery_forms", []) as Array).size(),
		"prova focal escolhe um exemplar de cada forma declarada")
	for form: String in representatives:
		var delivery: Node3D = SpellDeliveryFactory.create(
			String(representatives[form]), _catalog, {
				"origin": Vector3.ZERO,
				"direction": Vector3.FORWARD,
				"manual": true,
			})
		_check(delivery != null, "fábrica constrói %s" % form)
		if delivery == null:
			continue
		root.add_child(delivery)
		var snapshot: Dictionary = delivery.call("snapshot") as Dictionary
		_check(String(snapshot.get("delivery_form", "")) == form,
			"fábrica publica o comportamento %s" % form)
		delivery.queue_free()


func _test_piercing_stops_after_declared_targets() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("lanca_fulgor", _catalog, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"manual": true,
	})
	root.add_child(delivery)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var max_hits := int(contract.get("max_target_hits", 0))
	_check(max_hits > 0, "perfurante declara o limite de corpos como número executável")
	if max_hits <= 0:
		delivery.queue_free()
		return
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var contact_point := Vector3.FORWARD * float(contract.get("speed_m_s")) * tick
	var targets: Array[Node3D] = []
	for _index: int in max_hits + 1:
		var target := TestTarget.new()
		root.add_child(target)
		target.global_position = contact_point
		targets.append(target)
	delivery.call("advance", tick, targets)
	var contacts := 0
	for target: TestTarget in targets:
		contacts += target.contacts.size()
		root.remove_child(target)
		target.free()
	_check(contacts == max_hits,
		"perfurante atravessa só os corpos declarados e não o seguinte")
	delivery.queue_free()


func _test_hunter_turns_and_breaks_on_line_of_sight() -> void:
	var target := TestTarget.new()
	root.add_child(target)
	target.global_position = Vector3.RIGHT
	var delivery: Node3D = SpellDeliveryFactory.create("cacador_azul", _catalog, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"target": target,
		"manual": true,
	})
	root.add_child(delivery)
	var before: Dictionary = delivery.call("snapshot") as Dictionary
	delivery.call("advance", 1.0 / float(Engine.physics_ticks_per_second), [])
	var after: Dictionary = delivery.call("snapshot") as Dictionary
	var before_direction := before.get("primary_direction", Vector3.FORWARD) as Vector3
	var after_direction := after.get("primary_direction", Vector3.FORWARD) as Vector3
	_check(after_direction.dot(Vector3.RIGHT) > before_direction.dot(Vector3.RIGHT),
		"perseguidor roda para o alvo pela taxa declarada")
	_check(delivery.has_method("set_line_of_sight_visible"),
		"perseguidor expõe a quebra de visão à física da casca")
	if delivery.has_method("set_line_of_sight_visible"):
		delivery.call("set_line_of_sight_visible", false)
	_check(not bool((delivery.call("snapshot") as Dictionary).get("alive", true)),
		"perseguidor desaparece quando a linha de visão quebra")
	target.queue_free()
	delivery.queue_free()


func _test_orbiting_form_keeps_declared_bodies_around_caster() -> void:
	var caster := Node3D.new()
	root.add_child(caster)
	var delivery: Node3D = SpellDeliveryFactory.create("coroa_brasa", _catalog, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"caster": caster,
		"manual": true,
	})
	root.add_child(delivery)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var before: Dictionary = delivery.call("snapshot") as Dictionary
	var before_instances: Array = before.get("instances", []) as Array
	_check(before_instances.size() == int(contract.get("count")),
		"orbitante materializa a contagem declarada")
	delivery.call("advance", 1.0 / float(Engine.physics_ticks_per_second), [])
	var after_instances: Array = (delivery.call("snapshot") as Dictionary).get(
		"instances", []) as Array
	var any_moved := false
	for index: int in mini(before_instances.size(), after_instances.size()):
		any_moved = any_moved or not ((before_instances[index] as Dictionary).get(
			"position", Vector3.ZERO) as Vector3).is_equal_approx(
			(after_instances[index] as Dictionary).get("position", Vector3.ZERO) as Vector3)
	_check(any_moved, "orbitante gira em torno do conjurador pela taxa declarada")
	caster.queue_free()
	delivery.queue_free()


func _test_beams_keep_their_distinct_geometry() -> void:
	var straight: Node3D = SpellDeliveryFactory.create("chama_faminta", _catalog, {
		"origin": Vector3.ZERO, "direction": Vector3.FORWARD, "manual": true})
	var ground: Node3D = SpellDeliveryFactory.create("rasto_carvao", _catalog, {
		"origin": Vector3.ZERO, "direction": Vector3.FORWARD, "manual": true})
	root.add_child(straight)
	root.add_child(ground)
	var straight_before: Dictionary = straight.call("snapshot") as Dictionary
	var ground_before: Dictionary = ground.call("snapshot") as Dictionary
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	straight.call("advance", tick, [])
	ground.call("advance", tick, [])
	var straight_after: Dictionary = straight.call("snapshot") as Dictionary
	var ground_after: Dictionary = ground.call("snapshot") as Dictionary
	_check((straight_after.get("primary_direction", Vector3.ZERO) as Vector3).is_equal_approx(
		straight_before.get("primary_direction", Vector3.ONE) as Vector3),
		"feixe conserva a linha comprometida")
	_check(not (ground_after.get("primary_direction", Vector3.ZERO) as Vector3).is_equal_approx(
		ground_before.get("primary_direction", Vector3.ZERO) as Vector3),
		"feixe rasteiro varre o chão pela rotação declarada")
	var straight_contract: Dictionary = straight.call("delivery_contract") as Dictionary
	var expected_end := (straight_before.get("primary_position", Vector3.ZERO) as Vector3) \
		+ (straight_before.get("primary_direction", Vector3.FORWARD) as Vector3) \
		* float(straight_contract.get("max_range_m"))
	_check((straight_before.get("beam_endpoint", Vector3.ZERO) as Vector3).is_equal_approx(
		expected_end), "feixe expõe a linha visível até ao alcance catalogado")
	straight.queue_free()
	ground.queue_free()


func _test_cone_emits_declared_arc_over_cadence() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("chuva_cinzenta", _catalog, {
		"origin": Vector3.ZERO, "direction": Vector3.FORWARD, "manual": true})
	root.add_child(delivery)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var count := int(contract.get("count"))
	var cadence := float(contract.get("cadence_s"))
	for _index: int in count:
		delivery.call("advance", cadence, [])
	var snapshot: Dictionary = delivery.call("snapshot") as Dictionary
	_check(int(snapshot.get("emitted_count", 0)) == count,
		"barragem em cone emite a contagem pela cadência declarada")
	var directions: Dictionary = {}
	for instance: Dictionary in snapshot.get("instances", []) as Array:
		directions[str((instance.get("direction", Vector3.ZERO) as Vector3).snapped(
			Vector3.ONE / float(Engine.physics_ticks_per_second)))] = true
	_check(directions.size() == count,
		"barragem distribui cada projéctil por uma direcção do arco")
	delivery.queue_free()


func _test_one_cone_impact_does_not_cancel_the_barrage() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("chuva_cinzenta", _catalog, {
		"origin": Vector3.ZERO, "direction": Vector3.FORWARD, "manual": true})
	root.add_child(delivery)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var target := TestTarget.new()
	root.add_child(target)
	var partial_step := float(contract.get("cadence_s")) * 0.5
	var before: Dictionary = delivery.call("snapshot") as Dictionary
	var first: Dictionary = (before.get("instances", []) as Array)[0] as Dictionary
	target.global_position = (first.get("direction", Vector3.FORWARD) as Vector3) \
		* float(contract.get("speed_m_s")) \
		* partial_step
	delivery.call("advance", partial_step, [target])
	var after_hit: Dictionary = delivery.call("snapshot") as Dictionary
	_check(bool(after_hit.get("alive", false)),
		"impacto de um projéctil não cancela a barragem inteira")
	for _index: int in int(contract.get("count")):
		delivery.call("advance", float(contract.get("cadence_s")), [])
	_check(int((delivery.call("snapshot") as Dictionary).get("emitted_count", 0)) \
		== int(contract.get("count")),
		"barragem continua a emitir depois do primeiro impacto")
	target.queue_free()
	delivery.queue_free()


func _test_rain_falls_and_dies_on_ceiling() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("granizo_carmim", _catalog, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"target_point": Vector3.ZERO,
		"manual": true,
	})
	root.add_child(delivery)
	var before: Dictionary = delivery.call("snapshot") as Dictionary
	var before_y := float(((before.get("instances", []) as Array)[0] as Dictionary).get(
		"position", Vector3.ZERO).y)
	delivery.call("advance", 1.0 / float(Engine.physics_ticks_per_second), [])
	var after: Dictionary = delivery.call("snapshot") as Dictionary
	var after_y := float(((after.get("instances", []) as Array)[0] as Dictionary).get(
		"position", Vector3.ZERO).y)
	_check(after_y < before_y, "chuva nasce acima da área e cai com gravidade")
	_check(delivery.has_method("notify_solid_collision"),
		"chuva expõe colisão com tecto/chão à física da zona")
	if delivery.has_method("notify_solid_collision"):
		delivery.call("notify_solid_collision", 0)
	_check(int((delivery.call("snapshot") as Dictionary).get("living_instance_count", -1)) == 0,
		"primeiro fragmento da chuva desaparece ao bater no tecto")
	delivery.queue_free()


func _test_solid_collision_closes_a_spent_delivery() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("dardo", _catalog, {
		"origin": Vector3.ZERO, "direction": Vector3.FORWARD, "manual": true})
	root.add_child(delivery)
	delivery.call("notify_solid_collision", 0)
	var snapshot: Dictionary = delivery.call("snapshot") as Dictionary
	_check(not bool(snapshot.get("alive", true)) \
		and not bool(snapshot.get("hitbox_active", true)) \
		and not bool(snapshot.get("contact_visual_visible", true)),
		"último volume fecha efeito e hitbox ao bater num sólido")
	delivery.queue_free()


func _test_carrier_moves_and_releases_seekers() -> void:
	var target := TestTarget.new()
	root.add_child(target)
	target.global_position = Vector3.FORWARD
	var delivery: Node3D = SpellDeliveryFactory.create("ruina", _catalog, {
		"origin": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"target": target,
		"target_point": target.global_position,
		"manual": true,
	})
	root.add_child(delivery)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var before: Dictionary = delivery.call("snapshot") as Dictionary
	for _index: int in int(contract.get("count")):
		delivery.call("advance", float(contract.get("cadence_s")), [])
	var after: Dictionary = delivery.call("snapshot") as Dictionary
	_check(not (after.get("primary_position", Vector3.ZERO) as Vector3).is_equal_approx(
		before.get("primary_position", Vector3.ZERO) as Vector3),
		"portador move o volume principal")
	_check(int(after.get("released_count", 0)) == int(contract.get("count")),
		"portador larga a contagem de perseguidores pela cadência declarada")
	_check((after.get("instances", []) as Array).size() == int(contract.get("count")) + 1,
		"portador mantém corpo principal e perseguidores como volumes separados")
	target.queue_free()
	delivery.queue_free()


func _test_non_damage_wave_expands_once_through_target() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("peso", _catalog, {
		"origin": Vector3.ZERO, "direction": Vector3.FORWARD, "manual": true})
	root.add_child(delivery)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	var target := TestTarget.new()
	root.add_child(target)
	target.global_position = Vector3.RIGHT * float(contract.get("speed_m_s")) * tick
	delivery.call("advance", tick, [target])
	var snapshot: Dictionary = delivery.call("snapshot") as Dictionary
	_check(is_equal_approx(float(snapshot.get("wave_radius_m", 0.0)),
		float(contract.get("speed_m_s")) * tick),
		"onda sem dano expande radialmente pela velocidade declarada")
	_check((snapshot.get("primary_position", Vector3.ONE) as Vector3).is_equal_approx(Vector3.ZERO),
		"onda fica centrada no lançamento em vez de virar projéctil")
	_check(target.contacts.size() == 1
		and not bool(target.contacts[0].get("damage_enabled", true)),
		"onda contacta uma vez e publica explicitamente zero dano")
	target.queue_free()
	delivery.queue_free()


func _test_bait_stays_and_lures_on_declared_pulse() -> void:
	var delivery: Node3D = SpellDeliveryFactory.create("coro", _catalog, {
		"origin": Vector3.ZERO,
		"target_point": Vector3.ZERO,
		"direction": Vector3.FORWARD,
		"manual": true,
	})
	root.add_child(delivery)
	var target := TestTarget.new()
	root.add_child(target)
	var contract: Dictionary = delivery.call("delivery_contract") as Dictionary
	var before := (delivery.call("snapshot") as Dictionary).get(
		"primary_position", Vector3.ONE) as Vector3
	for _pulse: int in 2:
		delivery.call("advance", float(contract.get("pulse_s")), [target])
	var after := (delivery.call("snapshot") as Dictionary).get(
		"primary_position", Vector3.ZERO) as Vector3
	_check(after.is_equal_approx(before), "isco fica onde foi lançado")
	_check(target.contacts.size() == 2
		and not bool(target.contacts[0].get("damage_enabled", true)),
		"isco publica atracção periódica sem dano")
	target.queue_free()
	delivery.queue_free()


func _test_vfx_residency_keeps_only_equipped_spells() -> void:
	var residency := SpellVfxResidency.new()
	residency.configure(_catalog)
	var equipped: Array = (_catalog.get("_rules", {}) as Dictionary).get(
		"default_favorites", []) as Array
	_check(residency.equip(equipped), "residência aceita os três favoritos equipados")
	var resident_ids: Array = residency.resident_spell_ids()
	_check(resident_ids == equipped,
		"residência contém exactamente os feitiços equipados e na mesma ordem")
	for spell_id: Variant in _catalog.get("order", []):
		_check(residency.has_spell(String(spell_id)) == equipped.has(spell_id),
			"residência de %s coincide com o equipamento" % spell_id)
	var stats: Dictionary = residency.stats()
	_check(int(stats.get("resident_spell_count", 0)) == equipped.size()
		and int(stats.get("mesh_count", 0)) <= equipped.size()
		and int(stats.get("material_count", 0)) <= equipped.size(),
		"recursos são partilhados sem materializar 53 VFX")
	var before_rejected: Array = resident_ids.duplicate()
	_check(not residency.equip(_catalog.get("order", []) as Array),
		"pedido para pré-carregar o catálogo inteiro é recusado")
	_check(residency.resident_spell_ids() == before_rejected,
		"pedido recusado não expulsa o equipamento válido")


func _test_contact_geometry_shares_the_hitbox_clock() -> void:
	var residency := SpellVfxResidency.new()
	residency.configure(_catalog)
	var spell_ids: Array = ["dardo", "lamina_astral", "ruina"]
	_check(residency.equip(spell_ids),
		"residência prepara uma amostra de cada tipo de contacto")
	for spell_id: String in spell_ids:
		var delivery := SpellDelivery.new()
		root.add_child(delivery)
		var spell: Dictionary = _catalog.get(spell_id, {}) as Dictionary
		var contract := _contract_for(spell)
		var contact_contracts: Dictionary = _catalog.get("_contact_contracts", {}) as Dictionary
		contract.merge(contact_contracts.get(String(spell.get("contact_type", "")), {}) \
			as Dictionary, true)
		delivery.configure(spell_id, spell, contract, {
			"origin": Vector3.ZERO,
			"direction": Vector3.FORWARD,
			"manual": true,
		})
		var vfx := delivery.call("attach_vfx", residency.bundle_for(spell_id)) as Node3D
		var open_snapshot: Dictionary = delivery.snapshot()
		_check(vfx != null and vfx.is_contact_visible() \
			== bool(open_snapshot.get("hitbox_active", false)),
			"%s abre geometria e hitbox no mesmo relógio" % spell_id)
		_check(vfx != null and bool(vfx.call("has_started_audio_cue")),
			"%s usa um perfil sonoro sintetizado no acto de aparecer" % spell_id)
		delivery.call("expire")
		var closed_snapshot: Dictionary = delivery.snapshot()
		_check(not vfx.is_contact_visible() \
			and not bool(closed_snapshot.get("hitbox_active", true)),
			"%s fecha geometria e hitbox no mesmo relógio" % spell_id)
		delivery.queue_free()


func _contract_for(spell: Dictionary) -> Dictionary:
	var contracts: Dictionary = _catalog.get("_delivery_contracts", {}) as Dictionary
	var contract: Dictionary = (contracts.get(
		String(spell.get("delivery_form", "")), {}) as Dictionary).duplicate(true)
	for source_key: String in ["speed_mps", "range_m", "max_range"]:
		if spell.has(source_key):
			var target_key := "speed_m_s" if source_key == "speed_mps" else "max_range_m"
			contract[target_key] = spell[source_key]
	contract["delivery_form"] = spell.get("delivery_form", "")
	contract["contact_type"] = spell.get("contact_type", "")
	return contract


func _load_catalog() -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/spells.json"))
	_check(parsed is Dictionary, "catálogo de magia abre como JSON")
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("[magia+vfx] FALHOU: %s" % message)
