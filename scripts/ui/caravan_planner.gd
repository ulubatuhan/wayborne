extends Control

## Kervan planlayıcı. Erzağı gerçek envanterden okur, eksiği cüzdandan
## satın aldırır ve onaylandığında kervanı gerçekten yola çıkarır.

## Uyarı turuncusu artık ArtPalette.UI_WARNING'te (bkz. onun kendi yorumu) -
## bu ekranın satırları defect matrix'in ölçtüğü 2.4-3.7:1'e düşen yerdi,
## çünkü `.modulate` zaten çözülmüş `font_color`'ı bir kez daha çarpıyordu.
## Etiketler artık `add_theme_color_override("font_color", ...)` kullanıyor.
const SATISFIED_COLOR: Color = Color(0.45, 0.8, 0.45)

var _session: GameSession
var _plan: CaravanPlan
var _destination: Location
var _route_danger: float = 0.0
var _route_state: RouteConditions.State = RouteConditions.State.OPEN
var _terrain: RouteTerrain
var _offer_rows: Array[Dictionary] = []

var _wagon_counter_label: Label
var _gold_label: Label
## Dondurucu gecelerin erzak payı; tüccar seçildikçe ağız sayısı değişiyor,
## o yüzden _refresh'te yeniden yazılıyor.
var _cold_label: Label
var _party_label: Label
var _documents_label: Label
var _required_provisions_label: Label
var _current_provisions_label: Label
var _shortfall_label: Label
## Eksik erzakla çıkmanın somut bedeli: kaç gün aç kalınacağı. Ayrı bir
## etiket, çünkü eksiklik satırı "ne kadar eksik / kaça alınır" diyor;
## bu satır "çıkarsan ne olur" diyor ve ikisi farklı sorular.
var _risk_label: Label
var _offer_warning_label: Label
## Sofra kipi (Ö2): hangi kip, günde kaç erzak. Yolda verilen emir
## **burada da** verilebiliyor, çünkü asıl bedeli yola çıkarken ödüyorsun.
var _meal_label: Label
var _meal_buttons: Array[Dictionary] = []
var _labour_button: Button
var _profit_label: Label
var _upkeep_label: Label
var _morale_label: Label
var _morale_reasons: VBoxContainer
var _buy_provisions_button: Button
## Satın alma yetmezse görünür - loncanın borçlar sekmesine götürür.
## Ekranın kendisi borç vermiyor; DebtPanel zaten kredi hattı ve tahsis
## ücreti kurallarını taşıyor, burası yalnızca oraya işaret ediyor.
var _borrow_button: Button
var _confirm_button: Button
## Onay silahlanmış mı (bkz. _on_confirm_pressed). Ekran her açıldığında
## sıfırdan başlar, yani bir önceki ziyaretin onayı taşınmaz.
var _departure_armed: bool = false
var _result_label: Label

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	WaybookTheme.fit_desk_workspace(self)
	_session = GameState.get_session()

	_destination = WorldMapData.get_location_by_id(TravelContext.selected_destination_id)
	var origin := WorldMapData.get_location_by_id(_session.current_location_id)

	if _destination == null or origin == null:
		_build_missing_context_ui()
		return
	var none: Array[MerchantOffer] = []
	_setup(origin, none)

## Kestirme açılıp kapanınca plan yeniden kurulur (süre, tehlike, arazi,
## erzak payı hep birlikte değişir); seçili kontratlar korunur.
func _rebuild() -> void:
	var chosen: Array[MerchantOffer] = []
	chosen.append_array(_plan.get_selected_offers())
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_departure_armed = false
	_setup(WorldMapData.get_location_by_id(_session.current_location_id), chosen)

