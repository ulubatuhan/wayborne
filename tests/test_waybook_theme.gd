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
	_test_desk_workspace_keeps_the_props(t)
	_test_warning_colour_is_readable(t)
	_test_present_dismiss_is_a_settle_not_a_snap(t)
	_test_default_button_is_minimal(t, theme)

func _test_chrome_is_textured(t, theme: Theme) -> void:
	var expected := [
		["panel", "PanelContainer"], ["panel", "SealPanel"], ["panel", "SlipPanel"],
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

## "Disabled with its reason": kilitli düğme çerçevesini/köşesini kaybetmiyor
## (aynı aile - `_minimal_button`), yalnızca dolgusu ve çerçevesi soluyor -
## karalama yok (oyuncu testinde reddedildi), yarı saydam ton.
func _test_locked_button_is_marked(t, theme: Theme) -> void:
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	var locked := theme.get_stylebox("disabled", "Button") as StyleBoxFlat
	t.eq(locked.corner_radius_top_left, normal.corner_radius_top_left, "kilitli düğme aynı aile - köşe yarıçapı ortak")
	t.ok(locked.bg_color.a < normal.bg_color.a, "kilitli düğme dolgusu soluk")
	t.ok(locked.border_color.a < normal.border_color.a, "kilitli düğme çerçevesi soluk")
	t.ne(
		theme.get_color("font_disabled_color", "Button"), theme.get_color("font_color", "Button"),
		"kilitli düğmenin yazısı da soluk (sebep satırı ayrı ve canlı)"
	)
	# Ekranların bir kısmı `disabled = true`'nun üstüne bir de `modulate`
	# uyguluyordu - düğmenin dokusunu *ve* yazısını birlikte karartıp
	# sebebi ~2.8:1'e düşürüyordu (WCAG AA'nın altında, ölçülen: Recruit/
	# Guild/Planner/Combat/Purification). Temanın kendi kontrastı tek
	# başına ≥4.5:1 kalmalı - `modulate` eklenmediği sürece artık öyle.
	t.ge(
		_contrast_ratio(theme.get_color("font_disabled_color", "Button"), ArtPalette.UI_PANEL_FILL),
		4.5,
		"kilitli düğme yazısı panel zemininde WCAG AA'yı geçiyor"
	)

## WCAG bağıl parlaklık/kontrast formülü - `_test_locked_button_is_marked`'ın
## kendi iddiasını gerçek bir sayı ile doğrulaması için.
func _relative_luminance(c: Color) -> float:
	var channels := [c.r, c.g, c.b]
	var linear := []
	for channel in channels:
		linear.append(channel / 12.92 if channel <= 0.03928 else pow((channel + 0.055) / 1.055, 2.4))
	return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]

func _contrast_ratio(a: Color, b: Color) -> float:
	var l1 := _relative_luminance(a) + 0.05
	var l2 := _relative_luminance(b) + 0.05
	return maxf(l1, l2) / minf(l1, l2)

## Kenar payları dokunun yarısını geçerse ortada esneyecek bir bölge kalmaz
## ve Godot çerçeveyi bozuk çizer.
func _test_nine_slice_leaves_a_centre(t, theme: Theme) -> void:
	for pair in [["panel", "PanelContainer"], ["panel", "SealPanel"], ["tab_selected", "TabContainer"], ["panel", "SlipPanel"]]:
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
## Uyarı turuncusu (planlayıcı/borç paneli/şehir brifingi) panel zemininde
## WCAG AA'yı geçmeli - defect matrix'in ölçtüğü eski `.modulate` hatası
## (2.4-3.7:1) bir daha sessizce geri gelmesin diye.
func _test_warning_colour_is_readable(t) -> void:
	t.ge(
		_contrast_ratio(ArtPalette.UI_WARNING, ArtPalette.UI_PANEL_FILL),
		4.5,
		"UI_WARNING panel zemininde WCAG AA'yı geçiyor"
	)

