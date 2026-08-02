extends Node
## Carrega todos os ficheiros de dados e constroi o mapa de comandos em runtime.
##
## REGRA DO PROTOTIPO: nenhum numero de combate vive em codigo. Vive em res://data/*.json.
## Para afinar uma janela, um custo ou um MV, mexe-se no JSON e volta-se a correr — sem recompilar.
##
## Fontes: spec/01-combate.md (WP1 — frames, janelas, MV, custos)
##         spec/11-formulas.md (WP2 — atributos, formula de dano, curvas dos inimigos)

const DATA_DIR := "res://data/"

var combat: Dictionary = {}
var weapons: Dictionary = {}
var enemies: Dictionary = {}
var spells: Dictionary = {}
var controls: Dictionary = {}
var attributes: Dictionary = {}
var abilities: Dictionary = {}
var biomes: Dictionary = {}
var races: Dictionary = {}
var armor: Dictionary = {}
var equipment: Dictionary = {}
var world: Dictionary = {}
var progression: Dictionary = {}
var named_catalog: Dictionary = {}
var economy: Dictionary = {}
var appearance: Dictionary = {}
var ui_strings: Dictionary = {}
var save_state: Dictionary = {}

var load_errors: Array[String] = []


func _ready() -> void:
	combat = _load_json("combat.json")
	weapons = _load_json("weapons.json")
	enemies = _load_json("enemies.json")
	spells = _load_json("spells.json")
	controls = _load_json("controls.json")
	attributes = _load_json("attributes.json")
	abilities = _load_json("abilities.json")
	biomes = _load_json("biomes.json")
	races = _load_json("races.json")
	armor = _load_json("armor.json")
	equipment = _load_json("equipment.json")
	world = _load_json("world.json")
	progression = _load_json("progression.json")
	named_catalog = _load_json("named_encounters.json")
	economy = _load_json("economy.json")
	appearance = _load_json("appearance.json")
	ui_strings = _load_json("strings.pt.json")
	_expand_enemy_catalog()
	_build_input_map()
	_validate()


