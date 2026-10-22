extends RefCounted

## Şehrin gün evresi resmi (görevler 9.3, N33) ve ses çeşidi seçimi (N31c).

const PHASED: Array[String] = [
	"akavan", "auderin", "belvanor", "brazdun", "caramine", "dravoss", "ezmerak", "golcavar", "ilsande",
	"kesgrav", "kirsavel", "liraven", "merigaud", "mirsana", "ondrelle", "orsolune", "orvahel", "rivecande",
	"samuran", "selvicar", "serai_duvenmor", "serai_orbeyan", "serai_seyvan", "tolvarin", "vastrevar",
	"vorgat", "zelmarin",
]

func suite_name() -> String:
	return "PhasesAudio"

func run(t) -> void:
	_test_every_settlement_has_its_phases(t)
	_test_background_path_by_hour(t)
	_test_variant_never_repeats(t)
	_test_beat_log(t)
	_test_road_ambience_table(t)

func _test_every_settlement_has_its_phases(t) -> void:
	for city in PHASED:
		for phase in ["morning", "day", "evening"]:
			var path: String = CityFront.TOWNS_DIR + city + "/background_%s.jpg" % phase
			t.ok(ResourceLoader.exists(path) or FileAccess.file_exists(path), "%s %s resmi var" % [city, phase])

func _test_background_path_by_hour(t) -> void:
	var base := CityFront.TOWNS_DIR + "vastrevar/"
	t.eq(CityFront.background_path("vastrevar", 6.0), base + "background_morning.jpg", "şafak sabah resmi")
	t.eq(CityFront.background_path("vastrevar", 12.0), base + "background_day.jpg", "öğle gündüz resmi")
	t.eq(CityFront.background_path("vastrevar", 15.5), base + "background_day.jpg", "ikindi gündüz resmi")
	t.eq(CityFront.background_path("vastrevar", 18.0), base + "background_evening.jpg", "akşam resmi")
	t.eq(CityFront.background_path("vastrevar", 23.0), base + "background.jpg", "gece taban resim")
	t.eq(CityFront.background_path("vastrevar", 2.0), base + "background.jpg", "gece yarısından sonra taban")
	t.eq(CityFront.background_path("tavern", 12.0), CityFront.TOWNS_DIR + "tavern/background.jpg",
		"evre resmi olmayan yer taban resmine düşer")

func _test_variant_never_repeats(t) -> void:
	var audio: Script = load("res://scripts/autoload/audio_manager.gd")
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for count in [2, 3, 5]:
		var last := -1
		var seen := {}
		for roll in 200:
			var pick: int = audio.pick_variant(count, last, rng.randi())
			t.ok(pick >= 0 and pick < count, "çeşit aralıkta")
			t.ok(pick != last, "aynı çeşit arka arkaya gelmez (%d çeşit)" % count)
			seen[pick] = true
			last = pick
		t.eq(seen.size(), count, "%d çeşidin hepsi çalınıyor" % count)
	t.eq(audio.pick_variant(1, 0, 5), 0, "tek çeşit hep aynı")

## N31a: beat satırı oyun saniyesini ve türü taşır; testler dosyaya yazmaz.
func _test_beat_log(t) -> void:
	var session := GameSession.new(100, 10)
	session.caravan_name = "Deneme"
	session.play_seconds = 12.34
	var line := session.beat_log_line(GameSession.BEAT_LOG_DECISION, "card:evt_x")
	t.eq(line.t, 12.3, "saniye onda bire yuvarlanır")
	t.eq(String(line.kind), "decision", "tür")
	t.eq(String(line.caravan), "Deneme", "kervan adı")
	var before := FileAccess.file_exists(GameSession.PLAYTEST_BEATS)
	var size_before := FileAccess.get_file_as_bytes(GameSession.PLAYTEST_BEATS).size() if before else 0
	session.log_beat(GameSession.BEAT_LOG_INFO, "x")
	var size_after := FileAccess.get_file_as_bytes(GameSession.PLAYTEST_BEATS).size() if FileAccess.file_exists(GameSession.PLAYTEST_BEATS) else 0
	t.eq(size_after, size_before, "gerçek oyun dışında dosyaya yazılmaz")

## N31f: kampta ateş, sert havada rüzgâr, açık gündüz sessiz, gece ıssız rüzgâr.
func _test_road_ambience_table(t) -> void:
	var audio: Script = load("res://scripts/autoload/audio_manager.gd")
	t.eq(audio.road_ambience_for(RouteWeather.CLEAR, false, true), audio.AMBIENCE_FIRE, "kampta ateş")
	t.eq(audio.road_ambience_for(RouteWeather.STORM, false, false), audio.AMBIENCE_WIND, "fırtınada rüzgâr")
	t.eq(audio.road_ambience_for(RouteWeather.CLEAR, false, false), "", "açık gündüz yalnızca müzik")
	t.eq(audio.road_ambience_for(RouteWeather.CLEAR, true, false), audio.AMBIENCE_WIND, "açık gece rüzgâr")
	for weather in audio.ROAD_AMBIENCE:
		t.ok(audio.AMBIENCE_PATHS.has(String(audio.ROAD_AMBIENCE[weather])), "%s katmanının dosyası tanımlı" % weather)
