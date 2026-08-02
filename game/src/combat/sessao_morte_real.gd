extends "res://src/tools/sessao_de_jogo.gd"
## Prova de sessao para a regra mais basica do combate: um inimigo com os PV
## completos morre exclusivamente por comandos de ataque do jogador.

const MAX_ATTACKS := 6
const RETREAT_FRAMES := 120
const ATTACK_TIMEOUT_FRAMES := 180

var _inimigos_mortos := 0
var _morte_observada := false


func _passo_inimigos() -> void:
	await super()
	await _passo_morte_por_golpes()


func _passo_morte_por_golpes() -> void:
	var inimigos := get_tree().get_nodes_in_group("enemies")
	_diz("ha inimigos no mundo", not inimigos.is_empty(),
		"%d encontrados" % inimigos.size())
	if inimigos.is_empty():
		return

	var jogador := _jogador as Player
	var alvo := _primeiro_inimigo_comum(inimigos)
	if jogador == null or alvo == null:
		_diz("ha jogador e inimigo comuns para combater", false)
		return
	var original_player_position := jogador.global_position

	# Os restantes actores nao interferem na medicao. O alvo e reactivado apenas
	# durante a experiencia de afastamento, para exercer a IA de regresso real.
	for node: Node in inimigos:
		var inimigo := node as Enemy
		if inimigo != null:
			inimigo.set_physics_process(false)
	alvo.died.connect(_ao_morrer_na_sessao, CONNECT_ONE_SHOT)

	var weapon: Dictionary = GameData.weapon(jogador.main_weapon)
	var light: Dictionary = weapon.get("light", {}) as Dictionary
	var reach := float(weapon.get("range", 0.0))
	var expected_damage := GameData.compute_damage(float(light.get("mv", 0.0)),
		jogador.main_weapon, jogador.attrs, alvo.defense)
	if reach <= 0.0 or expected_damage <= 0.0:
		_diz("a arma da sessao tem alcance e dano executaveis", false,
			"alcance=%.1f; dano=%.1f" % [reach, expected_damage])
		_restaurar_mundo(jogador, alvo, inimigos, original_player_position)
		return
	var initial_health := alvo.health
	var hits := 0
	var attempts := 0
	var uncapped_hits := true

	if not await _esperar_jogador_livre(jogador):
		_diz("o jogador recupera antes da prova de morte", false,
			"estado=%s" % jogador.state_name())
		_restaurar_mundo(jogador, alvo, inimigos, original_player_position)
		return

	_colocar_para_golpe(jogador, alvo, reach)
	var first := await _dar_um_golpe(jogador, alvo, 1, expected_damage)
	attempts += 1
	if bool(first.get("hit", false)):
		hits += 1
	uncapped_hits = uncapped_hits and bool(first.get("uncapped", false))

	# Hipotese (a): depois de levar dano, a IA ve o jogador fora da trela e tem
	# dois segundos para regressar ao posto. Medimos os PV antes e depois.
	var health_after_first := alvo.health
	var leash := float(alvo.data.get("leash_range", 30.0))
	alvo.target = jogador
	alvo.set_physics_process(true)
	for _frame: int in 30:
		await get_tree().physics_frame
		if alvo.state in [Enemy.State.CHASE, Enemy.State.ATTACK]:
			break
	var state_before_return := alvo.state
	jogador.global_position = alvo.home + Vector3.BACK * (leash + 5.0)
	jogador.velocity = Vector3.ZERO
	await _esperar_fisica(RETREAT_FRAMES)
	alvo.set_physics_process(false)
	var healed_on_return := alvo.health > health_after_first + 0.01
	print("[morte-real] regresso: estado %s -> %s; PV %.1f -> %.1f em %d frames" % [
		_nome_estado_inimigo(state_before_return), _nome_estado_inimigo(alvo.state),
		health_after_first, alvo.health,
		RETREAT_FRAMES])
	_diz("afastar-se nao cura o inimigo silenciosamente", not healed_on_return,
		"PV %.1f -> %.1f" % [health_after_first, alvo.health])

	for attack_index: int in range(2, MAX_ATTACKS + 1):
		if not alvo.is_alive():
			break
		if not await _esperar_jogador_livre(jogador):
			break
		_colocar_para_golpe(jogador, alvo, reach)
		var sample := await _dar_um_golpe(
			jogador, alvo, attack_index, expected_damage)
		attempts += 1
		if bool(sample.get("hit", false)):
			hits += 1
		uncapped_hits = uncapped_hits and bool(sample.get("uncapped", false))

	_diz("seis golpes ao alcance nao se perdem por alcance ou orientacao",
		hits == attempts
			and hits == mini(MAX_ATTACKS, ceili(initial_health / expected_damage)),
		"%d acertos em %d tentativas (limite %d)" % [hits, attempts, MAX_ATTACKS])
	_diz("nao ha tecto oculto de dano por golpe ou por segundo", uncapped_hits,
		"dano esperado por leve %.1f" % expected_damage)
	_diz("bater ate zero dispara a morte do inimigo",
		_morte_observada and not alvo.is_alive() and alvo.health <= 0.0,
		"PV %.1f -> %.1f; acertos=%d; sinal died=%s" % [
			initial_health, alvo.health, hits, _morte_observada])

	var death_position := alvo.global_position
	await _esperar_fisica(60)
	var moved_after_death := alvo.global_position.distance_to(death_position) > 0.05
	_diz("o inimigo morto para de se mexer", not moved_after_death,
		"deslocou-se depois de morrer" if moved_after_death else "")
	print("inimigos mortos: %d" % _inimigos_mortos)
	_restaurar_mundo(jogador, alvo, inimigos, original_player_position)