func _load_json(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		_fail("Ficheiro de dados em falta: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("JSON invalido em %s" % path)
		return {}
	return parsed as Dictionary


func _fail(message: String) -> void:
	load_errors.append(message)
	push_error(message)


# --- Acessos ------------------------------------------------------------------

## Converte frames (a 60 fps de referencia) em segundos.
func frames_to_seconds(f: float) -> float:
	return f / float(combat.get("reference_fps", 60))


func section(name: String) -> Dictionary:
	return combat.get(name, {}) as Dictionary


func weapon(id: String) -> Dictionary:
	if id == "":
		return {}
	return weapons.get(id, {}) as Dictionary


func enemy(id: String) -> Dictionary:
	return enemies.get(id, {}) as Dictionary


func ring(id: String) -> Dictionary:
	return (equipment.get("rings", {}) as Dictionary).get(id, {}) as Dictionary


func equipment_weapon(id: String) -> Dictionary:
	return (equipment.get("weapons", {}) as Dictionary).get(id, {}) as Dictionary


func equipment_armor(id: String) -> Dictionary:
	return (equipment.get("armor", {}) as Dictionary).get(id, {}) as Dictionary


func world_zone(id: String) -> Dictionary:
	return (world.get("zones", {}) as Dictionary).get(id, {}) as Dictionary


func named_encounter(id: String) -> Dictionary:
	return (named_catalog.get("encounters", {}) as Dictionary).get(id, {}) as Dictionary


func material(id: String) -> Dictionary:
	return (economy.get("materials", {}) as Dictionary).get(id, {}) as Dictionary


func consumable(id: String) -> Dictionary:
	var aliases: Dictionary = economy.get("aliases", {}) as Dictionary
	var canonical_id := String(aliases.get(id, id))
	return (economy.get("consumables", {}) as Dictionary).get(canonical_id, {}) as Dictionary


## Todo o texto apresentado ao jogador nasce no catálogo da língua. Mensagens
## de diagnóstico e nomes internos continuam no código: não são interface.
func ui_text(id: String, fallback: String = "") -> String:
	var strings: Dictionary = ui_strings.get("strings", {}) as Dictionary
	return String(strings.get(id, fallback))


## O JSON guarda declaracoes compactas de ataques, mas o runtime recebe sempre
## a ficha completa do spec/38. Assim um molde de contacto corrige todos os
## utilizadores sem apagar a pose, o som ou a ancora propria de cada golpe.
func _expand_enemy_catalog() -> void:
	var templates: Dictionary = enemies.get("_attack_templates", {}) as Dictionary
	var attack_defaults: Dictionary = enemies.get("_attack_defaults", {}) as Dictionary
	var defaults: Dictionary = enemies.get("_enemy_defaults", {}) as Dictionary
	for enemy_id: String in enemies.keys():
		if enemy_id.begins_with("_"):
			continue
		var e: Dictionary = defaults.duplicate(true)
		e.merge(enemies[enemy_id] as Dictionary, true)
		enemies[enemy_id] = e
		var expanded: Array = []
		for value: Variant in e.get("attacks", []):
			var declared: Dictionary = value as Dictionary
			var template_id := String(declared.get("template", ""))
			var attack: Dictionary = attack_defaults.duplicate(true)
			attack.merge(templates.get(template_id, {}) as Dictionary, true)
			attack.merge(declared, true)
			var phase_1 := int(attack["phase_1_frames"])
			var phase_2 := int(attack["phase_2_frames"])
			var startup := phase_1 + phase_2
			var active := int(attack["active"])
			var recovery := int(attack["recovery"])
			var phase_4 := mini(int(attack["phase_4_frames"]), recovery)
			var actor := String(attack.get("actor", "corpo"))
			var tell := String(attack.get("tell", "recolhe antes de avancar"))
			var impact := String(attack.get("impact", "cruza o espaco marcado"))
			var sound_description := String(attack.get("sound", "esforco e deslocacao de ar distintos"))
			var anchor := String(attack.get("anchor", actor))
			attack["startup"] = startup
			attack["aviso_total_frames"] = startup
			attack["fase_1"] = "%d f — %s: %s" % [phase_1, actor, tell]
			attack["fase_2"] = "%d f — %s; ajuste cai para 30 graus/s" % [phase_2, sound_description]
			attack["fase_3"] = "%d f — %s" % [active, impact]
			attack["fases_4_5"] = "%d f de saida + %d f de regresso" % [phase_4, recovery - phase_4]
			attack["momento_compromisso_frame"] = phase_1
			var tracking := attack["tracking_curve_deg_s"] as Dictionary
			attack["curva_seguimento"] = {
				"fase_1_deg_s": float(tracking["phase_1"]),
				"fase_2_deg_s": float(tracking["phase_2"]),
				"fase_3_deg_s": float(tracking["phase_3"]),
			}
			attack["som_anuncio"] = {
				"cue_id": "attack.%s.%s" % [enemy_id, attack.get("id", "unknown")],
				"descricao": sound_description,
				"profile": _attack_sound_profile(attack),
				"alcance_informativo_m": float(attack["informative_range_m"]),
			}
			attack["sinal_visual_equivalente"] = {
				"ancora": anchor,
				"forma": String(attack.get("visual_shape", "losango partido ESQUIVAR")),
				"inicio": "surge no frame 1, preso a %s" % anchor,
				"compromisso": "fecha no primeiro frame activo, frame %d" % (startup + 1),
				"fim": "dissolve no fim; se cancelado, quebra em 0,15 s",
				"fora_ecra": "cunha no bordo na direccao da origem, com a mesma forma e tres bandas de distancia",
			}
			if attack.has("radius"):
				attack["alcance_arco"] = "raio %.1f m · 360 graus" % float(attack.get("radius", 0.0))
			else:
				attack["alcance_arco"] = "%.1f m · %d graus" % [
					float(attack.get("range", 0.0)), int(attack.get("arc_degrees", 0))]
			attack["descricao_visual"] = "%s; %s; materiais e silhueta pertencem ao inimigo que o executa" % [tell, impact]
			attack["fatia_1"] = bool(e.get("fatia_1", false))
			expanded.append(attack)
		e["attacks"] = expanded

		if not bool(e.get("is_boss", false)):
			var cards: Array = (e.get("loot_cards", []) as Array).duplicate(true)
			var mandatory_count := mini(int(e.get("mandatory_loot_count", 0)), cards.size())
			var mandatory_indices: Array = []
			for index in mandatory_count:
				mandatory_indices.append(index)
			e["loot_deck"] = {
				"cards": cards,
				"mandatory_indices": mandatory_indices,
				"without_replacement": true,
				"bias_only_on_filler": true,
			}
		if not e.has("patterns") and not bool(e.get("is_boss", false)):
			var single_patterns: Array = []
			for attack_value: Variant in expanded:
				if not bool((attack_value as Dictionary).get("anti_kite_only", false)):
					single_patterns.append([String((attack_value as Dictionary).get("id", ""))])
			e["patterns"] = single_patterns
		e["gap_between_patterns"] = float(e.get("gap_between_patterns", 1.25))


## Ordem reproduzivel do baralho. O estado de save guarda depois o indice e as
## cartas tiradas; esta funcao garante que o mesmo ensaio + semente da spec/60
## produz exactamente a mesma sequencia.
func loot_draw_order(enemy_id: String, seed_value: int) -> Array:
	var cards: Array = ((enemy(enemy_id).get("loot_deck", {}) as Dictionary).get("cards", []) as Array).duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ hash(enemy_id)
	for i in range(cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held: Variant = cards[i]
		cards[i] = cards[j]
		cards[j] = held
	return cards


## Custo cubico canonico do nivel que se compra (spec/58 corrigido por spec/72).
## O minimo evita custos negativos nos primeiros niveis sem criar uma segunda
## tabela que possa divergir da formula publicada.
func level_cost(level_to_buy: int) -> int:
	var economy_rules: Dictionary = economy.get("rules", {}) as Dictionary
	var cost_rule: Dictionary = economy_rules.get("level_cost", {}) as Dictionary
	var level := clampi(level_to_buy, 1, int(cost_rule.get("maximum_level", 100)))
	return maxi(1, roundi(0.02 * pow(level, 3) + 3.06 * pow(level, 2)
		+ 105.6 * level - 895.0))


## Resolve apenas a carta de enchimento. As cartas obrigatorias nunca passam
## aqui e, portanto, nunca mudam com a classe. Em co-op o chamador fornece a
## classe do destinatario: quem e esse destinatario continua pergunta dos donos.
func resolve_loot_card(enemy_id: String, raw_card: String, receiver_class_id: String) -> String:
	if raw_card != "bias:classe":
		var split: PackedStringArray = raw_card.split(":", false, 1)
		if split.size() == 2 and split[0] == "consumivel":
			var aliases: Dictionary = economy.get("aliases", {}) as Dictionary
			return "consumivel:%s" % String(aliases.get(split[1], split[1]))
		return raw_card
	var e := enemy(enemy_id)
	var zone_ids: Array = e.get("biome_ids", []) as Array
	if zone_ids.is_empty():
		return ""
	var bias: Dictionary = economy.get("class_bias", {}) as Dictionary
	var profile := String((bias.get("profiles", {}) as Dictionary).get(receiver_class_id, "martial"))
	var zone_pool: Dictionary = (bias.get("by_zone", {}) as Dictionary).get(
		String(zone_ids[0]), {}) as Dictionary
	return String(zone_pool.get(profile, ""))


## Compra transaccional em memoria. O chamador persiste o dicionario inteiro
## com SaveSystem.commit_enemy_defeat(), cujo rename atomico publica ao mesmo
## tempo almas, indice do baralho, item e recibo. event_id torna a operacao
## idempotente quando uma repeticao de rede ou recuperacao volta a pedi-la.
func reward_enemy_defeat(state: Dictionary, enemy_id: String, event_id: String,
		seed_value: int, receiver_class_id: String) -> Dictionary:
	var e := enemy(enemy_id)
	if state.is_empty() or e.is_empty() or bool(e.get("is_boss", false)) or event_id == "":
		return {"status": "invalid"}
	var world_state: Dictionary = state.get("world", {}) as Dictionary
	var receipts: Array = world_state.get("reward_receipts", []) as Array
	for receipt_value: Variant in receipts:
		var previous := receipt_value as Dictionary
		if String(previous.get("event_id", "")) == event_id:
			var repeated := previous.duplicate(true)
			repeated["status"] = "already_committed"
			return repeated

	var loot_decks: Dictionary = world_state.get("loot_decks", {}) as Dictionary
	var deck_state: Dictionary = loot_decks.get(enemy_id, {}) as Dictionary
	if deck_state.is_empty():
		deck_state = {
			"seed": seed_value,
			"order": loot_draw_order(enemy_id, seed_value),
			"next_index": 0,
		}
	var order: Array = deck_state.get("order", []) as Array
	var next_index := int(deck_state.get("next_index", 0))
	if next_index >= order.size():
		return {"status": "exhausted", "enemy_id": enemy_id, "event_id": event_id}

	var raw_card := String(order[next_index])
	var resolved_card := resolve_loot_card(enemy_id, raw_card, receiver_class_id)
	if resolved_card == "":
		return {"status": "invalid_bias", "enemy_id": enemy_id, "event_id": event_id}
	var soul_delta := int(e.get("souls", 0))
	var card_parts: PackedStringArray = resolved_card.split(":", false, 1)
	if card_parts.size() == 2 and card_parts[0] == "almas_bonus":
		soul_delta += int(card_parts[1])

	var character: Dictionary = state.get("character", {}) as Dictionary
	var character_progression: Dictionary = character.get("progression", {}) as Dictionary
	character_progression["souls_held"] = int(character_progression.get("souls_held", 0)) + soul_delta
	if card_parts.size() == 2 and card_parts[0] not in ["almas_bonus", "bias"]:
		var inventory: Dictionary = character.get("inventory", {}) as Dictionary
		var items: Dictionary = inventory.get("items", {}) as Dictionary
		items[resolved_card] = int(items.get(resolved_card, 0)) + 1
		inventory["items"] = items
		character["inventory"] = inventory
	character["progression"] = character_progression
	state["character"] = character

	deck_state["next_index"] = next_index + 1
	loot_decks[enemy_id] = deck_state
	world_state["loot_decks"] = loot_decks
	var receipt := {
		"status": "awarded",
		"event_id": event_id,
		"enemy_id": enemy_id,
		"deck_index": next_index,
		"raw_card": raw_card,
		"resolved_card": resolved_card,
		"souls_awarded": soul_delta,
	}
	receipts.append(receipt.duplicate(true))
	world_state["reward_receipts"] = receipts
	state["world"] = world_state
	return receipt


func _attack_sound_profile(attack: Dictionary) -> String:
	var vectors: Array = attack.get("vectores_fuga", []) as Array
	if String(attack.get("tipo_contacto", "")) == "volume_persistente":
		return "attack_area"
	if vectors.has("quebrar_a_visao"):
		return "attack_hunter"
	if String(attack.get("tipo_contacto", "")) == "volume_movel":
		return "attack_moving"
	if bool(attack.get("parryable", false)):
		return "attack_parry"
	return "attack_dodge"


func spell(id: String) -> Dictionary:
	return spells.get(id, {}) as Dictionary


## Expande a forma comum e deixa a ficha do feitico substituir apenas as
## diferencas. Esta e a unica fronteira que o runtime de projeteis deve ler.
func spell_delivery_contract(id: String) -> Dictionary:
	var spell_entry := spell(id)
	if spell_entry.is_empty():
		return {}
	var contracts: Dictionary = spells.get("_delivery_contracts", {}) as Dictionary
	var contract: Dictionary = (contracts.get(
		String(spell_entry.get("delivery_form", "")), {}) as Dictionary).duplicate(true)
	if spell_entry.has("speed_mps"):
		contract["speed_m_s"] = float(spell_entry.get("speed_mps", 0.0))
	if spell_entry.has("max_range"):
		contract["max_range_m"] = float(spell_entry.get("max_range", 0.0))
	contract["delivery_form"] = String(spell_entry.get("delivery_form", ""))
	contract["contact_type"] = String(spell_entry.get("contact_type", ""))
	return contract


## A pergunta 41 continua dos donos. Enquanto estiver aberta, o runtime expõe
## apenas o nível base e nunca interpreta as propostas editoriais como regras.
func spell_upgrade(id: String, level: int) -> Dictionary:
	var spell_entry := spell(id)
	if spell_entry.is_empty() or level < 0:
		return {}
	var gate: Dictionary = (spells.get("_rules", {}) as Dictionary).get(
		"upgrades", {}) as Dictionary
	if not (gate.get("available_levels", []) as Array).has(level):
		return {}
	var upgrades: Array = spell_entry.get("upgrades", []) as Array
	if level >= upgrades.size():
		return {}
	return (upgrades[level] as Dictionary).duplicate(true)


func class_attributes(class_id: String) -> Dictionary:
	return (attributes.get("classes", {}) as Dictionary).get(class_id, {}) as Dictionary


# --- Progressao e fisica corrigidas na spec/70 -------------------------------

func cycle_multipliers(cycle: int) -> Vector2:
	var cfg: Dictionary = progression.get("cycles", {}) as Dictionary
	var bounded := clampi(cycle, int(cfg.get("min", 1)), int(cfg.get("max", 7)))
	if bounded <= 1:
		return Vector2.ONE
	var first: Dictionary = cfg.get("ng_plus", {}) as Dictionary
	var later: Dictionary = cfg.get("each_cycle_after_ng_plus", {}) as Dictionary
	var extra_cycles := bounded - 2
	return Vector2(
		float(first.get("health_multiplier", 1.30)) + extra_cycles * float(later.get("health_add", 0.05)),
		float(first.get("damage_multiplier", 1.15)) + extra_cycles * float(later.get("damage_add", 0.03))
	)


func fall_is_fatal(height_m: float) -> bool:
	var cfg: Dictionary = progression.get("fall", {}) as Dictionary
	return height_m >= float(cfg.get("fatal_min_m", 20.0))


func fall_damage(height_m: float, maximum_health: float, load_fraction: float = 0.0,
		fall_reduction: float = 0.0) -> float:
	var cfg: Dictionary = progression.get("fall", {}) as Dictionary
	if height_m <= float(cfg.get("no_damage_max_m", 5.0)):
		return 0.0
	if fall_is_fatal(height_m):
		return INF
	var knots: Array = cfg.get("damage_knots", []) as Array
	var lower: Dictionary = knots[0] as Dictionary
	var upper: Dictionary = knots[-1] as Dictionary
	for index in range(1, knots.size()):
		upper = knots[index] as Dictionary
		if height_m <= float(upper.get("height_m", 20.0)):
			lower = knots[index - 1] as Dictionary
			break
	var lower_h := float(lower.get("height_m", 5.0))
	var upper_h := float(upper.get("height_m", 20.0))
	var t := inverse_lerp(lower_h, upper_h, height_m)
	var fixed := lerpf(float(lower.get("fixed", 0.0)), float(upper.get("fixed", 0.0)), t)
	var proportional := lerpf(float(lower.get("max_health_fraction", 0.0)),
		float(upper.get("max_health_fraction", 0.0)), t)
	var base_damage := fixed + proportional * maximum_health
	var load_at_full := float(cfg.get("load_damage_multiplier_at_100_pct", 1.40))
	var load_multiplier := lerpf(1.0, load_at_full, clampf(load_fraction, 0.0, 1.0))
	return base_damage * load_multiplier * (1.0 - clampf(fall_reduction, 0.0, 0.95))


# --- Formulas do WP2 (spec/11-formulas.md) ------------------------------------

func _dmg_cfg() -> Dictionary:
	return attributes.get("damage", {}) as Dictionary


func _formula(name: String) -> Dictionary:
	return (attributes.get("formulas", {}) as Dictionary).get(name, {}) as Dictionary


## Soma uma curva por bandas absolutas. Cada banda vale desde o limite anterior
## ate `until`; o ultimo valor continua depois do ultimo limite.
func _piecewise_total(value: float, bands: Array) -> float:
	var remaining := maxf(value, 0.0)
	var previous_until := 0.0
	var total := 0.0
	for band_value: Variant in bands:
		var band := band_value as Dictionary
		var until := float(band.get("until", previous_until))
		var width := maxf(until - previous_until, 0.0)
		var in_band := minf(remaining, width)
		total += in_band * float(band.get("per_point", 0.0))
		remaining -= in_band
		previous_until = until
		if remaining <= 0.0:
			return total
	if remaining > 0.0 and not bands.is_empty():
		total += remaining * float((bands[-1] as Dictionary).get("per_point", 0.0))
	return total


## PV pela curva de Vida 20/50 (spec/70 §1).
func max_health_for(vida: int) -> float:
	var f := _formula("health")
	return float(f.get("base", 200.0)) + _piecewise_total(float(vida), f.get("bands", []) as Array)


## Reserva de stamina pela curva 20/40. A regeneracao nao escala — Lei 1.
func max_stamina_for(stamina_attr: int) -> float:
	var f := _formula("stamina")
	return float(f.get("base", 80.0)) \
		+ _piecewise_total(float(stamina_attr), f.get("bands", []) as Array)


## DEF pela curva propria de Constituicao 25/50.
func defense_for(constituicao: int) -> float:
	var f := _formula("defense")
	return float(f.get("base", 0.0)) \
		+ _piecewise_total(float(constituicao), f.get("bands", []) as Array)


## Capacidade de carga: Carga 8 preserva os 50 pontos dos kits iniciais.
func load_capacity_for(carga_attr: int) -> float:
	var f := _formula("load_capacity")
	return float(f.get("base", 42.0)) \
		+ _piecewise_total(float(carga_attr), f.get("bands", []) as Array)


## A reserva de mana cresce com o melhor dos dois atributos de conjuracao.
## A escola vermelha usa o MENOR apenas para a eficacia do feitico, nunca para
## reduzir a reserva partilhada por todas as escolas (spec/42 + spec/66).
func max_mana_for(attrs: Dictionary) -> int:
	var f := _formula("mana")
	var intelligence := int(attrs.get("inteligencia", 8))
	var faith := int(attrs.get("fe", 8))
	var casting_attr := maxi(intelligence, faith)
	var soft_cap := int(f.get("soft_cap", 35))
	var first_band := mini(casting_attr, soft_cap)
	var after_cap := maxi(casting_attr - soft_cap, 0)
	return int(f.get("base", 60)) \
		+ first_band * int(f.get("per_point", 4)) \
		+ after_cap * int(f.get("per_point_after_soft_cap", 1))


func casting_attribute_for(school_id: String, attrs: Dictionary) -> float:
	var schools: Dictionary = spells.get("_schools", {}) as Dictionary
	var school: Dictionary = schools.get(school_id, {}) as Dictionary
	var intelligence := float(attrs.get("inteligencia", 8))
	var faith := float(attrs.get("fe", 8))
	match String(school.get("scaling", "inteligencia")):
		"fe":
			return faith
		"media_int_fe":
			return (intelligence + faith) * 0.5
		"menor_int_fe":
			return minf(intelligence, faith)
		_:
			return intelligence


## Escala de dano com breakpoints absolutos 40/60. Calcula apenas o ganho acima
## do atributo base para conservar escala 1,0 no valor 8.
func attribute_scale(attr_value: float, weight_name: String) -> float:
	var cfg := _dmg_cfg()
	var weights: Dictionary = cfg.get("scale_weights", {}) as Dictionary
	var w: float = weights.get(weight_name, 0.6)
	var base_attr: float = float(attributes.get("base_value", 8))
	var bands: Array = cfg.get("scale_bands", []) as Array
	var gain := _piecewise_total(attr_value, bands) - _piecewise_total(base_attr, bands)
	return 1.0 + gain * w


## O jogador cumpre os requisitos da arma?
## Lei 3: nunca proibe pegar na arma — falhar custa em numeros (x0,6), nao em permissao.
func meets_requirements(weapon_id: String, attrs: Dictionary) -> bool:
	var reqs: Dictionary = weapon(weapon_id).get("requirements", {}) as Dictionary
	for attr_name: String in reqs.keys():
		if float(attrs.get(attr_name, 0)) < float(reqs[attr_name]):
			return false
	return true


## dano = MV x dano_base_da_arma x escala - DEF_do_alvo
## A DEF corta no maximo 40% (minimo 60% do dano calculado).
## Abaixo do requisito da arma: dano x0,6 e escala = 1.
func compute_damage(mv: float, weapon_id: String, attrs: Dictionary, target_defense: float) -> float:
	var w := weapon(weapon_id)
	if w.is_empty():
		return 0.0
	var cfg := _dmg_cfg()
	var base: float = w.get("base_damage", 0.0)
	var scale := 1.0
	var penalty := 1.0
	if meets_requirements(weapon_id, attrs):
		var attr_name: String = w.get("scaling_attribute", "")
		var attr_value: float = float(attrs.get(attr_name, attributes.get("base_value", 8)))
		scale = attribute_scale(attr_value, String(w.get("scale_weight", "medio")))
	else:
		scale = float(cfg.get("below_requirement_scale", 1.0))
		penalty = float(cfg.get("below_requirement_damage_multiplier", 0.6))

	var raw := mv * base * scale * penalty
	return apply_defense(raw, target_defense)


## Aplica a DEF a um dano bruto, respeitando o tecto de 40% de corte.
## Usado pelos inimigos, cujo dano vem fixado no WP2 em vez de sair de uma arma.
func apply_defense(raw: float, target_defense: float) -> float:
	var floor_fraction: float = _dmg_cfg().get("min_damage_fraction_after_defense", 0.6)
	return maxf(raw * floor_fraction, raw - target_defense)


## Dano de postura por golpe = MV x 10 (spec/01-combate.md, "Poise e interrupcao")
func posture_damage_from_mv(mv: float, multiplier: float = 1.0) -> float:
	var per_mv: float = section("poise").get("posture_damage_per_mv", 10.0)
	return mv * per_mv * multiplier


# --- Mapa de comandos ---------------------------------------------------------

func _build_input_map() -> void:
	var actions: Dictionary = controls.get("actions", {}) as Dictionary
	for action_name: String in actions.keys():
		if action_name.begins_with("_"):
			continue
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)
		InputMap.action_erase_events(action_name)
		for binding: Variant in actions[action_name]:
			var event := _event_from_binding(binding as Dictionary, action_name)
			if event != null:
				InputMap.action_add_event(action_name, event)


func reset_input_map_to_defaults() -> void:
	_build_input_map()


func _event_from_binding(binding: Dictionary, action_name: String) -> InputEvent:
	match binding.get("type", ""):
		"key":
			var code := _keycode_from_name(String(binding.get("key", "")))
			if code == KEY_NONE:
				_fail("Tecla desconhecida '%s' na accao '%s'" % [binding.get("key", ""), action_name])
				return null
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			return ev
		"mouse":
			var mb := InputEventMouseButton.new()
			mb.button_index = int(binding.get("button", 1)) as MouseButton
			return mb
		"joypad_button":
			var joy := InputEventJoypadButton.new()
			joy.button_index = int(binding.get("button", 0)) as JoyButton
			return joy
		"joypad_motion":
			var motion := InputEventJoypadMotion.new()
			motion.axis = int(binding.get("axis", 0)) as JoyAxis
			motion.axis_value = float(binding.get("value", 1.0))
			return motion
	_fail("Tipo de ligacao desconhecido em '%s'" % action_name)
	return null


func _keycode_from_name(n: String) -> Key:
	if n.length() == 1:
		var c := n.to_upper().unicode_at(0)
		if c >= 65 and c <= 90:
			return (KEY_A + (c - 65)) as Key
		if c >= 48 and c <= 57:
			return (KEY_0 + (c - 48)) as Key
	# F1..F12, genericamente — para nao voltar a faltar um F6.
	if n.length() >= 2 and n[0] == "F" and n.substr(1).is_valid_int():
		var fn := n.substr(1).to_int()
		if fn >= 1 and fn <= 12:
			return (KEY_F1 + (fn - 1)) as Key
	match n:
		"Space": return KEY_SPACE
		"Shift": return KEY_SHIFT
		"Ctrl", "Control": return KEY_CTRL
		"Alt": return KEY_ALT
		"Tab": return KEY_TAB
		"Escape": return KEY_ESCAPE
		"Enter", "Return": return KEY_ENTER
		"BracketLeft": return KEY_BRACKETLEFT
		"BracketRight": return KEY_BRACKETRIGHT
		"ArrowLeft": return KEY_LEFT
		"ArrowRight": return KEY_RIGHT
		"ArrowUp": return KEY_UP
		"ArrowDown": return KEY_DOWN
	return KEY_NONE


# --- Guardas de coerencia com a spec ------------------------------------------
# Falham alto (push_error) em vez de falhar em silencio. Um numero fora da spec
# e um bug critico neste prototipo: e a spec que manda.

func _validate() -> void:
	var checks := 0

	# 1. Todo o ataque inimigo tem de ter >= 0,5 s (30 f) de aviso legivel.
	const MIN_STARTUP := 30
	for enemy_id: String in enemies.keys():
		if enemy_id.begins_with("_"):
			continue
		var e: Dictionary = enemies[enemy_id]
		for atk: Variant in e.get("attacks", []):
			var a := atk as Dictionary
			if int(a.get("startup", 0)) < MIN_STARTUP:
				_fail("[SPEC] %s/%s tem arranque %d f (< %d f = 0,5 s de aviso)"
					% [enemy_id, a.get("id", "?"), int(a.get("startup", 0)), MIN_STARTUP])
			var follow: Variant = a.get("followup", null)
			if follow != null and int((follow as Dictionary).get("startup", 0)) < MIN_STARTUP:
				_fail("[SPEC] %s/%s (seguimento) tem arranque abaixo de %d f"
					% [enemy_id, a.get("id", "?"), MIN_STARTUP])
		# Fugir tem de ser sempre possivel: perseguicao abaixo do correr do jogador.
		var run_speed: float = section("movement").get("run_speed", 5.0)
		if float(e.get("chase_speed", 0.0)) >= run_speed:
			_fail("[SPEC] %s persegue a %.1f m/s (>= correr do jogador, %.1f)"
				% [enemy_id, e.get("chase_speed", 0.0), run_speed])
	checks += 1

	# 2. O brutamontes e o professor de parry: TODOS os golpes dele sao aparaveis.
	for atk: Variant in enemy("orc_brute").get("attacks", []):
		if not bool((atk as Dictionary).get("parryable", false)):
			_fail("[SPEC] orc_brute/%s nao e aparavel — todos os golpes do brutamontes tem de ser"
				% (atk as Dictionary).get("id", "?"))
	checks += 1

	# 3. Golpes-para-matar a nivel 1, Guerreiro, leve de espada longa (spec/01 + spec/11).
	var warrior := class_attributes("warrior")
	var light_mv := float((weapon("longsword")["light"] as Dictionary)["mv"])
	if not warrior.is_empty():
		_check_hits("orc_spearman", light_mv, warrior, 3, 5)
		_check_hits("orc_brute", light_mv, warrior, 6, 9)
		_check_hits("vorgar", light_mv, warrior, 45, 70)
	checks += 1

	# 4. As formulas do WP2 no exemplo resolvido (atributo 10 = o caso de referencia).
	_expect(max_health_for(10), 420.0, "formula de PV com Vida 10")
	_expect(max_stamina_for(10), 100.0, "formula de STA com Stamina 10")
	_expect(defense_for(10), 20.0, "formula de DEF com Constituicao 10")
	# A reserva usa o melhor atributo de conjuracao; a escola vermelha usa o menor
	# apenas na eficacia dos seus feiticos (spec/42 + spec/66).
	var sorcerer := class_attributes("sorcerer")
	if not sorcerer.is_empty():
		_expect(float(max_mana_for(sorcerer)), 116.0,
			"mana de arranque do Feiticeiro")
	checks += 1

	# 5. Cada classe distribui exactamente +14 pontos sobre a base 8.
	var base_v: int = attributes.get("base_value", 8)
	var bonus: int = attributes.get("class_bonus_points", 14)
	var ids: Array = attributes.get("attribute_ids", [])
	for class_id: String in (attributes.get("classes", {}) as Dictionary).keys():
		if class_id.begins_with("_"):
			continue
		var c: Dictionary = class_attributes(class_id)
		var spent := 0
		for attr_name: Variant in ids:
			spent += int(c.get(attr_name, base_v)) - base_v
		if spent != bonus:
			_fail("[SPEC] classe '%s' distribui %d pontos (a spec da %d)" % [class_id, spent, bonus])
	checks += 1

	# 6. As 12 fichas de bioma (spec/49-biomas.md): 8 linhas cada, paleta de 3
	# cores hex, e exactamente UMA na fatia 1 (Brumal). A ficha e a fonte da
	# luz e da nevoa — um campo em falta e um bioma que nao se consegue construir.
	const BIOME_FIELDS: Array[String] = ["nome", "elemento", "eficaz_contra_nativos",
		"material", "paleta", "racas", "colheita", "ameaca", "historia",
		"descricao_visual", "fatia_1"]
	var ids_b := biome_ids()
	if ids_b.size() != 12:
		_fail("[SPEC] %d biomas em biomes.json (a spec/49 diz 12)" % ids_b.size())
	var in_slice := 0
	for biome_id in ids_b:
		var b := biome(biome_id)
		for field in BIOME_FIELDS:
			if not b.has(field):
				_fail("[SPEC] bioma '%s' sem o campo '%s' (spec/49 §3)" % [biome_id, field])
		var pal: Dictionary = b.get("paleta", {}) as Dictionary
		for colour_key: String in ["luz", "nevoa", "acento"]:
			var c := String(pal.get(colour_key, ""))
			if not c.is_valid_html_color():
				_fail("[SPEC] bioma '%s': cor '%s' invalida ('%s')" % [biome_id, colour_key, c])
		if String((b.get("racas", {}) as Dictionary).get("dominante", "")) == "":
			_fail("[SPEC] bioma '%s' sem raca dominante (spec/46 §2)" % biome_id)
		if bool(b.get("fatia_1", false)):
			in_slice += 1
	if in_slice != 1:
		_fail("[SPEC] %d biomas na fatia 1 (a spec/10 diz 1 — Brumal)" % in_slice)
	checks += 1

	# 7. O laco bioma <-> raca, nos dois sentidos (spec/50 + spec/46 §4).
	# Toda a raca que um bioma aloja existe em races.json E declara esse bioma;
	# todo o bioma que uma raca habita existe em biomes.json E lista essa raca.
	# E a regra anti-mistura em codigo: um boneco sem casa nao arranca o jogo.
	const RACE_FIELDS: Array[String] = ["nome", "tipo", "papel", "origem", "quer",
		"biomas", "relacoes", "mortos", "veste", "segredo", "descricao_visual", "fatia_1"]
	const VALID_ROLES: Array[String] = ["rapido", "pesado", "distancia", "grupo", "armadilha"]
	var true_races := 0
	for race_id in race_ids():
		var r := race(race_id)
		for field in RACE_FIELDS:
			if not r.has(field):
				_fail("[SPEC] raca '%s' sem o campo '%s' (spec/50)" % [race_id, field])
		if String(r.get("tipo", "")) == "raca":
			true_races += 1
		if String(r.get("papel", "")) not in VALID_ROLES:
			_fail("[SPEC] raca '%s' com papel '%s' fora do spec/38 §6" % [race_id, r.get("papel", "")])
		var homes: Dictionary = r.get("biomas", {}) as Dictionary
		if homes.is_empty():
			_fail("[SPEC] raca '%s' sem bioma nenhum (spec/46 §5)" % race_id)
		for home: String in homes.keys():
			if biome(home).is_empty():
				_fail("[SPEC] raca '%s' habita bioma inexistente '%s'" % [race_id, home])
			else:
				var housed: Dictionary = biome(home).get("racas", {}) as Dictionary
				var listed: Array = [String(housed.get("dominante", ""))]
				listed.append_array(housed.get("secundarias", []) as Array)
				if race_id not in listed:
					_fail("[SPEC] raca '%s' diz viver em '%s', mas o bioma nao a lista" % [race_id, home])
	if true_races != 12:
		_fail("[SPEC] %d racas verdadeiras (a spec/50 diz 12; pragas nao contam)" % true_races)
	for biome_id in biome_ids():
		var housed_b: Dictionary = biome(biome_id).get("racas", {}) as Dictionary
		var all_listed: Array = [String(housed_b.get("dominante", ""))]
		all_listed.append_array(housed_b.get("secundarias", []) as Array)
		for listed_race: Variant in all_listed:
			var rr := race(String(listed_race))
			if rr.is_empty():
				_fail("[SPEC] bioma '%s' aloja raca inexistente '%s'" % [biome_id, listed_race])
			elif not (rr.get("biomas", {}) as Dictionary).has(biome_id):
				_fail("[SPEC] bioma '%s' lista '%s', mas a raca nao declara esse bioma" % [biome_id, listed_race])
	checks += 1

	# 8. WP5 camada 1 (spec/51-familias.md): familias, kits e armadura.
	# A regra do 41 §2: uma familia sem a frase "onde e ma" esta listada, nao
	# desenhada — e aqui isso e um erro, nao uma opiniao.
	var fams: Dictionary = weapons.get("familias", {}) as Dictionary
	var fam_ids: Array[String] = []
	for f: String in fams.keys():
		if not f.begins_with("_"):
			fam_ids.append(f)
	if fam_ids.size() != 8:
		_fail("[SPEC] %d familias de arma (a spec/51 §2 diz 8)" % fam_ids.size())
	for fam_id in fam_ids:
		var fam: Dictionary = fams[fam_id]
		for field: String in ["nome", "onde_boa", "onde_ma", "interrupcao", "fatia_1"]:
			if not fam.has(field):
				_fail("[SPEC] familia '%s' sem '%s' (spec/51 §2)" % [fam_id, field])
		if String(fam.get("onde_ma", "")) == "":
			_fail("[SPEC] familia '%s' sem a frase 'onde e ma' — esta listada, nao desenhada" % fam_id)

	# Toda a arma da fatia declara a familia a que pertence, e ela existe.
	for w_id: String in weapons.keys():
		if w_id.begins_with("_") or w_id in ["familias", "familias_escudo", "loadouts",
				"test_loadouts", "golpes_universais", "modificadores_de_combate"]:
			continue
		var w: Dictionary = weapons[w_id]
		if w.has("familia"):
			if not fams.has(String(w.get("familia"))):
				_fail("[SPEC] arma '%s' aponta a familia inexistente '%s'" % [w_id, w.get("familia")])
		elif not w.has("familia_escudo"):
			_fail("[SPEC] arma '%s' sem familia (spec/51 §2)" % w_id)

	# Escudos: o tecto de estabilidade e rigido — sem ele bloquear e gratis.
	var shields: Dictionary = weapons.get("familias_escudo", {}) as Dictionary
	var stab_max: float = shields.get("estabilidade_maxima", 85.0)
	for s_id: String in shields.keys():
		if s_id.begins_with("_") or typeof(shields[s_id]) != TYPE_DICTIONARY:
			continue
		if float((shields[s_id] as Dictionary).get("estabilidade", 0.0)) > stab_max:
			_fail("[SPEC] escudo '%s' passa o tecto de estabilidade %.0f (spec/51 §3)" % [s_id, stab_max])

	# Kits: nenhuma referencia fantasma, e a carga e uma das tres.
	var pieces: Dictionary = armor.get("pieces", {}) as Dictionary
	var loads: Dictionary = weapons.get("loadouts", {}) as Dictionary
	for class_id: String in loads.keys():
		if class_id.begins_with("_"):
			continue
		var kit: Dictionary = loads[class_id]
		for slot_key: String in ["main", "offhand"]:
			var wid: Variant = kit.get(slot_key, null)
			if wid != null and String(wid) != "" and not weapons.has(String(wid)):
				_fail("[SPEC] kit '%s': arma '%s' nao existe" % [class_id, wid])
		for piece: Variant in kit.get("pecas", []):
			if not pieces.has(String(piece)):
				_fail("[SPEC] kit '%s': peca '%s' nao existe em armor.json" % [class_id, piece])
		if String(kit.get("carga", "")) not in ["leve", "medio", "pesado"]:
			_fail("[SPEC] kit '%s' com carga '%s' fora das tres classes" % [class_id, kit.get("carga", "")])
		if not kit.has("pecas") or (kit.get("pecas", []) as Array).is_empty():
			_fail("[SPEC] kit '%s' sem pecas (instrucao do Rico, spec/51 §5)" % class_id)

	# Os i-frames NUNCA mudam dentro de uma esquiva. Sobrecarregado perde a
	# accao inteira, nao recebe uma janela diferente (spec/70 §1.1).
	var carga: Dictionary = armor.get("carga", {}) as Dictionary
	for load_name: String in ["leve", "medio", "pesado", "sobrecarregado"]:
		var c: Dictionary = carga.get(load_name, {}) as Dictionary
		if c.is_empty():
			_fail("[SPEC] classe de carga '%s' em falta (spec/70 §1.1)" % load_name)
		elif c.has("iframe_start_frame") or c.has("iframe_end_frame"):
			_fail("[SPEC] carga '%s' mexe nos i-frames — a Lei 1 nao deixa (spec/70 §1.1)" % load_name)
	checks += 1

	# 9. WP4 completo (spec/66): quatro escolas, 12 formas usadas, ficha de
	# honestidade e seis niveis. Isto corre no arranque normal, nao so no teste.
	var spell_ids: Array = spells.get("order", []) as Array
	var spell_schools: Dictionary = spells.get("_schools", {}) as Dictionary
	var delivery_forms: Array = spells.get("_delivery_forms", []) as Array
	var escape_vectors: Array = spells.get("_escape_vectors", []) as Array
	if spell_ids.size() != 53:
		_fail("[SPEC] %d feiticos (spec/66 diz 53)" % spell_ids.size())
	if spell_schools.size() != 4:
		_fail("[SPEC] %d escolas de magia (spec/66 diz 4)" % spell_schools.size())
	if delivery_forms.size() != 12:
		_fail("[SPEC] %d formas de entrega (spec/55 diz 12)" % delivery_forms.size())
	if escape_vectors.size() != 9:
		_fail("[SPEC] %d vectores de fuga (spec/38 diz 9)" % escape_vectors.size())
	var used_forms := {}
	var first_slice_spells: Array[String] = []
	const SPELL_FIELDS: Array[String] = ["display_name", "school", "question", "formula",
		"mana_cost", "cast_time", "delivery_form", "invalid_where", "escape_vector",
		"escape_method", "contact_type", "descricao_visual", "sound_cue", "visual_cue", "fatia_1"]
	for raw_spell_id: Variant in spell_ids:
		var spell_id := String(raw_spell_id)
		var s: Dictionary = spell(spell_id)
		for field: String in SPELL_FIELDS:
			if not s.has(field) or str(s.get(field, "")) == "":
				_fail("[SPEC] feitico '%s' sem '%s' (spec/66)" % [spell_id, field])
		if String(s.get("school", "")) not in spell_schools.keys():
			_fail("[SPEC] feitico '%s' aponta a escola inexistente '%s'" % [spell_id, s.get("school", "")])
		var form := String(s.get("delivery_form", ""))
		if form not in delivery_forms:
			_fail("[SPEC] feitico '%s' usa forma inexistente '%s'" % [spell_id, form])
		used_forms[form] = true
		var contact := String(s.get("contact_type", ""))
		if contact not in ["instantaneo", "volume_movel", "volume_persistente", "nenhum"]:
			_fail("[SPEC] feitico '%s' tem contacto invalido '%s'" % [spell_id, contact])
		elif contact != "nenhum" and String(s.get("escape_vector", "")) not in escape_vectors:
			_fail("[SPEC] feitico '%s' foge fora dos 9 vectores do spec/38" % spell_id)
		var upgrades: Array = s.get("upgrades", []) as Array
		if upgrades.size() != 6:
			_fail("[SPEC] feitico '%s' tem %d niveis de melhoria (spec/66 diz 6)" % [spell_id, upgrades.size()])
		else:
			for level: int in range(6):
				if int((upgrades[level] as Dictionary).get("level", -1)) != level:
					_fail("[SPEC] feitico '%s' tem tabela 0..5 fora de ordem" % spell_id)
			for level: int in [1, 3, 5]:
				if String((upgrades[level] as Dictionary).get("axis", "")) not in ["area", "lancamentos"]:
					_fail("[SPEC] feitico '%s' nivel %d nao abre area/lancamentos" % [spell_id, level])
		if bool(s.get("fatia_1", false)):
			first_slice_spells.append(spell_id)
	for form: Variant in delivery_forms:
		if not used_forms.has(String(form)):
			_fail("[SPEC] forma de entrega '%s' sem feitico (spec/66)" % form)
	if first_slice_spells != ["dardo", "ruina", "egide"]:
		_fail("[SPEC] Fatia 1 de magia tem %s; devia ter Dardo/Ruina/Egide" % first_slice_spells)
	var spell_rules: Dictionary = spells.get("_rules", {}) as Dictionary
	var favorites: Array = spell_rules.get("default_favorites", []) as Array
	if favorites.size() > int(spell_rules.get("favorite_limit", 0)):
		_fail("[SPEC] favoritos de fabrica excedem o limite de 8")
	for favorite: Variant in favorites:
		if not spell_ids.has(String(favorite)):
			_fail("[SPEC] favorito '%s' nao existe no catalogo" % favorite)
	checks += 1

	# 10. WP6 completo (spec/67): a ficha expandida é a fronteira de runtime.
	const CONTACT_TYPES: Array[String] = ["instantaneo", "volume_movel", "volume_persistente"]
	const ATTACK_VECTORS: Array[String] = ["sair_da_linha", "rolar_para_dentro",
		"rolar_para_fora", "afastar_se", "aproximar_se", "quebrar_a_visao",
		"sair_da_area", "aparar", "bloquear_e_aguentar"]
	var common_enemy_count := 0
	for bestiary_id: String in enemies.keys():
		if bestiary_id.begins_with("_"):
			continue
		var bestiary_enemy := enemy(bestiary_id)
		if bool(bestiary_enemy.get("is_boss", false)):
			continue
		common_enemy_count += 1
		if (bestiary_enemy.get("loot_deck", {}) as Dictionary).get("cards", []).size() != 10:
			_fail("[SPEC] '%s' sem baralho de 10 (spec/43 + spec/67)" % bestiary_id)
		if float(bestiary_enemy.get("mass_kg", 0.0)) <= 0.0 or int(bestiary_enemy.get("souls", 0)) <= 0:
			_fail("[SPEC] '%s' sem massa/almas positivas (spec/36 + spec/40)" % bestiary_id)
		var catalogue_attacks: Array = bestiary_enemy.get("attacks", []) as Array
		if catalogue_attacks.size() < 3 or catalogue_attacks.size() > 5:
			_fail("[SPEC] '%s' tem %d ataques; comum exige 3-5" % [bestiary_id, catalogue_attacks.size()])
		for catalogue_attack_value: Variant in catalogue_attacks:
			var catalogue_attack := catalogue_attack_value as Dictionary
			var label := "%s/%s" % [bestiary_id, catalogue_attack.get("id", "?")]
			if String(catalogue_attack.get("tipo_contacto", "")) not in CONTACT_TYPES:
				_fail("[SPEC] %s sem tipo de contacto valido" % label)
			var attack_vectors: Array = catalogue_attack.get("vectores_fuga", []) as Array
			if attack_vectors.is_empty() or attack_vectors.size() > 2:
				_fail("[SPEC] %s precisa de 1-2 vectores de fuga" % label)
			for vector: Variant in attack_vectors:
				if String(vector) not in ATTACK_VECTORS:
					_fail("[SPEC] %s usa vector inexistente '%s'" % [label, vector])
			var cue: Dictionary = catalogue_attack.get("sinal_visual_equivalente", {}) as Dictionary
			for cue_field: String in ["ancora", "forma", "inicio", "compromisso", "fim", "fora_ecra"]:
				if String(cue.get(cue_field, "")) == "":
					_fail("[SPEC] %s: equivalente visual sem '%s'" % [label, cue_field])
	if common_enemy_count != 33:
		_fail("[SPEC] bestiario tem %d tipos comuns; spec/67 fecha 33" % common_enemy_count)
	if (enemies.get("_zone_budgets", {}) as Dictionary).size() != 12:
		_fail("[SPEC] bestiario sem orcamento de almas para as 12 zonas")
	checks += 1

	# 11. WP5 completo (spec/68): catálogo fechado e todas as promessas do
	# bestiário resolvem. A validação duplica de propósito a fronteira do teste:
	# uma build normal também se recusa a arrancar com espólio fantasma.
	var catalogue_weapons: Dictionary = equipment.get("weapons", {}) as Dictionary
	var catalogue_armor: Dictionary = equipment.get("armor", {}) as Dictionary
	var catalogue_rings: Dictionary = equipment.get("rings", {}) as Dictionary
	if catalogue_weapons.size() != 120:
		_fail("[SPEC] catálogo WP5 tem %d armas; spec/68 diz 120" % catalogue_weapons.size())
	if catalogue_armor.size() != 68:
		_fail("[SPEC] catálogo WP5 tem %d armaduras; spec/68 diz 68" % catalogue_armor.size())
	if catalogue_rings.size() != 70:
		_fail("[SPEC] catálogo WP5 tem %d anéis; spec/68 diz 70" % catalogue_rings.size())
	for catalogue: Dictionary in [catalogue_weapons, catalogue_armor, catalogue_rings]:
		for item_id: String in catalogue.keys():
			var item := catalogue[item_id] as Dictionary
			if String(item.get("descricao_visual", "")).length() < 40:
				_fail("[SPEC] item '%s' sem descrição visual gerável" % item_id)
			if typeof(item.get("fatia_1")) != TYPE_BOOL:
				_fail("[SPEC] item '%s' sem Fatia 1? booleana" % item_id)

	var family_movesets: Dictionary = equipment.get("family_movesets", {}) as Dictionary
	const REQUIRED_STRIKES: Array[String] = ["leve", "pesado", "cadeia", "leve_para_pesado",
		"em_corrida", "a_rolar", "a_saltar", "de_cima", "empurrao", "arte_1mao", "arte_2maos"]
	if family_movesets.size() != 8:
		_fail("[SPEC] catálogo WP5 sem os oito movesets")
	for family_id: String in family_movesets.keys():
		var moveset := family_movesets[family_id] as Dictionary
		for strike: String in REQUIRED_STRIKES:
			if not moveset.has(strike) or (moveset[strike] as Dictionary).is_empty():
				_fail("[SPEC] família '%s' sem golpe '%s'" % [family_id, strike])

	var improvement_levels: Array = (equipment.get("weapon_improvement", {}) as Dictionary).get("levels", []) as Array
	if improvement_levels.size() != 7:
		_fail("[SPEC] melhoria de arma não declara base + seis níveis")
	for level: int in range(improvement_levels.size()):
		var improvement := improvement_levels[level] as Dictionary
		if int(improvement.get("level", -1)) != level or bool(improvement.get("increases_base_damage", true)):
			_fail("[SPEC] melhoria %d fora de ordem ou compra força" % level)

	var status_effects: Dictionary = equipment.get("status_effects", {}) as Dictionary
	for status_id: String in ["veneno", "sangramento", "queimadura"]:
		var status := status_effects.get(status_id, {}) as Dictionary
		if String(status.get("applies_to", "")) != "jogador_e_inimigo":
			_fail("[SPEC] estado '%s' não é simétrico" % status_id)
		for status_field: String in ["meter_max", "decay", "trigger", "effect", "escape", "visual_cue"]:
			if str(status.get(status_field, "")) == "":
				_fail("[SPEC] estado '%s' sem '%s'" % [status_id, status_field])

	var ring_axes: Dictionary = {}
	var ring_effects: Dictionary = {}
	for ring_id: String in catalogue_rings.keys():
		var catalogue_ring := catalogue_rings[ring_id] as Dictionary
		ring_axes[String(catalogue_ring.get("eixo", ""))] = true
		var ring_effect := String(catalogue_ring.get("efeito", ""))
		if ring_effects.has(ring_effect):
			_fail("[SPEC] anel '%s' repete um efeito" % ring_id)
		ring_effects[ring_effect] = true
		if catalogue_ring.has("input_action"):
			_fail("[SPEC] anel '%s' consome tecla" % ring_id)
		if float((catalogue_ring.get("numeros", {}) as Dictionary).get("max_percent", 0.0)) > 10.0:
			_fail("[SPEC] anel '%s' passa o tecto de 10%%" % ring_id)
	if ring_axes.size() != 8:
		_fail("[SPEC] os anéis só cobrem %d/8 eixos" % ring_axes.size())

	for loot_enemy_id: String in enemies.keys():
		if loot_enemy_id.begins_with("_") or bool(enemy(loot_enemy_id).get("is_boss", false)):
			continue
		for loot_card_value: Variant in enemy(loot_enemy_id).get("loot_cards", []):
			var split: PackedStringArray = String(loot_card_value).split(":", false, 1)
			if split.size() != 2:
				continue
			if split[0] == "arma" and not catalogue_weapons.has(split[1]):
				_fail("[SPEC] espólio arma '%s' não resolve" % split[1])
			elif split[0] == "armadura" and not catalogue_armor.has(split[1]):
				_fail("[SPEC] espólio armadura '%s' não resolve" % split[1])
			elif split[0] == "anel" and not catalogue_rings.has(split[1]):
				_fail("[SPEC] espólio anel '%s' não resolve" % split[1])
	checks += 1

	# 12. WP8 completo (spec/69): a leitura vem antes do traçado e a rede só
	# arranca se todas as zonas fecharem os dois círculos e as 30 portas tiverem
	# razão visível. Isto impede que o catálogo markdown se afaste do runtime.
	var map_reading: Dictionary = world.get("map_reading", {}) as Dictionary
	if not bool(map_reading.get("decided_before_layout", false)):
		_fail("[SPEC] WP8 traçado sem leitura do mapa decidida primeiro")
	if String(map_reading.get("projection", "")) != "inclinada_40_graus":
		_fail("[SPEC] WP8 perdeu a vista inclinada do spec/57 §5")
	if String(map_reading.get("reveal_rule", "")) != "apenas_terreno_percorrido":
		_fail("[SPEC] WP8 mapa revela conteúdo antes da descoberta")
	if not String(map_reading.get("scope_decision", "")).contains("donos"):
		_fail("[SPEC] WP8 decidiu à socapa mapa por zona vs mundo inteiro")

	var world_zones: Dictionary = world.get("zones", {}) as Dictionary
	var history_doors: Dictionary = world.get("history_doors", {}) as Dictionary
	var world_connections: Array = world.get("connections", []) as Array
	if world_zones.size() != 12:
		_fail("[SPEC] catálogo WP8 tem %d zonas; spec/69 diz 12" % world_zones.size())
	if history_doors.size() != 30:
		_fail("[SPEC] catálogo WP8 tem %d portas de história; spec/69 diz 30" % history_doors.size())
	if world_connections.size() < 16:
		_fail("[SPEC] catálogo WP8 tem %d ligações e parece linear" % world_connections.size())
	var world_slice_count := 0
	var history_door_counts: Dictionary = {}
	var adjacency: Dictionary = {}
	for biome_id: String in biome_ids():
		adjacency[biome_id] = []
		var zone: Dictionary = world_zones.get(biome_id, {}) as Dictionary
		if zone.is_empty():
			_fail("[SPEC] bioma '%s' sem traçado em world.json" % biome_id)
			continue
		for field: String in ["nome", "biome_id", "traversal", "encounter_curve",
				"rest_points", "landmarks", "horizontal_loop", "vertical_loop", "shortcut",
				"dungeon", "environmental_threat", "connections", "descricao_visual",
				"concept_art", "fatia_1"]:
			if not zone.has(field) or str(zone.get(field, "")) == "":
				_fail("[SPEC] zona '%s' sem '%s' (spec/69)" % [biome_id, field])
		if String(zone.get("biome_id", "")) != biome_id:
			_fail("[SPEC] zona '%s' aponta ao bioma '%s'" % [biome_id, zone.get("biome_id", "")])
		var traversal_minutes := int((zone.get("traversal", {}) as Dictionary).get("clean_minutes", 0))
		if traversal_minutes < 8 or traversal_minutes > 12:
			_fail("[SPEC] zona '%s' mede %d min; spec/53 exige 8-12" % [biome_id, traversal_minutes])
		var encounter_curve: Dictionary = zone.get("encounter_curve", {}) as Dictionary
		if int(encounter_curve.get("common", 0)) < 12 or int(encounter_curve.get("common", 0)) > 20:
			_fail("[SPEC] zona '%s' fora dos 12-20 encontros comuns" % biome_id)
		if int(encounter_curve.get("elites", 0)) < 3 or int(encounter_curve.get("elites", 0)) > 5:
			_fail("[SPEC] zona '%s' fora das 3-5 elites" % biome_id)
		if int(encounter_curve.get("named", 0)) < 2 or int(encounter_curve.get("named", 0)) > 3:
			_fail("[SPEC] zona '%s' fora dos 2-3 nomeados" % biome_id)
		var zone_rests: Array = zone.get("rest_points", []) as Array
		if zone_rests.size() < 2 or zone_rests.size() > 3:
			_fail("[SPEC] zona '%s' tem %d descansos; spec/53 exige 2-3" % [biome_id, zone_rests.size()])
		for loop_key: String in ["horizontal_loop", "vertical_loop", "shortcut"]:
			var loop: Dictionary = zone.get(loop_key, {}) as Dictionary
			if String(loop.get("opens_from", "")) != "interior":
				_fail("[SPEC] %s/%s não abre do lado de dentro" % [biome_id, loop_key])
			if String(loop.get("descricao_visual", "")).length() < 40 or typeof(loop.get("fatia_1")) != TYPE_BOOL:
				_fail("[SPEC] %s/%s sem descrição visual/Fatia 1?" % [biome_id, loop_key])
		if int((zone.get("vertical_loop", {}) as Dictionary).get("height_gain_m", 0)) < 4:
			_fail("[SPEC] zona '%s' não fecha círculo vertical real" % biome_id)
		if (zone.get("connections", []) as Array).size() < 2:
			_fail("[SPEC] zona '%s' só tem uma direcção" % biome_id)
		if not FileAccess.file_exists(String(zone.get("concept_art", ""))):
			_fail("[SPEC] zona '%s' sem conceito visual arquivado" % biome_id)
		if bool(zone.get("fatia_1", false)):
			world_slice_count += 1
	if world_slice_count != 1 or not bool((world_zones.get("brumal", {}) as Dictionary).get("fatia_1", false)):
		_fail("[SPEC] Fatia 1 do mundo não é apenas Brumal")

	for connection_value: Variant in world_connections:
		var connection := connection_value as Dictionary
		var from_id := String(connection.get("from", ""))
		var to_id := String(connection.get("to", ""))
		if not world_zones.has(from_id) or not world_zones.has(to_id) or from_id == to_id:
			_fail("[SPEC] ligação WP8 inválida '%s' -> '%s'" % [from_id, to_id])
			continue
		(adjacency[from_id] as Array).append(to_id)
		(adjacency[to_id] as Array).append(from_id)
		if (connection.get("loads", []) as Array).size() != 2:
			_fail("[SPEC] ligação %s/%s tenta carregar mais que os dois vizinhos" % [from_id, to_id])
		if String(connection.get("descricao_visual", "")).length() < 40 or typeof(connection.get("fatia_1")) != TYPE_BOOL:
			_fail("[SPEC] ligação %s/%s sem descrição visual/Fatia 1?" % [from_id, to_id])
	var reached: Dictionary = {"brumal": true}
	var frontier: Array[String] = ["brumal"]
	while not frontier.is_empty():
		var current: String = String(frontier.pop_front())
		for neighbour_value: Variant in adjacency.get(current, []):
			var neighbour := String(neighbour_value)
			if not reached.has(neighbour):
				reached[neighbour] = true
				frontier.append(neighbour)
	if reached.size() != 12:
		_fail("[SPEC] rede WP8 só liga %d/12 biomas" % reached.size())

	for door_id: String in history_doors.keys():
		var history_door := history_doors[door_id] as Dictionary
		for field: String in ["nome", "biome_id", "form", "what_exists_now",
				"reason_is_legible", "future_slot", "witness", "descricao_visual", "fatia_1"]:
			if not history_door.has(field) or str(history_door.get(field, "")) == "":
				_fail("[SPEC] porta '%s' sem '%s'" % [door_id, field])
		var door_biome := String(history_door.get("biome_id", ""))
		if not world_zones.has(door_biome):
			_fail("[SPEC] porta '%s' aponta a zona inexistente '%s'" % [door_id, door_biome])
		history_door_counts[door_biome] = int(history_door_counts.get(door_biome, 0)) + 1
		if bool(history_door.get("fatia_1", true)):
			_fail("[SPEC] porta de história '%s' invadiu a Fatia 1" % door_id)
	for biome_id: String in world_zones.keys():
		var count := int(history_door_counts.get(biome_id, 0))
		if count < 2 or count > 3:
			_fail("[SPEC] zona '%s' tem %d portas; spec/53 exige 2-3" % [biome_id, count])
	checks += 1

	# 13. Tarefa 4: os 36 encontros nomeados e todos os IDs economicos que os
	# baralhos prometem existem de verdade. O runtime tambem faz esta auditoria
	# para uma carta nova nunca poder criar espolio fantasma.
	var named_entries: Dictionary = named_catalog.get("encounters", {}) as Dictionary
	var named_counts_by_zone: Dictionary = {}
	if named_entries.size() != 36:
		_fail("[SPEC] encontros nomeados: %d/36" % named_entries.size())
	for named_id: String in named_entries.keys():
		var named: Dictionary = named_entries[named_id] as Dictionary
		var named_zone := String(named.get("zone_id", ""))
		var base_enemy_id := String(named.get("base_enemy_id", ""))
		var base_enemy := enemy(base_enemy_id)
		if not world_zones.has(named_zone):
			_fail("[SPEC] nomeado '%s' aponta a zona inexistente '%s'" % [named_id, named_zone])
		if base_enemy.is_empty() or bool(base_enemy.get("is_boss", false)):
			_fail("[SPEC] nomeado '%s' nao reutiliza um inimigo comum" % named_id)
		elif not (base_enemy.get("biome_ids", []) as Array).has(named_zone):
			_fail("[SPEC] nomeado '%s' desloca '%s' para fora do bioma" % [named_id, base_enemy_id])
		named_counts_by_zone[named_zone] = int(named_counts_by_zone.get(named_zone, 0)) + 1
		var health_multiplier := float(named.get("health_multiplier", 0.0))
		var posture_multiplier := float(named.get("posture_multiplier", 0.0))
		if health_multiplier < 1.25 or health_multiplier > 1.55 \
				or posture_multiplier < 1.10 or posture_multiplier > 1.30:
			_fail("[SPEC] nomeado '%s' sai da faixa curta de PV/postura" % named_id)
		var extra_attack: Dictionary = named.get("extra_attack", {}) as Dictionary
		for named_attack_field: String in ["id", "display_name", "startup", "active",
				"recovery", "parryable", "vector", "tell"]:
			if not extra_attack.has(named_attack_field) or str(extra_attack.get(named_attack_field, "")) == "":
				_fail("[SPEC] ataque extra de '%s' sem '%s'" % [named_id, named_attack_field])
		if int(extra_attack.get("startup", 0)) < 30:
			_fail("[SPEC] ataque extra de '%s' tem aviso inferior a 30 f" % named_id)
		if String(extra_attack.get("vector", "")) not in ATTACK_VECTORS:
			_fail("[SPEC] ataque extra de '%s' usa vector inexistente" % named_id)
		var named_reward_parts: PackedStringArray = String(named.get(
			"guaranteed_loot", "")).split(":", false, 1)
		if named_reward_parts.size() != 2:
			_fail("[SPEC] nomeado '%s' sem carta garantida" % named_id)
		elif named_reward_parts[0] == "material" and material(named_reward_parts[1]).is_empty():
			_fail("[SPEC] nomeado '%s' promete material inexistente" % named_id)
		elif named_reward_parts[0] == "consumivel" and consumable(named_reward_parts[1]).is_empty():
			_fail("[SPEC] nomeado '%s' promete consumivel inexistente" % named_id)
	for named_zone: String in world_zones.keys():
		if int(named_counts_by_zone.get(named_zone, 0)) != 3:
			_fail("[SPEC] zona '%s' tem %d/3 nomeados" % [
				named_zone, int(named_counts_by_zone.get(named_zone, 0))])

	var materials: Dictionary = economy.get("materials", {}) as Dictionary
	var consumables: Dictionary = economy.get("consumables", {}) as Dictionary
	if materials.size() != 40:
		_fail("[SPEC] economia tem %d/40 materiais" % materials.size())
	if consumables.size() != 15:
		_fail("[SPEC] economia tem %d/15 consumiveis canonicos" % consumables.size())
	for material_id: String in materials.keys():
		var material_entry: Dictionary = materials[material_id] as Dictionary
		if not world_zones.has(String(material_entry.get("zone_id", ""))):
			_fail("[SPEC] material '%s' sem zona valida" % material_id)
		if int(material_entry.get("refinement", 0)) not in [1, 2, 3] \
				or int(material_entry.get("trade_value", 0)) <= 0:
			_fail("[SPEC] material '%s' sem valor/refinamento" % material_id)
		if String(material_entry.get("visual", "")).length() < 40:
			_fail("[SPEC] material '%s' sem descricao visual" % material_id)
	for consumable_id: String in consumables.keys():
		var consumable_entry: Dictionary = consumables[consumable_id] as Dictionary
		if (consumable_entry.get("effect", {}) as Dictionary).is_empty() \
				or float(consumable_entry.get("use_seconds", 0.0)) <= 0.0:
			_fail("[SPEC] consumivel '%s' sem efeito/tempo exacto" % consumable_id)
		if String(consumable_entry.get("visual", "")).length() < 30 \
				or String(consumable_entry.get("sound", "")).length() < 10:
			_fail("[SPEC] consumivel '%s' sem leitura visual/sonora" % consumable_id)
	for loot_enemy_id: String in enemies.keys():
		if loot_enemy_id.begins_with("_") or bool(enemy(loot_enemy_id).get("is_boss", false)):
			continue
		for promised_card_value: Variant in enemy(loot_enemy_id).get("loot_cards", []):
			var promised_card := String(promised_card_value)
			var promised_parts: PackedStringArray = promised_card.split(":", false, 1)
			if promised_parts.size() != 2:
				continue
			if promised_parts[0] == "material" and not materials.has(promised_parts[1]):
				_fail("[SPEC] carta '%s' promete material fantasma" % promised_card)
			elif promised_parts[0] == "consumivel" and consumable(promised_parts[1]).is_empty():
				_fail("[SPEC] carta '%s' promete consumivel fantasma" % promised_card)
			elif promised_card == "consumivel:brasa_portatil":
				_fail("[SPEC] Brasa voltou a um baralho repetivel")
	var bias_by_zone: Dictionary = ((economy.get("class_bias", {}) as Dictionary).get(
		"by_zone", {}) as Dictionary)
	for bias_zone_id: String in world_zones.keys():
		var bias_pool: Dictionary = bias_by_zone.get(bias_zone_id, {}) as Dictionary
		for profile: String in ["martial", "arcane"]:
			var bias_card := String(bias_pool.get(profile, ""))
			var bias_parts: PackedStringArray = bias_card.split(":", false, 1)
			if bias_parts.size() != 2 or bias_parts[0] != "material" or not materials.has(bias_parts[1]):
				_fail("[SPEC] enviesamento %s/%s nao resolve" % [bias_zone_id, profile])
	if level_cost(20) != 2601 or level_cost(40) != 9505 \
			or level_cost(70) != 28351 or level_cost(100) != 60265:
		_fail("[SPEC] curva cubica de almas divergiu dos marcos publicados")
	checks += 1

	# 14. Tarefa 4.4: fronteiras que antes eram assumidas e agora são dados.
	var enemy_spell_rule: Dictionary = (enemies.get("_rules", {}) as Dictionary).get(
		"enemy_spellcasting", {}) as Dictionary
	for shared_rule: String in ["forma_de_entrega", "tell", "momento_de_compromisso",
			"hitbox_visivel", "elemento", "interrupcao", "cue_audio_visual", "vectores_de_fuga"]:
		if not (enemy_spell_rule.get("shares_with_player", []) as Array).has(shared_rule):
			_fail("[SPEC] magia inimiga não partilha '%s' com a ficha de ataque" % shared_rule)
	if String(enemy_spell_rule.get("enemy_resource", "")) == "" \
			or String(enemy_spell_rule.get("interrupt_rule", "")) == "":
		_fail("[SPEC] magia inimiga sem recurso/interrupção explícitos")

	var traversal: Dictionary = world.get("_traversal_rules", {}) as Dictionary
	for absent_verb: String in ["free_swimming", "free_climbing", "free_traversal_jump"]:
		if bool(traversal.get(absent_verb, true)):
			_fail("[SPEC] travessia reabriu o verbo '%s'" % absent_verb)
	if not is_equal_approx(float(traversal.get("automatic_step_max_m", 0.0)), 0.45):
		_fail("[SPEC] passo automático deixou de ser 0,45 m")
	var subboss: Dictionary = world.get("_subboss_rules", {}) as Dictionary
	for subboss_field: String in ["on_flee", "on_defeat", "on_new_zone_cycle", "presentation"]:
		if String(subboss.get(subboss_field, "")) == "":
			_fail("[SPEC] ciclo de subchefe sem '%s'" % subboss_field)

	const REQUIRED_UI_TEXTS: Array[String] = ["hud.help", "hud.info", "hud.boss",
		"toast.start", "toast.reward", "toast.loot_exhausted", "toast.reward_save_failed",
		"toast.death", "toast.respawn", "toast.boss_defeated", "toast.arena_reset",
		"toast.class_changed"]
	for text_id: String in REQUIRED_UI_TEXTS:
		if ui_text(text_id) == "":
			_fail("[SPEC] texto obrigatório '%s' não está no catálogo português" % text_id)
	var remote_heal: Dictionary = spell("elo_curador")
	var remote_heal_effect: Dictionary = remote_heal.get("effect", {}) as Dictionary
	var remote_heal_network: Dictionary = remote_heal.get("network_contract", {}) as Dictionary
	if not is_equal_approx(float(remote_heal_effect.get(
			"heal_target_max_health_fraction", 0.0)), 0.30) \
			or bool(remote_heal_effect.get("can_resurrect", true)):
		_fail("[SPEC] Elo Curador deixou de curar 30% sem ressuscitar")
	if String(remote_heal_network.get("channel", "")) != "reliable_ordered_gameplay" \
			or String(remote_heal_network.get("deduplication", "")) == "":
		_fail("[SPEC] cura remota sem canal fiável/ordem/idempotência")

	var control_actions: Dictionary = controls.get("actions", {}) as Dictionary
	for required_action_value: Variant in controls.get("gamepad_required", []):
		var required_action := String(required_action_value)
		var has_primary := false
		var has_gamepad := false
		for binding_value: Variant in control_actions.get(required_action, []):
			var binding := binding_value as Dictionary
			var binding_type := String(binding.get("type", ""))
			has_primary = has_primary or binding_type in ["key", "mouse"]
			has_gamepad = has_gamepad or binding_type in ["joypad_button", "joypad_motion"]
		if not has_primary or not has_gamepad:
			_fail("[SPEC] acção nuclear '%s' não é agnóstica da fonte" % required_action)
	checks += 1

	if load_errors.is_empty():
		print("[GameData] dados carregados — %d grupos de verificacoes contra a spec passaram" % checks)
	else:
		printerr("[GameData] %d PROBLEMAS DE COERENCIA COM A SPEC" % load_errors.size())


func _check_hits(enemy_id: String, mv: float, attrs: Dictionary, lo: int, hi: int) -> void:
	var e := enemy(enemy_id)
	var per_hit := compute_damage(mv, "longsword", attrs, float(e.get("defense", 0.0)))
	if per_hit <= 0.0:
		_fail("[SPEC] dano nulo contra %s" % enemy_id)
		return
	var hits := int(ceil(float(e.get("health", 0.0)) / per_hit))
	if hits < lo or hits > hi:
		_fail("[SPEC] %s morre em %d leves de espada (a spec exige %d-%d)" % [enemy_id, hits, lo, hi])


func _expect(got: float, want: float, what: String) -> void:
	if absf(got - want) > 0.01:
		_fail("[SPEC] %s deu %.1f, a spec diz %.1f" % [what, got, want])


func ability(class_id: String) -> Dictionary:
	return abilities.get(class_id, {}) as Dictionary


func biome(id: String) -> Dictionary:
	return biomes.get(id, {}) as Dictionary


## Ids reais dos biomas (ignora as chaves "_meta" do JSON).
func biome_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in biomes.keys():
		if not k.begins_with("_"):
			out.append(k)
	return out


func race(id: String) -> Dictionary:
	return races.get(id, {}) as Dictionary


## Ids reais das racas (ignora as chaves "_meta" do JSON).
func race_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in races.keys():
		if not k.begins_with("_"):
			out.append(k)
	return out


# --- Estado persistente (spec/59-saves.md) -----------------------------------

func replace_save_state(state: Dictionary) -> void:
	save_state = state.duplicate(true)


func save_state_snapshot() -> Dictionary:
	return save_state.duplicate(true)
