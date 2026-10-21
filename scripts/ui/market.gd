extends Control

## Şehir pazarı (görev Y-G11T masa şablonu, kullanıcı kararı 2026-10-19: "pazar
## Y-G11T'deki gibi, terazi referans görseldeki gibi"). Üç sütun:
## - solda tezgâh: mal, alış, satış ve birim ağırlık; satıra tıklamak malı
##   kefeye koyar (bir daha tıklamak bir tane daha ekler);
## - ortada terazi ve altında kâğıt: kefedeki mal, ağırlığı, ödenecek altın,
##   neden (bilinen en iyi satış yeri), engel varsa kırmızı satır; Al,
##   Pazarlık, Vazgeç;
## - sağda kervan: her vagon kendi yuvası ve ağırlığıyla; bir mala tıklamak
##   onu satılacak olarak kefeye koyar (Sat, Vazgeç).
## Kalıcı oturumun cüzdanı ve envanteri üzerinde çalışır. Fiyatlar bulunduğun
## şehre göre değişir (bkz. MarketPricing); alım vagonların hem yuva hem ağırlık
## sınırına (bkz. Inventory.add_item) ve şehrin stoğuna bağlıdır. Kefe birden
## çok mal taşıyabilir (Faz 17 PR-5'in sepeti): tek anlaşma, anında ya da
## pazarlıkla. Pazarlık koparsa alım bedelsiz iptal olur, itibar biraz düşer.

const MAX_BUY_QUANTITY: int = 99
const MARKET_HAGGLE_GREED: float = 0.4
const MARKET_HAGGLE_REPUTATION: float = 0.3
const SIDE_WIDTH: float = 470.0
const ROW_HEIGHT: float = 54.0
const ROW_ICON: float = 34.0
const CELL_SIZE: Vector2 = Vector2(68, 64)
const CELL_ICON: float = 34.0
const CELL_COLUMNS: int = 5
## Az stok sınırı: altında "az" yazılır.
const LOW_STOCK: int = 5
const PROFITEER_MARK_FILE: String = "b2b_thumb.png"
const MESSAGE_COLOR: Color = Color(0.78, 0.22, 0.16)
const BLUR_SHADER: String = """
shader_type canvas_item;
uniform float radius = 5.0;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * radius;
	vec4 sum = vec4(0.0);
	float weight = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			float k = exp(-float(x * x + y * y) / 8.0);
			sum += texture(TEXTURE, UV + vec2(float(x), float(y)) * px) * k;
			weight += k;
		}
	}
	COLOR = sum / weight;
}
"""

const MODE_NONE: String = ""
const MODE_BUY: String = "buy"
const MODE_SELL: String = "sell"

var _session: GameSession
var _current_location: Location
var _shop_items: Array[Item] = []
var _shop_rows: Array[Dictionary] = []

## Kefedeki alım: {"item": Item, "quantity": int}. Faz 17 PR-5'in sepeti.
var _basket: Array[Dictionary] = []
var _active_id: String = ""
var _mode: String = MODE_NONE
var _sell_item: Item
var _sell_quantity: int = 0
var _haggling_active: bool = false
## Kâğıdın altında gösterilen son engel: engel kalkınca satır da kalkar.
var _shown_block: String = ""

var _scale: MarketScale
var _purse_label: Label
var _cargo_label: Label
var _city_gold_label: Label
var _stall_foot: Label
var _wagon_column: VBoxContainer
var _slip: PanelContainer
var _line_box: VBoxContainer
var _reason_label: Label
var _message_label: Label
var _primary_button: Button
var _haggle_button: Button
var _cancel_button: Button
var _button_row: HBoxContainer
var _haggle_holder: VBoxContainer
var _back_button: Button

func _ready() -> void:
	_session = GameState.get_session()
	_current_location = WorldMapData.get_location_by_id(_session.current_location_id)
	# Kasaba ve kervansarayda her mal bulunmaz (bkz. Location.available);
	# bulunmayan mal ne alınır ne satılır.
	for item in ItemCatalog.get_trade_goods():
		if _current_location == null or _current_location.sells(item.item_id):
			_shop_items.append(item)
	# Nadir mal tezgâhta yok; kervanda varsa satırı açılır (Y-C19).
	var relic := ItemCatalog.get_item(ItemCatalog.RARE_RELIC)
	if relic != null and _session.get_total_quantity(relic.item_id) > 0:
		_shop_items.append(relic)
	_build_background()
	_build_layout()
	_session.wallet.balance_changed.connect(func(_b: int) -> void: _refresh_header())
	_refresh_all()

# --- kurulum ---

