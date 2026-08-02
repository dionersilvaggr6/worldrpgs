extends SceneTree
## Auto-teste da camada de rede, contra os numeros do spec/19-rede.md.
##
## Corre: godot --headless --path . --script src/net/net_selftest.gd
## E esta no VERIFICAR.bat — um teste que ninguem corre nao e um teste,
## e um ficheiro (aviso do PARA-O-OPUS-DO-RICO.md, aprendido da maneira dificil).
##
## O QUE ISTO TESTA E O QUE NAO TESTA, dito a serio:
##   testa   — o formato do fio, o orcamento de bytes, a interpolacao, a
##             tolerancia do parry, e dois processos do jogo real na mesma
##             maquina a hospedar/entrar/mostrar/mover os dois corpos
##   NAO testa — duas maquinas em casas diferentes. A porta/VPN e a latencia
##             entre as duas casas so existem quando essas casas participarem.

var _passed := 0
var _failed := 0


func _init() -> void:
	print("\n=== AUTO-TESTE DA REDE (spec/19-rede.md) ===\n")
	_test_protocol_budget()
	_test_body_roundtrip()
	_test_interpolation()
	_test_parry_tolerance()
	_test_link_quality()
	_test_gameplay_two_processes()
	_report()


func _check(ok: bool, what: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		printerr("  FALHOU: %s" % what)


# --- O orcamento de largura de banda -----------------------------------------

func _test_protocol_budget() -> void:
	# O numero da spec: < 30 kbps por sentido com 2 jogadores + <= 5 inimigos.
	var worst := NetProtocol.worst_case_bits_per_second()
	_check(worst < NetProtocol.BANDWIDTH_BUDGET_BPS,
		"pior caso %d bps tem de caber em %d" % [worst, NetProtocol.BANDWIDTH_BUDGET_BPS])
	print("  pior caso previsto: %d bps (tecto %d) — folga de %d%%" % [
		worst, NetProtocol.BANDWIDTH_BUDGET_BPS,
		int(100.0 * (1.0 - float(worst) / NetProtocol.BANDWIDTH_BUDGET_BPS))])

	# O corpo tem de caber nos 18 bytes declarados. Se alguem acrescentar um
	# campo sem pensar, e aqui que da erro — e nao a meio de um chefe.
	var buf := StreamPeerBuffer.new()
	NetProtocol.write_body(buf, 3, Vector3(1, 2, 3), 0.5, 4, 9, 0.5, 1)
	_check(buf.data_array.size() == NetProtocol.BODY_BYTES,
		"um corpo ocupa %d bytes (declarado: %d)" % [
			buf.data_array.size(), NetProtocol.BODY_BYTES])

	# A 20 Hz com 1 corpo, o custo tem de ser folgado — e o caso do co-op a dois
	# sem inimigos, que e o que mais tempo dura numa sessao.
	_check(NetProtocol.snapshot_bits_per_second(1) < 5000,
		"um corpo sozinho custa pouco")


# --- O formato do fio --------------------------------------------------------

func _test_body_roundtrip() -> void:
	var buf := StreamPeerBuffer.new()
	var pos := Vector3(12.5, 3.25, -8.125)  # exactos em binario, sem erro de virgula
	NetProtocol.write_body(buf, 7, pos, 1.5, 3, 42, 0.5,
		NetProtocol.BodyFlag.INVULNERABLE | NetProtocol.BodyFlag.BLOCKING)
	buf.seek(0)
	var got := NetProtocol.read_body(buf)

	_check(got["id"] == 7, "id sobrevive ao fio")
	_check((got["position"] as Vector3).is_equal_approx(pos), "posicao sobrevive ao fio")
	_check(absf(float(got["yaw"]) - 1.5) < 0.01, "yaw sobrevive (float16 chega para um angulo)")
	_check(got["state"] == 3, "estado sobrevive")
	_check(got["frame"] == 42, "frame sobrevive")
	_check(absf(float(got["health_fraction"]) - 0.5) < 0.01, "vida em 8 bits chega para uma barra")
	_check(int(got["flags"]) & NetProtocol.BodyFlag.INVULNERABLE != 0, "bandeira de invencivel sobrevive")
	_check(int(got["flags"]) & NetProtocol.BodyFlag.BLOCKING != 0, "bandeira de bloqueio sobrevive")


# --- A interpolacao ----------------------------------------------------------

func _test_interpolation() -> void:
	var interp := NetInterpolator.new()
	# Tres instantaneos a 20 Hz, o corpo a andar em linha recta a 1 m por tick.
	for i in range(3):
		var t := float(i) * NetProtocol.SNAPSHOT_INTERVAL
		interp.push(t, t, {
			"position": Vector3(float(i), 0, 0), "yaw": 0.0,
			"state": 0, "frame": 0, "health_fraction": 1.0, "flags": 0,
		})

	# Pedir o instante do MEIO entre o 1.o e o 2.o instantaneo (25 ms depois do
	# primeiro) tem de dar meio metro. Se der 0 ou 1, nao ha interpolacao
	# nenhuma — ha saltos.
	var mid := interp.sample_at(0.025 + NetProtocol.INTERPOLATION_DELAY)
	_check(not mid.is_empty(), "ha pose a devolver")
	var x := (mid.get("position", Vector3.ZERO) as Vector3).x
	_check(absf(x - 0.5) < 0.05, "interpola a meio caminho (deu %.3f, esperava 0,5)" % x)

	# NAO extrapolar: pedir muito para a frente tem de congelar no ultimo,
	# nunca continuar a deslizar sozinho.
	var future := interp.sample_at(10.0)
	_check(absf((future.get("position", Vector3.ZERO) as Vector3).x - 2.0) < 0.001,
		"congela no ultimo conhecido em vez de extrapolar")

	# O caminho curto do angulo: de 170 para -170 graus sao 20 graus, nao 340.
	var a := deg_to_rad(170.0)
	var b := deg_to_rad(-170.0)
	var half := NetInterpolator._lerp_angle(a, b, 0.5)
	var dist := absf(rad_to_deg(fposmod(half - deg_to_rad(180.0) + PI, TAU) - PI))
	_check(dist < 1.0, "o yaw interpola pelo caminho curto (deu %.1f graus de desvio)" % dist)

	# Fora de ordem deita-se fora, em vez de estragar o historico.
	var before := interp.sample_count()
	interp.push(0.0, 0.0, {"position": Vector3(99, 0, 0)})
	_check(interp.sample_count() == before, "instantaneo atrasado e descartado")


# --- A tolerancia do parry ---------------------------------------------------

func _test_parry_tolerance() -> void:
	var active := 10.0
	_check(NetProtocol.parry_report_is_timely(active + 0.05, active),
		"parry a 50 ms aceita-se")
	_check(NetProtocol.parry_report_is_timely(active + 0.150, active),
		"parry no limite exacto de 150 ms aceita-se")
	_check(not NetProtocol.parry_report_is_timely(active + 0.200, active),
		"parry a 200 ms ja nao conta (linha ma, nao batota)")
	_check(not NetProtocol.parry_report_is_timely(active - 0.010, active),
		"parry ANTES do frame activo nao conta")


# --- A qualidade da linha ----------------------------------------------------

func _test_link_quality() -> void:
	var q := NetLinkQuality.new()
	var t := 0.0

	# Linha boa: nada de avisos.
	for i in range(10):
		t += 1.0
		q.add_sample(40.0, t)
	_check(not q.should_warn(t), "linha de 40 ms nao avisa")
	_check(q.quality(t) == NetLinkQuality.Quality.BOA, "40 ms e linha boa")

	# Um pico solto NAO pode acender o aviso — senao pisca a meio de um chefe.
	t += 1.0
	q.add_sample(400.0, t)
	_check(not q.should_warn(t), "um pico solto nao acende o aviso")

	# Ma de forma sustentada: ai sim.
	for i in range(20):
		t += 1.0
		q.add_sample(400.0, t)
	_check(q.should_warn(t), "400 ms sustentados acendem o aviso")
	_check(q.describe(t).contains("instável"), "o aviso e uma frase em portugues")

	# Silencio longo = ligacao perdida, nao um jogo a fingir que esta bem.
	_check(q.quality(t + NetProtocol.STALL_GIVE_UP_S + 1.0) == NetLinkQuality.Quality.PERDIDA,
		"silencio acima de 10 s conta como perdida")


# --- A prova que arranca o jogo ----------------------------------------------

func _test_gameplay_two_processes() -> void:
	var output: Array = []
	var args := PackedStringArray([
		"--headless", "--audio-driver", "Dummy",
		"--path", ProjectSettings.globalize_path("res://"),
		"res://src/coop/coop_online_gameplay_proof.tscn",
	])
	var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
	if not output.is_empty():
		var child_output := String(output[0]).strip_edges()
		for line: String in child_output.split("\n", false):
			if line.begins_with("=== CO-OP") or line.begins_with("PASS:") \
					or line.begins_with("anfitriao:") \
					or line.begins_with("convidado:") \
					or line.begins_with("saves:"):
				print("  " + line)
	_check(exit_code == 0,
		"jogo real: F3, Hospedar/Entrar, duas origens, dois corpos e movimento remoto")


func _report() -> void:
	print("\n=== %d passaram, %d falharam ===\n" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
