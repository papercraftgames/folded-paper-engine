@icon("res://addons/folded_paper_engine/Engine/Input/input.svg")

class_name FPEInputMapper extends ScrollContainer

@export var MAPPING: DeviceMapping = DeviceMapping.new()

static func App(k, p = {}, d = {}, c = []) -> Dictionary:
	return FPEUI.FC(
		func(): return MarginContainer.new(),
		func(n, d, c, i) -> Array:
			var mapping := d.get("mapping") as DeviceMapping
			var on_mapping_change := d.get("on_mapping_change") as Callable
			var action_bar_data := d.get("action_bar_data", {}) as Dictionary
			var player_actions := InputConstants.PLAYER_ACTIONS.keys()
			var ui_actions := InputConstants.UI_ACTIONS.keys()
			
			var open_dialogue := FPEFC.FileDialogFC(
				"open-dialogue",
				{
					"file_mode": FileDialog.FILE_MODE_OPEN_FILE,
					"access": FileDialog.ACCESS_FILESYSTEM,
					"filters": PackedStringArray(["*.tres ; Resources", "*.res ; Binary Resources"]),
					"use_native_dialog": true,
					"$file_selected": func(path: String) -> void:
						var res := ResourceLoader.load(path)
						
						if res is DeviceMapping:
							if not res.device_type:
								res.device_type = DeviceType.new()
							
							on_mapping_change.call(res),
				},
			)
			var save_dialogue := FPEFC.FileDialogFC(
				"save-dialogue",
				{
					"file_mode": FileDialog.FILE_MODE_SAVE_FILE,
					"access": FileDialog.ACCESS_FILESYSTEM,
					"filters": PackedStringArray(["*.tres ; Resources", "*.res ; Binary Resources"]),
					"use_native_dialog": true,
					"$file_selected": func(path: String) -> void:
						ResourceSaver.save(mapping, path),
				},
			)
			
			d.set("action_bar_data", action_bar_data)
			
			return [
				FPEFC.VBoxContainerFC(
					"outer-vbox",
					{},
					{},
					FPEUI.ComposeChildren([
						FPEFC.HBoxContainerFC(
							"file-controls",
							{
								"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
								"alignment": BoxContainer.ALIGNMENT_END,
								"^separation": 12,
							},
							{},
							[
								FPEFC.LabelFC(
									"title-label",
									{
										"text": "Input Mapping",
										"^font_size": 32,
									},
								),
								FPEFC.ControlFC(
									"title-spacer",
									{
										"size_flags_horizontal": Control.SIZE_EXPAND,
									},
								),
								FPEFC.ButtonFC(
									"open-button",
									{
										"text": "Open Mapping",
										":normal:content_margin_top": 12,
										":normal:content_margin_right": 12,
										":normal:content_margin_bottom": 12,
										":normal:content_margin_left": 12,
										"$pressed": func() -> void:
											var d_node := open_dialogue.get("node") as FileDialog
											
											if d_node is FileDialog:
												d_node.popup_centered(),
									},
								),
								open_dialogue,
								FPEFC.ButtonFC(
									"save-button",
									{
										"text": "Save Mapping",
										":normal:content_margin_top": 12,
										":normal:content_margin_right": 12,
										":normal:content_margin_bottom": 12,
										":normal:content_margin_left": 12,
										"$pressed": func() -> void:
											var d_node := save_dialogue.get("node") as FileDialog
											
											if d_node is FileDialog:
												d_node.popup_centered(),
									},
								),
								save_dialogue,
							],
						),
						FPEFC.ControlFC(
							"title-content-spacer",
							{
								"custom_minimum_size": Vector2(25, 25)
							},
						),
						FPEFC.LabelFC(
							"controller_name_label",
							{
								"expand_to_text_length": true,
								"text": mapping.device_type.label if mapping.device_type.label else "Controller Name...",
							},
						),
						FPEFC.LabelFC(
							"controller_id_label",
							{
								"expand_to_text_length": true,
								"text": mapping.device_type.id if mapping.device_type.id else "Controller ID...",
							},
						),
						FPEFC.LabelFC(
							"controller_type_label",
							{
								"expand_to_text_length": true,
								"text": mapping.device_type.type if mapping.device_type.type else "Controller Type...",
							},
						),
						FPEFC.ControlFC(
							"spacer",
							{
								"custom_minimum_size": Vector2(25, 25)
							},
						),
						FPEFC.LabelFC(
							"player_controls_label",
							{
								"expand_to_text_length": true,
								"text": "Player Controls:",
							},
						),
						FPEFC.ControlFC(
							"spacer2",
							{
								"custom_minimum_size": Vector2(25, 25)
							},
						),
						FPEFC.VBoxContainerFC(
							"player_action_list",
							{
								"^separation": 10,
							},
							{},
							player_actions.map(
								func(action: String) -> Dictionary:
									var bar_data := action_bar_data.get(
										action, 
										{
											"action": action,
											"mapping": mapping,
											"auto_focus": player_actions.find(action) == 0,
										}
									) as Dictionary
									
									action_bar_data.set(action, bar_data)
									
									return FPEInputFC.MappingActionBar(
										action,
										{
											"^separation": 10,
										},
										bar_data,
									),
							),
						),
						FPEFC.ControlFC(
							"spacer3",
							{
								"custom_minimum_size": Vector2(25, 25)
							},
						),
						FPEFC.LabelFC(
							"ui_controls_label",
							{
								"expand_to_text_length": true,
								"text": "UI Controls:",
							},
						),
						FPEFC.ControlFC(
							"spacer4",
							{
								"custom_minimum_size": Vector2(25, 25)
							},
						),
						FPEFC.VBoxContainerFC(
							"ui_action_list",
							{
								"^separation": 10,
							},
							{},
							ui_actions.map(
								func(action: String) -> Dictionary:
									var bar_data := action_bar_data.get(
										action, 
										{
											"action": action,
											"mapping": mapping,
										}
									) as Dictionary
									
									action_bar_data.set(action, bar_data)
									
									return FPEInputFC.MappingActionBar(
										action,
										{
											"^separation": 10,
										},
										bar_data,
									),
							),
						),
					])
				)
			],
	).call(k, p, d, c)

func _init() -> void:
	DisplayServer.window_set_title("FPE Input Mapping")
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_render()

var _unmount: Callable

func _render() -> void:
	if not _unmount.is_null():
		_unmount.call()
	
	_unmount = FPEUI.Mount(
		App(
			"app",
			{
				"^margin_top": 25,
				"^margin_left": 25,
				"^margin_bottom": 25,
				"^margin_right": 25,
				"size_flags_horizontal": Control.SIZE_EXPAND_FILL,
			},
			{
				"mapping": MAPPING,
				"on_mapping_change": func(new_mapping: DeviceMapping) -> void:
					MAPPING = new_mapping
					_render(),
			},
		),
		self
	)
