class_name LineageArchive
extends RefCounted

## Soy mirası (görev Y-D03): kervan bitince (adı taşıyacak kimse kalmayınca)
## soyun izi oyunun kayıtlarından ayrı bir arşive yazılır. Yeni oyun onu okur:
## eski soyun defterinden son satırlar, yollardaki mezarları (yolda ve
## haritada görünür), ünü ve bir yadigâr. Arşiv tek dosya, en yeni soy sonda;
## yeni oyunun neyi miras aldığı oturumun `legacy` alanında (kayıtta).

const PATH: String = "user://lineage_archive.json"
const MAX_LINEAGES: int = 12
const LEDGER_LINES: int = 8
## Ünün mirası: eski soyun itibarının bu payı, tavanla.
const REPUTATION_SHARE: float = 0.2
const MAX_REPUTATION_LEGACY: int = 6

static var path: String = PATH

static func build_record(session: GameSession) -> Dictionary:
	var graves: Array = []
	for m in session.road_memorials:
		var kind := String(m["kind"])
		if kind == GameSession.MEMORIAL_GRAVE or kind == GameSession.MEMORIAL_CAIRN:
			graves.append((m as Dictionary).duplicate())
	var lines: Array = []
	for entry in session.ledger.entries.slice(maxi(0, session.ledger.entries.size() - LEDGER_LINES)):
		lines.append((entry as Dictionary).duplicate())
	return {
		"caravan_name": session.caravan_name,
		"generations": session.lineage_generation,
		"days": session.total_days_elapsed,
		"reputation": session.reputation,
		"journeys": session.journeys_completed,
		"graves": graves,
		"ledger": lines,
	}

## Soyu yazar ve açtığı başlangıç kökenlerini (Y-D05) meta kayda ekler.
static func record(session: GameSession) -> void:
	var data := _read()
	var all: Array = data.get("lineages", [])
	var lineage := build_record(session)
	all.append(lineage)
	while all.size() > MAX_LINEAGES:
		all.pop_front()
	var unlocked: Array = data.get("unlocked", [])
	for origin in StartOrigins.unlocks_for(lineage):
		if not unlocked.has(origin):
			unlocked.append(origin)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"lineages": all, "unlocked": unlocked}))

static func _read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func load_all() -> Array:
	return _read().get("lineages", []) as Array

## Açılmış başlangıç kökenleri (Y-D05); arşivden soy düşse de kalır.
static func unlocked_origins() -> Array:
	return _read().get("unlocked", []) as Array

static func latest() -> Dictionary:
	var all := load_all()
	return all[-1] if not all.is_empty() else {}

## Yeni oyuna eski soyu işler; dönen: miras özeti (oturumun `legacy`'si).
static func apply_to(session: GameSession, old: Dictionary) -> Dictionary:
	if old.is_empty():
		return {}
	var reputation := mini(MAX_REPUTATION_LEGACY, int(float(maxi(0, int(old.get("reputation", 0)))) * REPUTATION_SHARE))
	session.change_reputation(reputation)
	for m in old.get("graves", []):
		var grave: Dictionary = (m as Dictionary).duplicate()
		grave["old_lineage"] = String(old.get("caravan_name", ""))
		grave["id"] = "old_%s" % String(grave.get("id", ""))
		session.road_memorials.append(grave)
	# Yadigâr: eski soydan kalan eski mühür.
	session.add_to_cargo_or_bag(ItemCatalog.get_item(ItemCatalog.RARE_RELIC), 1)
	session.ledger.record(CaravanLedger.KIND_MEMORIAL, String(old.get("caravan_name", "")),
		0, 0, "", "LEDGER_CAUSE_OLD_LINEAGE")
	var legacy := {
		"from": String(old.get("caravan_name", "")),
		"generations": int(old.get("generations", 1)),
		"reputation": reputation,
		"graves": (old.get("graves", []) as Array).size(),
		"ledger": old.get("ledger", []),
	}
	session.legacy = legacy
	return legacy
