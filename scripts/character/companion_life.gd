class_name CompanionLife
extends RefCounted

## Yoldaşlar arası bağ ve yoldaşın kendi kararları (görev R1 #2, #4; Y-C17).
## Sahne ağacından bağımsız; GameSession gün başına çağırır, sonuçları yol
## günlüğü okur. Yeni sistem yok: etkiler stres, moral, erzak ve bağ.
##
## Bağ: "idA|idB" (sıralı) -> -3..+3. Kayıtta (GameSession.bonds). İlk değer
## aynı kültürden gelenler için +1, değilse 0. Ortak savaştan sağ çıkmak +1,
## birlikte kamp +0.5, adı taşıma kavgası (varis seçimi) -2. Bağ +2 ve üstü
## dostluk: o çift kolonda yan yana daha sıkı yürür ve her gün birbirini biraz
## rahatlatır; -2 ve altı husumet: araları açılır, sürtüşme stres yazar.

const MIN_BOND: float = -3.0
const MAX_BOND: float = 3.0
const FRIENDS_AT: float = 2.0
const RIVALS_AT: float = -2.0
const SHARED_FIGHT: float = 1.0
const SHARED_CAMP: float = 0.5
const PASSED_OVER_SPLIT: float = -2.0
const FRIEND_DAILY_STRESS: int = -1
const RIVAL_DAILY_STRESS: int = 1

## Kendi kararı: yalnız derdi olan (stresli, iki şikâyetli ya da kötü huylu)
## yoldaş; kişi başına günde ACTION_CHANCE, günde en fazla bir, kişi başına
## ACTION_COOLDOWN_DAYS. Hiçbiri öldürmez, hepsi görünür (günlük ve baloncuk).
const ACTION_CHANCE: float = 0.06
const ACTION_COOLDOWN_DAYS: int = 4
const ACTION_SHARES_RATION: String = "shares_ration"
const ACTION_PRAYS: String = "prays"
const ACTION_SINGS: String = "sings"
const ACTION_SULKS: String = "sulks"
const ACTIONS: Array[String] = [ACTION_SHARES_RATION, ACTION_PRAYS, ACTION_SINGS, ACTION_SULKS]
const ACTION_LINE_KEYS: Dictionary = {
	"shares_ration": "UI_ROAD_ACT_SHARES_RATION", "prays": "UI_ROAD_ACT_PRAYS",
	"sings": "UI_ROAD_ACT_SINGS", "sulks": "UI_ROAD_ACT_SULKS",
}

## --- Ateş başı: kampın sessiz anı (Ruh alt sistemi, tasarım notu §D-R7) ---
##
## Her kampta **en çok bir** sessiz an. Zar yok, öncelik sırası var: ilk
## uyan gösterilir. Zar olsaydı o an bir süs olurdu; sıra olunca o gün
## yaşananın görünen yüzü oluyor.
##
## Sıra: boş yer · bugün bedel ödeyen · bugün hâli değişen · bugün iyi dönen
## iz · aynı ateşte hasım çift · hiçbiri (var olan %6 zar).
const MOMENT_EMPTY_SEAT: String = "bos_yer"
const MOMENT_PRICE: String = "bedel"
const MOMENT_STATE: String = "hal"
const MOMENT_RETURN: String = "donus"
const MOMENT_RIVALS: String = "hasim"
## Boş yerin anı en çok bu kadar kampta bir tekrarlanır: her akşam aynı
## boşluğu göstermek yası bir duvar kâğıdına çevirir.
const EMPTY_SEAT_EVERY_CAMPS: int = 3
const MOMENT_LINE_KEYS: Dictionary = {
	MOMENT_EMPTY_SEAT: "UI_CAMP_MOMENT_EMPTY_SEAT",
	MOMENT_PRICE: "UI_CAMP_MOMENT_PRICE",
	MOMENT_STATE: "UI_CAMP_MOMENT_STATE",
	MOMENT_RETURN: "UI_CAMP_MOMENT_RETURN",
	MOMENT_RIVALS: "UI_CAMP_MOMENT_RIVALS",
}

