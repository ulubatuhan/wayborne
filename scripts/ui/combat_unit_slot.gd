class_name CombatUnitSlot
extends PanelContainer

## Savaş alanındaki tek bir mevki: figür, can barı, mevki numarası ve
## durum satırı. Savaş artık liste değil *mekân* olduğu için var - eski
## panel birimleri `Label` satırı olarak basıyordu ve hedef ayrı bir
## menüden seçiliyordu, o yüzden pozisyona dayalı bir savaş visual novel
## gibi okunuyordu.
##
## Figür artık `ColorRect` değil, `CombatFigure` - poligonla çizilmiş bir
## silüet. Dikdörtgen bir yer tutucu *kimseyi* temsil etmiyordu: dört sınıf
## ve dokuz düşman aynı renkli kutuydu. Sprite geldiğinde yapı
## değişmeyecek, `_figure`'ın yerine bir `TextureRect` koymak yeterli.

signal clicked(unit)  # CombatUnit

## İlk denemede 104x108'di ve sanal ekranda alınan görüntüde savaş alanı
## 900 piksel yüksekliğin yalnızca üst 200'ünde ince bir şerit olarak
## duruyordu - mekân hissi vermiyordu. Figür artık ekranın gövdesini
## dolduruyor; DD'de de savaş alanı ekranın kendisidir.
const SLOT_WIDTH: float = 136.0
const FIGURE_HEIGHT: float = 208.0


const ACTIVE_BORDER: Color = Color(0.95, 0.82, 0.45)
const TARGET_BORDER: Color = Color(0.90, 0.35, 0.30)
const IDLE_BORDER: Color = Color(0.0, 0.0, 0.0, 0.0)

## Mevkinin Waybook çerçevesi (K1) ve Ölümün Kıyısı'ndaki çatlak hâli (K2).
## Doku yarı ölçekte dokuz parça: tam ölçekte 30 piksellik kenar 136'lık
## mevkide figürü sıkıştırıyordu.
const FRAME_FILE: String = "k1_slot.png"
const DOOR_FRAME_FILE: String = "k2_door.png"
const FRAME_SCALE: float = 0.5
const FRAME_SLICE: int = 16
const DOOR_FRAME_SLICE: int = 22
const FRAME_CONTENT: int = 12
## Can çubuğunun demir çerçevesi (K3) - dolgu çerçevenin içinde kalsın diye
## dolgunun saydam bir kenarı var.
const HP_FRAME_FILE: String = "k3_bar.png"
const HP_FRAME_SLICE_X: int = 8
const HP_FRAME_SLICE_Y: int = 4
const HP_BAR_HEIGHT: float = 12.0
const STATUS_ICON_SIZE: float = 18.0
const EMBLEM_SIZE: float = 18.0

## Ölümün Kıyısı'nı ayrı bir renkle veriyoruz: oyuncunun tek bir vuruşla
## karakterini kaybedebileceğini *görmeden* anlaması mümkün değil.
const DEATHS_DOOR_FIGURE: Color = Color(0.62, 0.16, 0.16)

var unit: CombatUnit

var _figure: CombatFigure
var _hp_bar: ProgressBar
var _hp_label: Label
var _name_label: Label
var _rank_label: Label
var _status_row: HBoxContainer
var _bark_label: Label
var _frame: StyleBoxTexture
var _door_frame: StyleBoxTexture
var _border: StyleBoxFlat
var _emblem: TextureRect
var _selectable: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(SLOT_WIDTH, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Çerçeve içi boş: arkadaki zemin görünmeli, mevki bir çerçeve
	# olmalı, bir pencere değil.
	_frame = _frame_box(FRAME_FILE, FRAME_SLICE)
	_door_frame = _frame_box(DOOR_FRAME_FILE, DOOR_FRAME_SLICE)
	add_theme_stylebox_override("panel", _frame)
	# Sıra/hedef vurgusu çerçevenin *üstünde* ayrı bir kenar (bkz. _draw):
	# koyu ahşabı altına boyamak onu okunur kılmıyordu.
	_border = StyleBoxFlat.new()
	_border.draw_center = false
	_border.border_color = IDLE_BORDER
	_border.set_border_width_all(3)
	_border.set_corner_radius_all(3)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)

	# Yorum balonu: sessiz, kısa bir metin - "isabet/kritik/düşüş/dinlemiyor"
	# gibi. `visible = false` iken VBoxContainer hiç yer ayırmıyor, o yüzden
	# boşta hiçbir görsel maliyeti yok. `show_bark()` çağrılmadıkça hep
	# gizli kalır (bkz. CombatPanel._apply_pending_bark).
	_bark_label = Label.new()
	_bark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bark_label.add_theme_font_size_override("font_size", 11)
	_bark_label.modulate = Color(0.95, 0.88, 0.55)
	_bark_label.visible = false
	column.add_child(_bark_label)

	var rank_row := HBoxContainer.new()
	rank_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_row.add_theme_constant_override("separation", 4)
	column.add_child(rank_row)
	_emblem = WaybookTheme.picture(WaybookIcons.CLASS_EMBLEMS[ClassCatalog.GUARD], EMBLEM_SIZE)
	_emblem.visible = false
	rank_row.add_child(_emblem)
	_rank_label = Label.new()
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.add_theme_font_size_override("font_size", 12)
	_rank_label.modulate = ArtPalette.UI_TEXT_DIM
	rank_row.add_child(_rank_label)

	_figure = CombatFigure.new()
	_figure.custom_minimum_size = Vector2(0.0, FIGURE_HEIGHT)
	_figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_figure)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.clip_text = true
	column.add_child(_name_label)

	# Varsayılan tema barı koyu zeminde neredeyse görünmüyordu (görüntüde
	# ölçüldü), o yüzden dolgu ve zemin açıkça veriliyor.
	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(0.0, HP_BAR_HEIGHT)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxTexture.new()
	track.texture = WaybookTheme.texture(HP_FRAME_FILE)
	track.texture_margin_left = HP_FRAME_SLICE_X
	track.texture_margin_right = HP_FRAME_SLICE_X
	track.texture_margin_top = HP_FRAME_SLICE_Y
	track.texture_margin_bottom = HP_FRAME_SLICE_Y
	_hp_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ArtPalette.BLOOD
	fill.border_color = Color(0, 0, 0, 0)
	fill.border_width_left = 3
	fill.border_width_right = 3
	fill.border_width_top = 3
	fill.border_width_bottom = 3
	_hp_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(_hp_bar)

	_hp_label = Label.new()
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 10)
	column.add_child(_hp_label)

	_status_row = HBoxContainer.new()
	_status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_row.add_theme_constant_override("separation", 3)
	column.add_child(_status_row)

