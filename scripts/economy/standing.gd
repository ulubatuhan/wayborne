class_name Standing
extends RefCounted

## Bölgesel itibar ve hizipler (görev Y-C12, T16-07; sütun: Yol yaşar, Defter unutmaz).
##
## Tek bir global itibar yerine her bölgenin kendi gözü var: Vadi'de sevilen bir
## kervanı Vaelghard tanımaz, Avuçiçi'nde sevilen bir kervan kâfir şehirlerde
## şüpheyle karşılanır. Ama "bir bölgede çok itibarlı olup öbüründe hiç
## tanınmamak da olmaz" (kullanıcı): bir bölgede kazanılan itibar öbürlerine
## jeopolitik ağırlıkla yayılır (`data/config/standing.json`, LORE §12). Değerler
## ondalıklı tutulur (5 × 0.1 = 0,5 kaybolmasın), dışarıya tam sayı verilir.
##
## Hizipler bölgeden bağımsız: lonca (kontrat ve kredi), kilise (inanç
## toplulukları), kardeşlik (yolun haydutları). Bir hizip bir kapıyı açar ya da
## kapatır; hangisi olduğu GameSession'daki okuyucularda yazılı.

const DATA_PATH: String = "res://data/config/standing.json"
const MIN_VALUE: float = -20.0
const MAX_VALUE: float = 100.0
const GUILD: String = "lonca"
const CHURCH: String = "kilise"
const BROTHERHOOD: String = "kardeslik"

static var _data: Dictionary = {}
static var _neighbours: Dictionary = {}

var regions: Dictionary = {}
var factions: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = parsed if parsed is Dictionary else {"regions": {}, "relations": [], "factions": {}}
	return _data

static func region_ids() -> Array:
	return (data().get("regions", {}) as Dictionary).keys()

static func faction_ids() -> Array:
	return (data().get("factions", {}) as Dictionary).keys()

static func faction_name_key(faction_id: String) -> String:
	return String(((data().get("factions", {}) as Dictionary).get(faction_id, {}) as Dictionary).get("name_key", faction_id))

## Bir bölgede kazanılan itibarın öbür bölgeye geçen payı. Önce lore'daki
## ilişki (dostluk, düşmanlık, borç), yoksa yol komşuluğu, yoksa uzaklık.
static func spill(from_region: String, to_region: String) -> float:
	if from_region == to_region:
		return 1.0
	for relation in data().get("relations", []):
		var r: Dictionary = relation
		if (r["a"] == from_region and r["b"] == to_region) or (r["a"] == to_region and r["b"] == from_region):
			return float(r["spill"])
	if _are_neighbours(from_region, to_region):
		return float(data().get("neighbour", 0.1))
	return float(data().get("far", 0.03))

## Yol komşuluğu haritadan: iki bölgenin yerleşimleri arasında bir yol var mı.
static func _are_neighbours(a: String, b: String) -> bool:
	if _neighbours.is_empty():
		for from in WorldMapData.get_locations():
			for route in WorldMapData.get_routes_from(from.location_id):
				var to := WorldMapData.get_location_by_id(route.to_location_id)
				if to == null or from.region == to.region:
					continue
				_neighbours["%s|%s" % [from.region, to.region]] = true
				_neighbours["%s|%s" % [to.region, from.region]] = true
	return _neighbours.has("%s|%s" % [a, b])

## Bütün bölgeleri aynı değerle açar (yeni oyun ve itibarı tek sayı olan eski kayıt).
func reset(value: float = 0.0) -> void:
	regions.clear()
	for id in region_ids():
		regions[id] = clampf(value, MIN_VALUE, MAX_VALUE)
	factions.clear()
	for id in faction_ids():
		factions[id] = 0.0

func region(region_id: String) -> int:
	return int(round(float(regions.get(region_id, 0.0))))

func faction(faction_id: String) -> int:
	return int(round(float(factions.get(faction_id, 0.0))))

## Bir bölgede itibar değişir, öbürlerine yayılır. Dönen: o bölgedeki tam sayı farkı.
func change_region(region_id: String, delta: float) -> int:
	var before := region(region_id)
	for id in region_ids():
		var share := spill(region_id, String(id))
		if share == 0.0:
			continue
		regions[id] = clampf(float(regions.get(id, 0.0)) + delta * share, MIN_VALUE, MAX_VALUE)
	if not regions.has(region_id):
		# Haritada bölgesi bilinmeyen yer (sentetik sefer): yine kendisi yazılır.
		regions[region_id] = clampf(delta, MIN_VALUE, MAX_VALUE)
	return region(region_id) - before

## Doğrudan değer (eski `reputation = x` yazımları ve testler): yayılmaz.
func set_region(region_id: String, value: float) -> void:
	regions[region_id] = clampf(value, MIN_VALUE, MAX_VALUE)

func change_faction(faction_id: String, delta: float) -> int:
	var before := faction(faction_id)
	factions[faction_id] = clampf(float(factions.get(faction_id, 0.0)) + delta, MIN_VALUE, MAX_VALUE)
	return faction(faction_id) - before

func to_dict() -> Dictionary:
	return {"regions": regions.duplicate(), "factions": factions.duplicate()}

func from_dict(data_in: Dictionary) -> void:
	reset()
	for id in (data_in.get("regions", {}) as Dictionary):
		regions[String(id)] = clampf(float(data_in["regions"][id]), MIN_VALUE, MAX_VALUE)
	for id in (data_in.get("factions", {}) as Dictionary):
		factions[String(id)] = clampf(float(data_in["factions"][id]), MIN_VALUE, MAX_VALUE)
