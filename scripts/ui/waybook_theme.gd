class_name WaybookTheme
extends RefCounted

## Waybook: arayüzün tamamı tek bir kervan hesap defteri gibi giyiniyor. Bu
## dosya o defterin malzemelerinden tek paylaşılan `Theme`'i kuruyor - her
## panelin deri cildi, geri alınamaz kararların daha ağır mühürlü cildi, her
## düğmenin kendisi olan fihrist sekmesi, mürekkep çizgisi, kurdele kaydırma
## çubuğu, iğneyle tutturulmuş ipucu fişi - ve her yazının dizildiği tek
## kitap yüzü.
##
## **Neden ekran ekran override değil tek tema.** Bundan önce opak bir panel
## isteyen her ekran kendi `StyleBoxFlat`'ını kendi iki renk sabitiyle
## kuruyordu (aynı panelin dokuz kopyası, birbirinden hafifçe farklı iki
## kahverengi). Ortak bir görünüm ancak tek bir yerden geliyorsa ortaktır -
## `ArtPalette` ve `ArtDraw`'ın var olma sebebinin aynısı.
##
## **Renk hâlâ `ArtPalette`'ten geliyor.** Dokular boyanmış malzeme (deri,
## pirinç, kâğıt); *arayüzün* verdiği her karar - panelin iç zemini, yazının
## rengi, sekmenin üstüne gelince ne kadar aydınlandığı, kilitliyken ne
## kadar solduğu - bir palet rolü, burada dolgu ya da ton olarak uygulanıyor.
## Panelin iç zemini çalışma anında birleştiriliyor (dolgu + leke maskesi +
## çerçeve), tam da hiçbir renk kararı bir PNG'ye gömülmesin diye.
##
## **Proje temasına değil motorun varsayılan temasına kuruluyor.** Bir
## `CanvasLayer` altındaki `Control` ebeveyninin temasını devralmıyor ve bu
## oyundaki katmanların neredeyse hepsi tam olarak bu (sahnesiz `.new()` +
## `CanvasLayer` panelleri). Varsayılan tema her arama zincirinin son
## halkası; oraya yazmak, paletin kopyalanacağı bir `.tres` dosyası olmadan
## hepsine ulaşıyor.

const ART_DIR: String = "res://data/assets/ui/waybook/"
const FONT_PATH: String = "res://data/assets/fonts/EBGaramond.ttf"
## Kitap yüzünün göz yüksekliği motorun sans'ından küçük; 18 eski 16 gibi
## okunuyor ve aşağı yukarı aynı genişliği kaplıyor.
const FONT_SIZE: int = 18
const TOOLTIP_FONT_SIZE: int = 16

## Ekranların `theme_type_variation` ile seçtiği tema çeşitleri.
const SEAL_PANEL: StringName = &"SealPanel"
const SLIP_PANEL: StringName = &"SlipPanel"
const HUD_BAR: StringName = &"HudBar"
const PAGE_LABEL: StringName = &"PageLabel"
const PAGE_HEADING: StringName = &"PageHeading"

## Dokuz parça geometrisi, doku pikseli cinsinden, işlenmiş PNG'ler
## üstünde ölçüldü (tools/waybook_assets.py boyutları basıyor). Her pay köşe
## süsünü bütünüyle içermeli, yoksa esneme onu bulaştırır.
const BINDING_SLICE: int = 60
const BINDING_FILL_INSET: int = 20
const BINDING_CONTENT: int = 40
const SEAL_SLICE: int = 78
const SEAL_FILL_INSET: int = 26
const SEAL_CONTENT: int = 60
## Sekmenin sol ucu kıvrık bir kulak, o yüzden sol pay daha geniş.
const TAB_SLICE: Array[int] = [40, 14, 24, 14]
const TAB_CONTENT: Array[int] = [34, 16, 20, 16]
const SLIP_SLICE: Array[int] = [34, 72, 38, 40]
const SLIP_CONTENT: Array[int] = [36, 66, 42, 36]

static var _installed: bool = false
static var _font: Font = null

## Tekrar çağrılabilir: autoload açılışta çağırıyor, başsız screenshot
## araçları kendileri çağırıyor (`--script` kipinde autoload'lar canlı değil).
static func install() -> void:
	if _installed:
		return
	_installed = true
	var target := ThemeDB.get_default_theme()
	target.merge_with(build())
	target.default_font = get_font()
	target.default_font_size = FONT_SIZE
	ThemeDB.fallback_font = get_font()
	ThemeDB.fallback_font_size = FONT_SIZE

