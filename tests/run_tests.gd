extends SceneTree

## Headless test koşucusu. Eklenti kullanmaz:
##
##   godot --headless --script res://tests/run_tests.gd
##
## Başarısızlıkta çıkış kodu 1 döner, böylece CI kırmızıya döner.
##
## Bu dosya bilerek hiçbir class_name'e başvurmuyor - autoload'lardaki
## ayrıştırma sırası tuzağının aynısına düşmemek için (bkz. CLAUDE.md).
## Paketler load() ile çalışma anında kuruluyor; onların içinde class_name
## serbest, çünkü o noktada global sınıf önbelleği hazır.

const REPORTER_PATH: String = "res://tests/test_reporter.gd"

const SUITE_PATHS: Array[String] = [
	"res://tests/test_character_stats.gd",
	"res://tests/test_culture.gd",
	"res://tests/test_character_data.gd",
	"res://tests/test_combat.gd",
	"res://tests/test_event_engine.gd",
	"res://tests/test_event_effects.gd",
	"res://tests/test_game_session.gd",
	"res://tests/test_progression.gd",
	"res://tests/test_duties.gd",
	"res://tests/test_save_migration.gd",
	"res://tests/test_localization.gd",
	"res://tests/test_journey_clock.gd",
	"res://tests/test_debt.gd",
	"res://tests/test_market_conditions.gd",
	"res://tests/test_haggling.gd",
	"res://tests/test_route_conditions.gd",
	"res://tests/test_morale.gd",
	"res://tests/test_recruit_catalog.gd",
	"res://tests/test_traits.gd",
	"res://tests/test_stress.gd",
	"res://tests/test_equipment.gd",
	"res://tests/test_world_map_data.gd",
	"res://tests/test_enemy_variety.gd",
]

## Katalog metinleri artık çeviri anahtarı taşıyor ve display_name gibi
## alanlar o anki dile göre çözülüyor (bkz. CLAUDE.md Localization Rules).
## Dil sabitlenmezse testler koşulduğu makinenin diline göre farklı sonuç
## verirdi - kaynak dil Türkçe olduğu için ona sabitliyoruz.
const TEST_LOCALE: String = "tr"

func _initialize() -> void:
	TranslationServer.set_locale(TEST_LOCALE)
	print("── Wayborne test koşusu")

	var reporter = load(REPORTER_PATH).new()
	var missing: Array[String] = []

	for suite_path in SUITE_PATHS:
		if not ResourceLoader.exists(suite_path):
			missing.append(suite_path)
			continue

		var suite = load(suite_path).new()
		reporter.begin_suite(suite.suite_name())
		suite.run(reporter)
		print(reporter.end_suite())

	for suite_path in missing:
		print("  ! paket bulunamadı: %s" % suite_path)

	if not reporter.failures.is_empty():
		print("")
		print("── Kalanlar")
		for failure in reporter.failures:
			print("  ✗ %s" % failure)

	print("")
	print("── %d geçti, %d kaldı" % [reporter.passed, reporter.failed])

	# reporter çalışma anında load() ile geldiği için Variant; ondan
	# türeyen ifadede `:=` çıkarım yapamaz (bkz. city_map.gd hatası).
	var has_error: bool = reporter.failed > 0 or not missing.is_empty()
	quit(1 if has_error else 0)

## quit() ana döngüyü bir sonraki karede kapatır; işi _initialize'da
## bitirdiğimiz için burada beklemeye gerek yok. true dönmek döngüyü
## kapatır, quit()'in verdiği çıkış kodunu değiştirmez.
func _process(_delta: float) -> bool:
	return true
