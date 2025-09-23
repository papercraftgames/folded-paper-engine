class_name FPEInputFC

static func MappingInputMouseVelocityFC(k, p = {}, d = {}, c = []) -> Dictionary:
	return FPEUI.FC(
		func(): return OptionButton.new(),
		func(n: OptionButton, d, c, i) -> Array:
			var action := d.get("action") as String
			var mapping := d.get("mapping") as DeviceMapping
			
			if n.item_count < 1:
				var mouse_vel_base_items := [
					InputConstants.ACTUATOR_NAMES.MOUSE_VELOCITY_X,
					InputConstants.ACTUATOR_NAMES.MOUSE_VELOCITY_Y,
				]
				var mouse_vel_items: Array[String] = []
				
				for mv in mouse_vel_base_items:
					var np_postfixes := InputConstants.ACTUATOR_POSTFIXES.keys()
					
					for npp in np_postfixes:
						mouse_vel_items.append(
							InputConstants.ACTUATOR_ID_DELIMITER.join([InputConstants.ACTUATOR_PREFIXES.AXIS, mv, npp])
						)
				
				for mv in mouse_vel_items:
					n.add_item(mv, mouse_vel_items.find(mv))
				
				n.select(-1)
				
				FPEUI.on(n, "item_selected", "item_selected", func(ind: int) -> void:
					var actuator := mouse_vel_items.get(ind) as String
					
					mapping.add_action(action, actuator)
					n.select(-1)
					i.call()
				)
			
			return c,
	).call(k, p, d, c)

static func MappingInputFC(k, p = {}, d = {}, c = []) -> Dictionary:
	return FPEUI.FC(
		func(): return LineEdit.new(),
		func(node: LineEdit, data = {}, c = [], i = null) -> Array:
			var action := data.get("action") as String
			var mapping := data.get("mapping") as DeviceMapping
			var ui_locked := data.get("ui_locked", false) as bool
			var receiving := data.get("receiving", false) as bool
			var auto_focus := d.get("auto_focus", false) as bool
			
			node.editable = false
			node.placeholder_text = "ready..." if receiving else "Set a button/axis/key/etc"
			
			FPEUI.on_dep(node, "ready", "ready", [auto_focus], func() -> void:
				if auto_focus:
					node.grab_focus()
			)
			FPEUI.on_dep(
				node, 
				"gui_input", 
				"gui_input", 
				[action, mapping, ui_locked, receiving],
				func(event: InputEvent) -> void:
					if ui_locked:
						if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
							node.accept_event()  # stop Tab focus
						elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") \
							or event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
							node.accept_event()  # stop DPAD/arrow focus
					
					if node.has_focus():
						if receiving:
							var abs_value := abs(InputUtils.get_raw_standard_actuator_value(event))
							
							if abs_value > InputConstants.MAPPING_THRESHOLD:
								mapping.device_type.id = Input.get_joy_guid(event.device)
								mapping.device_type.label = Input.get_joy_name(event.device)
								mapping.device_type.type = InputUtils.get_controller_type(event.device)
								InputUtils.apply_input_to_mapping_action(event, mapping, action)
								
								data.set("receiving", false)
								i.call()
								
								var timer := Timer.new()
								node.add_child(timer)
								timer.start(0.3)
								await timer.timeout
								node.remove_child(timer)
								timer.queue_free()
								
								data.set("ui_locked", false)
								i.call()
						elif Input.is_action_pressed("ui_accept"):
							data.set("ui_locked", true)
							data.set("receiving", true)
							i.call()
			)
			
			return c
	).call(k, p, d, c)

static func MappingActionLabelFC(k, p = {}, d = {}, c = []) -> Dictionary:
	return FPEUI.FC(
		func(): return HBoxContainer.new(),
		func(n, d, c, i) -> Array:
			var action := d.get("action") as String
			var actuator := d.get("actuator") as String
			var mapping := d.get("mapping") as DeviceMapping
			
			return [
				FPEFC.LabelFC(
					"label",
					{
						"text": actuator,
						"expand_to_text_length": true,
					}
				),
				FPEFC.ButtonFC(
					"remove",
					{
						"text": "Remove",
						"$pressed": func() -> void:
							mapping.remove_action_actuator(action, actuator)
							i.call(),
					}
				)
			]
	).call(k, p, d, c)

static func MappingActionBar(k, p = {}, d = {}, c = []) -> Dictionary:
	return FPEUI.FC(
		func(): return HBoxContainer.new(),
		func(n, d, c, i) -> Array:
			var auto_focus := d.get("auto_focus", false) as bool
			var action := d.get("action", "") as String
			var mapping := d.get("mapping") as DeviceMapping
			var actuator_keys := mapping.get_actuators_for_action(action) as Array
			var input_data := d.get("input_data", {
				"auto_focus": auto_focus,
				"action": action,
				"mapping": mapping,
			}) as Dictionary
			
			d.set("input_data", input_data)
			
			return FPEUI.ComposeChildren([
				FPEFC.LabelFC(
					"action_name_label",
					{
						"text": action + ":",
						"expand_to_text_length": true,
						"size_flags_vertical": Control.SIZE_SHRINK_BEGIN,
					},
				),
				FPEFC.VBoxContainerFC(
					"vbox",
					{},
					{},
					FPEUI.ComposeChildren([
						FPEFC.HBoxContainerFC(
							"input-box",
							{
								"^separation": 12,
							},
							{},
							[
								MappingInputFC(
									"mapping_input",
									{
										"expand_to_text_length": true,
									},
									input_data,
								),
								MappingInputMouseVelocityFC(
									"mouse_input",
									{},
									input_data,
								),
							]
						),
						actuator_keys.map(
							func(actu: String) -> Dictionary:
								return MappingActionLabelFC(
									"_".join(["actuator_label", actu]),
									{
										"text": actu if actu else "",
										"expand_to_text_length": true,
									},
									{
										"action": action,
										"mapping": mapping,
										"actuator": actu,
									},
								),
						),
					])
				)
			])
	).call(k, p, d, c)
