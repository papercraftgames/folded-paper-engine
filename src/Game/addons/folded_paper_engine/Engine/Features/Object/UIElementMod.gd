class_name UIElementMode extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	if node and data:
		var config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.UIElement)
		
		if config:
			var is_ui_cursor := config.get("UICursor", 0.0) as float
			var is_ui_option := config.get("UIOption", 0.0) as float
			
			if is_ui_cursor:
				var cursor_depth := config.get("UICursorDepth", 10.0) as float
				var cursor_select_anim := config.get("UICursorSelectAnimation", "") as String
				var cursor_look_at_camera := config.get("UICursorLookAtCamera", 0.0) as float
				var parent := node.get_parent()
				
				if parent:
					var cursor := Cursor3D.new(
						FEATURE_UTILS, 
						node, 
						cursor_depth, 
						cursor_select_anim,
						cursor_look_at_camera,
					)
					
					FPEGlobals.CURSOR_LIST.append(cursor)
					
					var cursor_index := FPEGlobals.CURSOR_LIST.find(cursor)
					var device_proxy := FPEGlobals.DEVICE_PROXY_LIST.get(cursor_index)
					
					if not device_proxy:
						var device_index := InputUtils.get_device_index_for_player_index(cursor_index)
						var mapping := InputUtils.get_controller_mapping(device_index)
						
						device_proxy = InputUtils.get_device_proxy(device_index, mapping, cursor_index == 0)
						FPEGlobals.DEVICE_PROXY_LIST.append(device_proxy)
					
					cursor.set_device_proxy(device_proxy)
					
					UserDataUtils.apply_user_data(node, cursor)
					parent.add_child(cursor)
			elif is_ui_option:
				var ui_option := UIOption3D.new(
					node,
					func(triggered_by: Node, trigger_type: String) -> void:
						FEATURE_UTILS.TRIGGER_UTILS.trigger_events(node, triggered_by, trigger_type),
					true,
				)
				
				FEATURE_UTILS.FPE_GLOBALS.UI_OPTIONS.append(ui_option)
