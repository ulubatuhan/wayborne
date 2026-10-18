extends SceneTree

## Karanlık arayüz taslağının ekran görüntüleri (test değil, PNG basar):
## şehir merkezi (boş ve bir binanın menüsü açık), başlık, ticaret, envanter,
## yol göstergeleri ve tek tek bileşenlerin durum sayfası. Örnek veri burada,
## oyunun kodunda değil - taslak ekranlar yalnızca bir `model` okuyor.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_grim_ui.gd

const SIZE: Vector2i = Vector2i(1920, 1080)
const OUT_DIR: String = "user://grim_ui/"
## Eski taslak kasaba resimleri (görev P17'ye kadar geçici); ad yalnızca etiket.
const CITY_KEYS: Dictionary = {
	"karakonak": "Karakonak", "kurtbogazi": "Kurtbogazi", "ipekevi": "Ipekevi",
	"demirkapi": "Demirkapi", "yesilova": "Yesilova",
}

func _init() -> void:
	TranslationServer.set_locale("tr")
	WaybookTheme.install()
	get_root().size = SIZE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# UserSettings dili kendi ayarından kuruyor; ilk kareden sonra Türkçeye sabitle.
	await process_frame
	TranslationServer.set_locale("tr")
	var model := _sample_model()
	var cities: Array = OS.get_cmdline_user_args() if not OS.get_cmdline_user_args().is_empty() else ["karakonak"]
	for city in cities:
		model["city_name"] = tr(String(CITY_KEYS.get(city, city)))
		await _shot("1_town_%s" % city, CityFront.new().setup(city, model))
		var lit := CityFront.new().setup(city, model)
		await _shot("2_town_%s_hover" % city, lit, func(): lit.set_hovered(4))
	await _shot("3_title", GrimDrafts.title(1, {"name": "Demirtaş", "generation": 3, "day": 214}))
	await _shot("4_trade", GrimDrafts.trade(model))
	await _shot("5_inventory", GrimDrafts.inventory(model))
	var hud := GrimDrafts.hud(model)
	await _shot("6_hud", hud, func():
		GrimDrafts.push_notice(hud, tr("UI_GRIM_N_HUNGER_TITLE"), tr("UI_GRIM_N_HUNGER_BODY"), GrimNotice.Severity.LOSS)
		GrimDrafts.push_notice(hud, tr("UI_GRIM_N_FIND_TITLE"), tr("UI_GRIM_N_FIND_BODY"), GrimNotice.Severity.GAIN))
	await _shot("7_states", _states_sheet())
	print("yazildi: ", ProjectSettings.globalize_path(OUT_DIR))
	quit()

func _shot(name: String, screen: Control, after: Callable = Callable()) -> void:
	var root := get_root()
	root.add_child(screen)
	screen.size = Vector2(SIZE)
	for _f in 3:
		await process_frame
	if after.is_valid():
		after.call()
	_freeze(screen, 2.0)
	for _f in 4:
		await process_frame
	root.get_texture().get_image().save_png(OUT_DIR + name + ".png")
	screen.queue_free()
	await process_frame

## Zamanla oynayan her şeyi aynı ana sabitler - her çekim aynı kareyi verir.
func _freeze(node: Node, t: float) -> void:
	if node.has_method("set_time"):
		node.call("set_time", t)
	node.set_process(false)
	for child in node.get_children():
		_freeze(child, t)

## Bileşenlerin durumları yan yana: göstergeler iyi → kötü, hücre sağlam →
## harap, terazi üç denge, menü satırı hover yokken/varken.
func _states_sheet() -> Control:
	var root := Control.new()
	var bg := ColorRect.new()
	bg.color = ArtPalette.GRIM_CHARCOAL
	bg.size = Vector2(SIZE)
	root.add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(40, 30)
	col.add_theme_constant_override("separation", 22)
	root.add_child(col)
	for spec in [
		[SurvivalGauge.Kind.VIAL, ArtPalette.UI_GAUGE_MORALE, "UI_GRIM_G_MORALE", true],
		[SurvivalGauge.Kind.FLAME, ArtPalette.GRIM_AMBER, "UI_GRIM_G_WARMTH", true],
		[SurvivalGauge.Kind.STAIN, ArtPalette.GRIM_CRIMSON, "UI_GRIM_G_DANGER", false],
	]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 26)
		col.add_child(row)
		for v in [100, 75, 50, 30, 12, 0]:
			var g := SurvivalGauge.new().setup(spec[0], spec[1], tr(String(spec[2])), bool(spec[3]))
			g.set_value(v)
			row.add_child(g)
	var cells := HBoxContainer.new()
	cells.add_theme_constant_override("separation", 10)
	col.add_child(cells)
	for w in [[1.0, 0, 0], [0.7, 0, 0.3], [0.45, 0.2, 0.6], [0.25, 0.7, 0.4], [0.08, 0.3, 0.9]]:
		cells.add_child(WornCell.new().setup("test_cloth", 3, 6, w[0], w[1], w[2]))
	for w in [[1.0, 0.0, 0.0], [0.6, 0.8, 0.1]]:
		cells.add_child(WornCell.new().setup("fish", 8, 4, w[0], w[1], w[2], 2))
	var scales_row := HBoxContainer.new()
	col.add_child(scales_row)
	for pair in [[120, 70], [100, 100], [80, 130]]:
		var s := TradeScales.new()
		s.custom_minimum_size = Vector2(300, 250)
		s.set_values(pair[0], pair[1], true)
		scales_row.add_child(s)
	var meters := VBoxContainer.new()
	scales_row.add_child(meters)
	for m in [[0.1, 1.6, true], [0.4, 1.15, false], [0.9, 0.8, false]]:
		var meter := MarketMeter.new()
		meter.set_state(m[0], m[1], m[2])
		meters.add_child(meter)
	return root

