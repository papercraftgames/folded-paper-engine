class_name ConversationUtils

static func get_conversation_instance_id() -> String:
	var b := Crypto.new().generate_random_bytes(16)  # CSPRNG
	# RFC 4122 bits
	b[6] = (b[6] & 0x0F) | 0x40  # version 4
	b[8] = (b[8] & 0x3F) | 0x80  # variant 10xx
	
	var parts: Array[String] = [
		"%02x%02x%02x%02x" % [b[0], b[1], b[2], b[3]],
		"%02x%02x"         % [b[4], b[5]],
		"%02x%02x"         % [b[6], b[7]],
		"%02x%02x"         % [b[8], b[9]],
		"%02x%02x%02x%02x%02x%02x" % [b[10], b[11], b[12], b[13], b[14], b[15]],
	]
	
	return "-".join(parts)

static func select_conversation(conversations: Array[Conversation], characters: Array[String]) -> Conversation:
	var selected: Conversation = null
	
	for conv in conversations:
		var do_select: bool = true
		
		if conv.required_characters is Array and conv.required_characters.size() > 0 and characters.size() > 0:
			for req in conv.required_characters:
				if not characters.has(req):
					do_select = false
					break
			
			if do_select:
				for char in characters:
					if not conv.required_characters.has(char):
						do_select = false
						break
		
		if do_select:
			selected = conv
			break
	
	return selected

static func conversation_is_complete(conversation_instance: ConversationInstance) -> bool:
	return  conversation_instance.current_comment.possible_replies.size() == 0 \
		if conversation_instance and conversation_instance.current_comment and conversation_instance.current_comment.possible_replies \
		else true

static func create_conversation(conversation: Conversation, conversation_owner: Node, conversation_initializer: Node) -> ConversationInstance:
	var conversation_instance := ConversationInstance.new()
	conversation_instance.instance_id = get_conversation_instance_id()
	conversation_instance.conversation_id = conversation.conversation_id
	conversation_instance.current_comment = conversation.initial_comment
	conversation_instance.complete = conversation_is_complete(conversation_instance)
	
	# Apply names
	conversation_instance.owner_name = ConversationUtils.get_character_name_from_node(conversation_owner)
	conversation_instance.owner_sidekick_names = ConversationUtils.get_sidekick_character_names_from_node(conversation_owner)
	conversation_instance.initializer_name = ConversationUtils.get_character_name_from_node(conversation_initializer)
	conversation_instance.initializer_sidekick_names = ConversationUtils.get_sidekick_character_names_from_node(conversation_initializer)
	
	return conversation_instance

static func select_reply(conversation_instance: ConversationInstance, reply_index: int) -> ConversationInstance:
	var reply := conversation_instance.current_comment.possible_replies[reply_index]
	
	conversation_instance.current_comment = reply.follow_up_comment
	conversation_instance.complete = conversation_is_complete(conversation_instance)
	
	return conversation_instance

static func get_character_name_from_node(node: Node) -> String:
	var node_name: String = ""
	
	if node:
		if is_instance_of(node, CharacterControls):
			var char := node as CharacterControls
			
			node_name = char.get_character_name()
		else:
			node_name = str(node.name)
	
	return node_name

static func get_sidekick_character_names_from_node(node: Node) -> Array[String]:
	var names: Array[String] = []
	
	if is_instance_of(node, CharacterControls):
		var node_char := node as CharacterControls
		var chars := node_char.get_sidekicks()
		
		for ch in chars:
			var char_name := get_character_name_from_node(ch)
			
			if char_name:
				names.append(char_name)
	
	return names

static func get_all_character_names_from_node(node: Node) -> Array[String]:
	var names: Array[String] = []
	var node_name := get_character_name_from_node(node)
	
	if node_name:
		names.append(node_name)
	
	names.append_array(get_sidekick_character_names_from_node(node))
	
	return names

static func get_all_character_names_from_all_nodes(nodes: Array[Node]) -> Array[String]:
	var names: Array[String] = []
	
	if nodes:
		for n in nodes:
			var cur_names := get_all_character_names_from_node(n)
			
			names.append_array(cur_names)
	
	return names

static func load_conversation_from_file_item(file_item: Dictionary) -> Conversation:
	var conversation: Conversation = null
	
	if file_item and file_item is Dictionary and file_item.has("path") and file_item.path:
		conversation = load(file_item.path) as Conversation
	
	return conversation

static func load_conversations_from_file_item_list(file_item_list: Array) -> Array[Conversation]:
	var conversations: Array[Conversation] = []
	
	if file_item_list and file_item_list is Array:
		for fi in file_item_list:
			var conv := load_conversation_from_file_item(fi)
			
			if is_instance_of(conv, Conversation):
				conversations.append(conv)
	
	return conversations
