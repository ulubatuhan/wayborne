class_name CombatPanel
extends VBoxContainer

## Savaş arayüzünün yeniden kullanılabilir hali. Yol olaylarındaki
## TRIGGER_COMBAT etkisi ve dev panelindeki savaş testi bunu kullanır,
## böylece savaş mantığı tek yerde durur (bkz. HagglingPanel deseni).
##
## Sahne dosyası yok: panel kendini kodda kurar, yolculuk ekranının içine
## gömülür. Böylece sefer sırasında sahne değiştirip durum taşımak
## gerekmez.
##
## **Bu ekran bir savaş alanı, bir liste değil.** Önceki hali dikey bir
## yığındı - düşman listesi, parti listesi, yetenek tuşları, *ayrı* bir
## hedef tuşu listesi - ve mevkiler yalnızca sayı olarak yazıyordu. Yani
## motor pozisyona dayalıydı ama ekran değildi; pozisyonun bütün anlamı
## kaybolduğu için savaş bir visual novel gibi okunuyordu. Şimdi iki
## karşılıklı saf var, hedef sahnede tıklanıyor, mevki kilidi yetenek
## kartının üzerindeki belirteçlerden okunuyor.

## dead_characters: savaşta kalıcı ölen CharacterData listesi (bkz.
## CombatUnit'in Ölümün Kıyısı bölümü). Panel bunu *uygulamaz* - partiden
## çıkarma ve liderliğin devri oturumun işi, ekranın değil.
signal combat_finished(victory, xp_awarded, downed_count, dead_characters)  # bool, int, int, Array[CharacterData]
## Bedelli geri çekilmenin türü (Y-C07); combat_finished'ten önce gelir.
signal retreated(kind)  # String
## Zaferde düşen ganimet (Y-C03) ve savaşta kullanılan sarf (Y-C04);
## combat_finished'ten önce gelir, yol ekranı kervana uygular.
signal loot_rolled(drops)  # Array[Dictionary]
signal consumables_used(used)  # Dictionary item_id -> adet

## Kervanda olan sarf (yol ekranı verir) ve bu savaşta kullanılanlar.
var consumables: Dictionary = {}
var _used: Dictionary = {}
var _loot: Array[Dictionary] = []

const MAX_LOG_LINES: int = 40
## Yorum balonu ne kadar sürsün. Slotlar her `_refresh()`'te yeniden
## kuruluyor (bkz. `_refresh_side`), o yüzden balon bir Tween'le değil
## gerçek zaman damgasıyla tutuluyor - `_bark_texts` her yeni slota
## `bind()`'tan sonra süresi geçmemişse yeniden basılıyor.
const BARK_DURATION_MSEC: int = 2200

## Hasar sayılarının yazı boyu.
const NUMBER_FONT_SIZE: int = 20

## Parlama renkleri ArtPalette.FX_FLASH_* - renk tek yerden gelir.

## Mevki belirteçleri: dolu nokta "burada durabilir" / "buraya vurabilir",
## boş nokta duramaz/vuramaz. Sayı yerine şekil, çünkü oyuncunun bunu okumak için durup
## düşünmemesi gerekiyor.
##
## Bir süre `●`/`○` karakterleriyle yazılıyordu ve ekranda **boş kutu**
## olarak çıkıyordu: varsayılan font Geometric Shapes bloğunu taşımıyor.
## Playtest'in fotoğrafladığı hata buydu. Artık çiziliyor (bkz. `UiIcon`),
## ki zaten oyunun geri kalanının çizim dili bu.
const MARK_SIZE: float = 13.0
## Pirinç düğme pipler (K5): dolu "burada/buraya", boş "değil". Renk hâlâ
## çıkış/hedef ayrımını taşıyor, düğmenin kendisi dokudan.
const PIP_FILLED_FILE: String = "k5_pip_filled.png"
const PIP_HOLLOW_FILE: String = "k5_pip_hollow.png"
## Alan ve kaydırma işaretleri (K7) yeteneğin not satırının başında.
const AREA_GLYPH_HEIGHT: float = 16.0
const LAUNCH_COLOR: Color = Color(0.95, 0.82, 0.45)
## Taslağın yetenek kartı (1080p): 200x110, adı büyük, altında isabet.
const SKILL_CARD_WIDTH: float = 200.0
const SKILL_CARD_HEIGHT: float = 112.0
const MEDAL_SIZE: float = 104.0
const BOTTOM_PANEL_HEIGHT: float = 250.0
## Düşmanın huyu (CombatUnit.behavior, Y-C08) sağ panelde bir cümle.
const BEHAVIOR_KEYS: Dictionary = {
	"": "UI_COMBAT_BEHAVIOR_WEAKEST",
	"leader_hunter": "UI_COMBAT_BEHAVIOR_LEADER",
	"pack": "UI_COMBAT_BEHAVIOR_PACK",
	"guard": "UI_COMBAT_BEHAVIOR_GUARD",
	"beast": "UI_COMBAT_BEHAVIOR_BEAST",
}
## Savaş alanının en az yüksekliği. İlk denemede alan 900 pikselin
## üst 200'ünde ince bir şeritti; savaş alanı ekranın kendisi olmalı.
const STAGE_HEIGHT: float = 480.0
const TARGET_MARK_COLOR: Color = Color(0.90, 0.45, 0.40)

var _encounter: CombatEncounter
var _selected_skill: CombatSkill
var _built: bool = false

var _round_label: Label
var _medal: RoundMedal
var _target_heading: Label
var _target_bar: HpLine
var _target_stats: Label
var _target_behavior: Label
var _order_strip: HBoxContainer
var _fx_layer: CombatFxLayer
var _player_row: HBoxContainer
var _enemy_row: HBoxContainer
var _active_label: Label
var _hint_label: Label
var _skill_row: HBoxContainer
var _extra_row: HFlowContainer
var _result_label: Label
var _continue_button: Button
var _log_scroll: ScrollContainer
var _log_list: VBoxContainer
var _bark_texts: Dictionary = {}  # CombatUnit -> {"text": String, "expires_at": int}
var _flash_states: Dictionary = {}  # CombatUnit -> {"color": Color, "start": int, "duration": int}
var _lunge_states: Dictionary = {}  # CombatUnit -> {"direction": float, "magnitude": float, "start": int}
var _fall_states: Dictionary = {}  # CombatUnit -> {"start": int}
var _action_states: Dictionary = {}  # CombatUnit -> {"role": String, "start": int, "duration": int}
var _ring_states: Dictionary = {}  # CombatUnit -> {"color": Color, "start": int}
var _shake: Dictionary = {}  # {"amplitude": float, "start": int}
## Yüzen hasar/iyileşme sayıları: {"unit", "label", "start", "slot_index"}.
var _numbers: Array = []
## Son görülen can - sayılar motorun ne dediğinden değil, canın gerçekte
## ne kadar değiştiğinden çıkıyor (zırh, Kıyı, iyileşme tavanı hepsi
## zaten içinde).
var _hp_seen: Dictionary = {}  # CombatUnit -> int
var _backdrop: CombatBackdrop
## Son vuruşu kritik olan birimler: sayısı kritik renginde çıkıyor.
var _crit_marks: Dictionary = {}  # CombatUnit -> true
## Kritik yakınlaşması (Y-H05): {"start": int, "pivot": Vector2} ya da boş.
var _zoom: Dictionary = {}
var _stage: Control
var _slot_by_unit: Dictionary = {}  # CombatUnit -> CombatUnitSlot
var _fx_overlay: Control

