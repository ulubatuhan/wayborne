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

func _init() -> void:
	load(THEME_SCRIPT_PATH).install()

## Tam genişliğe gerilen düğme bir sekme değil, bir sıra: ciltli çerçeveyi
## (`RowButton`) kendiliğinden giyiyor. Sekmenin kıvrık kulağı ve dikişi
## 1000 piksele gerildiğinde çizgili bir şerit oluyordu (ölçüldü: Kervan
## Avlusu, geri tuşları). Ekranların tek tek hatırlaması gerekmesin diye
## karar burada, düğüm ağaca girerken veriliyor - `SceneInk`'in deseni.
## Kendi çeşidini ya da stil geçersiz kılmasını taşıyan düğmeye dokunulmuyor.
const ROW_BUTTON: StringName = &"RowButton"

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.get_class() != "Button":
		return
	var button := node as Button
	if button.theme_type_variation != &"" or button.has_theme_stylebox_override("normal"):
		return
	if is_wide_button(button):
		button.theme_type_variation = ROW_BUTTON

static func is_wide_button(button: Control) -> bool:
	var parent := button.get_parent()
	var flags := button.size_flags_horizontal
	if parent is VBoxContainer:
		return (flags & Control.SIZE_FILL) != 0
	if parent is HBoxContainer:
		return (flags & Control.SIZE_EXPAND) != 0
	return false
