class_name ShapeGuesser

# Tunables ------------------------------------------------------------
const ROUND_STDDEV_THRESHOLD: float = 0.14   # a bit looser now that we sample faces
const ELONGATION_RATIO: float = 1.5
const AXIS_SIMILARITY: float = 1.15
const BOX_VOLUME_RATIO_THRESHOLD: float = 0.70  # >= -> favor box over sphere when axes ~equal

# --- helpers --------------------------------------------------------------
static func _collect_samples(mesh: Mesh) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var sc: int = mesh.get_surface_count()
	var i: int = 0
	while i < sc:
		var arrays := mesh.surface_get_arrays(i)
		if arrays.size() > Mesh.ARRAY_VERTEX:
			var vtx := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			if vtx != null and vtx.size() > 0:
				# add all vertices
				pts.append_array(vtx)

				# add triangle centroids (catches face centers on cubes)
				var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				if typeof(idx) == TYPE_PACKED_INT32_ARRAY and idx.size() >= 3:
					var j: int = 0
					while j + 2 < idx.size():
						var a: Vector3 = vtx[idx[j]]
						var b: Vector3 = vtx[idx[j + 1]]
						var c: Vector3 = vtx[idx[j + 2]]
						pts.push_back((a + b + c) / 3.0)
						j += 3
		i += 1
	return pts

static func _approx_mesh_volume(mesh: Mesh) -> float:
	# Signed volume via tetrahedra to origin (triangle (a,b,c): dot(a, cross(b, c)) / 6)
	var vol: float = 0.0
	var sc: int = mesh.get_surface_count()
	var i: int = 0
	while i < sc:
		var arrays := mesh.surface_get_arrays(i)
		var vtx := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if typeof(vtx) == TYPE_PACKED_VECTOR3_ARRAY and typeof(idx) == TYPE_PACKED_INT32_ARRAY:
			var j: int = 0
			while j + 2 < idx.size():
				var a: Vector3 = vtx[idx[j]]
				var b: Vector3 = vtx[idx[j + 1]]
				var c: Vector3 = vtx[idx[j + 2]]
				vol += a.dot((b).cross(c)) / 6.0
				j += 3
		i += 1
	return absf(vol)

static func _stdev(values: PackedFloat32Array) -> float:
	var n: int = values.size()
	var result: float = 0.0
	if n > 0:
		var sum: float = 0.0
		var k: int = 0
		while k < n:
			sum += values[k]
			k += 1
		var mean: float = sum / float(n)
		var accum: float = 0.0
		k = 0
		while k < n:
			var dv: float = values[k] - mean
			accum += dv * dv
			k += 1
		result = sqrt(accum / float(n))
	return result

static func _min3(a: float, b: float, c: float) -> float:
	return a if a <= b and a <= c else (b if b <= c else c)

static func get_mesh_offset(mi: MeshInstance3D) -> Vector3:
	var aabb := mi.mesh.get_aabb() if mi and mi.mesh else AABB()
	var center_local := aabb.position + aabb.size * 0.5
	
	return center_local

