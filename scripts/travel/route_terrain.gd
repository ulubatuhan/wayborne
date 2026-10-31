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
## araziden geçiyor - kaydı yeniden yükleyen oyuncu aynı yolu buluyor (aynı
## gerekçe `RouteConditions`'ın doğal durumlarında da var). Yol iki günlük
## bozkır sonra ormansa, o yol hep öyledir; "bugün nasıl" sorusunun cevabı
## hava ve rota durumu.
##
## **Arazi haritadan gelir.** Harita v3'ün yollarında biyom dizisi ve
## duraklar güzergâhın kendisinden ölçüldü (`build_settlements.py`:
## dağlık alan, bataklık kasabasının çevresi, göl/deniz kıyısı, orman, açık
## arazi; duraklar dağa girişte geçit, suya girişte köprü, yoldaki kule,
## manastır, maden, mezra). İlk sürüm araziyi yalnızca yolun adından
## tohumluyordu: vadideki Belvanor-İlsande yolu dağ yolu çıkıyordu.
## Haritada olmayan bir anahtar (test, sentetik sefer) eski tohumlu yoldan
## kurulur. Eğim yine tohumdan, biyoma göre.

## Bir ara durak: yolun ortasında görünen ve okunan bir şey.
const STOP_NONE: String = ""
const STOP_MEZRA: String = "mezra"
const STOP_OUTPOST: String = "outpost"
const STOP_MINE: String = "mine"
const STOP_PASS: String = "pass"
const STOP_SHRINE: String = "shrine"
const STOP_BRIDGE: String = "bridge"
## Irmak geçidi (görev R4 #16): köprüsüz kısa bir su parçası. Su seviyesi
## son üç günün yağışından (RouteFord), kervan okuyarak karar verir.
const STOP_FORD: String = "ford"
## Kuyu (Y-B15): bozkırda bir sınırda. Yeni bir su kaynağı değil, yorgunluğu
## ve stresi biraz alır; erzak hesabına dokunmaz.
const STOP_WELL: String = "well"
## Yol kenarı kervansarayı (Y-B14). Hâli `stop_state`te: çoğu eskimiş ama
## açık, çok azı kapanmış harabe, bazıları haydut elinde. Oyun metninde "han"
## denmez.
const STOP_SERAI: String = "serai"
const SERAI_OPEN: String = "open"
const SERAI_RUIN: String = "ruin"
const SERAI_BANDIT: String = "bandit"
## Harita sınırında boş durak yeri varsa: bozkırda ikide bir kuyu, uzun
## yolda üçte bir kervansaray. Tohum yolun anahtarı ve sınırın kaynaktaki
## sırası: iki yönden aynı yer seçilir.
const WELL_SHARE: int = 2
const SERAI_SHARE: int = 3
const SERAI_MIN_ROUTE_DAYS: int = 5
## Haritadaki her üç köprüden biri geçit.
const FORD_SHARE_OF_BRIDGES: int = 3

