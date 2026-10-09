class_name OutfitCatalog
extends RefCounted

## Kıyafet sistemi. Her giysi küçük bir savaş katkısı taşıyor (OutfitPiece'in
## bonus alanları, ekipmanla aynı adlar) ve terzide statına göre fiyatlanıyor
## (`price_for`). Görseli olan parça gerçek,
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
## döner.
const ALL_SLOTS: Array[String] = [
	SLOT_HAT, SLOT_SHIRT, SLOT_JACKET, SLOT_GLOVES, SLOT_PANTS, SLOT_SHOES,
]

## Bir stat puanının altın değeri. Ekipmanla aynı ölçekte durur: zırhın ilk
## kademesi (+4 can) 150 altın, ama zırh bir demirci işi; bir giysinin bir
## puanı kumaş ve dikiş, o yüzden aynı puan çok daha ucuz. Dayanıklılığı
## dolaylı artıran can en ucuzu, vuruş gücü en pahalısı - savaşta en çok
## fark yaratan en pahalı (bkz. Ruin Rules'un beden A/B'si: kaçınma candan
## değerli).
const STAT_PRICE: Dictionary = {
	"hp_bonus": 6, "dodge_bonus": 10, "accuracy_bonus": 8,
	"crit_bonus": 12, "damage_bonus": 16,
}
const BONUS_FIELDS: Array[String] = [
	"hp_bonus", "dodge_bonus", "accuracy_bonus", "crit_bonus", "damage_bonus",
]
## Negatif bir stat fiyattan düşer ama giysi kendi kumaşının yarısından
## ucuza satılmaz.
const MIN_PRICE_SHARE: float = 0.5

