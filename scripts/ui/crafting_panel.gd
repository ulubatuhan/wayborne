class_name CraftingPanel
extends CanvasLayer

## Atölye: basit bir Rust tarzı craft menüsü - malzeme + tek tık. Kervanın
## toplam envanterini (bkz. GameSession.get_total_quantity) okur, RecipeCatalog'un
## sabit tariflerini listeler. `MealDistributionPanel`in sahnesiz deseni.

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.75)
const PANEL_BACKGROUND: Color = Color(0.09, 0.08, 0.07)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.28)
const PANEL_WIDTH: float = 480.0
const OK_COLOR: Color = Color(0.7, 0.85, 0.7)
const MISSING_COLOR: Color = Color(0.85, 0.45, 0.4)

var _session: GameSession
var _rows: Array[Dictionary] = []
var _message_label: Label

func setup(session: GameSession) -> void:
	_session = session
	layer = 65

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
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_CRAFT_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_message_label)

	vbox.add_child(HSeparator.new())

	for recipe in RecipeCatalog.get_recipes():
		vbox.add_child(_build_row(recipe))
		vbox.add_child(HSeparator.new())

	var close_button := Button.new()
	close_button.text = tr("UI_CRAFT_CLOSE")
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)

	_refresh_rows()

func _build_row(recipe: CraftingRecipe) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var name_label := Label.new()
	name_label.text = recipe.recipe_name
	name_label.tooltip_text = recipe.description
	row.add_child(name_label)

	var materials_label := Label.new()
	materials_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(materials_label)

	var craft_button := Button.new()
	craft_button.pressed.connect(_on_craft_pressed.bind(recipe))
	row.add_child(craft_button)

	_rows.append({
		"recipe": recipe,
		"materials_label": materials_label,
		"craft_button": craft_button,
	})
	return row

## Her satır kendi malzeme sahip/gerek sayısını gösterir - kilitli bir
## tarif *sebebiyle birlikte* gösterilir, gizlenmez (bkz. kilitli olay
## seçimi/ekipman/vagon satışı kuralı).
func _refresh_rows() -> void:
	for row in _rows:
		var recipe: CraftingRecipe = row.recipe
		var craftable := _session.can_craft(recipe)

		var materials_label: Label = row.materials_label
		var parts: Array[String] = []
		for item_id in recipe.inputs:
			var item := ItemCatalog.get_item(String(item_id))
			if item == null:
				continue
			var need := int(recipe.inputs[item_id])
			var have := _session.get_total_quantity(String(item_id))
			parts.append(tr("UI_CRAFT_MATERIAL") % [item.item_name, have, need])
		materials_label.text = ", ".join(parts)
		materials_label.modulate = OK_COLOR if craftable else MISSING_COLOR

		var craft_button: Button = row.craft_button
		var reason := _session.get_craft_block_reason(recipe)
		if reason.is_empty():
			craft_button.text = tr("UI_CRAFT_BUTTON") % recipe.recipe_name
			craft_button.disabled = false
		else:
			craft_button.text = tr(reason)
			craft_button.disabled = true

func _on_craft_pressed(recipe: CraftingRecipe) -> void:
	if _session.craft(recipe.recipe_id):
		_message_label.text = tr("UI_CRAFT_SUCCESS") % recipe.recipe_name
		_message_label.modulate = OK_COLOR
	else:
		_message_label.text = tr("UI_CRAFT_FAILED")
		_message_label.modulate = MISSING_COLOR
	_refresh_rows()

func _on_close_pressed() -> void:
	queue_free()
