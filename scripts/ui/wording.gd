class_name Wording
extends RefCounted

## Sayı değil söz (görev Y-H03, kullanıcı notu: "-10 moral yerine moral düşük
## yazsın"). Bir değeri dört kademeli bir kelimeye, nedenlerini kısa cümlelere
## çevirir; sayı ikinci planda (ipucunun ikinci satırı, satırın sonunda parantez).
## Dil kılavuzu: docs/design_notes/dil_kilavuzu.md.

const MORALE: String = "morale"
const STRESS: String = "stress"
const STAMINA: String = "stamina"
const DANGER: String = "danger"

## Kademe eşikleri (pay olarak, küçükten büyüğe): altı -> 0, ... üstü -> 3.
const BAND_EDGES: Array[float] = [0.25, 0.5, 0.75]
## Yüksek olanın kötü olduğu değerler: kelime sırası ters.
const HIGH_IS_BAD: Array[String] = [STRESS, DANGER]
const BAND_KEYS: Dictionary = {
	MORALE: ["WORD_MORALE_0", "WORD_MORALE_1", "WORD_MORALE_2", "WORD_MORALE_3"],
	STRESS: ["WORD_STRESS_0", "WORD_STRESS_1", "WORD_STRESS_2", "WORD_STRESS_3"],
	STAMINA: ["WORD_STAMINA_0", "WORD_STAMINA_1", "WORD_STAMINA_2", "WORD_STAMINA_3"],
	DANGER: ["WORD_DANGER_0", "WORD_DANGER_1", "WORD_DANGER_2", "WORD_DANGER_3"],
}
const RECENT_DEATH_DAYS: int = 3
const NEAR_BREAK_STRESS: int = 70
## Etki satırında "büyük" sayılan değişim (moral ve stres puanı).
const BIG_CHANGE: int = 8

static func band(value: float, max_value: float) -> int:
	var share := clampf(value / maxf(1.0, max_value), 0.0, 1.0)
	var b := 0
	for edge in BAND_EDGES:
		if share >= edge:
			b += 1
	return b

static func level_key(kind: String, value: float, max_value: float) -> String:
	return String(BAND_KEYS[kind][band(value, max_value)])

## Değerin şimdiki nedenleri, okunur cümleler hâlinde (çevrilmiş).
static func reasons(session: GameSession, kind: String) -> Array[String]:
	var out: Array[String] = []
	if kind == MORALE or kind == STRESS:
		var hungry := 0
		for character in session.get_party():
			hungry = maxi(hungry, character.consecutive_hungry_days)
		hungry = maxi(hungry, session.crew_hungry_nights)
		if hungry > 0:
			out.append(TranslationServer.translate("WORD_REASON_HUNGRY") % hungry)
		for entry in session.ledger.entries:
			if String(entry.get("kind", "")) == CaravanLedger.KIND_DIED \
					and session.total_days_elapsed - int(entry.get("day", -99)) <= RECENT_DEATH_DAYS:
				out.append(TranslationServer.translate("WORD_REASON_DEATH") % String(entry.get("name", "")))
				break
	if kind == MORALE and not session.debts.get_overdue_debts(session.total_days_elapsed).is_empty():
		out.append(TranslationServer.translate("WORD_REASON_DEBT"))
	if kind == STRESS:
		var worst := session.get_max_stress_character()
		if worst != null and worst.stress >= NEAR_BREAK_STRESS:
			out.append(TranslationServer.translate("WORD_REASON_NEAR_BREAK") % worst.character_name)
	return out

## İpucu: önce söz ("Moral düşük: 2 gündür aç"), sonra sayı.
static func gauge_tooltip(label: String, kind: String, value: float, max_value: float, why: Array[String]) -> String:
	var word: String = String(TranslationServer.translate(level_key(kind, value, max_value)))
	var head: String = word if why.is_empty() else "%s: %s" % [word, ", ".join(why)]
	return "%s\n%s %d/%d" % [head, label, int(round(value)), int(round(max_value))]

## Anahtarlar tam yazılı (Localization Rules: çalışırken birleştirilmez):
## [yukarı küçük, yukarı büyük, aşağı küçük, aşağı büyük].
const PROVISIONS: String = "provisions"
const REPUTATION: String = "reputation"
const GOLD: String = "gold"
const CHANGE_KEYS: Dictionary = {
	MORALE: ["WORD_MORALE_UP_SMALL", "WORD_MORALE_UP_BIG", "WORD_MORALE_DOWN_SMALL", "WORD_MORALE_DOWN_BIG"],
	STRESS: ["WORD_STRESS_UP_SMALL", "WORD_STRESS_UP_BIG", "WORD_STRESS_DOWN_SMALL", "WORD_STRESS_DOWN_BIG"],
	PROVISIONS: ["WORD_PROVISIONS_UP_SMALL", "WORD_PROVISIONS_UP_BIG", "WORD_PROVISIONS_DOWN_SMALL", "WORD_PROVISIONS_DOWN_BIG"],
	DANGER: ["WORD_DANGER_UP_SMALL", "WORD_DANGER_UP_BIG", "WORD_DANGER_DOWN_SMALL", "WORD_DANGER_DOWN_BIG"],
	REPUTATION: ["WORD_REPUTATION_UP_SMALL", "WORD_REPUTATION_UP_BIG", "WORD_REPUTATION_DOWN_SMALL", "WORD_REPUTATION_DOWN_BIG"],
	GOLD: ["WORD_GOLD_UP_SMALL", "WORD_GOLD_UP_BIG", "WORD_GOLD_DOWN_SMALL", "WORD_GOLD_DOWN_BIG"],
}
## Neyin "büyük" sayıldığı türüne göre (Y-H03): beş altın küçük, beş itibar büyük.
const BIG_CHANGES: Dictionary = {PROVISIONS: 10, DANGER: 10, REPUTATION: 3, GOLD: 50}
## Sayının birimi parantezde (tehlike yüzde).
const CHANGE_SUFFIX: Dictionary = {DANGER: "%"}

## Etki satırı: "Moral sarsıldı (-10)". Yön ve büyüklük kelimede, sayı parantezde.
static func change_line(kind: String, amount: int) -> String:
	var big := int(BIG_CHANGES.get(kind, BIG_CHANGE))
	var slot := (0 if amount > 0 else 2) + (1 if absi(amount) >= big else 0)
	return "%s (%+d%s)" % [TranslationServer.translate(String(CHANGE_KEYS[kind][slot])), amount, String(CHANGE_SUFFIX.get(kind, ""))]