func _ready() -> void:
	_ensure_built()

## Verilen parti ve tehlike seviyesiyle yeni bir savaş açar. Parti
## CharacterData listesidir; sıralaması mevki sırasıdır. Kırılmışlık
## GameSession'dan geçirilir - kırılma noktasını aşmış (bkz.
## CharacterData.is_stressed) her karakter emirlere kulak asmayabilir -
## ve bu artık kadronun ortalamasına değil kişinin kendi stresine bakıyor.
func start_combat(
	party: Array[CharacterData], danger_level: float,
	rng: RandomNumberGenerator = null,
	enemy_kind: String = "bandit", region_id: String = "", biome: String = "", look: String = ""
) -> void:
	_ensure_built()
	# Arka plan yolun o konumdaki resmi (RouteTerrain.look_of); kadro biyomu okuyor.
	_backdrop.biome = look if not look.is_empty() else biome

	var combat_rng := rng
	if combat_rng == null:
		combat_rng = RandomNumberGenerator.new()
		combat_rng.randomize()

	var units: Array[CombatUnit] = []
	var position := 1
	var level_total := 0
	for character in party:
		if position > CombatEncounter.MAX_SIDE_SIZE:
			break
		units.append(CombatUnit.from_character(character, position, character.is_stressed()))
		level_total += character.level
		position += 1

	var average_level := int(round(float(level_total) / float(maxi(1, units.size()))))
	var enemies := EnemyCatalog.build_squad(
		enemy_kind, region_id, danger_level, units.size(), combat_rng, average_level, biome
	)
	var enemy_label := EnemyCatalog.get_kind_label(enemy_kind)

	_apply_muhafiz_opening_bonus(party, units)

	_encounter = CombatEncounter.new(units, enemies, combat_rng, enemy_label)
	_encounter.log_added.connect(_on_log_added)
	_encounter.state_changed.connect(_on_state_changed)
	_encounter.unit_barked.connect(_on_unit_barked)
	_encounter.skill_resolving.connect(_on_skill_resolving)

	_selected_skill = null
	_result_label.text = ""
	_continue_button.visible = false
	NodeUtil.clear_children(_log_list)
	_bark_texts.clear()
	_reset_fx()

	_encounter.start()
	for unit in _encounter.player_units + _encounter.enemy_units:
		_hp_seen[unit] = unit.current_hp
	_refresh()

## Muhafız görevini tutan biri varsa kadro ilk tura iyi konumlanmış girer:
## herkese tek turluk bir isabet bonusu. DutyCatalog.get_duty_power()
## zaten sınıf eşleşmesini ve statı hesaba katıyor, burada yalnızca sayıya
## çeviriyoruz.
func _apply_muhafiz_opening_bonus(party: Array[CharacterData], units: Array[CombatUnit]) -> void:
	var holder: CharacterData = null
	for character in party:
		if character.duty_id == DutyCatalog.MUHAFIZ:
			holder = character
			break
	if holder == null:
		return

	var power := DutyCatalog.get_duty_power(holder, DutyCatalog.MUHAFIZ)
	var bonus := int(round(10.0 * (power - 1.0)))
	if bonus <= 0:
		return
	for unit in units:
		unit.apply_modifier("accuracy", bonus, 1)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ArtPalette.GRIM_CHARCOAL)

# --- Kurulum ---

func _ensure_built() -> void:
	if _built:
		return
	_built = true
	# Savaş ekranın tamamı (yolun HUD'u o sırada gizli): kendi koyu zemini var.
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)

	add_theme_constant_override("separation", 6)
	_build_header()
	_build_field()
	_build_action_area()
	_build_log()

## Üstte ortada tur madalyonu (taslak 9.8 + Y-G05, y_98_savas.png): altın
## halkada Roma rakamıyla tur, altında "N. tur" ve küçük harflerle bu turun
## sırası. Sıra hız zarıyla her tur değişiyor (CombatEncounter.SPEED_DIE),
## o yüzden kalıyor; taslakta yalnız madalyon vardı.
func _build_header() -> void:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 2)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := Control.new()
	top.custom_minimum_size = Vector2(0, 14)
	header.add_child(top)
	_medal = RoundMedal.new()
	_medal.custom_minimum_size = Vector2(MEDAL_SIZE, MEDAL_SIZE)
	_medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.add_child(_medal)
	_round_label = Label.new()
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.add_theme_font_size_override("font_size", 22)
	_round_label.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_BONE)
	header.add_child(_round_label)
	_order_strip = HBoxContainer.new()
	_order_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	_order_strip.add_theme_constant_override("separation", 10)
	header.add_child(_order_strip)
	add_child(header)

## İki karşılıklı saf. Oyuncu tarafı ters sırada diziliyor: 1. mevki
## ortaya, yani düşmanın 1. mevkisinin karşısına gelmeli - "ön saf" ancak
## karşı karşıya durunca anlam taşır.
func _build_field() -> void:
	# Figürler boşlukta duruyordu ve savaş bir tabloya benziyordu. Zemin
	# katmanı (karanlık kuyu + ufuk + meşale ışığı + vinyet) saflardan
	# *önce* çiziliyor; saflar onun üstünde duruyor.
	var stage := Panel.new()
	var stage_style := StyleBoxFlat.new()
	stage_style.bg_color = Color(0, 0, 0, 0)
	stage_style.border_color = Color(0.30, 0.25, 0.18, 0.8)
	stage_style.set_border_width_all(1)
	stage.add_theme_stylebox_override("panel", stage_style)
	# Dikeyde *uzamıyor*: EXPAND_FILL'de eldeki bütün boşluğu yutup
	# figürleri dibe itiyordu. Sahne her ekranda aynı yükseklikte durmalı.
	stage.custom_minimum_size = Vector2(0.0, STAGE_HEIGHT)
	stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	add_child(stage)
	_stage = stage
	stage.resized.connect(_fit_row_separation)

	var backdrop := CombatBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(backdrop)
	_backdrop = backdrop

	var field := HBoxContainer.new()
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.add_theme_constant_override("separation", 10)
	field.alignment = BoxContainer.ALIGNMENT_CENTER

	_player_row = HBoxContainer.new()
	# Hayvan portreleri artık kutularını bilerek aşıyor (bkz. CombatFigure'ın
	# kendi notu - ayı/domuz/kurt reisleri gerçek boylarında çiziliyor).
	# Eski 4px ayraç bitişik mevkilerdeki iki büyük hayvanı üst üste
	# bindiriyordu (domuz sürüsü - kullanıcının kendi bildirdiği hata);
	# 4 → 56 taşan gövdelere gerçek bir boşluk bıraktı, ama kurt sürüsü
	# reisinin (bulk 2.6, sıradan kurdun kendi uzun kuyruk vektörüyle
	# çarpılınca ~2.3x genişlik taşması) kuyruğu 56px'i de aşıp arkasındaki
	# sıradan kurdun üstüne biniyordu - kullanıcının kendi ekran görüntüsüyle
	# bildirdiği hata. 56 → 160: merkez boşluğuyla (aşağıdaki `gap`) aynı
	# değer, çünkü ikisi de aynı riski taşıyor - taşan bir ayı/kurt reisinin
	# gövdesi komşu mevkiye bakıyor.
	_player_row.add_theme_constant_override("separation", 160)
	_player_row.alignment = BoxContainer.ALIGNMENT_END
	_player_row.size_flags_vertical = Control.SIZE_SHRINK_END
	_player_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(_player_row)

	# İki tarafın en önü tam burada karşı karşıya duruyor - ve en öndeki
	# mevkiler taşan hayvan portrelerinin (bkz. CombatFigure'ın kendi notu)
	# kaçamayacağı tek yer, çünkü ikisi de bu boşluğa bakan tarafa hizalı
	# (`_player_row` ALIGNMENT_END, `_enemy_row` ALIGNMENT_BEGIN). Eski 26px
	# ince çizgi ayrımı için yeterliydi ama bir ayının/kurt reisinin gövdesi
	# önündeki mevkiyi kolayca aşıyor - kullanıcının kendi bildirdiği "parti
	# ile düşman arası boşluk da ezilmiş" hatası. 26 → 160, satır içi
	# ayraçtan (56) da geniş: en riskli sınır en geniş boşluğu alıyor.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(160.0, 0.0)
	field.add_child(gap)

	_enemy_row = HBoxContainer.new()
	# bkz. `_player_row`'un kendi yorumu - aynı 160px, aynı sebep.
	_enemy_row.add_theme_constant_override("separation", 160)
	_enemy_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_enemy_row.size_flags_vertical = Control.SIZE_SHRINK_END
	_enemy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(_enemy_row)

	stage.add_child(field)

	# Yüzen sayılar sahnenin üstünde ama saflardan bağımsız bir katmanda:
	# slotlar her tazelemede yeniden kurulurken sayı yaşamaya devam etmeli.
	_fx_overlay = Control.new()
	_fx_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_fx_overlay)

	_fx_layer = CombatFxLayer.new()
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(_fx_layer)

