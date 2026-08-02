extends Node
## Prova o percurso jogavel completo: o piloto usa as mesmas accoes de movimento,
## ataque, defesa e cura que o jogador, atravessa a rota publicada pelo mundo e
## luta com o guardiao. Nenhuma mudanca de `global_position` e permitida aqui.
##
## Corre com:
##   godot --audio-driver Dummy --path . --rendering-method mobile scenes/percurso.tscn
## Para nao tocar nas capturas existentes, a automacao pode definir
## `WORLDRPGS_PROOF_CAPTURE_DIR` para uma pasta temporaria.

const GAMEPLAY := preload("res://scenes/gameplay.tscn")

const AQUECIMENTO_FRAMES := 90
const TOLERANCIA_DESTINO_M := 1.35
const TOLERANCIA_PROGRESSO_M := 0.08
const FRAMES_SEM_PROGRESSO := 180

var _jogo: Node
var _jogador: Player
var _camara: Camera3D
var _dir := ""
var _tarefas: Array[int] = []
var _relatorio: Array[String] = []
var _falhas := 0
var _mortos := 0
var _mortes_observadas: Dictionary = {}
var _tipos_vistos: Dictionary = {}
var _jogador_morreu := false


func _ready() -> void:
	_dir = OS.get_environment("WORLDRPGS_PROOF_CAPTURE_DIR")
	if _dir.is_empty():
		_dir = ProjectSettings.globalize_path("res://captures/percurso-honesto")
	_dir = _dir.trim_suffix("/").trim_suffix("\\")
	var erro := DirAccess.make_dir_recursive_absolute(_dir)
	if erro != OK:
		_falhar("nao foi possivel criar a pasta de capturas: %s" % error_string(erro))
		_fim()
		return
	get_tree().node_added.connect(_ao_no_adicionado)
	_jogo = GAMEPLAY.instantiate()
	add_child(_jogo)
	_correr.call_deferred()


func _diz(texto: String) -> void:
	_relatorio.append(texto)
	print("[percurso] ", texto)


func _falhar(texto: String) -> void:
	_falhas += 1
	_diz("FALHA — " + texto)


func _correr() -> void:
	await _esperar_fisica(AQUECIMENTO_FRAMES)
	_jogador = _jogo.get("player") as Player
	if _jogador == null:
		_falhar("a cena real nao criou o jogador")
		_fim()
		return
	_jogador.died.connect(_ao_jogador_morrer, CONNECT_ONE_SHOT)
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		_observar_inimigo(no)

	var mundo := _jogo.get("world") as Node3D
	var rota := _rota_publicada(mundo)
	_diz("rota publicada com %d destinos" % rota.size())
	if rota.is_empty():
		_falhar("o mundo nao publicou uma rota continua ate a arena")
		_fim()
		return

	_camara = Camera3D.new()
	_camara.fov = 62.0
	add_child(_camara)
	_camara.make_current()

	for indice: int in rota.size():
		if not await _andar_ate(rota[indice]):
			await _capturar("falha-%02d" % indice)
			_fim()
			return
		_diz("destino %02d/%02d alcancado a pe" % [indice + 1, rota.size()])
		await _capturar("destino-%02d" % indice)

	_parar_movimento()
	var chefe := _chefe_vivo()
	if chefe == null:
		_falhar("chegou a arena a pe, mas o guardiao nao apareceu")
		await _capturar("arena-sem-chefe")
		_fim()
		return
	_diz("guardiao encontrado na arena: %s" % chefe.display_name())
	var vida_chefe_inicial := chefe.health
	var venceu := await _combater(chefe)
	await _capturar("vorgar-derrotado" if venceu else "vorgar-falha")
	if not venceu:
		_falhar("a luta real nao derrotou o guardiao")
	elif chefe.health >= vida_chefe_inicial or chefe.is_alive():
		_falhar("a fotografia final contradiz o resultado da luta")
	else:
		_diz("guardiao derrotado por accoes de ataque; PV %.0f -> %.0f" % [
			vida_chefe_inicial, chefe.health])

	if _mortos <= 0:
		_falhar("atravessou a rota sem provar a morte de nenhum inimigo")
	if _jogador_morreu or not _jogador.is_alive():
		_falhar("o piloto morreu; nao atravessou o percurso vivo")
	_fim()


