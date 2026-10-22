class_name Temperature
extends RefCounted

## Yolun sıcaklığı, Celsius derecesiyle (Ana Hedefler'deki sıcaklık maddesi).
## Mevsim, haritadaki iklim (kuzey soğuk, güney sıcak), biyom, saat ve günün
## havası bir derece üretir.
##
## **Hesaplanıyor, saklanmıyor** - `RouteWeather` ile aynı gerekçe: aynı yolda
## aynı gün aynı soğuk; kaydı yeniden yükleyen oyuncu ayazı kapatamaz.
##
## **Yeni sistem uydurmuyor.** Soğuğun bütün etkisi var olan kolları
## çeviriyor: gece soğuğu kişinin stresine ve yorgunluğuna (giysisinin
## sıcaklığı ve kamp ateşi bunu indirir), ayaz ateşe (humma şansı), tayfanın
## üşümesi morale, dondurucu gün erzak payına. Erzak payı planlayıcının
## önceden bildiği bir sayı, yoksa "doğru stoklayan asla aç kalmaz" sözü
## kışın sessizce bozulurdu (bkz. `forecast_ration_shares`).

## Mevsimin ortasındaki ortalama; iki mevsim ortası arası doğrusal geçiyor,
## yoksa mevsim değiştiği sabah sıcaklık on derece sıçrardı.
## Sıra `MarketConditions.Season` ile aynı: ilkbahar, yaz, sonbahar, kış.
const SEASON_MEAN: Array[float] = [11.0, 22.0, 10.0, -3.0]

## Haritanın iklimi (`settlements.json` `climate`, bkz. Rendered Road Rules):
## kuzey soğuk, güney sıcak. Haritada olmayan yol ılıman.
const CLIMATE_OFFSET: Dictionary = {"cold": -7.0, "warm": 6.0}

## Biyomun kendi payı: dağ yüksek ve soğuk, çayır vadide biraz ılık.
const BIOME_OFFSET: Dictionary = {
	ArtPalette.BIOME_MOUNTAIN: -7.0,
	ArtPalette.BIOME_FOREST: -1.0,
	ArtPalette.BIOME_MEADOW: 1.0,
}

## Gece-gündüz farkının yarısı. Bozkır ve dağ açık: gündüz yakar, gece
## dondurur; göl ve orman ısıyı tutar.
const BIOME_SWING: Dictionary = {
	ArtPalette.BIOME_STEPPE: 8.0,
	ArtPalette.BIOME_MOUNTAIN: 7.0,
	ArtPalette.BIOME_MEADOW: 6.0,
	ArtPalette.BIOME_FOREST: 4.0,
	ArtPalette.BIOME_LAKE: 3.0,
	ArtPalette.BIOME_MARSH: 4.0,
}
const DEFAULT_SWING: float = 5.0

## Hava: bulut gece-gündüz farkını kapatır, yağmur ve fırtına soğutur.
const WEATHER_OFFSET: Dictionary = {
	RouteWeather.OVERCAST: -1.0,
	RouteWeather.RAIN: -3.0,
	RouteWeather.FOG: -2.0,
	RouteWeather.STORM: -5.0,
}
const WEATHER_SWING_SCALE: Dictionary = {
	RouteWeather.OVERCAST: 0.5,
	RouteWeather.RAIN: 0.4,
	RouteWeather.FOG: 0.5,
	RouteWeather.STORM: 0.3,
}

## Günün en sıcak saati; en soğuğu on iki saat sonra (03:00).
const WARMEST_HOUR: float = 15.0

## Bu derecenin altında, giysisiz bir beden üşür (vagonun altında, battaniyeyle).
## Köylü takımı (~4 °C sıcaklık) sıfırın altına inen gecede üşür, kışın donar; kalın
## giyinmiş biri (~19 °C) kuzey bozkırının kış gecesini (~−18) ateş başında
## atlatır, ateşsiz donar - açıkta ayazda uyumak giysiyle çözülmüyor.
const COMFORT_C: float = 6.0
## Kamp ateşinin başında geçen gece bu kadar ılık sayılır.
const CAMPFIRE_WARMTH: float = 10.0
## Tayfanın giysisi (isimsiz, köylü takımı).
const CREW_WARMTH: float = 4.0
## Beden: iri beden yağıyla ısınır, ince beden çabuk üşür. Orta kilo nötr
## (A body is three dials - orta değer sistem yokmuş gibi davranır).
const BODY_WEIGHT_WARMTH: Array[float] = [-2.0, 0.0, 2.0]

## Soğuk yükü (konfor eksi gece) bandı: 0 yok, 1 üşüyor, 2 donuyor, 3 ayaz.
const BAND_CHILLED: float = 0.5
const BAND_FREEZING: float = 8.0
const BAND_FROSTBITE: float = 16.0
## Banda göre gece bedeli: stres, yorgunluk; ayazda humma şansı.
const BAND_STRESS: Array[int] = [0, 1, 2, 4]
const BAND_FATIGUE: Array[int] = [0, 0, 3, 6]
const FROSTBITE_FEVER_BONUS: float = 0.04
## Tayfa donarsa moral (isimsizler kişisel stres almıyor, açlıkla aynı kural).
const CREW_BAND_MORALE: Array[int] = [0, 0, -1, -2]

