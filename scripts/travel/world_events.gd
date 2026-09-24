class_name WorldEvents
extends RefCounted

## Haritanın büyük, adlı olayları - bölgesel savaş, veba/karantina, ticaret
## fuarı, haydut kralının haraç bölgesi. `MarketConditions`in "süreli şok"
## desenini (bkz. `_shocks`) rota ve şehir hedeflerine genelleştiriyor:
## aynı vokabüler, iki hedef türü. Sahne ağacına bağlı değil, GameSession'ın
## içinde yaşar ve kaydedilir.
##
## Bilerek arka planda kendiliğinden atılmıyor (`RouteConditions`'ın doğal
## durumları gibi bir "hava" değil): bir rota/olay motoru olayı
## (`EventEffect.Type.WORLD_EVENT_START`, bkz. `evt_regional_war_news` ve
## kardeşleri) başlatır - yolda duyulan bir haber, aniden beliren bir hava
## durumu değil. `advance_day()` yalnızca süresi dolanları düşürür.

enum Kind { REGIONAL_WAR, PLAGUE, TRADE_FAIR, BANDIT_TRIBUTE }

const KIND_IDS: Dictionary = {
	"war": Kind.REGIONAL_WAR,
	"plague": Kind.PLAGUE,
	"trade_fair": Kind.TRADE_FAIR,
	"bandit_tribute": Kind.BANDIT_TRIBUTE,
}

const KIND_LABEL_KEYS: Dictionary = {
	Kind.REGIONAL_WAR: "WORLD_EVENT_WAR_LABEL",
	Kind.PLAGUE: "WORLD_EVENT_PLAGUE_LABEL",
	Kind.TRADE_FAIR: "WORLD_EVENT_TRADE_FAIR_LABEL",
	Kind.BANDIT_TRIBUTE: "WORLD_EVENT_BANDIT_TRIBUTE_LABEL",
}

## İki hedef türü var: rota (route_key ile) ya da şehir (location_id ile).
## Savaş ve haraç bölgesi yolu vurur - yolda karşına çıkarlar; veba ve
## fuar bir şehri vurur - varınca karşına çıkarlar.
const ROUTE_KINDS: Array[Kind] = [Kind.REGIONAL_WAR, Kind.BANDIT_TRIBUTE]
const CITY_KINDS: Array[Kind] = [Kind.PLAGUE, Kind.TRADE_FAIR]

## Rota tehlikesine eklenen headroom-delta - `RouteConditions.DANGER_DELTA`
## ile aynı formül (`base + delta * (1 - base)`, bkz. GameSession.
## get_route_danger), Route Rules'un "delta tabanın kendisine değil
## headroom'a uygulanır" kuralı burada da geçerli.
const ROUTE_DANGER_DELTA: Dictionary = {
	Kind.REGIONAL_WAR: 0.30,
	Kind.BANDIT_TRIBUTE: 0.18,
}

## Şehir çapında fiyat şoku - `MarketConditions.add_shock()`'un aynısı,
## yeni bir fiyat kodu yok. Veba darlık, fuar bolluk.
const CITY_PRICE_MULTIPLIER: Dictionary = {
	Kind.PLAGUE: 1.6,
	Kind.TRADE_FAIR: 0.75,
}

const MIN_DURATION_DAYS: int = 8
const MAX_DURATION_DAYS: int = 30

## Her giriş {"kind": Kind, "target": route_key ya da location_id,
## "started_day": int, "until_day": int}.
var _events: Array[Dictionary] = []

static func kind_from_id(kind_id: String) -> Kind:
	return int(KIND_IDS.get(kind_id, Kind.REGIONAL_WAR)) as Kind

static func is_route_kind(kind: Kind) -> bool:
	return ROUTE_KINDS.has(kind)

static func get_label_key(kind: Kind) -> String:
	return String(KIND_LABEL_KEYS.get(kind, ""))

func add_event(kind: Kind, target: String, day: int, duration_days: int) -> void:
	var clamped_duration := clampi(duration_days, MIN_DURATION_DAYS, MAX_DURATION_DAYS)
	_events.append({
		"kind": kind,
		"target": target,
		"started_day": day,
		"until_day": day + clamped_duration,
	})

func get_active(day: int) -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for entry in _events:
		if int(entry["until_day"]) >= day:
			active.append(entry)
	return active

func get_route_events(route_key: String, day: int) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for entry in get_active(day):
		if String(entry["target"]) == route_key and ROUTE_KINDS.has(int(entry["kind"]) as Kind):
			matches.append(entry)
	return matches

func get_city_events(location_id: String, day: int) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for entry in get_active(day):
		if String(entry["target"]) == location_id and CITY_KINDS.has(int(entry["kind"]) as Kind):
			matches.append(entry)
	return matches

## Rota tehlikesinin okuduğu tek kapı - birden çok olay aynı rotayı
## vurursa (savaş + haraç) payları toplanır, RouteConditions'ın kendi
## delta'sının yanına eklenir.
func get_route_danger_delta(route_key: String, day: int) -> float:
	var delta := 0.0
	for entry in get_route_events(route_key, day):
		delta += float(ROUTE_DANGER_DELTA.get(int(entry["kind"]), 0.0))
	return delta

func has_kind_on_route(kind: Kind, route_key: String, day: int) -> bool:
	for entry in get_route_events(route_key, day):
		if int(entry["kind"]) == int(kind):
			return true
	return false

func has_kind_on_city(kind: Kind, location_id: String, day: int) -> bool:
	for entry in get_city_events(location_id, day):
		if int(entry["kind"]) == int(kind):
			return true
	return false

## Hedeften bağımsız - "lonca haritanın herhangi bir yerinde süren bir X
## duydu mu" sorusu (bkz. GameSession'ın lonca özel görevleri). Kervanın
## o an nerede olduğuna bakmaz, world_events zaten harita çapında tek bir
## liste.
func get_active_by_kind(kind: Kind, day: int) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for entry in get_active(day):
		if int(entry["kind"]) == int(kind):
			matches.append(entry)
	return matches

func advance_day(day: int) -> void:
	var living: Array[Dictionary] = []
	for entry in _events:
		if int(entry["until_day"]) >= day:
			living.append(entry)
	_events = living

func to_save_dict() -> Dictionary:
	return {"events": _events.duplicate(true)}

func load_from_dict(data: Dictionary) -> void:
	_events = []
	for entry in (data.get("events", []) as Array):
		var source: Dictionary = entry
		_events.append({
			"kind": int(source.get("kind", 0)),
			"target": str(source.get("target", "")),
			"started_day": int(source.get("started_day", 0)),
			"until_day": int(source.get("until_day", 0)),
		})