func _setup(origin: Location, chosen: Array[MerchantOffer]) -> void:
	var route := WorldMapData.get_route(origin.location_id, _destination.location_id)
	var travel_days: int = 1
	if route != null:
		# Süre ve tehlike yolun ham tablosundan değil o günkü halinden
		# geliyor (bkz. RouteConditions): çamur yolu uzatır, eşkıya
		# tehlikeyi yükseltir. İzci bunun üstüne biner - öndeki tehlikeyi
		# ve en kısa yolu bilir, kervandaysa yol kısalır (asla bir günün
		# altına inmez), bkz. DutyCatalog.IZCI.
		var izci_reduction := _session.get_duty_flat_reduction(DutyCatalog.IZCI)
		travel_days = maxi(1, _session.get_route_travel_days(route) - izci_reduction)
		_route_danger = _session.get_route_danger(route)
		_route_state = _session.get_route_state(route)
	_base_travel_days = travel_days
	if _use_shortcut and RouteTerrain.shortcut_available(travel_days):
		travel_days = RouteTerrain.shortcut_days(travel_days)
		_route_danger = RouteTerrain.shortcut_danger(_route_danger)

	_plan = CaravanPlan.new(
		_destination, travel_days, _session.get_wagon_capacity(), _session.owned_wagon_count
	)
	# Erzak hesabının kervana bağlı parçaları: kimi besleyeceğimiz, kültürün
	# iştahı ve levazımcının tasarrufu. Bunlar verilmezse plan yolun gerçekte
	# yiyeceğinden az bir sayı gösterir.
	_plan.caravan_party_size = _session.get_party().size()
	_plan.provision_multiplier = _session.get_daily_provision_multiplier()
	_plan.provision_reduction = _session.get_duty_flat_reduction(DutyCatalog.LEVAZIMCI)
	_plan.height_adjustment = CaravanPlan.height_adjustment_for(_session.get_party())
	_plan.animal_mouths = _session.get_pack_animal_provision_mouths()
	# Dağılan ekip ağız sayısını da düşürür (G2): plan gerçek eli sayar,
	# vagon sayısını değil - yoksa yolda yenmeyecek bir sayı gösterir.
	_plan.crew_hands = _session.get_crew_hands()
	# Emanet yük (Y-C02) vagonlardaki boş yere sığmalı.
	_plan.cargo_room = _session.get_cargo_space_remaining()
	for offer in chosen:
		_plan.toggle_merchant(offer)

	# Yolun coğrafyası ve havası. İkisi de tohumdan hesaplanıyor, yani
	# burada gösterilen arazi ve hava payı yolda birebir yaşanacak olan
	# (bkz. RouteTerrain, RouteWeather) - planlayıcı "muhtemelen" demiyor.
	#
	# Hava payı erzak hesabına giriyor çünkü yağmur yolu yavaşlatıyor: bu
	# satır olmasa "planlayıcının istediğini aldım ve yine aç kaldım"
	# olurdu (bkz. Provision Rules).
	var route_key := RouteConditions.route_key(
		origin.location_id, _destination.location_id
	)
	_terrain = RouteTerrain.build(route_key, travel_days, origin.location_id, _session.departure_season(), _is_shortcut())
	# Kondisyon payı hava payıyla aynı hesaba giriyor (bkz. RouteWeather.
	# forecast_extra_days'in condition_factor notu) - vagon yükü ve parti
	# kondisyonunun bugünkü (yola çıkış anındaki) en yavaşı, seferin
	# kalanında da geçerli varsayılıyor. Şehre varışta can zaten tam
	# (bkz. finish_journey), o yüzden bu anlık görüntü genelde iyimser
	# değil gerçekçi bir taban.
	# Akşam kampı emri de aynı hesaba giriyor: her akşam sekiz saat yol
	# alınmıyor ve ateşin kendi erzağı var (bkz. GameSession.CAMP_HOURS).
	var walking_hours := 24.0
	if _session.standing_camp_at_dusk:
		walking_hours -= GameSession.CAMP_HOURS
	_plan.travel_reserve_days = int(ceil(RouteWeather.forecast_extra_days(
		route_key, _session.total_days_elapsed + 1, _terrain, travel_days,
		_session.get_caravan_theoretical_speed(), walking_hours
	)))
	if _session.standing_camp_at_dusk:
		_plan.camp_provisions = GameSession.CAMP_PROVISIONS_COST * _plan.get_provisioned_days()
	# Soğuk: dondurucu günlerde herkes daha çok yer. Yol o günü aynı formülle
	# yiyor (GameSession.get_daily_provision_consumption), planlayıcı da
	# kervanın o gün girebileceği en soğuk parçaya göre önceden istiyor.
	_plan.cold_ration_shares = Temperature.forecast_ration_shares(
		route_key, _session.total_days_elapsed + 1, _terrain, travel_days,
		_session.get_caravan_theoretical_speed(), walking_hours
	)

	if not _session.wallet.balance_changed.is_connected(_on_wallet_changed):
		_session.wallet.balance_changed.connect(_on_wallet_changed)

	_build_ui(origin, _destination, travel_days)
	_refresh()

