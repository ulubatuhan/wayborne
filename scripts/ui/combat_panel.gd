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

const LOCKED_COLOR: Color = Color(0.6, 0.6, 0.6)
const MAX_LOG_LINES: int = 40
## Yorum balonu ne kadar sürsün. Slotlar her `_refresh()`'te yeniden
## kuruluyor (bkz. `_refresh_side`), o yüzden balon bir Tween'le değil
## gerçek zaman damgasıyla tutuluyor - `_bark_texts` her yeni slota
## `bind()`'tan sonra süresi geçmemişse yeniden basılıyor.
const BARK_DURATION_MSEC: int = 2200

## Savaş animasyon katmanı. Slotlar her `_refresh()`'te yeniden kurulduğu
## için (bkz. `_refresh_side`) bir Tween figüre bağlanamıyor; durum panelde
## gerçek zaman damgasıyla tutuluyor ve `_process` her karede canlı
## slotlara `CombatFx` eğrilerinden okunan değeri basıyor. Önceki katman
## bunu yalnızca `bind()` anında yapıyordu: parlama bir sonraki tazelemeye
## kadar donuk bir renk olarak kalıp tek karede kayboluyordu. Eğriler ve
## süreler `CombatFx`'te - tek yerde.
const LUNGE_DISTANCE: float = 14.0
## Hasar sayılarının yazı boyu.
const NUMBER_FONT_SIZE: int = 20

## Parlama renkleri ArtPalette.FX_FLASH_* - renk tek yerden gelir.

## Mevki belirteçleri: dolu nokta "burada durabilir" / "buraya vurabilir",
## boş nokta duramaz/vuramaz. DD'nin yetenek ikonundaki nokta dizisinin
## karşılığı - sayı yerine şekil, çünkü oyuncunun bunu okumak için durup
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
const SKILL_CARD_WIDTH: float = 156.0
## Savaş alanının en az yüksekliği. İlk denemede alan 900 pikselin
## üst 200'ünde ince bir şeritti; DD'de savaş alanı ekranın kendisidir.
const STAGE_HEIGHT: float = 380.0
const TARGET_MARK_COLOR: Color = Color(0.90, 0.45, 0.40)

var _encounter: CombatEncounter
var _selected_skill: CombatSkill
var _built: bool = false

var _round_label: Label
var _order_strip: HBoxContainer
var _player_row: HBoxContainer
var _enemy_row: HBoxContainer
var _active_label: Label
var _hint_label: Label
var _skill_row: HBoxContainer
var _extra_row: HBoxContainer
var _result_label: Label
var _continue_button: Button
var _log_scroll: ScrollContainer
var _log_list: VBoxContainer
var _bark_texts: Dictionary = {}  # CombatUnit -> {"text": String, "expires_at": int}
var _flash_states: Dictionary = {}  # CombatUnit -> {"color": Color, "start": int, "duration": int}
var _lunge_states: Dictionary = {}  # CombatUnit -> {"direction": float, "magnitude": float, "start": int}
var _fall_states: Dictionary = {}  # CombatUnit -> {"start": int}
var _ring_states: Dictionary = {}  # CombatUnit -> {"color": Color, "start": int}
var _shake: Dictionary = {}  # {"amplitude": float, "start": int}
## Yüzen hasar/iyileşme sayıları: {"unit", "label", "start", "slot_index"}.
var _numbers: Array = []
## Son görülen can - sayılar motorun ne dediğinden değil, canın gerçekte
## ne kadar değiştiğinden çıkıyor (zırh, Kıyı, iyileşme tavanı hepsi
## zaten içinde).
var _hp_seen: Dictionary = {}  # CombatUnit -> int
## Son vuruşu kritik olan birimler: sayısı kritik renginde çıkıyor.
var _crit_marks: Dictionary = {}  # CombatUnit -> true
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
	enemy_kind: String = "bandit", region_id: String = "", biome: String = ""
) -> void:
	_ensure_built()

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

	_selected_skill = null
	_result_label.text = ""
	_continue_button.visible = false
	_clear_children(_log_list)
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

# --- Kurulum ---

func _ensure_built() -> void:
	if _built:
		return
	_built = true

	add_theme_constant_override("separation", 6)
	_build_header()
	_build_field()
	_build_action_area()
	_build_log()

