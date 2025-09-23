class_name CharacterAI extends CharacterControls

# =============================================================================
# CHARACTER AI PATHFINDING SYSTEM WITH PERIMETER BOUNDARY PROTECTION
# =============================================================================
# This system provides intelligent AI character movement with the following features:
# - Automatic perimeter detection from mesh boundaries
# - Safe pathfinding that never crosses perimeter edges
# - Dynamic waypoint generation inside safe areas
# - Robust line intersection detection
# - Character movement state management
# =============================================================================

# =============================================================================
# CORE DEPENDENCIES
# =============================================================================
var BOUNDS: Node3D                                     # Reference to bounds mesh node

# =============================================================================
# PATHFINDING CONFIGURATION
# =============================================================================
var path_points: Array[Vector3] = []                   # Current path waypoints
var current_path_index: int = 0                        # Index of current target waypoint
var path_timer: float = 0.0                           # Timer for path regeneration
var path_update_interval: float = 10.0                # How often to pick new paths (seconds)
var visit_distance: float = 0.2                       # Distance to consider waypoint "reached"
var distance_threshold: float = 4.0                   # Maximum distance between consecutive waypoints

# =============================================================================
# CORE PATHFINDING DATA (INVISIBLE - NO VISUALS)
# =============================================================================
var available_waypoints: Array[Vector3] = []          # All valid pathfinding waypoints (invisible)
var perimeter_boundary: Array[Array] = []             # Perimeter edges for boundary detection (invisible)
var bounds_vertices: PackedVector3Array = []          # All mesh vertices in world space
var bounds_edges: Array[Array] = []                   # All mesh edges as vertex index pairs
var bounds_min: Vector2                               # 2D bounding box minimum
var bounds_max: Vector2                               # 2D bounding box maximum

# =============================================================================
# MOVEMENT CONFIGURATION
# =============================================================================
var max_speed: float = 0.5                            # Maximum movement speed
var min_speed: float = 0.1                            # Minimum movement speed
var speed_distance_threshold: float = 2.0             # Distance threshold for speed calculations

# =============================================================================
# MOVEMENT STATE MANAGEMENT
# =============================================================================
var current_movement_direction: Vector2 = Vector2.ZERO # Locked movement direction to prevent shaking
var direction_change_threshold: float = 0.3           # Threshold for changing movement direction

# =============================================================================
# STUCK DETECTION SYSTEM
# =============================================================================
var stuck_detection_timer: float = 0.0                # Timer for stuck detection
var stuck_check_interval: float = 2.0                 # How often to check for stuck state
var last_position: Vector2 = Vector2.ZERO             # Previous position for stuck detection
var min_expected_movement: float = 0.1                # Minimum expected movement distance

# =============================================================================
# IDLE BEHAVIOR SYSTEM
# =============================================================================
var is_idling_between_points: bool = false            # Whether character is idling between waypoints
var idle_timer: float = 0.0                          # Current idle timer
var idle_duration: float = 3.0                       # How long to idle between waypoints

# =============================================================================
# LEGACY VARIABLES (kept for compatibility)
# =============================================================================
var direction_change_timer: float = 0.0               # Legacy direction change timer
var direction_change_interval: float = 2.0            # Legacy direction change interval
var current_input: Vector2 = Vector2.ZERO             # Legacy input vector
var stuck_threshold_time: float = 3.0                 # Legacy stuck threshold

func _ready() -> void:
	super._ready()
	
	if CHARACTER_CONFIG and CHARACTER_CONFIG.WanderingBounds:
		BOUNDS = NodeUtils.find_node_by_name(get_tree().current_scene, CHARACTER_CONFIG.WanderingBounds)
		
		_analyze_bounds_mesh()

