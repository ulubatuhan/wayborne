extends RefCounted

## Kamp kurulunca kadro ve tayfa kendi ateşine yürüyor, kamp kalkınca
## aynı yoldan geri dönüyor (bkz. RoadCaravan'ın `_advance_gather`'ı).
## Bu paket beş iddiayı koruyor:
##
## 1. Ateş sayısı vagon sayısı kadar ve hiçbiri bir vagonun/bir sonraki
##    vagonun üstüne binmiyor - "vagon başına bir tane" kelimesi kadar
##    "vagonun içinde değil" de bir sözdü.
## 2. Toplanan herkes gerçekten yürüyüp gerçekten dönüyor: kamp bitince
##    kalan biri, dönüşü hiç başlamamış biri kadar bir kusur.
## 3. Lider ve öküzler hiç kıpırdamıyor - nöbet/koşum kuralı görsel
##    olarak da geçerli.
## 4. Arabacı da ateşe geliyor - yürüyen tayfayla birlikte vagonun
##    **ikisi de** insanı toplanıyor, "kervandakiler" tek kişi değil.
## 5. Aynı ateşe gelen birden fazla kişi üst üste binmiyor - erken bir
##    sürümde herkesin hedefi tam olarak ateşin merkeziydi, yani iki
##    kişi tek bir figür gibi görünüyordu; koltuk kayması bunu ayırıyor.
##
## `RoadCaravan` sahnesiz kurulabiliyor (`test_caravan_layout.gd` ile
## aynı numara); `_process()` de doğrudan çağrılıyor - Godot onu ancak
## düğüm ağaçtaysa kendiliğinden çağırıyor, testte ağaç yok.

func suite_name() -> String:
	return "CampGathering"

## Oyunun kendi şeridi: 1920 genişlik, `TravelBand.BAND_HEIGHT` yükseklik.
const BAND: Vector2 = Vector2(1920.0, 320.0)

func run(t) -> void:
	_test_one_fire_per_wagon(t)
	_test_fires_clear_the_wagons(t)
	_test_humans_gather_and_return(t)
	_test_drivers_join_the_gathering(t)
	_test_shared_fire_seats_do_not_stack(t)
	_test_leader_and_oxen_never_move(t)
	_test_returning_is_interrupted_cleanly_by_a_new_camp(t)

func _build(wagons: int, party: int) -> RoadCaravan:
	var band := TravelBand.new()
	band.size = BAND
	var caravan := RoadCaravan.new()
	band.add_child(caravan)
	caravan.size = BAND
	caravan.column_length_changed.connect(band.set_column_length)

	var session := GameSession.new()
	session.owned_wagon_count = wagons
	var culture := CultureCatalog.get_cultures()[0]
	for index in party:
		var character := CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id, CharacterStats.new(),
			CharacterData.DEFAULT_HEIGHT_CM, index, ClassCatalog.GUARD
		)
		if index == 0:
			character.is_player = true
		session.party.append(character)
	caravan.configure(session)
	# Şeridin çapası kolonun boyuna göre kayıyor; yerleşim de o çapadan
	# geriye yürüyor, yani ikisi bir kez daha el sıkışmalı (bkz.
	# test_caravan_layout.gd'nin aynı satırı).
	caravan.set_ground_line(band.caravan_x(), BAND.y * 0.84)
	caravan.set_ground_line(band.caravan_x(), BAND.y * 0.84)
	return caravan

func _walk_frames(caravan: RoadCaravan, frames: int, dt: float = 1.0 / 30.0) -> void:
	for _frame in frames:
		caravan._process(dt)

## Aynı ateşe gelen ikinci/üçüncü kişi merkezden kayıyor (bkz.
## CAMPFIRE_SEAT_OFFSETS), o yüzden "ateşe vardı" iddiası artık tam
## merkeze değil, koltukların kapladığı aralığa karşı sınanıyor.
func _fire_tolerance(caravan: RoadCaravan) -> float:
	var max_offset := 0.0
	for offset in RoadCaravan.CAMPFIRE_SEAT_OFFSETS:
		max_offset = maxf(max_offset, absf(offset))
	return max_offset * RoadCaravan.CAMPFIRE_SEAT_SPACING * caravan.get_column_scale() + 1.0

