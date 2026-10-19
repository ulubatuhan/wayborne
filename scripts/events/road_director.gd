class_name RoadDirector
extends RefCounted

## Yol yönetmeni (görev Y-B02): olay çekilişini kervanın durumuna göre
## eğer - gerilim, zirve, rahatlama. Yeni olay icat etmez; EventEngine'in
## günlük ihtimaline ve ağırlıklarına bir çarpan verir.
## - Üst üste sessiz günler gerilimi biriktirir: ihtimal artar (üç sessiz gün
##   seyrekleşir).
## - Ağır bir karttan (savaş, kayıp, yoldaş bırakma) sonraki gün rahatlama:
##   ağır kartlar seyrek, ihtimal biraz düşük (art arda iki ağır kart seyrek).
## - Kervan zorda (yüksek stres, açlık, vadesi geçmiş borç): ağır kart
##   seyrekleşir, hafif kart sıklaşır - zaten düşeni ezmez.
## Durum seferle birlikte kaydedilir (EventEngine.to_dict).

const QUIET_RAMP: float = 0.5
const MAX_QUIET_BOOST: float = 2.0
const RELIEF_HEAVY_WEIGHT: float = 0.35
const RELIEF_CHANCE: float = 0.8
const STRAIN_HEAVY_WEIGHT: float = 0.7
const STRAIN_LIGHT_WEIGHT: float = 1.2
const STRAIN_STRESS: float = 60.0

## Olay sertliği (Y-D01): ağır kartların ağırlık çarpanı (kolay < 1 < zor).
var heavy_scale: float = 1.0
var quiet_streak: int = 0
var last_heavy_day: int = -99
var _today: int = 0

static func is_heavy(event: GameEvent) -> bool:
	for choice in event.choices:
		if _heavy_effects(choice.effects):
			return true
		for outcome in choice.outcomes:
			if _heavy_effects(outcome.effects):
				return true
	return false

static func _heavy_effects(effects: Array[EventEffect]) -> bool:
	for effect in effects:
		var type := effect.type
		if type == EventEffect.Type.TRIGGER_COMBAT or type == EventEffect.Type.WAGON_LOSE or type == EventEffect.Type.LEAVE_BEHIND:
			return true
		if type == EventEffect.Type.PARTY_HP and effect.amount <= -10:
			return true
	return false

static func is_strained(context: Dictionary) -> bool:
	return float(context.get("stress", 0.0)) >= STRAIN_STRESS \
		or float(context.get("debt_overdue", 0.0)) > 0.0 \
		or float(context.get("hungry", 0.0)) > 0.0

func begin_day(day: int) -> void:
	_today = day

func chance_multiplier() -> float:
	var m := minf(MAX_QUIET_BOOST, 1.0 + QUIET_RAMP * float(maxi(0, quiet_streak - 1)))
	if _today - last_heavy_day == 1:
		m *= RELIEF_CHANCE
	return m

func weight_multiplier(event: GameEvent, context: Dictionary) -> float:
	var heavy := is_heavy(event)
	var m := heavy_scale if heavy else 1.0
	if heavy and _today - last_heavy_day == 1:
		m *= RELIEF_HEAVY_WEIGHT
	if is_strained(context):
		m *= STRAIN_HEAVY_WEIGHT if heavy else STRAIN_LIGHT_WEIGHT
	return m

func note_card(event: GameEvent, day: int) -> void:
	quiet_streak = 0
	if is_heavy(event):
		last_heavy_day = day

func note_quiet() -> void:
	quiet_streak += 1

func to_dict() -> Dictionary:
	return {"quiet_streak": quiet_streak, "last_heavy_day": last_heavy_day}

func load_from_dict(data: Dictionary) -> void:
	quiet_streak = maxi(0, int(data.get("quiet_streak", 0)))
	last_heavy_day = int(data.get("last_heavy_day", -99))
