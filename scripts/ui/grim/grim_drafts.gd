class_name GrimDrafts
extends RefCounted

## Karanlık arayüz taslağının beş ekranı - şehir merkezi, başlık, ticaret,
## envanter, yol göstergeleri - koddan kurulmuş, sahnesiz. Her biri bir
## `model` sözlüğü okuyor; `from_session()` o sözlüğün oyunun bugün zaten
## tuttuğu kısmını GameSession'dan dolduruyor, gerisi (durum/bozulma,
## sıcaklık) bir tasarım kararı bekliyor (docs/ui/REDESIGN.md).
##
## Onay için çizilmiş taslaklar olarak başladılar; bağlananlar ekranların
## kendisi tarafından kuruluyor (başlık: main_menu.gd). Gezinmeyi hiçbiri
## yapmıyor - neye basıldığını ekran okuyor.

const BAR_HEIGHT: float = 64.0
const STRIP_HEIGHT: float = 100.0

# ------------------------------------------------------------------ ortak

static func _full(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

static func _root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	var bg := ColorRect.new()
	bg.color = ArtPalette.GRIM_CHARCOAL
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_full(bg))
	return root

static func _finish(root: Control, ash: float) -> void:
	if ash > 0.0:
		var a := AshFall.new()
		a.density = ash
		root.add_child(a)
	root.add_child(GrimTheme.overlay("vignette.png", 0.95))

static func _stat(caption_key: String, value: String, colour: Color) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	v.add_child(GrimTheme.label(tr_key(caption_key), GrimTheme.SMALL_SIZE - 2, ArtPalette.GRIM_PARCHMENT_DIM))
	v.add_child(GrimTheme.label(value, GrimTheme.HEADING_SIZE, colour, true))
	return v

static func tr_key(key: String) -> String:
	return TranslationServer.translate(key)

static func _sep() -> Control:
	var s := ColorRect.new()
	s.color = Color(ArtPalette.GRIM_RUST, 0.6)
	s.custom_minimum_size = Vector2(1, 38)
	return s

## Üst şerit: kaynaklar, zaman, hava, etkin değiştiriciler, kervanın hali.
static func top_bar(model: Dictionary) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", GrimTheme.bar_panel())
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, BAR_HEIGHT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	row.add_child(GrimTheme.label(String(model.get("city_name", "")), GrimTheme.TITLE_SIZE - 4, ArtPalette.GRIM_PARCHMENT, true))
	row.add_child(_sep())
	row.add_child(_stat("UI_GRIM_GOLD", "%d" % int(model.get("gold", 0)), ArtPalette.GRIM_AMBER))
	var debt := int(model.get("debt", 0))
	if debt > 0:
		row.add_child(_stat("UI_GRIM_DEBT", "-%d" % debt, ArtPalette.GRIM_CRIMSON.lightened(0.25)))
	var days := int(model.get("provisions_days", 0))
	row.add_child(_stat("UI_GRIM_PROVISIONS", tr_key("UI_GRIM_PROVISIONS_VALUE") % [int(model.get("provisions", 0)), days],
		ArtPalette.GRIM_CRIMSON.lightened(0.25) if days <= 3 else ArtPalette.GRIM_PARCHMENT))
	row.add_child(_sep())
	var dial := TimeDial.new()
	dial.custom_minimum_size = Vector2(42, 42)
	dial.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dial.set_hour(float(model.get("hour", 12.0)))
	row.add_child(dial)
	row.add_child(_stat("UI_GRIM_DATE", tr_key("UI_GRIM_DAY_SEASON") % [int(model.get("day", 1)),
		tr_key(String(model.get("season_key", "UI_GRIM_SEASON_AUTUMN")))], ArtPalette.GRIM_PARCHMENT))
	row.add_child(_stat("UI_GRIM_WEATHER", tr_key(String(model.get("weather_key", "UI_GRIM_WEATHER_ASH"))), ArtPalette.GRIM_SLATE_LIGHT))
	row.add_child(_sep())
	var mods := HBoxContainer.new()
	mods.add_theme_constant_override("separation", 6)
	mods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for m in model.get("modifiers", []):
		var bad := String(m.get("kind", "bad")) == "bad"
		mods.add_child(GrimTheme.banner_tag(tr_key(String(m["key"])) % m.get("args", []), not bad))
	row.add_child(mods)
	row.add_child(_party_strip(model.get("party", [])))
	return bar

