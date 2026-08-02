class_name MusicDirector
extends Node
## Director unico de musica e camas de ambiente.
##
## Recebe eventos autoritativos do jogo; nunca infere combate por distancia.
## Nao cria sliders: toca nos buses internos Music/Ambience, que continuam sob
## Musica/Ambiente nas opcoes existentes.

const Catalog = preload("res://src/audio/music_catalog.gd")
const AmbienceSynth = preload("res://src/audio/music_ambience_synth.gd")

signal state_changed(previous_state: String, current_state: String, event_id: String)
signal zone_changed(previous_zone: String, current_zone: String, event_id: String)
signal transition_started(kind: String, from_id: String, to_id: String, seconds: float)
signal track_unavailable(entry_id: String, state_id: String)
signal catalogue_rejected(errors: Array[String])

var current_state := "SILENCE"
var current_zone := ""
var current_track_id := ""
var current_ambience_id := ""
var last_transition_event_id := ""
var last_error := ""
var synthesis_milliseconds: Dictionary = {}

var _catalog: Dictionary = {}
var _runtime_streams: Dictionary = {}
var _synth_streams: Dictionary = {}
var _seen_events: Dictionary = {}

var _music_players: Array[AudioStreamPlayer] = []
var _music_base_db: Array[float] = [0.0, 0.0]
var _music_fade_db: Array[float] = [0.0, 0.0]
var _music_slot_ids: Array[String] = ["", ""]
var _music_active_slot := -1
var _music_transition: Dictionary = {}

var _ambience_players: Array[AudioStreamPlayer] = []
var _ambience_base_db: Array[float] = [0.0, 0.0]
var _ambience_fade_db: Array[float] = [0.0, 0.0]
var _ambience_slot_ids: Array[String] = ["", ""]
var _ambience_active_slot := -1
var _ambience_transition: Dictionary = {}
var _ambience_state_db := 0.0
var _ambience_state_transition: Dictionary = {}

var _rest_player: AudioStreamPlayer
var _rest_base_db := 0.0
var _rest_fade_db := 0.0
var _rest_transition: Dictionary = {}
var _pause_db := 0.0


func _ready() -> void:
	_catalog = Catalog.load_catalog()
	var errors := Catalog.validate(_catalog)
	if not errors.is_empty():
		last_error = "; ".join(errors)
		catalogue_rejected.emit(errors)
		set_process(false)
		return
	_ensure_internal_buses()
	_build_players()
	set_process(false)


func catalogue() -> Dictionary:
	return _catalog.duplicate(true)


func catalogue_errors() -> Array[String]:
	return Catalog.validate(_catalog)


## Liga futuramente uma faixa aprovada sem alterar a maquina de estados.
## E tambem a costura usada pelo auto-teste para provar crossfades sem fingir
## que a cama sintetizada e musica de producao.
func register_runtime_stream(entry_id: String, stream: AudioStream) -> bool:
	var item := Catalog.entry(_catalog, entry_id)
	if item.is_empty() or String(item.get("bus", "")) != "Music" or stream == null:
		last_error = "stream musical recusado: %s" % entry_id
		return false
	_runtime_streams[entry_id] = stream
	return true


func preload_zone(zone_id: String) -> bool:
	var ambience_id := Catalog.resolve_ambience(_catalog, zone_id)
	if ambience_id == "":
		last_error = "zona sonora desconhecida: %s" % zone_id
		return false
	return _ambience_stream(ambience_id) != null


func enter_menu(event_id: String) -> bool:
	return request_state("MENU", "", event_id)


func enter_zone(zone_id: String, event_id: String,
		host_music_seconds := -1.0) -> bool:
	return request_state("EXPLORE", zone_id, event_id, host_music_seconds)


func set_combat_active(active: bool, event_id: String) -> bool:
	return request_state("COMBAT" if active else "EXPLORE", current_zone, event_id)


func enter_rest(event_id: String) -> bool:
	return request_state("REST", current_zone, event_id)


