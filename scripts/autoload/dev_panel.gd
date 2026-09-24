extends Node

## F1 ile açılıp kapanan geliştirici menüsü. Autoload olduğu için sahne
## değişimlerinde kaybolmaz ve her ekranın üstünde açılabilir. Oyunu
## duraklatmaz; yalnızca CanvasLayer'ı gizler/gösterir. Nav.return_scene'e
## hiç dokunmadığı için bir hedefe geçince o ekranın geri tuşu, paneli
## açtığın yere (oyunun kendisine) döner.
##
## Bir sistemi test edilebilir hale getirmek için test_selector.gd'deki
## boş stringi ilgili sahnenin yoluyla değiştirmek yeterli.

const SELECTOR_SCENE_PATH: String = "res://scenes/ui/test_selector.tscn"

var _layer: CanvasLayer
var _panel: Control

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)

	var packed_scene: PackedScene = load(SELECTOR_SCENE_PATH)
	_panel = packed_scene.instantiate()
	_panel.visible = false
	_layer.add_child(_panel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		toggle_panel()

func toggle_panel() -> void:
	_panel.visible = not _panel.visible

func hide_panel() -> void:
	_panel.visible = false