func _build_missing_context_ui() -> void:
	var label := Label.new()
	label.text = tr("UI_PLANNER_NO_DESTINATION")
	_content.add_child(label)

	var back_button := Button.new()
	back_button.text = tr("UI_BACK_TO_MAP")
	back_button.pressed.connect(_on_map_pressed)
	$MarginContainer/VBoxContainer.add_child(back_button)

## Tehlike yüzdesinin kaynakları (görev Y-F10), motorun kendi adımlarından.
const DANGER_PART_KEYS: Dictionary = {
	"base": "UI_DANGER_PART_BASE",
	"state": "UI_DANGER_PART_STATE",
	"world": "UI_DANGER_PART_WORLD",
	"growth": "UI_DANGER_PART_GROWTH",
	"convoy": "UI_DANGER_PART_CONVOY",
	"brotherhood": "UI_DANGER_PART_BROTHERHOOD",
}

## Kestirme (görev Y-B13): yol kısalır, ortası zor araziden geçer, tehlike artar.
var _use_shortcut: bool = false
var _base_travel_days: int = 1

func _is_shortcut() -> bool:
	return _use_shortcut and RouteTerrain.shortcut_available(_base_travel_days)

func _add_shortcut_choice() -> void:
	if not RouteTerrain.shortcut_available(_base_travel_days):
		return
	var saved := _base_travel_days - RouteTerrain.shortcut_days(_base_travel_days)
	var button := Button.new()
	button.toggle_mode = true
	button.button_pressed = _use_shortcut
	button.text = tr("UI_PLANNER_SHORTCUT_ON" if _use_shortcut else "UI_PLANNER_SHORTCUT_OFF") % [
		saved, int(round(RouteTerrain.SHORTCUT_DANGER_DELTA * 100.0)),
	]
	button.toggled.connect(func(on: bool):
		_use_shortcut = on
		_rebuild.call_deferred())
	_content.add_child(button)

## Yolun hafızası planlayıcıda (Y-B11): kaç kez yürüdün, kimler orada yatıyor.
func _add_route_memory() -> void:
	var key := RouteConditions.route_key(_session.current_location_id, _destination.location_id)
	var names: Array[String] = []
	for m in _session.memorials_on(key):
		if String(m["kind"]) == GameSession.MEMORIAL_GRAVE or String(m["kind"]) == GameSession.MEMORIAL_CAIRN:
			names.append(String(m["name"]))
	var trips := int((_session.route_memory.get(key, {}) as Dictionary).get("trips", 0))
	if names.is_empty() and trips <= 0:
		return
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.modulate = Color(0.78, 0.80, 0.74)
	label.text = tr("UI_PLANNER_ROUTE_MEMORY") % [trips, ", ".join(names) if not names.is_empty() else tr("UI_PLANNER_ROUTE_NO_GRAVES")]
	_content.add_child(label)

func _add_danger_breakdown() -> void:
	var route := WorldMapData.get_route(_session.current_location_id, _destination.location_id)
	var parts := _session.get_route_danger_breakdown(route)
	if parts.size() < 2 and not _is_shortcut():
		return
	var words: Array[String] = []
	for part in parts:
		var key := String(DANGER_PART_KEYS.get(String(part["part"]), ""))
		var percent := int(round(float(part["delta"]) * 100.0))
		# "state" ve "convoy" iki parçalı: biri yolun hâlini, öbürü kaç
		# vagonluk kolon olduğunu adıyla söylüyor.
		if String(part["part"]) in ["state", "convoy"]:
			words.append(tr(key) % [String(part["arg"]), percent])
		else:
			words.append(tr(key) % percent)
	if _is_shortcut():
		var before := float(parts[-1]["value"])
		words.append(tr("UI_DANGER_PART_SHORTCUT") % int(round((RouteTerrain.shortcut_danger(before) - before) * 100.0)))
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text = tr("UI_PLANNER_DANGER_BREAKDOWN") % " · ".join(words)
	label.modulate = Color(0.78, 0.80, 0.74)
	_content.add_child(label)

