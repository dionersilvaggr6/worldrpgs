extends SceneTree
## Harness de Lei 4. Carrega a arena real e mantém o pior estado visual do
## ArenaVorgar durante a amostra do Bench, sem alterar main.gd/greybox.gd.


class DownedMarkerAnchor extends Node3D:
	func is_alive() -> bool:
		return false


func _initialize() -> void:
	call_deferred("_install_worst_case")


func _install_worst_case() -> void:
	var shell_scene: PackedScene = load("res://scenes/main.tscn")
	var shell := shell_scene.instantiate()
	root.add_child(shell)
	await process_frame
	await process_frame

	var boss: Node3D
	for node: Node in get_nodes_in_group("enemies"):
		if String(node.get("enemy_id")) == "vorgar":
			boss = node as Node3D
			break
	if boss == null:
		push_error("Lei 4/Vorgar: chefe não nasceu na arena")
		quit(1)
		return
	if "--vorgar-controller=off" in OS.get_cmdline_user_args():
		print("[vorgar-perf] baseline com o mesmo harness, sem controlador")
		return

	var boss_data := boss.get("data") as Dictionary
	var encounter := boss_data.get("vorgar_encounter", {}) as Dictionary
	var downed := DownedMarkerAnchor.new()
	root.add_child(downed)
	var refuge := (encounter.get("refuge_offsets_m", []) as Array).front() as Array
	downed.global_position = boss.global_position + Vector3(
		float(refuge[0]), float(refuge[1]), float(refuge[2]))
	downed.add_to_group("player")

	var arena_script: Script = load("res://src/world/arena_vorgar.gd")
	var arena: Node3D = arena_script.new()
	root.add_child(arena)
	arena.global_position = boss.global_position
	var local_player: Node3D
	for node: Node in get_nodes_in_group("player"):
		if node != downed:
			local_player = node as Node3D
			break
	arena.call("setup", boss, encounter, local_player)
	await process_frame
	var sequences := encounter.get("coop_sequences", {}) as Dictionary
	var join := sequences.get("juntar", {}) as Dictionary
	arena.call("begin_sequence", join)
	arena.call("tick_sequence", int(join.get("startup")) + 1)
	var cost := arena.call("visual_cost_snapshot") as Dictionary
	print("[vorgar-perf] %d/%d malhas · %d/%d etiquetas" % [
		int(cost.get("meshes")), int(cost.get("mesh_budget")),
		int(cost.get("labels")), int(cost.get("label_budget")),
	])
