class_name RigidBodyUtils extends FeatureConfig

func add(body: RigidBody3D) -> void:
	if not FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST.has(body):
		FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST.append(body)

func remove(body: RigidBody3D) -> void:
	if FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST.has(body):
		var index := FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST.find(body)
		
		FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST.remove_at(index)

func freeze_all() -> void:
	for body in FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST:
		body.freeze = true
		body.set_physics_process(false)
		body.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
		body.set_deferred("disabled", true)

func unfreeze_all() -> void:
	for body in FEATURE_UTILS.FPE_GLOBALS.RIGID_BODY_LIST:
		body.freeze = false
		body.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
		body.set_deferred("disabled", false)
		body.set_physics_process(true)
