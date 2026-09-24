class_name CombatBackdrop
extends Control

## Savaşın geçtiği yer. Arkasında hiçbir şey yoktu - figürler boşlukta
## duruyordu ve bu, savaşı bir tabloya benzetiyordu. Darkest Dungeon'ın
## havası büyük ölçüde *ortamdan* gelir: karanlık bir kuyu, altta bir
## zemin çizgisi, ortadan gelen meşale ışığı ve kenarlara doğru kararan
## bir vinyet.
##
## Tamamı `_draw()` ile çiziliyor, varlık dosyası yok. Sprite/doku geldiğinde
## bu katman bir `TextureRect`'in arkasına geçer ya da yerini ona bırakır;
## üstündeki mevki kutuları hiç değişmez.

## Gün ışığı değil meşale ışığı: ton sıcak, doygunluk düşük.
const SKY_TOP: Color = Color(0.055, 0.050, 0.060)
const SKY_BOTTOM: Color = Color(0.135, 0.115, 0.105)
const FLOOR_NEAR: Color = Color(0.165, 0.140, 0.120)
const FLOOR_FAR: Color = Color(0.085, 0.075, 0.070)
const TORCH: Color = Color(0.95, 0.66, 0.32)

## Zeminin başladığı yer (yüksekliğin oranı). Figürlerin ayakları bu
## çizginin biraz üstüne oturuyor.
## İlk denemede 0.62'ydi ve figürler dibe otururken üstte kocaman boş bir
## turuncu alan kalıyordu. Ufuk figürlerin ayak hizasına yakın olmalı.
const HORIZON: float = 0.46

## Işık havuzunun yarıçapı, **yüksekliğin** oranı. Genişliğe bağlıyken
## geniş ekranda 870 piksellik bir turuncu küre oluyor ve sahneyi yutuyordu;
## meşale ışığı zeminde bir havuz olmalı, bir gün doğumu değil.
const POOL_RADIUS: float = 0.85
## Havuzun en parlak noktasının şiddeti. 0.085'ti ve 22 halka üst üste
## binince ortası düpedüz turuncuydu.
const POOL_STRENGTH: float = 0.035

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var box := size
	if box.x <= 8.0 or box.y <= 8.0:
		return

	_draw_vertical_band(Rect2(Vector2.ZERO, Vector2(box.x, box.y * HORIZON)), SKY_TOP, SKY_BOTTOM)
	_draw_vertical_band(
		Rect2(Vector2(0.0, box.y * HORIZON), Vector2(box.x, box.y * (1.0 - HORIZON))),
		FLOOR_FAR, FLOOR_NEAR
	)
	_draw_horizon_line(box)
	_draw_torch_pool(box)
	_draw_floor_seams(box)
	_draw_vignette(box)

## Godot'un `_draw()`'unda hazır gradyan yok; ince şeritlerle kuruyoruz.
## 48 şerit gözle bant vermiyor ve kare başına bir kez değil, yalnızca
## yeniden çizimde koşuyor.
func _draw_vertical_band(area: Rect2, top: Color, bottom: Color) -> void:
	var steps := 48
	var step_h := area.size.y / float(steps)
	for index in steps:
		var ratio := float(index) / float(steps - 1)
		draw_rect(
			Rect2(
				Vector2(area.position.x, area.position.y + step_h * float(index)),
				Vector2(area.size.x, step_h + 1.0)
			),
			top.lerp(bottom, ratio), true
		)

## Ufuk: zeminin başladığı yerde ince bir aydınlık çizgi. Derinlik hissini
## tek başına bu satır taşıyor.
func _draw_horizon_line(box: Vector2) -> void:
	var y := box.y * HORIZON
	draw_line(Vector2(0.0, y), Vector2(box.x, y), Color(0.42, 0.33, 0.24, 0.55), 2.0)
	draw_line(
		Vector2(0.0, y + 2.0), Vector2(box.x, y + 2.0),
		Color(0.0, 0.0, 0.0, 0.35), 3.0
	)

## Ortadan gelen meşale ışığı: eşmerkezli halkalar, dışa doğru saydamlaşan.
func _draw_torch_pool(box: Vector2) -> void:
	# Havuz zeminde ve basık: dikeyde ezilmiş bir elips, yuvarlak bir küre
	# değil. Işık yerden yansıyor.
	var centre := Vector2(box.x * 0.5, box.y * 0.86)
	var max_r := box.y * POOL_RADIUS
	var rings := 18
	for index in range(rings, 0, -1):
		var ratio := float(index) / float(rings)
		var alpha := (1.0 - ratio) * POOL_STRENGTH
		_draw_ellipse(
			centre, Vector2(max_r * ratio * 1.9, max_r * ratio * 0.62),
			Color(TORCH.r, TORCH.g, TORCH.b, alpha)
		)

func _draw_ellipse(centre: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 26:
		var angle := TAU * float(index) / 26.0
		points.append(centre + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

## Zemin dokusu: ufka doğru daralan birkaç taş çizgisi. Düz bir renk
## zemin "zemin" gibi durmuyordu.
func _draw_floor_seams(box: Vector2) -> void:
	var top := box.y * HORIZON
	var rows := 6
	for index in rows:
		var ratio := pow(float(index + 1) / float(rows), 1.7)
		var y := top + (box.y - top) * ratio
		var inset := box.x * 0.5 * (1.0 - ratio) * 0.55
		draw_line(
			Vector2(inset, y), Vector2(box.x - inset, y),
			Color(0.0, 0.0, 0.0, 0.16), 1.5
		)

## Vinyet: kenarlardan içe doğru kararma. Dikdörtgen çerçeveler halinde,
## radyal maske için doku gerekmesin diye.
func _draw_vignette(box: Vector2) -> void:
	var layers := 14
	for index in layers:
		var ratio := float(index) / float(layers)
		var inset := box.x * 0.055 * ratio
		var inset_y := box.y * 0.075 * ratio
		var alpha := 0.055 * (1.0 - ratio)
		draw_rect(
			Rect2(Vector2(inset, inset_y), box - Vector2(inset, inset_y) * 2.0),
			Color(0.0, 0.0, 0.0, alpha), false, maxf(2.0, box.x * 0.012)
		)
