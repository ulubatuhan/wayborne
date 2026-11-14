class_name DungeonMapPanel
extends CanvasLayer

## Galeri haritası (Y-A07 derinleşme): kadro bir odaya varınca ve kartı
## yaşanınca bu açılır. Seviyenin odaları ve koridorları (`DungeonMapView`),
## ışık, sırt yükü ve kervanın beklediği; altta "aşağı in" ve "çıkışa yönel".
##
## Panel kararı kendisi uygulamaz: bir `EventChoice` (DungeonMap'in kurduğu)
## gönderir ve yol ekranı onu kartların seçimi gibi `EventResolver`'dan
## geçirir. Böylece koridorun stresi, günü ve pususu kartlarla aynı dilde.
##
## Ekranın altına oturur, üstü boş: arkada seviyenin bölge resmi ve kadro
## görünür (`DungeonView`). Kök tıklamayı tutar, altındaki yol ekranına geçmez.

signal acted(choice)  # EventChoice

const PANEL_WIDTH: float = 1040.0
const MARGIN_BOTTOM: float = 28.0

var _session: GameSession
var _view: DungeonMapView
var _descend: Button

func setup(session: GameSession) -> void:
	_session = session
	layer = 64
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dock := VBoxContainer.new()
	dock.set_anchors_preset(Control.PRESET_FULL_RECT)
	dock.alignment = BoxContainer.ALIGNMENT_END
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_theme_constant_override("separation", 0)
	root.add_child(dock)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(row)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, MARGIN_BOTTOM)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.add_child(spacer)

	var card := PanelContainer.new()
	card.theme_type_variation = WaybookTheme.SEAL_PANEL
	card.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	row.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	_build_header(column)
	_view = DungeonMapView.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.room_pressed.connect(_on_room_pressed)
	column.add_child(_view)
	_build_footer(column)
	_refresh()

func _build_header(column: VBoxContainer) -> void:
	var run := _session.dungeon_run
	var id := String(run["id"])
	var level := int(run["depth"])
	var title := Label.new()
	title.text = "%s · %s" % [tr(DungeonCatalog.name_key(id)),
		tr("UI_DNG_LEVEL") % [level, DungeonCatalog.max_depth(id)]]
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	column.add_child(title)
	var zone := Label.new()
	zone.text = tr(zone_key(DungeonMap.zone(id, level)))
	zone.modulate = ArtPalette.UI_TEXT_DIM
	column.add_child(zone)
	var status := Label.new()
	status.text = "%s   ·   %s   ·   %s" % [light_line(_session),
		tr("UI_DNG_BAG") % [_session.get_party().size() * DungeonCatalog.BAG_PER_PERSON - _session.dungeon_bag_free(),
			_session.get_party().size() * DungeonCatalog.BAG_PER_PERSON],
		tr("UI_DNG_WAIT")]
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status)
	column.add_child(HSeparator.new())

func _build_footer(column: VBoxContainer) -> void:
	var hint := Label.new()
	hint.text = tr("UI_DNG_HINT")
	hint.modulate = ArtPalette.UI_TEXT_DIM
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	_descend = Button.new()
	_descend.text = tr("UI_DNG_DESCEND")
	_descend.theme_type_variation = WaybookTheme.PRIMARY_BUTTON
	_descend.pressed.connect(func(): acted.emit(DungeonMap.descend_choice(_session)))
	buttons.add_child(_descend)
	var leave := Button.new()
	leave.text = tr("UI_DNG_LEAVE")
	leave.pressed.connect(func(): acted.emit(DungeonMap.leave_choice()))
	buttons.add_child(leave)

func _refresh() -> void:
	var run := _session.dungeon_run
	var level := DungeonMap.level_of(run)
	var here := int(run["room"])
	_view.set_level(level, here, DungeonMap.neighbours(level, here))
	var on_stair := String(DungeonMap.room(level, here).get("type", "")) == DungeonMap.STAIR
	_descend.visible = on_stair

## Karar paneli: Esc yutulur (kart gibi), altındaki yol ekranı kapanmaz.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

func _on_room_pressed(room_id: int) -> void:
	acted.emit(DungeonMap.move_choice(_session, room_id))

## Işığın durumu, sözle (Words first, Y-H03).
static func light_line(session: GameSession) -> String:
	var lit := int(session.dungeon_run.get("light", 0))
	var spare := session.get_total_quantity(ItemCatalog.TORCH)
	if session.get_total_quantity(ItemCatalog.LANTERN) > 0 and lit <= 0:
		return TranslationServer.translate("UI_DNG_LIGHT_LANTERN")
	if lit > 0:
		return TranslationServer.translate("UI_DNG_LIGHT_TORCH") % [lit, spare]
	if spare > 0:
		return TranslationServer.translate("UI_DNG_LIGHT_SPARE") % spare
	return TranslationServer.translate("UI_DNG_LIGHT_NONE")

static func zone_key(zone: String) -> String:
	match zone:
		"gecis":
			return "UI_DNG_ZONE_GECIS"
		"galeri":
			return "UI_DNG_ZONE_GALERI"
	return "UI_DNG_ZONE_AGIZ"
