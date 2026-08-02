extends Node3D
## Apresenta um evento informativo por dois canais independentes (spec/62).
## A geometria no mundo mostra origem/área/vector; o indicador de bordo mantém
## direcção e resposta quando a origem sai do ecrã. O áudio pode estar a zero e
## este nó continua a existir com exactamente o mesmo relógio.
##
## Esta pegada é também a única autoridade espacial do dano: Enemy pergunta a
## este nó se o alvo está dentro da forma, em vez de reconstruir um cone oculto.

const CURVE_SEGMENTS := 24

var _attack: Dictionary = {}
var _source: Node3D
var _frame := 0
var _danger_end_frame := 0
var _cancel_frames := -1
var _world_mark: MeshInstance3D
var _world_glyph: Label3D
var _edge_glyph: Label
var _material: StandardMaterial3D
var _footprint := PackedVector2Array()


func configure(source: Node3D, attack: Dictionary) -> void:
	_source = source
	_attack = attack


func _ready() -> void:
	top_level = true
	_sync_to_source()
	_danger_end_frame = int(_attack.get("startup")) + int(_attack.get("active"))
	_danger_end_frame = int(_attack["startup"]) + int(_attack["active"])
	_build_world_mark()
	_build_edge_mark()
	var sound: Dictionary = _attack.get("som_anuncio", {}) as Dictionary
	Sfx.play(String(sound.get("profile", "attack_dodge")), global_position, -4.0, 0.02)


func _physics_process(_delta: float) -> void:
	_frame += 1
	if is_instance_valid(_source):
		_sync_to_source()
	_update_pulse()
	_update_edge_mark()
	if _cancel_frames >= 0:
		_cancel_frames -= 1
		if _cancel_frames <= 0:
			queue_free()
	elif _frame > _danger_end_frame:
		queue_free()


func cancel() -> void:
	# 0,15 s a 60 Hz: a forma quebra, em vez de continuar a prometer o ataque.
	_cancel_frames = 9
	if is_instance_valid(_world_glyph):
		_world_glyph.text = "×"


## A pergunta pública de colisão usa o mesmo polígono que foi entregue ao mesh.
## O eixo Y não entra: a marca no chão descreve a pegada horizontal do golpe.
func covers_world_point(world_point: Vector3) -> bool:
	if _footprint.size() < 3:
		return false
	var local_point := to_local(world_point)
	return Geometry2D.is_point_in_polygon(
		Vector2(local_point.x, local_point.z), _footprint)


func _sync_to_source() -> void:
	if not is_instance_valid(_source):
		return
	# A faixa tem de apontar para onde o golpe ficou comprometido; posição sem
	# orientação desenharia uma mentira sempre que o inimigo não estivesse a norte.
	global_transform = Transform3D(_source.global_transform.basis.orthonormalized(), _source.global_position)


func _build_world_mark() -> void:
	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(0.92, 0.18, 0.16, 0.32)
	_material.emission_enabled = true
	_material.emission = Color(0.92, 0.18, 0.16)
	_material.emission_energy_multiplier = 0.7
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_world_mark = MeshInstance3D.new()
	_footprint = _build_footprint()
	_world_mark.mesh = _mesh_from_footprint(_footprint)
	_world_mark.position.y = 0.035
	var contact := String(_attack.get("tipo_contacto", "instantaneo"))
	if bool(_attack.get("is_aoe", false)) or contact == "volume_persistente":
		var disc := CylinderMesh.new()
		var radius := float(_attack["radius"])
		disc.top_radius = radius
		disc.bottom_radius = radius
		disc.height = 0.025
		disc.radial_segments = 32
		_world_mark.mesh = disc
		_world_mark.position.y = 0.035
	else:
		var lane := BoxMesh.new()
		var reach := maxf(float(_attack["range"]), float(_attack.get("lunge_distance", 0.0)))
		lane.size = Vector3(0.12 if contact == "instantaneo" else 0.34, 0.025, reach)
		_world_mark.mesh = lane
		_world_mark.position = Vector3(0.0, 0.035, -reach * 0.5)
	_world_mark.material_override = _material
	add_child(_world_mark)

	_world_glyph = Label3D.new()
	_world_glyph.text = _glyph_for_attack()
	_world_glyph.font_size = 96
	_world_glyph.outline_size = 18
	_world_glyph.modulate = Color.WHITE
	_world_glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_world_glyph.no_depth_test = true
	_world_glyph.position = Vector3(0.0, 2.35, 0.0)
	add_child(_world_glyph)


