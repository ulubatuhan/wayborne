class_name Soaking
extends RefCounted

## Kervanın **üstündeki** su ve kar: insanın omzunda, hayvanın sırtında,
## vagonun brandasında. Zeminin karşılığı `GroundCover`; ikisi aynı iki
## girdiyi okuyor (`RouteWeather` + `Temperature`) ama ayrı şeyleri
## biriktiriyor - yol çamur olurken sırtta kuru kar durabilir, kar erirken
## yol su, sırt ıslak olur.
##
## **Hesaplanır, saklanmaz** - `GroundCover`, `RouteWeather` ve
## `Temperature` ile aynı kural. Girdi yalnızca tohumdan türeyen şeyler ve
## kayıtta zaten duran bir sayı (`GameSession.last_fire_day`), yani aynı
## yolun aynı günü her zaman aynı ıslaklık; kaydı yeniden yükleyip üstünü
## kurutmak yok.
##
## **Islaklık bir yaprak değil, bir domino.** Islanan giysi daha az ısıtır
## (`Temperature.cold_load`), yani yağmurlu bir gün soğuk bir geceye
## bindiğinde bedeli stres, yorgunluk ve humma olarak çıkar; kuruma yolu
## ateştir, yani kamp kurmanın görünmeyen bir karşılığı daha olur. Yeni bir
## ceza sistemi değil, var olan kolun çevrilmesi (bkz. kurallar-yol, "Weather
## invents no system").

## Kaç günlük hafıza: dün ıslanan bugün hâlâ nemli.
const MEMORY_DAYS: int = 2
## Bir gün sonra kalan ıslaklık payı. Zeminden hızlı kurur (`GroundCover`
## 0.55): toprak suyu tutar, sırttaki giysi rüzgârda kurur.
const DAY_DRY: float = 0.40
## Ateş yanan gece fazladan kurutur. Kampın görünmeyen karşılığı bu.
const FIRE_DRY: float = 0.45
## Gövde zeminden hızlı ıslanır: yağmur yere değmeden önce omuza değiyor.
const BODY_SOAK: float = 1.15
## Yürüyen bir sırtta kar zeminde durduğunun yarısı kadar durur - kıpırdayan
## omuzdan dökülür, vagonun brandası daha çok tutar (`WAGON_SNOW_HOLD`).
const SNOW_SHED: float = 0.55
const WAGON_SNOW_HOLD: float = 1.5
## Eriyen karın ne kadarı ıslaklığa dönüşür.
const MELT_TO_WET: float = 0.8
## Karın yerde (ve sırtta) durmaya başladığı sıcaklık; üstü `GroundCover`.
const LYING_SNOW_FROM_C: float = GroundCover.LYING_SNOW_FROM_C

## Kervanın o günkü hâli: `wet` ve `snow`, ikisi de 0..1.
## `fire_day` kamp ateşinin en son yandığı gün (`GameSession.last_fire_day`);
## o geceyi kurutur.
static func at(
	route_key: String, day: int, biome: String, climate: String = "",
	fire_day: int = -1
) -> Dictionary:
	var wet := 0.0
	var snow := 0.0
	for back in range(MEMORY_DAYS - 1, -1, -1):
		var d := maxi(1, day - back)
		var weather := RouteWeather.at(route_key, d, biome)
		var mean := Temperature.daily_mean(d, biome, climate, weather)
		# Düşen yağışın payı zeminle aynı tablodan: ekranda bir yağmur var,
		# iki tane değil (bkz. GroundCover.WETTING).
		var falling := float(GroundCover.WETTING.get(weather, 0.0))
		var as_snow := GroundCover.snow_share(mean)
		wet = wet * DAY_DRY + falling * (1.0 - as_snow) * BODY_SOAK
		if mean <= LYING_SNOW_FROM_C:
			snow = snow + falling * as_snow * SNOW_SHED
		else:
			# Erime: sırttaki kar suya döner, yani soğuktan çıkan kervan
			# ısınmaz, sırılsıklam olur.
			var melted := snow * clampf((mean - LYING_SNOW_FROM_C) * 0.45, 0.0, 1.0)
			snow = maxf(0.0, snow - melted)
			wet = wet + melted * MELT_TO_WET
		# **Ateş günün sonunda yanıyor.** İlk sürüm kurutmayı günün
		# *başındaki* taşımaya uyguluyordu, yani yağmurlu bir günde ateşin
		# hiçbir faydası görünmüyordu: gün boyu yağan yağmur kervanı yine
		# tavana çıkarıyordu (test yakaladı, "ateş kurutur 1.00 < 1.00").
		# Kurutma artık o günün sonunda: akşam ateşin başında giysiler
		# kurur, sabah kervan daha az ıslak kalkar.
		if fire_day == d:
			wet *= 1.0 - FIRE_DRY
		wet = clampf(wet, 0.0, 1.0)
		snow = clampf(snow, 0.0, 1.0)
	return {"wet": wet, "snow": snow}

## Brandanın üstü omuzdan daha çok kar tutar: yatay, geniş ve kıpırdamayan
## bir yüzey. Aynı günün karı, başka bir yüzey.
static func wagon_snow(body_snow: float) -> float:
	return clampf(body_snow * WAGON_SNOW_HOLD, 0.0, 1.0)
