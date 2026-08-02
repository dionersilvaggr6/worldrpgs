extends SceneTree
## Prova focal da direccao musical e de ambiente.
## Correr com: godot --headless --audio-driver Dummy --path game \
##   --script res://src/audio/music_self_test.gd

const Catalog = preload("res://src/audio/music_catalog.gd")
const AmbienceSynth = preload("res://src/audio/music_ambience_synth.gd")
const DirectorScript = preload("res://src/audio/music_director.gd")

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := Catalog.load_catalog()
	_test_catalogue(catalog)
	_test_archive_inventory(catalog)
	var streams := _test_ambience_synthesis()
	_test_director(catalog, streams)
	print("[musica] %d passaram, %d falharam" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_catalogue(catalog: Dictionary) -> void:
	var errors := Catalog.validate(catalog)
	_check(errors.is_empty(), "catalogo cumpre o contrato: %s" % "; ".join(errors))
	var mix := catalog.get("mix", {}) as Dictionary
	_check(int(mix.get("max_music_streams_during_crossfade", 0)) == 2,
		"crossfade musical reserva exactamente duas streams")
	_check(int(mix.get("sfx_voice_ceiling", 0)) == 24
		and int(mix.get("gameplay_info_reserved_voices", 0)) == 8,
		"catalogo conserva 24 vozes SFX e 8 informativas")
	var entries := catalog.get("entries", {}) as Dictionary
	var music_missing := 0
	for entry_value: Variant in entries.values():
		var item := entry_value as Dictionary
		if String(item.get("bus", "")) == "Music" and not bool(item.get("enabled", true)):
			music_missing += 1
	_check(music_missing == 9, "as seis pecas e tres stingers ficam honestamente por produzir")
	_check(Catalog.resolve_track(catalog, "EXPLORE", "brumal") == "mus_brumal_explore"
		and Catalog.resolve_track(catalog, "COMBAT", "brumal") == "mus_brumal_tension",
		"Brumal separa exploracao de tensao sem inferir distancia")
	_check(Catalog.resolve_track(catalog, "EXPLORE", "toca") == "mus_toca"
		and Catalog.resolve_ambience(catalog, "brumal") != Catalog.resolve_ambience(
			catalog, "toca"), "Toca tem musica prevista e cama propria")
	_check(String((entries.get("amb_rest_campfire", {}) as Dictionary).get(
		"emotional_role", "")) == "safety", "fogueira declara seguranca como papel")


func _test_archive_inventory(catalog: Dictionary) -> void:
	var archive := catalog.get("archive_inventory", {}) as Dictionary
	var archive_path := ProjectSettings.globalize_path("res://../art/audio")
	var actual_ogg := _count_ogg(archive_path)
	_check(actual_ogg == int(archive.get("ogg_total", -1)),
		"arquivo local contem exactamente %d OGG" % actual_ogg)
	var preview_path := ProjectSettings.globalize_path(
		"res://../art/audio/kenney-rpg-audio/Preview.ogg")
	var expected_hash := String(((archive.get("excluded", []) as Array)[0] as Dictionary).get(
		"sha256", ""))
	_check(FileAccess.get_sha256(preview_path) == expected_hash,
		"Preview.ogg e identificado por hash e continua excluido")
	_check(actual_ogg - (archive.get("excluded", []) as Array).size() == int(
		archive.get("usable_sfx_candidates", -1)),
		"182 ficheiros significam 181 SFX candidatos e zero musica")
	_check(int(archive.get("runtime_music_files", -1)) == 0
		and int(archive.get("runtime_ambience_loops_from_pack", -1)) == 0,
		"catalogo nao promove SFX curtos a musica ou loop de ambiente")


func _test_ambience_synthesis() -> Dictionary:
	var streams := {
		"amb_brumal_bed": AmbienceSynth.make_brumal(),
		"amb_toca_bed": AmbienceSynth.make_toca(),
		"amb_rest_campfire": AmbienceSynth.make_campfire(),
	}
	var total_bytes := 0
	var hashes: Dictionary = {}
	for entry_id: String in streams:
		var stream := streams[entry_id] as AudioStreamWAV
		_check(stream != null and stream.mix_rate == AmbienceSynth.RATE,
			"%s existe a %d Hz" % [entry_id, AmbienceSynth.RATE])
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo,
			"%s e mono 16-bit" % entry_id)
		_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD
			and stream.loop_end == stream.data.size() / 2,
			"%s declara loop integral" % entry_id)
		var peak := AmbienceSynth.peak(stream)
		_check(peak > 0.015 and peak < 0.98,
			"%s tem sinal sem clipping (pico %.3f)" % [entry_id, peak])
		var seam := AmbienceSynth.seam_delta(stream)
		_check(seam < 0.12, "%s tem costura curta (delta %.4f)" % [entry_id, seam])
		total_bytes += AmbienceSynth.decoded_bytes(stream)
		hashes[entry_id] = _sha256(stream.data)
	_check(hashes["amb_brumal_bed"] != hashes["amb_toca_bed"],
		"Brumal e Toca geram ondas diferentes, nao a mesma cama repitched")
	_check(hashes["amb_rest_campfire"] != hashes["amb_toca_bed"],
		"descanso tem fogo proprio em vez da ressonancia da Toca")
	_check(total_bytes < 2 * 1024 * 1024,
		"as tres camas descodificadas custam %.2f MiB" % (float(total_bytes) / 1048576.0))
	return streams


