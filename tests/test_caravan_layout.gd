extends RefCounted

## Yoldaki kolonun yerleşimi. Sahnesiz kurulabildiği için test edilebiliyor
## (`OnboardingPanel` ile aynı numara: `.new()` + boyu elle vermek).
##
## Neden var: bu kolon iki kez çakıştı (iki vagon üst üste, sonra arkadaki
## vagonun öküzü öndekinin içinde) ve bir kez de **hiç görünmedi** - iki
## vagonluk bir kervanın iki vagonu da karenin solunda kalıyordu, üstelik
## bunu yakalaması gereken ekran görüntüsü aracı oyunun oranlarını
## kullanmadığı için tek bir vagon bile basmamıştı. Yapısal test görüntüyü
## doğrulamaz ama "vagon ekranda mı" ve "iki vagon üst üste mi" sorularının
## ikisi de saf aritmetik.

func suite_name() -> String:
	return "CaravanLayout"

## Oyunun kendi şeridi: 1920 genişlik, `TravelBand.BAND_HEIGHT` yükseklik.
const BAND: Vector2 = Vector2(1920.0, 320.0)

## Bu kadar vagona kadar kolonun tamamı ekranda olmalı. Daha uzun bir
## kervanın kuyruğunun kadraja sığmaması dürüst - uzun bir kervan görüş
## alanından uzundur - ama oyuncunun kampanya boyunca ulaştığı büyüklüğü
## görememesi değil.
const FULLY_VISIBLE_WAGONS: int = 4

func run(t) -> void:
	for wagons in [1, 2, 3, 4, 6]:
		for party in [1, 2, 4]:
			_check(t, wagons, party)
	_test_a_small_caravan_is_not_shrunk(t)
	_test_pack_animals_are_placed(t)
	_test_turnaround(t)
	_test_leader_speed_is_symmetric(t)
	_test_walking_left_is_not_a_moonwalk(t)

func _build(wagons: int, party: int, dogs: int = 0, donkeys: int = 0, half_wagons: int = 0) -> RoadCaravan:
	var band := TravelBand.new()
	band.size = BAND
	var caravan := RoadCaravan.new()
	band.add_child(caravan)
	caravan.size = BAND
	caravan.column_length_changed.connect(band.set_column_length)

	# Bol altın: bu paket köpek/eşek/yarım vagon satın alıyor, yerleşimin
	# kendisiyle ilgisiz bir kese kısıtına takılmamalı.
	var session := GameSession.new(2000, 20, wagons)
	session.owned_wagon_count = wagons
	for _i in dogs:
		session.adopt_dog()
	for _i in donkeys:
		session.buy_donkey()
	for _i in half_wagons:
		session.buy_half_wagon()
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
	# geriye yürüyor, yani ikisi bir kez daha el sıkışmalı.
	caravan.set_ground_line(band.caravan_x(), BAND.y * 0.84)
	caravan.set_ground_line(band.caravan_x(), BAND.y * 0.84)
	return caravan

## Köpek/eşek/yarım vagon yol ekranında da görünmeli - bir süre yalnızca
## `world_hub.gd`'ye (şehir dışı yürüme alanı) bağlanmışlardı, sefer
## sırasında (`RoadCaravan`, bu dosyanın test ettiği sınıf) hiç
## çizilmiyorlardı: oyuncu satın alıyor, yola çıkınca kayboluyorlardı.
func _test_pack_animals_are_placed(t) -> void:
	var caravan := _build(2, 1, 2, 1, 1)
	var pack_centres: Array[float] = caravan.get_pack_centres()
	t.eq(pack_centres.size(), 4, "2 köpek + 1 eşek + 1 yarım vagon dört hayvan çizer")

	# Sürü kolonun en arkasında: son vagondan da geride.
	var wagon_centres: Array[float] = caravan.get_wagon_centres()
	var last_wagon: float = wagon_centres[wagon_centres.size() - 1]
	for centre in pack_centres:
		t.ok(centre < last_wagon, "sürü hep son vagonun gerisinde durmalı")

	# Üst üste binmiyorlar: sıradaki merkez bir öncekinden daima geride.
	for index in range(1, pack_centres.size()):
		t.ok(
			pack_centres[index - 1] - pack_centres[index] > 0.0,
			"%d. ve %d. sürü hayvanı üst üste biniyor" % [index, index + 1]
		)

	# Hiç hayvan yoksa hiç figür çizilmez - varsayılan davranış bozulmadı.
	var bare := _build(1, 1)
	t.eq(bare.get_pack_centres().size(), 0, "hayvan yoksa sürü de yok")

