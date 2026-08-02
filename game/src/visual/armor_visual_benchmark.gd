extends Node
## Prova visual e benchmark reproduzível da armadura. Mede baseline e armadura
## com a mesma câmara, luz, actores e animação; a saída é JSON na consola.

const ArmorVisualScript = preload("res://src/visual/armor_visual.gd")
const EquipmentScreenScript = preload("res://src/ui/equipment_screen.gd")
const EquipmentScreenSelfTestScript = preload("res://src/ui/equipment_screen_self_test.gd")

const CLASS_IDS := ["warrior", "sorcerer", "tank", "assassin", "berserker", "paladin"]

var _mode := "armored"
var _actors := 5
var _warmup_seconds := 3.0
var _measure_seconds := 10.0
var _vsync_on := false
var _capture_name := ""
var _elapsed := 0.0
var _last_wall_usec := 0
var _samples: Array[float] = []
var _visual_surfaces := 0
var _captured := false


func _ready() -> void:
	_parse_arguments()
	if _mode == "selftest":
		_run_self_test.call_deferred()
		return
	Bench.set_overlay_visible(false)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if _vsync_on else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_build_stage()
	_last_wall_usec = Time.get_ticks_usec()
	print("[ARMOR_BENCH] mode=%s actors=%d warmup=%.1fs measure=%.1fs resolution=1920x1080 vsync=%s renderer=%s gpu=%s" % [
		_mode, _actors, _warmup_seconds, _measure_seconds,
		"on" if _vsync_on else "off", RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name()])


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var wall_delta := float(now - _last_wall_usec) / 1000000.0
	_last_wall_usec = now
	_elapsed += wall_delta
	if _elapsed < _warmup_seconds:
		return
	if not _captured and _capture_name != "":
		_captured = true
		_capture.call_deferred()
	_samples.append(wall_delta * 1000.0)
	if _elapsed >= _warmup_seconds + _measure_seconds:
		_report()
		get_tree().quit()


func _build_stage() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182128")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9eabb2")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.15, -10.5)
	camera.fov = 43.0
	add_child(camera)
	camera.look_at_from_position(camera.position, Vector3(0.0, 1.05, 0.0))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42.0, 145.0, 0.0)
	key.light_energy = 1.15
	key.shadow_enabled = true
	add_child(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 8.0)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("30383c")
	floor_material.roughness = 1.0
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)
	if _mode == "ui":
		_build_ui_proof()
		return
	if _mode == "comparison":
		_build_chest_comparison()
		return
	for index: int in _actors:
		var class_id := String(CLASS_IDS[index % CLASS_IDS.size()])
		var visual: CharacterVisual
		if _mode == "armored":
			visual = ArmorVisualScript.new()
		else:
			visual = CharacterVisual.new()
		visual.position = Vector3(
			(float(index) - float(_actors - 1) * 0.5) * 1.45, 0.0,
			absf(float(index) - float(_actors - 1) * 0.5) * 0.22)
		add_child(visual)
		visual.setup(1.8, Color.WHITE, true, "body_male", class_id)
		visual.play_animation("Walk")
		if visual.has_method("apply_equipment"):
			var loadout: Dictionary = (GameData.weapons.get("loadouts", {}) as Dictionary).get(
				class_id, {}) as Dictionary
			visual.call("apply_equipment", loadout.get("pecas", []) as Array)
			_visual_surfaces += int(visual.call("draw_surface_count"))
		else:
			_visual_surfaces += _surface_count(visual)


func _build_chest_comparison() -> void:
	var chest_ids := ["couro_peitoral", "ferro_peitoral"]
	var labels := ["COURO", "FERRO"]
	for index: int in chest_ids.size():
		var visual := ArmorVisualScript.new()
		visual.position = Vector3((float(index) - 0.5) * 2.2, 0.0, 0.0)
		add_child(visual)
		visual.setup(1.8, Color.WHITE, false, "body_male", "warrior")
		visual.apply_equipment([chest_ids[index]])
		_visual_surfaces += visual.draw_surface_count()
		var label := Label3D.new()
		label.text = labels[index]
		label.position = visual.position + Vector3(0.0, 2.35, 0.0)
		label.font_size = 48
		label.outline_size = 10
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


func _build_ui_proof() -> void:
	var screen_state := SaveSystem.create_save("armor-ui-proof", "tank")
	screen_state.character.inventory.items["armadura:couro_peitoral"] = 1
	screen_state.character.inventory.equipment.main = ""
	screen_state.character.inventory.equipment.offhand = ""
	var screen := EquipmentScreenScript.new()
	add_child(screen)
	screen.open_for_state(screen_state, "tank", "armor:peito", "armadura:couro_peitoral")


func _run_self_test() -> void:
	var suite := EquipmentScreenSelfTestScript.new()
	var result: Dictionary = await suite.run(self)
	get_tree().quit(1 if int(result.get("failed", 0)) > 0 else 0)


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "user://%s" % _capture_name
	var error := image.save_png(path)
	print("[ARMOR_CAPTURE] path=%s error=%d" % [ProjectSettings.globalize_path(path), error])


func _report() -> void:
	if _samples.is_empty():
		printerr("[ARMOR_BENCH_ERROR] sem amostras")
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
		"actors": _actors,
		"samples": _samples.size(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"resolution": "1920x1080",
		"vsync": "on" if _vsync_on else "off",
		"average_ms": snappedf(average_ms, 0.001),
		"average_fps": snappedf(1000.0 / average_ms, 0.1),
		"p95_ms": snappedf(_samples[p95_index], 0.001),
		"p99_ms": snappedf(_samples[p99_index], 0.001),
		"worst_ms": snappedf(_samples[-1], 0.001),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"visible_mesh_surfaces": _visual_surfaces,
	}
	print("ARMOR_BENCH_RESULT %s" % JSON.stringify(result))


func _parse_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--actors="):
			_actors = maxi(1, argument.trim_prefix("--actors=").to_int())
		elif argument.begins_with("--warmup="):
			_warmup_seconds = maxf(0.0, argument.trim_prefix("--warmup=").to_float())
		elif argument.begins_with("--seconds="):
			_measure_seconds = maxf(1.0, argument.trim_prefix("--seconds=").to_float())
		elif argument.begins_with("--vsync="):
			_vsync_on = argument.trim_prefix("--vsync=") == "on"
		elif argument.begins_with("--capture="):
			_capture_name = argument.trim_prefix("--capture=")


static func _surface_count(node: Node) -> int:
	var total := 0
	for mesh_node: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance.visible and mesh_instance.mesh != null:
			total += mesh_instance.mesh.get_surface_count()
	return total
