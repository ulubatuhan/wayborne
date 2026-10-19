class_name StartOrigins
extends RefCounted

## Hafif meta ilerleme (görev Y-D05): güç değil çeşitlilik. Biten soylar
## (LineageArchive) yeni başlangıç kökenleri açar; her köken bir takastır -
## borçsuz ama yoksul, ünlü ama daha borçlu - hiçbiri düz bir üstünlük değil.
## Açılımlar arşiv dosyasında (meta kayıt) kalır, arşivden bir soy düşse de.

const FATHER: String = "father"
const EXILE: String = "exile"
const GUILD_WARD: String = "guild_ward"
const SALT_RUNNER: String = "salt_runner"
const DROVERS: String = "drovers"
const WIDOW_LEDGER: String = "widow_ledger"

const ORDER: Array[String] = [FATHER, EXILE, GUILD_WARD, SALT_RUNNER, DROVERS, WIDOW_LEDGER]

const NAME_KEYS: Dictionary = {
	FATHER: "UI_ORIGIN_FATHER", EXILE: "UI_ORIGIN_EXILE", GUILD_WARD: "UI_ORIGIN_GUILD_WARD",
	SALT_RUNNER: "UI_ORIGIN_SALT_RUNNER", DROVERS: "UI_ORIGIN_DROVERS", WIDOW_LEDGER: "UI_ORIGIN_WIDOW_LEDGER",
}
const DESC_KEYS: Dictionary = {
	FATHER: "UI_ORIGIN_FATHER_DESC", EXILE: "UI_ORIGIN_EXILE_DESC", GUILD_WARD: "UI_ORIGIN_GUILD_WARD_DESC",
	SALT_RUNNER: "UI_ORIGIN_SALT_RUNNER_DESC", DROVERS: "UI_ORIGIN_DROVERS_DESC", WIDOW_LEDGER: "UI_ORIGIN_WIDOW_LEDGER_DESC",
}
## Kilitliyken gösterilen sebep (gizlenmez, sebebiyle kilitli).
const UNLOCK_KEYS: Dictionary = {
	EXILE: "UI_ORIGIN_UNLOCK_EXILE", GUILD_WARD: "UI_ORIGIN_UNLOCK_GUILD_WARD",
	SALT_RUNNER: "UI_ORIGIN_UNLOCK_SALT_RUNNER", DROVERS: "UI_ORIGIN_UNLOCK_DROVERS",
	WIDOW_LEDGER: "UI_ORIGIN_UNLOCK_WIDOW_LEDGER",
}
## Kurucu satırının sebebi: her köken defteri başka bir hikâyeyle açar.
const FOUNDER_CAUSE_KEYS: Dictionary = {
	EXILE: "LEDGER_CAUSE_ORIGIN_EXILE", GUILD_WARD: "LEDGER_CAUSE_ORIGIN_GUILD_WARD",
	SALT_RUNNER: "LEDGER_CAUSE_ORIGIN_SALT_RUNNER", DROVERS: "LEDGER_CAUSE_ORIGIN_DROVERS",
	WIDOW_LEDGER: "LEDGER_CAUSE_ORIGIN_WIDOW_LEDGER",
}

const GUILD_WARD_JOURNEYS: int = 10
const SALT_RUNNER_GRAVES: int = 3
const DROVERS_DAYS: int = 120
const WIDOW_GENERATIONS: int = 3

const EXILE_GOLD_SHARE: float = 0.4
const EXILE_REPUTATION: int = -4
const GUILD_WARD_REPUTATION: int = 6
const GUILD_WARD_DEBT_SHARE: float = 2.0
const SALT_RUNNER_SALT: int = 8
const SALT_RUNNER_DEBT_TERM_DAYS: int = 30
const DROVERS_PROVISIONS: int = 12
const DROVERS_GOLD_SHARE: float = 0.5
const WIDOW_DEBT_SHARE: float = 0.5

## Bir soy kaydının açtığı kökenler (arşivin build_record biçimi).
static func unlocks_for(lineage: Dictionary) -> Array[String]:
	var out: Array[String] = [EXILE]
	if int(lineage.get("journeys", 0)) >= GUILD_WARD_JOURNEYS:
		out.append(GUILD_WARD)
	if (lineage.get("graves", []) as Array).size() >= SALT_RUNNER_GRAVES:
		out.append(SALT_RUNNER)
	if int(lineage.get("days", 0)) >= DROVERS_DAYS:
		out.append(DROVERS)
	if int(lineage.get("generations", 1)) >= WIDOW_GENERATIONS:
		out.append(WIDOW_LEDGER)
	return out

static func is_unlocked(origin: String, unlocked: Array) -> bool:
	return origin == FATHER or unlocked.has(origin)

## Kökeni yeni oyuna işler; start_playthrough ve inherit_father_caravan'dan
## sonra çağrılır (babanın borcunu büker ya da kaldırır).
static func apply(session: GameSession, origin: String) -> void:
	session.origin_id = origin
	if origin == FATHER or not ORDER.has(origin):
		session.origin_id = FATHER
		return
	var father_debt := session.debts.get_debt(GameSession.FATHER_DEBT_ID)
	if origin == EXILE:
		_clear_debt(session, father_debt)
		_scale_gold(session, EXILE_GOLD_SHARE)
		session.change_reputation(EXILE_REPUTATION)
	elif origin == GUILD_WARD:
		if father_debt != null:
			father_debt.principal = int(round(float(father_debt.principal) * GUILD_WARD_DEBT_SHARE))
		session.change_reputation(GUILD_WARD_REPUTATION)
	elif origin == SALT_RUNNER:
		if father_debt != null:
			father_debt.due_day = session.total_days_elapsed + SALT_RUNNER_DEBT_TERM_DAYS
		session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.CONTRABAND_SALT), SALT_RUNNER_SALT)
	elif origin == DROVERS:
		_clear_debt(session, father_debt)
		_scale_gold(session, DROVERS_GOLD_SHARE)
		session.change_provisions(DROVERS_PROVISIONS)
	elif origin == WIDOW_LEDGER:
		if father_debt != null:
			father_debt.principal = int(round(float(father_debt.principal) * WIDOW_DEBT_SHARE))
	for entry in session.ledger.entries:
		if String(entry.get("kind", "")) == CaravanLedger.KIND_FOUNDER:
			entry["cause"] = String(FOUNDER_CAUSE_KEYS[origin])
			break

static func _clear_debt(session: GameSession, debt: Debt) -> void:
	if debt != null:
		session.debts.pay(debt.debt_id, debt.principal)

static func _scale_gold(session: GameSession, share: float) -> void:
	var gold := session.wallet.balance
	var keep := int(round(float(gold) * share))
	if gold > keep:
		session.wallet.spend(gold - keep)