# =============================================================================
# MAIN UPDATE LOOP
# =============================================================================
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Update path regeneration timer
	path_timer += delta
	
	# Regenerate path every X seconds to keep movement dynamic
	if path_timer >= path_update_interval:
		path_timer = 0.0
		is_idling_between_points = false
		idle_timer = 0.0
		
		# Reset all movement state to prevent old input from carrying over
		current_movement_direction = Vector2.ZERO
		stuck_detection_timer = 0.0
		last_position = Vector2(global_position.x, global_position.z)
		
		_pick_new_path()
	
	# Handle idle periods between waypoints
	if is_idling_between_points:
		idle_timer += delta
		
		# Keep character stationary during idle
		move(Vector2.ZERO, 0.0, 0.0)
		
		# Check if idle period is complete
		if idle_timer >= idle_duration:
			is_idling_between_points = false
			idle_timer = 0.0
		return
	
	# Execute pathfinding movement or idle if no path available
	if path_points.size() > 0 and current_path_index < path_points.size():
		_move_towards_current_target(delta)
	else:
		# No active path - keep character stationary
		move(Vector2.ZERO, 0.0, 0.0)

# =============================================================================
# PATHFINDING MOVEMENT EXECUTION
# =============================================================================
func _move_towards_current_target(delta: float) -> void:
	# Get current target waypoint and character position
	var current_target = path_points[current_path_index]
	var character_pos = global_position
	
	# Calculate 2D distance to target (ignore Y axis for ground-based movement)
	var char_pos_2d = Vector2(character_pos.x, character_pos.z)
	var target_pos_2d = Vector2(current_target.x, current_target.z)
	var distance_to_target = char_pos_2d.distance_to(target_pos_2d)
	
	# === STUCK DETECTION SYSTEM ===
	stuck_detection_timer += delta
	if stuck_detection_timer >= stuck_check_interval:
		var movement_distance = char_pos_2d.distance_to(last_position)
		
		# If character hasn't moved enough, consider it stuck and skip to next waypoint
		if movement_distance < min_expected_movement and current_movement_direction != Vector2.ZERO:
			# Skip to next waypoint in path
			current_path_index += 1
			current_movement_direction = Vector2.ZERO
			
			# Check if we've completed the entire path
			if current_path_index >= path_points.size():
				path_points.clear()
				current_path_index = 0
				current_movement_direction = Vector2.ZERO
				
				# Stop character movement when path is complete
				move(Vector2.ZERO, 0.0, 0.0)
			
			# Reset stuck detection system
			stuck_detection_timer = 0.0
			last_position = char_pos_2d
			return
		
		# Update stuck detection state
		stuck_detection_timer = 0.0
		last_position = char_pos_2d
	
	# === WAYPOINT ARRIVAL CHECK ===
	if distance_to_target <= visit_distance:
		# Waypoint reached - advance to next one
		current_path_index += 1
		
		# Reset movement state for clean transition
		current_movement_direction = Vector2.ZERO
		stuck_detection_timer = 0.0
		last_position = char_pos_2d
		
		# Check if we've completed the entire path
		if current_path_index >= path_points.size():
			path_points.clear()
			current_path_index = 0
			current_movement_direction = Vector2.ZERO
			
			# Stop character movement when path is complete
			move(Vector2.ZERO, 0.0, 0.0)
		else:
			# More waypoints remaining - start idle period between waypoints
			is_idling_between_points = true
			idle_timer = 0.0
		return
	
	# === MOVEMENT DIRECTION CALCULATION ===
	var direction_to_target = (target_pos_2d - char_pos_2d).normalized()
	var speed_factor = max_speed  # Use consistent maximum speed
	
	# Determine primary movement direction (cardinal directions only to prevent diagonal drift)
	var new_direction = Vector2.ZERO
	if abs(direction_to_target.x) > abs(direction_to_target.y):
		# Horizontal movement is dominant
		new_direction = Vector2(1, 0) if direction_to_target.x > 0 else Vector2(-1, 0)
	else:
		# Vertical movement is dominant
		new_direction = Vector2(0, 1) if direction_to_target.y > 0 else Vector2(0, -1)
	
	# === DIRECTION LOCKING SYSTEM (prevents movement shaking) ===
	if current_movement_direction == Vector2.ZERO:
		# No direction set yet - use the calculated direction
		current_movement_direction = new_direction
		last_position = char_pos_2d
	elif abs(direction_to_target.x) > abs(direction_to_target.y) + direction_change_threshold and current_movement_direction.y != 0:
		# Strong horizontal preference - switch from vertical to horizontal
		current_movement_direction = new_direction
	elif abs(direction_to_target.y) > abs(direction_to_target.x) + direction_change_threshold and current_movement_direction.x != 0:
		# Strong vertical preference - switch from horizontal to vertical
		current_movement_direction = new_direction
	
	# === APPLY MOVEMENT ===
	var movement_input = current_movement_direction * speed_factor
	move(movement_input, 0.0, 0.0)

