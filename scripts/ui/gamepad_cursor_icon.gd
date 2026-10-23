class_name GamepadCursorIcon
extends Control

## Sanal imlecin görüntüsü. `GamepadCursor` autoload'unun kurduğu tek
## çocuk düğüm - fare filtresi kapalı, yani kendisi hiçbir tıklamayı
## yutmuyor, yalnızca konumu gösteriyor.
##
## Fareyle aynı ok (tools/cursor_art.py): kumandaya geçince imleç değişmiş gibi
## görünmesin. Resim yoksa eski çizgi oka düşer.

const SIZE_PX: float = 32.0
const ARROW_PATH: String = "res://data/assets/ui/cursor/arrow.png"
## Okun ucu resmin bu pikselinde; düğümün sol üstü imlecin gerçek noktası.
const HOTSPOT: Vector2 = Vector2(3, 2)

var _arrow: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIZE_PX, SIZE_PX)
	pivot_offset = Vector2.ZERO
	if ResourceLoader.exists(ARROW_PATH):
		_arrow = load(ARROW_PATH)

func _draw() -> void:
	if _arrow != null:
		draw_texture(_arrow, -HOTSPOT)
		return
	var points := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(0.0, 22.0),
		Vector2(5.5, 17.0),
		Vector2(9.5, 25.0),
		Vector2(13.0, 23.0),
		Vector2(9.0, 15.0),
		Vector2(16.0, 15.0),
	])
	ArtDraw.inked(self, points, ArtPalette.GOLD, 1.6)
