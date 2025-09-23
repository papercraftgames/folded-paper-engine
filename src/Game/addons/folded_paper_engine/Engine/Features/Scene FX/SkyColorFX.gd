class_name SkyColorFX extends SceneFeatureBase

func apply(env: WorldEnvironment, data: Variant) -> void:
	if data and data is Array:
		var color_list: Array = data
		var r = color_list[0]
		var g = color_list[1]
		var b = color_list[2]
		var a = color_list[3]
		
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(r,g,b,a)
