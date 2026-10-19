class_name StruckLine
extends MarginContainer

## Defterin üstü çizili satırı: canlı bir metin ve onun üstünden geçen
## ıslak mürekkep darbesi (R9). Darbe soldan sağa çekiliyor - bir isim
## silinmiyor, çiziliyor (bkz. Lineage Rules: "CaravanLedger never deletes a
## line"). `animate` kapalıyken darbe baştan tam; defter panelindeki eski
## satırlar için, çünkü onlar zaten çizilmiş.
##
## Mürekkep dokusu yeniden boyanmıyor, yalnızca ton alıyor: koyu zeminde
## `ArtPalette.UI_INK_MARK`, kâğıt üstünde `INK` (bkz. `set_on_page`).

const STRIKE_FILE: String = "r9_strike.png"
const STRIKE_SECONDS: float = 0.9
const STRIKE_DELAY_SECONDS: float = 0.5
## Darbe yazının ortasından biraz aşağıdan geçiyor ve iki uçtan taşıyor -
## elle çekilmiş bir çizgi harflerin kutusuna oturmaz.
const STRIKE_OVERHANG: float = 6.0
## İnce: yazıyı örtmemeli, üstünden geçmeli - kalın bir darbe ismi
## okunmaz bir kutuya çeviriyordu (ilk ekran görüntüsü tam bunu gösterdi).
const STRIKE_HEIGHT_RATIO: float = 0.15
## Kâğıt üstünde daha da ince ve kan kırmızısı mürekkep (görev 9.11 denetimi):
## siyah ve kalın darbe defterde adı tamamen örtüyordu; onaylı taslakta ad
## çizginin altından okunuyor.
const PAGE_STRIKE_HEIGHT_RATIO: float = 0.085
const PAGE_STRIKE_TINT: Color = Color(0.46, 0.11, 0.10, 0.9)

var label: Label
var progress: float = 1.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		if _ink != null:
			_ink.queue_redraw()
var _ink: Control
var _tint: Color = ArtPalette.UI_INK_MARK
var _height_ratio: float = STRIKE_HEIGHT_RATIO

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	_ink = Control.new()
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.draw.connect(_draw_strike)
	add_child(_ink)

func setup(text: String, animate: bool) -> StruckLine:
	label.text = text
	progress = 0.0 if animate else 1.0
	if animate:
		ready.connect(_play, CONNECT_ONE_SHOT)
	return self

func set_on_page(on_page: bool) -> StruckLine:
	_tint = PAGE_STRIKE_TINT if on_page else ArtPalette.UI_INK_MARK
	_height_ratio = PAGE_STRIKE_HEIGHT_RATIO if on_page else STRIKE_HEIGHT_RATIO
	label.theme_type_variation = WaybookTheme.PAGE_LABEL if on_page else &""
	_ink.queue_redraw()
	return self

func _play() -> void:
	var tween := create_tween()
	tween.tween_interval(STRIKE_DELAY_SECONDS)
	tween.tween_property(self, "progress", 1.0, STRIKE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _draw_strike() -> void:
	if progress <= 0.0:
		return
	var texture := WaybookTheme.texture(STRIKE_FILE)
	if texture == null:
		return
	# Tek satırlık metnin genişliği; sarılmış metinde satır kutusunun tamamı.
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_width := minf(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, size.x)
	var line_height := font.get_height(font_size)
	var x0 := _text_left(text_width) - STRIKE_OVERHANG
	var full := text_width + STRIKE_OVERHANG * 2.0
	var height := line_height * _height_ratio
	var y := minf(size.y, line_height) * 0.55 - height * 0.5
	var tex_size := texture.get_size()
	var shown := full * progress
	_ink.draw_texture_rect_region(
		texture, Rect2(x0, y, shown, height),
		Rect2(0.0, 0.0, tex_size.x * progress, tex_size.y), _tint
	)

func _text_left(text_width: float) -> float:
	match label.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			return (size.x - text_width) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			return size.x - text_width
	return 0.0
