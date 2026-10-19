class_name PatternStripe
extends Control

## Renk körlüğü için desenli şerit (görev Y-H07): kan rengi şerit, ayarda
## açıksa rengi okumadan da ayırt edilsin diye kesik kesik çizilir
## (dolu - boş - dolu). Kapalıyken düz ColorRect gibi.

const SEGMENT: float = 6.0
const GAP: float = 4.0

var colour: Color = Color.WHITE
var patterned: bool = false

func _draw() -> void:
	if not patterned:
		draw_rect(Rect2(Vector2.ZERO, size), colour)
		return
	var y := 0.0
	while y < size.y:
		draw_rect(Rect2(0.0, y, size.x, minf(SEGMENT, size.y - y)), colour)
		y += SEGMENT + GAP

## Desenin kaç parça çizileceği (test için): düzde 1.
static func segment_count(height: float, is_patterned: bool) -> int:
	if not is_patterned or height <= 0.0:
		return 1
	return int(ceil(height / (SEGMENT + GAP)))
