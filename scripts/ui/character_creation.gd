extends Control

## Yeni oyunun giriş ekranı: kültür, isim, boy, ten rengi, stat dağıtımı
## ve tayfa büyüklüğü. Buradan çıkınca kalıcı oturum kurulmuş, oyuncunun
## karakteri partiye yerleşmiş olur.
##
## Tayfa büyüklüğü (vagonları süren kişi sayısı) ile savaş partisi
## (adı olan en fazla 4 kişi) ayrı kavramlar: ilki kargo kapasitesini,
## ikincisi çarpışmayı belirler.

## Sekiz stata oranlı: altı stat için 6 puandı (stat başına 1.0), sekiz
## stat aynı oranı korur (bkz. CLAUDE.md Progression Rules'un genişlemesi).
const STAT_POINTS: int = 8

## Vagonları süren tayfa: her vagonda en fazla iki kişi kalır.

const DEFAULT_STARTING_GOLD: int = 250
const DEFAULT_STARTING_PROVISIONS: int = 20

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const PERK_COLOR: Color = Color(0.75, 0.85, 1.0)

var _base_stats: CharacterStats = CharacterStats.new()
var _spent_points: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _culture_button: OptionButton
var _culture_description: Label
var _culture_bonus: Label
var _culture_perk: Label
var _class_button: OptionButton
var _class_description: Label
var _name_edit: LineEdit
var _height_slider: HSlider
var _height_label: Label
var _skin_button: OptionButton
var _skin_preview: ColorRect
var _gender_button: OptionButton
## Saç (görev Y-G03): ilk seçenek saçsız, sonra `OutfitCatalog.HAIR_STYLES`.
var _hair_button: OptionButton
var _hair_color_button: OptionButton
var _weight_button: OptionButton
var _points_label: Label
var _stat_rows: Array[Dictionary] = []
var _summary_label: Label
var _start_button: Button

## OutfitCatalog.SLOT_* -> piece_id, tamamen kozmetik (bkz. CLAUDE.md
## Faz 13 hazırlık notu #14). Her `_refresh()`'te yeni bir önizleme
## karakteri kurulduğu için seçimler ekranın kendisinde tutuluyor.
var _outfit: Dictionary = {}
var _outfit_preview: FigurePreview
var _outfit_rows: Array[Dictionary] = []

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer

func _ready() -> void:
	WaybookTheme.fit_desk_workspace(self)
	$MarginContainer/VBoxContainer/TitleLabel.text = tr("UI_CREATION_TITLE")
	_rng.randomize()
	_build_ui()
	_on_culture_selected(0)

func _build_ui() -> void:
	_build_culture_section()
	_content.add_child(HSeparator.new())
	_build_class_section()
	_content.add_child(HSeparator.new())
	_build_identity_section()
	_content.add_child(HSeparator.new())
	_build_outfit_section()
	_content.add_child(HSeparator.new())
	_build_stats_section()
	_content.add_child(HSeparator.new())
	_build_fate_section()
	_content.add_child(HSeparator.new())
	_build_origin_section()
	_content.add_child(HSeparator.new())

	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(_summary_label)

	# Form uzun (kültür + sınıf + kimlik + altı stat); "Başla" ile "Geri"
	# kaydırma kutusunun içinde kalırsa oyunun ilk ekranında oyuncu en
	# dibe inmeden başlayamıyor. İkisi de dışarıda, hep görünür.
	var exit_row := $MarginContainer/VBoxContainer

	_start_button = Button.new()
	_start_button.text = tr("UI_CREATE_START")
	_start_button.pressed.connect(_on_start_pressed)
	exit_row.add_child(_start_button)

	var back_button := Button.new()
	back_button.text = Nav.back_label()
	back_button.pressed.connect(_on_back_pressed)
	exit_row.add_child(back_button)

## Kader Modu ve açık zorluk (görev Y-D01): gizli ayar yok, hepsi burada.
var _fate_mode: bool = false
var _difficulty: Dictionary = {"deathblow": GameSession.DIFFICULTY_STANDARD, "hunger": GameSession.DIFFICULTY_STANDARD, "events": GameSession.DIFFICULTY_STANDARD}
const DIFFICULTY_LABEL_KEYS: Dictionary = {
	"deathblow": "UI_DIFF_DEATHBLOW", "hunger": "UI_DIFF_HUNGER", "events": "UI_DIFF_EVENTS",
}

## Başlangıç kökeni (Y-D05): kilitliler sebebiyle görünür, seçilemez.
var _origin: String = StartOrigins.FATHER