func _check(t, wagons: int, party: int) -> void:
	var caravan := _build(wagons, party)
	var centres: Array[float] = caravan.get_wagon_centres()
	var label := "%d vagon / %d kişi" % [wagons, party]
	t.eq(centres.size(), wagons, "%s: çizilen vagon sayısı tutmuyor" % label)

	# Çakışma yok: her vagonun merkezi bir öncekinden en az bir vagon
	# genişliği kadar geride. Bu kolonun iki kez bozulan özelliği.
	var wagon_w := BAND.y * caravan.get_column_scale() * RoadCaravan.WAGON_WIDTH_RATIO
	for index in range(1, centres.size()):
		t.ok(
			centres[index - 1] - centres[index] >= wagon_w,
			"%s: %d. ve %d. vagon üst üste biniyor" % [label, index, index + 1]
		)

	# **Öküz kendi vagonuna koşulu.** Aralarına bir tayfa konmuştu ve
	# ekranda öküz o vagonu çeken hayvan gibi değil, önünde yürüyen
	# başıboş bir hayvan gibi duruyordu: aradaki mesafe (128 px) vagonun
	# kendisinden (67 px) neredeyse iki kat genişti. Koşum yerine hiçbir
	# şey giremez.
	var ox_centres: Array[float] = caravan.get_ox_centres()
	t.eq(ox_centres.size(), wagons, "%s: öküz sayısı vagon sayısını tutmuyor" % label)
	var ox_w := BAND.y * caravan.get_column_scale() * RoadCaravan.OX_HEIGHT_RATIO * 2.0
	for index in mini(ox_centres.size(), centres.size()):
		var clearance := (ox_centres[index] - ox_w * 0.5) - (centres[index] + wagon_w * 0.5)
		t.ok(
			clearance >= 0.0,
			"%s: %d. öküz vagonun içine girdi (%.0f)" % [label, index + 1, clearance]
		)
		t.ok(
			clearance <= wagon_w * 0.6,
			"%s: %d. öküz vagonundan kopuk (%.0f px, vagon %.0f px)" % [
				label, index + 1, clearance, wagon_w
			]
		)

	# İlk `FULLY_VISIBLE_WAGONS` vagon **koşulsuz** ekranda. Şart koymak
	# ("ölçek tabana dayanmadıysa") tam olarak korumak istediği şeyi
	# kapatıyordu: çapayı eski sabitine geri çeken bir mutasyonda ölçek
	# tabana iniyor, iddia da kendini kapatıp sessizce geçiyordu -
	# `test_combat_dd.gd`'nin sersemletme iddiasında da yaşanan hata,
	# korunan sabitin kendisiyle ölçmek.
	for index in mini(centres.size(), FULLY_VISIBLE_WAGONS):
		t.ok(
			centres[index] - wagon_w * 0.5 > 0.0,
			"%s: %d. vagon karenin solunda kaldı (%.0f)" % [
				label, index + 1, centres[index]
			]
		)

func _test_a_small_caravan_is_not_shrunk(t) -> void:
	# Küçültme yalnızca sığmayan kolon için. Başlangıç kervanı (bir vagon,
	# iki kişi) tam boyunda kalmalı, yoksa "sığdırma" sessizce bütün oyunun
	# ölçeğini değiştiren bir ayara dönüşür.
	var caravan := _build(1, 2)
	t.almost(
		caravan.get_column_scale(), 1.0,
		"başlangıç kervanı gereksiz yere küçültüldü", 0.001
	)

