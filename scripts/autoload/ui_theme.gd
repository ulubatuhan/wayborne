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
