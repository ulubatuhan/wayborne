class_name Trace
extends RefCounted

## Bir iz: kervanın bir kararının dünyada bıraktığı, vadesi olan kayıt.
## (İz alt sistemi, tasarım notu `docs/design_notes/ahlak_ruh_iz_mimarisi.md`
## §C.1 ve §D.3.)
##
## Niye gerekti: `recent_decisions` her kartta dolduruluyordu ve tek okuyucusu
## ölüm ekranıydı (teşhis A7); yol kimin öldüğünü hatırlıyor ama hiçbir kart
## bunu okumuyordu (A9); aç bırakılan tayfanın izi tek bir fiyata iniyordu
## (A10); vurgunculuğun tek sonucu tek bir karttı (A11). Hepsinin ortak
## eksiği aynı: bir kararın **taşıyıcısı**, **şiddeti**, **vadesi** ve
## **sönmesi** yoktu. Bayrak (`SET_FLAG`) bunların hiçbirini taşımaz.
##
## İz rastgele bir "kelebek etkisi" değildir: her izin bir `kaynak`'ı vardır
## ve geri döndüğünde metni doğum yerini ya da kişisini adıyla anar. Doğum
## kaydı olmayan geri dönüş rastgelelikten ayırt edilemez (§I'de reddedilen
## fikir).

## --- Tür ---
const TYPE_GRATITUDE: String = "minnet"
const TYPE_GRUDGE: String = "kin"
const TYPE_PROMISE: String = "soz"
const TYPE_RUMOR: String = "soylenti"
const TYPE_BLOOD_DEBT: String = "borc_kani"
const TYPE_SACRED: String = "kutsal"
const TYPE_SICKNESS: String = "hastalik"
const TYPE_LEGACY: String = "miras"
const TYPES: Array[String] = [
	TYPE_GRATITUDE, TYPE_GRUDGE, TYPE_PROMISE, TYPE_RUMOR,
	TYPE_BLOOD_DEBT, TYPE_SACRED, TYPE_SICKNESS, TYPE_LEGACY,
]

## Tür tablosu (§G.1): başlangıç şiddeti · gün başına sönme · yayılma atlaması.
## **Kin minnetten yavaş söner ve daha uzağa gider**: bu dünyada iyilik
## yakında bilinir, kötülük uzakta duyulur. Sayılar ±%30 oynatılabilir;
## oranları bozmak dünyanın huyunu değiştirir.
const TYPE_TABLE: Dictionary = {
	TYPE_GRATITUDE: {"siddet": 0.5, "sonme": 0.006, "yayilma": 1},
	TYPE_GRUDGE: {"siddet": 0.6, "sonme": 0.004, "yayilma": 2},
	TYPE_PROMISE: {"siddet": 0.5, "sonme": 0.0, "yayilma": 0},
	TYPE_RUMOR: {"siddet": 0.3, "sonme": 0.008, "yayilma": 3},
	TYPE_SACRED: {"siddet": 0.5, "sonme": 0.006, "yayilma": 1},
	TYPE_SICKNESS: {"siddet": 0.9, "sonme": 0.006, "yayilma": 3},
	TYPE_BLOOD_DEBT: {"siddet": 0.6, "sonme": 0.002, "yayilma": 0},
	TYPE_LEGACY: {"siddet": 0.7, "sonme": 0.0, "yayilma": 1},
}

## Defter satırının sebebi. Anahtarlar tam yazılı: çalışma anında
## birleştirilen bir anahtarı ne tanımsız-anahtar taraması ne de çevirmen
## bulabilir (aynı kural `CaravanLedger.KIND_LABEL_KEYS`'te de yazılı).
const LEDGER_CAUSE_KEYS: Dictionary = {
	TYPE_GRATITUDE: "LEDGER_TRACE_GRATITUDE",
	TYPE_GRUDGE: "LEDGER_TRACE_GRUDGE",
	TYPE_PROMISE: "LEDGER_TRACE_PROMISE",
	TYPE_RUMOR: "LEDGER_TRACE_RUMOR",
	TYPE_SACRED: "LEDGER_TRACE_SACRED",
	TYPE_SICKNESS: "LEDGER_TRACE_SICKNESS",
	TYPE_BLOOD_DEBT: "LEDGER_TRACE_BLOOD",
	TYPE_LEGACY: "LEDGER_TRACE_LEGACY",
}

## --- Taşıyıcı tipi: izi kim taşır, yani nerede/kimde karşına çıkar ---
const BEARER_PERSON: String = "kisi"
const BEARER_CITY: String = "sehir"
const BEARER_REGION: String = "bolge"
const BEARER_FACTION: String = "hizip"
const BEARER_ROAD: String = "yol"
const BEARER_COMPANION: String = "yoldas"
const BEARER_LINE: String = "soy"

## --- Gecikme: en erken ne zaman dönebilir ---
const DELAY_NOW: String = "ani"
const DELAY_JOURNEY: String = "sefer"
const DELAY_SHORT: String = "kisa"
const DELAY_LONG: String = "uzun"
const DELAY_GENERATION: String = "kusak"
## Gün aralıkları (§D-İ1). Alt uç 15'ten kısaysa "anında ceza" gibi okunur.
const DELAY_DAYS: Dictionary = {
	DELAY_NOW: [0, 0],
	DELAY_JOURNEY: [1, 6],
	DELAY_SHORT: [15, 70],
	DELAY_LONG: [130, 400],
	DELAY_GENERATION: [9999, 9999],
}

