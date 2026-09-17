extends SceneTree
## Run with: godot --headless --path <project> --script res://addons/folded_paper_engine/tests/character_animation_test.gd

class RecordingFrameEvents extends FrameEventRunner:
	var fired: Array[String] = []
	func _trigger_frame_event(_target: NodePath, _event: Dictionary, anim_name: String) -> void:
		fired.append(anim_name)

var failures: int = 0
var features: FeatureUtils
var stage: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _clip(anim_name: String, value: float, looping: bool = true) -> AnimationPlayer:
	var animation := Animation.new()
	animation.length = 0.1 if not looping else 1.0
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	var track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(track, NodePath("Pose"))
	animation.position_track_insert_key(track, 0.0, Vector3(value, 0, 0))
	animation.position_track_insert_key(track, animation.length, Vector3(value, 0, 0))
	var library := AnimationLibrary.new()
	library.add_animation(anim_name, animation)
	var player := AnimationPlayer.new()
	player.add_animation_library("", library)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	stage.add_child(player)
	features.FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name] = player
	return player

func _run() -> void:
	features = FeatureUtils.new()
	stage = Node3D.new()
	root.add_child(stage)
	features.FPE_GLOBALS.CURRENT_LOADED_ROOT = stage
	var pose := Node3D.new()
	pose.name = "Pose"
	stage.add_child(pose)
	var idle := _clip("Idle", 0.0)
	var walk_source := _clip("Walk", 10.0)
	_clip("Run", 20.0)
	_clip("Jump", 30.0, false)
	var door := _clip("Door", 50.0)
	var other_character := _clip("OtherIdle", 60.0)
	var utils := features.ANIMATION_UTILS
	utils.share_character_animation_player(["Idle", "Walk", "Run", "Jump", "", "Missing", "Idle"])
	_check(utils.get_animation_player("Walk") == idle, "Character clips must share a player")
	_check(utils.get_animation_player("Door") == door, "Unrelated animation must remain independent")
	_check(utils.get_animation_player("OtherIdle") == other_character, "Other character must remain independent")
	_check(not walk_source.is_playing(), "Old clip players must stop writing poses")
	utils.share_character_animation_player(["Idle", "Walk", "Run", "Jump"])
	utils.play_animation("Idle")
	idle.advance(0)
	utils.play_animation("Walk", 0.2)
	idle.advance(0)
	_check(is_equal_approx(pose.position.x, 0.0), "Transition must start from previous pose")
	idle.advance(0.1)
	idle.advance(0)
	_check(pose.position.x > 0.0 and pose.position.x < 10.0, "Halfway through blend must be an intermediate pose")
	idle.advance(0.15)
	idle.advance(0)
	_check(is_equal_approx(pose.position.x, 10.0), "Blend must reach destination pose")
	utils.stop_animation("Idle")
	utils.pause_animation("Idle")
	_check(idle.is_playing(), "Commands for inactive clips must not stop the active shared clip")
	utils.pause_playing_animations()
	_check(not idle.is_playing(), "Global pause must pause shared player")
	_check(utils.PAUSED_ANIMATION_NAMES.get("Walk", false), "Pause must record the active clip")
	var paused_position := idle.current_animation_position
	utils.resume_paused_animations()
	_check(idle.current_animation == "Walk" and is_equal_approx(idle.current_animation_position, paused_position), "Resume must preserve clip and time")
	utils.pause_playing_animations()
	utils.play_animation("Run", 0.2)
	utils.play_animation("Jump", 0.1)
	utils.resume_paused_animations()
	_check(idle.current_animation == "Jump", "Only the last transition requested during pause must resume")
	idle.advance(0.3)
	_check(not idle.is_playing() and is_equal_approx(pose.position.x, 30.0), "A finished one-shot must retain its final pose")
	utils.play_animation("Walk", 0.2)
	idle.advance(0)
	_check(is_equal_approx(pose.position.x, 30.0), "Landing blend must start from the finished jump pose")
	idle.advance(0.1)
	idle.advance(0)
	_check(pose.position.x > 10.0 and pose.position.x < 30.0, "Finished one-shots must blend into locomotion")
	utils.play_animation("Walk", 0.0)
	idle.advance(0.02)
	var events := RecordingFrameEvents.new(features)
	stage.add_child(events)
	events.set_process(false)
	var event := {AnimationConstants.ANIMATION_DATA_PROPERTY_NAMES.FrameTime: 0.01}
	events._frame_events_by_anim = {"Idle": [event], "Walk": [event], "Jump": [event]}
	events._process(0.0)
	_check(events.fired == ["Walk"], "Shared player must dispatch only active clip frame events")
	utils.stop_all_animations()
	_test_rotation_blending()
	utils.stop_all_animations()
	_test_jump_stages()
	utils.stop_all_animations()
	await _test_landing(idle)
	stage.queue_free()
	await process_frame
	print("FPE animation regression: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

func _test_rotation_blending() -> void:
	var skeleton := Skeleton3D.new()
	skeleton.name = "RotationTest"
	skeleton.motion_scale = 2.0
	skeleton.add_bone("Torso")
	var rest_rotation := Quaternion(Vector3.BACK, deg_to_rad(-1.0))
	skeleton.set_bone_rest(0, Transform3D(Basis(rest_rotation), Vector3.ZERO))
	skeleton.set_bone_pose_rotation(0, rest_rotation)
	stage.add_child(skeleton)
	var angles := {"TurnA": 179.0, "TurnB": -179.0, "TurnC": 175.0}
	for anim_name in angles:
		var source := _clip(anim_name, 0.0)
		var animation := source.get_animation(anim_name)
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("RotationTest:Torso"))
		var rotation := Quaternion(Vector3.BACK, deg_to_rad(angles[anim_name]))
		animation.rotation_track_insert_key(track, 0.0, rotation)
		animation.rotation_track_insert_key(track, 1.0, rotation)
		track = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("RotationTest:Torso"))
		animation.position_track_insert_key(track, 0.0, Vector3.RIGHT)
		animation.position_track_insert_key(track, 1.0, Vector3.RIGHT)
	var utils := features.ANIMATION_UTILS
	utils.share_character_animation_player(["TurnA", "TurnB", "TurnC"])
	var player := utils.get_animation_player("TurnA")
	utils.play_animation("TurnA", 0.0)
	player.advance(0)
	for anim_name in ["TurnB", "TurnA", "TurnB"]:
		var previous := skeleton.get_bone_pose_rotation(0)
		var total_rotation := 0.0
		utils.play_animation(anim_name, 0.15)
		for frame in range(12):
			player.advance(1.0 / 60.0)
			var current := skeleton.get_bone_pose_rotation(0)
			total_rotation += previous.angle_to(current)
			previous = current
		_check(total_rotation < deg_to_rad(5.0), "179 to -179 degree transitions must take the short path, not spin through the rest pose")
		var target := Quaternion(Vector3.BACK, deg_to_rad(angles[anim_name]))
		_check(previous.angle_to(target) < 0.001, "Rotation blend must reach the authored destination")
	utils.play_animation("TurnA", 0.15)
	player.advance(0.05)
	utils.play_animation("TurnC", 0.15)
	for frame in range(15):
		player.advance(1.0 / 60.0)
		_check(skeleton.get_bone_pose_rotation(0).angle_to(Quaternion(Vector3.BACK, PI)) < deg_to_rad(10.0), "Interrupted blends must stay near the visible pose")
	utils.pause_playing_animations()
	utils.resume_paused_animations()
	player.advance(0.02)
	var before_stop := skeleton.get_bone_pose_rotation(0)
	utils.stop_animation("TurnC")
	_check(skeleton.get_bone_pose_rotation(0).angle_to(before_stop) < 0.001, "Stopping playback must preserve the visible bone rotation")
	_check(skeleton.get_bone_rest(0).basis.get_rotation_quaternion().angle_to(rest_rotation) < 0.001, "Blending must not modify bone rests")
	_check(skeleton.get_bone_pose_position(0).is_equal_approx(Vector3.RIGHT * 2.0), "Custom rotation blending must preserve skeleton motion scale")

