class_name CoopPlayerRuntime
extends Node
## Liga a camada de rede ao Player e ao mundo reais sem obrigar `main.gd` a
## conhecer ENet. E a ponta que faltava ao contrato do PR #20:
##
##   Player local -> NetSession.local_body -> fio -> partner_body -> corpo visual.

const REMOTE_PLAYER_SCRIPT = preload("res://src/coop/coop_remote_player.gd")

var _session: Node
var _local_player: Player
var _remote_player: CoopRemotePlayer
var _remote_peer_id := 0


func setup(session: Node) -> void:
	_session = session
	_session.peer_disconnected.connect(_on_peer_disconnected)
	_session.session_ended.connect(_on_session_ended)
	_session.peer_profile_received.connect(_on_peer_profile_received)
	get_tree().node_added.connect(_on_node_added)
	get_tree().node_removed.connect(_on_node_removed)
	_find_existing_local_player()


func _exit_tree() -> void:
	if get_tree() != null:
		if get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.disconnect(_on_node_added)
		if get_tree().node_removed.is_connected(_on_node_removed):
			get_tree().node_removed.disconnect(_on_node_removed)


func _process(_delta: float) -> void:
	if not is_instance_valid(_local_player):
		_find_existing_local_player()
	if not is_instance_valid(_local_player):
		_clear_remote_player()
		return
	_sync_local_profile()
	if _session == null or not bool(_session.call("is_online")):
		_clear_remote_player()
		return
	_publish_local_pose()
	var partner_id := int(_session.call("partner_id"))
	if partner_id == 0:
		_clear_remote_player()
		return
	var profile := _session.call("partner_profile") as Dictionary
	if profile.is_empty():
		_clear_remote_player()
		return
	if not is_instance_valid(_remote_player) or _remote_peer_id != partner_id \
			or _remote_player.class_id != String(profile.get("class_id", "")) \
			or _remote_player.body_id != String(profile.get("body_id", "")):
		_spawn_remote_player(partner_id, profile)
	if not is_instance_valid(_remote_player):
		return
	var pose := _session.call("partner_body") as Dictionary
	_remote_player.apply_pose(pose)


func _publish_local_pose() -> void:
	var flags := 0
	if _local_player.state == Player.State.BLOCK:
		flags |= NetProtocol.BodyFlag.BLOCKING
	if _local_player.state == Player.State.DEAD:
		flags |= NetProtocol.BodyFlag.DEAD
	if is_instance_valid(_local_player.lock_on) and _local_player.lock_on.target != null:
		flags |= NetProtocol.BodyFlag.LOCKED_ON
	_session.set("local_body", {
		"position": _local_player.global_position,
		"yaw": _local_player.rotation.y,
		"state": _local_player.state,
		"frame": _local_player.state_frame,
		"health_fraction": _local_player.health / maxf(_local_player.max_health, 1.0),
		"flags": flags,
	})


func _sync_local_profile() -> void:
	var character := GameData.save_state.get("character", {}) as Dictionary
	var identity := character.get("identity", {}) as Dictionary
	var appearance := identity.get("appearance", {}) as Dictionary
	var profile := {
		"protocol_version": NetProtocol.VERSION,
		"profile_id": String(character.get("profile_id", "local-player")),
		"class_id": _local_player.class_id,
		"body_id": String(appearance.get("body_id", "body_male")),
	}
	if (_session.get("local_profile") as Dictionary) == profile:
		return
	_session.call("set_local_profile", profile)


func _spawn_remote_player(peer_id: int, profile: Dictionary) -> void:
	_clear_remote_player()
	var parent := _local_player.get_parent()
	if parent == null:
		return
	_remote_player = REMOTE_PLAYER_SCRIPT.new() as CoopRemotePlayer
	_remote_peer_id = peer_id
	parent.add_child(_remote_player)
	var palette := _local_player.get("_palette") as Dictionary
	_remote_player.setup(String(profile.get("class_id", "")), palette,
		String(profile.get("body_id", "body_male")))


func _clear_remote_player() -> void:
	_remote_peer_id = 0
	if is_instance_valid(_remote_player):
		_remote_player.queue_free()
	_remote_player = null


func _find_existing_local_player() -> void:
	for node: Node in get_tree().get_nodes_in_group("coop_local_player"):
		if node is Player:
			_bind_local_player(node as Player)
			return
	var root := get_tree().root
	if root == null:
		return
	for node: Node in root.find_children("*", "Player", true, false):
		if _is_local_player_candidate(node):
			_bind_local_player(node as Player)
			return


func _bind_local_player(player: Player) -> void:
	if _local_player == player:
		return
	_clear_remote_player()
	_local_player = player
	_local_player.add_to_group("coop_local_player")


func _on_node_added(node: Node) -> void:
	if _is_local_player_candidate(node):
		_bind_local_player(node as Player)


func _is_local_player_candidate(node: Node) -> bool:
	if not node is Player or node.is_in_group("coop_remote_player"):
		return false
	var parent := node.get_parent()
	if parent != null:
		for property: Dictionary in parent.get_property_list():
			if String(property.get("name", "")) == "player":
				return parent.get("player") == node
	return node.name == "Player"


func _on_node_removed(node: Node) -> void:
	if node == _local_player:
		_local_player = null
		_clear_remote_player()


func _on_peer_disconnected(_peer_id: int) -> void:
	_clear_remote_player()


func _on_session_ended(_reason: String) -> void:
	_clear_remote_player()


func _on_peer_profile_received(peer_id: int, _profile: Dictionary) -> void:
	if peer_id == _remote_peer_id:
		_clear_remote_player()