func _test_director(catalog: Dictionary, streams: Dictionary) -> void:
	var director := DirectorScript.new() as MusicDirector
	root.add_child(director)
	_check(director.catalogue_errors().is_empty(), "MusicDirector aceita o catalogo")
	var music_bus := AudioServer.get_bus_index("Music")
	var ambience_bus := AudioServer.get_bus_index("Ambience")
	_check(music_bus >= 0 and AudioServer.get_bus_send(music_bus) == "Musica",
		"Music usa o slider Musica existente")
	_check(ambience_bus >= 0 and AudioServer.get_bus_send(ambience_bus) == "Ambiente",
		"Ambience usa o slider Ambiente existente")
	_check(not director.enter_menu(""), "evento sem id autoritativo e recusado")
	_check(director.enter_menu("menu-ready"), "menu aceita evento autoritativo")
	_check(director.current_state == "MENU" and director.current_track_id == "mus_menu_rest"
		and director.active_music_stream_count() == 0,
		"menu conserva silencio honesto enquanto a faixa nao existe")
	_check(director.register_runtime_stream("mus_menu_rest",
		streams["amb_brumal_bed"] as AudioStream), "teste injecta stream sem mudar catalogo")
	_check(director.request_state("MENU", "", "creation-open"),
		"criacao reutiliza o estado de menu")
	director._process(2.0)
	_check(director.active_music_stream_count() == 1,
		"stream aprovada entraria pelo player Music")
	_check(director.enter_zone("brumal", "brumal-loaded"), "Brumal entra ao recuperar controlo")
	_check(director.current_ambience_id == "amb_brumal_bed"
		and director.current_track_id == "mus_brumal_explore",
		"Brumal escolhe ambiente e musica pelo estado")
	director._process(5.0)
	_check(director.active_ambience_stream_count() == 1,
		"Brumal estabiliza numa unica voz de ambiente")
	_check(director.set_combat_active(true, "aggro-confirmed"),
		"musica de tensao so recebe ALERT/AGGRO confirmado")
	_check(director.current_track_id == "mus_brumal_tension",
		"combate escolhe o stem de tensao sem denunciar emboscada")
	_check(director.enter_zone("toca", "toca-loaded"), "Toca aceita transicao de zona")
	_check(director.active_ambience_stream_count() == 2,
		"transicao audivel usa duas camas temporarias")
	director._process(4.0)
	_check(director.current_ambience_id == "amb_toca_bed"
		and director.active_ambience_stream_count() == 1,
		"Toca termina com identidade propria e liberta Brumal")
	_check(director.enter_rest("campfire-rest"), "interagir/descansar activa seguranca")
	_check(director.active_ambience_stream_count() == 2,
		"fogueira junta fogo proximo sem exceder tres vozes")
	director._process(3.0)
	_check(director.current_state == "REST", "estado seguro fica explicito")
	_check(director.leave_rest("campfire-rise"), "levantar regressa a exploracao")
	director._process(3.0)
	_check(director.active_ambience_stream_count() == 1,
		"fogo de seguranca sai depois de levantar")
	_check(director.begin_boss(1, "vorgar-active"), "intro autoritativa activa chefe")
	_check(director.current_track_id == "mus_vorgar_p1",
		"fase 1 nunca toca pela proximidade ao nevoeiro")
	director._process(2.0)
	_check(director.active_music_stream_count() == 0,
		"chefe fica em silencio em vez de fingir uma faixa inexistente")
	_check(director.register_runtime_stream("mus_vorgar_p1",
		streams["amb_brumal_bed"] as AudioStream)
		and director.register_runtime_stream("mus_vorgar_p2",
		streams["amb_toca_bed"] as AudioStream),
		"duas faixas futuras podem ser ligadas sem mudar estados")
	_check(director.request_state("BOSS_P1", "toca", "vorgar-p1-stream"),
		"fase 1 passa a tocar quando recebe stream aprovada")
	director._process(2.0)
	_check(director.begin_boss(2, "vorgar-roar"), "grito autoritativo activa fase 2")
	_check(director.active_music_stream_count() == 2,
		"mudanca de fase respeita duas streams de crossfade")
	director._process(3.0)
	_check(director.active_music_stream_count() == 1,
		"crossfade liberta a fase anterior")
	_check(not director.begin_boss(2, "vorgar-roar"), "event_id repetido nao reinicia faixa")
	var snapshot := director.network_snapshot()
	var peer := DirectorScript.new() as MusicDirector
	root.add_child(peer)
	_check(peer.apply_authoritative_snapshot(snapshot),
		"peer atrasado aceita estado, zona, evento e tempo autoritativos")
	_check(peer.current_state == director.current_state and peer.current_zone == director.current_zone,
		"dois peers convergem no mesmo estado logico")
	_check(float((catalog.get("transitions", {}) as Dictionary).get(
		"network_sync_target_ms", 999.0)) <= 50.0, "contrato de rede fixa erro alvo <= 50 ms")
	_test_interrupted_transitions(streams)
	_test_director_cost(director)
	peer.queue_free()
	director.queue_free()