func _build_ui(origin: Location, destination: Location, travel_days: int) -> void:
	var title := Label.new()
	title.text = tr("UI_PLANNER_TITLE") % [origin.location_name, destination.location_name]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = WaybookTheme.PAGE_TITLE
	_content.add_child(title)

	var route_label := Label.new()
	var state_note := ""
	if _route_state != RouteConditions.State.OPEN:
		state_note = " · %s" % RouteConditions.get_state_label(_route_state)
	route_label.text = tr("UI_PLANNER_ROUTE") % [
		travel_days,
		state_note,
		int(_route_danger * 100.0),
		_plan.max_wagons,
		_plan.player_wagon_count,
	]
	_content.add_child(route_label)
	_add_danger_breakdown()
	_add_shortcut_choice()
	_add_route_memory()

	# Arazi: rota seçimi kör bir karar olmasın. "İki gün bozkır, sonra
	# orman" cümlesi oyuncuya neyle karşılaşacağını söylüyor ve yol
	# ekranındaki manzarayla birebir eşleşiyor.
	if _terrain != null:
		var terrain_label := Label.new()
		terrain_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		terrain_label.text = tr("UI_PLANNER_TERRAIN") % _terrain.describe()
		terrain_label.modulate = Color(0.78, 0.80, 0.74)
		_content.add_child(terrain_label)

	if _plan.travel_reserve_days > 0:
		var weather_label := Label.new()
		weather_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		weather_label.text = tr("UI_PLANNER_WEATHER_RESERVE") % _plan.travel_reserve_days
		weather_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
		_content.add_child(weather_label)

	if _plan.camp_provisions > 0:
		var camp_label := Label.new()
		camp_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		camp_label.text = tr("UI_PLANNER_CAMP_RESERVE") % _plan.camp_provisions
		camp_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
		_content.add_child(camp_label)

	_cold_label = Label.new()
	_cold_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_cold_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
	_content.add_child(_cold_label)

	_gold_label = Label.new()
	_content.add_child(_gold_label)

	_wagon_counter_label = Label.new()
	_content.add_child(_wagon_counter_label)

	_content.add_child(HSeparator.new())

	var merchants_title := Label.new()
	merchants_title.text = tr("UI_PLANNER_MERCHANTS")
	_content.add_child(merchants_title)

	var accepted_offers := _session.get_accepted_offers_for_destination(destination.location_id)
	if accepted_offers.is_empty():
		var hint_label := Label.new()
		hint_label.text = tr("UI_NO_CONTRACTS_FOR_DESTINATION")
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_content.add_child(hint_label)
	for offer in accepted_offers:
		_content.add_child(_build_offer_row(offer))
	# G8: alınmaya çalışılan ama sığmayan ilanın sebebi buraya yazılıyor.
	# Ayrı bir etiket, çünkü `_risk_label`'ı her tazeleme erzak yazısıyla
	# eziyor - uyarı bir tıklamanın cevabı, sürekli bir durum değil.
	_offer_warning_label = Label.new()
	_offer_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_offer_warning_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
	_offer_warning_label.visible = false
	_content.add_child(_offer_warning_label)

	_content.add_child(HSeparator.new())

	var summary_title := Label.new()
	summary_title.text = tr("UI_PLANNER_SUMMARY")
	_content.add_child(summary_title)

	_party_label = Label.new()
	_documents_label = Label.new()
	_required_provisions_label = Label.new()
	_current_provisions_label = Label.new()
	_shortfall_label = Label.new()
	_risk_label = Label.new()
	_risk_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_risk_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
	_risk_label.visible = false
	_profit_label = Label.new()
	# Büyümenin bedeli (U3): bakım faturası yola çıkmadan okunsun.
	_upkeep_label = Label.new()
	_content.add_child(_party_label)
	_content.add_child(_documents_label)
	_content.add_child(_required_provisions_label)
	_content.add_child(_current_provisions_label)
	_content.add_child(_shortfall_label)
	_content.add_child(_upkeep_label)
	_content.add_child(_risk_label)
	_build_meal_row()
	_content.add_child(_profit_label)

	# Çıkış morali görünmezse mekanik sessiz bir cezaya dönüşür: oyuncu
	# neden düşük moralle yola çıktığını göremez (bkz. GameSession.
	# get_departure_morale_breakdown).
	_content.add_child(HSeparator.new())
	_morale_label = Label.new()
	_content.add_child(_morale_label)
	_morale_reasons = VBoxContainer.new()
	_content.add_child(_morale_reasons)

	# Erzağın iki yolu **yan yana**: parayla al, ya da bir gün çalış.
	# Alt alta konduğunda ekran uzuyor ve "yola çık" düğmesi aşağı
	# taşıyordu (ekran görüntüsünde yakalandı); iki seçenek zaten aynı
	# sorunun iki cevabı, yan yana durmaları da doğru.
	var provisions_row := HBoxContainer.new()
	provisions_row.add_theme_constant_override("separation", 8)
	_content.add_child(provisions_row)

	_buy_provisions_button = Button.new()
	_buy_provisions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_provisions_button.pressed.connect(_on_buy_provisions_pressed)
	provisions_row.add_child(_buy_provisions_button)

	# Gündelik iş (Ö3): zordaki oyuncunun tek kurtarma kolu. Zaman öder,
	# para değil - kıtlık kipini bozmaz, para musluğu açmaz.
	_labour_button = Button.new()
	_labour_button.visible = false
	_labour_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_labour_button.pressed.connect(_on_labour_pressed)
	provisions_row.add_child(_labour_button)

	_borrow_button = Button.new()
	_borrow_button.text = tr("UI_PLANNER_BORROW_FOR_PROVISIONS")
	_borrow_button.visible = false
	_borrow_button.pressed.connect(_on_borrow_pressed)
	_content.add_child(_borrow_button)

	_confirm_button = Button.new()
	_confirm_button.text = tr("UI_CONFIRM_CARAVAN")
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_content.add_child(_confirm_button)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_result_label)

	_content.add_child(HSeparator.new())

	# Çıkış tuşları kaydırma kutusunun dışında: plan uzadıkça (kontratlar,
	# erzak, moral dökümü) aşağı kayıp ekrandan taşmasınlar - pazar
	# ekranında bir kez yaşanan tuzak (bkz. World Navigation Rules).
	var exit_row := $MarginContainer/VBoxContainer

	var map_button := Button.new()
	map_button.text = tr("UI_BACK_TO_MAP")
	map_button.pressed.connect(_on_map_pressed)
	exit_row.add_child(map_button)

	var back_button := Button.new()
	back_button.text = Nav.back_label()
	back_button.pressed.connect(_on_back_pressed)
	exit_row.add_child(back_button)