# Public: returns a best-fit Shape3D; you can also assign it to a CollisionShape3D
static func build_collision_for(target: Node, allow_trimesh_when_thin: bool = true, min_axis_epsilon: float = 0.01, prefer_simple_box: bool = false) -> Shape3D:
	var shape: Shape3D = null
	var box := BoxShape3D.new()
	box.size = Vector3.ONE
	shape = box
	var valid_mesh_instance: bool = target is MeshInstance3D and (target as MeshInstance3D).mesh != null
	
	if valid_mesh_instance:
		var mi: MeshInstance3D = target
		var mesh: Mesh = mi.mesh
		# Use the INSTANCE AABB so scaling/import transforms are reflected.
		var aabb_inst: AABB = mi.get_aabb()
		var size: Vector3 = aabb_inst.size
		# Keep your mesh AABB too (for sampling/volume ratio, etc.)
		var aabb_mesh: AABB = mesh.get_aabb()
		# Clamp near-zero axes to avoid degenerate primitives.
		var sx := size.x if size.x >= min_axis_epsilon else min_axis_epsilon
		var sy := size.y if size.y >= min_axis_epsilon else min_axis_epsilon
		var sz := size.z if size.z >= min_axis_epsilon else min_axis_epsilon

		box.size = Vector3(sx, sy, sz)

		var samples: PackedVector3Array = _collect_samples(mesh)
		var has_samples: bool = samples.size() > 0

		if not prefer_simple_box and has_samples:
			var center: Vector3 = aabb_mesh.position + aabb_mesh.size * 0.5

			var nsx: float = aabb_mesh.size.x if aabb_mesh.size.x != 0.0 else 1.0
			var nsy: float = aabb_mesh.size.y if aabb_mesh.size.y != 0.0 else 1.0
			var nsz: float = aabb_mesh.size.z if aabb_mesh.size.z != 0.0 else 1.0

			var dist3d := PackedFloat32Array()
			var dist_xy := PackedFloat32Array()
			var dist_xz := PackedFloat32Array()
			var dist_yz := PackedFloat32Array()

			for p in samples:
				var q: Vector3 = p - center
				var n := Vector3(q.x / nsx, q.y / nsy, q.z / nsz) * 2.0
				dist3d.push_back(n.length())
				dist_xy.push_back(Vector2(n.x, n.y).length())
				dist_xz.push_back(Vector2(n.x, n.z).length())
				dist_yz.push_back(Vector2(n.y, n.z).length())

			var round_stddev_3d := _stdev(dist3d)
			var round_stddev_xy := _stdev(dist_xy)
			var round_stddev_xz := _stdev(dist_xz)
			var round_stddev_yz := _stdev(dist_yz)

			var w := sx
			var h := sy
			var d := sz
			var s := PackedFloat32Array([w, h, d]); s.sort()
			var min_axis := s[0]
			var mid_axis := s[1]
			var max_axis := s[2]

			var nearly_equal_axes := (max_axis / min_axis) <= AXIS_SIMILARITY
			var elongated := (max_axis / mid_axis) >= ELONGATION_RATIO
			var round_3d := round_stddev_3d <= ROUND_STDDEV_THRESHOLD

			var mesh_vol: float = _approx_mesh_volume(mesh)
			var aabb_vol: float = max(1e-12, aabb_mesh.size.x * aabb_mesh.size.y * aabb_mesh.size.z)
			var volume_ratio: float = mesh_vol / aabb_vol

			var long_is_x := w >= h and w >= d
			var long_is_y := h >= w and h >= d
			var long_is_z := d >= w and d >= h

			var cross_round := false
			if long_is_x:
				cross_round = round_stddev_yz <= ROUND_STDDEV_THRESHOLD
			elif long_is_y:
				cross_round = round_stddev_xz <= ROUND_STDDEV_THRESHOLD
			else:
				cross_round = round_stddev_xy <= ROUND_STDDEV_THRESHOLD

			# If an axis is thin and we allow it, prefer a mesh-based shape (esp. for text glyphs).
			var any_axis_thin := (aabb_mesh.size.x < min_axis_epsilon or aabb_mesh.size.y < min_axis_epsilon or aabb_mesh.size.z < min_axis_epsilon)
			if any_axis_thin and allow_trimesh_when_thin:
				var tri := mesh.create_trimesh_shape()
				if tri != null:
					shape = tri

			# Otherwise, choose a primitive (sphere/capsule/box) using clamped sizes.
			if shape == box:
				if nearly_equal_axes and round_3d and volume_ratio < BOX_VOLUME_RATIO_THRESHOLD:
					var sphere := SphereShape3D.new()
					sphere.radius = max(min_axis * 0.5, min_axis_epsilon * 0.5)
					shape = sphere
				elif elongated and cross_round:
					var capsule := CapsuleShape3D.new()
					var radius := max(min(w, h, d) * 0.5, min_axis_epsilon * 0.5)
					var long_len := max_axis
					capsule.radius = radius
					capsule.height = max(0.0, long_len - (radius * 2.0))
					shape = capsule
				else:
					var box_fit := BoxShape3D.new()
					box_fit.size = Vector3(w, h, d)
					shape = box_fit
		else:
			var box_fallback := BoxShape3D.new()
			box_fallback.size = Vector3(sx, sy, sz)
			shape = box_fallback

	return shape
