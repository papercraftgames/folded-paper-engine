class_name RenderPriorityMod extends MaterialFeatureBase

func apply(material: Material, data: Variant, _mesh_instance: MeshInstance3D) -> void:
	if material is Material and (data is int or data is float):
		var value := int(data)
		
		if value >= material.RENDER_PRIORITY_MIN and value <= material.RENDER_PRIORITY_MAX:
			material.render_priority = value