# =============================================================================
# PATH GENERATION SYSTEM
# =============================================================================
func _pick_new_path() -> void:
	# Ensure we have enough waypoints for pathfinding
	if available_waypoints.size() < 3:
		return
	
	# Reset all movement state for clean path transition
	path_points.clear()
	current_path_index = 0
	current_movement_direction = Vector2.ZERO
	stuck_detection_timer = 0.0
	
	# Stop character movement immediately during path change
	move(Vector2.ZERO, 0.0, 0.0)
	
	# Find starting point near character's current position
	var character_pos = global_position
	var character_pos_2d = Vector2(character_pos.x, character_pos.z)
	last_position = character_pos_2d
	
	var nearest_point = _find_nearest_waypoint_to_position(character_pos)
	if nearest_point == Vector3.INF:
		return
	
	# Attempt to create a valid 3-waypoint path with perimeter safety
	var max_attempts = 50
	var attempt = 0
	
	while path_points.size() < 3 and attempt < max_attempts:
		attempt += 1
		path_points.clear()
		
		# Start path from nearest waypoint to character
		var remaining_points = available_waypoints.duplicate()
		var current_point = nearest_point
		path_points.append(current_point)
		remaining_points.erase(current_point)
		
		# Build path by finding connected waypoints
		var valid_path = true
		for i in range(2):  # Need 2 more points for 3-point path
			var next_point = _find_next_waypoint_in_range(current_point, remaining_points)
			
			if next_point != Vector3.INF:
				path_points.append(next_point)
				remaining_points.erase(next_point)
				current_point = next_point
			else:
				valid_path = false
				break
		
		# Validate complete path for perimeter safety
		if path_points.size() == 3 and valid_path:
			var path_valid = true
			
			# Check every path segment for perimeter crossings
			for i in range(path_points.size() - 1):
				if _path_crosses_perimeter(path_points[i], path_points[i + 1]):
					path_valid = false
					break
			
			if path_valid:
				break  # Successfully created valid path
	
	# Handle path creation failure
	if path_points.size() < 3:
		# Clean up failed path attempt
		path_points.clear()
		current_path_index = 0
		current_movement_direction = Vector2.ZERO
		
		# Stop character movement when no valid path available
		move(Vector2.ZERO, 0.0, 0.0)

# =============================================================================
# WAYPOINT CONNECTION SYSTEM
# =============================================================================
func _find_next_waypoint_in_range(from_point: Vector3, candidates: Array[Vector3]) -> Vector3:
	var valid_points: Array[Vector3] = []
	
	# Find all candidate waypoints within range that don't cross perimeter
	for point in candidates:
		var distance = Vector2(from_point.x, from_point.z).distance_to(Vector2(point.x, point.z))
		
		if distance <= distance_threshold:
			# Check if direct path to this point crosses the perimeter boundary
			if not _path_crosses_perimeter(from_point, point):
				valid_points.append(point)
	
	# Return random valid waypoint, or failure indicator
	if valid_points.size() > 0:
		var chosen = valid_points[randi() % valid_points.size()]
		return chosen
	else:
		return Vector3.INF  # No valid points found

