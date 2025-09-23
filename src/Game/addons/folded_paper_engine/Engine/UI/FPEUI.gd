@icon("res://addons/folded_paper_engine/Engine/UI/fpeui.svg")

class_name FPEUI

static func update_children(node: Node, wanted: Array[Node]) -> void:
	# Build membership set (skip nulls/freed) and dedupe preserving order
	var seen: Dictionary = {}
	var ordered: Array[Node] = []
	for ch in wanted:
		if ch != null and is_instance_valid(ch) and not seen.has(ch):
			seen[ch] = true
			ordered.append(ch)

	# Remove those not wanted
	var current := node.get_children()
	for ch in current:
		if not seen.has(ch):
			node.remove_child(ch)
			ch.queue_free()

	# Ensure parenting and order without churn
	var i := 0
	for ch in ordered:
		# attach if needed (no remove+add for existing children)
		if ch.get_parent() != node:
			if ch.get_parent() != null:
				ch.reparent(node)  # use ch.reparent(node, true) if you must keep global xform
			else:
				node.add_child(ch)
		# put at correct index (doesn't drop focus/state)
		if node.get_child(i) != ch:
			node.move_child(ch, i)
		i += 1

static func Mount(entry: Dictionary, parent: Node) -> Callable:
	var root_node: Node = null
	
	if entry is Dictionary and entry.has("comp"):
		var entry_comp: Callable = entry.get("comp")
		
		root_node = entry_comp.call({}) as Node
		entry.set("node", root_node)
		parent.add_child(root_node)
	
	return func() -> void:
		if root_node:
			parent.remove_child(root_node)
			root_node.queue_free()

static func FC(construct: Callable, render: Variant = null) -> Callable:
	return func(key: String, props: Dictionary = {}, data: Variant = null, children: Array = []) -> Dictionary:
		if not key is String:
			push_error("Invalid key")
		
		return {
			"key": key,
			"node": null,
			"comp": func(context: Dictionary, invalidate: Variant = null, existing_node: Node = null) -> Node:
				var node := existing_node if existing_node is Node else construct.call() as Node
				var invalidation_holder: Dictionary = {
					"invalidate": invalidate,
				}
				var update: Callable = func() -> void:
					# Tracking
					var child_nodes := context.get("child_nodes", {}) as Dictionary
					var child_contexts := context.get("child_contexts", {}) as Dictionary
					# Updates
					var child_node_order: Array[String] = []
					var next_children: Array[Node] = []
					var new_rendered_child_nodes := render.call(node, data, children, invalidation_holder.invalidate) as Array if render is Callable else children
					
					for p in props:
						var str_p := str(p)
						
						if str_p.begins_with("$"):
							var signal_name := str_p.substr(1)
							
							on(node, signal_name, signal_name, props.get(p))
						elif str_p.begins_with("^") and node is Control:
							var control_node := node as Control
							var override := str_p.substr(1)
							
							if override == "font_size":
								control_node.add_theme_font_size_override(override, props.get(p))
							else:
								control_node.add_theme_constant_override(override, props.get(p))
						elif str_p.begins_with(":") and node is Control:
							var control_node := node as Control
							var style_box_info := str_p.substr(1).split(":")
							var style_box_type := style_box_info.get(0)
							var style_box_prop := style_box_info.get(1)
							var style_box := control_node.get_theme_stylebox(style_box_type)
							
							if not control_node.has_theme_stylebox_override(style_box_type):
								style_box = style_box.duplicate()
							
							style_box.set(style_box_prop, props.get(p))
							control_node.add_theme_stylebox_override(style_box_type, style_box)
						else:
							if node.get(p) != props.get(p):
								node.set(p, props.get(p))
					
					for c in new_rendered_child_nodes:
						if c is Dictionary and c.has("comp") and c.has("key"):
							var c_key: String = c.get("key")
							var c_comp: Callable = c.get("comp")
							# Context
							var c_context := child_contexts.get(c_key, {}) as Dictionary
							# Nodes
							var last_c_node: Variant = child_nodes.get(c_key)
							var c_node := c_comp.call(c_context, invalidation_holder.invalidate, last_c_node) as Node
							
							c.set("node", c_node)
							
							child_node_order.append(c_key)
							child_nodes.set(c_key, c_node)
							child_contexts.set(c_key, c_context)
					
					for c_k in child_node_order:
						if child_nodes.has(c_k):
							var cn := child_nodes.get(c_k) as Node
							
							if cn is Node:
								next_children.append(cn)
					
					# IMPORTANT: Clean-up removed child nodes.
					for c_key in child_nodes:
						if not child_node_order.has(c_key):
							# WARNING: This will crash if you don't clean-up and remove these.
							child_nodes.erase(c_key)
							child_contexts.erase(c_key)
					
					context.set("child_nodes", child_nodes)
					context.set("child_contexts", child_contexts)
					
					update_children(node, next_children)
				
				if invalidation_holder.invalidate is not Callable:
					invalidation_holder.invalidate = update
				
				update.call()
				
				return node,
		}