func _build_origin_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_ORIGIN")))
	var unlocked := LineageArchive.unlocked_origins()
	var picker := OptionButton.new()
	var desc := Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	for i in StartOrigins.ORDER.size():
		var origin := StartOrigins.ORDER[i]
		var open := StartOrigins.is_unlocked(origin, unlocked)
		var label := tr(String(StartOrigins.NAME_KEYS[origin]))
		if not open:
			label = tr("UI_ORIGIN_LOCKED") % [label, tr(String(StartOrigins.UNLOCK_KEYS[origin]))]
		picker.add_item(label)
		picker.set_item_disabled(i, not open)
		picker.set_item_tooltip(i, tr(String(StartOrigins.DESC_KEYS[origin])))
	picker.select(0)
	desc.text = tr(String(StartOrigins.DESC_KEYS[StartOrigins.FATHER]))
	picker.item_selected.connect(func(index: int) -> void:
		_origin = StartOrigins.ORDER[index]
		desc.text = tr(String(StartOrigins.DESC_KEYS[_origin])))
	_content.add_child(picker)
	_content.add_child(desc)

func _build_fate_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_FATE")))
	var fate := CheckBox.new()
	fate.text = tr("UI_CREATE_FATE_MODE")
	fate.tooltip_text = tr("UI_CREATE_FATE_MODE_TIP")
	fate.toggled.connect(func(on: bool) -> void: _fate_mode = on)
	_content.add_child(fate)
	for key in GameSession.DIFFICULTY_KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = tr(String(DIFFICULTY_LABEL_KEYS[key]))
		label.custom_minimum_size = Vector2(220, 0)
		row.add_child(label)
		var picker := OptionButton.new()
		for level_key in ["UI_DIFF_EASY", "UI_DIFF_STANDARD", "UI_DIFF_HARD"]:
			picker.add_item(tr(level_key))
		picker.select(GameSession.DIFFICULTY_STANDARD)
		var setting := String(key)
		picker.item_selected.connect(func(index: int) -> void: _difficulty[setting] = index)
		row.add_child(picker)
		_content.add_child(row)

func _build_culture_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_CULTURE")))

	_culture_button = OptionButton.new()
	for culture in CultureCatalog.get_cultures():
		_culture_button.add_item(culture.culture_name)
	_culture_button.item_selected.connect(_on_culture_selected)
	_content.add_child(_culture_button)

	_culture_description = _make_hint_label()
	_content.add_child(_culture_description)

	_culture_bonus = Label.new()
	_content.add_child(_culture_bonus)

	_culture_perk = Label.new()
	_culture_perk.autowrap_mode = TextServer.AUTOWRAP_WORD
	_culture_perk.modulate = PERK_COLOR
	_content.add_child(_culture_perk)

func _build_class_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_CLASS")))

	_class_button = OptionButton.new()
	for character_class in ClassCatalog.get_classes():
		_class_button.add_item(character_class.display_name)
	_class_button.item_selected.connect(_on_class_selected)
	_content.add_child(_class_button)

	_class_description = _make_hint_label()
	_content.add_child(_class_description)