## Oyunun yüzü, arkasında motorun kendi fontu: EB Garamond Latin (Türkçe
## dahil) ve Kiril'i taşıyor, taşımadığı her şey (bugün CJK) daha önce
## çizilen fonta düşüyor - önceki fontun çizebildiği bir karakter asla boş
## kutuya dönmüyor.
static func get_font() -> Font:
	if _font != null:
		return _font
	var book: FontFile = load(FONT_PATH)
	var engine_default := ThemeDB.get_default_theme().default_font
	if engine_default == null:
		engine_default = ThemeDB.fallback_font
	if engine_default != null and engine_default != book:
		book.fallbacks = [engine_default]
	_font = book
	return _font

static func texture(file_name: String) -> Texture2D:
	return load(ART_DIR + file_name) as Texture2D

## Tek bir Waybook resmi (ikon, mühür, defter nesnesi) verilen yükseklikte,
## oranı korunarak. Ekranlar resmi hep bu kapıdan alıyor ki boyut ve
## germe kuralı her yerde aynı olsun.
static func picture(file_name: String, height: float) -> TextureRect:
	var rect := TextureRect.new()
	var tex := texture(file_name)
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var aspect := 1.0 if tex == null else tex.get_size().x / maxf(tex.get_size().y, 1.0)
	rect.custom_minimum_size = Vector2(height * aspect, height)
	return rect

## Bir malın ikonu (`item_<id>.png`). Kayıt uyumluluğu için sabit kalan
## `test_` önekli eski id'ler (bkz. ItemCatalog) dosya adında düşüyor.
## İkonu olmayan bir mal boş bir yer tutucu alır - satır hizası bozulmasın.
static func item_icon(item_id: String, height: float) -> Control:
	var file_name := "item_%s.png" % item_id.trim_prefix("test_")
	if not ResourceLoader.exists(ART_DIR + file_name):
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(height, height)
		return spacer
	return picture(file_name, height)

static func build() -> Theme:
	var theme := Theme.new()
	_build_panels(theme)
	_build_buttons(theme)
	_build_tabs(theme)
	_build_rules_and_scroll(theme)
	_build_tooltip(theme)
	_build_labels(theme)
	return theme

# --- Paneller ---

static func binding_panel() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = _filled_frame("g2_binding.png", BINDING_FILL_INSET)
	box.set_texture_margin_all(BINDING_SLICE)
	box.set_content_margin_all(BINDING_CONTENT)
	return box

static func seal_panel() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = _filled_frame("g3_seal.png", SEAL_FILL_INSET)
	box.set_texture_margin_all(SEAL_SLICE)
	box.set_content_margin_all(SEAL_CONTENT)
	# Her kenar aynalanmış bir deri şerit (tools/waybook_assets.py
	# `declasp`), döşenince deri boyandığı ölçekte kalıyor.
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return box

static func _build_panels(theme: Theme) -> void:
	var binding := binding_panel()
	theme.set_stylebox("panel", "PanelContainer", binding)
	theme.set_stylebox("panel", "Panel", binding)
	theme.set_stylebox("panel", "PopupPanel", binding)

	theme.set_type_variation(SEAL_PANEL, "PanelContainer")
	theme.set_stylebox("panel", SEAL_PANEL, seal_panel())

	theme.set_type_variation(SLIP_PANEL, "PanelContainer")
	theme.set_stylebox("panel", SLIP_PANEL, _slip())

	# Yolun HUD şeritleri dünyanın *üstünde* duruyor ve onu çerçevelememeli:
	# ince, yarı saydam bir kuşak - düz renk kalan tek panel.
	var bar := StyleBoxFlat.new()
	bar.bg_color = ArtPalette.UI_HUD_BAR
	bar.set_content_margin_all(8)
	theme.set_type_variation(HUD_BAR, "PanelContainer")
	theme.set_stylebox("panel", HUD_BAR, bar)

	var menu := StyleBoxFlat.new()
	menu.bg_color = ArtPalette.UI_PANEL_FILL
	menu.border_color = ArtPalette.GOLD_DIM
	menu.set_border_width_all(1)
	menu.set_content_margin_all(6)
	theme.set_stylebox("panel", "PopupMenu", menu)
	theme.set_color("font_color", "PopupMenu", ArtPalette.UI_TEXT)
	theme.set_color("font_hover_color", "PopupMenu", ArtPalette.UI_ACCENT)

