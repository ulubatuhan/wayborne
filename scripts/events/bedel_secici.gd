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
## Havuz üç kademelidir (§H adım 2, teşhis A1-A2): adı olan yoldaşlar
## (lider hariç) · adı yazılı tayfa elleri (`crew_names`) · gelecekteki sen.
## Kadro onuncu seferde 1'e iniyordu ve oyunun en iyi ikilemleri
## `party_size ≥ 2/3/6` koşulunun arkasında, oyunun hiç ulaşmadığı bir
## durumu bekliyordu. Bedel kadro dışına da düşebildiği için o koşullar
## kaldırıldı: kart kadro 1'de de gelir, yalnız bedeli başka bir sırta biner.
## `pick()` yalnız birinci kademeyi (yoldaş) verir - `CharacterData` döner;
## tayfa elinin `CharacterData`'sı yoktur, onu `pick_bearer()` adıyla döner.

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

## Taşıyıcı kademeleri.
const KIND_COMPANION: String = "yoldas"
const KIND_HAND: String = "el"
const KIND_FUTURE: String = "sen"

## Bedeli ödeyecek sırt, türüyle: `{"tur": …, "ad": String, "kisi": CharacterData}`.
## `kisi` yalnız `KIND_COMPANION` ve `KIND_FUTURE`'da doludur (ikincisinde
## kervanbaşının kendisi). Hiç kimse yoksa `tur` boş döner.
static func pick_bearer(rule: String, session: GameSession) -> Dictionary:
	if session == null:
		return {"tur": "", "ad": "", "kisi": null}
	var companion: CharacterData = pick(rule, session)
	if companion != null:
		return {"tur": KIND_COMPANION, "ad": companion.character_name, "kisi": companion}
	var hand := _pick_hand(session)
	if not hand.is_empty():
		return {"tur": KIND_HAND, "ad": hand, "kisi": null}
	var leader := session.get_player_character()
	if leader == null:
		return {"tur": "", "ad": "", "kisi": null}
	return {"tur": KIND_FUTURE, "ad": leader.character_name, "kisi": leader}

## İkinci kademe: adı yazılı tayfa eli. Ellerin kırgınlığı, bağı, geçmişi
## yok - puanlanacak bir şey taşımıyorlar - o yüzden kural değil sıra karar
## verir: **en son tutulan el**, yani kervanda en kısa süre kalmış olan
## (seçicinin eşitlik kuralının aynısı). Deterministiktir: aynı durum aynı adı
## verir.
static func _pick_hand(session: GameSession) -> String:
	for index in range(session.crew_names.size() - 1, -1, -1):
		var crew_name: String = session.crew_names[index]
		if not crew_name.is_empty():
			return crew_name
	return ""

## Bir seçeneğin metninde yazacak ad; kimse yoksa boş.
static func bearer_name(rule: String, session: GameSession) -> String:
	return String(pick_bearer(rule, session).get("ad", ""))

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
