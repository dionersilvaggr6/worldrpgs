class_name ArenaVorgar
extends Node3D
## Arena dedicada do Vorgar.
##
## [CODEX] A sala usa o alvo normal de 24 x 22 m do spec/61, em vez do minimo
## historico de 20 x 16 m. Razao: as marcas SEPARAR ficam a 16 m uma da outra e
## ainda conservam duas rotas de fuga com mais de 3 m entre pilar e parede.
## Alternativa descartada: conservar 20 x 16 m; passa o minimo aritmetico, mas
## deixa pouco espaco quando os dois jogadores, o chefe e um volume persistente
## ocupam a mesma metade.
##
## Este ficheiro nao decide ataques nem contagens de impactos. O agente do
## Vorgar chama set_cover_broken() e set_gate_closed() a partir dos seus dados.

signal gate_state_changed(closed: bool)
signal cover_state_changed(cover_id: StringName, broken: bool)
signal threshold_entered(player: Node3D)
signal threshold_exited(player: Node3D)
signal arena_ready(arena_id: StringName)
signal arena_blocked(arena_id: StringName, dependency: String)
signal sequence_started(objective: String)
signal sequence_committed(objective: String)
signal sequence_finished(objective: String)
signal revive_channel_started(reviver: Node3D, downed: Node3D)
signal revive_channel_cancelled(reason: String)
signal player_revived(player: Node3D)
signal revive_window_expired(player: Node3D)

var arena_id := StringName()
var _arena_contract: Dictionary = {}
var _marker_positions: Dictionary = {}
var _width_m := 0.0
var _depth_m := 0.0
var _wall_height_m := 0.0
var _threshold_depth_m := 0.0
var _flank_clearance_m := 0.0
var _empurrao_maximo_m := 0.0
var _arena_is_ready := false
var _arena_block_reason := ""
var _mesh_cache: Dictionary = {}
var _covers: Dictionary = {}
var _cover_collisions: Dictionary = {}
var _gate_fog: MeshInstance3D
var _gate_collision: CollisionShape3D
var _gate_status: Label3D
var _preview_camera: Camera3D
var controller_only := false
var _approach_players: Dictionary = {}
var _committed_players: Dictionary = {}
var _machine_ready_peers: Dictionary = {}
var _expected_player_count := 1
var _gate_closed := true
var _boss_physics_before_gate := true

var _boss: Node3D
var _config: Dictionary = {}
var _resurrection_contract: Dictionary = {}
var _local_player: Node3D
var _players: Array[Node3D] = []
var _runtime_guides: Node3D

var _active_sequence: Dictionary = {}
var _sequence_frame := 0
var _sequence_visuals: Array[Node3D] = []
var _sequence_markers: Dictionary = {}
var _sequence_hits: Dictionary = {}
var _safe_zone_local := Vector3.ZERO
var _solo_origin_global := Vector3.ZERO
var _sequence_was_committed := false

var _downed_elapsed: Dictionary = {}
var _downed_expired: Dictionary = {}
var _revive_markers: Dictionary = {}
var _revive_intents: Dictionary = {}
var _reviver: Node3D
var _revived: Node3D
var _revive_progress := 0.0
var _reviver_last_health := 0.0
var _resurrection_was_used := false


func _ready() -> void:
	if not _load_arena_contract():
		return
	_runtime_guides = Node3D.new()
	_runtime_guides.name = "RuntimeGuides"
	add_child(_runtime_guides)
	# A Toca integrada ja fornece chao, paredes, porta e obstaculos. O controlador
	# instalado pelo BossVorgar acrescenta apenas os guias e volumes das sequencias;
	# construir a sala outra vez criaria colisao e custo de render duplicados.
	if controller_only:
		_arena_is_ready = true
		_arena_block_reason = ""
		return
	_build_floor()
	_build_floor_reading()
	_build_boundaries()
	_build_entry()
	_build_covers()
	_build_dressing()
	_build_markers()
	_finish_arena_loading()
	if get_tree().current_scene == self:
		_build_preview_environment()
		_build_preview_audio()
	if "--arena-audit" in OS.get_cmdline_user_args():
		call_deferred("_run_command_line_audit")
	elif "--arena-photos" in OS.get_cmdline_user_args():
		call_deferred("_run_photo_tour")


func set_gate_closed(closed: bool) -> void:
	_gate_closed = closed
	if is_instance_valid(_gate_fog):
		_gate_fog.visible = closed
	if is_instance_valid(_gate_collision):
		_gate_collision.set_deferred("disabled", not closed)
	gate_state_changed.emit(closed)


func is_arena_ready() -> bool:
	return _arena_is_ready


func arena_block_reason() -> String:
	return _arena_block_reason


func empurrao_maximo_m() -> float:
	return _empurrao_maximo_m


func cap_push_displacement(requested: Vector3) -> Vector3:
	if requested.length() <= _empurrao_maximo_m:
		return requested
	if _empurrao_maximo_m <= 0.0:
		return Vector3.ZERO
	return requested.normalized() * _empurrao_maximo_m


func _load_arena_contract() -> bool:
	var arenas := GameData.world.get("arenas", {}) as Dictionary
	_arena_contract = arenas.get("arena_vorgar", {}) as Dictionary
	if _arena_contract.is_empty():
		_block_arena("data/world.json:arenas.arena_vorgar")
		return false
	arena_id = StringName(String(_arena_contract.get("arena_id", "")))
	if arena_id == StringName():
		_block_arena("arena_id")
		return false
	var size := _arena_contract.get("usable_size_m", {}) as Dictionary
	_width_m = float(size.get("width", 0.0))
	_depth_m = float(size.get("depth", 0.0))
	_wall_height_m = float(size.get("wall_height", 0.0))
	_threshold_depth_m = float(size.get("threshold_depth", 0.0))
	_flank_clearance_m = float(size.get("flank_clearance", 0.0))
	_empurrao_maximo_m = float((_arena_contract.get("edge", {}) as Dictionary).get(
		"empurrao_maximo_m", -1.0))
	var smallest_dimension := minf(minf(_width_m, _depth_m), minf(_wall_height_m,
		minf(_threshold_depth_m, _flank_clearance_m)))
	if smallest_dimension <= 0.0 or _empurrao_maximo_m < 0.0:
		_block_arena("usable_size_m/edge.empurrao_maximo_m")
		return false
	var marker_data := _arena_contract.get("markers", {}) as Dictionary
	for marker_value: Variant in marker_data:
		var coordinates := marker_data[marker_value] as Array
		if coordinates.size() != 3:
			_block_arena("markers.%s" % String(marker_value))
			return false
		_marker_positions[StringName(String(marker_value))] = _vector_from_array(coordinates)
	var assets := ((_arena_contract.get("art_and_sound", {}) as Dictionary).get(
		"assets", {}) as Dictionary)
	if assets.is_empty():
		_block_arena("art_and_sound.assets")
		return false
	for asset_id: Variant in assets:
		var dependency := String(assets[asset_id])
		if dependency.is_empty() or not ResourceLoader.exists(dependency):
			_block_arena("art_and_sound.assets.%s" % String(asset_id))
			return false
	return true


