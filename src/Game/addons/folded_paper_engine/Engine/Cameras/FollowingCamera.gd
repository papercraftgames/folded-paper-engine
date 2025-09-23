class_name FollowingCamera extends Camera3D

var FPE_GLOBALS: FPEGlobals
var target: Node3D
var offset: Vector3 = Vector3(0.0, 1.5, 3.0)
var angular_offset_degrees: float = 0.0
var align: bool = false
var face: bool = false

func _init(fpe_globals: FPEGlobals, node: Node3D) -> void:
	FPE_GLOBALS = fpe_globals
	target = node
	
	if FPE_GLOBALS.STAGE_SCENE:
		FPE_GLOBALS.STAGE_SCENE.add_child.call_deferred(self)

func get_rotation_around_pivot_x(point: Vector3, pivot: Vector3) -> float:
	var r := point - pivot
	var yz_len2 := r.y * r.y + r.z * r.z
	var ang := atan2(r.y, r.z) if yz_len2 > 0.0 else 0.0
	
	return ang

func rotate_around_pivot_x(point: Vector3, pivot: Vector3, rads: float) -> Vector3:
	var rotated_offset := (point - pivot).rotated(Vector3.LEFT, rads)
	
	return pivot + rotated_offset

func rotate_around_pivot_y(point: Vector3, pivot: Vector3, src_basis: Basis) -> Vector3:
	var yaw := src_basis.get_euler().y
	var rotated_offset := (point - pivot).rotated(Vector3.UP, yaw)
	
	return pivot + rotated_offset

func _process(_delta):
	if is_instance_valid(target):
		var existing_angular_offset_degress := rad_to_deg(get_rotation_around_pivot_x(offset, Vector3.ZERO))
		var adjusted_angular_offset_degrees := existing_angular_offset_degress + angular_offset_degrees
		
		if adjusted_angular_offset_degrees > 90:
			adjusted_angular_offset_degrees = 90
		elif adjusted_angular_offset_degrees < -5:
			adjusted_angular_offset_degrees = -5
		
		angular_offset_degrees = adjusted_angular_offset_degrees - existing_angular_offset_degress
		
		var pitched_offset := rotate_around_pivot_x(offset, Vector3.ZERO, deg_to_rad(angular_offset_degrees))
		var new_pos := target.global_position + pitched_offset
		
		if align:
			var aligned_pos := rotate_around_pivot_y(new_pos, target.global_position, target.global_basis)
			
			new_pos.x = lerp(global_position.x, aligned_pos.x, 0.05)
			new_pos.z = lerp(global_position.z, aligned_pos.z, 0.05)
		
		global_position = new_pos

		# Smooth look-at
		if face:
			global_rotation.y = target.global_rotation.y
		else:
			look_at(target.global_position, Vector3.UP)