func _rota_publicada(mundo: Node3D) -> Array[Vector3]:
	var rota: Array[Vector3] = []
	if mundo == null or not "path_points" in mundo:
		return rota
	for valor: Variant in mundo.get("path_points") as Array:
		if valor is Vector3:
			rota.append(valor as Vector3)
	if rota.is_empty() or not "map_path_segments" in mundo or not "arena_center" in mundo:
		return []

	var entrada := rota[rota.size() - 1]
	var arena := mundo.get("arena_center") as Vector3
	var segmento_da_toca := PackedVector3Array()
	for valor: Variant in mundo.get("map_path_segments") as Array:
		var segmento := valor as PackedVector3Array
		if segmento.size() < 2:
			continue
		if segmento[0].distance_to(entrada) <= TOLERANCIA_DESTINO_M \
				and segmento[segmento.size() - 1].distance_to(arena) <= TOLERANCIA_DESTINO_M:
			segmento_da_toca = segmento
			break
	if segmento_da_toca.is_empty():
		return []
	for indice: int in range(1, segmento_da_toca.size()):
		rota.append(segmento_da_toca[indice])
	return rota


func _andar_ate(destino: Vector3) -> bool:
	var melhor_distancia := _distancia_plana(_jogador.global_position, destino)
	var sem_progresso := 0
	var desvios_tentados := 0
	var lados := [1.0, -1.0]
	while melhor_distancia > TOLERANCIA_DESTINO_M:
		if _jogador_morreu or not _jogador.is_alive():
			_parar_movimento()
			_falhar("o jogador morreu antes de chegar a %s" % str(destino))
			return false

		var inimigo := _inimigo_em_confronto()
		if inimigo != null:
			var nome_inimigo := inimigo.display_name()
			_parar_movimento()
			if not await _combater(inimigo):
				_falhar("nao conseguiu ultrapassar %s no caminho" % nome_inimigo)
				return false
			melhor_distancia = _distancia_plana(_jogador.global_position, destino)
			sem_progresso = 0
			continue

		var direccao := destino - _jogador.global_position
		direccao.y = 0.0
		_aplicar_movimento(direccao.normalized(), true)
		await get_tree().physics_frame
		var distancia := _distancia_plana(_jogador.global_position, destino)
		if distancia + TOLERANCIA_PROGRESSO_M < melhor_distancia:
			melhor_distancia = distancia
			sem_progresso = 0
		else:
			sem_progresso += 1
		if sem_progresso >= FRAMES_SEM_PROGRESSO:
			if desvios_tentados < lados.size():
				_diz("colisao a %.2f m; a contornar pelo lado %d" % [
					distancia, desvios_tentados + 1])
				await _contornar(destino, float(lados[desvios_tentados]))
				desvios_tentados += 1
				melhor_distancia = _distancia_plana(_jogador.global_position, destino)
				sem_progresso = 0
				continue
			_parar_movimento()
			_falhar("colisao ou geometria bloqueou a caminhada a %.2f m do destino" % distancia)
			return false
	_parar_movimento()
	return true


func _contornar(destino: Vector3, lado: float) -> void:
	var frente := destino - _jogador.global_position
	frente.y = 0.0
	var lateral := Vector3(-frente.z, 0.0, frente.x).normalized() * lado
	for _frame: int in maxi(1, int(FRAMES_SEM_PROGRESSO / 3)):
		if _jogador_morreu or not _jogador.is_alive():
			break
		_aplicar_movimento(lateral, false)
		await get_tree().physics_frame
	_parar_movimento()


