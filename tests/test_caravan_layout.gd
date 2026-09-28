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
