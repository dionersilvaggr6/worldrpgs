extends SceneTree
## Prova autónoma da arte inimiga. Valida escala/pés, produz uma captura com a
## câmara à distância de leitura do catálogo e compara o custo isolado do
## renderer corrente com o proposto.
##
## godot --path game --rendering-method mobile \
##   --script res://assets/models/enemies/monster_visual_audit.gd -- --capture
## godot --path game --rendering-method mobile \
##   --script res://assets/models/enemies/monster_visual_audit.gd \
##   -- --benchmark --implementation=monster

const MONSTER_VISUAL = preload("res://src/visual/monster_visual.gd")
const CURRENT_VISUAL = preload("res://src/enemies/enemy_visual.gd")

var _built := false
var _frames := 0
var _capture := false
var _benchmark := false
var _implementation := "monster"
var _camera_distance_m := 20.0
var _warmup_s := 0.0
var _duration_s := 0.0
var _elapsed_s := 0.0
var _samples: Array[float] = []
var _failures: Array[String] = []


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--capture":
			_capture = true
		elif argument == "--benchmark":
			_benchmark = true
		elif argument.begins_with("--implementation="):
			_implementation = argument.trim_prefix("--implementation=")
		elif argument.begins_with("--distance="):
			_camera_distance_m = maxf(3.0, argument.trim_prefix("--distance=").to_float())
	var audit: Dictionary = MONSTER_VISUAL.audit_rules()
	_warmup_s = float(audit.get("benchmark_warmup_s", 0.0))
	_duration_s = float(audit.get("benchmark_duration_s", 0.0))
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0


func _process(delta: float) -> bool:
	_frames += 1
	if not _built and _frames > 1:
		_built = true
		_build_stage()
		if not _benchmark and not _capture:
			_finish_validation()
			return false
	if not _built:
		return false
	if _benchmark:
		_elapsed_s += delta
		if _elapsed_s > _warmup_s:
			_samples.append(delta * 1000.0)
		if _elapsed_s >= _warmup_s + _duration_s:
			_report_benchmark()
			quit(1 if not _failures.is_empty() else 0)
		return false
	if _capture and _frames > 24:
		_capture_and_finish()
	return false


func _build_stage() -> void:
	# SettingsSystem aplica o limite do perfil depois de _initialize(); o A/B
	# precisa de folga real, por isso fixa outra vez aqui, já depois dos autoloads.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var stage := Node3D.new()
	stage.name = "AuditoriaArteInimiga"
	root.add_child(stage)
	_build_environment(stage)
	var ids := MONSTER_VISUAL.family_ids()
	var actor_count := int(MONSTER_VISUAL.audit_rules().get("benchmark_actor_count", ids.size())) \
		if _benchmark else ids.size()
	for index: int in actor_count:
		var enemy_id := ids[index % ids.size()]
		var visual := _new_visual(enemy_id, index)
		stage.add_child(visual)
		visual.position = _actor_position(index, actor_count)
		if _implementation == "monster":
			var integration_profile := {"target_height_m": MONSTER_VISUAL.profile_for(
				enemy_id).get("target_height_m", 0.0)}
			visual.call("setup", enemy_id, {}, integration_profile, false, index)
			_validate_monster(enemy_id, visual)
		if not _benchmark:
			_add_label(stage, enemy_id, visual.position,
				float(MONSTER_VISUAL.profile_for(enemy_id).get("target_height_m", 0.0)))
	_validate_family_set(ids)


func _new_visual(enemy_id: String, seed: int) -> Node3D:
	if _implementation == "monster":
		return MONSTER_VISUAL.new()
	if _implementation != "current":
		_failures.append("implementação desconhecida: %s" % _implementation)
		return MONSTER_VISUAL.new()
	var game_data := root.get_node("GameData")
	var all_enemies: Dictionary = game_data.get("enemies") as Dictionary
	var presentation: Dictionary = all_enemies.get("_presentation", {}) as Dictionary
	var enemy_data: Dictionary = game_data.call("enemy", enemy_id) as Dictionary
	var profiles: Dictionary = presentation.get("visual_profiles", {}) as Dictionary
	var profile_key := enemy_id
	if not profiles.has(profile_key):
		profile_key = "%s:%s" % [enemy_data.get("race_id", ""), enemy_data.get("role", "")]
	var profile := (profiles.get(profile_key, {}) as Dictionary).duplicate(true)
	profile["animation_blend_s"] = float(presentation.get("animation_blend_s", 0.0))
	var visual := CURRENT_VISUAL.new()
	visual.call_deferred("setup", enemy_id, enemy_data, profile, false, seed)
	return visual


func _validate_monster(enemy_id: String, visual: Node3D) -> void:
	var audit := MONSTER_VISUAL.audit_rules()
	var profile := MONSTER_VISUAL.profile_for(enemy_id)
	var body: AABB = visual.call("body_bounds") as AABB
	var full: AABB = visual.call("visual_bounds") as AABB
	var target := float(profile.get("target_height_m", 0.0))
	var ground_tolerance := float(audit.get("ground_tolerance_m", 0.0))
	var height_tolerance := float(audit.get("height_tolerance_m", 0.0))
	_check(absf(body.position.y) <= ground_tolerance,
		"%s: pés a %.4f m do chão" % [enemy_id, body.position.y])
	_check(absf(body.size.y - target) <= height_tolerance,
		"%s: corpo mede %.4f m, alvo %.4f m" % [enemy_id, body.size.y, target])
	_check(full.position.y >= -ground_tolerance,
		"%s: silhueta atravessa o chão em %.4f m" % [enemy_id, full.position.y])
	var distance := float(audit.get("readability_distance_m", 20.0))
	var fov_rad := deg_to_rad(float(audit.get("vertical_fov_deg", 70.0)))
	var viewport_height := float(audit.get("viewport_height_px", 1080.0))
	var body_pixels := 2.0 * atan(target / (2.0 * distance)) / fov_rad * viewport_height
	_check(body_pixels >= float(audit.get("minimum_body_height_px_at_distance", 0.0)),
		"%s: só %.1f px de corpo a %.0f m" % [enemy_id, body_pixels, distance])
	print("[MONSTER_AUDIT] família=%s corpo=%.3fm pés=%.4fm silhueta_piso=%.4fm leitura_%.0fm=%.1fpx" % [
		enemy_id, body.size.y, body.position.y, full.position.y, distance, body_pixels])


