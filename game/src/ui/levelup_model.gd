class_name LevelUpModel
extends RefCounted
## Modelo puro do ecrã de nível. Lê todas as curvas e custos dos catálogos e
## devolve um estado antes/depois; não conhece fogueiras, zonas ou requisitos.


static func build(state: Dictionary, selected_attribute := "") -> Dictionary:
	var progression := _progression(state)
	if progression.is_empty():
		return {"ok": false, "status": "invalid_state", "attribute_rows": []}
	var level_cfg: Dictionary = _attributes().get("level", {}) as Dictionary
	var maximum_level := int(level_cfg.get("max_level", 0))
	var current_level := int(progression.get("level", 0))
	var at_level_cap := current_level >= maximum_level
	var next_level := mini(current_level + int(level_cfg.get("points_per_level", 1)), maximum_level)
	var cost := 0 if at_level_cap else int(_game_data().call("level_cost", next_level))
	var souls := int(progression.get("souls_held", 0))
	var attrs: Dictionary = progression.get("attributes", {}) as Dictionary
	var rows: Array[Dictionary] = []
	var row_cfgs: Array = (_attributes().get("level_up_ui", {}) as Dictionary).get(
		"attribute_rows", []) as Array
	var valid_selection := false
	for row_value: Variant in row_cfgs:
		var row_cfg := row_value as Dictionary
		if String(row_cfg.get("id", "")) == selected_attribute:
			valid_selection = true
			break
	if not valid_selection:
		selected_attribute = _first_available_attribute(attrs, row_cfgs)
	var selected_preview := {}
	for row_value: Variant in row_cfgs:
		var row_cfg := row_value as Dictionary
		var attribute_id := String(row_cfg.get("id", ""))
		var value := int(attrs.get(attribute_id, _attributes().get("base_value", 0)))
		var maximum_attribute := int(_attributes().get("max_per_attribute", 0))
		var capped := value >= maximum_attribute
		var preview := preview_attribute(state, attribute_id)
		var primary_metric := String(row_cfg.get("primary_metric", ""))
		var before: Dictionary = preview.get("before", {}) as Dictionary
		var after: Dictionary = preview.get("after", {}) as Dictionary
		var row := {
			"id": attribute_id,
			"display_name": String(row_cfg.get("display_name", attribute_id.capitalize())),
			"value": value,
			"proposed_value": value if capped else value + 1,
			"capped": capped,
			"selected": attribute_id == selected_attribute,
			"primary_metric": primary_metric,
			"primary_before": before.get(primary_metric, 0.0),
			"primary_after": after.get(primary_metric, before.get(primary_metric, 0.0)),
			"curve_markers": curve_markers(row_cfg),
			"preview": preview,
		}
		rows.append(row)
		if attribute_id == selected_attribute:
			selected_preview = preview
	var selected_row := _row_for(rows, selected_attribute)
	var selected_capped := bool(selected_row.get("capped", true))
	return {
		"ok": true,
		"status": "ready",
		"currency_id": String(level_cfg.get("currency", "")),
		"current_level": current_level,
		"next_level": next_level,
		"maximum_level": maximum_level,
		"at_level_cap": at_level_cap,
		"souls_held": souls,
		"cost": cost,
		"shortfall": maxi(cost - souls, 0),
		"can_afford": not at_level_cap and souls >= cost,
		"selected_attribute": selected_attribute,
		"selected_capped": selected_capped,
		"can_confirm": not at_level_cap and not selected_capped and souls >= cost,
		"attribute_rows": rows,
		"preview": selected_preview,
	}


