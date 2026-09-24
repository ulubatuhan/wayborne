class_name CaravanOverviewPanel
extends CanvasLayer

## Kervan yönetimi için genel bir döküm - kervan burada sembolize
## edilir (her vagon kendi simgesiyle, `CaravanWagonIcon`), altında o
## vagonun yükü/tayfası/hesaplanan hızı; en sağda kervanın **teorik
## hızı** - en yavaş vagonun hızı (bir kervan en yavaş tekerleğinden
## hızlı gidemez, bkz. `GameSession.get_caravan_theoretical_speed()`).
## Altında kadronun tamamı: can, stres ve kervan hakkındaki kısa bir
## "düşünce" satırı - hepsi zaten var olan sayılardan okunuyor, yeni bir
## stat icat edilmiyor (bkz. Faz 13 PR-D'nin kısa savaş yorumlarıyla aynı
## "metin, yeni sistem değil" disiplini).
##
## **Sefer Hazırlığı bölümü moral ve erzağı da gösterir** - stresin kalıcı,
## moralin sefere özgü olduğu ayrım hâlâ geçerli (bkz. Stress Rules), ama
## bu ekran her zaman şehirden açıldığı için gösterilen sayı seferin
## *o anki* morali değil, **çıkış morali**: `GameSession.
## get_departure_morale()`, planlayıcının zaten gösterdiği "bugün yola
## çıksan moral ne olurdu" sorusunun aynı cevabı - iki ekranda iki farklı
## sayı okunmasın diye aynı fonksiyon, aynı çeviri anahtarı
## (`UI_PLANNER_DEPARTURE_MORALE`) kullanılıyor. Kalıcı bir açlık statı
## hiç yok (açlık yalnızca yolda anlık bir olay, bkz. Provision Rules), o
## yüzden "açlık" burada **erzak otonomisi** olarak okunuyor: kervanın
## toplam erzağı günlük tüketime bölününce kaç gün dayanacağı - şehirde
## sorulabilecek gerçek soru zaten bu, "şu an aç mısın" değil "yeterince
## stokladın mı."
##
## `CaravanStatusPanel`'in yol ekranındaki salt-okunur dökümüyle akraba
## ama onun yerine geçmiyor: o bir Tab paneli, bu Kervan Avlusu'ndan
## açılan ayrı bir ekran/mekanik - `MealDistributionPanel`/`WagonPanel`'in
## sahnesiz `CanvasLayer` deseni.

signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const PANEL_WIDTH: float = 620.0
const WAGON_ICON_SIZE: Vector2 = Vector2(64.0, 56.0)
const SECTION_COLOR: Color = Color(0.80, 0.82, 0.76)
const HINT_COLOR: Color = Color(0.70, 0.72, 0.78)
const HURT_COLOR: Color = Color(0.90, 0.55, 0.45)
const URGENT_COLOR: Color = Color(0.90, 0.45, 0.35)

## `CaravanStatusPanel`'inkiyle aynı eşik - kim kırılmaya yakın sorusunun
## cevabı burada da kişinin kendi direncine göre okunuyor.
const STRESS_WARNING_RATIO: float = 0.75
const SATISFIED_COLOR: Color = Color(0.55, 0.80, 0.55)
const SHORTFALL_COLOR: Color = Color(0.90, 0.55, 0.45)

## Erzak otonomisi bu günün altına inince kırmızıya döner - Provision
## Rules'un "correct stocking never starves" sözünün gerektirdiği rezervle
## aynı büyüklük mertebesinde: bir sonraki sefer başlamadan önce planlama
## yapılması gerektiğini erkenden söylemek için.
const PROVISIONS_WARNING_DAYS: int = 5

