extends Control

## Şehir pazarı. Kalıcı oturumun cüzdanı ve envanteri üzerinde çalışır:
## burada aldığın erzak, sefere çıkarken kervan planlayıcıda görünür.
## Fiyatlar bulunduğun şehre göre değişir (bkz. MarketPricing), satın
## alma vagon kargo kapasitesiyle (bkz. GameSession.get_cargo_capacity)
## ve şehrin ürettiği malın stoğuyla (bkz. GameSession.market_stock)
## sınırlıdır. Miktar seçilip toptan alınabilir; toptan alım için
## sticker fiyat yerine HagglingPanel üzerinden pazarlık da açılabilir -
## pazarlık koparsa alım bedelsiz iptal olur (zorunlu karşılaşma değil).

const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 4
const SLOT_SIZE: Vector2 = Vector2(80, 80)
## Boş hücre aynı cilt, soluk: yer var ama içinde bir şey yok.
const EMPTY_CELL_ALPHA: float = 0.4
const CELL_ICON_SIZE: float = 36.0
const NAME_COLUMN_WIDTH: float = 150.0
const PRICE_COLUMN_WIDTH: float = 190.0

const MESSAGE_COLOR: Color = Color(0.9, 0.45, 0.35)
const TRADE_NOTE_COLOR: Color = Color(0.75, 0.85, 1.0)

const MAX_BUY_QUANTITY: int = 99
const MARKET_HAGGLE_GREED: float = 0.4
const MARKET_HAGGLE_REPUTATION: float = 0.3

var _session: GameSession
var _shop_items: Array[Item] = []
var _current_location: Location
var _shop_rows: Array[Dictionary] = []

var _pending_purchase_item: Item
var _pending_purchase_quantity: int = 0

## Faz 17 PR-5: sepet, çoklu-mal pazarlığı için. Her giriş {"item": Item,
## "quantity": int} - Pazar Meydanı'nın "toptan alım" fikrini tek maldan
## birden çok mala genişletiyor: tek pazarlıkta birden çok kalem, tek
## anlaşma fiyatı (bkz. Faz 3'ün "miktar seçili toptan alım" notu).
var _basket: Array[Dictionary] = []
var _haggling_active: bool = false

# İçerik kaydırılabilir bir kutunun içinde: mağaza satırları ve envanter
# ızgarası ekranı aşınca geri tuşu ekrandan taşıp tıklanamaz hale
# geliyordu. Başlık ve geri tuşu bilerek kaydırma alanının dışında.
@onready var _scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _location_note_label: Label = _content.get_node("LocationNoteLabel")
@onready var _balance_row: HBoxContainer = _content.get_node("BalanceRow")
@onready var _balance_value_label: Label = _content.get_node("BalanceRow/BalanceValueLabel")
@onready var _cargo_value_label: Label = _content.get_node("BalanceRow/CargoValueLabel")
@onready var _message_label: Label = _content.get_node("MessageLabel")
@onready var _shop_list: VBoxContainer = _content.get_node("ContentRow/ShopPanel/ShopList")
@onready var _inventory_grid: GridContainer = _content.get_node("ContentRow/InventoryPanel/InventoryGrid")
@onready var _haggle_holder: VBoxContainer = _content.get_node("HaggleHolder")
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

var _city_gold_label: Label
var _basket_holder: VBoxContainer
var _basket_list: VBoxContainer
var _basket_total_label: Label
var _basket_buy_button: Button
var _basket_haggle_button: Button
var _basket_clear_button: Button

