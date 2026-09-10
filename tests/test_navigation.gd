extends RefCounted

## Ekranlar arası gezinme testleri. Buradaki hatalar oyunu çökertmez,
## oyuncuyu bir ekranda kilitler: bir kez loncaya girip tayfa arayınca
## şehre bir daha çıkılamıyordu, çünkü mekân ekranı alt ekranı açarken
## Nav.return_scene'e *kendini* yazıyordu ve dönünce kendi geri tuşu
## kendisine dönüyordu.
##
## Ekranların kendisi (Control sahneleri) headless koşturulamaz, bu yüzden
## test edilen şey ekranların çağırdığı Nav mantığı ve sahne dosyalarının
## yapısı - test_localization.gd'nin kaynak taraması ile aynı yaklaşım.

const NAV_PATH: String = "res://scripts/world/nav.gd"

## Kaydırma kutusu içinde kalması geri tuşunu ekran dışına iten ekranlar
## için tarama. Buradaki isimler "çıkış tuşu" sayılır.
const EXIT_BUTTON_NAMES: Array[String] = ["back_button", "_exit_button", "_start_button"]

func suite_name() -> String:
	return "Navigation"

func run(t) -> void:
	var nav = load(NAV_PATH)
	_test_recruit_detour_keeps_caller_return(t, nav)
	_test_scene_constants_exist(t, nav)
	_test_every_screen_has_an_exit(t, nav)
	_test_labels_never_blank(t, nav)
	_test_recruit_funnel_is_the_only_door(t, nav)
	_test_exit_buttons_outside_scroll(t)
	_test_node_paths_resolve(t, nav)

## Asıl hata buydu: tayfa ekranına gitmek, gönderen mekânın kendi geri
## hedefini eziyordu.
func _test_recruit_detour_keeps_caller_return(t, nav) -> void:
	nav.return_scene = nav.CITY_MAP

	var target: String = nav.open_recruit("guild", nav.GUILD)
	t.ok(target == nav.RECRUIT, "open_recruit tayfa ekranını hedefler")
	t.ok(nav.recruit_venue == "guild", "mekân aday havuzuna taşınır")
	t.ok(
		nav.return_scene == nav.CITY_MAP,
		"tayfa ekranını açmak gönderenin geri hedefini ezmez"
	)
	t.ok(nav.close_recruit() == nav.GUILD, "tayfa ekranı gönderen mekâna döner")

	# Mekâna dönen oyuncu oradan da çıkabilmeli - kilidin ikinci yarısı.
	t.ok(
		nav.return_scene != nav.GUILD,
		"mekânın geri tuşu kendisine dönmez"
	)

	# Yoldan girilen pazar için de aynısı geçerli.
	nav.return_scene = nav.WORLD_HUB
	nav.open_recruit("market", nav.ECONOMY)
	t.ok(
		nav.return_scene == nav.WORLD_HUB,
		"yoldan girilen pazarda da yol bağlamı korunur"
	)

	nav.return_scene = nav.CITY_MAP

## Bir sahne yolu yanlışsa geri tuşu sessizce hiçbir şey yapmaz.
func _test_scene_constants_exist(t, nav) -> void:
	for path in _scene_paths(nav):
		t.ok(ResourceLoader.exists(path), "sahne dosyası var: %s" % path)

## Her ekranın en az bir çıkışı olmalı; olmayan ekran oyuncuyu hapseder.
func _test_every_screen_has_an_exit(t, nav) -> void:
	for path in _scene_paths(nav):
		var script_path := _script_of_scene(path)
		t.ok(not script_path.is_empty(), "sahnenin script'i var: %s" % path)
		if script_path.is_empty():
			continue
		var source := _read(script_path)
		var has_exit := (
			source.contains("change_scene_to_file")
			or source.contains("get_tree().quit()")
		)
		t.ok(has_exit, "ekranın çıkışı var: %s" % script_path)

func _test_labels_never_blank(t, nav) -> void:
	for path in _scene_paths(nav):
		var label: String = nav.label_for(path)
		t.ok(not label.strip_edges().is_empty(), "geri tuşu yazısı boş değil: %s" % path)

