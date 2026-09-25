extends RefCounted

## JourneyClock sefer zamanının tek kaynağı: gün mekaniği (erzak, kontrat,
## olay) hâlâ gün başına işliyor ama günü artık bu saat sayıyor. İki şey
## kritik: bir gün asla iki kez işlenmemeli ve hiçbir gün atlanmamalı -
## 3x hızda ya da uzun bir olaydan sonra bir karede birden fazla gün
## geçebiliyor.

func suite_name() -> String:
	return "JourneyClock"

func run(t) -> void:
	_test_speed_selection(t)
	_test_camp_speed_index(t)
	_test_advance_converts_real_time(t)
	_test_days_reported_once_and_never_skipped(t)
	_test_consumed_hours_count_as_time(t)
	_test_phases(t)
	_test_phase_progress(t)
	_test_camp_window(t)
	_test_save_round_trip(t)
	_test_arrival_hour_colours_the_city(t)

func _test_speed_selection(t) -> void:
	var clock := JourneyClock.new()
	t.eq(clock.get_speed(), 1.0, "varsayılan hız 1x")

	# 0.5x kampın kendi hızı: dizinin başında duruyor, varsayılan seçim
	# yine 1x (bkz. DEFAULT_SPEED_INDEX) - 0.5 eklenmesi normal yürüyüşün
	# varsayılanını değiştirmemeli.
	clock.cycle_speed()
	t.eq(clock.get_speed(), 1.5, "sonraki hız 1.5x")
	clock.cycle_speed()
	t.eq(clock.get_speed(), 3.0, "sonraki hız 3x")
	clock.cycle_speed()
	t.eq(clock.get_speed(), 0.5, "3x'ten sonraki hız 0.5x - dizi başa dönmeden önce en yavaşa uğrar")
	clock.cycle_speed()
	t.eq(clock.get_speed(), 1.0, "hız başa döner")

	clock.set_speed_index(99)
	t.eq(clock.get_speed(), 3.0, "aralık dışı indeks son hıza kenetlenir")
	clock.set_speed_index(-5)
	t.eq(clock.get_speed(), 0.5, "negatif indeks ilk hıza kenetlenir")

func _test_camp_speed_index(t) -> void:
	var clock := JourneyClock.new()
	t.eq(
		clock.SPEEDS[clock.camp_speed_index()], 0.5,
		"kampın önerdiği hız 0.5x - dizide nerede durduğuna bakmaksızın"
	)

func _test_advance_converts_real_time(t) -> void:
	var clock := JourneyClock.new()
	var start := clock.total_hours

	# Bir günlük gerçek süre, 1x hızda tam bir oyun günü etmeli.
	clock.advance(JourneyClock.REAL_SECONDS_PER_DAY)
	t.ok(
		is_equal_approx(clock.total_hours - start, JourneyClock.HOURS_PER_DAY),
		"1x'te bir gün gerçek süre bir oyun günü eder"
	)

	var fast := JourneyClock.new()
	fast.set_speed_index(JourneyClock.SPEEDS.find(3.0))
	fast.advance(JourneyClock.REAL_SECONDS_PER_DAY)
	t.ok(
		is_equal_approx(fast.total_hours - JourneyClock.START_HOUR, JourneyClock.HOURS_PER_DAY * 3.0),
		"3x'te aynı süre üç oyun günü eder"
	)

	t.eq(clock.advance(0.0), 0.0, "sıfır delta zamanı ilerletmez")
	t.eq(clock.advance(-5.0), 0.0, "negatif delta zamanı geri almaz")

