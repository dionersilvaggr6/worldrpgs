extends "res://src/tools/percurso.gd"
## O percurso antigo inferia morte apenas quando o Node deixava de ser valido.
## Enemy conserva o cadaver para a apresentacao e a necromancia; o contrato
## publico de morte e, por isso, o sinal `died`, nao `queue_free()`.


func _contar(no: Node3D) -> void:
	super(no)
	var ao_morrer := Callable(self, "_ao_inimigo_morrer")
	if no.has_signal("died") and not no.is_connected("died", ao_morrer):
		no.connect("died", ao_morrer)


func _ao_inimigo_morrer(_inimigo: Enemy) -> void:
	_mortos += 1