func _finish_arena_loading() -> void:
	var ready_contract := _arena_contract.get("arena_ready", {}) as Dictionary
	for required_node: String in ["FogThreshold/Fog", "FogThreshold/ClosedGate",
			"FogThreshold/ReadyThreshold", "Boundaries", "Markers"]:
		if get_node_or_null(required_node) == null:
			_block_arena(required_node)
			return
	if String(ready_contract.get("becomes_true_when", "")).is_empty():
		_block_arena("arena_ready.becomes_true_when")
		return
	_arena_is_ready = true
	_arena_block_reason = ""
	_machine_ready_peers[multiplayer.get_unique_id()] = true
	_update_gate_status("")
	arena_ready.emit(arena_id)


func _asset_path(asset_id: StringName) -> String:
	var assets := ((_arena_contract.get("art_and_sound", {}) as Dictionary).get(
		"assets", {}) as Dictionary)
	return String(assets.get(String(asset_id), ""))


func _block_arena(dependency: String) -> void:
	_arena_is_ready = false
	_arena_block_reason = dependency
	set_gate_closed(true)
	var status := ((_arena_contract.get("entrance", {}) as Dictionary).get(
		"status_text", {}) as Dictionary)
	_update_gate_status(String(status.get("blocked", "Arena incompleta: %s")) % dependency)
	arena_blocked.emit(arena_id, dependency)


func _update_gate_status(message: String) -> void:
	if not is_instance_valid(_gate_status):
		return
	_gate_status.text = message
	_gate_status.visible = not message.is_empty()


func set_cover_broken(cover_id: StringName, broken: bool) -> void:
	var cover := _covers.get(cover_id) as Node3D
	var collision := _cover_collisions.get(cover_id) as CollisionShape3D
	if cover == null or collision == null:
		push_warning("[arena] refugio desconhecido: %s" % cover_id)
		return
	var intact := cover.get_node_or_null("Intact") as Node3D
	var rubble := cover.get_node_or_null("Rubble") as Node3D
	if intact != null:
		intact.visible = not broken
	if rubble != null:
		rubble.visible = broken
	collision.set_deferred("disabled", broken)
	cover_state_changed.emit(cover_id, broken)


func marker_position(marker_id: StringName) -> Vector3:
	var marker := get_node_or_null("Markers/%s" % marker_id) as Marker3D
	if marker != null:
		return marker.global_position
	if _marker_positions.has(marker_id):
		return to_global(_marker_positions[marker_id] as Vector3)
	return global_position


func setup(p_boss: Node3D, p_config: Dictionary, p_local_player: Node3D = null) -> void:
	if p_config.is_empty():
		push_error("Vorgar: ficha vorgar_encounter em falta")
		return
	_boss = p_boss
	_config = p_config.duplicate(true)
	_local_player = p_local_player
	_resurrection_contract = GameData.progression.get("coop_resurrection", {}) as Dictionary
	if StringName(String(_config.get("arena_id", ""))) != arena_id:
		_block_arena("vorgar_encounter.arena_id")
		return
	_sync_players()
	_expected_player_count = maxi(_players.size(), 1)
	_boss_physics_before_gate = _boss.is_physics_processing()
	_build_static_guides()
	if controller_only:
		return
	_publish_local_readiness()
	_register_players_already_inside()
	if _committed_players.size() >= _expected_player_count:
		_commit_party()
	else:
		_set_boss_active(false)
		set_gate_closed(true)


func set_local_player(player: Node3D) -> void:
	_local_player = player


func set_revive_intent(player: Node3D, pressed: bool) -> void:
	if is_instance_valid(player):
		_revive_intents[player.get_instance_id()] = pressed


func _register_players_already_inside() -> void:
	var gate_z := _gate_local_z()
	for player: Node3D in _players:
		if to_local(player.global_position).z < gate_z:
			_committed_players[player.get_instance_id()] = true


func _try_open_gate() -> void:
	var status := ((_arena_contract.get("entrance", {}) as Dictionary).get(
		"status_text", {}) as Dictionary)
	if not _arena_is_ready:
		set_gate_closed(true)
		_update_gate_status(String(status.get("preparing", "A preparar a arena…")))
		return
	var missing_machine := _first_machine_not_ready()
	if missing_machine != 0:
		set_gate_closed(true)
		_update_gate_status(String(status.get("waiting_machine",
			"A preparar a arena… máquina %s")) % missing_machine)
		return
	var ready_players := _committed_players.duplicate()
	for player_id: Variant in _approach_players:
		ready_players[player_id] = true
	if ready_players.size() < _expected_player_count:
		set_gate_closed(true)
		_update_gate_status(String(status.get("waiting_partner", "À espera do parceiro"))
			if _expected_player_count > 1 and not ready_players.is_empty() else "")
		return
	set_gate_closed(false)
	_update_gate_status("")


func _publish_local_readiness() -> void:
	if not _arena_is_ready:
		return
	_machine_ready_peers[multiplayer.get_unique_id()] = true
	if multiplayer.has_multiplayer_peer() and not multiplayer.get_peers().is_empty():
		_receive_arena_ready.rpc(String(arena_id))


@rpc("any_peer", "reliable", "call_remote")
func _receive_arena_ready(reported_arena_id: String) -> void:
	if reported_arena_id != String(arena_id):
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender not in multiplayer.get_peers():
		return
	_machine_ready_peers[sender] = true
	_try_open_gate()


func _first_machine_not_ready() -> int:
	if not multiplayer.has_multiplayer_peer():
		return 0
	if not bool(_machine_ready_peers.get(multiplayer.get_unique_id(), false)):
		return multiplayer.get_unique_id()
	for peer_id: int in multiplayer.get_peers():
		if not bool(_machine_ready_peers.get(peer_id, false)):
			return peer_id
	return 0


func _commit_party() -> void:
	set_gate_closed(true)
	_update_gate_status("")
	_set_boss_active(true)


func _set_boss_active(active: bool) -> void:
	if not is_instance_valid(_boss):
		return
	_boss.set_physics_process(active and _boss_physics_before_gate)


func _gate_local_z() -> float:
	var entrance := _arena_contract.get("entrance", {}) as Dictionary
	return _vector_from_array(entrance.get("collision_center_m", []) as Array).z


func begin_sequence(sequence: Dictionary) -> void:
	end_sequence()
	if sequence.is_empty() or not is_instance_valid(_boss):
		push_error("Vorgar: sequencia ou chefe em falta na arena")
		return
	_active_sequence = sequence.duplicate(true)
	_sequence_frame = 0
	_sequence_was_committed = false
	_sequence_hits.clear()
	_sync_players()
	var objective := String(sequence.get("objectivo_coop", ""))
	match objective:
		"separar":
			_build_separate_markers()
		"juntar":
			_build_join_markers()
		_:
			push_error("Vorgar: objectivo co-op desconhecido '%s'" % objective)
			end_sequence()
			return
	var sound := sequence.get("som_anuncio", {}) as Dictionary
	Sfx.play(String(sound.get("profile", "")), _boss.global_position)
	sequence_started.emit(objective)


