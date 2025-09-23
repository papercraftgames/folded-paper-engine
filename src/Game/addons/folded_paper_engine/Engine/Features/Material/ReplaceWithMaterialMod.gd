class_name ReplaceWithMaterialMod extends MaterialFeatureBase

func apply(_material: Material, data: Variant, mesh_instance: MeshInstance3D) -> void:
	if data is String and is_instance_of(mesh_instance, MeshInstance3D):
		mesh_instance.material_override = load(data) as Material
