extends Node
## Joga uma sessão inteira e diz, passo a passo, o que funciona e o que não.
##
## Porque isto existe (02-08-2026): o Mateus disse *"joga tu e testa"*. Os testes
## que temos verificam contratos; o modo fotografia apanha poses paradas; o filme
## apanha um golpe. Faltava alguém sentar-se e **jogar**.
##
## Não é um teste que passa ou falha — é um RELATÓRIO. Cada passo diz OK ou FALHA
## com a razão, e no fim imprime a lista para o Codex arrumar um a um.
##
## Corre com:
##   godot --audio-driver Dummy --path . --rendering-method mobile scenes/sessao-de-jogo.tscn

const GAMEPLAY := preload("res://scenes/gameplay.tscn")

var _jogo: Node
var _jogador: Node3D
var _relatorio: Array[String] = []
var _falhas := 0
var _morte_inimigo_observada := false

const FRAMES_SEM_PROGRESSO := 180
const TOLERANCIA_DESTINO_M := 1.35


func _ready() -> void:
	_jogo = GAMEPLAY.instantiate()
	add_child(_jogo)
	_jogar.call_deferred()


func _diz(passo: String, ok: bool, detalhe := "") -> void:
	if not ok:
		_falhas += 1
	var marca := "  ok  " if ok else "FALHA "
	var linha := "%s %s%s" % [marca, passo, ("  — " + detalhe) if detalhe != "" else ""]
	_relatorio.append(linha)
	print("[sessao] ", linha)


func _jogar() -> void:
	await _esperar(120)

	_jogador = _jogo.get("player") as Node3D
	if _jogador == null:
		_diz("o jogo arranca com um jogador", false, "player é nulo")
		return _fim()
	_diz("o jogo arranca com um jogador", true,
		"origem %s" % String(_jogador.get("class_id")))

	await _passo_rede()
	await _passo_equipamento()
	await _passo_atacar()
	await _passo_inimigos()
	await _passo_item_rapido()
	await _passo_fogueira()
	await _passo_mundo()
	_fim()


## A entrada de rede nunca pode parecer clicável enquanto o rato está preso.
## A tecla indicada no HUD tem de abrir o menu real, não apenas libertar o rato.
func _passo_rede() -> void:
	var menu := _jogo.get("net_menu") as NetMenu
	var interface := _jogo.get("hud") as Hud
	var botao := interface.get_node_or_null("JogarADois") as Button \
		if interface != null else null
	var alcancavel := botao != null and botao.visible \
		and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	_diz("o botão Jogar a dois está alcançável", alcancavel,
		"rato livre e botão visível" if alcancavel else (
			"o rato está capturado enquanto o botão continua visível" if botao != null \
			and botao.visible else "a entrada de rede não apareceu"))
	if menu == null or botao == null:
		return

	botao.pressed.emit()
	await _esperar(2)
	var hospedar := menu.get("_host_button") as Button
	var entrar := menu.get("_join_button") as Button
	var menu_real := menu.visible and hospedar != null and hospedar.visible \
		and entrar != null and entrar.visible
	_diz("o botão abre o menu de rede real", menu_real,
		"Hospedar e Entrar visíveis" if menu_real \
		else "Hospedar e Entrar não ficaram disponíveis")
	_jogo.call("_toggle_network_menu")
	await _esperar(2)

	await _accionar("toggle_mouse")
	var tecla_abriu := menu.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	_diz("a tecla de rede abre o menu e liberta o rato", tecla_abriu,
		"menu aberto e rato livre" if tecla_abriu \
		else "a tecla apenas libertou o rato sem abrir Jogar a dois")
	if menu.visible:
		_jogo.call("_toggle_network_menu")
		await _esperar(2)


