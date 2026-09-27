class_name WaybookTheme
extends RefCounted

## Waybook: arayüzün tek paylaşılan `Theme`'i. Denetimler (panel, geri
## alınamaz kararların paneli, düğme, sekme, giriş alanı, hücre, kaydırma
## çubuğu) tek bir minimal düz kutu ailesi - ince çizgi, ortak köşe, palet
## tonlu dolgu. Deri dokular oyuncu tarafından reddedildi; boyanmış
## malzeme yalnızca resimlerde (masa sahneleri, mühür, ikonlar), mürekkep
## çizgisinde ve iğneyle tutturulmuş ipucu fişinde kalıyor. Her yazı tek
## kitap yüzünde dizili.
##
## **Neden ekran ekran override değil tek tema.** Bundan önce opak bir panel
## isteyen her ekran kendi `StyleBoxFlat`'ını kendi iki renk sabitiyle
## kuruyordu (aynı panelin dokuz kopyası, birbirinden hafifçe farklı iki
## kahverengi). Ortak bir görünüm ancak tek bir yerden geliyorsa ortaktır -
## `ArtPalette` ve `ArtDraw`'ın var olma sebebinin aynısı.
##
## **Renk `ArtPalette`'ten geliyor.** Panelin zemini, çizginin rengi,
## üstüne gelince dolgunun ne kadar koyulaştığı, kilitliyken ne kadar
## solduğu - hepsi bir palet rolü.
##
## **Proje temasına değil motorun varsayılan temasına kuruluyor.** Bir
## `CanvasLayer` altındaki `Control` ebeveyninin temasını devralmıyor ve bu
## oyundaki katmanların neredeyse hepsi tam olarak bu (sahnesiz `.new()` +
## `CanvasLayer` panelleri). Varsayılan tema her arama zincirinin son
## halkası; oraya yazmak, paletin kopyalanacağı bir `.tres` dosyası olmadan
## hepsine ulaşıyor.

const ART_DIR: String = "res://data/assets/ui/waybook/"
const FONT_PATH: String = "res://data/assets/fonts/EBGaramond.ttf"
## Kitap yüzünün CJK yedekleri (Noto Serif, alt küme - bkz.
## tools/cjk_font_subset.py). Aynı Han karakteri Çince ve Japoncada farklı
## çiziliyor, o yüzden ikisi de kendi dili dışında geri çekiliyor.
const CJK_FONTS: Array = [
	["res://data/assets/fonts/NotoSerifSC-Subset.otf", "zh", "ja"],
	["res://data/assets/fonts/NotoSerifJP-Subset.otf", "ja", "zh"],
]
## Kitap yüzünün göz yüksekliği motorun sans'ından küçük; 18 eski 16 gibi
## okunuyor ve aşağı yukarı aynı genişliği kaplıyor.
const FONT_SIZE: int = 18
const TOOLTIP_FONT_SIZE: int = 16
## Savaş panelinin en küçük yazı boyutu. Sıra şeridi, yorum balonu, mevki/
## isim etiketi ve kayıt satırı 9-12 px'e kadar düşmüştü - EB Garamond'un
## küçük gözünde okunaksız (CLAUDE.md'nin "Combat micro-fonts" maddesi).
## Saf sayı taşıyan etiketler (can, durum turu sayacı) `FONT_NUMBER`;
## geri kalan her küçük savaş metni `FONT_MIN`.
const FONT_MIN: int = 15
const FONT_NUMBER: int = 16

