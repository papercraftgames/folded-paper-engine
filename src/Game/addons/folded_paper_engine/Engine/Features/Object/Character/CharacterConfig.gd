class_name CharacterConfig

var WalkSpeedMultiplier: float = 1.0
var RunSpeedMultiplier: float = 1.0
var JumpForceMultiplier: float = 1.0
var AnimationConfig: CharacterAnimationConfig
var WanderingBounds: String = ""
var FaceMotionDirection: bool = false

func _init(data: Dictionary):
	WalkSpeedMultiplier = data.get("WalkSpeedMultiplier", 1.0)
	RunSpeedMultiplier = data.get("RunSpeedMultiplier", 1.0)
	JumpForceMultiplier = data.get("JumpForceMultiplier", 1.0)
	
	AnimationConfig = CharacterAnimationConfig.new()
	
	AnimationConfig.Idle = data.get("IdleAnimation", "")
	AnimationConfig.Walk = data.get("WalkAnimation", "")
	AnimationConfig.Run = data.get("RunAnimation", "")
	AnimationConfig.Jump = data.get("JumpAnimation", "")
	
	WanderingBounds = data.get("WanderingBounds", "")
	
	FaceMotionDirection = true if data.get("FaceMotionDirection", 0.0) == 1.0 else false

func get_animation_name(walking: bool, running: bool, jumping: bool) -> String:
	var anim_name: String = AnimationConfig.Idle
	
	if jumping:
		anim_name = AnimationConfig.Jump
	elif running and walking:
		anim_name = AnimationConfig.Run
	elif walking:
		anim_name = AnimationConfig.Walk
	
	return anim_name
