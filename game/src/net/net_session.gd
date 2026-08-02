extends Node
## A camada de rede: hospedar, entrar, replicar corpos, entregar golpes.
##
## Fonte: spec/19-rede.md, que esta fechado. Nada aqui volta a decidir o que
## esta la decidido — isto implementa-o.
##
## AS TRES REGRAS QUE MANDAM NESTE FICHEIRO:
##
## 1. AUTORIDADE DIVIDIDA. O anfitriao manda no mundo (inimigos, chefes, portas,
##    espolio). Cada jogador manda no PROPRIO CORPO — os seus i-frames, o seu
##    parry, a sua stamina. spec/19: "se um golpe me acertou, decido eu, com o
##    meu relogio". Isto nao e desleixo: com 60-100 ms de ida e volta, uma
##    esquiva avaliada do outro lado da linha PARECE BATOTA CONTRA O JOGADOR,
##    e os 317 ms de i-frames perdem essa margem. Entre dois amigos que nao
##    fazem batota, confiar e a compensacao de latencia mais barata que existe.
##
## 2. AGNOSTICO AO TRANSPORTE. Isto liga-se a um endereco. De onde esse endereco
##    vem — porta aberta no router ou VPN de amigos — nao e problema do jogo.
##    E o que permite trocar de transporte mais tarde sem partir nada.
##
## 3. SEM FALHAS SILENCIOSAS. Toda a falha de ligacao produz uma frase em
##    portugues para o ecra. Nunca um codigo de erro: quem esta a jogar precisa
##    de saber o que fazer a seguir, nao de um numero para procurar na net.

signal hosting_started(port: int)
signal joined(peer_id: int)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal session_ended(reason: String)
signal connection_failed(reason: String)
signal link_warning(message: String)
signal combat_event(event_type: int, payload: Dictionary)
signal peer_profile_received(peer_id: int, profile: Dictionary)

const COOP_PLAYER_RUNTIME_SCRIPT = preload("res://src/coop/coop_player_runtime.gd")

enum Role { OFFLINE, ANFITRIAO, CONVIDADO }

const DEFAULT_PORT := 27015

var role := Role.OFFLINE
var last_error := ""
var link := NetLinkQuality.new()
## Mantem a porta decidida pela spec no jogo. Provas paralelas podem escolher
## outra antes de carregar nos mesmos botoes, sem disputar a 27015 entre arvores.
var connection_port := DEFAULT_PORT

## Corpos remotos, por id de peer. Cada um com o seu interpolador.
var _remote: Dictionary = {}
var _snapshot_accumulator := 0.0
var _ping_accumulator := 0.0
var _ping_sent_at: Dictionary = {}
var _ping_seq := 0
var _warned := false

## O que este cliente reporta sobre o proprio corpo. O jogo preenche-o;
## a rede so o transporta. Manter isto como dicionario simples e o que impede
## a rede de ficar agarrada ao Player — e o que a torna testavel sem cena.
var local_body: Dictionary = {
	"position": Vector3.ZERO, "yaw": 0.0, "state": 0,
	"frame": 0, "health_fraction": 1.0, "flags": 0,
}
var local_profile: Dictionary = {}
var _remote_profiles: Dictionary = {}

## Bytes enviados desde o inicio da sessao — para a medicao ser real e nao fe.
var bytes_sent := 0
var bytes_received := 0
var _session_start := 0.0
var _player_runtime: CoopPlayerRuntime


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_player_runtime = COOP_PLAYER_RUNTIME_SCRIPT.new() as CoopPlayerRuntime
	_player_runtime.name = "CoopPlayerRuntime"
	add_child(_player_runtime)
	_player_runtime.setup(self)
	set_process(false)


# --- Hospedar e entrar -------------------------------------------------------
# spec/19, criterio 1 da fatia: "entrar numa sessao: < 2 min, sem editar
# ficheiros". Por isso isto sao duas funcoes com um argumento cada.

func host(port: int = 0) -> bool:
	if role != Role.OFFLINE:
		_fail("Já estás numa sessão. Sai primeiro.")
		return false
	var target_port := connection_port if port <= 0 else port
	var peer := ENetMultiplayerPeer.new()
	# MAX_PLAYERS - 1: a spec fixa DOIS jogadores exactamente, e o anfitriao
	# ja conta. Recusar o terceiro aqui e mais honesto do que o deixar entrar
	# e partir-se num sitio qualquer mais a frente.
	var err := peer.create_server(target_port, NetProtocol.MAX_PLAYERS - 1)
	if err != OK:
		_fail(_explain_host_error(err, target_port))
		return false
	multiplayer.multiplayer_peer = peer
	role = Role.ANFITRIAO
	_begin_session()
	hosting_started.emit(target_port)
	return true