func _test_jump_stages() -> void:
	var jump_source := _clip("StageJump", 1.0)
	jump_source.get_animation("StageJump").length = 0.1
	_clip("StageAir", 2.0, false)
	var land_source := _clip("StageLand", 3.0)
	land_source.get_animation("StageLand").length = 1.0
	var utils := features.ANIMATION_UTILS
	utils.share_character_animation_player(["Idle", "Walk", "Run", "StageJump", "StageAir", "StageLand"])
	var player := utils.get_animation_player("Idle")
	var rig: RigidBody3D = load("res://addons/folded_paper_engine/Engine/Features/Object/Character/CharacterRig.tscn").instantiate()
	rig.set_script(load("res://addons/folded_paper_engine/Engine/Features/Object/Character/CharacterControls.gd"))
	var character := rig as CharacterControls
	character.freeze = true
	character.set_feature_utils(features)
	character.setup_character_config({"IdleAnimation": "Idle", "WalkAnimation": "Walk", "RunAnimation": "Run", "JumpAnimation": "StageJump", "AirControlAnimation": "StageAir", "LandAnimation": "StageLand"})
	stage.add_child(character)
	var config := character.CHARACTER_CONFIG.AnimationConfig
	_check(config.AirControl == "StageAir" and config.Land == "StageLand", "Blender metadata must populate the new stages")
	character._animation_on_floor = true
	character.set_animation(Vector2.ZERO, false, false)
	character._animation_on_floor = false
	character.set_animation(Vector2.ZERO, false, false, true)
	_check(character.LAST_ANIM_PLAYED == "StageJump" and player.get_animation("StageJump").loop_mode == Animation.LOOP_NONE, "Takeoff must play once even when imported as looping")
	player.advance(0.04)
	player.get_animation("StageJump").loop_mode = Animation.LOOP_LINEAR
	character.set_animation(Vector2.ZERO, false, false)
	_check(player.get_animation("StageJump").loop_mode == Animation.LOOP_NONE, "Late scene metadata must not make takeoff loop")
	_check(character.LAST_ANIM_PLAYED == "StageJump" and player.current_animation_position > 0.03, "Takeoff must not restart while held airborne")
	utils.pause_playing_animations()
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageJump", "Paused takeoff must not be mistaken for completion")
	utils.resume_paused_animations()
	player.advance(0.1)
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageAir", "Completed takeoff must enter Air Control")
	player.advance(0.6)
	character.set_animation(Vector2.ZERO, false, false)
	_check(player.is_playing() and player.current_animation == "StageAir", "Air Control must loop throughout flight even if imported as one-shot")
	character._animation_on_floor = true
	character.set_animation(Vector2.RIGHT, true, true)
	var pose := stage.get_node("Pose") as Node3D
	_check(character.LAST_ANIM_PLAYED == "StageLand" and is_instance_valid(character._landing_animation_tree), "Landing must start the simultaneous animation mixer")
	_check(is_equal_approx(pose.position.x, 2.0), "Landing entry must begin from the visible Air Control pose")
	character._update_landing_blend(character.landing_entry_blend_time * 0.5)
	character._landing_animation_tree.advance(0.0)
	_check(pose.position.x > 2.0 and pose.position.x < 6.4, "Landing entry must smoothly approach the weighted composite")
	character._update_landing_blend(character.landing_entry_blend_time * 0.5)
	character._landing_animation_tree.advance(0.0)
	_check(is_equal_approx(pose.position.x, 3.0 * 0.8 + 20.0 * 0.2), "Landing composite must be 80 percent Land and 20 percent Run")
	character.set_animation(Vector2.RIGHT, true, false)
	character._landing_animation_tree.advance(0.0)
	_check(is_equal_approx(pose.position.x, 3.0 * 0.8 + 10.0 * 0.2), "Landing mixer must follow changing Walk input")
	character.set_animation(Vector2.ZERO, false, false)
	character._landing_animation_tree.advance(0.0)
	_check(is_equal_approx(pose.position.x, 3.0 * 0.8), "Landing mixer must follow changing Idle input")
	character.set_animation(Vector2.RIGHT, true, true)
	character._landing_animation_tree.advance(0.0)
	character._update_landing_blend(character.landing_weight_fade_time * 0.5)
	character._landing_animation_tree.advance(0.07)
	_check(pose.position.x > 6.4 and pose.position.x < 20.0, "Land weight must fade toward the running animation")
	character._update_landing_blend(character.landing_weight_fade_time * 0.5)
	character._landing_animation_tree.advance(0.07)
	var locomotion_position := float(character._landing_animation_tree.get("parameters/Locomotion/current_position"))
	character.set_animation(Vector2.RIGHT, true, true)
	player.advance(0.0)
	_check(character.LAST_ANIM_PLAYED == "Run" and player.current_animation == "Run", "Completed landing mix must hand off to Run")
	_check(is_equal_approx(player.current_animation_position, locomotion_position), "Landing handoff must preserve the locomotion playback phase")
	_check(is_equal_approx(pose.position.x, 20.0), "Landing mix must finish at 100 percent Run without an Idle frame")
	character._animation_on_floor = false
	character.linear_velocity = Vector3.DOWN
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageAir", "Walking off a ledge must skip takeoff")
	character._animation_on_floor = true
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageLand" and player.get_animation("StageLand").loop_mode == Animation.LOOP_NONE, "A stationary landing must still play Land")
	character._animation_on_floor = false
	character.set_animation(Vector2.ZERO, false, false, true)
	_check(character.LAST_ANIM_PLAYED == "StageJump", "A new jump must interrupt landing")
	player.advance(0.01)
	character._animation_on_floor = true
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageLand", "A short jump must land without waiting for takeoff to finish")
	config.AirControl = "MissingAir"
	character._animation_on_floor = false
	character.set_animation(Vector2.ZERO, false, false, true)
	player.advance(0.2)
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageJump" and not player.is_playing(), "Missing Air Control must hold the completed takeoff pose")
	character._animation_on_floor = true
	character.set_animation(Vector2.ZERO, false, false)
	_check(character.LAST_ANIM_PLAYED == "StageLand", "Land must work when Air Control is missing")
	config.AirControl = "StageAir"
	config.Land = "MissingLand"
	character._animation_on_floor = false
	character.set_animation(Vector2.ZERO, false, false, true)
	player.advance(0.2)
	character.set_animation(Vector2.ZERO, false, false)
	character._animation_on_floor = true
	character.set_animation(Vector2.RIGHT, true, false)
	_check(character.LAST_ANIM_PLAYED == "Walk", "Missing Land must return directly to locomotion")
	config.Jump = "MissingJump"
	character._animation_on_floor = false
	character.set_animation(Vector2.ZERO, false, false, true)
	_check(character.LAST_ANIM_PLAYED == "StageAir", "Missing takeoff must enter Air Control directly")
	character.queue_free()

