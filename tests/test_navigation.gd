extends RefCounted

## Gezinme testleri. Buradaki hatalar oyunu çökertmez, oyuncuyu bir ekranda
## kilitler - ve bu, projede en sık tekrarlayan şikâyet oldu.
##
## Kök sebep mimariydi: tek bir `Nav.return_scene` string'i yalnızca *bir*
## seviye geçmiş tutabiliyordu, o yüzden iki seviye derinlikte biri
## diğerinin çıkışını eziyordu. Yığın bunu yapısal olarak çözüyor; bu paket
## de çözümün gerçekten tuttuğunu tüketici biçimde doğruluyor.
##
## Kenar listesi **kaynaktan türetiliyor**: her `Nav.open(Nav.A, Nav.B)`
## çağrısı taranıyor. Elle yazılmış bir tablo koddan kayar ve kayınca da
## testi değil oyunu yanlış gösterir.

const NAV_PATH: String = "res://scripts/world/nav.gd"

## Yolların tüketileceği azami derinlik. Gerçek grafik bundan sığ; sınır
## yalnızca bir döngü kalırsa testin sonsuza kadar koşmasını engelliyor.
const MAX_PATH_DEPTH: int = 6

## `_walk` özyinelemesi kökleri bilmek zorunda; Nav çalışma anında load()
## ile geldiği için sabite bağlanamıyor, run() başında dolduruluyor.
var _roots: Array = []

func suite_name() -> String:
	return "Navigation"

func run(t) -> void:
	var nav = load(NAV_PATH)
	nav.reset()
	_roots = []
	for root in nav.ROOTS:
		_roots.append(String(root))

	var edges := _extract_edges(nav)
	t.ok(edges.size() >= 10, "kaynaktan anlamlı sayıda geçiş çıkarıldı (%d)" % edges.size())

	_test_every_edge_returns_to_its_opener(t, nav, edges)
	_test_every_path_unwinds_to_a_root(t, nav, edges)
	_test_back_always_leads_somewhere(t, nav)
	_test_no_screen_opens_itself(t, edges)
	_test_roots_clear_the_stack(t, nav, edges)
	_test_stack_cannot_grow_without_bound(t, nav)
	_test_every_screen_is_reachable(t, nav, edges)
	_test_every_screen_has_an_exit(t, nav)
	_test_labels_never_blank(t, nav)
	_test_exit_buttons_outside_scroll(t)
	_test_node_paths_resolve(t, nav)
	_test_overlay_never_traps_the_player(t)

	nav.reset()

## Yığının tanımlayıcı özelliği: A ekranı B'yi açtıysa, B'den geri basmak
## **A'ya** döner. Eski tek değişkenli modelde bu yalnızca tek seviyede
## doğruydu.
func _test_every_edge_returns_to_its_opener(t, nav, edges: Array) -> void:
	for edge in edges:
		var from: String = edge.from
		var to: String = edge.to
		nav.reset()
		var opened: String = nav.open(from, to)
		t.eq(opened, to, "%s → %s geçişi hedefe gider" % [_short(from), _short(to)])

		# Köke inilmez, gidilir: oraya varmak geçmişi siler, o yüzden
		# "açanına döner" kuralı yalnızca kök olmayan hedefler için geçerli.
		if nav.is_root(to):
			t.eq(nav.depth(), 0, "%s bir kök, geçmişi temizler" % _short(to))
			continue

		t.eq(
			nav.back(), from,
			"%s'den geri basmak %s'e döner" % [_short(to), _short(from)]
		)

