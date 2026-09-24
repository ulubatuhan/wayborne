extends CanvasLayer

## Autoload: sahneler arası mürekkep geçişi. Oyunun bütün gezinmesi
## `change_scene_to_file()` (bkz. World Navigation Rules) ve her biri ekranı
## tek karede kesiyordu - defterin bir sayfasından ötekine atlamak gibi
## değil, projektörün slaytı değiştirmesi gibi. Burada yeni sahne her
## seferinde mürekkepten (koyu zeminden) belirerek geliyor.
##
## Çağıran yok: katman `current_scene`'in değiştiğini kendisi görüyor. Her
## ekranın geçişi ayrı ayrı çağırması gerekseydi, bir ekran eninde sonunda
## unuturdu - `_refresh_modal`'ın "görünürlüğü içerikten oku" kuralıyla aynı
## gerekçe.
##
## Varış anı daha uzun tutuluyor (`hold_next`): yoldan şehre girmek oyunun
## "vardık" dediği tek yer (bkz. Audio Rules'un crossfade gerekçesi).
##
## `class_name` anmıyor (autoload kuralı); palet `load()` ile okunuyor.

const PALETTE_PATH: String = "res://scripts/ui/art_palette.gd"
const FADE_SECONDS: float = 0.45
const LAYER: int = 120

var _ink: ColorRect
var _last_scene_id: int = 0
var _hold_seconds: float = 0.0
var _tween: Tween

func _ready() -> void:
	layer = LAYER
	_ink = ColorRect.new()
	_ink.color = load(PALETTE_PATH).INK
	_ink.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.modulate.a = 0.0
	add_child(_ink)
	var scene := get_tree().current_scene
	_last_scene_id = scene.get_instance_id() if scene != null else 0

## Bir sonraki sahne mürekkepte bu kadar daha beklesin (şehre varış).
func hold_next(seconds: float) -> void:
	_hold_seconds = maxf(_hold_seconds, seconds)

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_id := scene.get_instance_id() if scene != null else 0
	if scene_id == _last_scene_id:
		return
	_last_scene_id = scene_id
	if scene_id != 0:
		_reveal()

func _reveal() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	# CanvasLayer'ın ColorRect'i pencere boyuna çapa ile bağlı değil; her
	# geçişte ekranın o anki boyunu alıyor (bkz. Art Rules'un çapa tuzağı).
	_ink.size = get_viewport().get_visible_rect().size
	_ink.modulate.a = 1.0
	_tween = create_tween()
	if _hold_seconds > 0.0:
		_tween.tween_interval(_hold_seconds)
		_hold_seconds = 0.0
	_tween.tween_property(_ink, "modulate:a", 0.0, FADE_SECONDS)
