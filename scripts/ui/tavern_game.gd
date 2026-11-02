class_name TavernGame
extends Control

## Tavernanın oyun masası (T16-06, N34): oyuncu masaya oturur, ekran açılır.
## Kullanıcı kararı (2026-11-02): şimdilik masada bir oyun yok; ekran açılır ve
## geri çıkılabilir. Oyun kurulunca bu ekranın gövdesi onu taşıyacak.
## Sahnesiz, `.new()` ile kurulur; tavernanın üstüne tam ekran biner.

signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = Color(ArtPalette.GRIM_CHARCOAL, 0.94)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620.0, 0.0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)

	var title := Label.new()
	title.text = tr("UI_TAVERN_GAME_TITLE")
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var body := Label.new()
	body.text = tr("UI_TAVERN_GAME_BODY")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	column.add_child(body)
	var leave := Button.new()
	leave.name = "LeaveButton"
	leave.text = tr("UI_TAVERN_GAME_LEAVE")
	leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave.pressed.connect(close)
	column.add_child(leave)
	leave.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func close() -> void:
	closed.emit()
	queue_free()
