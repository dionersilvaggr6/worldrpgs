class_name RegraDeOuroGuard
extends RefCounted
## Guarda estática da Regra de Ouro sobre o código de produção.
##
## Não tenta proibir números estruturais (índices, canais, geometria de arte).
## Proíbe as duas regressões desta revisão: completar silenciosamente campos de
## combate com um literal e voltar a declarar catálogos de conteúdo em GDScript.

const RUNTIME_ROOT := "res://src"

const COMBAT_FALLBACK_PATTERN := \
	"\\.get\\(\\s*\"(?:startup|active|recovery|stamina|stamina_cost|mv|range|" \
	+ "arc_degrees|health|max_health|defense|posture|max_posture|collision_radius_m|" \
	+ "body_radius|charge_max_frames|charge_max_mv|hyper_armor_start_frame|" \
	+ "damage_interval_frames|radius|duration_frames|iframe_start_frame|" \
	+ "iframe_end_frame|riposte_duration|guard_break_duration|heal_fraction)\"" \
	+ "\\s*,\\s*(?:[1-9]\\d*(?:\\.\\d+)?|0\\.\\d*[1-9]\\d*)"
const COMBAT_INITIALIZER_PATTERN := \
	"\\b(?:health|max_health|defense|posture|max_posture|posture_mult|body_radius|" \
	+ "_atk_startup|_atk_active|_atk_recovery|_atk_mv|_buffer_life|" \
	+ "_buffer_life_parry)\\s*(?::[^=\\n]+)?\\s*:?=\\s*" \
	+ "(?:[1-9]\\d*(?:\\.\\d+)?|0\\.\\d*[1-9]\\d*)"
const FIXED_COMBAT_ANGLE_PATTERN := \
	"deg_to_rad\\(\\s*(?:[1-9]\\d*(?:\\.\\d+)?|0\\.\\d*[1-9]\\d*)"
const FIXED_COMBAT_DISTANCE_PATTERN := \
	"\\.length\\(\\)\\s*<=\\s*(?:[1-9]\\d*(?:\\.\\d+)?|0\\.\\d*[1-9]\\d*)"
const CONTENT_CATALOGUE_PATTERN := \
	"\\bconst\\s+(?:FAMILY_ANIMATIONS|SHAPE_POSES|FAMILY_ARM_BIAS|CLASS_ROLES|" \
	+ "OPENING_LINES|TIP_IDS|STARTING_WEAPON_IDS|OWNER_QUESTION_SLOTS|" \
	+ "REQUIRED_STRING_IDS|ACTIVE_ORIGIN_IDS)\\b"


static func contract_errors(root_path := RUNTIME_ROOT) -> Array[String]:
	var errors: Array[String] = []
	var paths: Array[String] = []
	_collect_gd_files(root_path, paths)
	paths.sort()
	for path: String in paths:
		if not _is_production_source(path):
			continue
		var source := FileAccess.get_file_as_string(path)
		if source.is_empty() and FileAccess.get_open_error() != OK:
			errors.append("não foi possível ler %s" % path)
			continue
		errors.append_array(violations_in_source(path, source))
	return errors


static func violations_in_source(path: String, source: String) -> Array[String]:
	var errors: Array[String] = []
	_append_matches(errors, path, source, COMBAT_FALLBACK_PATTERN,
		"fallback numérico de combate")
	_append_matches(errors, path, source, CONTENT_CATALOGUE_PATTERN,
		"catálogo de conteúdo escrito à mão")
	if source.contains("class_name Player") or source.contains("class_name Enemy"):
		_append_matches(errors, path, source, COMBAT_INITIALIZER_PATTERN,
			"baseline numérico de combate")
		_append_matches(errors, path, source, FIXED_COMBAT_ANGLE_PATTERN,
			"ângulo de combate literal")
		_append_matches(errors, path, source, FIXED_COMBAT_DISTANCE_PATTERN,
			"distância de combate literal")
	return errors


static func _append_matches(errors: Array[String], path: String, source: String,
		pattern: String, reason: String) -> void:
	var expression := RegEx.new()
	var compile_error := expression.compile(pattern)
	if compile_error != OK:
		errors.append("guarda inválida para %s: %s" % [reason, error_string(compile_error)])
		return
	for match_value: RegExMatch in expression.search_all(source):
		var line := source.left(match_value.get_start()).count("\n") + 1
		errors.append("%s:%d — %s: %s" % [
			path, line, reason, match_value.get_string().strip_edges()])


static func _collect_gd_files(path: String, result: Array[String]) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child_path := path.path_join(entry)
			if directory.current_is_dir():
				_collect_gd_files(child_path, result)
			elif entry.ends_with(".gd"):
				result.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


static func _is_production_source(path: String) -> bool:
	var filename := path.get_file()
	return not path.contains("/src/tests/") \
		and not path.contains("/src/tools/") \
		and not filename.contains("_test") \
		and not filename.contains("benchmark") \
		and not filename.contains("probe") \
		and not filename.contains("proof")