func _test_one_fire_per_wagon(t) -> void:
	for wagons in [1, 2, 4, 6]:
		var caravan := _build(wagons, 2)
		t.eq(
			caravan.get_campfire_positions().size(), wagons,
			"%d vagon: ateş sayısı vagon sayısını tutmuyor" % wagons
		)

## Tek ateşken kaçış yolu "kolonun önü, boş alan"dı (bkz. CLAUDE.md Art
## Rules); vagon başına çoğalınca her ateş kendi vagonunun kuyruğuna
## kaymak zorunda. Ölçülen şey: ne kendi vagonunun üstünde, ne bir
## sonraki vagonun üstünde.
func _test_fires_clear_the_wagons(t) -> void:
	for wagons in [2, 4, 6]:
		var caravan := _build(wagons, 2)
		var centres := caravan.get_wagon_centres()
		var fires := caravan.get_campfire_positions()
		var wagon_w := BAND.y * caravan.get_column_scale() * RoadCaravan.WAGON_WIDTH_RATIO
		for index in fires.size():
			t.ok(
				absf(fires[index].x - centres[index]) > wagon_w * 0.3,
				"%d vagon, %d. ateş kendi vagonunun üstünde duruyor" % [wagons, index + 1]
			)
			if index + 1 < centres.size():
				t.ok(
					fires[index].x > centres[index + 1] + wagon_w * 0.5,
					"%d vagon, %d. ateş bir sonraki vagona taşıyor" % [wagons, index + 1]
				)

func _test_humans_gather_and_return(t) -> void:
	var caravan := _build(2, 3)
	var party_home := caravan.get_party_centres()
	var crew_home := caravan.get_crew_centres()

	caravan.set_camping(true)
	# CAMP_GATHER_SECONDS'ten fazlası: toplanmanın kesin bittiğinden
	# emin olmak için.
	_walk_frames(caravan, 120)

	var fires := caravan.get_campfire_positions()
	var tolerance := _fire_tolerance(caravan)
	var party_at_fire := caravan.get_party_centres()
	var fire_count := fires.size()
	for index in party_at_fire.size():
		var fire_index := index % fire_count
		t.ok(
			absf(party_at_fire[index] - fires[fire_index].x) < tolerance,
			"%d. parti üyesi toplanma bitince kendi ateşinin yakınında değil" % (index + 1)
		)
		t.ok(
			absf(party_at_fire[index] - party_home[index]) > 1.0,
			"%d. parti üyesi hiç yürümemiş" % (index + 1)
		)

	caravan.set_camping(false)
	_walk_frames(caravan, 120)

	t.not_ok(caravan.is_gathering(), "dönüş bitince kimse yürümüyor olmalı")
	var party_after := caravan.get_party_centres()
	var crew_after := caravan.get_crew_centres()
	for index in party_after.size():
		t.ok(
			absf(party_after[index] - party_home[index]) < 1.0,
			"%d. parti üyesi kendi yerine dönmedi" % (index + 1)
		)
	for index in crew_after.size():
		t.ok(
			absf(crew_after[index] - crew_home[index]) < 1.0,
			"%d. tayfa kendi yerine dönmedi" % (index + 1)
		)

## Arabacı normalde `ArtDraw.wagon()`'un sabit silüeti - kamp onu ilk
## kez gerçek bir figüre çeviriyor. "Kervandakiler ateşe gelsin" isteği
## yalnızca yürüyen tayfayla sınırlı kalmamalı, çünkü vagon başına iki
## tayfa var (bkz. PEOPLE_PER_WAGON) ve ikisi de kervanın adamı.
func _test_drivers_join_the_gathering(t) -> void:
	var caravan := _build(2, 1)
	t.eq(
		caravan.get_driver_centres().size(), 2,
		"iki vagon: iki arabacı figürü kurulmalı (görünmez de olsa)"
	)

	caravan.set_camping(true)
	_walk_frames(caravan, 120)

	var fires := caravan.get_campfire_positions()
	var tolerance := _fire_tolerance(caravan)
	var drivers_at_fire := caravan.get_driver_centres()
	for index in drivers_at_fire.size():
		t.ok(
			absf(drivers_at_fire[index] - fires[index].x) < tolerance,
			"%d. arabacı toplanma bitince kendi ateşinin yakınında değil" % (index + 1)
		)

	caravan.set_camping(false)
	_walk_frames(caravan, 120)
	t.not_ok(caravan.is_gathering(), "arabacılar da dönünce toplanma bitmeli")

