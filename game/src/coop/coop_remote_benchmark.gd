extends Node
## A/B repetivel do custo visual do proxy co-op no mundo de combate real.
## `Bench` recolhe fps/p95/p99; este wrapper muda uma unica variavel:
## `--coop-proxy=off|on`.

const GAMEPLAY_SCENE: PackedScene = preload("res://scenes/gameplay.tscn")
const PROOF_SLOT_BASE := 910000000

var _proof_slot := 0
var _gameplay: Node
var _remote: CoopRemotePlayer
var _elapsed := 0.0


func _ready() -> void:
	_proof_slot = PROOF_SLOT_BASE + (OS.get_process_id() % 100000)
	SaveSystem.active_slot = _proof_slot
	var class_ids := GameShell.CLASS_IDS
	if class_ids.is_empty():
		push_error("[coop-benchmark] catalogo sem origens")
		get_tree().quit(1)
		return
	GameData.replace_save_state(SaveSystem.create_save(
		"benchmark-coop-%d" % OS.get_process_id(), class_ids[0], {
			"name": "Benchmark", "appearance": {},
		}))
	_gameplay = GAMEPLAY_SCENE.instantiate()
	add_child(_gameplay)
	if _argument_value("--coop-proxy=") == "on":
		var actor := _gameplay.get("player") as Player
		_remote = CoopRemotePlayer.new()
		_gameplay.add_child(_remote)
		_remote.setup(class_ids[-1], actor.get("_palette") as Dictionary)
		_remote.apply_pose({
			"position": actor.global_position + Vector3(2.0, 0.0, 0.0),
			"yaw": actor.rotation.y,
			"state": Player.State.FREE,
			"frame": 0,
			"health_fraction": 1.0,
		})


func _process(delta: float) -> void:
	if not is_instance_valid(_remote) or not is_instance_valid(_gameplay):
		return
	var actor := _gameplay.get("player") as Player
	if actor == null:
		return
	_elapsed += delta
	var offset := Vector3(cos(_elapsed) * 2.0, 0.0, sin(_elapsed) * 2.0)
	_remote.apply_pose({
		"position": actor.global_position + offset,
		"yaw": atan2(-offset.x, -offset.z),
		"state": Player.State.FREE,
		"frame": 0,
		"health_fraction": 1.0,
	})


func _exit_tree() -> void:
	GameData.replace_save_state({})
	var base_path := SaveSystem.slot_path(_proof_slot)
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(base_path + suffix))


func _argument_value(prefix: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			return argument.trim_prefix(prefix)
	return ""