func join(address: String, port: int = 0) -> bool:
	if role != Role.OFFLINE:
		_fail("Já estás numa sessão. Sai primeiro.")
		return false
	var target_port := connection_port if port <= 0 else port
	var clean := address.strip_edges()
	if clean.is_empty():
		_fail("Falta o endereço do teu parceiro.")
		return false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(clean, target_port)
	if err != OK:
		_fail("Não consegui ligar a %s. Confirma o endereço e se ele já está a hospedar." % clean)
		return false
	multiplayer.multiplayer_peer = peer
	role = Role.CONVIDADO
	_begin_session()
	return true


func leave(reason: String = "Saíste da sessão.") -> void:
	if role == Role.OFFLINE:
		return
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = Role.OFFLINE
	_remote.clear()
	_remote_profiles.clear()
	link.reset()
	_warned = false
	set_process(false)
	session_ended.emit(reason)


func is_online() -> bool:
	return role != Role.OFFLINE


func is_host() -> bool:
	return role == Role.ANFITRIAO


## O anfitriao manda no mundo. Quem pergunta "posso decidir isto?" sobre um
## inimigo, um chefe ou uma porta, pergunta aqui.
func has_world_authority() -> bool:
	return role != Role.CONVIDADO


func _begin_session() -> void:
	bytes_sent = 0
	bytes_received = 0
	_session_start = _now()
	_snapshot_accumulator = 0.0
	_ping_accumulator = 0.0
	link.reset()
	set_process(true)


func _fail(message: String) -> void:
	last_error = message
	push_warning("[rede] " + message)
	connection_failed.emit(message)


func _explain_host_error(err: int, port: int) -> String:
	# Uma frase que diz o que fazer, nao o que aconteceu.
	if err == ERR_ALREADY_IN_USE:
		return "A porta %d já está ocupada. Fecha o outro jogo, ou escolhe outra porta." % port
	if err == ERR_CANT_CREATE:
		return "Não consegui abrir a porta %d. O antivírus ou a firewall podem estar a travar." % port
	return "Não consegui hospedar na porta %d." % port


# --- Relogio -----------------------------------------------------------------

func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


# --- O ciclo -----------------------------------------------------------------

func _process(delta: float) -> void:
	if role == Role.OFFLINE:
		return

	_snapshot_accumulator += delta
	if _snapshot_accumulator >= NetProtocol.SNAPSHOT_INTERVAL:
		_snapshot_accumulator = 0.0
		_send_body()

	# Um ping por segundo chega: a media movel do NetLinkQuality precisa de
	# amostras regulares, nao de muitas.
	_ping_accumulator += delta
	if _ping_accumulator >= 1.0:
		_ping_accumulator = 0.0
		_send_ping()

	_check_link()


func _check_link() -> void:
	var now := _now()
	var warn := link.should_warn(now)
	# So se avisa na TRANSICAO. Emitir todos os frames enchia o log e o ecra.
	if warn and not _warned:
		_warned = true
		link_warning.emit(link.describe(now))
	elif not warn and _warned:
		_warned = false
		link_warning.emit("")

	if link.quality(now) == NetLinkQuality.Quality.PERDIDA:
		leave("A ligação caiu. Voltaste ao teu mundo, com tudo o que ganhaste.")


# --- Replicacao de corpo (20 Hz, nao fiavel) ---------------------------------

func _send_body() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.get_peers().is_empty():
		return
	var buf := StreamPeerBuffer.new()
	buf.put_float(_now())
	NetProtocol.write_body(buf, 0,
		local_body.get("position", Vector3.ZERO),
		float(local_body.get("yaw", 0.0)),
		int(local_body.get("state", 0)),
		int(local_body.get("frame", 0)),
		float(local_body.get("health_fraction", 1.0)),
		int(local_body.get("flags", 0)))
	var data := buf.data_array
	bytes_sent += data.size()
	_receive_body.rpc(data)