## Arka plan bulunulan şehrin kendi resmi, bulanık ve karanlık: pazar o
## sokakta kurulu (referans görseldeki gibi).
func _build_background() -> void:
	var art: TextureRect = $BackgroundArt
	var path := "res://data/assets/ui/towns/%s/background.jpg" % _session.current_location_id
	var tex := TextureLoader.load_any(path)
	if tex == null:
		tex = WaybookTheme.texture("b2_market.jpg")
	art.texture = tex
	var shader := Shader.new()
	shader.code = BLUR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	art.material = material

func _build_layout() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	column.add_child(_build_header())
	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 22)
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(main)
	main.add_child(_build_stall())
	main.add_child(_build_centre())
	main.add_child(_build_caravan())

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	column.add_child(bottom)
	var hint := Label.new()
	hint.text = tr("UI_MARKET_PICK_HINT")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	bottom.add_child(hint)
	_back_button = Button.new()
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	bottom.add_child(_back_button)
	RecruitButton.add_before(_back_button, RecruitCatalog.VENUE_MARKET, Nav.ECONOMY)

func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var title := Label.new()
	title.theme_type_variation = WaybookTheme.PAGE_TITLE
	title.text = tr("UI_MARKET_TITLE") if _current_location == null else tr("UI_MARKET_TITLE_CITY") % _current_location.location_name
	row.add_child(title)
	var note := Label.new()
	note.text = _build_trade_note()
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	note.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(note)
	_purse_label = Label.new()
	row.add_child(_purse_label)
	_cargo_label = Label.new()
	row.add_child(_cargo_label)
	_city_gold_label = Label.new()
	_city_gold_label.tooltip_text = tr("UI_MARKET_CITY_GOLD_TOOLTIP")
	_city_gold_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_city_gold_label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	row.add_child(_city_gold_label)
	# Fiyat defteri (görev Y-C10): bilinen şehir fiyatları, tarihiyle.
	var book := Button.new()
	book.text = tr("UI_PRICE_BOOK_OPEN")
	book.pressed.connect(func(): add_child(PriceBookPanel.new().setup(_session)))
	row.add_child(book)
	return row

func _side_panel(heading: String) -> Array:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	panel.theme_type_variation = WaybookTheme.FRAMED_PANEL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var title := Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", ArtPalette.GRIM_AMBER)
	col.add_child(title)
	col.add_child(WaybookTheme.title_strip())
	return [panel, col]

