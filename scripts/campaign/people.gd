class_name People
extends RefCounted

## Adı olan, hatırlayan kişiler (görev Y-C13) ve yolun hafızası (N32); T16-09.
## Sütunlar: Defter unutmaz · Yol yaşar · İnsanlar aşınır.
##
## Her şehirde üç kişi kalıcıdır: lonca ustası, tefeci ve taverna sahibi. Kervanı
## görür, kaç kez geldiğini, verdiği işi tutup tutmadığını hatırlar; yaşlanır,
## kıtlıkta erken ölür. Her biri kendi kişisel iş zincirini verir (şehrin
## istediği maldan, giderek büyüyen). Yolda ise kaçan haydut reisi adıyla,
## yüzündeki izle ve kiniyle geri döner; her kaçışta çetesi büyür.
##
## Kural (N32): yeni bir dünya icat etmez, olay sözlüğüyle konuşur; kişiler
## kayıtta, tohumdan kurulur, yeniden yüklemeyle değişmez.

const ROLE_GUILD: String = "lonca"
const ROLE_LENDER: String = "tefeci"
const ROLE_INNKEEPER: String = "taverna"
const CITY_ROLES: Array[String] = [ROLE_GUILD, ROLE_LENDER, ROLE_INNKEEPER]
const ROLE_CHIEF: String = "reis"
const ROLE_KEYS: Dictionary = {
	ROLE_GUILD: "PEOPLE_ROLE_GUILD", ROLE_LENDER: "PEOPLE_ROLE_LENDER",
	ROLE_INNKEEPER: "PEOPLE_ROLE_INNKEEPER", ROLE_CHIEF: "PEOPLE_ROLE_CHIEF",
}
## Yaş: oyunun yılı Scarcity.YEAR_DAYS gün.
const MIN_AGE: int = 28
const MAX_AGE: int = 63
## Altmışından sonra her yıl için günlük ölüm payı; kıtlık bunu katlar.
const OLD_AGE_DEATH_PER_DAY: float = 0.0004
const FAMINE_DEATH_MULTIPLIER: float = 3.0
## İş zinciri: istenen mal ve miktar, süre, ödül.
const CHAIN_STEPS: int = 3
const CHAIN_BASE_QTY: int = 4
const CHAIN_QTY_PER_STEP: int = 3
const CHAIN_DAYS: int = 24
const CHAIN_GOLD_PER_STEP: int = 45
const CHAIN_REPUTATION: int = 2
## Reisin yüzündeki iz (çeviri anahtarları); kaçışta biri seçilir.
const SCARS: Array[String] = ["PEOPLE_SCAR_EAR", "PEOPLE_SCAR_EYE", "PEOPLE_SCAR_CHEEK", "PEOPLE_SCAR_HAND"]
## Reisin kaçma payı: yenilen çetenin reisi her zaman ölmez.
const CHIEF_ESCAPE_CHANCE: float = 0.5

var persons: Dictionary = {}
## Şu an kartta adı geçen reis (olay metni {nemesis} ile ona bakar).
var active_chief: String = ""
## Şu an kartta olan yoldaki yer (T16-11): {place} adı, {off} sapma günü.
var active_place_name: String = ""
var active_place_off: int = 0

# --- şehrin kişileri ---

func ensure_city(location_id: String, day: int) -> void:
	if location_id.is_empty() or persons.has(_id(location_id, ROLE_GUILD)):
		return
	var location := WorldMapData.get_location_by_id(location_id)
	if location == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("people|%s" % location_id)
	var used: Array[String] = []
	for role in CITY_ROLES:
		var person := _make(rng, location.peoples, used)
		person["id"] = _id(location_id, role)
		person["role"] = role
		person["home"] = location_id
		person["born"] = day - rng.randi_range(MIN_AGE, MAX_AGE) * Scarcity.YEAR_DAYS - rng.randi_range(0, Scarcity.YEAR_DAYS - 1)
		persons[person["id"]] = person