func tick_sequence(frame: int) -> void:
	if _active_sequence.is_empty():
		return
	_sequence_frame = frame
	_sync_players()
	var commitment := int(_active_sequence.get("momento_compromisso_frame"))
	if not _sequence_was_committed and frame >= commitment:
		_sequence_was_committed = true
		sequence_committed.emit(String(_active_sequence.get("objectivo_coop", "")))
	var startup := int(_active_sequence.get("startup"))
	var active := int(_active_sequence.get("active"))
	var objective := String(_active_sequence.get("objectivo_coop", ""))
	if objective == "separar":
		_update_separate_markers(frame)
	if frame > startup + active:
		_set_sequence_visuals_visible(false)
		return
	_set_sequence_visuals_visible(true)
	if frame <= startup:
		return
	var active_frame := frame - startup
	match objective:
		"separar":
			_resolve_separate(active_frame)
		"juntar":
			_resolve_join(active_frame)


func end_sequence() -> void:
	if not _active_sequence.is_empty():
		sequence_finished.emit(String(_active_sequence.get("objectivo_coop", "")))
	for visual: Node3D in _sequence_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	_sequence_visuals.clear()
	_sequence_markers.clear()
	_sequence_hits.clear()
	_active_sequence = {}
	_sequence_frame = 0
	_sequence_was_committed = false


func join_safe_center_global() -> Vector3:
	return to_global(_safe_zone_local)


func sequence_visuals_visible() -> bool:
	for visual: Node3D in _sequence_visuals:
		if is_instance_valid(visual) and visual.visible:
			return true
	return false


func join_reach_budget() -> Dictionary:
	var sequence := _active_or_named_sequence("juntar")
	var clearance := float(sequence.get("safe_zone_min_boss_distance_m"))
	var half_diagonal := Vector2(_width_m, _depth_m).length() * 0.5
	var available_seconds := GameData.frames_to_seconds(float(sequence.get("startup")))
	var run_speed := float(GameData.section("movement").get("run_speed"))
	return {
		"required_max_m": half_diagonal + clearance,
		"available_m": available_seconds * run_speed,
		"warning_seconds": available_seconds,
	}


func visual_cost_snapshot() -> Dictionary:
	var counts := _count_visual_descendants(_runtime_guides)
	return {
		"meshes": counts.x,
		"labels": counts.y,
		"mesh_budget": int(_config.get("max_visual_meshes")),
		"label_budget": int(_config.get("max_visual_labels")),
	}


func _sync_players() -> void:
	_players.clear()
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player := node as Node3D
		if player != null:
			_players.append(player)
	if _local_player == null and not _players.is_empty():
		_local_player = _players.front()


func _build_static_guides() -> void:
	if not is_instance_valid(_runtime_guides):
		return
	for existing: Node in _runtime_guides.get_children():
		if bool(existing.get_meta("vorgar_static_guide", false)):
			existing.queue_free()
	var colors := _config.get("colors", {}) as Dictionary
	var labels := _config.get("labels", {}) as Dictionary
	var coop_space := _arena_contract.get("coop_space", {}) as Dictionary
	for marker_value: Variant in coop_space.get("separate_markers", []):
		var marker := _make_disc(
			float(_config.get("flank_marker_radius_m")),
			Color(String(colors.get("flank"))),
			float(_config.get("guide_alpha")),
			String(labels.get("flank")))
		marker.position = _marker_positions[StringName(String(marker_value))]
		marker.set_meta("vorgar_static_guide", true)
		_runtime_guides.add_child(marker)
	for marker_value: Variant in coop_space.get("temporary_refuges", []):
		var marker := _make_disc(
			float(_config.get("refuge_marker_radius_m")),
			Color(String(colors.get("refuge"))),
			float(_config.get("guide_alpha")),
			String(labels.get("refuge")))
		marker.position = _marker_positions[StringName(String(marker_value))]
		marker.set_meta("vorgar_static_guide", true)
		_runtime_guides.add_child(marker)


func _build_separate_markers() -> void:
	var colors := _config.get("colors", {}) as Dictionary
	var labels := _config.get("labels", {}) as Dictionary
	var alive := _alive_players()
	for player: Node3D in alive:
		var marker := _make_disc(
			float(_active_sequence.get("marker_radius_m")),
			Color(String(colors.get("danger"))),
			float(_config.get("danger_alpha")),
			String(labels.get("separate")))
		_runtime_guides.add_child(marker)
		marker.global_position = player.global_position
		_sequence_visuals.append(marker)
		_sequence_markers[player.get_instance_id()] = marker
	if alive.size() == 1:
		_solo_origin_global = alive.front().global_position


func _update_separate_markers(frame: int) -> void:
	var alive := _alive_players()
	var solo := alive.size() == 1
	var freeze_frame := int(_active_sequence.get("solo_marker_freeze_frame"))
	for player: Node3D in alive:
		var marker := _sequence_markers.get(player.get_instance_id()) as Node3D
		if not is_instance_valid(marker):
			continue
		if not solo or frame <= freeze_frame:
			marker.global_position = player.global_position
			if solo:
				_solo_origin_global = player.global_position


func _build_join_markers() -> void:
	_safe_zone_local = to_local(_choose_join_safe_center())
	var colors := _config.get("colors", {}) as Dictionary
	var labels := _config.get("labels", {}) as Dictionary
	var danger := _make_rectangle(Vector2(_width_m, _depth_m),
		Color(String(colors.get("danger"))), float(_config.get("danger_alpha")),
		String(labels.get("join")))
	_runtime_guides.add_child(danger)
	_sequence_visuals.append(danger)
	var safe := _make_disc(float(_active_sequence.get("safe_zone_radius_m")),
		Color(String(colors.get("safe"))), float(_config.get("safe_alpha")),
		String(labels.get("join")))
	safe.position = _safe_zone_local
	_runtime_guides.add_child(safe)
	_sequence_visuals.append(safe)


func _choose_join_safe_center() -> Vector3:
	var alive := _alive_players()
	var desired := _boss.global_position
	var coop_space := _arena_contract.get("coop_space", {}) as Dictionary
	if alive.size() == 1:
		var nearest_distance: float = INF
		for marker_value: Variant in coop_space.get("separate_markers", []):
			var candidate: Vector3 = marker_position(StringName(String(marker_value)))
			var distance: float = alive.front().global_position.distance_to(candidate)
			if distance < nearest_distance:
				nearest_distance = distance
				desired = candidate
	elif not alive.is_empty():
		desired = Vector3.ZERO
		for player: Node3D in alive:
			desired += player.global_position
		desired /= float(alive.size())
	var boss_forward := -_boss.global_transform.basis.z.normalized()
	var from_boss := desired - _boss.global_position
	from_boss.y = 0.0
	var clearance := float(_active_sequence.get("safe_zone_min_boss_distance_m"))
	if from_boss.length() < clearance or boss_forward.dot(from_boss.normalized()) < 0.0:
		from_boss = boss_forward * clearance
	desired = _boss.global_position + from_boss
	var local := to_local(desired)
	var radius := float(_active_sequence.get("safe_zone_radius_m"))
	local.x = clampf(local.x, -_width_m * 0.5 + radius, _width_m * 0.5 - radius)
	local.z = clampf(local.z, -_depth_m * 0.5 + radius, _depth_m * 0.5 - radius)
	local.y = 0.0
	return to_global(local)


