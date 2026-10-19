class_name RoadControlPanel
extends PanelContainer

## Yol ekranının alt kontrol paneli (görevler N16-N23, §14 P18). Kullanıcı
## kararı: sahnenin üstündeki boş gökyüzü şeridi kalkar, sahne yukarı kayar,
## altta açılan yerde sekmeli bir panel durur (referans oyunların ve Kenshi'nin
## alt paneli gibi). Panel karar vermez, okur: kararlar emir paneli, olay
## kartı ve sofradadır.
##
## Sekmeler: Kadro (kişi kartları), Durum (göstergeler ve sayılar, sorunlar
## kelimeyle), Yük (vagonlar, erzak, kontratlar), Harita (küçük harita, kervan
## yolun neresinde), Defter (son olaylar, açık işaretler, kalıcı emirler).
## Sayı göstergenin yanında kalır (sayısal şeffaflık); stres ekran efektiyle
## değil kelimeyle ve renkle.

signal map_requested

const TAB_KEYS: Array[String] = [
	"UI_PANEL_TAB_PARTY", "UI_PANEL_TAB_STATUS", "UI_PANEL_TAB_CARGO", "UI_PANEL_TAB_MAP", "UI_PANEL_TAB_LOG",
]
const TAB_PARTY: int = 0
const TAB_STATUS: int = 1
const TAB_CARGO: int = 2
const TAB_MAP: int = 3
const TAB_LOG: int = 4
const REFRESH_SECONDS: float = 0.5
const CARD_SIZE: Vector2 = Vector2(290, 0)
const SUMMARY_WIDTH: float = 340.0
const GOODS_COLUMNS: int = 3
const GOODS_CELL: Vector2 = Vector2(210, 0)
## Küçük haritanın yakınlığı: panel alçak, kervanın çevresi okunmalı.
const MINI_MAP_ZOOM: float = 0.2
const LOG_LINES: int = 7

var _session: GameSession
## Yol ekranının o anki hâli (saat, hava, arazi, tempo, işaretler, günlük,
## yolun harita çizgisi ve ilerleme). Çağıran bir sözlük döndüren Callable verir.
var _provider: Callable
var _gauges: Control
var _tab_buttons: Array[Button] = []
var _pages: Array[Control] = []
var _active: int = TAB_PARTY
var _timer: float = 0.0
var _map_view: WorldMapView
var _tab_box: HBoxContainer
var _stack: Control
## Panelin sağında hep açık küçük harita (görev 9.9, kullanıcı notu: "harita ve
## envanter ile beraber görmeliyim"): sekme değişse de kervanın yeri görünür.
var _side_map: WorldMapView
const SIDE_MAP_WIDTH: float = 430.0
const SIDE_MAP_ZOOM: float = 0.16

func setup(session: GameSession, provider: Callable, gauges: Control) -> RoadControlPanel:
	_session = session
	_provider = provider
	_gauges = gauges
	add_theme_stylebox_override("panel", _panel_box())
	mouse_filter = Control.MOUSE_FILTER_STOP
	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	add_child(outer)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(col)
	outer.add_child(_build_side_map())
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	col.add_child(tabs)
	_tab_box = tabs
	for index in TAB_KEYS.size():
		var button := Button.new()
		button.text = tr(TAB_KEYS[index])
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_tab.bind(index))
		tabs.add_child(button)
		_tab_buttons.append(button)
	var stack := Control.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.clip_contents = true
	col.add_child(stack)
	_stack = stack
	for index in TAB_KEYS.size():
		var page: Control
		if index == TAB_MAP:
			page = _build_map_page()
		elif index == TAB_STATUS:
			page = _build_status_page()
		else:
			var scroll := ScrollContainer.new()
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if index == TAB_PARTY else ScrollContainer.SCROLL_MODE_DISABLED
			page = scroll
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		stack.add_child(page)
		_pages.append(page)
	stack.resized.connect(func():
		for p in _pages:
			p.size = stack.size)
	select_tab(TAB_PARTY)
	return self

