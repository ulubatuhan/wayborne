class_name CaravanOverviewPanel
extends CanvasLayer

## Kervan yönetimi için genel bir döküm - kervan burada sembolize
## edilir (her vagon kendi simgesiyle, `CaravanWagonIcon`), altında o
## vagonun yükü/tayfası/hesaplanan hızı; en sağda kervanın **teorik
## hızı** - en yavaş vagonun hızı (bir kervan en yavaş tekerleğinden
## hızlı gidemez, bkz. `GameSession.get_caravan_theoretical_speed()`).
## Altında kadronun tamamı: can, stres ve kervan hakkındaki kısa bir
## "düşünce" satırı - hepsi zaten var olan sayılardan okunuyor, yeni bir
## stat icat edilmiyor (bkz. Stress Rules'un stresin kalıcı, moralin
## sefere özgü olduğu ayrımı - bu ekran şehirden de açıldığı için yalnızca
## kalıcı olan stres gösteriliyor, moral değil).
##
## `CaravanStatusPanel`'in yol ekranındaki salt-okunur dökümüyle akraba
## ama onun yerine geçmiyor: o bir Tab paneli, bu Kervan Avlusu'ndan
## açılan ayrı bir ekran/mekanik - `MealDistributionPanel`/`WagonPanel`'in
## sahnesiz `CanvasLayer` deseni.

signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const PANEL_BACKGROUND: Color = Color(0.09, 0.08, 0.07)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.28)
const PANEL_WIDTH: float = 620.0
const WAGON_ICON_SIZE: Vector2 = Vector2(64.0, 56.0)
const SECTION_COLOR: Color = Color(0.80, 0.82, 0.76)
const HINT_COLOR: Color = Color(0.70, 0.72, 0.78)
const HURT_COLOR: Color = Color(0.90, 0.55, 0.45)
const URGENT_COLOR: Color = Color(0.90, 0.45, 0.35)

## `CaravanStatusPanel`'inkiyle aynı eşik - kim kırılmaya yakın sorusunun
## cevabı burada da kişinin kendi direncine göre okunuyor.
const STRESS_WARNING_RATIO: float = 0.75

var _session: GameSession
var _wagon_row: HBoxContainer
var _speed_label: Label
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
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
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
	_refresh_party()

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
		_party_body.add_child(row)

		var thought := Label.new()
		thought.text = "     %s" % _thought_for(character)
		thought.modulate = HINT_COLOR
		thought.autowrap_mode = TextServer.AUTOWRAP_WORD
		_party_body.add_child(thought)

## Kervan hakkında kısa bir düşünce - yeni bir stat değil, var olan
## stres/can okunarak seçilen bir satır (bkz. Faz 13 PR-D'nin kısa savaş
## yorumları, aynı "metin, yeni sistem değil" disiplini).
func _thought_for(character: CharacterData) -> String:
	if character.is_stressed():
		return tr("UI_CARAVAN_OVERVIEW_THOUGHT_BROKEN")
	if float(character.stress) >= float(character.get_stress_resistance()) * STRESS_WARNING_RATIO:
		return tr("UI_CARAVAN_OVERVIEW_THOUGHT_TENSE")
	if character.current_hp < character.get_max_hp() / 2:
		return tr("UI_CARAVAN_OVERVIEW_THOUGHT_WOUNDED")
	return tr("UI_CARAVAN_OVERVIEW_THOUGHT_FINE")

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
