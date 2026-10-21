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
## Zırhın görünüş slotu: oyuncu bunu terzide seçmiyor, demircinin zırh
## kademesi (Equipment) giydiriyor - `CharacterData.get_appearance_outfit`.
const SLOT_ARMOR: String = "armor"
const ARMOR_ART: Dictionary = {
	"armor_tier_1": "armor_leather", "armor_tier_2": "armor_mail", "armor_tier_3": "armor_plate",
}

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

## Satılan/giyilen giysiler (zırhın görünüşü hariç).
static func get_all_pieces() -> Array[OutfitPiece]:
	_ensure_built()
	var out: Array[OutfitPiece] = []
	for piece in _pieces:
		if piece.sold:
			out.append(piece)
	return out

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
static func cycle(
	slot: String, current_id: String, direction: int, starter_only: bool = false, gender: int = -1
) -> String:
	var ids: Array[String] = [NONE_PIECE]
	for piece in get_pieces_for_slot(slot):
		if (piece.starter or not starter_only) and (gender < 0 or piece.fits(gender)):
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
## Çıplak ten yok (görev Y-G12): görünüşte boş kalan gömlek, pantolon ve
## ayakkabı yuvası köylü takımıyla çizilir. Yalnızca çizim - stat ve dolap
## bundan habersiz (giyilmeyen bir parça stat vermez). İsimsiz tayfa da bu
## takımla yürür.
const MODESTY_LAYER: Dictionary = {
	SLOT_SHIRT: "peasant_shirt",
	SLOT_PANTS: "peasant_pants",
	SLOT_SHOES: "peasant_shoes",
}

static func with_modesty_layer(outfit: Dictionary) -> Dictionary:
	var out := outfit.duplicate()
	var hidden := hidden_slots(out)
	for slot in MODESTY_LAYER:
		if hidden.has(slot):
			continue  # elbise pantolonu, cübbe gömleği örtüyor: alta bir şey eklenmez
		if not out.has(slot) or str(out[slot]).is_empty() or str(out[slot]) == NONE_PIECE:
			out[slot] = MODESTY_LAYER[slot]
	return out

## Bu yuva boş görünüyor ama figür üstünde köylü takımı taşıyor mu: ekran
## "boş" yerine bunu söylesin, yoksa figür giyinik, yuva boş görünür.
static func is_plain_cloth_slot(outfit: Dictionary, slot: String) -> bool:
	if not MODESTY_LAYER.has(slot) or hidden_slots(outfit).has(slot):
		return false
	var id := str(outfit.get(slot, ""))
	return id.is_empty() or id == NONE_PIECE

static func worn_frames(outfit: Dictionary, body_variant: String) -> Array[BodyFrames]:
	var worn: Array[OutfitPiece] = []
	var hidden := hidden_slots(outfit)
	for slot in outfit:
		var piece := get_piece(str(outfit[slot]))
		if piece != null and not hidden.has(piece.slot):
			worn.append(piece)
	worn.sort_custom(func(a: OutfitPiece, b: OutfitPiece) -> bool: return a.draw_order < b.draw_order)
	var out: Array[BodyFrames] = []
	for piece in worn:
		var frames := BodyFrames.for_body(frames_id(piece, body_variant))
		if frames != null:
			out.append(frames)
	return out

