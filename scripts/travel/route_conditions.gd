class_name RouteConditions
extends RefCounted

## Yolun o günkü hali. Coğrafya sabittir - dağ yerinden oynamaz, bu yüzden
## WorldMapData'nın kenar tablosu (hangi şehir hangisine bağlı, kaç günlük
## mesafede) yerinde kalır. Değişen şey yolun *durumu*: sel basmış bir geçit,
## çığ kapatmış bir boğaz, eşkıya kaynayan bir güzergâh.
##
## MarketPricing/MarketConditions ile aynı bölünme: taban tablo + üstüne
## binen dinamik katman. Katman verilmeyen bir çağıran eski, sabit davranışı
## görür.
##
## Rotalar bu yüzden "sabit yedi kenar" değil: aynı topoloji üstünde her gün
## farklı bir ağ çıkar. Demirkapı'ya giden kısa yol kapandığında Kurtboğazı
## üzerinden dolaşmak (bkz. find_open_path) gerçek bir karar haline gelir.
##
## DOĞAL DURUMLAR SAKLANMAZ, HESAPLANIR. Her rota kendi "nöbet" penceresinde
## (SPELL_DAYS) rota kimliği + pencere numarasından tohumlanmış bir zar atar;
## yani aynı kayıt her açılışta aynı dünyayı verir, kayıt dosyasında tek bir
## bayt tutmadan. Saklanan tek şey olayların açtığı geçici müdahaleler
## (bkz. add_override / EventEffect.Type.ROUTE_CHANGE).

enum State { OPEN, SLOW, PERILOUS, CLOSED }

## Bir doğal durumun sürdüğü gün sayısı. Rota başına kaydırılıyor, yoksa
## bütün yollar aynı gün birden değişirdi.
const SPELL_DAYS: int = 6

## Durum başına yol süresi çarpanı ve tehlike eklentisi (State sırasında).
## SLOW yolu uzatır, PERILOUS uzatmaz ama tehlikeyi yükseltir - biri
## lojistik, diğeri askerî bir sorun.
const DAYS_MULTIPLIER: Array[float] = [1.0, 1.6, 1.0, 1.0]
const DANGER_DELTA: Array[float] = [0.0, 0.05, 0.22, 0.0]

## Pencere başına doğal durum olasılıkları. Tehlikeli rotalar hem daha çok
## eşkıya hem daha çok kapanma görür; kış her ikisini de artırır.
const CHANCE_CLOSED: float = 0.05
const CHANCE_SLOW: float = 0.15
const CHANCE_PERILOUS: float = 0.13
const WINTER_MULTIPLIER: float = 2.2
const DANGER_INFLUENCE: float = 1.0

## Toplam bozulma olasılığının tavanı - hiçbir rota "her zaman kapalı"
## olmamalı, yoksa harita kendi kendini kilitler.
const DISRUPTION_CHANCE_CAP: float = 0.55

## Yönsüz anahtar: çığ iki yönü birden kapatır.
static func route_key(a: String, b: String) -> String:
	return "%s|%s" % [a, b] if a <= b else "%s|%s" % [b, a]

static func get_state_key(state: State) -> String:
	match state:
		State.SLOW:
			return "ROUTE_STATE_SLOW"
		State.PERILOUS:
			return "ROUTE_STATE_PERILOUS"
		State.CLOSED:
			return "ROUTE_STATE_CLOSED"
		_:
			return "ROUTE_STATE_OPEN"

static func get_state_label(state: State) -> String:
	return String(TranslationServer.translate(get_state_key(state)))

static func parse_state(name: String) -> State:
	match name.to_lower():
		"slow":
			return State.SLOW
		"perilous":
			return State.PERILOUS
		"closed":
			return State.CLOSED
		_:
			return State.OPEN

## Olayların açtığı geçici müdahaleler: anahtar -> {"state", "until_day"}.
## Doğal zarın önüne geçer, çünkü olay somut bir sebeple gelir (çığ düştü,
## devriye yolu temizledi) ve oyuncu o sebebi ekranda görmüştür.
var _overrides: Dictionary = {}

