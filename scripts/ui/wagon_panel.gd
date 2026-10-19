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
const PANEL_WIDTH: float = 820.0
const LEFT_WIDTH: float = 300.0
const WAGON_PICTURE_HEIGHT: float = 150.0
const BENCH_HEIGHT: float = 380.0
const WAGON_PROP: String = "covered_wagon"
const OK_COLOR: Color = Color(0.7, 0.85, 0.7)
const MISSING_COLOR: Color = Color(0.85, 0.45, 0.4)
const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)

const ITEM_ICON_SIZE: float = 26.0

var _session: GameSession
var _wagon_index: int = 0
var _rows: Array[Dictionary] = []
var _message_label: Label
var _inventory_list: VBoxContainer
var _load_bar: ProgressBar
var _load_label: Label
var _root: Control
var _backdrop: ColorRect
## Devinen "kart" (`panel`) - `backdrop`in kardeşi, `root`'un torunu değil.
var _card: PanelContainer
var _dismissing: bool = false

func setup(session: GameSession, wagon_index: int) -> void:
	_session = session
	_wagon_index = wagon_index
	layer = 65

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_root = root

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	_backdrop = backdrop

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	center.add_child(panel)
	_card = panel

	# Vagonun kendi atölyesi (görev Y-F04T, kullanıcı notu): vagona gitmek
	# atölyeye gitmek. Solda vagonun kendisi (resmi, tayfası, hâli, yükü),
	# sağda tezgâh: her tarif bir kart, girdi -> çıktı resimleriyle.
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_WORKSHOP_TITLE") % (_wagon_index + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	vbox.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(LEFT_WIDTH, 0)
	left.add_theme_constant_override("separation", 6)
	columns.add_child(left)
	var picture := Control.new()
	picture.custom_minimum_size = Vector2(LEFT_WIDTH, WAGON_PICTURE_HEIGHT)
	picture.draw.connect(func():
		if not PropArt.has(WAGON_PROP):
			return
		var size_m := PropArt.size_m(WAGON_PROP)
		var k := (WAGON_PICTURE_HEIGHT * 0.85 / maxf(0.1, size_m.y)) / maxf(0.001, PropArt.ppm(WAGON_PROP))
		PropArt.draw_all(picture, WAGON_PROP, Vector2(LEFT_WIDTH * 0.5, WAGON_PICTURE_HEIGHT - 4.0), k))
	left.add_child(picture)
	var identity := Label.new()
	identity.autowrap_mode = TextServer.AUTOWRAP_WORD
	identity.text = _identity_text()
	identity.modulate = HINT_COLOR
	left.add_child(identity)
	_load_bar = ProgressBar.new()
	_load_bar.show_percentage = false
	_load_bar.custom_minimum_size = Vector2(0, 10)
	left.add_child(_load_bar)
	_load_label = Label.new()
	_load_label.modulate = HINT_COLOR
	left.add_child(_load_label)
	var inventory_title := Label.new()
	inventory_title.text = tr("UI_WAGON_PANEL_INVENTORY_TITLE")
	left.add_child(inventory_title)
	_inventory_list = VBoxContainer.new()
	_inventory_list.add_theme_constant_override("separation", 2)
	left.add_child(_inventory_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	var craft_title := Label.new()
	craft_title.text = tr("UI_WORKSHOP_BENCH")
	right.add_child(craft_title)
	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right.add_child(_message_label)
	var bench_scroll := ScrollContainer.new()
	bench_scroll.custom_minimum_size = Vector2(0, BENCH_HEIGHT)
	bench_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(bench_scroll)
	var bench := VBoxContainer.new()
	bench.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bench.add_theme_constant_override("separation", 6)
	bench_scroll.add_child(bench)
	for recipe in RecipeCatalog.get_recipes():
		bench.add_child(_build_recipe_row(recipe))

	var close_button := Button.new()
	close_button.text = tr("UI_CRAFT_CLOSE")
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)

	_refresh()
	WaybookTheme.present(_card, _backdrop, self)

func _build_recipe_row(recipe: CraftingRecipe) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = WaybookTheme.CELL_PANEL
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	card.add_child(row)

	var name_label := Label.new()
	name_label.text = recipe.recipe_name
	name_label.tooltip_text = recipe.description
	row.add_child(name_label)

	# Girdi -> çıktı, resimleriyle (vagonun kendi malından).
	var flow := HBoxContainer.new()
	flow.add_theme_constant_override("separation", 4)
	for item_id in recipe.inputs:
		flow.add_child(WaybookTheme.item_icon(String(item_id), ITEM_ICON_SIZE))
	var arrow := Label.new()
	arrow.text = "->"
	flow.add_child(arrow)
	if recipe.effect == CraftingRecipe.Effect.ITEM:
		flow.add_child(WaybookTheme.item_icon(recipe.output_item_id, ITEM_ICON_SIZE))
	var result := Label.new()
	result.text = recipe.description
	result.autowrap_mode = TextServer.AUTOWRAP_WORD
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.modulate = HINT_COLOR
	flow.add_child(result)
	row.add_child(flow)

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
	return card

## Vagonun kimliği: kaçıncı vagon, kimin sürdüğü, hâli.
func _identity_text() -> String:
	var names := _session.crew_names
	var first := _wagon_index * GameSession.PEOPLE_PER_WAGON
	var driver := String(names[first]) if first < names.size() else "?"
	var walker := String(names[first + 1]) if first + 1 < names.size() else "?"
	var state_key := "UI_WORKSHOP_DAMAGED" if _wagon_index < _session.owned_wagon_damaged else "UI_WORKSHOP_SOUND"
	return tr("UI_WORKSHOP_IDENTITY") % [driver, walker, tr(state_key)]

func _refresh() -> void:
	_refresh_inventory()
	_refresh_recipes()
	var inventory := _session.wagon_inventories[_wagon_index]
	_load_bar.max_value = maxf(1.0, inventory.weight_limit)
	_load_bar.value = inventory.get_total_weight()
	_load_label.text = tr("UI_WORKSHOP_LOAD") % [inventory.get_total_weight(), inventory.weight_limit]

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
	if _dismissing:
		return
	_dismissing = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		closed.emit()
		queue_free()
	)

## Esc paneli kapatır, altındaki ekranı değil (görev Y-H04): girdi burada
## tüketilir, UiTheme'in "alt ekrandan geri" kuralına ulaşmaz.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