## Geri dönüş: kervan **yerinde, sırayla** dönüyor (bkz. RoadCaravan'ın
## TURN_SECONDS notu). Sıra değişmiyor - arkadaki vagon artık önde -,
## emir baştan kuyruğa iniyor, lider yeni başa sürüyor, ve dönüş bitince
## kolon tam aynalı: her birim sola bakıyor.
func _test_turnaround(t) -> void:
	var caravan := _build(3, 3, 1, 1, 0)
	var before: Array[float] = caravan.get_wagon_centres().duplicate()
	var finished := [false]
	caravan.turn_finished.connect(func() -> void: finished[0] = true)
	caravan.begin_turn(-1.0)
	t.ok(caravan.is_turning(), "dönüş başladı")

	# İlk birim son birimden önce dönmeye başlıyor: emir dalga gibi iniyor.
	var first_started := -1.0
	var last_started := -1.0
	var elapsed := 0.0
	var step := 1.0 / 30.0
	while caravan.is_turning() and elapsed < RoadCaravan.TURN_SECONDS + 1.0:
		caravan._process(step)
		elapsed += step
		var facings: Array[float] = caravan.get_unit_facings()
		if first_started < 0.0 and facings[0] < 0.999:
			first_started = elapsed
		if last_started < 0.0 and facings[facings.size() - 1] < 0.999:
			last_started = elapsed
	t.ok(finished[0], "dönüş bitince haber veriyor")
	t.ok(absf(elapsed - RoadCaravan.TURN_SECONDS) < 0.1, "dönüş on saniye sürüyor (%.2f)" % elapsed)
	t.ok(first_started > 0.0 and last_started > first_started, "birimler baştan kuyruğa sırayla dönüyor")
	t.eq(caravan.get_heading(), -1.0, "dönüşten sonra kervan geri bakıyor")
	for facing in caravan.get_unit_facings():
		t.eq(facing, -1.0, "her birim tam dönmüş")

	# Vagonlar yerinde döndü: merkezleri kaymadı, sıra aynı.
	var after: Array[float] = caravan.get_wagon_centres()
	for index in before.size():
		t.ok(absf(after[index] - before[index]) < 0.5, "%d. vagon yerinde dönüyor" % (index + 1))

	# Lider yeni başta: her şeyin solunda, ve kolonda "0" yeni baş.
	var leader := caravan.get_leader_centre()
	for centre in after:
		t.ok(leader < centre, "lider dönmüş kolonun önünde (solunda)")
	for centre in caravan.get_pack_centres():
		t.ok(leader < centre, "yük hayvanları artık liderin arkasında")
	t.eq(caravan.get_leader_offset(), 0.0, "dönüşten sonra lider başta")

	# Aynalı kolonda dokunarak yürümek: liderin yerine dokunmak yerinde tutar,
	# kolonun sağ ucuna dokunmak onu kuyruğa götürür.
	t.ok(absf(caravan.leader_offset_for_x(leader)) < 0.5, "aynalı kolonda liderin yeri 0")
	t.ok(
		absf(caravan.leader_offset_for_x(99999.0) + caravan.get_column_length()) < 0.5,
		"aynalı kolonda sağa dokunmak kuyruğa yürütür"
	)
	caravan.set_leader_offset(-caravan.get_column_length() * 0.5)
	t.ok(caravan.get_leader_centre() > leader, "aynalı kolonda geri gitmek sağa gitmek")

	# Karşılaşmanın burnu: dönmüş kervanın önü artık solda, kolonun boyu kadar.
	t.ok(caravan.get_front_offset() > caravan.get_trailing_length() * caravan.get_column_scale(),
		"dönmüş kervanın burnu çapadan kolon boyu kadar uzakta")

	# Geri dönmek de aynı yol: kervan yeniden hedefe bakıyor.
	caravan.begin_turn(1.0)
	var guard := 0.0
	while caravan.is_turning() and guard < RoadCaravan.TURN_SECONDS + 1.0:
		caravan._process(step)
		guard += step
	t.eq(caravan.get_heading(), 1.0, "ikinci dönüş kervanı yeniden ileri çeviriyor")
	var forward_leader := caravan.get_leader_centre()
	for centre in caravan.get_wagon_centres():
		t.ok(forward_leader > centre, "ileri dönmüş kervanda lider yine önde (sağda)")

## Lider zemine göre iki yönde aynı hızla gidiyor: kervanın ters yönüne
## giderken kolonun akışı eklenir. Eskiden geri giden atlı zemine göre
## neredeyse yerinde sayıyordu.
func _test_leader_speed_is_symmetric(t) -> void:
	var road := load("res://scripts/ui/road_journey.gd")
	var column := 20.0
	var ride := 96.0
	for heading in [1.0, -1.0]:
		var ahead: float = road.leader_screen_speed(heading, heading, column, ride)
		var back: float = road.leader_screen_speed(-heading, heading, column, ride)
		t.ok(absf((ahead + heading * column) - heading * ride) < 0.01, "ileri: zemine göre atın hızı")
		t.ok(absf((back + heading * column) + heading * ride) < 0.01, "geri: zemine göre yine atın hızı")
	# Kervan attan hızlı aksa da ileri tutulan tuş lideri öne götürür.
	var fast: float = road.leader_screen_speed(1.0, 1.0, 300.0, ride)
	t.ok(fast > 0.0, "hızlı akışta bile lider tuşun yönüne gidiyor")
	t.eq(RoadCaravan.leader_step_for(0.0), 0.0, "duran lider adım atmıyor")
	t.ok(RoadCaravan.leader_step_for(-50.0) < 0.0, "sola giden liderin adımı sola")

## Sola yürüyen figür fazını ileri sarıyor: iskelet aynalandığı için fazı
## geri sarmak geri geri yürümekti.
func _test_walking_left_is_not_a_moonwalk(t) -> void:
	var figure := WalkFigure.new()
	figure.set_kind(WalkFigure.KIND_PERSON, "guard")
	figure.set_phase_offset(1.0)
	figure.advance(0.1, -2.0)
	t.ok(figure._phase > 1.0, "sola yürürken faz ileri akıyor")
	t.eq(figure._facing, -1.0, "sola yürüyen sola bakıyor")
	figure.free()