func _build_header() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)

	_round_label = Label.new()
	_round_label.custom_minimum_size = Vector2(90.0, 0.0)
	header.add_child(_round_label)

	# Tur sırası şeridi: hız zarı round başına sırayı değiştirdiği için
	# artık gerçekten bilgi taşıyor (bkz. CombatEncounter.SPEED_DIE).
	# Sabit sırada bunu göstermenin bir anlamı yoktu.
	_order_strip = HBoxContainer.new()
	_order_strip.add_theme_constant_override("separation", 4)
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

	var backdrop := CombatBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(backdrop)

	var field := HBoxContainer.new()
	field.set_anchors_preset(Control.PRESET_FULL_RECT)
	field.add_theme_constant_override("separation", 10)
	field.alignment = BoxContainer.ALIGNMENT_CENTER

	_player_row = HBoxContainer.new()
	_player_row.add_theme_constant_override("separation", 4)
	_player_row.alignment = BoxContainer.ALIGNMENT_END
	_player_row.size_flags_vertical = Control.SIZE_SHRINK_END
	_player_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_child(_player_row)

	# İki tarafın arasında ince bir boşluk yeter: zemin ve ışık havuzu
	# ayrımı zaten taşıyor, ek bir çizgi sahneyi ikiye biçiyordu.
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(26.0, 0.0)
	field.add_child(gap)

	_enemy_row = HBoxContainer.new()
	_enemy_row.add_theme_constant_override("separation", 4)
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

func _build_action_area() -> void:
	_active_label = Label.new()
	add_child(_active_label)

	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hint_label.modulate = Color(0.72, 0.70, 0.64)
	add_child(_hint_label)

	_skill_row = HBoxContainer.new()
	_skill_row.add_theme_constant_override("separation", 6)
	add_child(_skill_row)

	_extra_row = HBoxContainer.new()
	_extra_row.add_theme_constant_override("separation", 6)
	add_child(_extra_row)

	_result_label = Label.new()
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_result_label)

	_continue_button = Button.new()
	_continue_button.text = tr("UI_COMBAT_CONTINUE")
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	add_child(_continue_button)

func _build_log() -> void:
	# Sahne sabit yükseklikte (STAGE_HEIGHT), yetenek düğmeleri de kendi
	# içeriği kadar - altlarında ekranın neredeyse yarısı boş siyah
	# kalıyordu (ölçüldü: 1920x1080'de ~45%). ScrollContainer'ın kendi
	# hiç çizilen zemini olmadığı için yalnızca `size_flags_vertical`
	# büyütmek görsel olarak hiçbir şeyi değiştirmiyordu - genişleyen alan
	# hâlâ boş siyah okunuyordu. Kayıt artık HUD_BAR temalı bir panelin
	# içinde: hem kalan boşluğu dolduruyor hem de "burası kaydın olduğu
	# yer" diyen görünür bir zemin taşıyor.
	var log_panel := PanelContainer.new()
	# HUD_BAR (bkz. WaybookTheme) dünyanın kendi renkli zemini üstünde
	# okunmak üzere neredeyse siyah boyanmış - savaş sahnesinin zaten
	# neredeyse siyah arka planında tamamen kayboluyordu. Sahnenin kendi
	# kart çerçevesiyle (`stage_style`, yukarıda) aynı aileden, biraz
	# daha açık bir zemin kullanılıyor.
	var log_style := StyleBoxFlat.new()
	log_style.bg_color = Color(0.12, 0.11, 0.10, 0.55)
	log_style.border_color = Color(0.30, 0.25, 0.18, 0.8)
	log_style.set_border_width_all(1)
	log_style.content_margin_left = 8
	log_style.content_margin_right = 8
	log_style.content_margin_top = 6
	log_style.content_margin_bottom = 6
	log_panel.add_theme_stylebox_override("panel", log_style)
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(log_panel)

	_log_scroll = ScrollContainer.new()
	_log_scroll.custom_minimum_size = Vector2(0, 96)
	log_panel.add_child(_log_scroll)

	_log_list = VBoxContainer.new()
	_log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_scroll.add_child(_log_list)

# --- Tazeleme ---

func _refresh() -> void:
	if _encounter == null:
		return
	_refresh_header()
	_refresh_side(_player_row, _encounter.player_units, true)
	_refresh_side(_enemy_row, _encounter.enemy_units, false)
	_refresh_actions()
	_spawn_hp_numbers()
	_animate(Time.get_ticks_msec())

