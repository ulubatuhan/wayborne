class_name RouteFord
extends RefCounted

## Irmak geçidinin su seviyesi (görev R4 #16): son üç günün havasından,
## tohumdan - saklanmaz, yeniden yüklemek suyu çekmez. 0 alçak, 1 orta,
## 2 yüksek. Bataklık bir kademe yüksek. Ön bölgede olan seviyeyi önceden okur.

const LOW: int = 0
const NORMAL: int = 1
const HIGH: int = 2
const LOOKBACK_DAYS: int = 3
const LEVEL_KEYS: Array[String] = ["UI_FORD_LOW", "UI_FORD_NORMAL", "UI_FORD_HIGH"]

static func water_level(route_key: String, day: int, biome: String) -> int:
	var wet := 0
	for i in LOOKBACK_DAYS:
		var weather := RouteWeather.at(route_key, maxi(1, day - i), biome)
		if weather == RouteWeather.RAIN or weather == RouteWeather.STORM:
			wet += 1
	var level := LOW if wet == 0 else (NORMAL if wet == 1 else HIGH)
	if biome == ArtPalette.BIOME_MARSH:
		level += 1
	return clampi(level, LOW, HIGH)
