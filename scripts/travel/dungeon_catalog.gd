class_name DungeonCatalog
extends RefCounted

## Galeri ağızları (görev Y-A07; SIDERIA §11.7).
##
## Oda haritası yok: bir ağız art arda gelen aşamalardır ve her aşama bir kart
## ya da bir savaştır (oyunun dili kart ve savaş; yeni bir keşif sistemi
## icat edilmez). Her aşamadan sonra kapı kartı: daha derine mi, çıkış mı.
## Derinleştikçe ganimet de tehlike de artar; son aşama her ağzın kendi
## kartıdır ve sonrası göçükle kapalıdır (derinin ne olduğu söylenmez).
##
## Kadro iner, kervan ağızda bekler: her iki aşama bir gün sürer ve kervan o
## gün erzak yer. Işık (meşale ya da fener) yoksa her aşama daha çok yorar.
## Aşamanın kartı ağzın kimliğinden, girişin sırasından ve derinlikten türer:
## kaydı yeniden yüklemek zarı değiştirmez.

const ESKI_AGIZ: String = "eski_agiz"
const KEMRUG_YARIGI: String = "kemrug_yarigi"
const KOR_KAZMALAR: String = "kor_kazmalar"

## Ağızlar Vorgat'ın ocaklarının kenarında: Vorgat'a giden ya da oradan çıkan
## yolda bulunur.
const NEAR: Array[String] = ["vorgat"]

const DUNGEONS: Dictionary = {
	ESKI_AGIZ: {"name": "DUNGEON_ESKI_AGIZ", "depth": 4, "last": "evt_dng_s_sealed_tunnel"},
	KEMRUG_YARIGI: {"name": "DUNGEON_KEMRUG_YARIGI", "depth": 5, "last": "evt_dng_s_warm_spring"},
	KOR_KAZMALAR: {"name": "DUNGEON_KOR_KAZMALAR", "depth": 5, "last": "evt_dng_s_painted_room"},
}
const ORDER: Array[String] = [ESKI_AGIZ, KEMRUG_YARIGI, KOR_KAZMALAR]

## Derinlik katmanlarının aşama havuzları.
const SHALLOW: Array[String] = [
	"evt_dng_s_collapsed_shaft", "evt_dng_s_bad_air", "evt_dng_s_blind_badgers",
	"evt_dng_s_miners_cache", "evt_dng_s_flat_wall",
]
const MIDDLE: Array[String] = [
	"evt_dng_s_echo_hall", "evt_dng_s_stone_wolves", "evt_dng_s_warm_stones",
	"evt_dng_s_old_bones", "evt_dng_s_resting_niche", "evt_dng_s_looters",
]
const DEEP: Array[String] = ["evt_dng_s_cave_bear", "evt_dng_s_looters", "evt_dng_s_old_bones"]

## Kişi başına taşınabilen ganimet (kervan dışarıda; yalnız sırtta taşınır).
const BAG_PER_PERSON: int = 2

static func name_key(dungeon_id: String) -> String:
	return String((DUNGEONS.get(dungeon_id, {}) as Dictionary).get("name", ""))

static func max_depth(dungeon_id: String) -> int:
	return int((DUNGEONS.get(dungeon_id, {}) as Dictionary).get("depth", 0))

static func is_near(origin_id: String, destination_id: String) -> bool:
	return NEAR.has(origin_id) or NEAR.has(destination_id)

static func is_stage(event_id: String) -> bool:
	return event_id.begins_with("evt_dng_s_")

## Bu derinliğin kartı. Son derinlik ağzın kendi kartı; öbürleri katmanın
## havuzundan, bu girişte henüz çıkmamış olanlardan, tohumla.
static func stage_for(dungeon_id: String, depth: int, visit: int, used: Array) -> String:
	if depth >= max_depth(dungeon_id):
		return String(DUNGEONS[dungeon_id]["last"])
	var pool: Array[String] = SHALLOW if depth <= 2 else (MIDDLE if depth <= 4 else DEEP)
	var free: Array[String] = []
	for id in pool:
		if not used.has(id):
			free.append(id)
	if free.is_empty():
		free = pool
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d" % [dungeon_id, visit, depth])
	return free[rng.randi() % free.size()]

## Kapı kartı: her aşamadan sonra. Derine inmenin bedeli kartın üstünde yazar.
static func gate_event(depth: int, deepest: bool, has_light: bool) -> GameEvent:
	var event := GameEvent.new()
	event.event_id = "evt_dng_gate"
	event.title_key = "EVT_DNG_GATE_TITLE"
	event.text_key = "EVT_DNG_GATE_END_TEXT" if deepest else ("EVT_DNG_GATE_TEXT" if has_light else "EVT_DNG_GATE_DARK_TEXT")
	event.triggered_only = true
	var choices: Array[EventChoice] = []
	if not deepest:
		var down: Array[EventEffect] = [EventEffect.make(EventEffect.Type.DUNGEON_DEEPER)]
		down.append(EventEffect.make(EventEffect.Type.STRESS, 3 if has_light else 7))
		if depth % 2 == 1:
			down.append(EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1))
		choices.append(EventChoice.make("EVT_DNG_GATE_OPT_DEEPER" if has_light else "EVT_DNG_GATE_OPT_DEEPER_DARK", down))
	var share: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.GOLD, -20),
		EventEffect.make(EventEffect.Type.IZ_BIRAK, 30, "minnet|bolge|uzun|kapi"),
		EventEffect.make(EventEffect.Type.DUNGEON_EXIT),
	]
	var share_choice := EventChoice.make("EVT_DNG_GATE_OPT_EXIT_SHARE", share)
	share_choice.requirements = [EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 20)]
	share_choice.unavailable_text_key = "EVT_DNG_GATE_OPT_EXIT_SHARE_LOCKED"
	choices.append(share_choice)
	var keep: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.IZ_BIRAK, -40, "kin|bolge|uzun|ret"),
		EventEffect.make(EventEffect.Type.DUNGEON_EXIT),
	]
	choices.append(EventChoice.make("EVT_DNG_GATE_OPT_EXIT", keep))
	event.choices = choices
	return event
