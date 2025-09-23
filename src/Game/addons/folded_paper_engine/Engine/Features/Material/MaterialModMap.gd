class_name MaterialModMap extends FeatureConfig

var RenderPriority: MaterialFeatureBase
var Reflective: MaterialFeatureBase
var ReplaceWithMaterial: MaterialFeatureBase

func _init(feature_utils: FeatureUtils) -> void:
	super(feature_utils)
	
	RenderPriority = RenderPriorityMod.new(feature_utils)
	Reflective = ReflectiveMod.new(feature_utils)
	ReplaceWithMaterial = ReplaceWithMaterialMod.new(feature_utils)
