extends RefCounted
## Interface pura entre equipment.json e o consumidor de magia.
## Nao cria nos, nao escolhe formulas e nao conhece classes concretas.

const REQUIRED_FIELDS: Array[String] = [
	"weapon_id",
	"instrument_type",
	"school_tags",
	"slot",
	"hands",
	"spell_power",
	"cast_speed_multiplier_by_form",
	"cast_option",
	"origin_bias",
	"access_policy",
]


static func contract_errors(equipment: Dictionary, attributes: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var instruments: Dictionary = equipment.get("magic_instruments", {}) as Dictionary
	var rules: Dictionary = equipment.get("_magic_instrument_rules", {}) as Dictionary
	var assignments: Dictionary = rules.get("starting_instrument_by_origin", {}) as Dictionary
	var classes: Dictionary = attributes.get("classes", {}) as Dictionary
	var used_instruments: Dictionary = {}
	var choice_owners: Dictionary = {}

	for origin_id: String in classes.keys():
		if origin_id.begins_with("_"):
			continue
		var instrument_id := String(assignments.get(origin_id, ""))
		if instrument_id.is_empty() or not instruments.has(instrument_id):
			errors.append("origem sem instrumento: %s" % origin_id)
			continue
		if used_instruments.has(instrument_id):
			errors.append("instrumento inicial repetido: %s" % instrument_id)
		used_instruments[instrument_id] = origin_id
		var instrument: Dictionary = instruments.get(instrument_id, {}) as Dictionary
		if String(instrument.get("origin_bias", "")) != origin_id:
			errors.append("bias inicial divergente: %s" % instrument_id)

	for origin_value: Variant in assignments.keys():
		var origin_id := String(origin_value)
		if not classes.has(origin_id):
			errors.append("instrumento aponta para origem inexistente: %s" % origin_id)

	for instrument_id: String in instruments.keys():
		var instrument: Dictionary = instruments.get(instrument_id, {}) as Dictionary
		for field: String in REQUIRED_FIELDS:
			if not instrument.has(field):
				errors.append("%s sem %s" % [instrument_id, field])
		if String(instrument.get("access_policy", "")) != "any_origin":
			errors.append("instrumento bloqueia origem: %s" % instrument_id)
		for forbidden_field: String in ["allowed_classes", "class_lock", "required_origin"]:
			if instrument.has(forbidden_field):
				errors.append("%s declara bloqueio %s" % [instrument_id, forbidden_field])
		var expected_slot := "main_hand" if String(instrument.get(
			"instrument_type", "")) == "cajado" else "offhand"
		if String(instrument.get("slot", "")) != expected_slot \
				or int(instrument.get("hands", 0)) != 1:
			errors.append("mao decidida nao cumprida: %s" % instrument_id)
		var option: Dictionary = instrument.get("cast_option", {}) as Dictionary
		for option_field: String in ["choice_id", "operation", "trigger_action", "build",
				"gain", "loss"]:
			if String(option.get(option_field, "")).is_empty():
				errors.append("%s sem opcao semantica %s" % [instrument_id, option_field])
		if String(option.get("trigger_action", "")) != "cast":
			errors.append("instrumento sem accao existente: %s" % instrument_id)
		var signature := _choice_signature(option)
		if choice_owners.has(signature):
			errors.append("%s e %s diferem apenas em numeros" % [
			choice_owners.get(signature), instrument_id])
		else:
			choice_owners[signature] = instrument_id

	return errors


static func build_cast_plan(equipment: Dictionary, instrument_id: String,
		spell: Dictionary) -> Dictionary:
	var instruments: Dictionary = equipment.get("magic_instruments", {}) as Dictionary
	var instrument: Dictionary = instruments.get(instrument_id, {}) as Dictionary
	if instrument.is_empty():
		return {"valid": false, "reason": "instrument_not_found"}
	var school := String(spell.get("school", ""))
	if not (instrument.get("school_tags", []) as Array).has(school):
		return {"valid": false, "reason": "school_not_supported"}

	var option: Dictionary = instrument.get("cast_option", {}) as Dictionary
	var spell_role := String(spell.get("instrument_role", "direct"))
	var eligible_roles: Array = option.get("eligible_spell_roles", []) as Array
	if not eligible_roles.has(spell_role):
		return {"valid": false, "reason": "spell_role_not_supported"}
	var input_delivery := String(spell.get("delivery_form", ""))
	var output_delivery := String(option.get("to_delivery", input_delivery))
	if output_delivery == "unchanged":
		output_delivery = input_delivery
	var speed_by_form: Dictionary = instrument.get(
		"cast_speed_multiplier_by_form", {}) as Dictionary

	return {
		"valid": true,
		"instrument_id": instrument_id,
		"spell_id": spell.get("id", ""),
		"input_action": option.get("trigger_action", ""),
		"input_delivery": input_delivery,
		"output_delivery": output_delivery,
		"semantic_operation": option.get("operation", ""),
		"preserves_spell_effect": option.get("preserves_spell_effect", false),
		"spell_power": instrument.get("spell_power"),
		"cast_speed_multiplier": speed_by_form.get(
			input_delivery, speed_by_form.get("default")),
		"slot": instrument.get("slot", ""),
		"blocks_slot": instrument.get("blocks_slot", ""),
		"formula_policy": (equipment.get("_magic_instrument_rules", {}) as Dictionary).get(
			"formula_policy", ""),
	}


static func _choice_signature(option: Dictionary) -> String:
	var semantic := {
		"operation": option.get("operation", ""),
		"eligible_spell_roles": option.get("eligible_spell_roles", []),
		"to_delivery": option.get("to_delivery", ""),
		"preserves_spell_effect": option.get("preserves_spell_effect", false),
	}
	return JSON.stringify(semantic, "", true)