## Ekranların `theme_type_variation` ile seçtiği tema çeşitleri.
const SEAL_PANEL: StringName = &"SealPanel"
const SLIP_PANEL: StringName = &"SlipPanel"
const HUD_BAR: StringName = &"HudBar"
const PAGE_LABEL: StringName = &"PageLabel"
const PAGE_HEADING: StringName = &"PageHeading"
## Ekranın kendi başlığı (üst-sol köşedeki TitleLabel). Sekiz ekran bunu
## sahne dosyasında elle 24 px'e sabitlemişti, geri kalanı (Market, World
## Map, Caravan Planner, City Map, Character Creation) varsayılan 18 px'te
## kalmıştı - gövde metniyle aynı boyda okunuyordu. `PAGE_HEADING`'in
## kırmızısı sayfa içeriği için (bkz. yukarısı); başlık desk zemininde
## duruyor, o yüzden Label'ın kendi UI_TEXT/gölge çiftini koruyor.
const PAGE_TITLE: StringName = &"PageTitle"
const PAGE_TITLE_FONT_SIZE: int = 24
## Harita parşömeninin üstündeki şehir yazısı: kutu yok, mürekkep yazı ve
## kâğıt renginde bir hale - haritacının yazdığı gibi.
const MAP_LABEL: StringName = &"MapLabel"
## Kargo/pazar hücresi: minimal çerçeve, içinde malın resmi.
const CELL_PANEL: StringName = &"CellPanel"
## Sürüklenebilir "Kervan Emirleri" paneli yarı saydam bir cam gibi okunuyor
## (bkz. road_journey.gd::_build_orders_panel): dolgu mürekkep tabanlı ve
## çok düşük alfalı, varsayılan düğmenin altın tonlu dolgusu camda ağır
## kalırdı. Aynı köşe ve çerçeve - aynı aile, iki zemin.
const HUD_GHOST_BUTTON: StringName = &"HudGhostButton"

## Minimal aile: her çerçeve (panel, mühür paneli, düğme, sekme, giriş
## alanı, hücre) aynı köşe yarıçapını ve aynı ince çizgiyi taşıyor. Deri
## dokular (G2 cilt, G3 mühürlü cilt, G4 sekme, R1 kayış) oyuncu tarafından
## reddedildi - "deri efektini kullandığın her yer" - ve hepsi bu tek düz
## kutu ailesine geçti. Ayrım artık doku değil, çizginin kalınlığı ve
## dolgunun tonu.
const FRAME_RADIUS: int = 3
const PANEL_CONTENT: int = 20
## Geri alınamaz kararların (olay kartı, veraset) paneli: daha kalın,
## vurgu renginde bir çizgi ve daha geniş iç pay - ağırlık dokudan değil
## çerçeveden geliyor.
const SEAL_BORDER: int = 2
const SEAL_CONTENT: int = 28
const FIELD_CONTENT: Array[int] = [10, 4, 10, 4]
const CELL_CONTENT: Array[int] = [8, 6, 8, 6]
## Yol HUD'unun şeritleriyle dünya arasındaki çizgi (eski perçinli kayışın
## yerine): bir kuşak değil, ince bir sınır.
const HUD_RULE_HEIGHT: float = 2.0
const SLIP_SLICE: Array[int] = [34, 72, 38, 40]
const SLIP_CONTENT: Array[int] = [36, 66, 42, 36]
## Yazının arkasındaki koyu hale: deri, leke ve karalama üstünde bile
## kemik rengi yazı okunsun (bkz. Waybook UI Rules - kontrast).
const TEXT_OUTLINE_SIZE: int = 4
const MAP_LABEL_HALO_SIZE: int = 6

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

## Oyunun yüzü: EB Garamond Latin (Türkçe dahil) ve Kiril'i taşıyor, Han
## ve kana tırnaklı CJK yedeklerine düşüyor, kalan her şey motorun kendi
## fontuna - önceki fontun çizebildiği bir karakter asla boş kutuya dönmüyor.
static func get_font() -> Font:
	if _font != null:
		return _font
	var book: FontFile = load(FONT_PATH)
	var fallbacks: Array[Font] = []
	for entry in CJK_FONTS:
		var face: FontFile = load(entry[0])
		if face == null:
			continue
		face.set_language_support_override(entry[1], true)
		face.set_language_support_override(entry[2], false)
		fallbacks.append(face)
	var engine_default := ThemeDB.get_default_theme().default_font
	if engine_default == null:
		engine_default = ThemeDB.fallback_font
	if engine_default != null and engine_default != book:
		fallbacks.append(engine_default)
	book.fallbacks = fallbacks
	_font = book
	return _font

static func texture(file_name: String) -> Texture2D:
	return load(ART_DIR + file_name) as Texture2D

static var _scaled_cache: Dictionary = {}

