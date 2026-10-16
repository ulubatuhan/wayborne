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
## Gotik vitrin yüzü (Grenze Gotisch, OFL): yalnızca oyunun adı ve şehrin
## sancağı - bir ekranda en fazla bir kez. Okunacak hiçbir şey bununla
## yazılmaz.
const DISPLAY_FONT_PATH: String = "res://data/assets/fonts/GrenzeGotisch.ttf"
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

static func display_font() -> Font:
	if _cache.has(DISPLAY_FONT_PATH):
		return _cache[DISPLAY_FONT_PATH]
	var font: Font = null
	if ResourceLoader.exists(DISPLAY_FONT_PATH):
		font = load(DISPLAY_FONT_PATH)
	else:
		var file := FontFile.new()
		file.load_dynamic_font(ProjectSettings.globalize_path(DISPLAY_FONT_PATH))
		font = file
	if font is FontFile:
		(font as FontFile).fallbacks = [title_font()]
	_cache[DISPLAY_FONT_PATH] = font
	return font

static func display_label(text: String, size: int, color: Color) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", display_font())
	return l

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

## Kenar şeridi: perçinli pas demir kenarlı koyu tahta (ambientCG CC0,
## tools/ui_scenes/ui_kit.py). Metin şeridin düz, koyu orta kısmında kalır.
static func bar_panel() -> StyleBox:
	var tex := CityFront.kit("strip_wood.png")
	if tex == null:
		return flat_bar_panel()
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_top = 12
	box.texture_margin_bottom = 12
	box.texture_margin_left = 12
	box.texture_margin_right = 12
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 12
	box.content_margin_bottom = 10
	return box

## Taş levha (mekân levhası, gösterge plakası, metin düğmesi).
static func plate_box(lit: bool = false, pad: Vector4 = Vector4(14, 6, 14, 6)) -> StyleBox:
	var tex := CityFront.kit("plate_hover.png" if lit else "plate.png")
	if tex == null:
		return iron_panel()
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = 12
	box.texture_margin_right = 12
	box.texture_margin_top = 12
	box.texture_margin_bottom = 12
	box.content_margin_left = pad.x
	box.content_margin_top = pad.y
	box.content_margin_right = pad.z
	box.content_margin_bottom = pad.w
	return box

## Yırtık sancak etiketi: kötü haber kızıl, iyi haber yosun.
static func banner_tag(text: String, good: bool) -> PanelContainer:
	var p := PanelContainer.new()
	var tex := CityFront.kit("banner.png")
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = 16
	box.texture_margin_right = 40
	box.texture_margin_top = 8
	box.texture_margin_bottom = 8
	box.content_margin_left = 22
	box.content_margin_right = 34
	box.content_margin_top = 3
	box.content_margin_bottom = 5
	p.add_theme_stylebox_override("panel", box)
	if good:
		p.self_modulate = Color(0.45, 0.85, 0.5)
	p.add_child(label(text, SMALL_SIZE, ArtPalette.BONE))
	return p

## İkonlu düğme: madalyon resmi, altında ad. Kutusuz - resmin kendisi
## düğme; üstüne gelince kehribar.
static func icon_button(text: String, icon_name: String) -> Button:
	var b := Button.new()
	b.flat = true
	b.custom_minimum_size = Vector2(92, 78)
	b.icon = CityFront.kit("icon_%s.png" % icon_name)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.text = text
	b.add_theme_font_override("font", title_font())
	b.add_theme_font_size_override("font_size", SMALL_SIZE + 1)
	b.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	b.add_theme_color_override("font_hover_color", ArtPalette.GRIM_AMBER)
	b.add_theme_color_override("font_pressed_color", ArtPalette.BONE)
	b.add_theme_color_override("icon_hover_color", Color(1.25, 1.1, 0.9))
	b.add_theme_constant_override("icon_max_width", 52)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	return b

## Kızıl, ağır düğme: kapıdan çıkmak, geri dönmek - geri alınamayan adım.
static func crimson_button(text: String, icon_name: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if icon_name != "":
		b.icon = CityFront.kit("icon_%s.png" % icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 48)
	b.custom_minimum_size = Vector2(220, 64)
	b.add_theme_font_override("font", title_font())
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", ArtPalette.BONE)
	b.add_theme_color_override("font_hover_color", ArtPalette.GRIM_AMBER)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = ArtPalette.GRIM_CRIMSON.darkened(0.25 if state == "normal" else (0.0 if state == "hover" else 0.45))
		box.border_color = ArtPalette.GRIM_AMBER if state == "hover" else ArtPalette.GRIM_RUST.darkened(0.3)
		box.set_border_width_all(2)
		box.set_corner_radius_all(2)
		box.shadow_color = Color(0, 0, 0, 0.6)
		box.shadow_size = 8
		box.set_content_margin_all(10)
		if state == "focus":
			box.bg_color = Color(0, 0, 0, 0)
		b.add_theme_stylebox_override(state, box)
	return b

## Düz kömür şerit - doku dosyası yoksa.
static func flat_bar_panel() -> StyleBoxFlat:
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
	if CityFront.kit("plate.png") != null:
		b.add_theme_stylebox_override("normal", plate_box(false))
		b.add_theme_stylebox_override("hover", plate_box(true))
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
