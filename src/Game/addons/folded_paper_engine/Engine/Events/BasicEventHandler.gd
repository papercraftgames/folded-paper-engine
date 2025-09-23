@icon("res://addons/folded_paper_engine/Engine/Events/event.svg")

class_name BasicEventHandler extends EventHandler

var HANDLER_FUNCTION: Callable

func _init(handler_function: Callable) -> void:
	HANDLER_FUNCTION = handler_function

func handle_event(event: FPEEvent) -> void:
	if HANDLER_FUNCTION:
		HANDLER_FUNCTION.call(event)
