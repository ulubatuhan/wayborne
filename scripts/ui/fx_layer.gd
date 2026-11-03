class_name FxLayer
extends Control

## Tek seferlik efektlerin oynatıldığı havuzlu katman: sıçrama, toz, iz,
## nefes buharı. Perde (yağmur/kar/sis) burada değil - o ekranı döşüyor,
## bkz. `WeatherCurtain`.
##
## **Efekt yere bırakılır, ekrana değil.** Yol ekranında kervan sabit
## durur, dünya altından kayar; bir ayak izi ekran koordinatında
## tutulsaydı kervanla birlikte kayar, yani iz hep ayağın altında
## kalırdı - kayan dikdörtgen kusurunun tam kendisi (bkz. Art Rules).
## Her efekt bırakıldığı andaki **dünya x'ini** saklıyor ve ekrandaki
## yeri her karede aradaki farktan çıkıyor; böylece bırakıldığı toprak
## parçasıyla birlikte geriye akıyor.
##
## Havuz sınırlı: yağmurda her ayak, her toynak ve her tekerlek efekt
## bıraktığı için sınırsız liste bir seferde yüzlerce çizim demek olurdu.
## Dolunca en eski düşer - en yenisi her zaman görünür.

const MAX_LIVE: int = 96
## Yolun kendi düzlemi: kervanın bastığı zemin dünya hızının birebiri.
const GROUND_PARALLAX: float = 1.0

var world_x: float = 0.0
var px_per_metre: float = 60.0

var _live: Array[Dictionary] = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _ready() -> void:
	# `RoadCaravan`'ın kuralı: ön ayar boyu *bir sonraki* yerleşim
	# geçişinde veriyor, o ana kadar boy sıfır. Sıfır boyla efektler ekran
	# dışı sayılıp hiç çizilmiyordu.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

## Zeminin kaydığı mesafe. Yol ekranı her karede kendi `_world_x`'ini
## veriyor; efektler aradaki farkla geriye akıyor.
func set_world_x(value: float) -> void:
	if not is_equal_approx(value, world_x):
		world_x = value
		queue_redraw()

func set_px_per_metre(value: float) -> void:
	px_per_metre = maxf(1.0, value)

func live_count() -> int:
	return _live.size()

func clear_all() -> void:
	_live.clear()
	queue_redraw()

## Bir efekti bırakır. `at` ekran koordinatı (efektin mili oraya oturur),
## `parallax` zeminin hangi düzleminde durduğu.
func emit(
	id: String, at: Vector2, scale: float = 1.0, flip: bool = false,
	tint: Color = Color.WHITE, parallax: float = GROUND_PARALLAX
) -> void:
	if not FxCatalog.has(id):
		return
	var life := FxCatalog.duration(id)
	if life <= 0.0:
		return
	if _live.size() >= MAX_LIVE:
		_live.remove_at(0)
	_live.append({
		"id": id, "x": at.x, "y": at.y, "wx": world_x, "t": 0.0,
		"life": life, "flip": flip and FxCatalog.can_flip(id),
		"tint": tint, "scale": scale, "parallax": parallax,
	})
	queue_redraw()

func _process(delta: float) -> void:
	if _live.is_empty():
		return
	var kept: Array[Dictionary] = []
	for fx in _live:
		fx.t = float(fx.t) + delta
		if float(fx.t) < float(fx.life):
			kept.append(fx)
	_live = kept
	queue_redraw()

func _draw() -> void:
	for fx in _live:
		var id: String = fx.id
		var drift := (world_x - float(fx.wx)) * float(fx.parallax)
		var anchor := Vector2(float(fx.x) - drift, float(fx.y))
		# Ekranın dışına çıkanı çizme: havuzda kalabilir, çizim bedeli yok.
		if anchor.x < -size.x * 0.5 or anchor.x > size.x * 1.5:
			continue
		var rect := FxCatalog.rect_for(id, anchor, px_per_metre, float(fx.scale))
		FxCatalog.draw_frame(
			self, id, rect, FxCatalog.frame_at(id, float(fx.t)),
			fx.tint, bool(fx.flip)
		)
