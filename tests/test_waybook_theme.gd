extends RefCounted

## Waybook teması: tek paylaşılan tema gerçekten tek mi, renk hâlâ
## ArtPalette'ten mi geliyor, kilitli düğme hâlâ "kilitli" diye okunuyor mu.
## Görünüşü doğrulamıyor - o, screenshot araçlarının işi (bkz. Testing).

const UI_DIR: String = "res://scripts/ui"
const THEME_PATH: String = "res://scripts/ui/waybook_theme.gd"

func suite_name() -> String:
	return "WaybookTheme"

func run(t) -> void:
	var theme: Theme = load(THEME_PATH).build()
	_test_chrome_is_textured(t, theme)
	_test_panel_fill_comes_from_palette(t, theme)
	_test_locked_button_is_marked(t, theme)
	_test_nine_slice_leaves_a_centre(t, theme)
	_test_no_screen_builds_its_own_panel(t)
	_test_fx_colours_live_in_the_palette(t)
	_test_cold_edge_reads_season_and_biome(t)
	_test_desk_workspace_keeps_the_props(t)

func _test_chrome_is_textured(t, theme: Theme) -> void:
	var expected := [
		["panel", "PanelContainer"], ["panel", "SealPanel"], ["panel", "SlipPanel"],
		["normal", "Button"], ["disabled", "Button"], ["normal", "OptionButton"],
		["tab_selected", "TabContainer"], ["separator", "HSeparator"],
		["grabber", "VScrollBar"], ["panel", "TooltipPanel"],
	]
	for pair in expected:
		var box := theme.get_stylebox(pair[0], pair[1])
		t.ok(
			box is StyleBoxTexture and (box as StyleBoxTexture).texture != null,
			"%s/%s dokulu bir çerçeve" % [pair[1], pair[0]]
		)
	t.ok(theme.is_type_variation("SealPanel", "PanelContainer"), "SealPanel bir PanelContainer çeşidi")
	t.ok(load(THEME_PATH).get_font() != null, "kitap yüzü yükleniyor")

## Panelin iç zemini bir PNG'ye gömülü değil, paletten boyanıyor: ortadaki
## piksel UI_PANEL_FILL'e (üstündeki leke tanesi payıyla) eşit olmalı.
func _test_panel_fill_comes_from_palette(t, theme: Theme) -> void:
	var box := theme.get_stylebox("panel", "PanelContainer") as StyleBoxTexture
	var image := box.texture.get_image()
	var centre := image.get_pixel(image.get_width() / 2, image.get_height() / 2)
	var fill := ArtPalette.UI_PANEL_FILL
	var distance := absf(centre.r - fill.r) + absf(centre.g - fill.g) + absf(centre.b - fill.b)
	t.le(distance, 0.12, "panelin iç zemini ArtPalette.UI_PANEL_FILL")

## "Disabled with its reason": kilitli düğme sekmesini kaybetmiyor, yalnızca
## siliniyor - karalama yok (oyuncu testinde reddedildi), aynı doku, yarı
## saydam ton.
func _test_locked_button_is_marked(t, theme: Theme) -> void:
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxTexture
	var locked := theme.get_stylebox("disabled", "Button") as StyleBoxTexture
	t.eq(locked.texture, normal.texture, "kilitli sekme karalamasız, aynı doku")
	t.ne(locked.modulate_color, normal.modulate_color, "kilitli sekme soluk")
	t.ok(locked.modulate_color.a < 1.0, "kilitli sekme yarı saydam - silik")
	t.ne(
		theme.get_color("font_disabled_color", "Button"), theme.get_color("font_color", "Button"),
		"kilitli düğmenin yazısı da soluk (sebep satırı ayrı ve canlı)"
	)

## Kenar payları dokunun yarısını geçerse ortada esneyecek bir bölge kalmaz
## ve Godot çerçeveyi bozuk çizer.
func _test_nine_slice_leaves_a_centre(t, theme: Theme) -> void:
	for pair in [["panel", "PanelContainer"], ["panel", "SealPanel"], ["normal", "Button"], ["panel", "SlipPanel"]]:
		var box := theme.get_stylebox(pair[0], pair[1]) as StyleBoxTexture
		var size := box.texture.get_size()
		t.ok(
			box.texture_margin_left + box.texture_margin_right < size.x
			and box.texture_margin_top + box.texture_margin_bottom < size.y,
			"%s/%s dokuz parçası ortada bir esneme bölgesi bırakıyor" % [pair[1], pair[0]]
		)

