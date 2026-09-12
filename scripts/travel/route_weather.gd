class_name RouteWeather
extends RefCounted

## Yolun havası. Görsel *ve* mekanik: yağmur yolu yavaşlatıyor, sis
## tehlikeyi büyütüyor, fırtına morali kırıyor.
##
## **Yeni sistem uydurmuyor.** Havanın bütün etkisi zaten var olan
## kolları çeviriyor - yürüme temposu, tehlike, moral aşınması - aynı
## kural kültür perklerinde de var ("hiçbir perk yeni bir sistem
## icat etmez"). Yoksa hava ayrı bir hesap defteri olur ve dengeye
## dokunduğu yer görünmez kalır.
##
## **Hesaplanıyor, saklanmıyor.** Gün + rota tohumundan çıkıyor, yani
## kaydı yeniden yükleyen oyuncu aynı havayı buluyor; `RouteConditions`'ın
## doğal durumlarındaki gerekçenin aynısı - yoksa yağmuru kapatmak için
## kaydı yeniden yüklemek bir strateji olurdu.

const CLEAR: String = "clear"
const OVERCAST: String = "overcast"
const RAIN: String = "rain"
const FOG: String = "fog"
const STORM: String = "storm"

## Ağırlıklı çekiliş: açık hava baskın olmalı, yoksa her sefer kötü
## havada geçiyor ve hava bir olay olmaktan çıkıp bir vergiye dönüşüyor.
const WEIGHTS: Dictionary = {
	CLEAR: 42.0,
	OVERCAST: 24.0,
	RAIN: 18.0,
	FOG: 11.0,
	STORM: 5.0,
}

## Biyom havayı eğiyor: gölde ve bataklıkta sis, dağda fırtına daha sık.
## Bozkır açık kalmaya meyilli.
const BIOME_BIAS: Dictionary = {
	ArtPalette.BIOME_LAKE: {FOG: 2.4, RAIN: 1.3},
	ArtPalette.BIOME_MARSH: {FOG: 2.8, RAIN: 1.4},
	ArtPalette.BIOME_MOUNTAIN: {STORM: 2.6, FOG: 1.4, CLEAR: 0.7},
	ArtPalette.BIOME_FOREST: {RAIN: 1.3},
	ArtPalette.BIOME_STEPPE: {CLEAR: 1.5, FOG: 0.5},
}

## Yürüme temposu çarpanı: çamurda kervan yavaşlar. Yol ekranı bunu
## mesafeye uyguluyor (bkz. road_journey'nin _advance_position'ı), yani
## kötü havada aynı yol daha çok gün yiyor - erzak üzerinden gerçek bir
## bedel.
const PACE: Dictionary = {
	CLEAR: 1.0,
	OVERCAST: 1.0,
	RAIN: 0.82,
	FOG: 0.88,
	STORM: 0.62,
}

## Tehlike zammı, *başlıktaki paya* uygulanıyor (base + delta * (1-base)),
## `RouteConditions`'ın danger delta kuralının aynısı: sisli bir yol
## sessiz yolu gerçekten riskli kılıyor ama zaten ölümcül olanı %90'lık
## bir yazı-tura yapmıyor.
const DANGER_DELTA: Dictionary = {
	CLEAR: 0.0,
	OVERCAST: 0.0,
	RAIN: 0.05,
	FOG: 0.18,
	STORM: 0.12,
}

## Günlük ek moral aşınması. `CaravanState.MORALE_DRAIN_PER_DAY`'in
## üstüne biniyor, onun yerine geçmiyor.
const MORALE_BITE: Dictionary = {
	CLEAR: 0,
	OVERCAST: 0,
	RAIN: -1,
	FOG: -1,
	STORM: -3,
}

