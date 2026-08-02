extends SceneTree
## Captura e benchmark reproduzivel das armas presas ao corpo.
##
## Executar com renderer real, uma vez com --mode=base e outra com
## --mode=armed. Ambos usam a mesma cena, camera, luz e corpos a 1920x1080.

class BenchActor extends Node3D:
	var main_weapon := ""
	var offhand_weapon := ""
	var is_two_handed := false


var _mode := "armed"
var _single_weapon := ""
var _single_offhand := ""
var _armor_piece := ""
var _warmup_seconds := 3.0
var _measure_seconds := 10.0
var _capture_name := ""
var _samples: Array[float] = []
var _visual_surfaces := 0
var _actor_count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_parse_arguments()
	root.get_node("Bench").call("set_overlay_visible", false)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_build_stage()
	print("[WEAPON_BENCH] mode=%s warmup=%.1fs measure=%.1fs renderer=%s gpu=%s" % [
		_mode, _warmup_seconds, _measure_seconds,
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name()])
	var start_usec := Time.get_ticks_usec()
	var last_usec := start_usec
	var captured := false
	while float(Time.get_ticks_usec() - start_usec) / 1000000.0 \
			< _warmup_seconds + _measure_seconds:
		await process_frame
		var now_usec := Time.get_ticks_usec()
		var elapsed := float(now_usec - start_usec) / 1000000.0
		if elapsed >= _warmup_seconds:
			_samples.append(float(now_usec - last_usec) / 1000.0)
			if not captured and not _capture_name.is_empty():
				captured = true
				await _capture()
		last_usec = now_usec
	_report()
	quit()


func _build_stage() -> void:
	var game_data := root.get_node("GameData")
	var weapon_catalogue := game_data.get("weapons") as Dictionary
	var declared_loadouts: Array = (weapon_catalogue.get("test_loadouts", {}) \
		as Dictionary).get("order", []) as Array
	var active_loadouts: Array = declared_loadouts if _single_weapon.is_empty() else [{
		"main": _single_weapon, "offhand": _single_offhand,
	}]
	_actor_count = active_loadouts.size()
	var stage := Node3D.new()
	stage.name = "WeaponBenchmark"
	root.add_child(stage)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("11171d")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("8ba2b6")
	environment.ambient_light_energy = 0.8
	world.environment = environment
	stage.add_child(world)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.65, -4.2) \
		if active_loadouts.size() == 1 else Vector3(0.0, 2.15, -10.5)
	camera.fov = 43.0
	stage.add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0.0, 1.05, 0.0))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42.0, 145.0, 0.0)
	light.light_energy = 1.15
	light.shadow_enabled = true
	stage.add_child(light)

	var floor_mesh := MeshInstance3D.new()
	var floor := PlaneMesh.new()
	floor.size = Vector2(18.0, 8.0)
	floor_mesh.mesh = floor
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("28343b")
	floor_material.roughness = 1.0
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)

	var player_height := float((game_data.call("section", "player") as Dictionary).get(
		"capsule_height", 0.0))
	for index: int in active_loadouts.size():
		var loadout := active_loadouts[index] as Dictionary
		var actor := BenchActor.new()
		actor.main_weapon = String(loadout.get("main", ""))
		actor.offhand_weapon = String(loadout.get("offhand", ""))
		actor.is_two_handed = int((game_data.call("weapon", actor.main_weapon) as Dictionary).get(
			"hands", 1)) >= 2
		actor.position = Vector3(
			(float(index) - float(active_loadouts.size() - 1) * 0.5) * 1.45,
			0.0,
			absf(float(index) - float(active_loadouts.size() - 1) * 0.5) * 0.22)
		stage.add_child(actor)
		# O benchmark corre como --script; o carregamento tardio deixa os autoloads
		# registarem-se antes de ArmorVisual resolver GameData.
		var visual: CharacterVisual = load("res://src/visual/armor_visual.gd").new() \
			if not _armor_piece.is_empty() else CharacterVisual.new()
		actor.add_child(visual)
		visual.setup(player_height, Color.WHITE, true, "body_male", "warrior")
		if not _armor_piece.is_empty():
			visual.call("apply_equipment", [_armor_piece])
		visual.play_animation("Idle")
		var body_surfaces := _surface_count(visual)
		_visual_surfaces += body_surfaces
		if _mode == "armed":
			var weapons := WeaponAttach.new()
			actor.add_child(weapons)
			weapons.setup(actor, visual)
			# BoneAttachment3D vive dentro do Skeleton3D do corpo, nao como filho
			# deste controlador; por isso a diferenca mede as superficies reais.
			_visual_surfaces += maxi(0, _surface_count(visual) - body_surfaces)


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var path := "user://%s" % _capture_name
	var error := image.save_png(path)
	print("[WEAPON_CAPTURE] path=%s error=%d" % [ProjectSettings.globalize_path(path), error])


func _report() -> void:
	if _samples.is_empty():
		printerr("[WEAPON_BENCH_ERROR] sem amostras")
		return
	_samples.sort()
	var total := 0.0
	for sample: float in _samples:
		total += sample
	var average_ms := total / float(_samples.size())
	var p95_index := clampi(ceili(float(_samples.size()) * 0.95) - 1, 0, _samples.size() - 1)
	var p99_index := clampi(ceili(float(_samples.size()) * 0.99) - 1, 0, _samples.size() - 1)
	var result := {
		"mode": _mode,
		"actors": _actor_count,
		"samples": _samples.size(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"resolution": "1920x1080",
		"average_ms": snappedf(average_ms, 0.001),
		"average_fps": snappedf(1000.0 / average_ms, 0.1),
		"p95_ms": snappedf(_samples[p95_index], 0.001),
		"p99_ms": snappedf(_samples[p99_index], 0.001),
		"worst_ms": snappedf(_samples[-1], 0.001),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_mem_mb": snappedf(
			Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"visible_mesh_surfaces": _visual_surfaces,
	}
	print("WEAPON_BENCH_RESULT %s" % JSON.stringify(result))


func _parse_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--warmup="):
			_warmup_seconds = maxf(0.0, argument.trim_prefix("--warmup=").to_float())
		elif argument.begins_with("--seconds="):
			_measure_seconds = maxf(1.0, argument.trim_prefix("--seconds=").to_float())
		elif argument.begins_with("--capture="):
			_capture_name = argument.trim_prefix("--capture=")
		elif argument.begins_with("--weapon="):
			_single_weapon = argument.trim_prefix("--weapon=")
		elif argument.begins_with("--offhand="):
			_single_offhand = argument.trim_prefix("--offhand=")
		elif argument.begins_with("--armor="):
			_armor_piece = argument.trim_prefix("--armor=")


static func _surface_count(node: Node) -> int:
	var total := 0
	for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.visible and mesh_instance.mesh != null:
			total += mesh_instance.mesh.get_surface_count()
	return total
