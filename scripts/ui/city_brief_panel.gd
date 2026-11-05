class_name CityBriefPanel
extends VBoxContainer

## Şehrin karar paneli. Şehir haritası beş kapı ve bir çıkıştı: oyuncu
## nereye gideceğini, ne alacağını, kervanın neye ihtiyacı olduğunu ancak
## o beş kapıyı tek tek gezerek öğrenebiliyordu. Nereye gidileceğini
## görmek için bile taverna → harita → planlayıcı gerekiyordu.
##
## Panel iki soruyu şehirde, tek ekranda cevaplıyor:
##
##   1. **Kervanın neye ihtiyacı var?** Hasarlı vagon, biten kontrat, boş
##      parti yeri, yaklaşan vade, yüksek stres - her satır onu çözen
##      ekranı açar. Sıralama aciliyete göre; ihtiyaç yoksa satır da yok.
##   2. **Nereye gidilir?** Her komşu şehir için gün, tehlike, yolun o
##      günkü hali ve o hedefe yazılmış kontratların toplam ödemesi. Seçim
##      doğrudan planlayıcıyı açar (bkz. TravelContext.selected_destination_id),
##      yani "görev al ve oraya doğru yola çık" tek tıkla oluyor.
##
## Sahnesiz, `.new()` ile kurulur (bkz. DebtPanel/OnboardingPanel deseni).
## Hiçbir yeni mekanik icat etmiyor: her satır oturumun zaten yayımladığı
## bir değeri okuyor. Panel yalnızca *gösteriyor*.

## Ekran değiştirmek panelin işi değil - şehir haritası bağlanır ve
## `Nav` ile gider, çünkü gezinme yığınını iten taraf gönderen ekrandır.
signal screen_requested(scene_path: String)
signal planner_requested(destination_id: String)

## Planlayıcının/borç panelinin aynı uyarı turuncusu - ArtPalette.UI_WARNING.
const URGENT_COLOR: Color = ArtPalette.UI_WARNING
const NOTE_COLOR: Color = Color(0.7, 0.72, 0.78)
const GOOD_COLOR: Color = Color(0.55, 0.8, 0.55)


var _session: GameSession
var _needs_box: VBoxContainer
var _routes_box: VBoxContainer
var _people_box: VBoxContainer

func setup(session: GameSession) -> void:
	_session = session
	_ensure_built()
	refresh()

func _ensure_built() -> void:
	if _needs_box != null:
		return
	add_theme_constant_override("separation", 10)

	add_child(_welcome_heading())
	add_child(_note(tr("UI_BRIEF_WELCOME_LINE")))
	add_child(HSeparator.new())

	add_child(_heading(tr("UI_BRIEF_NEEDS_TITLE")))
	_needs_box = VBoxContainer.new()
	_needs_box.add_theme_constant_override("separation", 6)
	add_child(_needs_box)

	add_child(HSeparator.new())

	# Tanıdıklar (Y-C13, T16-09): şehrin kalıcı kişileri, hatıraları ve işleri.
	add_child(_heading(tr("UI_PEOPLE_TITLE")))
	_people_box = VBoxContainer.new()
	_people_box.add_theme_constant_override("separation", 6)
	add_child(_people_box)

	add_child(HSeparator.new())

	add_child(_heading(tr("UI_BRIEF_ROUTES_TITLE")))
	_routes_box = VBoxContainer.new()
	_routes_box.add_theme_constant_override("separation", 6)
	add_child(_routes_box)

func refresh() -> void:
	if _session == null:
		return
	_ensure_built()
	NodeUtil.clear_children(_needs_box)
	NodeUtil.clear_children(_routes_box)
	NodeUtil.clear_children(_people_box)
	_session.note_city_arrival(journal_lines(_session))
	_build_needs()
	_build_people()
	_build_routes()

## Şehrin hâli (Y-C21) ve defterin son hatırası artık panelde değil, günlükte:
## varışta kervanbaşının gözlemi olarak yazılır (kullanıcı, 2026-11-01).
static func journal_lines(session: GameSession) -> Array[String]:
	var here := session.current_location_id
	var location := WorldMapData.get_location_by_id(here)
	var out: Array[String] = [TranslationServer.translate("UI_JOURNAL_ARRIVED") % (location.location_name if location != null else here)]
	out.append(TranslationServer.translate("UI_CITY_MOOD_LINE") % [TranslationServer.translate(session.morale_key(here)), int(round(session.scarcity_here() * 100.0))])
	var memory := CityBriefModel.build_memory(session)
	# Hatıra her varışta tekrarlanmaz: ilk sayfada ve yakın bir ölümün yasında yazılır.
	if not memory.is_empty() and (session.journal.is_empty() or bool(memory.get("mourning", false))):
		out.append(String(memory["text"]))
		if not String(memory["detail"]).is_empty():
			out.append(String(memory["detail"]))
	return out

