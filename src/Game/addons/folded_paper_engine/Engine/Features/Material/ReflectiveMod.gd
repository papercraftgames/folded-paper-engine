## ReflectiveMod.gd
class_name ReflectiveMod extends MaterialFeatureBase

# --- probe + layers ---------------------------------------------------------
const PROBE_NAME: StringName = &"_EnvProbe"

# Dedicated layer bit for “only this mesh receives reflections from this probe”.
# 3D has 20 layers → bit index 0..19. We’ll use the top bit by default (Layer 20).
const PRIVATE_LAYER_BIT: int = 19
const PRIVATE_LAYER_MASK: int = 1 << PRIVATE_LAYER_BIT
const ALL_LAYERS_MASK: int = (1 << 20) - 1

# Probe sizing: assume ~1 m objects; capture at least a 2 m cube; scale up for big meshes.
const BASE_CAPTURE_EDGE: float = 2.0
const CAPTURE_MULT: float = 4.0
const MIN_EDGE: float = 0.25
const PROBE_RESOLUTION: int = 128  # cheap & fine for moving probes

# --- helpers ----------------------------------------------------------------
static func _has_prop(obj: Object, name: StringName) -> bool:
	var found := false
	if obj != null:
		for d in obj.get_property_list():
			var n := d.get("name", "")
			if n is String and n == String(name):
				found = true
	return found

static func _get_or_create_probe(host: Node3D) -> ReflectionProbe:
	var probe: ReflectionProbe = null
	if host != null:
		for c in host.get_children():
			if c is ReflectionProbe:
				probe = c
				break
		if probe == null:
			probe = ReflectionProbe.new()
			probe.name = PROBE_NAME
			host.add_child(probe)
			if host.get_owner() != null:
				probe.owner = host.get_owner()
	return probe

static func _compute_cube(aabb_size: Vector3) -> Vector3:
	var dmax := max(aabb_size.x, max(aabb_size.y, aabb_size.z))
	var edge := max(BASE_CAPTURE_EDGE, dmax * CAPTURE_MULT)
	edge = max(edge, MIN_EDGE)
	return Vector3(edge, edge, edge)

static func _apply_probe_settings(
		probe: ReflectionProbe,
		center_local: Vector3,
		cube_size: Vector3,
		intensity: float,
		reflection_mask: int,
		capture_mask: int) -> void:
	if probe != null:
		probe.position = center_local

		# Size/Extents (defensive for older exports)
		if _has_prop(probe, &"size"):
			probe.set("size", cube_size)
		if _has_prop(probe, &"extents"):
			probe.set("extents", cube_size * 0.5)

		if _has_prop(probe, &"box_projection"):
			probe.set("box_projection", true)
		if _has_prop(probe, &"update_mode"):
			probe.set("update_mode", ReflectionProbe.UPDATE_ALWAYS)
		if _has_prop(probe, &"interior"):
			probe.set("interior", false)
		if _has_prop(probe, &"resolution"):
			probe.set("resolution", PROBE_RESOLUTION)
		if _has_prop(probe, &"intensity"):
			probe.set("intensity", clamp(intensity, 0.0, 2.0))

		# ⬇️ The key: who is AFFECTED vs who is CAPTURED
		if _has_prop(probe, &"reflection_mask"):
			probe.set("reflection_mask", reflection_mask)   # only our mesh receives this probe
		if _has_prop(probe, &"cull_mask"):
			probe.set("cull_mask", capture_mask)            # environment (and NOT our private layer)

# Optional gentle tuning so reflections read on dielectrics (keeps StandardMaterial3D)
static func _tune_standard_level(stdm: StandardMaterial3D, level: float) -> void:
	if stdm == null:
		return
	var L := clamp(level, 0.0, 1.0)
	var rough := lerp(0.60, 0.15, L)
	var metal := min(0.08, L * 0.08)
	var cc    := L
	var cc_r  := lerp(0.30, 0.08, L)

	if _has_prop(stdm, &"transparency") and stdm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		stdm.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	if _has_prop(stdm, &"alpha_scissor_threshold") and stdm.alpha_scissor_threshold != 0.0:
		stdm.alpha_scissor_threshold = 0.0
	if _has_prop(stdm, &"shading_mode"):
		stdm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	if _has_prop(stdm, &"roughness"):
		stdm.roughness = rough
	if _has_prop(stdm, &"metallic"):
		stdm.metallic = metal
	if _has_prop(stdm, &"clearcoat"):
		stdm.clearcoat = cc
	if _has_prop(stdm, &"clearcoat_roughness"):
		stdm.clearcoat_roughness = cc_r

	stdm.resource_local_to_scene = true

# --- main API ---------------------------------------------------------------
func apply(material: Material, data: Variant, mesh_instance: MeshInstance3D) -> void:
	# Only act if 'data' is a float (your requirement).
	if data is float:
		var level: float = clamp(float(data), 0.0, 1.0)

		# 0) Give this mesh a private layer bit so ONLY it can receive this probe.
		if mesh_instance != null and is_instance_valid(mesh_instance):
			mesh_instance.layers = mesh_instance.layers | PRIVATE_LAYER_MASK

		# 1) Ensure probe exists, sized, and isolated to this mesh via reflection_mask.
		var mesh_ok := mesh_instance != null and is_instance_valid(mesh_instance) and mesh_instance.mesh != null
		if mesh_ok:
			var aabb := mesh_instance.mesh.get_aabb()
			var center := aabb.position + aabb.size * 0.5
			var cube := _compute_cube(aabb.size)

			var probe := _get_or_create_probe(mesh_instance)   # child → moves with object
			# Capture everything EXCEPT our private layer (so we don't reflect ourselves).
			var capture_mask := ALL_LAYERS_MASK & ~PRIVATE_LAYER_MASK
			_apply_probe_settings(
				probe,
				center,
				cube,
				lerp(0.8, 1.4, level),
				PRIVATE_LAYER_MASK,
				capture_mask
			)

			# 2) Optionally nudge every StandardMaterial3D used by this mesh (keeps it StandardMaterial3D)
			var surface_count := mesh_instance.mesh.get_surface_count()
			for i in range(surface_count):
				var surf_mat: Material = mesh_instance.get_surface_override_material(i)
				if surf_mat == null:
					surf_mat = mesh_instance.mesh.surface_get_material(i)
				if surf_mat is StandardMaterial3D:
					var std := surf_mat as StandardMaterial3D
					if not std.resource_local_to_scene:
						std = std.duplicate() as StandardMaterial3D
						std.resource_local_to_scene = true
						mesh_instance.set_surface_override_material(i, std)
					_tune_standard_level(std, level)

		# 3) Also respect the standalone 'material' if it's a StandardMaterial3D (kept as-is).
		if material is StandardMaterial3D:
			var m := material as StandardMaterial3D
			if not m.resource_local_to_scene:
				m.resource_local_to_scene = true
			_tune_standard_level(m, level)
