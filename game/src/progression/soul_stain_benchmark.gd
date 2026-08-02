extends SceneTree
## Injecta o pior caso de manchas na cena pedida ao Bench. O proprio Bench mede
## e publica adapter, resolucao, FPS, percentis, draw calls e memoria.

const SoulStainScript = preload("res://src/progression/soul_stain.gd")


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	var scene := load("res://scenes/gameplay.tscn") as PackedScene
	if scene == null:
		printerr("[soul-stain-bench] gameplay.tscn nao carregou")
		quit(1)
		return
	var main := scene.instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var game_data := root.get_node_or_null("GameData")
	var player := main.get("player") as Node3D
	if game_data == null or player == null:
		printerr("[soul-stain-bench] runtime nao ficou pronto")
		quit(1)
		return
	var progression_data: Dictionary = game_data.get("progression") as Dictionary
	var presentation: Dictionary = ((progression_data.get("soul_stain", {}) as Dictionary).get(
		"presentation", {}) as Dictionary)
	var stain_count := int(presentation.get("benchmark_max_simultaneous_stains", 0))
	for index: int in stain_count:
		var offset := Vector3(float(index * 2 - 1) * 1.5, 0.0, -2.5)
		var position := player.global_position + offset
		var stain := SoulStainScript.new()
		player.add_child(stain)
		stain.configure({
			"stain_id": "benchmark:%d" % index,
			"amount": 0,
			"zone_id": "brumal",
			"position": [position.x, position.y, position.z],
			"death_sequence": index,
		})
		stain.monitoring = false
	print("[soul-stain-bench] %d manchas injectadas" % stain_count)