## `ArtPalette` dolgusunun üstüne leke maskesi, onun üstüne çerçeve.
## Tema kurulurken bir kez birleştiriliyor, panel başına değil.
static func _filled_frame(frame_file: String, inset: int) -> Texture2D:
	var frame := texture(frame_file).get_image()
	frame.decompress()
	frame.convert(Image.FORMAT_RGBA8)
	var size := frame.get_size()
	var composed := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var inner := Rect2i(inset, inset, size.x - inset * 2, size.y - inset * 2)
	composed.fill_rect(inner, ArtPalette.UI_PANEL_FILL)
	var grain := texture("g10_grain_mask.png").get_image()
	grain.decompress()
	grain.convert(Image.FORMAT_RGBA8)
	composed.blend_rect(grain, Rect2i(Vector2i.ZERO, inner.size), inner.position)
	composed.blend_rect(frame, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	return ImageTexture.create_from_image(composed)

static func _slip() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture("g8_slip.png")
	_set_margins(box, SLIP_SLICE, SLIP_CONTENT)
	return box

# --- Düğmeler ---

static func _tab(tint: Color, scratched: bool = false) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = _scratched_tab() if scratched else texture("g4_tab.png")
	box.modulate_color = tint
	_set_margins(box, TAB_SLICE, TAB_CONTENT)
	return box

## Kilitli düğme sekmesini koruyor, üstüne defterin karalama çizgisi
## biniyor. Sebep düğmenin yanında ya da altında canlı metin olarak kalıyor
## - çizgi "şimdi değil" diyor, metin nedenini (Event Engine Rules:
## *sebebiyle* kilitli, asla gizli değil).
static func _scratched_tab() -> Texture2D:
	var tab := texture("g4_tab.png").get_image()
	tab.decompress()
	tab.convert(Image.FORMAT_RGBA8)
	var scratch := _recoloured("g5_scratch.png", ArtPalette.UI_INK_MARK)
	var body := Vector2i(tab.get_width() - TAB_SLICE[0] - TAB_SLICE[2] + 20, tab.get_height() - 22)
	scratch.resize(body.x, body.y, Image.INTERPOLATE_LANCZOS)
	var at := Vector2i(TAB_SLICE[0] - 10, (tab.get_height() - body.y) / 2)
	tab.blend_rect(scratch, Rect2i(Vector2i.ZERO, body), at)
	return ImageTexture.create_from_image(tab)

static func _focus() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = ArtPalette.UI_FOCUS
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.set_expand_margin_all(2)
	return box

static func _build_buttons(theme: Theme) -> void:
	for type_name in ["Button", "OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", type_name, _tab(Color.WHITE))
		theme.set_stylebox("hover", type_name, _tab(ArtPalette.UI_TINT_HOVER))
		theme.set_stylebox("pressed", type_name, _tab(ArtPalette.UI_TINT_PRESSED))
		theme.set_stylebox("hover_pressed", type_name, _tab(ArtPalette.UI_TINT_PRESSED))
		theme.set_stylebox("disabled", type_name, _tab(ArtPalette.UI_TINT_DISABLED, true))
		theme.set_stylebox("focus", type_name, _focus())
		theme.set_color("font_color", type_name, ArtPalette.UI_TEXT)
		theme.set_color("font_hover_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_pressed_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_hover_pressed_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_focus_color", type_name, ArtPalette.UI_TEXT)
		theme.set_color("font_disabled_color", type_name, ArtPalette.UI_TEXT_DIM)

# --- Sekmeler ---

static func _build_tabs(theme: Theme) -> void:
	theme.set_stylebox("tab_selected", "TabContainer", _tab(ArtPalette.UI_TINT_HOVER))
	theme.set_stylebox("tab_hovered", "TabContainer", _tab(Color.WHITE))
	theme.set_stylebox("tab_unselected", "TabContainer", _tab(ArtPalette.UI_TINT_PRESSED))
	theme.set_stylebox("tab_disabled", "TabContainer", _tab(ArtPalette.UI_TINT_DISABLED, true))
	theme.set_stylebox("tab_focus", "TabContainer", _focus())
	theme.set_stylebox("panel", "TabContainer", binding_panel())
	theme.set_color("font_selected_color", "TabContainer", ArtPalette.UI_ACCENT)
	theme.set_color("font_hovered_color", "TabContainer", ArtPalette.UI_TEXT)
	theme.set_color("font_unselected_color", "TabContainer", ArtPalette.UI_TEXT_DIM)
	theme.set_color("font_disabled_color", "TabContainer", ArtPalette.UI_TEXT_DIM)

# --- Çizgiler ve kaydırma ---

static func _build_rules_and_scroll(theme: Theme) -> void:
	var rule := StyleBoxTexture.new()
	rule.texture = ImageTexture.create_from_image(_recoloured("g6_rule.png", ArtPalette.UI_RULE))
	# Mürekkep damlası sağ uçta; bütün kalsın.
	rule.texture_margin_left = 6.0
	rule.texture_margin_right = 34.0
	# HSeparator çizgiyi stil kutusunun *en küçük* yüksekliğinde çiziyor;
	# içerik payı sıfır kalınca çizgi sıfır piksel çiziliyordu.
	rule.content_margin_top = 9.0
	rule.content_margin_bottom = 10.0
	theme.set_stylebox("separator", "HSeparator", rule)
	theme.set_constant("separation", "HSeparator", 20)

	var ribbon := StyleBoxTexture.new()
	ribbon.texture = texture("g7_scroll.png")
	ribbon.texture_margin_top = 14.0
	ribbon.texture_margin_bottom = 14.0
	ribbon.content_margin_left = 7.0
	ribbon.content_margin_right = 7.0
	var ribbon_hot := ribbon.duplicate() as StyleBoxTexture
	ribbon_hot.modulate_color = ArtPalette.UI_TINT_HOVER
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(ArtPalette.INK, 0.55)
	groove.content_margin_left = 7.0
	groove.content_margin_right = 7.0
	theme.set_stylebox("grabber", "VScrollBar", ribbon)
	theme.set_stylebox("grabber_highlight", "VScrollBar", ribbon_hot)
	theme.set_stylebox("grabber_pressed", "VScrollBar", ribbon_hot)
	theme.set_stylebox("scroll", "VScrollBar", groove)
	theme.set_stylebox("scroll_focus", "VScrollBar", groove)

# --- İpucu ---

static func _build_tooltip(theme: Theme) -> void:
	theme.set_stylebox("panel", "TooltipPanel", _slip())
	theme.set_color("font_color", "TooltipLabel", ArtPalette.UI_TEXT_ON_PAGE)
	theme.set_font_size("font_size", "TooltipLabel", TOOLTIP_FONT_SIZE)
	theme.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0))