func _combater(alvo: Enemy) -> bool:
	if alvo == null or not alvo.is_alive():
		return true
	_observar_inimigo(alvo)
	_contar_tipo(alvo)
	var identidade := alvo.get_instance_id()
	var nome_alvo := alvo.display_name()
	var arma: Dictionary = GameData.weapon(_jogador.main_weapon)
	var golpe: Dictionary = arma.get("light", {}) as Dictionary
	var alcance := float(arma.get("range", 0.0))
	var dano_esperado := GameData.compute_damage(float(golpe.get("mv", 0.0)),
		_jogador.main_weapon, _jogador.attrs, alvo.defense)
	if alcance <= 0.0 or dano_esperado <= 0.0:
		_falhar("a arma equipada nao fornece alcance/dano executaveis")
		return false
	var golpes_necessarios := ceili(alvo.health / dano_esperado)
	var ataques_catalogados := (alvo.data.get("attacks", []) as Array).size()
	# A margem para falhas tambem vem do conteudo que o alvo pode escolher. Um
	# inimigo com mais perguntas de ataque desloca-se mais e exige mais novas
	# aproximacoes; nao se escreve aqui um numero de golpes de combate.
	var tentativas_maximas := golpes_necessarios * (maxi(1, ataques_catalogados) + 1)
	var tentativas := 0
	var acertos := 0
	var vida_inicial := alvo.health
	var ciclo_jogador := int(golpe.get("startup", 0)) + int(golpe.get("active", 0)) \
		+ int(golpe.get("recovery", 0))
	var ciclos_inimigo := 0
	for valor: Variant in alvo.data.get("attacks", []) as Array:
		var ataque := valor as Dictionary
		ciclos_inimigo += int(ataque.get("startup", 0)) \
			+ int(ataque.get("active", 0)) + int(ataque.get("recovery", 0))
	var frame_limite := Engine.get_physics_frames() \
		+ tentativas_maximas * maxi(1, ciclo_jogador + ciclos_inimigo)

	while is_instance_valid(alvo) and alvo.is_alive() \
			and tentativas < tentativas_maximas \
			and Engine.get_physics_frames() < frame_limite:
		if _jogador_morreu or not _jogador.is_alive():
			_parar_movimento()
			return false
		if _jogador.state != Player.State.FREE:
			await get_tree().physics_frame
			continue
		var ameaca := _ameaca_em_preparacao()
		if ameaca != null:
			await _defender(ameaca)
			continue
		if _deve_curar() and _jogador.flask_uses > 0:
			await _accionar("use_item")
			await _esperar_jogador_livre(golpe)
			continue
		if not _jogador.stamina.can_act():
			await get_tree().physics_frame
			continue
		if alvo.state_name() == "golpe":
			await get_tree().physics_frame
			continue

		var distancia := _distancia_plana(_jogador.global_position, alvo.global_position)
		if distancia > alcance:
			var direccao := alvo.global_position - _jogador.global_position
			direccao.y = 0.0
			_aplicar_movimento(direccao.normalized(), false)
			await get_tree().physics_frame
			continue

		# O ultimo passo de aproximacao orienta o boneco; o golpe seguinte entra
		# exclusivamente pela accao remapeavel `attack`.
		var orientar := alvo.global_position - _jogador.global_position
		orientar.y = 0.0
		_aplicar_movimento(orientar.normalized(), false)
		await get_tree().physics_frame
		_parar_movimento()
		var antes := alvo.health
		if not await _tentar_atacar():
			continue
		tentativas += 1
		await _esperar_resultado_do_golpe(alvo, antes, golpe)
		if is_instance_valid(alvo) and alvo.health < antes:
			acertos += 1

	_parar_movimento()
	if not is_instance_valid(alvo):
		if _mortes_observadas.has(identidade):
			_diz("%s morreu e o streaming retirou o cadaver depois do sinal" % nome_alvo)
			return true
		_diz("combate falhou: %s desapareceu sem emitir died" % nome_alvo)
		return false
	if alvo.is_alive():
		_diz("combate falhou: %s conservou %.0f/%.0f PV (%d acertos/%d tentativas)" % [
			nome_alvo, alvo.health, vida_inicial, acertos, tentativas])
		return false
	_diz("%s morreu: %.0f -> %.0f PV, %d acertos por entrada" % [
		nome_alvo, vida_inicial, alvo.health, acertos])
	return true


func _esperar_resultado_do_golpe(alvo: Enemy, vida_antes: float,
		golpe: Dictionary) -> void:
	var total := int(golpe.get("startup", 0)) + int(golpe.get("active", 0)) \
		+ int(golpe.get("recovery", 0))
	var viu_ataque := _jogador.state in [Player.State.ATTACK, Player.State.RIPOSTE]
	var ataques_catalogados := maxi(1, (alvo.data.get("attacks", []) as Array).size())
	for _frame: int in maxi(1, total * ataques_catalogados):
		await get_tree().physics_frame
		if _jogador_morreu or not is_instance_valid(alvo):
			break
		viu_ataque = viu_ataque \
			or _jogador.state in [Player.State.ATTACK, Player.State.RIPOSTE]
		if not alvo.is_alive():
			break
		if viu_ataque and _jogador.state == Player.State.FREE:
			break


