class_name NodeUtils

static func find_node_by_name(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	for child in root.get_children():
		var found = find_node_by_name(child, name)
		if found:
			return found
	return null
