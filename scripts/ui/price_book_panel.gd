class_name PriceBookPanel
extends CanvasLayer

## Fiyat defteri (görev Y-C10): kervanın bildiği şehir fiyatları, tarihiyle.
## Gözle görülen ve söylentiyle duyulan ayrı yazılır; eskiyen bilgi soluk ve
## "eskimiş" işaretli. Yalnızca okur - alım satım pazarda, gerçek fiyattan.

signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.68)
const PANEL_SIZE: Vector2 = Vector2(760.0, 560.0)
const STALE_ALPHA: float = 0.55

var _session: GameSession
var _card: PanelContainer
var _backdrop: ColorRect
var _dismissing: bool = false

func setup(session: GameSession) -> PriceBookPanel:
	_session = session
	return self

func _ready() -> void:
	layer = 55
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP_COLOR
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_close())
	root.add_child(_backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = PANEL_SIZE
	center.add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_card.add_child(col)
	var title := Label.new()
	title.text = tr("UI_PRICE_BOOK_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)
	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.text = tr("UI_PRICE_BOOK_HINT") % GameSession.PRICE_STALE_DAYS
	col.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for line in lines_for(_session):
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = String(line["text"])
		if bool(line.get("heading", false)):
			label.add_theme_font_size_override("font_size", 17)
		if bool(line.get("stale", false)):
			label.modulate.a = STALE_ALPHA
		list.add_child(label)
	var close := Button.new()
	close.text = tr("UI_CLOSE")
	close.pressed.connect(_close)
	col.add_child(close)
	WaybookTheme.present(_card, _backdrop, self)

## Defterin satırları, en tazeden en eskiye: şehir başlığı (yaş ve kaynak),
## sonra alış ve satış satırları. Test bunu okur.
static func lines_for(session: GameSession) -> Array[Dictionary]:
	var ids: Array = session.price_book.keys()
	ids.sort_custom(func(a, b): return session.get_price_age(String(a)) < session.get_price_age(String(b)))
	var out: Array[Dictionary] = []
	if ids.is_empty():
		out.append({"text": TranslationServer.translate("UI_PRICE_BOOK_EMPTY")})
		return out
	for id in ids:
		var location_id := String(id)
		var entry: Dictionary = session.price_book[location_id]
		var location := WorldMapData.get_location_by_id(location_id)
		var stale := session.is_price_stale(location_id)
		var source_key := "UI_PRICE_BOOK_RUMOR" if String(entry.get("source", "")) == GameSession.PRICE_SOURCE_RUMOR else "UI_PRICE_BOOK_SEEN"
		var heading := TranslationServer.translate("UI_PRICE_BOOK_CITY") % [
			location.location_name if location != null else location_id,
			session.get_price_age(location_id), TranslationServer.translate(source_key),
		]
		if stale:
			heading += " " + TranslationServer.translate("UI_PRICE_BOOK_STALE")
		out.append({"text": heading, "heading": true, "stale": stale})
		for side in [["buy", "UI_PRICE_BOOK_BUY"], ["sell", "UI_PRICE_BOOK_SELL"]]:
			var prices: Dictionary = entry.get(side[0], {})
			if prices.is_empty():
				continue
			var parts: Array[String] = []
			for item_id in prices:
				var item := ItemCatalog.get_item(String(item_id))
				parts.append("%s %d" % [item.item_name if item != null else String(item_id), int(prices[item_id])])
			out.append({"text": TranslationServer.translate(String(side[1])) % ", ".join(parts), "stale": stale})
	return out

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	if _dismissing:
		return
	_dismissing = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		closed.emit()
		queue_free()
	)
