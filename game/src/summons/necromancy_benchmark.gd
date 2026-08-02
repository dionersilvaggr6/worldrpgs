extends Node3D
## Mede o custo incremental dos invocados sobre o cenário de risco declarado:
## dois jogadores + cinco inimigos. `--summons` não tem tecto deliberadamente.
##
## godot --path game/ --rendering-method mobile --windowed \
##   res://src/summons/necromancy_benchmark.tscn -- \
##   --summons=3 --vsync=off --capture=necromancia-3.png

const RaisedEnemyScript := preload("res://src/enemies/raised_enemy.gd")

const BASE_PLAYER_ACTORS := 2
const BASE_HOSTILE_ACTORS := 5

class DummyTarget extends Node3D:
	func is_alive() -> bool:
		return true

	func state_name() -> String:
		return "livre"

	func take_damage(_info: Variant) -> void:
		pass


class DurableEnemy extends Enemy:
	## Conserva IA, rig, tells e reacções durante toda a amostra.
	func take_damage(_info: DamageInfo) -> void:
		pass


var _summon_count := 0
var _warmup_seconds := 0.0
var _sample_seconds := 0.0
var _viewport_size := Vector2i.ZERO
var _vsync_on := false
var _capture_name := ""
var _elapsed_seconds := 0.0
var _last_wall_usec := 0
var _samples_ms: Array[float] = []
var _captured := false
var _capture_complete := false
var _hostiles: Array[Enemy] = []
var _raised: Array[Enemy] = []


func _ready() -> void:
	var config := GameData.enemies.get("_ai_benchmark", {}) as Dictionary
	_warmup_seconds = float(config.get("warmup_seconds", 0.0))
	_sample_seconds = float(config.get("sample_seconds", 0.0))
	_viewport_size = Vector2i(int(config.get("viewport_width_px", 0)),
		int(config.get("viewport_height_px", 0)))
	_parse_arguments()
	Bench.set_overlay_visible(false)
	DisplayServer.window_set_size(_viewport_size)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if _vsync_on else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_build_stage(config)
	_last_wall_usec = Time.get_ticks_usec()
	print("[NECROMANCY_BENCH] baseline=%d summons=%d actors=%d resolution=%dx%d renderer=%s gpu=%s vsync=%s" % [
		BASE_PLAYER_ACTORS + BASE_HOSTILE_ACTORS, _summon_count,
		BASE_PLAYER_ACTORS + BASE_HOSTILE_ACTORS + _summon_count,
		_viewport_size.x, _viewport_size.y,
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_video_adapter_name(), "on" if _vsync_on else "off"])


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var wall_delta := float(now - _last_wall_usec) / 1000000.0
	_last_wall_usec = now
	_elapsed_seconds += wall_delta
	if _elapsed_seconds < _warmup_seconds:
		return
	if not _captured and not _capture_name.is_empty():
		_captured = true
		_capture.call_deferred()
		return
	if _captured and not _capture_complete:
		return
	_samples_ms.append(wall_delta * 1000.0)
	if _elapsed_seconds < _warmup_seconds + _sample_seconds:
		return
	_report()
	get_tree().quit()


func _physics_process(_delta: float) -> void:
	# Replica o custo O(invocados x hostis) de NecromancyRuntime sem introduzir
	# um tecto; cada actor continua a executar a sua IA Enemy normal.
	var hostiles := get_tree().get_nodes_in_group("enemies")
	for summon: Enemy in _raised:
		var nearest: Enemy
		var nearest_distance := INF
		for hostile_value: Variant in hostiles:
			var hostile := hostile_value as Enemy
			if hostile == null or not hostile.is_alive():
				continue
			var distance := summon.global_position.distance_squared_to(
				hostile.global_position)
			if distance < nearest_distance:
				nearest = hostile
				nearest_distance = distance
		if nearest != null:
			summon.target = nearest


func _build_stage(config: Dictionary) -> void:
	_add_environment()
	_add_floor()
	_add_camera_and_light(config)
	var target := DummyTarget.new()
	target.position = Vector3.UP * float(config.get("spawn_height_m", 0.0))
	add_child(target)
	_build_player_visuals()
	_build_hostiles(target, config)
	_build_raised(target, config)


func _build_player_visuals() -> void:
	for index: int in BASE_PLAYER_ACTORS:
		var visual := CharacterVisual.new()
		visual.position = Vector3((float(index) - 0.5) * 1.8, 0.0, 3.2)
		add_child(visual)
		visual.setup(1.8, Color.WHITE, true, "body_male",
			"evil_mage" if index == 0 else "sorcerer")
		visual.play_animation("Jog_Fwd")


