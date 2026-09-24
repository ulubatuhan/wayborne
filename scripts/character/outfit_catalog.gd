class_name OutfitCatalog
extends RefCounted

## Kıyafet sistemi: altı slot, tamamen dış görünüm için - hiçbir stat ya da
## mekanik etkisi yok (bkz. CLAUDE.md Faz 13 hazırlık notu #14). Karakter
## oluşturma ekranında her slot sağa/sola kaydırılarak (bkz. `cycle()`) bir
## seçenekten diğerine geçilir, "hiçbiri" de bir seçenektir.
##
## Şimdilik her slotun küçük, hep-açık bir havuzu var - ekonomik kilit ya
## da edinim mekaniği (Equipment'ınki gibi) sonraki bir iş, sistemin
## kendisi burada kuruluyor. Tablo bir kez kurulup statik önbelleğe alınır
## (bkz. TraitCatalog/EquipmentCatalog deseni).

const SLOT_HAT: String = "hat"
const SLOT_SHIRT: String = "shirt"
const SLOT_JACKET: String = "jacket"
const SLOT_GLOVES: String = "gloves"
const SLOT_PANTS: String = "pants"
const SLOT_SHOES: String = "shoes"

## Baştan ayağa doğru sıra - önizleme penceresi ve slot listesi bu sırayla
## döner.
const ALL_SLOTS: Array[String] = [
	SLOT_HAT, SLOT_SHIRT, SLOT_JACKET, SLOT_GLOVES, SLOT_PANTS, SLOT_SHOES,
]

## Bir slotun boş bırakılması - herkesin varsayılanı.
const NONE_PIECE: String = ""

static var _pieces: Array[OutfitPiece] = []
static var _by_id: Dictionary = {}

static func get_pieces_for_slot(slot: String) -> Array[OutfitPiece]:
	_ensure_built()
	var result: Array[OutfitPiece] = []
	for piece in _pieces:
		if piece.slot == slot:
			result.append(piece)
	return result

static func get_piece(piece_id: String) -> OutfitPiece:
	_ensure_built()
	return _by_id.get(piece_id)

static func get_slot_display_name(slot: String) -> String:
	match slot:
		SLOT_HAT:
			return String(TranslationServer.translate("OUTFIT_SLOT_HAT"))
		SLOT_SHIRT:
			return String(TranslationServer.translate("OUTFIT_SLOT_SHIRT"))
		SLOT_JACKET:
			return String(TranslationServer.translate("OUTFIT_SLOT_JACKET"))
		SLOT_GLOVES:
			return String(TranslationServer.translate("OUTFIT_SLOT_GLOVES"))
		SLOT_PANTS:
			return String(TranslationServer.translate("OUTFIT_SLOT_PANTS"))
		_:
			return String(TranslationServer.translate("OUTFIT_SLOT_SHOES"))

## Bir slotta bir sonraki (direction 1) ya da önceki (direction -1) parçaya
## geçer. "Hiçbiri" listenin başında durur, yani her slot en az bu kadar
## seçenek taşır ve kaydırma hiçbir zaman tıkanmaz.
static func cycle(slot: String, current_id: String, direction: int) -> String:
	var ids: Array[String] = [NONE_PIECE]
	for piece in get_pieces_for_slot(slot):
		ids.append(piece.piece_id)
	var index := ids.find(current_id)
	if index < 0:
		index = 0
	index = wrapi(index + direction, 0, ids.size())
	return ids[index]