## O que se leva na mão, e se bate certo com o que a interface diz.
func _passo_equipamento() -> void:
	var principal := String(_jogador.get("main_weapon"))
	var secundaria := String(_jogador.get("offhand_weapon"))
	_diz("arranca com arma na mão principal", principal != "", "main=%s" % principal)
	_diz("arranca com alguma coisa na secundária", secundaria != "", "offhand=%s" % secundaria)

	var pendurados: Array[String] = []
	var por_ver: Array[Node] = [_jogador]
	while not por_ver.is_empty():
		var no: Node = por_ver.pop_back()
		if no is BoneAttachment3D and no.get_child_count() > 0:
			pendurados.append((no as BoneAttachment3D).bone_name)
		for f in no.get_children():
			por_ver.append(f)
	_diz("há geometria pendurada no esqueleto", not pendurados.is_empty(),
		"ossos com coisa: %s" % ", ".join(pendurados))

	var visual := _jogador.get("_visual") as Node
	var estado := GameData.save_state_snapshot()
	var inventario: Dictionary = (estado.get("character", {}) as Dictionary).get(
		"inventory", {}) as Dictionary
	var esperada: Array = (inventario.get("equipment", {}) as Dictionary).get(
		"armor", []) as Array
	var visivel: Array = visual.call("equipped_piece_ids") as Array \
		if visual != null and visual.has_method("equipped_piece_ids") else []
	var faltam: Array[String] = []
	for peca: Variant in esperada:
		if not String(peca) in visivel:
			faltam.append(String(peca))
	_diz("a armadura equipada aparece no boneco",
		not esperada.is_empty() and faltam.is_empty(),
		"peças sem geometria: %s" % ", ".join(faltam) if not faltam.is_empty() \
		else "%d peça(s) equipadas e visíveis" % esperada.size())

	# ⚠️ Uma arma abaixo do requisito corta o dano: o jogador começa castigado.
	var aviso := String(_jogador.get("requirement_warning")) if "requirement_warning" in _jogador else ""
	_diz("a arma inicial cumpre o requisito da origem", aviso == "",
		aviso if aviso != "" else "sem penalização")


## Carregar em atacar tem de mudar a pose. Se não muda, não há combate.
func _passo_atacar() -> void:
	var visual: Node = _jogador.get("_visual") as Node
	var erros_catalogo := CharacterVisual.animation_catalogue_errors()
	var fronteira_catalogada := visual != null \
		and visual.has_method("play_state_animation") \
		and FileAccess.file_exists("res://data/animations.json") \
		and erros_catalogo.is_empty()
	_diz("os estados visuais obedecem ao catálogo de animações",
		fronteira_catalogada,
		"" if fronteira_catalogada \
		else "falta catálogo/API ou há erros: %s" % ", ".join(erros_catalogo))

	var antes := _pose()
	Input.action_press("attack")
	await _esperar(2)
	var estado_durante_golpe := String(_jogador.call("state_name")) \
		if _jogador.has_method("state_name") else "?"
	Input.action_release("attack")
	await _esperar(8)
	var meio := _pose()
	var animacao_do_golpe := _animacao_tocada()
	await _esperar(20)
	_diz("atacar muda a pose do boneco", antes != meio,
		"o esqueleto não se mexeu entre o repouso e o meio do golpe" if antes == meio else "")
	_diz("atacar com espada toca um golpe de espada, nunca um Punch",
		animacao_do_golpe.contains("Sword_Attack") and not animacao_do_golpe.contains("Punch"),
		"animação=%s" % animacao_do_golpe)

	_diz("atacar entra em estado de ataque", estado_durante_golpe == "ataque",
		"estado observado dois frames depois da entrada=%s" % estado_durante_golpe)