@rpc("any_peer", "unreliable_ordered", "call_remote", 1)
func _receive_body(data: PackedByteArray) -> void:
	var sender := multiplayer.get_remote_sender_id()
	bytes_received += data.size()
	var buf := StreamPeerBuffer.new()
	buf.data_array = data
	var host_time := buf.get_float()
	var body := NetProtocol.read_body(buf)
	if not _remote.has(sender):
		_remote[sender] = NetInterpolator.new()
	(_remote[sender] as NetInterpolator).push(host_time, _now(), body)


## A pose do parceiro, ja atrasada os 100 ms da spec. Devolve {} se ainda
## nao houver historico.
func remote_body(peer_id: int) -> Dictionary:
	if not _remote.has(peer_id):
		return {}
	return (_remote[peer_id] as NetInterpolator).sample_at(_now())


## O primeiro (e unico) parceiro. Com dois jogadores exactamente, "o outro"
## e uma pergunta com uma resposta.
func partner_id() -> int:
	var peers := multiplayer.get_peers()
	return peers[0] if not peers.is_empty() else 0


func partner_body() -> Dictionary:
	var id := partner_id()
	return remote_body(id) if id != 0 else {}


# --- Identidade visual (fiavel) ----------------------------------------------

## A pose cabe no canal de 20 Hz; a identidade muda raramente e tem de chegar.
## Envia apenas ids de catalogo, nunca caminhos nem recursos arbitrarios.
func set_local_profile(profile: Dictionary) -> bool:
	var versioned := profile.duplicate(true)
	versioned["protocol_version"] = NetProtocol.VERSION
	var normalized := _normalise_profile(versioned)
	if normalized.is_empty():
		return false
	local_profile = normalized
	if is_online() and not multiplayer.get_peers().is_empty():
		_receive_profile.rpc(local_profile)
	return true


func remote_profile(peer_id: int) -> Dictionary:
	return (_remote_profiles.get(peer_id, {}) as Dictionary).duplicate(true)


func partner_profile() -> Dictionary:
	var id := partner_id()
	return remote_profile(id) if id != 0 else {}


func _normalise_profile(profile: Dictionary) -> Dictionary:
	if int(profile.get("protocol_version", -1)) != NetProtocol.VERSION:
		return {}
	var profile_id := String(profile.get("profile_id", "")).strip_edges()
	var class_id := String(profile.get("class_id", "")).strip_edges()
	var classes := GameData.attributes.get("classes", {}) as Dictionary
	if profile_id.is_empty() or class_id.is_empty() or class_id.begins_with("_") \
			or not classes.has(class_id):
		return {}
	var body_id := String(profile.get("body_id", "body_male")).strip_edges()
	if body_id.is_empty():
		body_id = "body_male"
	var appearance_options := GameData.appearance.get("options", {}) as Dictionary
	var body_ids := appearance_options.get("body_id", []) as Array
	if not body_id in body_ids:
		return {}
	return {
		"protocol_version": NetProtocol.VERSION,
		"profile_id": profile_id,
		"class_id": class_id,
		"body_id": body_id,
	}


func _send_profile_to(peer_id: int) -> void:
	if peer_id == 0 or local_profile.is_empty():
		return
	_receive_profile.rpc_id(peer_id, local_profile)


