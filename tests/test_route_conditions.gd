extends RefCounted

## Rotalar sabit yedi kenar değil: coğrafya durur, üstündeki ağ her gün
## değişir. Bu paket o katmanın kırılmaması gereken yerlerini kilitler.
##
## En kritik ikisi: (1) doğal durumlar **hesaplanıyor**, saklanmıyor - aynı
## kayıt her açılışta aynı dünyayı vermezse ileri sarıp geri yükleyerek
## kapalı geçit "açtırılabilirdi"; (2) harita kendini kilitleyemez -
## kapalı bir yol her zaman ya dolambaçlı bir alternatife ya da açık bir
## itirafa çıkmalı.

func suite_name() -> String:
	return "RouteConditions"

func run(t) -> void:
	_test_key_is_undirected(t)
	_test_natural_state_is_reproducible(t)
	_test_states_actually_occur(t)
	_test_state_modifiers(t)
	_test_overrides_win_and_expire(t)
	_test_map_never_locks_itself(t)
	_test_detour_path(t)
	_test_last_exit_stays_open(t)
	_test_session_layers_stack(t)
	_test_divert_and_turn_back(t)
	_test_save_round_trip(t)

func _route(from_id: String, to_id: String) -> TravelRoute:
	return WorldMapData.get_route(from_id, to_id)

func _test_key_is_undirected(t) -> void:
	t.eq(
		RouteConditions.route_key("b", "a"), RouteConditions.route_key("a", "b"),
		"çığ tek yönlü düşmez - anahtar yönsüz"
	)

	var forward := _route("test_loc_a", "test_loc_b")
	var backward := _route("test_loc_b", "test_loc_a")
	var conditions := RouteConditions.new()
	for day in [0, 7, 19, 44, 91]:
		t.eq(
			conditions.get_state(forward, day), conditions.get_state(backward, day),
			"%d. günde yolun iki yönü aynı halde" % day
		)

## Doğal durum saklanmıyor, tohumlanıp hesaplanıyor: kaydı yeniden yüklemek
## dünyayı yeniden atmamalı, yoksa kapalı geçit kayıt yükleyerek açtırılırdı.
func _test_natural_state_is_reproducible(t) -> void:
	var route := _route("test_loc_a", "test_loc_d")
	var first := RouteConditions.new()
	var second := RouteConditions.new()
	for day in range(0, 90):
		t.ok(
			first.get_state(route, day) == second.get_state(route, day),
			"aynı gün aynı yolun hali - taze bir katman da aynı sonucu verir"
		)

	# Gün ilerletmek geçmişi değiştirmemeli.
	var advanced := RouteConditions.new()
	for day in range(1, 40):
		advanced.advance_day(day)
	t.eq(
		advanced.get_state(route, 12), first.get_state(route, 12),
		"gün ilerletmek geçmiş günlerin halini değiştirmez"
	)

## Katman gerçekten çalışıyor mu: hem bozulma çıkmalı hem yol çoğunlukla
## açık kalmalı. İkisinden biri tutmazsa sistem ya hiç yok ya oynanamaz.
func _test_states_actually_occur(t) -> void:
	var counts := {
		RouteConditions.State.OPEN: 0,
		RouteConditions.State.SLOW: 0,
		RouteConditions.State.PERILOUS: 0,
		RouteConditions.State.CLOSED: 0,
	}
	var conditions := RouteConditions.new()
	var samples := 0
	for location in WorldMapData.get_locations():
		for route in WorldMapData.get_routes_from(location.location_id):
			for day in range(0, 240, 3):
				counts[conditions.get_state(route, day)] += 1
				samples += 1

	t.ok(samples > 0, "örnek toplandı")
	t.ok(counts[RouteConditions.State.OPEN] > samples / 2, "yollar çoğunlukla açık")
	t.ok(counts[RouteConditions.State.SLOW] > 0, "çamura batan yollar oluyor")
	t.ok(counts[RouteConditions.State.PERILOUS] > 0, "eşkıya kaynayan yollar oluyor")
	t.ok(counts[RouteConditions.State.CLOSED] > 0, "kapanan geçitler oluyor")

