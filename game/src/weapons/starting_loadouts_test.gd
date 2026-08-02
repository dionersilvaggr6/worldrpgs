extends SceneTree
## Teste isolado RED/GREEN dos kits iniciais.
## Corre com:
##   godot --headless --audio-driver Dummy --path game/ \
##     --script res://src/weapons/starting_loadouts_test.gd

const StartingLoadoutsContract := preload("res://src/weapons/starting_loadouts.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Scripts executados por --script sao compilados antes dos nomes globais dos
	# autoloads; os Nodes continuam na raiz e sao a fronteira publica equivalente.
	var game_data := root.get_node_or_null("GameData")
	var save_system := root.get_node_or_null("SaveSystem")
	if game_data == null or save_system == null:
		printerr("[STARTING LOADOUTS] autoloads GameData/SaveSystem indisponiveis")
		quit(1)
		return
	var errors: Array[String] = StartingLoadoutsContract.contract_errors(
			game_data.weapons, game_data.equipment, game_data.attributes)
	var checks := 1
	var loadouts := game_data.weapons.get("loadouts", {}) as Dictionary
	for origin_id: String in StartingLoadoutsContract.active_origin_ids(game_data.weapons):
		checks += 3
		var loadout := loadouts.get(origin_id, {}) as Dictionary
		var expected_main := String(loadout.get("main", ""))
		var save: Dictionary = save_system.create_save(
				"starting-test-%s" % origin_id, origin_id)
		var character := save.get("character", {}) as Dictionary
		var inventory := character.get("inventory", {}) as Dictionary
		var equipment := inventory.get("equipment", {}) as Dictionary
		var items := inventory.get("items", {}) as Dictionary
		if String(equipment.get("main", "")) != expected_main:
			errors.append("save de %s nao equipa a arma inicial" % origin_id)
		if int(items.get("arma:%s" % expected_main, 0)) < 1:
			errors.append("save de %s nao recebe a arma no inventario" % origin_id)
		if String((character.get("identity", {}) as Dictionary).get(
				"class_id", "")) != origin_id:
			errors.append("save de %s perdeu a origem escolhida" % origin_id)

	if errors.is_empty():
		print("=== STARTING LOADOUTS: %d passaram, 0 falharam ===" % checks)
		quit(0)
		return
	for error: String in errors:
		printerr("[STARTING LOADOUTS] " + error)
	printerr("=== STARTING LOADOUTS: 0 passaram, %d falharam ===" % errors.size())
	quit(1)
