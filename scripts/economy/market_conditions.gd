class_name MarketConditions
extends RefCounted

## Fiyatın şehirler arası farkın ötesindeki katmanı. Kârın kaynağı yalnızca
## "ucuz şehirden al, pahalı şehirde sat" değil: zamanla enflasyon, mevsimin
## dönmesi, oyuncunun kendi alım-satımının yarattığı arz-talep kayması ve
## ekonomik/politik olaylar da fiyatı oynatır.
##
## Sahne ağacına bağlı değil, GameSession'ın içinde yaşar ve kaydedilir.
## MarketPricing bunu okur; conditions verilmezse her çarpan 1.0 olur, yani
## bu katman bilmeyen bir çağıran eski davranışı görür.
##
## Buradaki sayılar denge için ayarlanacak yer tutuculardır - fiyat
## tablosunun kendisi gibi (bkz. MarketPricing).

# --- Enflasyon: para zamanla değer kaybeder ---
## Günlük bileşik değil doğrusal artış: uzun bir oyunda fiyatlar tırmanır
## ama kontrolden çıkmaz. Tavan, geç oyunun tamamen ulaşılmaz olmasını
## engelliyor.
const INFLATION_PER_DAY: float = 0.0015
const INFLATION_CAP: float = 1.8

# --- Mevsimler ---
const SEASON_LENGTH_DAYS: int = 30
enum Season { SPRING, SUMMER, AUTUMN, WINTER }

## Mal başına mevsim çarpanı: [ilkbahar, yaz, sonbahar, kış]. Hasat
## sonbaharda tahılı ucuzlatır, kış kürkü pahalandırır. Listede olmayan
## mal mevsimden etkilenmez.
const SEASON_MULTIPLIERS: Dictionary = {
	"test_grain": [1.25, 1.05, 0.75, 1.15],
	"test_furs": [0.90, 0.75, 1.05, 1.40],
	"test_potion": [1.10, 0.95, 1.00, 1.20],
	"provisions": [1.10, 1.00, 0.85, 1.25],
}

# --- Arz-talep: oyuncunun kendi ticareti fiyatı oynatır ---
## Alım fiyatı yukarı iter, satış aşağı - bir şehri sürekli boşaltmak
## orayı pahalılaştırır. Bu, tek bir rotayı sonsuza kadar sağmayı
## (cheat farming) engelleyen şey.
const PRESSURE_PER_UNIT_BOUGHT: float = 0.010
const PRESSURE_PER_UNIT_SOLD: float = 0.008
const PRESSURE_LIMIT: float = 0.45
## Baskı her gün bu oranda tabana geri çeker - pazar zamanla kendini toparlar.
const PRESSURE_DECAY_PER_DAY: float = 0.06

# --- Ekonomik/politik olaylar ---
## Süreli fiyat şoku: bir şehirde bir malın (ya da tüm malların) fiyatını
## bir süre için değiştirir. EventEffect.Type.MARKET_SHOCK bunu kurar.
const SHOCK_LIMIT: float = 2.5

## Toplam çarpanın sıkıştırıldığı aralık - katmanlar üst üste binip fiyatı
## saçmalaştırmasın diye.
const TOTAL_MULTIPLIER_MIN: float = 0.35
const TOTAL_MULTIPLIER_MAX: float = 3.0

## "location_id|item_id" -> baskı (pozitif = pahalandı, negatif = ucuzladı)
var _pressure: Dictionary = {}

## Aktif şoklar. Her biri {"location_id", "item_id", "multiplier", "until_day",
## "label_key"}; item_id boşsa şehrin tamamını etkiler.
var _shocks: Array = []

static func get_season(day: int) -> Season:
	var index := int(floor(float(maxi(0, day)) / float(SEASON_LENGTH_DAYS))) % 4
	return index as Season


## Sezonun kaçıncı günündeyiz - "kış bitmek üzere" hissi için.
static func get_days_into_season(day: int) -> int:
	return maxi(0, day) % SEASON_LENGTH_DAYS

static func get_inflation_multiplier(day: int) -> float:
	return minf(1.0 + INFLATION_PER_DAY * float(maxi(0, day)), INFLATION_CAP)

static func get_season_multiplier(item_id: String, day: int) -> float:
	if not SEASON_MULTIPLIERS.has(item_id):
		return 1.0
	var table: Array = SEASON_MULTIPLIERS[item_id]
	return float(table[int(get_season(day))])

func _pressure_key(location_id: String, item_id: String) -> String:
	return "%s|%s" % [location_id, item_id]

func get_pressure(location_id: String, item_id: String) -> float:
	return float(_pressure.get(_pressure_key(location_id, item_id), 0.0))

## Oyuncu aldıkça o mal o şehirde pahalanır.
func record_purchase(location_id: String, item_id: String, quantity: int) -> void:
	_add_pressure(location_id, item_id, float(quantity) * PRESSURE_PER_UNIT_BOUGHT)

## Oyuncu sattıkça o mal o şehirde ucuzlar - aynı malı aynı şehre boca
## etmek getirisini düşürür.
func record_sale(location_id: String, item_id: String, quantity: int) -> void:
	_add_pressure(location_id, item_id, -float(quantity) * PRESSURE_PER_UNIT_SOLD)

func _add_pressure(location_id: String, item_id: String, delta: float) -> void:
	var key := _pressure_key(location_id, item_id)
	var updated := clampf(float(_pressure.get(key, 0.0)) + delta, -PRESSURE_LIMIT, PRESSURE_LIMIT)
	if is_zero_approx(updated):
		_pressure.erase(key)
	else:
		_pressure[key] = updated

