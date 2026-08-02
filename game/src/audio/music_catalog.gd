class_name MusicCatalog
extends RefCounted
## Le e valida o contrato de musica/ambiente sem depender de um autoload.
## Os numeros de mistura e transicao vivem no JSON; o director apenas executa.

const CATALOG_PATH := "res://data/audio_catalog.json"
const REQUIRED_ENTRY_FIELDS := [
	"id", "source_file", "license_id", "hash", "runtime_file", "bus",
	"spatial", "max_distance_m", "gain_db", "pitch_range", "loop", "stream",
	"variations", "max_polyphony", "priority", "informative",
	"gameplay_cue_type", "visual_cue_id", "where", "state", "_estado",
]


static func load_catalog(path := CATALOG_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


static func validate(catalog: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if catalog.is_empty():
		return ["audio_catalog.json esta vazio ou nao e JSON valido"]
	_validate_mix(catalog, errors)
	_validate_entries(catalog, errors)
	_validate_states_and_zones(catalog, errors)
	_validate_archive(catalog, errors)
	return errors


static func resolve_track(catalog: Dictionary, state_id: String,
		zone_id: String) -> String:
	var states := catalog.get("states", {}) as Dictionary
	var state := states.get(state_id, {}) as Dictionary
	var role := String(state.get("music_role", "none"))
	var roles := catalog.get("roles", {}) as Dictionary
	var zones := catalog.get("zones", {}) as Dictionary
	var zone := zones.get(zone_id, {}) as Dictionary
	match role:
		"none":
			return ""
		"zone_explore":
			return String(zone.get("explore_music", ""))
		"zone_combat":
			return String(zone.get("combat_music", ""))
		_:
			return String(roles.get(role, ""))


static func resolve_ambience(catalog: Dictionary, zone_id: String) -> String:
	var zone := (catalog.get("zones", {}) as Dictionary).get(zone_id, {}) as Dictionary
	return String(zone.get("ambience_bed", ""))


static func entry(catalog: Dictionary, entry_id: String) -> Dictionary:
	return (catalog.get("entries", {}) as Dictionary).get(entry_id, {}) as Dictionary


static func transition_seconds(catalog: Dictionary, from_state: String,
		to_state: String, zone_changed := false, late_join := false) -> float:
	var transitions := catalog.get("transitions", {}) as Dictionary
	if late_join:
		return float(transitions.get("late_join_fade_s", 0.0))
	if zone_changed:
		return float(transitions.get("zone_crossfade_s", 0.0))
	if from_state == "COMBAT" and to_state == "EXPLORE":
		return float(transitions.get("combat_out_s", 0.0))
	var state := (catalog.get("states", {}) as Dictionary).get(to_state, {}) as Dictionary
	return float(transitions.get(String(state.get("transition", "")), 0.0))


static func ambience_gain_db(catalog: Dictionary, zone_id: String,
		state_id: String) -> float:
	var zones := catalog.get("zones", {}) as Dictionary
	var zone := zones.get(zone_id, {}) as Dictionary
	var levels := zone.get("ambient_state_db", {}) as Dictionary
	return float(levels.get(state_id, levels.get("EXPLORE", 0.0)))


static func floor_db(catalog: Dictionary) -> float:
	return float((catalog.get("transitions", {}) as Dictionary).get("floor_db", -60.0))


static func _validate_mix(catalog: Dictionary, errors: Array[String]) -> void:
	var mix := catalog.get("mix", {}) as Dictionary
	var buses := mix.get("internal_buses", {}) as Dictionary
	for bus_name: String in ["GameplayInfo", "Impact", "UI", "Music", "Ambience", "Voice"]:
		if not buses.has(bus_name):
			errors.append("mix.internal_buses nao declara %s" % bus_name)
	if String(buses.get("Music", "")) != "Musica":
		errors.append("Music tem de enviar para o slider Musica existente")
	if String(buses.get("Ambience", "")) != "Ambiente":
		errors.append("Ambience tem de enviar para o slider Ambiente existente")
	if int(mix.get("max_music_streams_during_crossfade", -1)) != 2:
		errors.append("o crossfade musical tem de respeitar o tecto de 2 streams")
	if int(mix.get("sfx_voice_ceiling", -1)) != 24:
		errors.append("o tecto SFX tem de ser 24 vozes")
	if int(mix.get("gameplay_info_reserved_voices", -1)) != 8:
		errors.append("GameplayInfo tem de conservar 8 vozes reservadas")


static func _validate_entries(catalog: Dictionary, errors: Array[String]) -> void:
	var entries := catalog.get("entries", {}) as Dictionary
	if entries.is_empty():
		errors.append("o catalogo nao tem entradas")
		return
	for key_value: Variant in entries:
		var key := String(key_value)
		var item := entries[key] as Dictionary
		for field: String in REQUIRED_ENTRY_FIELDS:
			if not item.has(field):
				errors.append("%s nao declara %s" % [key, field])
		if String(item.get("id", "")) != key:
			errors.append("%s tem id interno divergente" % key)
		var bus := String(item.get("bus", ""))
		if bus in ["Music", "Ambience"] and bool(item.get("informative", true)):
			errors.append("%s: atmosfera nunca pode ser informative" % key)
		if bool(item.get("informative", false)) and bus != "GameplayInfo":
			errors.append("%s: entrada informativa fora de GameplayInfo" % key)
		var pitch := item.get("pitch_range", []) as Array
		if pitch.size() != 2 or float(pitch[0]) <= 0.0 or float(pitch[1]) < float(pitch[0]):
			errors.append("%s tem pitch_range invalido" % key)
		var enabled := bool(item.get("enabled", false))
		if enabled and bool(item.get("loop", false)) and not bool(item.get("seam_tested", false)):
			errors.append("%s activa um loop sem teste de costura" % key)
		if enabled and bus == "Music" and not bool(item.get("stream", false)):
			errors.append("%s activa musica sem streaming" % key)
		if not enabled and item.get("runtime_file") != null:
			errors.append("%s esta desactivado mas promete ficheiro runtime" % key)
		for path_field: String in ["source_file", "runtime_file"]:
			var raw_path: Variant = item.get(path_field)
			if raw_path != null and _looks_absolute(String(raw_path)):
				errors.append("%s contem caminho absoluto em %s" % [key, path_field])
		var source_value: Variant = item.get("source_file")
		if source_value != null and "Preview.ogg" in String(source_value):
			errors.append("%s tenta usar a demonstracao Preview.ogg" % key)


static func _validate_states_and_zones(catalog: Dictionary,
		errors: Array[String]) -> void:
	var states := catalog.get("states", {}) as Dictionary
	var entries := catalog.get("entries", {}) as Dictionary
	for required_state: String in ["SILENCE", "MENU", "EXPLORE", "REST", "COMBAT",
			"BOSS_P1", "BOSS_P2", "VICTORY", "DEATH"]:
		if not states.has(required_state):
			errors.append("estado musical em falta: %s" % required_state)
	var roles := catalog.get("roles", {}) as Dictionary
	for role_value: Variant in roles:
		var role := String(role_value)
		var role_entry := String(roles[role])
		if not entries.has(role_entry):
			errors.append("papel %s aponta para entrada inexistente %s" % [role, role_entry])
	var zones := catalog.get("zones", {}) as Dictionary
	for zone_id: String in ["brumal", "toca"]:
		if not zones.has(zone_id):
			errors.append("zona sonora em falta: %s" % zone_id)
			continue
		var zone := zones[zone_id] as Dictionary
		for field: String in ["ambience_bed", "explore_music", "combat_music"]:
			var linked := String(zone.get(field, ""))
			if not entries.has(linked):
				errors.append("%s.%s aponta para %s inexistente" % [zone_id, field, linked])
	if resolve_ambience(catalog, "brumal") == resolve_ambience(catalog, "toca"):
		errors.append("Brumal e Toca nao podem partilhar a mesma cama de ambiente")


static func _validate_archive(catalog: Dictionary, errors: Array[String]) -> void:
	var archive := catalog.get("archive_inventory", {}) as Dictionary
	if int(archive.get("ogg_total", -1)) != 182:
		errors.append("inventario tem de reconhecer os 182 OGG")
	if int(archive.get("usable_sfx_candidates", -1)) != 181:
		errors.append("inventario tem de separar 181 candidatos do Preview")
	var family_total := 0
	for family_value: Variant in archive.get("families", []):
		family_total += int((family_value as Dictionary).get("count", 0))
	if family_total != 181:
		errors.append("familias do arquivo somam %d, esperado 181" % family_total)
	var preview_excluded := false
	for excluded_value: Variant in archive.get("excluded", []):
		if String((excluded_value as Dictionary).get("path", "")).ends_with("Preview.ogg"):
			preview_excluded = true
	if not preview_excluded:
		errors.append("Preview.ogg nao esta explicitamente excluido")


static func _looks_absolute(path: String) -> bool:
	var clean := path.trim_prefix("sintetizado:")
	return clean.begins_with("/") or clean.begins_with("\\") \
		or (clean.length() >= 2 and clean[1] == ":")
