class_name PlaceholderHelper
extends RefCounted

static func create_box(box_size: Vector2, color: Color, label_text: String = "") -> Control:
	var container := Control.new()
	container.custom_minimum_size = box_size

	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(rect)

	if not label_text.is_empty():
		var label := Label.new()
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		container.add_child(label)

	return container