## Biyom sırası bilinçli: komşu biyomlar birbirine benziyor, o yüzden
## rastgele seçim bile "bozkırdan sonra dağ, sonra göl" gibi sıçramalar
## üretmiyor. İndeks farkı büyük olan ikisi yan yana gelmiyor
## (bkz. _pick_next_biome).
const BIOME_CHAIN: Array[String] = [
	ArtPalette.BIOME_STEPPE,
	ArtPalette.BIOME_MEADOW,
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

## Faz 17 PR-6: eğim artık yalnızca görsel değil - gerçekten yavaşlatıyor/
## hızlandırıyor. "Bir çizilen durağın hiçbir olay tarafından okunmaması
## dekordur, mekanik değil" ilkesinin (bkz. Route Terrain & Weather Rules)
## eğim tarafındaki karşılığı: slope hep vardı, hiçbir formül onu
## okumuyordu. Tırmanış yavaşlatır, iniş hafifçe hızlandırır - ikisi de
## kenetli, tek bir eğim bütün seferi anlamsız kılamaz (bkz. RouteWeather'ın
## PACE tablosundaki aynı disiplin).
const SLOPE_SPEED_PER_UNIT: float = 0.25
const MIN_SLOPE_SPEED_FACTOR: float = 0.75
const MAX_SLOPE_SPEED_FACTOR: float = 1.15

## Aynı rotada farklı yol (görev Y-B13). Arazi tohumdan gelir ve haritadan
## okunur; mevsim ve kestirme onun üstünde iki deterministik dönüşüm:
## - İlkbahar: göl ya da bataklığa komşu bozkır/çayır parçası su basar (bataklık).
## - Yaz: iki ucu da kuru olan bataklık parçası kurur (çayır).
## - Kış: dağ parçaları karla dikleşir (eğim, yani yavaşlık).
## - Kestirme: yolun ortası (pay `SHORTCUT_FROM`..`SHORTCUT_TO`) zor araziden,
##   dağdan ya da ormandan geçer; yol `SHORTCUT_DAY_SHARE` kadar kısalır,
##   tehlike `SHORTCUT_DANGER_DELTA` kadar (boş paya) artar.
## Planlayıcı ve yol aynı parametrelerle kurar; erzak sözü bozulmaz.
const NO_SEASON: int = -1
const WINTER_MOUNTAIN_SLOPE: float = 0.2
const SHORTCUT_MIN_DAYS: int = 5
const SHORTCUT_DAY_SHARE: float = 0.8
const SHORTCUT_DANGER_DELTA: float = 0.15
const SHORTCUT_FROM: float = 0.35
const SHORTCUT_TO: float = 0.65

var route_key: String = ""
var total_days: int = 1
## Her biri {"biome", "from_day", "to_day", "stop", "slope", "climate", "peaks"}.
## `climate` ("cold"/"warm"/"") ve `peaks` haritadan (build_settlements.py
## annotate_variants): yol ekranı aynı biyomun o konumdaki resmini seçiyor.
var segments: Array[Dictionary] = []

## Belirli bir yol için coğrafyayı kurar. `total_days` rotanın taban
## süresi; parça sayısı ondan çıkıyor, yani uzun yol daha çeşitli.
## `from_id` kervanın çıktığı şehir: harita arazisi bir yönde yazılı, öbür
## yönde dizi ters okunur (dönüşte ve sapmada da seferin asıl çıkışı).
static func build(key: String, days: int, from_id: String = "", season: int = NO_SEASON, shortcut: bool = false) -> RouteTerrain:
	var terrain := _build_base(key, days, from_id)
	if shortcut:
		terrain._apply_shortcut()
	if season != NO_SEASON:
		terrain._apply_season(season)
	return terrain

## Kestirme bu yol için var mı: kısa yolda kesilecek bir orta yok.
static func shortcut_available(days: int) -> bool:
	return days >= SHORTCUT_MIN_DAYS

static func shortcut_days(days: int) -> int:
	return maxi(1, int(round(float(days) * SHORTCUT_DAY_SHARE)))

## Kestirmenin tehlikesi, rotanın kendi delta kuralıyla (boş paya).
static func shortcut_danger(danger: float) -> float:
	return clampf(danger + SHORTCUT_DANGER_DELTA * (1.0 - danger), 0.0, 1.0)

static func _build_base(key: String, days: int, from_id: String) -> RouteTerrain:
	var terrain := RouteTerrain.new()
	terrain.route_key = key
	terrain.total_days = maxi(1, days)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("terrain|%s" % key)

	var mapped := WorldMapData.get_route_terrain(key)
	if not mapped.is_empty():
		terrain._build_from_map(mapped, from_id, rng)
		return terrain

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

## Haritanın dizisi: payları güne çevirir, gerekirse ters çevirir. Durak
## bir parçanın *sonunda* (sınırda) durur; ters yönde aynı sınırın durağı
## öbür parçaya geçer. Eğim haritanın yazıldığı sırada atılır ki iki yön
## aynı zarları görsün.
func _build_from_map(mapped: Dictionary, from_id: String, rng: RandomNumberGenerator) -> void:
	var source: Array = mapped["segments"]
	var slopes: Array[float] = []
	for entry in source:
		slopes.append(_slope_for(String(entry["biome"]), rng))
	var n := source.size()
	var reverse := not from_id.is_empty() and from_id != String(mapped["from"])
	var days := float(total_days)
	var from_day := 0.0
	for k in n:
		var i := n - 1 - k if reverse else k
		var to_share := 1.0
		var stop := STOP_NONE
		if k < n - 1:
			if reverse:
				to_share = 1.0 - float(source[i - 1]["to"])
				stop = String(source[i - 1]["stop"])
			else:
				to_share = float(source[i]["to"])
				stop = String(source[i]["stop"])
		# Haritanın köprülerinin bir kısmı köprüsüz geçit (R4 #16): sınır
		# kaynaktaki sırasıyla tohumlanır, iki yönden aynı yer seçilir.
		var boundary := i - 1 if reverse else i
		if stop == STOP_BRIDGE:
			if absi(hash("ford|%s|%d" % [route_key, boundary])) % FORD_SHARE_OF_BRIDGES == 0:
				stop = STOP_FORD
		var stop_state := ""
		if stop == STOP_NONE and k < n - 1:
			stop = _derived_stop(source, boundary)
			if stop == STOP_SERAI:
				stop_state = serai_state(route_key, boundary)
		var to_day := days if k == n - 1 else clampf(to_share * days, from_day, days)
		segments.append({
			"biome": String(source[i]["biome"]),
			"from_day": from_day,
			"to_day": to_day,
			"stop": stop,
			"stop_state": stop_state,
			"slope": slopes[i],
			"climate": String(source[i].get("climate", "")),
			"peaks": bool(source[i].get("peaks", false)),
		})
		from_day = to_day

## Haritanın boş bir sınırına türetilmiş durak. Komşu sınırlarda durak varsa
## boş kalır (duraklar birbirine yığılmasın); karar yalnızca kaynağın
## sırasına bakar, yön değiştirince aynı sonuç çıkar.
func _derived_stop(source: Array, boundary: int) -> String:
	for near in [boundary - 1, boundary + 1]:
		if near >= 0 and near < source.size() - 1 and String(source[near]["stop"]) != STOP_NONE:
			return STOP_NONE
	var steppe := String(source[boundary]["biome"]) == ArtPalette.BIOME_STEPPE \
		or String(source[boundary + 1]["biome"]) == ArtPalette.BIOME_STEPPE
	if steppe and absi(hash("well|%s|%d" % [route_key, boundary])) % WELL_SHARE == 0:
		return STOP_WELL
	if total_days >= SERAI_MIN_ROUTE_DAYS and absi(hash("serai|%s|%d" % [route_key, boundary])) % SERAI_SHARE == 0:
		return STOP_SERAI
	return STOP_NONE

## Kervansarayın hâli: onda yedi açık (eskimiş, ücra), onda biri harabe,
## onda ikisi haydut elinde. Saklanmaz, yeniden kurulduğunda aynı çıkar.
static func serai_state(key: String, boundary: int) -> String:
	var roll := absi(hash("serai_state|%s|%d" % [key, boundary])) % 10
	if roll == 0:
		return SERAI_RUIN
	if roll <= 2:
		return SERAI_BANDIT
	return SERAI_OPEN

func _apply_season(season: int) -> void:
	var source := segments.duplicate(true)
	for i in segments.size():
		var biome := String(source[i]["biome"])
		var before := String(source[i - 1]["biome"]) if i > 0 else ""
		var after := String(source[i + 1]["biome"]) if i < source.size() - 1 else ""
		var wet := [ArtPalette.BIOME_LAKE, ArtPalette.BIOME_MARSH]
		var inner := i > 0 and i < source.size() - 1
		if season == MarketConditions.Season.SPRING:
			if biome in [ArtPalette.BIOME_STEPPE, ArtPalette.BIOME_MEADOW] and (before in wet or after in wet):
				segments[i]["biome"] = ArtPalette.BIOME_MARSH
				segments[i]["slope"] = minf(float(segments[i]["slope"]), 0.0)
		elif season == MarketConditions.Season.SUMMER:
			if biome == ArtPalette.BIOME_MARSH and inner and not (before in wet) and not (after in wet):
				segments[i]["biome"] = ArtPalette.BIOME_MEADOW
		elif season == MarketConditions.Season.WINTER:
			if biome == ArtPalette.BIOME_MOUNTAIN:
				segments[i]["slope"] = minf(0.7, float(segments[i]["slope"]) + WINTER_MOUNTAIN_SLOPE)

## Yolun ortası zor araziden: yolda dağ varsa dağ (girişte geçit), yoksa orman.
func _apply_shortcut() -> void:
	var days := float(total_days)
	var a := SHORTCUT_FROM * days
	var b := SHORTCUT_TO * days
	var rough := ArtPalette.BIOME_FOREST
	for segment in segments:
		if String(segment["biome"]) == ArtPalette.BIOME_MOUNTAIN:
			rough = ArtPalette.BIOME_MOUNTAIN
	var out: Array[Dictionary] = []
	for segment in segments:
		var from_day := float(segment["from_day"])
		var to_day := float(segment["to_day"])
		if from_day < a:
			var head := segment.duplicate()
			head["to_day"] = minf(to_day, a)
			if to_day > a:
				head["stop"] = STOP_PASS if rough == ArtPalette.BIOME_MOUNTAIN else STOP_NONE
			out.append(head)
		if from_day < b and to_day > a and (out.is_empty() or String(out[-1]["biome"]) != "shortcut"):
			if out.is_empty() or float(out[-1]["to_day"]) <= a:
				var climate := String(out[-1].get("climate", "")) if not out.is_empty() else ""
				out.append({"biome": "shortcut", "from_day": a, "to_day": b, "stop": STOP_NONE,
					"slope": 0.5 if rough == ArtPalette.BIOME_MOUNTAIN else 0.1,
					"climate": climate, "peaks": false})
		if to_day > b:
			var tail := segment.duplicate()
			tail["from_day"] = maxf(from_day, b)
			out.append(tail)
	for segment in out:
		if String(segment["biome"]) == "shortcut":
			segment["biome"] = rough
	segments = out

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
			pool = [STOP_BRIDGE, STOP_MEZRA, STOP_FORD]
		ArtPalette.BIOME_FOREST:
			pool = [STOP_SHRINE, STOP_MEZRA, STOP_OUTPOST]
		ArtPalette.BIOME_MARSH:
			pool = [STOP_BRIDGE, STOP_SHRINE, STOP_FORD]
		ArtPalette.BIOME_MEADOW:
			pool = [STOP_MEZRA, STOP_SHRINE, STOP_OUTPOST]
		_:
			pool = [STOP_MEZRA, STOP_OUTPOST]
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

## Parçanın yol ekranındaki görünüşü (görev Y-G07): biyom, haritadaki
## iklimi ve ufkunda dağ olup olmadığı - "forest_cold_peaks" gibi.
## RoadStrips bir katmanın varyantı yoksa bir alttakine düşüyor.
static func look_of(segment: Dictionary) -> String:
	var look := String(segment.get("biome", ArtPalette.FALLBACK_BIOME))
	var climate := String(segment.get("climate", ""))
	if not climate.is_empty():
		look += "_" + climate
	if bool(segment.get("peaks", false)) and String(segment.get("biome", "")) != ArtPalette.BIOME_MOUNTAIN:
		look += "_peaks"
	return look

func look_at(day: float) -> String:
	return look_of(segment_at(day))

func biome_at(day: float) -> String:
	return String(segment_at(day).biome)

func slope_at(day: float) -> float:
	return float(segment_at(day).slope)

## Eğimin yürüme temposuna çarpanı - düz arazide tam 1.0 (SLOPE_FLAT sıfır
## olduğu için), tırmanışta düşer, inişte hafifçe yükselir. `road_journey.gd`
## `_walk_at()`'te gerçek yürüyüşe, `RouteWeather.forecast_extra_days()`
## planlayıcının erzak payına uyguluyor - ikisi de aynı sayıyı okumazsa
## "doğru stoklayan asla aç kalmaz" sözü tırmanışlı bir rotada bozulur.
func speed_factor_at(day: float) -> float:
	return clampf(
		1.0 - slope_at(day) * SLOPE_SPEED_PER_UNIT,
		MIN_SLOPE_SPEED_FACTOR, MAX_SLOPE_SPEED_FACTOR
	)

## Arazi geçişi için karışım: sınıra yaklaşırken bir sonraki biyomun
## rengine kayıyoruz. `BLEND_DAYS` içinde yumuşuyor, böylece "iki
## günlük orman" bir duvarla başlamıyor.
const BLEND_DAYS: float = 0.55

func terrain_colors_at(day: float) -> Dictionary:
	var blend := biome_blend_at(day)
	if float(blend.ratio) <= 0.0:
		return ArtPalette.terrain(String(blend.from))
	return ArtPalette.blend_terrain(String(blend.from), String(blend.to), float(blend.ratio) * 0.85)

## Renk karışımının kendisi: hangi biyomdan hangisine, ne kadar (0-1). Yolun
## render edilmiş katmanları (RoadStrips) iki biyomun resmini bu oranla
## üst üste koyuyor - renk ile resim ayrı hesaplansa biri ormana girmişken
## öteki hâlâ bozkırda kalırdı.
func biome_blend_at(day: float) -> Dictionary:
	var segment := segment_at(day)
	var current := String(segment.biome)
	var look := look_of(segment)
	var still := {"from": current, "to": current, "from_look": look, "to_look": look, "ratio": 0.0}
	var remaining := float(segment.to_day) - clampf(day, 0.0, float(total_days))
	if remaining >= BLEND_DAYS:
		return still
	var next_index := segments.find(segment) + 1
	if next_index <= 0 or next_index >= segments.size():
		return still
	return {
		"from": current, "to": String(segments[next_index].biome),
		"from_look": look_of(segment), "to_look": look_of(segments[next_index]),
		"ratio": 1.0 - clampf(remaining / BLEND_DAYS, 0.0, 1.0),
	}

## Yolda görünecek duraklar, gün cinsinden konumlarıyla. Yol ekranı
## bunları ilerleme oranına göre ekrana yerleştiriyor.
func get_stops() -> Array[Dictionary]:
	var stops: Array[Dictionary] = []
	for segment in segments:
		if String(segment.stop) == STOP_NONE:
			continue
		stops.append({"stop": String(segment.stop), "day": float(segment.to_day), "state": String(segment.get("stop_state", ""))})
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
		ArtPalette.BIOME_MEADOW: return "TERRAIN_MEADOW"
		_: return "TERRAIN_STEPPE"

static func stop_name_key(stop: String) -> String:
	match stop:
		STOP_MEZRA: return "STOP_MEZRA"
		STOP_OUTPOST: return "STOP_OUTPOST"
		STOP_MINE: return "STOP_MINE"
		STOP_PASS: return "STOP_PASS"
		STOP_SHRINE: return "STOP_SHRINE"
		STOP_BRIDGE: return "STOP_BRIDGE"
		STOP_FORD: return "STOP_FORD"
		STOP_WELL: return "STOP_WELL"
		STOP_SERAI: return "STOP_SERAI"
		_: return "STOP_MEZRA"
