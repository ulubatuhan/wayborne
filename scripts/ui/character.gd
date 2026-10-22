extends Control

## Tek bir karakterin ayrıntı ekranı: stat/yetkinlik yatırımı, görev
## ataması, multiclass seçimi ve ekipman (bkz. GameSession.equip_to_character -
## takılan/çıkarılan parça kervanın ortak equipment_inventory deposuyla
## alışveriş eder). Parti ekranından tr("UI_PARTY_OPEN_CHARACTER") düğmesiyle açılır; hangi
## üyeyi gösterdiği Nav.character_target_index'ten okunur.
##
## Görev 9.6: onaylı taslağa göre iki sekme. "Kişi" üç sütun - kimlik
## (figür, boy/kilo, geçmiş, hedef, bağ), huylar ve statlar (amblem, dilimli
## çubuk, puan yatırımı), beceriler ve dirençler (yetkinlik çubukları, durum
## dirençleri, can/stres satırı, ilerleme). Üç sütuna sığmayan işler -
## kıyafet, ekipman, görev, ikinci sınıf - "Kuşam ve görev" sekmesinde;
## hiçbiri silinmedi.

const SegmentBar := preload("res://scripts/ui/segment_bar.gd")

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const PERK_COLOR: Color = Color(0.75, 0.85, 1.0)
const POSITIVE_COLOR: Color = Color(0.6, 0.85, 0.6)
const NEGATIVE_COLOR: Color = Color(0.9, 0.6, 0.55)
## Waybook işaretleri (bkz. WaybookIcons): stat/görev amblemleri, huy
## mühürleri, kırgınlık notları.
const EMBLEM_SIZE: float = 26.0
const STAT_EMBLEM_SIZE: float = 44.0
const TOKEN_SIZE: float = 36.0
const TRAIT_TOKEN_SIZE: float = 40.0
const RESIST_ICON_SIZE: float = 40.0
## Ekipman satırının resmi - metin satırıyla aynı yükseklikte dursun diye
## küçük, `EMBLEM_SIZE`'a yakın.
const EQUIP_ICON_HEIGHT: float = 28.0
const GEAR_PREVIEW_SIZE: Vector2 = Vector2(200, 360)
const IDENTITY_PREVIEW_MIN: Vector2 = Vector2(220, 300)

## Taslak 9.6 (y_96_karakter.png, 1080p): ad ve sütun başlıkları IM Fell
## (küçük büyük harf) soluk altın, satırlar EB Garamond.
const TITLE_FONT_SIZE: int = 48
const SUBTITLE_FONT_SIZE: int = 24
const HEADING_FONT_SIZE: int = 30
const SUBHEADING_FONT_SIZE: int = 26
const ROW_FONT_SIZE: int = 25
const HINT_FONT_SIZE: int = 21
const STAT_ROW_GAP: int = 14
const SKILL_ROW_GAP: int = 26
const RESIST_ROW_GAP: int = 26
## Stat çubuğu beşer puanlık dilimlerle: 15 tavan, üç dilim.
const STAT_SEGMENTS: int = 3
## Sütunların ekran kenarından payı. Taslak üç sütunu neredeyse tam genişlikte
## istiyor: masa sütununun %65'i (fit_desk_workspace) üç sütunu sıkıştırıyordu.
## Sütunların kendi koyu zemini var, metnin arkasına soluk çadır bezi düşmüyor -
## %65 kuralının korumak istediği kontrast burada panelin kendisinden geliyor.
const COLUMN_EDGE_MARGIN: float = 60.0
const COLUMN_MIN_WIDTH: float = 320.0
const RESIST_KEYS: Array[String] = [
	"UI_CHAR_RESIST_BLEED", "UI_CHAR_RESIST_BLIGHT", "UI_CHAR_RESIST_STUN", "UI_CHAR_RESIST_BURN",
]
const RESIST_ICONS: Array[String] = ["k4a_bleed.png", "k4b_blight.png", "k4c_stun.png", "k4g_burn.png"]
const BOND_WORD_KEYS: Array[String] = [
	"UI_CHAR_BOND_WORD_1", "UI_CHAR_BOND_WORD_2", "UI_CHAR_BOND_WORD_3",
	"UI_CHAR_BOND_WORD_4", "UI_CHAR_BOND_WORD_5",
]
const TAB_PERSON: int = 0
const TAB_GEAR: int = 1