static func preview_attribute(state: Dictionary, attribute_id: String) -> Dictionary:
	var progression := _progression(state)
	var attrs: Dictionary = progression.get("attributes", {}) as Dictionary
	var ids: Array = _attributes().get("attribute_ids", []) as Array
	if not ids.has(attribute_id):
		return {"ok": false, "status": "invalid_attribute", "before": {}, "after": {}}
	var maximum_attribute := int(_attributes().get("max_per_attribute", 0))
	var current := int(attrs.get(attribute_id, _attributes().get("base_value", 0)))
	var proposed := mini(current + 1, maximum_attribute)
	var proposed_state := state.duplicate(true)
	var proposed_progression := _progression(proposed_state)
	var proposed_attrs: Dictionary = proposed_progression.get("attributes", {}) as Dictionary
	proposed_attrs[attribute_id] = proposed
	proposed_progression["attributes"] = proposed_attrs
	var before := _combat_snapshot(state, attrs)
	var after := _combat_snapshot(proposed_state, proposed_attrs)
	return {
		"ok": true,
		"status": "attribute_cap" if current >= maximum_attribute else "ready",
		"attribute_id": attribute_id,
		"current_value": current,
		"proposed_value": proposed,
		"before": before,
		"after": after,
		"delta": _numeric_delta(before, after),
	}


static func purchase(state: Dictionary, attribute_id: String) -> Dictionary:
	var progression := _progression(state)
	if progression.is_empty():
		return {"ok": false, "status": "invalid_state", "state": state.duplicate(true)}
	var ids: Array = _attributes().get("attribute_ids", []) as Array
	if not ids.has(attribute_id):
		return {"ok": false, "status": "invalid_attribute", "state": state.duplicate(true)}
	var level_cfg: Dictionary = _attributes().get("level", {}) as Dictionary
	var level := int(progression.get("level", 0))
	var maximum_level := int(level_cfg.get("max_level", 0))
	if level >= maximum_level:
		return {"ok": false, "status": "level_cap", "state": state.duplicate(true)}
	var attrs: Dictionary = progression.get("attributes", {}) as Dictionary
	var current_attribute := int(attrs.get(
		attribute_id, _attributes().get("base_value", 0)))
	var maximum_attribute := int(_attributes().get("max_per_attribute", 0))
	if current_attribute >= maximum_attribute:
		return {"ok": false, "status": "attribute_cap", "state": state.duplicate(true)}
	var next_level := level + int(level_cfg.get("points_per_level", 1))
	var cost := int(_game_data().call("level_cost", next_level))
	var souls := int(progression.get("souls_held", 0))
	if souls < cost:
		return {
			"ok": false,
			"status": "insufficient_currency",
			"cost": cost,
			"shortfall": cost - souls,
			"state": state.duplicate(true),
		}
	var working := state.duplicate(true)
	var working_progression := _progression(working)
	var working_attrs: Dictionary = working_progression.get("attributes", {}) as Dictionary
	working_attrs[attribute_id] = current_attribute + 1
	working_progression["attributes"] = working_attrs
	working_progression["level"] = next_level
	working_progression["souls_held"] = souls - cost
	return {
		"ok": true,
		"status": "purchased",
		"attribute_id": attribute_id,
		"attribute_before": current_attribute,
		"attribute_after": current_attribute + 1,
		"level_before": level,
		"level_after": next_level,
		"cost": cost,
		"souls_before": souls,
		"souls_after": souls - cost,
		"state": working,
	}


static func curve_markers(row_cfg: Dictionary) -> Array[int]:
	var markers: Array[int] = []
	for key: String in ["curve_path", "secondary_curve_path"]:
		var path := String(row_cfg.get(key, ""))
		if path == "":
			continue
		var curve_value: Variant = _value_at_path(_attributes(), path)
		if curve_value is Array:
			for band_value: Variant in curve_value as Array:
				var marker := int((band_value as Dictionary).get("until", 0))
				if marker > 0 and not markers.has(marker):
					markers.append(marker)
		elif curve_value is int or curve_value is float:
			var marker := int(curve_value)
			if marker > 0 and not markers.has(marker):
				markers.append(marker)
	var maximum_attribute := int(_attributes().get("max_per_attribute", 0))
	if maximum_attribute > 0 and not markers.has(maximum_attribute):
		markers.append(maximum_attribute)
	markers.sort()
	return markers


