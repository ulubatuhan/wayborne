extends Control

## Taverna (görev 9.4, kullanıcı notu 2026-10-19: "popup değil, tamamen
## referans ekran gibi"). Ekranın üstü odanın kendisi, tam genişlikte; altında
## yolun alt paneliyle aynı sekmeli panel (kadro, yük, harita, artı tavernanın
## hizmetleri ve yol söylentileri); en altta düğmeler: sohbete başla, tavernayı
## izle (panel kalkar, oda büyür), tayfa ara, geri dön.
##
## Rota dedikodusu hâlâ satın alınıyor (Söylentiler sekmesi); N34 bunu sohbetle
## öğrenilen bilgiye çevirecek. Tehlike seviyesi varsayılan olarak kaba bir bant
## (dünya haritasında gösterilir) - tam yüzdeyi öğrenmek için burada ödeme
## yapılır. Bilgi kalıcıdır (bkz. GameSession.known_routes), rota simetrik
## olduğu için öğrenince iki yön de kaydolur.

const BASE_RUMOR_COST: int = 10
const PER_DAY_RUMOR_COST: int = 5

## Bir konuğa ısmarlanan içkinin bedeli; içen konuk bildiğini daha kolay söyler.
const DRINK_COST: int = 3
## Biri yollardan bildiğini söyler mi: rolüne göre (meyhaneci ve ozan her şeyi
## duyar), içki ısmarlanmışsa daha çok (N34'ün ilk adımı: söylenti sohbetle).
const NEWS_CHANCE: Dictionary = {"bartender": 0.65, "bard": 0.55, "waitress": 0.4, "patron": 0.35, "visitor": 0.45}
const NEWS_DRINK_BONUS: float = 0.35

## Tavernadaki huy arındırma, Kilise'den daha pahalı - içmekle unutmak
## Kilise'nin uzmanlaştığı işten daha kolay değil (bkz. church.gd).
const PURIFICATION_COST: int = 60

## Oda ile alt panelin yükseklik oranı (referansta oda ekranın üçte ikisi).
const ROOM_STRETCH: float = 2.3

var _session: GameSession
var _rows: Array[Dictionary] = []
var _purification_panel: PurificationPanel
var _room: TavernRoom
var _panel: RoadControlPanel
var _chat_button: Button
var _watch_button: Button
var _purse_label: Label
var _chat_rng := RandomNumberGenerator.new()
var _feast_label: Label
var _feast_button: Button
## Fiyat söylentisi (görev Y-C10): komşu şehirlerin fiyatı, bazen yanlış.
var _price_rumor_list: VBoxContainer
## Bu gün kime içki ısmarlandı, kime yol soruldu (kişi kimliği -> true).
var _treated: Dictionary = {}
var _asked: Dictionary = {}
var _talk: DialoguePanel

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _scroll: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var _info_label: Label = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/InfoLabel
@onready var _rumor_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/RumorList
@onready var _map_button: Button = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/MapButton
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	# Masa sütunu (fit_desk_workspace) burada yok: ekranın tamamı oda.
	_session = GameState.get_session()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	# Sahne dosyasındaki yazı yalnızca editör içindir; oyuncunun gördüğü her
	# metin koddan, anahtarla gelir (bkz. Localization Rules).
	_info_label.text = tr("UI_TAVERN_HINT")
	_map_button.text = tr("UI_GO_TO_WORLD_MAP")
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_map_button.pressed.connect(_on_map_pressed)
	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = tr("UI_TAVERN_TITLE") if location == null else tr("UI_TAVERN_TITLE_CITY") % location.location_name
	_build_screen()
	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_build_rows()
	_refresh_rows()
	_refresh_feast()
	_refresh_price_rumors()
	_refresh_purse()