func add_override(a: String, b: String, state: State, until_day: int) -> void:
	_overrides[route_key(a, b)] = {"state": int(state), "until_day": until_day}

func clear_override(a: String, b: String) -> void:
	_overrides.erase(route_key(a, b))

func has_override(a: String, b: String, day: int) -> bool:
	var entry: Dictionary = _overrides.get(route_key(a, b), {})
	return not entry.is_empty() and int(entry.get("until_day", 0)) >= day

## Süresi dolan müdahaleler defterden düşer; doğal durumlar zaten
## hesaplandığı için burada bakım gerektirmez.
func advance_day(day: int) -> void:
	var living: Dictionary = {}
	for key in _overrides:
		if int(_overrides[key].get("until_day", 0)) >= day:
			living[key] = _overrides[key]
	_overrides = living

## Zarın ya da olayın söylediği ham hal - emniyet kuralı uygulanmadan önce.
## Ekranlar bunu değil get_state()'i okur; burası yalnızca kuralın kendisi
## ve testler için.
func get_raw_state(route: TravelRoute, day: int) -> State:
	if route == null:
		return State.OPEN
	var key := route_key(route.from_location_id, route.to_location_id)
	var entry: Dictionary = _overrides.get(key, {})
	if not entry.is_empty() and int(entry.get("until_day", 0)) >= day:
		return int(entry.get("state", 0)) as State
	return natural_state(key, route.danger_level, day)

## Yolun oyunun gördüğü hali. Ham hal CLOSED olsa bile bir şehrin **son
## çıkışıysa** kapanmaz, güç bela geçilir hale (SLOW) düşer.
##
## Beş şehrin bazısının yalnızca iki komşusu var; ikisi birden kapandığında
## oyuncu bir kasabada mahsur kalıp oyun duruyordu (bkz. test_route_
## conditions.gd "hiçbir şehir hiçbir gün tamamen kapanmıyor"). Emniyeti
## is_open()'da değil burada uygulamak önemli: süre, tehlike, etiket ve yol
## bulma hepsi get_state()'i okuyor, yani "zar zor geçilen yol" her yerde
## aynı görünüyor - yoksa harita "Geçit kapalı" yazan bir yoldan kervan
## geçirirdi.
##
## Kural iki uca da bakıyor ve yalnızca ham hali okuyor, bu yüzden hem
## simetrik (çığ tek yönlü açılmaz) hem de kendini çağırmıyor.
func get_state(route: TravelRoute, day: int) -> State:
	var raw := get_raw_state(route, day)
	if raw != State.CLOSED:
		return raw
	if (
		_is_last_exit(route.from_location_id, route, day)
		or _is_last_exit(route.to_location_id, route, day)
	):
		return State.SLOW
	return State.CLOSED

func _is_last_exit(location_id: String, route: TravelRoute, day: int) -> bool:
	for other in WorldMapData.get_routes_from(location_id):
		var same_pair := (
			(other.from_location_id == route.from_location_id and other.to_location_id == route.to_location_id)
			or (other.from_location_id == route.to_location_id and other.to_location_id == route.from_location_id)
		)
		if same_pair:
			continue
		if get_raw_state(other, day) != State.CLOSED:
			return false
	return true

func is_open(route: TravelRoute, day: int) -> bool:
	if route == null:
		return false
	return get_state(route, day) != State.CLOSED

## Yolun o günkü gerçek süresi. En az bir gün - çamur bir yolu uzatabilir,
## kısaltamaz.
func get_travel_days(route: TravelRoute, day: int) -> int:
	if route == null:
		return 1
	var state := get_state(route, day)
	return maxi(1, int(round(float(route.travel_days) * DAYS_MULTIPLIER[int(state)])))