func _build_side_map() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(SIDE_MAP_WIDTH, 0)
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	_side_map = WorldMapView.new()
	holder.add_child(_side_map)
	# Her boyut değişiminde kervana yeniden odaklanır: ilk boyut geçici olabilir.
	holder.resized.connect(func():
		_side_map.size = holder.size
		if holder.size.x > 10.0 and holder.size.y > 10.0:
			_side_map.focus_caravan(SIDE_MAP_ZOOM))
	# Küçük haritaya tıklamak büyük haritayı açar.
	holder.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			map_requested.emit())
	holder.tooltip_text = tr("UI_PANEL_MAP_OPEN")
	return holder

func set_session(session: GameSession) -> void:
	_session = session
	refresh()

## Yolun dışında (şehir mekânları) panel kendi sekmesini ekler: içerik çağıranın,
## panel yalnızca sekmeyi ve sayfayı taşır (görev 9.4, taverna).
func add_tab(title: String, page: Control) -> int:
	var index := _pages.size()
	var button := Button.new()
	button.text = title
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(select_tab.bind(index))
	_tab_box.add_child(button)
	_tab_buttons.append(button)
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.size = _stack.size
	_stack.add_child(page)
	_pages.append(page)
	page.visible = false
	return index

## Yola özgü bir sekme (durum, defter) şehirde gizlenir.
func hide_tab(index: int) -> void:
	if index >= 0 and index < _tab_buttons.size():
		_tab_buttons[index].visible = false

func select_tab(index: int) -> void:
	_active = clampi(index, 0, _pages.size() - 1)
	for i in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == _active)
		_pages[i].visible = i == _active
	refresh()

func get_active_tab() -> int:
	return _active

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= REFRESH_SECONDS:
		_timer = 0.0
		refresh()

func refresh() -> void:
	if _session == null or _pages.is_empty():
		return
	var state: Dictionary = _provider.call() if _provider.is_valid() else {}
	_refresh_map_view(_side_map, state)
	match _active:
		TAB_PARTY:
			_fill(_pages[TAB_PARTY], _party_content(state))
		TAB_STATUS:
			_refresh_status(state)
		TAB_CARGO:
			_fill(_pages[TAB_CARGO], _cargo_content())
		TAB_MAP:
			_refresh_map(state)
		TAB_LOG:
			_fill(_pages[TAB_LOG], _log_content(state))

func _fill(scroll: Control, content: Control) -> void:
	NodeUtil.clear_children(scroll)
	# ScrollContainer çocuğu yalnızca EXPAND_FILL ise kendi genişliğine yayar;
	# yoksa en küçük boyutunda kalır ve kırılan etiketler harf harf dizilir.
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

# --- Kadro -------------------------------------------------------------------