## Kervanın hali: her kişi için ad, can ve stres - iki ince çizgi.
static func _party_strip(party: Array) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 10)
	for p in party:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		if p.has("class"):
			cell.add_child(WaybookIcons.picture(WaybookIcons.CLASS_EMBLEMS, String(p["class"]), 34))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		v.custom_minimum_size = Vector2(70, 0)
		cell.add_child(v)
		v.add_child(GrimTheme.label(String(p["name"]), GrimTheme.SMALL_SIZE - 1, ArtPalette.GRIM_PARCHMENT))
		v.add_child(_thin_bar(float(p["hp"]) / maxf(1.0, float(p["max_hp"])), ArtPalette.GRIM_CRIMSON.lightened(0.15)))
		v.add_child(_thin_bar(float(p["stress"]) / 100.0, ArtPalette.GRIM_SLATE_LIGHT))
		cell.tooltip_text = "%d/%d · %d" % [int(p["hp"]), int(p["max_hp"]), int(p["stress"])]
		strip.add_child(cell)
	return strip

static func _thin_bar(share: float, colour: Color) -> ColorRect:
	var back := ColorRect.new()
	back.color = Color(ArtPalette.GRIM_IRON, 0.7)
	back.custom_minimum_size = Vector2(70, 3)
	var fill := ColorRect.new()
	fill.color = colour
	fill.size = Vector2(70.0 * clampf(share, 0.0, 1.0), 3)
	back.add_child(fill)
	return back

## Alt şerit: gezinme. İkonu olan eylem madalyon düğme, olmayan taş levha;
## geri alınamayan çıkış sağda kızıl. Her düğme bir tuşun karşılığı.
const ACTION_ICONS: Dictionary = {
	"UI_GRIM_NAV_PARTY": "party", "UI_GRIM_NAV_LEDGER": "ledger", "UI_GRIM_NAV_MAP": "map",
	"UI_GRIM_NAV_CARAVAN": "caravan", "UI_GRIM_HUD_CAMP": "camp", "UI_GRIM_TRADE_BASKET": "market",
	"UI_GRIM_INV_MOVE": "caravan", "UI_GRIM_INV_CRAFT": "wardrobe",
}

static func bottom_bar(keys: Array, exit_key: String) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", GrimTheme.bar_panel())
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_top = -STRIP_HEIGHT
	bar.custom_minimum_size = Vector2(0, STRIP_HEIGHT)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	for k in keys:
		var key := String(k)
		var b: Button
		if ACTION_ICONS.has(key):
			b = GrimTheme.icon_button(tr_key(key), String(ACTION_ICONS[key]))
		else:
			b = GrimTheme.button(tr_key(key))
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	var exit := GrimTheme.crimson_button(tr_key(exit_key))
	exit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(exit)
	return bar

# ------------------------------------------------------------------ şehir

static func menu_position(screen: Vector2, building: Rect2, menu_size: Vector2) -> Vector2:
	var gap := 18.0
	var x := building.end.x + gap
	if x + menu_size.x > screen.x - 16.0:
		x = building.position.x - gap - menu_size.x
	var y := clampf(building.position.y + 20.0, BAR_HEIGHT + 12.0, screen.y - BAR_HEIGHT - 12.0 - menu_size.y)
	return Vector2(maxf(16.0, x), y)

## Haber kartlarının sağ üst köşedeki yuvası.
static func _add_notice_host(root: Control) -> void:
	var notices := Control.new()
	notices.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notices)
	root.set_meta("notices", notices)

## Bir haber kartını sağ üst köşeye bırakır; kartlar birbirinin altına
## hafif farklı eğimlerle dizilir (masaya atılmış gibi, hizalı değil).
static func push_notice(root: Control, title: String, body: String, kind: GrimNotice.Severity, age: float = 1.0) -> GrimNotice:
	var host: Control = root.get_meta("notices") if root.has_meta("notices") else root
	var index := host.get_child_count()
	var card := GrimNotice.new().setup(title, body, kind, -2.0 + 1.6 * (index % 3))
	host.add_child(card)
	var y := BAR_HEIGHT + 18.0 + index * 120.0
	card.position = Vector2(-GrimNotice.WIDTH - 30.0 + (index % 2) * 10.0, y)
	card.set_meta("rest_y", y)
	card.set_age(age)
	return card