## Birimi bu mevkiye yerleştirir. `is_active` sırası gelen savaşçı,
## `is_target` seçili yeteneğin vurabileceği bir hedef demek - ikisi de
## kenar rengiyle gösteriliyor, çünkü hedefi sahnede seçmenin ön koşulu
## hangisinin seçilebilir olduğunu görmek.
func bind(bound_unit: CombatUnit, is_active: bool, is_target: bool) -> void:
	unit = bound_unit
	_selectable = is_target

	_rank_label.text = tr("UI_COMBAT_RANK") % bound_unit.position
	_name_label.text = bound_unit.display_name
	_name_label.tooltip_text = bound_unit.display_name

	_hp_bar.max_value = maxf(1.0, float(bound_unit.max_hp))
	_hp_bar.value = clampf(float(bound_unit.current_hp), 0.0, _hp_bar.max_value)
	_hp_label.text = "%d/%d" % [bound_unit.current_hp, bound_unit.max_hp]

	# Silüet: oyuncu sağa, düşman sola bakar. Derinlik arka mevkileri
	# hafifçe küçültüp karartıyor - dört mevkinin sıralı durduğu hissi.
	var depth := float(bound_unit.position - 1) / float(maxi(1, CombatEncounter.MAX_SIDE_SIZE - 1))
	_figure.setup(
		bound_unit.figure_kind, bound_unit.is_player_side, _figure_state(bound_unit), depth,
		bound_unit.outfit
	)
	_figure.set_stunned(bound_unit.is_stunned and bound_unit.is_alive())
	_border.border_color = _border_color(is_active, is_target)
	add_theme_stylebox_override("panel", _door_frame if bound_unit.on_deaths_door else _frame)
	queue_redraw()
	var emblem_file := String(WaybookIcons.CLASS_EMBLEMS.get(bound_unit.figure_kind, "")) if bound_unit.is_player_side else ""
	_emblem.visible = emblem_file != ""
	if _emblem.visible:
		_emblem.texture = WaybookTheme.texture(emblem_file)
	_refresh_status(bound_unit)

	# Ölü/düşmüş bir birim soluk durur ama gizlenmez: saftaki boşluğu
	# görmek mevki mantığının okunabilmesi için gerekli.
	modulate = Color(1, 1, 1, _field_alpha(bound_unit))
	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if is_target else Control.CURSOR_ARROW
	)

## Sahadaki soluklaşma: düşen hâlâ saftaki bir boşluk, ölü daha da silik.
static func _field_alpha(bound_unit: CombatUnit) -> float:
	if bound_unit.is_dead:
		return ArtPalette.UI_DEAD_ALPHA
	if not bound_unit.is_alive():
		return ArtPalette.UI_FALLEN_ALPHA
	return 1.0

## Silüetin duruşunu ve paletini belirleyen durum. Düşen bir figür
## ayakta soluk durmuyor, yere çöküyor - "düşmüş" ancak duruş değişince
## okunuyor.
func _frame_box(file_name: String, slice: int) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = WaybookTheme.scaled_texture(file_name, FRAME_SCALE)
	box.set_texture_margin_all(slice)
	box.set_content_margin_all(FRAME_CONTENT)
	return box

func _draw() -> void:
	if _border.border_color.a > 0.0:
		draw_style_box(_border, Rect2(Vector2.ZERO, size))

func _figure_state(bound_unit: CombatUnit) -> String:
	if bound_unit.is_dead:
		return "dead"
	if bound_unit.on_deaths_door:
		return "deaths_door"
	if not bound_unit.is_alive():
		return "downed"
	return "normal"

