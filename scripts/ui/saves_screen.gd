extends Control

## Ana menüden açılan Kayıtlar ekranı: `SaveSlotsPanel`'i tek başına
## gösteren ince bir çerçeve. İçerik bir `ScrollContainer` içinde, geri
## tuşu onun **dışında** - yuva sayısı büyüdükçe tuş ekrandan taşmasın
## (bkz. World Navigation Rules'un kaydırma maddesi).
##
## Burada hiç "Buraya Kaydet" yok: ana menüde henüz canlı bir sefer
## yok, yalnızca var olan kayıtları yükleyip silmek anlamlı - `InGameMenu`
## içindeki aynı `SaveSlotsPanel` `can_save = true` ile açılıyor.

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _panel_holder: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/PanelHolder
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

var _panel: SaveSlotsPanel

func _ready() -> void:
	_title_label.text = tr("UI_SAVES_TITLE")
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)

	_panel = SaveSlotsPanel.new()
	_panel_holder.add_child(_panel)
	_panel.loaded.connect(_on_loaded)
	_panel.setup(false)

func _on_loaded(session) -> void:
	GameState.set_session(session)
	get_tree().change_scene_to_file(Nav.go_root(Nav.CITY_MAP))

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.back())
