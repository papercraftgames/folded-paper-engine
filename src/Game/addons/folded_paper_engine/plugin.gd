# res://addons/folded_paper_engine/plugin.gd
@tool
extends EditorPlugin

var _icon := preload("res://addons/folded_paper_engine/icon.svg")
var _inventory_icon := preload("res://addons/folded_paper_engine/Engine/Inventory/inventory.svg")
var _conversation_icon := preload("res://addons/folded_paper_engine/Engine/Conversation/conversation.svg")
var _event_icon := preload("res://addons/folded_paper_engine/Engine/Events/event.svg")

var _ext: GLBMetaInclude

func _enter_tree() -> void:
	_ext = GLBMetaInclude.new()
	GLTFDocument.register_gltf_document_extension(_ext)
	add_custom_type(
		"FoldedPaperEngine",
		"Node",
		preload("res://addons/folded_paper_engine/FoldedPaperEngine.gd"),
		_icon
	)
	add_custom_type(
		"FPEInventoryConfig",
		"Node",
		preload("res://addons/folded_paper_engine/Engine/Inventory/FPEInventoryConfig.gd"),
		_inventory_icon
	)
	add_custom_type(
		"FPEConversationManager",
		"Node",
		preload("res://addons/folded_paper_engine/Engine/Conversation/FPEConversationManager.gd"),
		_conversation_icon
	)
	add_custom_type(
		"FPEEventManager",
		"Node",
		preload("res://addons/folded_paper_engine/Engine/Events/FPEEventManager.gd"),
		_event_icon
	)

func _exit_tree() -> void:
	if _ext:
		GLTFDocument.unregister_gltf_document_extension(_ext)
		_ext = null
	remove_custom_type("FoldedPaperEngine")
	remove_custom_type("FPEInventoryConfig")
	remove_custom_type("ConversationManager")