var _session: GameSession
var _character: CharacterData
var _tab: int = TAB_PERSON
var _tab_buttons: Array[Button] = []

@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var _title_label: Label = $MarginContainer/VBoxContainer/Header/HeaderText/TitleLabel
@onready var _subtitle_row: HBoxContainer = $MarginContainer/VBoxContainer/Header/HeaderText/SubtitleRow
@onready var _tab_row: HBoxContainer = $MarginContainer/VBoxContainer/Header/TabRow

func _ready() -> void:
	WaybookTheme.fit_desk_workspace(self)
	_title_label.text = tr("UI_CHARACTER_TITLE")
	_title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	_title_label.add_theme_color_override("font_color", ArtPalette.MENU_TITLE_GOLD)
	_title_label.add_theme_font_override("font", GrimTheme.title_font())
	_session = GameState.get_session()
	# Bu ekran yalnızca parti ekranından açılıyor, dönüş hedefi de her
	# zaman orası; gezinme yığını geri yolunu zaten taşıyor (bkz. Nav).
	_back_button.text = tr("UI_CHAR_BACK_TO_PARTY")
	_back_button.custom_minimum_size = Vector2(240, 0)
	_back_button.pressed.connect(_on_back_pressed)

	var party := _session.get_party()
	var index := clampi(Nav.character_target_index, 0, maxi(0, party.size() - 1))
	_character = party[index] if not party.is_empty() else _session.get_player_character()

	_build_tabs()
	# fit_desk_workspace'in kendi `resized` bağlantısından sonra: sütun
	# genişliği içeriğin en dar genişliği olarak ona geri dönüyor.
	resized.connect(_fit_columns)
	_refresh()
	_fit_columns()

## Geniş ekranda içerik ekran eksi iki kenar payı kadar geniş; masa sütunu
## (`workspace_side_margin`) içeriğin en dar genişliğinden dar olamadığı için
## kenar payı kendiliğinden `COLUMN_EDGE_MARGIN`'e iniyor. Dar ekranda masa
## sütunu zaten tam genişlik.
func _fit_columns() -> void:
	var target := 0.0
	if size.x >= WaybookTheme.WORKSPACE_FULL_WIDTH_BELOW:
		target = size.x - 2.0 * COLUMN_EDGE_MARGIN - 16.0
	_content.custom_minimum_size = Vector2(target, 0.0)

func _build_tabs() -> void:
	var group := ButtonGroup.new()
	for key in ["UI_CHAR_TAB_PERSON", "UI_CHAR_TAB_GEAR"]:
		var button := Button.new()
		button.text = tr(key)
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150, 0)
		button.pressed.connect(_on_tab_pressed.bind(_tab_buttons.size()))
		_tab_row.add_child(button)
		_tab_buttons.append(button)

func _refresh() -> void:
	_build_header()
	for i in _tab_buttons.size():
		_tab_buttons[i].set_pressed_no_signal(i == _tab)
	NodeUtil.clear_children(_content)
	if _tab == TAB_PERSON:
		_build_person_page()
	else:
		_build_gear_page()

# --- Başlık ---

func _build_header() -> void:
	_title_label.text = _character.character_name
	NodeUtil.clear_children(_subtitle_row)
	var class_name_text := _character.get_character_class().display_name
	if not _character.second_class_id.is_empty():
		var second := ClassCatalog.get_character_class(_character.second_class_id)
		if second != null:
			class_name_text = "%s / %s" % [class_name_text, second.display_name]
	var subtitle := Label.new()
	subtitle.text = tr("UI_CHAR_SUBTITLE") % [
		class_name_text, _character.level, _character.get_culture().culture_name,
	]
	subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	subtitle.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_DIM.lightened(0.15))
	_subtitle_row.add_child(subtitle)

# --- Kişi sekmesi: üç sütun ---

func _build_person_page() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(columns)
	columns.add_child(_build_identity_column())
	columns.add_child(_build_stats_column())
	columns.add_child(_build_skills_column())