## Os inimigos existem, atacam, e morrem sem ficar a mexer-se.
func _passo_inimigos() -> void:
	var inimigos := get_tree().get_nodes_in_group("enemies")
	_diz("há inimigos no mundo", not inimigos.is_empty(), "%d encontrados" % inimigos.size())
	if inimigos.is_empty():
		return

	var alvo := _inimigo_comum_mais_perto() as Enemy
	if alvo == null:
		_diz("há um inimigo comum vivo para a sessão", false)
		return
	alvo.died.connect(_ao_inimigo_morrer, CONNECT_ONE_SHOT)
	var arma: Dictionary = GameData.weapon(_jogador.main_weapon)
	var golpe: Dictionary = arma.get("light", {}) as Dictionary
	var alcance := float(arma.get("range", 0.0))
	if alcance <= 0.0 or not await _andar_ate_alvo(alvo, alcance):
		_diz("o jogador anda até ao primeiro inimigo", false,
			"não chegou ao alcance sem teletransporte")
		return
	_diz("o jogador anda até ao primeiro inimigo", true,
		"distância %.2f m" % _distancia_plana(_jogador.global_position, alvo.global_position))
	await _provar_telegrafo(alvo)

	var vida_inicial := alvo.health
	var dano_esperado := GameData.compute_damage(float(golpe.get("mv", 0.0)),
		_jogador.main_weapon, _jogador.attrs, alvo.defense)
	if dano_esperado <= 0.0:
		_diz("a arma retira PV pelo golpe catalogado", false,
			"dano calculado=%.1f" % dano_esperado)
		return
	var golpes_necessarios := ceili(vida_inicial / dano_esperado)
	var tentativas_maximas := golpes_necessarios \
		* ((alvo.data.get("attacks", []) as Array).size() + 1)
	var tentativas := 0
	var acertos := 0
	while is_instance_valid(alvo) and alvo.is_alive() and tentativas < tentativas_maximas:
		if not _jogador.is_alive():
			break
		if _jogador.state != Player.State.FREE:
			await get_tree().physics_frame
			continue
		if alvo.telegraphing_parryable() >= 0:
			await _bloquear_telegrafo(alvo)
			continue
		if _distancia_plana(_jogador.global_position, alvo.global_position) > alcance:
			if not await _andar_ate_alvo(alvo, alcance):
				break
		var orientar := alvo.global_position - _jogador.global_position
		orientar.y = 0.0
		_aplicar_movimento(orientar.normalized())
		await get_tree().physics_frame
		_parar_movimento()
		var vida_antes := alvo.health
		await _accionar("attack")
		tentativas += 1
		await _esperar_fim_do_golpe(golpe)
		if is_instance_valid(alvo) and alvo.health < vida_antes:
			acertos += 1

	if not is_instance_valid(alvo):
		_diz("bater até zero dispara a morte do inimigo", _morte_inimigo_observada,
			"o corpo desapareceu; died=%s" % str(_morte_inimigo_observada))
		return
	await _esperar(60)

	var pos_a := alvo.global_position
	await _esperar(60)
	var mexeu := alvo.global_position.distance_to(pos_a) > 0.05
	var morreu := _morte_inimigo_observada and not alvo.is_alive()
	_diz("os comandos de ataque matam o inimigo", morreu,
		"PV %.0f -> %.0f; %d acertos/%d tentativas; died=%s" % [
			vida_inicial, alvo.health, acertos, tentativas, str(_morte_inimigo_observada)])
	_diz("o inimigo morto pára a IA e fica quieto", morreu and not mexeu \
		and not alvo.is_physics_processing(),
		"continuou a deslocar-se depois de morrer" if mexeu else "")

	var visual := alvo.get("_visual") as Node
	var animacao := String(visual.get("_current_animation")) if visual != null else ""
	var tinta: Variant = visual.get("_current_tint") if visual != null else null
	_diz("o cadáver toca Death01 uma vez", animacao.to_lower().contains("death"),
		"animação actual=%s" % animacao)
	var tinta_inteira := typeof(tinta) == TYPE_COLOR \
		and (tinta as Color).is_equal_approx(Color.WHITE)
	_diz("o cadáver não fica preto", tinta_inteira,
		"material conserva a cor" if tinta_inteira else "a morte escureceu o material")
	var placement_id := String(alvo.get_meta("placement_id", ""))
	_diz("o cadáver tem identidade para o descanso", placement_id != "",
		placement_id if placement_id != "" \
		else "sem placement_id a fogueira recusa depois de uma morte real")


