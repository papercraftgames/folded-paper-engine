class_name SpeakerUtils

static func wait_for_speaker(node: Node) -> void:
	if node is AudioStreamPlayer3D:
		var speaker := node as AudioStreamPlayer3D
		
		if speaker.playing:
			await speaker.finished

static func wait_for_speakers_to_finish(node: Node) -> void:
	if node is Node:
		var node_children := node.get_children()
		
		await wait_for_speaker(node)
			
		for child in node_children:
				await wait_for_speaker(child)
