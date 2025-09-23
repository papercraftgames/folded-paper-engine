@icon("res://addons/folded_paper_engine/Engine/Conversation/conversation.svg")

class_name FPEConversationManager extends Node

signal conversation_started(conversation_instance: ConversationInstance, conversation_manager: FPEConversationManager)
signal conversation_changed(conversation_instance: ConversationInstance, conversation_manager: FPEConversationManager)
signal conversation_ended(conversation_instance: ConversationInstance, conversation_manager: FPEConversationManager)

static var GLOBAL_CONVERSATION_MANAGER: FPEConversationManager
static var CURRENT_CONVERSATION_INSTANCE: ConversationInstance
static var CURRENT_CONVERSATION_OWNER: Node
static var CURRENT_CONVERSATION_INITIALIZER: Node

func _init() -> void:
	if not GLOBAL_CONVERSATION_MANAGER:
		GLOBAL_CONVERSATION_MANAGER = self

func _process_conversation_event(
	conversation_instance: ConversationInstance,
	conversation_owner: Node,
	conversation_initializer: Node,
	) -> void:
	if conversation_instance \
	and conversation_instance.current_comment \
	and conversation_owner \
	and conversation_initializer:
		var comment: Comment = conversation_instance.current_comment
		
		if comment.event_type:
			var event := FPEEvent.new(
				comment.event_type,
				conversation_owner,
				conversation_initializer,
				comment.event_data,
			)
			
			FPEEventManager.dispatch_event(event)

func start(conversation_owner: Node, conversation_initializer: Node, conversation_options: Array) -> void:
	if not CURRENT_CONVERSATION_INSTANCE:
		var conversation_list := ConversationUtils.load_conversations_from_file_item_list(conversation_options)
		var character_names := ConversationUtils.get_all_character_names_from_all_nodes([
			conversation_owner,
			conversation_initializer,
		])
		var conversation := ConversationUtils.select_conversation(conversation_list, character_names)
		
		if conversation:
			var conversation_instance := ConversationUtils.create_conversation(
				conversation,
				conversation_owner,
				conversation_initializer,
			)
			
			CURRENT_CONVERSATION_INSTANCE = conversation_instance
			CURRENT_CONVERSATION_OWNER = conversation_owner
			CURRENT_CONVERSATION_INITIALIZER = conversation_initializer
			
			_process_conversation_event(
				CURRENT_CONVERSATION_INSTANCE,
				CURRENT_CONVERSATION_OWNER,
				CURRENT_CONVERSATION_INITIALIZER,
			)
			
			if GLOBAL_CONVERSATION_MANAGER:
				GLOBAL_CONVERSATION_MANAGER.conversation_started.emit(conversation_instance, GLOBAL_CONVERSATION_MANAGER)

func select_reply(reply_index: int, end_on_complete: bool = true) -> void:
	if CURRENT_CONVERSATION_INSTANCE:
		var conversation_instance := ConversationUtils.select_reply(CURRENT_CONVERSATION_INSTANCE, reply_index)
		
		CURRENT_CONVERSATION_INSTANCE = conversation_instance
		
		_process_conversation_event(
			CURRENT_CONVERSATION_INSTANCE,
			CURRENT_CONVERSATION_OWNER,
			CURRENT_CONVERSATION_INITIALIZER,
		)
		
		if GLOBAL_CONVERSATION_MANAGER:
			GLOBAL_CONVERSATION_MANAGER.conversation_changed.emit(conversation_instance, GLOBAL_CONVERSATION_MANAGER)
			
			if end_on_complete:
				# TRICKY: Always call end(), it takes care of its own conditions.
				GLOBAL_CONVERSATION_MANAGER.end()

func end() -> void:
	if CURRENT_CONVERSATION_INSTANCE and CURRENT_CONVERSATION_INSTANCE.complete:
		var conversation_instance := CURRENT_CONVERSATION_INSTANCE
		
		CURRENT_CONVERSATION_INSTANCE = null
		CURRENT_CONVERSATION_OWNER = null
		CURRENT_CONVERSATION_INITIALIZER = null
		
		GLOBAL_CONVERSATION_MANAGER.conversation_ended.emit(conversation_instance, GLOBAL_CONVERSATION_MANAGER)
