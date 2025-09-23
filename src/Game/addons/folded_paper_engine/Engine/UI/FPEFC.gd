@icon("res://addons/folded_paper_engine/Engine/UI/fpeui.svg")

class_name FPEFC

static func VBoxContainerFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(func(): return VBoxContainer.new()).call(k, p, d, c)

static func HBoxContainerFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(func(): return HBoxContainer.new()).call(k, p, d, c)

static func LineEditFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(
	func(): return LineEdit.new(),
	func(n: LineEdit, d, c, i) -> Array:
		var auto_focus := d.get("auto_focus", false) as bool
		
		FPEUI.on_dep(n, "ready", "ready", [auto_focus], func() -> void:
			if auto_focus:
				n.grab_focus()
		)
		
		return c
).call(k, p, d, c)

static func LabelFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(func(): return Label.new()).call(k, p, d, c)

static func ControlFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(func(): return Control.new()).call(k, p, d, c)

static func ButtonFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(func(): return Button.new()).call(k, p, d, c)

static func FileDialogFC(k, p = {}, d = {}, c = []) -> Dictionary: return FPEUI.FC(func(): return FileDialog.new()).call(k, p, d, c)
