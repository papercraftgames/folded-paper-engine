class_name TriggerMod extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	# data is boolean, true or false, do or do not.
	if data:
		var tracking_area := TrackingArea3D.new(
			node,
			func(triggered_by: Node, trigger_type: String) -> void:
				FEATURE_UTILS.TRIGGER_UTILS.trigger_events(node, triggered_by, trigger_type),
		)