var _session: GameSession
var _wagon_row: HBoxContainer
var _speed_label: Label
var _morale_label: Label
var _morale_reasons: VBoxContainer
var _provisions_label: Label
var _party_body: VBoxContainer

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
	title.text = tr("UI_CARAVAN_OVERVIEW_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var wagons_title := Label.new()
	wagons_title.text = tr("UI_STATUS_WAGONS")
	wagons_title.modulate = SECTION_COLOR
	vbox.add_child(wagons_title)

	var wagon_scroll := ScrollContainer.new()
	wagon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wagon_scroll.custom_minimum_size = Vector2(0.0, WAGON_ICON_SIZE.y + 70.0)
	vbox.add_child(wagon_scroll)

	_wagon_row = HBoxContainer.new()
	_wagon_row.add_theme_constant_override("separation", 14)
	wagon_scroll.add_child(_wagon_row)

	_speed_label = Label.new()
	_speed_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_speed_label)

	vbox.add_child(HSeparator.new())

	var readiness_title := Label.new()
	readiness_title.text = tr("UI_CARAVAN_OVERVIEW_READINESS_TITLE")
	readiness_title.modulate = SECTION_COLOR
	vbox.add_child(readiness_title)

	_morale_label = Label.new()
	_morale_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_morale_label)

	_morale_reasons = VBoxContainer.new()
	_morale_reasons.add_theme_constant_override("separation", 0)
	vbox.add_child(_morale_reasons)

	_provisions_label = Label.new()
	_provisions_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_provisions_label)

	vbox.add_child(HSeparator.new())

	var party_title := Label.new()
	party_title.modulate = SECTION_COLOR
	party_title.text = tr("UI_STATUS_PARTY") % [session.get_party().size(), session.get_party_capacity()]
	vbox.add_child(party_title)

	var party_scroll := ScrollContainer.new()
	party_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	party_scroll.custom_minimum_size = Vector2(0.0, 180.0)
	vbox.add_child(party_scroll)

	_party_body = VBoxContainer.new()
	_party_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_party_body.add_theme_constant_override("separation", 4)
	party_scroll.add_child(_party_body)

	vbox.add_child(HSeparator.new())

	var close_button := Button.new()
	close_button.text = tr("UI_CRAFT_CLOSE")
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)

	_refresh()

func _refresh() -> void:
	_refresh_wagons()
	_refresh_readiness()
	_refresh_party()

## Çıkış morali (bkz. yukarıdaki sınıf yorumu) - planlayıcının kendi
## `_refresh_departure_morale()`'ıyla aynı hesap ve aynı format, iki
## ekranda iki farklı sayı okunmasın diye.
func _refresh_readiness() -> void:
	var departure := _session.get_departure_morale()
	_morale_label.text = tr("UI_PLANNER_DEPARTURE_MORALE") % [departure, CaravanState.MAX_MORALE]

	for child in _morale_reasons.get_children():
		_morale_reasons.remove_child(child)
		child.queue_free()

	var breakdown := _session.get_departure_morale_breakdown()
	if breakdown.is_empty():
		var good_day := Label.new()
		good_day.text = tr("UI_MORALE_GOOD_DAY")
		good_day.modulate = HINT_COLOR
		good_day.add_theme_font_size_override("font_size", 11)
		_morale_reasons.add_child(good_day)
	else:
		for entry in breakdown:
			var line := Label.new()
			line.text = "  %s %+d" % [tr(String(entry["key"])), int(entry["amount"])]
			line.add_theme_font_size_override("font_size", 11)
			line.modulate = SATISFIED_COLOR if int(entry["amount"]) > 0 else SHORTFALL_COLOR
			_morale_reasons.add_child(line)

	var total_provisions := _session.get_total_quantity(GameSession.PROVISIONS_ITEM_ID)
	var daily := maxi(1, _session.get_daily_provision_consumption())
	var autonomy_days := int(floor(float(total_provisions) / float(daily)))
	_provisions_label.text = tr("UI_CARAVAN_OVERVIEW_PROVISIONS") % [total_provisions, autonomy_days]
	_provisions_label.modulate = SHORTFALL_COLOR if autonomy_days < PROVISIONS_WARNING_DAYS else HINT_COLOR

func _refresh_wagons() -> void:
	for child in _wagon_row.get_children():
		_wagon_row.remove_child(child)
		child.queue_free()

	for index in _session.wagon_inventories.size():
		_wagon_row.add_child(_build_wagon_column(index))

	var speed_percent := int(round(_session.get_caravan_theoretical_speed() * 100.0))
	_speed_label.text = tr("UI_CARAVAN_OVERVIEW_SPEED") % speed_percent

