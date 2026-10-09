class_name OutfitCatalog
extends RefCounted

## Kıyafet sistemi: tamamen dış görünüm için - hiçbir stat ya da mekanik
## etkisi yok (bkz. CLAUDE.md Faz 13 hazırlık notu #14). Her parça gerçek,
## 3B'den render edilmiş bir giysi (`art_id`, bkz. CLAUDE.md "Clothes are
## worn, not painted on"): bedenin aynı pozunda, aynı katmanlarda çiziliyor
## ve çıkarılabiliyor. Bir parça bir kişinin üstünde ya da kervanın kıyafet
## dolabında (`GameSession.outfit_inventory`) durur; giymek dolaptan alır,
## çıkarmak geri koyar - ekipmanın deposuyla aynı desen.
##
## Tablo bir kez kurulup statik önbelleğe alınır (bkz. TraitCatalog/
## EquipmentCatalog deseni).

const SLOT_HAT: String = "hat"
const SLOT_SHIRT: String = "shirt"
const SLOT_JACKET: String = "jacket"
const SLOT_GLOVES: String = "gloves"
const SLOT_PANTS: String = "pants"
const SLOT_SHOES: String = "shoes"

## Baştan ayağa doğru sıra - önizleme penceresi ve slot listesi bu sırayla
## döner. Eldiven slotu sabit olarak duruyor (Wardrobe katman sırası onu
## okuyor) ama listede yok: elimizdeki giysilerin eldiveni gömlekle/yelekle
## birlikte geliyor, tek başına bir eldiven parçası yok.
const ALL_SLOTS: Array[String] = [
	SLOT_HAT, SLOT_SHIRT, SLOT_JACKET, SLOT_PANTS, SLOT_SHOES,
]

## Kıyafetler render'a geçmeden önceki renk-kalemleri. Eski bir kayıttaki
## kimlik en yakın gerçek giysiye çevriliyor (`migrate_piece_id`); karşılığı
## olmayan (fötr şapka, tek eldiven) düşüyor - yeni dünyada öyle bir parça yok.
const LEGACY_IDS: Dictionary = {
	"shirt_linen": "peasant_shirt", "shirt_dyed": "peasant_shirt",
	"jacket_wool": "ranger_jacket", "jacket_leather": "ranger_jacket",
	"pants_wool": "peasant_pants", "pants_canvas": "ranger_pants",
	"shoes_boots": "ranger_boots", "shoes_sandals": "peasant_shoes",
	"hat_hood": "ranger_hood", "hat_felt": "", "gloves_leather": "",
}

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

## Eski ya da bilinmeyen bir kimliğin bugünkü karşılığı ("" = yok).
static func migrate_piece_id(piece_id: String) -> String:
	if get_piece(piece_id) != null:
		return piece_id
	return str(LEGACY_IDS.get(piece_id, ""))

## Bir bedenin (CharacterData.get_body_variant_id) üstündeki parçanın kare
## kümesinin kimliği: `outfit_<art_id>_<cinsiyet>_<kilo>`.
static func frames_id(piece: OutfitPiece, body_variant: String) -> String:
	if piece == null or piece.art_id.is_empty() or not body_variant.begins_with("body_"):
		return ""
	return "outfit_%s_%s" % [piece.art_id, body_variant.trim_prefix("body_")]

## Giyilen parçaların kare kümeleri, çizim sırasıyla (alttan üste). Kare
## kümesi henüz olmayan parça (o beden için render edilmemiş) atlanıyor:
## figür o parçayı prosedürel rengiyle taşımaya devam ediyor.
static func worn_frames(outfit: Dictionary, body_variant: String) -> Array[BodyFrames]:
	var worn: Array[OutfitPiece] = []
	for slot in outfit:
		var piece := get_piece(str(outfit[slot]))
		if piece != null:
			worn.append(piece)
	worn.sort_custom(func(a: OutfitPiece, b: OutfitPiece) -> bool: return a.draw_order < b.draw_order)
	var out: Array[BodyFrames] = []
	for piece in worn:
		var frames := BodyFrames.for_body(frames_id(piece, body_variant))
		if frames != null:
			out.append(frames)
	return out

