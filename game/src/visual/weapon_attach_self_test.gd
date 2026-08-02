extends SceneTree
## Prova isolada da arma equipada na mao.
##
## godot --headless --audio-driver Dummy --path game/ --script res://src/visual/weapon_attach_self_test.gd

const ATTACH_PATH := "res://src/visual/weapon_attach.gd"

class MockActor extends Node3D:
	var main_weapon := "longsword"
	var offhand_weapon := "shield"
	var is_two_handed := false


var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var attach_script := load(ATTACH_PATH) as Script
	_check(attach_script != null, "modulo WeaponAttach existe")
	if attach_script == null:
		_finish()
		return
	var weapons := _read_json("res://data/weapons.json")
	var combat := _read_json("res://data/combat.json")
	var actor := MockActor.new()
	root.add_child(actor)
	var visual := CharacterVisual.new()
	actor.add_child(visual)
	visual.setup(float((combat.get("player", {}) as Dictionary).get("capsule_height", 0.0)),
		Color.WHITE, false, "body_male", "warrior")
	var attach := attach_script.new() as Node3D
	actor.add_child(attach)
	_check(bool(attach.call("setup", actor, visual)), "arma encontra o rig Quaternius")
	var bones: Dictionary = attach.call("attachment_bones") as Dictionary
	_check(not String(bones.get("main", "")).is_empty(), "arma principal prende-se a mao direita")
	_check(not String(bones.get("offhand", "")).is_empty(), "secundaria prende-se a mao esquerda")

	var previous_model_id := 0
	var previous_main_id := ""
	var loadouts: Array = (weapons.get("test_loadouts", {}) as Dictionary).get("order", []) as Array
	for loadout_value: Variant in loadouts:
		var loadout := loadout_value as Dictionary
		var main_id := String(loadout.get("main", ""))
		var offhand_id := "" if loadout.get("offhand") == null else String(loadout.get("offhand", ""))
		var main: Dictionary = weapons.get(main_id, {}) as Dictionary
		var two_handed := int(main.get("hands", 1)) >= 2
		attach.call("sync_loadout", main_id, offhand_id, two_handed)
		_check(bool(attach.call("has_visible_weapon", main_id)), "%s fica visivel na mao" % main_id)
		var model_kind := String(attach.call("model_kind_for", main_id))
		_check(model_kind in ["asset", "procedural"],
			"%s resolve modelo ou geometria procedural" % main_id)
		_check(int(attach.call("visible_mesh_count")) >= 1, "%s tem malha renderizavel" % main_id)
		var current_model_id := int(attach.call("main_model_instance_id"))
		if previous_model_id != 0 and main_id != previous_main_id:
			_check(current_model_id != previous_model_id,
				"trocar para %s substitui a instancia no mesmo frame" % main_id)
		previous_model_id = current_model_id
		previous_main_id = main_id
		# Deixa o renderer concluir a libertacao da malha anterior, como entre
		# duas entradas reais do jogador, sem enfraquecer a assercao de troca no
		# mesmo frame feita imediatamente acima.
		await process_frame

	attach.call("sync_loadout", "dagger", "dagger", false)
	_check(bool(attach.call("has_visible_weapon", "dagger", false)),
		"segunda adaga aparece na mao esquerda")
	await process_frame
	attach.call("sync_loadout", "greataxe", "shield", true)
	_check(not bool(attach.call("has_visible_weapon", "shield", false)),
		"duas maos escondem a secundaria")
	await process_frame
	attach.call("sync_loadout", "longsword", "shield", false)
	_check(bool(attach.call("has_visible_weapon", "shield", false)),
		"voltar a uma mao recupera o escudo")
	_check((attach.call("main_weapon_tip_position") as Vector3).distance_to(
		actor.global_position) > 0.0, "ponta visivel fornece origem do contacto")
	# O SceneTree liberta a raiz ao sair. Libertar explicitamente todo o rig no
	# frame anterior ao quit faz Godot 4.7 destruir materiais ainda referenciados
	# pelo RenderingServer e produz falsos erros de RID nulo.
	_finish()


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok    ", label)
	else:
		_failed += 1
		printerr("  FALHA ", label)


func _finish() -> void:
	print("\n=== ARMA NA MAO: %d passaram, %d falharam ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