## O aviso tem de existir durante o startup e antes de a vida descer.
func _provar_telegrafo(alvo: Enemy) -> void:
	var ficha: Dictionary = alvo.data
	var ataques: Array = ficha.get("attacks", []) as Array
	if ataques.is_empty():
		_diz("o inimigo telegrafa antes de bater", false, "não há ataque executável")
		return
	var espera_maxima := 0
	for valor: Variant in ataques:
		var ataque := valor as Dictionary
		espera_maxima += int(ataque.get("startup", 0)) + int(ataque.get("active", 0)) \
			+ int(ataque.get("recovery", 0))
	var jogador := _jogador as Player
	var vida_antes: float = jogador.health
	var vida_ao_anuncio: float = vida_antes
	var anunciou := false
	var sinal_visivel := false
	var bateu := false
	for _frame: int in maxi(1, espera_maxima):
		await get_tree().physics_frame
		if not anunciou and alvo.telegraphing_parryable() >= 0:
			anunciou = true
			vida_ao_anuncio = _jogador.health
			var cue := alvo.get("_active_gameplay_cue") as Node3D
			sinal_visivel = is_instance_valid(cue) and cue.visible
		if anunciou and _jogador.health < vida_ao_anuncio:
			bateu = true
			break
	var nao_bateu_cedo := anunciou and is_equal_approx(vida_antes, vida_ao_anuncio)
	_diz("o inimigo telegrafa o ataque antes de bater",
		anunciou and sinal_visivel and nao_bateu_cedo and bateu,
		"aviso=%s, forma visível=%s, dano antes=%s, dano depois=%s" % [
			anunciou, sinal_visivel, not nao_bateu_cedo, bateu])


## As ranhuras rápidas têm de ter coisas e a tecla tem de as usar.
func _passo_item_rapido() -> void:
	var frascos_antes := int(_jogador.get("flask_uses")) if "flask_uses" in _jogador else -1
	_diz("o jogador tem frascos", frascos_antes > 0, "frascos=%d" % frascos_antes)
	if frascos_antes <= 0:
		return
	# A vida em falta tem de vir do golpe real observado no passo anterior. Uma
	# escrita directa aqui provaria apenas o setter, nao o item do jogador.
	if _jogador.health >= _jogador.max_health:
		_diz("há dano real para o frasco curar", false,
			"o inimigo anterior não retirou PV")
		return
	var vida_antes := float(_jogador.get("health"))
	Input.action_press("use_item")
	await _esperar(2)
	Input.action_release("use_item")
	await _esperar(90)
	var vida_depois := float(_jogador.get("health"))
	var frascos_depois := int(_jogador.get("flask_uses"))
	_diz("usar o item rápido gasta um frasco", frascos_depois < frascos_antes,
		"frascos %d -> %d" % [frascos_antes, frascos_depois])
	_diz("usar o item rápido cura", vida_depois > vida_antes,
		"vida %.0f -> %.0f" % [vida_antes, vida_depois])


## Descansar: a queixa foi "Não foi possível descansar agora".
func _passo_fogueira() -> void:
	var descanso: Vector3 = _jogo.get("_respawn_point") if "_respawn_point" in _jogo else Vector3.ZERO
	var chegou := await _andar_ate_ponto(descanso)
	_diz("o jogador volta à fogueira a pé", chegou,
		"distância final %.2f m" % _distancia_plana(_jogador.global_position, descanso))
	if not chegou:
		return
	await _esperar(20)
	var vida_antes := float(_jogador.get("health"))
	var frascos_antes := int(_jogador.get("flask_uses"))
	Input.action_press("interact")
	await _esperar(2)
	Input.action_release("interact")
	await _esperar(150)
	var vida_depois := float(_jogador.get("health"))
	var frascos_depois := int(_jogador.get("flask_uses"))
	var descansou := vida_depois > vida_antes or frascos_depois > frascos_antes
	_diz("descansar na fogueira restaura recursos", descansou,
		"vida %.0f -> %.0f; frascos %d -> %d" % [
			vida_antes, vida_depois, frascos_antes, frascos_depois] if descansou \
		else "vida e frascos não mudaram; o descanso foi recusado")


