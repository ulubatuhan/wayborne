class_name CityFront
extends Control

## Şehir merkezi: önden bakılan, boyalı
## bir kasaba resmi (her şehrin kendi resmi), solda mekân levhaları, sağda
## kadro kartları, sol üstte arma ve sancak, altta tahta şerit.
##
## Resim ve mekân maskesi tools/ui_scenes/ (town_scene.py → town_post.py)
## ile CC0 modellerden render ediliyor. Maske piksel başına mekân numarası
## taşıyor: binanın üstüne gelmek levhayı, levhanın üstüne gelmek binayı
## aydınlatıyor - ikisi aynı `hovered` durumunu okuyor.
##
## `venue_pressed(scene_path)` şehir haritasının mekân sinyali: `city_map.gd` bağlıyor.

signal venue_pressed(scene_path: String)
signal nav_pressed(key: String)

const TOWNS_DIR: String = "res://data/assets/ui/towns/"
const KIT_DIR: String = "res://data/assets/ui/grim/kit/"
const SHADER_PATH: String = "res://scripts/ui/grim/venue_highlight.gdshader"

## Maske numarası sırası town_post.py'nin VENUE_IDS sırasıyla aynı (1'den).
## `gate` levha değil, alt şeritteki "Yola Çık" düğmesi.
const VENUES: Array = [
	{"id": 1, "key": "UI_GRIM_VENUE_YARD", "icon": "yard", "scene": Nav.CARAVAN_YARD, "facility": SettlementRules.CARAVAN_YARD},
	{"id": 2, "key": "UI_GRIM_VENUE_MARKET", "icon": "market", "scene": Nav.ECONOMY, "facility": SettlementRules.MARKET},
	{"id": 3, "key": "UI_GRIM_VENUE_GUILD", "icon": "guild", "scene": Nav.GUILD, "facility": SettlementRules.GUILD},
	{"id": 4, "key": "UI_GRIM_VENUE_TAVERN", "icon": "tavern", "scene": Nav.TAVERN, "facility": SettlementRules.TAVERN},
	{"id": 5, "key": "UI_GRIM_VENUE_CHURCH", "icon": "church", "scene": Nav.CHURCH, "facility": SettlementRules.CHURCH},
	{"id": 6, "key": "UI_GRIM_VENUE_WARDROBE", "icon": "tailor", "scene": Nav.WARDROBE, "facility": SettlementRules.WARDROBE},
]
const GATE_ID: int = 7
const NAV: Array = [
	["UI_GRIM_NAV_PARTY", "party"],
	["UI_GRIM_NAV_LEDGER", "ledger"],
	["UI_GRIM_NAV_MAP", "map"],
	["UI_GRIM_NAV_CARAVAN", "caravan"],
]
const PLATE_SIZE: Vector2 = Vector2(330, 70)
const STRIP_HEIGHT: float = 104.0
const CARD_SIZE: Vector2 = Vector2(300, 112)

var hovered: int = 0
var _bg: TextureRect
var _mask_img: Image
var _plates: Dictionary = {}
var _model: Dictionary = {}

func setup(city_id: String, model: Dictionary) -> CityFront:
	_model = model
	# Anchor-preset tuzağı (bkz. CLAUDE.md Art Rules): ebeveyn zaten
	# boyutlanmışsa çapa tek başına boyut vermiyor; ofsetler de sıfırlanmalı
	# ve boyut bir kez açıkça alınmalı.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var parent := get_parent_control()
	if parent != null:
		size = parent.size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var back := ColorRect.new()
	back.color = ArtPalette.GRIM_CHARCOAL
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.texture = TextureLoader.load_any(background_path(city_id, float(model.get("hour", 22.0))))
	var mask_tex := TextureLoader.load_any(TOWNS_DIR + city_id + "/mask.png")
	if mask_tex != null:
		_mask_img = mask_tex.get_image()
		var mat := ShaderMaterial.new()
		mat.shader = load(SHADER_PATH)
		mat.set_shader_parameter("mask", mask_tex)
		mat.set_shader_parameter("mood", int(model.get("mood", MOOD_NORMAL)))
		_bg.material = mat
	add_child(_bg)
	# Meydanın halkı (Y-G10T): gece az, akşam ve gündüz biraz daha.
	var hour := float(model.get("hour", 22.0))
	var phase := JourneyClock.phase_for_hour(hour)
	var night := phase == JourneyClock.Phase.NIGHT
	var lantern := night or phase == JourneyClock.Phase.EVENING
	add_child(TownsfolkLayer.new().setup(_bg, night, "%s|%d" % [city_id, int(model.get("day", 1))], lantern))
	var smoke := SmokeWisps.new()
	add_child(smoke)
	var ash := AshFall.new()
	ash.density = 0.5
	add_child(ash)
	add_child(WaybookTheme.overlay("vignette.png", 0.7))
	add_child(_crest_and_banner())
	add_child(_venue_column())
	add_child(_roster())
	add_child(_strip())
	return self

