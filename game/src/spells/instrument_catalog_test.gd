extends SceneTree
## Contrato executavel dos instrumentos magicos.
## Correr com: godot --headless --path game --script res://src/spells/instrument_catalog_test.gd

const InstrumentCatalog = preload("res://src/spells/instrument_catalog.gd")
const BENCHMARK_CAST_PLANS := 10000

var _passed := 0
var _failed := 0


func _init() -> void:
	var equipment := _load_json("res://data/equipment.json")
	var attributes := _load_json("res://data/attributes.json")
	var errors := InstrumentCatalog.contract_errors(equipment, attributes)
	_check(errors.is_empty(),
		"cada origem tem instrumento e qualquer origem pode equipar qualquer um: %s" % [errors])
	var missing_origin := equipment.duplicate(true)
	var missing_rules: Dictionary = missing_origin.get("_magic_instrument_rules", {}) as Dictionary
	var missing_assignments: Dictionary = missing_rules.get(
		"starting_instrument_by_origin", {}) as Dictionary
	missing_assignments.erase("evil_mage")
	var missing_errors := InstrumentCatalog.contract_errors(missing_origin, attributes)
	_check(_contains_error(missing_errors, "origem sem instrumento: evil_mage"),
		"o contrato falha se uma das sete origens ficar sem instrumento")

	var numeric_clone := equipment.duplicate(true)
	var instruments: Dictionary = numeric_clone.get("magic_instruments", {}) as Dictionary
	var bell: Dictionary = (instruments.get("sino", {}) as Dictionary).duplicate(true)
	var relic: Dictionary = instruments.get("relicario", {}) as Dictionary
	bell["cast_option"] = (relic.get("cast_option", {}) as Dictionary).duplicate(true)
	var relic_speeds: Dictionary = relic.get("cast_speed_multiplier_by_form", {}) as Dictionary
	bell["spell_power"] = relic_speeds.size()
	bell["cast_speed_multiplier_by_form"] = relic_speeds.duplicate(true)
	instruments["sino"] = bell
	var numeric_errors := InstrumentCatalog.contract_errors(numeric_clone, attributes)
	_check(_contains_error(numeric_errors, "diferem apenas em numeros"),
		"Lei 2 rejeita instrumentos cuja unica diferenca mecanica sao numeros")

	var spell := {
		"id": "prova",
		"school": "feiticaria",
		"delivery_form": "projectil_simples",
	}
	var staff_plan := InstrumentCatalog.build_cast_plan(equipment, "cajado", spell)
	var bell_plan := InstrumentCatalog.build_cast_plan(equipment, "sino", spell)
	_check(bool(staff_plan.get("valid", false)) and bool(bell_plan.get("valid", false))
		and String(staff_plan.get("input_action", "")) == "cast"
		and String(bell_plan.get("input_action", "")) == "cast"
		and String(staff_plan.get("output_delivery", "")) == "perfurante"
		and String(bell_plan.get("output_delivery", "")) == "persistent_pulse_at_target",
		"o mesmo feitiço usa a acção cast e ganha opções, não apenas números")
	var benchmark_start := Time.get_ticks_usec()
	for iteration: int in BENCHMARK_CAST_PLANS:
		InstrumentCatalog.build_cast_plan(equipment, "cajado" if iteration % 2 == 0 else "sino",
			spell)
	var benchmark_elapsed_us := Time.get_ticks_usec() - benchmark_start
	print("INSTRUMENT_CAST_PLAN_BENCHMARK %d planos em %d us (%.3f us/plano)" % [
		BENCHMARK_CAST_PLANS, benchmark_elapsed_us,
		float(benchmark_elapsed_us) / float(BENCHMARK_CAST_PLANS)])
	_report()


func _load_json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  OK  ", description)
	else:
		_failed += 1
		push_error("  FALHOU  " + description)


func _contains_error(errors: Array[String], fragment: String) -> bool:
	for error: String in errors:
		if error.contains(fragment):
			return true
	return false


func _report() -> void:
	print("INSTRUMENT_CATALOG_TEST %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
