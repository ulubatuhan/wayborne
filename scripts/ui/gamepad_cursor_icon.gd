class_name GamepadCursorIcon
extends Control

## Sanal imlecin görüntüsü. `GamepadCursor` autoload'unun kurduğu tek
## çocuk düğüm - fare filtresi kapalı, yani kendisi hiçbir tıklamayı
## yutmuyor, yalnızca konumu gösteriyor.
##
## Klasik ok: oyunun tek fırçası (`ArtDraw.inked`) ve tek paletinden
## (`ArtPalette.GOLD`) - Art Rules'un kuralı burada da geçerli, kumanda
## imleci için ayrı bir renk icat edilmiyor.

const SIZE_PX: float = 30.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(SIZE_PX, SIZE_PX)
	# İmleç konumu ekranın *gerçek* koordinatı, kendi kutusunun sol
	# üstü değil - ok ucu tam o noktayı göstermeli.
	pivot_offset = Vector2.ZERO

func _draw() -> void:
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
