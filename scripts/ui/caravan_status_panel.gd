class_name CaravanStatusPanel
extends VBoxContainer

## Yoldaki kervanın tam dökümü - tek ekranda, tek tuşla.
##
## Yol HUD'ı bilerek ince: iki şerit, aralarında manzara (bkz. Road Screen
## Layout Rules). Ama incelik bir bedelle geldi - kervanın *ayrıntısı*
## hiçbir yerde okunamıyordu. Bir playtest oyuncusu tam bunu istedi:
## *"yolculuk kısmında daha detaylı 'My Caravan Status' tarzında bir sekme
## açılsa"*, ve ardından *"status, map, inventory, my contracts gibi"*
## düğmeler. İkisi aynı istek: **yolda kervanı okuyabilmek.**
##
## Cevabı dört ayrı ekran değil bir katman, çünkü yol bir ekran
## değiştirmez (bkz. road_journey.gd'nin savaş sahnesi kararı): kervan
## yürümeye devam ederken oyuncu üzerine bakar.
##
## Panel **hiçbir şeye karar vermez, yalnızca gösterir** - `CityBriefPanel`
## ile aynı kural. Okuduğu her değer oturumun zaten yayımladığı bir değer;
## yeni bir hesap icat etmiyor.
##
## Sahnesiz (`PulseBar`, `DebtPanel`, `OnboardingPanel` deseni): `.new()` +
## `setup()` + `refresh()`.

const TITLE_COLOR: Color = Color(0.85, 0.78, 0.55)
const SECTION_COLOR: Color = Color(0.80, 0.82, 0.76)
const NOTE_COLOR: Color = Color(0.70, 0.72, 0.78)
const HURT_COLOR: Color = Color(0.90, 0.55, 0.45)
const GOOD_COLOR: Color = Color(0.55, 0.80, 0.55)
const URGENT_COLOR: Color = Color(0.90, 0.45, 0.35)

## Stresi bu oranın üstünde olan kişi kırılmaya yakın sayılıyor - kadro
## listesinde kırmızıya döner. Kişinin *kendi* direncine göre okunuyor
## (bkz. CharacterData.is_stressed), kadro ortalamasına göre değil: kim
## kırılır sorusunun cevabı bir ortalama değil.
const STRESS_WARNING_RATIO: float = 0.75

var _session: GameSession
var _body: VBoxContainer

## `session` girişte `null` olabilir: yol ekranında bu panel `_ready()`
## sırasında kuruluyor ama gerçek oturum ancak `_init_journey()` bittiğinde
## atanıyor (bkz. road_journey.gd). Yapı yine de kurulur, `refresh()`
## oturum gelene kadar sessizce boş kalır - `set_session()` gerçek
## oturumu verdiğinde ilk gerçek dolum olur.
func setup(session: GameSession) -> void:
	_session = session
	add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = tr("UI_STATUS_TITLE")
	title.modulate = TITLE_COLOR
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)

	# İçerik kaydırma kutusunda, kapatma tuşu **dışında** - ekranların geri
	# tuşuyla aynı kural (bkz. World Navigation Rules). Kadro dörde,
	# kontratlar altıya çıkınca döküm görüntü alanını aşıyor.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 4)
	scroll.add_child(_body)

	refresh()

## Ekran gerçek oturumu elde ettiğinde çağırır (bkz. `setup`'ın notu).
func set_session(session: GameSession) -> void:
	_session = session
	refresh()

func refresh() -> void:
	if _session == null or _body == null:
		return
	for child in _body.get_children():
		child.queue_free()
		_body.remove_child(child)

	_build_journey()
	_build_party()
	_build_wagons()
	_build_cargo()
	_build_contracts()
	_build_ledger()

# --- Bölümler ---

func _build_journey() -> void:
	_section(tr("UI_STATUS_JOURNEY"))

	var origin := WorldMapData.get_location_by_id(_session.journey_origin_id)
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	if origin != null and destination != null:
		_line(tr("UI_STATUS_ROUTE") % [origin.location_name, destination.location_name])
	_line(tr("UI_STATUS_DAYS") % [
		_session.journey_total_days - _session.journey_days_remaining,
		_session.journey_total_days,
	])
	_line(tr("UI_STATUS_DAY_COUNT") % (_session.total_days_elapsed + 1))

func _build_party() -> void:
	var party := _session.get_party()
	_section(tr("UI_STATUS_PARTY") % [party.size(), _session.get_party_capacity()])

	for index in party.size():
		var character: CharacterData = party[index]
		# Mevki numarası kadro sırasıdır - savaşta hangi safta duracağı.
		# Yolda okunabilmesi savaşa hazırlanmanın yarısı.
		var row := _line(tr("UI_STATUS_MEMBER") % [
			index + 1, character.character_name, character.level,
			character.current_hp, character.get_max_hp(),
			character.stress, CharacterData.MAX_STRESS,
		])
		if character.is_stressed():
			row.modulate = URGENT_COLOR
		elif float(character.stress) >= float(character.get_stress_resistance()) * STRESS_WARNING_RATIO:
			row.modulate = HURT_COLOR
		elif character.current_hp < character.get_max_hp():
			row.modulate = HURT_COLOR

		var notes := _character_notes(character)
		if not notes.is_empty():
			var note := _line("     %s" % " · ".join(notes))
			note.modulate = NOTE_COLOR