## Altta iki panel (taslak): solda sırası gelen kişi ve yetenek kartları,
## altında mevki değişimi, sargı/iksir, geri çekilme; sağda hedef - üstüne
## gelinen ya da seçili yeteneğin ilk hedefi, yoksa düşmanın ön safı: canı,
## zırhı, durumları, huyu - ve altında savaşın kaydı.
func _build_action_area() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 40)
	margin.add_child(bottom)

	var left := _bottom_panel()
	bottom.add_child(left)
	var left_col: VBoxContainer = left.get_child(0)
	_active_label = _panel_heading()
	left_col.add_child(_active_label)
	left_col.add_child(_panel_rule())
	_skill_row = HBoxContainer.new()
	_skill_row.add_theme_constant_override("separation", 14)
	left_col.add_child(_skill_row)
	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_DIM)
	left_col.add_child(_hint_label)
	# Satır kırılıyor: mevki değişimi ve geri çekilme düğmeleri bir arada
	# sol paneli genişletip hedef panelini eziyordu.
	_extra_row = HFlowContainer.new()
	_extra_row.add_theme_constant_override("h_separation", 6)
	_extra_row.add_theme_constant_override("v_separation", 6)
	left_col.add_child(_extra_row)
	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_result_label.add_theme_font_size_override("font_size", 22)
	left_col.add_child(_result_label)
	_continue_button = Button.new()
	_continue_button.text = tr("UI_COMBAT_CONTINUE")
	_continue_button.visible = false
	_continue_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_continue_button.custom_minimum_size = Vector2(220, 0)
	_continue_button.pressed.connect(_on_continue_pressed)
	left_col.add_child(_continue_button)

	var right := _bottom_panel()
	bottom.add_child(right)
	var right_col: VBoxContainer = right.get_child(0)
	_target_heading = _panel_heading()
	right_col.add_child(_target_heading)
	right_col.add_child(_panel_rule())
	_target_bar = HpLine.new()
	_target_bar.custom_minimum_size = Vector2(0, 12)
	right_col.add_child(_target_bar)
	_target_stats = Label.new()
	_target_stats.add_theme_font_size_override("font_size", 22)
	_target_stats.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_BONE)
	right_col.add_child(_target_stats)
	_target_behavior = Label.new()
	_target_behavior.add_theme_font_size_override("font_size", 18)
	_target_behavior.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_DIM)
	right_col.add_child(_target_behavior)
	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_scroll.custom_minimum_size = Vector2(0, 60)
	right_col.add_child(_log_scroll)
	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_list)
	var foot := Control.new()
	foot.custom_minimum_size = Vector2(0, 16)
	add_child(foot)

## Kayıt sağ panelin altında (bkz. `_build_action_area`); ayrı bir kutu yok.
func _build_log() -> void:
	pass

