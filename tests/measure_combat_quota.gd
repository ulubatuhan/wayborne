extends SceneTree

## Dövüş garantisinin ölçümü (kullanıcı kararı 2026-11-07). **Test değil** -
## sayı basar: kaç seferde yol kesildi, kaçıncı günde, ve muaf bölgelerde
## gerçekten kesilmiyor mu.
##
##   godot --headless --script res://tests/measure_combat_quota.gd
##
## Oyuncu politikası: kart dövüşe açılıyorsa **ilk açık seçenek** seçilir
## (yani çoğu kartta "öde/ver"), ki garanti "oyuncu dövüşü seçtiği için"
## değil, sistem yolu kestiği için tutsun.

const RUNS: int = 120
const ROUTES: Array = [
	# [çıkış, varış, gün, beklenti]
	["liraven", "ondrelle", 3, true],
	["liraven", "ondrelle", 8, true],
	["vastrevar", "dravoss", 4, false],
	["vastrevar", "tolvarin", 5, true],
	["liraven", "orvahel", 6, false],
	["liraven", "serai_orbeyan", 6, false],
]

## Hangi kart yolu kesti (yeni kartlar gerçekten çıkıyor mu).
var _raid_cards: Dictionary = {}

func _init() -> void:
	print("── Dövüş garantisi (%d koşu/yol)" % RUNS)
	var failures := 0
	for row in ROUTES:
		var leg: Array = row
		var raided := 0
		var first_days: Array[int] = []
		for run in RUNS:
			var day := _run_leg(String(leg[0]), String(leg[1]), int(leg[2]), run)
			if day > 0:
				raided += 1
				first_days.append(day)
		var share := float(raided) / float(RUNS)
		var average := 0.0
		for day in first_days:
			average += float(day)
		average = average / float(maxi(1, first_days.size()))
		var expected: bool = bool(leg[3])
		var verdict := "—"
		if expected and share < 1.0:
			verdict = "✗ GARANTİ TUTMADI"
			failures += 1
		elif expected:
			verdict = "✓"
		elif share > 0.0:
			verdict = "muaf (yine de %d koşuda çıktı, bu normal: muafiyet garantiyi kaldırır, kartı yasaklamaz)" % raided
		else:
			verdict = "muaf, hiç çıkmadı"
		print("  %-10s → %-14s %d gün · yol kesildi %%%3d · ilk gün ort. %.1f · %s" % [
			leg[0], leg[1], int(leg[2]), int(round(share * 100.0)), average, verdict,
		])
	print("── %s" % ("tamam" if failures == 0 else "%d yolda garanti tutmadı" % failures))
	print("── Yolu kesen kartlar")
	var ids: Array = _raid_cards.keys()
	ids.sort_custom(func(a, b): return int(_raid_cards[a]) > int(_raid_cards[b]))
	for id in ids:
		print("  %-26s %d" % [id, int(_raid_cards[id])])
	quit()

## Tek bir seferi gün gün yürütür; yolu kesen kartın geldiği günü döner
## (gelmezse 0).
func _run_leg(origin: String, destination: String, days: int, run: int) -> int:
	var session := GameSession.new(600, 60, 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + run
	session.start_playthrough(
		CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng
	)
	session.current_location_id = origin
	var place := WorldMapData.get_location_by_id(destination)
	session.start_journey(destination, days, 0.45, CaravanPlan.new(place, days))
	# Yük seferden SONRA konuyor: `start_journey` kervanı plandan yeniden
	# kuruyor, önce konan yük siliniyor - ilk ölçüm bu yüzden "mal ver"
	# kartlarını hiç göremedi.
	for item_id in ["test_grain", "honey", "test_cloth"]:
		var item := ItemCatalog.get_item(String(item_id))
		if item != null:
			session.add_to_cargo_or_bag(item, 6)

	var engine := EventEngine.new(EventCatalog.get_road_events(), 7000 + run)
	engine.director = RoadDirector.new()
	for day in days:
		session.journey_days_remaining = days - day
		var context := session.build_event_context()
		var event := engine.roll_for_day(session.total_days_elapsed + day, context)
		if event == null:
			continue
		engine.mark_fired(event, session.total_days_elapsed + day)
		var faced := RoadDirector.can_fight(event)
		var choice := _first_open_choice(event, context)
		if choice != null:
			EventResolver.resolve_choice(session, engine, event, choice)
		if faced:
			_raid_cards[event.event_id] = int(_raid_cards.get(event.event_id, 0)) + 1
			return day + 1
	return 0

func _first_open_choice(event: GameEvent, context: Dictionary) -> EventChoice:
	for choice in event.choices:
		if choice.is_available(context):
			return choice
	return null
