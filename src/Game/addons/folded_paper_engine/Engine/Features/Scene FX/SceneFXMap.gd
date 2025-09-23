class_name SceneFXMap extends FeatureConfig

var SkyColor: SceneFeatureBase
var BackgroundMusic: SceneFeatureBase
var BackgroundMusicVolume: SceneFeatureBase
var Gravity: SceneFeatureBase

func _init(feature_utils: FeatureUtils) -> void:
	super(feature_utils)
	
	SkyColor = SkyColorFX.new(feature_utils)
	BackgroundMusic = BackgroundMusicFX.new(feature_utils)
	BackgroundMusicVolume = BackgroundMusicVolumeFX.new(feature_utils)
	Gravity = GravityFX.new(feature_utils)
