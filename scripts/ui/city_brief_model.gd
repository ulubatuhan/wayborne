class_name CityBriefModel
extends RefCounted

## `CityBriefPanel`'in karar vermeyen, düğüm kurmayan yarısı: oturumdan
## "kervanın neyi eksik" ve "defter en son kimi hatırlıyor" listelerini
## düz sözlükler olarak üretir. Panel yalnızca bunları çizer. Böylece "her
## uyarı onu düzelten ekranı gösterir" kuralı bir Control kurmadan,
## sahne ağacı olmadan sınanabilir (bkz. tests/test_city_commerce.gd).
##
## `tr()` bir örnek metodu, statik fonksiyondan çağrılamıyor - metin
## `TranslationServer.translate()` ile çözülüyor (bkz. Localization Rules).

## Bu kadar gün kalınca vade "yaklaşıyor" sayılır - DebtPanel ile aynı eşik.
const DUE_SOON_DAYS: int = 7

## Stres bu çizginin üstündeyse şehirde müdahale önerilir. Kavga olayının
## eşiğinin (bkz. evt_stress_brawl) biraz altında: uyarı, kriz patladıktan
## sonra değil, önce gelmeli.
const STRESS_WARNING: int = 30

## Eldeki erzak bu kadar günden aza yetiyorsa uyarılır. Haritadaki en kısa
## bacak dört gün, en uzunu altı; altının altına düşmek "hiçbir yere
## gidemezsin" demek.
const PROVISION_WARNING_DAYS: int = 6

## Her ihtiyaç: {"text", "action", "scene", "urgent"}. İhtiyaç yoksa boş
## liste - kalıcı bir yeşil tik listesi gürültüdür.
static func build_needs(session: GameSession) -> Array[Dictionary]:
	var needs: Array[Dictionary] = []

	# Borç varsa *her zaman* görünür, vadesi uzak olsa bile: kervanın 350
	# altın açığı olması başlı başına bir ihtiyaçtır ve yalnızca vade
	# yaklaşınca göstermek, oyuncuya batışını son hafta haber verirdi.
	# Aciliyet renkte: gecikmiş ve yaklaşan kırmızı, uzak vade sade.
	if session.get_total_debt() > 0:
		var soonest := session.debts.get_soonest_due_in_days(session.total_days_elapsed)
		if soonest < 0:
			needs.append(_need(
				_t("UI_BRIEF_NEED_DEBT_OVERDUE") % session.get_total_debt(),
				_t("UI_BRIEF_GO_GUILD"), Nav.GUILD, true
			))
		else:
			needs.append(_need(
				_t("UI_BRIEF_NEED_DEBT_SOON") % [session.get_total_debt(), soonest],
				_t("UI_BRIEF_GO_GUILD"), Nav.GUILD, soonest <= DUE_SOON_DAYS
			))

	# Erzak, yolun omurgası: eldeki erzağın kaç güne yettiği rotadan
	# bağımsız ve dürüst bir sayı.
	var daily := session.get_daily_provision_consumption()
	var days_of_food := session.get_provisions() / maxi(1, daily)
	if days_of_food < PROVISION_WARNING_DAYS:
		needs.append(_need(
			_t("UI_BRIEF_NEED_PROVISIONS") % [session.get_provisions(), days_of_food, daily],
			_t("UI_BRIEF_GO_MARKET"), Nav.ECONOMY, days_of_food <= 0
		))

	if session.owned_wagon_damaged > 0:
		needs.append(_need(
			_t("UI_BRIEF_NEED_REPAIR") % session.owned_wagon_damaged,
			_t("UI_BRIEF_GO_YARD"), Nav.CARAVAN_YARD, true
		))

	if session.accepted_contracts.is_empty():
		needs.append(_need(
			_t("UI_BRIEF_NEED_CONTRACT"), _t("UI_BRIEF_GO_GUILD"), Nav.GUILD, false
		))

	if session.party_stress >= STRESS_WARNING:
		needs.append(_need(
			_t("UI_BRIEF_NEED_STRESS") % [session.party_stress, GameSession.MAX_STRESS],
			_t("UI_BRIEF_GO_TAVERN"), Nav.TAVERN, false
		))

	var free_slots := session.get_party_capacity() - session.get_party().size()
	if free_slots > 0:
		needs.append(_need(
			_t("UI_BRIEF_NEED_CREW") % free_slots,
			_t("UI_BRIEF_GO_TAVERN"), Nav.TAVERN, false
		))

	return needs

## Defterin en son üstü çizili satırı: {"text", "detail"}. `detail`, satırın
## sebebi ve yeri varsa onun okunur hali; yoksa boş. Hiç üstü çizili satır
## yoksa boş sözlük ("no need, no row").
## Yas: son çizili satır bir ölümse ve bu kadar gün içinde yazıldıysa
## brifingin hatırası siyah bir kurdele (C1) taşıyor. Kaydedilen yeni bir
## alan değil - defterin kendi günü ile takvimden okunuyor, yeniden
## yüklemek yası ne uzatır ne kısaltır.
const MOURNING_DAYS: int = 14

static func build_memory(session: GameSession) -> Dictionary:
	var struck := session.ledger.recent().filter(session.ledger.is_struck)
	if struck.is_empty():
		return {}
	var entry: Dictionary = struck[0]
	var kind := String(entry.get("kind", ""))
	var key := "UI_BRIEF_MEMORY_DEPARTED"
	if kind == CaravanLedger.KIND_DIED:
		key = "UI_BRIEF_MEMORY_DIED"
	elif kind == CaravanLedger.KIND_FOUNDER:
		key = "UI_BRIEF_MEMORY_FOUNDER"
	var detail := ""
	if not String(entry.get("cause", "")).is_empty():
		detail = CaravanLedger.describe(entry)
	var mourning := (
		kind == CaravanLedger.KIND_DIED
		and session.total_days_elapsed - int(entry.get("day", -MOURNING_DAYS - 1)) <= MOURNING_DAYS
	)
	return {
		"text": _t(key) % String(entry.get("name", "")), "detail": detail, "mourning": mourning,
	}

static func _need(text: String, action_label: String, scene_path: String, urgent: bool) -> Dictionary:
	return {"text": text, "action": action_label, "scene": scene_path, "urgent": urgent}

static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))
