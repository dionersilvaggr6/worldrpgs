class_name SpellCastVfx
extends Node3D
## Luz de compromisso presa ao foco real. E apenas antecipacao/confirmacao:
## nunca declara uma hitbox e desaparece se a conjuracao for interrompida.

var _bundle: Dictionary = {}
var _cast_duration_s := 0.0
var _linger_s := 0.0
var _elapsed_s := 0.0
var _committed := false
var _core := MeshInstance3D.new()
var _halo := MeshInstance3D.new()


func configure(bundle: Dictionary, cast_duration_s: float,
		commit_frames: int, tip_position: Vector3) -> void:
	_bundle = bundle.duplicate()
	_cast_duration_s = maxf(cast_duration_s, 0.0)
	_linger_s = float(maxi(commit_frames, 1)) / float(Engine.physics_ticks_per_second)
	top_level = true
	name = "SpellCastVfx_%s" % String(bundle.get("spell_id", "unknown"))
	global_position = tip_position
	add_to_group("spell_cast_vfx")

	var mesh := bundle.get("mesh") as Mesh
	var material := bundle.get("material") as StandardMaterial3D
	var render: Dictionary = bundle.get("render", {}) as Dictionary
	_core.mesh = mesh
	_core.material_override = material
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_core.scale = Vector3.ONE * float(render.get("core_scale", 0.0))
	add_child(_core)

	var halo_material := material.duplicate() as StandardMaterial3D
	var halo_color := halo_material.albedo_color
	halo_color.a = float(render.get("halo_alpha", 0.0))
	if String(bundle.get("school", "")) == "mal":
		# A escola vermelha usa sangue escuro, sem o branco heroico do impacto azul.
		halo_color = halo_color.darkened(float(render.get("core_scale", 0.0)))
	halo_material.albedo_color = halo_color
	halo_material.emission = halo_color
	_halo.mesh = mesh
	_halo.material_override = halo_material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.scale = Vector3.ONE * float(render.get("halo_scale", 0.0))
	add_child(_halo)


func _process(delta: float) -> void:
	_elapsed_s += delta
	var render: Dictionary = _bundle.get("render", {}) as Dictionary
	var core_scale := float(render.get("core_scale", 0.0))
	var halo_scale := float(render.get("halo_scale", 0.0))
	if _committed:
		var amount := clampf(_elapsed_s / maxf(_linger_s, delta), 0.0, 1.0)
		_core.scale = Vector3.ONE * lerpf(halo_scale, core_scale, amount)
		_halo.scale = Vector3.ONE * lerpf(halo_scale + core_scale, halo_scale, amount)
		if _elapsed_s >= _linger_s:
			queue_free()
		return
	var charge := clampf(_elapsed_s / maxf(_cast_duration_s, delta), 0.0, 1.0)
	_core.scale = Vector3.ONE * lerpf(core_scale, halo_scale, charge)
	_halo.scale = Vector3.ONE * lerpf(halo_scale, core_scale + halo_scale, charge)
	if _elapsed_s > _cast_duration_s + _linger_s:
		queue_free()


func sync_tip(tip_position: Vector3) -> void:
	if not _committed:
		global_position = tip_position


func commit(tip_position: Vector3) -> void:
	global_position = tip_position
	_committed = true
	_elapsed_s = 0.0


func cancel() -> void:
	queue_free()


func is_visible_flash() -> bool:
	return visible and _core.visible and _halo.visible


func tip_position() -> Vector3:
	return global_position
