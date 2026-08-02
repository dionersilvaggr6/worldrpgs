class_name SoulStain
extends Area3D
## Mancha criada no ponto exacto da morte. A apresentacao e sintetizada e a
## recolha acontece ao chegar com o corpo; nao existe uma tecla escondida.

signal recovered(result: Dictionary)
signal recovery_failed(result: Dictionary)

const ProgressionRuntime = preload("res://src/progression/progression_runtime.gd")
const ProgressionAudio = preload("res://src/progression/progression_audio.gd")

var collected := false
var stain_id := ""
var souls_amount := 0
var _recovery_callback := Callable()
var _elapsed := 0.0
var _material: StandardMaterial3D
var _light: OmniLight3D
var _mesh: MeshInstance3D
var _audio: AudioStreamPlayer3D
var _presentation: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func configure(stain: Dictionary, recovery_callback := Callable()) -> void:
	stain_id = String(stain.get("stain_id", ""))
	souls_amount = maxi(0, int(stain.get("amount", 0)))
	_recovery_callback = recovery_callback
	var position_data: Array = stain.get("position", []) as Array
	if position_data.size() == 3:
		global_position = Vector3(float(position_data[0]), float(position_data[1]),
			float(position_data[2]))
	_presentation = _progression_config("soul_stain").get(
		"presentation", {}) as Dictionary
	_build_presentation()


func try_recover() -> Dictionary:
	if collected:
		return {"status": "already_collected", "stain_id": stain_id}
	if stain_id.is_empty():
		return {"status": "invalid"}
	var result: Dictionary
	if _recovery_callback.is_valid():
		result = _recovery_callback.call(stain_id) as Dictionary
	else:
		result = ProgressionRuntime.commit_soul_stain_recovery(stain_id)
	if String(result.get("status", "")) != "recovered":
		recovery_failed.emit(result)
		return result
	collected = true
	monitoring = false
	monitorable = false
	if _mesh != null:
		_mesh.visible = false
	if _light != null:
		_light.visible = false
	# Uma callback injectada pertence a prova isolada; o runtime real usa a
	# fronteira por defeito e toca a confirmacao espacial.
	if _audio != null and not _recovery_callback.is_valid():
		_audio.play()
	recovered.emit(result)
	return result


func _process(delta: float) -> void:
	if collected or _material == null:
		return
	_elapsed += delta
	var pulse_hz := float(_presentation.get("pulse_hz", 0.0))
	var low := float(_presentation.get("emission_min", 0.0))
	var high := float(_presentation.get("emission_max", low))
	var phase := (sin(_elapsed * TAU * pulse_hz) + 1.0) * 0.5
	_material.emission_energy_multiplier = lerpf(low, high, phase)


func _on_body_entered(body: Node3D) -> void:
	if body == null or body.is_in_group("enemies"):
		return
	try_recover()


func _build_presentation() -> void:
	if _mesh != null:
		return
	var radius := float(_presentation.get("radius_m", 0.0))
	var height := float(_presentation.get("height_m", 0.0))
	var color := Color(String(_presentation.get("color", "#FFFFFF")))
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(color, 0.55)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = float(_presentation.get("emission_min", 0.0))
	_mesh = MeshInstance3D.new()
	_mesh.name = "SoulStainMesh"
	_mesh.mesh = cylinder
	_mesh.material_override = _material
	add_child(_mesh)

	_light = OmniLight3D.new()
	_light.name = "SoulStainLight"
	_light.light_color = color
	_light.light_energy = float(_presentation.get("light_energy", 0.0))
	_light.omni_range = float(_presentation.get("light_range_m", 0.0))
	_light.shadow_enabled = false
	add_child(_light)

	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = maxf(height, radius)
	var collision := CollisionShape3D.new()
	collision.name = "SoulStainCollision"
	collision.shape = shape
	add_child(collision)
	collision_layer = 0
	collision_mask = 1

	_audio = AudioStreamPlayer3D.new()
	_audio.name = "SoulStainAudio"
	_audio.stream = ProgressionAudio.make_chirp(
		_presentation.get("pickup_audio", {}) as Dictionary)
	_audio.volume_db = float((_presentation.get("pickup_audio", {}) as Dictionary).get(
		"volume_db", 0.0))
	_audio.bus = "Efeitos"
	add_child(_audio)
func _progression_config(section_name: String) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {}
	var game_data := tree.root.get_node_or_null("GameData")
	if game_data == null:
		return {}
	var progression_data: Dictionary = game_data.get("progression") as Dictionary
	return progression_data.get(section_name, {}) as Dictionary
