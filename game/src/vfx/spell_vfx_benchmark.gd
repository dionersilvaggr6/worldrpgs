extends SceneTree
## Medição reproduzível dos três feitiços equipados no alvo 1080p/Iris Xe.
## Corre com Godot gráfico e --rendering-method mobile.

const SpellDeliveryFactory = preload("res://src/spells/spell_delivery_factory.gd")
const SpellVfxResidency = preload("res://src/vfx/spell_vfx_residency.gd")

var _catalog: Dictionary = {}
var _benchmark: Dictionary = {}
var _residency: SpellVfxResidency
var _stage := Node3D.new()
var _camera: Camera3D
var _deliveries: Dictionary = {}
var _casters: Dictionary = {}
var _targets: Dictionary = {}
var _has_spawned: Dictionary = {}
var _frame_times_ms: Array[float] = []
var _started_usec := 0
var _last_frame_usec := 0
var _memory_before_bytes := 0
var _finishing := false


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	_catalog = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/spells.json")) as Dictionary
	_benchmark = (_catalog.get("_vfx", {}) as Dictionary).get(
		"benchmark", {}) as Dictionary
	DisplayServer.window_set_size(Vector2i(
		int(_benchmark.get("width", 0)), int(_benchmark.get("height", 0))))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.add_child(_stage)
	_build_stage()
	_memory_before_bytes = OS.get_static_memory_usage()
	_residency = SpellVfxResidency.new()
	_residency.configure(_catalog)
	var benchmark_spells: Array = _benchmark.get("spells", []) as Array
	if not _residency.equip(benchmark_spells):
		push_error("[vfx-benchmark] equipamento de benchmark invalido")
		quit(1)
		return
	for index: int in benchmark_spells.size():
		_prepare_spell(String(benchmark_spells[index]), index)
	_started_usec = Time.get_ticks_usec()
	_last_frame_usec = _started_usec
	print("[vfx-benchmark] inicio %dx%d, %s" % [
		int(_benchmark.get("width", 0)), int(_benchmark.get("height", 0)),
		JSON.stringify(_residency.stats())])


func _process(_delta: float) -> bool:
	if _started_usec == 0 or _finishing:
		return false
	_maintain_three_spells()
	var now_usec := Time.get_ticks_usec()
	var elapsed_s := float(now_usec - _started_usec) / 1000000.0
	var frame_ms := float(now_usec - _last_frame_usec) / 1000.0
	_last_frame_usec = now_usec
	var warmup_s := float(_benchmark.get("warmup_s", 0.0))
	if elapsed_s >= warmup_s:
		_frame_times_ms.append(frame_ms)
	if elapsed_s >= warmup_s + float(_benchmark.get("sample_s", 0.0)):
		_finishing = true
		_finish.call_deferred()
	return false


func _build_stage() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.from_string(
		String(_benchmark.get("background_color", "#000000")), Color.BLACK)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.35
	world_environment.environment = environment
	_stage.add_child(world_environment)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	var floor_size := float(_benchmark.get("floor_size_m", 0.0))
	floor_mesh.size = Vector2(floor_size, floor_size)
	var floor_material := StandardMaterial3D.new()
	floor_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_material.albedo_color = Color.from_string(
		String(_benchmark.get("ground_color", "#000000")), Color.BLACK)
	floor_mesh.material = floor_material
	floor.mesh = floor_mesh
	_stage.add_child(floor)

	_camera = Camera3D.new()
	_stage.add_child(_camera)
	_camera.position = _vector3_from(_benchmark.get("camera_position", []))
	_camera.look_at(_vector3_from(_benchmark.get("camera_target", [])), Vector3.UP)
	_camera.current = true


func _prepare_spell(spell_id: String, index: int) -> void:
	var origins: Array = _benchmark.get("origins", []) as Array
	var targets: Array = _benchmark.get("targets", []) as Array
	var caster := Node3D.new()
	caster.position = _vector3_from(origins[index])
	_stage.add_child(caster)
	_casters[spell_id] = caster
	var target := Node3D.new()
	target.position = _vector3_from(targets[index])
	_stage.add_child(target)
	_targets[spell_id] = target
	_spawn_spell(spell_id, index)


