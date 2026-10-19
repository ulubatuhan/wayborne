class_name DialoguePanel
extends CanvasLayer

## Bir kişiyle konuşma penceresi (kullanıcı isteği 2026-10-19: "tavernada,
## yolda NPC'lerle konuşma diyalogları böyle bir panelde olmalı"): solda
## çerçeveli portre kartı (kişinin kendi figürü, belden yukarı; altında adı ve
## rolü), sağda söylediği ve seçenekler; sağ üstte Kapat.
##
## Pencere karar vermez: seçeneği `choice_made(id)` ile çağırana bildirir;
## çağıran ya `say()` ile konuşmayı sürdürür ya `close()` ile bitirir. Kilitli
## bir seçenek gizlenmez, sebebiyle soluk gösterilir (Event Engine Rules).
## Bedeli olan seçenek bedelini adının yanında söyler.
##
##     var panel := DialoguePanel.new()
##     add_child(panel)
##     panel.open(character, "Ozan", "Yollar tekinsiz...", [
##         {"id": "hire", "text": "Haklısın", "cost": "-50 Altın"},
##         {"id": "no", "text": "Gerek yok", "locked": "Kesede yeterli altın yok"},
##     ])

signal choice_made(id: String)
signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.55)
const PANEL_SIZE: Vector2 = Vector2(1080, 560)
const PORTRAIT_SIZE: Vector2 = Vector2(320, 470)
const TEXT_SIZE: int = 23
## Kadroda olmayan biri silahsız çizilir (sınıfın silahı sırtında durmasın);
## kadrodan biri için "" verilir, sınıfının görünüşü kullanılır.
const STRANGER: String = "villager"

var _root: Control
var _backdrop: ColorRect
var _card: PanelContainer
var _portrait: FigurePreview
var _name_label: Label
var _role_label: Label
var _text_label: Label
var _choices: VBoxContainer
var _dismissing: bool = false
var _closable: bool = true
var _close_button: Button

func _init() -> void:
	layer = 66
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP_COLOR
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_backdrop)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)
	_card = PanelContainer.new()
	_card.custom_minimum_size = PANEL_SIZE
	_card.add_theme_stylebox_override("panel", _frame(Color(ArtPalette.GRIM_CHARCOAL, 0.98), 2, 22))
	center.add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	_card.add_child(row)
	row.add_child(_build_portrait())
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	row.add_child(right)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(top)
	_close_button = Button.new()
	_close_button.text = tr("UI_DIALOGUE_CLOSE")
	_close_button.flat = true
	_close_button.pressed.connect(close)
	top.add_child(_close_button)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", TEXT_SIZE)
	_text_label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_text_label)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 10)
	right.add_child(_choices)

func _frame(fill: Color, width: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color(ArtPalette.GRIM_AMBER, 0.65)
	box.set_border_width_all(width)
	box.set_corner_radius_all(3)
	box.set_content_margin_all(margin)
	box.shadow_color = Color(0, 0, 0, 0.6)
	box.shadow_size = 18
	return box

func _build_portrait() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = PORTRAIT_SIZE
	card.add_theme_stylebox_override("panel", _frame(Color(0.10, 0.08, 0.06, 1.0), 1, 10))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	card.add_child(col)
	var frame := Control.new()
	frame.clip_contents = true
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(frame)
	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.color = Color(0.20, 0.15, 0.10)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(glow)
	_portrait = FigurePreview.new()
	frame.add_child(_portrait)
	# Belden yukarı: figür kutusu çerçevenin iki katı, baş üst kenarda.
	frame.resized.connect(func() -> void:
		var h := frame.size.y * 1.85
		_portrait.size = Vector2(frame.size.x * 1.4, h)
		_portrait.position = Vector2((frame.size.x - _portrait.size.x) * 0.5, -h * 0.10))
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 24)
	_name_label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	col.add_child(_name_label)
	_role_label = Label.new()
	_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role_label.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT_DIM)
	col.add_child(_role_label)
	return card

## Pencereyi açar: kişi, rolü, ilk sözü ve seçenekler. `closable` false ise
## Esc ve Kapat çalışmaz (bir karar zorunluysa).
func open(character: CharacterData, role_text: String, text: String, choices: Array, closable: bool = true, archetype: String = STRANGER) -> void:
	_closable = closable
	_close_button.visible = closable
	set_speaker(character, role_text, archetype)
	say(text, choices)
	WaybookTheme.present(_card, _backdrop, self)

## Konuşan kişi değişir (kervanbaşı soruyor, tüccar cevaplıyor).
func set_speaker(character: CharacterData, role_text: String, archetype: String = STRANGER) -> void:
	_portrait.show_character(character, archetype)
	# Pencerenin loş, sıcak ışığı: tavernadaki figürlerle aynı ton.
	_portrait.set_tint(Color(0.86, 0.74, 0.62))
	_name_label.text = character.character_name if character != null else ""
	_role_label.text = role_text

## Kadroda olmayan biri (tüccar, yolcu): adı ve bir tohumdan kılığı. Aynı tohum
## aynı yüzü verir; kılık tavernanın konuk takımlarından.
static func stranger(name_text: String, seed_key: String) -> CharacterData:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_key)
	var cultures := CultureCatalog.get_cultures()
	var culture = cultures[rng.randi_range(0, cultures.size() - 1)]
	var gender := CharacterData.GENDER_MALE if rng.randf() < 0.7 else CharacterData.GENDER_FEMALE
	var character := CharacterData.create(
		name_text, culture.culture_id, CharacterStats.new(), rng.randi_range(160, 186),
		rng.randi_range(0, 3), ClassCatalog.GUARD, gender, rng.randi_range(0, 2)
	)
	var sets: Array = TavernRoom.MALE_OUTFITS if gender == CharacterData.GENDER_MALE else TavernRoom.FEMALE_OUTFITS
	var slots := [OutfitCatalog.SLOT_SHIRT, OutfitCatalog.SLOT_PANTS, OutfitCatalog.SLOT_SHOES, OutfitCatalog.SLOT_JACKET, OutfitCatalog.SLOT_HAT]
	var picked: Array = sets[rng.randi_range(0, sets.size() - 1)]
	for i in slots.size():
		var piece := String(picked[i])
		if not piece.is_empty() and OutfitCatalog.get_piece(piece) != null:
			character.set_outfit_piece(slots[i], piece)
	return character

## Konuşmayı sürdürür: yeni söz, yeni seçenekler.
func say(text: String, choices: Array) -> void:
	_text_label.text = text
	NodeUtil.clear_children(_choices)
	for choice in choices:
		_choices.add_child(_choice_button(choice))

func _choice_button(choice: Dictionary) -> Button:
	var button := Button.new()
	var text := String(choice.get("text", ""))
	var cost := String(choice.get("cost", ""))
	var locked := String(choice.get("locked", ""))
	if not cost.is_empty():
		text += "  (%s)" % cost
	if not locked.is_empty():
		text += "  - %s" % locked
		button.disabled = true
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(func() -> void: choice_made.emit(String(choice.get("id", ""))))
	return button

func get_text() -> String:
	return _text_label.text

func get_choice_count() -> int:
	return _choices.get_child_count()

func close() -> void:
	if _dismissing:
		return
	_dismissing = true
	WaybookTheme.dismiss(_card, _backdrop, self, func():
		closed.emit()
		queue_free()
	)

## Esc pencereyi kapatır, altındaki ekranı değil (görev Y-H04).
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _closable:
			close()