# =============================================================================
# BOUNDS MESH ANALYSIS SYSTEM
# =============================================================================
func _analyze_bounds_mesh() -> void:
	if not BOUNDS:
		return
	
	# Find MeshInstance3D component
	var mesh_instance: MeshInstance3D = null
	
	if BOUNDS is MeshInstance3D:
		mesh_instance = BOUNDS as MeshInstance3D
	else:
		# Look for MeshInstance3D child
		for child in BOUNDS.get_children():
			if child is MeshInstance3D:
				mesh_instance = child as MeshInstance3D
				break
	
	if not mesh_instance or not mesh_instance.mesh:
		return
	
	# Process mesh to generate core pathfinding data (invisible)
	_extract_vertices_and_edges_from_mesh(mesh_instance)
	_detect_perimeter_boundary()
	_generate_pathfinding_waypoints()

# =============================================================================
# MESH GEOMETRY EXTRACTION
# =============================================================================
func _extract_vertices_and_edges_from_mesh(mesh_instance: MeshInstance3D) -> void:
	var mesh = mesh_instance.mesh
	var surface_count = mesh.get_surface_count()
	
	# Clear previous data
	bounds_vertices.clear()
	bounds_edges.clear()
	var all_vertices: PackedVector3Array = []
	var vertex_offset = 0
	
	# Process each mesh surface
	for surface_idx in range(surface_count):
		var arrays = mesh.surface_get_arrays(surface_idx)
		if not arrays[Mesh.ARRAY_VERTEX] or not arrays[Mesh.ARRAY_INDEX]:
			continue
			
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		
		# Transform vertices to world space
		var transform = mesh_instance.global_transform
		for vertex in vertices:
			var world_vertex = transform * vertex
			all_vertices.append(world_vertex)
		
		# Extract edges from triangles
		for i in range(0, indices.size(), 3):
			var v1 = indices[i] + vertex_offset
			var v2 = indices[i + 1] + vertex_offset  
			var v3 = indices[i + 2] + vertex_offset
			
			# Add the three edges of each triangle
			_add_edge(v1, v2)
			_add_edge(v2, v3)
			_add_edge(v3, v1)
		
		vertex_offset += vertices.size()
	
	bounds_vertices = all_vertices
	
	# Calculate 2D bounding rectangle for waypoint generation
	if bounds_vertices.size() > 0:
		bounds_min = Vector2(bounds_vertices[0].x, bounds_vertices[0].z)
		bounds_max = bounds_min
		
		for vertex in bounds_vertices:
			bounds_min.x = min(bounds_min.x, vertex.x)
			bounds_min.y = min(bounds_min.y, vertex.z)
			bounds_max.x = max(bounds_max.x, vertex.x)
			bounds_max.y = max(bounds_max.y, vertex.z)

func _add_edge(v1: int, v2: int) -> void:
	# Create normalized edge (smaller index first) to prevent duplicates
	var edge = [min(v1, v2), max(v1, v2)]
	
	# Check if edge already exists
	for existing_edge in bounds_edges:
		if existing_edge[0] == edge[0] and existing_edge[1] == edge[1]:
			return
	
	bounds_edges.append(edge)