## Dondurucu günde herkes daha çok yer: günlük erzak çarpanına eklenen pay.
const RATION_FREEZE_C: float = 0.0
const RATION_HARD_FREEZE_C: float = -12.0
const RATION_SHARE_FREEZE: float = 0.25
const RATION_SHARE_HARD: float = 0.5
## Planlayıcı payı bugünün konumunda değil, kervanın bu pencere içinde
## olabileceği her parçanın en soğuğunda hesaplıyor: hızlı tempoyla erken,
## yavaşla geç varılan bir dağ parçası payı bozmasın.
const FORECAST_BEHIND_DAYS: float = 1.0
const FORECAST_AHEAD_DAYS: float = 2.0

## "−4 °C" - eksi işareti tire değil gerçek eksi.
static func round_text(c: float) -> String:
	var n := roundi(c)
	return ("−%d" % absi(n) if n < 0 else "%d" % n) + " °C"

## Mevsimin günlük ortalaması, iki mevsim ortası arasında doğrusal.
static func seasonal_mean(day: int) -> float:
	var length := float(MarketConditions.SEASON_LENGTH_DAYS)
	var t := float(maxi(0, day)) / length - 0.5
	var index := floori(t)
	var share := t - float(index)
	var a := SEASON_MEAN[posmod(index, 4)]
	var b := SEASON_MEAN[posmod(index + 1, 4)]
	return lerpf(a, b, share)

static func daily_mean(day: int, biome: String, climate: String, weather: String) -> float:
	return (
		seasonal_mean(day)
		+ float(CLIMATE_OFFSET.get(climate, 0.0))
		+ float(BIOME_OFFSET.get(biome, 0.0))
		+ float(WEATHER_OFFSET.get(weather, 0.0))
	)

static func swing(biome: String, weather: String) -> float:
	return float(BIOME_SWING.get(biome, DEFAULT_SWING)) * float(WEATHER_SWING_SCALE.get(weather, 1.0))

## Günün `hour` saatindeki derece.
static func celsius(day: int, hour: float, biome: String, climate: String, weather: String) -> float:
	var phase := (hour - WARMEST_HOUR) / 24.0 * TAU
	return daily_mean(day, biome, climate, weather) + swing(biome, weather) * cos(phase)

## Gecenin en soğuğu (03:00).
static func daily_low(day: int, biome: String, climate: String, weather: String) -> float:
	return daily_mean(day, biome, climate, weather) - swing(biome, weather)

static func daily_high(day: int, biome: String, climate: String, weather: String) -> float:
	return daily_mean(day, biome, climate, weather) + swing(biome, weather)

## Dondurucu günün erzak payı (0, 0.25 ya da 0.5).
static func ration_share(low_c: float) -> float:
	if low_c < RATION_HARD_FREEZE_C:
		return RATION_SHARE_HARD
	if low_c < RATION_FREEZE_C:
		return RATION_SHARE_FREEZE
	return 0.0

## Gece soğuğunun bir bedene yükü: konfordan ne kadar aşağıda kaldığı.
static func cold_load(low_c: float, warmth: float, by_fire: bool) -> float:
	var felt := low_c + (CAMPFIRE_WARMTH if by_fire else 0.0)
	return maxf(0.0, COMFORT_C - felt - warmth)

static func band(load: float) -> int:
	if load >= BAND_FROSTBITE:
		return 3
	if load >= BAND_FREEZING:
		return 2
	if load >= BAND_CHILLED:
		return 1
	return 0

## Bir parçanın bir gününün gece soğuğu - yol ekranı ve planlayıcı aynı
## formülü okusun diye segment sözlüğünden (RouteTerrain).
static func segment_low(route_key: String, day: int, segment: Dictionary) -> float:
	var biome := String(segment.get("biome", ArtPalette.FALLBACK_BIOME))
	var climate := String(segment.get("climate", ""))
	return daily_low(day, biome, climate, RouteWeather.at(route_key, day, biome))

## Planlayıcının erzak payı: `forecast_extra_days` ile aynı günlük yürüyüş,
## her gün için kervanın o pencere içinde girebileceği parçaların en soğuk
## gecesinin payı. Dizinin uzunluğu yolun gerçekte süreceği gün sayısı.
static func forecast_ration_shares(
	route_key: String, start_day: int, terrain: RouteTerrain, travel_days: int,
	condition_factor: float = 1.0, walking_hours: float = 24.0
) -> Array[float]:
	var shares: Array[float] = []
	var days := maxi(1, travel_days)
	var walked := 0.0
	var spent := 0
	var condition := clampf(condition_factor, 0.05, 1.0)
	var day_share := clampf(walking_hours / 24.0, 0.05, 1.0)
	while walked < float(days) and spent < days * 6 + 12:
		var day := start_day + spent
		shares.append(_window_share(route_key, day, terrain, walked))
		var biome := ArtPalette.FALLBACK_BIOME
		var slope := 1.0
		if terrain != null:
			biome = terrain.biome_at(walked)
			slope = terrain.speed_factor_at(walked)
		var weather := RouteWeather.at(route_key, day, biome)
		walked += RouteWeather.pace_multiplier(weather) * condition * slope * day_share
		spent += 1
	return shares

static func _window_share(route_key: String, day: int, terrain: RouteTerrain, at_day: float) -> float:
	if terrain == null:
		return ration_share(daily_low(day, ArtPalette.FALLBACK_BIOME, "", RouteWeather.at(route_key, day, ArtPalette.FALLBACK_BIOME)))
	var lo := at_day - FORECAST_BEHIND_DAYS
	var hi := at_day + FORECAST_AHEAD_DAYS
	var best := 0.0
	for segment in terrain.segments:
		if float(segment.get("to_day", 0.0)) < lo or float(segment.get("from_day", 0.0)) > hi:
			continue
		best = maxf(best, ration_share(segment_low(route_key, day, segment)))
	return best