## Sahnesiz panellerin açılış/kapanış devinimi (bkz. defect matrix'in "15
## scene-less panel" maddesi). Bir tween ağaç dışında koşamadığı için
## (`create_tween` bir düğümün ağaçta olmasını ister) burada canlı bir
## devinim ölçülemiyor - `_verify_present_dismiss.gd` (bu oturumda xvfb
## altında koşturuldu) canlı uçtan uca doğrulamayı yaptı. Burada kilitlenen
## iki saf iddia: ağaç dışında çağrılmak güvenle no-op kalıyor (çökmüyor,
## `root`u değiştirmiyor) ve kapanış açılıştan kısa - "bir durma bir
## yerleşmedir, ani bir kesme değil" kuralının süre tarafı.
func _test_present_dismiss_is_a_settle_not_a_snap(t) -> void:
	var theme_script = load(THEME_PATH)
	t.ok(theme_script.PRESENT_CARD_START_SCALE < 1.0, "kart küçükten büyüğe açılıyor")
	t.le(theme_script.DISMISS_SECONDS, theme_script.PRESENT_CARD_SECONDS, "kapanış açılıştan kısa ya da eşit")
	t.le(theme_script.PRESENT_BACKDROP_SECONDS, theme_script.PRESENT_CARD_SECONDS + 0.01, "perde karttan daha uzun sürmüyor")

	# Ağaçta olmayan bir düğümde present()/dismiss() çökmemeli, sessizce
	# no-op kalmalı (bkz. WaybookTheme.present/dismiss'in `is_inside_tree`
	# koruması).
	var orphan := PanelContainer.new()
	var before_scale := orphan.scale
	var before_alpha := orphan.modulate.a
	theme_script.present(orphan, null, null)
	t.eq(orphan.scale, before_scale, "ağaç dışı kart present() ile değişmiyor")
	t.eq(orphan.modulate.a, before_alpha, "ağaç dışı kart present() ile solmuyor")
	var completed := [false]
	theme_script.dismiss(orphan, null, null, func(): completed[0] = true)
	t.ok(completed[0], "ağaç dışı dismiss() geri çağrıyı hemen çağırıyor")
	orphan.free()

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

## Oyuncu G4'ün opak deri dokusunu oyunun *varsayılan* düğmesi olarak
## reddetti (bkz. WaybookTheme._tab()'ın kendi notu) - emir panelinin
## minimal ilkesi (`_ghost_button`) artık her ekranın düğmesi. Ama sekme
## (TabContainer), tam genişlikte sıra düğmesi (RowButton) ve HUD simge
## düğmesi (IconTab) kasıtlı olarak G4'te kaldı - farklı, ayrı üsluplar,
## bu değişikliğin kapsamı dışında. Bu test her iki ailenin de doğru
## dokuda kalmasını kilitliyor; biri yanlışlıkla ötekine kayarsa (ya da
## bir "hepsini minimal yap" refactor'ü sekmeleri de sürüklerse) burada
## kırılır.
func _test_default_button_is_minimal(t, theme: Theme) -> void:
	for type_name in ["Button", "OptionButton", "MenuButton"]:
		var normal := theme.get_stylebox("normal", type_name)
		t.ok(normal is StyleBoxFlat, "%s artık G4 dokusu değil, düz kutu" % type_name)
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	var hover := theme.get_stylebox("hover", "Button") as StyleBoxFlat
	var pressed := theme.get_stylebox("pressed", "Button") as StyleBoxFlat
	t.ok(hover.bg_color.a > normal.bg_color.a, "üstüne gelince dolgu artıyor")
	t.ok(pressed.bg_color.a > hover.bg_color.a, "basılınca dolgu daha da artıyor")
	t.ok(normal.border_width_left > 0, "minimal düğme yine de bir çerçeve taşıyor")
	# Kasıtlı olarak G4'te kalan aileler: sekme, sıra düğmesi, HUD simgesi.
	t.ok(
		theme.get_stylebox("tab_selected", "TabContainer") is StyleBoxTexture,
		"sekmeler kasıtlı olarak G4'te kaldı"
	)
	var theme_script = load(THEME_PATH)
	var row := theme.get_stylebox("normal", theme_script.ROW_BUTTON)
	t.ok(row is StyleBoxTexture, "tam genişlik sıra düğmesi (RowButton) kasıtlı olarak dokulu kaldı")
	var icon_tab := theme.get_stylebox("normal", theme_script.ICON_TAB)
	t.ok(icon_tab is StyleBoxTexture, "HUD simge düğmesi (IconTab) kasıtlı olarak dokulu kaldı")
