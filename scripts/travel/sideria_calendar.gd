class_name SideriaCalendar
extends RefCounted

## Sürü Yılı'nın dönemleri (görev Y-E08; SIDERIA §2.3 ve §2.3a).
##
## Yıl 360 gün (`Scarcity.YEAR_DAYS`) ve ilk otun çıktığı gün başlar; oyunun
## ilk günü yılın ilk günü. Dönem hesaplanır, saklanmaz: gün sayısı zaten
## kayıtta, dönem ondan türer (RouteWeather ve Temperature ile aynı kural).
##
## Bir dönem yeni bir sistem değil: var olan kartların ağırlığını değiştirir
## (`EventCatalog.CALENDAR_WEIGHTS`), bağlama `takvim_<id>` yazar ve yol
## ekranının saat satırında adıyla görünür. Pazar mevsimleri ayrı ve kısa
## (`MarketConditions.SEASON_LENGTH_DAYS`): o, fiyatın nefesi; bu, yılın
## kendisi.

const YEAR_DAYS: int = 360

## id -> [ilk gün, son gün] (yılın içinde, dahil).
const PERIODS: Dictionary = {
	"ilk_ot": [0, 4],
	"hac": [60, 71],
	"panayir": [150, 159],
	"ondalik": [235, 244],
	"tas_gecesi": [300, 302],
}

## Tam yazılı anahtarlar (Localization Rules).
const NAME_KEYS: Dictionary = {
	"ilk_ot": "CAL_ILK_OT",
	"hac": "CAL_HAC",
	"panayir": "CAL_PANAYIR",
	"ondalik": "CAL_ONDALIK",
	"tas_gecesi": "CAL_TAS_GECESI",
}

static func year_day(day: int) -> int:
	return posmod(day, YEAR_DAYS)

## O günün dönemi; dönem dışıysa boş.
static func period(day: int) -> String:
	var d := year_day(day)
	for id in PERIODS:
		var span: Array = PERIODS[id]
		if d >= int(span[0]) and d <= int(span[1]):
			return String(id)
	return ""

static func name_key(id: String) -> String:
	return String(NAME_KEYS.get(id, ""))

## Bir dönemin bir sonraki başlangıcına kaç gün var (yol planı ve haber için).
static func days_until(id: String, day: int) -> int:
	if not PERIODS.has(id):
		return -1
	var start := int((PERIODS[id] as Array)[0])
	return posmod(start - year_day(day), YEAR_DAYS)
