class_name GroundCover
extends RefCounted

## Zeminin o günkü hâli: ne kadar ıslak, ne kadar çamur, ne kadar kar, ne
## kadar toz. Kervanın ayağı, toynağı ve tekerleği buna göre tepki veriyor
## (bkz. `FxLayer`); yol ekranının birikintileri de buradan.
##
## **Hesaplanır, saklanmaz** - `RouteWeather` ve `Temperature` ile aynı
## kural. Aynı yolun aynı günü her zaman aynı çamur; kaydı yeniden yükleyip
## yağmuru silmek ya da çamuru kurutmak mümkün değil. Bunun için girdi
## yalnızca tohumdan türeyen şeyler: yolun anahtarı, gün, biyom, iklim.
##
## Üç gün hafıza: dün yağan yağmur bugün hâlâ çamur. Tek güne bakmak
## "yağmur durdu, yol anında kurudu" demekti; üç gün, kervanın bir gün
## önceki kararının bugün hâlâ ayağının altında olması demek.

const MEMORY_DAYS: int = 3
## Bir önceki günün ıslaklığı bugüne ne kadar taşınıyor.
const DAY_DECAY: float = 0.55

## Her havanın o günkü ıslatma payı. `RouteWeather.visuals`'ın `rain`
## değeriyle aynı kaynaktan okunabilirdi ama ıslatma yağışın *görünür*
## yoğunluğu değil: sis ıslatır, kapalı hava biraz nemlendirir.
const WETTING: Dictionary = {
	RouteWeather.CLEAR: 0.0,
	RouteWeather.OVERCAST: 0.08,
	RouteWeather.RAIN: 0.72,
	RouteWeather.FOG: 0.18,
	RouteWeather.STORM: 1.0,
}

## Biyomun kendi zemini. `tut` suyu ne kadar tutuyor (bataklık her zaman
## ıslak, bozkır hemen kuruyor), `toz` kuruyken ne kadar toz kalkıyor.
const SOIL: Dictionary = {
	ArtPalette.BIOME_STEPPE: {"taban": 0.0, "tut": 0.45, "toz": 1.0},
	ArtPalette.BIOME_MEADOW: {"taban": 0.08, "tut": 0.80, "toz": 0.55},
	ArtPalette.BIOME_FOREST: {"taban": 0.14, "tut": 0.90, "toz": 0.35},
	ArtPalette.BIOME_LAKE: {"taban": 0.22, "tut": 0.85, "toz": 0.40},
	ArtPalette.BIOME_MOUNTAIN: {"taban": 0.0, "tut": 0.35, "toz": 0.70},
	ArtPalette.BIOME_MARSH: {"taban": 0.62, "tut": 1.00, "toz": 0.05},
}

## Donma eşiği ve altında kar payının tam dolduğu sıcaklık.
const SNOW_FROM_C: float = 2.0
const SNOW_FULL_C: float = -3.0
## Karın yerde durması: kar yağmasa da soğuk günde yerde kar kalır.
const LYING_SNOW_FROM_C: float = -1.0

## Zeminin dört payı, her biri 0..1. `wet` yüzeydeki su (birikinti,
## parıltı), `mud` çamur, `snow` kar, `dust` kuru toz.
static func at(
	route_key: String, day: int, biome: String, climate: String = ""
) -> Dictionary:
	var soil: Dictionary = SOIL.get(biome, SOIL[ArtPalette.BIOME_STEPPE])
	var tut := float(soil.tut)
	var islak := float(soil.taban)
	var kar := 0.0
	# Bugünden geriye: eski gün ne kadar eskiyse o kadar az iz bırakıyor.
	for geri in range(MEMORY_DAYS - 1, -1, -1):
		var d := maxi(0, day - geri)
		var weather := RouteWeather.at(route_key, d, biome)
		var mean := Temperature.daily_mean(d, biome, climate, weather)
		var dusen := float(WETTING.get(weather, 0.0))
		var kar_payi := snow_share(mean)
		islak = islak * DAY_DECAY * tut + dusen * (1.0 - kar_payi) * tut
		# Kar erimez, birikir; eriyince suya döner.
		if mean <= LYING_SNOW_FROM_C:
			kar = clampf(kar + dusen * kar_payi * 0.8 + (0.10 if kar_payi > 0.5 else 0.0), 0.0, 1.0)
		else:
			var eriyen := kar * clampf((mean - LYING_SNOW_FROM_C) * 0.35, 0.0, 1.0)
			kar = maxf(0.0, kar - eriyen)
			islak = minf(1.0, islak + eriyen * 0.6)
	islak = clampf(islak, 0.0, 1.0)
	# Çamur ıslaklığın toprağa işlemiş hâli: taşta çamur olmaz, bataklıkta
	# hep vardır. En ıslak hâlde bile bir kısmı su olarak yüzeyde kalıyor.
	var camur := clampf(islak * float(soil.tut), 0.0, 1.0)
	var toz := clampf((1.0 - maxf(islak, kar)) * float(soil.toz), 0.0, 1.0)
	return {"wet": islak, "mud": camur, "snow": clampf(kar, 0.0, 1.0), "dust": toz}

## Günün ortalama sıcaklığında yağış ne kadar kar: 0 tamamen yağmur,
## 1 tamamen kar. Perde de (`WeatherCurtain.layers_for`) bunu okuyor, yani
## gökten kar düşerken yerde çamur olmuyor.
static func snow_share(mean_c: float) -> float:
	if mean_c >= SNOW_FROM_C:
		return 0.0
	if mean_c <= SNOW_FULL_C:
		return 1.0
	return (SNOW_FROM_C - mean_c) / (SNOW_FROM_C - SNOW_FULL_C)

## Zemin durumundan efekt adı. Tek karar yeri: ayak, toynak, tekerlek ve
## pençe aynı sırayı izliyor (su > kar > çamur > toz), yoksa aynı zeminde
## öküz çamur, insan toz savururdu.
static func pick(cover: Dictionary, prefix: String) -> String:
	var wet := float(cover.get("wet", 0.0))
	var snow := float(cover.get("snow", 0.0))
	var mud := float(cover.get("mud", 0.0))
	var dust := float(cover.get("dust", 0.0))
	if wet >= 0.55 and wet >= snow:
		return prefix + "_splash"
	if snow >= 0.30:
		return prefix + "_snow"
	if mud >= 0.30:
		return prefix + "_mud"
	if dust >= 0.25:
		return prefix + "_dust"
	return ""

## Yerde kalan izin adı; kuru toprak iz tutmaz.
static func track(cover: Dictionary, prefix: String) -> String:
	if float(cover.get("snow", 0.0)) >= 0.30:
		return prefix + "_snow"
	if float(cover.get("mud", 0.0)) >= 0.40:
		return prefix + "_mud"
	return ""