func _build_footprint() -> PackedVector2Array:
	var contact := String(_attack.get("tipo_contacto"))
	if bool(_attack.get("is_aoe", false)) or contact == "volume_persistente":
		return _disc_footprint(float(_attack.get("radius")))

	var reach := float(_attack.get("range"))
	if _attack.has("lunge_distance"):
		reach = maxf(reach, float(_attack.get("lunge_distance")))
	if contact == "volume_movel":
		var half_width := float(_attack.get("projectile_radius_m", 0.0))
		if half_width <= 0.0 and is_instance_valid(_source) \
				and _source.get("body_radius") != null:
			half_width = float(_source.get("body_radius"))
		return PackedVector2Array([
			Vector2(-half_width, 0.0), Vector2(half_width, 0.0),
			Vector2(half_width, -reach), Vector2(-half_width, -reach),
		])
	return _sector_footprint(reach, float(_attack.get("arc_degrees")))


func _disc_footprint(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in CURVE_SEGMENTS:
		var angle := TAU * float(step) / float(CURVE_SEGMENTS)
		points.append(Vector2(sin(angle), -cos(angle)) * radius)
	return points


func _sector_footprint(reach: float, arc_degrees: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var half_arc := deg_to_rad(arc_degrees) * 0.5
	for step: int in CURVE_SEGMENTS + 1:
		var progress := float(step) / float(CURVE_SEGMENTS)
		var angle := lerpf(-half_arc, half_arc, progress)
		points.append(Vector2(sin(angle), -cos(angle)) * reach)
	return points


func _mesh_from_footprint(points: PackedVector2Array) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var indices := Geometry2D.triangulate_polygon(points)
	if indices.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	for point: Vector2 in points:
		vertices.append(Vector3(point.x, 0.0, point.y))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_edge_mark() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_edge_glyph = Label.new()
	_edge_glyph.text = _glyph_for_attack()
	_edge_glyph.add_theme_font_size_override("font_size", 42)
	_edge_glyph.add_theme_color_override("font_color", Color.WHITE)
	_edge_glyph.add_theme_color_override("font_outline_color", Color(0.25, 0.0, 0.0, 0.95))
	_edge_glyph.add_theme_constant_override("outline_size", 8)
	_edge_glyph.visible = false
	layer.add_child(_edge_glyph)


func _update_pulse() -> void:
	var startup := maxi(int(_attack["startup"]), 1)
	var t := clampf(float(_frame) / float(startup), 0.0, 1.0)
	var pulse := 0.35 + 0.65 * t
	_material.albedo_color.a = pulse * 0.42
	_material.emission_energy_multiplier = 0.55 + pulse * 1.25
	var scale_value := 0.82 + 0.18 * t
	_world_glyph.scale = Vector3.ONE * scale_value
	if String(_attack.get("tipo_contacto", "")) == "volume_persistente" and _frame > startup:
		var interval := maxi(int(_attack["damage_interval_frames"]), 1)
		var tick_t := float((_frame - startup) % interval) / float(interval)
		_material.albedo_color.a = 0.20 + tick_t * 0.30


func _update_edge_mark() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_edge_glyph.visible = false
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var screen := camera.unproject_position(global_position + Vector3.UP * 1.5)
	var behind := camera.is_position_behind(global_position + Vector3.UP * 1.5)
	var margin := Vector2(52.0, 52.0)
	var outside := behind or screen.x < margin.x or screen.y < margin.y \
		or screen.x > viewport_size.x - margin.x or screen.y > viewport_size.y - margin.y
	_edge_glyph.visible = outside
	_world_glyph.visible = not outside
	if not outside:
		return
	if behind:
		screen = viewport_size - screen
	screen.x = clampf(screen.x, margin.x, viewport_size.x - margin.x)
	screen.y = clampf(screen.y, margin.y, viewport_size.y - margin.y)
	_edge_glyph.position = screen - _edge_glyph.size * 0.5


func _glyph_for_attack() -> String:
	var vectors: Array = _attack.get("vectores_fuga", []) as Array
	if vectors.has("aparar"):
		return "><"
	if vectors.has("sair_da_area") or vectors.has("rolar_para_fora"):
		return "◎"
	if vectors.has("sair_da_linha"):
		return "↔"
	if vectors.has("quebrar_a_visao"):
		return "◉"
	if vectors.has("bloquear_e_aguentar"):
		return "▥"
	return "◇"
