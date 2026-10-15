class_name OutfitIcon
extends Control

## Bir giysinin resmi: giysinin kendi kare kümesinden (`outfit_<art>_<beden>`)
## duruş karesi, bedensiz, kutuya sığdırılmış. Giysiler için ayrı bir ikon
## çizilmedi - oyunda giyilen resim zaten var, ikinci bir resim o resimden
## sapardı (Art Rules: "a shape drawn in two places is two different
## shapes"). Henüz render'ı olmayan parça (`art_id` boş) kendi rengiyle,
## yerinin kaba bir şekliyle duruyor.

const CLIP: String = "idle"
const PAD: float = 3.0

var _frames: BodyFrames
var _piece: OutfitPiece

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## `body_variant` bakılan kişinin bedeni; parça o bedene dikilmemişse (öbür
## cinsiyet) parçanın kendi cinsiyetinin orta bedeni.
func setup(piece: OutfitPiece, body_variant: String, side: float) -> OutfitIcon:
	_piece = piece
	custom_minimum_size = Vector2(side, side)
	var body := body_variant if body_variant.begins_with("body_") else BodyFrames.CREW_BODY
	if piece != null and piece.gender_only >= 0:
		body = Wardrobe.body_id_for(piece.gender_only, CharacterData.BODY_WEIGHT_AVERAGE)
	_frames = BodyFrames.for_body(OutfitCatalog.frames_id(piece, body))
	if _frames != null and not _frames.has_clip(CLIP):
		_frames = null
	queue_redraw()
	return self

## Kare kümesinin bütün katmanlarının kapsadığı dikdörtgen, render pikselinde.
static func frame_bounds(frames: BodyFrames, clip: String) -> Rect2:
	var bounds := Rect2()
	var first := true
	for layer in BodyFrames.LAYERS.size():
		var e := frames.entry(clip, 0, layer, BodyFrames.KIND_BODY)
		if e.is_empty():
			continue
		var r := Rect2(e.offset, e.size)
		bounds = r if first else bounds.merge(r)
		first = false
	return bounds

func _draw() -> void:
	if _piece == null:
		return
	var box := Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)
	if _frames == null:
		_draw_swatch(box)
		return
	var bounds := frame_bounds(_frames, CLIP)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		_draw_swatch(box)
		return
	var k := minf(box.size.x / bounds.size.x, box.size.y / bounds.size.y)
	var origin := box.get_center() - bounds.get_center() * k
	draw_set_transform(origin, 0.0, Vector2(k, k))
	for layer in BodyFrames.LAYERS.size():
		var e := _frames.entry(CLIP, 0, layer, BodyFrames.KIND_BODY)
		if e.is_empty():
			continue
		draw_texture_rect_region(e.texture, Rect2(e.offset, e.size), e.region)
	draw_set_transform(Vector2.ZERO)

## Resmi olmayan parça: yerinin kaba şekli, parçanın rengiyle.
func _draw_swatch(box: Rect2) -> void:
	var c := box.get_center()
	var w := box.size.x
	var shape := PackedVector2Array()
	match _piece.slot:
		OutfitCatalog.SLOT_HAT:
			shape = PackedVector2Array([c + Vector2(-0.4, 0.15) * w, c + Vector2(-0.25, -0.2) * w,
				c + Vector2(0.25, -0.2) * w, c + Vector2(0.4, 0.15) * w])
		OutfitCatalog.SLOT_PANTS:
			shape = PackedVector2Array([c + Vector2(-0.25, -0.4) * w, c + Vector2(0.25, -0.4) * w,
				c + Vector2(0.28, 0.4) * w, c + Vector2(0.05, 0.4) * w, c + Vector2(0.0, -0.05) * w,
				c + Vector2(-0.05, 0.4) * w, c + Vector2(-0.28, 0.4) * w])
		OutfitCatalog.SLOT_SHOES:
			shape = PackedVector2Array([c + Vector2(-0.3, -0.2) * w, c + Vector2(-0.1, -0.2) * w,
				c + Vector2(-0.1, 0.05) * w, c + Vector2(0.35, 0.1) * w, c + Vector2(0.35, 0.25) * w,
				c + Vector2(-0.3, 0.25) * w])
		_:
			shape = PackedVector2Array([c + Vector2(-0.18, -0.4) * w, c + Vector2(0.18, -0.4) * w,
				c + Vector2(0.4, -0.25) * w, c + Vector2(0.3, -0.1) * w, c + Vector2(0.22, -0.15) * w,
				c + Vector2(0.22, 0.4) * w, c + Vector2(-0.22, 0.4) * w, c + Vector2(-0.22, -0.15) * w,
				c + Vector2(-0.3, -0.1) * w, c + Vector2(-0.4, -0.25) * w])
	ArtDraw.inked(self, shape, _piece.color)