## Kervanın yola hangi ruh haliyle çıkacağı ve nedeni.
func _refresh_departure_morale() -> void:
	var departure := _session.get_departure_morale()
	_morale_label.text = tr("UI_PLANNER_DEPARTURE_MORALE") % [
		departure, CaravanState.MAX_MORALE
	]

	for child in _morale_reasons.get_children():
		_morale_reasons.remove_child(child)
		child.queue_free()

	var breakdown := _session.get_departure_morale_breakdown()
	if breakdown.is_empty():
		var good_day := Label.new()
		good_day.text = tr("UI_MORALE_GOOD_DAY")
		_morale_reasons.add_child(good_day)
		return

	for entry in breakdown:
		var line := Label.new()
		# Önce söz, sayı parantezde (Y-H03): "Zamanın darlığı: Moral biraz düştü (-8)".
		line.text = "  %s: %s" % [tr(String(entry["key"])), Wording.change_line(Wording.MORALE, int(entry["amount"]))]
		var line_color := SATISFIED_COLOR if int(entry["amount"]) > 0 else ArtPalette.UI_WARNING
		line.add_theme_color_override("font_color", line_color)
		_morale_reasons.add_child(line)

func _build_offer_row(offer: MerchantOffer) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var checkbox := CheckBox.new()
	checkbox.set_pressed_no_signal(_plan.is_selected(offer))
	checkbox.toggled.connect(_on_offer_toggled.bind(offer, checkbox))
	row.add_child(checkbox)

	var name_label := Label.new()
	# tr() bilinmeyen bir anahtarda dizeyi olduğu gibi döner (Godot'un
	# varsayılanı), o yüzden bu sıradan tüccar isimlerini (kültür isim
	# havuzundan, hiç CSV'de tanımlı değil) bozmaz - yalnızca loncanın iki
	# özel vagon görevinin gerçek çeviri anahtarını (bkz. WorldMapData.
	# _build_guild_wagon_quests) çözer.
	name_label.text = tr(offer.merchant_name)
	name_label.custom_minimum_size = Vector2(160, 0)
	row.add_child(name_label)

	var wagon_label := Label.new()
	# Eşekli bir tüccar vagon slotu tüketmiyor (bkz. MerchantOffer.
	# uses_donkey_escort) - etiket de bunu söylemeli, yoksa "0 vagon"
	# okunurdu ki bu ne kervanın gerçekte taşıdığı şey ne de doğru bir sayı.
	if offer.uses_donkey_escort():
		wagon_label.text = tr("UI_PLANNER_DONKEYS") % offer.donkey_count
	elif offer.kind == MerchantOffer.KIND_PASSENGER:
		wagon_label.text = tr("UI_PLANNER_PASSENGERS") % offer.passengers
	elif offer.cargo_weight > 0:
		# Emanet yük bizim vagonlarımızda yer kaplar (Y-C02).
		wagon_label.text = tr("UI_PLANNER_CARGO") % offer.cargo_weight
	else:
		wagon_label.text = tr("UI_PLANNER_WAGONS") % offer.wagon_count
	wagon_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(wagon_label)

	var profit_label := Label.new()
	profit_label.text = tr("UI_PLANNER_PROFIT") % offer.potential_profit
	profit_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(profit_label)

	_offer_rows.append({"offer": offer, "checkbox": checkbox})
	return row

