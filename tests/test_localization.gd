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