## Havanın kendi tohumu var ama `route_key` ve günü de okuyor: aynı yolda
## aynı gün aynı hava. Aynı gün *başka* bir yolda başka hava, çünkü
## anahtar farklı.
static func at(route_key: String, day: int, biome: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("weather|%s|%d" % [route_key, day])

	var bias: Dictionary = BIOME_BIAS.get(biome, {})
	var total := 0.0
	var kinds: Array[String] = []
	var weights: Array[float] = []
	for kind in WEIGHTS.keys():
		var weight: float = float(WEIGHTS[kind]) * float(bias.get(kind, 1.0))
		kinds.append(String(kind))
		weights.append(weight)
		total += weight

	var roll := rng.randf() * total
	for index in kinds.size():
		roll -= weights[index]
		if roll <= 0.0:
			return kinds[index]
	return CLEAR

static func pace_multiplier(weather: String) -> float:
	return float(PACE.get(weather, 1.0))

## Kötü havanın yola kattığı gün sayısı - **tahmin değil, hesap**.
##
## Buna ihtiyaç olmasının sebebi bir söz: "doğru stoklayan asla aç kalmaz"
## (bkz. Provision Rules). Hava yolu yavaşlatıyorsa aynı rota daha çok gün
## yer ve planlayıcının istediği erzak yetmez - yani bu fonksiyon olmadan
## hava, ölçülmüş erzak dengesini sessizce bozan gizli bir cezaya
## dönüşürdü.
##
## Hesap kesin olabiliyor çünkü hava tohumdan çıkıyor: planlayıcı seferin
## her gününün havasını *şimdiden* biliyor. Kervanın her gün `pace` kadar
## yol aldığı düşünülürse, bir günlük mesafeyi yürümek `1/pace` gün
## sürüyor; fark da yolun uzaması.
static func forecast_extra_days(
	route_key: String, start_day: int, terrain: RouteTerrain, travel_days: int
) -> float:
	var days := maxi(1, travel_days)
	var walked := 0.0
	var spent := 0
	# Yol bitene kadar gün gün yürüyoruz; kötü havada bir gün bir günden
	# az mesafe kapatıyor, o yüzden döngü `days`'ten uzun sürebilir.
	# Tavan güvenlik için: en kötü hava bile yolu iki katından fazla
	# uzatmıyor (bkz. PACE'in en küçük değeri).
	while walked < float(days) and spent < days * 3 + 6:
		var biome := ArtPalette.FALLBACK_BIOME
		if terrain != null:
			biome = terrain.biome_at(walked)
		var weather := at(route_key, start_day + spent, biome)
		walked += pace_multiplier(weather)
		spent += 1
	return maxf(0.0, float(spent) - float(days))

static func danger_delta(weather: String) -> float:
	return float(DANGER_DELTA.get(weather, 0.0))

static func morale_bite(weather: String) -> int:
	return int(MORALE_BITE.get(weather, 0))

static func name_key(weather: String) -> String:
	match weather:
		OVERCAST: return "WEATHER_OVERCAST"
		RAIN: return "WEATHER_RAIN"
		FOG: return "WEATHER_FOG"
		STORM: return "WEATHER_STORM"
		_: return "WEATHER_CLEAR"

## Görsel katmanın okuduğu üç sayı: yağmur yoğunluğu, sis yoğunluğu ve
## gökyüzünün ne kadar kurşuna çaldığı. Ekran bunları kendi uydurmuyor,
## hava tablosundan alıyor - "hem mekanik hem görsel aynı kaynaktan"
## kuralı bu.
static func visuals(weather: String) -> Dictionary:
	match weather:
		OVERCAST:
			return {"rain": 0.0, "fog": 0.18, "gloom": 0.30}
		RAIN:
			return {"rain": 0.62, "fog": 0.25, "gloom": 0.45}
		FOG:
			return {"rain": 0.0, "fog": 0.78, "gloom": 0.35}
		STORM:
			return {"rain": 1.0, "fog": 0.35, "gloom": 0.62}
		_:
			return {"rain": 0.0, "fog": 0.0, "gloom": 0.0}
