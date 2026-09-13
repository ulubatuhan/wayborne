class_name RouteTerrain
extends RefCounted

## Bir yolun neye benzediği: hangi araziden geçtiği ve yol boyunca hangi
## durakların olduğu. Görsel değil **veri** - yol ekranı bunu okuyup
## çiziyor, ama sefer süresi ve tehlike de aynı tablodan besleniyor.
##
## `WorldMapData` hangi şehrin hangisine komşu olduğunu söylüyor,
## `RouteConditions` o yolun *bugünkü* halini (sel, heyelan, eşkıya).
## Bu dosya üçüncü katman: yolun *coğrafyası*. Aynı bölünme:
##
##   WorldMapData   -> değişmeyen harita
##   RouteTerrain   -> değişmeyen coğrafya (hesaplanır, saklanmaz)
##   RouteConditions-> haftalık değişen durum
##
## **Hesaplanıyor, saklanmıyor.** Aynı iki şehir arası her zaman aynı
## araziden geçiyor, çünkü tohum `route_key`'den geliyor - kaydı yeniden
## yükleyen oyuncu aynı yolu buluyor (aynı gerekçe
## `RouteConditions`'ın doğal durumlarında da var). Yol iki günlük bozkır
## sonra ormansa, o yol hep öyledir; "bugün nasıl" sorusunun cevabı
## hava ve rota durumu.

## Bir ara durak: yolun ortasında görünen ve okunan bir şey.
const STOP_NONE: String = ""
const STOP_HAMLET: String = "hamlet"
const STOP_OUTPOST: String = "outpost"
const STOP_MINE: String = "mine"
const STOP_PASS: String = "pass"
const STOP_SHRINE: String = "shrine"
const STOP_BRIDGE: String = "bridge"

## Biyom sırası bilinçli: komşu biyomlar birbirine benziyor, o yüzden
## rastgele seçim bile "bozkırdan sonra dağ, sonra göl" gibi sıçramalar
## üretmiyor. İndeks farkı büyük olan ikisi yan yana gelmiyor
## (bkz. _pick_next_biome).
const BIOME_CHAIN: Array[String] = [
	ArtPalette.BIOME_STEPPE,
	ArtPalette.BIOME_MARSH,
	ArtPalette.BIOME_FOREST,
	ArtPalette.BIOME_LAKE,
	ArtPalette.BIOME_MOUNTAIN,
]

## Bir parça en az bu kadar gün sürüyor: yarım günlük biyomlar ekranda
## anlaşılmadan geçip gidiyordu, "arazi değişti" hissi vermiyordu.
const MIN_SEGMENT_DAYS: float = 0.8

## Durakların çıkma olasılığı. Her parça sınırında bir zar atılıyor;
## çıkmazsa o sınır sadece bir arazi geçişi.
const STOP_CHANCE: float = 0.55

## Yolun eğimi: parçaya göre yukarı/aşağı. Dağ yukarı, göl aşağı eğimli
## olmaya meyilli - hem görsel hem de "yol zor" hissi için.
const SLOPE_FLAT: float = 0.0

var route_key: String = ""
var total_days: int = 1
## Her biri {"biome", "from_day", "to_day", "stop", "slope"}.
var segments: Array[Dictionary] = []

## Belirli bir yol için coğrafyayı kurar. `total_days` rotanın taban
## süresi; parça sayısı ondan çıkıyor, yani uzun yol daha çeşitli.
static func build(key: String, days: int) -> RouteTerrain:
	var terrain := RouteTerrain.new()
	terrain.route_key = key
	terrain.total_days = maxi(1, days)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("terrain|%s" % key)

	var segment_count := clampi(
		int(round(float(terrain.total_days) / 1.6)), 1, 5
	)
	var span := float(terrain.total_days) / float(segment_count)
	var biome := BIOME_CHAIN[rng.randi_range(0, BIOME_CHAIN.size() - 1)]

	for index in segment_count:
		var from_day := span * float(index)
		var to_day := span * float(index + 1) if index < segment_count - 1 else float(terrain.total_days)
		if to_day - from_day < MIN_SEGMENT_DAYS and index > 0:
			# Fazla kısa parçayı öncekine katıyoruz: ekranda okunmayan bir
			# arazi değişimi gürültüden başka bir şey değil.
			terrain.segments[-1]["to_day"] = to_day
			continue

		var stop := STOP_NONE
		# Durak parçanın *sonunda* duruyor; son parçanın sonu şehir
		# olduğu için orada durak olmuyor.
		if index < segment_count - 1 and rng.randf() < STOP_CHANCE:
			stop = terrain._pick_stop(biome, rng)

		terrain.segments.append({
			"biome": biome,
			"from_day": from_day,
			"to_day": to_day,
			"stop": stop,
			"slope": terrain._slope_for(biome, rng),
		})
		biome = terrain._pick_next_biome(biome, rng)

	return terrain

## Komşu biyom: zincirde en fazla iki adım uzağa gidiyor. Bozkırdan
## doğrudan dağa çıkmak coğrafya gibi durmuyor.
func _pick_next_biome(current: String, rng: RandomNumberGenerator) -> String:
	var index := BIOME_CHAIN.find(current)
	if index < 0:
		index = 0
	var step := rng.randi_range(-2, 2)
	if step == 0:
		step = 1 if rng.randf() < 0.5 else -1
	return BIOME_CHAIN[clampi(index + step, 0, BIOME_CHAIN.size() - 1)]