func _on_offer_toggled(_toggled_on: bool, offer: MerchantOffer, checkbox: CheckBox) -> void:
	# G8: kutucuk kapalı değil - tıklanır, olmuyorsa **sebebini söyler.**
	# Ölü bir kutucuk oyuncuya neyin eksik olduğunu öğretmiyordu.
	var reason := _plan.get_offer_block_reason(offer)
	if _plan.toggle_merchant(offer):
		if _offer_warning_label != null:
			_offer_warning_label.visible = false
	else:
		checkbox.set_pressed_no_signal(false)
		if _offer_warning_label != null and not reason.is_empty():
			_offer_warning_label.text = tr(reason)
			_offer_warning_label.visible = true
	_refresh()

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh()

## Şehirde ne varsa o kadar. Alım `GameSession.buy_provisions`'tan geçiyor:
## stok, kese ve kargo sınırı orada tek yerde (bkz. P5/P9B - açlığın kapısı
## artık para değil arz).
func _on_buy_provisions_pressed() -> void:
	var shortfall := _plan.get_provisions_shortfall(_session.get_provisions())
	if shortfall <= 0:
		return
	_session.buy_provisions(shortfall)
	_refresh()

func _on_labour_pressed() -> void:
	# Ekranda ayrı bir mesaj satırı yok: `_refresh` erzak, gün ve maliyet
	# satırlarını zaten tazeliyor, sayılar kendi kendini anlatıyor.
	_session.work_a_day()
	_refresh()

func _refresh_labour_button() -> void:
	if _labour_button == null:
		return
	# Yalnız erzağı eksik olan kervana görünür: tok kervanın gün harcaması
	# anlamsız, ve düğme her zaman duruyorsa bir çözüm değil bir alışkanlık
	# olur.
	var shortfall := _plan.get_provisions_shortfall(_session.get_provisions()) if _plan != null else 0
	_labour_button.visible = _session.should_offer_day_labour(shortfall)
	if _labour_button.visible:
		_labour_button.text = tr("UI_PLANNER_LABOUR") % maxi(
			GameSession.DAY_LABOUR_MIN_PROVISIONS,
			int(round(float(_session.get_daily_provision_consumption())
				* GameSession.DAY_LABOUR_PROVISION_FACTOR))
		)

func _on_borrow_pressed() -> void:
	Nav.guild_initial_tab = 1
	SceneInk.go(Nav.open(Nav.CARAVAN_PLANNER, Nav.GUILD))

## Sofra kipleri yan yana, her birinin günlük erzak maliyetiyle.
## Ablasyonun bulduğu şey: bu karar oyunun en sert değişkeni ve oyuncu
## bedelini göremeden veriyor.
const MEAL_ROW_MODES: Array[String] = [
	GameSession.MEAL_MODE_ALL,
	GameSession.MEAL_MODE_PARTY_ONLY,
	GameSession.MEAL_MODE_SELF_ONLY,
]

func _build_meal_row() -> void:
	# Başlık ve düğmeler **tek satırda**: ayrı satırda durduklarında ekran
	# uzuyor ve kaydırma alanının altındaki "yola çık" düğmesi görünmez
	# oluyordu (ekran görüntüsünde yakalandı - Y-K01'in tam konusu).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_content.add_child(row)
	_meal_label = Label.new()
	row.add_child(_meal_label)
	for mode in MEAL_ROW_MODES:
		var button := Button.new()
		button.toggle_mode = true
		button.pressed.connect(_on_meal_mode_pressed.bind(mode))
		row.add_child(button)
		_meal_buttons.append({"mode": mode, "button": button})

