class_name PropNode
extends Node2D

## Dünyaya konmuş tek bir render edilmiş eşya (PropArt). Düğümün konumu
## eşyanın yere bastığı orta nokta; `k` oyun pikseli / render pikseli.
##
## İki hareket var, ikisi de eşyanın kendi katmanı: değirmen kanadı döner
## (`spin_*`), kapı kanadı yukarı kalkar (`open_*`). Dönen ya da kalkan bir
## şey yoksa düğüm hiç işlem yapmıyor.

## Duvarın *arkasında* kalan katmanlar: kapı kanadı duvarın kalınlığının
## içinde, kalktığında duvarın arkasına giriyor.
const BEHIND := PropArt.BEHIND_LAYERS

var prop_id: String = ""
var k: float = 1.0
var tint: Color = Color.WHITE
var flip: bool = false
var spin_layer: String = ""
var spin_pivot: String = ""
## Saniyede radyan.
var spin_speed: float = 0.0
## Kapının açıklığı 0..1 ve hedefi; 1'de kanat kendi boyunun bu payı kadar kalkıyor.
var open_amount: float = 0.0
var open_target: float = 0.0
const OPEN_SPEED: float = 1.6

var _angle: float = 0.0
## Yerleşim kapısı kesiti (`gate_<id>`): sur malzemesi, pus ve gece payı
## GateArt'a gider - arkadaki şehir, geçit ve kanat orada çiziliyor.
var gate_kind: String = ""
var haze: Color = Color(0.8, 0.84, 0.9)
var night: float = 0.0

func setup(id: String, scale_k: float, colour: Color = Color.WHITE, mirrored: bool = false) -> void:
	prop_id = id
	k = scale_k
	tint = colour
	flip = mirrored
	set_process(spin_speed != 0.0)
	queue_redraw()

func set_spin(layer: String, pivot_name: String, speed: float, start_angle: float = 0.0) -> void:
	spin_layer = layer
	spin_pivot = pivot_name
	spin_speed = speed
	_angle = start_angle
	set_process(true)

func set_open_target(value: float) -> void:
	open_target = clampf(value, 0.0, 1.0)
	if not is_equal_approx(open_target, open_amount):
		set_process(true)

func bounds() -> Rect2:
	var r := PropArt.bounds(prop_id, Vector2.ZERO, k, flip)
	return Rect2(r.position + position, r.size)

func layer_bounds(layer: String) -> Rect2:
	var r := PropArt.layer_rect(prop_id, layer, Vector2.ZERO, k, flip)
	return Rect2(r.position + position, r.size)

func _process(delta: float) -> void:
	var busy := false
	if spin_speed != 0.0:
		_angle = fmod(_angle + spin_speed * delta, TAU)
		busy = true
	if not is_equal_approx(open_amount, open_target):
		open_amount = move_toward(open_amount, open_target, OPEN_SPEED * delta)
		busy = true
	if not busy:
		set_process(false)
	queue_redraw()

func is_settlement_gate() -> bool:
	return not gate_kind.is_empty() and (PropArt.has_layer(prop_id, "town") or GateArt.has_door(prop_id))

func _draw() -> void:
	if not PropArt.has(prop_id):
		return
	if is_settlement_gate():
		GateArt.draw(self, prop_id, Vector2.ZERO, k, tint, haze, open_amount, night, gate_kind)
		return
	var layers: Array = PropArt.info(prop_id).get("layers", {}).keys()
	for layer in layers:
		if layer in BEHIND:
			_draw_one(layer)
	for layer in layers:
		if not layer in BEHIND:
			_draw_one(layer)

func _draw_one(layer: String) -> void:
	if layer == spin_layer and spin_pivot != "":
		PropArt.draw_layer_rotated(self, prop_id, layer, Vector2.ZERO, k, spin_pivot, _angle, tint, flip)
	elif layer == "gate":
		PropArt.draw_gate_leaf(self, prop_id, Vector2.ZERO, k, tint, open_amount, flip)
	else:
		PropArt.draw_layer(self, prop_id, layer, Vector2.ZERO, k, tint, flip)