func _ready() -> void:
	_session = GameState.get_session()
	# Sahne dosyasındaki yazı yalnızca editör içindir; oyuncunun gördüğü her
	# metin koddan, anahtarla gelir (bkz. Localization Rules).
	$MarginContainer/VBoxContainer/TitleLabel.text = tr("UI_MARKET_TITLE")
	_content.get_node("BalanceRow/BalanceLabel").text = tr("UI_MARKET_BALANCE")
	_content.get_node("ContentRow/ShopPanel/ShopTitle").text = tr("UI_MARKET_SHOP")
	_content.get_node("ContentRow/InventoryPanel/InventoryTitle").text = tr("UI_MARKET_INVENTORY")
	_current_location = WorldMapData.get_location_by_id(_session.current_location_id)
	_inventory_grid.columns = GRID_COLUMNS
	_shop_items = ItemCatalog.get_trade_goods()

	_session.wallet.balance_changed.connect(_on_wallet_balance_changed)
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_add_recruit_button(RecruitCatalog.VENUE_MARKET, Nav.ECONOMY)

	_location_note_label.text = _build_trade_note()
	_location_note_label.modulate = TRADE_NOTE_COLOR
	_location_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_build_city_gold_label()
	_build_shop_rows()
	_build_basket_panel()
	_refresh_header()
	_refresh_shop_rows()
	_refresh_inventory_grid()
	_refresh_basket_panel()

## Faz 17 PR-5: şehrin kendi hazinesi artık görünür - tıpkı piyasa şoku
## gibi, gizli bir tavan oyuncuya bir bug gibi hissettirir (bkz. Economy
## Rules'un "hidden penalty is indistinguishable from a bug" ilkesi).
func _build_city_gold_label() -> void:
	_city_gold_label = Label.new()
	_city_gold_label.modulate = TRADE_NOTE_COLOR
	_city_gold_label.tooltip_text = tr("UI_MARKET_CITY_GOLD_TOOLTIP")
	_balance_row.add_child(_city_gold_label)

## Faz 17 PR-5: sepet paneli. Toptan pazarlık artık tek maldan çoklu mala
## genişliyor - satır başına "Sepete Ekle" doldurur, burada tek bir
## anlaşma (anında ya da pazarlıkla) toplu uygulanır. HaggleHolder'ın hemen
## üstüne yerleşir, ikisi de aynı akışın parçası.
func _build_basket_panel() -> void:
	_basket_holder = VBoxContainer.new()
	_basket_holder.add_theme_constant_override("separation", 6)
	_content.add_child(_basket_holder)
	_content.move_child(_basket_holder, _haggle_holder.get_index())

	var title := Label.new()
	title.text = tr("UI_MARKET_BASKET_TITLE")
	_basket_holder.add_child(title)

	_basket_list = VBoxContainer.new()
	_basket_list.add_theme_constant_override("separation", 2)
	_basket_holder.add_child(_basket_list)

	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 8)
	_basket_total_label = Label.new()
	summary_row.add_child(_basket_total_label)

	_basket_buy_button = Button.new()
	_basket_buy_button.text = tr("UI_MARKET_BASKET_BUY")
	_basket_buy_button.pressed.connect(_on_basket_buy_pressed)
	summary_row.add_child(_basket_buy_button)

	_basket_haggle_button = Button.new()
	_basket_haggle_button.text = tr("UI_MARKET_BASKET_HAGGLE")
	_basket_haggle_button.pressed.connect(_on_basket_haggle_pressed)
	summary_row.add_child(_basket_haggle_button)

	_basket_clear_button = Button.new()
	_basket_clear_button.text = tr("UI_MARKET_BASKET_CLEAR")
	_basket_clear_button.pressed.connect(_on_basket_clear_pressed)
	summary_row.add_child(_basket_clear_button)

	_basket_holder.add_child(summary_row)

func _on_basket_add_pressed(item: Item, quantity_spin: SpinBox) -> void:
	if _haggling_active:
		return
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return

	var existing_total := quantity
	for entry in _basket:
		if entry.item.item_id == item.item_id:
			existing_total += entry.quantity

	if not _has_enough_stock(item, existing_total):
		_show_message(tr("UI_NOT_ENOUGH_STOCK") % item.item_name)
		return

	for entry in _basket:
		if entry.item.item_id == item.item_id:
			entry.quantity += quantity
			_clear_message()
			_refresh_basket_panel()
			return

	_basket.append({"item": item, "quantity": quantity})
	_clear_message()
	_refresh_basket_panel()