func _test_state_modifiers(t) -> void:
	var route := _route("test_loc_a", "test_loc_b")
	var conditions := RouteConditions.new()

	conditions.add_override("test_loc_a", "test_loc_b", RouteConditions.State.SLOW, 100)
	t.ok(
		conditions.get_travel_days(route, 0) > route.travel_days,
		"çamur yolu uzatır"
	)
	t.ok(conditions.is_open(route, 0), "çamurlu yol kapalı değil, sadece yavaş")

	conditions.add_override("test_loc_a", "test_loc_b", RouteConditions.State.PERILOUS, 100)
	t.eq(
		conditions.get_travel_days(route, 0), route.travel_days,
		"eşkıya yolu uzatmaz - lojistik değil askerî sorun"
	)
	t.ok(
		conditions.get_danger(route, 0) > route.danger_level,
		"eşkıya tehlikeyi yükseltir"
	)

	conditions.add_override("test_loc_a", "test_loc_b", RouteConditions.State.CLOSED, 100)
	# Kapalı geçit ancak şehri dünyadan koparmıyorsa gerçekten kapalı -
	# o yüzden Kurtboğazı'nın diğer çıkışı açık sabitleniyor (bkz.
	# _test_last_exit_stays_open).
	conditions.add_override("test_loc_b", "test_loc_d", RouteConditions.State.OPEN, 100)
	t.eq(conditions.get_state(route, 0), RouteConditions.State.CLOSED, "geçit kapandı")
	t.ok(not conditions.is_open(route, 0), "kapalı geçitten geçilmez")

	# Süre asla sıfıra inmez, tehlike asla taşmaz.
	t.ok(conditions.get_travel_days(route, 0) >= 1, "yol en az bir gün sürer")
	var deadly := _route("test_loc_a", "test_loc_e")
	var perilous := RouteConditions.new()
	perilous.add_override(
		deadly.from_location_id, deadly.to_location_id, RouteConditions.State.PERILOUS, 100
	)
	t.ok(perilous.get_danger(deadly, 0) <= 1.0, "tehlike 1.0'ı aşmaz")

func _test_overrides_win_and_expire(t) -> void:
	var route := _route("test_loc_d", "test_loc_e")
	var conditions := RouteConditions.new()

	# İki ucun da başka açık çıkışı olsun, yoksa emniyet kuralı (son çıkış
	# kapanmaz) ölçülmek isteneni gizler.
	conditions.add_override("test_loc_d", "test_loc_b", RouteConditions.State.OPEN, 999)
	conditions.add_override("test_loc_e", "test_loc_c", RouteConditions.State.OPEN, 999)
	conditions.add_override("test_loc_d", "test_loc_e", RouteConditions.State.CLOSED, 10)
	t.ok(conditions.has_override("test_loc_d", "test_loc_e", 10), "müdahale son güne kadar geçerli")
	t.eq(
		conditions.get_state(route, 5), RouteConditions.State.CLOSED,
		"olayın açtığı hal doğal zarın önüne geçer"
	)
	# Ters yönden sorulunca da aynı - çığ iki yönü birden kapatır.
	t.eq(
		conditions.get_state(_route("test_loc_e", "test_loc_d"), 5),
		RouteConditions.State.CLOSED, "müdahale iki yöne birden işler"
	)

	t.ok(not conditions.has_override("test_loc_d", "test_loc_e", 11), "süresi dolan müdahale geçmez")
	conditions.advance_day(11)
	t.eq(
		conditions.get_state(route, 11),
		RouteConditions.natural_state(
			RouteConditions.route_key("test_loc_d", "test_loc_e"), route.danger_level, 11
		),
		"süresi dolunca yol doğal haline döner"
	)

	conditions.add_override("test_loc_d", "test_loc_e", RouteConditions.State.CLOSED, 50)
	conditions.clear_override("test_loc_d", "test_loc_e")
	t.ok(
		not conditions.has_override("test_loc_d", "test_loc_e", 20),
		"müdahale elle de kaldırılabilir - devriye yolu temizler"
	)

## Harita hiçbir gün kendini kilitlememeli: her şehirden en az bir yere
## gidilebilmeli, yoksa oyuncu bir kasabada mahsur kalır ve oyun durur.
func _test_map_never_locks_itself(t) -> void:
	var conditions := RouteConditions.new()
	var trapped_days: Array[int] = []
	for day in range(0, 300):
		for location in WorldMapData.get_locations():
			var has_exit := false
			for route in WorldMapData.get_routes_from(location.location_id):
				if conditions.is_open(route, day):
					has_exit = true
					break
			if not has_exit:
				trapped_days.append(day)
	t.eq(trapped_days.size(), 0, "hiçbir şehir hiçbir gün tamamen kapanmıyor")