## Ekranı referans düzeninde kurar: üst şerit, oda, panel, alt şerit.
func _build_screen() -> void:
	($BackgroundArt as CanvasItem).visible = false
	($BackgroundScrim as ColorRect).color = ArtPalette.GRIM_CHARCOAL
	var margin: MarginContainer = $MarginContainer
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 0)
	var column: VBoxContainer = $MarginContainer/VBoxContainer
	column.add_theme_constant_override("separation", 0)

	var top := _strip()
	column.add_child(top)
	column.move_child(top, 0)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 16)
	top.add_child(top_row)
	_title_label.reparent(top_row)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_purse_label = Label.new()
	_purse_label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	top_row.add_child(_purse_label)

	_room = TavernRoom.new()
	_room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_room.size_flags_stretch_ratio = ROOM_STRETCH
	column.add_child(_room)
	column.move_child(_room, 1)
	_room.populate(_session.current_location_id, _session.total_days_elapsed)
	_room.person_chosen.connect(_on_person_chosen)
	_chat_rng.seed = hash("tavern_chat|%s|%d" % [_session.current_location_id, _session.total_days_elapsed])

	_panel = RoadControlPanel.new().setup(_session, func() -> Dictionary: return {"origin": _session.current_location_id}, null)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.size_flags_stretch_ratio = 1.0
	column.add_child(_panel)
	column.move_child(_panel, 2)
	_panel.hide_tab(RoadControlPanel.TAB_STATUS)
	_panel.hide_tab(RoadControlPanel.TAB_LOG)
	_panel.map_requested.connect(_on_map_pressed)
	_panel.add_tab(tr("UI_TAVERN_SERVICES"), _services_page())
	_scroll.get_parent().remove_child(_scroll)
	_panel.add_tab(tr("UI_TAVERN_TAB_RUMORS"), _scroll)
	_panel.select_tab(RoadControlPanel.TAB_PARTY)

	var bottom := _strip()
	column.add_child(bottom)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	bottom.add_child(bar)
	var hint := Label.new()
	hint.text = tr("UI_TAVERN_ROOM_HINT")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hint.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	bar.add_child(hint)
	_chat_button = Button.new()
	_chat_button.text = tr("UI_TAVERN_CHAT")
	_chat_button.toggle_mode = true
	_chat_button.toggled.connect(_on_chat_toggled)
	bar.add_child(_chat_button)
	_watch_button = Button.new()
	_watch_button.text = tr("UI_TAVERN_WATCH")
	_watch_button.toggle_mode = true
	_watch_button.toggled.connect(_on_watch_toggled)
	bar.add_child(_watch_button)
	_back_button.reparent(bar)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	RecruitButton.add_before(_back_button, RecruitCatalog.VENUE_TAVERN, Nav.TAVERN)

## Üst ve alt şerit: yolun HUD şeridiyle aynı koyu bant.
func _strip() -> PanelContainer:
	var strip := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.97)
	box.border_color = Color(ArtPalette.GRIM_AMBER, 0.35)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	strip.add_theme_stylebox_override("panel", box)
	return strip

## Hizmetler sekmesi: arınma, ziyafet, fiyat söylentileri.
func _services_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 28)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(left)
	_purification_panel = PurificationPanel.new()
	left.add_child(_purification_panel)
	_purification_panel.setup(_session, tr("UI_PURIFY_TRAIT"), PURIFICATION_COST)
	_purification_panel.trait_removed.connect(_refresh_rows)
	# Ziyafet: stresin paralı kolu. Varış rahatlaması artık seferin
	# getirdiğini tek başına eritmiyor (bkz. GameSession.get_city_rest_relief),
	# o yüzden oyuncunun kesesiyle müdahale edebileceği bir yol olmalı -
	# yoksa stres kaçınılmaz bir sayaca dönerdi.
	left.add_child(HSeparator.new())
	_feast_label = Label.new()
	_feast_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	left.add_child(_feast_label)
	_feast_button = Button.new()
	_feast_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_feast_button.pressed.connect(_on_feast_pressed)
	left.add_child(_feast_button)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(right)
	var price_heading := Label.new()
	price_heading.autowrap_mode = TextServer.AUTOWRAP_WORD
	price_heading.text = tr("UI_PRICE_RUMOR_HEADING") % int(round(GameSession.PRICE_RUMOR_FALSE_CHANCE * 100.0))
	right.add_child(price_heading)
	_price_rumor_list = VBoxContainer.new()
	right.add_child(_price_rumor_list)
	var book_button := Button.new()
	book_button.text = tr("UI_PRICE_BOOK_OPEN")
	book_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	book_button.pressed.connect(func(): add_child(PriceBookPanel.new().setup(_session)))
	right.add_child(book_button)
	return scroll

func _refresh_purse() -> void:
	_purse_label.text = tr("UI_TAVERN_TOP_LINE") % [_session.total_days_elapsed + 1, _session.wallet.balance]

func _on_chat_toggled(on: bool) -> void:
	_room.set_chat_mode(on)
	_chat_button.text = tr("UI_TAVERN_CHAT_END") if on else tr("UI_TAVERN_CHAT")