func _on_basket_remove_pressed(item_id: String) -> void:
	for i in range(_basket.size()):
		if _basket[i].item.item_id == item_id:
			_basket.remove_at(i)
			break
	_refresh_basket_panel()

func _on_basket_clear_pressed() -> void:
	_basket.clear()
	_refresh_basket_panel()

func _basket_total_sticker_price() -> int:
	var total := 0
	for entry in _basket:
		total += _get_buy_price(entry.item) * int(entry.quantity)
	return total

## Sepetteki her kalemin, kervanda zaten taşınandan bağımsız, mağazadaki
## stoğa göre yeterli olup olmadığını doğrular - bkz. add_to_cargo'nun
## "hep ya da hiç" ilkesi, burada mağaza stoğu tarafında uygulanıyor.
func _basket_stock_ok() -> bool:
	for entry in _basket:
		if not _has_enough_stock(entry.item, int(entry.quantity)):
			return false
	return true

func _basket_cargo_ok() -> bool:
	var total_weight := 0.0
	for entry in _basket:
		var item: Item = entry.item
		if item.item_id != GameSession.PROVISIONS_ITEM_ID:
			total_weight += item.unit_weight * float(entry.quantity)
	return total_weight <= _session.get_cargo_space_remaining()

## Sepeti sticker fiyatından, pazarlıksız satın alır - haggle'a girmeden
## hızlı toplu alım.
func _on_basket_buy_pressed() -> void:
	if _basket.is_empty() or _haggling_active:
		return
	if not _basket_stock_ok():
		_show_message(tr("UI_MARKET_BASKET_STOCK_SHORT"))
		return
	if not _basket_cargo_ok():
		_show_message(tr("UI_CARGO_FULL") % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return
	var total := _basket_total_sticker_price()
	if not _session.wallet.can_afford(total):
		_show_message(tr("UI_MARKET_NEED_GOLD") % total)
		return

	for entry in _basket:
		var item: Item = entry.item
		var quantity: int = entry.quantity
		var subtotal := _get_buy_price(item) * quantity
		_session.add_to_cargo(item, quantity)
		_session.consume_stock(item.item_id, quantity, subtotal)
		_session.wallet.spend(subtotal)

	_show_message(tr("UI_MARKET_BASKET_BOUGHT") % total)
	_basket.clear()
	_on_inventory_changed()

## Sepeti tek bir toplam anlaşma olarak pazarlığa açar - HagglingSession
## sepetin tüm sticker toplamını taban fiyat kabul eder, kazanılan tek
## anlaşma fiyatı sepetteki her kaleme sticker payı oranında dağıtılır
## (bkz. _on_basket_haggle_deal).
func _on_basket_haggle_pressed() -> void:
	if _basket.is_empty() or _haggling_active:
		return
	if not _basket_stock_ok():
		_show_message(tr("UI_MARKET_BASKET_STOCK_SHORT"))
		return
	if not _basket_cargo_ok():
		_show_message(tr("UI_CARGO_FULL") % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return

	_set_shop_controls_enabled(false)
	_clear_children(_haggle_holder)

	var base_price := _basket_total_sticker_price()
	var item_count := 0
	for entry in _basket:
		item_count += int(entry.quantity)

	var intro := Label.new()
	intro.text = tr("UI_MARKET_BASKET_HAGGLE_INTRO") % [_basket.size(), item_count, base_price]
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_basket_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	panel.start_haggling(
		float(base_price),
		MARKET_HAGGLE_GREED,
		MARKET_HAGGLE_REPUTATION,
		_session.get_best_effective_stat(CharacterStats.Kind.INTELLECT),
		_session.get_best_effective_stat(CharacterStats.Kind.CHARISMA),
		false
	)

func _on_basket_haggle_deal(price: int) -> void:
	if not _session.wallet.can_afford(price):
		_show_message(tr("UI_MARKET_CANNOT_PAY"))
		_close_haggling()
		return
	if not _basket_cargo_ok():
		_show_message(tr("UI_MARKET_NO_ROOM_CANCELLED"))
		_close_haggling()
		return

	var sticker_total := maxi(1, _basket_total_sticker_price())
	for entry in _basket:
		var item: Item = entry.item
		var quantity: int = entry.quantity
		var sticker_subtotal := _get_buy_price(item) * quantity
		var share := int(round(float(price) * float(sticker_subtotal) / float(sticker_total)))
		_session.add_to_cargo(item, quantity)
		_session.consume_stock(item.item_id, quantity, share)

	_session.wallet.spend(price)
	_show_message(tr("UI_MARKET_HAGGLE_WON") % price)
	_basket.clear()
	_close_haggling()
	_on_inventory_changed()

func _refresh_basket_panel() -> void:
	_with_preserved_scroll(_rebuild_basket_panel)

func _rebuild_basket_panel() -> void:
	_clear_children(_basket_list)

	if _basket.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("UI_MARKET_BASKET_EMPTY")
		empty_label.modulate = TRADE_NOTE_COLOR
		_basket_list.add_child(empty_label)
	else:
		for entry in _basket:
			var item: Item = entry.item
			var quantity: int = entry.quantity
			var subtotal := _get_buy_price(item) * quantity

			var line := HBoxContainer.new()
			line.add_theme_constant_override("separation", 8)
			var line_label := Label.new()
			line_label.text = tr("UI_MARKET_BASKET_LINE") % [item.item_name, quantity, subtotal]
			line_label.custom_minimum_size = Vector2(300, 0)
			line.add_child(line_label)

			var remove_button := Button.new()
			remove_button.text = tr("UI_MARKET_BASKET_REMOVE")
			remove_button.pressed.connect(_on_basket_remove_pressed.bind(item.item_id))
			line.add_child(remove_button)

			_basket_list.add_child(line)

	_basket_total_label.text = tr("UI_MARKET_BASKET_TOTAL") % _basket_total_sticker_price()
	var has_items := not _basket.is_empty()
	_basket_buy_button.disabled = not has_items or _haggling_active
	_basket_haggle_button.disabled = not has_items or _haggling_active
	_basket_clear_button.disabled = not has_items or _haggling_active

func _build_trade_note() -> String:
	if _current_location == null:
		return ""

	var produced_names := _item_names(_current_location.produces)
	var demanded_names := _item_names(_current_location.demands)
	var parts: Array[String] = []
	if not produced_names.is_empty():
		parts.append(tr("UI_MARKET_CHEAP_HERE") % ", ".join(produced_names))
	if not demanded_names.is_empty():
		parts.append(tr("UI_MARKET_WANTED_HERE") % ", ".join(demanded_names))
	return " · ".join(parts)

func _item_names(item_ids: Array[String]) -> Array[String]:
	var names: Array[String] = []
	for item_id in item_ids:
		var item := ItemCatalog.get_item(item_id)
		if item != null:
			names.append(item.item_name)
	return names

const ITEM_ICON_SIZE: float = 32.0
const PROFITEER_MARK_FILE: String = "b2b_thumb.png"

func _build_shop_rows() -> void:
	for item in _shop_items:
		_shop_list.add_child(_build_shop_row(item))

func _build_shop_row(item: Item) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	row.add_child(WaybookTheme.item_icon(item.item_id, ITEM_ICON_SIZE))

	var name_label := Label.new()
	name_label.text = item.item_name
	# Sabit sütun, uzun ad sarılıyor: "Otacı İksiri" gibi bir ad satırın
	# kalanını sağa itiyor, sütunlar satırdan satıra kayıyordu (ölçüldü).
	name_label.custom_minimum_size = Vector2(NAME_COLUMN_WIDTH, 0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var price_label := Label.new()
	price_label.text = tr("UI_MARKET_PRICES") % [_get_buy_price(item), _get_sell_price(item)]
	price_label.custom_minimum_size = Vector2(PRICE_COLUMN_WIDTH, 0)
	price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	# Piyasa şoku gerçekti ama görünürlüğü yoktu: fiyat oynuyordu, hiçbir
	## ekran nedenini söylemiyordu (bkz. MarketConditions.is_shocked).
	## Küçük, ayrı bir etiket - fiyatın kendisine karışmıyor, yalnızca
	## "bu fiyat şu an geçici bir olayın etkisinde" diyor.
	var shock_label := Label.new()
	shock_label.custom_minimum_size = Vector2(90, 0)
	shock_label.modulate = ArtPalette.TORCH
	shock_label.tooltip_text = tr("UI_MARKET_SHOCK_TOOLTIP")
	row.add_child(shock_label)

	var stock_label := Label.new()
	stock_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(stock_label)

	var quantity_spin := SpinBox.new()
	quantity_spin.min_value = 1
	quantity_spin.max_value = MAX_BUY_QUANTITY
	quantity_spin.value = 1
	quantity_spin.custom_minimum_size = Vector2(70, 0)
	row.add_child(quantity_spin)

	var buy_button := Button.new()
	buy_button.text = tr("UI_MARKET_BUY")
	buy_button.pressed.connect(_on_buy_pressed.bind(item, quantity_spin))
	row.add_child(buy_button)

	var haggle_button := Button.new()
	haggle_button.text = tr("UI_MARKET_HAGGLE")
	haggle_button.pressed.connect(_on_haggle_pressed.bind(item, quantity_spin))
	row.add_child(haggle_button)

	var sell_button := Button.new()
	sell_button.text = tr("UI_MARKET_SELL")
	sell_button.pressed.connect(_on_sell_pressed.bind(item, quantity_spin))
	row.add_child(sell_button)

	# Krizdeki bir şehre tam da krizin malını satmak dünyanın hafızasına
	# yazılıyor (bkz. GameSession.is_profiteering_sale). Satış yasak değil -
	# yalnızca kanlı bir parmak izi, satmadan *önce* ne yaptığını söylüyor.
	var profiteer_mark := WaybookTheme.picture(PROFITEER_MARK_FILE, ITEM_ICON_SIZE)
	profiteer_mark.tooltip_text = tr("UI_MARKET_PROFITEERING_TOOLTIP")
	profiteer_mark.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(profiteer_mark)

	# Faz 17 PR-5: sepete ekle. Toptan pazarlığın çoklu-mal hali - bu satırın
	# kendi miktar seçicisini okuyup sepete katar, ayrı bir mini-mağazaya
	# ihtiyaç duymadan.
	var basket_button := Button.new()
	basket_button.text = tr("UI_MARKET_ADD_TO_BASKET")
	basket_button.pressed.connect(_on_basket_add_pressed.bind(item, quantity_spin))
	row.add_child(basket_button)

	_shop_rows.append({
		"item": item,
		"price_label": price_label,
		"shock_label": shock_label,
		"stock_label": stock_label,
		"buy_button": buy_button,
		"haggle_button": haggle_button,
		"basket_button": basket_button,
		"profiteer_mark": profiteer_mark,
	})
	return row

func _refresh_shop_rows() -> void:
	for row in _shop_rows:
		var item: Item = row.item
		var stock_label: Label = row.stock_label
		var remaining := _session.get_market_stock(item.item_id)

		if remaining < 0:
			stock_label.text = ""
		else:
			stock_label.text = tr("UI_MARKET_STOCK") % remaining

		var out_of_stock := remaining == 0
		row.buy_button.disabled = out_of_stock
		row.haggle_button.disabled = out_of_stock
		row.basket_button.disabled = out_of_stock

		# Fiyat alım-satımla (arz-talep baskısı) değişiyor, o yüzden burada
		# da tazeleniyor - yoksa şok işareti güncel kalsa bile yanındaki
		# fiyat sefer başında donup kalırdı.
		var price_label: Label = row.price_label
		price_label.text = tr("UI_MARKET_PRICES") % [_get_buy_price(item), _get_sell_price(item)]

		var shock_label: Label = row.shock_label
		var shocked := _session.market.is_shocked(
			_session.current_location_id, item.item_id, _session.total_days_elapsed
		)
		shock_label.text = tr("UI_MARKET_SHOCK_MARK") if shocked else ""
		# Görünmez değil saydam: satır hizası mal mal kaymasın.
		var mark: Control = row.profiteer_mark
		var profiteering := _session.is_profiteering_sale(item.item_id)
		mark.modulate.a = 1.0 if profiteering else 0.0
		mark.mouse_filter = Control.MOUSE_FILTER_PASS if profiteering else Control.MOUSE_FILTER_IGNORE

func _on_buy_pressed(item: Item, quantity_spin: SpinBox) -> void:
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return

	var price := _get_buy_price(item) * quantity
	if not _session.wallet.can_afford(price):
		_show_message(tr("UI_MARKET_NEED_GOLD") % price)
		return
	if not _has_enough_stock(item, quantity):
		_show_message(tr("UI_NOT_ENOUGH_STOCK") % item.item_name)
		return
	if not _has_enough_cargo_space(item, quantity):
		_show_message(tr("UI_CARGO_FULL") % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return
	if not _session.add_to_cargo(item, quantity):
		_show_message(tr("UI_MARKET_NO_ROOM"))
		return

	_session.consume_stock(item.item_id, quantity, price)
	_session.wallet.spend(price)
	_clear_message()
	_on_inventory_changed()

func _on_haggle_pressed(item: Item, quantity_spin: SpinBox) -> void:
	if _haggling_active:
		return
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return
	if not _has_enough_stock(item, quantity):
		_show_message(tr("UI_NOT_ENOUGH_STOCK") % item.item_name)
		return
	if not _has_enough_cargo_space(item, quantity):
		_show_message(tr("UI_CARGO_FULL") % [
			_session.get_cargo_weight(), _session.get_cargo_capacity()
		])
		return

	_pending_purchase_item = item
	_pending_purchase_quantity = quantity
	_set_shop_controls_enabled(false)
	_clear_children(_haggle_holder)

	var base_price := _get_buy_price(item) * quantity

	var intro := Label.new()
	intro.text = tr("UI_MARKET_HAGGLE_INTRO") % [quantity, item.item_name, base_price]
	_haggle_holder.add_child(intro)

	var panel := HagglingPanel.new()
	_haggle_holder.add_child(panel)
	panel.deal_made.connect(_on_haggle_deal)
	panel.haggling_failed.connect(_on_haggle_failed)
	# Pazarlık artık kör bir mini oyun değil: kervanın en iyi zekâsı ve
	# karizması tüccarın taban fiyatını gerçekten aşağı çeker (bkz.
	# HagglingSession.get_floor). Dilini iyi kullanan birini yanına almak
	# burada somut para kazandırır.
	panel.start_haggling(
		float(base_price),
		MARKET_HAGGLE_GREED,
		MARKET_HAGGLE_REPUTATION,
		_session.get_best_effective_stat(CharacterStats.Kind.INTELLECT),
		_session.get_best_effective_stat(CharacterStats.Kind.CHARISMA),
		false
	)

func _on_haggle_deal(price: int) -> void:
	if not _session.wallet.can_afford(price):
		_show_message(tr("UI_MARKET_CANNOT_PAY"))
		_close_haggling()
		return
	if not _session.add_to_cargo(_pending_purchase_item, _pending_purchase_quantity):
		_show_message(tr("UI_MARKET_NO_ROOM_CANCELLED"))
		_close_haggling()
		return

	_session.consume_stock(_pending_purchase_item.item_id, _pending_purchase_quantity, price)
	_session.wallet.spend(price)
	_show_message(tr("UI_MARKET_HAGGLE_WON") % price)
	_close_haggling()
	_on_inventory_changed()

## Masadan kalkmak bedava değil: alım iptal olur *ve* itibar yersin. Bu ceza
## olmadan "kopana kadar dip teklif ver, koparsa yeniden başla" bedava bir
## deneme döngüsü olurdu - pazarlığın para basma noktasına dönüştüğü yer
## tam olarak orasıydı (bkz. HagglingSession başlığı).
func _on_haggle_failed(reputation_penalty: int) -> void:
	if reputation_penalty > 0:
		_session.reputation -= reputation_penalty
		_show_message(
			tr("UI_MARKET_HAGGLE_LOST_REPUTATION")
			% reputation_penalty
		)
	else:
		_show_message(tr("UI_MARKET_HAGGLE_LOST"))
	_close_haggling()

func _close_haggling() -> void:
	_clear_children(_haggle_holder)
	_pending_purchase_item = null
	_pending_purchase_quantity = 0
	_set_shop_controls_enabled(true)
	_refresh_shop_rows()
	_refresh_basket_panel()

## enabled=false hem tekli hem sepet pazarlığı sırasında bütün ticaret
## kontrollerini kapatır - iki pazarlık aynı anda açık olamaz, ikisi de
## aynı _haggle_holder'ı paylaşıyor.
func _set_shop_controls_enabled(enabled: bool) -> void:
	_haggling_active = not enabled
	for row in _shop_rows:
		row.buy_button.disabled = not enabled
		row.haggle_button.disabled = not enabled
		row.basket_button.disabled = not enabled
	_basket_buy_button.disabled = not enabled or _basket.is_empty()
	_basket_haggle_button.disabled = not enabled or _basket.is_empty()
	_basket_clear_button.disabled = not enabled or _basket.is_empty()
	if enabled:
		_refresh_shop_rows()

func _on_sell_pressed(item: Item, quantity_spin: SpinBox) -> void:
	var quantity := int(quantity_spin.value)
	if quantity <= 0:
		return
	if _session.get_total_quantity(item.item_id) < quantity:
		_show_message(tr("UI_MARKET_NOT_ENOUGH_ITEM") % item.item_name)
		return

	var total_price := _get_sell_price(item) * quantity
	# Faz 17 PR-5: tüccarın kendi kesesi var, bedava para değil. Hazine
	# yetmiyorsa satış hiç başlamaz (hep ya da hiç - bkz. add_to_cargo'nun
	# aynı ilkesi), oyuncuya ne kadarını karşılayabildiği söylenir.
	if not _session.can_city_afford_sale(total_price):
		var reserve := _session.get_city_gold_reserve()
		var affordable_units := 0
		var unit_price := _get_sell_price(item)
		if unit_price > 0:
			affordable_units = int(floor(float(reserve) / float(unit_price)))
		_show_message(tr("UI_MARKET_CITY_CANNOT_AFFORD") % [reserve, affordable_units])
		return

	_session.remove_from_cargo_or_bags(item.item_id, quantity)
	_session.wallet.earn(total_price)
	# Aynı malı aynı şehre boca etmek fiyatını düşürür (bkz. MarketConditions)
	# ve şehrin hazinesinden o kadarını çeker.
	_session.record_sale(item.item_id, quantity, total_price)
	_clear_message()
	_on_inventory_changed()

func _has_enough_stock(item: Item, quantity: int) -> bool:
	var remaining := _session.get_market_stock(item.item_id)
	return remaining < 0 or remaining >= quantity

func _has_enough_cargo_space(item: Item, quantity: int) -> bool:
	if item.item_id == GameSession.PROVISIONS_ITEM_ID:
		return true
	return item.unit_weight * quantity <= _session.get_cargo_space_remaining()

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
	return MarketPricing.get_sell_price(
		item, _current_location, _session.market, _session.total_days_elapsed
	)

func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = MESSAGE_COLOR

func _clear_message() -> void:
	_message_label.text = ""

func _on_wallet_balance_changed(_new_balance: int) -> void:
	_refresh_header()

## Faz 17 PR-5: her alım/satım envanter ızgarasını ve mağaza satırlarını
## yeniden kuruyordu (kayıt sayısı değişince kaydırma kutusunun içeriği
## boyu değişiyor) - kaydırma konumu her seferinde en tepeye zıplıyordu.
## Bir sepet dolduran ya da alt alta alışveriş yapan oyuncu her tık sonrası
## yeniden en başa savruluyordu. Konum artık kenetlenip geri veriliyor.
func _on_inventory_changed() -> void:
	_with_preserved_scroll(func() -> void:
		_refresh_header()
		_refresh_shop_rows()
		_refresh_inventory_grid()
	)

## Bir işlem içerik yüksekliğini değiştirebilir (yeni envanter satırı,
## sepete eklenen/çıkan kalem) - kaydırma çubuğu buna göre kendini
## sıfırlar. Kaydeder, işlemi çalıştırır, konumu tek bir gecikmeli
## çağrıyla geri verir - konteynerlerin yeni boyutu aynı karede henüz
## oturmayabileceği için (bkz. World Navigation Rules'un anchor-preset
## tuzağı - aynı "layout henüz hazır değil" ailesi).
func _with_preserved_scroll(action: Callable) -> void:
	var saved := _scroll_container.scroll_vertical
	action.call()
	_scroll_container.set_deferred("scroll_vertical", saved)

func _refresh_header() -> void:
	_balance_value_label.text = "%d GG" % _session.wallet.balance
	_cargo_value_label.text = tr("UI_MARKET_CARGO") % [
		_session.get_cargo_weight(), _session.get_cargo_capacity()
	]
	_city_gold_label.text = tr("UI_MARKET_CITY_GOLD") % _session.get_city_gold_reserve()

func _refresh_inventory_grid() -> void:
	for child in _inventory_grid.get_children():
		_inventory_grid.remove_child(child)
		child.queue_free()

	var entries := _session.get_total_inventory_entries()
	var total_slots := GRID_COLUMNS * GRID_ROWS

	for i in range(total_slots):
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var item: Item = entry.item
			_inventory_grid.add_child(_cargo_cell(item, int(entry.quantity)))
		else:
			_inventory_grid.add_child(_cargo_cell(null, 0))

## Kargo hücresi ciltli küçük bir kutu (`CELL_PANEL`): malın resmi ve
## miktarı, adı ipucunda. Düz yeşil/gri `ColorRect` kutuları defterin hiçbir
## parçasına benzemiyordu.
func _cargo_cell(item: Item, quantity: int) -> Control:
	var cell := PanelContainer.new()
	cell.theme_type_variation = WaybookTheme.CELL_PANEL
	cell.custom_minimum_size = SLOT_SIZE
	if item == null:
		cell.modulate.a = EMPTY_CELL_ALPHA
		return cell
	cell.tooltip_text = "%s ×%d" % [item.item_name, quantity]
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(column)
	var icon := WaybookTheme.item_icon(item.item_id, CELL_ICON_SIZE)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var amount := Label.new()
	amount.text = "×%d" % quantity
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.add_theme_font_size_override("font_size", 15)
	column.add_child(amount)
	return cell

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())

## Tayfa ekranı ortak; hangi mekândan girildiğini gönderen ekran bildirir
## (bkz. Nav.recruit_venue). Geri tuşu gezinme yığınından döner.
func _add_recruit_button(venue: String, own_scene: String) -> void:
	var button := Button.new()
	button.text = tr("UI_LOOK_FOR_CREW")
	button.pressed.connect(_on_recruit_button_pressed.bind(venue, own_scene))
	var container := _back_button.get_parent()
	container.add_child(button)
	container.move_child(button, _back_button.get_index())

func _on_recruit_button_pressed(venue: String, own_scene: String) -> void:
	SceneInk.go(Nav.open_recruit(venue, own_scene))