func _test_detour_path(t) -> void:
	var conditions := RouteConditions.new()
	# Doğrudan yolu kapat, dolambaçlı yol hâlâ bulunmalı. Kurtboğazı'nın
	# öbür çıkışı açık sabitleniyor - kapanan yol o şehrin son çıkışı
	# olsaydı emniyet kuralı onu zaten açık tutardı.
	conditions.add_override("test_loc_b", "test_loc_d", RouteConditions.State.OPEN, 100)
	conditions.add_override("test_loc_a", "test_loc_b", RouteConditions.State.CLOSED, 100)
	var path := conditions.find_open_path("test_loc_a", "test_loc_b", 0)
	t.ok(path.size() >= 3, "kapalı yola dolambaçlı alternatif bulunur")
	t.eq(path[0], "test_loc_a", "yol nerede olduğunla başlar")
	t.eq(path[path.size() - 1], "test_loc_b", "yol hedefte biter")
	t.ok(not path.has("test_loc_b") or path.count("test_loc_b") == 1, "hedef bir kez geçer")

	# Ardışık her adım gerçek ve açık bir rota olmalı.
	for index in range(path.size() - 1):
		var leg := WorldMapData.get_route(path[index], path[index + 1])
		t.ok(leg != null, "yolun her adımı gerçek bir rota")
		t.ok(conditions.is_open(leg, 0), "yolun her adımı açık")

	t.ok(
		conditions.find_open_path("test_loc_a", "test_loc_a", 0).is_empty(),
		"bulunduğun şehre yol aranmaz"
	)
	t.ok(
		conditions.find_open_path("test_loc_a", "yok_boyle_sehir", 0).is_empty(),
		"olmayan şehre yol yok"
	)

## Bir şehrin bütün çıkışları kapansa bile son çıkış açık kalır: yoksa
## oyuncu bir kasabada mahsur kalır ve oyun durur. Yol berbat haldedir
## ama vardır.
func _test_last_exit_stays_open(t) -> void:
	var sealed := RouteConditions.new()
	for route in WorldMapData.get_routes_from("test_loc_a"):
		sealed.add_override(
			route.from_location_id, route.to_location_id, RouteConditions.State.CLOSED, 100
		)

	var open_exits := 0
	for route in WorldMapData.get_routes_from("test_loc_a"):
		t.eq(
			sealed.get_raw_state(route, 0), RouteConditions.State.CLOSED,
			"zarın/olayın söylediği ham hal hâlâ kapalı"
		)
		if sealed.is_open(route, 0):
			open_exits += 1
			t.eq(
				sealed.get_state(route, 0), RouteConditions.State.SLOW,
				"son çıkış kapanmaz, güç bela geçilir hale düşer"
			)
			t.ok(
				sealed.get_travel_days(route, 0) > route.travel_days,
				"güç bela geçilen yol uzar - ekranda 'kapalı' yazan yoldan kervan geçmez"
			)
	t.ok(open_exits > 0, "son çıkış açık kalır, şehir dünyadan kopmaz")
	t.ok(
		not sealed.find_open_path("test_loc_a", "test_loc_b", 0).is_empty(),
		"mahsur kalınan şehir yok"
	)

## Üç katman ayrı ayrı yaşıyor: rotanın tablosu, yolun o günkü hali ve
## kervanın deneyim eğrisi. GameSession bunları toplayan tek yer.
func _test_session_layers_stack(t) -> void:
	var session := GameSession.new(100, 0)
	var route := _route("test_loc_a", "test_loc_c")

	session.route_conditions.add_override(
		"test_loc_a", "test_loc_c", RouteConditions.State.OPEN, 999
	)
	t.eq(session.get_route_travel_days(route), route.travel_days, "açık yolda süre tablodaki gibi")
	t.almost(
		session.get_route_danger(route), session.get_effective_danger(route.danger_level),
		"açık yolda tehlike yalnızca deneyim eğrisiyle ölçeklenir"
	)

	session.route_conditions.add_override(
		"test_loc_a", "test_loc_c", RouteConditions.State.PERILOUS, 999
	)
	t.ok(
		session.get_route_danger(route) > session.get_effective_danger(route.danger_level),
		"eşkıya katmanı deneyim katmanının üstüne biner"
	)

	session.route_conditions.add_override(
		"test_loc_a", "test_loc_c", RouteConditions.State.CLOSED, 999
	)
	# İpekevi'nin diğer çıkışı açık sabitleniyor, yoksa emniyet kuralı
	# (son çıkış hep açıktır) ölçülmek isteneni gizlerdi.
	session.route_conditions.add_override(
		"test_loc_c", "test_loc_e", RouteConditions.State.OPEN, 999
	)
	t.ok(not session.is_route_open(route), "oturum kapalı yolu kapalı görür")
	t.ok(session.find_open_path("test_loc_c").size() >= 3, "oturum dolambaçlı yolu bulur")

	# ROUTE_CHANGE etkisi aynı katmandan geçmeli.
	var closer := GameSession.new(100, 0)
	closer.route_conditions.add_override(
		"test_loc_b", "test_loc_d", RouteConditions.State.OPEN, 999
	)
	EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.ROUTE_CHANGE, 6, "test_loc_a|test_loc_b|closed"),
	], closer)
	t.ok(
		not closer.is_route_open(_route("test_loc_a", "test_loc_b")),
		"ROUTE_CHANGE yolu gerçekten kapatır"
	)

	# Olmayan bir rotayı kapatmaya çalışmak sessizce hiçbir şey yapmamalı.
	var noop := GameSession.new(100, 0)
	var result := EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.ROUTE_CHANGE, 6, "yok|bilinmiyor|closed"),
	], noop)
	t.ok(result.lines.is_empty(), "olmayan rota için satır yazılmaz")