## --- Dönüş biçimi: iz olgunlaşınca hangi yoldan geri gelir ---
const RETURN_CARD: String = "kart"
const RETURN_ECHO: String = "yanki"
const RETURN_PRICE: String = "fiyat"
const RETURN_GATE: String = "kapi"
const RETURN_FACE: String = "yuz"
const RETURN_OFFER: String = "teklif"
const RETURN_REFUSAL: String = "ret"
const RETURN_ENEMY: String = "dusman"
const RETURN_CANDIDATE: String = "aday"
const RETURN_INHERITANCE: String = "miras"

## --- Durum ---
const STATE_OPEN: String = "acik"
const STATE_RIPE: String = "olgun"
const STATE_RETURNED: String = "dondu"
const STATE_FADED: String = "sondu"
const STATE_LEGACY: String = "miras"

var id: String = ""
var tur: String = TYPE_GRATITUDE
## "event_id|choice_key" ya da "eylem:<ad>" - dönüşün metni bunu anar.
var kaynak: String = ""
var dogum_gunu: int = 0
## location_id ya da "yol:<from>|<to>".
var dogum_yeri: String = ""
var tasiyici_tip: String = BEARER_CITY
var tasiyici_id: String = ""
## Bedeli kim ödedi (karakter kimliği ya da tayfa adı); `{bedel}` bunu doldurur.
var bedel_odeyen: String = ""
## +1 kervanın lehine, -1 aleyhine.
var yon: int = 1
var siddet: float = 0.5
var gecikme: String = DELAY_SHORT
var olgunluk_gunu: int = 0
var sonme: float = 0.006
var yayilma: int = 0
## İzin ulaştığı yerler (yayılma, §H adım 8). En çok 8.
var bilenler: Array[String] = []
var donus: String = RETURN_PRICE
var donus_karti: String = ""
var durum: String = STATE_OPEN
## Geri döndüğü gün (-1: dönmedi). Defter "karşılığı"nı buna bakarak yazar.
var donus_gunu: int = -1
## Son yayılma günü: söz bir komşuya varmak için gün ister (§D-İ2).
var son_yayilma_gunu: int = -1

const MAX_KNOWERS: int = 8

func is_open() -> bool:
	return durum == STATE_OPEN or durum == STATE_LEGACY

## Bugün dönebilir mi (yer koşulu çağıranda - bkz. TraceLedger.ripe_here).
func is_ripe(day: int) -> bool:
	return is_open() and day >= olgunluk_gunu

func knows(place_id: String) -> bool:
	return dogum_yeri == place_id or bilenler.has(place_id)

func add_knower(place_id: String) -> void:
	if place_id.is_empty() or bilenler.has(place_id) or bilenler.size() >= MAX_KNOWERS:
		return
	bilenler.append(place_id)

func to_dict() -> Dictionary:
	return {
		"id": id, "tur": tur, "kaynak": kaynak, "dogum_gunu": dogum_gunu,
		"dogum_yeri": dogum_yeri, "tasiyici_tip": tasiyici_tip, "tasiyici_id": tasiyici_id,
		"bedel_odeyen": bedel_odeyen, "yon": yon, "siddet": siddet, "gecikme": gecikme,
		"olgunluk_gunu": olgunluk_gunu, "sonme": sonme, "yayilma": yayilma,
		"bilenler": bilenler.duplicate(), "donus": donus, "donus_karti": donus_karti,
		"durum": durum, "donus_gunu": donus_gunu,
		"son_yayilma_gunu": son_yayilma_gunu,
	}

static func from_dict(data: Dictionary) -> Trace:
	var trace := Trace.new()
	trace.id = String(data.get("id", ""))
	trace.tur = String(data.get("tur", TYPE_GRATITUDE))
	trace.kaynak = String(data.get("kaynak", ""))
	trace.dogum_gunu = int(data.get("dogum_gunu", 0))
	trace.dogum_yeri = String(data.get("dogum_yeri", ""))
	trace.tasiyici_tip = String(data.get("tasiyici_tip", BEARER_CITY))
	trace.tasiyici_id = String(data.get("tasiyici_id", ""))
	trace.bedel_odeyen = String(data.get("bedel_odeyen", ""))
	trace.yon = int(data.get("yon", 1))
	trace.siddet = float(data.get("siddet", 0.5))
	trace.gecikme = String(data.get("gecikme", DELAY_SHORT))
	trace.olgunluk_gunu = int(data.get("olgunluk_gunu", 0))
	trace.sonme = float(data.get("sonme", 0.006))
	trace.yayilma = int(data.get("yayilma", 0))
	var knowers: Array = data.get("bilenler", [])
	for place in knowers:
		trace.add_knower(String(place))
	trace.donus = String(data.get("donus", RETURN_PRICE))
	trace.donus_karti = String(data.get("donus_karti", ""))
	trace.durum = String(data.get("durum", STATE_OPEN))
	trace.donus_gunu = int(data.get("donus_gunu", -1))
	trace.son_yayilma_gunu = int(data.get("son_yayilma_gunu", -1))
	return trace
