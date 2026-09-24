class_name CaravanLedger
extends RefCounted

## Kervanın hafızası: kimin geldiği, kimin gittiği, kimin öldüğü ve
## liderliğin kime geçtiği.
##
## **Hiçbir satır silinmiyor.** Bir yoldaş ayrıldığında ya da öldüğünde
## kaydı listeden çıkmıyor, *üstü çiziliyor* (`is_struck`). Sebebi mekanik
## değil: kaybın kaydı, kaybın kendisinden daha çok bağ kuruyor. Silinen
## bir isim hiç var olmamış gibi olur; çizili bir isim, oyuncunun kendi
## geçmişidir. Darkest Dungeon'ın mezarlığı ve This War of Mine'ın
## "hatırlıyoruz" ekranı aynı işi yapıyor.
##
## Defter iki iş görüyor:
##
## 1. **Anlatı.** Parti ekranı bunu okuyup kervanın tarihçesini gösterir.
## 2. **Dünyanın hafızası.** `GameSession.build_event_context()` defterden
##    saydığı birkaç sayıyı (kaç ölü, kaç ayrılan, kaçıncı kuşak) olay
##    havuzuna açıyor, yani yol geçmişini okuyabiliyor. Ayrı bir "hafıza"
##    sistemi icat edilmedi - zaten var olan bayrak/bağlam dili kullanıldı
##    (aynı gerekçe: kampanya hedefleri de `EventCondition`).
##
## Metin burada tutulmuyor, anahtar tutuluyor: satırın okunur hali
## ekranda `tr()` ile çözülüyor (bkz. Localization Rules).

## Satır türleri. Kimlikler kayda yazıldığı için sabit.
const KIND_JOINED: String = "joined"
const KIND_DEPARTED: String = "departed"
const KIND_DIED: String = "died"
const KIND_LED: String = "led"
## Oyuncudan önce adı taşımış olan. Defter oyunun ilk dakikasında boş
## kalmasın, tezini ilk satırından söylesin diye: devraldığın ad zaten birinin
## üstü çizili adıydı. Hiçbir sayaca girmiyor (kampanya/olay bağlamı
## `KIND_DIED`'ı sayıyor, bunu değil) - kurucu senin kaybın değil, mirasın.
const KIND_FOUNDER: String = "founder"

## Tür -> çeviri anahtarı. Tam yazılıyor, çalışma anında birleştirilmiyor
## (bkz. CampaignCatalog.OBJECTIVE_LABEL_KEYS'in aynı notu).
const KIND_LABEL_KEYS: Dictionary = {
	KIND_JOINED: "LEDGER_JOINED",
	KIND_DEPARTED: "LEDGER_DEPARTED",
	KIND_DIED: "LEDGER_DIED",
	KIND_LED: "LEDGER_LED",
	KIND_FOUNDER: "LEDGER_FOUNDER",
}

## Üstü çizili sayılan türler: kervandan ayrılmış olmak.
const STRUCK_KINDS: Array[String] = [KIND_DEPARTED, KIND_DIED, KIND_FOUNDER]

var entries: Array[Dictionary] = []

static func get_kind_label(kind: String) -> String:
	if not KIND_LABEL_KEYS.has(kind):
		return kind
	return String(TranslationServer.translate(String(KIND_LABEL_KEYS[kind])))

## `cause_key` ve `location_id` bir satırı istatistikten hatıraya çeviren
## iki alan: "öldü" değil, "Kurtboğazı yolunda kurtlara düştü". İkisi de
## boş bırakılabilir (eski kayıtlar, sebebin anlamsız olduğu `joined`/`led`).
func record(
	kind: String, character_name: String, day: int, generation: int = 1,
	character_id: String = "", cause_key: String = "", location_id: String = ""
) -> void:
	entries.append({
		"kind": kind,
		"name": character_name,
		"day": day,
		"generation": generation,
		"id": character_id,
		"cause": cause_key,
		"location": location_id,
	})

func is_struck(entry: Dictionary) -> bool:
	return STRUCK_KINDS.has(String(entry.get("kind", "")))

func count_of(kind: String) -> int:
	var total := 0
	for entry in entries:
		if String(entry.get("kind", "")) == kind:
			total += 1
	return total

## Bir türün satırları, belirli bir sebep hariç. Finalin kayıp kapısı
## kendi isteğiyle yollanan (şehirde işten çıkarılan) biri için
## açılmasın diye var - aksi hâlde meydandan iki ucuz tayfa tutup
## göndermek "kayıp" satın almak olurdu.
func count_of_excluding_cause(kind: String, excluded_cause: String) -> int:
	var total := 0
	for entry in entries:
		if String(entry.get("kind", "")) != kind:
			continue
		if String(entry.get("cause", "")) == excluded_cause:
			continue
		total += 1
	return total

## Bir ismin defterdeki bütün satırları - parti ekranı bir kişinin
## hikâyesini bir arada gösterebilsin diye.
func entries_for(character_name: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry in entries:
		if String(entry.get("name", "")) == character_name:
			found.append(entry)
	return found

## Kimlikle eşleşen satırlar; kimliği olmayan eski satırlar için isimle
## eşleşmeye düşer.
func entries_for_id(character_id: String, fallback_name: String = "") -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry in entries:
		var entry_id := String(entry.get("id", ""))
		if not character_id.is_empty() and entry_id == character_id:
			found.append(entry)
		elif entry_id.is_empty() and not fallback_name.is_empty() \
				and String(entry.get("name", "")) == fallback_name:
			found.append(entry)
	return found

## Satırın okunur hali: "Ad — sebep, yer (gün N)". Sebebi olmayan satır
## eski biçimde, türün etiketiyle kalır.
static func describe(entry: Dictionary) -> String:
	var name := String(entry.get("name", ""))
	var cause := String(entry.get("cause", ""))
	var day := int(entry.get("day", 0))
	if cause.is_empty():
		return "%s — %s" % [name, get_kind_label(String(entry.get("kind", "")))]
	var cause_text := String(TranslationServer.translate(cause))
	var location_id := String(entry.get("location", ""))
	var location := WorldMapData.get_location_by_id(location_id) if not location_id.is_empty() else null
	if location != null:
		return String(TranslationServer.translate("LEDGER_LINE_WITH_PLACE")) % [
			name, cause_text, location.location_name, day
		]
	return String(TranslationServer.translate("LEDGER_LINE")) % [name, cause_text, day]

## En yeniden eskiye. Ekran her zaman son olanı önce gösteriyor: defteri
## açan oyuncunun sorusu "en son ne oldu".
func recent(limit: int = 0) -> Array[Dictionary]:
	var reversed: Array[Dictionary] = []
	for index in range(entries.size() - 1, -1, -1):
		reversed.append(entries[index])
		if limit > 0 and reversed.size() >= limit:
			break
	return reversed

func to_array() -> Array:
	var data: Array = []
	for entry in entries:
		data.append(entry.duplicate())
	return data

func load_from_array(data: Array) -> void:
	entries.clear()
	for raw in data:
		if not (raw is Dictionary):
			continue
		var entry: Dictionary = raw
		entries.append({
			"kind": String(entry.get("kind", KIND_JOINED)),
			"name": String(entry.get("name", "")),
			"day": int(entry.get("day", 0)),
			"generation": maxi(0, int(entry.get("generation", 1))),
			"id": String(entry.get("id", "")),
			"cause": String(entry.get("cause", "")),
			"location": String(entry.get("location", "")),
		})
