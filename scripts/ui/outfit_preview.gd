class_name OutfitPreview
extends Control

## Karakter oluşturmadaki "boydan görebildiğimiz pencere" (bkz. CLAUDE.md
## Faz 13 hazırlık notu #14). Kıyafet sistemi tamamen dış görünüm için
## olduğundan burası da karmaşık bir silüet değil, katman katman renklenen
## basit bir insan taslağı - gerçek sprite gelene kadarki `_draw()` yer
## tutucusu, tıpkı oyunun geri kalanının ART-A'dan önceki hâli gibi.
##
## Boy `height_cm`'e göre ölçekleniyor ki #2'nin karaktere göre değişen
## boyu burada da görünsün - iki not aynı önizlemede buluşuyor.

var _character: CharacterData
var _outfit: Dictionary = {}

func _ready() -> void:
	resized.connect(queue_redraw)

func setup(character: CharacterData, outfit: Dictionary) -> void:
	_character = character
	_outfit = outfit
	queue_redraw()

func _draw() -> void:
	if _character == null or size.y <= 0.0:
		return

	var h_ratio := clampf(
		float(_character.height_cm - CharacterData.MIN_HEIGHT_CM)
		/ float(maxi(1, CharacterData.MAX_HEIGHT_CM - CharacterData.MIN_HEIGHT_CM)),
		0.0, 1.0
	)
	var figure_height := lerpf(size.y * 0.70, size.y * 0.92, h_ratio)
	var center_x := size.x * 0.5
	var top_y := size.y - figure_height

	var skin := CharacterData.get_skin_tone_color(_character.skin_tone)

	var head_radius := figure_height * 0.09
	var head_center := Vector2(center_x, top_y + head_radius)
	draw_circle(head_center, head_radius, _piece_color(OutfitCatalog.SLOT_HAT, skin))

	var torso_top := head_center.y + head_radius * 0.9
	var torso_height := figure_height * 0.36
	var torso_width := figure_height * 0.26
	var torso_rect := Rect2(center_x - torso_width * 0.5, torso_top, torso_width, torso_height)
	draw_rect(torso_rect, _torso_color(skin))

	var hand_radius := torso_width * 0.16
	var hand_y := torso_rect.position.y + torso_rect.size.y * 0.62
	var glove_color := _piece_color(OutfitCatalog.SLOT_GLOVES, skin)
	draw_circle(Vector2(torso_rect.position.x, hand_y), hand_radius, glove_color)
	draw_circle(Vector2(torso_rect.position.x + torso_rect.size.x, hand_y), hand_radius, glove_color)

	var legs_top := torso_rect.position.y + torso_rect.size.y
	var legs_height := figure_height * 0.32
	var legs_width := torso_width * 0.85
	var legs_rect := Rect2(center_x - legs_width * 0.5, legs_top, legs_width, legs_height)
	draw_rect(legs_rect, _piece_color(OutfitCatalog.SLOT_PANTS, Color(0.5, 0.5, 0.5)))

	var feet_height := figure_height * 0.06
	var feet_rect := Rect2(legs_rect.position.x, legs_rect.position.y + legs_rect.size.y, legs_rect.size.x, feet_height)
	draw_rect(feet_rect, _piece_color(OutfitCatalog.SLOT_SHOES, Color(0.3, 0.3, 0.3)))

## Bu ekranın ve figürlerin (WalkFigure/CombatFigure) aynı kuralı okuması
## için asıl mantık OutfitCatalog.resolve_color()'da - bkz. o dosyanın
## "Figürlerin okuduğu çözümleyiciler" başlığı.
func _piece_color(slot: String, fallback: Color) -> Color:
	return OutfitCatalog.resolve_color(_outfit, slot, fallback)

## Ceket varsa gömleğin üstünü kapatır; ikisi de yoksa çıplak ten görünür.
func _torso_color(skin: Color) -> Color:
	return OutfitCatalog.resolve_torso_color(_outfit, skin)