func _resolve_separate(active_frame: int) -> void:
	if not _damage_tick_due(active_frame):
		return
	var alive := _alive_players()
	if alive.size() == 1:
		var player: Node3D = alive.front()
		if player.global_position.distance_to(_solo_origin_global) <= float(
				_active_sequence.get("marker_radius_m")):
			_apply_sequence_damage(player)
		return
	var minimum := float(_active_sequence.get("minimum_player_separation_m"))
	for player: Node3D in alive:
		for other: Node3D in alive:
			if player == other:
				continue
			if player.global_position.distance_to(other.global_position) < minimum:
				_apply_sequence_damage(player)
				break


func _resolve_join(active_frame: int) -> void:
	if not _damage_tick_due(active_frame):
		return
	var radius := float(_active_sequence.get("safe_zone_radius_m"))
	var safe_global := join_safe_center_global()
	for player: Node3D in _alive_players():
		if player.global_position.distance_to(safe_global) > radius:
			_apply_sequence_damage(player)


func _damage_tick_due(active_frame: int) -> bool:
	var interval := int(_active_sequence.get("damage_interval_frames"))
	return active_frame == 1 or (active_frame - 1) % interval == 0


func _apply_sequence_damage(player: Node3D) -> void:
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return
	var interval := int(_active_sequence.get("damage_interval_frames"))
	var last_frame := int(_sequence_hits.get(player.get_instance_id(), -interval))
	if _sequence_frame - last_frame < interval:
		return
	var boss_data := _boss.get("data") as Dictionary
	var damage := boss_data.get("damage", {}) as Dictionary
	var weight := String(_active_sequence.get("weight"))
	var info := DamageInfo.make(float(damage.get(weight)), _boss, weight)
	info.is_aoe = true
	info.parryable = false
	info.attack_id = String(_active_sequence.get("id"))
	player.call("take_damage", info)
	_sequence_hits[player.get_instance_id()] = _sequence_frame


func reset_attempt() -> void:
	end_sequence()
	_cancel_revive_channel("reset_tentativa", false)
	_resurrection_was_used = false
	_downed_elapsed.clear()
	_downed_expired.clear()
	_revive_intents.clear()
	for marker_value: Variant in _revive_markers.values():
		var marker_data := marker_value as Dictionary
		var root := marker_data.get("root") as Node3D
		if is_instance_valid(root):
			root.queue_free()
	_revive_markers.clear()
	if controller_only:
		return
	_approach_players.clear()
	_committed_players.clear()
	_sync_players()
	_expected_player_count = maxi(_players.size(), 1)
	_register_players_already_inside()
	if _committed_players.size() >= _expected_player_count:
		_commit_party()
	else:
		set_gate_closed(true)
		_set_boss_active(false)


func resurrection_used() -> bool:
	return _resurrection_was_used


func resurrection_progress_seconds() -> float:
	return _revive_progress


func _physics_process(delta: float) -> void:
	if _config.is_empty():
		return
	_sync_players()
	_tick_resurrection(delta)


func _tick_resurrection(delta: float) -> void:
	_refresh_downed_players(delta)
	if _resurrection_was_used:
		_cancel_revive_channel("utilizacao_consumida", false)
		return
	var downed := _first_revivable_player()
	if downed == null:
		_cancel_revive_channel("sem_corpo_valido", false)
		return
	var reviver := _find_reviver_for(downed)
	if reviver == null:
		_cancel_revive_channel("interaccao_ou_distancia", true)
		return
	if _reviver != reviver or _revived != downed:
		_start_revive_channel(reviver, downed)
		return
	var current_health := float(reviver.get("health"))
	if bool(_resurrection_contract.get("damage_interrupts")) \
			and current_health < _reviver_last_health:
		_cancel_revive_channel("dano", true)
		return
	_reviver_last_health = current_health
	_revive_progress += delta
	_refresh_revive_marker(downed)
	if _revive_progress >= float((_config.get("resurrection", {}) as Dictionary).get(
			"channel_seconds")):
		_complete_revive()


func _refresh_downed_players(delta: float) -> void:
	var window := float(_resurrection_contract.get("window_seconds"))
	for player: Node3D in _players:
		var id := player.get_instance_id()
		if _is_alive(player):
			if _downed_elapsed.has(id):
				_remove_revive_marker(id)
				_downed_elapsed.erase(id)
				_downed_expired.erase(id)
			continue
		if not _downed_elapsed.has(id):
			_downed_elapsed[id] = 0.0
			_downed_expired[id] = false
			_build_revive_marker(player)
		else:
			_downed_elapsed[id] = float(_downed_elapsed[id]) + delta
		if not bool(_downed_expired[id]) and float(_downed_elapsed[id]) >= window:
			_downed_expired[id] = true
			_remove_revive_marker(id)
			revive_window_expired.emit(player)
		elif not bool(_downed_expired[id]):
			_refresh_revive_marker(player)


func _first_revivable_player() -> Node3D:
	for player: Node3D in _players:
		var id := player.get_instance_id()
		if not _is_alive(player) and _downed_elapsed.has(id) and not bool(
				_downed_expired[id]):
			return player
	return null


func _find_reviver_for(downed: Node3D) -> Node3D:
	var radius := float(_config.get("revive_radius_m"))
	var closest: Node3D
	var closest_distance := INF
	for player: Node3D in _players:
		if player == downed or not _is_alive(player) or not _revive_intent_for(player):
			continue
		var distance := player.global_position.distance_to(downed.global_position)
		if distance <= radius and distance < closest_distance:
			closest = player
			closest_distance = distance
	return closest


func _revive_intent_for(player: Node3D) -> bool:
	var id := player.get_instance_id()
	if _revive_intents.has(id):
		return bool(_revive_intents[id])
	var action := String((_config.get("resurrection", {}) as Dictionary).get(
		"input_action"))
	return player == _local_player and Input.is_action_pressed(action)


func _start_revive_channel(reviver: Node3D, downed: Node3D) -> void:
	_reviver = reviver
	_revived = downed
	_revive_progress = 0.0
	_reviver_last_health = float(reviver.get("health"))
	var resurrection := _config.get("resurrection", {}) as Dictionary
	if bool(resurrection.get("boss_targets_reviver")) and _boss.has_method("taunt"):
		_boss.call("taunt", reviver, float(resurrection.get("channel_seconds")))
	var sounds := resurrection.get("sound_profiles", {}) as Dictionary
	Sfx.play(String(sounds.get("begin")), downed.global_position)
	revive_channel_started.emit(reviver, downed)


func _cancel_revive_channel(reason: String, announce: bool) -> void:
	if _reviver == null and _revived == null:
		return
	if announce and is_instance_valid(_revived):
		var sounds := ((_config.get("resurrection", {}) as Dictionary).get(
			"sound_profiles", {}) as Dictionary)
		Sfx.play(String(sounds.get("cancel")), _revived.global_position)
	_reviver = null
	_revived = null
	_revive_progress = 0.0
	_reviver_last_health = 0.0
	revive_channel_cancelled.emit(reason)


