@icon("res://addons/folded_paper_engine/Engine/Events/event.svg")

class_name FPEEventManager extends Node

static var GLOBAL_INSTANCE: FPEEventManager = FPEEventManager.new()

signal fpe_event(event: FPEEvent)

var EVENT_UTILS: EventUtils

func _init() -> void:
	if not GLOBAL_INSTANCE:
		GLOBAL_INSTANCE = self
	
	EVENT_UTILS = EventUtils.new()

static func _get_event_utils() -> EventUtils:
	return GLOBAL_INSTANCE.EVENT_UTILS

static func dispatch_event(event: FPEEvent) -> void:
	_get_event_utils().dispatch_event(event)

static func add_event_handler(type: String, handler: EventHandler) -> void:
	_get_event_utils().add_event_handler(type, handler)

static func remove_event_handler(type: String, handler: EventHandler) -> void:
	_get_event_utils().remove_event_handler(type, handler)
