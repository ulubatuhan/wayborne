extends Control

## Kıyafet dolabı ve terzi: şehirde, kervanın giysileriyle uğraşılan tek yer.
## Ortada seçili kişi boydan, yanında altı yerin (başlık, gömlek, ceket,
## eldiven, pantolon, ayakkabı) kutusu; solda kervanın dolabı, sağda o günkü
## terzi tezgâhı. Dolaptaki bir giysi kişinin üstündeki yerine sürüklenir,
## üstteki bir giysi dolaba geri sürüklenince çıkar, dolaptan terziye
## sürüklenen satılır. Her sürüklemenin bir düğme karşılığı da var (Giy /
## Çıkar / Sat / Satın Al) - sürüklemek kısayol, karar düğmede görünür
## (bkz. CLAUDE.md Road Movement Rules: "every decision has a visible
## control").
##
## Ekran hiçbir kural taşımıyor: giymek, çıkarmak, almak, satmak GameSession
## üstünden (wear_outfit / take_off_outfit / buy_outfit / sell_outfit), kilitli
## bir alış nedeniyle gösteriliyor (get_outfit_buy_block_reason).

const PREVIEW_SIZE: Vector2 = Vector2(220, 360)
const SLOT_BOX_SIZE: Vector2 = Vector2(230, 54)
const COLUMN_WIDTH: float = 300.0
const HINT_COLOR: Color = Color(0.78, 0.74, 0.66)
const DROP_OK_COLOR: Color = Color(0.86, 0.72, 0.36)
const DRAG_KIND: String = "wayborne_outfit"

var _session: GameSession
var _index: int = 0

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	WaybookTheme.fit_desk_workspace(self)
	_session = GameState.get_session()
	_title_label.text = tr("UI_CITY_WARDROBE")
	_info_label.text = tr("UI_WARDROBE_HINT")
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)
	_index = clampi(Nav.character_target_index, 0, maxi(0, _session.party.size() - 1))
	_refresh()

func _character() -> CharacterData:
	if _session.party.is_empty():
		return null
	return _session.party[clampi(_index, 0, _session.party.size() - 1)]

func _refresh() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var purse := Label.new()
	purse.text = tr("UI_PURSE") % _session.wallet.balance
	_content.add_child(purse)
	_content.add_child(_build_party_row())
	var columns := HFlowContainer.new()
	columns.add_theme_constant_override("h_separation", 24)
	columns.add_theme_constant_override("v_separation", 18)
	_content.add_child(columns)
	columns.add_child(_build_person_column())
	columns.add_child(_build_locker_column())
	columns.add_child(_build_tailor_column())

# --- Kişi seçimi ---

func _build_party_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in _session.party.size():
		var button := Button.new()
		button.text = _session.party[i].character_name
		button.toggle_mode = true
		button.button_pressed = i == _index
		button.pressed.connect(_on_person_pressed.bind(i))
		row.add_child(button)
	return row

func _on_person_pressed(index: int) -> void:
	_index = index
	Nav.character_target_index = index
	_refresh()

# --- Kişi ve üstündekiler ---

func _build_person_column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.add_child(_heading(tr("UI_WARDROBE_WORN")))
	var character := _character()
	if character == null:
		return column
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	var preview := FigurePreview.new()
	preview.custom_minimum_size = PREVIEW_SIZE
	row.add_child(preview)
	preview.show_character(character)
	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(slots)
	for slot in OutfitCatalog.ALL_SLOTS:
		slots.add_child(_build_slot_box(character, slot))
	column.add_child(_build_stats_label(character))
	return column

