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
var _style: StyleBoxFlat
var _selectable: bool = false

func _init() -> void:
	custom_minimum_size = Vector2(SLOT_WIDTH, 0.0)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_style = StyleBoxFlat.new()
	# Kutu neredeyse şeffaf: arkadaki zemin görünmeli, kutu bir
	# çerçeve olmalı, bir pencere değil.
	_style.bg_color = Color(0.06, 0.05, 0.06, 0.30)
	_style.set_corner_radius_all(3)
	_style.set_content_margin_all(4)
	_style.border_color = IDLE_BORDER
	_style.set_border_width_all(3)
	add_theme_stylebox_override("panel", _style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	add_child(column)

	_rank_label = Label.new()
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_label.add_theme_font_size_override("font_size", 10)
	_rank_label.modulate = Color(0.7, 0.68, 0.62)
	column.add_child(_rank_label)

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
	_hp_bar.custom_minimum_size = Vector2(0.0, 10.0)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.07, 0.07, 0.08)
	track.set_corner_radius_all(2)
	_hp_bar.add_theme_stylebox_override("background", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.68, 0.20, 0.18)
	fill.set_corner_radius_all(2)
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
		bound_unit.figure_kind, bound_unit.is_player_side, _figure_state(bound_unit), depth
	)
	_style.border_color = _border_color(is_active, is_target)
	_refresh_status(bound_unit)

	# Ölü/düşmüş bir birim soluk durur ama gizlenmez: saftaki boşluğu
	# görmek mevki mantığının okunabilmesi için gerekli.
	modulate = Color(1, 1, 1, 1) if bound_unit.is_alive() else Color(1, 1, 1, 0.55)
	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if is_target else Control.CURSOR_ARROW
	)

## Silüetin duruşunu ve paletini belirleyen durum. Düşen bir figür
## ayakta soluk durmuyor, yere çöküyor - "düşmüş" ancak duruş değişince
## okunuyor.
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
	if bound_unit.protection > 0:
		_add_badge(
			tr("UI_COMBAT_BADGE_PROT") % bound_unit.protection, Color(0.55, 0.62, 0.72)
		)
	if bound_unit.is_stressed:
		_add_badge(tr("UI_COMBAT_BADGE_STRESSED"), Color(0.78, 0.62, 0.35))

	# Durum efektleri kalan turlarıyla görünüyor. Görünmeyen bir kanama,
	# "canım neden azalıyor" sorusunu cevapsız bırakır - kilitli
	# yeteneğin sebebini göstermekle aynı kural.
	if bound_unit.has_status(CombatUnit.STATUS_BLEED):
		_add_badge(
			tr("UI_COMBAT_BADGE_BLEED") % bound_unit.get_status_rounds(CombatUnit.STATUS_BLEED),
			ArtPalette.BLOOD
		)
	if bound_unit.has_status(CombatUnit.STATUS_BLIGHT):
		_add_badge(
			tr("UI_COMBAT_BADGE_BLIGHT") % bound_unit.get_status_rounds(CombatUnit.STATUS_BLIGHT),
			Color(0.48, 0.66, 0.34)
		)
	if bound_unit.is_stunned:
		_add_badge(tr("UI_COMBAT_BADGE_STUN"), Color(0.86, 0.82, 0.40))

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