func _validate_family_set(ids: Array[String]) -> void:
	var expected_count := int(MONSTER_VISUAL.audit_rules().get(
		"expected_family_count", ids.size()))
	_check(ids.size() == expected_count,
		"catálogo tem as %d famílias declaradas" % expected_count)
	var signatures: Dictionary = {}
	var heights: Array[float] = []
	for enemy_id: String in ids:
		var profile := MONSTER_VISUAL.profile_for(enemy_id)
		var signature := String(profile.get("silhouette_signature", ""))
		_check(not signature.is_empty() and not signatures.has(signature),
			"%s tem assinatura de silhueta própria" % enemy_id)
		signatures[signature] = true
		heights.append(float(profile.get("target_height_m", 0.0)))
	heights.sort()
	for index: int in range(1, heights.size()):
		_check(heights[index] > heights[index - 1],
			"as alturas de silhueta do catálogo são distintas")


func _build_environment(stage: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#344047")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#82949a")
	environment.ambient_light_energy = 0.72
	world_environment.environment = environment
	stage.add_child(world_environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	key.light_color = Color("#bdc8c5")
	key.light_energy = 1.05
	key.shadow_enabled = false
	stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-24.0, 150.0, 0.0)
	rim.light_color = Color("#667d82")
	rim.light_energy = 0.48
	rim.shadow_enabled = false
	stage.add_child(rim)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(18.0, 12.0)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("#26302e")
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	stage.add_child(ground)
	var camera := Camera3D.new()
	camera.fov = float(MONSTER_VISUAL.audit_rules().get("vertical_fov_deg", 70.0))
	camera.look_at_from_position(Vector3(0.0, 1.65, -_camera_distance_m),
		Vector3(0.0, 1.35, 0.0))
	camera.current = true
	stage.add_child(camera)


func _actor_position(index: int, actor_count: int) -> Vector3:
	if actor_count == 3:
		return Vector3((float(index) - 1.0) * 3.4, 0.0, 0.0)
	var row := index / 3
	var column := index % 3
	return Vector3((float(column) - 1.0) * 3.2, 0.0, float(row) * 2.7)


func _add_label(stage: Node3D, enemy_id: String, actor_position: Vector3,
		target_height: float) -> void:
	var profile := MONSTER_VISUAL.profile_for(enemy_id)
	var label := Label3D.new()
	label.text = "%s — %.2f m" % [profile.get("display_name", enemy_id), target_height]
	label.font_size = 28
	label.outline_size = 7
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = actor_position + Vector3.UP * (target_height + 0.58)
	stage.add_child(label)


func _capture_and_finish() -> void:
	_capture = false
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://captures/enemy-art-%dm.png" % int(_camera_distance_m)
	var error := image.save_png(path)
	_check(error == OK, "captura escrita em %s" % path)
	print("[MONSTER_AUDIT] captura=%s" % path)
	_finish_validation()


func _finish_validation() -> void:
	if _failures.is_empty():
		print("[MONSTER_AUDIT] PASS famílias=%d escala=JSON pés=no_chão leitura=%.0fm" \
			% [MONSTER_VISUAL.family_ids().size(), float(MONSTER_VISUAL.audit_rules().get(
				"readability_distance_m", 20.0))])
		quit(0)
		return
	for failure: String in _failures:
		printerr("[MONSTER_AUDIT] FAIL %s" % failure)
	quit(1)


func _report_benchmark() -> void:
	if _samples.is_empty():
		_failures.append("benchmark sem amostras")
		return
	var sorted := _samples.duplicate()
	sorted.sort()
	var total_ms := 0.0
	for sample: float in _samples:
		total_ms += sample
	var count := sorted.size()
	var p95: float = sorted[clampi(ceili(float(count) * 0.95) - 1, 0, count - 1)]
	var p99: float = sorted[clampi(ceili(float(count) * 0.99) - 1, 0, count - 1)]
	var result := {
		"implementation": _implementation,
		"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"resolution": "%dx%d" % [int(root.get_visible_rect().size.x), int(root.get_visible_rect().size.y)],
		"actors": int(MONSTER_VISUAL.audit_rules().get("benchmark_actor_count", 0)),
		"seconds": _duration_s,
		"avg_fps": snappedf(float(count) / (total_ms / 1000.0), 0.1),
		"p95_frame_ms": snappedf(p95, 0.001),
		"p99_frame_ms": snappedf(p99, 0.001),
		"worst_frame_ms": snappedf(float(sorted[-1]), 0.001),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"primitives": int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		"video_mem_mb": snappedf(Performance.get_monitor(
			Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1)
	}
	print("MONSTER_BENCH_RESULT " + JSON.stringify(result))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
