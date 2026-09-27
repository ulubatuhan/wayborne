class_name Wardrobe
extends RefCounted

## Giyilebilir her şeyin (kıyafet, zırh, silah) iskelete takılan sprite
## parçaları. Bir parçanın resmi yolundan bulunuyor, ayrı bir liste yok:
##
##     data/assets/characters/wardrobe/<item_id>/<parça>.png
##
## `item_id` bir `OutfitPiece.piece_id` ya da `Equipment.equipment_id`;
## `<parça>` `FigureRig.PARTS`'tan biri (head, torso, upper_arm, forearm,
## hand, thigh, shin, foot, weapon). Bir kalemin yalnızca kapladığı parçalar
## vardır - bir çizmenin `shin` ve `foot`'u, bir kılıcın yalnızca `weapon`'u.
## Arka uzuv ön uzvun resmini karartılmış kullanıyor; farklı çizilmesi
## gerekiyorsa `<parça>_back.png` onun yerine geçiyor.
##
## Resmi olmayan kalem prosedürel figürde kalır (renk + kafa şekli, bkz.
## OutfitCatalog'un çözümleyicileri) - sprite geldikçe kalem kalem geçiş,
## hiçbir ekran "hepsi hazır mı" diye beklemiyor.
##
## `ResourceLoader.exists()` Web dışa aktarımında da çalışıyor (dizin
## taramasının aksine): içe aktarılmış dokular yeniden eşleniyor, dizin
## listesi eşlenmiyor.

const ROOT: String = "res://data/assets/characters/wardrobe/"
## Ten katmanı: `wardrobe/body/<parça>.png` varsa prosedürel uzvun üstüne
## herkesin altında çiziliyor ve karakterin ten rengiyle çarpılıyor (ressam
## açık gri bir beden çiziyor).
const BODY_ID: String = "body"

## Aynı kemikteki katmanların sırası, alttan üste. Gömlek ceketin, ceket
## zırhın altında; eldiven kolluğun, şapka her şeyin üstünde. Silah kendi
## kemiğinde (`weapon`) ama kolluk/eldiven gibi diğer parçaları da olabilir.
const SLOT_LAYERS: Array[String] = [
	OutfitCatalog.SLOT_SHIRT,
	OutfitCatalog.SLOT_PANTS,
	OutfitCatalog.SLOT_SHOES,
	OutfitCatalog.SLOT_JACKET,
	EquipmentCatalog.SLOT_ARMOR,
	OutfitCatalog.SLOT_GLOVES,
	EquipmentCatalog.SLOT_AMULET,
	OutfitCatalog.SLOT_HAT,
	EquipmentCatalog.SLOT_WEAPON,
]

## Arka uzvun kendi resmi yoksa ön uzvunki bu kadar karartılıyor -
## prosedürel arka bacağın `darkened(0.28)`'iyle aynı derinlik ipucu.
const BACK_SHADE: Color = Color(0.72, 0.72, 0.72)

static var _cache: Dictionary = {}
## Testler kendi geçici klasörlerini gösteriyor; oyun hep `ROOT`'u okuyor.
static var root_path: String = ROOT

## `<item_id>/<part>.png`'nin dokusu ya da yoksa null. Sonuç (yokluk dahil)
## önbellekte: her karede her kemik için diske sorulmuyor. İçe aktarılmış
## doku önce; henüz içe aktarılmamış bir PNG (yeni bırakılmış resim, test
## fikstürü) doğrudan diskten okunuyor.
static func part_texture(item_id: String, part: String) -> Texture2D:
	var key := "%s/%s" % [item_id, part]
	if _cache.has(key):
		return _cache[key]
	var path := "%s%s.png" % [root_path, key]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path)
	elif FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture

## Bir kemiğin dokusu ve arka uzuv için kendi resmi olup olmadığı.
static func bone_texture(item_id: String, bone: String) -> Dictionary:
	var spec: Dictionary = FigureRig.BONES[bone]
	var part := String(spec.part)
	if bool(spec.back):
		var own := part_texture(item_id, part + "_back")
		if own != null:
			return {"texture": own, "shade": false}
	return {"texture": part_texture(item_id, part), "shade": bool(spec.back)}

static func has_sprites(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for part in FigureRig.PART_ORDER:
		if part_texture(item_id, part) != null:
			return true
	return false

static func has_part(item_ids: PackedStringArray, part: String) -> bool:
	for item_id in item_ids:
		if part_texture(item_id, part) != null:
			return true
	return false

## Bir karakterin üstündeki, resmi olan kalemler - katman sırasıyla, alttan
## üste. Kıyafet (`outfit`) ve ekipman (`equipped`) aynı listeye giriyor:
## oyuncu için ikisi de "üstünde ne var" sorusunun cevabı.
static func loadout_of(outfit: Dictionary, equipped: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for slot in SLOT_LAYERS:
		var item_id := str(outfit.get(slot, equipped.get(slot, "")))
		if has_sprites(item_id):
			result.append(item_id)
	return result

static func loadout_for(character: CharacterData) -> PackedStringArray:
	if character == null:
		return PackedStringArray()
	return loadout_of(character.outfit, character.equipped)

## Yeni bir resim eklendiğinde (araç, test) önbelleği boşaltmak için.
static func clear_cache() -> void:
	_cache.clear()
