extends Node
## Filma um combate iniciado pelas accoes reais de movimento e ataque. O piloto
## deixa de enviar ataques no mesmo frame em que recebe `died`; o cadaver fica no
## mundo para a necromancia e aparece no ultimo fotograma.
##
## Corre com:
##   godot --audio-driver Dummy --path . --rendering-method mobile scenes/filme-de-combate.tscn

const GAMEPLAY := preload("res://scenes/gameplay.tscn")

const AQUECIMENTO_FRAMES := 90
const INTERVALO_FRAMES := 7
const FRAMES_SEM_PROGRESSO := 180

var _jogo: Node
var _jogador: Player
var _inimigo: Enemy
var _camara: Camera3D
var _dir := ""
var _tarefas: Array[int] = []
var _imagens := 0
var _amostras := 0
var _falhas := 0
var _morte_observada := false
var _jogador_morreu := false
var _enviou_ataque_ao_morto := false


func _ready() -> void:
	_dir = OS.get_environment("WORLDRPGS_PROOF_CAPTURE_DIR")
	if _dir.is_empty():
		_dir = ProjectSettings.globalize_path("res://captures/filme-combate-honesto")
	_dir = _dir.trim_suffix("/").trim_suffix("\\")
	var erro := DirAccess.make_dir_recursive_absolute(_dir)
	if erro != OK:
		_falhar("nao foi possivel criar a pasta de capturas: %s" % error_string(erro))
		_fim()
		return
	_jogo = GAMEPLAY.instantiate()
	add_child(_jogo)
	_correr.call_deferred()


func _correr() -> void:
	await _esperar_fisica(AQUECIMENTO_FRAMES)
	_jogador = _jogo.get("player") as Player
	if _jogador == null:
		_falhar("a cena real nao criou o jogador")
		_fim()
		return
	_jogador.died.connect(_ao_jogador_morrer, CONNECT_ONE_SHOT)
	_inimigo = _inimigo_mais_perto(_jogador)
	if _inimigo == null:
		_falhar("a cena real nao materializou um inimigo vivo")
		_fim()
		return
	_inimigo.died.connect(_ao_inimigo_morrer, CONNECT_ONE_SHOT)

	var arma: Dictionary = GameData.weapon(_jogador.main_weapon)
	var alcance := float(arma.get("range", 0.0))
	if alcance <= 0.0 or not await _andar_ate_alcance(alcance):
		_falhar("o jogador nao chegou ao inimigo usando as accoes de movimento")
		_fim()
		return

	_camara = Camera3D.new()
	_camara.fov = 60.0
	add_child(_camara)
	_camara.make_current()
	_olhar()
	await get_tree().process_frame

	var vida_inicial := _inimigo.health
	var golpe: Dictionary = arma.get("light", {}) as Dictionary
	var dano_esperado := GameData.compute_damage(float(golpe.get("mv", 0.0)),
		_jogador.main_weapon, _jogador.attrs, _inimigo.defense)
	if dano_esperado <= 0.0:
		_falhar("a arma do jogador nao produz dano executavel")
		_fim()
		return
	var golpes_necessarios := ceili(vida_inicial / dano_esperado)
	var ciclo_do_golpe := int(golpe.get("startup", 0)) + int(golpe.get("active", 0)) \
		+ int(golpe.get("recovery", 0))
	var total_frames := ciclo_do_golpe * (golpes_necessarios \
		+ (_inimigo.data.get("attacks", []) as Array).size())
	print("[combate] inimigo: %s, PV iniciais %.0f" % [
		_inimigo.display_name(), vida_inicial])
	for frame_filme: int in range(0, total_frames, INTERVALO_FRAMES):
		if _morte_observada or not is_instance_valid(_inimigo) or not _inimigo.is_alive():
			Input.action_release("attack")
			await _esperar_repouso_apos_morte(ciclo_do_golpe)
			await _capturar("morte")
			break
		if frame_filme % (INTERVALO_FRAMES * 4) == 0:
			if _morte_observada or not _inimigo.is_alive():
				_enviou_ataque_ao_morto = true
			else:
				Input.action_press("attack")
		elif frame_filme % (INTERVALO_FRAMES * 4) == INTERVALO_FRAMES:
			Input.action_release("attack")

		_olhar()
		await _capturar("%02d" % _amostras)
		print("[combate] %02d · jogador=%s pv=%.0f · inimigo=%s pv=%.0f" % [
			_amostras, _jogador.state_name(), _jogador.health,
			_inimigo.state_name(), _inimigo.health])
		_amostras += 1
		await _esperar_fisica(INTERVALO_FRAMES)
		if _jogador_morreu:
			break

	Input.action_release("attack")
	if _jogador_morreu:
		_falhar("o jogador morreu durante o filme")
	if is_instance_valid(_inimigo) and _inimigo.health >= vida_inicial:
		_falhar("o filme nao mostra nenhum golpe a retirar PV ao inimigo")
	if not _morte_observada:
		_falhar("o filme acabou sem exercer o sinal died do inimigo")
	if _enviou_ataque_ao_morto:
		_falhar("o piloto enviou um ataque depois do sinal died")
	if _morte_observada and is_instance_valid(_inimigo) and _inimigo.is_alive():
		_falhar("o sinal died contradiz o estado visivel do inimigo")
	print("[combate] %d amostras, %d imagens; died=%s; ataque ao morto=%s" % [
		_amostras, _imagens, str(_morte_observada), str(_enviou_ataque_ao_morto)])
	_fim()