static func _flat_into(arr: Array, out: Array, level: int, depth: int) -> void:
	for v in arr:
		if v is Array and (depth < 0 or level < depth):
			_flat_into(v, out, level + 1, depth)
		else:
			out.append(v)

static func ComposeChildren(arr: Array, depth: int = -1) -> Array:
	var out: Array = []
	_flat_into(arr, out, 0, depth)
	return out

static var _wired: Dictionary = {} # id -> { keys: Dictionary, cleanups_by_key: Dictionary[String, Array[Callable]] }

static func _dispose_all_id(id: int) -> void:
	var b := _wired.get(id)
	if b != null:
		for key in b["cleanups_by_key"]:
			var arr: Array = b["cleanups_by_key"][key]
			for c in arr:
				c.call_deferred()
		_wired.erase(id)

static func wire_once(node: Object, key: String, setup: Callable, cleanup: Variant) -> void:
	var id := node.get_instance_id()
	var b := _bucket(id)
	if not b["keys"].has(key):
		b["keys"][key] = true
		if cleanup is Callable:
			var arr := b["cleanups_by_key"].get(key, []) as Array
			if arr == null:
				arr = []
				b["cleanups_by_key"][key] = arr
			arr.append(cleanup)
		setup.call()
		if node is Node and not b["keys"].has("__cleanup_hook"):
			b["keys"]["__cleanup_hook"] = true
			(node as Node).tree_exiting.connect(func() -> void:
				_dispose_all_id(id)
			)

static func _bucket(id: int) -> Dictionary:
	var b := _wired.get(id)
	if b == null:
		b = {}
		_wired[id] = b
	return b

static func _stable_repr(v: Variant) -> Variant:
	if v is Callable:
		var o = v.get_object()
		var oid := -1
		if o != null:
			oid = o.get_instance_id()
		return {"__callable__": true, "m": v.get_method(), "id": oid}
	elif v is Object:
		return {"__obj__": true, "id": v.get_instance_id()}
	elif typeof(v) == TYPE_ARRAY:
		var out: Array = []
		for e in v:
			out.append(_stable_repr(e))
		return out
	elif typeof(v) == TYPE_DICTIONARY:
		var out := {}
		var ks = v.keys()
		ks.sort()
		for k in ks:
			out[k] = _stable_repr(v[k])
		return out
	else:
		return v

static func _deps_hash(deps: Array) -> int:
	return hash(_stable_repr(deps))

# New: deps-aware wiring (reconnect when deps change)
static func on_dep(node: Object, signal_name: StringName, key: StringName, deps: Array, cb: Callable) -> void:
	var id := node.get_instance_id()
	var b := _bucket(id)
	var new_h := _deps_hash(deps)

	var rec := b.get(key)
	if rec == null:
		b[key] = {"signal": signal_name, "cb": cb, "deps_hash": new_h}
		node.connect(signal_name, cb)
		if node is Node and not b.has(&"__cleanup__"):
			b[&"__cleanup__"] = true
			(node as Node).tree_exiting.connect(func() -> void:
				var last := _wired.get(id)
				if last != null:
					for k in last.keys():
						if k != &"__cleanup__":
							var sig: StringName = last[k]["signal"]
							var old_cb: Callable = last[k]["cb"]
							if node.is_connected(sig, old_cb):
								node.disconnect(sig, old_cb)
					_wired.erase(id)
			)
	else:
		if int(rec["deps_hash"]) != new_h or rec["cb"] != cb:
			var old_cb: Callable = rec["cb"]
			if node.is_connected(signal_name, old_cb):
				node.disconnect(signal_name, old_cb)
			rec["cb"] = cb
			rec["deps_hash"] = new_h
			node.connect(signal_name, cb)

# Back-compat shorthand (no deps)
static func on(node: Object, signal_name: StringName, key: StringName, cb: Callable) -> void:
	on_dep(node, signal_name, key, [], cb)

# Optional manual cleanup
static func off(node: Object, key: StringName) -> void:
	var id := node.get_instance_id()
	var b := _wired.get(id)
	if b != null and b.has(key):
		var sig = b[key]["signal"]
		var old_cb = b[key]["cb"]
		if node.is_connected(sig, old_cb):
			node.disconnect(sig, old_cb)
		b.erase(key)

static func dispose(node: Object, key: String) -> void:
	var id := node.get_instance_id()
	var b := _wired.get(id)
	if b != null:
		if b["keys"].has(key):
			b["keys"].erase(key)
		var arr: Array = b["cleanups_by_key"].get(key)
		if arr != null:
			for c in arr:
				c.call()
			b["cleanups_by_key"].erase(key)
		if b["keys"].size() == 0 and b["cleanups_by_key"].size() == 0:
			_wired.erase(id)

static func dispose_all(node: Object) -> void:
	var id := node.get_instance_id()
	_dispose_all_id(id)

static func rewire(node: Object, key: String, setup: Callable, cleanup: Variant = null) -> void:
	dispose(node, key)
	wire_once(node, key, setup, cleanup)

static func effect(node: Object, key: String, setup: Callable, cleanup: Callable) -> void:
	wire_once(node, "eff_%s" % key, setup, cleanup)
