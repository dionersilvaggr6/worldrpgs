class_name CoopRemotePlayer
extends Node3D
## Representacao visual do corpo que pertence ao outro processo.
##
## Nao simula combate nem colisao: a spec/19 da autoridade ao dono do corpo.
## Este no apenas apresenta a pose interpolada que `NetSession` recebeu.

var health_fraction := 1.0
var remote_state := Player.State.FREE
var remote_state_frame := 0
var class_id := ""
var body_id := ""
var _visual: CharacterVisual
var _last_position := Vector3.ZERO
var _has_pose := false


func setup(class_id: String, _palette: Dictionary, body_id := "body_male") -> void:
	self.class_id = class_id
	self.body_id = body_id
	name = "CoopPartner"
	add_to_group("coop_remote_player")
	visible = false
	_visual = CharacterVisual.new()
	_visual.name = "Visual"
	add_child(_visual)
	var height := float(GameData.section("player").get("capsule_height", 1.8))
	_visual.setup(height, Color.WHITE, true, body_id, class_id)


func apply_pose(pose: Dictionary) -> void:
	if pose.is_empty():
		return
	var next_position := pose.get("position", global_position) as Vector3
	var moved := _has_pose and next_position.distance_squared_to(_last_position) > 0.0001
	global_position = next_position
	rotation.y = float(pose.get("yaw", rotation.y))
	visible = true
	health_fraction = clampf(float(pose.get("health_fraction", 1.0)), 0.0, 1.0)
	remote_state = int(pose.get("state", Player.State.FREE))
	remote_state_frame = int(pose.get("frame", 0))
	_refresh_animation(moved)
	_last_position = next_position
	_has_pose = true


func _refresh_animation(moved: bool) -> void:
	if not is_instance_valid(_visual):
		return
	match remote_state:
		Player.State.DEAD:
			_visual.play_state_animation("player", "death")
		Player.State.DODGE:
			_visual.play_state_animation("player", "dodge")
		Player.State.ATTACK:
			_visual.play_state_animation("player", "attack")
		Player.State.BLOCK:
			_visual.play_state_animation("player", "block")
		Player.State.PARRY:
			_visual.play_state_animation("player", "parry")
		Player.State.CASTING:
			_visual.play_state_animation("player", "casting_idle")
		_:
			_visual.play_state_animation("player", "jog" if moved else "idle")