# ------------------------------------------------------------------ başlık

const TITLE_ENTRIES: Array = ["UI_CONTINUE", "UI_GRIM_NEW_LINEAGE", "UI_MAIN_MENU_SAVES", "UI_SETTINGS", "UI_QUIT"]

static func title(hovered: int = 0, lineage: Dictionary = {}, entry_keys: Array = TITLE_ENTRIES) -> Control:
	var root := _root()
	# Arka plan: gece kampı (vagon, çadır, kamp ateşi, tepede uzak bir şehir),
	# şehirlerle aynı hattan render (tools/ui_scenes, "camp"). Işık yalnızca
	# ateşten: kısık, titrek, küçük - ekranı aydınlatmıyor.
	var bg := TextureRect.new()
	bg.texture = TextureLoader.load_any(CityFront.TOWNS_DIR + "camp/background.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_full(bg))
	var glow := LanternGlow.new().setup(150.0, 0.22, 1.3)
	glow.set_meta("image_point", FIRE_POINT)
	root.add_child(glow)
	var travellers := _camp_travellers()
	for figure in travellers:
		root.add_child(figure.get_meta("crate"))
		root.add_child(figure)
	root.resized.connect(func():
		_place_on_image(glow, bg, root.size)
		for figure in travellers:
			_place_traveller(figure, bg, root.size))
	(func():
		for figure in travellers:
			_place_traveller(figure, bg, root.size)).call_deferred()
	_finish(root, 0.5)
	var strip := _title_strip(hovered, lineage, entry_keys)
	root.add_child(strip)
	root.set_meta("strip", strip)
	return root

## Kamp ateşinin resimdeki yeri (payı). Işık bu noktaya oturur.
const FIRE_POINT: Vector2 = Vector2(0.285, 0.735)

## Ateşin başındaki üç yorgun yolcu (görev Y-G16, taslak: `menu_kamp_taslak.py`):
## her biri bir sandığın üstünde oturuyor (`sit_box` klibi: kalça sandığın
## kapağında, ayaklar yerde), ikisi ateşe yan dönük, biri ateşin ardında.
## Işık yalnızca ateşten: yakın olan sıcak, uzaktaki karanlık. Ayak noktası ve
## boy resmin payı; ekran boyutu değişince `_place_traveller` yeniden oturtur.
const CAMP_TRAVELLERS: Array = [
	{"at": Vector2(0.206, 0.787), "height": 0.33, "gender": 1, "weight": 2, "skin": 1, "right": true,
		"light": 1.0,
		"outfit": ["wool_pants", "short_boots", "linen_tunic", "wool_coat", "felt_cap"]},
	{"at": Vector2(0.388, 0.796), "height": 0.33, "gender": 0, "weight": 0, "skin": 0, "right": false,
		"light": 1.0,
		"outfit": ["long_skirt", "felt_shoes", "peasant_blouse", "head_veil"]},
	{"at": Vector2(0.341, 0.748), "height": 0.27, "gender": 1, "weight": 0, "skin": 2, "right": false,
		"light": 0.55,
		"outfit": ["peasant_pants", "peasant_shoes", "peasant_shirt"]},
]
const CRATE_ART: String = "res://data/assets/props/crate/body.png"
const FIRELIT_SHADER: Shader = preload("res://scripts/ui/grim/firelit.gdshader")
const SEATED_CLIP: String = "sit_box"
## Sandığın boyu oturanın boyunun bu payı; kalça sandığın kapağında.
const CRATE_HEIGHT_SHARE: float = 0.26
const CRATE_BACK_SHARE: float = 0.09
## Ateşin ışığının eriştiği yarıçap, resmin boyunun payı.
const FIRE_LIGHT_RADIUS: float = 0.34

static func _camp_travellers() -> Array:
	var out: Array = []
	var crate_tex: Texture2D = TextureLoader.load_any(CRATE_ART)
	# Önce uzaktakiler çizilsin: ayak noktası yukarıda olan arkada kalır.
	var order: Array = CAMP_TRAVELLERS.duplicate()
	order.sort_custom(func(x, y): return Vector2(x["at"]).y < Vector2(y["at"]).y)
	for entry in order:
		var look: Dictionary = entry
		var person := FigurePreview.new()
		person.max_figure_height = 0.0
		var outfit := {}
		for piece_id in look["outfit"]:
			var piece := OutfitCatalog.get_piece(String(piece_id))
			if piece != null:
				outfit[piece.slot] = piece.piece_id
		var skin := CharacterData.get_skin_tone_color(int(look["skin"]))
		var variant := Wardrobe.body_id_for(int(look["gender"]), int(look["weight"]))
		person.show_look("villager", 1.0, skin, outfit, PackedStringArray(), variant)
		person.set_facing(1.0 if look["right"] else -1.0)
		person.set_action(SEATED_CLIP)
		var lit := ShaderMaterial.new()
		lit.shader = FIRELIT_SHADER
		lit.set_shader_parameter("strength", float(look["light"]))
		person.set_figure_material(lit)
		person.set_meta("light", lit)
		person.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var crate := TextureRect.new()
		crate.texture = crate_tex
		crate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crate.stretch_mode = TextureRect.STRETCH_SCALE
		crate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Sandık da ateşten aydınlanır, yolcudan biraz daha az (taslak: ışık × 0.8).
		var crate_light := ShaderMaterial.new()
		crate_light.shader = FIRELIT_SHADER
		crate_light.set_shader_parameter("strength", float(look["light"]) * 0.8)
		crate.material = crate_light
		person.set_meta("look", look)
		person.set_meta("crate", crate)
		out.append(person)
	return out

static func _place_traveller(person: Control, bg: TextureRect, view: Vector2) -> void:
	if bg.texture == null:
		return
	var img := Vector2(bg.texture.get_size())
	var k := maxf(view.x / img.x, view.y / img.y)
	var offset := (view - img * k) * 0.5
	var look: Dictionary = person.get_meta("look")
	var at: Vector2 = look["at"]
	var feet := offset + at * img * k
	var figure_h := float(look["height"]) * img.y * k
	# FigurePreview çizdiği boyu penceresinin %86'sı yapar (`_layout`).
	person.size = Vector2(figure_h * 0.8, figure_h / 0.86)
	person.position = feet - Vector2(person.size.x * 0.5, person.size.y)
	(person as FigurePreview).refit()
	# Işık ateşten yayılır: ateşe dönük yan sıcak, sırt karanlık.
	var fire := offset + FIRE_POINT * img * k
	var radius := img.y * k * FIRE_LIGHT_RADIUS
	var lit: ShaderMaterial = person.get_meta("light")
	lit.set_shader_parameter("fire", fire)
	lit.set_shader_parameter("radius", radius)
	var crate: TextureRect = person.get_meta("crate")
	if crate != null and crate.texture != null:
		var crate_h := figure_h * CRATE_HEIGHT_SHARE
		var crate_w := crate_h * 0.98
		var back := -1.0 if look["right"] else 1.0
		crate.size = Vector2(crate_w, crate_h)
		crate.position = Vector2(feet.x + back * figure_h * CRATE_BACK_SHARE - crate_w * 0.5, feet.y - crate_h + 4.0)
		var crate_light: ShaderMaterial = crate.material
		crate_light.set_shader_parameter("fire", fire)
		crate_light.set_shader_parameter("radius", radius)

static func _place_on_image(node: Control, bg: TextureRect, view: Vector2) -> void:
	if bg.texture == null:
		return
	var img := Vector2(bg.texture.get_size())
	var k := maxf(view.x / img.x, view.y / img.y)
	var offset := (view - img * k) * 0.5
	var p: Vector2 = node.get_meta("image_point")
	node.position = offset + p * img * k - node.size * 0.5

## Başlık ve menü (taslak `y_g16_menu_kamp.png`): şerit yok, kutu yok. Yazı
## doğrudan kampın gece göğünün üstünde, sahnenin sağ yarısında: altın
## WAYBORNE, altında kemik renkli satırlar, en altta kervanın soy satırı.
## Konumlar 1920x1080 taslağın payları; ekran genişleyince sütun sağa kayar.
const TITLE_COLUMN_X: float = 1180.0 / 1920.0
const TITLE_Y: float = 300.0 / 1080.0
const MENU_Y: float = 460.0 / 1080.0
const LINEAGE_Y: float = 800.0 / 1080.0
const TITLE_FONT_SIZE: int = 92
const MENU_FONT_SIZE: int = 38
const MENU_ROW_HEIGHT: float = 62.0
const LINEAGE_FONT_SIZE: int = 24

## Fener amblemi başlığın yazı boyunun bu payı kadar, başlığın solunda.
const EMBLEM_SHARE: float = 1.15
const EMBLEM_GAP: float = 18.0
## Fener kare resmin ortasında dar duruyor: yanlardaki boş pay kadar başlığa yaklaştır.
const EMBLEM_SIDE_MARGIN: float = 0.22

static func _title_strip(hovered: int, lineage: Dictionary, entry_keys: Array) -> Control:
	var column := Control.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := GrimTheme.label("WAYBORNE", TITLE_FONT_SIZE, ArtPalette.MENU_TITLE_GOLD, true)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin(title, TITLE_COLUMN_X, TITLE_Y - 0.012)
	column.add_child(title)
	# Görev Y-G08: oyunun motifi fener, adın yanında küçük bir amblem.
	# Menünün ışığı ateş kalıyor (kullanıcı kararı: ateş ve fener birlikte).
	var emblem := TextureRect.new()
	emblem.texture = GrimTheme.texture("lantern_emblem.png")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.modulate = Color(0.92, 0.86, 0.74)
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pin(emblem, TITLE_COLUMN_X, TITLE_Y - 0.012)
	var side := float(TITLE_FONT_SIZE) * EMBLEM_SHARE
	emblem.offset_right = -EMBLEM_GAP + side * EMBLEM_SIDE_MARGIN
	emblem.offset_left = emblem.offset_right - side
	emblem.offset_top = (float(TITLE_FONT_SIZE) * 1.25 - side) * 0.5
	emblem.offset_bottom = emblem.offset_top + side
	column.add_child(emblem)
	var entries: Array = []
	for key in entry_keys:
		entries.append(tr_key(String(key)))
	var menu := InkMenu.new().setup_plain(entries, MENU_FONT_SIZE, MENU_ROW_HEIGHT,
		ArtPalette.MENU_TEXT_BONE, ArtPalette.MENU_TITLE_GOLD)
	_pin(menu, TITLE_COLUMN_X + 10.0 / 1920.0, MENU_Y - 0.008)
	column.add_child(menu)
	menu.force_hover(hovered)
	if not lineage.is_empty():
		var line := GrimTheme.label(tr_key("UI_GRIM_LINEAGE_LINE") % [String(lineage.get("name", "")),
			int(lineage.get("generation", 1)), int(lineage.get("day", 1))], LINEAGE_FONT_SIZE, ArtPalette.MENU_TEXT_DIM)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pin(line, TITLE_COLUMN_X + 10.0 / 1920.0, LINEAGE_Y)
		column.add_child(line)
	column.set_meta("menu", menu)
	return column

## Bir düğümün sol üst köşesini ekranın payına çiviler (anchor, offset sıfır).
static func _pin(node: Control, x_share: float, y_share: float) -> void:
	node.anchor_left = x_share
	node.anchor_right = x_share
	node.anchor_top = y_share
	node.anchor_bottom = y_share
	node.grow_horizontal = Control.GROW_DIRECTION_END
	node.grow_vertical = Control.GROW_DIRECTION_END

# ------------------------------------------------------------------ ticaret

static func trade(model: Dictionary) -> Control:
	var root := _root()
	var bg := TextureRect.new()
	bg.texture = WaybookTheme.texture("b2_market.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.35, 0.32, 0.30)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_full(bg))
	_finish(root, 0.3)
	root.add_child(top_bar(model))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	margin.add_theme_constant_override("margin_top", int(BAR_HEIGHT) + 26)
	margin.add_theme_constant_override("margin_bottom", int(STRIP_HEIGHT) + 20)
	root.add_child(margin)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 22)
	margin.add_child(split)
	split.add_child(_goods_column(tr_key("UI_GRIM_THEIR_STALL"), model.get("market", []), true))
	split.add_child(_scales_column(model))
	split.add_child(_goods_column(tr_key("UI_GRIM_YOUR_LOAD"), model.get("load", []), false))
	root.add_child(bottom_bar(["UI_GRIM_TRADE_BASKET", "UI_GRIM_TRADE_HAGGLE"], "UI_GRIM_BACK"))
	return root

static func _goods_column(heading: String, rows: Array, theirs: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GrimTheme.iron_panel(0.9))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(GrimTheme.label(heading, GrimTheme.HEADING_SIZE + 2, ArtPalette.GRIM_PARCHMENT, true))
	for r in rows:
		col.add_child(_goods_row(r, theirs))
	return panel

static func _goods_row(r: Dictionary, theirs: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var id := String(r["item"])
	row.add_child(WaybookTheme.item_icon(id, 34))
	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", -2)
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var item := ItemCatalog.get_item(id)
	name_col.add_child(GrimTheme.label(tr_key(item.item_name_key) if item != null else id, GrimTheme.BODY_SIZE, ArtPalette.GRIM_PARCHMENT))
	var sub := tr_key("UI_GRIM_WEIGHT_QTY") % [float(item.unit_weight) if item != null else 0.0, int(r.get("qty", 0))]
	name_col.add_child(GrimTheme.label(sub, GrimTheme.SMALL_SIZE - 1, ArtPalette.GRIM_PARCHMENT_DIM))
	row.add_child(name_col)
	if theirs:
		var meter := MarketMeter.new()
		meter.set_state(float(r.get("stock", 0.5)), float(r.get("mult", 1.0)), bool(r.get("shocked", false)))
		row.add_child(meter)
	var price := GrimTheme.label("%d" % int(r.get("price", 0)), GrimTheme.HEADING_SIZE, ArtPalette.GRIM_AMBER, true)
	price.custom_minimum_size = Vector2(52, 0)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(price)
	return row

static func _scales_column(model: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(420, 0)
	col.add_theme_constant_override("separation", 8)
	col.add_child(GrimTheme.label(tr_key("UI_GRIM_SCALES_HEADING"), GrimTheme.HEADING_SIZE + 2, ArtPalette.GRIM_PARCHMENT, true))
	var scales := TradeScales.new()
	scales.custom_minimum_size = Vector2(420, 360)
	scales.set_values(float(model.get("trade_ask", 120)), float(model.get("trade_offer", 96)), true)
	col.add_child(scales)
	var note := GrimTheme.label(tr_key("UI_GRIM_SCALES_NOTE") % [int(model.get("trade_rounds", 2))],
		GrimTheme.BODY_SIZE - 1, ArtPalette.GRIM_PARCHMENT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	var hint := GrimTheme.label(tr_key("UI_GRIM_SCARCITY_LEGEND"), GrimTheme.SMALL_SIZE - 1, Color(ArtPalette.GRIM_PARCHMENT_DIM, 0.8))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	return col

# ------------------------------------------------------------------ envanter

static func inventory(model: Dictionary) -> Control:
	var root := _root()
	# Yük vagonun içinde sayılır: arkada avlunun masası (B4), loş.
	var bg := TextureRect.new()
	bg.texture = WaybookTheme.texture("b4_yard.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.32, 0.30, 0.28)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_full(bg))
	_finish(root, 0.25)
	root.add_child(top_bar(model))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", int(BAR_HEIGHT) + 24)
	margin.add_theme_constant_override("margin_bottom", int(STRIP_HEIGHT) + 20)
	root.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_child(row)
	var wagons: Array = model.get("wagons", [])
	for i in wagons.size():
		row.add_child(_grid_panel(tr_key("UI_GRIM_WAGON_N") % (i + 1), wagons[i], 4, float(model.get("wagon_cap", 400))))
	row.add_child(_grid_panel(tr_key("UI_GRIM_POCKETS"), model.get("pockets", []), 2, float(model.get("pocket_cap", 40))))
	root.add_child(bottom_bar(["UI_GRIM_INV_MOVE", "UI_GRIM_INV_DROP", "UI_GRIM_INV_CRAFT"], "UI_GRIM_BACK"))
	return root

static func _grid_panel(heading: String, cells: Array, columns: int, capacity: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GrimTheme.iron_panel(0.92))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var load := 0.0
	for c in cells:
		load += float(c["weight"])
	var head := HBoxContainer.new()
	col.add_child(head)
	var h := GrimTheme.label(heading, GrimTheme.HEADING_SIZE + 2, ArtPalette.GRIM_PARCHMENT, true)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(h)
	head.add_child(GrimTheme.label("%.0f / %.0f" % [load, capacity], GrimTheme.BODY_SIZE,
		ArtPalette.GRIM_CRIMSON.lightened(0.3) if load > capacity * 0.9 else ArtPalette.GRIM_PARCHMENT_DIM))
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	for c in cells:
		grid.add_child(WornCell.new().setup(String(c["item"]), int(c["qty"]), float(c["weight"]),
			float(c.get("cond", 1.0)), float(c.get("frost", 0.0)), float(c.get("grime", 0.0)), int(c.get("days", -1))))
	for _i in maxi(0, columns * 3 - cells.size()):
		var empty := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0, 0, 0, 0.35)
		box.border_color = Color(ArtPalette.GRIM_IRON, 0.5)
		box.set_border_width_all(1)
		empty.add_theme_stylebox_override("panel", box)
		empty.custom_minimum_size = Vector2(WornCell.SIDE, WornCell.SIDE + 18)
		grid.add_child(empty)
	return panel

# ------------------------------------------------------------------ yol

## Yolun göstergeleri. Arka plan gerçek yol ekranı olurdu; taslakta onun
## yerinde loş bir manzara var, çünkü değişen şey yalnızca kenar.
static func hud(model: Dictionary) -> Control:
	var root := _root()
	var band := TravelBand.new()
	root.add_child(_full(band))
	band.set_phase(JourneyClock.Phase.EVENING, 0.5)
	var shade := ColorRect.new()
	shade.color = Color(ArtPalette.GRIM_CHARCOAL, 0.25)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_full(shade))
	_finish(root, 1.0)
	root.add_child(top_bar(model))
	_add_notice_host(root)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", GrimTheme.plate_box(false, Vector4(18, 12, 18, 10)))
	root.add_child(plate)
	plate.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	plate.offset_left = 24
	plate.offset_bottom = -STRIP_HEIGHT - 14
	plate.offset_top = plate.offset_bottom - SurvivalGauge.SIZE.y - SurvivalGauge.NUMBER_HEIGHT * 2.0 - 28.0
	var gauges := HBoxContainer.new()
	gauges.add_theme_constant_override("separation", 18)
	plate.add_child(gauges)
	var g: Dictionary = model.get("gauges", {})
	for spec in [
		[SurvivalGauge.Kind.VIAL, ArtPalette.UI_GAUGE_MORALE, "UI_GRIM_G_MORALE", "morale", true],
		[SurvivalGauge.Kind.VIAL, ArtPalette.GRIM_BILE, "UI_GRIM_G_HUNGER", "hunger", true],
		[SurvivalGauge.Kind.VIAL, ArtPalette.UI_GAUGE_STAMINA, "UI_GRIM_G_FATIGUE", "fatigue", true],
		[SurvivalGauge.Kind.STAIN, ArtPalette.GRIM_CRIMSON, "UI_GRIM_G_DANGER", "danger", false],
		[SurvivalGauge.Kind.FLAME, ArtPalette.GRIM_AMBER, "UI_GRIM_G_WARMTH", "warmth", true],
	]:
		var gauge := SurvivalGauge.new().setup(spec[0], spec[1], tr_key(String(spec[2])), bool(spec[4]))
		if String(spec[3]) == "warmth" and g.has("celsius"):
			gauge.set_celsius(float(g["celsius"]))
		else:
			gauge.set_value(float(g.get(String(spec[3]), 50)))
		gauge.set_time(1.7)
		gauges.add_child(gauge)
	root.add_child(bottom_bar(["UI_GRIM_HUD_CAMP", "UI_GRIM_NAV_LEDGER", "UI_GRIM_NAV_MAP"], "UI_GRIM_HUD_TURN_BACK"))
	return root

# ------------------------------------------------------------------ oturumdan

## Taslağın oturumdan okuyabildiği her şey. Durum/bozulma ve sıcaklık bugün
## yok; o alanlar model'de boş kalıyor ve ekran onları göstermiyor.
static func from_session(session: GameSession) -> Dictionary:
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	var party: Array = []
	for c in session.party:
		party.append({"name": c.character_name, "hp": c.current_hp, "max_hp": c.get_max_hp(), "stress": c.stress})
	var daily := maxi(1, session.get_daily_provision_consumption())
	return {
		"city_name": location.location_name if location != null else "",
		"gold": session.wallet.balance,
		"debt": session.get_total_debt(),
		"provisions": session.get_provisions(),
		"provisions_days": session.get_provisions() / daily,
		"day": session.total_days_elapsed + 1,
		"hour": session.last_clock_hour,
		"party": party,
	}