func _test_landing(player: AnimationPlayer) -> void:
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	stage.add_child(floor_body)
	var rig: RigidBody3D = load("res://addons/folded_paper_engine/Engine/Features/Object/Character/CharacterRig.tscn").instantiate()
	rig.set_script(load("res://addons/folded_paper_engine/Engine/Features/Object/Character/CharacterControls.gd"))
	var character := rig as CharacterControls
	character.set_feature_utils(features)
	character.setup_character_config({"IdleAnimation": "Idle", "WalkAnimation": "Walk", "RunAnimation": "Run", "JumpAnimation": "Jump"})
	character.position.y = 2.0
	stage.add_child(character)
	var landed_from_probe := false
	var landed := false
	for frame in range(180):
		await physics_frame
		character.set_animation(Vector2.ZERO, false, false)
		player.advance(1.0 / 60.0)
		if not character._animation_on_floor:
			_check(character.LAST_ANIM_PLAYED == "Jump", "Jump must stay selected throughout flight, including after clip completion")
		else:
			landed_from_probe = character.is_on_floor()
			landed = true
			_check(character.LAST_ANIM_PLAYED == "Idle", "Landing must return to idle")
			break
	_check(landed_from_probe, "Animation landing must use the movement ground probe without waiting on a late solver contact")
	_check(landed, "Character must land on physical floor")
	# Probe-based animation landing can precede the solver contact by a few frames.
	# Let the fixture settle before exercising a new physical jump.
	for frame in range(10):
		await physics_frame
	character.move(Vector2.ZERO, 0.0, 1.0)
	_check(character.LAST_ANIM_PLAYED == "Jump", "Takeoff must start jump immediately")
	var airborne_frames := 0
	for frame in range(120):
		await physics_frame
		character.set_animation(Vector2.ZERO, false, false)
		if not character._animation_on_floor:
			airborne_frames += 1
			_check(character.LAST_ANIM_PLAYED == "Jump", "Jump must not cut to idle during ascent or descent")
		elif airborne_frames > 2:
			break
	_check(airborne_frames > 2, "Jump fixture must leave the floor")
	_check(character.LAST_ANIM_PLAYED == "Idle", "Jump must end on landing")
	character.CHARACTER_CONFIG = CharacterConfig.new({"IdleAnimation": "Idle", "JumpAnimation": "StageJump", "AirControlAnimation": "StageAir", "LandAnimation": "StageLand"})
	character.set_animation(Vector2.ZERO, false, false)
	character.move(Vector2.ZERO, 0.0, 1.0)
	var sequence: Array[String] = [character.LAST_ANIM_PLAYED]
	for frame in range(120):
		await physics_frame
		character.set_animation(Vector2.ZERO, false, false)
		player.advance(1.0 / 60.0)
		if sequence.back() != character.LAST_ANIM_PLAYED:
			sequence.append(character.LAST_ANIM_PLAYED)
		if sequence.back() == "Idle":
			break
	_check(sequence == ["StageJump", "StageAir", "StageLand", "Idle"], "Physical jump must complete Jump -> Air Control -> Land -> Idle: " + str(sequence))
	# The same contact test must work for rigs oriented to custom gravity.
	character.gravity_scale = 0.0
	character.rotation.z = -PI / 2.0
	character.position = Vector3(2, 5, 0)
	character.linear_velocity = Vector3.ZERO
	character.constant_force = Vector3(-9.8, 0, 0)
	floor_body.rotation.z = -PI / 2.0
	floor_body.position = Vector3(-0.5, 5, 0)
	for frame in range(120):
		await physics_frame
		character.set_animation(Vector2.ZERO, false, false)
		player.advance(1.0 / 60.0)
	character.set_animation(Vector2.ZERO, false, false)
	_check(character._animation_on_floor and character.LAST_ANIM_PLAYED == "Idle", "Rotated rigs must recognize floor contacts along their own up direction")