func leave_rest(event_id: String) -> bool:
	return request_state("EXPLORE", current_zone, event_id)


func begin_boss(phase: int, event_id: String,
		host_music_seconds := -1.0) -> bool:
	var state_id := "BOSS_P%d" % phase
	if not (_catalog.get("states", {}) as Dictionary).has(state_id):
		last_error = "fase musical de chefe invalida: %d" % phase
		return false
	return request_state(state_id, current_zone, event_id,
		host_music_seconds)


func confirm_player_death(event_id: String) -> bool:
	return request_state("DEATH", current_zone, event_id)


func confirm_boss_victory(event_id: String) -> bool:
	return request_state("VICTORY", current_zone, event_id)


## Este e o unico ponto que muda estado. O chamador passa a acao real:
## zona carregada, ALERT/AGGRO, descanso confirmado, intro/fase, morte/vitoria.
func request_state(state_id: String, zone_id: String, event_id: String,
		host_music_seconds := -1.0, late_join := false) -> bool:
	last_error = ""
	if _catalog.is_empty() or not (_catalog.get("states", {}) as Dictionary).has(state_id):
		last_error = "estado musical desconhecido: %s" % state_id
		return false
	if event_id == "":
		last_error = "transicao musical sem event_id autoritativo"
		return false
	if _seen_events.has(event_id):
		return false
	var previous_state := current_state
	var previous_zone := current_zone
	var requested_zone := zone_id
	if requested_zone == "" and state_id not in ["MENU", "SILENCE"]:
		requested_zone = current_zone
	if requested_zone != "" and not (_catalog.get("zones", {}) as Dictionary).has(
			requested_zone):
		last_error = "zona sonora desconhecida: %s" % requested_zone
		return false
	_remember_event(event_id)
	var did_change_zone := requested_zone != current_zone
	current_state = state_id
	current_zone = requested_zone
	last_transition_event_id = event_id
	var seconds := Catalog.transition_seconds(_catalog, previous_state, state_id,
		did_change_zone, late_join)
	if did_change_zone:
		_transition_ambience(Catalog.resolve_ambience(_catalog, current_zone), seconds)
		zone_changed.emit(previous_zone, current_zone, event_id)
	_transition_ambience_state(seconds)
	_transition_rest_layer(state_id == "REST", seconds)
	var next_track := Catalog.resolve_track(_catalog, state_id, current_zone)
	_transition_music(next_track, seconds, host_music_seconds)
	state_changed.emit(previous_state, current_state, event_id)
	return true


func set_pause_overlay_open(open: bool) -> void:
	_pause_db = float((_catalog.get("mix", {}) as Dictionary).get(
		"pause_attenuation_db", 0.0)) if open else 0.0
	_apply_player_volumes()


func network_snapshot() -> Dictionary:
	var playback_seconds := 0.0
	if _music_active_slot >= 0 and _music_players[_music_active_slot].playing:
		playback_seconds = _music_players[_music_active_slot].get_playback_position()
	return {
		"catalogue_version": int((_catalog.get("_meta", {}) as Dictionary).get("version", 0)),
		"music_state": current_state,
		"zone_id": current_zone,
		"track_id": current_track_id,
		"transition_event_id": last_transition_event_id,
		"music_seconds": playback_seconds,
	}


func apply_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var event_id := String(snapshot.get("transition_event_id", ""))
	return request_state(String(snapshot.get("music_state", "SILENCE")),
		String(snapshot.get("zone_id", "")), event_id,
		float(snapshot.get("music_seconds", 0.0)), true)


func active_music_stream_count() -> int:
	var count := 0
	for player in _music_players:
		if player.playing:
			count += 1
	return count


func active_ambience_stream_count() -> int:
	var count := 1 if is_instance_valid(_rest_player) and _rest_player.playing else 0
	for player in _ambience_players:
		if player.playing:
			count += 1
	return count


func synthesized_resident_bytes() -> int:
	var total := 0
	for stream_value: Variant in _synth_streams.values():
		total += AmbienceSynth.decoded_bytes(stream_value as AudioStreamWAV)
	return total