func _party_content(state: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var party := _session.get_party()
	for index in party.size():
		row.add_child(_card(party[index], index))
	row.add_child(VSeparator.new())
	row.add_child(_caravan_summary(state))
	row.add_child(VSeparator.new())
	row.add_child(_cargo_summary())
	return row

## Yükün özeti: vagon başına ağırlık çubuğu ve en çok taşınan mallar ikonla.
func _cargo_summary() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(300, 0)
	col.add_theme_constant_override("separation", 3)
	col.add_child(_heading(tr("UI_PANEL_TAB_CARGO")))
	for index in _session.wagon_inventories.size():
		var inv: Inventory = _session.wagon_inventories[index]
		col.add_child(_bar(tr("UI_PANEL_WAGON_N") % (index + 1), int(round(inv.get_total_weight())), int(round(inv.weight_limit)), ArtPalette.GRIM_AMBER))
	var goods := GridContainer.new()
	goods.columns = 4
	goods.add_theme_constant_override("h_separation", 14)
	var shown := 0
	for entry in _session.get_total_inventory_entries():
		var item: Item = (entry as Dictionary)["item"]
		if item == null or shown >= 8:
			continue
		var line := WaybookTheme.item_line(item.item_id, "×%d" % int(entry["quantity"]), 22)
		line.custom_minimum_size = Vector2(64, 0)
		line.tooltip_text = item.item_name
		goods.add_child(line)
		shown += 1
	if shown == 0:
		col.add_child(_dim_line(tr("UI_PANEL_NO_GOODS")))
	else:
		col.add_child(goods)
	return col

## Kadronun yanında kervanın nabzı: moral, takat, tehlike, erzak ve tayfa.
## Kişiler soldaki kartlarda; bu sütun bütün kervanı söyler.
func _caravan_summary(state: Dictionary) -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(SUMMARY_WIDTH, 0)
	col.add_theme_constant_override("separation", 3)
	col.add_child(_heading(tr("UI_PANEL_CARAVAN")))
	col.add_child(_bar(tr("UI_PANEL_MORALE"), _session.caravan.morale, CaravanState.MAX_MORALE, ArtPalette.UI_GAUGE_MORALE))
	# Kervanın takati en yorgun kişiye bağlı (Y-F01): bağlayan varsa adıyla.
	col.add_child(_bar(tr("UI_PANEL_STAMINA"), _session.get_caravan_stamina(), CaravanState.MAX_STAMINA, ArtPalette.UI_GAUGE_STAMINA))
	var binder := _session.get_stamina_binder()
	if binder != null:
		var bound := _dim_line(tr("UI_FATIGUE_BINDS") % [binder.character_name, binder.fatigue])
		bound.add_theme_font_size_override("font_size", 14)
		bound.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bound.tooltip_text = bound.text
		bound.mouse_filter = Control.MOUSE_FILTER_PASS
		col.add_child(bound)
	col.add_child(_bar(tr("UI_PANEL_DANGER"), int(round(float(state.get("danger", _session.danger_level)) * 100.0)), 100, ArtPalette.BLOOD))
	var daily := maxi(1, _session.get_daily_provision_consumption())
	col.add_child(_fact_line(tr("UI_PANEL_PROVISIONS"), tr("UI_PANEL_PROVISIONS_VALUE") % [_session.get_provisions(), _session.get_provisions() / daily]))
	var crew := Label.new()
	crew.text = tr("UI_PANEL_CREW") % [_session.owned_wagon_count * GameSession.PEOPLE_PER_WAGON, _session.owned_wagon_count]
	crew.add_theme_font_size_override("font_size", 14)
	crew.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	col.add_child(crew)
	return col

func _fact_line(key_text: String, value_text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var key := Label.new()
	key.text = key_text
	key.custom_minimum_size = Vector2(62, 0)
	key.add_theme_font_size_override("font_size", 14)
	key.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	row.add_child(key)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	row.add_child(value)
	return row

func _card(character: CharacterData, index: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.7)
	box.border_color = Color(ArtPalette.GRIM_AMBER, 0.6 if character.is_player else 0.25)
	box.set_border_width_all(2 if character.is_player else 1)
	box.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	card.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	if WaybookIcons.CLASS_EMBLEMS.has(character.class_id):
		head.add_child(WaybookIcons.picture(WaybookIcons.CLASS_EMBLEMS, character.class_id, 26))
	# Açlık çetelesi başlıkta değil: kartın durum satırı "N gecedir aç" diyor,
	# başlıktaki çubuk ismi kesiyordu (9.6/9.7 denetimi).
	var name := Label.new()
	name.text = "%d. %s" % [index + 1, character.character_name]
	name.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name)
	# Kırgınlıklar kartın kenarında (Y-F01, karakter ekranındaki işaretlerle aynı).
	if character.get_grievance_total() > 0:
		head.add_child(WaybookIcons.grievance_row(character, 18))
	var cls := character.get_character_class()
	var sub := Label.new()
	sub.text = tr("UI_PANEL_CLASS_LEVEL") % [cls.display_name if cls != null else "", character.level]
	if character.is_player:
		sub.text = tr("UI_PANEL_LEADER") + " · " + sub.text
	sub.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	sub.add_theme_font_size_override("font_size", 14)
	col.add_child(sub)
	col.add_child(_bar(tr("UI_PANEL_HP"), character.current_hp, character.get_max_hp(), ArtPalette.BLOOD))
	col.add_child(_bar(tr("UI_PANEL_STRESS"), character.stress, CharacterData.MAX_STRESS, ArtPalette.UI_GAUGE_STRESS))
	# Yorgunluk (Y-F01): bedenin hâli, stresin altında; sayı yanında.
	col.add_child(_bar(tr("UI_PANEL_FATIGUE"), character.fatigue, CharacterData.MAX_FATIGUE, ArtPalette.UI_GAUGE_STAMINA))
	var notes: Array[String] = [tr(character.get_condition_label_key())]
	if character.is_stressed():
		notes.append(tr("UI_PANEL_BROKEN"))
	var weary := character.get_fatigue_combat_penalty()
	if weary > 0:
		notes.append(tr("UI_FATIGUE_COMBAT_PENALTY") % weary)
	if character.consecutive_hungry_days > 0:
		notes.append(tr("UI_PANEL_HUNGRY") % character.consecutive_hungry_days)
	if not character.duty_id.is_empty():
		var duty := DutyCatalog.get_duty(character.duty_id)
		if duty != null:
			notes.append(duty.display_name)
	var note := Label.new()
	note.text = " · ".join(notes)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", ArtPalette.GRIM_CRIMSON.lightened(0.3) if character.is_stressed() or character.consecutive_hungry_days > 0 or weary > 0 else ArtPalette.GRIM_PARCHMENT_DIM)
	col.add_child(note)
	card.tooltip_text = _traits_text(character)
	return card

func _traits_text(character: CharacterData) -> String:
	var names: Array[String] = []
	for trait_id in character.trait_ids:
		var t := TraitCatalog.get_trait(trait_id)
		if t != null:
			names.append(t.display_name)
	return ", ".join(names)

## Etiket, ince çubuk ve sayı (sayı göstergenin yanında kalır).
func _bar(label_text: String, value: int, max_value: int, colour: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(62, 0)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(1, max_value)
	bar.value = clampi(value, 0, max_value)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(110, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var number := Label.new()
	number.text = "%d/%d" % [value, max_value]
	number.add_theme_font_size_override("font_size", 14)
	number.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	row.add_child(number)
	return row

# --- Durum -------------------------------------------------------------------

var _status_facts: GridContainer
var _status_problems: VBoxContainer

func _build_status_page() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	if _gauges != null:
		if _gauges.get_parent() != null:
			_gauges.get_parent().remove_child(_gauges)
		_gauges.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(_gauges)
	_status_facts = GridContainer.new()
	_status_facts.columns = 2
	_status_facts.add_theme_constant_override("h_separation", 14)
	_status_facts.add_theme_constant_override("v_separation", 2)
	row.add_child(_status_facts)
	_status_problems = VBoxContainer.new()
	_status_problems.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_status_problems)
	return row

func _refresh_status(state: Dictionary) -> void:
	NodeUtil.clear_children(_status_facts)
	NodeUtil.clear_children(_status_problems)
	var provisions := _session.get_provisions()
	var daily := maxi(1, _session.get_daily_provision_consumption())
	var days_left := provisions / daily
	var facts := [
		["UI_PANEL_DAY", "%s" % String(state.get("clock", ""))],
		["UI_PANEL_ROUTE", tr("UI_PANEL_ROUTE_VALUE") % [String(state.get("destination", "")), int(state.get("days_left", _session.journey_days_remaining))]],
		["UI_PANEL_WEATHER", String(state.get("weather", ""))],
		["UI_PANEL_TERRAIN", String(state.get("terrain", ""))],
		["UI_PANEL_PACE", String(state.get("pace", ""))],
		["UI_PANEL_PROVISIONS", tr("UI_PANEL_PROVISIONS_VALUE") % [provisions, days_left]],
		["UI_PANEL_GOLD", "%d" % _session.wallet.balance],
		["UI_PANEL_DEBT", "%d" % _session.get_total_debt()],
		# N23: üst şeridin sayı satırı kalktı; söylediği her şey burada.
		["UI_PANEL_REPUTATION", "%d" % _session.reputation],
		["UI_PANEL_WAGONS", tr("UI_PANEL_WAGONS_VALUE") % [_session.caravan.wagon_count, _session.caravan.damaged_wagons]],
		["UI_PANEL_MERCHANTS", "%d" % _session.caravan.merchant_names.size()],
		["UI_PANEL_DOCUMENTS", "%d" % _session.caravan.documents],
	]
	for fact in facts:
		var key := Label.new()
		key.text = tr(String(fact[0]))
		key.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
		_status_facts.add_child(key)
		var value := Label.new()
		value.text = String(fact[1])
		value.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
		_status_facts.add_child(value)
	var title := Label.new()
	title.text = tr("UI_PANEL_PROBLEMS")
	title.add_theme_color_override("font_color", ArtPalette.GRIM_AMBER)
	_status_problems.add_child(title)
	var problems := problems_for(_session, state)
	if problems.is_empty():
		problems.append(tr("UI_PANEL_NO_PROBLEMS"))
	for text in problems:
		var line := Label.new()
		line.text = "· " + text
		line.autowrap_mode = TextServer.AUTOWRAP_WORD
		line.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
		_status_problems.add_child(line)

## Sorunlar kelimeyle (kullanıcı kuralı: oyuncuya gerekçe sayıyla değil
## sözle). Saf: test aynı listeyi okur.
static func problems_for(session: GameSession, state: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var daily := maxi(1, session.get_daily_provision_consumption())
	var days_left := session.get_provisions() / daily
	if days_left < session.journey_days_remaining:
		out.append(TranslationServer.translate("UI_PANEL_PROBLEM_PROVISIONS") % [days_left, session.journey_days_remaining])
	var hungry := 0
	var hurt := 0
	var broken := 0
	for character in session.get_party():
		if character.consecutive_hungry_days > 0:
			hungry += 1
		if character.current_hp * 2 < character.get_max_hp():
			hurt += 1
		if character.is_stressed():
			broken += 1
	if hungry > 0:
		out.append(TranslationServer.translate("UI_PANEL_PROBLEM_HUNGRY") % hungry)
	if hurt > 0:
		out.append(TranslationServer.translate("UI_PANEL_PROBLEM_HURT") % hurt)
	if broken > 0:
		out.append(TranslationServer.translate("UI_PANEL_PROBLEM_BROKEN") % broken)
	if session.caravan.damaged_wagons > 0:
		out.append(TranslationServer.translate("UI_PANEL_PROBLEM_WAGONS") % session.caravan.damaged_wagons)
	if session.get_caravan_stamina() <= 20:
		out.append(TranslationServer.translate("UI_PANEL_PROBLEM_STAMINA"))
	for signal_text in state.get("signals", []):
		out.append(String(signal_text))
	return out

# --- Yük ---------------------------------------------------------------------

func _cargo_content() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var wagons := VBoxContainer.new()
	wagons.custom_minimum_size = Vector2(260, 0)
	wagons.add_child(_heading(tr("UI_PANEL_WAGONS")))
	for index in _session.wagon_inventories.size():
		var inv: Inventory = _session.wagon_inventories[index]
		wagons.add_child(_bar(tr("UI_PANEL_WAGON_N") % (index + 1), int(round(inv.get_total_weight())), int(round(inv.weight_limit)), ArtPalette.GRIM_AMBER))
	row.add_child(wagons)
	var goods := VBoxContainer.new()
	goods.add_child(_heading(tr("UI_PANEL_GOODS")))
	var grid := GridContainer.new()
	grid.columns = GOODS_COLUMNS
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 2)
	goods.add_child(grid)
	var entries := _session.get_total_inventory_entries()
	for entry in entries:
		var item: Item = (entry as Dictionary)["item"]
		if item == null:
			continue
		var line := WaybookTheme.item_line(item.item_id, "%s × %d" % [item.item_name, int(entry["quantity"])], 22)
		line.custom_minimum_size = GOODS_CELL
		grid.add_child(line)
	if grid.get_child_count() == 0:
		goods.add_child(_dim_line(tr("UI_PANEL_NO_GOODS")))
	row.add_child(goods)
	var contracts := VBoxContainer.new()
	contracts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contracts.add_child(_heading(tr("UI_PANEL_CONTRACTS") % _session.caravan.merchant_names.size()))
	var destination := WorldMapData.get_location_by_id(_session.journey_destination_id)
	for merchant_name in _session.caravan.merchant_names:
		var line := Label.new()
		line.text = tr("UI_STATUS_CONTRACT_ROW") % [tr(merchant_name), destination.location_name if destination != null else ""]
		line.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
		contracts.add_child(line)
	if _session.caravan.merchant_names.is_empty():
		contracts.add_child(_dim_line(tr("UI_PANEL_NO_CONTRACTS")))
	row.add_child(contracts)
	return row

func _dim_line(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	return label

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", ArtPalette.GRIM_AMBER)
	return label

# --- Harita ------------------------------------------------------------------

func _build_map_page() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	row.add_child(holder)
	_map_view = WorldMapView.new()
	holder.add_child(_map_view)
	holder.resized.connect(func():
		_map_view.size = holder.size
		if not _map_view.has_meta("framed") and holder.size.x > 10.0:
			_map_view.set_meta("framed", true)
			_map_view.focus_caravan(MINI_MAP_ZOOM))
	var side := VBoxContainer.new()
	row.add_child(side)
	var open := Button.new()
	open.text = tr("UI_PANEL_MAP_OPEN")
	open.pressed.connect(func(): map_requested.emit())
	side.add_child(open)
	var go := Button.new()
	go.text = tr("UI_MAP_GO_CARAVAN")
	go.pressed.connect(func(): _map_view.focus_caravan(MINI_MAP_ZOOM))
	side.add_child(go)
	return row

func _refresh_map(state: Dictionary) -> void:
	_refresh_map_view(_map_view, state)

func _refresh_map_view(view: WorldMapView, state: Dictionary) -> void:
	if view == null:
		return
	view.current_location_id = String(state.get("origin", _session.journey_origin_id))
	view.focused_location_id = _session.journey_destination_id
	view.journey_path = state.get("path", PackedVector2Array())
	view.journey_progress = float(state.get("progress", 0.0))
	view.hour = float(state.get("hour", 12.0))
	view.trail = _session.map_trail
	view.camps = _session.journey_camps
	view.graves = _session.map_graves()

# --- Defter ------------------------------------------------------------------

func _log_content(state: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var log_col := VBoxContainer.new()
	log_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_col.add_child(_heading(tr("UI_PANEL_RECENT")))
	var lines: Array = state.get("log", [])
	for i in range(maxi(0, lines.size() - LOG_LINES), lines.size()):
		var line := Label.new()
		line.text = String(lines[i])
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
		log_col.add_child(line)
	row.add_child(log_col)
	var orders := VBoxContainer.new()
	orders.add_child(_heading(tr("UI_PANEL_ORDERS")))
	for text in state.get("orders", []):
		var line := Label.new()
		line.text = String(text)
		line.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
		orders.add_child(line)
	row.add_child(orders)
	return row

func _panel_box() -> StyleBox:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.97)
	box.border_color = Color(ArtPalette.GRIM_AMBER, 0.45)
	box.border_width_top = 2
	box.set_content_margin_all(10)
	box.content_margin_top = 8
	return box