# =============================================================================
# PERIMETER BOUNDARY DETECTION
# =============================================================================
func _detect_perimeter_boundary() -> void:
	perimeter_boundary.clear()
	
	# Count how many triangles use each edge
	var edge_count: Dictionary = {}
	
	# Get mesh instance for triangle processing
	var mesh_instance: MeshInstance3D = BOUNDS as MeshInstance3D
	if not mesh_instance:
		for child in BOUNDS.get_children():
			if child is MeshInstance3D:
				mesh_instance = child as MeshInstance3D
				break
	
	if not mesh_instance or not mesh_instance.mesh:
		return
	
	var mesh = mesh_instance.mesh
	var vertex_offset = 0
	
	# Process each mesh surface to count edge usage
	for surface_idx in range(mesh.get_surface_count()):
		var arrays = mesh.surface_get_arrays(surface_idx)
		if not arrays[Mesh.ARRAY_VERTEX] or not arrays[Mesh.ARRAY_INDEX]:
			continue
			
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		
		# Count edge usage in triangles
		for i in range(0, indices.size(), 3):
			var v1 = indices[i] + vertex_offset
			var v2 = indices[i + 1] + vertex_offset
			var v3 = indices[i + 2] + vertex_offset
			
			_count_edge_usage(edge_count, v1, v2)
			_count_edge_usage(edge_count, v2, v3)
			_count_edge_usage(edge_count, v3, v1)
		
		vertex_offset += vertices.size()
	
	# Edges used by only one triangle are perimeter edges (boundary)
	for edge_key in edge_count.keys():
		if edge_count[edge_key] == 1:
			var vertices_indices = edge_key.split(",")
			var v1 = int(vertices_indices[0])
			var v2 = int(vertices_indices[1])
			perimeter_boundary.append([v1, v2])

func _count_edge_usage(edge_count: Dictionary, v1: int, v2: int) -> void:
	# Create normalized edge key for counting
	var key = str(min(v1, v2)) + "," + str(max(v1, v2))
	
	if key in edge_count:
		edge_count[key] += 1
	else:
		edge_count[key] = 1

# =============================================================================
# WAYPOINT GENERATION SYSTEM (INVISIBLE)
# =============================================================================
func _generate_pathfinding_waypoints() -> void:
	if bounds_vertices.size() == 0 or perimeter_boundary.size() == 0:
		return
	
	available_waypoints.clear()
	
	var target_waypoints = 50           # Number of waypoints to generate
	var waypoints_created = 0
	var safety_margin = 0.3            # Distance from perimeter edge
	var min_spacing = 2.0              # Minimum distance between waypoints
	var max_attempts = target_waypoints * 30
	
	var attempts = 0
	var placed_positions: Array[Vector2] = []
	
	# Method 1: Random placement with safety checks
	while waypoints_created < target_waypoints and attempts < max_attempts:
		attempts += 1
		
		# Generate random position within bounds
		var random_x = randf_range(bounds_min.x + safety_margin, bounds_max.x - safety_margin)
		var random_z = randf_range(bounds_min.y + safety_margin, bounds_max.y - safety_margin)
		var test_point = Vector2(random_x, random_z)
		
		# Check if point is safely inside perimeter with proper spacing
		if _is_point_safely_inside_perimeter(test_point, safety_margin):
			var too_close = false
			for existing_pos in placed_positions:
				if test_point.distance_to(existing_pos) < min_spacing:
					too_close = true
					break
			
			if not too_close:
				# Add invisible waypoint to pathfinding system
				available_waypoints.append(Vector3(random_x, 7.945, random_z))
				placed_positions.append(test_point)
				waypoints_created += 1
	
	# Method 2: Grid-based placement if needed
	if waypoints_created < target_waypoints * 0.5:
		var grid_size = 20
		var step_x = (bounds_max.x - bounds_min.x) / grid_size
		var step_z = (bounds_max.y - bounds_min.y) / grid_size
		
		for x in range(grid_size):
			for z in range(grid_size):
				if waypoints_created >= target_waypoints:
					break
				
				var pos_x = bounds_min.x + x * step_x
				var pos_z = bounds_min.y + z * step_z
				var test_point = Vector2(pos_x, pos_z)
				
				if _is_point_safely_inside_perimeter(test_point, safety_margin):
					var too_close = false
					for existing_pos in placed_positions:
						if test_point.distance_to(existing_pos) < min_spacing:
							too_close = true
							break
					
					if not too_close:
						# Add invisible waypoint to pathfinding system
						available_waypoints.append(Vector3(pos_x, 7.945, pos_z))
						placed_positions.append(test_point)
						waypoints_created += 1
			
			if waypoints_created >= target_waypoints:
				break

