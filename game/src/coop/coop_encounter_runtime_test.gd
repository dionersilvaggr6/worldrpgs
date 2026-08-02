extends Node
## Smoke do adaptador real Enemy -> regra do Elo, com dois corpos locais.

var _passed := 0
var _failed := 0


class LocalFighter extends Node3D:
	var alive := true

	func is_alive() -> bool:
		return alive


func _ready() -> void:
	print("\n=== SMOKE DO INIMIGO CO-OP LOCAL ===\n")
	var veteran := LocalFighter.new()
	var apprentice := LocalFighter.new()
	add_child(veteran)
	add_child(apprentice)
	var participants := {&"veterano": veteran, &"aprendiz": apprentice}
	var guard := EncounterBrumalElo.new()
	add_child(guard)
	_configure_guard(guard)
	_check(guard.configure_participants(participants),
		"runtime: subclasse aceita exactamente dois corpos")

	var attack := _first_attack()
	guard.target = veteran
	_set_attack_frame(guard, attack, false)
	var health_before := guard.health
	guard.take_damage(_damage_from(veteran, health_before / float(participants.size())))
	_check(is_equal_approx(guard.health, health_before),
		"runtime: golpe do alvo e bloqueado")
	guard.take_damage(_damage_from(apprentice, health_before / float(participants.size())))
	_check(is_equal_approx(guard.health, health_before),
		"runtime: parceiro nao rouba abertura durante a hitbox activa")

	_set_attack_frame(guard, attack, true)
	guard.take_damage(_damage_from(apprentice, health_before / float(participants.size())))
	_check(guard.health < health_before and guard.target == apprentice,
		"runtime: parceiro fere na recuperacao e recebe a atencao")

	var lethal_guard := EncounterBrumalElo.new()
	add_child(lethal_guard)
	_configure_guard(lethal_guard)
	lethal_guard.configure_participants(participants)
	lethal_guard.target = veteran
	_set_attack_frame(lethal_guard, attack, true)
	lethal_guard.take_damage(_damage_from(apprentice, lethal_guard.health))
	_check(lethal_guard.state != Enemy.State.DEAD and lethal_guard.target == apprentice,
		"runtime: primeiro perfil nao mata num golpe antes da troca")
	lethal_guard._change_state(Enemy.State.CHASE)
	_set_attack_frame(lethal_guard, attack, true)
	lethal_guard.take_damage(_damage_from(veteran, lethal_guard.health))
	_check(lethal_guard.state == Enemy.State.DEAD,
		"runtime: golpe mortal resolve depois de ambos criarem abertura")

	veteran.alive = false
	guard._change_state(Enemy.State.CHASE)
	_set_attack_frame(guard, attack, true)
	_check(not guard.can_accept_damage_from(veteran),
		"runtime: parceiro caido bloqueia a progressao do encontro")
	print("\n=== %d passaram, %d falharam (Enemy real; dois corpos locais) ===\n" \
		% [_passed, _failed])
	guard.free()
	lethal_guard.free()
	veteran.free()
	apprentice.free()
	# O smoke termina antes do `hit_block` sintetizado acabar. Parar o player
	# evita confundir playback ainda vivo com fuga do encontro.
	for audio_node: Node in Sfx.get_children():
		if audio_node is AudioStreamPlayer:
			(audio_node as AudioStreamPlayer).stop()
			(audio_node as AudioStreamPlayer).stream = null
		elif audio_node is AudioStreamPlayer3D:
			(audio_node as AudioStreamPlayer3D).stop()
			(audio_node as AudioStreamPlayer3D).stream = null
	get_tree().quit(0 if _failed == 0 else 1)


func _configure_guard(guard: EncounterBrumalElo) -> void:
	var brute := GameData.enemy("orc_brute")
	guard.enemy_id = "orc_brute"
	guard.data = brute
	guard.max_health = float(brute.get("health"))
	guard.health = guard.max_health
	guard.max_posture = float(brute.get("posture"))
	guard.posture = guard.max_posture


func _first_attack() -> Dictionary:
	var attacks: Array = GameData.enemy("orc_brute").get("attacks", []) as Array
	return (attacks.front() as Dictionary).duplicate(true)


func _set_attack_frame(guard: EncounterBrumalElo, attack: Dictionary,
		in_recovery: bool) -> void:
	guard._atk = attack
	guard._change_state(Enemy.State.ATTACK)
	guard._atk_frame = int(attack.get("startup")) + int(attack.get("active"))
	if in_recovery:
		guard._atk_frame += 1


func _damage_from(attacker: Node3D, amount: float) -> DamageInfo:
	return DamageInfo.make(amount, attacker, "light")


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % label)
	else:
		_failed += 1
		push_error("  FALHA %s" % label)