## Süreli bir fiyat şoku ekler. item_id boşsa şehrin tamamı etkilenir.
func add_shock(
	location_id: String, item_id: String, multiplier: float, until_day: int,
	label_key: String = ""
) -> void:
	_shocks.append({
		"location_id": location_id,
		"item_id": item_id,
		"multiplier": clampf(multiplier, 1.0 / SHOCK_LIMIT, SHOCK_LIMIT),
		"until_day": until_day,
		"label_key": label_key,
	})

func get_active_shocks(day: int) -> Array:
	var active: Array = []
	for shock in _shocks:
		if int(shock["until_day"]) >= day:
			active.append(shock)
	return active

func _get_shock_multiplier(location_id: String, item_id: String, day: int) -> float:
	var multiplier := 1.0
	for shock in _shocks:
		if int(shock["until_day"]) < day:
			continue
		if str(shock["location_id"]) != location_id:
			continue
		var shock_item := str(shock["item_id"])
		if not shock_item.is_empty() and shock_item != item_id:
			continue
		multiplier *= float(shock["multiplier"])
	return multiplier

## Günlük işleyiş: baskı tabana doğru çekilir, süresi dolan şoklar düşer.
func advance_day(day: int) -> void:
	var decayed: Dictionary = {}
	for key in _pressure:
		var value := float(_pressure[key]) * (1.0 - PRESSURE_DECAY_PER_DAY)
		if absf(value) > 0.001:
			decayed[key] = value
	_pressure = decayed

	var living: Array = []
	for shock in _shocks:
		if int(shock["until_day"]) >= day:
			living.append(shock)
	_shocks = living

## Bütün katmanların çarpımı. MarketPricing bunu taban fiyata uygular.
func get_price_multiplier(item_id: String, location_id: String, day: int) -> float:
	var multiplier := get_inflation_multiplier(day)
	multiplier *= get_season_multiplier(item_id, day)
	multiplier *= 1.0 + get_pressure(location_id, item_id)
	multiplier *= _get_shock_multiplier(location_id, item_id, day)
	return clampf(multiplier, TOTAL_MULTIPLIER_MIN, TOTAL_MULTIPLIER_MAX)

## --- Zamanın ruhu ---
## "Bugün nasıl bir günde yola çıkıyoruz?" sorusunun cevabı, 0 (bolluk) ile
## 1 (darlık) arasında. Yeni bir sistem icat etmiyor: zaten var olan mevsim,
## fiyat şoku ve enflasyon katmanlarını tek sayıya indiriyor. Kıtlık, ambargo
## ya da grev (bkz. EventEffect.Type.MARKET_SHOCK) fiyatı yukarı iten bir
## şok olarak zaten modelleniyor - "kötü zaman" tam olarak bu.
##
## Kervanın yola hangi moralle çıktığını bu belirliyor (bkz.
## GameSession.get_departure_morale): bereketli bir ilkbaharda kadro
## keyifli, kıtlık kol gezen bir kışta değil.
const HARDSHIP_WINTER: float = 0.30
const HARDSHIP_AUTUMN_RELIEF: float = -0.10
const HARDSHIP_PER_SHOCK_STEP: float = 0.60
const HARDSHIP_INFLATION_WEIGHT: float = 0.35

func get_hardship(location_id: String, day: int) -> float:
	var hardship := 0.0

	match get_season(day):
		Season.WINTER:
			hardship += HARDSHIP_WINTER
		Season.AUTUMN:
			# Hasat sonrası ambarlar dolu.
			hardship += HARDSHIP_AUTUMN_RELIEF
		_:
			pass

	# Fiyatı yukarı iten şok darlık, aşağı iten bolluk demek. Şehrin tamamını
	# etkileyen şok (item_id boş) burada ayrıca ağırlıklandırılmıyor - kaç
	# kalem etkilendiği değil, hayatın ne kadar pahalandığı önemli.
	var shock_multiplier := 1.0
	for shock in _shocks:
		if int(shock["until_day"]) < day:
			continue
		if str(shock["location_id"]) != location_id:
			continue
		shock_multiplier *= float(shock["multiplier"])
	hardship += (shock_multiplier - 1.0) * HARDSHIP_PER_SHOCK_STEP

	# Uzun bir oyunda para değer kaybeder; bu da bir tür yorgunluk.
	var inflation := get_inflation_multiplier(day) - 1.0
	hardship += inflation * HARDSHIP_INFLATION_WEIGHT

	return clampf(hardship, 0.0, 1.0)

func to_save_dict() -> Dictionary:
	return {
		"pressure": _pressure.duplicate(),
		"shocks": _shocks.duplicate(true),
	}

func load_from_dict(data: Dictionary) -> void:
	_pressure = {}
	var stored: Dictionary = data.get("pressure", {})
	for key in stored:
		_pressure[str(key)] = float(stored[key])

	_shocks = []
	for entry in (data.get("shocks", []) as Array):
		var shock: Dictionary = entry
		_shocks.append({
			"location_id": str(shock.get("location_id", "")),
			"item_id": str(shock.get("item_id", "")),
			"multiplier": float(shock.get("multiplier", 1.0)),
			"until_day": int(shock.get("until_day", 0)),
			"label_key": str(shock.get("label_key", "")),
		})
