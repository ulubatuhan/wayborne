class_name DungeonCatalog
extends RefCounted

## Galeri ağızları (görev Y-A07; SIDERIA §11.7).
##
## Bir ağız seviye seviye inilen bir haritadır (`DungeonMap`): her seviye
## koridorlarla bağlı odalar, her oda bir kart ya da bir savaş. Son seviyenin
## son odası ağzın kendi kartıdır ve sonrası göçükle kapalıdır (derinin ne
## olduğu söylenmez). Derinleştikçe ganimet de tehlike de artar.
##
## Kadro iner, kervan ağızda bekler: iki koridor bir gün sürer ve kervan o gün
## erzak yer. Işık (meşale ya da fener) yoksa her adım daha çok yorar ve
## koridorda pusu olasılığı artar. Çıkış her odadan; derinden dönüş gün alır.
## Harita ağzın kimliğinden ve girişin sırasından türer, kayıtta durur.

const ESKI_AGIZ: String = "eski_agiz"
const KEMRUG_YARIGI: String = "kemrug_yarigi"
const KOR_KAZMALAR: String = "kor_kazmalar"

## Ağızlar Vorgat'ın ocaklarının kenarında: Vorgat'a giden ya da oradan çıkan
## yolda bulunur.
const NEAR: Array[String] = ["vorgat"]

## `zones`: seviye başına bölge (arka plan, kart resmi). Bir ağız madencinin ya
## da doğanın açtığı girişle başlar ("agiz"), kaba kayanın kadim işçiliğe
## döndüğü yerden geçer ("gecis") ve kadim şehrin kendi galerisinde biter
## ("galeri"); SIDERIA §11.7'deki tarife göre:
## Eski Ağız kuyu -> madenci tüneli -> düz kesilmiş tünel; Kemrug Yarığı ıslak
## yarık -> oyulmuş su kanalı -> ılık kaynak salonu; Kör Kazmalar merdiven ->
## nişli koridor -> resimli duvarlar.
const DUNGEONS: Dictionary = {
	ESKI_AGIZ: {"name": "DUNGEON_ESKI_AGIZ", "depth": 4, "last": "evt_dng_s_sealed_tunnel",
		"zones": ["agiz", "gecis", "gecis", "galeri"]},
	KEMRUG_YARIGI: {"name": "DUNGEON_KEMRUG_YARIGI", "depth": 5, "last": "evt_dng_s_warm_spring",
		"zones": ["agiz", "agiz", "gecis", "galeri", "galeri"]},
	KOR_KAZMALAR: {"name": "DUNGEON_KOR_KAZMALAR", "depth": 5, "last": "evt_dng_s_painted_room",
		"zones": ["agiz", "gecis", "galeri", "galeri", "galeri"]},
}
const ORDER: Array[String] = [ESKI_AGIZ, KEMRUG_YARIGI, KOR_KAZMALAR]

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

## Çıkış kartı: haritadan "çık" denince. Derinden dönüş gün alır; töreye göre
## pay bırakmak ya da bırakmamak, ya da vazgeçip haritaya dönmek.
static func gate_event(level: int, has_light: bool, room_id: int) -> GameEvent:
	var event := GameEvent.new()
	event.event_id = "evt_dng_gate"
	event.title_key = "EVT_DNG_GATE_TITLE"
	event.text_key = "EVT_DNG_GATE_LEAVE_TEXT" if has_light else "EVT_DNG_GATE_LEAVE_DARK_TEXT"
	event.triggered_only = true
	var climb := DungeonMap.climb_days(level)
	var choices: Array[EventChoice] = []
	var share: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.GOLD, -20),
		EventEffect.make(EventEffect.Type.IZ_BIRAK, 30, "minnet|bolge|uzun|kapi"),
		EventEffect.make(EventEffect.Type.DUNGEON_EXIT),
	]
	var keep: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.IZ_BIRAK, -40, "kin|bolge|uzun|ret"),
		EventEffect.make(EventEffect.Type.DUNGEON_EXIT),
	]
	if climb > 0:
		share.append(EventEffect.make(EventEffect.Type.TRAVEL_DAYS, climb))
		keep.append(EventEffect.make(EventEffect.Type.TRAVEL_DAYS, climb))
	var share_choice := EventChoice.make("EVT_DNG_GATE_OPT_EXIT_SHARE", share)
	share_choice.requirements = [EventCondition.make("gold", EventCondition.Op.GREATER_EQUAL, 20)]
	share_choice.unavailable_text_key = "EVT_DNG_GATE_OPT_EXIT_SHARE_LOCKED"
	choices.append(share_choice)
	choices.append(EventChoice.make("EVT_DNG_GATE_OPT_EXIT", keep))
	choices.append(EventChoice.make("EVT_DNG_GATE_OPT_BACK",
		[EventEffect.make(EventEffect.Type.DUNGEON_MOVE, room_id)] as Array[EventEffect]))
	event.choices = choices
	return event