func _complete_revive() -> void:
	if not is_instance_valid(_revived) or not _revived.has_method("respawn_at"):
		_cancel_revive_channel("interface_de_jogador_em_falta", true)
		return
	var player := _revived
	var mana_before: Variant = player.get("mana")
	var meditation_before: Variant = player.get("meditation_uses")
	var stamina: Object = player.get("stamina") as Object
	var stamina_before: Variant = stamina.get("current") if stamina != null else null
	player.call("respawn_at", player.global_position)
	player.set("health", float(player.get("max_health")) * float(
		_resurrection_contract.get("revived_health_fraction")))
	if mana_before != null:
		player.set("mana", mana_before)
	if meditation_before != null:
		player.set("meditation_uses", meditation_before)
	if stamina != null and stamina_before != null:
		stamina.set("current", stamina_before)
	_resurrection_was_used = true
	var id := player.get_instance_id()
	_downed_elapsed.erase(id)
	_downed_expired.erase(id)
	_remove_revive_marker(id)
	var sounds := ((_config.get("resurrection", {}) as Dictionary).get(
		"sound_profiles", {}) as Dictionary)
	Sfx.play(String(sounds.get("success")), player.global_position)
	_reviver = null
	_revived = null
	_revive_progress = 0.0
	_reviver_last_health = 0.0
	player_revived.emit(player)


func _build_revive_marker(player: Node3D) -> void:
	var colors := _config.get("colors", {}) as Dictionary
	var labels := _config.get("labels", {}) as Dictionary
	var root := _make_disc(float(_config.get("revive_radius_m")),
		Color(String(colors.get("revive"))), float(_config.get("guide_alpha")),
		String(labels.get("revive")))
	_runtime_guides.add_child(root)
	root.global_position = player.global_position
	_revive_markers[player.get_instance_id()] = {
		"root": root,
		"label": _first_label(root),
	}


func _refresh_revive_marker(player: Node3D) -> void:
	var marker_data := _revive_markers.get(player.get_instance_id(), {}) as Dictionary
	if marker_data.is_empty():
		return
	var root := marker_data.get("root") as Node3D
	var label := marker_data.get("label") as Label3D
	if is_instance_valid(root):
		root.global_position = player.global_position
	if is_instance_valid(label):
		var action := String((_config.get("resurrection", {}) as Dictionary).get(
			"input_action"))
		var channel := float((_config.get("resurrection", {}) as Dictionary).get(
			"channel_seconds"))
		label.text = "%s · %s %.1f/%.1f s" % [
			SettingsSystem.binding_label(action),
			String((_config.get("labels", {}) as Dictionary).get("revive")),
			_revive_progress,
			channel,
		]


func _remove_revive_marker(id: int) -> void:
	var marker_data := _revive_markers.get(id, {}) as Dictionary
	var root := marker_data.get("root") as Node3D
	if is_instance_valid(root):
		root.queue_free()
	_revive_markers.erase(id)


func audit_layout() -> PackedStringArray:
	var failures := PackedStringArray()
	_check(_width_m >= 20.0 and _depth_m >= 16.0, "dimensao minima 20 x 16 m", failures)
	_check(_threshold_depth_m >= 4.0, "limiar com pelo menos 4 m", failures)
	_check(_flank_clearance_m >= 3.0, "dois flancos com pelo menos 3 m", failures)
	var left: Vector3 = _marker_positions[&"separate_left"]
	var right: Vector3 = _marker_positions[&"separate_right"]
	var boss: Vector3 = _marker_positions[&"boss"]
	_check(left.distance_to(right) >= 10.0,
		"SEPARAR conserva pelo menos 10 m entre alvos", failures)
	_check(left.distance_to(boss) >= 3.0 and right.distance_to(boss) >= 3.0,
		"os dois alvos ficam pelo menos 3 m do chefe", failures)
	_check(_covers.size() == 2, "existem dois refugios independentes", failures)
	_check(is_instance_valid(_gate_fog) and is_instance_valid(_gate_collision),
		"nevoeiro e fecho fisico partilham o limiar", failures)
	_check(get_node_or_null("FogThreshold/ReadyThreshold") != null,
		"andar ate ao patamar emite o pedido de entrada", failures)
	_check(get_node_or_null("Boundaries") != null,
		"o limite visivel tem colisao coincidente", failures)
	for marker_id: StringName in _marker_positions:
		_check(get_node_or_null("Markers/%s" % marker_id) != null,
			"marcador %s existe" % marker_id, failures)
	return failures


func _build_floor() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "WorkedFloor"
	add_child(floor_root)
	var clean_tiles: Array[Transform3D] = []
	var rocky_tiles: Array[Transform3D] = []
	for x_index: int in 6:
		for z_index: int in 5:
			var x := -10.0 + float(x_index) * 4.0
			var z := -8.8 + float(z_index) * 4.4
			var transform := Transform3D(
				Basis.IDENTITY.scaled(Vector3(1.0, 1.0, 1.1)), Vector3(x, 0.0, z))
			var outside_join_zone := absf(x) > 6.0 or z < -3.5 or z > 7.0
			if outside_join_zone and (x_index + z_index * 2) % 7 == 0:
				rocky_tiles.append(transform)
			else:
				clean_tiles.append(transform)
	_add_multimesh(floor_root, _asset_path(&"floor"), clean_tiles, "FloorTiles")
	_add_multimesh(floor_root, _asset_path(&"floor_rocks"), rocky_tiles, "RockyFloorTiles")
	_add_static_box(floor_root, "FloorCollision", Vector3(_width_m, 0.4, _depth_m),
		Vector3(0.0, -0.23, 0.0))


func _build_floor_reading() -> void:
	var reading := Node3D.new()
	reading.name = "CombatReading"
	add_child(reading)
	var flank_material := _material(Color("#4b3432"), 0.97)
	var flank_marks: Array[Transform3D] = []
	for x: float in [-8.0, 8.0]:
		for z: float in [-4.4, -1.1, 2.2, 5.5]:
			flank_marks.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.065, z)))
	_add_box_multimesh(reading, Vector3(3.0, 0.035, 2.45), flank_marks,
		flank_material, "BrokenFlankInlays")
	var join_material := _material(Color("#82765d"), 0.96)
	var join_ring := MeshInstance3D.new()
	join_ring.name = "JoinRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 3.65
	torus.outer_radius = 3.92
	torus.rings = 32
	torus.ring_segments = 8
	join_ring.mesh = torus
	join_ring.material_override = join_material
	join_ring.position = Vector3(0.0, 0.055, 2.0)
	join_ring.scale = Vector3(1.0, 0.16, 1.0)
	join_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	reading.add_child(join_ring)
	var threshold_material := _material(Color("#5d4e3d"), 0.96)
	_add_visual_box(reading, "Threshold", Vector3(4.0, 0.045, _threshold_depth_m),
		Vector3(0.0, 0.08, 8.75), threshold_material)