## Asıl iddia: kaç seviye derine inilirse inilsin, geri basa basa her zaman
## bir köke varılır ve yığın boşalır. Kilitlenme tam olarak bunun
## olmamasıydı.
func _test_every_path_unwinds_to_a_root(t, nav, edges: Array) -> void:
	var paths := _all_paths(nav, edges)
	t.ok(paths.size() > 0, "kökten çıkan en az bir yol var")

	var deepest := 0
	for path in paths:
		var typed_path: Array = path
		deepest = maxi(deepest, typed_path.size())

		nav.reset()
		for index in range(typed_path.size() - 1):
			nav.open(String(typed_path[index]), String(typed_path[index + 1]))

		# Adım adım geri: her adımda yığın küçülmeli, sonunda kök gelmeli.
		var previous_depth: int = nav.depth()
		var current: String = String(typed_path[typed_path.size() - 1])
		var steps := 0
		while not nav.is_root(current) and steps <= MAX_PATH_DEPTH + 1:
			current = nav.back()
			steps += 1
			t.ok(
				nav.depth() < previous_depth,
				"geri basmak yığını küçültür (%s)" % _short(current)
			)
			previous_depth = nav.depth()

		t.ok(
			nav.is_root(current),
			"%s yolundan geri basa basa köke varılır" % _path_text(typed_path)
		)
		t.eq(nav.depth(), 0, "%s yolu tamamen çözülür" % _path_text(typed_path))

	t.ok(deepest >= 3, "grafik en az üç seviye derinleşiyor (ölçülen %d)" % deepest)

## Yığın boşken bile geri tuşu bir yere götürmeli - "geri" gösterip
## hiçbir şey yapmamak, kilitlenmenin başka bir adı.
func _test_back_always_leads_somewhere(t, nav) -> void:
	nav.reset()
	var landing: String = nav.back()
	t.ok(not landing.is_empty(), "boş yığında geri bir yere götürür")
	t.ok(nav.is_root(landing), "boş yığında geri bir köke götürür")
	t.eq(nav.depth(), 0, "boş yığın eksiye düşmez")

	for _repeat in 5:
		t.ok(nav.is_root(nav.back()), "üst üste geri basmak da köke götürür")

func _test_no_screen_opens_itself(t, edges: Array) -> void:
	for edge in edges:
		t.ok(
			String(edge.from) != String(edge.to),
			"%s kendini açmıyor" % _short(String(edge.from))
		)

## Köke varmak geçmişi siler: oraya "geri" ile dönülmez, gidilir. Yoksa
## şehre vardıktan sonra geri tuşu seni sefere geri gönderirdi.
func _test_roots_clear_the_stack(t, nav, edges: Array) -> void:
	for edge in edges:
		nav.reset()
		nav.open(String(edge.from), String(edge.to))
		nav.go_root(nav.CITY_MAP)
		t.eq(nav.depth(), 0, "köke gitmek yığını temizler")

func _test_stack_cannot_grow_without_bound(t, nav) -> void:
	nav.reset()
	for index in 200:
		nav.open(nav.CITY_MAP, nav.GUILD)
	t.le(
		float(nav.depth()), float(nav.MAX_DEPTH),
		"yığın sınırsız büyümez - bir ekranın kendini itmesi sessiz bir sızıntı olurdu"
	)
	nav.reset()

## Hiçbir ekran yetim kalmamalı: her sahne ya bir kök, ya bir geçişin
## hedefi, ya da bilerek başka türlü girilen bir ekran olmalı.
func _test_every_screen_is_reachable(t, nav, edges: Array) -> void:
	var reachable := {}
	for root in nav.ROOTS:
		reachable[root] = true
	for edge in edges:
		reachable[String(edge.to)] = true

	# Bunlara `open()` ile girilmez: yol ekranı planlayıcının onayından
	# (`go_root`), savaş ekranı ile pazarlık ekranı yalnızca F1 geliştirici
	# panelinden. Gerçek oyunda ikisi de gömülü panel olarak çalışır
	# (`CombatPanel`, `HagglingPanel`), ayrı bir sahne olarak değil.
	var entered_by_flow: Array[String] = [nav.JOURNEY, nav.COMBAT, nav.HAGGLING]

	for scene_path in _scene_paths(nav):
		if entered_by_flow.has(scene_path):
			continue
		t.ok(
			reachable.has(scene_path),
			"%s bir yerden açılabiliyor (yetim ekran yok)" % _short(scene_path)
		)

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