## Giyilen bir parçanın örttüğü slotlar (elbise -> pantolon, cübbe ->
## gömlek ve pantolon). Örtülen giysi giyili kalıyor (statı da), yalnız
## çizilmiyor - render da onun üstüne şişirilmedi, yani çizilse içinden
## taşardı.
static func hidden_slots(outfit: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for slot in outfit:
		var piece := get_piece(str(outfit[slot]))
		if piece != null:
			for hidden in piece.hides:
				out[hidden] = true
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
	var F := CharacterData.GENDER_FEMALE
	var M := CharacterData.GENDER_MALE
	# --- pantolon ve etek ---
	_add(SLOT_PANTS, "peasant_pants", "OUTFIT_PEASANT_PANTS", Color(0.27, 0.18, 0.12), 10,
		5, {"hp_bonus": 1}, art, true)
	_add(SLOT_PANTS, "ranger_pants", "OUTFIT_RANGER_PANTS", Color(0.10, 0.22, 0.14), 10,
		16, {"hp_bonus": 1, "dodge_bonus": 1}, art)
	_add(SLOT_PANTS, "riding_breeches", "OUTFIT_RIDING_BREECHES", Color(0.44, 0.38, 0.30), 10,
		18, {"accuracy_bonus": 2}, art, false, "", false, {"art": "wool_pants"})
	_add(SLOT_PANTS, "viking_pants", "OUTFIT_VIKING_PANTS", Color(0.40, 0.33, 0.25), 10,
		14, {"hp_bonus": 2}, art)
	_add(SLOT_PANTS, "harem_pants", "OUTFIT_HAREM_PANTS", Color(0.60, 0.30, 0.22), 10,
		10, {"dodge_bonus": 1}, art)
	_add(SLOT_PANTS, "cloth_trousers", "OUTFIT_CLOTH_TROUSERS", Color(0.34, 0.31, 0.27), 10,
		16, {"hp_bonus": 1, "accuracy_bonus": 1}, art)
	_add(SLOT_PANTS, "long_skirt", "OUTFIT_LONG_SKIRT", Color(0.44, 0.30, 0.22), 25,
		6, {"hp_bonus": 1}, art, true, "", false, {"gender": F})
	_add(SLOT_PANTS, "tiered_skirt", "OUTFIT_TIERED_SKIRT", Color(0.56, 0.38, 0.24), 25,
		14, {"dodge_bonus": 1}, art, false, "", false, {"gender": F})
	# --- ayakkabı ---
	_add(SLOT_SHOES, "peasant_shoes", "OUTFIT_PEASANT_SHOES", Color(0.50, 0.44, 0.24), 20,
		4, {"dodge_bonus": 1}, art, true, "", true)
	_add(SLOT_SHOES, "ranger_boots", "OUTFIT_RANGER_BOOTS", Color(0.45, 0.28, 0.16), 20,
		20, {"hp_bonus": 2, "dodge_bonus": 1}, art, false, "", true)
	_add(SLOT_SHOES, "hobnail_boots", "OUTFIT_HOBNAIL_BOOTS", Color(0.52, 0.30, 0.14), 20,
		22, {"hp_bonus": 3, "damage_bonus": 1, "dodge_bonus": -1}, art, false, "", true)
	_add(SLOT_SHOES, "short_boots", "OUTFIT_SHORT_BOOTS", Color(0.42, 0.24, 0.12), 20,
		14, {"hp_bonus": 1, "dodge_bonus": 1}, art)
	_add(SLOT_SHOES, "riding_boots", "OUTFIT_RIDING_BOOTS", Color(0.36, 0.20, 0.10), 20,
		24, {"hp_bonus": 1, "accuracy_bonus": 1}, art, false, "", true)
	_add(SLOT_SHOES, "leather_boots", "OUTFIT_LEATHER_BOOTS", Color(0.54, 0.33, 0.16), 20,
		18, {"hp_bonus": 2}, art, false, "", true)
	_add(SLOT_SHOES, "ankle_boots", "OUTFIT_ANKLE_BOOTS", Color(0.44, 0.26, 0.13), 20,
		14, {"hp_bonus": 1, "dodge_bonus": 1}, art, false, "", false, {"gender": M})
	_add(SLOT_SHOES, "womens_ankle_boots", "OUTFIT_WOMENS_ANKLE_BOOTS", Color(0.48, 0.28, 0.15), 20,
		14, {"hp_bonus": 1, "dodge_bonus": 1}, art, false, "", false, {"gender": F})
	_add(SLOT_SHOES, "womens_knee_boots", "OUTFIT_WOMENS_KNEE_BOOTS", Color(0.36, 0.20, 0.10), 20,
		24, {"hp_bonus": 2, "dodge_bonus": 1}, art, false, "", true, {"gender": F})
	_add(SLOT_SHOES, "strap_sandals", "OUTFIT_STRAP_SANDALS", Color(0.56, 0.36, 0.18), 20,
		8, {"dodge_bonus": 2, "hp_bonus": -1}, art)
	_add(SLOT_SHOES, "felt_shoes", "OUTFIT_FELT_SHOES", Color(0.40, 0.34, 0.26), 20,
		5, {"dodge_bonus": 1}, art, true)
	# --- gömlek, bluz, elbise ---
	_add(SLOT_SHIRT, "peasant_shirt", "OUTFIT_PEASANT_SHIRT", Color(0.62, 0.60, 0.46), 30,
		6, {"hp_bonus": 1}, art, true)
	_add(SLOT_SHIRT, "quilted_shirt", "OUTFIT_QUILTED_SHIRT", Color(0.58, 0.50, 0.36), 30,
		14, {"hp_bonus": 3}, art, false, "", false, {"art": "quilted_tunic"})
	_add(SLOT_SHIRT, "silk_shirt", "OUTFIT_SILK_SHIRT", Color(0.90, 0.86, 0.74), 30,
		40, {"dodge_bonus": 1, "crit_bonus": 1}, art, false, "", false, {"art": "silk_blouse"})
	_add(SLOT_SHIRT, "laced_shirt", "OUTFIT_LACED_SHIRT", Color(0.72, 0.64, 0.50), 30,
		12, {"hp_bonus": 1, "dodge_bonus": 1}, art)
	_add(SLOT_SHIRT, "fisherman_sweater", "OUTFIT_FISHERMAN_SWEATER", Color(0.60, 0.55, 0.45), 30,
		14, {"hp_bonus": 3, "dodge_bonus": -1}, art)
	_add(SLOT_SHIRT, "linen_tunic", "OUTFIT_LINEN_TUNIC", Color(0.80, 0.74, 0.60), 30,
		6, {"hp_bonus": 1}, art, true)
	_add(SLOT_SHIRT, "bodice_top", "OUTFIT_BODICE_TOP", Color(0.42, 0.28, 0.20), 30,
		24, {"crit_bonus": 1, "dodge_bonus": 1}, art, false, "", false, {"gender": F})
	_add(SLOT_SHIRT, "peasant_blouse", "OUTFIT_PEASANT_BLOUSE", Color(0.86, 0.82, 0.72), 30,
		6, {"hp_bonus": 1}, art, true, "", false, {"gender": F})
	_add(SLOT_SHIRT, "shift_dress", "OUTFIT_SHIFT_DRESS", Color(0.52, 0.30, 0.28), 32,
		18, {"hp_bonus": 2, "dodge_bonus": 1}, art, false, "", false, {"gender": F, "hides": [SLOT_PANTS]})
	_add(SLOT_SHIRT, "pinafore_dress", "OUTFIT_PINAFORE_DRESS", Color(0.36, 0.42, 0.30), 32,
		14, {"hp_bonus": 2}, art, false, "", false, {"gender": F, "hides": [SLOT_PANTS]})
	# --- ceket, yelek, cübbe ---
	_add(SLOT_JACKET, "ranger_jacket", "OUTFIT_RANGER_JACKET", Color(0.24, 0.42, 0.20), 40,
		30, {"hp_bonus": 2, "dodge_bonus": 1, "accuracy_bonus": 1}, art)
	_add(SLOT_JACKET, "leather_jerkin", "OUTFIT_LEATHER_JERKIN", Color(0.52, 0.30, 0.14), 40,
		28, {"hp_bonus": 3, "damage_bonus": 1}, art, false, "", false, {"art": "leather_vest"})
	_add(SLOT_JACKET, "wool_coat", "OUTFIT_WOOL_COAT", Color(0.40, 0.30, 0.22), 42,
		18, {"hp_bonus": 4, "dodge_bonus": -1}, art)
	_add(SLOT_JACKET, "pilgrim_robe", "OUTFIT_PILGRIM_ROBE", Color(0.42, 0.33, 0.24), 44,
		22, {"hp_bonus": 3, "dodge_bonus": 1}, art, false, "", false, {"hides": [SLOT_SHIRT, SLOT_PANTS]})
	_add(SLOT_JACKET, "scribe_robe", "OUTFIT_SCRIBE_ROBE", Color(0.24, 0.27, 0.40), 44,
		34, {"accuracy_bonus": 2, "crit_bonus": 1, "dodge_bonus": -1}, art, false, "", false,
		{"hides": [SLOT_SHIRT, SLOT_PANTS]})
	# Büyücü cüppesi: terzide satılmaz - büyücüler nadir ve hoş
	# karşılanmıyor (docs/lore/LORE.md §3.3), cüppe ancak bir büyücüden kalır.
	_add(SLOT_JACKET, "mage_robe", "OUTFIT_MAGE_ROBE", Color(0.30, 0.17, 0.40), 44,
		40, {"accuracy_bonus": 2, "crit_bonus": 2, "dodge_bonus": -1}, art, false, "", false,
		{"hides": [SLOT_SHIRT, SLOT_PANTS], "sold": false})
	# --- eldiven ---
	_add(SLOT_GLOVES, "leather_gloves", "OUTFIT_LEATHER_GLOVES", Color(0.52, 0.30, 0.14), 15,
		12, {"accuracy_bonus": 1, "crit_bonus": 1}, art)
	# --- başlık ---
	_add(SLOT_HAT, "felt_cap", "OUTFIT_FELT_CAP", Color(0.40, 0.30, 0.22), 50,
		6, {"hp_bonus": 1}, art, true, "cap", false, {"art": "felt_hat"})
	_add(SLOT_HAT, "leather_cap", "OUTFIT_LEATHER_CAP", Color(0.52, 0.30, 0.14), 50,
		14, {"hp_bonus": 3, "dodge_bonus": -1}, art, false, "helmet", false, {"art": "leather_helmet"})
	_add(SLOT_HAT, "ranger_hood", "OUTFIT_RANGER_HOOD", Color(0.25, 0.45, 0.18), 50,
		18, {"dodge_bonus": 1, "crit_bonus": 1}, art, false, "hood")
	_add(SLOT_HAT, "pilgrim_hood", "OUTFIT_PILGRIM_HOOD", Color(0.42, 0.33, 0.24), 50,
		8, {"dodge_bonus": 1}, art, false, "hood")
	_add(SLOT_HAT, "head_veil", "OUTFIT_HEAD_VEIL", Color(0.80, 0.76, 0.66), 50,
		5, {"hp_bonus": 1}, art, true, "wrap", false, {"gender": F})
	_add(SLOT_HAT, "wizard_hat", "OUTFIT_WIZARD_HAT", Color(0.28, 0.16, 0.38), 50,
		12, {"crit_bonus": 1}, art, false, "cap", false, {"sold": false})
	_add(SLOT_HAT, "wide_hat", "OUTFIT_WIDE_HAT", Color(0.38, 0.30, 0.22), 50,
		12, {"accuracy_bonus": 1}, art, false, "cap")
	_add(SLOT_HAT, "fur_hat", "OUTFIT_FUR_HAT", Color(0.48, 0.36, 0.24), 50,
		14, {"hp_bonus": 2}, art, false, "cap")
	_add(SLOT_HAT, "knit_cap", "OUTFIT_KNIT_CAP", Color(0.50, 0.44, 0.36), 50,
		5, {"hp_bonus": 1}, art, true, "cap")
	_add(SLOT_HAT, "guard_helmet", "OUTFIT_GUARD_HELMET", Color(0.64, 0.64, 0.68), 50,
		40, {"hp_bonus": 4, "dodge_bonus": -1}, art, false, "helmet")
	_add(SLOT_HAT, "spiked_helmet", "OUTFIT_SPIKED_HELMET", Color(0.55, 0.52, 0.50), 50,
		46, {"hp_bonus": 3, "damage_bonus": 1, "dodge_bonus": -1}, art, false, "helmet")
	# --- zırhın görünüşü (satılmaz; Equipment'ın zırh kademesinden) ---
	for tier in ARMOR_ART:
		_add(SLOT_ARMOR, ARMOR_ART[tier], "", Color(0.45, 0.40, 0.34), 36, 0, {}, art, false, "", false,
			{"sold": false})

## `extra`: "art" (kare kümesi başka adla render edildiyse - eski kimlik
## korunuyor, kayıtlar bozulmasın), "gender", "hides", "sold".
static func _add(
	slot: String, piece_id: String, name_key: String, color: Color, draw_order: int,
	base_price: int, bonuses: Dictionary, has_art: bool, starter: bool = false,
	head_shape: String = "", boots: bool = false, extra: Dictionary = {}
) -> void:
	var piece := OutfitPiece.new()
	piece.piece_id = piece_id
	piece.slot = slot
	piece.display_name_key = name_key
	piece.color = color
	piece.head_shape = head_shape
	piece.art_id = str(extra.get("art", piece_id)) if has_art else ""
	piece.gender_only = int(extra.get("gender", -1))
	for hidden in extra.get("hides", []):
		piece.hides.append(String(hidden))
	piece.sold = bool(extra.get("sold", true))
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
