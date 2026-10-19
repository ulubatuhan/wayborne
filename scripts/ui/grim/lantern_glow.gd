class_name LanternGlow
extends Control

## Bir fenerin dağıttığı titrek ışık havuzu. Işık yalnızca fenerden gelir:
## ekranın geri kalanı karanlıkta kalsın diye bu bileşen *eklenen* (additive)
## bir katman, ortamı aydınlatan bir dolgu değil.

var radius: float = 260.0
var strength: float = 0.75
var _time: float = 0.0
var _redraw_wait: float = 0.0
var _seed: float = 0.0
var _tex: Texture2D

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

func setup(r: float, s: float, seed_value: float = 0.0) -> LanternGlow:
	radius = r
	strength = s
	_seed = seed_value
	custom_minimum_size = Vector2(r, r) * 2.0
	size = custom_minimum_size
	return self

func set_time(t: float) -> void:
	_time = t
	queue_redraw()

## Ortam animasyonu: zaman hep akar, ama görünmezken çizilmez ve en çok
## `NodeUtil.AMBIENT_REDRAW_HZ` kez çizilir (görev 5.1, O-8).
func _process(delta: float) -> void:
	_time += delta
	_redraw_wait = NodeUtil.ambient_redraw(self, _redraw_wait, delta)

## Alev titremesi: iki yavaş, bir hızlı dalga; asla sıfıra inmiyor.
static func flicker(t: float, seed_value: float) -> float:
	return 0.86 + 0.07 * sin(t * 2.3 + seed_value) + 0.05 * sin(t * 5.7 + seed_value * 1.7) \
		+ 0.02 * sin(t * 17.0 + seed_value * 3.1)

func _draw() -> void:
	if _tex == null:
		_tex = GrimTheme.texture("lantern_glow.png")
		if _tex == null:
			return
	var f := flicker(_time, _seed)
	var r := radius * (0.96 + 0.04 * f)
	var c := size * 0.5
	draw_texture_rect(_tex, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, strength * f))