func _esperar_jogador_livre(golpe: Dictionary) -> void:
	var total := int(golpe.get("startup", 0)) + int(golpe.get("active", 0)) \
		+ int(golpe.get("recovery", 0))
	for _frame: int in maxi(1, total + 1):
		if _jogador.state == Player.State.FREE:
			return
		await get_tree().physics_frame


func _defender(alvo: Enemy) -> void:
	var encarar := alvo.global_position - _jogador.global_position
	encarar.y = 0.0
	_aplicar_movimento(encarar.normalized(), false)
	await get_tree().physics_frame
	_parar_movimento()
	var lado := _jogador.camera.right_flat() \
		if _jogador.camera != null else Vector3.RIGHT
	_aplicar_movimento(lado, false)
	Input.action_press("dodge_sprint")
	await get_tree().physics_frame
	Input.action_release("dodge_sprint")
	await get_tree().physics_frame
	_parar_movimento()
	var maior_duracao := 1
	for valor: Variant in alvo.data.get("attacks", []) as Array:
		var ataque := valor as Dictionary
		maior_duracao = maxi(maior_duracao, int(ataque.get("startup", 0)) \
			+ int(ataque.get("active", 0)) + int(ataque.get("recovery", 0)))
	for _frame: int in maior_duracao:
		await get_tree().physics_frame
		if _jogador_morreu or not is_instance_valid(alvo) or (
				_jogador.state == Player.State.FREE and alvo.state_name() in [
					"recuperacao", "persegue", "livre", "patrulha", "postura quebrada"]):
			break
	_parar_movimento()


func _ameaca_em_preparacao() -> Enemy:
	var melhor: Enemy
	var melhor_distancia := INF
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		var inimigo := no as Enemy
		if inimigo == null or not inimigo.is_alive() \
				or inimigo.telegraphing_parryable() < 0:
			continue
		var distancia := _distancia_plana(inimigo.global_position, _jogador.global_position)
		if distancia < melhor_distancia:
			melhor = inimigo
			melhor_distancia = distancia
	return melhor


func _deve_curar() -> bool:
	if _jogador.health >= _jogador.max_health:
		return false
	var perda_concorrente_possivel := 0.0
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		var inimigo := no as Enemy
		if inimigo == null or not inimigo.is_alive():
			continue
		var maior_deste_inimigo := 0.0
		for valor: Variant in inimigo.data.get("attacks", []) as Array:
			var ataque := valor as Dictionary
			maior_deste_inimigo = maxf(maior_deste_inimigo,
				GameData.apply_defense(float(ataque.get("damage", 0.0)), _jogador.defense))
		perda_concorrente_possivel += maior_deste_inimigo
	return perda_concorrente_possivel > 0.0 \
		and _jogador.health <= perda_concorrente_possivel


func _inimigo_em_confronto() -> Enemy:
	var melhor: Enemy
	var melhor_distancia := INF
	var defaults: Dictionary = GameData.enemies.get("_enemy_defaults", {}) as Dictionary
	var alcance_de_alerta := float(defaults.get("aggro_range", 0.0))
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		var inimigo := no as Enemy
		if inimigo == null or not inimigo.is_alive() or inimigo.is_boss:
			continue
		var distancia := _distancia_plana(inimigo.global_position, _jogador.global_position)
		if distancia <= alcance_de_alerta and distancia < melhor_distancia:
			melhor = inimigo
			melhor_distancia = distancia
	return melhor


func _chefe_vivo() -> Enemy:
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		var inimigo := no as Enemy
		if inimigo != null and inimigo.is_boss and inimigo.is_alive():
			return inimigo
	return null


func _ao_no_adicionado(no: Node) -> void:
	# O sinal `died` ja existe quando o Enemy entra na arvore. Ligar aqui evita
	# guardar uma referencia diferida a um no que o streaming possa libertar.
	_observar_inimigo(no)