func _process(delta: float) -> void:
	_update_music_transition(delta)
	_update_ambience_transition(delta)
	_update_ambience_state(delta)
	_update_rest_transition(delta)
	_apply_player_volumes()
	if _music_transition.is_empty() and _ambience_transition.is_empty() \
			and _ambience_state_transition.is_empty() and _rest_transition.is_empty():
		set_process(false)


func _build_players() -> void:
	for index in 2:
		var music := AudioStreamPlayer.new()
		music.name = "MusicCrossfade%d" % index
		music.bus = "Music"
		add_child(music)
		_music_players.append(music)
		var ambience := AudioStreamPlayer.new()
		ambience.name = "AmbienceCrossfade%d" % index
		ambience.bus = "Ambience"
		add_child(ambience)
		_ambience_players.append(ambience)
	_rest_player = AudioStreamPlayer.new()
	_rest_player.name = "RestSafetyCampfire"
	_rest_player.bus = "Ambience"
	add_child(_rest_player)


func _transition_music(entry_id: String, seconds: float, host_seconds: float) -> void:
	if not _music_transition.is_empty():
		_music_active_slot = _collapse_crossfade(_music_players, _music_fade_db,
			_music_slot_ids)
		_music_transition.clear()
	if entry_id == current_track_id and _music_active_slot >= 0 \
			and _music_slot_ids[_music_active_slot] == entry_id:
		if host_seconds >= 0.0 and _music_players[_music_active_slot].playing:
			_music_players[_music_active_slot].seek(host_seconds)
		return
	var from_id := current_track_id
	var from_slot := _music_active_slot
	var stream := _music_stream(entry_id)
	var to_slot := -1
	if stream != null:
		to_slot = 0 if from_slot != 0 else 1
		var player := _music_players[to_slot]
		player.stop()
		player.stream = stream
		player.bus = "Music"
		_music_slot_ids[to_slot] = entry_id
		_music_base_db[to_slot] = float(Catalog.entry(_catalog, entry_id).get("gain_db", 0.0))
		_music_fade_db[to_slot] = Catalog.floor_db(_catalog)
		player.play(maxf(host_seconds, 0.0))
	else:
		_music_active_slot = -1
		if entry_id != "":
			track_unavailable.emit(entry_id, current_state)
	current_track_id = entry_id
	_music_transition = _crossfade(from_slot, to_slot, seconds, _music_fade_db)
	if to_slot >= 0:
		_music_active_slot = to_slot
	transition_started.emit("music", from_id, entry_id, seconds)
	set_process(true)


func _transition_ambience(entry_id: String, seconds: float) -> void:
	if not _ambience_transition.is_empty():
		_ambience_active_slot = _collapse_crossfade(_ambience_players,
			_ambience_fade_db, _ambience_slot_ids)
		_ambience_transition.clear()
	if entry_id == current_ambience_id and _ambience_active_slot >= 0 \
			and _ambience_slot_ids[_ambience_active_slot] == entry_id:
		return
	var from_id := current_ambience_id
	var from_slot := _ambience_active_slot
	var stream := _ambience_stream(entry_id)
	var to_slot := -1
	if stream != null:
		to_slot = 0 if from_slot != 0 else 1
		var player := _ambience_players[to_slot]
		player.stop()
		player.stream = stream
		player.bus = "Ambience"
		_ambience_slot_ids[to_slot] = entry_id
		_ambience_base_db[to_slot] = float(Catalog.entry(_catalog, entry_id).get(
			"gain_db", 0.0))
		_ambience_fade_db[to_slot] = Catalog.floor_db(_catalog)
		player.play()
	else:
		_ambience_active_slot = -1
	current_ambience_id = entry_id
	_ambience_transition = _crossfade(from_slot, to_slot, seconds,
		_ambience_fade_db)
	if to_slot >= 0:
		_ambience_active_slot = to_slot
	transition_started.emit("ambience", from_id, entry_id, seconds)
	set_process(true)