## Kıyafetler render'a geçmeden önceki renk-kalemleri. Eski bir kayıttaki
## kimlik en yakın gerçek giysiye çevriliyor (`migrate_piece_id`).
const LEGACY_IDS: Dictionary = {
	"shirt_linen": "peasant_shirt", "shirt_dyed": "peasant_shirt",
	"jacket_wool": "ranger_jacket", "jacket_leather": "ranger_jacket",
	"pants_wool": "peasant_pants", "pants_canvas": "ranger_pants",
	"shoes_boots": "ranger_boots", "shoes_sandals": "peasant_shoes",
	"hat_hood": "ranger_hood", "hat_felt": "felt_cap", "gloves_leather": "leather_gloves",
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

static func get_all_pieces() -> Array[OutfitPiece]:
	_ensure_built()
	return _pieces.duplicate()

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
## `starter_only`: karakter oluşturma yalnızca köylü takımını dolaşır.
static func cycle(slot: String, current_id: String, direction: int, starter_only: bool = false) -> String:
	var ids: Array[String] = [NONE_PIECE]
	for piece in get_pieces_for_slot(slot):
		if piece.starter or not starter_only:
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

## Tabanın (kumaş + işçilik) üstüne her statın değeri.
static func price_for(base: int, bonuses: Dictionary) -> int:
	var total := 0
	for field in bonuses:
		total += int(STAT_PRICE.get(field, 0)) * int(bonuses[field])
	return maxi(int(ceil(base * MIN_PRICE_SHARE)), base + total)

## "+2 can, +1 kaçınma" - terzide ve dolapta parçanın yanında yazan satır.
static func bonus_text(piece: OutfitPiece) -> String:
	if piece == null:
		return ""
	var parts: PackedStringArray = []
	for field in BONUS_FIELDS:
		var value := int(piece.get(field))
		if value != 0:
			parts.append("%+d %s" % [value, String(TranslationServer.translate(_stat_key(field)))])
	return ", ".join(parts)

static func _stat_key(field: String) -> String:
	match field:
		"hp_bonus":
			return "UI_OUTFIT_STAT_HP"
		"dodge_bonus":
			return "UI_OUTFIT_STAT_DODGE"
		"accuracy_bonus":
			return "UI_OUTFIT_STAT_ACCURACY"
		"crit_bonus":
			return "UI_OUTFIT_STAT_CRIT"
		_:
			return "UI_OUTFIT_STAT_DAMAGE"

static func _ensure_built() -> void:
	if not _pieces.is_empty():
		return
	# Renk: parçanın dokusunun ortalama tonu (görseli olanlarda) ya da
	# kumaşının tonu - kare kümesi olmayan çizimler parçayı bu renkle
	# taşıyor. draw_order tools/figure_pipeline/config/outfits.json ile aynı:
	# dış giysi iç giysinin üstüne çiziliyor, render'da da onu sarıyor (eps).
	# Taban fiyat kumaşın ve işin değeri: keten ucuz, yün orta, deri ve ipek
	# pahalı. Statlar bilerek küçük: bütün bir korucu takımı (+5 can, +4
	# kaçınma, +2 isabet, +2 kritik) bir zırh kademesine yakın, üstünü değil.
	var art := true
	_add(SLOT_PANTS, "peasant_pants", "OUTFIT_PEASANT_PANTS", Color(0.27, 0.18, 0.12), 10,
		5, {"hp_bonus": 1}, art, true)
	_add(SLOT_PANTS, "ranger_pants", "OUTFIT_RANGER_PANTS", Color(0.10, 0.22, 0.14), 10,
		16, {"hp_bonus": 1, "dodge_bonus": 1}, art)
	_add(SLOT_PANTS, "riding_breeches", "OUTFIT_RIDING_BREECHES", Color(0.36, 0.30, 0.22), 10,
		18, {"accuracy_bonus": 2}, false)
	_add(SLOT_SHOES, "peasant_shoes", "OUTFIT_PEASANT_SHOES", Color(0.50, 0.44, 0.24), 20,
		4, {"dodge_bonus": 1}, art, true, "", true)
	_add(SLOT_SHOES, "ranger_boots", "OUTFIT_RANGER_BOOTS", Color(0.45, 0.28, 0.16), 20,
		20, {"hp_bonus": 2, "dodge_bonus": 1}, art, false, "", true)
	_add(SLOT_SHOES, "hobnail_boots", "OUTFIT_HOBNAIL_BOOTS", Color(0.22, 0.17, 0.13), 20,
		22, {"hp_bonus": 3, "damage_bonus": 1, "dodge_bonus": -1}, false, false, "", true)
	_add(SLOT_SHIRT, "peasant_shirt", "OUTFIT_PEASANT_SHIRT", Color(0.62, 0.60, 0.46), 30,
		6, {"hp_bonus": 1}, art, true)
	_add(SLOT_SHIRT, "quilted_shirt", "OUTFIT_QUILTED_SHIRT", Color(0.55, 0.50, 0.40), 30,
		14, {"hp_bonus": 3}, false)
	_add(SLOT_SHIRT, "silk_shirt", "OUTFIT_SILK_SHIRT", Color(0.62, 0.20, 0.22), 30,
		40, {"dodge_bonus": 1, "crit_bonus": 1}, false)
	_add(SLOT_JACKET, "ranger_jacket", "OUTFIT_RANGER_JACKET", Color(0.24, 0.42, 0.20), 40,
		30, {"hp_bonus": 2, "dodge_bonus": 1, "accuracy_bonus": 1}, art)
	_add(SLOT_JACKET, "wool_coat", "OUTFIT_WOOL_COAT", Color(0.38, 0.34, 0.30), 40,
		18, {"hp_bonus": 4, "dodge_bonus": -1}, false)
	_add(SLOT_JACKET, "leather_jerkin", "OUTFIT_LEATHER_JERKIN", Color(0.40, 0.24, 0.12), 40,
		28, {"hp_bonus": 3, "damage_bonus": 1}, false)
	_add(SLOT_GLOVES, "leather_gloves", "OUTFIT_LEATHER_GLOVES", Color(0.35, 0.22, 0.12), 45,
		12, {"accuracy_bonus": 1, "crit_bonus": 1}, false)
	_add(SLOT_HAT, "felt_cap", "OUTFIT_FELT_CAP", Color(0.42, 0.20, 0.14), 50,
		6, {"hp_bonus": 1}, false, true, "cap")
	_add(SLOT_HAT, "leather_cap", "OUTFIT_LEATHER_CAP", Color(0.33, 0.22, 0.14), 50,
		14, {"hp_bonus": 3, "dodge_bonus": -1}, false, false, "helmet")
	_add(SLOT_HAT, "ranger_hood", "OUTFIT_RANGER_HOOD", Color(0.25, 0.45, 0.18), 50,
		18, {"dodge_bonus": 1, "crit_bonus": 1}, art, false, "hood")

static func _add(
	slot: String, piece_id: String, name_key: String, color: Color, draw_order: int,
	base_price: int, bonuses: Dictionary, has_art: bool, starter: bool = false,
	head_shape: String = "", boots: bool = false
) -> void:
	var piece := OutfitPiece.new()
	piece.piece_id = piece_id
	piece.slot = slot
	piece.display_name_key = name_key
	piece.color = color
	piece.head_shape = head_shape
	piece.art_id = piece_id if has_art else ""
	piece.draw_order = draw_order
	piece.boots = boots
	piece.starter = starter
	for field in bonuses:
		piece.set(field, int(bonuses[field]))
	piece.price = price_for(base_price, bonuses)
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
