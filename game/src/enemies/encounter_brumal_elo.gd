class_name EncounterBrumalElo
extends Enemy
## Brutamontes co-op do spec/19. Um jogador segura a atencao; so o outro
## consegue ferir depois do compromisso. Um acerto aceite troca os papeis.

signal hit_blocked(attacker_profile_id: StringName, target_profile_id: StringName)
signal opening_used(attacker_profile_id: StringName, previous_target_profile_id: StringName)

const EloRules = preload("res://src/coop/coop_elo_rules.gd")
const REQUIRED_PARTICIPANTS := EloRules.REQUIRED_PARTICIPANTS

var _participants: Dictionary = {}
var _profile_by_instance: Dictionary = {}
var _openings_by_profile: Dictionary = {}
var _opening_consumed := false
var _last_attack_frame := 0


func configure_participants(participants: Dictionary) -> bool:
	_participants.clear()
	_profile_by_instance.clear()
	_openings_by_profile.clear()
	if participants.size() != REQUIRED_PARTICIPANTS:
		return false
	for profile_value: Variant in participants:
		var profile_id := StringName(String(profile_value))
		var body := participants[profile_value] as Node3D
		if profile_id == StringName() or body == null \
				or _profile_by_instance.has(body.get_instance_id()):
			_participants.clear()
			_profile_by_instance.clear()
			return false
		_participants[profile_id] = body
		_profile_by_instance[body.get_instance_id()] = profile_id
	return true


func can_accept_damage_from(attacker: Node3D) -> bool:
	_refresh_attack_boundary()
	var alive_by_profile: Dictionary = {}
	for profile_value: Variant in _participants:
		var profile_id := StringName(String(profile_value))
		alive_by_profile[profile_id] = _body_alive(_participants[profile_value] as Node3D)
	return EloRules.can_accept_damage(_profile_for(attacker), _profile_for(target),
		alive_by_profile, _attack_is_committed(), _opening_consumed)


func take_damage(info: DamageInfo) -> void:
	var attacker := info.attacker
	if not can_accept_damage_from(attacker):
		if attacker != null and _profile_by_instance.has(attacker.get_instance_id()):
			Sfx.play("hit_block", global_position)
			hit_blocked.emit(_profile_for(attacker), _profile_for(target))
		return

	_opening_consumed = true
	var previous_target := _profile_for(target)
	var attacker_profile := _profile_for(attacker)
	var lethal_still_locked := info.amount >= health \
		and not EloRules.lethal_is_unlocked(_openings_by_profile, attacker_profile)
	_openings_by_profile[attacker_profile] = true
	if lethal_still_locked:
		Sfx.play("hit_block", global_position)
		target = attacker
		opening_used.emit(attacker_profile, previous_target)
		return
	super(info)
	if state != State.DEAD:
		target = attacker
	opening_used.emit(attacker_profile, previous_target)


func _change_state(next: int) -> void:
	if next != State.ATTACK or state != State.ATTACK:
		_opening_consumed = false
	_last_attack_frame = 0
	super(next)


func full_reset() -> void:
	_opening_consumed = false
	_last_attack_frame = 0
	_openings_by_profile.clear()
	super()


func _attack_is_committed() -> bool:
	if state != State.ATTACK or _atk.is_empty() or not _atk.has("startup") \
			or not _atk.has("active"):
		return false
	return _atk_frame > int(_atk.get("startup")) + int(_atk.get("active"))


func _refresh_attack_boundary() -> void:
	# Follow-ups podem reiniciar o frame sem sair de ATTACK.
	if state != State.ATTACK:
		_opening_consumed = false
	elif _atk_frame < _last_attack_frame:
		_opening_consumed = false
	_last_attack_frame = _atk_frame


func _body_alive(body: Node3D) -> bool:
	return body != null and body.has_method("is_alive") and bool(body.call("is_alive"))


func _profile_for(body: Node3D) -> StringName:
	if body == null:
		return StringName()
	return _profile_by_instance.get(body.get_instance_id(), StringName())