## Bir çerçeveyi dokuz parça olarak kullanmadan önce küçültmek için: dokuz
## parçanın köşeleri doku pikseliyle çiziliyor, 30 piksellik bir kenar dar
## bir kutuda gövdeyi yutuyordu. Ölçek başına bir kez üretilip saklanıyor.
static func scaled_texture(file_name: String, scale: float) -> Texture2D:
	var key := "%s@%s" % [file_name, scale]
	if _scaled_cache.has(key):
		return _scaled_cache[key]
	var image := texture(file_name).get_image()
	image.decompress()
	image.resize(
		maxi(1, int(round(image.get_width() * scale))),
		maxi(1, int(round(image.get_height() * scale))),
		Image.INTERPOLATE_LANCZOS
	)
	var result := ImageTexture.create_from_image(image)
	_scaled_cache[key] = result
	return result

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

## Bir malın satırı: ikonu ve yanında canlı metin. Kargo listelerinin
## (vagon, kervan yükü, yol dökümü) hepsi aynı kapıdan geçiyor.
static func item_line(item_id: String, text: String, icon_height: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(item_icon(item_id, icon_height))
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row

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

## Oyunun paneli: `UI_PANEL_FILL` zemin, altın tonlu ince çizgi, yumuşak
## bir gölge - masa resminin üstünde bir kâğıt kadar hafif duruyor.
static func frame_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = ArtPalette.UI_PANEL_FILL
	box.border_color = Color(ArtPalette.GOLD_DIM, 0.8)
	box.set_border_width_all(1)
	box.set_corner_radius_all(FRAME_RADIUS)
	box.shadow_color = Color(ArtPalette.INK, 0.45)
	box.shadow_size = 6
	box.set_content_margin_all(PANEL_CONTENT)
	return box

static func seal_panel() -> StyleBoxFlat:
	var box := frame_panel()
	box.border_color = ArtPalette.UI_ACCENT
	box.set_border_width_all(SEAL_BORDER)
	box.shadow_size = 10
	box.set_content_margin_all(SEAL_CONTENT)
	return box

## Yazı/sayı giriş alanı (SpinBox'ın içindeki LineEdit dahil): zeminden
## bir ton koyu bir kuyu, ince çizgili - düğmeyle aynı köşe, ama dolgusu
## altın değil mürekkep: basılacak bir şey değil, yazılacak bir yer.
static func field_frame(locked: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.INK, 0.3 if locked else 0.6)
	box.border_color = Color(ArtPalette.UI_RULE, 0.3) if locked else ArtPalette.UI_RULE
	box.set_border_width_all(1)
	box.set_corner_radius_all(FRAME_RADIUS)
	_set_content(box, FIELD_CONTENT)
	return box

static func _build_panels(theme: Theme) -> void:
	var panel := frame_panel()
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)

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

## --- Masa çalışma alanı ---
## Yönetim ekranlarının arka planı bir masa resmi: kenarlarındaki mum,
## mühür, terazi resmin kendisi. Satırlar ekranın bir ucundan öbür ucuna
## uzanınca hem o nesnelerin üstünden geçiyor hem de açık renkli çadır
## bezinde okunmuyordu. Metin ortada, genişliğin en çok %65'ini tutan bir
## sütuna çekiliyor; arkasına kenarları yumuşak bir mürekkep bandı iniyor,
## kenarlardaki perde hafifliyor ki masa görünsün. Dar ekranda sütun tam
## genişlik - yan boşluk, satırı kırmaktan daha pahalı.
const WORKSPACE_WIDTH_RATIO: float = 0.65
const WORKSPACE_FULL_WIDTH_BELOW: float = 1100.0
const WORKSPACE_EDGE_MARGIN: int = 24
const WORKSPACE_BAND_ALPHA: float = 0.55
const WORKSPACE_BAND_FEATHER: int = 56
const WORKSPACE_SIDE_SCRIM_ALPHA: float = 0.38

