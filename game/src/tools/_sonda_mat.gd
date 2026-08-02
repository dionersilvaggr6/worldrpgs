extends Node
const GAMEPLAY := preload("res://scenes/gameplay.tscn")
func _ready() -> void:
	add_child(GAMEPLAY.instantiate())
	_ver.call_deferred()
func _ver() -> void:
	for _i in 120: await get_tree().process_frame
	var jog := get_tree().get_first_node_in_group("player")
	if jog == null:
		printerr("[sonda] sem jogador"); get_tree().quit(1); return
	for m: Node in jog.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if not mi.is_in_group("armor_visual_piece"): continue
		var over := mi.get_surface_override_material(0)
		var base = mi.mesh.surface_get_material(0) if mi.mesh and mi.mesh.get_surface_count()>0 else null
		var tem_tex := "?"
		if over is ShaderMaterial:
			tem_tex = str((over as ShaderMaterial).get_shader_parameter("use_albedo_texture"))
		print("[sonda] %s | override=%s | base=%s | use_albedo_texture=%s" % [
			mi.name, over.get_class() if over else "NENHUM",
			base.get_class() if base else "NENHUM", tem_tex])
	get_tree().quit(0)