func _primeiro_inimigo_comum(inimigos: Array[Node]) -> Enemy:
	for node: Node in inimigos:
		var inimigo := node as Enemy
		if inimigo != null and inimigo.enemy_id == "orc_spearman" and inimigo.is_alive():
			return inimigo
	for node: Node in inimigos:
		var inimigo := node as Enemy
		if inimigo != null and not inimigo.is_boss and inimigo.is_alive():
			return inimigo
	return null


func _colocar_para_golpe(jogador: Player, alvo: Enemy, reach: float) -> void:
	var distance := maxf(0.8, reach * 0.72)
	jogador.global_position = alvo.global_position + Vector3.BACK * distance
	jogador.velocity = Vector3.ZERO
	alvo.velocity = Vector3.ZERO
	jogador.look_at(Vector3(alvo.global_position.x, jogador.global_position.y,
		alvo.global_position.z), Vector3.UP)
	jogador.lock_on.target = alvo


func _dar_um_golpe(jogador: Player, alvo: Enemy, attack_index: int,
		expected_damage: float) -> Dictionary:
	var before := alvo.health
	var distance := jogador.global_position.distance_to(alvo.global_position)
	var to_target := alvo.global_position - jogador.global_position
	to_target.y = 0.0
	var angle := 0.0
	if to_target.length_squared() > 0.001:
		angle = rad_to_deg((-jogador.global_transform.basis.z).angle_to(
			to_target.normalized()))

	Input.action_release("attack")
	await get_tree().physics_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	Input.action_release("attack")

	for _frame: int in ATTACK_TIMEOUT_FRAMES:
		await get_tree().physics_frame
		if not alvo.is_alive() or (alvo.health < before and jogador.state_name() == "livre"):
			break
	var dealt := before - alvo.health
	var hit := dealt > 0.01
	var uncapped := (hit and is_equal_approx(dealt, expected_damage)) \
		or (not alvo.is_alive() and before <= expected_damage + 0.01)
	print(("[morte-real] tentativa %d: PV %.1f -> %.1f; dano %.1f/%.1f; " \
		+ "distancia %.2f; angulo %.1f; %s") % [attack_index, before,
			alvo.health, dealt, expected_damage, distance, angle,
			"ACERTO" if hit else "FALHOU"])
	return {"hit": hit, "uncapped": uncapped}


func _esperar_jogador_livre(jogador: Player) -> bool:
	for _frame: int in ATTACK_TIMEOUT_FRAMES:
		if jogador.state_name() == "livre" and jogador.stamina.can_act():
			return true
		await get_tree().physics_frame
	return false


func _esperar_fisica(frames: int) -> void:
	for _frame: int in frames:
		await get_tree().physics_frame


func _nome_estado_inimigo(value: int) -> String:
	var names := Enemy.State.keys()
	return String(names[value]) if value >= 0 and value < names.size() else str(value)


func _restaurar_mundo(jogador: Player, alvo_morto: Enemy,
		inimigos: Array[Node], original_player_position: Vector3) -> void:
	jogador.lock_on.target = null
	jogador.global_position = original_player_position
	jogador.velocity = Vector3.ZERO
	for node: Node in inimigos:
		var inimigo := node as Enemy
		if inimigo == null:
			continue
		if inimigo != alvo_morto and inimigo.is_alive():
			inimigo.full_reset()
		inimigo.set_physics_process(true)


func _ao_morrer_na_sessao(_inimigo: Enemy) -> void:
	_morte_observada = true
	_inimigos_mortos += 1
