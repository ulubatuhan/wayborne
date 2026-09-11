extends RefCounted

## Çeviri altyapısının sözleşmesi. Dil eklemek üç yeri birden ilgilendiriyor
## (UserSettings.SUPPORTED, her CSV'nin sütunları, project.godot'un
## locale/translations dizisi) ve üçü ayrışırsa oyun sessizce bozuk dille
## açılır - bu paket o ayrışmaya izin vermiyor.
##
## Burada bilerek class_name kullanılmıyor (bkz. CLAUDE.md Testing) ve
## UserSettings'e autoload olarak değil dosyadan okunarak erişiliyor: test
## koşucusu SceneTree betiği, autoload'lar orada kurulmuyor.

const LOCALE_DIR: String = "res://data/locale"
const CSV_NAMES: Array[String] = ["ui", "events", "game"]
const USER_SETTINGS_PATH: String = "res://scripts/autoload/user_settings.gd"

## Boş bırakılan hücreler bu dile düşüyor, o yüzden ikisi her satırda dolu
## olmalı (bkz. UserSettings.FALLBACK_LOCALE).
const REQUIRED_LOCALES: Array[String] = ["tr", "en"]

func suite_name() -> String:
	return "Localization"

func run(t) -> void:
	var locales := _supported_locales()
	t.ok(locales.size() >= 2, "en az iki dil tanımlı")

	_test_csv_columns_match_supported(t, locales)
	_test_required_locales_are_filled(t)
	_test_project_godot_lists_every_translation(t, locales)
	_test_no_duplicate_keys(t)
	_test_placeholders_match_across_locales(t)
	_test_every_referenced_key_exists(t)
	_test_no_hardcoded_prose_in_screens(t)
	_test_no_hardcoded_prose_in_scenes(t)
	_test_scene_keys_are_defined(t)

func _supported_locales() -> Array:
	var script = load(USER_SETTINGS_PATH)
	var settings = script.new()
	var codes: Array = settings.get_locale_codes()
	return codes

func _read_csv(csv_name: String) -> Array:
	var file := FileAccess.open("%s/%s.csv" % [LOCALE_DIR, csv_name], FileAccess.READ)
	if file == null:
		return []
	var rows: Array = []
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() > 1 or (line.size() == 1 and not line[0].is_empty()):
			rows.append(line)
	file.close()
	return rows

## Sütun başlıkları desteklenen dillerle birebir aynı olmalı: eksik sütun
## o dilin hiç yüklenmemesi, fazla sütun ise kimsenin görmediği bir çeviri
## demek.
func _test_csv_columns_match_supported(t, locales: Array) -> void:
	for csv_name in CSV_NAMES:
		var rows := _read_csv(csv_name)
		t.ok(rows.size() > 0, "%s.csv okunabiliyor" % csv_name)
		if rows.is_empty():
			continue

		var header: Array = []
		for cell in rows[0]:
			header.append(cell)
		t.eq(header[0], "keys", "%s.csv ilk sütunu 'keys'" % csv_name)

		var columns := header.slice(1)
		t.eq(
			columns, locales,
			"%s.csv sütunları UserSettings.SUPPORTED ile aynı ve aynı sırada" % csv_name
		)

## tr ve en her satırda dolu olmalı - en fallback, tr kaynak dil.
func _test_required_locales_are_filled(t) -> void:
	for csv_name in CSV_NAMES:
		var rows := _read_csv(csv_name)
		if rows.size() < 2:
			continue
		var header: Array = rows[0]
		for locale in REQUIRED_LOCALES:
			var column := header.find(locale)
			if column < 0:
				continue
			var missing: Array[String] = []
			for i in range(1, rows.size()):
				var row: Array = rows[i]
				if column >= row.size() or str(row[column]).strip_edges().is_empty():
					missing.append(str(row[0]))
			t.eq(
				missing.size(), 0,
				"%s.csv içinde '%s' boş bırakılmamış (boş olanlar: %s)" % [
					csv_name, locale, ", ".join(missing.slice(0, 5))
				]
			)