func _build_identity_column() -> PanelContainer:
	var column := _make_column(tr("UI_CHAR_COL_IDENTITY"))
	var body := _body_of(column)

	var preview := FigurePreview.new()
	preview.custom_minimum_size = IDENTITY_PREVIEW_MIN
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(preview)
	preview.show_character(_character)

	body.add_child(_make_row_label(tr("UI_CHAR_BODY_LINE") % [
		_character.height_cm, CharacterData.get_body_weight_name(_character.body_weight),
	]))

	# Geçmiş, hedef ve liderle bağ (görev Y-C17): yanında yürüyüp konuştukça
	# öğrenilir; ilk sohbetten önce yalnızca "henüz tanımıyorsun". Kervanbaşı
	# kendisiyle bağ kurmuyor - satırları yok.
	if not _character.is_player and not _character.backstory_id.is_empty():
		if _character.rapport <= 0:
			body.add_child(_make_hint_label(tr("UI_CHAR_STRANGER")))
		else:
			var backstory_key := String(CharacterData.BACKSTORY_LABEL_KEYS.get(_character.backstory_id, ""))
			if not backstory_key.is_empty():
				body.add_child(_make_hint_label(tr("UI_CHAR_BACKSTORY") % tr(backstory_key)))
			var goal_key := String(CampStory.GOAL_KEYS.get(_character.backstory_id, ""))
			if not goal_key.is_empty():
				body.add_child(_make_hint_label(tr("UI_CHAR_GOAL") % tr(goal_key)))
			var word_index := clampi(_character.rapport, 1, BOND_WORD_KEYS.size()) - 1
			var bond := _make_hint_label(tr("UI_CHAR_BOND") % [tr(BOND_WORD_KEYS[word_index]), _character.rapport])
			bond.tooltip_text = "%d/%d" % [_character.rapport, CharacterData.MAX_RAPPORT]
			bond.mouse_filter = Control.MOUSE_FILTER_PASS
			body.add_child(bond)

	var perk := _make_hint_label(_character.get_culture().perk_text)
	perk.modulate = PERK_COLOR
	body.add_child(perk)

	# Kırgınlıklar ve açlık çetelesi kişinin kenarına düşülmüş notlar:
	# ihtiyaç yoksa satır da yok.
	var grievances := WaybookIcons.grievance_row(_character, TOKEN_SIZE)
	var tally := WaybookIcons.hunger_tally(_character, TOKEN_SIZE)
	if grievances.get_child_count() > 0 or tally.get_child_count() > 0:
		var marks := HBoxContainer.new()
		marks.add_theme_constant_override("separation", 12)
		marks.add_child(grievances)
		marks.add_child(tally)
		body.add_child(marks)
	else:
		grievances.free()
		tally.free()
	return column

func _build_stats_column() -> PanelContainer:
	var column := _make_column(tr("UI_CHAR_COL_TRAITS_STATS"))
	var body := _body_of(column)
	var stat_rows := VBoxContainer.new()
	stat_rows.add_theme_constant_override("separation", STAT_ROW_GAP)
	body.add_child(stat_rows)
	for kind in CharacterStats.KIND_ORDER:
		stat_rows.add_child(_build_stat_row(kind))

	var derived := _make_hint_label(tr("UI_STATLINE") % [
		_character.stats.get_initiative(),
		_character.get_accuracy(),
		_character.get_dodge(),
		_character.get_crit_chance(),
		_character.get_damage_bonus(),
	])
	body.add_child(derived)

	var traits_heading := _heading_label(tr("UI_CHAR_TRAITS"), SUBHEADING_FONT_SIZE)
	body.add_child(_spacer(10))
	body.add_child(traits_heading)
	_build_traits_into(body)
	return column