func _build_stall() -> Control:
	var parts := _side_panel(tr("UI_MARKET_STALL"))
	var col: VBoxContainer = parts[1]
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	for spec in [["UI_MARKET_COL_GOODS", 0.0, true], ["UI_MARKET_COL_BUY", 62.0, false], ["UI_MARKET_COL_SELL", 62.0, false], ["UI_MARKET_COL_WEIGHT", 50.0, false]]:
		var label := Label.new()
		label.text = tr(String(spec[0]))
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
		if bool(spec[2]):
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			label.custom_minimum_size = Vector2(float(spec[1]), 0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.add_child(label)
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	for item in _shop_items:
		list.add_child(_build_shop_row(item))
	_stall_foot = Label.new()
	_stall_foot.autowrap_mode = TextServer.AUTOWRAP_WORD
	_stall_foot.add_theme_font_size_override("font_size", 14)
	_stall_foot.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	col.add_child(_stall_foot)
	return parts[0]

## Bir tezgâh satırı: düğmenin kendisi (seçilince çerçevesi parlar), içinde
## ikon, ad ve not, alış, satış, ağırlık.
func _build_shop_row(item: Item) -> Control:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_row_pressed.bind(item))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var icon := WaybookTheme.item_icon(item.item_id, ROW_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", -4)
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(names)
	var name_label := Label.new()
	name_label.text = item.item_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(name_label)
	var note := Label.new()
	note.add_theme_font_size_override("font_size", 13)
	note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(note)
	var buy := _cell_label(62.0)
	row.add_child(buy)
	var sell := _cell_label(62.0)
	row.add_child(sell)
	var weight := _cell_label(50.0)
	weight.text = _weight_text(item.unit_weight)
	row.add_child(weight)
	# Krizdeki bir şehre tam da krizin malını satmak dünyanın hafızasına
	# yazılıyor (bkz. GameSession.is_profiteering_sale): satmadan önce söylenir.
	var mark := WaybookTheme.picture(PROFITEER_MARK_FILE, 22)
	mark.tooltip_text = tr("UI_MARKET_PROFITEERING_TOOLTIP")
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	_shop_rows.append({"item": item, "button": button, "note": note, "buy": buy, "sell": sell, "mark": mark})
	return button

func _cell_label(width: float) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(width, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _build_centre() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	_scale = MarketScale.new()
	_scale.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(_scale)
	_slip = PanelContainer.new()
	_slip.theme_type_variation = WaybookTheme.SLIP_PANEL
	col.add_child(_slip)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 4)
	_slip.add_child(inside)
	_line_box = VBoxContainer.new()
	_line_box.add_theme_constant_override("separation", 2)
	inside.add_child(_line_box)
	_reason_label = Label.new()
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.add_theme_font_size_override("font_size", 15)
	_reason_label.theme_type_variation = WaybookTheme.PAGE_LABEL
	_reason_label.add_theme_color_override("font_color", WaybookTheme.KIT_PLATE_TEXT)
	inside.add_child(_reason_label)
	_message_label = Label.new()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_color_override("font_color", MESSAGE_COLOR)
	_message_label.add_theme_font_size_override("font_size", 15)
	col.add_child(_message_label)
	_button_row = HBoxContainer.new()
	_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_button_row.add_theme_constant_override("separation", 14)
	col.add_child(_button_row)
	_primary_button = _wide_button("UI_MARKET_BUY", _on_primary_pressed)
	_primary_button.theme_type_variation = WaybookTheme.PRIMARY_BUTTON
	_haggle_button = _wide_button("UI_MARKET_HAGGLE", _on_haggle_pressed)
	_cancel_button = _wide_button("UI_MARKET_CANCEL", _on_cancel_pressed)
	_haggle_holder = VBoxContainer.new()
	_haggle_holder.add_theme_constant_override("separation", 6)
	col.add_child(_haggle_holder)
	return col

func _wide_button(key: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size = Vector2(150, 44)
	button.pressed.connect(handler)
	_button_row.add_child(button)
	return button

func _build_caravan() -> Control:
	var parts := _side_panel(tr("UI_MARKET_CARAVAN"))
	var col: VBoxContainer = parts[1]
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_wagon_column = VBoxContainer.new()
	_wagon_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wagon_column.add_theme_constant_override("separation", 10)
	scroll.add_child(_wagon_column)
	var note := Label.new()
	note.text = tr("UI_MARKET_CARGO_NOTE")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	col.add_child(note)
	return parts[0]

# --- tazeleme ---

func _refresh_all() -> void:
	_refresh_header()
	_refresh_shop_rows()
	_refresh_wagons()
	_refresh_selection()

func _refresh_header() -> void:
	_purse_label.text = tr("UI_MARKET_PURSE") % _session.wallet.balance
	_cargo_label.text = tr("UI_MARKET_CARGO") % [_session.get_cargo_weight(), _session.get_cargo_capacity()]
	_city_gold_label.text = tr("UI_MARKET_CITY_GOLD") % _session.get_city_gold_reserve()
	if _stall_foot != null:
		_stall_foot.text = tr("UI_MARKET_STALL_FOOT") % _session.wallet.balance

func _refresh_shop_rows() -> void:
	for row in _shop_rows:
		var item: Item = row.item
		var remaining := _session.get_market_stock(item.item_id)
		var buy_reason := MarketPricing.buy_block_reason(item, _current_location)
		var sell_reason := MarketPricing.sell_block_reason(item, _current_location)
		(row.buy as Label).text = "—" if not buy_reason.is_empty() else "%d" % _get_buy_price(item)
		(row.sell as Label).text = "—" if not sell_reason.is_empty() else "%d" % _get_sell_price(item)
		var notes: Array[String] = []
		var note_colour := ArtPalette.GRIM_PARCHMENT_DIM
		if buy_reason.is_empty():
			if remaining == 0:
				notes.append(tr("UI_MARKET_STOCK_NONE"))
				note_colour = MESSAGE_COLOR.lightened(0.2)
			elif remaining > 0 and remaining < LOW_STOCK:
				notes.append(tr("UI_MARKET_STOCK_LOW") % remaining)
			elif remaining > 0:
				notes.append(tr("UI_MARKET_STOCK_PLENTY"))
		# Görev Y-C11: fiyatın yedi katmanından sapanlar kısa adlarla; üstüne
		# gelince her biri bir cümleyle açıklanır.
		var layer_text := PriceLayerText.marks(item, _current_location, _session.market, _session.total_days_elapsed)
		for reason in [buy_reason, sell_reason]:
			if not reason.is_empty():
				notes.append(tr(reason))
		if not layer_text[0].is_empty():
			notes.append(layer_text[0])
		var note: Label = row.note
		note.text = " · ".join(notes)
		note.add_theme_color_override("font_color", note_colour)
		var tips: Array[String] = [tr("UI_MARKET_BULK_HINT") % [MarketPricing.BULK_MIN_QUANTITY, int(round(MarketPricing.BULK_DISCOUNT * 100.0))]]
		if not String(layer_text[1]).is_empty():
			tips.append(String(layer_text[1]))
		(row.button as Button).tooltip_text = "\n".join(tips)
		var mark: Control = row.mark
		var profiteering := _session.is_profiteering_sale(item.item_id)
		mark.modulate.a = 1.0 if profiteering else 0.0
		mark.mouse_filter = Control.MOUSE_FILTER_PASS if profiteering else Control.MOUSE_FILTER_IGNORE
		var chosen := (_mode == MODE_BUY and _basket_has(item.item_id)) or (_mode == MODE_SELL and _sell_item == item)
		(row.button as Button).set_pressed_no_signal(chosen)
		(row.button as Button).disabled = _haggling_active

## Kervan sütunu açılır-kapanır bölümler (kullanıcı kararı D1, 2026-10-21):
## her vagon kendi bölümü (başlık, yuva ve ağırlık çubukları, mal hücreleri),
## altında her kişinin kendi çantası. Başlığa tıklamak bölümü açar ya da
## kapatır; kapalı bölüm başlığında yükünün özeti kalır. Hangi bölümün açık
## olduğu ekrandan çıkıp gelince de hatırlanır (oturum boyunca).
static var _collapsed: Dictionary = {}

func _refresh_wagons() -> void:
	NodeUtil.clear_children(_wagon_column)
	for index in _session.wagon_inventories.size():
		var inv: Inventory = _session.wagon_inventories[index]
		var crew_index := index * GameSession.PEOPLE_PER_WAGON
		var driver := _session.crew_names[crew_index] if crew_index < _session.crew_names.size() else ""
		var title := tr("UI_MARKET_WAGON_HEAD") % [index + 1, driver] if not driver.is_empty() else tr("UI_MARKET_WAGON_N") % (index + 1)
		var entries := inv.get_all_entries()
		var summary := tr("UI_MARKET_WEIGHT") % [inv.get_total_weight(), inv.weight_limit]
		var body := _section("wagon_%d" % index, title, summary, false)
		if body == null:
			continue
		var bars := HBoxContainer.new()
		bars.add_theme_constant_override("separation", 12)
		body.add_child(bars)
		bars.add_child(_meter(tr("UI_MARKET_SLOTS") % [entries.size(), inv.max_slots], float(entries.size()) / float(maxi(1, inv.max_slots))))
		var limit := maxf(1.0, inv.weight_limit)
		bars.add_child(_meter(summary, inv.get_total_weight() / limit))
		var grid := _cell_grid(body)
		var shown := mini(inv.max_slots, CELL_COLUMNS * int(ceil(float(entries.size() + 1) / float(CELL_COLUMNS))))
		for i in shown:
			if i < entries.size():
				var entry: Dictionary = entries[i]
				grid.add_child(_cargo_cell(entry.item, int(entry.quantity)))
			else:
				grid.add_child(_cargo_cell(null, 0))
	# Kişilerin çantaları: vagonlara sığmayan küçük kazançlar, kişi kişi.
	for character in _session.get_party():
		var bag: Inventory = character.personal_inventory
		var bag_entries := bag.get_all_entries()
		var summary := tr("UI_MARKET_WEIGHT") % [bag.get_total_weight(), bag.weight_limit]
		var body := _section("bag_" + character.character_id, tr("UI_MARKET_BAG_OF") % character.character_name,
			summary, true)
		if body == null:
			continue
		if bag_entries.is_empty():
			var empty := Label.new()
			empty.text = tr("UI_MARKET_BAG_EMPTY")
			empty.add_theme_font_size_override("font_size", 14)
			empty.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
			body.add_child(empty)
			continue
		var grid := _cell_grid(body)
		for entry in bag_entries:
			grid.add_child(_cargo_cell(entry.item, int(entry.quantity)))

## Bölüm başlığı ve (açıksa) gövdesi. Kapalıysa null döner: gövde kurulmaz.
func _section(key: String, title: String, summary: String, closed_by_default: bool) -> VBoxContainer:
	var closed := bool(_collapsed.get(key, closed_by_default))
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 3)
	_wagon_column.add_child(block)
	var head := Button.new()
	head.flat = true
	head.focus_mode = Control.FOCUS_NONE
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.text = "      %s" % title
	head.tooltip_text = summary
	head.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	head.pressed.connect(func():
		_collapsed[key] = not closed
		_refresh_wagons())
	var arrow := UiIcon.new()
	arrow.setup(UiIcon.Kind.CHEVRON_RIGHT if closed else UiIcon.Kind.CHEVRON_DOWN, ArtPalette.GRIM_AMBER, 10.0)
	arrow.position = Vector2(6, 9)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(arrow)
	var row := HBoxContainer.new()
	row.add_child(head)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if closed:
		var note := Label.new()
		note.text = summary
		note.add_theme_font_size_override("font_size", 13)
		note.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
		note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(note)
	block.add_child(row)
	if closed:
		return null
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	block.add_child(body)
	return body

func _cell_grid(body: VBoxContainer) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = CELL_COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	body.add_child(grid)
	return grid

func _meter(text: String, share: float) -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 1)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	col.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = clampf(share, 0.0, 1.0)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 5)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	var fill := StyleBoxFlat.new()
	fill.bg_color = MESSAGE_COLOR if share >= 0.95 else ArtPalette.GRIM_AMBER
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	col.add_child(bar)
	return col

