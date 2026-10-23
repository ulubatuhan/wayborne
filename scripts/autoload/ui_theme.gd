extends Node

## Autoload: Waybook temasını oyunun ilk karesinden önce kurar.
##
## Tema kendisi `WaybookTheme`'de (scripts/ui/); burada yalnızca kurulum
## çağrısı var. Bilerek `class_name` ile anılmıyor - autoload'lar global
## sınıf önbelleği hazır olmadan ayrıştırılıyor (bkz. CLAUDE.md Autoload
## rule), o yüzden script `load()` ile çalışma anında çözülüyor.
##
## `_init`'te, `_ready`'de değil: autoload listesinin başında duruyor ve
## başka hiçbir düğüm (DevPanel'in gizli paneli dahil) kurulmadan tema
## hazır olmalı - kurulmuş bir kontrol tema değişikliğini sonradan
## görmeyebilir.

const THEME_SCRIPT_PATH: String = "res://scripts/ui/waybook_theme.gd"
## Düğmenin eldeki hissi (bkz. ButtonFeedback) - her düğmeye burada, aynı
## kapıdan takılıyor. `class_name` ile anılmıyor (autoload kuralı).
const FEEDBACK_SCRIPT_PATH: String = "res://scripts/ui/button_feedback.gd"
var _feedback_script: Script

func _init() -> void:
	load(THEME_SCRIPT_PATH).install()

const NAV_PATH: String = "res://scripts/world/nav.gd"
## Fare imleci (tools/cursor_art.py): ok her yerde, parlak tonu tıklanabilir bir şeyin
## üstünde. Ok proje ayarında da var (ilk kareden önce görünsün diye); parlak ton yalnızca
## buradan kurulabiliyor. Uç ikisinde de aynı pikselde.
const CURSOR_ARROW: String = "res://data/assets/ui/cursor/arrow.png"
const CURSOR_POINTER: String = "res://data/assets/ui/cursor/pointer.png"
const CURSOR_HOTSPOT: Vector2 = Vector2(3, 2)

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	install_cursor()

static func install_cursor() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not ResourceLoader.exists(CURSOR_ARROW) or not ResourceLoader.exists(CURSOR_POINTER):
		return
	Input.set_custom_mouse_cursor(load(CURSOR_ARROW), Input.CURSOR_ARROW, CURSOR_HOTSPOT)
	Input.set_custom_mouse_cursor(load(CURSOR_POINTER), Input.CURSOR_POINTING_HAND, CURSOR_HOTSPOT)

## Esc her alt ekrandan bir üst ekrana döner (görev Y-H04): ekranların
## çoğunun yalnızca bir geri düğmesi vardı, klavyede sıkışılıyordu. Kendi Esc'ini
## işleyen ekran ve paneller (`_input`) olayı zaten tüketiyor, buraya düşen
## yalnızca sahipsiz olan. Kökler (şehir, merkez, menü) ve yol kendi çıkışını taşır.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var nav = load(NAV_PATH)
	if not esc_exits(scene.scene_file_path, nav.is_root(scene.scene_file_path), nav.depth(), nav.JOURNEY):
		return
	get_viewport().set_input_as_handled()
	var ink := get_node_or_null("/root/SceneInk")
	if ink != null:
		ink.go(nav.back())

## Saf karar: Esc bu ekranda geri götürür mü. Kök olmayan, yolun kendisi
## olmayan ve geri dönülecek bir yığını olan her ekranda evet.
static func esc_exits(scene_path: String, is_root: bool, depth: int, journey_path: String) -> bool:
	return not scene_path.is_empty() and not is_root and scene_path != journey_path and depth > 0

## Her düğme aynı minimal kutuyu varsayılan temadan giyiyor; burada
## yalnızca temanın ulaşamadığı üç şey veriliyor: düğmenin eldeki hissi,
## üstündeyken imlecin parlak tonu ve sayı kutusundaki sayının ortalanması (`SpinBox.alignment` bir tema
## özelliği değil, düğümün kendi özelliği - `SceneInk`'in deseniyle, düğüm
## ağaca girerken bir kez, hiçbir ekran hatırlamak zorunda kalmadan).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		if _feedback_script == null:
			_feedback_script = load(FEEDBACK_SCRIPT_PATH)
		_feedback_script.attach(node)
		var button := node as BaseButton
		if button.mouse_default_cursor_shape == Control.CURSOR_ARROW:
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	elif node is SpinBox:
		(node as SpinBox).alignment = HORIZONTAL_ALIGNMENT_CENTER
