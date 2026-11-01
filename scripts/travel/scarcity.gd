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
