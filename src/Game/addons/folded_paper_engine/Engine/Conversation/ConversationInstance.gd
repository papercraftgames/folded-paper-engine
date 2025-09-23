@icon("res://addons/folded_paper_engine/Engine/Conversation/conversation.svg")

class_name ConversationInstance extends Resource

@export var instance_id: String = ""
@export var conversation_id: String = ""

var owner_name: String
var owner_sidekick_names: Array[String]
var initializer_name: String
var initializer_sidekick_names: Array[String]
var current_comment: Comment
var complete: bool = false
