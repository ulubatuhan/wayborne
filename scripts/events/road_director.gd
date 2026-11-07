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

## Sessiz güne izin (P17, kullanıcı kararı 2026-11-05). Sessizlik rampası
## kıtlıkta gevşer: *"bugün de hiçbir şey olmadı ve bir çuval azaldı"*
## geçerli bir gündür.
##
## Neden: rampa her sessiz günden sonra ihtimali büyüttüğü için üçüncü gün
## neredeyse kesin bir şey oluyordu. Yani oyun hiçbir zaman sessiz kalamıyordu
## - **her dakika bir şey sunan oyun kasvetli değil meşguldür.** Tekdüzelik
## bir kusur değil, bir kaynak: kıtlıkta günlerin birbirine benzemesi
## anlatının kendisi.
##
## Rampa sıfırlanmıyor, *kısılıyor*: kıtlık en ağır günde bile yol büsbütün
## susmaz, yalnız üç gün üst üste susabilir hâle gelir.
const SCARCITY_QUIET_FROM: float = 0.45
const SCARCITY_QUIET_RAMP: float = 0.16
const SCARCITY_MAX_QUIET_BOOST: float = 1.3

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

## `context` kıtlığı taşıyorsa (`scarcity_here`) sessizlik rampası kısılır
## (P17). Varsayılanı boş: kıtlığı bilmeyen bir çağıran eski davranışı alır.
func chance_multiplier(context: Dictionary = {}) -> float:
	var scarcity := clampf(float(context.get("scarcity_here", 0.0)), 0.0, 1.0)
	var quiet := inverse_lerp(SCARCITY_QUIET_FROM, 1.0, scarcity)
	quiet = clampf(quiet, 0.0, 1.0)
	var ramp := lerpf(QUIET_RAMP, SCARCITY_QUIET_RAMP, quiet)
	var ceiling := lerpf(MAX_QUIET_BOOST, SCARCITY_MAX_QUIET_BOOST, quiet)
	var m := minf(ceiling, 1.0 + ramp * float(maxi(0, quiet_streak - 1)))
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
	# Domino (Y-C23): açık halkanın sonraki kartı daha sık gelir.
	for link in (context.get("domino_open", []) as Array):
		if (DOMINO_NEXT.get(String(link), []) as Array).has(event.event_id):
			m *= DOMINO_WEIGHT
	return m * novelty_multiplier(event.event_id, context)

## Yenilik çarpanı (U1, uzman ölçümü 2026-11-07).
##
## Ölçüm: kataloğun 97 kartından yalnızca %56'sı bir kariyerde hiç görünüyor,
## buna karşılık çekilişlerin %73'ü tekrar; içerik ömrü 4,2 sefer. Sebebi
## içerik eksiği değil, ağırlığın kartın geçmişini hiç bilmemesiydi - aynı
## yüksek ağırlıklı kart her uygun günde yeniden favori oluyordu.
##
## Üç kademe: hiç görülmemiş kart kayırılır, yakında görülen bastırılır,
## eskiden görülmüş olan hafifçe sönümlenir. Hiçbiri sıfır değil: kart
## havuzdan **çıkmaz**, yalnız sıraya girer. Bir kartı tümden kilitlemek
## koşulu sağlayan tek kart kaldığında yolu susturur; sönüm susturmaz.
##
## Domino bunun üstünde kalır (DOMINO_WEIGHT 2,5 > RECENT_CARD_WEIGHT'in
## bastırması): bir zincirin ikinci halkası yeni görülmüş olsa bile gelir,
## çünkü zincirin kopması tekrardan daha kötüdür.
const UNSEEN_CARD_WEIGHT: float = 2.4
const RECENT_CARD_WEIGHT: float = 0.35
const SEEN_CARD_WEIGHT: float = 0.8

func novelty_multiplier(event_id: String, context: Dictionary) -> float:
	if event_id.is_empty():
		return 1.0
	var recent := context.get("recent_cards", []) as Array
	if recent.has(event_id):
		return RECENT_CARD_WEIGHT
	var seen := context.get("seen_cards", {}) as Dictionary
	if seen.is_empty():
		# Bağlam hafızayı taşımıyor (eski çağıran, test): eski davranış.
		return 1.0
	return SEEN_CARD_WEIGHT if seen.has(event_id) else UNSEEN_CARD_WEIGHT

## Zincirin halkası -> sonraki halkayı getiren kartlar.
const DOMINO_WEIGHT: float = 2.5
const DOMINO_NEXT: Dictionary = {
	"axle": ["evt_elder_burden", "evt_hidden_guide"],
	"long_road": ["evt_starving_roadside", "evt_hunting_trip"],
	"hunger": ["evt_fever_quarantine", "evt_starving_roadside"],
	"fever": ["evt_bandit_ambush", "evt_wolves_follow", "evt_fever_quarantine"],
}

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