func _bottom_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.92)
	box.border_color = Color(ArtPalette.MENU_TITLE_GOLD, 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", box)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, BOTTOM_PANEL_HEIGHT)
	# İki panel eşit: içerik genişliği paneli büyütmesin.
	panel.clip_contents = true
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	return panel

func _panel_heading() -> Label:
	var heading := Label.new()
	heading.add_theme_font_override("font", WaybookTheme.title_font())
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", ArtPalette.MENU_TITLE_GOLD)
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return heading

func _panel_rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(ArtPalette.MENU_TITLE_GOLD, 0.45)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

# --- Tazeleme ---

func _refresh() -> void:
	if _encounter == null:
		return
	_refresh_header()
	_refresh_side(_player_row, _encounter.player_units, true)
	_refresh_side(_enemy_row, _encounter.enemy_units, false)
	_fit_row_separation.call_deferred()
	_refresh_actions()
	_refresh_target()
	_spawn_hp_numbers()
	_animate(Time.get_ticks_msec())

## Dört mevki yan yana 160 px'lik ayraçla 1920 px'e sığmıyordu: en arkadaki
## düşman kadrajdan taşıyordu. Ayraç, sığmayacağı kadar genişse daralır;
## sığıyorsa eski 160 kalır.
const MIN_ROW_SEPARATION: float = 12.0
const MAX_ROW_SEPARATION: float = 160.0

func _fit_row_separation() -> void:
	for row in [_player_row, _enemy_row]:
		if row == null or not is_instance_valid(row) or row.get_child_count() < 2 or _stage == null or _stage.size.x <= 0.0:
			continue
		var content := 0.0
		for child in row.get_children():
			content += (child as Control).get_combined_minimum_size().x
		var spare := ((_stage.size.x - 160.0) * 0.5 - content) / float(row.get_child_count() - 1)
		row.add_theme_constant_override("separation", int(clampf(spare, MIN_ROW_SEPARATION, MAX_ROW_SEPARATION)))

func _refresh_header() -> void:
	_round_label.text = tr("UI_COMBAT_ROUND") % _encounter.round_number
	_medal.set_round(_encounter.round_number)
	NodeUtil.clear_children(_order_strip)
	if _encounter.is_over():
		return
	var active := _encounter.get_active_unit()
	for unit in _encounter.get_turn_order():
		if not unit.is_alive():
			continue
		_order_strip.add_child(_build_order_chip(unit, unit == active))

func _build_order_chip(unit: CombatUnit, is_active: bool) -> Label:
	var chip := Label.new()
	chip.text = unit.display_name
	chip.add_theme_font_size_override("font_size", 15)
	if is_active:
		chip.modulate = CombatUnitSlot.ACTIVE_BORDER
	elif unit.is_player_side:
		chip.modulate = Color(0.6, 0.74, 0.6)
	else:
		chip.modulate = Color(0.78, 0.55, 0.52)
	return chip

## Bir safın mevkilerini kurar. Oyuncu tarafı ters diziliyor (bkz.
## _build_field). Hedeflenebilirlik seçili yetenekten geliyor, o yüzden
## her tazelemede yeniden hesaplanıyor.
func _refresh_side(row: HBoxContainer, units: Array[CombatUnit], reversed_order: bool) -> void:
	for child in row.get_children():
		var old := child as CombatUnitSlot
		if old != null and _slot_by_unit.get(old.unit) == old:
			_slot_by_unit.erase(old.unit)
	NodeUtil.clear_children(row)

	var ordered: Array[CombatUnit] = units.duplicate()
	ordered.sort_custom(func(a, b): return a.position < b.position)
	if reversed_order:
		ordered.reverse()

	var active := _encounter.get_active_unit()
	var targets := _current_targets()
	for unit in ordered:
		var slot := CombatUnitSlot.new()
		row.add_child(slot)
		slot.bind(unit, unit == active and not _encounter.is_over(), targets.has(unit))
		slot.clicked.connect(_on_unit_clicked)
		slot.mouse_entered.connect(_on_unit_hovered.bind(unit))
		_slot_by_unit[unit] = slot
		_apply_pending_bark(slot, unit)
		_apply_pending_animation(slot, unit)

## Slotlar her tazelemede yeniden kuruluyor (bkz. `_refresh_side`'ın kendi
## yorumu), o yüzden balon burada -panelde- gerçek zaman damgasıyla tutulup
## yeni slota basılıyor; süresi geçmişse hiç basılmıyor ve unutuluyor.
##
## `kind` (bkz. CombatEncounter.BARK_*) bir anın *türü*: hedefin parlaması,
## saldıranın hamlesi (isabet/kritik/kaçırma - o an sırası gelen birim,
## `_encounter.get_active_unit()`), sarsıntı, düşüş, durum halkası. Reddin
## kendisi bir hamle değil, yalnızca soluk bir parlama. Metni boş bir bark
## (durum efektleri) balon açmıyor - o bir yorum değil, bir an.
func _on_unit_barked(unit: CombatUnit, text: String, kind: String) -> void:
	var now := Time.get_ticks_msec()
	if not text.is_empty():
		_bark_texts[unit] = {"text": text, "expires_at": now + BARK_DURATION_MSEC}

	var flash := _flash_for_kind(kind)
	if flash != ArtPalette.FX_FLASH_NEUTRAL:
		_flash_states[unit] = {
			"color": flash, "start": now, "duration": CombatFx.flash_duration(kind),
		}
	if kind == CombatEncounter.BARK_CRIT:
		_crit_marks[unit] = true
		# Y-H05: kısa yakınlaşma hedefin üstüne, anlatıcı satırı deftere.
		if not NodeUtil.reduce_motion(self) and _stage != null:
			var slot: CombatUnitSlot = _slot_by_unit.get(unit)
			var pivot := _stage.size * 0.5
			if slot != null and is_instance_valid(slot):
				pivot = slot.get_global_rect().get_center() - _stage.get_global_rect().position
			_zoom = {"start": now, "pivot": pivot}
		_on_log_added(tr(CombatFx.crit_narration_key(_encounter.round_number, unit.position)) % unit.display_name)
	var sfx := CombatFx.hit_sfx(kind)
	if not sfx.is_empty() and is_inside_tree():
		# Autoload'a ağaçtan ulaşılıyor: panel testlerde ağaç dışında kuruluyor.
		var audio := get_tree().root.get_node_or_null("AudioManager")
		if audio != null:
			audio.play_sfx(sfx)

	if CombatFx.is_status_application(kind):
		_ring_states[unit] = {"color": CombatFx.status_color(kind), "start": now}

	# Bir kaçırma da taze bir hamle - saldıran gerçekten kılıcını salladı,
	# yalnızca değmedi. HIT/CRIT'in "bu bir vuruş girişimiydi" ailesinde,
	# DEATHS_DOOR/SURVIVED/KILLED/DOWNED'ın "bu bir sonuç" ailesinde değil.
	var magnitude := CombatFx.recoil_magnitude(kind)
	var skill := _encounter.last_skill
	var style := ""
	var delay := 0
	if magnitude > 0.0:
		var attacker := _encounter.get_active_unit()
		if attacker != null and attacker != unit:
			var ranged := skill != null and not skill.delivery.is_empty()
			if not ranged:
				_lunge_states[attacker] = {
					"direction": 1.0 if attacker.is_player_side else -1.0,
					"magnitude": magnitude, "start": now,
				}
			if skill != null:
				style = CombatFx.hit_style(skill.element, skill.delivery, _weapon_of(attacker))
				delay = CombatFxLayer.travel_msec(skill.delivery)
				_play_attack_fx(attacker, unit, skill, style, kind != CombatEncounter.BARK_MISS, now)
				if kind != CombatEncounter.BARK_MISS:
					unit.add_stuck(CombatFx.leaves_stuck(skill.delivery), now + delay)
	var reaction := CombatFx.reaction_clip(kind, style, _weapon_of(unit))
	if not reaction.is_empty():
		_action_states[unit] = {"role": reaction, "start": now + delay, "duration": CombatFx.REACT_MSEC}

	var amplitude := CombatFx.shake_amplitude(kind)
	if amplitude > 0.0 and not NodeUtil.reduce_motion(self):
		if _shake.is_empty() or amplitude >= float(_shake.get("amplitude", 0.0)) \
				or now - int(_shake.get("start", 0)) >= CombatFx.SHAKE_MSEC:
			_shake = {"amplitude": amplitude, "start": now}

	if CombatFx.starts_fall(kind):
		_fall_states[unit] = {"start": CombatFx.fall_start(kind, now)}
	set_process(true)

## Saldıranın klibi ve kendine yapılan büyü: bark'ı olmayan yarısı.
func _on_skill_resolving(unit: CombatUnit, skill: CombatSkill) -> void:
	var now := Time.get_ticks_msec()
	if skill.target_kind == CombatSkill.Target.ENEMY or skill.is_heal() or skill.base_damage > 0 or CombatFx.is_cast(skill.element, skill.delivery):
		var role := CombatFigure.ROLE_CAST if CombatFx.is_cast(skill.element, skill.delivery) else CombatFigure.ROLE_ATTACK
		_action_states[unit] = {"role": role, "start": now, "duration": CombatFx.ATTACK_MSEC}
	if skill.delivery == "aura":
		var at := _chest(unit)
		if at != Vector2.INF:
			_fx_layer.play_attack(at, at, "aura", skill.element, true, now)
	set_process(true)

func _weapon_of(unit: CombatUnit) -> String:
	return String(CombatFigure.ARCHETYPES.get(unit.figure_kind, {}).get("weapon", "none"))

## Figürün göğsü, efekt katmanının uzayında. Slotu henüz yoksa INF.
func _chest(unit: CombatUnit) -> Vector2:
	var slot: CombatUnitSlot = _slot_by_unit.get(unit)
	if slot == null or not is_instance_valid(slot) or _fx_layer == null:
		return Vector2.INF
	var rect := slot.get_figure_global_rect()
	return rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.48) - _fx_layer.get_global_rect().position