func _test_days_reported_once_and_never_skipped(t) -> void:
	var clock := JourneyClock.new()
	t.eq(clock.take_elapsed_days(), 0, "başlangıçta işlenecek gün yok")

	# Gün sınırı gece yarısı değil şafak (START_HOUR): kervanın günü ilk
	# ışıkla döner, yoksa günlük olaylar hep 00:00'da yaşanırdı.
	clock.consume_hours(23.0)
	t.eq(clock.take_elapsed_days(), 0, "gece yarısı geçmek günü döndürmez")

	clock.consume_hours(1.5)
	t.eq(clock.take_elapsed_days(), 1, "gün şafakta döner")
	t.ok(
		clock.get_phase() == JourneyClock.Phase.DAWN,
		"gün döndüğünde vakit şafak - olaylar gündüz yaşansın diye"
	)
	t.eq(clock.take_elapsed_days(), 0, "aynı gün ikinci kez raporlanmaz")

	# Tek çağrıda üç gün: 3x hızda ya da uzun bir olaydan sonra olabiliyor.
	clock.consume_hours(JourneyClock.HOURS_PER_DAY * 3.0)
	t.eq(clock.take_elapsed_days(), 3, "bir seferde geçen üç gün de raporlanır")
	t.eq(clock.take_elapsed_days(), 0, "arkasından tekrar raporlanmaz")

	# Gün gün alma: bir kart açılıp işlem durduğunda kalan günler kaybolmaz.
	clock.consume_hours(JourneyClock.HOURS_PER_DAY * 2.0)
	t.ok(clock.take_one_day(), "birinci gün alınır")
	t.ok(clock.take_one_day(), "ikinci gün sonraki çağrıda da duruyor")
	t.ok(not clock.take_one_day(), "üçüncü gün yok")
	t.eq(clock.take_elapsed_days(), 0, "tek tek alınan günler toplu da tekrar gelmez")

func _test_consumed_hours_count_as_time(t) -> void:
	var clock := JourneyClock.new()
	var before := clock.total_hours
	clock.consume_hours(5.0)
	t.ok(is_equal_approx(clock.total_hours - before, 5.0), "olay saatleri zamandan yer")

	clock.consume_hours(-3.0)
	t.ok(is_equal_approx(clock.total_hours - before, 5.0), "negatif tüketim zamanı geri almaz")

func _phase_at(hour: float) -> JourneyClock.Phase:
	var clock := JourneyClock.new()
	clock.total_hours = hour
	return clock.get_phase()

func _test_phases(t) -> void:
	t.eq(_phase_at(6.0), JourneyClock.Phase.DAWN, "06:00 şafak")
	t.eq(_phase_at(9.0), JourneyClock.Phase.MORNING, "09:00 sabah")
	t.eq(_phase_at(12.0), JourneyClock.Phase.NOON, "12:00 öğle")
	t.eq(_phase_at(15.0), JourneyClock.Phase.AFTERNOON, "15:00 ikindi")
	t.eq(_phase_at(18.0), JourneyClock.Phase.EVENING, "18:00 akşam")
	t.eq(_phase_at(22.0), JourneyClock.Phase.NIGHT, "22:00 gece")

	# Gece gün dönümünü aşıyor - sınırın iki yakası da gece olmalı.
	t.eq(_phase_at(23.9), JourneyClock.Phase.NIGHT, "gece yarısından hemen önce gece")
	t.eq(_phase_at(0.5), JourneyClock.Phase.NIGHT, "gece yarısından sonra hâlâ gece")
	t.eq(_phase_at(4.9), JourneyClock.Phase.NIGHT, "şafaktan hemen önce gece")

	# İkinci günün aynı saati aynı evre olmalı.
	t.eq(
		_phase_at(JourneyClock.HOURS_PER_DAY + 12.0), JourneyClock.Phase.NOON,
		"ertesi günün öğlesi yine öğle"
	)

func _test_phase_progress(t) -> void:
	var clock := JourneyClock.new()
	clock.total_hours = 8.0
	t.ok(clock.get_phase_progress() < 0.05, "evrenin başında ilerleme ~0")

	clock.total_hours = 10.9
	t.ok(clock.get_phase_progress() > 0.9, "evrenin sonunda ilerleme ~1")

	# Gece yarısını aşan evrede de 0-1 aralığında kalmalı.
	clock.total_hours = 2.0
	var night_progress := clock.get_phase_progress()
	t.ok(
		night_progress >= 0.0 and night_progress <= 1.0,
		"gece yarısını aşan evrede ilerleme 0-1 arasında kalır"
	)

