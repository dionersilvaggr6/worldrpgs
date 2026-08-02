class_name CoopAuthority
extends RefCounted
## Fronteira de autoridade da spec/19. Nao transporta pacotes: decide apenas
## quem pode publicar cada familia de evento antes de um adaptador ENet/local.

const HOST_WORLD_EVENTS := {
	&"encounter_attention": true,
	&"encounter_commitment": true,
	&"encounter_opening": true,
	&"encounter_damage": true,
	&"encounter_defeated": true,
	&"resurrection_progress": true,
	&"resurrection_completed": true,
}

const BODY_OWNER_EVENTS := {
	&"body_state": true,
	&"local_hit_report": true,
	&"interact_hold": true,
	&"local_dodge_report": true,
	&"local_parry_report": true,
}

const SUMMON_EVENT := &"summon_command"

var _host_profile_id := StringName()
var _body_owner_by_profile: Dictionary = {}
var _summon_policy := Callable()


func configure(host_profile_id: StringName, body_owner_by_profile: Dictionary,
		summon_policy := Callable()) -> bool:
	_host_profile_id = StringName()
	_body_owner_by_profile.clear()
	_summon_policy = Callable()
	if host_profile_id == StringName() or body_owner_by_profile.is_empty():
		return false
	var normalized_owners: Dictionary = {}
	for profile_value: Variant in body_owner_by_profile:
		var profile_id := StringName(String(profile_value))
		var owner_id := StringName(String(body_owner_by_profile[profile_value]))
		if profile_id == StringName() or owner_id == StringName():
			return false
		normalized_owners[profile_id] = owner_id
	_host_profile_id = host_profile_id
	_body_owner_by_profile = normalized_owners
	_summon_policy = summon_policy
	return true


func set_summon_policy(policy: Callable) -> void:
	# [TENSAO] 35: sem fallback. Os donos podem injectar "quem levantou" ou
	# "anfitriao" sem alterar os restantes dominios de autoridade.
	_summon_policy = policy


func can_publish(sender_profile_id: StringName, event: Dictionary) -> bool:
	var event_type := StringName(String(event.get("type", "")))
	if HOST_WORLD_EVENTS.has(event_type):
		return sender_profile_id == _host_profile_id
	if BODY_OWNER_EVENTS.has(event_type):
		var subject_id := StringName(String(event.get("subject_profile_id", "")))
		return _body_owner_by_profile.get(subject_id, StringName()) == sender_profile_id
	if event_type == SUMMON_EVENT:
		return _summon_policy.is_valid() and bool(_summon_policy.call(sender_profile_id, event))
	return false


func host_profile_id() -> StringName:
	return _host_profile_id