## Tavernayı izle: panel kalkar, oda alanın tamamını alır.
func _on_watch_toggled(on: bool) -> void:
	_panel.visible = not on
	_watch_button.text = tr("UI_TAVERN_WATCH_END") if on else tr("UI_TAVERN_WATCH")

## Bir kişiye tıklanınca konuşma penceresi açılır (kullanıcı isteği: NPC
## konuşmaları portreli bir pencerede). İlk söz kişinin kendi derdinden
## (RoadChatter); sonra içki ısmarlanabilir, yollar sorulabilir. Yolları
## sormak bedava ama her zaman cevap gelmez: rolüne ve içkiye bağlı bir
## şansla komşu bir yolun tehlikesini söyler (GameSession.learn_route) -
## dedikodu satın alınmadan, sohbetle (N34'ün ilk adımı).
func _on_person_chosen(character: CharacterData, role: String) -> void:
	if _talk != null:
		return
	var picked := RoadChatter.pick(character, {"day": _session.total_days_elapsed, "night": true}, _chat_rng)
	var opening := tr("UI_TALK_GREETING")
	if not picked.is_empty():
		RoadChatter.apply(character, picked, _session.total_days_elapsed)
		opening = tr(String(picked["key"]))
	_talk = DialoguePanel.new()
	add_child(_talk)
	_talk.choice_made.connect(_on_talk_choice.bind(character, role))
	_talk.closed.connect(func() -> void: _talk = null)
	_talk.open(character, tr(String(TavernRoom.ROLE_LABEL_KEYS.get(role, "UI_TAVERN_ROLE_GUEST"))), opening, _talk_choices(character))

func _talk_choices(character: CharacterData) -> Array:
	var choices: Array = []
	if not _treated.has(character.character_id):
		var drink := {"id": "drink", "text": tr("UI_TALK_DRINK"), "cost": tr("UI_TALK_COST") % DRINK_COST}
		if not _session.wallet.can_afford(DRINK_COST):
			drink["locked"] = tr("UI_TALK_NO_GOLD")
		choices.append(drink)
	if not _asked.has(character.character_id):
		choices.append({"id": "roads", "text": tr("UI_TALK_ROADS")})
	choices.append({"id": "bye", "text": tr("UI_TALK_BYE")})
	return choices

func _on_talk_choice(id: String, character: CharacterData, role: String) -> void:
	match id:
		"drink":
			if _session.wallet.can_afford(DRINK_COST):
				_session.wallet.spend(DRINK_COST)
				_treated[character.character_id] = true
				_talk.say(tr("UI_TALK_DRINK_THANKS"), _talk_choices(character))
		"roads":
			_asked[character.character_id] = true
			_talk.say(_road_news(character, role), _talk_choices(character))
			_refresh_rows()
		_:
			_talk.close()

## Bildiği bir yol varsa söyler ve öğrenilir; şans kişinin kimliği ve günden
## tohumlu, yeniden açmak sonucu değiştirmez.
func _road_news(character: CharacterData, role: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("tavern_news|%s|%d" % [character.character_id, _session.total_days_elapsed])
	var chance := float(NEWS_CHANCE.get(role, 0.35)) + (NEWS_DRINK_BONUS if _treated.has(character.character_id) else 0.0)
	var unknown: Array[TravelRoute] = []
	for route in WorldMapData.get_routes_from(_session.current_location_id):
		if not _session.is_route_known(_session.current_location_id, route.to_location_id):
			unknown.append(route)
	if unknown.is_empty() or rng.randf() >= chance:
		return tr("UI_TALK_ROAD_NONE")
	var route: TravelRoute = unknown[rng.randi_range(0, unknown.size() - 1)]
	_session.learn_route(_session.current_location_id, route.to_location_id)
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	return tr("UI_TALK_ROAD_NEWS") % [
		destination.location_name if destination != null else route.to_location_id,
		_session.get_route_travel_days(route), int(round(_session.get_route_danger(route) * 100.0)),
	]

func _refresh_feast() -> void:
	_feast_label.text = tr("UI_TAVERN_FEAST_HINT") % [
		_session.party_stress, GameSession.MAX_STRESS, GameSession.FEAST_STRESS_RELIEF
	]
	_feast_button.text = tr("UI_TAVERN_FEAST") % _session.get_feast_cost()
	_feast_button.disabled = not _session.can_afford_feast()

func _on_feast_pressed() -> void:
	if _session.throw_feast():
		_refresh_feast()

func _build_rows() -> void:
	for route in WorldMapData.get_routes_from(_session.current_location_id):
		_rumor_list.add_child(_build_row(route))

func _build_row(route: TravelRoute) -> HBoxContainer:
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = destination.location_name if destination != null else route.to_location_id
	name_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_label)

	var status_label := Label.new()
	status_label.custom_minimum_size = Vector2(220, 0)
	row.add_child(status_label)

	var buy_button := Button.new()
	buy_button.pressed.connect(_on_buy_pressed.bind(route))
	row.add_child(buy_button)

	_rows.append({
		"route": route,
		"status_label": status_label,
		"buy_button": buy_button,
	})
	return row

