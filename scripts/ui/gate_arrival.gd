class_name GateArrival
extends CanvasLayer

## Şehre gerçek bir girişte (yolun sonu ya da hub'ın kapısı; bkz.
## Nav.city_gate_opening) şehrin kendi kapısı bir an ekranı kaplar, sonra
## şehir arkasından belirir (görev 12.2a, onaylı: her yerleşimin kapısı kendi
## kasabasından türetilmiş bir render, tools/ui_scenes/settlement_gates.py).
## Kervan şehre girmez, kapının önünde durur: bu an onun resmi.
## Tıklamak ya da bir tuş geçer; Reduce Motion açıkken solmadan kısa durur.
## Gündüz evresinde gündüz kapısı, akşam ve gecede meşaleli gece kapısı.

const DIR: String = "res://data/assets/ui/gates/gate_%s/"
const HOLD_SECONDS: float = 1.6
const FADE_SECONDS: float = 0.9
const REDUCED_HOLD_SECONDS: float = 0.8

var _rect: TextureRect
var _left: float = 0.0
var _fading: bool = false

## Kapının resmi: gündüzse gündüz sürümü (varsa), değilse taban (gece).
static func picture_path(city_id: String, hour: float) -> String:
	var base := DIR % city_id
	var phase := JourneyClock.phase_for_hour(hour)
	var day := phase in [JourneyClock.Phase.DAWN, JourneyClock.Phase.MORNING, JourneyClock.Phase.NOON, JourneyClock.Phase.AFTERNOON]
	if day and (ResourceLoader.exists(base + "background_day.jpg") or FileAccess.file_exists(base + "background_day.jpg")):
		return base + "background_day.jpg"
	return base + "background.jpg"

static func available(city_id: String) -> bool:
	var path := (DIR % city_id) + "background.jpg"
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

func setup(city_id: String, hour: float) -> GateArrival:
	layer = 70
	_rect = TextureRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_rect.texture = TextureLoader.load_any(picture_path(city_id, hour))
	_rect.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_skip())
	add_child(_rect)
	return self

func _ready() -> void:
	_left = REDUCED_HOLD_SECONDS if NodeUtil.reduce_motion(_rect) else HOLD_SECONDS

func _process(delta: float) -> void:
	if _fading:
		return
	_left -= delta
	if _left <= 0.0:
		_skip()

## Esc (ui_cancel) ya da herhangi bir tuş geçer; girdi yutulur, alttaki şehre ulaşmaz.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed):
		get_viewport().set_input_as_handled()
		_skip()

func _skip() -> void:
	if _fading:
		return
	_fading = true
	if NodeUtil.reduce_motion(_rect):
		queue_free()
		return
	var tween := _rect.create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, FADE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(queue_free)
