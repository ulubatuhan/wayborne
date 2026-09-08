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
	_test_advance_converts_real_time(t)
	_test_days_reported_once_and_never_skipped(t)
	_test_consumed_hours_count_as_time(t)
	_test_phases(t)
	_test_phase_progress(t)
	_test_camp_window(t)
	_test_save_round_trip(t)

func _test_speed_selection(t) -> void:
	var clock := JourneyClock.new()
	t.eq(clock.get_speed(), 1.0, "varsayılan hız 1x")

	clock.cycle_speed()
	t.eq(clock.get_speed(), 1.5, "sonraki hız 1.5x")
	clock.cycle_speed()
	t.eq(clock.get_speed(), 3.0, "sonraki hız 3x")
	clock.cycle_speed()
	t.eq(clock.get_speed(), 1.0, "hız başa döner")

	clock.set_speed_index(99)
	t.eq(clock.get_speed(), 3.0, "aralık dışı indeks son hıza kenetlenir")
	clock.set_speed_index(-5)
	t.eq(clock.get_speed(), 1.0, "negatif indeks ilk hıza kenetlenir")

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
	fast.set_speed_index(2)
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

	# START_HOUR 6, yani ilk tam gün 18 saat sonra dolar.
	clock.consume_hours(17.0)
	t.eq(clock.take_elapsed_days(), 0, "gün dolmadan gün raporlanmaz")

	clock.consume_hours(2.0)
	t.eq(clock.take_elapsed_days(), 1, "gün dolunca bir kez raporlanır")
	t.eq(clock.take_elapsed_days(), 0, "aynı gün ikinci kez raporlanmaz")

	# Tek çağrıda üç gün: 3x hızda ya da uzun bir olaydan sonra olabiliyor.
	clock.consume_hours(JourneyClock.HOURS_PER_DAY * 3.0)
	t.eq(clock.take_elapsed_days(), 3, "bir seferde geçen üç gün de raporlanır")
	t.eq(clock.take_elapsed_days(), 0, "arkasından tekrar raporlanmaz")

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
