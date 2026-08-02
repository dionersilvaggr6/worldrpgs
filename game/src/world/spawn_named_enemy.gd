extends "res://src/enemies/enemy.gd"
## Variante de um inimigo comum promovida pelo catalogo de encontros nomeados.
## Reutiliza corpo, animacoes e combate-base; acrescenta apenas os multiplicadores,
## o golpe e o espolio que named_encounters.json declara.

signal guaranteed_loot_awarded(encounter_id: String, result: Dictionary)

var named_encounter_id := ""
var _guaranteed_loot_awarded := false


func configure_named(encounter_id: String) -> bool:
	var game_data := get_node_or_null("/root/GameData")
	if game_data == null:
		push_error("[spawn] GameData indisponivel para %s" % encounter_id)
		return false
	var encounter := game_data.call("named_encounter", encounter_id) as Dictionary
	if encounter.is_empty() or String(encounter.get("base_enemy_id", "")) != enemy_id:
		push_error("[spawn] encontro nomeado invalido: %s/%s" % [encounter_id, enemy_id])
		return false
	named_encounter_id = encounter_id
	data = data.duplicate(true)
	data["display_name"] = String(encounter.get("display_name", enemy_id))
	data["named_encounter_id"] = encounter_id
	max_health *= float(encounter.get("health_multiplier", 1.0))
	health = max_health
	max_posture *= float(encounter.get("posture_multiplier", 1.0))
	posture = max_posture

	var extra_attack := _expanded_extra_attack(
		encounter.get("extra_attack", {}) as Dictionary)
	if extra_attack.is_empty():
		push_error("[spawn] encontro nomeado sem golpe executavel: %s" % encounter_id)
		return false
	var extra_id := String(extra_attack.get("id", ""))
	_attacks[extra_id] = extra_attack
	var patterns: Array = (data.get("patterns", []) as Array).duplicate(true)
	patterns.append([extra_id])
	data["patterns"] = patterns
	set_meta("named_encounter_id", encounter_id)
	set_meta("guaranteed_loot", String(encounter.get("guaranteed_loot", "")))
	if not died.is_connected(_on_named_died):
		died.connect(_on_named_died)
	return true


func _expanded_extra_attack(declared: Dictionary) -> Dictionary:
	var base_attacks: Array = data.get("attacks", []) as Array
	if declared.is_empty() or base_attacks.is_empty():
		return {}
	# O catalogo nomeado declara a diferenca. Contacto, alcance, dano, som e forma
	# herdam do primeiro golpe completo do tipo-base, em vez de inventar numeros.
	var attack: Dictionary = (base_attacks[0] as Dictionary).duplicate(true)
	for field: String in ["id", "display_name", "startup", "active", "recovery",
			"parryable", "tell"]:
		attack[field] = declared.get(field, attack.get(field))
	var vector := String(declared.get("vector", ""))
	if not vector.is_empty():
		attack["vector"] = vector
		attack["vectores_fuga"] = [vector]
	var startup := int(attack["startup"])
	attack["aviso_total_frames"] = startup
	attack["momento_compromisso_frame"] = mini(
		int(attack.get("momento_compromisso_frame", startup)), startup)
	var audio: Dictionary = (attack.get("som_anuncio", {}) as Dictionary).duplicate(true)
	audio["cue_id"] = "attack.named.%s.%s" % [
		named_encounter_id, attack.get("id", "unknown")]
	audio["descricao"] = String(attack.get("tell", ""))
	attack["som_anuncio"] = audio
	var visual: Dictionary = (attack.get(
		"sinal_visual_equivalente", {}) as Dictionary).duplicate(true)
	visual["compromisso"] = "fecha no primeiro frame activo, frame %d" % (startup + 1)
	attack["sinal_visual_equivalente"] = visual
	attack["descricao_visual"] = String(attack.get("tell", ""))
	return attack


func _on_named_died(_defeated: Node) -> void:
	if _guaranteed_loot_awarded:
		return
	var item_key := String(get_meta("guaranteed_loot", ""))
	if item_key.is_empty():
		return
	var inventory_system := get_node_or_null("/root/InventorySystem")
	var result: Dictionary = inventory_system.call("add_item", item_key, 1) as Dictionary \
		if inventory_system != null else {"ok": false, "message": "Inventario indisponivel."}
	if bool(result.get("ok", false)):
		_guaranteed_loot_awarded = true
	guaranteed_loot_awarded.emit(named_encounter_id, result)