func _build_stat_row(kind: CharacterStats.Kind) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.tooltip_text = CharacterStats.kind_description(kind)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var emblem := WaybookIcons.picture(WaybookIcons.STAT_EMBLEMS, kind, STAT_EMBLEM_SIZE)
	row.add_child(emblem)
	var name_label := _make_row_label(CharacterStats.kind_name(kind))
	name_label.custom_minimum_size = Vector2(170, 0)
	row.add_child(name_label)

	var value := _character.stats.get_value(kind)
	var bar := SegmentBar.new()
	bar.setup(value, CharacterStats.MAX_VALUE, STAT_SEGMENTS, ArtPalette.GOLD)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	var value_label := _make_row_label(str(value))
	value_label.custom_minimum_size = Vector2(32, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	# Harcanacak puan varken "+" görünür; kilitliyse soluk, nedeni ipucunda.
	# Otomatik dağıtım puanı seviye atlarken harcıyor, ortada puan kalmıyor.
	if _character.unspent_stat_points > 0:
		var plus_button := _make_plus_button()
		var maxed := value >= CharacterStats.MAX_VALUE
		if _character.auto_allocate:
			plus_button.disabled = true
			plus_button.tooltip_text = tr("UI_AUTO_ALLOCATE_ON")
		elif maxed:
			plus_button.disabled = true
			plus_button.tooltip_text = tr("UI_AT_CAP")
		else:
			plus_button.pressed.connect(_on_stat_invest_pressed.bind(kind))
		row.add_child(plus_button)
	return row

func _build_traits_into(body: VBoxContainer) -> void:
	var traits := _character.get_traits()
	if traits.is_empty():
		body.add_child(_make_hint_label(tr("UI_CHAR_NO_TRAITS")))
		return
	for trait_resource in traits:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		var token := WaybookIcons.trait_token(trait_resource.is_positive, TRAIT_TOKEN_SIZE)
		token.custom_minimum_size = Vector2(TRAIT_TOKEN_SIZE, TRAIT_TOKEN_SIZE)
		token.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		line.add_child(token)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		var name_label := _make_row_label(trait_resource.display_name)
		name_label.modulate = POSITIVE_COLOR if trait_resource.is_positive else NEGATIVE_COLOR
		text.add_child(name_label)
		var fresh := _character.is_trait_fresh(trait_resource.trait_id, _session.total_days_elapsed)
		var description := _make_hint_label("%s%s" % [
			trait_resource.description, tr("UI_CHAR_TRAIT_FRESH") if fresh else "",
		])
		description.add_theme_font_size_override("font_size", WaybookTheme.FONT_MIN)
		text.add_child(description)
		body.add_child(line)

func _build_skills_column() -> PanelContainer:
	var column := _make_column(tr("UI_CHAR_COL_SKILLS_RESISTS"))
	var body := _body_of(column)
	var skill_rows := VBoxContainer.new()
	skill_rows.add_theme_constant_override("separation", SKILL_ROW_GAP)
	body.add_child(skill_rows)
	for skill in _character.get_skills():
		skill_rows.add_child(_build_skill_row(skill))

	body.add_child(_spacer(36))
	var resist_rows := VBoxContainer.new()
	resist_rows.add_theme_constant_override("separation", RESIST_ROW_GAP)
	body.add_child(resist_rows)
	var resists: Array[int] = [
		_character.get_bleed_resist(), _character.get_blight_resist(),
		_character.get_stun_resist(), _character.get_burn_resist(),
	]
	for i in RESIST_KEYS.size():
		resist_rows.add_child(_build_resist_row(RESIST_ICONS[i], tr(RESIST_KEYS[i]), resists[i]))

	body.add_child(_spacer(24))
	var footer := _make_row_label(tr("UI_CHAR_FOOTER") % [
		_character.current_hp, _character.get_max_hp(), _character.stress,
		tr(_character.get_condition_label_key()),
	])
	footer.add_theme_color_override("font_color", ArtPalette.BLOOD.lightened(0.25))
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(footer)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(filler)
	body.add_child(_make_rule(0.3))
	_build_progress_into(body)
	return column

func _build_skill_row(skill: CombatSkill) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.tooltip_text = skill.description
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var name_label := _make_row_label(skill.display_name)
	name_label.custom_minimum_size = Vector2(210, 0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	row.add_child(name_label)

	var proficiency := _character.get_skill_proficiency(skill.skill_id)
	var bar := SegmentBar.new()
	bar.setup(proficiency, CharacterData.MAX_SKILL_PROFICIENCY, 1, ArtPalette.MOSS.lightened(0.15))
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)

	# Taslakta yalnız çubuk; sayı ipucunda (bkz. `row.tooltip_text`).
	row.tooltip_text = "%s\n%d/%d" % [skill.description, proficiency, CharacterData.MAX_SKILL_PROFICIENCY]

	if _character.unspent_skill_points > 0:
		var plus_button := _make_plus_button()
		if _character.auto_allocate:
			plus_button.disabled = true
			plus_button.tooltip_text = tr("UI_AUTO_ALLOCATE_ON")
		elif proficiency >= CharacterData.MAX_SKILL_PROFICIENCY:
			plus_button.disabled = true
			plus_button.tooltip_text = tr("UI_AT_CAP")
		else:
			plus_button.pressed.connect(_on_skill_invest_pressed.bind(skill.skill_id))
		row.add_child(plus_button)
	return row

func _build_resist_row(icon: String, label_text: String, percent: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.tooltip_text = tr("UI_CHAR_RESIST_TOOLTIP")
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var picture := WaybookTheme.picture(icon, RESIST_ICON_SIZE)
	picture.custom_minimum_size = Vector2(RESIST_ICON_SIZE, RESIST_ICON_SIZE)
	row.add_child(picture)
	var name_label := _make_row_label(label_text)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label := _make_row_label(tr("UI_CHAR_RESIST_VALUE") % percent)
	value_label.custom_minimum_size = Vector2(90, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	return row

## Seviye, XP, harcanmamış puanlar ve otomatik dağıtım: "+" düğmeleri bu
## sekmede, anahtarları da yanlarında.
func _build_progress_into(body: VBoxContainer) -> void:
	var level_label := Label.new()
	if _character.level >= CharacterData.MAX_LEVEL:
		level_label.text = tr("UI_CHAR_LEVEL_CAP") % _character.level
	else:
		var required := CharacterData.xp_required_for_level(_character.level)
		level_label.text = tr("UI_CHAR_LEVEL") % [_character.level, _character.xp, required]
	body.add_child(level_label)

	if not _character.auto_allocate:
		body.add_child(_make_hint_label(tr("UI_CHAR_UNSPENT") % [
			_character.unspent_stat_points, _character.unspent_skill_points
		]))

	var auto_check := CheckBox.new()
	auto_check.text = tr("UI_CHAR_AUTO_ALLOCATE")
	auto_check.button_pressed = _character.auto_allocate
	# Motorun boş kutusu koyu sütun zemininde görünmüyordu (ölçüldü): kutuyu
	# sütunun kendi kehribar çizgisiyle çiziyoruz.
	auto_check.add_theme_icon_override("unchecked", _check_icon(false))
	auto_check.add_theme_icon_override("checked", _check_icon(true))
	auto_check.toggled.connect(_on_auto_allocate_toggled)
	body.add_child(auto_check)

# --- Kuşam ve görev sekmesi ---

func _build_gear_page() -> void:
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 40)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(columns)

	var outfit_column := _make_column(tr("UI_CHAR_APPEARANCE"))
	var outfit_body := _body_of(outfit_column)
	outfit_column.size_flags_stretch_ratio = 1.1
	columns.add_child(outfit_column)
	_build_appearance_into(outfit_body)

	var equipment_column := _make_column(tr("UI_CHAR_EQUIPMENT"))
	var equipment_body := _body_of(equipment_column)
	equipment_column.size_flags_stretch_ratio = 1.1
	columns.add_child(equipment_column)
	for slot in EquipmentCatalog.ALL_SLOTS:
		equipment_body.add_child(_build_equipment_slot_row(slot))

	var duty_column := _make_column(tr("UI_DUTY"))
	var duty_body := _body_of(duty_column)
	duty_column.size_flags_stretch_ratio = 0.8
	columns.add_child(duty_column)
	_build_duty_into(duty_body)
	if _character.can_multiclass():
		duty_body.add_child(_spacer(10))
		var heading := Label.new()
		heading.text = tr("UI_CHAR_SECOND_CLASS")
		heading.add_theme_font_size_override("font_size", SUBHEADING_FONT_SIZE)
		heading.add_theme_color_override("font_color", ArtPalette.GRIM_AMBER)
		duty_body.add_child(heading)
		_build_multiclass_into(duty_body)

## Görünüm ve kuşam: iskelet üstünde, duran pozda kişinin kendisi ve
## kıyafet slotları. Kıyafet yalnızca karakter oluşturmada seçilirdi; artık
## burada da değişiyor. Ekipman yandaki sütunda takılıyor, ama önizleme
## ikisini birden gösteriyor - kılıç, zırh, ceket aynı figürde.
func _build_appearance_into(body: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	body.add_child(row)
	var preview := FigurePreview.new()
	preview.custom_minimum_size = GEAR_PREVIEW_SIZE
	row.add_child(preview)
	preview.show_character(_character)

	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slots)
	for slot in OutfitCatalog.ALL_SLOTS:
		slots.add_child(_build_outfit_row(slot))
	# Giysinin soğuğa karşı toplamı (Temperature): yolun kış gecesine bu sayıyla gidiliyor.
	var warmth := Label.new()
	warmth.text = tr("UI_CHARACTER_WARMTH") % Temperature.round_text(_character.get_warmth())
	warmth.add_theme_color_override("font_color", ArtPalette.GRIM_AMBER)
	slots.add_child(warmth)

func _build_outfit_row(slot: String) -> VBoxContainer:
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	holder.add_child(row)
	var name_label := Label.new()
	name_label.text = OutfitCatalog.get_slot_display_name(slot)
	name_label.custom_minimum_size = Vector2(96, 0)
	row.add_child(name_label)
	var prev_button := Button.new()
	prev_button.text = "<"
	prev_button.pressed.connect(_on_outfit_cycle.bind(slot, -1))
	row.add_child(prev_button)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(150, 0)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	var piece := OutfitCatalog.get_piece(_character.get_outfit_piece(slot))
	if piece != null:
		value_label.text = piece.display_name
	elif OutfitCatalog.is_plain_cloth_slot(_character.outfit, slot):
		value_label.text = tr("UI_OUTFIT_PLAIN")
	else:
		value_label.text = tr("UI_CREATE_OUTFIT_NONE")
	row.add_child(value_label)
	# Dolapta bu slota ait başka bir şey yoksa oklar bir yere götürmüyor:
	# kapalı, nedeni altında (kilitli seçim gizlenmez, nedeniyle gösterilir).
	var choices := _session.get_outfit_choices(_character, slot)
	var stuck := choices.size() <= 1
	prev_button.disabled = stuck
	var next_button := Button.new()
	next_button.text = ">"
	next_button.pressed.connect(_on_outfit_cycle.bind(slot, 1))
	next_button.disabled = stuck
	row.add_child(next_button)
	if stuck:
		prev_button.tooltip_text = tr("UI_CHAR_OUTFIT_LOCKER_EMPTY")
		next_button.tooltip_text = tr("UI_CHAR_OUTFIT_LOCKER_EMPTY")
		var reason := _make_hint_label(tr("UI_CHAR_OUTFIT_LOCKER_EMPTY"))
		reason.add_theme_font_size_override("font_size", WaybookTheme.FONT_MIN)
		reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		holder.add_child(reason)
	return holder

## Kaydırıcı yalnızca elde olanları dolaşır: üstündeki ve dolapta o slota
## ait olanlar (GameSession.get_outfit_choices). Seçmek giydirmek, "hiçbiri"
## çıkarmak - ikisi de dolaptan geçiyor, giysi yoktan var olmuyor.
func _on_outfit_cycle(slot: String, direction: int) -> void:
	var choices := _session.get_outfit_choices(_character, slot)
	var index := maxi(0, choices.find(_character.get_outfit_piece(slot)))
	var next := choices[wrapi(index + direction, 0, choices.size())]
	if next.is_empty():
		_session.take_off_outfit(_character, slot)
	else:
		_session.wear_outfit(_character, next)
	_refresh()

func _build_duty_into(body: VBoxContainer) -> void:
	body.add_child(_make_hint_label(tr("UI_CHAR_DUTY_HINT")))

	var duty_row := HBoxContainer.new()
	duty_row.add_theme_constant_override("separation", 8)
	duty_row.add_child(WaybookIcons.picture(WaybookIcons.DUTY_EMBLEMS, _character.duty_id, EMBLEM_SIZE))
	var duty_button := OptionButton.new()
	duty_button.fit_to_longest_item = false
	duty_button.clip_text = true
	duty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duty_button.add_item(tr("UI_DUTY_NONE"))
	var duties := DutyCatalog.get_duties()
	var selected_index := 0
	for i in duties.size():
		var duty: Duty = duties[i]
		var holder := _session.get_duty_holder(duty.duty_id)
		var suffix := ""
		if holder != null and holder != _character:
			suffix = " " + tr("UI_DUTY_HELD_BY") % holder.character_name
		duty_button.add_item("%s%s" % [duty.display_name, suffix])
		if _character.duty_id == duty.duty_id:
			selected_index = i + 1
	duty_button.select(selected_index)
	duty_button.item_selected.connect(_on_duty_selected.bind(duties))
	duty_row.add_child(duty_button)
	body.add_child(duty_row)

func _build_multiclass_into(body: VBoxContainer) -> void:
	body.add_child(_make_hint_label(tr("UI_CHAR_MULTICLASS_HINT")))

	var class_button := OptionButton.new()
	class_button.fit_to_longest_item = false
	class_button.clip_text = true
	class_button.add_item(tr("UI_DUTY_NONE"))
	var options: Array[CharacterClass] = []
	var selected_index := 0
	for character_class in ClassCatalog.get_classes():
		if character_class.class_id == _character.class_id:
			continue
		options.append(character_class)
		class_button.add_item(character_class.display_name)
		if _character.second_class_id == character_class.class_id:
			selected_index = options.size()
	class_button.select(selected_index)
	class_button.item_selected.connect(_on_second_class_selected.bind(options))
	body.add_child(class_button)

func _build_equipment_slot_row(slot: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)

	var equipped := _character.get_equipped(slot)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)

	var slot_label := Label.new()
	slot_label.text = "%s:" % EquipmentCatalog.get_slot_display_name(slot)
	slot_label.custom_minimum_size = Vector2(70, 0)
	header.add_child(slot_label)

	# Takılı parçanın kendi resmi - boşken bir yer tutucu (bkz.
	# WaybookTheme.equipment_icon), satır hizası kayıp/dolu arasında oynamasın.
	header.add_child(
		WaybookTheme.equipment_icon(equipped.equipment_id, EQUIP_ICON_HEIGHT) if equipped != null
		else WaybookTheme.equipment_icon("", EQUIP_ICON_HEIGHT)
	)

	var equipped_label := Label.new()
	equipped_label.text = _equipment_summary(equipped) if equipped != null else tr("UI_CHAR_EMPTY_SLOT")
	equipped_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	equipped_label.modulate = HINT_COLOR if equipped == null else POSITIVE_COLOR
	equipped_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(equipped_label)

	var unequip_button := Button.new()
	unequip_button.text = tr("UI_CHAR_UNEQUIP")
	unequip_button.disabled = equipped == null
	unequip_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	unequip_button.pressed.connect(_on_unequip_pressed.bind(slot))
	header.add_child(unequip_button)

	column.add_child(header)

	for candidate in EquipmentCatalog.get_equipment_for_slot(slot):
		var available := _session.get_equipment_count(candidate.equipment_id)
		if available <= 0 or candidate.equipment_id == _character.get_equipped_id(slot):
			continue
		column.add_child(_build_equip_option_row(slot, candidate, available))

	return column

func _build_equip_option_row(slot: String, candidate: Equipment, available: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(WaybookTheme.equipment_icon(candidate.equipment_id, EQUIP_ICON_HEIGHT))

	var equip_button := Button.new()
	equip_button.tooltip_text = candidate.description
	equip_button.pressed.connect(_on_equip_pressed.bind(slot, candidate.equipment_id))
	# Kilitli seçenek gizlenmez, sebebiyle gösterilir - olay kartlarındaki ve
	# savaştaki yetenek kilidiyle aynı kural: oyuncu neye hazırlanacağını
	# görmeli (bkz. Equipment.required_level).
	if _session.can_equip(_character, candidate.equipment_id):
		equip_button.text = tr("UI_CHAR_EQUIP") % [candidate.display_name, available]
	else:
		equip_button.disabled = true
		equip_button.text = tr("UI_CHAR_EQUIP_LOCKED") % [
			candidate.display_name, candidate.required_level
		]
	row.add_child(equip_button)

	var bonus_label := Label.new()
	bonus_label.text = _equipment_bonus_text(candidate)
	bonus_label.modulate = HINT_COLOR
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bonus_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bonus_label)

	return row

func _equipment_summary(equipment_resource: Equipment) -> String:
	return "%s — %s" % [equipment_resource.display_name, _equipment_bonus_text(equipment_resource)]

func _equipment_bonus_text(equipment_resource: Equipment) -> String:
	var parts: Array[String] = []
	if equipment_resource.hp_bonus != 0:
		parts.append(tr("UI_BONUS_HP") % equipment_resource.hp_bonus)
	if equipment_resource.dodge_bonus != 0:
		parts.append(tr("UI_BONUS_DODGE") % equipment_resource.dodge_bonus)
	if equipment_resource.accuracy_bonus != 0:
		parts.append(tr("UI_BONUS_ACCURACY") % equipment_resource.accuracy_bonus)
	if equipment_resource.crit_bonus != 0:
		parts.append(tr("UI_BONUS_CRIT") % equipment_resource.crit_bonus)
	if equipment_resource.damage_bonus != 0:
		parts.append(tr("UI_BONUS_DAMAGE") % equipment_resource.damage_bonus)
	return ", ".join(parts)

# --- Yapı taşları ---

## İnce kehribar çerçeveli koyu bir sütun (RoadControlPanel._panel_box'ın
## ailesi): kehribar başlık, altında ince çizgi, sonra içerik (`_body_of`).
func _make_column(title: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _column_box())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(COLUMN_MIN_WIDTH, 0)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	panel.add_child(outer)
	outer.add_child(_heading_label(title, HEADING_FONT_SIZE))
	outer.add_child(_make_rule(0.45))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(body)
	return panel

## Taslağın başlık yazısı: IM Fell küçük büyük harf, soluk altın.
func _heading_label(text: String, font_size: int) -> Label:
	var heading := Label.new()
	heading.text = text
	heading.add_theme_font_override("font", GrimTheme.title_font())
	heading.add_theme_font_size_override("font_size", font_size)
	heading.add_theme_color_override("font_color", ArtPalette.MENU_TITLE_GOLD)
	return heading

## Sütunun içerik kutusu: başlık ve çizginin altındaki VBox.
func _body_of(panel: PanelContainer) -> VBoxContainer:
	return panel.get_child(0).get_child(2) as VBoxContainer

func _column_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.88)
	box.border_color = Color(ArtPalette.MENU_TITLE_GOLD, 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 20
	box.content_margin_bottom = 20
	return box

func _make_rule(alpha: float) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(ArtPalette.MENU_TITLE_GOLD, alpha)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer

func _make_row_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", ROW_FONT_SIZE)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label

func _make_hint_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
	label.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_DIM.lightened(0.2))
	return label