func _sample_model() -> Dictionary:
	var town_lines := {
		"UI_GRIM_VENUE_YARD": [{"key": "UI_GRIM_L_YARD_REPAIR", "args": [1], "kind": "bad"}],
		"UI_GRIM_VENUE_MARKET": [{"key": "UI_GRIM_L_MARKET_SCARCE", "args": [tr("ITEM_GRAIN_NAME")], "kind": "bad"}],
		"UI_GRIM_VENUE_GUILD": [{"key": "UI_GRIM_L_GUILD_BOARD", "args": [4]}],
		"UI_GRIM_VENUE_CHURCH": [{"key": "UI_GRIM_L_CHURCH_FRESH", "args": []}],
		"UI_GRIM_VENUE_WARDROBE": [{"key": "UI_GRIM_L_TAILOR_STOCK", "args": [7]}],
		"UI_GRIM_VENUE_TAVERN": [
			{"key": "UI_GRIM_L_RECRUITS", "args": [3]},
			{"key": "UI_GRIM_L_RUMOR", "args": []},
			{"key": "UI_GRIM_L_FEAST_USED", "args": [], "kind": "bad"},
		],
	}
	return {
		"city_name": "Kurtboğazı",
		"gold": 214, "debt": 120, "provisions": 46, "provisions_days": 4,
		"day": 63, "season_key": "UI_GRIM_SEASON_AUTUMN", "hour": 18.5,
		"weather_key": "UI_GRIM_WEATHER_ASH",
		"modifiers": [
			{"key": "UI_GRIM_MOD_PLAGUE", "args": ["Yeşilova"], "kind": "bad"},
			{"key": "UI_GRIM_MOD_SCARCITY", "args": [tr("ITEM_GRAIN_NAME")], "kind": "bad"},
			{"key": "UI_GRIM_MOD_FAIR", "args": ["İpekevi"], "kind": "good"},
		],
		"party": [
			{"name": "Arslan", "hp": 31, "max_hp": 44, "stress": 38, "class": "guard", "class_key": "CLASS_GUARD_NAME", "level": 4},
			{"name": "Elif", "hp": 12, "max_hp": 36, "stress": 71, "class": "hunter", "class_key": "CLASS_HUNTER_NAME", "level": 3},
			{"name": "Doruk", "hp": 40, "max_hp": 40, "stress": 15, "class": "clerk", "class_key": "CLASS_CLERK_NAME", "level": 2},
		],
		"venue_lines": town_lines,
		"gauges": {"morale": 54, "hunger": 28, "fatigue": 62, "danger": 71, "warmth": 22, "celsius": -4},
		"market": [
			{"item": "test_grain", "qty": 4, "price": 19, "stock": 0.1, "mult": 1.6, "shocked": true},
			{"item": "honey", "qty": 18, "price": 24, "stock": 0.7, "mult": 0.85},
			{"item": "test_furs", "qty": 9, "price": 41, "stock": 0.45, "mult": 1.1},
			{"item": "spice", "qty": 6, "price": 58, "stock": 0.3, "mult": 1.25},
		],
		"load": [
			{"item": "silk", "qty": 5, "price": 71},
			{"item": "test_cloth", "qty": 12, "price": 22},
			{"item": "fish", "qty": 8, "price": 7},
		],
		"trade_ask": 120, "trade_offer": 96, "trade_rounds": 2,
		"wagon_cap": 400, "pocket_cap": 40,
		"wagons": [
			[
				{"item": "test_grain", "qty": 20, "weight": 60, "cond": 0.9, "grime": 0.2},
				{"item": "test_cloth", "qty": 12, "weight": 36, "cond": 0.55, "grime": 0.5},
				{"item": "silk", "qty": 5, "weight": 10, "cond": 0.95},
				{"item": "fish", "qty": 8, "weight": 16, "cond": 0.6, "days": 2},
				{"item": "test_furs", "qty": 4, "weight": 48, "cond": 0.3, "frost": 0.7},
				{"item": "wine", "qty": 3, "weight": 45, "cond": 0.8},
			],
			[
				{"item": "test_weapon", "qty": 6, "weight": 90, "cond": 0.4, "grime": 0.8},
				{"item": "honey", "qty": 10, "weight": 20, "cond": 1.0, "days": 9},
				{"item": "spice", "qty": 2, "weight": 2, "cond": 0.75},
			],
		],
		"pockets": [
			{"item": "test_bandage", "qty": 3, "weight": 1, "cond": 0.7, "grime": 0.4},
			{"item": "test_potion", "qty": 1, "weight": 1, "cond": 0.15, "frost": 0.4},
			{"item": "jewelry", "qty": 1, "weight": 0.5, "cond": 1.0},
		],
	}
