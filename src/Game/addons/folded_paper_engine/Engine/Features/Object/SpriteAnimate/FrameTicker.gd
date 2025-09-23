class_name FrameTicker extends Node

var FPE_GLOBALS: FPEGlobals

var _NODE: Node
var _SPEED: float = 1.0
var _LAST_FRAME: int = 1
var _current_frame: float = 1.0

var _PLAYING: bool = true

func _init(node: Node3D, data: Variant, fpe_globals: FPEGlobals) -> void:
	_NODE = node
	_LAST_FRAME = _NODE.get_children().size()
	FPE_GLOBALS = fpe_globals
	
	if data is float:
		_SPEED = data
	
	FPE_GLOBALS.STAGE_SCENE.add_child(self)

func destroy() -> void:
	if self.is_inside_tree():
		FPE_GLOBALS.STAGE_SCENE.remove_child(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		destroy()

func _process(_delta: float) -> void:
	if _NODE and _PLAYING:
		var cf = floor(_current_frame)
		var children = _NODE.get_children()
		var child_len = children.size()
		
		for i in child_len:
			var ch = _NODE.get_child(i)
			
			if ch is Node3D:
				var ch_3D: Node3D = ch as Node3D
				var vis: bool = i + 1 == cf
				
				if vis:
					ch_3D.show()
				else:
					ch_3D.hide()
		
		_current_frame += _SPEED
		
		if _current_frame >= _LAST_FRAME + 1:
			_current_frame = 1.0

func is_playing() -> bool:
	return _PLAYING

func play() -> void:
	_PLAYING = true

func pause() -> void:
	_PLAYING = false

func stop() -> void:
	_PLAYING = false
	_current_frame = 0.0
