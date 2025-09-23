class_name Debounce

var _delay: float = 0.20
var _ticket: int = 0
var _pending: bool = false

func _init(delay: float) -> void:
	_delay = delay

func trigger(action: Callable) -> void:
	# Equivalent to clearTimeout() + setTimeout()
	_ticket += 1
	var my_ticket := _ticket
	_pending = true

	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		await tree.create_timer(_delay).timeout
		var is_latest := my_ticket == _ticket
		if is_latest:
			_pending = false
			if action.is_valid():
				action.call()

func cancel() -> void:
	# Cancels any pending trigger
	_ticket += 1
	_pending = false

func pending() -> bool:
	return _pending
