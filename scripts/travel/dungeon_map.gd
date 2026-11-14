class_name DungeonMap
extends RefCounted

## Galeri ağzının haritası, seviye seviye (Y-A07 derinleşme; kullanıcı
## 2026-11-14: "zindanlar için bir map oluştur seviye seviye").
##
## Bir seviye, sütunlara dizilmiş ve koridorlarla bağlı odalardır: girişten
## (ilk seviyede ağız, sonrakilerde merdivenin dibi) inişe ya da ağzın son
## odasına. Her odanın bir türü ve bir kartı var; kart girilince açılır ve bir
## kez yaşanır. Oyunun dili yine kart ve savaş: harita yalnızca hangi kartın,
## hangi sırayla, hangi bedelle geleceğini oyuncuya seçtirir.
##
## Bedel koridorda ödenir: her koridor ışık yer (yanan meşale `TORCH_STEPS`
## koridor gider), her `STEPS_PER_DAY` koridor bir gün sürer (kervan ağızda
## bekler ve erzak yer), karanlıkta her adım daha çok yorar ve pusu olasılığı
## yükselir. Odaya varınca komşuları görünür olur; görünmeyen oda haritada
## soru işaretidir.
##
## Harita girişin sırasından ve ağzın kimliğinden türer, kayıtta durur:
## yeniden yüklemek ne odaları ne kartları değiştirir.

const ENTRY: String = "giris"
const PASS: String = "gecit"
const FIGHT: String = "savas"
const CACHE: String = "hazine"
const REST: String = "dinlenme"
const RELIC: String = "kalinti"
const STAIR: String = "inis"
const FINAL: String = "son"

## Oda türü -> ad anahtarı (haritada ve ipucunda).
const TYPE_KEYS: Dictionary = {
	ENTRY: "UI_DNG_ROOM_ENTRY",
	PASS: "UI_DNG_ROOM_PASS",
	FIGHT: "UI_DNG_ROOM_FIGHT",
	CACHE: "UI_DNG_ROOM_CACHE",
	REST: "UI_DNG_ROOM_REST",
	RELIC: "UI_DNG_ROOM_RELIC",
	STAIR: "UI_DNG_ROOM_STAIR",
	FINAL: "UI_DNG_ROOM_FINAL",
}

## Tür -> derinlik katmanı -> aşama kartları. Katman: 0 sığ (1-2), 1 orta
## (3-4), 2 derin (5). Kartın kendi metni o derinliğe göre yazıldı.
const POOLS: Dictionary = {
	PASS: [["evt_dng_s_collapsed_shaft", "evt_dng_s_bad_air"], ["evt_dng_s_echo_hall", "evt_dng_s_bad_air"],
		["evt_dng_s_echo_hall", "evt_dng_s_collapsed_shaft"]],
	FIGHT: [["evt_dng_s_blind_badgers"], ["evt_dng_s_stone_wolves", "evt_dng_s_looters"],
		["evt_dng_s_cave_bear", "evt_dng_s_looters", "evt_dng_s_stone_wolves"]],
	CACHE: [["evt_dng_s_miners_cache"], ["evt_dng_s_warm_stones", "evt_dng_s_old_bones"],
		["evt_dng_s_old_bones", "evt_dng_s_warm_stones"]],
	REST: [["evt_dng_s_resting_niche"], ["evt_dng_s_resting_niche"], ["evt_dng_s_resting_niche"]],
	RELIC: [["evt_dng_s_flat_wall"], ["evt_dng_s_flat_wall", "evt_dng_s_old_bones"], ["evt_dng_s_echo_hall"]],
}

## Yanan meşale kaç koridor gider. Fener yanmaz (yağıyla gider; ItemCatalog).
const TORCH_STEPS: int = 3
## Kaç koridor bir gün eder (eski kapı kuralı: iki aşama bir gün).
const STEPS_PER_DAY: int = 2
## Koridorun stresi: ışıkla, ışıksız.
const STEP_STRESS_LIT: int = 1
const STEP_STRESS_DARK: int = 5
## İnişin stresi (eski kapı kartının bedeli).
const DESCEND_STRESS_LIT: int = 3
const DESCEND_STRESS_DARK: int = 7
## Koridorda pusu: kör dişler sesten kaçar ama karanlıkta yolunuz onlara çıkar.
const AMBUSH_LIT: float = 0.06
const AMBUSH_DARK: float = 0.22
const AMBUSH_DANGER: int = 45

