extends SceneTree
## Sonda visual e de custo na máquina alvo.
##
## godot --path game/ --rendering-method mobile \
##   --script res://src/ui/levelup_benchmark.gd

const LevelScreen = preload("res://src/ui/levelup_screen.gd")

var _game_data: Node
var _save_system: Node
var _original_state: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_game_data = root.get_node("GameData")
	_save_system = root.get_node("SaveSystem")
	root.get_node("Bench").call("set_overlay_visible", false)
	_original_state = _game_data.call("save_state_snapshot") as Dictionary
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var state := _save_system.call("create_save", "levelup-benchmark", "warrior") as Dictionary
	var progression: Dictionary = ((state.get("character", {}) as Dictionary).get(
		"progression", {}) as Dictionary)
	progression["souls_held"] = int(_game_data.call("level_cost", 2))
	_game_data.call("replace_save_state", state)
	var screen := LevelScreen.new()
	root.add_child(screen)

	screen.visible = false
	await _wait_frames(120)
	var baseline := await _sample_frames(600)
	screen.open_for_current()
	await _wait_frames(120)
	await RenderingServer.frame_post_draw
	var capture_path := "user://levelup-screen-1920x1080.png"
	var capture_error := root.get_texture().get_image().save_png(capture_path)
	var visible := await _sample_frames(600)
	var report := {
		"hardware": _video_adapter_name(),
		"renderer": RenderingServer.get_video_adapter_api_version(),
		"resolution": "%dx%d" % [root.size.x, root.size.y],
		"warmup_frames": 120,
		"sample_frames": 600,
		"baseline": baseline,
		"levelup_visible": visible,
		"capture_ok": capture_error == OK,
	}
	print("=== CUSTO VISUAL SUBIR DE NÍVEL ===")
	print(JSON.stringify(report))
	print("captura: %s" % ProjectSettings.globalize_path(capture_path))
	_game_data.call("replace_save_state", _original_state)
	screen.free()
	quit(0 if capture_error == OK else 1)


func _wait_frames(count: int) -> void:
	for _frame: int in count:
		await process_frame


func _sample_frames(count: int) -> Dictionary:
	var samples: Array[float] = []
	var draw_calls: Array[int] = []
	for _frame: int in count:
		var started := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
		draw_calls.append(RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	samples.sort()
	draw_calls.sort()
	var total_ms := 0.0
	for sample: float in samples:
		total_ms += sample
	var average_ms := total_ms / float(samples.size())
	return {
		"average_fps": snappedf(1000.0 / average_ms, 0.1),
		"average_ms": snappedf(average_ms, 0.001),
		"p95_ms": snappedf(samples[floori(samples.size() * 0.95)], 0.001),
		"p99_ms": snappedf(samples[floori(samples.size() * 0.99)], 0.001),
		"worst_ms": snappedf(samples.back(), 0.001),
		"draw_calls_median": draw_calls[draw_calls.size() / 2],
		"video_mem_mib": snappedf(float(Performance.get_monitor(
			Performance.RENDER_VIDEO_MEM_USED)) / 1048576.0, 0.1),
	}


func _video_adapter_name() -> String:
	var name := RenderingServer.get_video_adapter_name()
	return name if name != "" else "adaptador não identificado"