## O mundo tem as coisas que o jogo promete.
func _passo_mundo() -> void:
	var gestor: Node = null
	var por_ver: Array[Node] = [_jogo]
	while not por_ver.is_empty():
		var no: Node = por_ver.pop_back()
		if no is WorldPickupManager:
			gestor = no
			break
		for f in no.get_children():
			por_ver.append(f)
	_diz("o gestor de espólio existe na cena", gestor != null,
		"WorldPickupManager montado" if gestor != null \
		else "WorldPickupManager não foi encontrado — nada de baús nem de coisas no chão")
	if gestor != null:
		var baus := int(gestor.call("chest_count")) \
			if gestor.has_method("chest_count") else 0
		_diz("o gestor monta os três baús de Brumal", baus == 3, "%d baús" % baus)
	var fps := Engine.get_frames_per_second()
	_diz("a sessão regista o custo desta execução", fps > 0.0,
		"%.0f fps; esta máquina não prova a Iris Xe do Rico" % fps)


func _inimigo_comum_mais_perto() -> Enemy:
	var melhor: Enemy
	var distancia_melhor := INF
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		var inimigo := no as Enemy
		if inimigo == null or not inimigo.is_alive() or inimigo.is_boss:
			continue
		var distancia := _distancia_plana(_jogador.global_position, inimigo.global_position)
		if distancia < distancia_melhor:
			distancia_melhor = distancia
			melhor = inimigo
	return melhor


func _andar_ate_alvo(alvo: Enemy, alcance: float) -> bool:
	var melhor := _distancia_plana(_jogador.global_position, alvo.global_position)
	var sem_progresso := 0
	while is_instance_valid(alvo) and alvo.is_alive() and melhor > alcance:
		if not _jogador.is_alive():
			_parar_movimento()
			return false
		var direccao := alvo.global_position - _jogador.global_position
		direccao.y = 0.0
		_aplicar_movimento(direccao.normalized())
		await get_tree().physics_frame
		var distancia := _distancia_plana(_jogador.global_position, alvo.global_position)
		if distancia < melhor:
			melhor = distancia
			sem_progresso = 0
		else:
			sem_progresso += 1
		if sem_progresso >= FRAMES_SEM_PROGRESSO:
			_parar_movimento()
			return false
	_parar_movimento()
	return is_instance_valid(alvo) and alvo.is_alive()


func _andar_ate_ponto(destino: Vector3) -> bool:
	var melhor := _distancia_plana(_jogador.global_position, destino)
	var sem_progresso := 0
	while melhor > TOLERANCIA_DESTINO_M:
		if not _jogador.is_alive():
			_parar_movimento()
			return false
		var direccao := destino - _jogador.global_position
		direccao.y = 0.0
		_aplicar_movimento(direccao.normalized())
		await get_tree().physics_frame
		var distancia := _distancia_plana(_jogador.global_position, destino)
		if distancia < melhor:
			melhor = distancia
			sem_progresso = 0
		else:
			sem_progresso += 1
		if sem_progresso >= FRAMES_SEM_PROGRESSO:
			_parar_movimento()
			return false
	_parar_movimento()
	return true


func _aplicar_movimento(direccao_mundo: Vector3) -> void:
	_parar_movimento()
	var jogador := _jogador as Player
	if jogador == null or jogador.camera == null:
		return
	var eixo_x := clampf(direccao_mundo.dot(jogador.camera.right_flat()), -1.0, 1.0)
	var eixo_y := clampf(-direccao_mundo.dot(jogador.camera.forward_flat()), -1.0, 1.0)
	if eixo_x < 0.0:
		Input.action_press("move_left", -eixo_x)
	elif eixo_x > 0.0:
		Input.action_press("move_right", eixo_x)
	if eixo_y < 0.0:
		Input.action_press("move_forward", -eixo_y)
	elif eixo_y > 0.0:
		Input.action_press("move_back", eixo_y)


