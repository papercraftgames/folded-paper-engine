class_name SceneEventHandler extends EventHandler

var COMMAND_UTILS: CommandUtils
var COMMAND_CONFIG: Dictionary

func _init(command_utils: CommandUtils, command_config: Dictionary) -> void:
	COMMAND_UTILS = command_utils
	COMMAND_CONFIG = command_config

func handle_event(event: FPEEvent) -> void:
	if COMMAND_UTILS and COMMAND_CONFIG:
		COMMAND_UTILS.execute_commands_with_config(
			event.owner, 
			COMMAND_CONFIG, 
			event.initiator,
		)