## O slottaki parçanın bu beden için kare kümesi var mı - varsa onun
## prosedürel karşılığı (kukuletanın çizilmiş silüeti) çizilmiyor.
static func has_frames_for(outfit: Dictionary, slot: String, body_variant: String) -> bool:
	var piece := get_piece(str(outfit.get(slot, NONE_PIECE)))
	return BodyFrames.for_body(frames_id(piece, body_variant)) != null

## Bileği tutan bir ayakkabı giyiliyor mu (yürüyüş `walk_boots` klibine geçer).
static func wears_boots(outfit: Dictionary) -> bool:
	var piece := get_piece(str(outfit.get(SLOT_SHOES, NONE_PIECE)))
	return piece != null and piece.boots

static func _ensure_built() -> void:
	if not _pieces.is_empty():
		return
	# Renk: parçanın dokusunun ortalama tonu - kare kümesi olmayan çizimler
	# (savaş silüeti, eski parça mankeni) parçayı bu renkle taşıyor.
	# draw_order tools/figure_pipeline/config/outfits.json ile aynı: dış giysi
	# iç giysinin üstüne çiziliyor, render'da da onu sarıyor (eps).
	_add(SLOT_PANTS, "peasant_pants", "OUTFIT_PEASANT_PANTS", Color(0.27, 0.18, 0.12), 10)
	_add(SLOT_PANTS, "ranger_pants", "OUTFIT_RANGER_PANTS", Color(0.10, 0.22, 0.14), 10)
	_add(SLOT_SHOES, "peasant_shoes", "OUTFIT_PEASANT_SHOES", Color(0.50, 0.44, 0.24), 20, "", true)
	_add(SLOT_SHOES, "ranger_boots", "OUTFIT_RANGER_BOOTS", Color(0.45, 0.28, 0.16), 20, "", true)
	_add(SLOT_SHIRT, "peasant_shirt", "OUTFIT_PEASANT_SHIRT", Color(0.62, 0.60, 0.46), 30)
	_add(SLOT_JACKET, "ranger_jacket", "OUTFIT_RANGER_JACKET", Color(0.24, 0.42, 0.20), 40)
	_add(SLOT_HAT, "ranger_hood", "OUTFIT_RANGER_HOOD", Color(0.25, 0.45, 0.18), 50, "hood")

static func _add(
	slot: String, piece_id: String, name_key: String, color: Color, draw_order: int,
	head_shape: String = "", boots: bool = false
) -> void:
	var piece := OutfitPiece.new()
	piece.piece_id = piece_id
	piece.slot = slot
	piece.display_name_key = name_key
	piece.color = color
	piece.head_shape = head_shape
	piece.art_id = piece_id
	piece.draw_order = draw_order
	piece.boots = boots
	_pieces.append(piece)
	_by_id[piece_id] = piece

# --- Figürlerin okuduğu çözümleyiciler ---
#
# `WalkFigure` (yol, önizlemeler) ve `CombatFigure` (savaş) kıyafeti aynı
# kuralla okumalı, yoksa üçü farklı bir "seçilen
# parçanın rengi nedir" mantığı taşır ve biri diğerinden sessizce sapar -
# `CaravanPlan.daily_consumption()`'ın "tek formül, tek yer" kuralının
# kıyafet karşılığı. Hiçbiri kıyafeti *yazmıyor*, sadece okuyor.

## Bir slotta bir parça seçiliyse onun rengini, değilse `fallback`'i döner.
## Seçili ama tanınmayan bir piece_id (bozuk kayıt) de fallback'e düşer.
static func resolve_color(outfit: Dictionary, slot: String, fallback: Color) -> Color:
	var piece := get_piece(str(outfit.get(slot, NONE_PIECE)))
	return piece.color if piece != null else fallback

## Gövde rengi: ceket varsa gömleğin üstünü kapatır.
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