## Bir yerin kutusu: o yerde ne giyildiğini gösterir, oraya ait bir giysiyi
## dolaptan kabul eder, içindekini dolaba bırakmak için sürüklenir.
func _build_slot_box(character: CharacterData, slot: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.theme_type_variation = WaybookTheme.CELL_PANEL
	box.custom_minimum_size = SLOT_BOX_SIZE
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	box.add_child(inner)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(text)
	var slot_label := Label.new()
	slot_label.text = OutfitCatalog.get_slot_display_name(slot)
	slot_label.modulate = HINT_COLOR
	slot_label.add_theme_font_size_override("font_size", 13)
	text.add_child(slot_label)
	var piece := OutfitCatalog.get_piece(character.get_outfit_piece(slot))
	var name_label := Label.new()
	name_label.text = piece.display_name if piece != null else tr("UI_WARDROBE_SLOT_EMPTY")
	text.add_child(name_label)
	if piece != null:
		var bonus := Label.new()
		bonus.text = OutfitCatalog.bonus_text(piece)
		bonus.add_theme_font_size_override("font_size", 13)
		text.add_child(bonus)
		var off := Button.new()
		off.text = tr("UI_WARDROBE_TAKE_OFF")
		off.pressed.connect(_take_off.bind(slot))
		inner.add_child(off)
	box.tooltip_text = tr("UI_WARDROBE_SLOT_TOOLTIP")
	box.set_drag_forwarding(
		_slot_drag.bind(slot, box),
		_slot_can_drop.bind(slot),
		_slot_drop.bind(slot)
	)
	return box

func _build_stats_label(character: CharacterData) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(PREVIEW_SIZE.x + SLOT_BOX_SIZE.x, 0)
	var parts: PackedStringArray = []
	var values := {
		"hp_bonus": character.get_max_hp(), "dodge_bonus": character.get_dodge(),
		"accuracy_bonus": character.get_accuracy(), "crit_bonus": character.get_crit_chance(),
		"damage_bonus": character.get_damage_bonus(),
	}
	for field in OutfitCatalog.BONUS_FIELDS:
		var from_outfit := character.get_outfit_bonus(field)
		var line := "%s %d" % [tr(_stat_key(field)), int(values[field])]
		if from_outfit != 0:
			line += " (%s)" % (tr("UI_WARDROBE_FROM_OUTFIT") % from_outfit)
		parts.append(line)
	label.text = " · ".join(parts)
	return label

func _stat_key(field: String) -> String:
	match field:
		"hp_bonus":
			return "UI_OUTFIT_STAT_HP"
		"dodge_bonus":
			return "UI_OUTFIT_STAT_DODGE"
		"accuracy_bonus":
			return "UI_OUTFIT_STAT_ACCURACY"
		"crit_bonus":
			return "UI_OUTFIT_STAT_CRIT"
		_:
			return "UI_OUTFIT_STAT_DAMAGE"

# --- Dolap ---

func _build_locker_column() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	column.add_child(_heading(tr("UI_WARDROBE_LOCKER")))
	var ids := _locker_ids()
	if ids.is_empty():
		column.add_child(_hint(tr("UI_WARDROBE_LOCKER_EMPTY")))
	for piece_id in ids:
		column.add_child(_build_locker_card(piece_id))
	# Üstteki bir giysi buraya bırakılınca çıkar.
	panel.set_drag_forwarding(Callable(), _locker_can_drop, _locker_drop)
	return panel

func _locker_ids() -> Array[String]:
	var out: Array[String] = []
	for piece in OutfitCatalog.get_all_pieces():
		if _session.get_outfit_count(piece.piece_id) > 0:
			out.append(piece.piece_id)
	return out

func _build_locker_card(piece_id: String) -> PanelContainer:
	var piece := OutfitCatalog.get_piece(piece_id)
	var card := PanelContainer.new()
	card.theme_type_variation = WaybookTheme.CELL_PANEL
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	column.add_child(_piece_title(piece, _session.get_outfit_count(piece_id)))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	column.add_child(buttons)
	var wear := Button.new()
	wear.text = tr("UI_WARDROBE_WEAR")
	wear.disabled = _character() == null
	wear.pressed.connect(_wear.bind(piece_id))
	buttons.add_child(wear)
	var sell := Button.new()
	sell.text = tr("UI_WARDROBE_SELL") % _session.get_outfit_sell_price(piece_id)
	sell.pressed.connect(_sell.bind(piece_id))
	buttons.add_child(sell)
	card.tooltip_text = tr("UI_WARDROBE_CARD_TOOLTIP")
	card.set_drag_forwarding(_locker_drag.bind(piece_id), Callable(), Callable())
	return card

## "Ad (yer) ×adet" ve altında katkısı.
func _piece_title(piece: OutfitPiece, count: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_label := Label.new()
	name_label.text = "%s (%s)%s" % [
		piece.display_name, OutfitCatalog.get_slot_display_name(piece.slot),
		(" ×%d" % count) if count > 1 else "",
	]
	box.add_child(name_label)
	var bonus := Label.new()
	bonus.text = OutfitCatalog.bonus_text(piece)
	bonus.add_theme_font_size_override("font_size", 13)
	bonus.modulate = HINT_COLOR
	box.add_child(bonus)
	return box

# --- Terzi ---

func _build_tailor_column() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(COLUMN_WIDTH, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	column.add_child(_heading(tr("UI_TAILOR")))
	column.add_child(_hint(tr("UI_TAILOR_HINT")))
	var stock := _session.get_tailor_stock()
	if stock.is_empty():
		column.add_child(_hint(tr("UI_TAILOR_EMPTY")))
	for piece_id in stock:
		column.add_child(_build_tailor_row(str(piece_id), int(stock[piece_id])))
	# Dolaptan buraya bırakılan giysi satılır.
	panel.set_drag_forwarding(Callable(), _tailor_can_drop, _tailor_drop)
	return panel

func _build_tailor_row(piece_id: String, left: int) -> PanelContainer:
	var piece := OutfitCatalog.get_piece(piece_id)
	var card := PanelContainer.new()
	card.theme_type_variation = WaybookTheme.CELL_PANEL
	var column := VBoxContainer.new()
	card.add_child(column)
	column.add_child(_piece_title(piece, left))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	column.add_child(row)
	var buy := Button.new()
	buy.text = tr("UI_TAILOR_BUY") % _session.get_outfit_buy_price(piece_id)
	var reason := _session.get_outfit_buy_block_reason(piece_id)
	buy.disabled = not reason.is_empty()
	buy.pressed.connect(_buy.bind(piece_id))
	row.add_child(buy)
	# Kilitli seçim gizlenmez, nedeniyle gösterilir.
	if not reason.is_empty():
		row.add_child(_hint(tr(reason)))
	return card

# --- Sürükle-bırak ---

func _drag_data(piece_id: String, source: String, slot: String) -> Dictionary:
	return {"kind": DRAG_KIND, "piece_id": piece_id, "source": source, "slot": slot}

func _make_preview(piece_id: String) -> Control:
	var piece := OutfitCatalog.get_piece(piece_id)
	var panel := PanelContainer.new()
	panel.theme_type_variation = WaybookTheme.CELL_PANEL
	var label := Label.new()
	label.text = piece.display_name if piece != null else piece_id
	panel.add_child(label)
	return panel

func _is_outfit_drag(data: Variant) -> bool:
	return data is Dictionary and str((data as Dictionary).get("kind", "")) == DRAG_KIND

func _locker_drag(_at_position: Vector2, piece_id: String) -> Variant:
	set_drag_preview(_make_preview(piece_id))
	return _drag_data(piece_id, "locker", "")

func _slot_drag(_at_position: Vector2, slot: String, _box: Control) -> Variant:
	var character := _character()
	if character == null:
		return null
	var piece_id := character.get_outfit_piece(slot)
	if piece_id.is_empty():
		return null
	set_drag_preview(_make_preview(piece_id))
	return _drag_data(piece_id, "slot", slot)

func _slot_can_drop(_at_position: Vector2, data: Variant, slot: String) -> bool:
	if not _is_outfit_drag(data) or str(data["source"]) != "locker" or _character() == null:
		return false
	var piece := OutfitCatalog.get_piece(str(data["piece_id"]))
	return piece != null and piece.slot == slot

func _slot_drop(_at_position: Vector2, data: Variant, _slot: String) -> void:
	_wear(str(data["piece_id"]))

func _locker_can_drop(_at_position: Vector2, data: Variant) -> bool:
	return _is_outfit_drag(data) and str(data["source"]) == "slot"

func _locker_drop(_at_position: Vector2, data: Variant) -> void:
	_take_off(str(data["slot"]))

func _tailor_can_drop(_at_position: Vector2, data: Variant) -> bool:
	return _is_outfit_drag(data) and str(data["source"]) == "locker"

func _tailor_drop(_at_position: Vector2, data: Variant) -> void:
	_sell(str(data["piece_id"]))

# --- Eylemler ---
# Düğmeden ya da bırakmadan gelir; ekran bir sonraki karede yeniden kurulur,
# çünkü bu çağrı tam da yok edilecek düğümlerin içinden geliyor.

func _wear(piece_id: String) -> void:
	_session.wear_outfit(_character(), piece_id)
	call_deferred("_refresh")

func _take_off(slot: String) -> void:
	_session.take_off_outfit(_character(), slot)
	call_deferred("_refresh")

func _sell(piece_id: String) -> void:
	_session.sell_outfit(piece_id)
	call_deferred("_refresh")

func _buy(piece_id: String) -> void:
	_session.buy_outfit(piece_id)
	call_deferred("_refresh")

# --- Yardımcılar ---

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _hint(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = HINT_COLOR
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(120, 0)
	return label

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
