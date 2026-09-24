class_name WagonFigure
extends Control

## Tek başına hareket eden bir kervan vagonu. Gövdeyi `ArtDraw.wagon()`
## çiziyor - yol şeridindeki vagonun aynısı, çünkü aynı kervanın vagonu.
##
## Ayrı bir düğüm olması, şehir dışı yürüyüş alanında her vagonun kendi
## konumunda lerp'lenmesinden: `RoadCaravan` kolonu tek `_draw()`'da
## çiziyor çünkü orada aralıklar sabit, burada her vagon lidere kendi
## hızıyla yetişiyor.

const WHEEL_TURNS_PER_UNIT: float = 0.055

## Koşum okunun boyu - önündeki öküze uzanıyor. `world_hub`'ın
## `HITCH_GAP`'inden biraz uzun, çünkü öküzün *çizilen* gövdesi düğüm
## genişliğinden dar: boşluğu düğüme göre ölçmek boyunduruğu havada
## bırakıyor.
const POLE_LENGTH: float = 42.0

var _wheel_angle: float = 0.0
var _tint: Color = Color.WHITE
var _with_load: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(wagon_size: Vector2, with_load: bool) -> void:
	size = wagon_size
	_with_load = with_load
	queue_redraw()

## Tekerlek kat edilen *mesafeyle* dönüyor, zamanla değil: duran bir
## vagonun tekerleği dönerse araç yerde kayıyor gibi duruyor - "yerde
## süzülen dikdörtgen" hissinin araç tarafındaki karşılığı.
func roll(distance: float) -> void:
	if is_zero_approx(distance):
		return
	_wheel_angle = fmod(_wheel_angle + distance * WHEEL_TURNS_PER_UNIT, TAU)
	queue_redraw()

func set_tint(tint: Color) -> void:
	if _tint == tint:
		return
	_tint = tint
	queue_redraw()

func _draw() -> void:
	if size.y <= 1.0:
		return
	# Koşum oku vagondan önce: kalas gövdenin altından çıkıyor ve öne,
	# öküze doğru uzanıyor. Onsuz öküz vagonun önünde *duran* bir hayvan.
	ArtDraw.draught_pole(
		self, Vector2(size.x * 0.96, size.y), POLE_LENGTH, size.y, _tint
	)
	ArtDraw.wagon(
		self, Vector2(size.x * 0.5, size.y), size.x * 0.92, size.y,
		_wheel_angle, _tint, _with_load
	)