## Şehrin hâli (görev 9.3): kriz (veba ya da yolunda savaş) kapalı havadan
## önce gelir. Resmin üstünde gölgelendirici renklendirir (venue_highlight).
const MOOD_NORMAL: int = 0
const MOOD_GREY: int = 1
const MOOD_CRISIS: int = 2
const GREY_WEATHERS: Array[String] = [RouteWeather.OVERCAST, RouteWeather.RAIN, RouteWeather.FOG, RouteWeather.STORM]

## Şehrin bugünkü havası: yolun havası gibi tohumdan, saklanmıyor - aynı
## gün aynı şehir aynı göğü gösterir, yeniden yüklemek havayı değiştirmez.
static func mood_for(in_crisis: bool, location_id: String, day: int) -> int:
	if in_crisis:
		return MOOD_CRISIS
	var weather := RouteWeather.at("city|" + location_id, day, "meadow")
	return MOOD_GREY if GREY_WEATHERS.has(weather) else MOOD_NORMAL

## Gün evresinin resmi (görevler 9.3, N33): şafak sabah, öğle ve ikindi gündüz,
## akşam akşam, gece taban resim. Evre resmi yoksa taban resim (gece) kalır.
## Resimler aynı kamerayla render edilir, maske hepsinde aynı.
const PHASE_FILES: Dictionary = {
	JourneyClock.Phase.DAWN: "morning", JourneyClock.Phase.MORNING: "day", JourneyClock.Phase.NOON: "day",
	JourneyClock.Phase.AFTERNOON: "day", JourneyClock.Phase.EVENING: "evening",
}

static func background_path(city_id: String, hour: float) -> String:
	var phase := JourneyClock.phase_for_hour(hour)
	if PHASE_FILES.has(phase):
		var path := TOWNS_DIR + city_id + "/background_%s.jpg" % String(PHASE_FILES[phase])
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			return path
	return TOWNS_DIR + city_id + "/background.jpg"

func set_time(t: float) -> void:
	for c in get_children():
		if c.has_method("set_time"):
			c.call("set_time", t)

func set_hovered(id: int) -> void:
	if id == hovered:
		return
	hovered = id
	if _bg.material != null:
		(_bg.material as ShaderMaterial).set_shader_parameter("hovered", id)
	for key in _plates:
		var plate: PanelContainer = _plates[key]
		var lit := int(key) == id
		plate.add_theme_stylebox_override("panel", _plate_box(lit))
		(plate.get_meta("name") as Label).add_theme_color_override("font_color",
			ArtPalette.GRIM_AMBER if lit else ArtPalette.GRIM_PARCHMENT)

## Ekrandaki bir noktanın altındaki mekân (0 = hiçbiri). Resim "kapla"
## kipinde çiziliyor: ölçek ekranın iki kenarından büyük olanı, fazlası
## eşit kırpılıyor - maske de aynı dönüşümle okunur.
func venue_at(screen_point: Vector2) -> int:
	if _mask_img == null:
		return 0
	var img_size := Vector2(_mask_img.get_size())
	var p := cover_to_image(screen_point, size, img_size)
	if p.x < 0 or p.y < 0 or p.x >= img_size.x or p.y >= img_size.y:
		return 0
	return int(round(_mask_img.get_pixelv(Vector2i(p)).r * 255.0))