func _observar_inimigo(no: Node) -> void:
	var inimigo := no as Enemy
	if inimigo == null or not inimigo.has_signal("died"):
		return
	var callback := Callable(self, "_ao_inimigo_morrer")
	if not inimigo.died.is_connected(callback):
		inimigo.died.connect(callback)


func _ao_inimigo_morrer(inimigo: Enemy) -> void:
	var identidade := inimigo.get_instance_id()
	if _mortes_observadas.has(identidade):
		return
	_mortes_observadas[identidade] = true
	_mortos += 1


func _ao_jogador_morrer() -> void:
	_jogador_morreu = true
	_parar_movimento()
	_falhar("o jogador morreu durante a prova")


func _contar_tipo(inimigo: Enemy) -> void:
	var chave := inimigo.enemy_id
	_tipos_vistos[chave] = int(_tipos_vistos.get(chave, 0)) + 1


func _aplicar_movimento(direccao_mundo: Vector3, sprint: bool) -> void:
	_parar_movimento()
	if direccao_mundo.is_zero_approx() or _jogador.camera == null:
		return
	var direita := _jogador.camera.right_flat()
	var frente := _jogador.camera.forward_flat()
	var eixo_x := clampf(direccao_mundo.dot(direita), -1.0, 1.0)
	var eixo_y := clampf(-direccao_mundo.dot(frente), -1.0, 1.0)
	if eixo_x < 0.0:
		Input.action_press("move_left", -eixo_x)
	elif eixo_x > 0.0:
		Input.action_press("move_right", eixo_x)
	if eixo_y < 0.0:
		Input.action_press("move_forward", -eixo_y)
	elif eixo_y > 0.0:
		Input.action_press("move_back", eixo_y)
	if sprint:
		Input.action_press("dodge_sprint")


func _parar_movimento() -> void:
	for accao: String in ["move_left", "move_right", "move_forward", "move_back",
			"dodge_sprint", "attack", "block", "parry", "use_item"]:
		Input.action_release(accao)


func _accionar(accao: String) -> void:
	Input.action_press(accao)
	await get_tree().physics_frame
	Input.action_release(accao)
	await get_tree().physics_frame


func _tentar_atacar() -> bool:
	Input.action_press("attack")
	await get_tree().physics_frame
	var iniciou := _jogador.state in [Player.State.ATTACK, Player.State.RIPOSTE]
	Input.action_release("attack")
	await get_tree().physics_frame
	return iniciou


func _capturar(nome: String) -> void:
	if DisplayServer.get_name() == "headless":
		_diz("captura %s adiada para a execucao com renderer" % nome)
		return
	_olhar()
	await get_tree().process_frame
	var imagem := get_viewport().get_texture().get_image()
	if imagem == null or imagem.is_empty():
		_diz("captura %s indisponivel no renderer headless" % nome)
		return
	var caminho := _dir.path_join("percurso-%s.png" % nome)
	_tarefas.append(WorkerThreadPool.add_task(_guardar.bind(imagem, caminho)))


func _olhar() -> void:
	if _camara == null or _jogador == null:
		return
	var centro := _jogador.global_position + Vector3(0, 1.3, 0)
	var frente := -_jogador.global_transform.basis.z
	_camara.look_at_from_position(centro - frente * 4.0 + Vector3(0, 1.4, 0), centro)


func _fim() -> void:
	_parar_movimento()
	for tarefa: int in _tarefas:
		WorkerThreadPool.wait_for_task_completion(tarefa)
	print("\n========== PERCURSO HONESTO ==========")
	for linha: String in _relatorio:
		print("  ", linha)
	print("  inimigos mortos por sinal: %d" % _mortos)
	print("  tipos enfrentados: %d -> %s" % [_tipos_vistos.size(), str(_tipos_vistos)])
	print("  jogador morreu: %s" % str(_jogador_morreu))
	print("======================================")
	get_tree().quit(1 if _falhas > 0 else 0)


func _guardar(imagem: Image, caminho: String) -> void:
	var erro := imagem.save_png(caminho)
	if erro != OK:
		printerr("[percurso] falhou gravar %s: %s" % [caminho, error_string(erro)])


func _esperar_fisica(frames: int) -> void:
	for _frame: int in frames:
		await get_tree().physics_frame


func _distancia_plana(a: Vector3, b: Vector3) -> float:
	var delta := b - a
	delta.y = 0.0
	return delta.length()
