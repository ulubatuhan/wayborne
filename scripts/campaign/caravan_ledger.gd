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

## Tür -> çeviri anahtarı. Tam yazılıyor, çalışma anında birleştirilmiyor
## (bkz. CampaignCatalog.OBJECTIVE_LABEL_KEYS'in aynı notu).
const KIND_LABEL_KEYS: Dictionary = {
	KIND_JOINED: "LEDGER_JOINED",
	KIND_DEPARTED: "LEDGER_DEPARTED",
	KIND_DIED: "LEDGER_DIED",
	KIND_LED: "LEDGER_LED",
}

## Üstü çizili sayılan türler: kervandan ayrılmış olmak.
const STRUCK_KINDS: Array[String] = [KIND_DEPARTED, KIND_DIED]

var entries: Array[Dictionary] = []

static func get_kind_label(kind: String) -> String:
	if not KIND_LABEL_KEYS.has(kind):
		return kind
	return String(TranslationServer.translate(String(KIND_LABEL_KEYS[kind])))

func record(kind: String, character_name: String, day: int, generation: int = 1) -> void:
	entries.append({
		"kind": kind,
		"name": character_name,
		"day": day,
		"generation": generation,
	})

func is_struck(entry: Dictionary) -> bool:
	return STRUCK_KINDS.has(String(entry.get("kind", "")))

func count_of(kind: String) -> int:
	var total := 0
	for entry in entries:
		if String(entry.get("kind", "")) == kind:
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
			"generation": maxi(1, int(entry.get("generation", 1))),
		})