static func _combat_snapshot(state: Dictionary, attrs: Dictionary) -> Dictionary:
	var stamina := float(_game_data().call("max_stamina_for", int(attrs.get("stamina", 0))))
	var dodge_cost := float((_game_data().call("section", "dodge") as Dictionary).get(
		"stamina_cost", 0.0))
	var weapon_context := _weapon_context(state, attrs)
	var load_profile := _safe_load_profile(state)
	return {
		"damage": float(weapon_context.get("damage", 0.0)),
		"damage_available": bool(weapon_context.get("available", false)),
		"weapon_id": String(weapon_context.get("id", "")),
		"weapon_name": String(weapon_context.get("name", "")),
		"health": float(_game_data().call("max_health_for", int(attrs.get("vida", 0)))),
		"defense": float(_game_data().call("defense_for", int(attrs.get("constituicao", 0)))),
		"stamina": stamina,
		"dodges": floori(stamina / dodge_cost) if dodge_cost > 0.0 else 0,
		"mana": int(_game_data().call("max_mana_for", attrs)),
		"load_capacity": float(_game_data().call(
			"load_capacity_for", int(attrs.get("carga", 0)))),
		"load_weight": float(load_profile.get("weight", 0.0)),
		"load_fraction": float(load_profile.get("fraction", 0.0)),
		"load_class": String(load_profile.get("class", "")),
	}


static func _weapon_context(state: Dictionary, attrs: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	var weapon_id := String(equipment.get("main", ""))
	var weapon := _game_data().call("weapon", weapon_id) as Dictionary
	var light: Dictionary = weapon.get("light", {}) as Dictionary
	if weapon.is_empty() or light.is_empty():
		return {"available": false, "id": weapon_id, "name": "", "damage": 0.0}
	return {
		"available": true,
		"id": weapon_id,
		"name": String(weapon.get("display_name", weapon_id)),
		"damage": float(_game_data().call("compute_damage",
			float(light.get("mv", 0.0)), weapon_id, attrs, 0.0)),
	}


## InventorySystem.load_profile ainda chama String(null) nos slots vazios dos
## kits. A pré-visualização normaliza só uma cópia; nunca altera o save recebido.
static func _safe_load_profile(state: Dictionary) -> Dictionary:
	var preview_state := state.duplicate(true)
	var character: Dictionary = preview_state.get("character", {}) as Dictionary
	var inventory: Dictionary = character.get("inventory", {}) as Dictionary
	var equipment: Dictionary = inventory.get("equipment", {}) as Dictionary
	for slot: String in ["main", "offhand"]:
		if equipment.get(slot) == null:
			equipment[slot] = ""
	return _inventory_system().call("load_profile", preview_state) as Dictionary


static func _numeric_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key: Variant in before.keys():
		if before[key] is int or before[key] is float:
			result[key] = float(after.get(key, before[key])) - float(before[key])
	return result


static func _first_available_attribute(attrs: Dictionary, row_cfgs: Array) -> String:
	var maximum_attribute := int(_attributes().get("max_per_attribute", 0))
	for row_value: Variant in row_cfgs:
		var id := String((row_value as Dictionary).get("id", ""))
		if int(attrs.get(id, maximum_attribute)) < maximum_attribute:
			return id
	return String((row_cfgs[0] as Dictionary).get("id", "")) if not row_cfgs.is_empty() else ""


static func _row_for(rows: Array[Dictionary], attribute_id: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row.get("id", "")) == attribute_id:
			return row
	return {}


static func _progression(state: Dictionary) -> Dictionary:
	var character: Dictionary = state.get("character", {}) as Dictionary
	return character.get("progression", {}) as Dictionary


static func _value_at_path(source: Dictionary, path: String) -> Variant:
	var current: Variant = source
	for part: String in path.split("/", false):
		if not current is Dictionary:
			return null
		current = (current as Dictionary).get(part)
	return current


static func _game_data() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node("GameData")


static func _inventory_system() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node("InventorySystem")


static func _attributes() -> Dictionary:
	return _game_data().get("attributes") as Dictionary