## Yolun o günkü ham tehlikesi. Kervanın kendi deneyim eğrisi bunun
## üstüne biner (bkz. GameSession.get_effective_danger) - ikisi ayrı
## katman, biri yola biri oyuna ait.
## Eklenti kalan paya oranla uygulanıyor, ham toplama değil: eşkıya sakin
## bir yolu belirgin tehlikeli yapmalı (%20 → %37), zaten ölümcül bir yolu
## saçmalaştırmamalı (%65 → %90 gibi). Yükseldikçe azalan bir etki, tıpkı
## stat eğrisindeki gibi.
func get_danger(route: TravelRoute, day: int) -> float:
	if route == null:
		return 0.0
	var base := clampf(route.danger_level, 0.0, 1.0)
	var delta := DANGER_DELTA[int(get_state(route, day))]
	return clampf(base + delta * (1.0 - base), 0.0, 1.0)

## Aynı rota + aynı pencere = aynı zar. Kaydı yeniden yüklemek dünyayı
## yeniden atmaz; ileri sarmak da geriye dönmek de aynı yolu gösterir.
static func natural_state(key: String, base_danger: float, day: int) -> State:
	var safe_day := maxi(0, day)
	# Rota başına kaydırma olmasa bütün yollar aynı sabah birden değişirdi.
	var offset := absi(hash(key)) % SPELL_DAYS
	var spell := int(floor(float(safe_day + offset) / float(SPELL_DAYS)))

	# Mevsim pencerenin *başına* göre okunuyor: bir nöbet ortasında kış
	# girdi diye yolun hali gün ortasında değişmesin.
	var spell_start := maxi(0, spell * SPELL_DAYS - offset)
	var winter := MarketConditions.get_season(spell_start) == MarketConditions.Season.WINTER

	var severity := 1.0 + base_danger * DANGER_INFLUENCE
	if winter:
		severity *= WINTER_MULTIPLIER

	var closed := CHANCE_CLOSED * severity
	var slow := CHANCE_SLOW * severity
	var perilous := CHANCE_PERILOUS * severity
	var total := closed + slow + perilous
	if total > DISRUPTION_CHANCE_CAP:
		var scale := DISRUPTION_CHANCE_CAP / total
		closed *= scale
		slow *= scale
		perilous *= scale

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|route_spell" % [key, spell])
	var roll := rng.randf()

	if roll < closed:
		return State.CLOSED
	if roll < closed + slow:
		return State.SLOW
	if roll < closed + slow + perilous:
		return State.PERILOUS
	return State.OPEN

## Kapalı bir yol çıkmaz sokak değil: dolambaçlı yol hâlâ varsa oyuncuya
## gösterilmeli. Dönen dizi şehir kimliklerinin sırası (baştaki from,
## sondaki to); yol yoksa boş döner. En az duraklı yolu bulur - kaçış
## planı değil, gerçek bir alternatif olsun diye.
func find_open_path(from_id: String, to_id: String, day: int) -> Array[String]:
	var empty: Array[String] = []
	if from_id == to_id:
		return empty
	if WorldMapData.get_location_by_id(to_id) == null:
		return empty

	var came_from: Dictionary = {from_id: ""}
	var queue: Array[String] = [from_id]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if current == to_id:
			return _rebuild_path(came_from, from_id, to_id)
		for route in WorldMapData.get_routes_from(current):
			var next_id := route.to_location_id
			if came_from.has(next_id) or not is_open(route, day):
				continue
			came_from[next_id] = current
			queue.append(next_id)
	return empty

func _rebuild_path(came_from: Dictionary, from_id: String, to_id: String) -> Array[String]:
	var reversed_path: Array[String] = []
	var cursor := to_id
	while cursor != "":
		reversed_path.append(cursor)
		if cursor == from_id:
			break
		cursor = str(came_from.get(cursor, ""))

	var path: Array[String] = []
	for index in range(reversed_path.size() - 1, -1, -1):
		path.append(reversed_path[index])
	return path

func to_save_dict() -> Dictionary:
	return {"overrides": _overrides.duplicate(true)}

func load_from_dict(data: Dictionary) -> void:
	_overrides = {}
	var stored: Dictionary = data.get("overrides", {})
	for key in stored:
		var entry: Dictionary = stored[key]
		_overrides[str(key)] = {
			"state": int(entry.get("state", 0)),
			"until_day": int(entry.get("until_day", 0)),
		}