func _play_attack_fx(attacker: CombatUnit, target: CombatUnit, skill: CombatSkill, style: String, hit: bool, now: int) -> void:
	var from := _chest(attacker)
	var to := _chest(target)
	if from == Vector2.INF or to == Vector2.INF:
		return
	# Mermi elden çıkıyor: göğsün biraz önünden.
	from += Vector2(24.0 * signf(to.x - from.x), -10.0)
	_fx_layer.play_attack(from, to, skill.delivery, style, hit, now)

func _flash_for_kind(kind: String) -> Color:
	match kind:
		CombatEncounter.BARK_CRIT: return ArtPalette.FX_FLASH_CRIT
		CombatEncounter.BARK_HIT: return ArtPalette.FX_FLASH_HIT
		CombatEncounter.BARK_MISS: return ArtPalette.FX_FLASH_MISS
		CombatEncounter.BARK_REFUSE: return ArtPalette.FX_FLASH_REFUSE
		CombatEncounter.BARK_DEATHS_DOOR: return ArtPalette.FX_FLASH_DEATHS_DOOR
		CombatEncounter.BARK_SURVIVED: return ArtPalette.FX_FLASH_SURVIVED
		CombatEncounter.BARK_KILLED: return ArtPalette.FX_FLASH_KILLED
		CombatEncounter.BARK_DOWNED: return ArtPalette.FX_FLASH_DOWNED
		CombatEncounter.BARK_BLEED_TICK: return ArtPalette.FX_BLEED
		CombatEncounter.BARK_BLIGHT_TICK: return ArtPalette.FX_BLIGHT
		CombatEncounter.BARK_BURN_TICK: return ArtPalette.FX_BURN
		CombatEncounter.BARK_STUN_SKIP: return ArtPalette.FX_STUN
		_: return ArtPalette.FX_FLASH_NEUTRAL

func _apply_pending_bark(slot: CombatUnitSlot, unit: CombatUnit) -> void:
	var data: Dictionary = _bark_texts.get(unit, {})
	if data.is_empty():
		return
	if Time.get_ticks_msec() >= int(data.get("expires_at", 0)):
		_bark_texts.erase(unit)
		return
	slot.show_bark(String(data.get("text", "")))

func _apply_pending_animation(slot: CombatUnitSlot, unit: CombatUnit) -> void:
	_apply_fx(slot, unit, Time.get_ticks_msec())

## Bir birimin o anki efektlerini slotuna basar; süresi geçen kayıtları
## siler. `true` dönerse birim hâlâ canlanıyor.
func _apply_fx(slot: CombatUnitSlot, unit: CombatUnit, now: int) -> bool:
	var active := false

	var flash := ArtPalette.FX_FLASH_NEUTRAL
	var flash_data: Dictionary = _flash_states.get(unit, {})
	if not flash_data.is_empty():
		var u := CombatFx.progress(int(flash_data.get("start", 0)), int(flash_data.get("duration", 0)), now)
		if u >= 1.0:
			_flash_states.erase(unit)
		else:
			flash = CombatFx.flash_at(flash_data.get("color", ArtPalette.FX_FLASH_NEUTRAL), u)
			active = true

	var offset := _shake_offset(now, unit)
	var lunge_data: Dictionary = _lunge_states.get(unit, {})
	if not lunge_data.is_empty():
		var u := CombatFx.progress(int(lunge_data.get("start", 0)), CombatFx.RECOIL_MSEC, now)
		if u >= 1.0:
			_lunge_states.erase(unit)
		else:
			offset.x += float(lunge_data.get("direction", 1.0)) * float(lunge_data.get("magnitude", 0.0)) \
				* slot.get_figure_width() * CombatFx.recoil(u)
			active = true

	var fall := 1.0
	var fall_data: Dictionary = _fall_states.get(unit, {})
	if not fall_data.is_empty():
		fall = CombatFx.progress(int(fall_data.get("start", 0)), CombatFx.FALL_MSEC, now)
		if fall >= 1.0:
			_fall_states.erase(unit)
		else:
			active = true

	var ring_color := Color(0, 0, 0, 0)
	var ring := 1.0
	var ring_data: Dictionary = _ring_states.get(unit, {})
	if not ring_data.is_empty():
		ring = CombatFx.progress(int(ring_data.get("start", 0)), CombatFx.RING_MSEC, now)
		if ring >= 1.0:
			_ring_states.erase(unit)
		else:
			ring_color = ring_data.get("color", ring_color)
			active = true

	var role := ""
	var role_u := 0.0
	var action_data: Dictionary = _action_states.get(unit, {})
	if not action_data.is_empty():
		role_u = CombatFx.progress(int(action_data.get("start", 0)), int(action_data.get("duration", 1)), now)
		if role_u >= 1.0:
			_action_states.erase(unit)
		else:
			role = String(action_data.get("role", ""))
			active = true

	slot.apply_fx(flash, offset, fall, ring_color, ring)
	slot.apply_action(role, role_u)
	return active

## Sarsıntı her figürde aynı zarf, ama birim başına kaydırılmış bir faz:
## herkes aynı yöne aynı anda kayarsa sahne değil kamera sallanır.
func _shake_offset(now: int, unit: CombatUnit) -> Vector2:
	if _shake.is_empty():
		return Vector2.ZERO
	var elapsed := float(now - int(_shake.get("start", 0))) / 1000.0
	return CombatFx.shake_at(float(_shake.get("amplitude", 0.0)), elapsed, float(unit.position) * 1.9)

func _reset_fx() -> void:
	_flash_states.clear()
	_lunge_states.clear()
	_action_states.clear()
	_fall_states.clear()
	_ring_states.clear()
	_shake = {}
	_hp_seen.clear()
	_crit_marks.clear()
	for entry in _numbers:
		var label: Label = entry.get("label")
		if is_instance_valid(label):
			label.queue_free()
	_numbers.clear()

## Savaş animasyon katmanı. Slotlar her `_refresh()`'te yeniden kurulduğu
## için (bkz. `_refresh_side`) bir Tween figüre bağlanamıyor; durum panelde
## gerçek zaman damgasıyla tutuluyor ve `_process` her karede canlı
## slotlara `CombatFx` eğrilerinden okunan değeri basıyor. Önceki katman
## bunu yalnızca `bind()` anında yapıyordu: parlama bir sonraki tazelemeye
## kadar donuk bir renk olarak kalıp tek karede kayboluyordu. Eğriler ve
## süreler `CombatFx`'te - tek yerde.
func _process(_delta: float) -> void:
	if not _animate(Time.get_ticks_msec()):
		set_process(false)