## Liman şehrinden gelen bir kervancı her dedikoduyu daha ucuza duyar
## (bkz. Culture.rumor_cost_multiplier).
func _rumor_cost(route: TravelRoute) -> int:
	var base_cost := BASE_RUMOR_COST + route.travel_days * PER_DAY_RUMOR_COST
	var cost := float(base_cost) * _session.get_rumor_cost_multiplier()
	cost *= 1.0 - _session.get_duty_discount(DutyCatalog.TELLAL)
	return maxi(1, int(round(cost)))

func _refresh_rows() -> void:
	for row in _rows:
		var route: TravelRoute = row.route
		var status_label: Label = row.status_label
		var buy_button: Button = row.buy_button
		var known := _session.is_route_known(_session.current_location_id, route.to_location_id)

		# Yolun o günkü hali herkesin gözü önünde - çamura batmış bir geçit
		# dedikodu değil, meydan sohbeti. Parayla öğrenilen şey tehlikenin
		# *yüzdesi* (bkz. GameSession.known_routes), yolun durumu değil.
		var days := _session.get_route_travel_days(route)
		var state := _session.get_route_state(route)
		var state_note := ""
		if state != RouteConditions.State.OPEN:
			state_note = " · %s" % RouteConditions.get_state_label(state)

		if known:
			var effective_danger := _session.get_route_danger(route)
			status_label.text = tr("UI_TAVERN_ROUTE_KNOWN") % [
				days, int(effective_danger * 100.0), state_note
			]
			buy_button.text = tr("UI_TAVERN_LEARNED")
			buy_button.disabled = true
		else:
			var cost := _rumor_cost(route)
			status_label.text = tr("UI_TAVERN_ROUTE_UNKNOWN") % [days, state_note]
			buy_button.text = tr("UI_TAVERN_BUY_RUMOUR") % cost
			buy_button.disabled = not _session.wallet.can_afford(cost)

func _on_buy_pressed(route: TravelRoute) -> void:
	var cost := _rumor_cost(route)
	if not _session.wallet.can_afford(cost):
		return
	_session.wallet.spend(cost)
	_session.learn_route(_session.current_location_id, route.to_location_id)
	_refresh_rows()

## Komşu her şehir için bir satır: bildiğimizin yaşı, söylentinin bedeli ya
## da neden alınamadığı (kilitli düğme sebebiyle, gizlenmez).
func _refresh_price_rumors() -> void:
	for child in _price_rumor_list.get_children():
		child.queue_free()
	for route in WorldMapData.get_routes_from(_session.current_location_id):
		var target := route.to_location_id
		var destination := WorldMapData.get_location_by_id(target)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := Label.new()
		name_label.text = destination.location_name if destination != null else target
		name_label.custom_minimum_size = Vector2(160, 0)
		row.add_child(name_label)
		var age := _session.get_price_age(target)
		var known := Label.new()
		known.custom_minimum_size = Vector2(200, 0)
		known.text = tr("UI_PRICE_RUMOR_UNKNOWN") if age < 0 else tr("UI_PRICE_RUMOR_KNOWN") % age
		row.add_child(known)
		var button := Button.new()
		button.text = tr("UI_PRICE_RUMOR_BUY") % _session.get_price_rumor_cost(target)
		var reason := _session.get_price_rumor_block_reason(target)
		button.disabled = not reason.is_empty()
		button.pressed.connect(func():
			if _session.buy_price_rumor(target):
				_refresh_price_rumors())
		row.add_child(button)
		if not reason.is_empty():
			var why := Label.new()
			why.text = tr(reason)
			why.modulate = Color(0.75, 0.72, 0.66)
			row.add_child(why)
		_price_rumor_list.add_child(row)

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh_price_rumors()
	_refresh_rows()
	_refresh_feast()
	_refresh_purse()
	_purification_panel.refresh()

func _on_map_pressed() -> void:
	SceneInk.go(Nav.open(Nav.TAVERN, Nav.TRAVEL))

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
