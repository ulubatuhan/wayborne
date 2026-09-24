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

## "Disabled with its reason": kilitli düğme sekmesini kaybetmiyor, üstü
## çiziliyor ve soluyor - normal sekmeyle aynı doku olamaz.
func _test_locked_button_is_marked(t, theme: Theme) -> void:
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxTexture
	var locked := theme.get_stylebox("disabled", "Button") as StyleBoxTexture
	t.ne(locked.texture, normal.texture, "kilitli sekme üstü çizili ayrı bir doku")
	t.ne(locked.modulate_color, normal.modulate_color, "kilitli sekme soluk")
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
