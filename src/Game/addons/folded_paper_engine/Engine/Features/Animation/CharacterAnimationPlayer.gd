class_name CharacterAnimationPlayer extends AnimationPlayer
## Blend bone rotations relative to the visible pose, avoiding the +/-180 degree
## discontinuity of rest-relative blending. Animation resources and rests stay intact.

var _rotation_offsets: Dictionary = {}

func _init() -> void:
	mixer_applied.connect(_restore_rotation_space)

func _post_process_key_value(animation: Animation, track: int, value: Variant,
		object_id: int, object_sub_idx: int) -> Variant:
	if object_sub_idx < 0:
		return value
	var skeleton := instance_from_id(object_id) as Skeleton3D
	if not is_instance_valid(skeleton):
		return value
	if animation.track_get_type(track) == Animation.TYPE_POSITION_3D:
		# Preserve AnimationMixer's default bone-position processing.
		return value * skeleton.motion_scale
	if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
		return value
	if not _rotation_offsets.has(skeleton):
		_rotation_offsets[skeleton] = {}
	var offsets: Dictionary = _rotation_offsets[skeleton]
	if not offsets.has(object_sub_idx):
		var rest := skeleton.get_bone_rest(object_sub_idx).basis.get_rotation_quaternion()
		var pose := skeleton.get_bone_pose_rotation(object_sub_idx).normalized()
		offsets[object_sub_idx] = rest * pose.inverse()
	return (offsets[object_sub_idx] * value).normalized()

func _restore_rotation_space() -> void:
	# Every contributing clip uses the same offset during this mixer update.
	# Undo it only after Godot has applied all weighted tracks to the skeleton.
	for skeleton in _rotation_offsets:
		if not is_instance_valid(skeleton):
			continue
		var offsets: Dictionary = _rotation_offsets[skeleton]
		for bone in offsets:
			var rotation: Quaternion = offsets[bone].inverse() * skeleton.get_bone_pose_rotation(bone)
			skeleton.set_bone_pose_rotation(bone, rotation.normalized())
	_rotation_offsets.clear()