func _test_interrupted_transitions(streams: Dictionary) -> void:
	var burst := DirectorScript.new() as MusicDirector
	root.add_child(burst)
	for entry_id: String in ["mus_menu_rest", "mus_vorgar_p1", "mus_vorgar_p2"]:
		var stream_id := "amb_toca_bed" if entry_id == "mus_vorgar_p2" \
			else "amb_brumal_bed"
		_check(burst.register_runtime_stream(entry_id, streams[stream_id] as AudioStream),
			"rajada prepara %s" % entry_id)
	_check(burst.enter_menu("burst-menu"), "rajada entra no menu")
	burst._process(2.0)
	_check(burst.enter_zone("brumal", "burst-zone")
		and burst.set_combat_active(true, "burst-aggro")
		and burst.begin_boss(1, "burst-boss")
		and burst.begin_boss(2, "burst-phase")
		and burst.confirm_player_death("burst-death"),
		"cinco eventos rapidos sao aceites pela ordem autoritativa")
	_check(burst.active_music_stream_count() <= 2,
		"interromper crossfades nunca ultrapassa duas streams musicais")
	burst._process(5.0)
	_check(burst.current_state == "DEATH" and burst.active_music_stream_count() == 0,
		"morte interrompe a rajada e termina em silencio sem voz orfa")
	burst.queue_free()


func _test_director_cost(director: MusicDirector) -> void:
	var samples: Array[float] = []
	for _index in 6000:
		var started := Time.get_ticks_usec()
		director._process(1.0 / 60.0)
		samples.append(float(Time.get_ticks_usec() - started) / 1000.0)
	samples.sort()
	var p99 := samples[mini(int(samples.size() * 0.99), samples.size() - 1)]
	_check(p99 <= 0.30, "director custa %.3f ms CPU p99 (tecto 0.30 ms)" % p99)
	_check(director.synthesized_resident_bytes() < 2 * 1024 * 1024,
		"cache sintetica residente custa %.2f MiB" % (
			float(director.synthesized_resident_bytes()) / 1048576.0))
	print("[musica] CPU p99 %.3f ms; sintese %s; PCM %.2f MiB" % [p99,
		str(director.synthesis_milliseconds),
		float(director.synthesized_resident_bytes()) / 1048576.0])


func _count_ogg(directory_path: String) -> int:
	var count := 0
	for file_name: String in DirAccess.get_files_at(directory_path):
		if file_name.to_lower().ends_with(".ogg"):
			count += 1
	for child_name: String in DirAccess.get_directories_at(directory_path):
		count += _count_ogg(directory_path.path_join(child_name))
	return count


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("[musica] FALHOU: %s" % message)