## Geri/çıkış tuşu kaydırma kutusunun dışında durmalı; içeride kalırsa
## içerik uzadıkça ekran dışına itilir (pazar ekranında bir kez yaşandı).
func _test_exit_buttons_outside_scroll(t) -> void:
	var exit_names: Array[String] = ["back_button", "_exit_button", "_start_button"]
	for script_path in _all_screen_scripts():
		var source := _read_code(script_path)
		for button_name in exit_names:
			t.ok(
				not source.contains("_content.add_child(%s)" % button_name),
				"%s: çıkış tuşu kaydırma kutusunun dışında" % script_path
			)

## Ekran script'lerindeki `$A/B` düğüm yolları sahnede gerçekten var mı?
## Godot yanlış bir yolu yalnızca o ekran açıldığında bildirir.
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

# --- Grafiği kaynaktan çıkarma ---

## `Nav.open(Nav.A, Nav.B)` ve `Nav.open_recruit(..., Nav.A)` çağrılarını
## tarar. Elle tutulan bir tablo koddan kayabilir; bu kayamaz.
func _extract_edges(nav) -> Array:
	var constants: Dictionary = nav.get_script_constant_map()
	var edges: Array = []
	var seen := {}

	var open_regex := RegEx.new()
	open_regex.compile("Nav\\.open\\(\\s*Nav\\.([A-Z_]+)\\s*,\\s*Nav\\.([A-Z_]+)\\s*\\)")
	var recruit_regex := RegEx.new()
	recruit_regex.compile("Nav\\.open_recruit\\([^,]+,\\s*Nav\\.([A-Z_]+)\\s*\\)")

	for script_path in _all_screen_scripts():
		var source := _read_code(script_path)
		for found in open_regex.search_all(source):
			_add_edge(edges, seen, constants, found.get_string(1), found.get_string(2))
		for found in recruit_regex.search_all(source):
			_add_edge(edges, seen, constants, found.get_string(1), "RECRUIT")

	# Mekân ekranları tayfa düğmesini `own_scene` değişkeniyle kuruyor, o
	# yüzden regex yalnızca hedefi görüyor; gönderenleri burada tamamlıyoruz.
	for venue in ["ECONOMY", "TAVERN", "GUILD"]:
		_add_edge(edges, seen, constants, venue, "RECRUIT")

	_add_table_driven_edges(edges, seen, constants)
	return edges

## Şehir haritası ve yol ekranı hedefi bir tabloda taşıyıp `Nav.open(Nav.X,
## scene_path)` diye açıyor - hedef sabit değil, değişken. Böyle bir ekranın
## *bahsettiği* her sahne sabiti onun açabileceği bir ekrandır; aksi halde
## şehrin beş mekânı grafikte hiç görünmez ve "yetim ekran yok" kontrolü
## tam da kilitlenmenin yaşandığı yerde kör kalır.
func _add_table_driven_edges(edges: Array, seen: Dictionary, constants: Dictionary) -> void:
	var variable_open := RegEx.new()
	variable_open.compile("Nav\\.open\\(\\s*Nav\\.([A-Z_]+)\\s*,\\s*(?!Nav\\.)")
	var mention := RegEx.new()
	mention.compile("Nav\\.([A-Z_]+)")
	var go_root_call := RegEx.new()
	go_root_call.compile("Nav\\.go_root\\(\\s*Nav\\.([A-Z_]+)\\s*\\)")

	for script_path in _all_screen_scripts():
		var source := _read_code(script_path)
		var sources := variable_open.search_all(source)
		if sources.is_empty():
			continue
		# Tablo bazen ekranın kendi dosyasında değil, kurduğu bileşenin
		# içinde duruyor: şehir haritası mekânları artık `CityView`'dan
		# alıyor. Ekranın *kurduğu* sınıfların kaynağını da tarıyoruz,
		# yoksa beş mekân grafikten düşüyor - ki tam bu oldu, ve test
		# haklı olarak "yetim ekran" dedi. Bahsedilen her `Nav` sabitini
		# bütün dosyalardan toplamak da olmazdı: o zaman her tablo
		# taşıyan ekran her ekranı açıyor sayılırdı.
		source += _component_sources(source)

		# `go_root` ile anılanlar bir geçiş değil, kök atlaması.
		var excluded := {}
		for found in go_root_call.search_all(source):
			excluded[found.get_string(1)] = true

		for opener in sources:
			var from_name := opener.get_string(1)
			for found in mention.search_all(source):
				var to_name := found.get_string(1)
				if to_name == from_name or excluded.has(to_name):
					continue
				if not _is_scene_constant(constants, to_name):
					continue
				_add_edge(edges, seen, constants, from_name, to_name)