func _build_hostiles(target: DummyTarget, config: Dictionary) -> void:
	var enemy_id := String(config.get("enemy_id", ""))
	var radius := float(GameData.enemy(enemy_id).get("attack_range", 0.0)) * 2.2
	for index: int in BASE_HOSTILE_ACTORS:
		var enemy: Enemy = DurableEnemy.new()
		add_child(enemy)
		var angle := TAU * float(index) / float(BASE_HOSTILE_ACTORS)
		enemy.position = Vector3(sin(angle) * radius,
			float(config.get("spawn_height_m", 0.0)), cos(angle) * radius)
		enemy.setup(enemy_id, {}, false, index + 1)
		enemy.target = target
		_hostiles.append(enemy)


func _build_raised(caster: DummyTarget, config: Dictionary) -> void:
	if _summon_count <= 0:
		return
	var enemy_id := String(config.get("enemy_id", ""))
	var raise_effect := GameData.spell("levantar").get("effect", {}) as Dictionary
	var original_health := float(GameData.enemy(enemy_id).get("health", 0.0))
	var raised_health := original_health * float(
		raise_effect.get("raised_health_fraction", 0.0))
	var order := String(GameData.ability("evil_mage").get("default_order", ""))
	var radius := float(GameData.enemy(enemy_id).get("preferred_distance", 0.0)) * 2.4
	for index: int in _summon_count:
		var raised: Enemy = RaisedEnemyScript.new()
		add_child(raised)
		var angle := TAU * float(index) / float(_summon_count)
		raised.position = Vector3(sin(angle) * radius,
			float(config.get("spawn_height_m", 0.0)), cos(angle) * radius)
		raised.call("setup_raised", enemy_id, {}, {
			"summon_id": "benchmark-raised-%d" % index,
			"max_health": raised_health,
			"order": order,
		}, caster, &"benchmark-caster", &"benchmark-simulation")
		raised.target = _hostiles[index % _hostiles.size()]
		_raised.append(raised)


func _add_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("15191b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("9a8d82")
	environment.ambient_light_energy = 0.72
	world.environment = environment
	add_child(world)


func _add_floor() -> void:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(24.0, 1.0, 18.0)
	collision.shape = shape
	collision.position.y = -shape.size.y * 0.5
	body.add_child(collision)
	add_child(body)
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	floor_mesh.mesh = box
	floor_mesh.position = collision.position
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("292a27")
	material.roughness = 1.0
	floor_mesh.material_override = material
	add_child(floor_mesh)


func _add_camera_and_light(config: Dictionary) -> void:
	var camera := Camera3D.new()
	var camera_values := config.get("camera_position", []) as Array
	camera.position = Vector3(float(camera_values[0]), float(camera_values[1]),
		float(camera_values[2])) if camera_values.size() == 3 else Vector3.ZERO
	add_child(camera)
	camera.look_at_from_position(camera.position, Vector3.UP)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	light.light_energy = 1.05
	light.shadow_enabled = true
	add_child(light)


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "user://%s" % _capture_name
	var error := image.save_png(path)
	_last_wall_usec = Time.get_ticks_usec()
	_capture_complete = true
	print("[NECROMANCY_CAPTURE] path=%s error=%d" % [
		ProjectSettings.globalize_path(path), error])


func _report() -> void:
	if _samples_ms.is_empty():
		printerr("[NECROMANCY_BENCH_ERROR] sem amostras")
		return
	_samples_ms.sort()
	var total_ms := 0.0
	for sample_ms: float in _samples_ms:
		total_ms += sample_ms
	var average_ms := total_ms / float(_samples_ms.size())
	var p95_index := clampi(ceili(float(_samples_ms.size()) * 0.95) - 1,
		0, _samples_ms.size() - 1)
	var p99_index := clampi(ceili(float(_samples_ms.size()) * 0.99) - 1,
		0, _samples_ms.size() - 1)
	var result := {
		"baseline_actors": BASE_PLAYER_ACTORS + BASE_HOSTILE_ACTORS,
		"summons": _summon_count,
		"total_actors": BASE_PLAYER_ACTORS + BASE_HOSTILE_ACTORS + _summon_count,
		"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"resolution": "%dx%d" % [_viewport_size.x, _viewport_size.y],
		"vsync": "on" if _vsync_on else "off",
		"samples": _samples_ms.size(),
		"average_fps": snappedf(1000.0 / average_ms, 0.1),
		"average_ms": snappedf(average_ms, 0.001),
		"p95_ms": snappedf(_samples_ms[p95_index], 0.001),
		"p99_ms": snappedf(_samples_ms[p99_index], 0.001),
		"worst_ms": snappedf(_samples_ms[-1], 0.001),
		"draw_calls": int(Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(
			Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"static_memory_mb": snappedf(float(OS.get_static_memory_usage())
			/ 1048576.0, 0.1),
		"video_mem_mb": snappedf(Performance.get_monitor(
			Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
	}
	print("NECROMANCY_BENCH_RESULT " + JSON.stringify(result))


func _parse_arguments() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--summons="):
			_summon_count = maxi(argument.trim_prefix("--summons=").to_int(), 0)
		elif argument.begins_with("--vsync="):
			_vsync_on = argument.trim_prefix("--vsync=") == "on"
		elif argument.begins_with("--capture="):
			_capture_name = argument.trim_prefix("--capture=")
