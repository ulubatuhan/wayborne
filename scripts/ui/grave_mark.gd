class_name GraveMark
extends Control

## Düşenler sayfasında adın yanındaki mezar işareti (görev 9.11, onaylı taslak
## y_911_dusenler): defterin kenarına mürekkeple çizilmiş bir taş. Rütbe
## süslemeyle okunur, sembolle değil (dinî işaret yok, Art Rules):
## - kurucu: halkalı taş ve altında bir kaide - ad ondan geldi;
## - lider: halkalı taş - adı taşıdı;
## - yoldaş: taşın ortasında tek bir yatay çentik - adıyla anılan biri;
## - tayfa: yalın, biraz alçak taş.
## Çizim, yazı tipinden çevrilmez (Art Rules: UI'nin küçük işaretleri çizilir).

enum Rank { CREW, COMPANION, LEADER, FOUNDER }

const INK_WIDTH: float = 2.0
const ARC_SEGMENTS: int = 14

var rank: int = Rank.COMPANION
var ink: Color = ArtPalette.UI_TEXT_ON_PAGE

func setup(mark_rank: int, height: float) -> GraveMark:
	rank = mark_rank
	custom_minimum_size = Vector2(height * 0.9, height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self

## Taşın dış hattı: yuvarlak tepeli, düz tabanlı. Kapalı çokgen.
static func stone_outline(rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var radius := rect.size.x * 0.5
	var centre := Vector2(rect.position.x + radius, rect.position.y + radius)
	points.append(Vector2(rect.position.x, rect.end.y))
	for i in range(ARC_SEGMENTS + 1):
		var angle := PI + PI * float(i) / float(ARC_SEGMENTS)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	points.append(Vector2(rect.end.x, rect.end.y))
	points.append(points[0])
	return points

func _draw() -> void:
	var h := size.y
	var w := minf(size.x, h * 0.9)
	var stone_h := h * (0.74 if rank == Rank.CREW else 0.86)
	var stone_w := w * (0.46 if rank == Rank.CREW else 0.52)
	var x0 := (size.x - stone_w) * 0.5
	var base_y := h * 0.94
	var stone := Rect2(x0, base_y - stone_h, stone_w, stone_h)
	draw_polyline(stone_outline(stone), ink, INK_WIDTH, true)
	if rank == Rank.LEADER or rank == Rank.FOUNDER:
		var centre := stone.get_center()
		var ring := Vector2(stone_w * 0.82, stone_h * 0.62)
		_draw_ellipse(centre, ring, INK_WIDTH * 0.75)
	if rank != Rank.CREW:
		var mid := stone.position.y + stone_h * 0.52
		draw_line(Vector2(x0 + stone_w * 0.3, mid), Vector2(x0 + stone_w * 0.7, mid), ink, INK_WIDTH * 0.8, true)
	if rank == Rank.FOUNDER:
		var pad := stone_w * 0.45
		draw_line(Vector2(x0 - pad, base_y), Vector2(x0 + stone_w + pad, base_y), ink, INK_WIDTH * 1.4, true)

func _draw_ellipse(centre: Vector2, extent: Vector2, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		var angle := TAU * float(i) / 32.0
		points.append(centre + Vector2(cos(angle) * extent.x, sin(angle) * extent.y))
	draw_polyline(points, Color(ink, 0.8), width, true)

## Bir defter satırının rütbesi. `leaders` CaravanLedger.leader_generations().
static func rank_for(entry: Dictionary, leaders: Dictionary) -> int:
	if String(entry.get("kind", "")) == CaravanLedger.KIND_FOUNDER:
		return Rank.FOUNDER
	var id := String(entry.get("id", ""))
	if leaders.has(id if not id.is_empty() else "name:" + String(entry.get("name", ""))):
		return Rank.LEADER
	return Rank.CREW if id.is_empty() else Rank.COMPANION
