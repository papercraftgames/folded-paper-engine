# MovingPlatformStatic.gd
class_name MovingPlatformStatic extends StaticBody3D

var _prev := Transform3D()

func _ready() -> void:
	_prev = global_transform

func _physics_process(delta: float) -> void:
	var now := global_transform
	# linear
	constant_linear_velocity = (now.origin - _prev.origin) / max(delta, 1e-6)
	# angular
	var dR := _prev.basis.inverse() * now.basis
	var q := dR.get_rotation_quaternion()
	constant_angular_velocity = q.get_axis() * (q.get_angle() / max(delta, 1e-6))
	_prev = now