func _build_identity_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_IDENTITY")))

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var name_title := Label.new()
	name_title.text = tr("UI_CREATE_NAME")
	name_title.custom_minimum_size = Vector2(120, 0)
	name_row.add_child(name_title)

	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(240, 0)
	_name_edit.text_changed.connect(_on_name_changed)
	name_row.add_child(_name_edit)

	var random_button := Button.new()
	random_button.text = tr("UI_CREATE_RANDOM")
	random_button.pressed.connect(_roll_random_name)
	name_row.add_child(random_button)
	_content.add_child(name_row)

	var height_row := HBoxContainer.new()
	height_row.add_theme_constant_override("separation", 8)
	var height_title := Label.new()
	height_title.text = tr("UI_CREATE_HEIGHT")
	height_title.custom_minimum_size = Vector2(120, 0)
	height_row.add_child(height_title)

	_height_slider = HSlider.new()
	_height_slider.custom_minimum_size = Vector2(240, 0)
	_height_slider.min_value = CharacterData.MIN_HEIGHT_CM
	_height_slider.max_value = CharacterData.MAX_HEIGHT_CM
	_height_slider.step = 1
	_height_slider.value = CharacterData.DEFAULT_HEIGHT_CM
	_height_slider.value_changed.connect(_on_height_changed)
	height_row.add_child(_height_slider)

	_height_label = Label.new()
	_height_label.custom_minimum_size = Vector2(220, 0)
	height_row.add_child(_height_label)
	_content.add_child(height_row)

	var skin_row := HBoxContainer.new()
	skin_row.add_theme_constant_override("separation", 8)
	var skin_title := Label.new()
	skin_title.text = tr("UI_CREATE_SKIN")
	skin_title.custom_minimum_size = Vector2(120, 0)
	skin_row.add_child(skin_title)

	_skin_button = OptionButton.new()
	for index in CharacterData.SKIN_TONE_NAMES.size():
		_skin_button.add_item(CharacterData.get_skin_tone_name(index))
	_skin_button.select(1)
	_skin_button.item_selected.connect(_on_skin_selected)
	skin_row.add_child(_skin_button)

	_skin_preview = ColorRect.new()
	_skin_preview.custom_minimum_size = Vector2(48, 24)
	skin_row.add_child(_skin_preview)
	_content.add_child(skin_row)

	var hair_row := HBoxContainer.new()
	hair_row.add_theme_constant_override("separation", 8)
	var hair_title := Label.new()
	hair_title.text = tr("UI_CREATE_HAIR_STYLE")
	hair_title.custom_minimum_size = Vector2(120, 0)
	hair_row.add_child(hair_title)
	_hair_button = OptionButton.new()
	_hair_button.add_item(OutfitCatalog.get_hair_style_name(""))
	for style in OutfitCatalog.HAIR_STYLES:
		_hair_button.add_item(OutfitCatalog.get_hair_style_name(style))
	_hair_button.select(OutfitCatalog.HAIR_STYLES.find("hair_long01") + 1)
	_hair_button.item_selected.connect(func(_i: int) -> void: _refresh())
	hair_row.add_child(_hair_button)
	_hair_color_button = OptionButton.new()
	_hair_color_button.tooltip_text = tr("UI_CREATE_HAIR_COLOR")
	for index in OutfitCatalog.HAIR_COLORS.size():
		_hair_color_button.add_item(OutfitCatalog.get_hair_color_name(index))
	_hair_color_button.select(1)
	_hair_color_button.item_selected.connect(func(_i: int) -> void: _refresh())
	hair_row.add_child(_hair_color_button)
	_content.add_child(hair_row)

	var gender_row := HBoxContainer.new()
	gender_row.add_theme_constant_override("separation", 8)
	var gender_title := Label.new()
	gender_title.text = tr("UI_CREATE_GENDER")
	gender_title.custom_minimum_size = Vector2(120, 0)
	gender_row.add_child(gender_title)

	_gender_button = OptionButton.new()
	for index in CharacterData.GENDER_NAMES.size():
		_gender_button.add_item(CharacterData.get_gender_name(index))
	_gender_button.select(CharacterData.GENDER_FEMALE)
	_gender_button.item_selected.connect(_on_gender_selected)
	gender_row.add_child(_gender_button)
	_content.add_child(gender_row)

	var weight_row := HBoxContainer.new()
	weight_row.add_theme_constant_override("separation", 8)
	var weight_title := Label.new()
	weight_title.text = tr("UI_CREATE_WEIGHT")
	weight_title.custom_minimum_size = Vector2(120, 0)
	weight_row.add_child(weight_title)

	_weight_button = OptionButton.new()
	for index in CharacterData.BODY_WEIGHT_NAMES.size():
		_weight_button.add_item(CharacterData.get_body_weight_name(index))
	_weight_button.select(CharacterData.BODY_WEIGHT_AVERAGE)
	_weight_button.item_selected.connect(_on_weight_selected)
	weight_row.add_child(_weight_button)
	_content.add_child(weight_row)

## Karakteri boydan gösteren önizleme + her slotu sağa/sola kaydıran
## seçiciler (bkz. OutfitCatalog.cycle). Tamamen dış görünüm için.
func _build_outfit_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_OUTFIT")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	_outfit_preview = FigurePreview.new()
	_outfit_preview.custom_minimum_size = Vector2(150, 250)
	row.add_child(_outfit_preview)

	var slots_column := VBoxContainer.new()
	slots_column.add_theme_constant_override("separation", 4)
	for slot in OutfitCatalog.ALL_SLOTS:
		slots_column.add_child(_build_outfit_row(slot))
	row.add_child(slots_column)

	_content.add_child(row)