func _parar_movimento() -> void:
	for accao: String in ["move_left", "move_right", "move_forward", "move_back",
			"block", "attack", "interact", "use_item"]:
		Input.action_release(accao)


func _bloquear_telegrafo(alvo: Enemy) -> void:
	var encarar := alvo.global_position - _jogador.global_position
	encarar.y = 0.0
	_aplicar_movimento(encarar.normalized())
	await get_tree().physics_frame
	_parar_movimento()
	Input.action_press("block")
	var espera_maxima := 1
	for valor: Variant in alvo.data.get("attacks", []) as Array:
		var ataque := valor as Dictionary
		espera_maxima = maxi(espera_maxima, int(ataque.get("startup", 0)) \
			+ int(ataque.get("active", 0)) + int(ataque.get("recovery", 0)))
	for _frame: int in espera_maxima:
		await get_tree().physics_frame
		if not is_instance_valid(alvo) or alvo.state_name() in [
				"recuperacao", "persegue", "livre", "patrulha"]:
			break
	Input.action_release("block")
	await get_tree().physics_frame


func _esperar_fim_do_golpe(golpe: Dictionary) -> void:
	var total := int(golpe.get("startup", 0)) + int(golpe.get("active", 0)) \
		+ int(golpe.get("recovery", 0))
	var margem_hitstop := 0
	for valor: Variant in (GameData.section("hit_stop") as Dictionary).values():
		if valor is int or valor is float:
			margem_hitstop = maxi(margem_hitstop, int(valor))
	var jogador := _jogador as Player
	var viu_ataque: bool = jogador.state == Player.State.ATTACK
	for _frame: int in maxi(1, total + margem_hitstop):
		await get_tree().physics_frame
		viu_ataque = viu_ataque or _jogador.state == Player.State.ATTACK
		if viu_ataque and _jogador.state == Player.State.FREE:
			return


func _ao_inimigo_morrer(_inimigo: Enemy) -> void:
	_morte_inimigo_observada = true
	Input.action_release("attack")


func _distancia_plana(a: Vector3, b: Vector3) -> float:
	var delta := b - a
	delta.y = 0.0
	return delta.length()


func _fim() -> void:
	print("\n══════════ SESSÃO DE JOGO ══════════")
	for l in _relatorio:
		print(l)
	print("════════════════════════════════════")
	print("%d passo(s) com falha, de %d" % [_falhas, _relatorio.size()])
	_parar_movimento()
	get_tree().quit(1 if _falhas > 0 else 0)


func _pose() -> String:
	var esq: Skeleton3D = _achar_esqueleto(_jogador)
	if esq == null:
		return "sem-esqueleto"
	var soma := ""
	for i in mini(esq.get_bone_count(), 12):
		soma += str(esq.get_bone_pose_rotation(i)).substr(0, 18)
	return soma


func _achar_esqueleto(no: Node) -> Skeleton3D:
	if no is Skeleton3D:
		return no as Skeleton3D
	for f in no.get_children():
		var r := _achar_esqueleto(f)
		if r != null:
			return r
	return null


func _animacao_tocada() -> String:
	var candidatas: Array[String] = []
	var por_ver: Array[Node] = [_jogador]
	while not por_ver.is_empty():
		var no: Node = por_ver.pop_back()
		if no is AnimationPlayer:
			var atribuida := String((no as AnimationPlayer).assigned_animation)
			if not atribuida.is_empty():
				candidatas.append(atribuida)
		for filha: Node in no.get_children():
			por_ver.append(filha)
	for animacao: String in candidatas:
		if animacao.contains("weapon_attacks/"):
			return animacao
	return candidatas[0] if not candidatas.is_empty() else "nenhuma"


func _esperar(frames: int) -> void:
	for _i in frames:
		await get_tree().process_frame


func _accionar(action: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await _esperar(2)
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await _esperar(2)
