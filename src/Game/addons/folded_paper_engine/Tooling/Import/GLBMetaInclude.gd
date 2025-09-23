@tool
class_name GLBMetaInclude
extends GLTFDocumentExtension

const EXT_NAME := &"fpe.gltf_extras"
var DEBUG := false

func _get_name() -> StringName:
	return EXT_NAME

func _import_preflight(state: GLTFState, _extensions: PackedStringArray) -> int:
	if DEBUG:
		print("[FPE] preflight: file=", state.filename, " base=", state.base_path)
	return OK

func _import_post_parse(state: GLTFState) -> int:
	var parsed := state.json
	if typeof(parsed) != TYPE_DICTIONARY:
		if DEBUG: print("[FPE] post_parse: no JSON; aborting")
		return OK

	var scene_ex := _extract_scene_extras(parsed)
	var anim_ex := _extract_animation_extras(parsed)
	
	scene_ex.set(FeatureConstants.USER_DATA_TYPES.Animation, anim_ex)

	state.set_additional_data(EXT_NAME, {
		"scene": scene_ex,
	})

	var gltf_anims := state.get_animations()
	if gltf_anims is Array:
		for ga in gltf_anims:
			if ga is GLTFAnimation:
				var nm: String = ga.get_original_name()
				var key := _clean_anim_name(nm)
				if anim_ex.has(key):
					ga.set_additional_data(EXT_NAME, anim_ex[key])

	if DEBUG:
		print("[FPE] post_parse: scene_ex.size=", scene_ex.size(), " anim_ex.keys=", anim_ex.keys())
	return OK

func _import_post(state: GLTFState, root: Node) -> int:
	var blob := state.get_additional_data(EXT_NAME)
	if blob is Dictionary and root:
		var scene_ex = blob.get("scene", {})
		var anim_ex = blob.get("animations", {})

		if scene_ex is Dictionary and scene_ex.size() > 0:
			root.set_meta("extras", scene_ex)
		if anim_ex is Dictionary and anim_ex.size() > 0:
			root.set_meta("animation_extras", anim_ex)

		if DEBUG:
			print("[FPE] post: root.meta.extras =", root.get_meta("extras"))
			var ax := {}
			if root.has_meta("animation_extras"):
				ax = root.get_meta("animation_extras")
			if ax is Dictionary:
				print("[FPE] post: root.meta.animation_extras.keys =", ax.keys())
			else:
				print("[FPE] post: root.meta.animation_extras =", ax)
	return OK

# ---------- helpers ----------
func _extract_scene_extras(parsed: Dictionary) -> Dictionary:
	if parsed.has("scenes") and parsed["scenes"] is Array and parsed["scenes"].size() > 0:
		var s = parsed["scenes"][0]
		if s is Dictionary and s.has("extras") and s["extras"] is Dictionary:
			return s["extras"]
	return {}

func _extract_animation_extras(parsed: Dictionary) -> Dictionary[String, Dictionary]:
	var result: Dictionary[String, Dictionary] = {}
	
	if parsed is Dictionary and parsed.has("animations") and parsed["animations"] is Array:
		for anim in parsed["animations"]:
			if typeof(anim) == TYPE_DICTIONARY:
				var anim_name: String = anim.get("name", "")
				var anim_extras = anim.get("extras", {})
				
				if anim_name is String and anim_name != "" and typeof(anim_extras) == TYPE_DICTIONARY:
					var clean_anim_name := anim_name.replace(".", "_").replace("_loop", "")
					
					result[clean_anim_name] = anim_extras
	
	return result

func _clean_anim_name(n: String) -> String:
	return (n if n != null else "").replace(".", "_").replace("_loop", "")
