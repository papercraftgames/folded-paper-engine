class_name PhysicsMod extends FeatureBase

func _deep_apply(node: Node, config: Dictionary) -> void:
	if node and config is Dictionary:
		var children := node.get_children()
		
		if node is StaticBody3D or node is RigidBody3D:
			var body: PhysicsBody3D = node as PhysicsBody3D
			var friction := config.get("Friction", 0.0) as float
			var bounciness := config.get("Bounciness", 0.0) as float
			
			if body is RigidBody3D:
				var rigid_body := body as RigidBody3D
				var mass := config.get("Mass", 1.0) as float
				var continuous_cd := config.get("ContinuousCollisionDetection", 0.0) as float
				
				rigid_body.mass = mass
				rigid_body.continuous_cd = true if continuous_cd else false
			
			if friction > 0.0 or bounciness > 0.0:
				if not body.physics_material_override:
					body.physics_material_override = PhysicsMaterial.new()
				
				var mat: PhysicsMaterial = body.physics_material_override
				
				mat.friction = friction
				mat.bounce = bounciness
		
		for child in children:
			_deep_apply(child, config)

func apply(node: Node3D, data: Variant) -> void:
	if node and data:
		var config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.Physics)
		
		if config is Dictionary:
			_deep_apply(node, config)
