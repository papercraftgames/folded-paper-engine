class_name CameraUtils extends FPEGlobalsConfig

func activate_camera(name: String) -> void:
	if name is String and FPE_GLOBALS.SCENE_CAMERAS.has(name):
		var cam: Camera3D = FPE_GLOBALS.SCENE_CAMERAS[name]
		
		if cam is Camera3D:
			cam.make_current()

func reactivate_player_camera() -> void:
	var cam: Camera3D = FPE_GLOBALS.PLAYER_CAMERAS[FPE_GLOBALS.PLAYER_CAMERAS.size() - 1]
	
	if cam is Camera3D:
		cam.make_current()
