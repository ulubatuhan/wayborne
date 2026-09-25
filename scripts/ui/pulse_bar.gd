class_name PulseBar
extends Control

## Moral/stres gibi bir değeri gösteren, "değişince parlayıp sakinleşince
## geri solan" bir çubuk - sürekli göz tırmalamasın diye varsayılan olarak
## soluk durur, bir değişiklik olduğunda tam görünür olur, birkaç saniye
## sonra tekrar soluklaşır (bkz. world_hub.gd).

const IDLE_ALPHA: float = 0.35
const VISIBLE_ALPHA: float = 1.0
const FADE_DELAY: float = 2.5
const FADE_DURATION: float = 1.2
## Ölçüldü: yol HUD'una dördüncü çubuk (takat) eklenince 150'lik metin
## çubukları üst şeridi taşırmıştı. Şişe hâlinde adı ikon ve ipucu taşıyor,
## yalnızca sayı yazılı kalıyor - ikon + şişe + sayı 154'e sığıyor (rakam
## fontu 14'ten 16'ya çıkınca 6 px'lik pay eklendi, `VALUE_WIDTH`'in
## kendisiyle birlikte).
const BAR_SIZE: Vector2 = Vector2(154, 22)

var _value: float = 0.0
var _max_value: float = 100.0
var _label_prefix: String = ""
var _has_value: bool = false

## Şişe: Waybook'un pirinç kapaklı cam tüpü (r4_vial). Sıvı camın içinde,
## iki kapağın arasında duruyor - oran dokunun kendisi üstünde ölçüldü.
const VIAL_FILE: String = "r4_vial.png"
const ICON_SIZE: float = 20.0
const VIAL_SIZE: Vector2 = Vector2(96.0, 12.0)
const VALUE_WIDTH: float = 32.0
const VIAL_LIQUID: Rect2 = Rect2(0.10, 0.24, 0.80, 0.52)
const MARKER_WIDTH: float = 2.0

var _icon: TextureRect
var _vial: TextureRect
var _empty: ColorRect
var _fill: ColorRect
var _label: Label
var _marker: ColorRect
var _marker_note: String = ""
var _fade_tween: Tween
var _built: bool = false

func _ready() -> void:
	_ensure_built()

## setup()/set_value() de çağırır (bkz. CombatPanel/RecruitPanel deseni) -
## _ready()'nin add_child()'dan hemen sonra senkron çalıştığına
## güvenmiyoruz, çocuklar ilk gerektiğinde kurulur.
func _ensure_built() -> void:
	if _built:
		return
	_built = true

	custom_minimum_size = BAR_SIZE
	modulate.a = IDLE_ALPHA
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Çocuklar sabit konumlu; şerit satırı daha yüksek olduğunda çubuk
	# satırın ortasında dursun, tepesinde değil.
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_icon = TextureRect.new()
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	_icon.position = Vector2(0.0, (BAR_SIZE.y - ICON_SIZE) * 0.5)
	add_child(_icon)

	var vial_origin := Vector2(ICON_SIZE + 2.0, (BAR_SIZE.y - VIAL_SIZE.y) * 0.5)
	var liquid := Rect2(
		vial_origin + VIAL_LIQUID.position * VIAL_SIZE, VIAL_LIQUID.size * VIAL_SIZE
	)
	_vial = TextureRect.new()
	_vial.texture = WaybookTheme.texture(VIAL_FILE)
	_vial.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vial.stretch_mode = TextureRect.STRETCH_SCALE
	_vial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vial.position = vial_origin
	_vial.size = VIAL_SIZE
	add_child(_vial)

	# Boş cam koyulaşıyor, sıvı onun üstünde: cam dokusu açık gri
	# boyanmış, boş bir şişeyle dolu bir şişe öyle ayırt edilmiyordu.
	_empty = ColorRect.new()
	_empty.color = ArtPalette.UI_GAUGE_EMPTY
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.position = liquid.position
	_empty.size = liquid.size
	add_child(_empty)

	_fill = ColorRect.new()
	_fill.color = ArtPalette.UI_GAUGE_MORALE
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.position = liquid.position
	_fill.size = Vector2(0.0, liquid.size.y)
	add_child(_fill)

	# İşaret: ortalamanın yanında tek bir kişinin değeri (bkz. set_marker).
	# Şişenin içinde, sıvının üstünde ince bir çentik.
	_marker = ColorRect.new()
	_marker.color = ArtPalette.UI_SIGNAL_ESCALATED
	_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.size = Vector2(MARKER_WIDTH, liquid.size.y + 4.0)
	_marker.position = Vector2(liquid.position.x, liquid.position.y - 2.0)
	_marker.visible = false
	add_child(_marker)

	_label = Label.new()
	_label.position = Vector2(vial_origin.x + VIAL_SIZE.x + 3.0, 0.0)
	_label.size = Vector2(VALUE_WIDTH, BAR_SIZE.y)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

## `icon_file` boşsa (eski çağıranlar) ikon yeri boş kalır; çubuğun adı
## her durumda ipucunda - ikon adı okutmuyor, yalnızca hatırlatıyor.
func setup(label_prefix: String, fill_color: Color, icon_file: String = "") -> void:
	_ensure_built()
	_label_prefix = label_prefix
	_fill.color = fill_color
	tooltip_text = label_prefix
	if icon_file != "":
		_icon.texture = WaybookTheme.texture(icon_file)

## Değer değişmediyse yalnızca metni/doluluğu tazeler, parlamaz - ilk
## çağrıda (henüz değer yokken) da parlamıyor, oyun açılır açılmaz çubuk
## göz tırmalamasın diye.
func set_value(new_value: float, max_value: float = 100.0) -> void:
	_ensure_built()
	var changed := _has_value and not is_equal_approx(new_value, _value)
	_has_value = true
	_value = new_value
	_max_value = maxf(1.0, max_value)

	_fill.size.x = _empty.size.x * clampf(_value / _max_value, 0.0, 1.0)
	_label.text = "%d" % int(round(_value))
	_refresh_tooltip()

	if changed:
		_pulse()

## Ortalamanın yanında bir kişiyi işaretler: stres çubuğu partinin
## ortalamasını gösteriyor, ama kırılan ortalama değil kişi. Çentik en
## yıpranmış kişinin değerinde durur, ipucu adını söyler. Negatif değer
## işareti kaldırır.
func set_marker(value: float, note: String = "") -> void:
	_ensure_built()
	_marker.visible = value >= 0.0
	_marker_note = note if value >= 0.0 else ""
	if _marker.visible:
		var ratio := clampf(value / _max_value, 0.0, 1.0)
		_marker.position.x = _empty.position.x + _empty.size.x * ratio - MARKER_WIDTH * 0.5
	_refresh_tooltip()

func is_marker_visible() -> bool:
	return _marker != null and _marker.visible

func get_marker_x() -> float:
	return _marker.position.x + MARKER_WIDTH * 0.5 if _marker != null else 0.0

func _refresh_tooltip() -> void:
	tooltip_text = "%s %d" % [_label_prefix, int(round(_value))]
	if not _marker_note.is_empty():
		tooltip_text += "\n" + _marker_note

func _pulse() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	modulate.a = VISIBLE_ALPHA
	_fade_tween = create_tween()
	_fade_tween.tween_interval(FADE_DELAY)
	_fade_tween.tween_property(self, "modulate:a", IDLE_ALPHA, FADE_DURATION)
