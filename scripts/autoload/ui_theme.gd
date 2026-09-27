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

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

## Her düğme aynı minimal kutuyu varsayılan temadan giyiyor; burada
## yalnızca temanın ulaşamadığı iki şey veriliyor: düğmenin eldeki hissi
## ve sayı kutusundaki sayının ortalanması (`SpinBox.alignment` bir tema
## özelliği değil, düğümün kendi özelliği - `SceneInk`'in deseniyle, düğüm
## ağaca girerken bir kez, hiçbir ekran hatırlamak zorunda kalmadan).
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		if _feedback_script == null:
			_feedback_script = load(FEEDBACK_SCRIPT_PATH)
		_feedback_script.attach(node)
	elif node is SpinBox:
		(node as SpinBox).alignment = HORIZONTAL_ALIGNMENT_CENTER