func _build_wagon_column(wagon_index: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(WAGON_ICON_SIZE.x + 16.0, 0.0)
	column.add_theme_constant_override("separation", 2)

	var icon := CaravanWagonIcon.new()
	icon.custom_minimum_size = WAGON_ICON_SIZE
	var wagon_inventory := _session.wagon_inventories[wagon_index]
	var weight := wagon_inventory.get_total_weight()
	var capacity := GameSession.CARGO_PER_WAGON
	icon.setup(weight / maxf(1.0, capacity))
	column.add_child(icon)

	var weight_label := Label.new()
	weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weight_label.add_theme_font_size_override("font_size", 11)
	weight_label.text = tr("UI_CARAVAN_OVERVIEW_WAGON_WEIGHT") % [int(weight), int(capacity)]
	column.add_child(weight_label)

	var crew_label := Label.new()
	crew_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crew_label.add_theme_font_size_override("font_size", 11)
	crew_label.modulate = HINT_COLOR
	crew_label.text = tr("UI_CARAVAN_OVERVIEW_WAGON_CREW") % GameSession.PEOPLE_PER_WAGON
	column.add_child(crew_label)

	# Tayfanın adları: vagon kaybedilirse defterde bu iki isim çizilir.
	var names_label := Label.new()
	names_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	names_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	names_label.add_theme_font_size_override("font_size", 11)
	names_label.modulate = HINT_COLOR
	names_label.text = ", ".join(_session.get_wagon_crew_names(wagon_index))
	column.add_child(names_label)

	var speed_label := Label.new()
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speed_label.add_theme_font_size_override("font_size", 11)
	speed_label.modulate = HINT_COLOR
	var speed_percent := int(round(_session.get_wagon_speed_factor(wagon_index) * 100.0))
	speed_label.text = tr("UI_CARAVAN_OVERVIEW_WAGON_SPEED") % speed_percent
	column.add_child(speed_label)

	return column

func _refresh_party() -> void:
	for child in _party_body.get_children():
		_party_body.remove_child(child)
		child.queue_free()

	var party := _session.get_party()
	for index in party.size():
		var character: CharacterData = party[index]
		# Madalyon ve kişinin kenar notları (bkz. WaybookIcons): kırgınlık
		# bir sayı olarak değil, kişinin yanına düşülmüş bir işaret olarak.
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		line.add_child(PortraitCameo.new().setup(character, PARTY_CAMEO_HEIGHT))
		var text_column := VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text_column)
		_party_body.add_child(line)
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.text = tr("UI_STATUS_MEMBER") % [
			index + 1, character.character_name, character.level,
			character.current_hp, character.get_max_hp(),
			character.stress, CharacterData.MAX_STRESS,
		]
		if character.is_stressed():
			row.modulate = URGENT_COLOR
		elif float(character.stress) >= float(character.get_stress_resistance()) * STRESS_WARNING_RATIO:
			row.modulate = HURT_COLOR
		elif character.current_hp < character.get_max_hp():
			row.modulate = HURT_COLOR
		text_column.add_child(row)

		var thought := Label.new()
		thought.text = _thought_for(character)
		thought.modulate = HINT_COLOR
		thought.autowrap_mode = TextServer.AUTOWRAP_WORD
		text_column.add_child(thought)

		var marks := HBoxContainer.new()
		marks.add_theme_constant_override("separation", 10)
		marks.add_child(WaybookIcons.grievance_row(character, PARTY_MARK_SIZE))
		marks.add_child(WaybookIcons.hunger_tally(character, PARTY_MARK_SIZE))
		text_column.add_child(marks)

## Kervan hakkında kısa bir düşünce - yeni bir stat değil, var olan
## stres/can okunarak seçilen bir satır (bkz. Faz 13 PR-D'nin kısa savaş
## yorumları, aynı "metin, yeni sistem değil" disiplini).
## Kırgınlık, anlık halden önce gelir: bir kişinin aklında kalan, o gün
## nasıl hissettiğinden daha çok şey söyler (bkz. CharacterData.grievances).
const GRIEVANCE_THOUGHT_THRESHOLD: int = 2
const PARTY_CAMEO_HEIGHT: float = 56.0
const PARTY_MARK_SIZE: float = 18.0
const GRIEVANCE_THOUGHT_KEYS: Dictionary = {
	CharacterData.GRIEVANCE_UNFED: "UI_THOUGHT_UNFED",
	CharacterData.GRIEVANCE_BENCHED: "UI_THOUGHT_BENCHED",
	CharacterData.GRIEVANCE_WITNESSED_DEATH: "UI_THOUGHT_WITNESSED_DEATH",
	CharacterData.GRIEVANCE_PASSED_OVER: "UI_THOUGHT_PASSED_OVER",
}

func _thought_for(character: CharacterData) -> String:
	return thought_for(character)

static func thought_for(character: CharacterData) -> String:
	var top := character.get_top_grievance()
	if not top.is_empty() and (
		character.get_grievance(top) >= GRIEVANCE_THOUGHT_THRESHOLD
		or top == CharacterData.GRIEVANCE_PASSED_OVER
	):
		return String(TranslationServer.translate(String(GRIEVANCE_THOUGHT_KEYS[top]))) % character.character_name
	if character.is_stressed():
		return String(TranslationServer.translate("UI_CARAVAN_OVERVIEW_THOUGHT_BROKEN"))
	if float(character.stress) >= float(character.get_stress_resistance()) * STRESS_WARNING_RATIO:
		return String(TranslationServer.translate("UI_CARAVAN_OVERVIEW_THOUGHT_TENSE"))
	if character.current_hp < character.get_max_hp() / 2:
		return String(TranslationServer.translate("UI_CARAVAN_OVERVIEW_THOUGHT_WOUNDED"))
	return String(TranslationServer.translate("UI_CARAVAN_OVERVIEW_THOUGHT_FINE"))

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