func _transition_ambience_state(seconds: float) -> void:
	var target := Catalog.ambience_gain_db(_catalog, current_zone, current_state)
	_ambience_state_transition = {
		"from": _ambience_state_db,
		"to": target,
		"elapsed": 0.0,
		"duration": seconds,
	}
	set_process(true)


func _transition_rest_layer(active: bool, seconds: float) -> void:
	var target := 0.0 if active else Catalog.floor_db(_catalog)
	if active and not _rest_player.playing:
		var entry_id := String((_catalog.get("roles", {}) as Dictionary).get(
			"rest_safety", ""))
		var stream := _ambience_stream(entry_id)
		if stream != null:
			_rest_player.stream = stream
			_rest_base_db = float(Catalog.entry(_catalog, entry_id).get("gain_db", 0.0))
			_rest_fade_db = Catalog.floor_db(_catalog)
			_rest_player.play()
	_rest_transition = {
		"from": _rest_fade_db,
		"to": target,
		"elapsed": 0.0,
		"duration": seconds,
		"stop": not active,
	}
	set_process(true)


func _crossfade(from_slot: int, to_slot: int, seconds: float,
		fades: Array[float]) -> Dictionary:
	return {
		"from_slot": from_slot,
		"to_slot": to_slot,
		"from_start_db": fades[from_slot] if from_slot >= 0 else 0.0,
		"to_start_db": fades[to_slot] if to_slot >= 0 else Catalog.floor_db(_catalog),
		"elapsed": 0.0,
		"duration": seconds,
		"floor": Catalog.floor_db(_catalog),
	}


func _update_music_transition(delta: float) -> void:
	if _music_transition.is_empty():
		return
	var finished := _update_crossfade(_music_transition, _music_fade_db, delta)
	if finished:
		var old_slot := int(_music_transition.get("from_slot", -1))
		var new_slot := int(_music_transition.get("to_slot", -1))
		if old_slot >= 0 and old_slot != new_slot:
			_music_players[old_slot].stop()
			_music_players[old_slot].stream = null
			_music_slot_ids[old_slot] = ""
		_music_transition.clear()


func _update_ambience_transition(delta: float) -> void:
	if _ambience_transition.is_empty():
		return
	var finished := _update_crossfade(_ambience_transition, _ambience_fade_db, delta)
	if finished:
		var old_slot := int(_ambience_transition.get("from_slot", -1))
		var new_slot := int(_ambience_transition.get("to_slot", -1))
		if old_slot >= 0 and old_slot != new_slot:
			_ambience_players[old_slot].stop()
			_ambience_players[old_slot].stream = null
			_ambience_slot_ids[old_slot] = ""
		_ambience_transition.clear()


func _update_crossfade(transition: Dictionary, fades: Array[float],
		delta: float) -> bool:
	var duration := float(transition.get("duration", 0.0))
	var elapsed := minf(float(transition.get("elapsed", 0.0)) + delta, duration)
	transition["elapsed"] = elapsed
	var amount := 1.0 if duration <= 0.0 else clampf(elapsed / duration, 0.0, 1.0)
	amount = amount * amount * (3.0 - 2.0 * amount)
	var floor := float(transition.get("floor", -60.0))
	var from_slot := int(transition.get("from_slot", -1))
	var to_slot := int(transition.get("to_slot", -1))
	if from_slot >= 0:
		fades[from_slot] = lerpf(float(transition.get("from_start_db", 0.0)),
			floor, amount)
	if to_slot >= 0:
		fades[to_slot] = lerpf(float(transition.get("to_start_db", floor)),
			0.0, amount)
	return duration <= 0.0 or elapsed >= duration


func _collapse_crossfade(players: Array[AudioStreamPlayer], fades: Array[float],
		slot_ids: Array[String]) -> int:
	var keep_slot := -1
	var best_db := -INF
	for slot in players.size():
		if players[slot].playing:
			var audible_db := players[slot].volume_db
			if audible_db > best_db:
				best_db = audible_db
				keep_slot = slot
	for slot in players.size():
		if slot != keep_slot and players[slot].playing:
			players[slot].stop()
			players[slot].stream = null
			slot_ids[slot] = ""
	if keep_slot >= 0:
		fades[keep_slot] = clampf(fades[keep_slot], Catalog.floor_db(_catalog), 0.0)
	return keep_slot