## project.godot her CSV × her dil için bir .translation yolu saymalı;
## biri unutulursa o dil çalışma anında sessizce yüklenmez.
func _test_project_godot_lists_every_translation(t, locales: Array) -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	t.ok(file != null, "project.godot okunabiliyor")
	if file == null:
		return
	var text := file.get_as_text()
	file.close()

	var missing: Array[String] = []
	for csv_name in CSV_NAMES:
		for locale in locales:
			var path := "res://data/locale/%s.%s.translation" % [csv_name, locale]
			if not text.contains(path):
				missing.append("%s.%s" % [csv_name, locale])
	t.eq(
		missing.size(), 0,
		"project.godot her dil/dosya çiftini listeliyor (eksik: %s)" % ", ".join(missing.slice(0, 5))
	)

	t.ok(text.contains('locale/fallback="en"'), "fallback dili İngilizce olarak ayarlı")

## Aynı anahtar iki dosyada tanımlıysa hangisinin kazandığı yükleme
## sırasına kalır - sessiz ve izi zor sürülen bir hata.
func _test_no_duplicate_keys(t) -> void:
	var seen: Dictionary = {}
	var duplicates: Array[String] = []
	for csv_name in CSV_NAMES:
		var rows := _read_csv(csv_name)
		for i in range(1, rows.size()):
			var key := str(rows[i][0])
			if seen.has(key):
				duplicates.append("%s (%s ve %s)" % [key, seen[key], csv_name])
			else:
				seen[key] = csv_name
	t.eq(
		duplicates.size(), 0,
		"anahtarlar dosyalar arasında benzersiz (çakışan: %s)" % ", ".join(duplicates.slice(0, 5))
	)

## Bir çeviri, kaynak metinle **aynı biçim argümanlarını aynı sırada**
## taşımak zorunda. GDScript'in % operatörü konumlu argüman ("%2$s")
## desteklemiyor, yani bir çevirmen sırayı değiştirirse ya da bir %d'yi
## düşürürse oyun o satırı bastığı anda çöker - üstelik yalnızca o dilde,
## yani test etmeyen kimse görmez. Kaçış olan %% argüman sayılmaz.
func _test_placeholders_match_across_locales(t) -> void:
	var mismatches: Array[String] = []
	for csv_name in CSV_NAMES:
		var rows := _read_csv(csv_name)
		if rows.size() < 2:
			continue
		var header: Array = rows[0]
		for i in range(1, rows.size()):
			var row: Array = rows[i]
			var key := str(row[0])
			var source := _placeholders(str(row[1]))
			for column in range(2, mini(header.size(), row.size())):
				var value := str(row[column]).strip_edges()
				if value.is_empty():
					continue
				if _placeholders(value) != source:
					mismatches.append("%s[%s]" % [key, str(header[column])])
	t.eq(
		mismatches.size(), 0,
		"her çeviri kaynakla aynı biçim argümanlarını taşıyor (bozuk: %s)"
			% ", ".join(mismatches.slice(0, 5))
	)

## "%d", "%s", "%.1f", "%+d" gibi argümanlar; "%%" kaçışı atlanır.
## GDScript'in desteklediği dönüşüm karakterleri.
const CONVERSIONS: String = "difsxXoc"


func _placeholders(text: String) -> Array[String]:
	var found: Array[String] = []
	var index := 0
	while index < text.length():
		if text[index] != "%":
			index += 1
			continue
		var cursor := index + 1
		if cursor < text.length() and text[cursor] == "%":
			index = cursor + 1
			continue
		# Boşluk bilerek yok: printf'te geçerli bir bayrak ama pratikte
		# "%15 fazla" / "10% discount" gibi düz yüzde ifadelerini argüman
		# sanmamıza yol açıyordu.
		while cursor < text.length() and "+-#0123456789.".contains(text[cursor]):
			cursor += 1
		# Gerçek bir biçim argümanı bir dönüşüm karakteriyle biter. Bu kontrol
		# olmadan "%30 az" gibi düz bir yüzde ifadesi argüman sanılıyordu -
		# Türkçe metin sahte bir yer tutucu taşıyor, İngilizcesi ("30% less")
		# taşımıyor görünüyordu.
		if cursor < text.length() and CONVERSIONS.contains(text[cursor]):
			found.append("%" + text[cursor])
			index = cursor + 1
		else:
			index = maxi(cursor, index + 1)
	return found

