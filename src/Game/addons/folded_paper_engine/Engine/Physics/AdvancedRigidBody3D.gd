# AdvancedRigidBody3D.gd
class_name AdvancedRigidBody3D
extends RigidBody3D

signal being_held_changed

var _BEING_HELD: bool = false

@export var ground_normal_dot_thresh: float = 0.6
@export var max_platform_history: int = 64
@export var auto_enable_contact_monitoring: bool = true
@export var contacts_to_report: int = 8

var contact_linear_velocity: Vector3 = Vector3.ZERO
var contact_angular_velocity: Vector3 = Vector3.ZERO
var contact_valid: bool = false
var contact_up_dot: float = 0.0

# collider_instance_id -> { origin: Vector3, basis: Basis }
var _prev_xform: Dictionary = {}

func _init() -> void:
	if HoldableItemUtils.is_item_holdable(self):
		continuous_cd = true

func _ready() -> void:
	if auto_enable_contact_monitoring:
		contact_monitor = true
		max_contacts_reported = contacts_to_report

func _physics_process(_delta: float) -> void:
	# values are computed in _integrate_forces()
	pass

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	contact_linear_velocity = Vector3.ZERO
	contact_angular_velocity = Vector3.ZERO
	contact_valid = false
	contact_up_dot = 0.0

	var best := {}
	var best_dot := -1.0
	var cc := state.get_contact_count()

	# Pick best "ground" contact among StaticBody3D
	for i in range(cc):
		var obj := state.get_contact_collider_object(i)
		if not (obj is StaticBody3D):
			continue
		var n_world := (global_transform.basis * state.get_contact_local_normal(i)).normalized()
		var updot := n_world.dot(Vector3.UP)
		if updot > ground_normal_dot_thresh and updot > best_dot:
			best_dot = updot
			var p_world := global_transform * state.get_contact_local_position(i)
			best = {"i": i, "collider": obj, "p_world": p_world, "updot": updot}

	# Compute carry (engine first; fallback if needed)
	if not best.is_empty():
		var i: int = best["i"]
		var body: StaticBody3D = best["collider"]
		var p: Vector3 = best["p_world"]
		contact_up_dot = float(best["updot"])

		var v_engine := state.get_contact_collider_velocity_at_position(i) # uses constant_* if set. :contentReference[oaicite:1]{index=1}
		var v_fallback := _static_point_velocity(body, p, state.get_step())
		contact_linear_velocity = v_engine if (v_engine.length_squared() > 0.0) else v_fallback
		contact_angular_velocity = _static_angular_velocity(body, state.get_step())
		contact_valid = true

	# Update history after using it
	for j in range(cc):
		var o := state.get_contact_collider_object(j)
		if o is StaticBody3D:
			var s: StaticBody3D = o
			_prev_xform[s.get_instance_id()] = {
				"origin": s.global_transform.origin,
				"basis":  s.global_transform.basis
			}
			if _prev_xform.size() > max_platform_history:
				for k in _prev_xform.keys():
					_prev_xform.erase(k); break

# --- Static platform motion extraction ---

func _static_point_velocity(body: StaticBody3D, world_point: Vector3, dt: float) -> Vector3:
	# Prefer explicit constant_* velocities if set
	if "constant_linear_velocity" in body and "constant_angular_velocity" in body:
		var v_const: Vector3 = body.constant_linear_velocity
		var w_const: Vector3 = body.constant_angular_velocity
		var r: Vector3 = world_point - body.global_transform.origin
		return v_const + w_const.cross(r)

	# Otherwise derive from transform delta (animated/tweened StaticBody3D)
	var key := body.get_instance_id()
	if _prev_xform.has(key):
		var prev = _prev_xform[key]
		var x_prev: Vector3 = prev["origin"]
		var x_now: Vector3 = body.global_transform.origin
		var v_lin: Vector3 = (x_now - x_prev) / max(dt, 1e-6)

		var b_prev: Basis = prev["basis"]
		var b_now: Basis = body.global_transform.basis
		var q := (b_prev.inverse() * b_now).get_rotation_quaternion()
		var w: Vector3 = q.get_axis() * (q.get_angle() / max(dt, 1e-6))

		var r3: Vector3 = world_point - body.global_transform.origin
		return v_lin + w.cross(r3)

	return Vector3.ZERO

func _static_angular_velocity(body: StaticBody3D, dt: float) -> Vector3:
	if "constant_angular_velocity" in body:
		return body.constant_angular_velocity

	var key := body.get_instance_id()
	if _prev_xform.has(key):
		var prev = _prev_xform[key]
		var q = (prev["basis"].inverse() * body.global_transform.basis).get_rotation_quaternion()
		return q.get_axis() * (q.get_angle() / max(dt, 1e-6))

	return Vector3.ZERO

# --- Holdable API ---

func set_being_held(value: bool) -> void:
	var changed: bool = value != _BEING_HELD
	
	_BEING_HELD = value
	
	being_held_changed.emit()

func get_being_held() -> bool:
	return _BEING_HELD