## Erken bir sürümde `_campfire_target` yalnızca ateş indeksine bakıyordu,
## yani aynı ateşe atanan herkesin hedefi **aynı noktaydı** - iki kişi
## tek bir figür gibi görünüyordu ve "toplanma" hiç okunmuyordu. Koltuk
## kayması bunu ayırıyor; burada tam bunu sınıyoruz.
func _test_shared_fire_seats_do_not_stack(t) -> void:
	# Tek vagon, iki parti üyesi + arabacı + tayfa: dördü de aynı ateşe
	# gidiyor (fire_count == 1), yani en az ikisinin ayrışması zorunlu.
	var caravan := _build(1, 3)
	caravan.set_camping(true)
	_walk_frames(caravan, 120)

	var seat_positions: Array[float] = []
	seat_positions.append_array(caravan.get_party_centres())
	seat_positions.append_array(caravan.get_crew_centres())
	seat_positions.append_array(caravan.get_driver_centres())
	t.ok(seat_positions.size() >= 3, "sınamak için yeterli figür toplanmadı")

	var min_gap := INF
	for i in seat_positions.size():
		for j in range(i + 1, seat_positions.size()):
			min_gap = minf(min_gap, absf(seat_positions[i] - seat_positions[j]))
	t.ok(
		min_gap > 3.0,
		"aynı ateşteki iki figür üst üste biniyor (en yakın çift %.1f piksel arayla)" % min_gap
	)

## Lider nöbette, öküzler koşumda - "kervandakiler ateşe gelsin" isteği
## ikisini kapsamıyor (bkz. `_begin_gathering`'in notu).
func _test_leader_and_oxen_never_move(t) -> void:
	var caravan := _build(2, 2)
	var leader_home := caravan.get_leader_centre()
	var ox_home := caravan.get_ox_centres()

	caravan.set_camping(true)
	_walk_frames(caravan, 60)

	t.eq(
		caravan.get_leader_centre(), leader_home,
		"lider kampta yerinden kımıldamamalı"
	)
	var ox_now := caravan.get_ox_centres()
	for index in ox_home.size():
		t.eq(ox_now[index], ox_home[index], "%d. öküz koşumdan çözülmemeli" % (index + 1))

## Kamp bitip dönüş sürerken yeni bir kamp kurulursa (CAMP_HOURS 0.5x'te
## bile dönüş süresinden uzun olduğu için pratikte olmaz, ama motor bunu
## varsaymamalı) geçiş kırılmadan tersine dönmeli - yarı yoldaki figür
## ne havada asılı kalmalı ne ışınlanmalı.
func _test_returning_is_interrupted_cleanly_by_a_new_camp(t) -> void:
	var caravan := _build(2, 2)
	var party_home := caravan.get_party_centres()

	caravan.set_camping(true)
	_walk_frames(caravan, 120)
	caravan.set_camping(false)
	# Dönüşün tam ortasında yakala.
	_walk_frames(caravan, 15)
	var mid_return := caravan.get_party_centres()

	caravan.set_camping(true)
	_walk_frames(caravan, 120)

	var fires := caravan.get_campfire_positions()
	var tolerance := _fire_tolerance(caravan)
	var back_at_fire := caravan.get_party_centres()
	for index in back_at_fire.size():
		t.ok(
			absf(back_at_fire[index] - fires[index % fires.size()].x) < tolerance,
			"%d. parti üyesi yarıda kesilen dönüşten sonra ateşe ulaşamadı" % (index + 1)
		)
		# Yarı yoldaki nokta ev ile ateş arasında bir yerde olmalıydı -
		# ışınlanma olmadığının kanıtı.
		t.ok(
			absf(mid_return[index] - party_home[index]) > 0.5,
			"%d. parti üyesi dönüşün ortasında hâlâ ateşteydi" % (index + 1)
		)
