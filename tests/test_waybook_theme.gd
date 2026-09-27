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
	_test_chrome_is_minimal(t, theme)
	_test_panel_fill_comes_from_palette(t, theme)
	_test_locked_button_is_marked(t, theme)
	_test_nine_slice_leaves_a_centre(t, theme)
	_test_no_leather_texture_is_read(t)
	_test_spin_box_number_is_centred(t)
	_test_no_screen_builds_its_own_panel(t)
	_test_fx_colours_live_in_the_palette(t)
	_test_desk_workspace_keeps_the_props(t)
	_test_warning_colour_is_readable(t)
	_test_present_dismiss_is_a_settle_not_a_snap(t)
	_test_default_button_is_minimal(t, theme)

## Oyuncu deri dokuları reddetti ("deri efektini kullandığın her yer"):
## panel, mühür paneli, sekme, giriş alanı, hücre, kaydırma çubuğu ve
## düğme tek bir düz kutu ailesi. Kâğıt (ipucu fişi) ve mürekkep çizgisi
## deri değil, dokulu kalıyor.
func _test_chrome_is_minimal(t, theme: Theme) -> void:
	var theme_script = load(THEME_PATH)
	var flat := [
		["panel", "PanelContainer"], ["panel", "Panel"], ["panel", "SealPanel"],
		["tab_selected", "TabContainer"], ["tab_unselected", "TabContainer"],
		["panel", "TabContainer"], ["normal", "LineEdit"], ["read_only", "LineEdit"],
		["panel", "CellPanel"], ["grabber", "VScrollBar"], ["normal", "Button"],
	]
	for pair in flat:
		var box := theme.get_stylebox(pair[0], pair[1])
		t.ok(box is StyleBoxFlat, "%s/%s minimal düz kutu" % [pair[1], pair[0]])
		if box is StyleBoxFlat:
			t.eq(
				(box as StyleBoxFlat).corner_radius_top_left, theme_script.FRAME_RADIUS,
				"%s/%s ailenin köşe yarıçapını taşıyor" % [pair[1], pair[0]]
			)
	for pair in [["panel", "SlipPanel"], ["panel", "TooltipPanel"], ["separator", "HSeparator"]]:
		var box := theme.get_stylebox(pair[0], pair[1])
		t.ok(
			box is StyleBoxTexture and (box as StyleBoxTexture).texture != null,
			"%s/%s kâğıt/mürekkep - dokulu kalıyor" % [pair[1], pair[0]]
		)
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	var seal := theme.get_stylebox("panel", "SealPanel") as StyleBoxFlat
	t.ok(seal.border_width_left > panel.border_width_left, "geri alınamaz kararın paneli daha kalın çizgili")
	t.ok(theme.is_type_variation("SealPanel", "PanelContainer"), "SealPanel bir PanelContainer çeşidi")
	t.ok(not theme.has_stylebox("normal", "RowButton"), "tam genişlik düğme ayrı bir deri çeşidi taşımıyor")
	t.ok(not theme.has_stylebox("normal", "IconTab"), "HUD simge düğmesi ayrı bir deri çeşidi taşımıyor")
	t.ok(theme_script.get_font() != null, "kitap yüzü yükleniyor")

## Panelin zemini paletten: UI_PANEL_FILL.
func _test_panel_fill_comes_from_palette(t, theme: Theme) -> void:
	var box := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	t.eq(box.bg_color, ArtPalette.UI_PANEL_FILL, "panelin zemini ArtPalette.UI_PANEL_FILL")

## Deri sayfaları (G2 cilt, G3 mühürlü cilt, G4 sekme, G7 kurdele, G10
## leke, R1 kayış) ne tema tarafından okunuyor ne sevk ediliyor - biri geri
## gelirse Web yüklemesine boşuna bir doku ekler.
func _test_no_leather_texture_is_read(t) -> void:
	var leather := ["g2_binding", "g3_seal.png", "g4_tab", "g7_scroll", "g10_grain", "r1_strap"]
	var sources := [THEME_PATH, "res://scripts/ui/road_journey.gd", "res://scripts/autoload/ui_theme.gd"]
	for path in sources:
		var text := FileAccess.get_file_as_string(path)
		for name in leather:
			t.ok(not text.contains(name), "%s deri dokusu %s okumuyor" % [path.get_file(), name])
	for name in leather:
		var file_name: String = name if name.ends_with(".png") else name + ".png"
		if name == "g10_grain":
			file_name = "g10_grain_mask.png"
		elif name == "r1_strap":
			file_name = "r1_strap_top.png"
		t.ok(
			not FileAccess.file_exists(load(THEME_PATH).ART_DIR + file_name),
			"%s sevk edilmiyor" % file_name
		)

## Sayı kutusundaki sayı ortada (pazarın miktar kutusu ilk istekti; aynı
## kapıdan her SpinBox). `SpinBox.alignment` tema özelliği değil, düğüm
## ağaca girerken UiTheme veriyor - autoload `--script` kipinde canlı
## olmadığı için kapı burada elle çağrılıyor.
func _test_spin_box_number_is_centred(t) -> void:
	var ui_theme: Node = load("res://scripts/autoload/ui_theme.gd").new()
	var spin := SpinBox.new()
	t.ne(spin.alignment, HORIZONTAL_ALIGNMENT_CENTER, "varsayılan SpinBox sola dayalı başlıyor")
	ui_theme._on_node_added(spin)
	t.eq(spin.alignment, HORIZONTAL_ALIGNMENT_CENTER, "UiTheme SpinBox'ın sayısını ortalıyor")
	spin.free()
	ui_theme.free()

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
## ve Godot çerçeveyi bozuk çizer. Dokulu kalan tek çerçeve kâğıt fiş.
func _test_nine_slice_leaves_a_centre(t, theme: Theme) -> void:
	for pair in [["panel", "SlipPanel"]]:
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

## Varsayılan düğme minimal: çerçeve + hafif dolgu, üstüne gelince ve
## basılınca dolgu koyulaşıyor.
func _test_default_button_is_minimal(t, theme: Theme) -> void:
	for type_name in ["Button", "OptionButton", "MenuButton"]:
		var normal := theme.get_stylebox("normal", type_name)
		t.ok(normal is StyleBoxFlat, "%s düz kutu" % type_name)
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	var hover := theme.get_stylebox("hover", "Button") as StyleBoxFlat
	var pressed := theme.get_stylebox("pressed", "Button") as StyleBoxFlat
	t.ok(hover.bg_color.a > normal.bg_color.a, "üstüne gelince dolgu artıyor")
	t.ok(pressed.bg_color.a > hover.bg_color.a, "basılınca dolgu daha da artıyor")
	t.ok(normal.border_width_left > 0, "minimal düğme yine de bir çerçeve taşıyor")
	var selected := theme.get_stylebox("tab_selected", "TabContainer") as StyleBoxFlat
	var unselected := theme.get_stylebox("tab_unselected", "TabContainer") as StyleBoxFlat
	t.ok(selected.bg_color.a > unselected.bg_color.a, "seçili sekme seçili olmayandan koyu")