## Bir kenardaki boşluk, ekran genişliğine göre. Saf fonksiyon - test ve
## ekran aynı sayıyı okusun diye.
## `content_min`: sütundaki içeriğin en dar genişliği. Sütun ondan dar
## olamaz - %65 oranı içeriği sıkıştırınca 1280'de parti ve tayfa
## ekranlarında yatay kaydırma çubuğu açılıyordu (ölçüldü).
static func workspace_side_margin(total_width: float, content_min: float = 0.0) -> int:
	if total_width < WORKSPACE_FULL_WIDTH_BELOW:
		return WORKSPACE_EDGE_MARGIN
	var side := int(round(total_width * (1.0 - WORKSPACE_WIDTH_RATIO) * 0.5))
	if content_min > 0.0:
		side = mini(side, int(floor((total_width - content_min) * 0.5)))
	return maxi(WORKSPACE_EDGE_MARGIN, side)

## Sütunun taşıması gereken en dar genişlik: kaydırılan içeriğin kendi
## en dar genişliği (ScrollContainer bunu kendi minimumuna katmıyor) ve
## sütunun geri kalanı.
static func _workspace_content_min(margin: MarginContainer) -> float:
	var need := 0.0
	for child in margin.get_children():
		if child is Control:
			need = maxf(need, (child as Control).get_combined_minimum_size().x)
	for scroll in margin.find_children("*", "ScrollContainer", true, false):
		var bar := (scroll as ScrollContainer).get_v_scroll_bar()
		var bar_w := bar.get_combined_minimum_size().x if bar != null else 0.0
		for inner in scroll.get_children():
			if inner is Control and not (inner is ScrollBar):
				need = maxf(need, (inner as Control).get_combined_minimum_size().x + bar_w)
	return need

## `root`: BackgroundArt / BackgroundScrim / MarginContainer iskeletini
## taşıyan masa ekranının kökü. Eksik parça varsa hiçbir şeye dokunmaz.
static func fit_desk_workspace(root: Control) -> void:
	var margin := root.get_node_or_null("MarginContainer") as MarginContainer
	var scrim := root.get_node_or_null("BackgroundScrim") as ColorRect
	if margin == null or scrim == null:
		return
	scrim.color = Color(ArtPalette.INK, WORKSPACE_SIDE_SCRIM_ALPHA)
	# `StyleBoxFlat.shadow_*` düz bir `Panel`de kenarları yumuşatmıyordu -
	# gölge rengi dolgu rengiyle birebir aynı olduğu için (ikisi de aynı
	# alfa) düz kutunun keskin kenarıyla gölgenin bulanıklığı görsel olarak
	# ayırt edilemiyordu, iki dikey çizgi gibi okunuyordu (ölçüldü). Gerçek
	# bir alfa rampası için `GradientTexture2D` kullanılıyor: 0 → hedef →
	# hedef → 0, `WORKSPACE_BAND_FEATHER`lik rampalarla.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(ArtPalette.INK, 0.0), Color(ArtPalette.INK, WORKSPACE_BAND_ALPHA),
		Color(ArtPalette.INK, WORKSPACE_BAND_ALPHA), Color(ArtPalette.INK, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.1, 0.9, 1.0])
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_LINEAR
	gradient_texture.fill_from = Vector2(0.0, 0.5)
	gradient_texture.fill_to = Vector2(1.0, 0.5)
	gradient_texture.width = 512
	gradient_texture.height = 8

	var band := TextureRect.new()
	band.name = "WorkspaceBand"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.texture = gradient_texture
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(band)
	root.move_child(band, margin.get_index())
	# Bant dar ekranda da kalıyor: tam genişlikte soluk çadır bezi yine
	# metnin arkasına geliyordu (karakter/parti, 1080 genişlikte ölçüldü).
	var apply := func() -> void:
		var side := workspace_side_margin(root.size.x, _workspace_content_min(margin))
		margin.add_theme_constant_override("margin_left", side)
		margin.add_theme_constant_override("margin_right", side)
		var band_width := maxf(1.0, root.size.x - 2.0 * (side - WORKSPACE_EDGE_MARGIN))
		band.position = Vector2(side - WORKSPACE_EDGE_MARGIN, 0.0)
		band.size = Vector2(band_width, root.size.y)
		# Rampa genişliği (56px) bant genişliğine göre bir oran - bant
		# yeniden boyutlanınca gradyanın kendi 0..1 uzayındaki karşılığı
		# da yeniden hesaplanıyor, yoksa geniş bir bantta rampa görünmez
		# kadar dar, dar bir bantta neredeyse tüm bandı yerdi.
		var feather_ratio := clampf(float(WORKSPACE_BAND_FEATHER) / band_width, 0.0, 0.5)
		gradient.offsets = PackedFloat32Array([0.0, feather_ratio, 1.0 - feather_ratio, 1.0])
	root.resized.connect(apply)
	# Satırlar _ready'den sonra da kuruluyor; içerik büyüyünce sütun genişler.
	for scroll in margin.find_children("*", "ScrollContainer", true, false):
		for inner in scroll.get_children():
			if inner is Control and not (inner is ScrollBar):
				(inner as Control).minimum_size_changed.connect(apply)
	apply.call()