# --- Yazılar ---

static func _build_labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", ArtPalette.UI_TEXT)
	# Kâğıda (fiş, sayfa) dizilen yazı kemik değil mürekkep rengi.
	theme.set_type_variation(PAGE_LABEL, "Label")
	theme.set_color("font_color", PAGE_LABEL, ArtPalette.UI_TEXT_ON_PAGE)
	theme.set_type_variation(PAGE_HEADING, "Label")
	theme.set_color("font_color", PAGE_HEADING, ArtPalette.BLOOD)

## Bir mürekkep işaretinin şeklini (alfa) koruyup rengini paletten verir.
## Çarpımsal `modulate` koyu bir mürekkebi açamaz; renk burada yeniden
## atanıyor, ama yalnızca işaretin kendisine - deri ve pirinç dokulara asla.
static func _recoloured(file_name: String, colour: Color) -> Image:
	var image := texture(file_name).get_image()
	image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.0:
				image.set_pixel(x, y, Color(colour, alpha * colour.a))
	return image

static func _set_margins(box: StyleBoxTexture, slice: Array[int], content: Array[int]) -> void:
	box.texture_margin_left = slice[0]
	box.texture_margin_top = slice[1]
	box.texture_margin_right = slice[2]
	box.texture_margin_bottom = slice[3]
	box.content_margin_left = content[0]
	box.content_margin_top = content[1]
	box.content_margin_right = content[2]
	box.content_margin_bottom = content[3]