## Bugünün sessiz anı: {"kind", "ad"} ya da boş. Girdilerin hepsi çağırandan
## gelir (oturum bilinmiyor, sahne ağacı yok) - böylece sıralama tek başına
## sınanabiliyor.
static func quiet_moment(
	party: Array[CharacterData], bonds: Dictionary, empty_seat_name: String,
	seat_shown_ago: int, price_payer: String, changed_state: String,
	good_return: bool, day: int
) -> Dictionary:
	if not empty_seat_name.is_empty() and seat_shown_ago >= EMPTY_SEAT_EVERY_CAMPS:
		return {"kind": MOMENT_EMPTY_SEAT, "ad": empty_seat_name, "gun": day}
	if not price_payer.is_empty():
		return {"kind": MOMENT_PRICE, "ad": price_payer, "gun": day}
	if not changed_state.is_empty():
		return {"kind": MOMENT_STATE, "ad": changed_state, "gun": day}
	if good_return:
		return {"kind": MOMENT_RETURN, "ad": "", "gun": day}
	for i in party.size():
		for j in range(i + 1, party.size()):
			if get_bond(bonds, party[i], party[j]) <= RIVALS_AT:
				return {"kind": MOMENT_RIVALS, "ad": party[i].character_name, "gun": day}
	return {}

static func bond_key(a: CharacterData, b: CharacterData) -> String:
	var ids := [a.character_id, b.character_id]
	ids.sort()
	return "%s|%s" % ids

static func initial_bond(a: CharacterData, b: CharacterData) -> float:
	return 1.0 if a.culture_id == b.culture_id else 0.0

static func get_bond(bonds: Dictionary, a: CharacterData, b: CharacterData) -> float:
	return float(bonds.get(bond_key(a, b), initial_bond(a, b)))

## Bağı değiştirir; eşik geçildiyse "friends"/"rivals"/"" döner (günlük için).
static func change_bond(bonds: Dictionary, a: CharacterData, b: CharacterData, delta: float) -> String:
	if a == b:
		return ""
	var before := get_bond(bonds, a, b)
	var after := clampf(before + delta, MIN_BOND, MAX_BOND)
	bonds[bond_key(a, b)] = after
	if before < FRIENDS_AT and after >= FRIENDS_AT:
		return "friends"
	if before > RIVALS_AT and after <= RIVALS_AT:
		return "rivals"
	return ""

## Bir grubun (savaşa girenler, kampta ateş başındakiler) herkesi birbirine.
static func bond_group(bonds: Dictionary, group: Array, delta: float) -> Array[Array]:
	var crossed: Array[Array] = []
	for i in group.size():
		for j in range(i + 1, group.size()):
			var result := change_bond(bonds, group[i], group[j], delta)
			if not result.is_empty():
				crossed.append([group[i], group[j], result])
	return crossed

## Kolonda yan yana yürüyen çiftin aralık çarpanı: dostlar sıkı, düşmanlar açık.
static func pair_gap_scale(bond: float) -> float:
	if bond >= FRIENDS_AT:
		return 0.6
	if bond <= RIVALS_AT:
		return 1.6
	return 1.0

static func is_troubled(character: CharacterData) -> bool:
	if character.is_stressed():
		return true
	var total := 0
	for key in character.grievances:
		total += int(character.grievances[key])
	if total >= 2:
		return true
	for trait_id in character.trait_ids:
		var t := TraitCatalog.get_trait(trait_id)
		if t != null and not t.is_positive:
			return true
	return false

## Günün kendi kararı: [kişi, eylem] ya da [] (kimse bir şey yapmadı).
static func roll_action(party: Array[CharacterData], day: int, rng: RandomNumberGenerator) -> Array:
	for character in party:
		if character.is_player or not is_troubled(character):
			continue
		if day - character.last_action_day < ACTION_COOLDOWN_DAYS:
			continue
		if rng.randf() < ACTION_CHANCE:
			return [character, ACTIONS[rng.randi_range(0, ACTIONS.size() - 1)]]
	return []