## Yol HUD'unun şeritleriyle dünya arasındaki ince çizgi. Eski perçinli
## deri kayışın (R1) yerinde - minimal ailenin çizgisi, panellerle aynı ton.
static func hud_rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(ArtPalette.GOLD_DIM, 0.8)
	rule.custom_minimum_size = Vector2(0.0, HUD_RULE_HEIGHT)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

static func _slip() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture("g8_slip.png")
	_set_margins(box, SLIP_SLICE, SLIP_CONTENT)
	return box

# --- Düğmeler ---

## Kilitli düğme aynı kutu, yalnızca silik - sebep yanında canlı metin
## olarak kalıyor (Event Engine Rules: *sebebiyle* kilitli, asla gizli
## değil). Karalama yok: oyuncu testinde güzel görünmedi.
##
## Oyunun varsayılan düğmesi: çerçeve + hafif dolgu, `_ghost_button()`
## (emir paneli) ile aynı ilke - opak bir doku değil, iki çizgi ve bir ton
## farkı. `_ghost_button()`'ın kendisi camsı bir HUD şeridinin üstü için
## ayarlı (mürekkep tabanlı, çok düşük alfa); bu düğme çoğu ekranın opak
## deri panel zemininin (`UI_PANEL_FILL`, kendisi neredeyse mürekkep tonu)
## üstünde duruyor, o yüzden dolgu mürekkep yerine altın tonundan ısıtılmış
## - aksi halde iki neredeyse-siyah katman üst üste binip düğme panelinin
## içinde kaybolurdu (ölçüldü). Köşe yarıçapı ve çerçeve kalınlığı emir
## panelininkiyle birebir aynı, tek aile iki bağlamda okunsun diye.
static func _minimal_button(fill_alpha: float, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var gold_dim := ArtPalette.GOLD_DIM
	box.bg_color = Color(gold_dim.r, gold_dim.g, gold_dim.b, fill_alpha)
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(FRAME_RADIUS)
	# Simetrik dolgu: "1x"/"–" gibi tek haneli metinler de merkezde duruyor.
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func _focus() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = ArtPalette.UI_FOCUS
	box.set_border_width_all(2)
	box.set_corner_radius_all(FRAME_RADIUS)
	box.set_expand_margin_all(2)
	return box

static func _build_buttons(theme: Theme) -> void:
	for type_name in ["Button", "OptionButton", "MenuButton"]:
		theme.set_stylebox("normal", type_name, _minimal_button(0.16, ArtPalette.UI_RULE))
		theme.set_stylebox("hover", type_name, _minimal_button(0.28, ArtPalette.GOLD_DIM))
		theme.set_stylebox("pressed", type_name, _minimal_button(0.42, ArtPalette.UI_ACCENT))
		theme.set_stylebox("hover_pressed", type_name, _minimal_button(0.42, ArtPalette.UI_ACCENT))
		theme.set_stylebox("disabled", type_name, _minimal_button(0.08, Color(ArtPalette.UI_RULE, 0.3)))
		theme.set_stylebox("focus", type_name, _focus())
		theme.set_color("font_color", type_name, ArtPalette.UI_TEXT)
		theme.set_color("font_hover_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_pressed_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_hover_pressed_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_focus_color", type_name, ArtPalette.UI_TEXT)
		theme.set_color("font_disabled_color", type_name, ArtPalette.UI_TEXT_DIM)
		theme.set_color("font_outline_color", type_name, ArtPalette.UI_TEXT_HALO)
		theme.set_constant("outline_size", type_name, TEXT_OUTLINE_SIZE)
	_build_fields(theme)
	_build_map_labels(theme)
	_build_hud_ghost_button(theme)

## Cam bir panelin üstünde okunması gereken düğme ailesi: mürekkep tabanlı,
## çok düşük alfalı dolgu. `Button.new()` sonrası
## `theme_type_variation = HUD_GHOST_BUTTON` ile açılır.
static func _ghost_button(fill_alpha: float, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.INK.r, ArtPalette.INK.g, ArtPalette.INK.b, fill_alpha)
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(FRAME_RADIUS)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

static func _build_hud_ghost_button(theme: Theme) -> void:
	theme.set_type_variation(HUD_GHOST_BUTTON, "Button")
	theme.set_stylebox("normal", HUD_GHOST_BUTTON, _ghost_button(0.16, ArtPalette.UI_RULE))
	theme.set_stylebox("hover", HUD_GHOST_BUTTON, _ghost_button(0.28, ArtPalette.GOLD_DIM))
	theme.set_stylebox("pressed", HUD_GHOST_BUTTON, _ghost_button(0.42, ArtPalette.UI_ACCENT))
	theme.set_stylebox("hover_pressed", HUD_GHOST_BUTTON, _ghost_button(0.42, ArtPalette.UI_ACCENT))
	theme.set_stylebox("disabled", HUD_GHOST_BUTTON, _ghost_button(0.08, Color(ArtPalette.UI_RULE, 0.3)))
	theme.set_stylebox("focus", HUD_GHOST_BUTTON, _focus())
	theme.set_color("font_color", HUD_GHOST_BUTTON, ArtPalette.UI_TEXT)
	theme.set_color("font_hover_color", HUD_GHOST_BUTTON, ArtPalette.UI_ACCENT)
	theme.set_color("font_pressed_color", HUD_GHOST_BUTTON, ArtPalette.UI_ACCENT)
	theme.set_color("font_hover_pressed_color", HUD_GHOST_BUTTON, ArtPalette.UI_ACCENT)
	theme.set_color("font_disabled_color", HUD_GHOST_BUTTON, ArtPalette.UI_TEXT_DIM)
	theme.set_color("font_outline_color", HUD_GHOST_BUTTON, ArtPalette.UI_TEXT_HALO)
	theme.set_constant("outline_size", HUD_GHOST_BUTTON, TEXT_OUTLINE_SIZE)

static func _build_fields(theme: Theme) -> void:
	theme.set_stylebox("normal", "LineEdit", field_frame())
	theme.set_stylebox("focus", "LineEdit", _focus())
	theme.set_stylebox("read_only", "LineEdit", field_frame(true))
	theme.set_color("font_color", "LineEdit", ArtPalette.UI_TEXT)
	theme.set_color("font_uneditable_color", "LineEdit", ArtPalette.UI_TEXT_DIM)
	theme.set_color("font_outline_color", "LineEdit", ArtPalette.UI_TEXT_HALO)
	theme.set_constant("outline_size", "LineEdit", TEXT_OUTLINE_SIZE)
	theme.set_color("caret_color", "LineEdit", ArtPalette.UI_ACCENT)
	theme.set_color("selection_color", "LineEdit", Color(ArtPalette.GOLD_DIM, 0.5))

	theme.set_type_variation(CELL_PANEL, "PanelContainer")
	var cell := field_frame()
	cell.bg_color = Color(ArtPalette.INK, 0.35)
	_set_content(cell, CELL_CONTENT)
	theme.set_stylebox("panel", CELL_PANEL, cell)

static func _build_map_labels(theme: Theme) -> void:
	theme.set_type_variation(MAP_LABEL, "Button")
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		theme.set_stylebox(state, MAP_LABEL, empty)
	theme.set_color("font_color", MAP_LABEL, ArtPalette.UI_TEXT_ON_PAGE)
	theme.set_color("font_hover_color", MAP_LABEL, ArtPalette.BLOOD)
	theme.set_color("font_pressed_color", MAP_LABEL, ArtPalette.BLOOD)
	theme.set_color("font_hover_pressed_color", MAP_LABEL, ArtPalette.BLOOD)
	theme.set_color("font_focus_color", MAP_LABEL, ArtPalette.UI_TEXT_ON_PAGE)
	theme.set_color("font_disabled_color", MAP_LABEL, ArtPalette.UI_MAP_INK_FADED)
	theme.set_color("font_outline_color", MAP_LABEL, ArtPalette.UI_MAP_HALO)
	theme.set_constant("outline_size", MAP_LABEL, MAP_LABEL_HALO_SIZE)

static func _set_content(box: StyleBox, content: Array) -> void:
	box.content_margin_left = content[0]
	box.content_margin_top = content[1]
	box.content_margin_right = content[2]
	box.content_margin_bottom = content[3]

# --- Sekmeler ---

## Sekmeler de düğme ailesinden: seçili sekme vurgu çizgisini ve en koyu
## dolguyu taşıyor, seçili olmayan neredeyse boş bir kutu.
static func _build_tabs(theme: Theme) -> void:
	theme.set_stylebox("tab_selected", "TabContainer", _minimal_button(0.34, ArtPalette.UI_ACCENT))
	theme.set_stylebox("tab_hovered", "TabContainer", _minimal_button(0.24, ArtPalette.GOLD_DIM))
	theme.set_stylebox("tab_unselected", "TabContainer", _minimal_button(0.10, ArtPalette.UI_RULE))
	theme.set_stylebox("tab_disabled", "TabContainer", _minimal_button(0.05, Color(ArtPalette.UI_RULE, 0.3)))
	theme.set_stylebox("tab_focus", "TabContainer", _focus())
	theme.set_stylebox("panel", "TabContainer", frame_panel())
	theme.set_constant("side_margin", "TabContainer", 0)
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

	# Kaydırma çubuğu da minimal aileden: kurdele dokusu yerine yuvarlak
	# köşeli ince bir tutamak, mürekkep bir oluğun içinde.
	var grabber := _scroll_box(Color(ArtPalette.GOLD_DIM, 0.75))
	var grabber_hot := _scroll_box(ArtPalette.UI_ACCENT)
	var groove := _scroll_box(Color(ArtPalette.INK, 0.55))
	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("grabber", bar, grabber)
		theme.set_stylebox("grabber_highlight", bar, grabber_hot)
		theme.set_stylebox("grabber_pressed", bar, grabber_hot)
		theme.set_stylebox("scroll", bar, groove)
		theme.set_stylebox("scroll_focus", bar, groove)

static func _scroll_box(colour: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(FRAME_RADIUS)
	box.set_content_margin_all(4.0)
	return box

# --- İpucu ---

static func _build_tooltip(theme: Theme) -> void:
	theme.set_stylebox("panel", "TooltipPanel", _slip())
	theme.set_color("font_color", "TooltipLabel", ArtPalette.UI_TEXT_ON_PAGE)
	theme.set_font_size("font_size", "TooltipLabel", TOOLTIP_FONT_SIZE)
	theme.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0))