const CHECK_ICON_SIZE: int = 18

func _check_icon(checked: bool) -> ImageTexture:
	var image := Image.create(CHECK_ICON_SIZE, CHECK_ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var line := Color(ArtPalette.GRIM_AMBER, 0.85)
	var last := CHECK_ICON_SIZE - 1
	for i in CHECK_ICON_SIZE:
		image.set_pixel(i, 0, line)
		image.set_pixel(i, last, line)
		image.set_pixel(0, i, line)
		image.set_pixel(last, i, line)
	if checked:
		image.fill_rect(Rect2i(4, 4, CHECK_ICON_SIZE - 8, CHECK_ICON_SIZE - 8), ArtPalette.GRIM_AMBER)
	return ImageTexture.create_from_image(image)

func _make_plus_button() -> Button:
	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(32, 0)
	plus_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return plus_button

# --- Girdi olayları ---

func _on_tab_pressed(index: int) -> void:
	if _tab == index:
		return
	_tab = index
	_refresh()

func _on_stat_invest_pressed(kind: CharacterStats.Kind) -> void:
	_character.invest_stat_point(kind)
	_refresh()

func _on_skill_invest_pressed(skill_id: String) -> void:
	_character.invest_skill_point(skill_id)
	_refresh()

func _on_auto_allocate_toggled(pressed: bool) -> void:
	_character.auto_allocate = pressed
	if pressed:
		_character.flush_pending_points()
	_refresh()

func _on_duty_selected(index: int, duties: Array) -> void:
	if index <= 0:
		_session.assign_duty(_character, "")
	else:
		var duty: Duty = duties[index - 1]
		_session.assign_duty(_character, duty.duty_id)
	_refresh()

func _on_second_class_selected(index: int, options: Array) -> void:
	if index <= 0:
		_character.clear_second_class()
	else:
		var character_class: CharacterClass = options[index - 1]
		_character.set_second_class(character_class.class_id)
	_refresh()

func _on_equip_pressed(slot: String, equipment_id: String) -> void:
	_session.equip_to_character(_character, slot, equipment_id)
	_refresh()

func _on_unequip_pressed(slot: String) -> void:
	_session.unequip_from_character(_character, slot)
	_refresh()

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