# =============================================================================
# GEOMETRIC POINT-IN-POLYGON TESTING
# =============================================================================
func _is_point_inside_shape(point: Vector2) -> bool:
	# Compatibility function - redirects to polygon testing
	return _is_point_inside_perimeter_polygon(point)

func _is_point_inside_perimeter_polygon(point: Vector2) -> bool:
	if perimeter_boundary.size() == 0:
		return false
	
	var polygon_points = _get_ordered_perimeter_points()
	if polygon_points.size() < 3:
		return false
	
	# Ray casting algorithm: count intersections with polygon edges
	var intersections = 0
	var ray_y = point.y
	
	for i in range(polygon_points.size()):
		var p1 = polygon_points[i]
		var p2 = polygon_points[(i + 1) % polygon_points.size()]
		
		# Check if edge crosses the horizontal ray
		if ((p1.y > ray_y) != (p2.y > ray_y)):
			var intersection_x = (p2.x - p1.x) * (ray_y - p1.y) / (p2.y - p1.y) + p1.x
			
			# Count intersections to the right of the point
			if intersection_x > point.x:
				intersections += 1
	
	# Point is inside if odd number of intersections
	return (intersections % 2) == 1

func _get_ordered_perimeter_points() -> Array[Vector2]:
	if perimeter_boundary.size() == 0:
		return []
	
	# Convert 3D vertices to 2D
	var vertex_2d_map: Dictionary = {}
	for i in range(bounds_vertices.size()):
		vertex_2d_map[i] = Vector2(bounds_vertices[i].x, bounds_vertices[i].z)
	
	# Build adjacency list from perimeter edges
	var adjacency: Dictionary = {}
	for edge in perimeter_boundary:
		var v1 = edge[0]
		var v2 = edge[1]
		
		if not adjacency.has(v1):
			adjacency[v1] = []
		if not adjacency.has(v2):
			adjacency[v2] = []
		
		adjacency[v1].append(v2)
		adjacency[v2].append(v1)
	
	# Find leftmost point as starting point
	var start_vertex = -1
	var leftmost_x = INF
	for vertex_idx in adjacency.keys():
		var pos = vertex_2d_map[vertex_idx]
		if pos.x < leftmost_x:
			leftmost_x = pos.x
			start_vertex = vertex_idx
	
	if start_vertex == -1:
		return []
	
	# Traverse perimeter to get ordered points
	var ordered_points: Array[Vector2] = []
	var current_vertex = start_vertex
	var previous_vertex = -1
	var visited: Dictionary = {}
	
	while true:
		if current_vertex in visited:
			break
		
		visited[current_vertex] = true
		ordered_points.append(vertex_2d_map[current_vertex])
		
		# Find next unvisited neighbor
		var next_vertex = -1
		for neighbor in adjacency[current_vertex]:
			if neighbor != previous_vertex:
				next_vertex = neighbor
				break
		
		if next_vertex == -1 or next_vertex == start_vertex:
			break
		
		previous_vertex = current_vertex
		current_vertex = next_vertex
	
	return ordered_points

func _is_point_safely_inside_perimeter(point: Vector2, safety_margin: float = 0.5) -> bool:
	# First check if point is inside the polygon
	if not _is_point_inside_perimeter_polygon(point):
		return false
	
	# Then check distance from all perimeter edges
	var min_distance_to_perimeter = INF
	
	for edge in perimeter_boundary:
		var v1_idx = edge[0]
		var v2_idx = edge[1]
		
		if v1_idx >= bounds_vertices.size() or v2_idx >= bounds_vertices.size():
			continue
		
		var v1_2d = Vector2(bounds_vertices[v1_idx].x, bounds_vertices[v1_idx].z)
		var v2_2d = Vector2(bounds_vertices[v2_idx].x, bounds_vertices[v2_idx].z)
		
		var distance = _distance_point_to_line_segment(point, v1_2d, v2_2d)
		min_distance_to_perimeter = min(min_distance_to_perimeter, distance)
	
	return min_distance_to_perimeter >= safety_margin