# --- Yazılar ---

static func _build_labels(theme: Theme) -> void:
	theme.set_color("font_color", "Label", ArtPalette.UI_TEXT)
	# Koyu zemindeki (deri, mürekkep sahneleri) kemik rengi yazının gölgesi:
	# sahne resimlerinin açık lekeleri üstünden geçerken bile okunsun.
	theme.set_color("font_shadow_color", "Label", ArtPalette.UI_TEXT_HALO)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_constant("shadow_outline_size", "Label", 3)
	# Kâğıda (fiş, sayfa) dizilen yazı kemik değil mürekkep rengi, gölgesiz.
	for variation in [PAGE_LABEL, PAGE_HEADING]:
		theme.set_type_variation(variation, "Label")
		theme.set_color("font_shadow_color", variation, Color(0, 0, 0, 0))
	theme.set_color("font_color", PAGE_LABEL, ArtPalette.UI_TEXT_ON_PAGE)
	theme.set_color("font_color", PAGE_HEADING, ArtPalette.BLOOD)

	theme.set_type_variation(PAGE_TITLE, "Label")
	theme.set_font_size("font_size", PAGE_TITLE, PAGE_TITLE_FONT_SIZE)

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

# --- Açılış/kapanış (sahnesiz panellerin ortak devinimi) ---
## Onboarding, Vagon, Sofra, Savaş Öncesi, Tüccar, Waybook, Kervan Dökümü/
## Yükü gibi sahnesiz `.new()` panelleri tek karede belirip kayboluyordu -
## `create_tween` çağıran yalnızca sekiz dosya vardı (bkz. Motion Rules'un
## "motion has one clock per system" kuralı, burada "presenter" hiç yoktu).
## Bu iki statik fonksiyon `fit_desk_workspace`'in kurduğu aynı disiplinle
## çalışıyor: gevşek tipli düğümler alıyor, eksik/uygunsuz girdide sessizce
## no-op ya da doğrudan tamamlanıyor.
const PRESENT_BACKDROP_SECONDS: float = 0.18
const PRESENT_CARD_SECONDS: float = 0.2
const DISMISS_SECONDS: float = 0.12
## Kartın açılış ölçeği - `reduce_motion` açıkken hiç uygulanmıyor, yalnızca
## alfa kalıyor (Motion Rules: azaltılmış hareket süsü kapatır, bilgiyi
## taşıyanı kapatmaz - burada "az önce açıldı" bilgisini alfa taşıyor).
const PRESENT_CARD_START_SCALE: float = 0.97