func _is_scene_constant(constants: Dictionary, name: String) -> bool:
	if not constants.has(name):
		return false
	var value = constants[name]
	return value is String and String(value).begins_with("res://scenes/")

func _add_edge(edges: Array, seen: Dictionary, constants: Dictionary, from_name: String, to_name: String) -> void:
	if not constants.has(from_name) or not constants.has(to_name):
		return
	var from_path := String(constants[from_name])
	var to_path := String(constants[to_name])
	var key := "%s>%s" % [from_path, to_path]
	if seen.has(key):
		return
	seen[key] = true
	edges.append({"from": from_path, "to": to_path})

## Köklerden başlayarak grafikteki bütün yolları çıkarır (aynı ekranı iki
## kez ziyaret etmeden, yani döngüler sonsuza açılmadan).
func _all_paths(nav, edges: Array) -> Array:
	var out_edges := {}
	for edge in edges:
		var from: String = edge.from
		if not out_edges.has(from):
			out_edges[from] = []
		(out_edges[from] as Array).append(String(edge.to))

	var paths: Array = []
	for root in nav.ROOTS:
		_walk(String(root), [String(root)], out_edges, paths)
	return paths

func _walk(node: String, path: Array, out_edges: Dictionary, paths: Array) -> void:
	if path.size() > 1:
		paths.append(path.duplicate())
	if path.size() >= MAX_PATH_DEPTH:
		return
	for next_node in (out_edges.get(node, []) as Array):
		var next_path: String = String(next_node)
		# Bir köke varmak yolu bitirir - geçmiş orada silinir, derine
		# devam eden bir dal değil.
		if path.has(next_path) or _roots.has(next_path):
			continue
		path.append(next_path)
		_walk(next_path, path, out_edges, paths)
		path.pop_back()

# --- Yardımcılar ---

func _path_text(path: Array) -> String:
	var parts: Array[String] = []
	for entry in path:
		parts.append(_short(String(entry)))
	return " → ".join(parts)

func _short(scene_path: String) -> String:
	return scene_path.get_file().trim_suffix(".tscn")

func _scene_paths(nav) -> Array[String]:
	var paths: Array[String] = []
	var constants: Dictionary = nav.get_script_constant_map()
	for key in constants:
		var value = constants[key]
		if value is String and value.begins_with("res://scenes/"):
			paths.append(value)
	return paths

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

func _dollar_paths(source: String) -> Array[String]:
	var paths: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\$([A-Za-z_][A-Za-z0-9_/]*)")
	for found in regex.search_all(source):
		var path := found.get_string(1)
		if not paths.has(path):
			paths.append(path)
	return paths

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

## Bir ekranın `X.new()` ile kurduğu bileşenlerin kaynağı. Yalnızca
## `scripts/ui` ve `scripts/world` altındaki `class_name`'ler sayılıyor -
## grafiği besleyen tablolar orada duruyor.
func _component_sources(source: String) -> String:
	var instantiation := RegEx.new()
	instantiation.compile("([A-Z][A-Za-z0-9]+)\\.new\\(")
	var classes := {}
	for found in instantiation.search_all(source):
		classes[found.get_string(1)] = true

	var joined := ""
	for script_path in _all_screen_scripts():
		var component := _read_code(script_path)
		var declared := RegEx.new()
		# `(?m)`: `class_name` dosyanın ilk satırı olmak zorunda değil.
		# Çok satır kipi olmadan yalnızca birinci satırda arıyordu ve
		# tesadüfen çalışıyordu - bu depodaki dosyaların hepsinde ilk
		# satır olduğu için.
		declared.compile("(?m)^class_name\\s+([A-Za-z0-9]+)")
		var match_result := declared.search(component)
		if match_result == null:
			continue
		if classes.has(match_result.get_string(1)):
			joined += "\n" + component
	return joined

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