## Koddan çağrılan her anahtar bir CSV'de tanımlı olmalı. Tanımsız anahtar
## Godot'ta hata vermez - ekrana anahtarın kendisi basılır ("UI_MARKET_BUY"
## yazan bir düğme), yani yalnızca o ekranı açan görür.
func _test_every_referenced_key_exists(t) -> void:
	var defined := _all_keys()
	var missing: Array[String] = []
	for path in _screen_scripts():
		var text := _read_text(path)
		for key in _referenced_keys(text):
			if not defined.has(key) and not missing.has(key):
				missing.append(key)
	t.eq(
		missing.size(), 0,
		"koddaki her çeviri anahtarı tanımlı (eksik: %s)" % ", ".join(missing.slice(0, 5))
	)

## Ekran katmanında sabit Türkçe metin kalmamalı. Türkçeye özgü harf
## taşıyan bir dizeyi yakalıyor - kusursuz değil ama gerilemeyi yakalar:
## yeni bir ekran metnini anahtara bağlamayı unutmak sessizce o metni
## tek dile çiviler.
func _test_no_hardcoded_prose_in_screens(t) -> void:
	var offenders: Array[String] = []
	for path in _screen_scripts():
		if PROSE_EXEMPT_SCRIPTS.has(path.get_file()):
			continue
		for line in _read_text(path).split("\n"):
			var stripped := line.strip_edges()
			if stripped.begins_with("#"):
				continue
			for literal in _string_literals(stripped):
				if _has_turkish_letter(literal):
					offenders.append("%s: %s" % [path.get_file(), literal.substr(0, 32)])
	t.eq(
		offenders.size(), 0,
		"ekranlarda sabit Türkçe metin yok (kalanlar: %s)" % ", ".join(offenders.slice(0, 5))
	)

func _has_turkish_letter(text: String) -> bool:
	for letter in ["ğ", "ü", "ş", "ı", "ö", "ç", "Ğ", "Ü", "Ş", "İ", "Ö", "Ç"]:
		if text.contains(letter):
			return true
	return false

func _string_literals(line: String) -> Array[String]:
	var found: Array[String] = []
	var parts := line.split('"')
	# Tırnaklar arasındaki her ikinci parça bir dize gövdesi.
	for index in range(1, parts.size(), 2):
		found.append(parts[index])
	return found

## `tr("X")` ve `TranslationServer.translate("X")` çağrılarındaki anahtarlar.
func _referenced_keys(text: String) -> Array[String]:
	var found: Array[String] = []
	# Kaynak diziye açık tip verilmezse döngü değişkeni Variant'a düşer ve
	# `:=` çıkarım yapamaz (bkz. CLAUDE.md `:=` / Variant tuzağı).
	var markers: Array[String] = ['tr("', 'translate("']
	for marker in markers:
		var from := 0
		while true:
			var start := text.find(marker, from)
			if start < 0:
				break
			var key_start := start + marker.length()
			var key_end := text.find('"', key_start)
			if key_end < 0:
				break
			var key := text.substr(key_start, key_end - key_start)
			if not key.is_empty() and not found.has(key):
				found.append(key)
			from = key_end
	return found

func _all_keys() -> Dictionary:
	var keys: Dictionary = {}
	for csv_name in CSV_NAMES:
		var rows := _read_csv(csv_name)
		for i in range(1, rows.size()):
			keys[str(rows[i][0])] = true
	return keys

## Oyuncuya metin gösterebilen her katman. Başta yalnızca ui/world
## taranıyordu ve bu gerçek bir boşluk bıraktı: savaş günlüğü
## (combat_encounter.gd), olay etki satırları (event_effect_applier.gd),
## kültür perk açıklamaları ve ekipman slot adları da oyuncuya görünüyor
## ama taramanın dışındaydı, yani Türkçeye çivili kalmışlardı.
##
## F1 geliştirici sahneleri (haggling/combat test ekranı) bilerek dışarıda:
## oyuna girmiyorlar, çevrilmeleri çevirmene boşuna iş çıkarırdı.
const SCREEN_DIRS: Array[String] = [
	"res://scripts/ui",
	"res://scripts/world",
	"res://scripts/combat",
	"res://scripts/events",
	"res://scripts/economy",
	"res://scripts/travel",
	"res://scripts/character",
	"res://scripts/autoload",
]

## İsim havuzları ve id'ler: özel isimler çevrilmez, çevrilmemeli.
## Dil adları bilerek çevrilmez: dil seçici her dili **kendi dilinde**
## gösterir, yoksa aradığı dili bulamayan oyuncu seçemez.
const PROSE_EXEMPT_SCRIPTS: Array[String] = [
	"culture_catalog.gd", "recruit_catalog.gd", "user_settings.gd",
]
const DEV_ONLY_SCRIPTS: Array[String] = ["haggling.gd", "combat_test.gd", "test_selector.gd"]