## Huy ve görev: ikisi de yolda sonuç doğuruyor (huy işaret sıklığını,
## görev tüketimi/onarımı/tehlikeyi değiştiriyor), o yüzden ikisi de
## burada okunmalı.
func _character_notes(character: CharacterData) -> Array[String]:
	var notes: Array[String] = []
	if not character.duty_id.is_empty():
		var duty := DutyCatalog.get_duty(character.duty_id)
		if duty != null:
			notes.append(duty.display_name)
	for trait_id in character.trait_ids:
		var trait_resource := TraitCatalog.get_trait(trait_id)
		if trait_resource != null:
			notes.append(trait_resource.display_name)
	return notes

func _build_wagons() -> void:
	var caravan := _session.caravan
	_section(tr("UI_STATUS_WAGONS"))
	var row := _line(tr("UI_STATUS_WAGON_COUNT") % [
		caravan.get_healthy_wagon_count(), caravan.wagon_count, caravan.damaged_wagons
	])
	if caravan.damaged_wagons > 0:
		row.modulate = HURT_COLOR
	_line(tr("UI_STATUS_STAMINA") % [caravan.stamina, CaravanState.MAX_STAMINA])
	_line(tr("UI_STATUS_MORALE") % [caravan.morale, CaravanState.MAX_MORALE])

func _build_cargo() -> void:
	_section(tr("UI_STATUS_CARGO"))

	# Erzak kalan *gün* olarak da yazılıyor: "34 birim" bir sayı, "4 gün
	# yeter" bir karar. Yolun ortasında lazım olan ikincisi.
	var provisions := _session.get_provisions()
	var daily := _session.get_daily_provision_consumption()
	var days_left := provisions / maxi(1, daily)
	var provisions_row := _line(tr("UI_STATUS_PROVISIONS") % [provisions, daily, days_left])
	if days_left < _session.journey_days_remaining:
		provisions_row.modulate = URGENT_COLOR
	elif days_left <= 2:
		provisions_row.modulate = HURT_COLOR

	_line(tr("UI_STATUS_GOLD") % _session.wallet.balance)

	var debt := _session.get_total_debt()
	if debt > 0:
		var debt_row := _line(tr("UI_STATUS_DEBT") % debt)
		debt_row.modulate = URGENT_COLOR

	var entries := _session.get_total_inventory_entries()
	if entries.is_empty():
		_line(tr("UI_STATUS_CARGO_EMPTY")).modulate = NOTE_COLOR
		return
	for entry in entries:
		var row: Dictionary = entry
		var item: Item = row["item"]
		if item == null:
			continue
		_line("     %s" % (tr("UI_STATUS_CARGO_ITEM") % [item.item_name, int(row["quantity"])]))

func _build_contracts() -> void:
	# Playtest'in "Contracts Deliver kısmını bulamadım" şikâyetinin yoldaki
	# yarısı: taşınan kontratın *nereye* gittiği yolda hiç yazmıyordu.
	var names := _session.caravan.merchant_names
	_section(tr("UI_STATUS_CONTRACTS") % names.size())
	if names.is_empty():
		_line(tr("UI_STATUS_NO_CONTRACTS")).modulate = NOTE_COLOR
		return

	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	var destination_name := destination.location_name if destination != null else ""
	for merchant_name in names:
		_line("     %s" % (tr("UI_STATUS_CONTRACT_ROW") % [
			tr(merchant_name), destination_name
		])).modulate = GOOD_COLOR

func _build_ledger() -> void:
	var recent := _session.ledger.recent(LEDGER_LIMIT)
	if recent.is_empty():
		return
	_section(tr("UI_STATUS_LEDGER"))
	for entry in recent:
		var text := CaravanLedger.describe(entry) if not String(entry.get("cause", "")).is_empty() \
			else tr("UI_STATUS_LEDGER_ROW") % [
				int(entry.get("day", 0)), String(entry.get("name", "")),
				CaravanLedger.get_kind_label(String(entry.get("kind", "")))
			]
		var row := _line("     %s" % text)
		row.modulate = NOTE_COLOR

const LEDGER_LIMIT: int = 4

# --- Küçük yapı taşları ---

func _section(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.modulate = SECTION_COLOR
	label.add_theme_font_size_override("font_size", 15)
	_body.add_child(label)

func _line(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(label)
	return label
