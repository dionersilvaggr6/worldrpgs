extends SceneTree
## Teste isolado da fronteira narrativa.
## Correr: godot --headless --path game --script res://src/ui/intro_selftest.gd

const IntroSequenceScript = preload("res://src/ui/intro_sequence.gd")

var _errors: Array[String] = []
var _runtime_checked := false


func _initialize() -> void:
	var strings := _load_json("res://data/strings.pt.json")
	var weapons := _load_json("res://data/weapons.json")
	_errors = IntroSequenceScript.contract_errors(strings, weapons)


func _process(_delta: float) -> bool:
	if not _runtime_checked:
		_runtime_checked = true
		var game_data := root.get_node_or_null("GameData")
		if game_data == null:
			_errors.append("GameData indisponível no teste runtime da abertura")
			quit(1)
			return true
		for tip_id: String in IntroSequenceScript.tip_ids(game_data.ui_strings):
			if IntroSequenceScript.tip_text(tip_id) == "":
				_errors.append("dica não resolve controlos em runtime: %s" % tip_id)
		for item_id: String in IntroSequenceScript.starting_weapon_ids(game_data.weapons):
			if IntroSequenceScript.item_description(item_id) == "":
				_errors.append("descrição não resolve catálogo em runtime: %s" % item_id)
	if _errors.is_empty():
		print("INTRO_SELFTEST: 28/28 passaram")
		return true
	for error: String in _errors:
		push_error("INTRO_SELFTEST: %s" % error)
	quit(1)
	return true


func _finalize() -> void:
	pass


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
