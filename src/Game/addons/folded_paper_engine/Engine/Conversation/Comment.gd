@icon("res://addons/folded_paper_engine/Engine/Conversation/conversation.svg")

class_name Comment extends Resource

@export var content: String = ""
@export var possible_replies: Array[Reply] = []
@export var event_type: String = ""
@export var event_data: Dictionary = {}