## Bir karelik canlandırma: canlı slotlar, yüzen sayılar, sarsıntı ve -
## düşüşler bitene kadar - Devam tuşunun kilidi. `true` dönerse hâlâ
## oynayan bir şey var.
func _animate(now: int) -> bool:
	var active := false
	for unit in _slot_by_unit.keys():
		var slot: CombatUnitSlot = _slot_by_unit[unit]
		if not is_instance_valid(slot):
			_slot_by_unit.erase(unit)
			continue
		if _apply_fx(slot, unit, now):
			active = true
	if not _shake.is_empty():
		if now - int(_shake.get("start", 0)) >= CombatFx.SHAKE_MSEC:
			_shake = {}
		else:
			active = true
	if not _zoom.is_empty() and _stage != null:
		var u := CombatFx.progress(int(_zoom.get("start", 0)), CombatFx.CRIT_ZOOM_MSEC, now)
		_stage.pivot_offset = _zoom.get("pivot", _stage.size * 0.5)
		_stage.scale = Vector2.ONE * CombatFx.crit_zoom(u)
		if u >= 1.0:
			_zoom = {}
		else:
			active = true
	if _animate_numbers(now):
		active = true
	if _continue_button != null and _continue_button.visible:
		_continue_button.disabled = falls_pending()
	return active

## Düşen birim yere inene kadar savaş bitmiş sayılmıyor: son vuruşun
## kendisini görmeden sonuç ekranına geçmek, sonucu okunmaz kılıyordu.
func falls_pending() -> bool:
	return not _fall_states.is_empty()

## Canı değişen her birim için bir sayı. Can farkından okunuyor, motorun
## vuruş satırından değil: kanama, zırh, Kıyı ve iyileşme hepsi aynı
## kapıdan gelsin diye.
func _spawn_hp_numbers() -> void:
	if _fx_overlay == null:
		return
	var every_unit: Array[CombatUnit] = []
	every_unit.append_array(_encounter.player_units)
	every_unit.append_array(_encounter.enemy_units)
	for unit in every_unit:
		var before := int(_hp_seen.get(unit, unit.current_hp))
		var delta := unit.current_hp - before
		_hp_seen[unit] = unit.current_hp
		if delta == 0:
			continue
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", NUMBER_FONT_SIZE)
		label.text = ("+%d" % delta) if delta > 0 else ("%d" % delta)
		var color := ArtPalette.FX_HEAL if delta > 0 else ArtPalette.FX_DAMAGE
		if delta < 0 and _crit_marks.has(unit):
			color = ArtPalette.FX_CRIT
		label.modulate = color
		label.visible = false
		_fx_overlay.add_child(label)
		var stacked := 0
		for entry in _numbers:
			if entry.get("unit") == unit:
				stacked += 1
		_numbers.append({
			"unit": unit, "label": label, "start": Time.get_ticks_msec(), "stack": stacked,
		})
	_crit_marks.clear()
	if not _numbers.is_empty():
		set_process(true)

func _animate_numbers(now: int) -> bool:
	var kept: Array = []
	for entry in _numbers:
		var label: Label = entry.get("label")
		if not is_instance_valid(label):
			continue
		var u := CombatFx.progress(int(entry.get("start", 0)), CombatFx.NUMBER_MSEC, now)
		if u >= 1.0:
			label.queue_free()
			continue
		kept.append(entry)
		var slot: CombatUnitSlot = _slot_by_unit.get(entry.get("unit"))
		if slot == null or not is_instance_valid(slot) or not slot.is_inside_tree():
			label.visible = false
			continue
		var anchor := slot.global_position - _fx_overlay.global_position
		label.visible = true
		label.reset_size()
		label.position = anchor + Vector2(
			(slot.size.x - label.size.x) * 0.5, slot.size.y * 0.12 - float(entry.get("stack", 0)) * 18.0
		) + CombatFx.number_offset(u)
		label.modulate.a = CombatFx.number_alpha(u)
	_numbers = kept
	return not _numbers.is_empty()

func _current_targets() -> Array[CombatUnit]:
	var empty: Array[CombatUnit] = []
	if _selected_skill == null or _encounter.is_over() or not _encounter.is_player_turn():
		return empty
	return _encounter.get_valid_targets(_encounter.get_active_unit(), _selected_skill)

func _refresh_actions() -> void:
	NodeUtil.clear_children(_skill_row)
	NodeUtil.clear_children(_extra_row)

	if _encounter.is_over() or not _encounter.is_player_turn():
		_active_label.text = ""
		_hint_label.text = ""
		return

	var unit := _encounter.get_active_unit()
	_active_label.text = _unit_title(unit)
	_active_label.tooltip_text = tr("UI_COMBAT_ACTIVE") % [
		unit.display_name, unit.position, unit.get_effective_accuracy(), unit.get_effective_protection()
	]
	_active_label.mouse_filter = Control.MOUSE_FILTER_PASS
	if _selected_skill != null:
		_hint_label.text = tr("UI_COMBAT_HINT_PICK_TARGET") % _selected_skill.display_name
	else:
		_hint_label.text = tr("UI_COMBAT_HINT_PICK_SKILL")

	for skill in unit.skills:
		_skill_row.add_child(_build_skill_card(unit, skill))

	_build_extra_actions()
	_build_consumable_actions()
	_build_retreat_actions(unit)

func _left(item_id: String) -> int:
	return int(consumables.get(item_id, 0)) - int(_used.get(item_id, 0))

## Sargı ve iksir: kervanda varsa düğme (kaç kaldığıyla), yoksa yok.
func _build_consumable_actions() -> void:
	for spec in [[CombatEncounter.CONSUMABLE_BANDAGE, "UI_COMBAT_USE_BANDAGE"], [CombatEncounter.CONSUMABLE_POTION, "UI_COMBAT_USE_POTION"]]:
		var item_id := String(spec[0])
		if _left(item_id) <= 0:
			continue
		var button := Button.new()
		button.text = tr(String(spec[1])) % _left(item_id)
		button.pressed.connect(func():
			var target := _encounter.most_wounded_ally()
			if _encounter.use_consumable(item_id, target):
				_used[item_id] = int(_used.get(item_id, 0)) + 1
				_refresh())
		_extra_row.add_child(button)

## Geri çekilme (Y-C07): zorda kalınca açılır, kapalıyken sebebiyle kilitli.
## Ayıya karşı tek bir bedelsiz düğme: ayı kaçanı kovalamaz.
func _build_retreat_actions(unit: CombatUnit) -> void:
	if not _encounter.can_retreat():
		var locked := Button.new()
		locked.text = tr("UI_COMBAT_RETREAT")
		locked.disabled = true
		locked.tooltip_text = tr("UI_COMBAT_RETREAT_LOCKED")
		_extra_row.add_child(locked)
		return
	if _encounter.retreat_is_free():
		_extra_row.add_child(_retreat_button("UI_COMBAT_RETREAT_FREE", CombatEncounter.RETREAT_CARGO, unit))
		return
	_extra_row.add_child(_retreat_button("UI_COMBAT_RETREAT_CARGO", CombatEncounter.RETREAT_CARGO, unit))
	_extra_row.add_child(_retreat_button("UI_COMBAT_RETREAT_WAGON", CombatEncounter.RETREAT_WAGON, unit))
	var rear := _retreat_button("UI_COMBAT_RETREAT_REARGUARD", CombatEncounter.RETREAT_REARGUARD, unit)
	rear.text = tr("UI_COMBAT_RETREAT_REARGUARD") % unit.display_name
	_extra_row.add_child(rear)

func _retreat_button(key: String, kind: String, unit: CombatUnit) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.pressed.connect(func():
		if _encounter.retreat(kind, unit):
			retreated.emit(_encounter.retreat_kind)
			_refresh())
	return button

