@icon("res://addons/folded_paper_engine/Engine/Events/event.svg")

class_name FPEEvent

var type: String
var owner: Node
var initiator: Node
var data: Variant

func _init(event_type: String, event_owner: Node, event_initiator: Node, event_data: Variant = null) -> void:
	type = event_type
	owner = event_owner
	initiator = event_initiator
	data = event_data