# --- Kervanın ihtiyaçları ---

func _build_needs() -> void:
	var needs := _collect_needs()
	if needs.is_empty():
		var ready_label := Label.new()
		ready_label.text = tr("UI_BRIEF_READY")
		ready_label.modulate = GOOD_COLOR
		ready_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_needs_box.add_child(ready_label)
		return

	for need in needs:
		_needs_box.add_child(_build_need_row(need))

## Satırlar aciliyet sırasında: vadesi geçmiş borç, yolda kalmaya yol
## açacak eksikler, sonra fırsatlar. Karşılığı olmayan bir ihtiyaç hiç
## üretilmiyor - boş bir uyarı listesi gürültüdür.
## Liste `CityBriefModel`'den gelir - panel yalnızca çizer.
func _collect_needs() -> Array[Dictionary]:
	return CityBriefModel.build_needs(_session)

func _build_need_row(need: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = String(need.text)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bool(need.urgent):
		# `.modulate` zaten çözülmüş font_color'ı bir kez daha çarpıyordu
		# (planlayıcı/borç paneliyle aynı hata) - yazının rengi doğrudan.
		label.add_theme_color_override("font_color", URGENT_COLOR)
	row.add_child(label)

	var button := Button.new()
	button.text = String(need.action)
	if String(need.scene).is_empty() or (_session.is_shut_out() and String(need.scene) != Nav.ECONOMY):
		# Bu yerde o mekân yok (bkz. CityBriefModel) ya da Avuçiçi kapısı inançsıza
		# kapalı (Ç14): kilitli, sebebi yazılı.
		button.disabled = true
		if _session.is_shut_out():
			button.tooltip_text = tr("UI_AVUCICI_SHUT_OUT")
	else:
		button.pressed.connect(_on_screen_requested.bind(String(need.scene)))
	row.add_child(button)
	return row

# --- Tanıdıklar ---

func _build_people() -> void:
	_session.people.ensure_city(_session.current_location_id, _session.total_days_elapsed)
	for person in _session.people.city_people(_session.current_location_id):
		_people_box.add_child(_person_row(person))

func _person_row(person: Dictionary) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var role := tr(String(People.ROLE_KEYS[person["role"]]))
	var head := Label.new()
	head.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(head)
	if not bool(person["alive"]):
		head.text = tr("UI_PEOPLE_DEAD") % [String(person["name"]), role, int(person.get("died_day", 0)) + 1]
		head.modulate = NOTE_COLOR
		return box
	head.text = tr("UI_PEOPLE_ROW") % [String(person["name"]), role, People.age_years(person, _session.total_days_elapsed)]
	var memory := tr("UI_PEOPLE_MET") % int(person["met"])
	var regard := People.regard(person)
	if regard > 0:
		memory += " " + tr("UI_PEOPLE_REGARD_GOOD")
	elif regard < 0:
		memory += " " + tr("UI_PEOPLE_REGARD_BAD")
	box.add_child(_note(memory))
	var chain: Dictionary = person.get("chain", {})
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var id := String(person["id"])
	if int(person.get("chain_step", 0)) >= People.CHAIN_STEPS:
		row.add_child(_note(tr("UI_PEOPLE_CHAIN_DONE_ALL")))
	elif chain.is_empty():
		var ask := Button.new()
		ask.text = tr("UI_PEOPLE_ASK")
		ask.pressed.connect(func():
			_session.people.offer_chain(id, _session.total_days_elapsed)
			refresh())
		row.add_child(ask)
	else:
		var item := ItemCatalog.get_item(String(chain["item"]))
		var wants := _note(tr("UI_PEOPLE_CHAIN") % [int(chain["qty"]), item.item_name if item != null else String(chain["item"]), int(chain["due"]) + 1, int(chain["gold"])])
		wants.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(wants)
		var deliver := Button.new()
		deliver.text = tr("UI_PEOPLE_DELIVER")
		# Kapalı düğme sebebini söyler: kaç tane eksik olduğu yazılır
		# (profil günlükleri, 2026-11-05).
		var chain_reason := _session.get_chain_block_reason(id)
		if not chain_reason.is_empty():
			var missing_text := _session.get_chain_missing_text(id)
			deliver.text = "%s — %s" % [
				deliver.text, missing_text if not missing_text.is_empty() else tr(chain_reason)
			]
		deliver.disabled = not chain_reason.is_empty()
		deliver.pressed.connect(func():
			if _session.deliver_chain(id):
				refresh())
		row.add_child(deliver)
	return box

# --- Nereye gidilir ---

func _build_routes() -> void:
	var routes := WorldMapData.get_routes_from(_session.current_location_id)
	if routes.is_empty():
		_routes_box.add_child(_note(tr("UI_BRIEF_NO_ROUTES")))
		return
	for route in routes:
		_routes_box.add_child(_build_route_row(route))

func _build_route_row(route: TravelRoute) -> VBoxContainer:
	var destination := WorldMapData.get_location_by_id(route.to_location_id)
	var destination_name := route.to_location_id if destination == null else destination.location_name

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var headline := Label.new()
	headline.text = "%s · %s" % [destination_name, route_summary(route)]
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(headline)

	# Veba (Y-C25): yalnızca bilinen haber söylenir; ne zaman duyulduğuyla.
	var news := _session.plague_news_for(route.to_location_id)
	if bool(news.get("sick", false)):
		var plague := Label.new()
		var age := _session.total_days_elapsed - int(news.get("day", 0))
		plague.text = tr("UI_BRIEF_ROUTE_PLAGUE") if age <= 0 else tr("UI_BRIEF_ROUTE_PLAGUE_OLD") % age
		plague.autowrap_mode = TextServer.AUTOWRAP_WORD
		plague.modulate = URGENT_COLOR
		box.add_child(plague)

	# Gidilecek yerin hâli: aç şehre yük götürmek oranın hâlini düzeltir.
	if _session.morale_of(route.to_location_id) < GameSession.MORALE_HUNGRY:
		var hungry := Label.new()
		hungry.text = tr("UI_BRIEF_ROUTE_HUNGRY")
		hungry.autowrap_mode = TextServer.AUTOWRAP_WORD
		hungry.modulate = NOTE_COLOR
		box.add_child(hungry)

	var offers := _session.get_accepted_offers_for_destination(route.to_location_id)
	var payout := 0
	for offer in offers:
		payout += offer.potential_profit

	var contract_note := Label.new()
	contract_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	contract_note.modulate = NOTE_COLOR
	if offers.is_empty():
		contract_note.text = tr("UI_BRIEF_ROUTE_NO_CONTRACT")
	else:
		contract_note.text = tr("UI_BRIEF_ROUTE_CONTRACTS") % [offers.size(), payout]
	box.add_child(contract_note)

	var button := Button.new()
	# Kapalı yol çıkmaz sokak değil ama buradan seçilmez: dolambaçlı yolu
	# harita gösteriyor (bkz. Route Rules), panel yalnızca bugün gidilebilecek
	# yerleri öneriyor - sebebiyle birlikte, gizlemeden.
	if _session.is_route_open(route):
		button.text = tr("UI_BRIEF_SET_OUT") % destination_name
		button.pressed.connect(_on_planner_requested.bind(route.to_location_id))
	else:
		button.text = RouteConditions.get_state_label(_session.get_route_state(route))
		button.disabled = true
	box.add_child(button)
	return box

## Dünya haritasındaki özetin aynısı: tehlike yüzdesi ancak tavernada
## öğrenildiyse ya da kervanda bir İzci varsa açık, yoksa kaba bant.
func route_summary(route: TravelRoute) -> String:
	var days := _session.get_route_travel_days(route)
	var danger := _session.get_route_danger(route)
	var state := _session.get_route_state(route)
	var state_note := ""
	if state != RouteConditions.State.OPEN:
		state_note = " · %s" % RouteConditions.get_state_label(state)

	var known := _session.is_route_known(_session.current_location_id, route.to_location_id)
	if known or _session.get_duty_holder(DutyCatalog.IZCI) != null:
		# Önce söz, yüzde parantezde (Y-H03).
		return tr("UI_BRIEF_ROUTE_KNOWN") % [days, tr(Wording.level_key(Wording.DANGER, danger, 1.0)), int(danger * 100.0), state_note]
	return tr("UI_BRIEF_ROUTE_UNKNOWN") % [days, Wording.danger_band(danger), state_note]

# --- Yardımcılar ---

func _on_screen_requested(scene_path: String) -> void:
	screen_requested.emit(scene_path)

func _on_planner_requested(destination_id: String) -> void:
	planner_requested.emit(destination_id)

## Şehrin adı, kervanın neye ihtiyacı olduğu/nereye gidilebileceğinden
## önce gelen ilk satır - "burada durduğun yer" sorusuna cevap. Şehir
## isimleri `culture_catalog.gd`'nin isim havuzları gibi özel ad, tr()
## taramasının muaf tuttuğu kategori - yalnızca "Hoş geldiniz." satırı
## çevrilir.
func _welcome_heading() -> Label:
	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	var city_name := tr("UI_CITY_FALLBACK_NAME") if location == null else location.location_name
	var label := Label.new()
	label.text = city_name
	label.add_theme_font_size_override("font_size", 24)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label

func _note(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = NOTE_COLOR
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	return label