func _update_ambience_state(delta: float) -> void:
	if _ambience_state_transition.is_empty():
		return
	var duration := float(_ambience_state_transition.get("duration", 0.0))
	var elapsed := minf(float(_ambience_state_transition.get("elapsed", 0.0)) + delta,
		duration)
	_ambience_state_transition["elapsed"] = elapsed
	var amount := 1.0 if duration <= 0.0 else clampf(elapsed / duration, 0.0, 1.0)
	_ambience_state_db = lerpf(float(_ambience_state_transition.get("from", 0.0)),
		float(_ambience_state_transition.get("to", 0.0)), amount)
	if duration <= 0.0 or elapsed >= duration:
		_ambience_state_transition.clear()


func _update_rest_transition(delta: float) -> void:
	if _rest_transition.is_empty():
		return
	var duration := float(_rest_transition.get("duration", 0.0))
	var elapsed := minf(float(_rest_transition.get("elapsed", 0.0)) + delta, duration)
	_rest_transition["elapsed"] = elapsed
	var amount := 1.0 if duration <= 0.0 else clampf(elapsed / duration, 0.0, 1.0)
	_rest_fade_db = lerpf(float(_rest_transition.get("from", 0.0)),
		float(_rest_transition.get("to", 0.0)), amount)
	if duration <= 0.0 or elapsed >= duration:
		if bool(_rest_transition.get("stop", false)) and _rest_player.playing:
			_rest_player.stop()
			_rest_player.stream = null
		_rest_transition.clear()


func _apply_player_volumes() -> void:
	for index in _music_players.size():
		_music_players[index].volume_db = _music_base_db[index] \
			+ _music_fade_db[index] + _pause_db
	for index in _ambience_players.size():
		_ambience_players[index].volume_db = _ambience_base_db[index] \
			+ _ambience_fade_db[index] + _ambience_state_db + _pause_db
	if is_instance_valid(_rest_player):
		_rest_player.volume_db = _rest_base_db + _rest_fade_db + _pause_db


func _music_stream(entry_id: String) -> AudioStream:
	if entry_id == "":
		return null
	if _runtime_streams.has(entry_id):
		return _runtime_streams[entry_id] as AudioStream
	var item := Catalog.entry(_catalog, entry_id)
	var runtime_path: Variant = item.get("runtime_file")
	if runtime_path != null and ResourceLoader.exists(String(runtime_path)):
		var stream := load(String(runtime_path)) as AudioStream
		if stream != null:
			_runtime_streams[entry_id] = stream
		return stream
	return null


func _ambience_stream(entry_id: String) -> AudioStreamWAV:
	if entry_id == "":
		return null
	if _synth_streams.has(entry_id):
		return _synth_streams[entry_id] as AudioStreamWAV
	var started := Time.get_ticks_usec()
	var stream := AmbienceSynth.make(entry_id)
	if stream != null:
		_synth_streams[entry_id] = stream
		synthesis_milliseconds[entry_id] = float(Time.get_ticks_usec() - started) / 1000.0
	return stream


func _ensure_internal_buses() -> void:
	var buses := (_catalog.get("mix", {}) as Dictionary).get("internal_buses", {}) as Dictionary
	for bus_name: String in ["Music", "Ambience"]:
		var parent_name := String(buses.get(bus_name, "Master"))
		_ensure_bus(parent_name, "Master")
		_ensure_bus(bus_name, parent_name)


func _ensure_bus(bus_name: String, parent_name: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, parent_name)


func _remember_event(event_id: String) -> void:
	_seen_events[event_id] = true
	# Mantem deduplicacao limitada; snapshots nao devem fazer crescer a sessao.
	if _seen_events.size() > 256:
		_seen_events.erase(_seen_events.keys()[0])