## Kargo hücresi: malın resmi ve miktarı; tıklamak satılacak olarak kefeye koyar.
func _cargo_cell(item: Item, quantity: int) -> Control:
	var cell := Button.new()
	cell.custom_minimum_size = CELL_SIZE
	cell.focus_mode = Control.FOCUS_NONE
	if item == null:
		cell.disabled = true
		cell.modulate.a = 0.45
		return cell
	cell.tooltip_text = "%s ×%d" % [item.item_name, quantity]
	cell.toggle_mode = true
	cell.set_pressed_no_signal(_mode == MODE_SELL and _sell_item == item)
	cell.disabled = _haggling_active
	cell.pressed.connect(_on_cargo_pressed.bind(item))
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", -2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(col)
	var icon := WaybookTheme.item_icon(item.item_id, CELL_ICON)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)
	var amount := Label.new()
	amount.text = "×%d" % quantity
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override("font_size", 13)
	col.add_child(amount)
	return cell

## Kefe ve kâğıt: ne seçiliyse onu söyler; düğmeler kipine göre.
func _refresh_selection() -> void:
	NodeUtil.clear_children(_line_box)
	_reason_label.text = ""
	if _mode == MODE_BUY:
		for entry in _basket:
			_line_box.add_child(_line_row(entry.item, int(entry.quantity), String(entry.item.item_id) == _active_id))
		var total := _basket_total_price()
		_line_box.add_child(_total_row(tr("UI_MARKET_TOTAL_PAY") % [_basket_weight(), total]))
		var active := _active_item()
		if active != null:
			_reason_label.text = _reason_for(active)
		_primary_button.text = tr("UI_MARKET_BUY")
	elif _mode == MODE_SELL and _sell_item != null:
		_line_box.add_child(_line_row(_sell_item, _sell_quantity, true))
		_line_box.add_child(_total_row(tr("UI_MARKET_TOTAL_GET") % (_get_sell_price(_sell_item) * _sell_quantity)))
		_reason_label.text = _reason_for(_sell_item)
		_primary_button.text = tr("UI_MARKET_SELL")
	else:
		var empty := Label.new()
		empty.text = tr("UI_MARKET_SLIP_EMPTY")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_line_box.add_child(empty)
	var has := _mode != MODE_NONE
	_button_row.visible = not _haggling_active
	_primary_button.disabled = not has or not _primary_block().is_empty()
	_haggle_button.visible = _mode != MODE_SELL
	_haggle_button.disabled = _mode != MODE_BUY or not _primary_block().is_empty()
	_cancel_button.disabled = not has
	var block := _primary_block()
	if has and not block.is_empty():
		_show_message(block)
		_shown_block = block
	elif not _shown_block.is_empty() and _message_label.text == _shown_block:
		_clear_message()
		_shown_block = ""
	_refresh_scale()

