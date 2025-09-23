class_name FXMap extends FeatureConfig

var Water: FeatureBase

func _init(feature_utils: FeatureUtils) -> void:
	super(feature_utils)
	
	Water = WaterFX.new(feature_utils)
