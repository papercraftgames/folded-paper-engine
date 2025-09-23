class_name NodeWatcher

var _NODE: Node = null
var _TREE_ENTERED: Callable
var _TREE_EXITED: Callable

# Watch a node for tree events.
# 
# @param node The Node to watch.
# @param tree_entered A function called on "tree_entered", recieves `node`.
# @param tree_exited A function called on "tree_exited", recieves `node`.
# 
# @return void
func _init(node: Node, tree_entered: Callable, tree_exited: Callable) -> void:
	_TREE_ENTERED = tree_entered
	_TREE_EXITED = tree_exited
	self.node = node

var node: Node:
	get:
		return _NODE
	set(value):
		if _NODE:
			_NODE.disconnect("tree_entered", _on_node_tree_entered)
			_NODE.disconnect("tree_exited", _on_node_tree_exited)
		
		_NODE = value
		
		if _NODE:
			_NODE.connect("tree_entered", _on_node_tree_entered)
			_NODE.connect("tree_exited", _on_node_tree_exited)
		
		_on_node_tree_entered()

func _on_node_tree_entered():
	if _NODE and _NODE.is_inside_tree():
		_TREE_ENTERED.call()

func _on_node_tree_exited():
	if _NODE and not _NODE.is_inside_tree():
		_TREE_EXITED.call()