## Durak araziye uyuyor: dağda geçit ve maden, gölde köprü, ormanda
## kuytu bir sunak. Rastgele bir liste yerine biyoma bağlı olması
## yolun okunmasını sağlıyor.
func _pick_stop(biome: String, rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = []
	match biome:
		ArtPalette.BIOME_MOUNTAIN:
			pool = [STOP_PASS, STOP_MINE, STOP_OUTPOST]
		ArtPalette.BIOME_LAKE:
			pool = [STOP_BRIDGE, STOP_HAMLET]
		ArtPalette.BIOME_FOREST:
			pool = [STOP_SHRINE, STOP_HAMLET, STOP_OUTPOST]
		ArtPalette.BIOME_MARSH:
			pool = [STOP_BRIDGE, STOP_SHRINE]
		_:
			pool = [STOP_HAMLET, STOP_OUTPOST]
	return pool[rng.randi_range(0, pool.size() - 1)]

## Eğim: dağ tırmanış, göl iniş, gerisi düze yakın. Görsel yol çizgisini
## eğdiriyor ve "yukarı gidiyoruz" hissini veriyor.
func _slope_for(biome: String, rng: RandomNumberGenerator) -> float:
	var base := 0.0
	match biome:
		ArtPalette.BIOME_MOUNTAIN:
			base = 0.55
		ArtPalette.BIOME_LAKE:
			base = -0.35
		ArtPalette.BIOME_MARSH:
			base = -0.15
	return clampf(base + (rng.randf() - 0.5) * 0.3, -0.7, 0.7)

## `day` kesirli olabilir (gün ortası). Sınırın dışındaki değerler
## kenetleniyor: varış anında `total_days` geliyor ve son parça
## okunmalı.
func segment_at(day: float) -> Dictionary:
	if segments.is_empty():
		return {
			"biome": ArtPalette.FALLBACK_BIOME, "from_day": 0.0,
			"to_day": float(total_days), "stop": STOP_NONE, "slope": SLOPE_FLAT,
		}
	var clamped := clampf(day, 0.0, float(total_days))
	for segment in segments:
		if clamped < float(segment.to_day) or is_equal_approx(clamped, float(segment.to_day)):
			return segment
	return segments[-1]

func biome_at(day: float) -> String:
	return String(segment_at(day).biome)

func slope_at(day: float) -> float:
	return float(segment_at(day).slope)

## Arazi geçişi için karışım: sınıra yaklaşırken bir sonraki biyomun
## rengine kayıyoruz. `BLEND_DAYS` içinde yumuşuyor, böylece "iki
## günlük orman" bir duvarla başlamıyor.
const BLEND_DAYS: float = 0.55

func terrain_colors_at(day: float) -> Dictionary:
	var segment := segment_at(day)
	var to_day := float(segment.to_day)
	var current := String(segment.biome)
	var remaining := to_day - clampf(day, 0.0, float(total_days))
	if remaining >= BLEND_DAYS:
		return ArtPalette.terrain(current)

	var next_index := segments.find(segment) + 1
	if next_index >= segments.size():
		return ArtPalette.terrain(current)
	var next_biome := String(segments[next_index].biome)
	var ratio := 1.0 - clampf(remaining / BLEND_DAYS, 0.0, 1.0)
	return ArtPalette.blend_terrain(current, next_biome, ratio * 0.85)

## Yolda görünecek duraklar, gün cinsinden konumlarıyla. Yol ekranı
## bunları ilerleme oranına göre ekrana yerleştiriyor.
func get_stops() -> Array[Dictionary]:
	var stops: Array[Dictionary] = []
	for segment in segments:
		if String(segment.stop) == STOP_NONE:
			continue
		stops.append({"stop": String(segment.stop), "day": float(segment.to_day)})
	return stops

## Oyuncuya tek satırda "bu yol neye benziyor": planlayıcı ekranı bunu
## gösteriyor, böylece rota seçimi kör bir karar olmaktan çıkıyor.
func describe() -> String:
	var parts: Array[String] = []
	for segment in segments:
		var length := int(round(float(segment.to_day) - float(segment.from_day)))
		parts.append(tr("TERRAIN_SPAN") % [
			maxi(1, length), tr(biome_name_key(String(segment.biome)))
		])
	return " · ".join(parts)

static func biome_name_key(biome: String) -> String:
	match biome:
		ArtPalette.BIOME_FOREST: return "TERRAIN_FOREST"
		ArtPalette.BIOME_LAKE: return "TERRAIN_LAKE"
		ArtPalette.BIOME_MOUNTAIN: return "TERRAIN_MOUNTAIN"
		ArtPalette.BIOME_MARSH: return "TERRAIN_MARSH"
		_: return "TERRAIN_STEPPE"

static func stop_name_key(stop: String) -> String:
	match stop:
		STOP_HAMLET: return "STOP_HAMLET"
		STOP_OUTPOST: return "STOP_OUTPOST"
		STOP_MINE: return "STOP_MINE"
		STOP_PASS: return "STOP_PASS"
		STOP_SHRINE: return "STOP_SHRINE"
		STOP_BRIDGE: return "STOP_BRIDGE"
		_: return "STOP_HAMLET"