func _screen_scripts() -> Array[String]:
	var paths: Array[String] = []
	for directory in SCREEN_DIRS:
		var names := DirAccess.get_files_at(directory)
		if names == null:
			continue
		for name in names:
			if not name.ends_with(".gd") or DEV_ONLY_SCRIPTS.has(name):
				continue
			paths.append("%s/%s" % [directory, name])
	return paths

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text

## Metin taraması yalnızca `scripts/`'e bakıyordu, ve bu gerçek bir gediği
## sakladı: `.tscn` dosyalarındaki statik etiketler (pazar başlığı, kilise
## açıklaması, "Partiyi Görüntüle" tuşu...) hiçbir zaman çevrilmiyordu.
## Ekranın `_ready()`'si o düğümün yazısını anahtarla atamazsa, sahnedeki
## Türkçe olduğu gibi kalıyor - on bir dilin onunda.
##
## Kural basit ve makineyle denetlenebilir: sahne dosyasındaki hiçbir
## `text = "..."` Türkçeye özgü harf taşımasın. Böyle bir yazı ya koddan
## atanmıyordur (hata) ya da atanıyordur ama sahnedeki kopya yanıltıcıdır -
## iki durumda da sahneden temizlenmesi doğrusu.
func _test_no_hardcoded_prose_in_scenes(t) -> void:
	var turkish := RegEx.new()
	turkish.compile("[şŞıİğĞüÜöÖçÇ]")
	var text_line := RegEx.new()
	text_line.compile('^text = "(.*)"$')

	for scene_path in _scene_files():
		var source := _read_text(scene_path)
		for line in source.split("\n"):
			var found := text_line.search(line)
			if found == null:
				continue
			var value := found.get_string(1)
			t.ok(
				turkish.search(value) == null,
				"%s: sahnedeki yazı koddan anahtarla gelmeli, sahnede sabit değil (\"%s\")" % [
					scene_path, value.substr(0, 40)
				]
			)

## F1 geliştirici ekranları oyuncuya hiç ulaşmaz (bkz. DEV_ONLY_SCRIPTS),
## oyunun adı da her dilde aynı kalır.
const SCENE_EXEMPT: Array[String] = [
	"res://scenes/game/combat.tscn",
	"res://scenes/ui/test_selector.tscn",
	"res://scenes/game/haggling.tscn",
]

func _scene_files() -> Array[String]:
	var found: Array[String] = []
	_collect_scenes("res://scenes", found)
	return found

func _collect_scenes(directory: String, found: Array[String]) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	for name in dir.get_files():
		if not name.ends_with(".tscn"):
			continue
		var path := "%s/%s" % [directory, name]
		if not SCENE_EXEMPT.has(path):
			found.append(path)
	for name in dir.get_directories():
		_collect_scenes("%s/%s" % [directory, name], found)

## Sahneler artık Türkçe yerine **anahtar** taşıyor, ama tanımsız bir
## anahtar aynı sessiz hata: ekranda "UI_MARKET_SHOP" yazar ve bunu yalnızca
## o ekranı açan görür. Sahnedeki her anahtar bir CSV'de tanımlı olmalı.
func _test_scene_keys_are_defined(t) -> void:
	var defined := _all_keys()
	var key_shape := RegEx.new()
	key_shape.compile("^[A-Z][A-Z0-9_]+$")
	var text_line := RegEx.new()
	text_line.compile('^text = "(.*)"$')

	for scene_path in _scene_files():
		for line in _read_text(scene_path).split("\n"):
			var found := text_line.search(line)
			if found == null:
				continue
			var value := found.get_string(1)
			if key_shape.search(value) == null or SCENE_TEXT_NOT_A_KEY.has(value):
				continue
			t.ok(
				defined.has(value),
				"%s: sahnedeki anahtar tanımlı (%s)" % [scene_path.get_file(), value]
			)

## Anahtar biçimine uyan ama anahtar olmayan tek metin: oyunun kendi adı.
## Özel isim, her dilde aynı kalır.
const SCENE_TEXT_NOT_A_KEY: Array[String] = ["WAYBORNE"]
