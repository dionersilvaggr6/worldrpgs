class_name EquipmentScreenSelfTest
extends RefCounted
## Prova isolada do ecrã completo e do boneco de equipamento.
##
## Corre sem editar o agregador que pertence a outro agente:
## godot --headless --audio-driver Dummy --path game/ \
##   src/equipment/armor_visual_benchmark.tscn -- --mode=selftest

const EquipmentScreen = preload("res://src/ui/equipment_screen.gd")
const ArmorVisual = preload("res://src/visual/armor_visual.gd")
var _passed := 0
var _failed := 0
var _host: Node


func run(host: Node) -> Dictionary:
	_host = host
	await host.get_tree().process_frame
	_test_slot_grammar_and_preview()
	_test_slot_assignment()
	await _test_credible_armor_geometry()
	print("\n=== EQUIPAMENTO: %d passaram, %d falharam ===" % [_passed, _failed])
	return {"passed": _passed, "failed": _failed}


func _test_slot_grammar_and_preview() -> void:
	var state: Dictionary = SaveSystem.create_save("equipment-screen", "tank")
	state.character.inventory.items["armadura:couro_peitoral"] = 1
	state.character.inventory.items["consumivel:bomba_bruma"] = 3
	var before := JSON.stringify(state)
	var model: Dictionary = EquipmentScreen.build_model(
		state, "armor:peito", "armadura:couro_peitoral")
	var slot_ids: Array = (model.get("slots", []) as Array).map(
		func(slot: Variant) -> String: return String((slot as Dictionary).get("id", "")))
	var preview: Dictionary = model.get("preview", {}) as Dictionary
	_check(slot_ids.has("main") and slot_ids.has("offhand"),
		"mãos usam a mesma gramática de slots do equipamento")
	for armor_slot: Variant in GameData.armor.get("slots", []):
		_check(slot_ids.has("armor:%s" % String(armor_slot)),
			"slot canónico de armadura %s aparece uma vez" % String(armor_slot))
	_check((model.get("quick_slot_ids", []) as Array).size() == \
		EquipmentScreen.quick_slot_actions().size(),
		"atalhos configuráveis nascem das acções hotbar existentes")
	_check(not preview.is_empty()
		and String(preview.get("candidate_key", "")) == "armadura:couro_peitoral"
		and float((preview.get("after_load", {}) as Dictionary).get("weight", -1.0))
			!= float((preview.get("before_load", {}) as Dictionary).get("weight", -1.0)),
		"seleccionar mostra o efeito na carga antes de confirmar")
	_check(JSON.stringify(state) == before,
		"pré-visualizar e cancelar não alteram o save recebido")


func _test_slot_assignment() -> void:
	var state: Dictionary = SaveSystem.create_save("equipment-slots", "warrior")
	state.character.inventory.items["arma:dagger"] = 1
	state.character.inventory.items["consumivel:bomba_bruma"] = 3
	var offhand_result: Dictionary = EquipmentScreen.apply_candidate_to_state(
		state, "offhand", "arma:dagger")
	var quick_result: Dictionary = EquipmentScreen.apply_candidate_to_state(
		state, "quick:1", "consumivel:bomba_bruma")
	var equipment: Dictionary = state.character.inventory.equipment
	var quick_slots: Array = state.character.inventory.quick_slots
	_check(bool(offhand_result.get("ok", false)) and String(equipment.offhand) == "dagger",
		"escolher a mão secundária não desvia a adaga para a principal")
	_check(bool(quick_result.get("ok", false)) and quick_slots.size() > 1
		and String(quick_slots[1]) == "consumivel:bomba_bruma",
		"mochila configura o item do atalho exacto sem deslocar os restantes")


func _test_credible_armor_geometry() -> void:
	var visual: ArmorVisual = ArmorVisual.new()
	_host.add_child(visual)
	visual.setup(1.8, Color.WHITE, false, "body_male", "tank")
	visual.apply_equipment(["ferro_elmo", "ferro_peitoral"])
	await _host.get_tree().process_frame
	var has_box := false
	for mesh_node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.is_in_group("armor_visual_piece") and mesh_instance.mesh is BoxMesh:
			has_box = true
	var iron_signature: String = visual.visual_signature("peito")
	visual.apply_equipment(["couro_peitoral", "couro_botas"])
	await _host.get_tree().process_frame
	var leather_signature: String = visual.visual_signature("peito")
	_check(visual.uses_quaternius_body(),
		"armadura conserva o corpo e o esqueleto Quaternius")
	_check(not has_box and visual.draw_surface_count() > 0,
		"peças visíveis usam superfícies curvas, nunca caixotes")
	_check(iron_signature != "" and leather_signature != ""
		and iron_signature != leather_signature,
		"trocar ferro por couro muda a silhueta no mesmo boneco")
	visual.free()


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % label)
	else:
		_failed += 1
		printerr("  FALHA %s" % label)
