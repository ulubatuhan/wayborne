extends Control

## Ana menüden açılan tek ayar ekranı - şimdilik dil seçimi (eskiden ana
## menüde duruyordu, bkz. main_menu.gd). Yalnızca ana menüden açıldığı
## için geri tuşu gezinme yığınını izler ve açıldığı yere
## döner (bkz. character.gd'nin aynı deseni, CLAUDE.md World Navigation
## Rules).
## Dil listesi burada tutulmuyor: tek doğruluk kaynağı UserSettings.SUPPORTED
## (bkz. o dosyanın başlığı). Yeni bir dil eklendiğinde bu ekran hiç
## değişmeden onu göstermeye başlar.
var _locale_codes: Array = []

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _language_label: Label = $MarginContainer/VBoxContainer/LanguageRow/LanguageLabel
@onready var _language_button: OptionButton = $MarginContainer/VBoxContainer/LanguageRow/LanguageButton
@onready var _music_label: Label = $MarginContainer/VBoxContainer/MusicRow/MusicLabel
@onready var _music_slider: HSlider = $MarginContainer/VBoxContainer/MusicRow/MusicSlider
@onready var _music_value: Label = $MarginContainer/VBoxContainer/MusicRow/MusicValueLabel
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_setup_language_selector()
	_setup_music_slider()

## Ses seviyesi **anında** uygulanıyor, "Uygula" tuşu yok: oyuncu sesi
## ayarlarken duyduğu şeyi ayarlıyor olmalı. `AudioManager` değeri
## UserSettings üzerinden diske de yazıyor, o yüzden ayrıca kaydetmek
## gerekmiyor.
func _setup_music_slider() -> void:
	_music_slider.value = AudioManager.get_music_volume()
	_music_slider.value_changed.connect(_on_music_volume_changed)
	_refresh_music_value()

func _on_music_volume_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	_refresh_music_value()

func _refresh_music_value() -> void:
	_music_value.text = "%d%%" % roundi(_music_slider.value * 100.0)

func _setup_language_selector() -> void:
	_locale_codes = UserSettings.get_locale_codes()
	var locale_names: Array = UserSettings.get_locale_names()
	for i in range(_locale_codes.size()):
		_language_button.add_item(_readable_locale_name(str(locale_names[i]), str(_locale_codes[i])), i)

	# Tam kod aranıyor, ilk iki harf değil: pt_BR ile pt aynı şey değil.
	var selected := _locale_codes.find(TranslationServer.get_locale())
	_language_button.select(maxi(selected, 0))

	_language_button.item_selected.connect(_on_language_selected)
	_refresh_texts()

## **Bir dilin adı okunamıyorsa o dil seçilemez.**
##
## Dil adları bilerek kendi dillerinde yazılı (bkz. UserSettings.SUPPORTED):
## oyuncunun aradığı şey "Chinese" değil "简体中文". Ama varsayılan font CJK
## taşımıyor, yani Çince ve Japonca satırları ekranda boş kutu olarak
## çıkıyordu - kuralın engellemeye çalıştığı şeyin ta kendisi, bu sefer
## fontun eliyle. Font kapsamı taraması (bkz. test_localization.gd) bunu
## yakaladı.
##
## Çözüm dil adını Latinceye çevirmek *değil*: adın yanına dil kodu
## ekleniyor, yalnızca ad çizilemiyorsa. "zh_CN" en azından aranabilir bir
## şey; ad çizilebildiği gün (CJK taşıyan bir font geldiğinde) ek
## kendiliğinden kayboluyor.
func _readable_locale_name(locale_name: String, code: String) -> String:
	var font := ThemeDB.fallback_font
	if font == null:
		return locale_name
	for index in locale_name.length():
		if not font.has_char(locale_name.unicode_at(index)):
			return "%s (%s)" % [locale_name, code]
	return locale_name

func _on_language_selected(index: int) -> void:
	if index < 0 or index >= _locale_codes.size():
		return
	# UserSettings hem uygular hem user://settings.cfg'ye yazar - seçim
	# oyunu kapatınca kaybolmasın.
	UserSettings.set_locale(str(_locale_codes[index]))
	_refresh_texts()

func _refresh_texts() -> void:
	_title_label.text = tr("UI_SETTINGS")
	_language_label.text = tr("UI_LANGUAGE")
	_music_label.text = tr("UI_MUSIC_VOLUME")
	_back_button.text = tr("UI_BACK_TO_MENU")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.back())
