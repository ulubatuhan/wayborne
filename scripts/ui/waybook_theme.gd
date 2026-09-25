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
## Tam genişlikte duran düğmeler (ekranın asıl eylem sıraları, geri tuşu):
## sekmenin kulağı ve dikişi 1000 pikselde çizgili bir şeride dönüyordu;
## bu sıralar ciltli çerçevenin (G2) küçültülmüş dokuz parçası.
const ROW_BUTTON: StringName = &"RowButton"
## Harita parşömeninin üstündeki şehir yazısı: kutu yok, mürekkep yazı ve
## kâğıt renginde bir hale - haritacının yazdığı gibi.
const MAP_LABEL: StringName = &"MapLabel"
## Kargo/pazar hücresi: aynı küçültülmüş cilt, içinde malın resmi.
const CELL_PANEL: StringName = &"CellPanel"
## Sürüklenebilir "Kervan Emirleri" paneli yarı saydam bir cam gibi okunuyor
## (bkz. road_journey.gd::_build_orders_panel) - üstündeki düğmeler G4'ün
## opak deri dokusunu taşırsa cam zeminin üstünde iki ayrı dil okunur.
## Dolgu yerine ince bir çerçeve çiziyor; hover/basılıyken dolgu belirir.
const HUD_GHOST_BUTTON: StringName = &"HudGhostButton"

## "1x", "–", "+" gibi 1-2 karakterlik yol HUD düğmeleri için - aynı G4
## dokusu, yalnızca simetrik dolgu (bkz. ICON_TAB_CONTENT).
const ICON_TAB: StringName = &"IconTab"

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
## "1x"/"–"/"+" gibi 1-2 karakterlik simge düğmeleri kulağın asimetrisini
## taşıyamıyor - metin kutunun merkezinden 7px sağa kayıyordu (34/20 payı
## dengesiz). Aynı toplam dolguyu ([54, 32]) simetrik dağıtıyor.
const ICON_TAB_CONTENT: Array[int] = [27, 16, 27, 16]
const SLIP_SLICE: Array[int] = [34, 72, 38, 40]
const SLIP_CONTENT: Array[int] = [36, 66, 42, 36]
## Kayışın yuvarlak uçları döşenirken her parçada tekrar etmesin diye
## kırpılan genişlik (doku pikseli).
const STRAP_END_CROP: int = 30
## Sıra düğmesinin ve hücrenin cildi G2'nin bu ölçeği: 60 piksellik köşe
## 21'e iniyor, 50 piksellik bir düğmeye sığıyor.
const ROW_SCALE: float = 0.35
const ROW_SLICE: int = 21
const ROW_CONTENT: Array[int] = [22, 12, 22, 12]
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

## Yol HUD'unun şeritleriyle dünya arasındaki perçinli kayış (r1): bir
## kuşak, çerçeve değil. Yazı kayışın üstünde değil - perçinler harflerin
## arasına giriyor, okunmuyordu (ölçüldü) - kayış yalnızca iki şeridin
## dünyaya bakan kenarında. Yuvarlak uçları kırpılmış orta parça döşeniyor.
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

static func strap_rule(height: float) -> TextureRect:
	var source := texture("r1_strap_top.png").get_image()
	source.decompress()
	var middle := source.get_region(Rect2i(STRAP_END_CROP, 0, source.get_width() - STRAP_END_CROP * 2, source.get_height()))
	var scale := height / float(middle.get_height())
	middle.resize(maxi(1, int(round(middle.get_width() * scale))), int(round(height)), Image.INTERPOLATE_LANCZOS)
	var rule := TextureRect.new()
	rule.texture = ImageTexture.create_from_image(middle)
	rule.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rule.stretch_mode = TextureRect.STRETCH_TILE
	rule.custom_minimum_size = Vector2(0.0, height)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

static func _slip() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture("g8_slip.png")
	_set_margins(box, SLIP_SLICE, SLIP_CONTENT)
	return box

# --- Düğmeler ---

## Kilitli düğme aynı sekme, yalnızca silik (`UI_TINT_DISABLED`'ın
## yarı saydamlığı) - sebep yanında canlı metin olarak kalıyor (Event
## Engine Rules: *sebebiyle* kilitli, asla gizli değil). Bir süre üstüne
## defterin karalama işareti de biniyordu; oyuncu testinde güzel
## görünmediği için kaldırıldı - silik olmak yetiyor.
static func _tab(tint: Color, content: Array[int] = TAB_CONTENT) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture("g4_tab.png")
	box.modulate_color = tint
	_set_margins(box, TAB_SLICE, content)
	# Orta dilim döşeniyor, gerilmiyor: gerilen deri damarı geniş bir
	# düğmede yatay çizgilere dönüşüyordu.
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box

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
		theme.set_stylebox("disabled", type_name, _tab(ArtPalette.UI_TINT_DISABLED))
		theme.set_stylebox("focus", type_name, _focus())
		theme.set_color("font_color", type_name, ArtPalette.UI_TEXT)
		theme.set_color("font_hover_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_pressed_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_hover_pressed_color", type_name, ArtPalette.UI_ACCENT)
		theme.set_color("font_focus_color", type_name, ArtPalette.UI_TEXT)
		theme.set_color("font_disabled_color", type_name, ArtPalette.UI_TEXT_DIM)
		theme.set_color("font_outline_color", type_name, ArtPalette.UI_TEXT_HALO)
		theme.set_constant("outline_size", type_name, TEXT_OUTLINE_SIZE)
	_build_row_buttons(theme)
	_build_map_labels(theme)
	_build_hud_ghost_button(theme)
	_build_icon_tab(theme)