func _test_camp_window(t) -> void:
	var clock := JourneyClock.new()
	clock.total_hours = 12.0
	t.not_ok(clock.is_camp_time(), "öğlen kamp zamanı değil")
	clock.total_hours = 18.0
	t.ok(clock.is_camp_time(), "akşam kamp kurulabilir")
	clock.total_hours = 23.0
	t.ok(clock.is_camp_time(), "gece kamp kurulabilir")

func _test_save_round_trip(t) -> void:
	var clock := JourneyClock.new()
	clock.consume_hours(30.5)
	clock.set_speed_index(1)
	clock.take_elapsed_days()

	var restored := JourneyClock.new()
	restored.load_from_dict(clock.to_dict())

	t.ok(is_equal_approx(restored.total_hours, clock.total_hours), "saat kayıttan aynen döner")
	t.eq(restored.speed_index, clock.speed_index, "hız seçimi korunur")
	t.eq(
		restored.take_elapsed_days(), 0,
		"kayıttan dönen saat zaten işlenmiş günü tekrar raporlamaz"
	)

	# Eksik alanlı (eski) bir kayıt çökmeden makul varsayılana düşmeli.
	var legacy := JourneyClock.new()
	legacy.load_from_dict({})
	t.ok(is_equal_approx(legacy.total_hours, JourneyClock.START_HOUR), "eksik kayıt başlangıç saatine düşer")

## Şehrin gökyüzü varış saatinden (SENSORY-003): statik evre saatin kendi
## evresiyle her saatte aynı olmalı, yoksa yol akşam biter de şehir başka
## bir akşamda açılır. Saat kayda yazılmalı.
func _test_arrival_hour_colours_the_city(t) -> void:
	var clock := JourneyClock.new()
	var mismatches := 0
	for step in range(96):
		clock.total_hours = step * 0.25
		var hour := clock.get_hour_of_day()
		if JourneyClock.phase_for_hour(hour) != clock.get_phase():
			mismatches += 1
		if not is_equal_approx(JourneyClock.phase_progress_for_hour(hour), clock.get_phase_progress()):
			mismatches += 1
	t.eq(mismatches, 0, "statik evre saatin evresiyle her çeyrek saatte aynı")

	var noon: Dictionary = TravelBand.sky_for_hour(12.0)
	var night: Dictionary = TravelBand.sky_for_hour(23.0)
	t.ok(
		Color(night.top).get_luminance() < Color(noon.top).get_luminance(),
		"gece varılan şehrin gökyüzü öğleninkinden karanlık"
	)

	t.eq(JourneyClock.darkness_for_hour(12.0), 0.0, "öğle karanlık değil")
	t.eq(JourneyClock.darkness_for_hour(2.0), 1.0, "02:00 tam gece - gökyüzü şafağa karışsa da")
	t.ok(JourneyClock.darkness_for_hour(19.0) > 0.0 and JourneyClock.darkness_for_hour(19.0) < 1.0,
		"akşam alacakaranlıkta yarı koyu")
	t.eq(TravelBand.night_wash_for_hour(12.0).a, 0.0, "öğle şehri örtüsüz")

	var session := GameSession.new()
	t.eq(session.last_clock_hour, JourneyClock.START_HOUR, "yeni oyun şafakta başlar")
	session.last_clock_hour = 19.5
	var restored := GameSession.new()
	restored.load_from_dict(session.to_save_dict())
	t.ok(is_equal_approx(restored.last_clock_hour, 19.5), "varış saati kayıttan geri gelir")
	var legacy := session.to_save_dict()
	legacy.erase("last_clock_hour")
	var old := GameSession.new()
	old.load_from_dict(legacy)
	t.eq(old.last_clock_hour, JourneyClock.START_HOUR, "eski kayıt şafağa düşer")
