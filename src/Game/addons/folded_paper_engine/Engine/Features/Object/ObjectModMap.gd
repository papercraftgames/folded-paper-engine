class_name ObjectModMap extends FeatureConfig

var Player: FeatureBase
var Character: FeatureBase
var Invisible: FeatureBase
var Physics: FeatureBase
var SpriteAnimate: FeatureBase
var Trigger: FeatureBase
var Speaker: FeatureBase
var UIElement: FeatureBase
var SubScene: FeatureBase
var Groups: FeatureBase
var ScriptPath: FeatureBase

func _init(feature_utils: FeatureUtils) -> void:
	super(feature_utils)
	
	Player = CharacterMod.new(feature_utils)
	Character = CharacterMod.new(feature_utils)
	Invisible = InvisibleMod.new(feature_utils)
	Physics = PhysicsMod.new(feature_utils)
	SpriteAnimate = SpriteAnimateMod.new(feature_utils)
	Trigger = TriggerMod.new(feature_utils)
	Speaker = SpeakerMod.new(feature_utils)
	UIElement = UIElementMode.new(feature_utils)
	SubScene = SubSceneMod.new(feature_utils)
	Groups = GroupsMod.new(feature_utils)
	ScriptPath = ScriptPathMod.new(feature_utils)
