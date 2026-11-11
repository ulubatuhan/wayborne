class_name EventEngine
extends RefCounted

## Yol olaylarının havuzunu yönetir: uygunluk filtresi, ağırlıklı çekim,
## bir-kez/bekleme takibi ve seçim çözümü. Sahne ağacına bağlı değildir,
## seed verilerek birebir tekrarlanabilir.

const DEFAULT_DAILY_EVENT_CHANCE: float = 0.35
const MAX_DAILY_EVENT_CHANCE: float = 0.95

var daily_event_chance: float = DEFAULT_DAILY_EVENT_CHANCE

var _events: Array[GameEvent] = []
var _rng := RandomNumberGenerator.new()
var _fired_once: Dictionary = {}
var _available_after_day: Dictionary = {}
var _unlocked: Dictionary = {}
## Yol yönetmeni (görev Y-B02): verilirse günlük ihtimali ve ağırlıkları eğer;
## null ise motor eskisi gibi çalışır (testler, eski harness'ler).
var director: RoadDirector = null

func _init(events: Array[GameEvent], seed_value: int = 0) -> void:
	_events = events
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

## Dövüş borcunun son günü (kullanıcı kararı 2026-11-07): sefer bitmek
## üzereyken hâlâ dövüşülmediyse o günün kartı **kesin** çıkar ve dövüşe
## açılan kartlar arasından çekilir. Rampa (RoadDirector.combat_debt_
## multiplier) çoğu seferde işi daha erken bitirdiği için bu kapı
## nadiren açılır; açıldığında garantiyi tutan odur.
static func combat_forced(context: Dictionary) -> bool:
	return float(context.get("combat_due", 0.0)) > 0.0 \
		and float(context.get("days_left", 99.0)) <= 1.0

## Tehlike arttıkça günlük olay ihtimali yükselir.
func get_daily_chance(context: Dictionary) -> float:
	if combat_forced(context):
		return 1.0
	var danger: float = float(context.get("danger", 0.0))
	var chance := daily_event_chance * (0.5 + danger)
	if director != null:
		chance *= director.chance_multiplier(context)
	return clampf(chance, 0.0, MAX_DAILY_EVENT_CHANCE)

## Bir yolculuk günü ilerletir. Olay çıkmazsa null döner.
func roll_for_day(current_day: int, context: Dictionary) -> GameEvent:
	if director != null:
		director.begin_day(current_day)
	if _rng.randf() > get_daily_chance(context):
		if director != null:
			director.note_quiet()
		return null
	var event := draw_event(current_day, context)
	if event == null and director != null:
		director.note_quiet()
	return event

func _weight(event: GameEvent, context: Dictionary) -> float:
	var weight := event.get_weight(context)
	if director != null:
		weight *= director.weight_multiplier(event, context)
	return weight

## Havuzdan koşulu sağlayan bir olayı ağırlıklı olarak çeker.
func draw_event(current_day: int, context: Dictionary) -> GameEvent:
	var eligible := get_eligible_events(current_day, context)
	# Dövüş borcunun son günü: havuz dövüşe açılan kartlara iniyor. Hiç
	# yoksa (kuramsal: o yolda uygun tek bir dövüş kartı bile yok) eski
	# havuz kalıyor - garanti bir kartı yoktan var edemez, sessiz bir gün
	# yanlış karttan iyidir.
	if combat_forced(context):
		var fighters: Array[GameEvent] = []
		for event in eligible:
			if RoadDirector.can_fight(event):
				fighters.append(event)
		if not fighters.is_empty():
			eligible = fighters
	if eligible.is_empty():
		return null

	var total_weight := 0.0
	for event in eligible:
		total_weight += _weight(event, context)

	if total_weight <= 0.0:
		return null

	var roll := _rng.randf() * total_weight
	var cursor := 0.0
	for event in eligible:
		cursor += _weight(event, context)
		if roll <= cursor:
			return event

	return eligible[eligible.size() - 1]

func get_eligible_events(current_day: int, context: Dictionary) -> Array[GameEvent]:
	var eligible: Array[GameEvent] = []
	for event in _events:
		if _is_eligible(event, current_day, context):
			eligible.append(event)
	return eligible

func _is_eligible(event: GameEvent, current_day: int, context: Dictionary) -> bool:
	if event.triggered_only and not _unlocked.has(event.event_id):
		return false
	if event.fire_only_once and _fired_once.has(event.event_id):
		return false
	if _available_after_day.has(event.event_id) and current_day < int(_available_after_day[event.event_id]):
		return false
	return event.is_eligible(context)

## Olay gösterildikten sonra çağrılır: bir-kez ve bekleme kayıtlarını işler.
func mark_fired(event: GameEvent, current_day: int) -> void:
	if director != null:
		director.note_card(event, current_day)
	if event.fire_only_once:
		_fired_once[event.event_id] = true
	if event.cooldown_days > 0:
		_available_after_day[event.event_id] = current_day + event.cooldown_days
	_unlocked.erase(event.event_id)

func unlock_event(event_id: String) -> void:
	_unlocked[event_id] = true

## Sefer ortası kaydı için motorun kendi durumu: bir-kez/bekleme/açılmış
## zincir kayıtları ve zarın *o anki* konumu. RNG'nin tohumu değil durumu
## yazılıyor - yeniden yüklenen bir sefer kaldığı yerden aynı zarları atsın,
## yükleyip yeniden zar attırmak bir sömürü kapısı olmasın.
func to_dict() -> Dictionary:
	return {
		"fired_once": _fired_once.keys(),
		"available_after_day": _available_after_day.duplicate(),
		"unlocked": _unlocked.keys(),
		"rng_seed": str(_rng.seed),
		"rng_state": str(_rng.state),
		"director": director.to_dict() if director != null else {},
	}

