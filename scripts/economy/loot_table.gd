class_name LootTable
extends RefCounted

## Ganimet (görev Y-C03): savaş türüne göre veri dosyasından (loot.json)
## düşenler. Zar savaşın kendi tohumundan; tehlike şansı biraz artırır.
## Eşya kargoya (sığmazsa kişisel çantaya), kıyafet ve ekipman dolaba düşer.

const DATA_PATH: String = "res://data/config/loot.json"
const DANGER_CHANCE_BONUS: float = 0.5

static var _tables: Dictionary = {}

static func table_for(kind: String) -> Array:
	if _tables.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_tables = parsed if parsed is Dictionary else {}
	return _tables.get(kind, []) as Array

## Düşenler: [{"type", "id", "qty"}].
static func roll(kind: String, danger: float, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var scale := 1.0 + clampf(danger, 0.0, 1.0) * DANGER_CHANCE_BONUS
	for entry in table_for(kind):
		var e: Dictionary = entry
		if rng.randf() >= minf(1.0, float(e.get("chance", 0.0)) * scale):
			continue
		var qty := 1
		if String(e.get("type", "")) == "item":
			qty = rng.randi_range(int(e.get("min", 1)), int(e.get("max", 1)))
		out.append({"type": String(e["type"]), "id": String(e["id"]), "qty": qty})
	return out

## Düşenleri kervana koyar; dönen: gösterilecek adlar ("2 Kürk" gibi).
static func apply(session: GameSession, drops: Array) -> Array[String]:
	var lines: Array[String] = []
	for drop in drops:
		var id := String(drop["id"])
		var qty := int(drop.get("qty", 1))
		match String(drop["type"]):
			"item":
				var item := ItemCatalog.get_item(id)
				if item != null and session.add_to_cargo_or_bag(item, qty):
					lines.append("%d %s" % [qty, item.item_name])
			"outfit":
				session.add_outfit(id, qty)
				var piece := OutfitCatalog.get_piece(id)
				lines.append(piece.display_name if piece != null else id)
			"equipment":
				session.add_equipment(id, qty)
				var equipment := EquipmentCatalog.get_equipment(id)
				lines.append(equipment.display_name if equipment != null else id)
	return lines

## Adlar, satır göstermek için (dolaba dokunmadan).
static func describe(drops: Array) -> Array[String]:
	var lines: Array[String] = []
	for drop in drops:
		var id := String(drop["id"])
		match String(drop["type"]):
			"item":
				var item := ItemCatalog.get_item(id)
				lines.append("%d %s" % [int(drop.get("qty", 1)), item.item_name if item != null else id])
			"outfit":
				var piece := OutfitCatalog.get_piece(id)
				lines.append(piece.display_name if piece != null else id)
			"equipment":
				var equipment := EquipmentCatalog.get_equipment(id)
				lines.append(equipment.display_name if equipment != null else id)
	return lines