func _andar_ate_alcance(alcance: float) -> bool:
	var melhor := _distancia_plana(_jogador.global_position, _inimigo.global_position)
	var sem_progresso := 0
	while is_instance_valid(_inimigo) and _inimigo.is_alive() \
			and melhor > alcance:
		if _jogador_morreu or not _jogador.is_alive():
			_parar_movimento()
			return false
		var direccao := _inimigo.global_position - _jogador.global_position
		direccao.y = 0.0
		_aplicar_movimento(direccao.normalized())
		await get_tree().physics_frame
		var distancia := _distancia_plana(_jogador.global_position, _inimigo.global_position)
		if distancia < melhor:
			melhor = distancia
			sem_progresso = 0
		else:
			sem_progresso += 1
		if sem_progresso >= FRAMES_SEM_PROGRESSO:
			_parar_movimento()
			return false
	_parar_movimento()
	return is_instance_valid(_inimigo) and _inimigo.is_alive()


func _inimigo_mais_perto(de: Node3D) -> Enemy:
	var melhor: Enemy
	var distancia_melhor := INF
	for no: Node in get_tree().get_nodes_in_group("enemies"):
		var candidato := no as Enemy
		if candidato == null or not candidato.is_alive() or candidato.is_boss:
			continue
		var distancia := candidato.global_position.distance_to(de.global_position)
		if distancia < distancia_melhor:
			distancia_melhor = distancia
			melhor = candidato
	return melhor


func _ao_inimigo_morrer(_alvo: Enemy) -> void:
	_morte_observada = true
	Input.action_release("attack")


func _ao_jogador_morrer() -> void:
	_jogador_morreu = true
	Input.action_release("attack")
	_parar_movimento()


func _aplicar_movimento(direccao_mundo: Vector3) -> void:
	_parar_movimento()
	if _jogador.camera == null:
		return
	var eixo_x := clampf(direccao_mundo.dot(_jogador.camera.right_flat()), -1.0, 1.0)
	var eixo_y := clampf(-direccao_mundo.dot(_jogador.camera.forward_flat()), -1.0, 1.0)
	if eixo_x < 0.0:
		Input.action_press("move_left", -eixo_x)
	elif eixo_x > 0.0:
		Input.action_press("move_right", eixo_x)
	if eixo_y < 0.0:
		Input.action_press("move_forward", -eixo_y)
	elif eixo_y > 0.0:
		Input.action_press("move_back", eixo_y)


func _parar_movimento() -> void:
	for accao: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(accao)


func _olhar() -> void:
	if _camara == null or _jogador == null or not is_instance_valid(_inimigo):
		return
	var meio := (_jogador.global_position + _inimigo.global_position) * 0.5 \
		+ Vector3(0, 1.2, 0)
	var atras := (_jogador.global_position - _inimigo.global_position).normalized()
	_camara.look_at_from_position(
		_jogador.global_position + atras * 3.2 + Vector3(0.9, 2.0, 0), meio)


func _capturar(nome: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	var imagem := get_viewport().get_texture().get_image()
	if imagem == null or imagem.is_empty():
		_falhar("o renderer nao devolveu o fotograma %s" % nome)
		return
	var caminho := _dir.path_join("combate-%s.png" % nome)
	_tarefas.append(WorkerThreadPool.add_task(_guardar.bind(imagem, caminho)))
	_imagens += 1


func _guardar(imagem: Image, caminho: String) -> void:
	var erro := imagem.save_png(caminho)
	if erro != OK:
		printerr("[combate] falhou gravar %s: %s" % [caminho, error_string(erro)])


func _esperar_repouso_apos_morte(limite_frames: int) -> void:
	for _frame: int in maxi(1, limite_frames):
		if _jogador.state == Player.State.FREE:
			return
		await get_tree().physics_frame


func _falhar(texto: String) -> void:
	_falhas += 1
	printerr("[combate] FALHA — %s" % texto)


func _fim() -> void:
	Input.action_release("attack")
	_parar_movimento()
	for tarefa: int in _tarefas:
		WorkerThreadPool.wait_for_task_completion(tarefa)
	get_tree().quit(1 if _falhas > 0 else 0)


func _esperar_fisica(frames: int) -> void:
	for _frame: int in frames:
		await get_tree().physics_frame


func _distancia_plana(a: Vector3, b: Vector3) -> float:
	var delta := b - a
	delta.y = 0.0
	return delta.length()