## Bir girişin bütün haritası: seviye başına {"rooms", "links"}.
static func generate(dungeon_id: String, visit: int) -> Array:
	var levels: Array = []
	var used: Array = []
	var depth := DungeonCatalog.max_depth(dungeon_id)
	for level in range(1, depth + 1):
		levels.append(_build_level(dungeon_id, visit, level, level == depth, used))
	return levels

static func _tier(level: int) -> int:
	return 0 if level <= 2 else (1 if level <= 4 else 2)

static func _build_level(dungeon_id: String, visit: int, level: int, last: bool, used: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dngmap|%s|%d|%d" % [dungeon_id, visit, level])
	# Sütun sayısı derinlikle artar: derin seviye daha uzun yürünür.
	var middle_cols := 2 + (1 if level >= 3 else 0) + (1 if rng.randf() < 0.35 else 0)
	var columns: Array = []
	var rooms: Array = []
	var next_id := 0
	for col in range(middle_cols + 2):
		var count := 1 if col == 0 or col == middle_cols + 1 else (2 if rng.randf() < 0.62 else 1)
		var ids: Array = []
		for row in count:
			var y := 0.5 if count == 1 else (0.27 if row == 0 else 0.73)
			rooms.append({"id": next_id, "col": col, "x": float(col) / float(middle_cols + 1),
				"y": clampf(y + rng.randf_range(-0.07, 0.07), 0.12, 0.88), "type": "", "card": "",
				"seen": false, "done": false})
			ids.append(next_id)
			next_id += 1
		columns.append(ids)
	var links: Array = _link_columns(columns, rng)
	_assign_types(rooms, columns, level, last, rng)
	for room in rooms:
		room["card"] = _card_for(String(room["type"]), level, dungeon_id, last, used, rng)
		if not String(room["card"]).is_empty():
			used.append(room["card"])
	return {"rooms": rooms, "links": links}

## Her oda bir sonraki sütundan en az birine, her oda bir öncekinden en az
## birinden bağlı; aynı sütunda iki oda varsa ara bir geçit olabilir.
static func _link_columns(columns: Array, rng: RandomNumberGenerator) -> Array:
	var links: Array = []
	for col in range(columns.size() - 1):
		var here: Array = columns[col]
		var there: Array = columns[col + 1]
		for a in here:
			links.append([a, there[rng.randi() % there.size()]])
		for b in there:
			if not _has_link_to(links, b, here):
				links.append([here[rng.randi() % here.size()], b])
		if here.size() == 2 and there.size() == 2 and rng.randf() < 0.45:
			var a2: int = here[rng.randi() % 2]
			var b2: int = there[rng.randi() % 2]
			if not _linked(links, a2, b2):
				links.append([a2, b2])
		if here.size() == 2 and col > 0 and rng.randf() < 0.3:
			links.append([here[0], here[1]])
	return links

static func _has_link_to(links: Array, b: int, sources: Array) -> bool:
	for link in links:
		if int(link[1]) == b and sources.has(int(link[0])):
			return true
	return false

static func _linked(links: Array, a: int, b: int) -> bool:
	for link in links:
		if (int(link[0]) == a and int(link[1]) == b) or (int(link[0]) == b and int(link[1]) == a):
			return true
	return false

## Türler: her seviyede bir hazine, ikinciden sonra bir savaş ve en çok bir
## dinlenme; gerisi geçit ve kalıntı. İlk seviye yüzeye yakın, savaşı nadir.
static func _assign_types(rooms: Array, columns: Array, level: int, last: bool, rng: RandomNumberGenerator) -> void:
	rooms[0]["type"] = ENTRY
	var end_id: int = (columns[columns.size() - 1] as Array)[0]
	rooms[end_id]["type"] = FINAL if last else STAIR
	var slots: Array = []
	for room in rooms:
		if String(room["type"]).is_empty():
			slots.append(int(room["id"]))
	# Öncelik sırası: az odalı bir seviyede önce ganimet, sonra savaş kalır.
	var bag: Array = [CACHE]
	if level >= 2 or rng.randf() < 0.5:
		bag.append(FIGHT)
	if level >= 2:
		bag.append(REST)
	if level >= 4:
		bag.append(FIGHT)
	while bag.size() < slots.size():
		bag.append(PASS if rng.randf() < 0.6 else RELIC)
	bag.resize(slots.size())
	for i in range(bag.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = bag[i]
		bag[i] = bag[j]
		bag[j] = tmp
	for i in slots.size():
		rooms[slots[i]]["type"] = bag[i]

static func _card_for(type: String, level: int, dungeon_id: String, last: bool, used: Array,
		rng: RandomNumberGenerator) -> String:
	if type == FINAL:
		return String(DungeonCatalog.DUNGEONS[dungeon_id]["last"])
	if not POOLS.has(type):
		return ""
	var pool: Array = (POOLS[type] as Array)[_tier(level)]
	var free: Array = []
	for id in pool:
		if not used.has(id):
			free.append(id)
	if free.is_empty():
		free = pool
	return String(free[rng.randi() % free.size()])

# ---------------------------------------------------------------- okuma

static func level_of(run: Dictionary) -> Dictionary:
	var levels: Array = run.get("map", [])
	var index := int(run.get("depth", 1)) - 1
	return levels[index] if index >= 0 and index < levels.size() else {}

static func room(level: Dictionary, room_id: int) -> Dictionary:
	for r in level.get("rooms", []):
		if int(r["id"]) == room_id:
			return r
	return {}

static func neighbours(level: Dictionary, room_id: int) -> Array[int]:
	var out: Array[int] = []
	for link in level.get("links", []):
		if int(link[0]) == room_id:
			out.append(int(link[1]))
		elif int(link[1]) == room_id:
			out.append(int(link[0]))
	return out

## Odaya varılınca o oda ve komşuları görünür olur.
static func reveal_around(level: Dictionary, room_id: int) -> void:
	room(level, room_id)["seen"] = true
	for other in neighbours(level, room_id):
		room(level, other)["seen"] = true

static func stair_id(level: Dictionary) -> int:
	for r in level.get("rooms", []):
		if String(r["type"]) == STAIR:
			return int(r["id"])
	return -1

# ---------------------------------------------------------------- bölge

## Seviyenin bölgesi: "agiz" (giriş), "gecis" (kaba kaya kadim işçiliğe
## döner), "galeri" (kadim şehrin kendi galerisi). Arka plan ve kart resmi bundan.
static func zone(dungeon_id: String, level: int) -> String:
	var zones: Array = (DungeonCatalog.DUNGEONS.get(dungeon_id, {}) as Dictionary).get("zones", [])
	if zones.is_empty():
		return "agiz"
	return String(zones[clampi(level - 1, 0, zones.size() - 1)])

## Savaş ve keşif arka planının adı: "<ağız>_<bölge>".
static func look(dungeon_id: String, level: int) -> String:
	return "%s_%s" % [dungeon_id, zone(dungeon_id, level)]

# ---------------------------------------------------------------- eylemler

## Bir koridor yürümenin seçimi: etkiler olay diliyle (EventEffect), çözümü
## kartlarınkiyle aynı yoldan (EventResolver) geçer.
static func move_choice(session: GameSession, room_id: int) -> EventChoice:
	var run: Dictionary = session.dungeon_run
	var lit := session.dungeon_has_light()
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.DUNGEON_MOVE, room_id)]
	effects.append(EventEffect.make(EventEffect.Type.STRESS, STEP_STRESS_LIT if lit else STEP_STRESS_DARK))
	var steps := int(run.get("steps", 0)) + 1
	if steps % STEPS_PER_DAY == 0:
		effects.append(EventEffect.make(EventEffect.Type.TRAVEL_DAYS, 1))
	if ambush_roll(run, steps) < (AMBUSH_LIT if lit else AMBUSH_DARK):
		effects.append(EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, AMBUSH_DANGER, EnemyCatalog.KIND_DEEP))
	return EventChoice.make("UI_DNG_MOVE", effects)

static func ambush_roll(run: Dictionary, steps: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("dngpusu|%s|%d|%d" % [String(run.get("id", "")), int(run.get("visit", 0)), steps])
	return rng.randf()

static func descend_choice(session: GameSession) -> EventChoice:
	var lit := session.dungeon_has_light()
	var effects: Array[EventEffect] = [
		EventEffect.make(EventEffect.Type.DUNGEON_DEEPER),
		EventEffect.make(EventEffect.Type.STRESS, DESCEND_STRESS_LIT if lit else DESCEND_STRESS_DARK),
	]
	return EventChoice.make("UI_DNG_DESCEND", effects)

static func leave_choice() -> EventChoice:
	return EventChoice.make("UI_DNG_LEAVE", [EventEffect.make(EventEffect.Type.DUNGEON_MOVE, -1)] as Array[EventEffect])

## Çıkış yolu: derinden yukarı tırmanmak da gün alır (seviye başına yarım gün).
static func climb_days(level: int) -> int:
	return (level - 1) / 2