static func _ensure_built() -> void:
	if not _pieces.is_empty():
		return

	# Kukulete/keçe şapka, WalkFigure/CombatFigure'ın zaten çizdiği "hood"/
	# "cap" kafa şekillerine eşleniyor (bkz. `head_shape`) - şapka seçimi
	# artık gerçekten farklı bir silüet, sadece farklı bir renk değil.
	_add(SLOT_HAT, "hat_felt", "OUTFIT_HAT_FELT", Color(0.42, 0.32, 0.22), "cap")
	_add(SLOT_HAT, "hat_hood", "OUTFIT_HAT_HOOD", Color(0.30, 0.30, 0.34), "hood")

	_add(SLOT_SHIRT, "shirt_linen", "OUTFIT_SHIRT_LINEN", Color(0.82, 0.78, 0.66))
	_add(SLOT_SHIRT, "shirt_dyed", "OUTFIT_SHIRT_DYED", Color(0.36, 0.46, 0.58))

	_add(SLOT_JACKET, "jacket_wool", "OUTFIT_JACKET_WOOL", Color(0.38, 0.28, 0.20))
	_add(SLOT_JACKET, "jacket_leather", "OUTFIT_JACKET_LEATHER", Color(0.30, 0.20, 0.14))

	_add(SLOT_GLOVES, "gloves_leather", "OUTFIT_GLOVES_LEATHER", Color(0.34, 0.24, 0.18))

	_add(SLOT_PANTS, "pants_wool", "OUTFIT_PANTS_WOOL", Color(0.28, 0.26, 0.24))
	_add(SLOT_PANTS, "pants_canvas", "OUTFIT_PANTS_CANVAS", Color(0.58, 0.54, 0.44))

	_add(SLOT_SHOES, "shoes_boots", "OUTFIT_SHOES_BOOTS", Color(0.22, 0.16, 0.12))
	_add(SLOT_SHOES, "shoes_sandals", "OUTFIT_SHOES_SANDALS", Color(0.50, 0.40, 0.30))

static func _add(
	slot: String, piece_id: String, name_key: String, color: Color, head_shape: String = ""
) -> void:
	var piece := OutfitPiece.new()
	piece.piece_id = piece_id
	piece.slot = slot
	piece.display_name_key = name_key
	piece.color = color
	piece.head_shape = head_shape
	_pieces.append(piece)
	_by_id[piece_id] = piece

# --- Figürlerin okuduğu çözümleyiciler ---
#
# `OutfitPreview` (karakter oluşturma), `WalkFigure` (yol) ve `CombatFigure`
# (savaş) kıyafeti aynı kuralla okumalı, yoksa üçü farklı bir "seçilen
# parçanın rengi nedir" mantığı taşır ve biri diğerinden sessizce sapar -
# `CaravanPlan.daily_consumption()`'ın "tek formül, tek yer" kuralının
# kıyafet karşılığı. Hiçbiri kıyafeti *yazmıyor*, sadece okuyor.

## Bir slotta bir parça seçiliyse onun rengini, değilse `fallback`'i döner.
## Seçili ama tanınmayan bir piece_id (bozuk kayıt) de fallback'e düşer.
static func resolve_color(outfit: Dictionary, slot: String, fallback: Color) -> Color:
	var piece := get_piece(str(outfit.get(slot, NONE_PIECE)))
	return piece.color if piece != null else fallback

## Gövde rengi: ceket varsa gömleğin üstünü kapatır (ikisi de `OutfitPreview`
## denen önizlemenin zaten uyguladığı kural, burada tek yere taşındı).
static func resolve_torso_color(outfit: Dictionary, fallback: Color) -> Color:
	if not str(outfit.get(SLOT_JACKET, NONE_PIECE)).is_empty():
		return resolve_color(outfit, SLOT_JACKET, fallback)
	return resolve_color(outfit, SLOT_SHIRT, fallback)

## Kafa: bir şapka seçiliyse ve o şapkanın bir `head_shape`'i varsa figür
## gerçekten farklı bir silüet çiziyor, kendi rengiyle - `override` false
## döndüğünde çağıran hiçbir şeyi değiştirmemeli, sınıfın/düşmanın
## kendi varsayılan kafa rengi ve şekli olduğu gibi kalmalı. Bu, kıyafeti
## olmayan bir karakterin (tayfa, düşman) görünümünün bu sistem hiç
## var olmadan önceki hâliyle birebir aynı kalmasını garanti eden satır.
static func resolve_headgear(outfit: Dictionary, fallback_kind: String) -> Dictionary:
	var piece := get_piece(str(outfit.get(SLOT_HAT, NONE_PIECE)))
	if piece != null and not piece.head_shape.is_empty():
		return {"kind": piece.head_shape, "color": piece.color, "override": true}
	return {"kind": fallback_kind, "color": Color.WHITE, "override": false}