@rpc("any_peer", "reliable", "call_remote", 2)
func _receive_profile(profile: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	var normalized := _normalise_profile(profile)
	if normalized.is_empty():
		var message := ("As versões dos dois jogos são diferentes. Actualizem os dois antes de voltar a entrar."
			if int(profile.get("protocol_version", -1)) != NetProtocol.VERSION
			else "Não consegui mostrar o corpo do teu parceiro porque o aspecto ou a origem dele não existe neste jogo.")
		_fail(message)
		call_deferred("leave", message)
		return
	if (_remote_profiles.get(sender, {}) as Dictionary) == normalized:
		return
	_remote_profiles[sender] = normalized
	peer_profile_received.emit(sender, normalized.duplicate(true))


# --- Eventos de combate (fiaveis, imediatos) ---------------------------------
# spec/19: "eventos fiaveis e imediatos para golpes, parries e aggro".
# Um golpe que nao conta e a Lei 1 quebrada — por isso estes vao no canal
# fiavel, mesmo custando mais quando ha perda.

func send_event(event_type: int, payload: Dictionary = {}) -> void:
	if not is_online():
		return
	if multiplayer.get_peers().is_empty():
		return
	payload = payload.duplicate()
	payload["t"] = _now()
	_receive_event.rpc(event_type, payload)


@rpc("any_peer", "reliable", "call_remote", 2)
func _receive_event(event_type: int, payload: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	var enriched := payload.duplicate()
	enriched["from"] = sender

	# A regra da autoridade, aplicada a chegada em vez de espalhada pelo codigo.
	if not _event_is_allowed(event_type, sender):
		push_warning("[rede] evento %d recusado ao peer %d (autoridade)" % [event_type, sender])
		return

	combat_event.emit(event_type, enriched)


## Quem pode dizer o quê. spec/19, tabela da autoridade.
func _event_is_allowed(event_type: int, sender: int) -> bool:
	match event_type:
		# O proprio corpo e sempre do proprio. Ninguem contesta a esquiva de
		# ninguem — e a decisao central da spec.
		NetProtocol.Event.DAMAGE_TAKEN, NetProtocol.Event.PARRY, \
		NetProtocol.Event.DODGE_WINDOW, NetProtocol.Event.DEATH, \
		NetProtocol.Event.FLASK, NetProtocol.Event.SPELL_CAST, \
		NetProtocol.Event.HIT_LANDED:
			return true
		# O mundo e do anfitriao. Se um convidado anuncia que um chefe mudou de
		# fase, ha um bug — ou pior. Recusa-se, e diz-se alto.
		NetProtocol.Event.AGGRO, NetProtocol.Event.BOSS_PHASE, \
		NetProtocol.Event.ENEMY_DIED, NetProtocol.Event.REVIVE:
			return _sender_is_host(sender)
	return false


func _sender_is_host(sender: int) -> bool:
	# No ENet do Godot o anfitriao e sempre o peer 1.
	return sender == 1


## O parry do convidado aceita-se dentro da tolerancia da spec. A regra vive no
## NetProtocol (e do fio, e tem de ser testavel sem sessao aberta); isto e so a
## porta por onde o codigo de combate lhe chega.
func parry_report_is_timely(reported_at: float, active_frame_at: float) -> bool:
	return NetProtocol.parry_report_is_timely(reported_at, active_frame_at)


# --- Ping --------------------------------------------------------------------

func _send_ping() -> void:
	if multiplayer.multiplayer_peer == null or multiplayer.get_peers().is_empty():
		return
	_ping_seq = (_ping_seq + 1) % 65536
	_ping_sent_at[_ping_seq] = _now()
	link.mark_sent()
	_ping.rpc(_ping_seq)


@rpc("any_peer", "unreliable", "call_remote", 3)
func _ping(seq: int) -> void:
	_pong.rpc_id(multiplayer.get_remote_sender_id(), seq)


@rpc("any_peer", "unreliable", "call_remote", 3)
func _pong(seq: int) -> void:
	if not _ping_sent_at.has(seq):
		return
	var rtt := (_now() - float(_ping_sent_at[seq])) * 1000.0
	_ping_sent_at.erase(seq)
	link.add_sample(rtt, _now())


# --- Largura de banda --------------------------------------------------------

## Bits por segundo medidos desde o inicio da sessao. E o numero que prova
## (ou desmente) o tecto de 30 kbps da spec — medido, nao estimado.
func measured_bits_per_second() -> float:
	var elapsed := _now() - _session_start
	if elapsed <= 0.0:
		return 0.0
	return float(bytes_sent) * 8.0 / elapsed


# --- Sinais do multiplayer ---------------------------------------------------

func _on_peer_connected(id: int) -> void:
	# A spec fixa dois jogadores. O ENet ja recusa o terceiro pelo limite do
	# create_server, mas se algum dia isso mudar, isto e a segunda porta.
	if multiplayer.get_peers().size() >= NetProtocol.MAX_PLAYERS:
		if is_host():
			multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	_remote[id] = NetInterpolator.new()
	_send_profile_to(id)
	peer_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	_remote.erase(id)
	_remote_profiles.erase(id)
	peer_disconnected.emit(id)
	if is_host():
		# spec/19: o mundo continua. Quem fica nao herda uma luta de dois —
		# quem reescala o chefe e o codigo do chefe, ao ouvir este sinal.
		session_ended.emit("O teu parceiro saiu. O mundo continua.")


func _on_connected_ok() -> void:
	_send_profile_to(1)
	joined.emit(multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	role = Role.OFFLINE
	multiplayer.multiplayer_peer = null
	set_process(false)
	_fail("Não consegui entrar. Confirma que ele está a hospedar e que o endereço está certo.")


func _on_server_disconnected() -> void:
	leave("O anfitrião saiu. Voltaste ao teu mundo, com tudo o que ganhaste.")
