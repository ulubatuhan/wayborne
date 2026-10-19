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
var _motion_toggle: CheckButton

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
	_setup_motion_toggle()
	_setup_credits()

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

## Kod içinde kuruluyor ve geri tuşunun hemen üstüne yerleşiyor - sahne
## dosyasında ayrı bir satır açmak, bir onay kutusu için bir düğüm yolu
## daha demekti.
func _setup_motion_toggle() -> void:
	_motion_toggle = CheckButton.new()
	_motion_toggle.button_pressed = UserSettings.reduce_motion
	_motion_toggle.toggled.connect(UserSettings.set_reduce_motion)
	var column := _back_button.get_parent()
	column.add_child(_motion_toggle)
	column.move_child(_motion_toggle, _back_button.get_index())
	_setup_access(column)
	_refresh_texts()

## Erişilebilirlik ve oynanış (görev Y-H07): metin boyu, desenli şeritler,
## otomatik duraklama. Geri tuşunun üstünde, hareket ayarının altında.
var _text_size: OptionButton
var _text_size_label: Label
var _pattern_toggle: CheckButton
var _pause_toggle: CheckButton

func _setup_access(column: Node) -> void:
	var row := HBoxContainer.new()
	_text_size_label = Label.new()
	row.add_child(_text_size_label)
	_text_size = OptionButton.new()
	for scale in UserSettings.TEXT_SCALES:
		_text_size.add_item("%d%%" % roundi(scale * 100.0))
	_text_size.select(UserSettings.text_scale_index)
	_text_size.item_selected.connect(func(index: int) -> void:
		UserSettings.set_access("text_scale", index)
		WaybookTheme.apply_text_scale(UserSettings.get_text_scale()))
	row.add_child(_text_size)
	_pattern_toggle = CheckButton.new()
	_pattern_toggle.button_pressed = UserSettings.pattern_stripes
	_pattern_toggle.toggled.connect(func(on: bool) -> void: UserSettings.set_access("pattern_stripes", on))
	_pause_toggle = CheckButton.new()
	_pause_toggle.button_pressed = UserSettings.auto_pause_events
	_pause_toggle.toggled.connect(func(on: bool) -> void: UserSettings.set_access("auto_pause_events", on))
	for node in [row, _pattern_toggle, _pause_toggle]:
		column.add_child(node)
		column.move_child(node, _back_button.get_index())

## Emeği Geçenler: CC-BY giysilerin yazarları oyunda anılmak zorunda
## (bkz. Credits). Uzun liste kendi kaydırma kutusunda - geri tuşu
## dışarıda kalıyor (World Navigation Rules).
func _setup_credits() -> void:
	var column := _back_button.get_parent()
	var title := Label.new()
	title.text = tr("UI_CREDITS")
	column.add_child(title)
	column.move_child(title, _back_button.get_index())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := Label.new()
	body.text = Credits.text()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.modulate = ArtPalette.UI_TEXT_DIM
	scroll.add_child(body)
	column.add_child(scroll)
	column.move_child(scroll, _back_button.get_index())

func _setup_language_selector() -> void:
	_locale_codes = UserSettings.get_locale_codes()
	var locale_names: Array = UserSettings.get_locale_names()
	var locale_complete: Array = UserSettings.get_locale_completeness()
	for i in range(_locale_codes.size()):
		var label := _readable_locale_name(str(locale_names[i]), str(_locale_codes[i]))
		# Dokuz dilin CSV sütunu hâlâ boş - seçmek sessizce İngilizce
		# gösteriyordu, oyuncuya hiçbir uyarı vermeden (P0 - bkz. CLAUDE.md'nin
		# "Localization — Settings language list" maddesi). Eksik olan her
		# dilin adının yanına bunu söyleyen bir ek geliyor.
		if i < locale_complete.size() and not bool(locale_complete[i]):
			label = "%s %s" % [label, tr("UI_LANGUAGE_UNTRANSLATED_SUFFIX")]
		_language_button.add_item(label, i)

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
## şey; ad çizilebildiğinde (kitap yüzünün CJK yedekleri geldi) ek
## kendiliğinden kayboluyor.
func _readable_locale_name(locale_name: String, code: String) -> String:
	var font := ThemeDB.fallback_font
	if font == null:
		return locale_name
	for index in locale_name.length():
		if not _chain_has_char(font, locale_name.unicode_at(index)):
			return "%s (%s)" % [locale_name, code]
	return locale_name

## Kitap yüzü CJK'yı kendisi değil yedekleriyle çiziyor; yalnızca ana fonta
## bakmak her CJK adına gereksiz yere kod eklerdi.
func _chain_has_char(font: Font, code: int) -> bool:
	if font.has_char(code):
		return true
	for fallback in font.fallbacks:
		if _chain_has_char(fallback, code):
			return true
	return false

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
	if _motion_toggle != null:
		_motion_toggle.text = tr("UI_SETTINGS_REDUCE_MOTION")
	if _pattern_toggle != null:
		_text_size_label.text = tr("UI_SETTINGS_TEXT_SIZE")
		_pattern_toggle.text = tr("UI_SETTINGS_PATTERN_STRIPES")
		_pause_toggle.text = tr("UI_SETTINGS_AUTO_PAUSE")
	_back_button.text = tr("UI_BACK_TO_MENU")

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