## Bir paneli açılış anında canlandırır. `backdrop` sahibi olmayan gömülü
## panellerde (bkz. Debt/SaveSlots/CaravanStatus/Haggling/Purification/
## Recruit - kendi perdeleri yok, ev sahibi ekranınki) `null` geçilir ve
## yalnızca kart canlanır. `context` yalnızca `reduce_motion`'ı okumak için:
## `WaybookTheme` durumsuz bir `RefCounted`, ağaçta değil.
static func present(root: Control, backdrop: CanvasItem, context: Node) -> void:
	if root == null or not root.is_inside_tree():
		return
	var reduce := _reduce_motion(context)
	root.modulate.a = 0.0
	if not reduce:
		root.pivot_offset = root.size * 0.5
		root.scale = Vector2(PRESENT_CARD_START_SCALE, PRESENT_CARD_START_SCALE)
	if backdrop != null:
		backdrop.modulate.a = 0.0
	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "modulate:a", 1.0, PRESENT_CARD_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not reduce:
		tween.tween_property(root, "scale", Vector2.ONE, PRESENT_CARD_SECONDS) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if backdrop != null:
		tween.tween_property(backdrop, "modulate:a", 1.0, PRESENT_BACKDROP_SECONDS) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Kapanışı canlandırıp `on_complete`'i (genelde `dismissed.emit(); queue_free()`)