## Dokuz ekran aynı paneli dokuz kez kendi renkleriyle kuruyordu; tema
## bunun yerine geçti. Biri kendi kutusunu yeniden kurarsa tek görünüm yine
## dağılır.
func _test_no_screen_builds_its_own_panel(t) -> void:
	var offenders: Array[String] = []
	var dir := DirAccess.open(UI_DIR)
	for file_name in dir.get_files():
		if not file_name.ends_with(".gd"):
			continue
		var text := FileAccess.get_file_as_string("%s/%s" % [UI_DIR, file_name])
		if text.contains("const PANEL_BACKGROUND") or text.contains("const PANEL_BORDER"):
			offenders.append(file_name)
	t.eq(offenders.size(), 0, "hiçbir ekran kendi panel rengini tanımlamıyor (%s)" % ", ".join(offenders))

## Efekt renkleri ArtPalette'te: savaş paneli kendi parlama sabitini bir daha
## tanımlamasın (aynı "ekran kendi panelini kurmaz" koruması).
func _test_fx_colours_live_in_the_palette(t) -> void:
	var file := FileAccess.open("res://scripts/ui/combat_panel.gd", FileAccess.READ)
	t.ok(file != null, "savaş paneli okunabiliyor")
	if file == null:
		return
	var regex := RegEx.new()
	regex.compile("const FLASH_\\w+\\s*:\\s*Color")
	t.eq(regex.search(file.get_as_text()), null, "parlama rengi yalnızca ArtPalette'te")

## Don kenarı yalnızca soğukta: yaz bozkırında hiç görünmez, kışın görünür,
## dağ kışı en koyusu ama tavanı aşmaz.
func _test_cold_edge_reads_season_and_biome(t) -> void:
	var road: Script = load("res://scripts/ui/road_journey.gd")
	t.eq(road.cold_level(false, ArtPalette.BIOME_STEPPE), 0.0, "yaz bozkırında don yok")
	t.ok(road.cold_level(true, ArtPalette.BIOME_STEPPE) > 0.0, "kışın don var")
	t.ok(road.cold_level(false, ArtPalette.BIOME_MOUNTAIN) > 0.0, "dağ geçidi kışın dışında da serin")
	t.ok(
		road.cold_level(true, ArtPalette.BIOME_MOUNTAIN) > road.cold_level(true, ArtPalette.BIOME_STEPPE),
		"dağ kışı ovadaki kıştan koyu"
	)
	t.le(road.cold_level(true, ArtPalette.BIOME_MOUNTAIN), 1.0, "don tavanı aşmıyor")

## Masa ekranlarında metin ortada bir sütunda: geniş ekranda genişliğin en
## çok %65'i (kenarlardaki nesneler resmin kendisi), dar ekranda tam genişlik.
func _test_desk_workspace_keeps_the_props(t) -> void:
	var theme_script = load(THEME_PATH)
	for width in [1280.0, 1600.0, 1920.0, 2560.0]:
		var side: int = theme_script.workspace_side_margin(width)
		var column: float = width - 2.0 * side
		t.ok(column <= width * theme_script.WORKSPACE_WIDTH_RATIO + 1.0, "geniş ekranda sütun en çok %%65 (%d)" % int(width))
	t.eq(theme_script.workspace_side_margin(1080.0), theme_script.WORKSPACE_EDGE_MARGIN, "dar ekranda sütun tam genişlik")
	# İçerik sütundan genişse sütun içeriğe açılıyor, yatay kaydırma olmuyor.
	var wide_side: int = theme_script.workspace_side_margin(1280.0, 900.0)
	t.ok(1280.0 - 2.0 * wide_side >= 900.0, "sütun içeriğin en dar genişliğinden dar değil")
	t.eq(theme_script.workspace_side_margin(1920.0, 400.0), theme_script.workspace_side_margin(1920.0), "dar içerik oranı değiştirmiyor")
	t.eq(theme_script.workspace_side_margin(1280.0, 5000.0), theme_script.WORKSPACE_EDGE_MARGIN, "kenar payı hiç sıfırın altına inmiyor")
	var screens := [
		"guild", "tavern", "caravan_yard", "church", "recruit",
		"character", "party", "caravan_planner", "character_creation", "../world/city_map",
	]
	for screen in screens:
		var source := FileAccess.get_file_as_string("res://scripts/ui/%s.gd" % screen)
		t.ok(source.contains("fit_desk_workspace"), "%s masa sütununu kullanıyor" % screen)