func _border_color(is_active: bool, is_target: bool) -> Color:
	if is_active:
		return ACTIVE_BORDER
	if is_target:
		return TARGET_BORDER
	return IDLE_BORDER

## Durum satırı: kıyı, zırh ve stres. Sayı değil kısa etiket - ikon
## varlıkları gelene kadar okunur kalması gerekiyor.
func _refresh_status(bound_unit: CombatUnit) -> void:
	for child in _status_row.get_children():
		_status_row.remove_child(child)
		child.queue_free()

	if bound_unit.on_deaths_door:
		_add_badge(tr("UI_COMBAT_BADGE_DEATHS_DOOR"), DEATHS_DOOR_FIGURE)
	if bound_unit.get_effective_protection() > 0:
		_add_badge(
			tr("UI_COMBAT_BADGE_PROT") % bound_unit.get_effective_protection(), Color(0.55, 0.62, 0.72)
		)
	if bound_unit.is_stressed:
		_add_badge(tr("UI_COMBAT_BADGE_STRESSED"), Color(0.78, 0.62, 0.35))

	# Durum efektleri kalan turlarıyla görünüyor. Görünmeyen bir kanama,
	# "canım neden azalıyor" sorusunu cevapsız bırakır - kilitli
	# yeteneğin sebebini göstermekle aynı kural.
	# İkonlar (K4) kalan tur sayısıyla; adı ve tam metni ipucunda.
	if bound_unit.has_status(CombatUnit.STATUS_BLEED):
		var rounds := bound_unit.get_status_rounds(CombatUnit.STATUS_BLEED)
		_add_status_icon("k4a_bleed.png", str(rounds), tr("UI_COMBAT_BADGE_BLEED") % rounds)
	if bound_unit.has_status(CombatUnit.STATUS_BLIGHT):
		var rounds := bound_unit.get_status_rounds(CombatUnit.STATUS_BLIGHT)
		_add_status_icon("k4b_blight.png", str(rounds), tr("UI_COMBAT_BADGE_BLIGHT") % rounds)
	if bound_unit.is_stunned:
		_add_status_icon("k4c_stun.png", "", tr("UI_COMBAT_BADGE_STUN"))
	elif bound_unit.has_stun_recovery():
		_add_status_icon("k4d_stun_resist.png", "", tr("UI_COMBAT_BADGE_STUN_RESIST"))
	if bound_unit.has_timed_buff():
		_add_status_icon("k4e_buff.png", "", tr("UI_COMBAT_BADGE_BUFF"))
	if bound_unit.has_timed_debuff():
		_add_status_icon("k4f_debuff.png", "", tr("UI_COMBAT_BADGE_DEBUFF"))

## Sessiz yorum balonu: seslendirme değil, yalnızca metin - bkz. UiIcon/log
## satırı deseniyle aynı aile. `bind()` her tazelemede yeni bir Label
## kurduğu için burada yalnızca metni yazıp görünür kılmak yeterli.
func show_bark(text: String) -> void:
	_bark_label.text = text
	_bark_label.visible = true

## Faz 17 PR-7: savaş animasyon katmanı. `bind()`'tan *sonra* çağrılır,
## `show_bark()` ile aynı sırada (bkz. CombatPanel._apply_pending_animation) -
## figürün kendi state/depth/outfit'ini yeniden hesaplamadan yalnızca
## parlama ve kayma uyguluyor.
func apply_action_animation(flash: Color, lunge: float) -> void:
	apply_fx(flash, Vector2(lunge, 0.0), 1.0, Color(0, 0, 0, 0), 1.0)

## Panelin her karede bastığı anlık durum (bkz. CombatFx): parlama, kayma
## (hamle + sarsıntı), düşüşün ilerlemesi, durum halkası.
func apply_fx(flash: Color, offset: Vector2, fall: float, ring_color: Color, ring: float) -> void:
	_figure.set_flash(flash)
	_figure.set_shift(offset)
	_figure.set_fall(fall)
	_figure.set_ring(ring_color, ring)

## Figürün yatay ekseni (hamlenin ölçüsü). Yerleşim henüz yapılmadıysa
## slotun sabit genişliği.
func get_figure_width() -> float:
	return _figure.size.x if _figure.size.x > 1.0 else SLOT_WIDTH

func _add_status_icon(file_name: String, count: String, tooltip: String) -> void:
	var holder := HBoxContainer.new()
	holder.add_theme_constant_override("separation", 1)
	holder.tooltip_text = tooltip
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(WaybookTheme.picture(file_name, STATUS_ICON_SIZE))
	if count != "":
		var label := Label.new()
		label.text = count
		label.add_theme_font_size_override("font_size", 11)
		holder.add_child(label)
	_status_row.add_child(holder)

func _add_badge(text: String, color: Color) -> void:
	var badge := Label.new()
	badge.text = text
	badge.add_theme_font_size_override("font_size", 10)
	badge.modulate = color
	_status_row.add_child(badge)

func _gui_input(event: InputEvent) -> void:
	if not _selectable or unit == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(unit)
		accept_event()