func _line_row(item: Item, quantity: int, active: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var text := Label.new()
	# Fiş parşömen (UI kiti v2): yazı mürekkep, seçili satır kan.
	text.theme_type_variation = WaybookTheme.PAGE_LABEL
	text.add_theme_color_override("font_color", ArtPalette.BLOOD if active else WaybookTheme.KIT_PLATE_TEXT)
	text.text = tr("UI_MARKET_LINE") % [item.item_name, quantity, item.unit_weight * float(quantity)]
	row.add_child(text)
	if active:
		var minus := Button.new()
		minus.text = "−"
		minus.custom_minimum_size = Vector2(34, 30)
		minus.pressed.connect(_change_quantity.bind(-1))
		row.add_child(minus)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(34, 30)
		plus.pressed.connect(_change_quantity.bind(1))
		row.add_child(plus)
	return row

func _total_row(text: String) -> Control:
	var label := Label.new()
	label.theme_type_variation = WaybookTheme.PAGE_LABEL
	label.add_theme_color_override("font_color", ArtPalette.BLOOD)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

## Kefenin neden ağır ya da hafif olduğu: bu malı bildiğimiz en iyi fiyata
## alan şehir ve buradaki fiyat, sapan fiyat katmanları.
func _reason_for(item: Item) -> String:
	var parts: Array[String] = []
	var best := _best_known_sale(item)
	if not String(best.city).is_empty() and String(best.city) != _session.current_location_id:
		var city := WorldMapData.get_location_by_id(String(best.city))
		parts.append(tr("UI_MARKET_BEST_ELSEWHERE") % [city.location_name if city != null else String(best.city), int(best.price), _get_sell_price(item)])
	var layer_text := PriceLayerText.marks(item, _current_location, _session.market, _session.total_days_elapsed)
	if not String(layer_text[0]).is_empty():
		parts.append(String(layer_text[0]))
	return " · ".join(parts)

## Bu mal için bilinen en iyi satış fiyatı ve yeri: burası ve fiyat defteri.
func _best_known_sale(item: Item) -> Dictionary:
	var best := {"city": _session.current_location_id, "price": _get_sell_price(item)}
	for city in _session.price_book:
		var sell: Dictionary = (_session.price_book[city] as Dictionary).get("sell", {})
		var price := int(sell.get(item.item_id, 0))
		if price > int(best.price):
			best = {"city": String(city), "price": price}
	return best

func _best_known_sell_price(item: Item) -> int:
	return int(_best_known_sale(item).price)

## Terazinin iki kefesi: soldaki mal, sağdaki altın. Kolun eğimi malın bilinen
## en iyi satış değeriyle kefedeki altının farkından (kâr işareti).
func _refresh_scale() -> void:
	var entries: Array[Dictionary] = []
	var value := 0
	var gold := 0
	if _mode == MODE_BUY:
		for entry in _basket:
			entries.append({"texture": _item_texture(entry.item), "quantity": int(entry.quantity)})
			value += _best_known_sell_price(entry.item) * int(entry.quantity)
		gold = _basket_total_price()
	elif _mode == MODE_SELL and _sell_item != null:
		entries.append({"texture": _item_texture(_sell_item), "quantity": _sell_quantity})
		value = _best_known_sell_price(_sell_item) * _sell_quantity
		gold = _get_sell_price(_sell_item) * _sell_quantity
	_scale.set_basket(entries, gold, value)

func _item_texture(item: Item) -> Texture2D:
	var file := "item_%s.png" % item.item_id.trim_prefix("test_")
	return WaybookTheme.texture(file) if ResourceLoader.exists(WaybookTheme.ART_DIR + file) else null

# --- seçim ---

func _on_row_pressed(item: Item) -> void:
	_clear_message()
	var can_buy := MarketPricing.buy_block_reason(item, _current_location).is_empty() and _session.get_market_stock(item.item_id) != 0
	if not can_buy and _session.get_total_quantity(item.item_id) > 0:
		_select_sell(item)
	elif can_buy:
		_select_buy(item)
	else:
		_show_message(_row_block_text(item))
		_refresh_shop_rows()

func _row_block_text(item: Item) -> String:
	var reason := MarketPricing.buy_block_reason(item, _current_location)
	return tr(reason) if not reason.is_empty() else tr("UI_NOT_ENOUGH_STOCK") % item.item_name

func _on_cargo_pressed(item: Item) -> void:
	_clear_message()
	_select_sell(item)

func _select_buy(item: Item) -> void:
	if _mode != MODE_BUY:
		_reset_selection()
		_mode = MODE_BUY
	if _basket_has(item.item_id):
		if _active_id == item.item_id:
			_active_id = item.item_id
			_change_quantity(1)
			return
		_active_id = item.item_id
	else:
		_basket.append({"item": item, "quantity": 1})
		_active_id = item.item_id
	_refresh_shop_rows()
	_refresh_selection()

func _select_sell(item: Item) -> void:
	if _mode == MODE_SELL and _sell_item == item:
		_change_quantity(1)
		return
	_reset_selection()
	_mode = MODE_SELL
	_sell_item = item
	_sell_quantity = 1
	_refresh_shop_rows()
	_refresh_wagons()
	_refresh_selection()

func _change_quantity(delta: int) -> void:
	if _mode == MODE_SELL and _sell_item != null:
		_sell_quantity = clampi(_sell_quantity + delta, 1, maxi(1, _session.get_total_quantity(_sell_item.item_id)))
	elif _mode == MODE_BUY:
		for i in _basket.size():
			if String(_basket[i].item.item_id) != _active_id:
				continue
			var item: Item = _basket[i].item
			var wanted := int(_basket[i].quantity) + delta
			if wanted <= 0:
				_basket.remove_at(i)
				_active_id = String(_basket[_basket.size() - 1].item.item_id) if not _basket.is_empty() else ""
				if _basket.is_empty():
					_mode = MODE_NONE
				break
			var stock := _session.get_market_stock(item.item_id)
			if stock >= 0:
				wanted = mini(wanted, stock)
			_basket[i].quantity = clampi(wanted, 1, MAX_BUY_QUANTITY)
			break
	_clear_message()
	_refresh_shop_rows()
	_refresh_selection()

func _reset_selection() -> void:
	_basket.clear()
	_active_id = ""
	_sell_item = null
	_sell_quantity = 0
	_mode = MODE_NONE

func _on_cancel_pressed() -> void:
	_reset_selection()
	_clear_message()
	_refresh_all()

func _basket_has(item_id: String) -> bool:
	for entry in _basket:
		if String(entry.item.item_id) == item_id:
			return true
	return false

func _active_item() -> Item:
	for entry in _basket:
		if String(entry.item.item_id) == _active_id:
			return entry.item
	return null

## Kefedeki alımın bedeli: kalem başına toptan indirimle (bkz. MarketPricing.bulk_total).
func _basket_total_price() -> int:
	var total := 0
	for entry in _basket:
		total += MarketPricing.bulk_total(_get_buy_price(entry.item), int(entry.quantity))
	return total

func _basket_weight() -> float:
	var total := 0.0
	for entry in _basket:
		var item: Item = entry.item
		if item.item_id != GameSession.PROVISIONS_ITEM_ID:
			total += item.unit_weight * float(entry.quantity)
	return total

## Kefedeki işin önündeki engel (boşsa yapılabilir): stok, yer, kese, hazine.
## Kilitli düğme sebebiyle gösterilir, gizlenmez.
func _primary_block() -> String:
	if _mode == MODE_BUY:
		for entry in _basket:
			if not _has_enough_stock(entry.item, int(entry.quantity)):
				return tr("UI_MARKET_BASKET_STOCK_SHORT")
		if _basket_weight() > _session.get_cargo_space_remaining() + 0.001:
			return tr("UI_MARKET_NO_ROOM_WEIGHT") % [_basket_weight(), _session.get_cargo_space_remaining()]
		if not _session.wallet.can_afford(_basket_total_price()):
			return tr("UI_MARKET_NEED_GOLD") % _basket_total_price()
	elif _mode == MODE_SELL and _sell_item != null:
		var reason := MarketPricing.sell_block_reason(_sell_item, _current_location)
		if not reason.is_empty():
			return tr(reason)
		var total := _get_sell_price(_sell_item) * _sell_quantity
		if not _session.can_city_afford_sale(total):
			var reserve := _session.get_city_gold_reserve()
			var unit := maxi(1, _get_sell_price(_sell_item))
			return tr("UI_MARKET_CITY_CANNOT_AFFORD") % [reserve, int(floor(float(reserve) / float(unit)))]
	return ""

# --- işlem ---

func _on_primary_pressed() -> void:
	if _haggling_active or not _primary_block().is_empty():
		return
	if _mode == MODE_BUY:
		_buy_basket()
	elif _mode == MODE_SELL:
		_sell_selected()

## Kefeyi etiket fiyatından, pazarlıksız satın alır.
func _buy_basket() -> void:
	var paid := 0
	for entry in _basket:
		var item: Item = entry.item
		var quantity: int = entry.quantity
		var subtotal := MarketPricing.bulk_total(_get_buy_price(item), quantity)
		# Ağırlık önceden sınandı; yuva sınırı yalnızca eklerken bilinir.
		if not _session.add_to_cargo(item, quantity):
			_show_message(tr("UI_MARKET_NO_ROOM"))
			break
		_session.consume_stock(item.item_id, quantity, subtotal)
		_session.wallet.spend(subtotal)
		paid += subtotal
	_reset_selection()
	if paid > 0:
		AudioManager.play_sfx(AudioManager.SFX_UI_COIN)
	if paid > 0 and _message_label.text.is_empty():
		_show_message_soft(tr("UI_MARKET_BASKET_BOUGHT") % paid)
	_refresh_all()

func _sell_selected() -> void:
	var item := _sell_item
	var quantity := _sell_quantity
	if _session.get_total_quantity(item.item_id) < quantity:
		_show_message(tr("UI_MARKET_NOT_ENOUGH_ITEM") % item.item_name)
		return
	var total_price := _get_sell_price(item) * quantity
	_session.remove_from_cargo_or_bags(item.item_id, quantity)
	_session.wallet.earn(total_price)
	AudioManager.play_sfx(AudioManager.SFX_UI_COIN)
	# Aynı malı aynı şehre boca etmek fiyatını düşürür (bkz. MarketConditions)
	# ve şehrin hazinesinden o kadarını çeker.
	_session.record_sale(item.item_id, quantity, total_price)
	_reset_selection()
	_show_message_soft(tr("UI_MARKET_SOLD") % [quantity, item.item_name, total_price])
	_refresh_all()

## Kefeyi tek bir toplam anlaşma olarak pazarlığa açar: kazanılan fiyat
## kalemlere etiket payı oranında dağıtılır.
func _on_haggle_pressed() -> void:
	if _mode != MODE_BUY or _basket.is_empty() or _haggling_active or not _primary_block().is_empty():
		return
	_haggling_active = true
	NodeUtil.clear_children(_haggle_holder)
	var base_price := _basket_total_price()
	var count := 0
	for entry in _basket:
		count += int(entry.quantity)
	var intro := Label.new()
	intro.text = tr("UI_MARKET_BASKET_HAGGLE_INTRO") % [_basket.size(), count, base_price]
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD
	_haggle_holder.add_child(intro)
	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	# Kervanın en iyi zekâsı ve karizması tüccarın tabanını aşağı çeker (bkz.
	# HagglingSession.get_floor): dilini iyi kullanan biri burada para kazandırır.
	panel.start_haggling(
		float(base_price),
		MARKET_HAGGLE_GREED,
		MARKET_HAGGLE_REPUTATION,
		_session.get_best_effective_stat(CharacterStats.Kind.INTELLECT),
		_session.get_best_effective_stat(CharacterStats.Kind.CHARISMA),
		false
	)
	_refresh_all()

func _on_haggle_deal(price: int) -> void:
	if not _session.wallet.can_afford(price):
		_show_message(tr("UI_MARKET_CANNOT_PAY"))
		_close_haggling()
		return
	if _basket_weight() > _session.get_cargo_space_remaining() + 0.001:
		_show_message(tr("UI_MARKET_NO_ROOM_CANCELLED"))
		_close_haggling()
		return
	var sticker_total := maxi(1, _basket_total_price())
	for entry in _basket:
		var item: Item = entry.item
		var quantity: int = entry.quantity
		var share := int(round(float(price) * float(MarketPricing.bulk_total(_get_buy_price(item), quantity)) / float(sticker_total)))
		if not _session.add_to_cargo(item, quantity):
			_show_message(tr("UI_MARKET_NO_ROOM"))
			break
		_session.consume_stock(item.item_id, quantity, share)
	_session.wallet.spend(price)
	_reset_selection()
	_show_message_soft(tr("UI_MARKET_HAGGLE_WON") % price)
	_close_haggling()

## Masadan kalkmak bedava değil: alım iptal olur *ve* itibar yersin. Bu ceza
## olmadan "kopana kadar dip teklif ver, koparsa yeniden başla" bedava bir
## deneme döngüsü olurdu (bkz. HagglingSession başlığı).
func _on_haggle_failed(reputation_penalty: int) -> void:
	if reputation_penalty > 0:
		_session.change_reputation(-reputation_penalty)
		_show_message(tr("UI_MARKET_HAGGLE_LOST_REPUTATION") % reputation_penalty)
	else:
		_show_message(tr("UI_MARKET_HAGGLE_LOST"))
	_close_haggling()

func _close_haggling() -> void:
	NodeUtil.clear_children(_haggle_holder)
	_haggling_active = false
	_refresh_all()

# --- fiyatlar ---

func _has_enough_stock(item: Item, quantity: int) -> bool:
	var remaining := _session.get_market_stock(item.item_id)
	return remaining < 0 or remaining >= quantity

## Kültür perkleri alış fiyatına burada giriyor: vadi loncaları her malı,
## balıkçı kasabası yalnızca erzağı ucuza alır. Satış fiyatı etkilenmez -
## perk pazarlık gücü, tüccarlık değil.
func _get_buy_price(item: Item) -> int:
	var price := float(MarketPricing.get_buy_price(
		item, _current_location, _session.market, _session.total_days_elapsed
	))
	price *= _session.get_buy_price_multiplier()
	if item.item_id == GameSession.PROVISIONS_ITEM_ID:
		price *= _session.get_provision_cost_multiplier()
	# Tellal pazarlığı ucuzlatır - tıpkı kültür perki gibi bir çarpan daha.
	price *= 1.0 - _session.get_duty_discount(DutyCatalog.TELLAL)
	return maxi(1, int(round(price)))

func _get_sell_price(item: Item) -> int:
	return _session.capped_sell_price(item.item_id, MarketPricing.get_sell_price(
		item, _current_location, _session.market, _session.total_days_elapsed
	))

func _weight_text(weight: float) -> String:
	return ("%.1f" % weight).trim_suffix(".0")

func _build_trade_note() -> String:
	if _current_location == null:
		return ""
	var parts: Array[String] = []
	var produced := _item_names(_current_location.produces)
	var demanded := _item_names(_current_location.demands)
	if not produced.is_empty():
		parts.append(tr("UI_MARKET_CHEAP_HERE") % ", ".join(produced))
	if not demanded.is_empty():
		parts.append(tr("UI_MARKET_WANTED_HERE") % ", ".join(demanded))
	return " · ".join(parts)

func _item_names(item_ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for item_id in item_ids:
		var item := ItemCatalog.get_item(item_id)
		if item != null:
			names.append(item.item_name)
	return names

func _show_message(text: String) -> void:
	_message_label.add_theme_color_override("font_color", MESSAGE_COLOR)
	_message_label.text = text

## İşin olduğu haberi: uyarı değil, kırmızı da değil.
func _show_message_soft(text: String) -> void:
	_message_label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	_message_label.text = text

func _clear_message() -> void:
	_message_label.text = ""

## Ekran görüntüsü aracı için: kefeye mal koyar (oyuncunun satıra tıklaması gibi).
func put_in_pan(item: Item, quantity: int) -> void:
	_select_buy(item)
	for k in quantity - 1:
		_change_quantity(1)

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
