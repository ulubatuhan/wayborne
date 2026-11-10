class_name BedelSecici
extends RefCounted

## Bir seçimin bedelini **kim** öder (Ahlak alt sistemi, tasarım notu
## `docs/design_notes/ahlak_ruh_iz_mimarisi.md` §D-A2).
##
## Niye gerekti: bugüne kadar bir kartın bedeli ya "en yaralı yoldaş"a
## (`LEAVE_BEHIND`) ya lidere ya da bir statta en iyi olana düşüyordu. Oysa
## oyun kimin kime yakın olduğunu, kimin neye kırgın olduğunu, kimin neden
## yola düştüğünü zaten biliyor (`bonds`, `grievances`, `rapport`,
## `backstory_id`) - ve hiçbir kart bunu okumuyordu. Ölçüm (uzman denetimi,
## 2026-11-07) bunun bedelini de gösterdi: kervan onuncu seferde tek kişiye
## iniyor, yani "en zayıfı seç" kuralının seçecek kimsesi kalmıyor.
##
## **Seçim rastgele değildir.** Aynı durum aynı kişiyi verir; kart açılırken
## ad seçeneğin üstünde yazar (bkz. `EventEffectApplier.get_choice_target`,
## `road_journey.gd` UI_ROAD_CHOICE_TARGET). Bilmeden ödetmek ikilem değil
## tuzaktır.
##
## Havuz: adı olan yoldaşlar (lider hariç). Havuz boşsa `null` döner ve
## bedel "gelecekteki sen"e yazılır - çağıran taraf (olay etkisi) o zaman
## kervanın kendisinden alır.

## Kural kimlikleri - kartın `text_value`'sunda yazan ad.
const RULE_WEAKEST: String = "en_zayif"
const RULE_GRIEVED: String = "en_kirgin"
const RULE_BONDED: String = "bagi_olan"
const RULE_UNSWORN: String = "yemini_yok"
const RULE_BACKSTORY: String = "gecmisi_uyan"
const RULES: Array[String] = [
	RULE_WEAKEST, RULE_GRIEVED, RULE_BONDED, RULE_UNSWORN, RULE_BACKSTORY,
]

## Aynı kişi art arda ödemesin: son ödemeden bu kadar gün geçmediyse puanı
## düşer (silinmez - tek kişilik bir kervanda yine o öder).
const RECENT_PRICE_DAYS: int = 10
const RECENT_PRICE_PENALTY: float = 1.5
## Yeminliyi geride bırakmak sözü bozmaktır (Y-C33): kural bunu istediğinde
## yeminli kişi fiilen seçilemez hâle gelir.
const SWORN_BLOCK: float = -99.0
## Lidere uzak olan daha kolay harcanır; yakınlık (rapport) koruma sağlar.
const RAPPORT_WEIGHT: float = 0.5
## Hâli bozuk olan (Sönük/Gidici) öne çıkar - hâl makinesi gelene kadar
## (§H adım 6) bu pay stresten okunuyor.
const WORN_BONUS: float = 1.0
const WORN_STRESS_FROM: int = 70
## Tek kalan yoldaşı korumak: "en zayıfı" dışındaki kurallar onu son seçer.
const LAST_COMPANION_PENALTY: float = 2.0

## Bedeli ödeyecek kişi. `session` yoksa ya da havuz boşsa `null`.
static func pick(rule: String, session: GameSession) -> CharacterData:
	if session == null:
		return null
	var havuz: Array[CharacterData] = []
	for member in session.get_party():
		if not member.is_player:
			havuz.append(member)
	if havuz.is_empty():
		return null
	var tek_kisi := havuz.size() == 1
	var best: CharacterData = null
	var best_score := -INF
	for aday in havuz:
		var score: float = _score(rule, aday, session, tek_kisi)
		# Eşitlikte kervanda en kısa süre kalmış olan: yeni gelen önce verir.
		if score > best_score or (is_equal_approx(score, best_score) and _newer(aday, best, session)):
			best_score = score
			best = aday
	if best_score <= SWORN_BLOCK / 2.0:
		return null
	return best

## Bir seçeneğin metninde yazacak ad; kimse yoksa boş.
static func bearer_name(rule: String, session: GameSession) -> String:
	var who: CharacterData = pick(rule, session)
	return who.character_name if who != null else ""

static func _score(rule: String, aday: CharacterData, session: GameSession, tek_kisi: bool) -> float:
	var score := 0.0
	match rule:
		RULE_WEAKEST:
			var ratio: float = float(aday.current_hp) / float(maxi(1, aday.get_max_hp()))
			score += 3.0 * (1.0 - ratio)
		RULE_GRIEVED:
			score += 2.0 * _grievance_weight(aday)
		RULE_BONDED:
			score += 2.0 * _strongest_bond(aday, session)
		RULE_UNSWORN:
			if aday.sworn:
				return SWORN_BLOCK
			score += 1.0
		RULE_BACKSTORY:
			score += 3.0 if _backstory_matches(aday, session) else 0.0
		_:
			var fallback: float = float(aday.current_hp) / float(maxi(1, aday.get_max_hp()))
			score += 3.0 * (1.0 - fallback)
	score += RAPPORT_WEIGHT * float(CharacterData.MAX_RAPPORT - aday.rapport)
	if aday.stress >= WORN_STRESS_FROM:
		score += WORN_BONUS
	if session.total_days_elapsed - aday.last_price_day < RECENT_PRICE_DAYS:
		score -= RECENT_PRICE_PENALTY
	if tek_kisi and rule != RULE_WEAKEST:
		score -= LAST_COMPANION_PENALTY
	return score

static func _grievance_weight(aday: CharacterData) -> float:
	var total := 0.0
	for key in aday.grievances:
		var weight := 1.0
		if key == CharacterData.GRIEVANCE_OATH_BROKEN:
			weight = float(CharacterData.OATH_BROKEN_WEIGHT)
		total += weight * float(aday.grievances[key])
	return total

static func _strongest_bond(aday: CharacterData, session: GameSession) -> float:
	var best := 0.0
	for member in session.get_party():
		if member == aday:
			continue
		var bond: float = session.get_bond(aday, member)
		if bond > best:
			best = bond
	return best

## Kartın istediği geçmiş: olayın kendi metni değil, kervanın hâli söyler -
## aç bir kervanda açlıktan yola düşen, borçlu bir kervanda borçlu öne çıkar.
static func _backstory_matches(aday: CharacterData, session: GameSession) -> bool:
	if aday.backstory_id.is_empty():
		return false
	if aday.backstory_id == CharacterData.BACKSTORY_HUNGRY:
		return session.is_caravan_hungry()
	if aday.backstory_id == CharacterData.BACKSTORY_DEBTOR:
		return session.get_total_debt() > 0
	if aday.backstory_id == CharacterData.BACKSTORY_FUGITIVE:
		return session.journey_region() == GameSession.GUARDED_REGION
	return false

static func _newer(aday: CharacterData, other: CharacterData, session: GameSession) -> bool:
	if other == null:
		return true
	return session.get_join_day(aday) > session.get_join_day(other)