func _build_outfit_row(slot: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = OutfitCatalog.get_slot_display_name(slot)
	name_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(name_label)

	var prev_button := Button.new()
	prev_button.text = "<"
	prev_button.pressed.connect(_on_outfit_cycle.bind(slot, -1))
	row.add_child(prev_button)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(150, 0)
	row.add_child(value_label)

	var next_button := Button.new()
	next_button.text = ">"
	next_button.pressed.connect(_on_outfit_cycle.bind(slot, 1))
	row.add_child(next_button)

	_outfit_rows.append({"slot": slot, "value_label": value_label})
	return row

func _on_outfit_cycle(slot: String, direction: int) -> void:
	var current: String = _outfit.get(slot, OutfitCatalog.NONE_PIECE)
	_outfit[slot] = OutfitCatalog.cycle(slot, current, direction, true, _gender_button.selected)
	_refresh()

func _build_stats_section() -> void:
	_content.add_child(_make_section_title(tr("UI_CREATE_STATS")))

	_points_label = Label.new()
	_content.add_child(_points_label)

	for kind in CharacterStats.KIND_ORDER:
		_content.add_child(_build_stat_row(kind))

func _build_stat_row(kind: CharacterStats.Kind) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = CharacterStats.kind_name(kind)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	var minus_button := Button.new()
	minus_button.text = "−"
	minus_button.pressed.connect(_on_stat_changed.bind(kind, -1))
	row.add_child(minus_button)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(90, 0)
	row.add_child(value_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.pressed.connect(_on_stat_changed.bind(kind, 1))
	row.add_child(plus_button)

	var description_label := _make_hint_label()
	description_label.text = CharacterStats.kind_description(kind)
	row.add_child(description_label)

	_stat_rows.append({
		"kind": kind,
		"value_label": value_label,
		"minus": minus_button,
		"plus": plus_button,
	})
	return row


func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label

func _make_hint_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.modulate = HINT_COLOR
	return label

# --- Girdi olayları ---

func _on_culture_selected(_index: int) -> void:
	var culture := _selected_culture()
	_culture_description.text = culture.description
	_culture_bonus.text = tr("UI_CREATE_CULTURE_BONUS") % culture.get_bonus_summary()
	_culture_perk.text = culture.perk_text
	if _name_edit.text.strip_edges().is_empty():
		_roll_random_name()
	_refresh()

func _on_name_changed(_new_text: String) -> void:
	_refresh()

func _on_class_selected(_index: int) -> void:
	_refresh()

func _roll_random_name() -> void:
	var pool := _selected_culture().name_pool
	if pool.is_empty():
		return
	_name_edit.text = pool[_rng.randi_range(0, pool.size() - 1)]
	_refresh()

func _on_height_changed(_value: float) -> void:
	_refresh()

func _on_skin_selected(index: int) -> void:
	_skin_preview.color = CharacterData.get_skin_tone_color(index)
	_refresh()

func _on_gender_selected(index: int) -> void:
	# Öbür cinsiyete dikilmiş bir giysi (etek, başörtüsü) seçimde kalmasın.
	for slot in _outfit.keys():
		var piece := OutfitCatalog.get_piece(str(_outfit[slot]))
		if piece != null and not piece.fits(index):
			_outfit.erase(slot)
	_refresh()

func _on_weight_selected(_index: int) -> void:
	_refresh()

func _on_stat_changed(kind: CharacterStats.Kind, delta: int) -> void:
	if delta > 0 and _spent_points >= STAT_POINTS:
		return
	var before := _base_stats.get_value(kind)
	if delta < 0 and before <= CharacterStats.BASE_VALUE:
		return

	_base_stats.add_value(kind, delta)
	_spent_points += _base_stats.get_value(kind) - before
	_refresh()

# --- Görsel tazeleme ---

func _refresh() -> void:
	var culture := _selected_culture()
	var character_class := _selected_class()
	var preview := _build_character()

	_class_description.text = tr("UI_CREATE_CLASS_DUTY") % [
		character_class.description, DutyCatalog.get_duty(character_class.duty_id).display_name
	]

	_points_label.text = tr("UI_CREATE_POINTS") % [STAT_POINTS - _spent_points, STAT_POINTS]
	for row in _stat_rows:
		var kind: CharacterStats.Kind = row.kind
		var base_value := _base_stats.get_value(kind)
		var final_value := preview.stats.get_value(kind)
		var bonus := culture.get_stat_bonus(kind)
		var value_label: Label = row.value_label
		if bonus == 0:
			value_label.text = str(final_value)
		else:
			value_label.text = "%d (%d%+d)" % [final_value, base_value, bonus]
		var minus_button: Button = row.minus
		var plus_button: Button = row.plus
		minus_button.disabled = base_value <= CharacterStats.BASE_VALUE
		plus_button.disabled = _spent_points >= STAT_POINTS or base_value >= CharacterStats.MAX_VALUE

	_height_label.text = tr("UI_CREATE_HEIGHT_VALUE") % [int(_height_slider.value), _height_effect_text(preview)]
	_skin_preview.color = CharacterData.get_skin_tone_color(_skin_button.selected)

	for outfit_row in _outfit_rows:
		var slot: String = outfit_row.slot
		var piece_id: String = _outfit.get(slot, OutfitCatalog.NONE_PIECE)
		var value_label: Label = outfit_row.value_label
		if piece_id.is_empty():
			value_label.text = tr("UI_OUTFIT_PLAIN") if OutfitCatalog.is_plain_cloth_slot(_outfit, slot) else tr("UI_CREATE_OUTFIT_NONE")
		else:
			value_label.text = OutfitCatalog.get_piece(piece_id).display_name
	_outfit_preview.show_look(
		preview.class_id,
		preview.get_height_scale(),
		CharacterData.get_skin_tone_color(preview.skin_tone),
		OutfitCatalog.with_hair(_outfit, preview.hair_style, OutfitCatalog.get_hair_color(preview.hair_color)),
		Wardrobe.loadout_of(_outfit, {}), preview.get_body_variant_id()
	)

	_summary_label.text = tr("UI_CREATE_PREVIEW") % [
		preview.get_summary_line(),
		preview.get_max_hp(),
		preview.stats.get_initiative(),
		preview.get_accuracy(),
		preview.get_dodge(),
		preview.get_crit_chance(),
	]
	_start_button.disabled = _name_edit.text.strip_edges().is_empty()

func _height_effect_text(preview: CharacterData) -> String:
	var hp_bonus := preview.get_height_hp_bonus()
	var dodge_bonus := preview.get_height_dodge_bonus()
	if hp_bonus == 0 and dodge_bonus == 0:
		return tr("UI_CREATE_HEIGHT_AVERAGE")
	return tr("UI_BONUS_HP_DODGE") % [hp_bonus, dodge_bonus]

func _selected_culture() -> Culture:
	return CultureCatalog.get_cultures()[maxi(_culture_button.selected, 0)]

func _selected_class() -> CharacterClass:
	return ClassCatalog.get_classes()[maxi(_class_button.selected, 0)]

func _build_character() -> CharacterData:
	var character := CharacterData.create(
		_name_edit.text.strip_edges(),
		_selected_culture().culture_id,
		_base_stats,
		int(_height_slider.value),
		_skin_button.selected,
		_selected_class().class_id,
		_gender_button.selected,
		_weight_button.selected
	)
	character.outfit = _outfit.duplicate()
	var hair_index := _hair_button.selected - 1
	character.hair_style = OutfitCatalog.HAIR_STYLES[hair_index] if hair_index >= 0 else ""
	character.hair_color = maxi(_hair_color_button.selected, 0)
	return character

# --- Çıkış ---

func _on_start_pressed() -> void:
	var character := _build_character()
	if character.character_name.is_empty():
		return

	# Seed huy: hangi statın öne çıktığına göre ağırlıklı seçilir, "basic
	# seviyede" kalması için tek huyla başlanır (bkz. TraitCatalog).
	character.grant_trait(TraitCatalog.roll_seed_trait(character.stats, _rng), 0)
	character.heal_full()

	SaveManager.delete_save()
	GameState.start_new_game(
		DEFAULT_STARTING_GOLD,
		DEFAULT_STARTING_PROVISIONS,
		GameSession.STARTING_WAGONS
	)
	# Vagon sayısı, yoldaş ve başlangıç şehri artık seçilmiyor: kervan her
	# yeni oyunda iki kişi ve bir vagonla, rastgele bir şehirde yola çıkar
	# (bkz. GameSession.start_playthrough).
	var session: GameSession = GameState.get_session()
	session.start_playthrough(character, _rng)
	session.inherit_father_caravan()
	session.fate_mode = _fate_mode
	session.difficulty = _difficulty.duplicate()
	StartOrigins.apply(session, _origin)
	# Eski soy varsa yeni kervan onu okur (Y-D03).
	LineageArchive.apply_to(session, LineageArchive.latest())

	SceneInk.go(Nav.go_root(Nav.CITY_MAP))

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
