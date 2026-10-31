extends RefCounted

## Yürüyüşün duruşa geçişi ve ikincil hareket (SENSORY-004/005). Görünüşü
## ekran görüntüsü araçları gösterir; burada kilitlenen şey hareketin
## sözleşmesi: durmak bir karede olmuyor, duran bir şey kıpırdamıyor,
## rüzgâr yalnızca kötü havada esiyor.

const FRAME: float = 1.0 / 60.0

func suite_name() -> String:
	return "Motion"

func run(t) -> void:
	_test_card_drift_settles(t)
	_test_stop_is_a_settle_not_a_snap(t)
	_test_figure_keeps_its_phase_when_stopping(t)
	_test_wind_only_in_bad_weather(t)
	_test_canopy_rests_with_the_wagon(t)
	_test_dust_follows_pace(t)
	_test_mud_flies_back_and_lands(t)

func _test_stop_is_a_settle_not_a_snap(t) -> void:
	var motion := WalkFigure.ease_motion(1.0, false, FRAME)
	t.ok(motion > 0.9, "durduktan bir kare sonra adım hâlâ neredeyse tam")
	var frames := 1
	while motion > 0.0 and frames < 600:
		motion = WalkFigure.ease_motion(motion, false, FRAME)
		frames += 1
	var seconds := frames * FRAME
	t.ok(
		absf(seconds - WalkFigure.REST_EASE_SECONDS) < FRAME * 2.0,
		"duruş REST_EASE_SECONDS içinde tamamlanıyor (%.3f sn)" % seconds
	)
	t.eq(WalkFigure.ease_motion(0.0, false, FRAME), 0.0, "duran figür duruyor")
	t.ok(
		WalkFigure.ease_motion(0.0, true, FRAME) < 1.0,
		"kalkış da bir karede olmuyor"
	)
	t.ok(
		WalkFigure.START_EASE_SECONDS < WalkFigure.REST_EASE_SECONDS,
		"kalkış duruştan kısa"
	)

func _test_figure_keeps_its_phase_when_stopping(t) -> void:
	var figure := WalkFigure.new()
	figure.advance(0.3, 1.0)
	var mid_stride: float = figure._phase
	figure.advance(FRAME, 0.0)
	t.ok(is_equal_approx(figure._phase, mid_stride), "durunca faz sıfıra atlamıyor")
	t.ok(figure.get_motion() > 0.0, "ayak yarım adımdan süzülerek toplanıyor")
	for _frame in 30:
		figure.advance(FRAME, 0.0)
	t.eq(figure.get_motion(), 0.0, "yarım saniye sonra ayaklar yan yana")
	figure.free()

func _test_wind_only_in_bad_weather(t) -> void:
	t.eq(RoadCaravan.wind_lean_at(0.0, 3.0, 2), 0.0, "açık havada kimse eğilmiyor")
	var rain: float = RoadCaravan.WIND_LEAN[RouteWeather.RAIN]
	var storm: float = RoadCaravan.WIND_LEAN[RouteWeather.STORM]
	t.ok(storm > rain, "fırtına yağmurdan sert eğiyor")
	var lowest := INF
	var highest := -INF
	var differs := false
	for step in 200:
		var time := step * 0.05
		var lean := RoadCaravan.wind_lean_at(storm, time, 1)
		lowest = minf(lowest, lean)
		highest = maxf(highest, lean)
		if not is_equal_approx(lean, RoadCaravan.wind_lean_at(storm, time, 2)):
			differs = true
	t.ok(lowest > 0.0, "bora eğilmeyi tersine çevirmiyor")
	t.ok(highest <= storm * (1.0 + RoadCaravan.GUST_AMPLITUDE) + 0.0001, "bora sınırlı")
	t.ok(differs, "iki figür aynı anda aynı açıda değil")

func _test_canopy_rests_with_the_wagon(t) -> void:
	t.eq(RoadCaravan.canopy_sway_at(1.2, 0, 40.0, 0.0), 0.0, "duran vagonun brandası kıpırdamıyor")
	var peak := 0.0
	for step in 64:
		peak = maxf(peak, absf(RoadCaravan.canopy_sway_at(step * 0.1, 1, 40.0, 1.0)))
	t.ok(peak > 0.0, "giden vagonun brandası salınıyor")
	t.ok(peak <= 40.0 * RoadCaravan.CANOPY_SWAY_RATIO + 0.0001, "salınım vagon boyuna oranlı ve küçük")

## N31e: toz tempoyla artar, dururken neredeyse yok; çamur geriye ve yukarı
## atılır, ömrünün sonunda yere iner.
func _test_dust_follows_pace(t) -> void:
	t.ok(TravelBand.dust_scale(0.0) < 0.2, "duran kervan toz kaldırmaz")
	t.ok(absf(TravelBand.dust_scale(1.0) - 1.0) < 0.001, "normal yürüyüşte toz eski yoğunlukta")
	t.ok(TravelBand.dust_scale(1.3) > TravelBand.dust_scale(1.0), "tempolu yürüyüş daha çok toz")
	t.ok(TravelBand.dust_scale(5.0) <= TravelBand.DUST_MAX_SHARE, "toz bir yerde durur")
	t.ok(TravelBand.SNOW_DRIFT.get_luminance() > 0.85, "kışın savrulan kar beyaza yakın")

func _test_mud_flies_back_and_lands(t) -> void:
	var start := RoadCaravan.mud_fleck(0.0)
	var mid := RoadCaravan.mud_fleck(0.5)
	var end := RoadCaravan.mud_fleck(1.0)
	t.ok(mid.x < start.x and end.x < mid.x, "çamur tekerleğin gerisine atılır")
	t.ok(mid.y < start.y, "çamur yükselir")
	t.ok(end.y > mid.y and end.y < 0.1, "çamur ömrünün sonunda yere iner")


# Y-G21: kartın resmi durgundan başlar, hızı sıfıra inerek durur.
func _test_card_drift_settles(t) -> void:
	t.almost(CardDrift.scale_at(0.0), 1.0, "kayma ölçeği 1'den başlar")
	t.almost(CardDrift.scale_at(1.0), 1.0 + CardDrift.ZOOM, "kayma hedefte durur")
	t.almost(CardDrift.scale_at(2.0), 1.0 + CardDrift.ZOOM, "süreden sonra kıpırdamaz")
	var late := CardDrift.scale_at(1.0) - CardDrift.scale_at(0.98)
	var early := CardDrift.scale_at(0.02) - CardDrift.scale_at(0.0)
	t.ok(late < early * 0.01, "sonda hız neredeyse sıfır")
