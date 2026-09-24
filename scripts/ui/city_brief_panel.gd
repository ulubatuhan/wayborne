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

const URGENT_COLOR: Color = Color(0.9, 0.45, 0.35)
const NOTE_COLOR: Color = Color(0.7, 0.72, 0.78)
const GOOD_COLOR: Color = Color(0.55, 0.8, 0.55)
const OBJECTIVE_MARK_SIZE: float = 11.0

const CREPE_FILE: String = "c1_crepe.png"
const CREPE_HEIGHT: float = 34.0

var _session: GameSession
var _chapter_box: VBoxContainer
var _needs_box: VBoxContainer
var _routes_box: VBoxContainer

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

	add_child(_heading(tr("UI_BRIEF_CHAPTER_TITLE")))
	_chapter_box = VBoxContainer.new()
	_chapter_box.add_theme_constant_override("separation", 4)
	add_child(_chapter_box)

	add_child(HSeparator.new())

	add_child(_heading(tr("UI_BRIEF_NEEDS_TITLE")))
	_needs_box = VBoxContainer.new()
	_needs_box.add_theme_constant_override("separation", 6)
	add_child(_needs_box)

	add_child(HSeparator.new())

	add_child(_heading(tr("UI_BRIEF_ROUTES_TITLE")))
	_routes_box = VBoxContainer.new()
	_routes_box.add_theme_constant_override("separation", 6)
	add_child(_routes_box)

func refresh() -> void:
	if _session == null:
		return
	_ensure_built()
	_clear(_chapter_box)
	_clear(_needs_box)
	_clear(_routes_box)
	_build_chapter()
	_build_needs()
	_build_routes()

# --- Hikâyenin neresindeyiz ---

## Hikâye bittikten sonra da ekran boş kalmıyor: oyun kapanmıyor, serbest
## ticaret sürüyor (bkz. CampaignCatalog'un `is_finale` notu), o yüzden
## bunu söyleyen bir satır duruyor.
func _build_chapter() -> void:
	var chapter := _session.get_current_chapter()
	if chapter == null:
		var epilogue := Label.new()
		epilogue.text = tr("UI_BRIEF_CHAPTER_DONE")
		epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD
		epilogue.modulate = GOOD_COLOR
		_chapter_box.add_child(epilogue)
		return

	var heading := Label.new()
	heading.text = tr("UI_BRIEF_CHAPTER_LINE") % [
		_session.campaign_chapter_index + 1,
		CampaignCatalog.chapter_count(),
		tr(chapter.title_key),
	]
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD
	_chapter_box.add_child(heading)

	var summary := Label.new()
	summary.text = tr(chapter.summary_key)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	summary.modulate = NOTE_COLOR
	_chapter_box.add_child(summary)

	var objective := Label.new()
	objective.text = tr(chapter.objective_key)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD
	_chapter_box.add_child(objective)

	# Sayaç hedefinde "tamam/değil" oyuncuya hiçbir şey söylemez; kaç kaldığı
	# söyler (bkz. CampaignChapter.describe_progress).
	var context := _session.build_campaign_context()
	for row in chapter.describe_progress(context):
		# Tamamlanmış hedefin tiki bir süre `✓` karakteriydi ve ekranda boş
		# kutu olarak çıkıyordu (varsayılan font o bloğu taşımıyor), yani
		# *biten* hedef bozuk görünüyordu. Artık çiziliyor, bkz. `UiIcon`.
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)

		var met := bool(row.met)
		var color: Color = GOOD_COLOR if met else NOTE_COLOR

		var mark := UiIcon.new()
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if met:
			mark.setup(UiIcon.Kind.CHECK, color, OBJECTIVE_MARK_SIZE)
		else:
			mark.setup_pips(1, [], color, OBJECTIVE_MARK_SIZE)
		line.add_child(mark)

		var label := CampaignCatalog.get_objective_label(String(row.key))
		var text := Label.new()
		if bool(row.numeric):
			text.text = tr("UI_BRIEF_OBJECTIVE_COUNT") % [label, int(row.current), int(row.target)]
		else:
			text.text = label
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.modulate = color
		line.add_child(text)

		_chapter_box.add_child(line)

	_build_memory()

## Defter hiçbir satırı silmiyor ama pasifti - yalnızca yol ekranındaki
## `CaravanStatusPanel`'i `Tab` ile açan biri görüyordu. Brifing zaten her
## varışta kendiliğinden açılan ekran (bkz. City Hub Rules'un "hikâye ile
## başlar" maddesi), o yüzden en son düşen/ayrılan isim buraya da taşınıyor -
## oyuncu aramadan önüne geliyor. "No need, no row" burada da geçerli:
## defterde üstü çizili hiçbir satır yoksa bu blok da yok.
func _build_memory() -> void:
	var memory_data := CityBriefModel.build_memory(_session)
	if memory_data.is_empty():
		return
	var memory := Label.new()
	memory.text = String(memory_data["text"])
	memory.autowrap_mode = TextServer.AUTOWRAP_WORD
	memory.modulate = NOTE_COLOR
	memory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if bool(memory_data.get("mourning", false)):
		# Yakın bir ölümün yası: hatıranın başında siyah kurdele (C1).
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var crepe := WaybookTheme.picture(CREPE_FILE, CREPE_HEIGHT)
		crepe.tooltip_text = tr("UI_BRIEF_MOURNING")
		crepe.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(crepe)
		row.add_child(memory)
		_chapter_box.add_child(row)
	else:
		_chapter_box.add_child(memory)
	if not String(memory_data["detail"]).is_empty():
		var detail := Label.new()
		detail.text = String(memory_data["detail"])
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD
		detail.modulate = NOTE_COLOR
		_chapter_box.add_child(detail)

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
		label.modulate = URGENT_COLOR
	row.add_child(label)

	var button := Button.new()
	button.text = String(need.action)
	button.pressed.connect(_on_screen_requested.bind(String(need.scene)))
	row.add_child(button)
	return row

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
	headline.text = "%s · %s" % [destination_name, _route_summary(route)]
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(headline)

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
func _route_summary(route: TravelRoute) -> String:
	var days := _session.get_route_travel_days(route)
	var danger := _session.get_route_danger(route)
	var state := _session.get_route_state(route)
	var state_note := ""
	if state != RouteConditions.State.OPEN:
		state_note = " · %s" % RouteConditions.get_state_label(state)

	var known := _session.is_route_known(_session.current_location_id, route.to_location_id)
	if known or _session.get_duty_holder(DutyCatalog.IZCI) != null:
		return tr("UI_BRIEF_ROUTE_KNOWN") % [days, int(danger * 100.0), state_note]
	return tr("UI_BRIEF_ROUTE_UNKNOWN") % [days, _danger_band(danger), state_note]

func _danger_band(danger: float) -> String:
	if danger < 0.3:
		return tr("UI_DANGER_LOW")
	if danger < 0.55:
		return tr("UI_DANGER_MEDIUM")
	return tr("UI_DANGER_HIGH")

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

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
