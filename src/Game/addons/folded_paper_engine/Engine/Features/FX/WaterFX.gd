class_name WaterFX extends FeatureBase

# Legacy water material (has your Water.png + original behavior)
const MAT_FALLBACK: ShaderMaterial = preload("res://addons/folded_paper_engine/Engine/Features/FX/Water/WaterShader.tres")

# Wobble/adopt shader (keeps target's look when it HAS a texture)
const SH_WOBBLE: Shader = preload("res://addons/folded_paper_engine/Engine/Features/FX/Water/WaterAdopt.gdshader")

func apply(node: Node3D, _data: Variant) -> void:
	if node:
		if not node.is_inside_tree():
			await node.ready
		
		_apply_recursive(node)

func _apply_recursive(n: Node) -> void:
	if n is MeshInstance3D:
		_apply_to_mesh(n as MeshInstance3D)
	
	for c in n.get_children():
		_apply_recursive(c)

func _apply_to_mesh(mi: MeshInstance3D) -> void:
	if mi.mesh and mi.mesh is Mesh:
		var surface_count := mi.mesh.get_surface_count()
		
		for s in range(surface_count):
			var src_mat: Material = mi.get_surface_override_material(s)
			
			if src_mat == null:
				src_mat = mi.mesh.surface_get_material(s)

			# -------- Decide: fallback vs adopt --------
			var use_fallback := false
			var src_has_tex := false
			var out_mat := ShaderMaterial.new()

			if src_mat == null:
				use_fallback = true
			elif src_mat is BaseMaterial3D:
				var b := src_mat as BaseMaterial3D
				
				src_has_tex = b.albedo_texture != null
				use_fallback = not src_has_tex
			elif src_mat is ShaderMaterial:
				var sm := src_mat as ShaderMaterial
				var names := _shader_uniform_names(sm.shader)
				
				if names.has("albedo_texture"):
					var tex := sm.get_shader_parameter("albedo_texture")
					src_has_tex = tex != null
					
				use_fallback = not src_has_tex
			else:
				# Unknown material type -> safest is your legacy water
				use_fallback = true

			if use_fallback:
				# -------- Fallback path (only when source does NOT have a texture) --------
				out_mat = MAT_FALLBACK.duplicate() as ShaderMaterial
			else:
				# -------- Adopt path (only when source HAS a texture) --------
				out_mat.shader = SH_WOBBLE

				if src_mat is BaseMaterial3D:
					var b2 := src_mat as BaseMaterial3D
					out_mat.set_shader_parameter("base_color", b2.albedo_color)
					out_mat.set_shader_parameter("base_albedo_tex", b2.albedo_texture)
					out_mat.set_shader_parameter("uv1_scale", b2.uv1_scale)
					out_mat.set_shader_parameter("uv1_offset", b2.uv1_offset)
				elif src_mat is ShaderMaterial:
					var sm2 := src_mat as ShaderMaterial
					var names2 := _shader_uniform_names(sm2.shader)
					if names2.has("albedo_color"):
						out_mat.set_shader_parameter("base_color", sm2.get_shader_parameter("albedo_color"))
					if names2.has("albedo_texture"):
						out_mat.set_shader_parameter("base_albedo_tex", sm2.get_shader_parameter("albedo_texture"))
					if names2.has("uv1_scale"):
						out_mat.set_shader_parameter("uv1_scale", sm2.get_shader_parameter("uv1_scale"))
					if names2.has("uv1_offset"):
						out_mat.set_shader_parameter("uv1_offset", sm2.get_shader_parameter("uv1_offset"))
			
			mi.set_surface_override_material(s, out_mat)
			
			# IMPORANT: Reapply material mods.
			UserDataUtils.apply_user_data(src_mat, out_mat)
			FEATURE_UTILS.applyMaterialMods(mi)

static func _shader_uniform_names(sh: Shader) -> Dictionary:
	var names := {}
	
	if sh == null:
		return names
	
	for u in sh.get_uniform_list():
		if u.has("name"):
			names[u["name"]] = true
	
	return names
