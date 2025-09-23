class_name ActuatorInfo

var value: float = 0.0
var is_mouse_axis: bool = false

func _init(actuator_value: float, actuator_is_mouse_axis: bool) -> void:
	value = actuator_value
	is_mouse_axis = actuator_is_mouse_axis