## "1x"/"–"/"+" gibi yol HUD'unun kısa metinli düğmeleri: aynı G4 dokusu,
## yalnızca `ICON_TAB_CONTENT`in simetrik dolgusuyla - kulağın asimetrisi
## (bkz. TAB_CONTENT'in kendi yorumu) bir haneli bir metni merkezden 7px
## kaydırıyordu.
static func _build_icon_tab(theme: Theme) -> void:
	theme.set_type_variation(ICON_TAB, "Button")
	theme.set_stylebox("normal", ICON_TAB, _tab(Color.WHITE, ICON_TAB_CONTENT))
	theme.set_stylebox("hover", ICON_TAB, _tab(ArtPalette.UI_TINT_HOVER, ICON_TAB_CONTENT))
	theme.set_stylebox("pressed", ICON_TAB, _tab(ArtPalette.UI_TINT_PRESSED, ICON_TAB_CONTENT))
	theme.set_stylebox("hover_pressed", ICON_TAB, _tab(ArtPalette.UI_TINT_PRESSED, ICON_TAB_CONTENT))
	theme.set_stylebox("disabled", ICON_TAB, _tab(ArtPalette.UI_TINT_DISABLED, ICON_TAB_CONTENT))

## Çerçeve + dolgusuz zemin, `_tab()`in opak deri dokusunun aksine - bir
## cam panelin üstünde okunması gereken tek düğme ailesi. `Button.new()`
## sonrası `theme_type_variation = HUD_GHOST_BUTTON` ile açılır.
static func _ghost_button(fill_alpha: float, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.INK.r, ArtPalette.INK.g, ArtPalette.INK.b, fill_alpha)
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
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

static func row_frame(tint: Color) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = _row_texture()
	box.modulate_color = tint
	box.set_texture_margin_all(ROW_SLICE)
	_set_content(box, ROW_CONTENT)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return box

static var _row_cache: Texture2D

## Doldurulmuş cilt (G2 + palet zemini + leke maskesi) sıra ölçeğine
## küçültülmüş. Kilitlisi aynı doku, yalnızca silik tonla.
static func _row_texture() -> Texture2D:
	if _row_cache != null:
		return _row_cache
	var image := _filled_frame("g2_binding.png", BINDING_FILL_INSET).get_image()
	image.resize(
		int(round(image.get_width() * ROW_SCALE)), int(round(image.get_height() * ROW_SCALE)),
		Image.INTERPOLATE_LANCZOS
	)
	_row_cache = ImageTexture.create_from_image(image)
	return _row_cache

static func _build_row_buttons(theme: Theme) -> void:
	theme.set_type_variation(ROW_BUTTON, "Button")
	theme.set_stylebox("normal", ROW_BUTTON, row_frame(Color.WHITE))
	theme.set_stylebox("hover", ROW_BUTTON, row_frame(ArtPalette.UI_TINT_HOVER))
	theme.set_stylebox("pressed", ROW_BUTTON, row_frame(ArtPalette.UI_TINT_PRESSED))
	theme.set_stylebox("hover_pressed", ROW_BUTTON, row_frame(ArtPalette.UI_TINT_PRESSED))
	theme.set_stylebox("disabled", ROW_BUTTON, row_frame(ArtPalette.UI_TINT_DISABLED))

	# Sayı/yazı alanları (SpinBox'ın içindeki LineEdit dahil) aynı küçük cilt:
	# motorun siyah giriş kutusu defterin hiçbir parçasına benzemiyordu.
	var field := row_frame(Color.WHITE)
	_set_content(field, [12, 4, 12, 4])
	var field_locked := row_frame(ArtPalette.UI_TINT_DISABLED)
	_set_content(field_locked, [12, 4, 12, 4])
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", _focus())
	theme.set_stylebox("read_only", "LineEdit", field_locked)
	theme.set_color("font_color", "LineEdit", ArtPalette.UI_TEXT)
	theme.set_color("font_outline_color", "LineEdit", ArtPalette.UI_TEXT_HALO)
	theme.set_constant("outline_size", "LineEdit", TEXT_OUTLINE_SIZE)
	theme.set_color("caret_color", "LineEdit", ArtPalette.UI_ACCENT)

	theme.set_type_variation(CELL_PANEL, "PanelContainer")
	var cell := row_frame(Color.WHITE)
	_set_content(cell, [8, 6, 8, 6])
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

static func _build_tabs(theme: Theme) -> void:
	theme.set_stylebox("tab_selected", "TabContainer", _tab(ArtPalette.UI_TINT_HOVER))
	theme.set_stylebox("tab_hovered", "TabContainer", _tab(Color.WHITE))
	theme.set_stylebox("tab_unselected", "TabContainer", _tab(ArtPalette.UI_TINT_PRESSED))
	theme.set_stylebox("tab_disabled", "TabContainer", _tab(ArtPalette.UI_TINT_DISABLED))
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