func _refresh_header() -> void:
	_round_label.text = tr("UI_COMBAT_ROUND") % _encounter.round_number
	_clear_children(_order_strip)
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
	chip.add_theme_font_size_override("font_size", WaybookTheme.FONT_MIN)
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
	_clear_children(row)

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

	if CombatFx.is_status_application(kind):
		_ring_states[unit] = {"color": CombatFx.status_color(kind), "start": now}

	# Bir kaçırma da taze bir hamle - saldıran gerçekten kılıcını salladı,
	# yalnızca değmedi. HIT/CRIT'in "bu bir vuruş girişimiydi" ailesinde,
	# DEATHS_DOOR/SURVIVED/KILLED/DOWNED'ın "bu bir sonuç" ailesinde değil.
	var magnitude := CombatFx.recoil_magnitude(kind)
	if magnitude > 0.0:
		var attacker := _encounter.get_active_unit()
		if attacker != null and attacker != unit:
			_lunge_states[attacker] = {
				"direction": 1.0 if attacker.is_player_side else -1.0,
				"magnitude": magnitude, "start": now,
			}

	var amplitude := CombatFx.shake_amplitude(kind)
	if amplitude > 0.0 and not _reduce_motion():
		if _shake.is_empty() or amplitude >= float(_shake.get("amplitude", 0.0)) \
				or now - int(_shake.get("start", 0)) >= CombatFx.SHAKE_MSEC:
			_shake = {"amplitude": amplitude, "start": now}

	if CombatFx.starts_fall(kind):
		_fall_states[unit] = {"start": now}
	set_process(true)

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

	slot.apply_fx(flash, offset, fall, ring_color, ring)
	return active

## Sarsıntı her figürde aynı zarf, ama birim başına kaydırılmış bir faz:
## herkes aynı yöne aynı anda kayarsa sahne değil kamera sallanır.
func _shake_offset(now: int, unit: CombatUnit) -> Vector2:
	if _shake.is_empty():
		return Vector2.ZERO
	var elapsed := float(now - int(_shake.get("start", 0))) / 1000.0
	return CombatFx.shake_at(float(_shake.get("amplitude", 0.0)), elapsed, float(unit.position) * 1.9)

func _reduce_motion() -> bool:
	if not is_inside_tree():
		return false
	var settings := get_node_or_null("/root/UserSettings")
	return settings != null and bool(settings.get("reduce_motion"))

func _reset_fx() -> void:
	_flash_states.clear()
	_lunge_states.clear()
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
	_clear_children(_skill_row)
	_clear_children(_extra_row)

	if _encounter.is_over() or not _encounter.is_player_turn():
		_active_label.text = ""
		_hint_label.text = ""
		return

	var unit := _encounter.get_active_unit()
	_active_label.text = tr("UI_COMBAT_ACTIVE") % [
		unit.display_name, unit.position, unit.get_effective_accuracy(), unit.get_effective_protection()
	]
	if _selected_skill != null:
		_hint_label.text = tr("UI_COMBAT_HINT_PICK_TARGET") % _selected_skill.display_name
	else:
		_hint_label.text = tr("UI_COMBAT_HINT_PICK_SKILL")

	for skill in unit.skills:
		_skill_row.add_child(_build_skill_card(unit, skill))

	_build_extra_actions()

## Bir yetenek kartı: adı, iki mevki belirteci satırı ve kilitliyse
## sebebi. Kilitli yetenek gizlenmez - oyuncu mevki kilidini böyle
## öğrenir (bkz. olay ekranındaki kilitli seçenekler).
func _build_skill_card(unit: CombatUnit, skill: CombatSkill) -> Control:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 1)
	# Eşit genişlik: ilk görüntüde kartlar ad uzunluğuna göre farklı
	# genişlikteydi ve satır tırtıklı duruyordu.
	card.custom_minimum_size = Vector2(SKILL_CARD_WIDTH, 0.0)

	var button := Button.new()
	button.text = skill.display_name
	button.tooltip_text = skill.description
	button.toggle_mode = true
	button.button_pressed = skill == _selected_skill

	var reason := unit.get_skill_block_reason(skill)
	if reason.is_empty():
		button.pressed.connect(_on_skill_pressed.bind(skill))
	else:
		button.disabled = true
		button.modulate = LOCKED_COLOR
		button.tooltip_text = "%s\n%s" % [skill.description, reason]
	card.add_child(button)

	card.add_child(_build_mark_row(tr("UI_COMBAT_MARK_LAUNCH"), skill.usable_positions, LAUNCH_COLOR))
	card.add_child(_build_mark_row(tr("UI_COMBAT_MARK_TARGET"), skill.target_positions, TARGET_MARK_COLOR))

	# Yeteneğin "ne yaptığı" yalnızca adında yazmamalı: alan genişliği,
	# mevki kaydırması ve durum efekti oyuncunun kararını değiştiren
	# şeyler. Görünmeyen bir etki, bir mekaniğin hiç olmaması gibidir.
	var glyphs := _skill_glyphs(skill)
	if glyphs.get_child_count() > 0:
		card.add_child(glyphs)

	var notes := _skill_notes(skill)
	if not notes.is_empty():
		var note := Label.new()
		note.text = " · ".join(notes)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD
		note.modulate = ArtPalette.GOLD_DIM
		card.add_child(note)
	return card

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
	label.add_theme_font_size_override("font_size", WaybookTheme.FONT_MIN)
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
	combat_finished.emit(victory, xp_awarded, downed_count, dead)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
