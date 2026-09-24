class_name WagonPanel
extends CanvasLayer

## Yolda bir vagona yürüyüp tıklayınca açılan panel (bkz. world_hub.gd'nin
## vagon etkileşim noktaları - artık her vagon kendi noktası, bkz.
## GameSession.wagon_inventories). İki şey gösterir: o vagonun kendi
## envanteri ve Rust tarzı basit bir craft menüsü - ikisi de **yalnızca
## bu vagonun** malzemesini okur/yazar (bkz. GameSession.craft_in_wagon),
## kervanın toplamını değil. Şehrin Kervan Avlusu'yla hiçbir ilgisi yok;
## `MealDistributionPanel`in sahnesiz `CanvasLayer` deseni.

signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const PANEL_WIDTH: float = 480.0
const OK_COLOR: Color = Color(0.7, 0.85, 0.7)
const MISSING_COLOR: Color = Color(0.85, 0.45, 0.4)
const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)

const ITEM_ICON_SIZE: float = 26.0

var _session: GameSession
var _wagon_index: int = 0
var _rows: Array[Dictionary] = []
var _message_label: Label
var _inventory_list: VBoxContainer

func setup(session: GameSession, wagon_index: int) -> void:
	_session = session
	_wagon_index = wagon_index
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
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_HUB_WAGON") % (_wagon_index + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var inventory_title := Label.new()
	inventory_title.text = tr("UI_WAGON_PANEL_INVENTORY_TITLE")
	inventory_title.modulate = HINT_COLOR
	vbox.add_child(inventory_title)

	_inventory_list = VBoxContainer.new()
	_inventory_list.add_theme_constant_override("separation", 2)
	vbox.add_child(_inventory_list)

	vbox.add_child(HSeparator.new())

	var craft_title := Label.new()
	craft_title.text = tr("UI_CRAFT_TITLE")
	craft_title.modulate = HINT_COLOR
	vbox.add_child(craft_title)

	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_message_label)

	for recipe in RecipeCatalog.get_recipes():
		vbox.add_child(_build_recipe_row(recipe))

	vbox.add_child(HSeparator.new())

	var close_button := Button.new()
	close_button.text = tr("UI_CRAFT_CLOSE")
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)

	_refresh()

func _build_recipe_row(recipe: CraftingRecipe) -> VBoxContainer:
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

func _refresh() -> void:
	_refresh_inventory()
	_refresh_recipes()

## Yalnızca bu vagonun taşıdıkları - kervanın toplamı değil, bu ekranın
## bütün amacı "bu vagonda ne var" sorusuna cevap vermek.
func _refresh_inventory() -> void:
	for child in _inventory_list.get_children():
		_inventory_list.remove_child(child)
		child.queue_free()

	var entries := _session.wagon_inventories[_wagon_index].get_all_entries()
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("UI_WAGON_PANEL_EMPTY")
		empty_label.modulate = HINT_COLOR
		_inventory_list.add_child(empty_label)
		return

	for entry in entries:
		var item: Item = entry.item
		_inventory_list.add_child(WaybookTheme.item_line(
			item.item_id, tr("UI_STATUS_CARGO_ITEM") % [item.item_name, int(entry.quantity)], ITEM_ICON_SIZE
		))

## Her satır kendi malzeme sahip/gerek sayısını gösterir - kilitli bir
## tarif *sebebiyle birlikte* gösterilir, gizlenmez (bkz. kilitli olay
## seçimi/ekipman/vagon satışı kuralı).
func _refresh_recipes() -> void:
	var wagon_inventory := _session.wagon_inventories[_wagon_index]
	for row in _rows:
		var recipe: CraftingRecipe = row.recipe
		var craftable := _session.can_craft_in_wagon(_wagon_index, recipe)

		var materials_label: Label = row.materials_label
		var parts: Array[String] = []
		for item_id in recipe.inputs:
			var item := ItemCatalog.get_item(String(item_id))
			if item == null:
				continue
			var need := int(recipe.inputs[item_id])
			var have := wagon_inventory.get_quantity(String(item_id))
			parts.append(tr("UI_CRAFT_MATERIAL") % [item.item_name, have, need])
		materials_label.text = ", ".join(parts)
		materials_label.modulate = OK_COLOR if craftable else MISSING_COLOR

		var craft_button: Button = row.craft_button
		var reason := _session.get_craft_block_reason_in_wagon(_wagon_index, recipe)
		if reason.is_empty():
			craft_button.text = tr("UI_CRAFT_BUTTON") % recipe.recipe_name
			craft_button.disabled = false
		else:
			craft_button.text = tr(reason)
			craft_button.disabled = true

func _on_craft_pressed(recipe: CraftingRecipe) -> void:
	if _session.craft_in_wagon(_wagon_index, recipe.recipe_id):
		_message_label.text = tr("UI_CRAFT_SUCCESS") % recipe.recipe_name
		_message_label.modulate = OK_COLOR
	else:
		_message_label.text = tr("UI_CRAFT_FAILED")
		_message_label.modulate = MISSING_COLOR
	_refresh()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