func city_people(location_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for role in CITY_ROLES:
		var id := _id(location_id, role)
		if persons.has(id):
			out.append(persons[id])
	return out

func person(id: String) -> Dictionary:
	return persons.get(id, {})

## Varışta: yaşayanlar kervanı görür (o gün bir kez).
func greet_city(location_id: String, day: int) -> void:
	for p in city_people(location_id):
		if bool(p["alive"]) and int(p.get("seen_day", -1)) != day:
			p["met"] = int(p["met"]) + 1
			p["seen_day"] = day

static func age_years(p: Dictionary, day: int) -> int:
	return int(floor(float(day - int(p.get("born", day))) / float(Scarcity.YEAR_DAYS)))

## Gönlü: iyilik eksi kin. Kapılar ve sözler bunu okur.
static func regard(p: Dictionary) -> int:
	return int(p.get("favor", 0)) - int(p.get("grudge", 0))

# --- günün geçişi: yaş, ölüm, süresi dolan iş ---

## Bir gün geçer. `famine` 0..1 (o şehrin kıtlığı, çağıran verir). Dönen:
## [{"kind": "died"|"chain_failed", "id"}].
func daily(day: int, famine_of: Callable) -> Array[Dictionary]:
	var notes: Array[Dictionary] = []
	for id in persons:
		var p: Dictionary = persons[id]
		if not bool(p["alive"]):
			continue
		var chain: Dictionary = p.get("chain", {})
		if not chain.is_empty() and day > int(chain.get("due", day)):
			p["chain"] = {}
			p["grudge"] = int(p["grudge"]) + 1
			notes.append({"kind": "chain_failed", "id": id})
		var age := age_years(p, day)
		if age < 60 or String(p["role"]) == ROLE_CHIEF:
			continue
		var chance := OLD_AGE_DEATH_PER_DAY * float(age - 59)
		var famine := float(famine_of.call(String(p.get("home", "")))) if famine_of.is_valid() else 0.0
		chance *= 1.0 + famine * (FAMINE_DEATH_MULTIPLIER - 1.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("death|%s|%d" % [id, day])
		if rng.randf() < chance:
			p["alive"] = false
			p["died_day"] = day
			notes.append({"kind": "died", "id": id})
	return notes

# --- kişisel iş zinciri ---

## Kişinin şimdi istediği şey (yoksa yeni bir iş açar). Şehrin istediği mallardan biri.
func offer_chain(id: String, day: int) -> Dictionary:
	var p: Dictionary = persons.get(id, {})
	if p.is_empty() or not bool(p["alive"]) or int(p.get("chain_step", 0)) >= CHAIN_STEPS:
		return {}
	if not (p.get("chain", {}) as Dictionary).is_empty():
		return p["chain"]
	var location := WorldMapData.get_location_by_id(String(p["home"]))
	var wants: Array[String] = location.demands if location != null and not location.demands.is_empty() else (["test_furs"] as Array[String])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("chain|%s|%d" % [id, int(p.get("chain_step", 0))])
	var step := int(p.get("chain_step", 0))
	p["chain"] = {
		"item": wants[rng.randi_range(0, wants.size() - 1)],
		"qty": CHAIN_BASE_QTY + CHAIN_QTY_PER_STEP * step,
		"due": day + CHAIN_DAYS,
		"gold": CHAIN_GOLD_PER_STEP * (step + 1),
	}
	return p["chain"]

## İş teslim edilir: çağıran malı düşer, ödülü verir; burada kişinin hafızası.
func complete_chain(id: String) -> void:
	var p: Dictionary = persons.get(id, {})
	if p.is_empty():
		return
	p["chain"] = {}
	p["chain_step"] = int(p.get("chain_step", 0)) + 1
	p["favor"] = int(p["favor"]) + 1

# --- yolun hafızası: reis ---

## Bir bölgenin yaşayan reisi (yoksa "").
func chief_in(region: String) -> String:
	for id in persons:
		var p: Dictionary = persons[id]
		if String(p["role"]) == ROLE_CHIEF and bool(p["alive"]) and String(p.get("home", "")) == region:
			return id
	return ""

## Yenilen çetenin reisi kaçtı: adı, izi ve kiniyle kayda geçer ya da büyür.
func chief_escaped(region: String, day: int, culture_ids: Array[String]) -> String:
	var id := chief_in(region)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("chief|%s|%d" % [region, day])
	if id.is_empty():
		var p := _make(rng, culture_ids, [])
		id = "chief_%s_%d" % [region, day]
		p["id"] = id
		p["role"] = ROLE_CHIEF
		p["home"] = region
		p["born"] = day - rng.randi_range(24, 45) * Scarcity.YEAR_DAYS
		persons[id] = p
	var chief: Dictionary = persons[id]
	chief["grudge"] = int(chief["grudge"]) + 1
	chief["rank"] = int(chief.get("rank", 0)) + 1
	chief["scar"] = SCARS[rng.randi_range(0, SCARS.size() - 1)]
	chief["seen_day"] = day
	return id

## Reise boyun eğildi (fidye, haraç): kini yok ama küçümser; çetesi büyür.
func chief_paid(id: String) -> void:
	if persons.has(id):
		persons[id]["rank"] = int(persons[id].get("rank", 0)) + 1

func chief_killed(id: String, day: int) -> void:
	if persons.has(id):
		persons[id]["alive"] = false
		persons[id]["died_day"] = day

## Olay metninde {nemesis} ve {scar}: o an kartta olan reis.
func fill_names(text: String) -> String:
	if not text.contains("{"):
		return text
	if not active_place_name.is_empty():
		text = text.replace("{place}", active_place_name).replace("{off}", str(active_place_off * 2))
	if active_chief.is_empty() or not persons.has(active_chief):
		return text
	var chief: Dictionary = persons[active_chief]
	return text.replace("{nemesis}", String(chief["name"])).replace("{scar}", TranslationServer.translate(String(chief.get("scar", SCARS[0]))))

# --- kayıt ---

func to_dict() -> Dictionary:
	return {"persons": persons.duplicate(true), "active_chief": active_chief}

func from_dict(data: Dictionary) -> void:
	persons = (data.get("persons", {}) as Dictionary).duplicate(true)
	active_chief = String(data.get("active_chief", ""))
	# JSON sayıları ondalık döner; tam sayı alanlar burada düzelir.
	for id in persons:
		var p: Dictionary = persons[id]
		for key in ["born", "met", "favor", "grudge", "rank", "seen_day", "chain_step", "died_day"]:
			if p.has(key):
				p[key] = int(p[key])
		var chain: Dictionary = p.get("chain", {})
		for key in ["qty", "due", "gold"]:
			if chain.has(key):
				chain[key] = int(chain[key])

# --- yardımcılar ---

static func _id(location_id: String, role: String) -> String:
	return "%s_%s" % [location_id, role]

func _make(rng: RandomNumberGenerator, culture_ids: Array[String], used: Array[String]) -> Dictionary:
	var cultures := culture_ids if not culture_ids.is_empty() else ([CultureCatalog.VALLEY] as Array[String])
	var culture := CultureCatalog.get_culture(cultures[rng.randi_range(0, cultures.size() - 1)])
	if culture == null:
		culture = CultureCatalog.get_cultures()[0]
	var name := culture.name_pool[rng.randi_range(0, culture.name_pool.size() - 1)]
	for _try in 6:
		if not used.has(name):
			break
		name = culture.name_pool[rng.randi_range(0, culture.name_pool.size() - 1)]
	used.append(name)
	return {"name": name, "culture": culture.culture_id, "alive": true, "met": 0, "favor": 0, "grudge": 0,
		"rank": 0, "chain_step": 0, "chain": {}}
