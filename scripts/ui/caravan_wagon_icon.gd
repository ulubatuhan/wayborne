class_name CaravanWagonIcon
extends Control

## Tek bir vagonun küçük simgesi - `CaravanOverviewPanel`'in "kervanı
## sembolize eden" satırı bunlardan oluşuyor. Yeni bir çizim icat etmiyor:
## `ArtDraw.wagon()` yolun ve dünyanın zaten paylaştığı fırça (bkz. Art
## Rules'un "a shape drawn in two places is two different shapes" maddesi) -
## burası üçüncü, statik bir bağlam.

var _load_ratio: float = 0.0

func setup(load_ratio: float) -> void:
	_load_ratio = clampf(load_ratio, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	if size.y <= 0.0:
		return
	var w := size.x * 0.78
	var h := size.y * 0.62
	var base := Vector2(size.x * 0.5, size.y * 0.86)
	# Yük oranı yükseldikçe tente rengi koyulaşır - "ne kadar dolu"
	# bir bakışta okunsun diye, sayıyı okumadan önce.
	var tint := Color.WHITE.lerp(Color(0.75, 0.62, 0.45), _load_ratio * 0.6)
	ArtDraw.wagon(self, base, w, h, 0.0, tint, _load_ratio > 0.05)
