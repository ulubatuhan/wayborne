class_name PassCatalog
extends RefCounted

## Geçiş belgeleri (görev Y-C31; SIDERIA §10.1, §10.3, §10.5, §10.9).
##
## Yolun sahibi bir güçtür ve kervan ona öder; karşılığında süreli bir belge
## alır ve belge deftere yazılır. Dört güç, dört belge, tek sistem:
## Orbeyan'ın tamgası (Gokyurt), Öküz Kâtibi'nin boynuz fişi (Ezmerak), dağlıların
## bedel taşı (Ayazkaya), Orvahel yolunun zili (Avuçiçi). Belgesiz geçiş yasak
## değil, bedellidir: kart açılır ve bedeli orada ödenir.
##
## Belge yola bağlı, bölgeye değil: boynuz fiş Ezmerak'tan çıkarken ve
## Golcavar'a giderken istenir; Çitler'in öbür şehirleri onu tanımaz.

const TAMGA: String = "tamga"
const BOYNUZ_FIS: String = "boynuz_fis"
const BEDEL_TASI: String = "bedel_tasi"
const ZIL: String = "zil"

## id -> {"to": varış yerleri, "from": çıkış yerleri, "name": anahtar}
const PASSES: Dictionary = {
	TAMGA: {"to": ["serai_orbeyan"], "from": [], "name": "PASS_TAMGA"},
	BOYNUZ_FIS: {"to": ["golcavar"], "from": ["ezmerak"], "name": "PASS_BOYNUZ_FIS"},
	BEDEL_TASI: {"to": ["kesgrav", "brazdun"], "from": ["kesgrav"], "name": "PASS_BEDEL_TASI"},
	ZIL: {"to": ["orvahel"], "from": [], "name": "PASS_ZIL"},
}

## Bu yolculuk bu belgeyi istiyor mu.
static func required_on(pass_id: String, origin_id: String, destination_id: String) -> bool:
	var spec: Dictionary = PASSES.get(pass_id, {})
	if spec.is_empty():
		return false
	return (spec["to"] as Array).has(destination_id) or (spec["from"] as Array).has(origin_id)

static func name_key(pass_id: String) -> String:
	return String((PASSES.get(pass_id, {}) as Dictionary).get("name", ""))
