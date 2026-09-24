class_name CaravanCargoPanel
extends CanvasLayer

## "Kervan Yükü" - Kervan Envanteri Rules'un #22 tasarım notunun hâlâ eksik
## kalan ikinci parçası (birincisi, yabancı vagona bakış, MerchantDialoguePanel
## olarak zaten şehirleşti - bkz. o notun kendi metni). Kargoyu her vagona
## tek tek yürüyüp keşfetmek yerine, kervandayken vagon vagon **bilerek**
## dağıtmak için tek ekran: her vagon kendi sütununda, her satır o vagonun
## taşıdığı bir mal - yanındaki bir `SpinBox` taşınacak miktarı seçer
## (varsayılanı elindeki tam yığın - tek tıkla "hepsini taşı" hâlâ eski
## davranışla birebir aynı), oklar (bkz. `UiIcon.CHEVRON_LEFT/RIGHT`,
## `party.gd`'nin sıralama tuşlarıyla aynı desen) o miktarı komşu vagona
## taşır. `GameSession.move_cargo_between_wagons`'ın "hepsi ya da hiçbiri"
## kuralı bozulmuyor, yalnızca büyüklüğü artık oyuncu seçiyor: istenen
## miktar ya tamamen taşınır ya da hiçbir şey değişmez - `add_to_cargo`'nun
## aynı gerekçesi, seçilen miktarın kendisi de bölünmüyor.
##
## Craft'ın "malzeme yanlış vagondaysa orada craftlanamaz" kısıtı hâlâ
## geçerli (bkz. WagonPanel) - bu ekran o kısıtı ortadan kaldırmıyor,
## oyuncunun onu **görerek** yönetmesini sağlıyor: bir malı doğru vagona
## taşımak artık yolda tesadüfen keşfedilen bir şey değil, şehirde
## planlanabilen bir karar.
##
## `WagonPanel`/`CaravanOverviewPanel`'in sahnesiz `CanvasLayer` deseni.

signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const PANEL_WIDTH: float = 720.0
const COLUMN_WIDTH: float = 180.0
const COLUMN_LIST_HEIGHT: float = 220.0
const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const BLOCK_COLOR: Color = Color(0.85, 0.45, 0.4)
const MOVE_BUTTON_SIZE: float = 20.0

const ITEM_ICON_SIZE: float = 24.0

var _session: GameSession
var _column_row: HBoxContainer

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
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_CARGO_PANEL_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = tr("UI_CARGO_PANEL_HINT")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.modulate = HINT_COLOR
	vbox.add_child(hint)

	vbox.add_child(HSeparator.new())

	var wagon_scroll := ScrollContainer.new()
	wagon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(wagon_scroll)

	_column_row = HBoxContainer.new()
	_column_row.add_theme_constant_override("separation", 12)
	wagon_scroll.add_child(_column_row)

	vbox.add_child(HSeparator.new())

	var close_button := Button.new()
	close_button.text = tr("UI_CRAFT_CLOSE")
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)

	_refresh()

func _refresh() -> void:
	for child in _column_row.get_children():
		_column_row.remove_child(child)
		child.queue_free()

	for index in _session.wagon_inventories.size():
		_column_row.add_child(_build_wagon_column(index))

