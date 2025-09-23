class_name PhysicsUtils extends FeatureConfig

const MOVING_PLATFORM_STATIC_SCRIPT: Script = preload("res://addons/folded_paper_engine/Engine/Physics/MovingPlatformStatic.gd")
const ADVANCED_RIGID_BODY_SCRIPT: Script = preload("res://addons/folded_paper_engine/Engine/Physics/AdvancedRigidBody3D.gd")

static func enhance_static_body(node: Node) -> void:
	if is_instance_of(node, StaticBody3D):
		node.set_script(MOVING_PLATFORM_STATIC_SCRIPT)

static func enhance_rigid_body(node: Node) -> void:
	if is_instance_of(node, RigidBody3D):
		node.set_script(ADVANCED_RIGID_BODY_SCRIPT)
