class_name PlagueWorld
extends RefCounted

## Vebanın arka plandaki modeli (görev Y-C25, kullanıcı düzeltmesi 2026-10-31:
## "veba kendiliğinden gitmez, arkaplanda bunu bir popülasyon, bulaşma,
## şehirler arası ilişki gibi sistemler kurup mantığını oturtmalıyız").
##
## Her yerleşimin bir nüfusu ve üç payı var: sağlam (s), hasta (i), iyileşmiş
## (r). Her gün:
## - şehrin içinde bulaşma: sağlamın bir kısmı hastalanır (hasta payı ve
##   bölgenin yatkınlığıyla orantılı),
## - yollar boyunca sızma: komşu şehirlerin hastası yolcularla gelir; yol
##   uzunsa daha az,
## - hastaların bir kısmı iyileşir, bir kısmı ölür (ölüler sayılır),
## - iyileşenlerin bağışıklığı yavaş söner: veba bir yerden "kalkmaz",
##   yeni dalga için zemin yeniden birikir.
## Kervan da taşır: vebalı şehirden gelen kervan vardığı yere hastalık
## götürür (`carry`). Kimse vebayı bildirmez; oyuncu onu görür ya da duyar
## (GameSession.plague_news).
##
## Gokyurt (göçebe) kıtanın en sağlıklı yeri: yatkınlığı en düşük, vadi en
## yüksek (bölge payları WorldEvents.PLAGUE_REGION_SHARE).

const POPULATION: Dictionary = {"city": 9000, "town": 3000, "caravanserai": 400}
## Bulaşma: günlük temas katsayısı; bölgenin yatkınlığıyla çarpılır.
const BETA: float = 0.12
## Hastalık ~10 gün sürer.
const GAMMA: float = 0.09
## Hastaların günlük ölüm payı.
const MU: float = 0.010
## Komşu şehirden yolla sızma (yol günü başına söner).
const ROUTE_MIX: float = 0.02
## İyileşmişin bağışıklığı söner: ~150 günde sağlama döner.
const IMMUNITY_FADE: float = 0.0065
## Kervanın taşıdığı hasta payı.
const CARRY: float = 0.006
## Bu payın üstü "vebalı" sayılır: kapıda görülür, hekim yetişemez.
const VISIBLE: float = 0.02
## Salgının başladığı şehir sayısı (en yatkın bölgelerden).
const SEED_CITIES: int = 2
const SEED_SHARE: float = 0.015

var cities: Dictionary = {}

## Yeni dünya: herkes sağlam, en yatkın bölgelerden iki şehirde salgın başlamış.
func setup(world_seed: int) -> void:
	cities.clear()
	var candidates: Array[String] = []
	for location in WorldMapData.get_locations():
		var pop := int(POPULATION.get(location.settlement_type, 1500))
		pop = int(round(pop * (0.8 + float(absi(hash(location.location_id)) % 40) / 100.0)))
		cities[location.location_id] = {"pop": pop, "s": 1.0, "i": 0.0, "r": 0.0, "dead": 0}
		if susceptibility(location.region) >= 1.2:
			candidates.append(location.location_id)
	candidates.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed ^ 0x51A6
	for _n in mini(SEED_CITIES, candidates.size()):
		var id: String = candidates[rng.randi_range(0, candidates.size() - 1)]
		candidates.erase(id)
		_infect(id, SEED_SHARE)

## Bölgenin yatkınlığı: vadi ~1.4, Gokyurt ~0.76.
static func susceptibility(region: String) -> float:
	return 0.6 + float(WorldEvents.PLAGUE_REGION_SHARE.get(region, 0.2)) * 2.0

## Bir gün geçer: önce herkesin dünkü hasta payı okunur, sonra hepsi birlikte
## güncellenir (sıra bir şehri ötekinden önce hasta etmesin).
func step() -> void:
	var before := {}
	for id in cities:
		before[id] = float(cities[id]["i"])
	for id in cities:
		var c: Dictionary = cities[id]
		var location := WorldMapData.get_location_by_id(id)
		var beta := BETA * susceptibility(location.region if location != null else "")
		var pressure := float(before[id])
		for route in WorldMapData.get_routes_from(id):
			pressure += ROUTE_MIX * float(before.get(route.to_location_id, 0.0)) / float(maxi(1, route.travel_days))
		var s := float(c["s"])
		var i := float(c["i"])
		var r := float(c["r"])
		var infected := minf(s, s * beta * pressure)
		var recovered := GAMMA * i
		var died := MU * i
		var faded := IMMUNITY_FADE * r
		c["s"] = clampf(s - infected + faded, 0.0, 1.0)
		c["i"] = clampf(i + infected - recovered - died, 0.0, 1.0)
		c["r"] = clampf(r + recovered - faded, 0.0, 1.0)
		c["dead"] = int(c["dead"]) + int(round(died * float(c["pop"])))

## Vebalı bir yerden gelen kervan hastalığı vardığı yere götürür.
func carry(from_id: String, to_id: String) -> void:
	if is_sick(from_id) and cities.has(to_id):
		_infect(to_id, CARRY)

func is_sick(location_id: String) -> bool:
	return cities.has(location_id) and float(cities[location_id]["i"]) >= VISIBLE

func sick_share(location_id: String) -> float:
	return float((cities.get(location_id, {}) as Dictionary).get("i", 0.0))

func dead(location_id: String) -> int:
	return int((cities.get(location_id, {}) as Dictionary).get("dead", 0))

func _infect(location_id: String, share: float) -> void:
	var c: Dictionary = cities[location_id]
	var moved := minf(share, float(c["s"]))
	c["s"] = float(c["s"]) - moved
	c["i"] = float(c["i"]) + moved

func to_dict() -> Dictionary:
	return cities.duplicate(true)

func load_from_dict(data: Dictionary) -> void:
	cities = data.duplicate(true)
