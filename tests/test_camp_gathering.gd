extends RefCounted

## Kamp kurulunca kadro ve tayfa kendi ateşine yürüyor, kamp kalkınca
## aynı yoldan geri dönüyor (bkz. RoadCaravan'ın `_advance_gather`'ı).
## Bu paket üç iddiayı koruyor:
##
## 1. Ateş sayısı vagon sayısı kadar ve hiçbiri bir vagonun/bir sonraki
##    vagonun üstüne binmiyor - "vagon başına bir tane" kelimesi kadar
##    "vagonun içinde değil" de bir sözdü.
## 2. Toplanan herkes gerçekten yürüyüp gerçekten dönüyor: kamp bitince
##    kalan biri, dönüşü hiç başlamamış biri kadar bir kusur.
## 3. Lider ve öküzler hiç kıpırdamıyor - nöbet/koşum kuralı görsel
##    olarak da geçerli.
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
	var party_at_fire := caravan.get_party_centres()
	var fire_count := fires.size()
	for index in party_at_fire.size():
		var fire_index := index % fire_count
		t.ok(
			absf(party_at_fire[index] - fires[fire_index].x) < 2.0,
			"%d. parti üyesi toplanma bitince kendi ateşinde değil" % (index + 1)
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
	var fire_count := fires.size()
	var back_at_fire := caravan.get_party_centres()
	for index in back_at_fire.size():
		t.ok(
			absf(back_at_fire[index] - fires[index % fire_count].x) < 2.0,
			"%d. parti üyesi yarıda kesilen dönüşten sonra ateşe ulaşamadı" % (index + 1)
		)
		# Yarı yoldaki nokta ev ile ateş arasında bir yerde olmalıydı -
		# ışınlanma olmadığının kanıtı.
		t.ok(
			absf(mid_return[index] - party_home[index]) > 0.5,
			"%d. parti üyesi dönüşün ortasında hâlâ ateşteydi" % (index + 1)
		)
