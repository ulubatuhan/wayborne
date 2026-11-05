class_name Scarcity
extends RefCounted

## Kıtayı saran kıtlık (görev Y-C21). Sebebi lore kararı (soru defteri III,
## kullanıcı cevabı bekleniyor); oyunda bir dünya hâli olarak yaşar ve her
## bölgede bir derecesi var (0 bolluk, 1 yokluk). Hesaplanır, saklanmaz
## (hava gibi): bölgenin tabanı, mevsim (kış en ağır) ve yıllar geçtikçe
## ağırlaşan bir kayma. Vadi kıtada en çok kıtlık yaşayan bölge (LORE), Gokyurt
## en sağlıklı yer: en geç o solar.
##
## Kullanıcı notu: "Kıtlık sebebiyle ticaret tarafı limite edilmeli, oyunun
## odağı ... kervanı gerçekten bir noktadan diğerine başarılı bir şekilde
## götürebilmek olmalı." Ticaret kalır ama kıt ve pahalı (derinleşme, asla
## sadeleştirme): stok azalır, yiyecek pahalanır, aç şehir yiyeceğe çok verir.

const REGION_BASE: Dictionary = {
	"vadi": 0.55, "guney": 0.45, "sinir": 0.45, "dag_maden": 0.40,
	"imparatorluk": 0.35, "dag": 0.35, "ahit": 0.30, "gocebe": 0.12,
}
const SEASON_SWING: float = 0.12
const YEAR_DAYS: int = 360
## Kış ortası (en ağır gün) yılın bu günü.
const WINTER_PEAK_DAY: int = 300
const DRIFT_PER_DAY: float = 0.0004
const DRIFT_CAP: float = 0.2
const FOOD_ITEMS: Array[String] = ["provisions", "test_grain", "fish", "honey"]
## Fiyat: yiyecek kıtlıkla en çok pahalanır, öbür mallar az.
const FOOD_PRICE_RISE: float = 0.6
const GOODS_PRICE_RISE: float = 0.2
## Pazarda satılmayan pay: satıcı satmak istemez.
const STOCK_WITHHELD: float = 0.6
## Bir şehrin "aç" sayıldığı kıtlık derecesi (P14): bunun üstünde yiyecek
## satmak bir alışveriş değil bir iyiliktir ve hatırlanır.
const HUNGRY_CITY_FROM: float = 0.5

static func degree(region: String, day: int) -> float:
	var base := float(REGION_BASE.get(region, 0.4))
	var season := SEASON_SWING * cos(TAU * float(day - WINTER_PEAK_DAY) / float(YEAR_DAYS))
	var drift := minf(DRIFT_CAP, float(day) * DRIFT_PER_DAY)
	return clampf(base + season + drift, 0.0, 1.0)

static func at(location_id: String, day: int) -> float:
	var location := WorldMapData.get_location_by_id(location_id)
	return degree(location.region if location != null else "", day)

static func is_food(item_id: String) -> bool:
	return FOOD_ITEMS.has(item_id)

static func buy_factor(item_id: String, degree_here: float) -> float:
	return 1.0 + degree_here * (FOOD_PRICE_RISE if is_food(item_id) else GOODS_PRICE_RISE)

static func stock_left(stock: int, degree_here: float) -> int:
	return int(floor(float(stock) * (1.0 - degree_here * STOCK_WITHHELD)))

## --- Erzağın stoğu (P5 + P9/B, kullanıcı kararı 2026-11-05) ---
##
## **Kıtlık bir para sorunu değil, bir arz sorunudur.** Erzak bugüne kadar
## planlayıcıda sınırsızdı: `PROVISIONS_UNIT_PRICE` ile kesen yettiği sürece
## tam gereken sayı alınabiliyordu. Yani açlığın tek gerçek kapısı paraydı ve
## para bulunabilir bir şey - "yoklukta kıvranmak" oradan sızıyordu.
##
## Artık her yerleşimin satabileceği bir erzak miktarı var ve o miktar
## kıtlıkla düşüyor. Planlayıcı hâlâ **doğru sayıyı söylüyor** ("doğru
## stoklayan asla aç kalmaz" sözü duruyor, bkz. Provision Rules); değişen
## şey o sayıyı her zaman **satın alabilmek değil**. Oyuncuya haksızlık yok:
## ne gerektiğini biliyor, bulamıyor.
##
## **Hesaplanır, saklanmaz** - `RouteWeather`, `Temperature`, `GroundCover`,
## `Soaking` ile aynı kural. Girdi: yerleşim türü, bölge, gün. Aynı şehrin
## aynı günü her zaman aynı rafı gösterir; kaydı yeniden yükleyip rafı
## doldurmak yok, şehirden çıkıp girerek de yok.

## Bir şehrin bir günde satabileceği erzak (ticaret payı 1.0 iken, bolluk).
const PROVISION_BASE_STOCK: int = 150
## Kıtlık bu payı yiyor: derece 1'de taban stoğun yalnızca %12'si kalır.
const PROVISION_SCARCITY_BITE: float = 0.88
## Yiyecek kıtlıkta en önce biter: bu pay, genel `STOCK_WITHHELD`'den sert.
## Gerekçe (Y-C21): "kervanın ulaştırdığı yük şehrin hâlini düzeltir" -
## şehirlerde yiyecek olsaydı kervanın taşıdığı şeyin anlamı kalmazdı.
const PROVISION_MIN_STOCK: int = 0
## Günden güne dalgalanma payı: aynı şehir her gün aynı sayıyı vermez.
## Tohum şehir + gün, yani gün içinde sabit.
const PROVISION_DAY_SWING: float = 0.35

## Bir yerleşimin bugün satabileceği erzak. `location` null ise (test, F1
## sentetik seferi) sınırsız demek için -1 döner - bilinmeyen bir yerde
## oyuncuyu kilitlemek yanlış olurdu.
static func provision_stock(location: Location, day: int) -> int:
	if location == null:
		return -1
	var degree_here := degree(location.region, day)
	var share := SettlementRules.trade_share(location.settlement_type)
	var base := float(PROVISION_BASE_STOCK) * share
	var left := base * (1.0 - degree_here * PROVISION_SCARCITY_BITE)
	# Günlük dalga: tohumlu, yani aynı gün aynı sayı.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("provision|%s|%d" % [location.location_id, day])
	left *= 1.0 + rng.randf_range(-PROVISION_DAY_SWING, PROVISION_DAY_SWING)
	return maxi(PROVISION_MIN_STOCK, int(floor(left)))