## Tam ekran bir katman da oyuncuyu kilitleyebilir - ve kilitledi.
## `OnboardingPanel` yeni oyunun ilk şehir varışında açılıyor, içeriği
## görüntü alanını aşıyordu ve kapat tuşu altta kalıyordu: oyuncunun ilk
## gördüğü ekran, çıkışı olmayan bir ekrandı.
##
## Buradaki kural ekranların kaydırma kuralının aynısı (bkz. World
## Navigation Rules) - yalnızca bir ekrana değil bir katmana uygulanıyor,
## o yüzden kimse uygulamamıştı. Taşma taşmadır.
##
## Bu paket ağaç canlı değilken koştuğu için `_ready()` kendiliğinden
## çalışmaz; inşayı testin kendisi tetikliyor.
const OVERLAY_PATH: String = "res://scripts/ui/onboarding_panel.gd"
## project.godot'un tasarım yüksekliği. Panel bunu aşarsa oyuncu alt
## kısmına hiçbir pencere boyutunda ulaşamaz (stretch mode canvas_layers,
## yani tasarım alanı pencereye ölçekleniyor).
const DESIGN_HEIGHT: float = 1080.0

func _test_overlay_never_traps_the_player(t) -> void:
	var script = load(OVERLAY_PATH)
	t.ok(script != null, "onboarding katmanı yüklenebiliyor")
	if script == null:
		return

	var overlay = script.new()
	overlay._ready()

	var scrolls := _descendants_of_class(overlay, "ScrollContainer")
	t.eq(scrolls.size(), 1, "katmanın uzayabilen içeriği bir ScrollContainer'da")

	var buttons := _descendants_of_class(overlay, "Button")
	t.ok(buttons.size() >= 1, "katmanı kapatan bir tuş var")
	for button in buttons:
		t.not_ok(
			_has_ancestor_of_class(button, "ScrollContainer"),
			"kapat tuşu kaydırma alanının dışında - içinde kalırsa içerik onu ekrandan atar"
		)

	# Panelin kendi asgari boyu tasarım alanına sığmalı: ScrollContainer'ın
	# asgarisi içeriğini saymadığı için bu, içerik ne kadar uzarsa uzasın
	# sabit kalır. Sığmazsa kapat tuşu yine erişilemez olur.
	#
	# Bu kontrolün *göremediği* şey kaydedilmeye değer, çünkü asıl hata
	# oradan geldi: sarmalanan bir `Label`'ın asgari yüksekliği düzen
	# geçişi olmadan tek satırdır (sarma, bilinmeyen genişliğe bağlı), o
	# yüzden eski panelin taşması bu ölçüme hiç yansımıyordu - mutasyon
	# denemesinde ateşlenen üç doğrulama aşağıdaki yapısal olanlardı, bu
	# değil. Yani bu satır yalnızca sabit boyların büyümesini yakalar;
	# metin taşmasına karşı gerçek koruma "içerik kaydırmada, tuş dışında"
	# yapısıdır - onunla birlikte sarma ne kadar uzarsa uzasın tuşu
	# ekrandan atamaz.
	for panel in _descendants_of_class(overlay, "PanelContainer"):
		var needed: float = panel.get_combined_minimum_size().y
		t.ok(
			needed <= DESIGN_HEIGHT,
			"katman tasarım yüksekliğine sığıyor (%d <= %d)" % [int(needed), int(DESIGN_HEIGHT)]
		)

	# Tuş tek çıkış yolu olmamalı: oyuncunun ilk refleksi kenara tıklamak.
	t.ok(
		overlay.has_method("_on_backdrop_input"),
		"perdeye tıklamak da kapatıyor"
	)
	t.ok(overlay.has_method("_unhandled_input"), "Esc de kapatıyor")

	overlay.free()

func _descendants_of_class(node: Node, cls: String) -> Array:
	var found := []
	for child in node.get_children():
		if child.is_class(cls):
			found.append(child)
		found.append_array(_descendants_of_class(child, cls))
	return found

func _has_ancestor_of_class(node: Node, cls: String) -> bool:
	var parent := node.get_parent()
	while parent != null:
		if parent.is_class(cls):
			return true
		parent = parent.get_parent()
	return false