func load_from_dict(data: Dictionary) -> void:
	_fired_once = {}
	for event_id in (data.get("fired_once", []) as Array):
		_fired_once[String(event_id)] = true
	_available_after_day = {}
	var after: Dictionary = data.get("available_after_day", {})
	for event_id in after:
		_available_after_day[String(event_id)] = int(after[event_id])
	_unlocked = {}
	for event_id in (data.get("unlocked", []) as Array):
		_unlocked[String(event_id)] = true
	# 64 bitlik değerler JSON'da float'a düşüp hassasiyet kaybeder - metin
	# olarak yazılıp okunuyor.
	if data.has("rng_seed"):
		_rng.seed = String(data["rng_seed"]).to_int()
	if data.has("rng_state"):
		_rng.state = String(data["rng_state"]).to_int()
	if director != null:
		director.load_from_dict(data.get("director", {}) as Dictionary)

## Faz 17: seçeneğin arkasında bir SkillCheck varsa zar atar ve context'in
## bir KOPYASINA "check_tier" (0/1/2) yazar - orijinal context'e dokunmuyor,
## çünkü aynı context aynı çağrıda başka seçeneklerin önizlemesinde de
## kullanılıyor olabilir. Check yoksa context'i olduğu gibi döner, yani
## çağıran taraf (road_journey.gd) her zaman bu fonksiyondan geçebilir.
##
## Zar bu motorun kendi `_rng`'siyle atılıyor - EventEngine seed'lenerek
## kurulduğu için (bkz. Event Engine Rules) bir sefer tamamen tekrarlanabilir
## kalıyor, check de dahil.
## Liderin yüzünün zara kattığı (§D-R4). Kabuk bağlamış lider sert bir
## seçeneği daha inandırıcı savunur, çatlamış lider merhametli olanı -
## çünkü ikisini de yaşamıştır. Hiçbir seçenek kapanmaz, yalnız zar kayar.
##
## Önizleme ve zar **aynı** fonksiyonu okuyor: düğmede yazan yüzde ile
## atılan zar ayrı hesaplanırsa oyuncuya yalan söylenmiş olur (aynı kural
## bedel taşıyıcısının adında da yazılı).
const LEADER_SOUL_GATE: float = 4.0
const LEADER_SOUL_BONUS: float = 1.0

static func leader_tone_bonus(choice: EventChoice, context: Dictionary) -> float:
	var tone := choice_tone(choice)
	if tone == TONE_HARSH and float(context.get("lider_kabuk", 0.0)) >= LEADER_SOUL_GATE:
		return LEADER_SOUL_BONUS
	if tone == TONE_MERCY and float(context.get("lider_catlak", 0.0)) >= LEADER_SOUL_GATE:
		return LEADER_SOUL_BONUS
	return 0.0

## Sertlik kapısının en üst bandında kontrol zorlaşır: kandıracak kadar tok
## adam kalmadı (§D-A3). Bir puan, tavanı değil zarı kaydırıyor - tavanı
## indirmek bazı seçenekleri fiilen kapatırdı.
const HARDSHIP_HARDEST_BAND: int = 3
const HARDSHIP_CHECK_PENALTY: float = -1.0

static func hardship_check_penalty(context: Dictionary) -> float:
	var scarcity := float(context.get("scarcity_here", 0.0))
	return HARDSHIP_CHECK_PENALTY if EventResolver.hardship_band(scarcity) >= HARDSHIP_HARDEST_BAND else 0.0

const TONE_HARSH: String = "sert"
const TONE_MERCY: String = "merhamet"

## Seçeneğin tonu, kendi etkilerinden okunur: bedeli başkasına yükleyen ya
## da kin bırakan sert, minnet bırakan merhametlidir. Katalogda ayrı bir
## etiket tutulmuyor - etiket unutulur, etki unutulmaz.
static func choice_tone(choice: EventChoice) -> String:
	for effect in choice.effects:
		if effect.type == EventEffect.Type.BEDEL:
			return TONE_HARSH
		if effect.type == EventEffect.Type.IZ_BIRAK:
			var tur := effect.text_value.split("|")[0].strip_edges()
			if tur == Trace.TYPE_GRUDGE:
				return TONE_HARSH
			if tur == Trace.TYPE_GRATITUDE:
				return TONE_MERCY
	return ""

func resolve_check(choice: EventChoice, context: Dictionary) -> Dictionary:
	var checked := context.duplicate()
	if choice.check == null:
		return checked
	var effective_stat: float = float(context.get(choice.check.get_context_key(), 0.0)) \
		+ leader_tone_bonus(choice, context) \
		+ hardship_check_penalty(context)
	checked["check_tier"] = choice.check.roll(effective_stat, _rng)
	return checked

## Seçeneğin sonuçlarından koşulu sağlayan birini ağırlıklı seçer.
## Sonuç listesi boşsa null döner: seçeneğin yalnızca garantili etkileri vardır.
func resolve_outcome(choice: EventChoice, context: Dictionary) -> EventOutcome:
	var available: Array[EventOutcome] = []
	var total_weight := 0.0
	for outcome in choice.outcomes:
		if outcome.is_available(context):
			available.append(outcome)
			total_weight += outcome.weight

	if available.is_empty() or total_weight <= 0.0:
		return null

	var roll := _rng.randf() * total_weight
	var cursor := 0.0
	for outcome in available:
		cursor += outcome.weight
		if roll <= cursor:
			return outcome

	return available[available.size() - 1]
