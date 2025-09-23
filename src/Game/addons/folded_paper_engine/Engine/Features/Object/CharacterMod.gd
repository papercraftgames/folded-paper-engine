class_name CharacterMod extends FeatureBase

const CHARACTER_RIG: PackedScene = preload("res://addons/folded_paper_engine/Engine/Features/Object/Character/CharacterRig.tscn")
const AI_CHARACTER_SCRIPT: Script = preload("res://addons/folded_paper_engine/Engine/Features/Object/Character/AICharacterControls.gd")
const PLAYER_SCRIPT: Script = preload("res://addons/folded_paper_engine/Engine/Features/Object/Character/PlayerControls.gd")

func apply(node: Node3D, data: Variant) -> void:
	if node and data:
		var parent = node.get_parent()
		
		if parent:
			var object_config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.Object)
			var is_player: bool = true if object_config and object_config.has("Player") and object_config.Player else false
			var has_physics: bool = true if object_config and object_config.has("Physics") and object_config.Physics else false
			var config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.Character)
			var script: Script = PLAYER_SCRIPT if is_player else AI_CHARACTER_SCRIPT
			var rig := CHARACTER_RIG.instantiate()
			
			UserDataUtils.apply_user_data(node, rig)
			
			rig.set_script(script)
			rig.set_feature_utils(FEATURE_UTILS)
			
			# IMPORTANT: Allow the character to be controlled in the physics controls.
			FEATURE_UTILS.RIGID_BODY_UTILS.add(rig)
			
			if is_player:
				var controls_config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.PlayerControls)
				var player := rig as PlayerControls
				
				FPEGlobals.PLAYER_LIST.append(player)
				
				var player_index := FPEGlobals.PLAYER_LIST.find(player)
				var device_proxy: DeviceProxy = FPEGlobals.DEVICE_PROXY_LIST.get(player_index) if not FPEGlobals.DEVICE_PROXY_LIST.is_empty() else null
				
				if not device_proxy:
					var device_index := InputUtils.get_device_index_for_player_index(player_index)
					var mapping := InputUtils.get_controller_mapping(device_index)
					
					device_proxy = InputUtils.get_device_proxy(device_index, mapping, player_index == 0)
					FPEGlobals.DEVICE_PROXY_LIST.append(device_proxy)
				
				player.set_device_proxy(device_proxy)
				
				player.set_player_controls_config(controls_config)
			
			parent.add_child(rig)
			rig.position = node.position
			rig.set_character_mesh(node)
			rig.setup_character_config(config)
		
			if has_physics:
				var physics_mod := PhysicsMod.new(FEATURE_UTILS)
				
				physics_mod.apply(rig, true)