## Şehirde kurulan plan bir taahhüt değil: yolda hedef değişebilir, kervan
## geri dönebilir. Değişen bacak yeni bir sefer gibi davranmalı.
func _test_divert_and_turn_back(t) -> void:
	var session := GameSession.new(300, 40)
	session.current_location_id = "test_loc_a"
	var route := _route("test_loc_a", "test_loc_e")
	var plan := CaravanPlan.new(
		WorldMapData.get_location_by_id("test_loc_e"), route.travel_days
	)
	session.start_journey("test_loc_e", route.travel_days, route.danger_level, plan)

	t.ok(not session.can_divert_to("test_loc_e"), "gittiğin yere sapılmaz")
	t.ok(not session.can_divert_to("test_loc_a"), "çıktığın şehre sapmak sapma değil, dönüştür")

	session.journey_days_remaining = session.journey_total_days - 2
	t.eq(session.get_days_travelled(), 2, "yürünen gün sayısı doğru")

	t.ok(session.can_divert_to("test_loc_b"), "çıkış şehrinden ulaşılabilen hedefe sapılır")
	t.ok(session.divert_journey("test_loc_b"), "sapma uygulanır")
	t.eq(session.journey_destination_id, "test_loc_b", "hedef değişti")
	t.eq(
		session.journey_days_remaining, session.journey_total_days,
		"yeni bacak baştan başlar - ilerleme çubuğu dolu kalmaz"
	)
	t.ok(
		session.journey_total_days >= _route("test_loc_a", "test_loc_b").travel_days,
		"sapan kervan geri yürüdüğü yolu da öder"
	)

	# Kapalı yola sapılamaz.
	session.route_conditions.add_override(
		"test_loc_c", "test_loc_e", RouteConditions.State.OPEN, 999
	)
	session.route_conditions.add_override(
		"test_loc_a", "test_loc_c", RouteConditions.State.CLOSED, 999
	)
	t.ok(not session.can_divert_to("test_loc_c"), "kapalı yola sapılamaz")

	var back := GameSession.new(300, 40)
	back.current_location_id = "test_loc_a"
	back.start_journey("test_loc_e", route.travel_days, route.danger_level, plan)
	back.journey_days_remaining = back.journey_total_days - 3
	t.ok(back.turn_back(), "geri dönmek her zaman mümkün")
	t.eq(back.journey_destination_id, "test_loc_a", "hedef çıkış şehri oldu")
	t.eq(back.journey_total_days, 3, "geri dönüş yürünen yol kadar sürer")

	# Yolda değilken ikisi de sessizce reddedilmeli.
	var idle := GameSession.new(100, 0)
	t.ok(not idle.turn_back(), "yolda olmayan kervan geri dönemez")
	t.ok(not idle.can_divert_to("test_loc_b"), "yolda olmayan kervan sapamaz")

func _test_save_round_trip(t) -> void:
	var session := GameSession.new(100, 0)
	session.total_days_elapsed = 20
	session.route_conditions.add_override(
		"test_loc_b", "test_loc_d", RouteConditions.State.CLOSED, 40
	)

	var restored := GameSession.new(0, 0)
	restored.load_from_dict(session.to_save_dict())
	t.ok(
		restored.has_route_override("test_loc_b", "test_loc_d"),
		"kapalı geçit kayıttan döner - kaydı yeniden yüklemek yolu açmaz"
	)
	t.eq(
		restored.get_route_state(_route("test_loc_b", "test_loc_d")),
		RouteConditions.State.CLOSED, "kayıttan dönen yol hâlâ kapalı"
	)

	# Eski (alanı olmayan) kayıt çökmeden müdahalesiz açılmalı.
	var legacy := RouteConditions.new()
	legacy.load_from_dict({})
	t.ok(
		not legacy.has_override("test_loc_b", "test_loc_d", 0),
		"eski kayıtta yol müdahalesi yok"
	)