## Bir yetenek kartı (taslak): adı ve altında hedefe isabet şansı - kilitliyse
## sebebi. Altında iki küçük mevki belirteci satırı: nereden kullanılır, kime
## erişir. Kilitli yetenek gizlenmez - oyuncu mevki kilidini böyle öğrenir
## (bkz. olay ekranındaki kilitli seçenekler).
func _build_skill_card(unit: CombatUnit, skill: CombatSkill) -> Control:
	var card := Button.new()
	card.toggle_mode = true
	card.button_pressed = skill == _selected_skill
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(SKILL_CARD_WIDTH, SKILL_CARD_HEIGHT)
	card.tooltip_text = skill.description
	var reason := unit.get_skill_block_reason(skill)
	if reason.is_empty():
		card.pressed.connect(_on_skill_pressed.bind(skill))
	else:
		card.disabled = true
		card.tooltip_text = "%s\n%s" % [skill.description, reason]
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 14
	col.offset_top = 10
	col.offset_right = -10
	col.offset_bottom = -8
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	col.add_child(name_row)
	var name_label := Label.new()
	name_label.text = skill.display_name
	name_label.add_theme_font_size_override("font_size", 23)
	name_label.add_theme_color_override("font_color",
		ArtPalette.MENU_TEXT_DIM if not reason.is_empty() else ArtPalette.MENU_TEXT_BONE)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	# Alan/itme işaretleri adın yanında: belirteç satırının sonuna sığmıyordu.
	var glyphs := _skill_glyphs(skill)
	if glyphs.get_child_count() > 0:
		glyphs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(glyphs)
	else:
		glyphs.free()
	var line := Label.new()
	line.text = reason if not reason.is_empty() else _skill_line(unit, skill)
	line.add_theme_font_size_override("font_size", 16)
	line.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_DIM)
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(line)
	var marks := HBoxContainer.new()
	marks.add_theme_constant_override("separation", 10)
	marks.add_child(_build_mark_row(tr("UI_COMBAT_MARK_LAUNCH"), skill.usable_positions, LAUNCH_COLOR))
	marks.add_child(_build_mark_row(tr("UI_COMBAT_MARK_TARGET"), skill.target_positions, TARGET_MARK_COLOR))
	col.add_child(marks)
	var notes := _skill_notes(skill)
	if not notes.is_empty():
		card.tooltip_text += "\n" + " · ".join(notes)
	_ignore_mouse(col)
	return card

## Kartın ikinci satırı: odaktaki düşmana isabet şansı (motorun aynı
## formülü, CombatEncounter.use_skill); düşmana gitmeyen yetenekte notları.
func _skill_line(unit: CombatUnit, skill: CombatSkill) -> String:
	var target := _focus_unit()
	if skill.target_kind == CombatSkill.Target.ENEMY and target != null and not target.is_player_side:
		var chance := clampi(unit.get_effective_accuracy() + skill.accuracy_bonus - target.get_effective_dodge(),
			CombatEncounter.MIN_HIT_CHANCE, CombatEncounter.MAX_HIT_CHANCE)
		return tr("UI_COMBAT_CARD_HIT") % chance
	var notes := _skill_notes(skill)
	return " · ".join(notes) if not notes.is_empty() else tr("UI_COMBAT_CARD_SUPPORT")

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

## Kart başlığı: "Ad · Sınıf" (sınıfı olmayan düşmanda yalnız ad).
func _unit_title(unit: CombatUnit) -> String:
	var who := unit.display_name
	if unit.source_character != null:
		var cls := unit.source_character.get_character_class()
		if cls != null:
			who = "%s · %s" % [who, cls.display_name]
	return who

# --- Hedef paneli ---

var _hovered_unit: CombatUnit = null

func _on_unit_hovered(unit: CombatUnit) -> void:
	if _hovered_unit == unit:
		return
	_hovered_unit = unit
	_refresh_target()
	_refresh_actions()

## Sağ panelin kimi gösterdiği: üstüne gelinen, yoksa seçili yeteneğin ilk
## hedefi, yoksa düşmanın en öndeki ayakta kalanı.
func _focus_unit() -> CombatUnit:
	if _hovered_unit != null and _hovered_unit.is_alive():
		return _hovered_unit
	var targets := _current_targets()
	if not targets.is_empty():
		return targets[0]
	var front: CombatUnit = null
	for unit in _encounter.enemy_units:
		if unit.is_alive() and (front == null or unit.position < front.position):
			front = unit
	return front

func _refresh_target() -> void:
	if _target_heading == null:
		return
	var unit := _focus_unit()
	if unit == null:
		_target_heading.text = ""
		_target_stats.text = ""
		_target_behavior.text = ""
		_target_bar.set_share(0.0)
		return
	_target_heading.text = tr("UI_COMBAT_TARGET_HEAD") % [unit.display_name, unit.position]
	_target_bar.set_share(float(unit.current_hp) / float(maxi(1, unit.max_hp)))
	var parts: Array[String] = [tr("UI_COMBAT_TARGET_HP") % [unit.current_hp, unit.max_hp],
		tr("UI_COMBAT_TARGET_PROT") % unit.get_effective_protection()]
	for kind in unit.get_active_status_kinds():
		var rounds := unit.get_status_rounds(kind)
		parts.append(tr("UI_COMBAT_TARGET_STATUS") % [tr(_status_label_key(kind)), rounds])
	_target_stats.text = " · ".join(parts)
	var behavior_key := String(BEHAVIOR_KEYS.get(unit.behavior, ""))
	_target_behavior.text = tr("UI_COMBAT_TARGET_BEHAVIOR") % tr(behavior_key) \
		if not unit.is_player_side and not behavior_key.is_empty() else ""

## Notun resmi: ok satırı gibi okunuyor, metni yine notta ve ipucunda.
func _skill_glyphs(skill: CombatSkill) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var entries: Array = []
	match skill.area:
		CombatSkill.Area.ADJACENT:
			entries.append(["k7_adjacent.png", "UI_COMBAT_AREA_ADJACENT"])
		CombatSkill.Area.ALL:
			entries.append(["k7_all.png", "UI_COMBAT_AREA_ALL"])
		_:
			pass
	if skill.shifts():
		if skill.shift_amount > 0:
			entries.append(["k7_push.png", "UI_COMBAT_SHIFT_PUSH"])
		else:
			entries.append(["k7_pull.png", "UI_COMBAT_SHIFT_PULL"])
	for entry in entries:
		var glyph := WaybookTheme.picture(String(entry[0]), AREA_GLYPH_HEIGHT)
		glyph.tooltip_text = tr(String(entry[1]))
		glyph.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(glyph)
	return row

func _skill_notes(skill: CombatSkill) -> Array[String]:
	var notes: Array[String] = []
	match skill.area:
		CombatSkill.Area.ADJACENT:
			notes.append(tr("UI_COMBAT_AREA_ADJACENT"))
		CombatSkill.Area.ALL:
			notes.append(tr("UI_COMBAT_AREA_ALL"))
		CombatSkill.Area.RANDOM:
			notes.append(tr("UI_COMBAT_AREA_RANDOM"))
		_:
			pass
	if skill.shifts():
		notes.append(tr(
			"UI_COMBAT_SHIFT_PUSH" if skill.shift_amount > 0 else "UI_COMBAT_SHIFT_PULL"
		))
	if skill.has_status():
		notes.append(tr("UI_COMBAT_SKILL_STATUS") % [
			tr(_status_label_key(skill.status_kind)), skill.status_chance
		])
	return notes