func _build_boundaries() -> void:
	var boundaries := Node3D.new()
	boundaries.name = "Boundaries"
	add_child(boundaries)
	var stone := _material(Color("#292d31"), 0.98)
	var entrance := _arena_contract.get("entrance", {}) as Dictionary
	var gate_size := _vector_from_array(entrance.get("collision_size_m", []) as Array)
	var boundary_thickness := 1.0
	var horizontal_span := _width_m + boundary_thickness
	var side_width := (horizontal_span - gate_size.x) * 0.5
	var side_center := gate_size.x * 0.5 + side_width * 0.5
	var boundary_x := _width_m * 0.5 + boundary_thickness * 0.5
	var boundary_z := _depth_m * 0.5 + boundary_thickness * 0.5
	var wall_size := Vector3(side_width, _wall_height_m, boundary_thickness)
	for edge_name: String in ["North", "South"]:
		var edge_z := -boundary_z if edge_name == "North" else boundary_z
		for side_name: String in ["Left", "Right"]:
			var side_x := -side_center if side_name == "Left" else side_center
			_add_visual_box(boundaries, "%s%sFoundation" % [edge_name, side_name], wall_size,
				Vector3(side_x, _wall_height_m * 0.5, edge_z), stone)
			_add_static_box(boundaries, "%s%sCollision" % [edge_name, side_name], wall_size,
				Vector3(side_x, _wall_height_m * 0.5, edge_z))
	var long_wall_size := Vector3(boundary_thickness, _wall_height_m, _depth_m)
	for side_name: String in ["West", "East"]:
		var side_x := -boundary_x if side_name == "West" else boundary_x
		_add_visual_box(boundaries, "%sFoundation" % side_name, long_wall_size,
			Vector3(side_x, _wall_height_m * 0.5, 0.0), stone)
		_add_static_box(boundaries, "%sCollision" % side_name, long_wall_size,
			Vector3(side_x, _wall_height_m * 0.5, 0.0))

	var wall_transforms: Array[Transform3D] = []
	var cracked_transforms: Array[Transform3D] = []
	for x: float in [-10.0, -6.0, -3.0, 3.0, 6.0, 10.0]:
		var path := cracked_transforms if x in [-6.0, 6.0] else wall_transforms
		path.append(Transform3D(Basis(Vector3.UP, PI), Vector3(x, 0.0, -11.0)))
	for x: float in [-10.0, -6.0, 6.0, 10.0]:
		wall_transforms.append(Transform3D(Basis.IDENTITY, Vector3(x, 0.0, 11.0)))
	for z: float in [-9.0, -5.0, -1.0, 3.0, 7.0]:
		wall_transforms.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-12.0, 0.0, z)))
		wall_transforms.append(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(12.0, 0.0, z)))
	_add_multimesh(boundaries, _asset_path(&"wall"), wall_transforms, "KayKitWalls")
	_add_multimesh(boundaries, _asset_path(&"wall_cracked"), cracked_transforms, "CrackedNorthWalls")
	var broken_transforms: Array[Transform3D] = [
		Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-12.0, 0.0, -7.0)),
		Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(12.0, 0.0, 5.0)),
	]
	_add_multimesh(boundaries, _asset_path(&"wall_broken"), broken_transforms, "BrokenWalls")
	_add_asset_instance(boundaries, _asset_path(&"wall_gated"),
		Transform3D(Basis(Vector3.UP, PI), Vector3(0.0, 0.0, -11.08)), "NorthExitGate")
	var buttresses: Array[Transform3D] = []
	for at: Vector3 in [
		Vector3(-12.0, 0.0, -11.0), Vector3(12.0, 0.0, -11.0),
		Vector3(-12.0, 0.0, 11.0), Vector3(12.0, 0.0, 11.0),
		Vector3(-2.35, 0.0, 11.0), Vector3(2.35, 0.0, 11.0),
	]:
		buttresses.append(Transform3D(Basis.IDENTITY, at))
	_add_multimesh(boundaries, _asset_path(&"wall_pillar"), buttresses, "WallButtresses")


func _build_entry() -> void:
	var entrance := _arena_contract.get("entrance", {}) as Dictionary
	var fog_center := _vector_from_array(entrance.get("fog_center_m", []) as Array)
	var fog_size_data := entrance.get("fog_size_m", []) as Array
	var collision_center := _vector_from_array(
		entrance.get("collision_center_m", []) as Array)
	var collision_size := _vector_from_array(entrance.get("collision_size_m", []) as Array)
	var approach_center := _vector_from_array(
		entrance.get("approach_center_m", []) as Array)
	var approach_size := _vector_from_array(entrance.get("approach_size_m", []) as Array)
	var entry := Node3D.new()
	entry.name = "FogThreshold"
	add_child(entry)
	var lintel_material := _material(Color("#292d31"), 0.98)
	_add_visual_box(entry, "StoneLintel", Vector3(5.0, 0.8, 1.1),
		Vector3(0.0, 3.6, 11.5), lintel_material)
	_gate_fog = MeshInstance3D.new()
	_gate_fog.name = "Fog"
	var fog_quad := QuadMesh.new()
	fog_quad.size = Vector2(float(fog_size_data[0]), float(fog_size_data[1]))
	_gate_fog.mesh = fog_quad
	_gate_fog.position = fog_center
	_gate_fog.material_override = _fog_material()
	_gate_fog.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	entry.add_child(_gate_fog)
	var gate_body := StaticBody3D.new()
	gate_body.name = "ClosedGate"
	entry.add_child(gate_body)
	_gate_collision = CollisionShape3D.new()
	var gate_shape := BoxShape3D.new()
	gate_shape.size = collision_size
	_gate_collision.shape = gate_shape
	_gate_collision.position = collision_center
	gate_body.add_child(_gate_collision)
	_gate_status = Label3D.new()
	_gate_status.name = "ArenaStatus"
	_gate_status.position = Vector3(fog_center.x,
		float(entrance.get("status_height_m", fog_center.y)), fog_center.z + 0.1)
	_gate_status.font_size = 42
	_gate_status.modulate = Color("e8e3d4")
	_gate_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_gate_status.no_depth_test = true
	_gate_status.visible = false
	entry.add_child(_gate_status)
	var threshold := Area3D.new()
	threshold.name = "ReadyThreshold"
	threshold.position = approach_center
	threshold.collision_layer = 0
	threshold.collision_mask = 1
	entry.add_child(threshold)
	var threshold_collision := CollisionShape3D.new()
	var threshold_shape := BoxShape3D.new()
	threshold_shape.size = approach_size
	threshold_collision.shape = threshold_shape
	threshold.add_child(threshold_collision)
	threshold.body_entered.connect(_on_threshold_body_entered)
	threshold.body_exited.connect(_on_threshold_body_exited)


func _build_covers() -> void:
	var covers_root := Node3D.new()
	covers_root.name = "TemporaryRefuges"
	add_child(covers_root)
	for side: int in [-1, 1]:
		var cover_id := &"left" if side < 0 else &"right"
		var cover := Node3D.new()
		cover.name = String(cover_id).capitalize()
		cover.position = Vector3(float(side) * 6.0, 0.0, -0.35)
		covers_root.add_child(cover)
		var intact := Node3D.new()
		intact.name = "Intact"
		cover.add_child(intact)
		_add_asset_instance(intact, _asset_path(&"pillar_decorated"),
			Transform3D(Basis.IDENTITY.scaled(Vector3(1.15, 1.35, 1.15)), Vector3.ZERO),
			"KayKitPillar")
		var rubble := Node3D.new()
		rubble.name = "Rubble"
		rubble.visible = false
		cover.add_child(rubble)
		_add_asset_instance(rubble, _asset_path(&"rubble_large"),
			Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.58), Vector3.ZERO),
			"KayKitRubble")
		var body := StaticBody3D.new()
		body.name = "Collision"
		cover.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 1.28
		shape.height = 4.9
		collision.shape = shape
		collision.position.y = 2.45
		body.add_child(collision)
		_covers[cover_id] = cover
		_cover_collisions[cover_id] = collision