## Tayfa ekranı tek kapıdan açılıp kapanmalı. Hub ekranları (yol, şehir,
## ana menü) return_scene'i meşru olarak kendilerine yazar - "alt ekranlar
## bana dönsün" demektir - o yüzden "kendine yazma" diye bir kural yok.
## Kural şu: gönderen ekran *kendi* geri hedefini korumak zorunda, ve bunu
## garanti eden tek yer Nav.open_recruit/close_recruit. Ekranlar buradan
## geçmezse aynı tuzağı yeniden kurabilirler.
func _test_recruit_funnel_is_the_only_door(t, nav) -> void:
	for script_path in _all_screen_scripts():
		if script_path.ends_with("nav.gd"):
			continue
		var source := _read_code(script_path)
		t.ok(
			not source.contains("Nav.RECRUIT"),
			"%s: tayfa ekranını Nav.open_recruit ile açar" % script_path
		)
		t.ok(
			not source.contains("Nav.recruit_return_scene"),
			"%s: tayfa geri hedefini Nav.close_recruit ile okur" % script_path
		)

## Geri/çıkış tuşu kaydırma kutusunun dışında durmalı; içeride kalırsa
## içerik uzadıkça ekran dışına itilir (pazar ekranında bir kez yaşandı).
func _test_exit_buttons_outside_scroll(t) -> void:
	for script_path in _all_screen_scripts():
		var source := _read_code(script_path)
		for button_name in EXIT_BUTTON_NAMES:
			t.ok(
				not source.contains("_content.add_child(%s)" % button_name),
				"%s: çıkış tuşu kaydırma kutusunun dışında" % script_path
			)

## Ekran script'lerindeki `$A/B` düğüm yolları sahnede gerçekten var mı?
## Godot yanlış bir yolu yalnızca o ekran açıldığında, çalışma anında
## bildirir - yani oyuncu ekrana girdiğinde. PackedScene'in durumu
## instantiate etmeden okunabildiği için burada önceden yakalanabiliyor
## (headless ortamda Control sahneleri kurulamıyor).
func _test_node_paths_resolve(t, nav) -> void:
	for scene_path in _scene_paths(nav):
		var script_path := _script_of_scene(scene_path)
		if script_path.is_empty():
			continue
		var known := _scene_node_paths(scene_path)
		for node_path in _dollar_paths(_read_code(script_path)):
			t.ok(
				known.has(node_path),
				"%s: $%s düğümü sahnede var" % [script_path, node_path]
			)

func _scene_node_paths(scene_path: String) -> Dictionary:
	var packed: PackedScene = load(scene_path)
	var known := {}
	if packed == null:
		return known
	var state := packed.get_state()
	for i in range(state.get_node_count()):
		var full := String(state.get_node_path(i)).trim_prefix("./")
		if not full.is_empty() and full != ".":
			known[full] = true
	return known

## `$MarginContainer/VBoxContainer/Foo` biçimindeki yolları ayıklar.
func _dollar_paths(source: String) -> Array[String]:
	var paths: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\$([A-Za-z_][A-Za-z0-9_/]*)")
	for found in regex.search_all(source):
		var path := found.get_string(1)
		if not paths.has(path):
			paths.append(path)
	return paths

func _scene_paths(nav) -> Array[String]:
	var paths: Array[String] = []
	for key in nav.get_script_constant_map():
		var value = nav.get_script_constant_map()[key]
		if value is String and value.begins_with("res://scenes/"):
			paths.append(value)
	return paths



## .tscn'in kök script'ini metinden okur - sahneyi instantiate etmek
## headless ortamda mümkün değil.
func _script_of_scene(scene_path: String) -> String:
	var source := _read(scene_path)
	for line in source.split("\n"):
		if not line.begins_with("[ext_resource type=\"Script\""):
			continue
		var start := line.find("path=\"")
		if start < 0:
			continue
		start += 6
		var end := line.find("\"", start)
		if end > start:
			return line.substr(start, end - start)
	return ""

func _all_screen_scripts() -> Array[String]:
	var scripts: Array[String] = []
	for directory in ["res://scripts/ui", "res://scripts/world"]:
		for file_name in DirAccess.get_files_at(directory):
			if file_name.ends_with(".gd"):
				scripts.append("%s/%s" % [directory, file_name])
	return scripts

## Kaynak taramaları yorum satırlarını görmemeli - kuralı anlatan bir
## açıklama, kuralı çiğneyen bir çağrı değildir.
func _read_code(path: String) -> String:
	var lines: Array[String] = []
	for line in _read(path).split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		lines.append(line)
	return "\n".join(lines)

func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