func _status_label_key(kind: String) -> String:
	match kind:
		CombatUnit.STATUS_BLIGHT: return "CBT_STATUS_BLIGHT"
		CombatUnit.STATUS_STUN: return "CBT_STATUS_STUN"
		CombatUnit.STATUS_BURN: return "CBT_STATUS_BURN"
		CombatUnit.STATUS_CHILL: return "CBT_STATUS_CHILL"
		_: return "CBT_STATUS_BLEED"

func _build_mark_row(prefix: String, positions: Array[int], color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)

	var label := Label.new()
	label.text = prefix
	label.add_theme_font_size_override("font_size", WaybookTheme.FONT_MIN)
	label.modulate = color
	row.add_child(label)

	# Dikey ortalama şart: pipler kendi asgari boylarıyla duruyor,
	# hizalanmazsa etiketin tepesine yapışıyor.
	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 2)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for rank in range(1, CombatEncounter.MAX_SIDE_SIZE + 1):
		var filled := positions.has(rank)
		var pip := WaybookTheme.picture(PIP_FILLED_FILE if filled else PIP_HOLLOW_FILE, MARK_SIZE)
		pip.modulate = color if filled else Color(color, 0.55)
		pips.add_child(pip)
	row.add_child(pips)
	return row

## Yetenek dışı eylemler: mevki değiştirmek ve turu geçmek. Turu geçmek
## motorun kendisi için de gerekli - elinde kullanılabilir yeteneği
## kalmamış bir savaşçı yoksa sırayı hiç bırakamaz (bkz.
## CombatEncounter.pass_turn).
func _build_extra_actions() -> void:
	var units := _encounter.player_units
	for index in units.size() - 1:
		var first := units[index]
		var second := units[index + 1]
		if not first.is_alive() or not second.is_alive():
			continue
		var button := Button.new()
		button.text = tr("UI_COMBAT_SWAP") % [first.display_name, second.display_name]
		button.pressed.connect(_on_swap_pressed.bind(first, second))
		_extra_row.add_child(button)

	var pass_button := Button.new()
	pass_button.text = tr("UI_COMBAT_PASS")
	pass_button.pressed.connect(_on_pass_pressed)
	_extra_row.add_child(pass_button)

# --- Girdi ---

func _on_skill_pressed(skill: CombatSkill) -> void:
	# Aynı yeteneğe ikinci basış seçimi kaldırır: hedef seçmekten
	# vazgeçmenin bir yolu olmalı.
	_selected_skill = null if _selected_skill == skill else skill
	_refresh()

func _on_unit_clicked(target: CombatUnit) -> void:
	if _selected_skill == null:
		return
	var skill := _selected_skill
	_selected_skill = null
	_encounter.use_skill(skill, target)
	_refresh()

func _on_swap_pressed(first: CombatUnit, second: CombatUnit) -> void:
	_selected_skill = null
	_encounter.swap_player_positions(first, second)
	_refresh()

func _on_pass_pressed() -> void:
	_selected_skill = null
	_encounter.pass_turn()
	_refresh()

# --- Kayıt ve bitiş ---

func _on_log_added(line: String) -> void:
	var label := Label.new()
	label.text = line
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", ArtPalette.MENU_TEXT_DIM.lightened(0.15))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_log_list.add_child(label)
	while _log_list.get_child_count() > MAX_LOG_LINES:
		var oldest := _log_list.get_child(0)
		_log_list.remove_child(oldest)
		oldest.queue_free()
	_scroll_log_to_bottom()

func _scroll_log_to_bottom() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)

func _on_state_changed(new_state: CombatEncounter.State) -> void:
	if new_state == CombatEncounter.State.VICTORY:
		_result_label.text = tr("UI_COMBAT_VICTORY") % _encounter.enemy_label
		# Ganimet zafer ekranında (Y-C03): zar savaşın türü ve tohumundan.
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("loot|%s|%d|%d" % [_loot_kind, _encounter.round_number, _encounter.enemy_units.size()])
		_loot = LootTable.roll(_loot_kind, _loot_danger, rng)
		if not _loot.is_empty():
			_result_label.text += "\n" + tr("UI_COMBAT_LOOT") % ", ".join(LootTable.describe(_loot))
	elif new_state == CombatEncounter.State.RETREAT:
		_result_label.text = tr("UI_COMBAT_RETREATED") % _encounter.enemy_label
	else:
		_result_label.text = tr("UI_COMBAT_DEFEAT") % _encounter.enemy_label
	_continue_button.visible = true
	_refresh()
	_continue_button.disabled = falls_pending()

func _on_continue_pressed() -> void:
	if falls_pending():
		return
	var victory := _encounter.state == CombatEncounter.State.VICTORY
	var xp_awarded := 0
	for unit in _encounter.enemy_units:
		if not unit.is_alive():
			xp_awarded += unit.xp_value
	# downed_count write_back_party()'den önce okunmalı - o çağrı düşenleri
	# 1 canla ayağa kaldırıyor, sonrasında kimse "düşmüş" sayılmıyor.
	var downed_count := _encounter.get_downed_count()
	var dead := _encounter.get_dead_characters()
	_encounter.write_back_party()
	_continue_button.visible = false
	if victory and not _loot.is_empty():
		loot_rolled.emit(_loot)
	if not _used.is_empty():
		consumables_used.emit(_used)
	combat_finished.emit(victory, xp_awarded, downed_count, dead)

## Ganimet tablosunun türü ve tehlikesi (yol ekranı setup sonrası verir).
var _loot_kind: String = "bandit"
var _loot_danger: float = 0.3

func set_loot_context(kind: String, danger: float) -> void:
	_loot_kind = kind
	_loot_danger = danger

## Tur madalyonu: koyu disk, altın halka, ortasında Roma rakamıyla tur.
class RoundMedal extends Control:
	var _round: int = 1

	func set_round(value: int) -> void:
		_round = value
		queue_redraw()

	func _draw() -> void:
		var centre := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 3.0
		draw_circle(centre, radius, Color(ArtPalette.INK, 0.85))
		draw_arc(centre, radius, 0.0, TAU, 64, ArtPalette.MENU_TITLE_GOLD, 3.0, true)
		var font := WaybookTheme.title_font()
		var text := roman(_round)
		var font_size := int(radius * (0.95 if text.length() <= 3 else 0.7))
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := centre.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5 - font_size * 0.12
		draw_string(font, Vector2(centre.x - text_size.x * 0.5, baseline), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ArtPalette.MENU_TITLE_GOLD)

	static func roman(value: int) -> String:
		var n := clampi(value, 1, 3999)
		var numerals := [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
			[50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
		var out := ""
		for pair in numerals:
			while n >= int(pair[0]):
				out += String(pair[1])
				n -= int(pair[0])
		return out

## Hedefin can çizgisi: koyu yatak, kanlı dolgu.
class HpLine extends Control:
	var _share: float = 0.0

	func set_share(value: float) -> void:
		_share = clampf(value, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var w := size.x * 0.7
		draw_rect(Rect2(Vector2.ZERO, Vector2(w, size.y)), Color(ArtPalette.BONE_DIM, 0.12))
		draw_rect(Rect2(Vector2.ZERO, Vector2(w * _share, size.y)), ArtPalette.BLOOD.lightened(0.1))