func _build_dressing() -> void:
	var dressing := Node3D.new()
	dressing.name = "SiegeScars"
	add_child(dressing)
	var banners: Array[Transform3D] = []
	for x: float in [-7.0, 7.0]:
		banners.append(Transform3D(Basis(Vector3.UP, PI), Vector3(x, 0.55, -10.45)))
	_add_multimesh(dressing, _asset_path(&"banner"), banners, "GateBanners")
	var torches: Array[Transform3D] = []
	for at: Vector3 in [
		Vector3(-9.0, 2.35, -10.45), Vector3(9.0, 2.35, -10.45),
		Vector3(-11.45, 2.35, 5.0), Vector3(11.45, 2.35, 5.0),
		Vector3(-2.2, 2.35, 10.45), Vector3(2.2, 2.35, 10.45),
	]:
		var yaw := 0.0
		if absf(at.x) > 10.0:
			yaw = -PI * 0.5 if at.x < 0.0 else PI * 0.5
		elif at.z < 0.0:
			yaw = PI
		torches.append(Transform3D(Basis(Vector3.UP, yaw), at))
	_add_multimesh(dressing, _asset_path(&"torch"), torches, "WallTorches")
	var rubble: Array[Transform3D] = [
		Transform3D(Basis(Vector3.UP, 0.25), Vector3(-10.7, 0.02, -8.5)),
		Transform3D(Basis(Vector3.UP, -0.55), Vector3(10.6, 0.02, -7.3)),
		Transform3D(Basis(Vector3.UP, 1.15), Vector3(-10.8, 0.02, 8.2)),
		Transform3D(Basis(Vector3.UP, -0.9), Vector3(10.8, 0.02, 8.5)),
	]
	_add_multimesh(dressing, _asset_path(&"rubble_half"), rubble, "EdgeRubble")
	var arms: Array[Transform3D] = [
		Transform3D(Basis(Vector3.UP, -0.35), Vector3(-9.5, 0.08, -9.6)),
		Transform3D(Basis(Vector3.UP, 0.65), Vector3(9.2, 0.08, -9.8)),
	]
	_add_multimesh(dressing, _asset_path(&"broken_arms"), arms, "BrokenArms")
	_add_guiding_lights(dressing)


func _build_markers() -> void:
	var markers := Node3D.new()
	markers.name = "Markers"
	add_child(markers)
	for marker_id: StringName in _marker_positions:
		var marker := Marker3D.new()
		marker.name = String(marker_id)
		marker.position = _marker_positions[marker_id]
		markers.add_child(marker)


func _build_preview_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "PreviewEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#0c1116")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#74818c")
	environment.ambient_light_energy = 0.48
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_enabled = true
	environment.fog_light_color = Color("#46515a")
	environment.fog_light_energy = 0.38
	environment.fog_density = 0.012
	environment.fog_height = -1.0
	environment.fog_height_density = 0.12
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Moonlight"
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_color = Color("#c5d2db")
	sun.light_energy = 0.72
	sun.shadow_enabled = false
	add_child(sun)
	_preview_camera = Camera3D.new()
	_preview_camera.name = "PreviewCamera"
	_preview_camera.position = Vector3(0.0, 5.2, 9.0)
	_preview_camera.fov = 58.0
	_preview_camera.far = 60.0
	_preview_camera.look_at_from_position(_preview_camera.position, Vector3(0.0, 1.0, -2.0))
	add_child(_preview_camera)
	_preview_camera.current = true


func _build_preview_audio() -> void:
	var ambience := AudioStreamPlayer.new()
	ambience.name = "SynthesisedStoneWind"
	ambience.stream = _synthesise_wind()
	ambience.volume_db = -27.0
	add_child(ambience)
	ambience.play()


func _add_guiding_lights(parent: Node3D) -> void:
	for at: Vector3 in [Vector3(-6.0, 3.0, -9.7), Vector3(6.0, 3.0, -9.7),
			Vector3(0.0, 3.0, 10.0)]:
		var light := OmniLight3D.new()
		light.name = "AmberGuide"
		light.position = at
		light.light_color = Color("#d98b49")
		light.light_energy = 1.35
		light.omni_range = 7.0
		light.shadow_enabled = false
		parent.add_child(light)


func _add_multimesh(parent: Node3D, path: String, transforms: Array[Transform3D],
		label: String) -> void:
	if transforms.is_empty():
		return
	var mesh := _mesh_for(path)
	if mesh == null:
		push_error("[arena] malha em falta: %s" % path)
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _add_box_multimesh(parent: Node3D, size: Vector3, transforms: Array[Transform3D],
		material: Material, label: String) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _mesh_for(path: String) -> Mesh:
	if _mesh_cache.has(path):
		return _mesh_cache[path] as Mesh
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var temporary := packed.instantiate()
	var mesh_instance := _first_mesh_instance(temporary)
	var mesh := mesh_instance.mesh if mesh_instance != null else null
	temporary.free()
	_mesh_cache[path] = mesh
	return mesh


func _first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child: Node in node.get_children():
		var found := _first_mesh_instance(child)
		if found != null:
			return found
	return null


