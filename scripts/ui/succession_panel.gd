class_name SuccessionPanel
extends CanvasLayer

## Liderlik devri artık bir kayıt satırı değil, bir sahne. Oyunun tek
## "non-negotiable" kuralı - kervan asla tükenmez, ama lider ölürse kıdemli
## yoldaş adı devralır (bkz. CLAUDE.md Lineage Rules) - şimdiye kadar
## `UI_ROAD_NEW_LEADER` log satırından ibaretti; playtest'in okuduğu diğer
## on bir satırdan biri gibi kayıp gidiyordu.
##
## OnboardingPanel'in deseni: sahnesiz, `.new()` ile kurulur. Ama bilerek
## OnboardingPanel'den bir yerde ayrılıyor - perdeye tıklamak ve Esc burada
## KAPATMIYOR. Törenin tek çıkışı "Devam Et" tuşu: bu an atlanabilir olursa
## bir bildirimden farkı kalmaz.

signal dismissed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.85)
const PANEL_BACKGROUND: Color = Color(0.09, 0.08, 0.07)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.28)
const PANEL_WIDTH: float = 560.0

func setup(caravan_name: String, fallen_name: String, heir_name: String, generation: int) -> void:
	layer = 70
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var eyebrow := Label.new()
	eyebrow.text = tr("UI_SUCCESSION_TITLE")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.modulate = ArtPalette.GOLD_DIM
	vbox.add_child(eyebrow)

	var name_label := Label.new()
	name_label.text = tr("UI_SUCCESSION_CARAVAN") % caravan_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.modulate = ArtPalette.GOLD
	vbox.add_child(name_label)

	var generation_label := Label.new()
	generation_label.text = tr("UI_SUCCESSION_GENERATION") % generation
	generation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(generation_label)

	vbox.add_child(HSeparator.new())

	var fallen_label := Label.new()
	fallen_label.text = tr("UI_SUCCESSION_FALLEN") % fallen_name
	fallen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fallen_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(fallen_label)

	var heir_label := Label.new()
	heir_label.text = tr("UI_SUCCESSION_HEIR") % heir_name
	heir_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heir_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	heir_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(heir_label)

	var continue_button := Button.new()
	continue_button.text = tr("UI_CONTINUE")
	continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_button)

func _on_continue_pressed() -> void:
	dismissed.emit()
	queue_free()
