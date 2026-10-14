class_name GrimTheme
extends RefCounted

## Karanlık arayüz taslağının ortak kalemi: yazı yüzleri, dokular, birkaç
## hazır kutu. **Motorun varsayılan temasına kurulmuyor** - WaybookTheme
## oyunun teması olarak kalıyor; bu dosya yalnızca taslak ekranlarının
## okuduğu bir yardımcı. Onaydan sonra hangi parçanın WaybookTheme'e
## taşınacağı docs/ui/REDESIGN.md'de.
##
## Renk yine ArtPalette'ten (GRIM_*). Kontroller düz kutu (StyleBoxFlat):
## oyuncu deri ve doku kaplı kontrolleri reddetti (Waybook UI Rules), o
## yüzden doku yalnızca *resim* olan yerde - haber kartının kâğıdı,
## mürekkep lekesi, kırağı ve kir katmanları.

const DIR: String = "res://data/assets/ui/grim/"
const TITLE_FONT_PATH: String = "res://data/assets/fonts/IMFellEnglishSC.ttf"
const SFX_DIR: String = "res://data/assets/audio/"

## Etkileşim -> ses imi. AudioManager'ın SFX tablosuna onaydan sonra
## girecek; taslakta yalnızca eşleme burada.
const SOUND_CUES: Dictionary = {
	"hover": "ui_hover.wav",
	"press": "ui_press.wav",
	"page": "ui_page.wav",
	"coin": "ui_coin.wav",
	"stamp": "ui_stamp.wav",
	"alert": "ui_alert.wav",
}

const TITLE_SIZE: int = 30
const HEADING_SIZE: int = 22
const BODY_SIZE: int = 17
const SMALL_SIZE: int = 14
const NOTICE_SLICE: int = 28

static var _cache: Dictionary = {}

static func texture(file_name: String) -> Texture2D:
	var path := DIR + file_name
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
	_cache[path] = tex
	return tex

static func title_font() -> Font:
	if _cache.has(TITLE_FONT_PATH):
		return _cache[TITLE_FONT_PATH]
	var font: Font = null
	if ResourceLoader.exists(TITLE_FONT_PATH):
		font = load(TITLE_FONT_PATH)
	else:
		var file := FontFile.new()
		file.load_dynamic_font(ProjectSettings.globalize_path(TITLE_FONT_PATH))
		font = file
	if font is FontFile:
		# Başlık yüzü Türkçe harfleri taşımazsa kitap yüzüne düşsün.
		(font as FontFile).fallbacks = [WaybookTheme.get_font()]
	_cache[TITLE_FONT_PATH] = font
	return font

## Başlık ya da gövde yazısı. Başlık IM Fell (yıpranmış serif), gövde
## oyunun EB Garamond'u - okunurluk başlığa feda edilmiyor.
static func label(text: String, size: int, color: Color, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", title_font())
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

## Demir çerçeveli koyu levha: kömür zemin, pas kenar. Düz kutu.
static func iron_panel(alpha: float = 0.94) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, alpha)
	box.border_color = ArtPalette.GRIM_RUST
	box.set_border_width_all(1)
	box.border_width_top = 2
	box.set_corner_radius_all(2)
	box.set_content_margin_all(14)
	box.shadow_color = Color(0, 0, 0, 0.6)
	box.shadow_size = 10
	return box

## Ekranın kenar şeridi (üst/alt çubuk): kömürden saydama.
static func bar_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.88)
	box.border_color = Color(ArtPalette.GRIM_RUST, 0.8)
	box.border_width_bottom = 1
	box.border_width_top = 1
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

## Haber kartının kâğıdı: tek resim olan dokulu kutu.
static func notice_panel() -> StyleBox:
	var tex := texture("notice_card.png")
	if tex == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = ArtPalette.GRIM_PARCHMENT
		flat.set_content_margin_all(NOTICE_SLICE)
		return flat
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = NOTICE_SLICE
	box.texture_margin_right = NOTICE_SLICE
	box.texture_margin_top = NOTICE_SLICE
	box.texture_margin_bottom = NOTICE_SLICE
	box.content_margin_left = NOTICE_SLICE + 4
	box.content_margin_right = NOTICE_SLICE + 4
	box.content_margin_top = NOTICE_SLICE - 6
	box.content_margin_bottom = NOTICE_SLICE - 4
	return box

## Düz, kenarı ince pas bir düğme - hover'da kehribar kenar, basınca kan.
static func button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", title_font())
	b.add_theme_font_size_override("font_size", BODY_SIZE + 1)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, _button_box(state))
	b.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	b.add_theme_color_override("font_hover_color", ArtPalette.GRIM_AMBER)
	b.add_theme_color_override("font_pressed_color", ArtPalette.BONE)
	b.add_theme_color_override("font_disabled_color", Color(ArtPalette.GRIM_PARCHMENT_DIM, 0.6))
	return b

static func _button_box(state: String) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL_SOFT, 0.85)
	box.border_color = Color(ArtPalette.GRIM_RUST, 0.9)
	box.set_border_width_all(1)
	box.set_corner_radius_all(2)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	match state:
		"hover":
			box.border_color = ArtPalette.GRIM_AMBER
			box.bg_color = Color(0.17, 0.13, 0.10, 0.92)
		"pressed":
			box.border_color = ArtPalette.GRIM_CRIMSON
			box.bg_color = Color(0.20, 0.07, 0.05, 0.95)
		"disabled":
			box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.6)
			box.border_color = Color(ArtPalette.GRIM_IRON, 0.7)
		"focus":
			box.bg_color = Color(0, 0, 0, 0)
			box.border_color = Color(ArtPalette.GRIM_AMBER, 0.8)
	return box

## Ekranın tamamını kaplayan, fare olaylarını yutmayan bir doku katmanı.
static func overlay(file_name: String, alpha: float = 1.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture(file_name)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = alpha
	return rect