func _on_meal_mode_pressed(mode: String) -> void:
	_session.set_meal_policy(mode)
	_refresh()

func _refresh_meal_row() -> void:
	if _meal_label == null:
		return
	_meal_label.text = tr("UI_PLANNER_MEAL_TITLE")
	for entry in _meal_buttons:
		var mode := String(entry["mode"])
		var button: Button = entry["button"]
		button.text = tr("UI_PLANNER_MEAL_OPTION") % [
			tr(MEAL_POLICY_LABELS.get(mode, mode)),
			_session.daily_provisions_for_mode(mode),
		]
		button.set_pressed_no_signal(_session.meal_policy_mode == mode)

## Yol ekranıyla aynı adlar: aynı emir iki yerde iki ad taşımasın.
const MEAL_POLICY_LABELS: Dictionary = {
	GameSession.MEAL_MODE_ALL: "UI_MEAL_POLICY_ALL",
	GameSession.MEAL_MODE_PARTY_ONLY: "UI_MEAL_POLICY_PARTY",
	GameSession.MEAL_MODE_SELF_ONLY: "UI_MEAL_POLICY_SELF",
}

func _refresh() -> void:
	_refresh_meal_row()
	_refresh_departure_morale()
	var cold := _plan.get_cold_provisions()
	_cold_label.visible = cold > 0
	_cold_label.text = tr("UI_PLANNER_COLD_RESERVE") % cold
	_gold_label.text = tr("UI_PURSE") % _session.wallet.balance
	_wagon_counter_label.text = tr("UI_PLANNER_WAGON_SLOTS") % [
		_plan.get_used_wagon_count(),
		_plan.get_available_wagon_slots(),
	]

	for row in _offer_rows:
		var offer: MerchantOffer = row.offer
		var checkbox: CheckBox = row.checkbox
		# Kutucuk artık kapatılmıyor (G8): tıklanıp sebebi okunabilsin.
		checkbox.disabled = false

	var current_provisions := _session.get_provisions()
	var required_provisions := _plan.get_required_provisions()
	var shortfall := _plan.get_provisions_shortfall(current_provisions)

	_party_label.text = tr("UI_PLANNER_PARTY") % [
		_plan.get_party_size(),
		_plan.get_total_wagon_count(),
	]
	# G2: dört vagonun ikisi sürülemiyorsa "Toplam vagon: 4" yanıltıcıdır.
	if _session.get_idle_wagon_count() > 0:
		_party_label.text += " · " + tr("UI_CREW_SHORT") % [
			_session.crew_missing, _session.get_idle_wagon_count()
		]
	_documents_label.text = tr("UI_PLANNER_DOCUMENTS") % _plan.get_required_documents()
	_required_provisions_label.text = tr("UI_PLANNER_PROVISIONS_NEEDED") % required_provisions
	_current_provisions_label.text = tr("UI_PLANNER_PROVISIONS_HELD") % current_provisions

	var shortfall_cost := shortfall * GameSession.PROVISIONS_UNIT_PRICE
	if shortfall > 0:
		# Şehirde ne kadar var: planlayıcı **doğru sayıyı söylemeye devam
		# ediyor**, ama o sayı burada bulunmayabilir. Sözün yeni hâli bu
		# (P9/B): "stok bulabilirsen aç kalmazsın".
		var stock := _session.get_provision_stock()
		var buyable := shortfall if stock < 0 else mini(shortfall, stock)
		_shortfall_label.text = tr("UI_PLANNER_PROVISIONS_SHORT") % [shortfall, shortfall_cost]
		# Aç gün sayısı aşağıdaki risk satırında zaten yazıyor (Ö1); onay düğmesi
		# de aynı sayıyı kullanıyor (IP-001). Burada tekrar edilmez.
		var hungry_days: int = _plan.get_hungry_days(current_provisions)
		if stock >= 0 and stock < shortfall:
			_shortfall_label.text += "\n" + (tr("UI_PLANNER_PROVISIONS_STOCK") % stock)
		_shortfall_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
		_buy_provisions_button.visible = true
		_buy_provisions_button.text = tr("UI_PLANNER_BUY_PROVISIONS") % (
			buyable * GameSession.PROVISIONS_UNIT_PRICE
		)
		var can_afford := _session.wallet.can_afford(GameSession.PROVISIONS_UNIT_PRICE)
		_buy_provisions_button.disabled = not can_afford or buyable <= 0
		# Alacak param yoksa satın alma tuşu kilitli kalır ve tek başına
		# çıkmaza götürür - oyuncu ya eksik erzakla yola çıkmayı kabul
		# etmeli ya da loncadan borç almalı. İkinci seçenek burada, bir
		# tık uzakta olmasın diye.
		_borrow_button.visible = not can_afford

		# Yola çıkmak **yasak değil, riskli**. Kilit yerine silahlanan bir
		# onay: ilk basış riski sayıyla söylüyor, ikincisi çıkıyor.
		# `.modulate` düğmenin dokusunu *ve* yazısını birlikte karartıyordu
		# (parti ekranındaki aynı hata) - yalnızca yazının rengi uyarıyor.
		_confirm_button.disabled = false
		_confirm_button.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
		if _departure_armed:
			# İkinci basışta soyut bir "emin misin?" değil, kaç gün aç
			# yürüneceği yazar (IP-001).
			_confirm_button.text = tr("UI_PLANNER_DEPART_CONFIRM_DAYS") % hungry_days
		else:
			_confirm_button.text = tr("UI_PLANNER_DEPART_HUNGRY")
		_risk_label.visible = true
		# **Bedelin ölçeği** (Ö1, profil çalışması 2026-11-05). Eski cümle
		# yalnız "moral düşer, stres birikir" diyordu ve atlatılabilir bir
		# rahatsızlık gibi okunuyordu; oysa ölçüm aynı kararın kervanı üç
		# seferde bitirdiğini gösterdi. Açlık eşiğini geçen yolda uyarı
		# ölümü **adıyla** anıyor. Yeni mekanik yok: söylenen şey zaten
		# işleyen `STARVATION_HP_LOSS_START_DAY`.
		if hungry_days >= GameSession.STARVATION_HP_LOSS_START_DAY:
			_risk_label.text = tr("UI_PLANNER_HUNGER_DEADLY") % [
				hungry_days, GameSession.STARVATION_HP_LOSS_START_DAY
			]
		else:
			_risk_label.text = tr("UI_PLANNER_HUNGER_RISK") % hungry_days
	else:
		_shortfall_label.text = tr("UI_PLANNER_READY")
		_shortfall_label.add_theme_color_override("font_color", SATISFIED_COLOR)
		_buy_provisions_button.visible = false
		_borrow_button.visible = false
		_confirm_button.disabled = false
		_confirm_button.remove_theme_color_override("font_color")
		_confirm_button.text = tr("UI_CONFIRM_CARAVAN")
		_risk_label.visible = false
		_departure_armed = false

	var upkeep := _session.get_wagon_upkeep(_plan.travel_days)
	_upkeep_label.visible = upkeep > 0
	if upkeep > 0:
		_upkeep_label.text = tr("UI_PLAN_UPKEEP") % upkeep
		_upkeep_label.add_theme_color_override("font_color", ArtPalette.UI_WARNING)
	_profit_label.text = tr("UI_TOTAL_POTENTIAL") % _plan.get_total_profit()
	# **Sonda**: eksik erzak sayısı bu noktada kesinleşiyor. Başta
	# çağrıldığında `_plan` henüz kurulmamış oluyordu ve düğme tam
	# gerektiği anda gizli kalıyordu - ekran görüntüsü yakaladı.
	_refresh_labour_button()

## Eksik erzakla çıkmak iki basış ister: ilki riski söyler, ikincisi
## kabul eder. Tek basış, ekranı okumayan bir oyuncuyu kazara aç bir yola
## sokardı; onay kutusu ise oyunun hiçbir yerinde olmayan bir kalıp.
func _on_confirm_pressed() -> void:
	if _plan.get_provisions_shortfall(_session.get_provisions()) > 0 and not _departure_armed:
		_departure_armed = true
		_refresh()
		return

	_session.depart_with_contracts(_plan.get_selected_offers())
	_session.start_journey(
		_destination.location_id,
		_plan.travel_days,
		_route_danger,
		_plan,
		_is_shortcut()
	)
	SceneInk.go(Nav.go_root(Nav.JOURNEY))

func _on_map_pressed() -> void:
	SceneInk.go(Nav.open(Nav.CARAVAN_PLANNER, Nav.TRAVEL))

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