func _spawn_spell(spell_id: String, index: int) -> void:
	var origins: Array = _benchmark.get("origins", []) as Array
	var directions: Array = _benchmark.get("directions", []) as Array
	var origin := _vector3_from(origins[index])
	var bundle := _residency.bundle_for(spell_id)
	# O ciclo curto só mantém o mesmo efeito dentro do frustum; não representa
	# novas conjurações e, por isso, o cue sintetizado toca apenas na primeira.
	if _has_spawned.has(spell_id):
		bundle["audio_profile"] = ""
	else:
		_has_spawned[spell_id] = true
	var delivery := SpellDeliveryFactory.create(spell_id, _catalog, {
		"origin": origin,
		"direction": _vector3_from(directions[index]).normalized(),
		"caster": _casters.get(spell_id) as Node3D,
		"target": _targets.get(spell_id) as Node3D,
		"target_point": (_targets.get(spell_id) as Node3D).position,
		"target_group": "vfx_benchmark_no_contacts",
		"vfx_bundle": bundle,
	})
	_stage.add_child(delivery)
	_deliveries[spell_id] = delivery


func _maintain_three_spells() -> void:
	var benchmark_spells: Array = _benchmark.get("spells", []) as Array
	for index: int in benchmark_spells.size():
		var spell_id := String(benchmark_spells[index])
		var delivery_value: Variant = _deliveries.get(spell_id)
		if not is_instance_valid(delivery_value):
			_spawn_spell(spell_id, index)
			continue
		var delivery := delivery_value as Node
		if delivery.is_queued_for_deletion():
			_spawn_spell(spell_id, index)
			continue
		var cycles: Array = _benchmark.get("visible_cycle_s", []) as Array
		var snapshot: Dictionary = delivery.call("snapshot") as Dictionary
		if index < cycles.size() and float(snapshot.get("elapsed_s", 0.0)) \
				>= float(cycles[index]):
			delivery.queue_free()
			_spawn_spell(spell_id, index)


func _finish() -> void:
	await RenderingServer.frame_post_draw
	var capture_path := "user://spell-vfx-three.png"
	var image := root.get_texture().get_image()
	var capture_error := image.save_png(capture_path)
	var visible_spell_count := _visible_spell_count()
	var sorted := _frame_times_ms.duplicate()
	sorted.sort()
	var mean_ms := 0.0
	for frame_ms: float in sorted:
		mean_ms += frame_ms
	mean_ms /= float(maxi(sorted.size(), 1))
	var report := {
		"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"resolution": "%dx%d" % [int(_benchmark.get("width", 0)),
			int(_benchmark.get("height", 0))],
		"sample_frames": sorted.size(),
		"average_fps": 1000.0 / mean_ms if mean_ms > 0.0 else 0.0,
		"average_frame_ms": mean_ms,
		"p95_frame_ms": _percentile(sorted, 0.95),
		"p99_frame_ms": _percentile(sorted, 0.99),
		"worst_frame_ms": sorted[-1] if not sorted.is_empty() else 0.0,
		"draw_calls": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"static_memory_delta_bytes": OS.get_static_memory_usage() - _memory_before_bytes,
		"static_memory_peak_bytes": OS.get_static_memory_peak_usage(),
		"residency": _residency.stats(),
		"visible_spell_count": visible_spell_count,
		"capture_ok": capture_error == OK and visible_spell_count \
			== (_benchmark.get("spells", []) as Array).size(),
	}
	print("[vfx-benchmark] RESULT %s" % JSON.stringify(report))
	print("[vfx-benchmark] CAPTURE %s" % ProjectSettings.globalize_path(capture_path))
	for delivery_value: Variant in _deliveries.values():
		if is_instance_valid(delivery_value):
			(delivery_value as Node).queue_free()
	_deliveries.clear()
	await process_frame
	await process_frame
	quit(0 if bool(report.get("capture_ok", false)) else 1)


func _visible_spell_count() -> int:
	var count := 0
	for raw_id: Variant in _benchmark.get("spells", []):
		var delivery_value: Variant = _deliveries.get(String(raw_id))
		if not is_instance_valid(delivery_value):
			continue
		var delivery := delivery_value as Node3D
		if delivery.is_queued_for_deletion():
			continue
		var snapshot: Dictionary = delivery.call("snapshot") as Dictionary
		if bool(snapshot.get("alive", false)) and _camera.is_position_in_frustum(
				snapshot.get("primary_position", Vector3.ZERO) as Vector3):
			count += 1
	return count


func _percentile(sorted: Array[float], fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	var index := clampi(ceili(fraction * float(sorted.size())) - 1, 0, sorted.size() - 1)
	return sorted[index]


func _vector3_from(value: Variant) -> Vector3:
	var parts := value as Array
	if parts.size() != 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
