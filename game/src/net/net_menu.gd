class_name NetMenu
extends CanvasLayer
## Hospedar ou entrar, em menos de dois minutos e sem editar ficheiros.
##
## Fonte: spec/19-rede.md — é o critério 1 da fatia, e é um critério de
## **tempo do jogador**, não de arquitectura. Por isso este ecrã tem exactamente
## dois botões e uma caixa de texto: hospedar, entrar, e onde.
##
## ⭐ A REGRA QUE MANDA AQUI: nenhuma falha mostra um código de erro.
## Quem está a jogar precisa de saber o que fazer a seguir. "ERR_CANT_CREATE"
## não é informação — "a porta está ocupada, fecha o outro jogo" é.

const PANEL_WIDTH := 420
const PANEL_HEIGHT := 300

var _session: Node
var _root: Control
var _status: Label
var _address: LineEdit
var _host_button: Button
var _join_button: Button
var _leave_button: Button
var _own_address: Label


func _ready() -> void:
	layer = 95
	_session = get_node_or_null("/root/NetSession")
	_build()
	if _session != null:
		_session.hosting_started.connect(_on_hosting_started)
		_session.joined.connect(_on_joined)
		_session.peer_connected.connect(_on_peer_connected)
		_session.peer_disconnected.connect(_on_peer_disconnected)
		_session.connection_failed.connect(_on_failed)
		_session.session_ended.connect(_on_ended)
	visible = false


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Jogar a dois"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var explain := Label.new()
	explain.text = "Um de vocês hospeda. O outro escreve o endereço e entra.\nO mundo que jogam é o de quem hospeda."
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explain.add_theme_font_size_override("font_size", 13)
	box.add_child(explain)

	_host_button = Button.new()
	_host_button.text = "Hospedar"
	_host_button.pressed.connect(_on_host_pressed)
	box.add_child(_host_button)

	_own_address = Label.new()
	_own_address.add_theme_font_size_override("font_size", 13)
	_own_address.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_own_address.visible = false
	box.add_child(_own_address)

	var sep := HSeparator.new()
	box.add_child(sep)

	_address = LineEdit.new()
	_address.placeholder_text = "endereço do teu parceiro"
	box.add_child(_address)

	_join_button = Button.new()
	_join_button.text = "Entrar"
	_join_button.pressed.connect(_on_join_pressed)
	box.add_child(_join_button)

	_leave_button = Button.new()
	_leave_button.text = "Sair da sessão"
	_leave_button.pressed.connect(_on_leave_pressed)
	_leave_button.visible = false
	box.add_child(_leave_button)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 13)
	box.add_child(_status)


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	var online: bool = _session != null and _session.is_online()
	_host_button.visible = not online
	_join_button.visible = not online
	_address.visible = not online
	_leave_button.visible = online


func _on_host_pressed() -> void:
	if _session == null:
		_status.text = "A rede não arrancou. Fecha e volta a abrir o jogo; se continuar, envia esta frase ao Mateus."
		return
	_status.text = "A abrir a porta…"
	_session.host()


func _on_join_pressed() -> void:
	if _session == null:
		_status.text = "A rede não arrancou. Fecha e volta a abrir o jogo; se continuar, envia esta frase ao Mateus."
		return
	_status.text = "A ligar…"
	_session.join(_address.text)


func _on_leave_pressed() -> void:
	if _session != null:
		_session.leave()


func _on_hosting_started(port: int) -> void:
	_status.text = "À espera do teu parceiro."
	# ⭐ Mostrar o proprio endereco poupa metade do tempo dos "2 minutos":
	# sem isto, o anfitriao tem de ir procurar o IP a algum lado.
	_own_address.text = ("Na mesma rede, diz-lhe para escrever:  %s\n"
		+ "Em casas diferentes, usem o endereço do Tailscale/ZeroTier; "
		+ "ou abre a porta UDP %d e dita o teu endereço público.") % [_local_hint(port), port]
	_own_address.visible = true
	_refresh()


## Os enderecos desta maquina, para o anfitriao ler em voz alta ao telefone.
## Na mesma casa serve o da rede local. O IP publico nao aparece nesta lista;
## o texto acima diz isso em vez de fingir que o jogo consegue descobri-lo.
func _local_hint(port: int) -> String:
	var out: Array[String] = []
	for ip: String in IP.get_local_addresses():
		if ip.begins_with("127.") or ip.contains(":"):
			continue  # sem loopback e sem IPv6, que ninguem dita ao telefone
		out.append(ip)
	if out.is_empty():
		return "o teu endereço, porta %d" % port
	return "%s   (porta %d)" % [", ".join(out), port]


func _on_joined(_id: int) -> void:
	_status.text = "Entraste. Bom jogo."
	_refresh()
	# O menu fecha-se sozinho: ficar aberto por cima do jogo depois de a
	# ligacao pegar e um passo a mais que ninguem pediu.
	await get_tree().create_timer(1.2).timeout
	visible = false


func _on_peer_connected(_id: int) -> void:
	_status.text = "O teu parceiro entrou."
	_own_address.visible = false
	await get_tree().create_timer(1.2).timeout
	visible = false


func _on_peer_disconnected(_id: int) -> void:
	_status.text = "O teu parceiro saiu."
	_refresh()


func _on_failed(reason: String) -> void:
	_status.text = reason
	_refresh()


func _on_ended(reason: String) -> void:
	_status.text = reason
	_own_address.visible = false
	_refresh()
