class_name IntroSequence
extends Node
## Fronteira da abertura jogável.
##
## A sequência nunca desactiva o input, não cria um ecrã de prólogo e não sabe
## números de combate. O anfitrião decide onde ficam as batidas no mundo; este
## nó resolve texto, controlos remapeados, apresentação única e autoria por ID.

signal cue_shown(cue_id: String)

const LOCATION_SECONDS := 3.0
const TIP_SECONDS := 4.0

var _hud: Node


## Começa já dentro do mundo. O HUD é o único colaborador necessário e o
## jogador conserva movimento/câmara durante toda a apresentação.
func begin(hud: Node) -> bool:
	if hud == null or not hud.has_method("toast") or not hud.has_method("context_tip"):
		push_error("IntroSequence precisa de um HUD com toast() e context_tip().")
		return false
	var game_data := _autoload("GameData")
	if game_data == null:
		push_error("IntroSequence não encontrou o catálogo GameData.")
		return false
	_hud = hud
	var intro := game_data.get("ui_strings").get("intro", {}) as Dictionary
	_hud.call("toast", game_data.call("ui_text", String(intro.get(
		"location_string_id", ""))), LOCATION_SECONDS)
	request_tip("movement", false)
	return true


## O anfitrião chama isto na batida posicional já definida em spec/27. Passar
## in_combat=true adia a linha: nenhuma dica nasce durante uma troca de golpes.
func request_tip(tip_id: String, in_combat: bool) -> bool:
	var game_data := _autoload("GameData")
	if in_combat or game_data == null or tip_id not in tip_ids(
			game_data.get("ui_strings")) or not is_instance_valid(_hud):
		return false
	var settings := _autoload("SettingsSystem")
	if settings == null or not bool(settings.call("context_tips_enabled")) \
			or bool(settings.call("tip_seen", tip_id)):
		return false
	var message := tip_text(tip_id)
	if message == "":
		push_error("Texto obrigatório da abertura em falta: intro.tip.%s" % tip_id)
		return false
	settings.call("mark_tip_seen", tip_id)
	_hud.call("context_tip", message, TIP_SECONDS)
	cue_shown.emit(tip_id)
	return true


static func tip_text(tip_id: String) -> String:
	var game_data := _autoload("GameData")
	var settings := _autoload("SettingsSystem")
	if game_data == null or settings == null:
		return ""
	var template := String(game_data.call("ui_text", "intro.tip.%s" % tip_id))
	if template == "":
		return ""
	match tip_id:
		"movement":
			return template % [
				settings.call("binding_label", "move_forward"),
				settings.call("binding_label", "move_back"),
				settings.call("binding_label", "move_left"),
				settings.call("binding_label", "move_right"),
			]
		"attack":
			return template % settings.call("binding_label", "attack")
		"dodge":
			return template % settings.call("binding_label", "dodge_sprint")
		"parry":
			return template % settings.call("binding_label", "parry")
		"flask":
			return template % settings.call("binding_label", "use_item")
	return ""


## Só devolve descrição se o ID continuar a existir no catálogo mecânico. Assim
## uma renomeação não deixa lore órfã a parecer um item real.
static func item_description(item_id: String) -> String:
	var game_data := _autoload("GameData")
	if game_data == null or item_id not in starting_weapon_ids(game_data.get("weapons")):
		return ""
	var weapon: Variant = game_data.call("weapon", item_id)
	if not weapon is Dictionary or (weapon as Dictionary).is_empty():
		return ""
	return String(game_data.call("ui_text", "item.weapon.%s.description" % item_id))


static func _autoload(autoload_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(autoload_name)


static func tip_ids(strings_catalog: Dictionary) -> Array[String]:
	return _string_array((strings_catalog.get("intro", {}) as Dictionary).get("tip_ids", []))


static func owner_question_slots(strings_catalog: Dictionary) -> Array[String]:
	return _string_array((strings_catalog.get("intro", {}) as Dictionary).get(
		"owner_question_slots", []))


static func starting_weapon_ids(weapons_catalog: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var loadouts := weapons_catalog.get("loadouts", {}) as Dictionary
	for origin_value: Variant in loadouts.keys():
		var origin_id := String(origin_value)
		if origin_id.begins_with("_"):
			continue
		var loadout := loadouts.get(origin_id, {}) as Dictionary
		for slot_id: String in ["main", "offhand"]:
			var item_id := str(loadout.get(slot_id, ""))
			var item := weapons_catalog.get(item_id, {}) as Dictionary
			if not item_id.is_empty() and item.has("display_name") and item_id not in result:
				result.append(item_id)
	result.sort()
	return result


static func required_string_ids(strings_catalog: Dictionary,
		weapons_catalog: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var intro := strings_catalog.get("intro", {}) as Dictionary
	result.append(String(intro.get("location_string_id", "")))
	for tip_id: String in tip_ids(strings_catalog):
		result.append("intro.tip.%s" % tip_id)
	for item_id: String in starting_weapon_ids(weapons_catalog):
		result.append("item.weapon.%s.description" % item_id)
	return result


static func _string_array(values: Variant) -> Array[String]:
	var result: Array[String] = []
	if not values is Array:
		return result
	for value: Variant in values as Array:
		result.append(String(value))
	return result


## Validação pura para o teste dedicado e para futuros clientes. Recebe os
## catálogos crus para não depender da árvore de autoload durante CI isolado.
static func contract_errors(strings_catalog: Dictionary, weapons_catalog: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var strings: Dictionary = strings_catalog.get("strings", {}) as Dictionary
	if owner_question_slots(strings_catalog).is_empty():
		errors.append("a abertura não reserva as perguntas dos donos no catálogo")
	if tip_ids(strings_catalog).is_empty():
		errors.append("a abertura não declara batidas de aprendizagem no catálogo")
	for string_id: String in required_string_ids(strings_catalog, weapons_catalog):
		if String(strings.get(string_id, "")).strip_edges() == "":
			errors.append("texto obrigatório em falta: %s" % string_id)
	for item_id: String in starting_weapon_ids(weapons_catalog):
		if not weapons_catalog.has(item_id):
			errors.append("descrição sem item no catálogo: %s" % item_id)
	return errors