static func cover_to_image(point: Vector2, view: Vector2, img: Vector2) -> Vector2:
	var k := maxf(view.x / img.x, view.y / img.y)
	var offset := (view - img * k) * 0.5
	return (point - offset) / k

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		set_hovered(venue_at(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := venue_at(event.position)
		for v in VENUES:
			if int(v["id"]) == id and has_venue(v):
				venue_pressed.emit(String(v["scene"]))
		if id == GATE_ID:
			nav_pressed.emit("UI_GRIM_EMBARK")

## Yerleşimde bu mekân var mı (bkz. SettlementRules): kasabada lonca ve
## kervan avlusu, kervansarayda lonca yok. Modelde liste yoksa hepsi var.
func has_venue(v: Dictionary) -> bool:
	var allowed: Array = _model.get("facilities", [])
	return allowed.is_empty() or allowed.has(String(v.get("facility", "")))

# ------------------------------------------------------------------ parçalar

static func kit(name: String) -> Texture2D:
	return TextureLoader.load_any(KIT_DIR + name)

static func _picture(tex: Texture2D, box: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = box
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func _sliced(tex: Texture2D, margin: int, content: Vector4) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = tex
	box.texture_margin_left = margin
	box.texture_margin_right = margin
	box.texture_margin_top = margin
	box.texture_margin_bottom = margin
	box.content_margin_left = content.x
	box.content_margin_top = content.y
	box.content_margin_right = content.z
	box.content_margin_bottom = content.w
	return box

func _plate_box(lit: bool) -> StyleBox:
	return WaybookTheme.plate_box(lit, Vector4(10, 6, 14, 6))

## Sol üst: kervanın arması ve şehrin adını taşıyan yırtık sancak.
func _crest_and_banner() -> Control:
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.position = Vector2(26, 18)
	var banner := _picture(kit("banner.png"), Vector2(560, 108))
	banner.position = Vector2(70, 14)
	host.add_child(banner)
	var crest := _picture(kit("crest.png"), Vector2(132, 132))
	host.add_child(crest)
	var col := VBoxContainer.new()
	col.position = Vector2(150, 22)
	col.add_theme_constant_override("separation", -6)
	host.add_child(col)
	col.add_child(WaybookTheme.display_label(String(_model.get("city_name", "")), 50, ArtPalette.BONE))
	var when: String = GrimDrafts.tr_key("UI_GRIM_DAY_SEASON") % [int(_model.get("day", 1)),
		GrimDrafts.tr_key(String(_model.get("season_key", "UI_GRIM_SEASON_AUTUMN")))]
	if _model.has("weather_key"):
		when += "  ·  " + GrimDrafts.tr_key(String(_model["weather_key"]))
	col.add_child(WaybookTheme.label(when, WaybookTheme.BODY_SIZE, ArtPalette.GRIM_PARCHMENT))
	return host

## Sol sütun: her mekân bir levha - ikon, ad, bugünkü tek satır durumu.
func _venue_column() -> Control:
	var col := VBoxContainer.new()
	col.position = Vector2(26, 176)
	col.add_theme_constant_override("separation", 10)
	var lines: Dictionary = _model.get("venue_lines", {})
	for v in VENUES:
		if not has_venue(v):
			continue
		var plate := PanelContainer.new()
		plate.custom_minimum_size = PLATE_SIZE
		plate.add_theme_stylebox_override("panel", _plate_box(false))
		plate.mouse_filter = Control.MOUSE_FILTER_STOP
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(row)
		row.add_child(_picture(kit("icon_%s.png" % v["icon"]), Vector2(58, 58)))
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", -2)
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(text)
		var name := WaybookTheme.label(GrimDrafts.tr_key(String(v["key"])), WaybookTheme.HEADING_SIZE, ArtPalette.GRIM_PARCHMENT, true)
		text.add_child(name)
		var first: Array = lines.get(String(v["key"]), [])
		if not first.is_empty():
			var line: Dictionary = first[0]
			var bad := String(line.get("kind", "")) == "bad"
			# Satır ya çevrilmiş metin (brifingin ihtiyacı) ya da anahtar + argüman taşır.
			var text_line: String = String(line["text"]) if line.has("text") else GrimDrafts.tr_key(String(line["key"])) % line.get("args", [])
			var l := WaybookTheme.label(text_line, WaybookTheme.SMALL_SIZE,
				ArtPalette.GRIM_CRIMSON.lightened(0.35) if bad else ArtPalette.GRIM_PARCHMENT_DIM)
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			l.custom_minimum_size = Vector2(230, 0)
			text.add_child(l)
		plate.set_meta("name", name)
		var id := int(v["id"])
		plate.mouse_entered.connect(func(): set_hovered(id))
		plate.mouse_exited.connect(func(): set_hovered(0))
		var scene := String(v["scene"])
		plate.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				venue_pressed.emit(scene))
		_plates[id] = plate
		col.add_child(plate)
	return col

## Sağ sütun: kadro kartları. Sınıf amblemi, ad, can ve stres.
func _roster() -> Control:
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	col.position = Vector2(-CARD_SIZE.x - 26, 30)
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p in _model.get("party", []):
		col.add_child(_card(p))
	return col

func _card(p: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.add_theme_stylebox_override("panel", _sliced(kit("card.png"), 6, Vector4(10, 8, 12, 8)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var emblem := WaybookIcons.picture(WaybookIcons.CLASS_EMBLEMS, String(p.get("class", "")), 72)
	emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(emblem)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(WaybookTheme.label(String(p["name"]), WaybookTheme.HEADING_SIZE, ArtPalette.BONE, true))
	if p.has("class_key"):
		text.add_child(WaybookTheme.label(GrimDrafts.tr_key(String(p["class_key"])) + "  ·  " +
			GrimDrafts.tr_key("UI_GRIM_LEVEL") % int(p.get("level", 1)), WaybookTheme.SMALL_SIZE, ArtPalette.GRIM_PARCHMENT_DIM))
	var hp := float(p["hp"]) / maxf(1.0, float(p["max_hp"]))
	text.add_child(_bar(hp, ArtPalette.GRIM_CRIMSON.lightened(0.1), "%d/%d" % [int(p["hp"]), int(p["max_hp"])]))
	text.add_child(_stress_pips(int(p["stress"])))
	return card

static func _bar(share: float, colour: Color, caption: String) -> Control:
	var back := ColorRect.new()
	back.color = Color(0.05, 0.04, 0.04, 0.9)
	back.custom_minimum_size = Vector2(180, 12)
	var fill := ColorRect.new()
	fill.color = colour
	fill.size = Vector2(180.0 * clampf(share, 0.0, 1.0), 12)
	back.add_child(fill)
	var l := WaybookTheme.label(caption, 11, ArtPalette.BONE)
	l.position = Vector2(4, -3)
	back.add_child(l)
	return back

## Stres, on boncuk: dolu boncuk arduvaz, eşik üstü kan.
static func _stress_pips(stress: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var filled := int(round(stress / 10.0))
	for i in 10:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 8)
		if i < filled:
			pip.color = ArtPalette.GRIM_CRIMSON.lightened(0.15) if i >= 6 else ArtPalette.GRIM_SLATE_LIGHT
		else:
			pip.color = Color(0.12, 0.11, 0.11, 0.9)
		row.add_child(pip)
	return row

## Alt şerit: kaynaklar (sol), gezinme ikonları (orta), Yola Çık (sağ).
func _strip() -> Control:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_top = -STRIP_HEIGHT
	bar.custom_minimum_size = Vector2(0, STRIP_HEIGHT)
	bar.add_theme_stylebox_override("panel", WaybookTheme.bar_panel())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	bar.add_child(row)
	row.add_child(_resource("UI_GRIM_GOLD", "%d" % int(_model.get("gold", 0)), ArtPalette.GRIM_AMBER))
	var debt := int(_model.get("debt", 0))
	if debt > 0:
		row.add_child(_resource("UI_GRIM_DEBT", "-%d" % debt, ArtPalette.GRIM_CRIMSON.lightened(0.3)))
	var days := int(_model.get("provisions_days", 0))
	row.add_child(_resource("UI_GRIM_PROVISIONS", GrimDrafts.tr_key("UI_GRIM_PROVISIONS_VALUE") % [int(_model.get("provisions", 0)), days],
		ArtPalette.GRIM_CRIMSON.lightened(0.3) if days <= 3 else ArtPalette.GRIM_PARCHMENT))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	for n in NAV:
		row.add_child(_icon_button(String(n[0]), String(n[1])))
	var gap2 := Control.new()
	gap2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap2)
	row.add_child(_embark())
	return bar

static func _resource(caption_key: String, value: String, colour: Color) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(WaybookTheme.label(GrimDrafts.tr_key(caption_key), WaybookTheme.SMALL_SIZE, ArtPalette.GRIM_PARCHMENT_DIM))
	v.add_child(WaybookTheme.label(value, 30, colour, true))
	return v

func _icon_button(key: String, icon_name: String) -> Button:
	var b := WaybookTheme.icon_button(GrimDrafts.tr_key(key), icon_name)
	b.tooltip_text = b.text
	b.pressed.connect(func(): nav_pressed.emit(key))
	return b

## Yola Çık: tek kızıl düğme, sağda. Kapının ikonu ve ağır yazı. Üstüne
## gelmek resimdeki kapıyı (varsa) aydınlatır.
func _embark() -> Button:
	var b := WaybookTheme.crimson_button(GrimDrafts.tr_key("UI_GRIM_EMBARK"), "gate")
	b.custom_minimum_size = Vector2(250, 70)
	b.pressed.connect(func(): nav_pressed.emit("UI_GRIM_EMBARK"))
	b.mouse_entered.connect(func(): set_hovered(GATE_ID))
	b.mouse_exited.connect(func(): set_hovered(0))
	return b