func _distance_point_to_line_segment(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	
	var line_len_squared = line_vec.length_squared()
	if line_len_squared == 0:
		return point_vec.length()
	
	var t = point_vec.dot(line_vec) / line_len_squared
	t = clamp(t, 0.0, 1.0)
	
	var projection = line_start + t * line_vec
	return point.distance_to(projection)

# =============================================================================
# LINE INTERSECTION DETECTION SYSTEM
# =============================================================================
func _path_crosses_perimeter(point1: Vector3, point2: Vector3) -> bool:
	var path_start = Vector2(point1.x, point1.z)
	var path_end = Vector2(point2.x, point2.z)
	
	# Check intersection with each perimeter edge
	for edge in perimeter_boundary:
		var v1_idx = edge[0]
		var v2_idx = edge[1]
		
		if v1_idx >= bounds_vertices.size() or v2_idx >= bounds_vertices.size():
			continue
		
		var edge_start = Vector2(bounds_vertices[v1_idx].x, bounds_vertices[v1_idx].z)
		var edge_end = Vector2(bounds_vertices[v2_idx].x, bounds_vertices[v2_idx].z)
		
		# Test if path line segment intersects perimeter edge
		if _line_segments_intersect_robust(path_start, path_end, edge_start, edge_end):
			return true
	
	return false

func _line_segments_intersect_robust(p1: Vector2, q1: Vector2, p2: Vector2, q2: Vector2) -> bool:
	# Calculate orientations for intersection test
	var o1 = _orientation(p1, q1, p2)
	var o2 = _orientation(p1, q1, q2)
	var o3 = _orientation(p2, q2, p1)
	var o4 = _orientation(p2, q2, q1)
	
	# General case - segments intersect if orientations differ
	if o1 != o2 and o3 != o4:
		return true
	
	# Special collinear cases
	if o1 == 0 and _point_on_segment_robust(p1, p2, q1):
		return true
	if o2 == 0 and _point_on_segment_robust(p1, q2, q1):
		return true
	if o3 == 0 and _point_on_segment_robust(p2, p1, q2):
		return true
	if o4 == 0 and _point_on_segment_robust(p2, q1, q2):
		return true
	
	return false

func _orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	# Calculate orientation of ordered triplet (p, q, r)
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	
	if abs(val) < 1e-10:  # Floating point epsilon
		return 0  # Collinear
	
	return 1 if val > 0 else 2  # Clockwise or counterclockwise

func _point_on_segment_robust(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
			q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y))

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
func _find_nearest_waypoint_to_position(position: Vector3) -> Vector3:
	if available_waypoints.size() == 0:
		return Vector3.INF
	
	var position_2d = Vector2(position.x, position.z)
	var nearest_point = Vector3.INF
	var nearest_distance = INF
	
	# Find closest waypoint to given position
	for point in available_waypoints:
		var point_2d = Vector2(point.x, point.z)
		var distance = position_2d.distance_to(point_2d)
		
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_point = point
	
	return nearest_point

func _find_node_by_name(node: Node, name: String) -> Node:
	# Recursive search for node by name
	if node.name.to_lower() == name.to_lower():
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, name)
		if result:
			return result
	
	return null

# =============================================================================
# LEGACY FUNCTIONS (kept for compatibility)
# =============================================================================
func _pick_new_direction() -> void:
	# Legacy random direction picker - no longer used in pathfinding system
	var directions = [
		Vector2.ZERO,
		Vector2(0, -1), Vector2(0, 1),
		Vector2(-1, 0), Vector2(1, 0),
		Vector2(-1, -1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(1, 1)
	]
	
	current_input = directions[randi() % directions.size()]
	direction_change_interval = randf_range(1.0, 3.0)