func _add_asset_instance(parent: Node3D, path: String, transform: Transform3D,
		label: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("[arena] cena em falta: %s" % path)
		return null
	var instance := packed.instantiate() as Node3D
	instance.name = label
	instance.transform = transform
	_set_shadow_recursive(instance, false)
	parent.add_child(instance)
	return instance


func _set_shadow_recursive(node: Node, enabled: bool) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON \
			if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_set_shadow_recursive(child, enabled)


func _add_static_box(parent: Node3D, label: String, size: Vector3, at: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = at
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _add_visual_box(parent: Node3D, label: String, size: Vector3, at: Vector3,
		material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func _fog_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;

void fragment() {
	float edge = smoothstep(0.0, 0.13, UV.x) * smoothstep(0.0, 0.13, 1.0 - UV.x);
	ALBEDO = vec3(0.66, 0.75, 0.77);
	EMISSION = vec3(0.16, 0.20, 0.21);
	ALPHA = (0.78 + UV.y * 0.06) * edge;
}

void vertex() {
	VERTEX.x += sin(UV.y * 6.0 + TIME * 0.45) * 0.03;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _synthesise_wind() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = 44100
	var data := PackedByteArray()
	data.resize(stream.loop_end * 2)
	for sample_index: int in stream.loop_end:
		var t := float(sample_index) / float(stream.mix_rate)
		var slow := sin(TAU * 0.19 * t) * 0.45 + sin(TAU * 0.31 * t + 1.2) * 0.25
		var grain := sin(TAU * 43.0 * t + sin(TAU * 0.7 * t) * 2.0) * 0.08
		data.encode_s16(sample_index * 2, int(clampf(slow + grain, -1.0, 1.0) * 2800.0))
	stream.data = data
	return stream


func _make_disc(radius: float, colour: Color, alpha: float, text: String) -> Node3D:
	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = float(_config.get("marker_height_m"))
	mesh.radial_segments = int(_config.get("marker_radial_segments"))
	mesh_instance.mesh = mesh
	mesh_instance.position.y = float(_config.get("marker_y_offset_m"))
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.material_override = _marker_material(colour, alpha)
	root.add_child(mesh_instance)
	root.add_child(_make_label(text, colour))
	return root


func _make_rectangle(size: Vector2, colour: Color, alpha: float, text: String) -> Node3D:
	var root := Node3D.new()
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, float(_config.get("marker_height_m")), size.y)
	mesh_instance.mesh = mesh
	mesh_instance.position.y = float(_config.get("marker_y_offset_m"))
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.material_override = _marker_material(colour, alpha)
	root.add_child(mesh_instance)
	root.add_child(_make_label(text, colour))
	return root


func _make_label(text: String, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = int(_config.get("label_font_size"))
	label.modulate = colour
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = float(_config.get("label_height_m"))
	return label


func _marker_material(colour: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	colour.a = alpha
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = Color(colour, 1.0)
	material.emission_energy_multiplier = float(_config.get("emission_energy"))
	return material


func _set_sequence_visuals_visible(visible_now: bool) -> void:
	for visual: Node3D in _sequence_visuals:
		if is_instance_valid(visual):
			visual.visible = visible_now


func _alive_players() -> Array[Node3D]:
	var alive: Array[Node3D] = []
	for player: Node3D in _players:
		if _is_alive(player):
			alive.append(player)
	return alive


func _is_alive(player: Node3D) -> bool:
	return is_instance_valid(player) and player.has_method("is_alive") and bool(
		player.call("is_alive"))


func _active_or_named_sequence(id: String) -> Dictionary:
	if String(_active_sequence.get("id", "")) == id:
		return _active_sequence
	return ((_config.get("coop_sequences", {}) as Dictionary).get(id, {}) as Dictionary)


func _vector_from_array(value: Array) -> Vector3:
	if value.size() != 3:
		return Vector3.ZERO
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func _first_label(root: Node3D) -> Label3D:
	for child: Node in root.get_children():
		var label := child as Label3D
		if label != null:
			return label
	return null


func _count_visual_descendants(root: Node) -> Vector2i:
	var count := Vector2i.ZERO
	if not is_instance_valid(root):
		return count
	for child: Node in root.get_children():
		if child is MeshInstance3D:
			count.x += 1
		elif child is Label3D:
			count.y += 1
		count += _count_visual_descendants(child)
	return count


func _check(condition: bool, message: String, failures: PackedStringArray) -> void:
	if condition:
		print("  ok    arena: ", message)
	else:
		failures.append(message)
		printerr("  FALHA arena: ", message)


func _on_threshold_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_approach_players[body.get_instance_id()] = true
		_try_open_gate()
		threshold_entered.emit(body)


func _on_threshold_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_approach_players.erase(body.get_instance_id())
		if to_local(body.global_position).z < _gate_local_z():
			_committed_players[body.get_instance_id()] = true
		if _committed_players.size() >= _expected_player_count:
			_commit_party()
		else:
			_try_open_gate()
		threshold_exited.emit(body)


func _run_command_line_audit() -> void:
	var failures := audit_layout()
	var events := [false, false]
	threshold_entered.connect(func(_player: Node3D) -> void: events[0] = true,
		CONNECT_ONE_SHOT)
	threshold_exited.connect(func(_player: Node3D) -> void: events[1] = true,
		CONNECT_ONE_SHOT)
	var probe := CharacterBody3D.new()
	probe.name = "ThresholdAuditPlayer"
	probe.add_to_group("player")
	probe.collision_layer = 1
	probe.collision_mask = 0
	var probe_collision := CollisionShape3D.new()
	var probe_shape := CapsuleShape3D.new()
	probe_shape.radius = 0.35
	probe_shape.height = 1.8
	probe_collision.shape = probe_shape
	probe.add_child(probe_collision)
	add_child(probe)
	var threshold := get_node("FogThreshold/ReadyThreshold") as Area3D
	probe.position = threshold.position
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(bool(events[0]), "patamar detecta um jogador que entra", failures)
	probe.position = Vector3(threshold.position.x, threshold.position.y, _gate_local_z() - 1.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(bool(events[1]), "patamar detecta um jogador que sai", failures)
	probe.queue_free()
	set_gate_closed(false)
	await get_tree().physics_frame
	_check(not _gate_fog.visible and _gate_collision.disabled,
		"abrir retira nevoeiro e colisao juntos", failures)
	set_gate_closed(true)
	await get_tree().physics_frame
	_check(_gate_fog.visible and not _gate_collision.disabled,
		"fechar repoe nevoeiro e colisao juntos", failures)
	_expected_player_count = 2
	_approach_players = {101: true, 202: true}
	_committed_players.clear()
	_try_open_gate()
	_check(not _gate_closed, "dupla reunida abre o nevoeiro", failures)
	_approach_players.erase(101)
	_committed_players[101] = true
	_try_open_gate()
	_check(not _gate_closed, "primeiro a atravessar nao fecha sobre o parceiro", failures)
	_approach_players.erase(202)
	_committed_players[202] = true
	_commit_party()
	_check(_gate_closed, "ultimo a atravessar fecha o nevoeiro atras da dupla", failures)
	_expected_player_count = 1
	_approach_players.clear()
	_committed_players.clear()
	set_cover_broken(&"left", true)
	await get_tree().physics_frame
	var left_cover := _covers[&"left"] as Node3D
	var right_cover := _covers[&"right"] as Node3D
	_check(not left_cover.get_node("Intact").visible
		and left_cover.get_node("Rubble").visible
		and (_cover_collisions[&"left"] as CollisionShape3D).disabled
		and right_cover.get_node("Intact").visible,
		"um refugio parte sem alterar o outro", failures)
	set_cover_broken(&"left", false)
	await get_tree().physics_frame
	_check(left_cover.get_node("Intact").visible
		and not left_cover.get_node("Rubble").visible
		and not (_cover_collisions[&"left"] as CollisionShape3D).disabled,
		"refugio restaura os dois estados pre-feitos", failures)
	print("=== ARENA: %d passaram, %d falharam ===" % [
		_marker_positions.size() + 18 - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)


func _run_photo_tour() -> void:
	if _preview_camera == null:
		printerr("[arena-photo] a cena precisa de ser executada directamente")
		get_tree().quit(1)
		return
	var shots: Array[Array] = [
		["01-entrada-nevoeiro", Vector3(0.0, 2.0, 16.5), Vector3(0.0, 1.4, 4.0)],
		["02-arena-geral", Vector3(0.0, 8.2, 15.5), Vector3(0.0, 1.0, -1.5)],
		["03-leitura-chao", Vector3(0.0, 5.0, 10.0), Vector3(0.0, 0.0, 1.0)],
		["04-separar", Vector3(0.0, 3.0, 8.5), Vector3(0.0, 1.0, -0.3)],
		["05-refugio-esquerdo", Vector3(-10.0, 2.2, 6.0), Vector3(-5.0, 1.2, -1.0)],
		["06-limite-norte", Vector3(8.5, 2.0, -5.0), Vector3(0.0, 1.2, -10.5)],
	]
	var output_dir := "user://arena-vorgar-captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	for shot: Array in shots:
		_preview_camera.look_at_from_position(shot[1] as Vector3, shot[2] as Vector3)
		for frame: int in 18:
			await get_tree().process_frame
		var image := get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [output_dir, shot[0]]
		var error := image.save_png(path)
		if error != OK:
			printerr("[arena-photo] falhou: %s (%s)" % [path, error])
		else:
			print("[arena-photo] ", path)
	print("[arena-photo] done=%d" % shots.size())
	get_tree().quit(0)