## devinim bitince çağırır. Kök ağaçta değilse (zaten serbest bırakılmış,
## ya da hiç sahnelenmemiş) devinim atlanıp `on_complete` hemen çağrılır -
## bir tween'in var olmayan bir düğümde çalışmaya çalışması yerine.
static func dismiss(root: Control, backdrop: CanvasItem, context: Node, on_complete: Callable) -> void:
	if root == null or not root.is_inside_tree():
		on_complete.call()
		return
	var reduce := _reduce_motion(context)
	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "modulate:a", 0.0, DISMISS_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if not reduce:
		tween.tween_property(root, "scale", Vector2(PRESENT_CARD_START_SCALE, PRESENT_CARD_START_SCALE), DISMISS_SECONDS) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if backdrop != null:
		tween.tween_property(backdrop, "modulate:a", 0.0, DISMISS_SECONDS) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(on_complete)

## `combat_panel.gd`/`button_feedback.gd`'nin zaten kurduğu korumalı okuma -
## `WaybookTheme`'in kendisi bir düğüm değil, `context`'in ağaçta olup
## olmadığını önce sormak gerekiyor.
static func _reduce_motion(context: Node) -> bool:
	if context == null or not context.is_inside_tree():
		return false
	var settings := context.get_node_or_null("/root/UserSettings")
	return settings != null and bool(settings.get("reduce_motion"))