func _build_wagon_column(wagon_index: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(COLUMN_WIDTH, 0.0)
	column.add_theme_constant_override("separation", 4)

	var wagon_inventory := _session.wagon_inventories[wagon_index]
	var header := Label.new()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.text = tr("UI_HUB_WAGON") % (wagon_index + 1)
	header.modulate = ArtPalette.GOLD
	column.add_child(header)

	var weight_label := Label.new()
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 11)
	weight_label.modulate = HINT_COLOR
	weight_label.text = tr("UI_CARAVAN_OVERVIEW_WAGON_WEIGHT") % [
		int(wagon_inventory.get_total_weight()), int(GameSession.CARGO_PER_WAGON),
	]
	column.add_child(weight_label)

	column.add_child(HSeparator.new())

	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.custom_minimum_size = Vector2(0.0, COLUMN_LIST_HEIGHT)
	column.add_child(list_scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	list_scroll.add_child(list)

	var entries := wagon_inventory.get_all_entries()
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("UI_WAGON_PANEL_EMPTY")
		empty_label.modulate = HINT_COLOR
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		list.add_child(empty_label)
	else:
		for entry in entries:
			list.add_child(_build_item_row(wagon_index, entry))

	return column

func _build_item_row(wagon_index: int, entry: Dictionary) -> VBoxContainer:
	var item: Item = entry.item
	var available := int(entry.quantity)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)

	row.add_child(WaybookTheme.item_line(
		item.item_id, tr("UI_STATUS_CARGO_ITEM") % [item.item_name, available], ITEM_ICON_SIZE
	))

	# Varsayılan değer elindeki tam yığın - tek tıkla "hepsini taşı" hâlâ
	# eski davranışla birebir aynı, yalnızca oyuncu isterse düşürebiliyor.
	var quantity_box := SpinBox.new()
	quantity_box.min_value = 1
	quantity_box.max_value = available
	quantity_box.value = available
	quantity_box.step = 1
	quantity_box.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(quantity_box)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	row.add_child(buttons)

	if wagon_index > 0:
		buttons.add_child(_build_move_control(
			item.item_id, wagon_index, wagon_index - 1, UiIcon.Kind.CHEVRON_LEFT, quantity_box
		))
	if wagon_index < _session.wagon_inventories.size() - 1:
		buttons.add_child(_build_move_control(
			item.item_id, wagon_index, wagon_index + 1, UiIcon.Kind.CHEVRON_RIGHT, quantity_box
		))

	return row

## Ok tuşu bir karakter değil çizim (bkz. `party.gd`'nin aynı yorumu,
## Art Rules'un font-kapsamı maddesi) - engelliyse *görünür* bir sebep
## satırı ekleniyor, yalnızca hover'da değil (kilitli seçenek kuralı).
## Engel durumu artık `quantity_box`'ın seçtiği miktara göre değişebilir -
## tam yığın sığmasa bile daha küçük bir miktar sığabilir - o yüzden
## `value_changed`'e bağlı bir kapanış (`update`) düğmeyi/sebep satırını
## her değişiklikte yeniden değerlendiriyor. Lambda'nın kendi yakaladığı
## `button`/`reason_label` birer Node referansı, CLAUDE.md'nin `:=`/Variant
## uyarısının komşusu olan "lambda dış değişkeni değerle yakalar" tuzağı
## burada geçerli değil - referans tipleri paylaşılan aynı düğümü gösterir.
func _build_move_control(
	item_id: String, from_index: int, to_index: int, icon_kind: int, quantity_box: SpinBox
) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)

	var reason_label := Label.new()
	reason_label.add_theme_font_size_override("font_size", 10)
	reason_label.modulate = BLOCK_COLOR
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	reason_label.visible = false
	wrapper.add_child(reason_label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(MOVE_BUTTON_SIZE, 0.0)
	var icon := UiIcon.new()
	icon.setup(icon_kind, ArtPalette.GOLD)
	button.add_child(icon)
	icon.fill_parent()
	button.pressed.connect(_on_move_pressed.bind(item_id, from_index, to_index, quantity_box))
	wrapper.add_child(button)

	var update := func() -> void:
		var reason := _session.get_cargo_move_block_reason(from_index, item_id, to_index, int(quantity_box.value))
		button.disabled = not reason.is_empty()
		button.tooltip_text = tr("UI_CARGO_MOVE_TOOLTIP") if reason.is_empty() else ""
		reason_label.visible = not reason.is_empty()
		reason_label.text = tr(reason) if not reason.is_empty() else ""
	quantity_box.value_changed.connect(func(_value: float) -> void: update.call())
	update.call()

	return wrapper

func _on_move_pressed(item_id: String, from_index: int, to_index: int, quantity_box: SpinBox) -> void:
	_session.move_cargo_between_wagons(from_index, item_id, to_index, int(quantity_box.value))
	_refresh()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
