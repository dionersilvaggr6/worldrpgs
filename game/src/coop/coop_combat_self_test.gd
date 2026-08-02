extends SceneTree
## Prova local honesta do Elo de Bruma. Nao cria peer ENet nem afirma rede.
## Correr: godot --headless --audio-driver Dummy --path game/ --script \
##   res://src/coop/coop_combat_self_test.gd

const AuthorityScript = preload("res://src/net/coop_authority.gd")
const CoordinatorScript = preload("res://src/coop/coop_encounter_coordinator.gd")
const EloRules = preload("res://src/coop/coop_elo_rules.gd")
const ResurrectionScript = preload("res://src/coop/coop_resurrection.gd")

const PROFILE_HOST := &"veterano"
const PROFILE_GUEST := &"aprendiz"

var _passed := 0
var _failed := 0


class LocalFighter extends RefCounted:
	signal died
	var alive := true
	var revived_state: Dictionary = {}

	func is_alive() -> bool:
		return alive

	func fall() -> void:
		alive = false
		died.emit()

	func revive_from_coop(health_fraction: float, keeps_current_flasks: bool) -> void:
		alive = true
		revived_state = {
			"health_fraction": health_fraction,
			"keeps_current_flasks": keeps_current_flasks,
		}


class LocalEncounter extends RefCounted:
	var participants: Dictionary = {}

	func configure_participants(value: Dictionary) -> bool:
		if value.size() != EloRules.REQUIRED_PARTICIPANTS:
			return false
		participants = value.duplicate()
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("\n=== AUTO-TESTE CO-OP LOCAL ===\n")
	_test_encounter_requires_two()
	_test_less_skilled_player_saves_attempt()
	_test_resurrection_policy_stays_open()
	_test_authority_without_summon_decision()
	_benchmark_hot_path()
	print("\n=== %d passaram, %d falharam (dois personagens locais; rede nao provada) ===\n" \
		% [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_encounter_requires_two() -> void:
	var brute: Dictionary = _json("res://data/enemies.json").get("orc_brute", {}) as Dictionary
	var damage: Dictionary = brute.get("damage", {}) as Dictionary
	var hit_amount := float(damage.get("light"))
	var remaining_health := float(brute.get("health"))
	var alive := {PROFILE_HOST: true, PROFILE_GUEST: true}
	var target := PROFILE_HOST

	_check(not EloRules.can_accept_damage(PROFILE_HOST, target, alive, true, false),
		"Elo: o alvo actual nao consegue causar dano")
	_check(EloRules.can_accept_damage(PROFILE_GUEST, target, alive, true, false),
		"Elo: o nao-alvo fere durante o compromisso")
	_check(not EloRules.can_accept_damage(PROFILE_GUEST, target, alive, false, false),
		"Elo: fora do compromisso nem o parceiro abre dano")

	var openings_by_profile := {PROFILE_HOST: 0, PROFILE_GUEST: 0}
	while remaining_health > 0.0:
		var attacker: StringName = PROFILE_GUEST if target == PROFILE_HOST else PROFILE_HOST
		if not EloRules.can_accept_damage(attacker, target, alive, true, false):
			break
		remaining_health = maxf(remaining_health - hit_amount, 0.0)
		openings_by_profile[attacker] = int(openings_by_profile[attacker]) + 1
		target = attacker
	_check(is_zero_approx(remaining_health)
		and int(openings_by_profile[PROFILE_HOST]) > 0
		and int(openings_by_profile[PROFILE_GUEST]) > 0,
		"Elo: trocar a atencao obriga ambos a criar aberturas ate vencer")
	_check(not EloRules.can_accept_damage(PROFILE_HOST, PROFILE_HOST,
		{PROFILE_HOST: true}, true, false),
		"Elo: um corpo nunca consegue derrotar o encontro co-op")
	_check(not EloRules.lethal_is_unlocked({}, PROFILE_GUEST)
		and EloRules.lethal_is_unlocked({PROFILE_GUEST: true}, PROFILE_HOST),
		"Elo: golpe mortal espera uma abertura criada por cada perfil")
	var encounter_source := FileAccess.get_file_as_string(
		"res://src/enemies/encounter_brumal_elo.gd")
	_check(encounter_source.contains("EloRules.can_accept_damage"),
		"Elo: o inimigo real delega na mesma regra provada")


func _test_less_skilled_player_saves_attempt() -> void:
	var veteran := LocalFighter.new()
	var apprentice := LocalFighter.new()
	var participants := {PROFILE_HOST: veteran, PROFILE_GUEST: apprentice}
	var encounter := LocalEncounter.new()
	var resurrection_config := _resurrection_config()
	var channel_range: Array = resurrection_config.get("channel_seconds_range", []) as Array
	var channel_seconds := float(channel_range.front())
	var coordinator := CoordinatorScript.new()
	_check(coordinator.configure(participants, encounter, resurrection_config, channel_seconds,
		ResurrectionScript.POLICY_CUMULATIVE),
		"salvamento: controlador usa os dois corpos e progression.json")

	veteran.fall()
	var one_alive := {PROFILE_HOST: false, PROFILE_GUEST: true}
	_check(not EloRules.can_accept_damage(PROFILE_HOST, PROFILE_GUEST,
		one_alive, true, false)
		and not EloRules.can_accept_damage(PROFILE_GUEST, PROFILE_GUEST,
			one_alive, true, false),
		"salvamento: com um caido o combate fica bloqueado ate ao resgate")

	var contribution := channel_seconds / float(participants.size())
	var first := coordinator.hold_interact(PROFILE_GUEST, PROFILE_HOST, contribution)
	var interrupted := coordinator.interrupt_by_damage(PROFILE_GUEST, PROFILE_HOST)
	_check(String(first.get("status")) == "progress"
		and float(interrupted.get("progress_seconds")) > 0.0,
		"salvamento: dano interrompe o toque sem apagar o progresso [PROTO]")
	var second := coordinator.hold_interact(PROFILE_GUEST, PROFILE_HOST, contribution)
	_check(String(second.get("status")) == "revived" and veteran.is_alive()
		and is_equal_approx(float(veteran.revived_state.get("health_fraction")),
			float(resurrection_config.get("revived_health_fraction"))),
		"salvamento: aprendiz levanta veterano e salva a tentativa")

	apprentice.fall()
	var exhausted := coordinator.hold_interact(PROFILE_HOST, PROFILE_GUEST, channel_seconds)
	_check(String(exhausted.get("status")) == "exhausted",
		"salvamento: a utilizacao partilhada nao cria vidas infinitas")
	coordinator.close()


func _test_resurrection_policy_stays_open() -> void:
	var config := _resurrection_config()
	var channel_range: Array = config.get("channel_seconds_range", []) as Array
	var channel_seconds := float(channel_range.front())
	var reset_model := ResurrectionScript.new()
	_check(reset_model.configure(config, channel_seconds,
		ResurrectionScript.POLICY_RESET_ON_INTERRUPT)
		and reset_model.begin_attempt([PROFILE_HOST, PROFILE_GUEST])
		and reset_model.down(PROFILE_HOST),
		"tensao 60: politica historica tambem configura sem mudar codigo")
	reset_model.contribute(PROFILE_GUEST, PROFILE_HOST,
		channel_seconds / float(EloRules.REQUIRED_PARTICIPANTS))
	var interrupted := reset_model.interrupt(PROFILE_GUEST, PROFILE_HOST)
	_check(is_zero_approx(float(interrupted.get("progress_seconds"))),
		"tensao 60: reset_on_interrupt apaga progresso quando for a decisao")

	var expiry_model := ResurrectionScript.new()
	expiry_model.configure(config, channel_seconds, ResurrectionScript.POLICY_CUMULATIVE)
	expiry_model.begin_attempt([PROFILE_HOST, PROFILE_GUEST])
	expiry_model.down(PROFILE_HOST)
	expiry_model.advance(float(config.get("window_seconds")))
	var expired := expiry_model.contribute(PROFILE_GUEST, PROFILE_HOST, channel_seconds)
	_check(String(expired.get("status")) == "expired",
		"salvamento: a janela termina e recusa ressurreicao tardia")


func _test_authority_without_summon_decision() -> void:
	var authority := AuthorityScript.new()
	_check(authority.configure(PROFILE_HOST,
		{PROFILE_HOST: PROFILE_HOST, PROFILE_GUEST: PROFILE_GUEST}),
		"autoridade: sessao conhece anfitriao e dono de cada corpo")
	var world_event := {"type": &"encounter_attention"}
	_check(authority.can_publish(PROFILE_HOST, world_event)
		and not authority.can_publish(PROFILE_GUEST, world_event),
		"autoridade: so o anfitriao publica mundo/inimigo")
	var body_event := {"type": &"body_state", "subject_profile_id": PROFILE_GUEST}
	_check(authority.can_publish(PROFILE_GUEST, body_event)
		and not authority.can_publish(PROFILE_HOST, body_event),
		"autoridade: cada jogador publica o proprio corpo")

	var summon_event := {
		"type": AuthorityScript.SUMMON_EVENT,
		"summon_owner_profile_id": PROFILE_GUEST,
	}
	_check(not authority.can_publish(PROFILE_GUEST, summon_event),
		"tensao 35: sem politica, comando de invocado e recusado")
	authority.set_summon_policy(func(sender: StringName, event: Dictionary) -> bool:
		return sender == StringName(String(event.get("summon_owner_profile_id", ""))))
	_check(authority.can_publish(PROFILE_GUEST, summon_event),
		"tensao 35: politica 'quem levantou' encaixa")
	authority.set_summon_policy(func(sender: StringName, _event: Dictionary) -> bool:
		return sender == authority.host_profile_id())
	_check(authority.can_publish(PROFILE_HOST, summon_event),
		"tensao 35: politica 'anfitriao' tambem encaixa")
	# A lambda do anfitriao captura `authority`; limpar desfaz o ciclo do teste.
	authority.set_summon_policy(Callable())


func _benchmark_hot_path() -> void:
	var alive := {PROFILE_HOST: true, PROFILE_GUEST: true}
	var iterations := 100000
	var started := Time.get_ticks_usec()
	for _index in iterations:
		EloRules.can_accept_damage(PROFILE_GUEST, PROFILE_HOST, alive, true, false)
	var elapsed := Time.get_ticks_usec() - started
	print("[custo] %d validacoes O(1): %d us; %.3f us/evento; 0 actores/draw calls novos" \
		% [iterations, elapsed, float(elapsed) / float(iterations)])


func _resurrection_config() -> Dictionary:
	var progression := _json("res://data/progression.json")
	return (progression.get("coop_resurrection", {}) as Dictionary).duplicate(true)


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok    %s" % label)
	else:
		_failed += 1
		push_error("  FALHA %s" % label)
