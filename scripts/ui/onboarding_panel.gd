class_name OnboardingPanel
extends CanvasLayer

## Karakter oluşturmadan sonraki ilk şehir varışında bir kereye mahsus
## gösterilen atlanabilir ipucu katmanı - stres/görev/huy/ekipman
## sistemlerini yeni oyuncuya tanıtır (bkz. city_map.gd, GameSession.
## ONBOARDING_FLAG). PulseBar gibi sahnesiz: .new() ile kurulur, tek
## kullanımlık olduğu için _ensure_built() yerine doğrudan _ready()'de
## inşa edilir.
##
## Bu panel oyuncuyu bir kez ekranda kilitledi ve üç sebebi vardı, üçü de
## aynı cinsten - "içerik ekrandan taşarsa ne olur" sorusunun hiç
## sorulmamış olması:
##
## 1. Dört konunun sarmalanmış metni `PANEL_SIZE`'ın yüksekliğini aşıyordu.
##    `custom_minimum_size` bir *asgari*, tavan değil: panel büyüyor, kapat
##    tuşu görüntü alanının altına düşüyordu. İçerik artık bir
##    `ScrollContainer` içinde ve kapat tuşu onun **dışında** - ekranların
##    geri tuşuyla aynı kural (bkz. World Navigation Rules'un kaydırma
##    maddesi). Kural ekranlar için yazılmıştı, bu bir ekran değil bir
##    katman olduğu için kimse uygulamamıştı; taşma taşmadır.
## 2. Panel `PRESET_CENTER` ile ortalanıp `position -= PANEL_SIZE * 0.5`
##    ile kaydırılıyordu - yani ortalama *tahmin edilen* boya göre
##    yapılıyordu, gerçek boya göre değil. Panel tahminden uzun olunca
##    aşağıya taşıyordu. Artık `CenterContainer` ortalıyor: ne kadar
##    uzarsa uzasın kendi gerçek boyuna göre ortalanır.
## 3. `CanvasLayer` bir `Control` değil, o yüzden doğrudan çocuğuna
##    verilen anchor preset'inin ortalayacağı bir çerçeve yok. Katmanın
##    kökü artık tam ekran bir `Control`; arka perde ve ortalama onun
##    içinde yaşıyor.
##
## Ayrıca kapanmanın tek yolu tuş değil: perdeye tıklamak ve Esc de kapatır.

signal dismissed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.72)
const PANEL_BACKGROUND: Color = Color(0.11, 0.10, 0.09)
const PANEL_BORDER: Color = Color(0.45, 0.40, 0.32)

## Genişlik sabit, yükseklik **kaydırma alanının** payına bırakılmış:
## `ScrollContainer`'ın asgari boyu içeriğini saymaz (kaydırmanın anlamı
## bu), o yüzden panelin toplam boyu başlık + bu + tuş kadar kalır ve
## içerik ne kadar uzarsa uzasın 1080'lik tasarım alanını aşmaz.
const PANEL_WIDTH: float = 760.0
const SCROLL_HEIGHT: float = 460.0

## Konular yalnızca **anahtar** taşır, metin değil: `const` ifadesinin
## içinde `tr()` çağrılamaz (sabit ifade olmak zorunda) ve prose zaten
## çeviri dosyasında yaşamalı (bkz. CLAUDE.md Localization Rules).
## Metin _build() sırasında çözülüyor, yani panel açıldığı andaki dile
## göre görünüyor.
## Anahtarlar tam yazılıyor, çalışma anında birleştirilmiyor: birleştirilen
## bir anahtarı ne test_localization.gd'nin "tanımsız anahtar" taraması
## görebilir ne de bir çevirmen arayabilir.
const TOPIC_KEYS: Array[Array] = [
	["UI_ONBOARD_STRESS_TITLE", "UI_ONBOARD_STRESS_TEXT"],
	["UI_ONBOARD_DUTY_TITLE", "UI_ONBOARD_DUTY_TEXT"],
	["UI_ONBOARD_TRAIT_TITLE", "UI_ONBOARD_TRAIT_TEXT"],
	["UI_ONBOARD_EQUIPMENT_TITLE", "UI_ONBOARD_EQUIPMENT_TEXT"],
]

func _ready() -> void:
	layer = 50
	_build()

func _build() -> void:
	# Katmanın kökü tam ekran bir Control: anchor'ların ortalayacağı
	# çerçeveyi bu sağlıyor (bkz. yukarıdaki 3. madde). STOP filtresi
	# arkadaki şehir haritasının tıklamaları yemesini de engelliyor.
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(_on_backdrop_input)
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	# Arka plan açıkça opak: varsayılan tema şeffaf kalınca şehir haritası
	# metnin arasından okunuyordu, iki katman üst üste binmiş görünüyordu.
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_ONBOARD_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	# Konular kaydırılabilir alanda; kapat tuşu bunun dışında kalıyor, o
	# yüzden içerik ne kadar uzarsa uzasın tuş her zaman ekranda.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, SCROLL_HEIGHT)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var topics := VBoxContainer.new()
	topics.add_theme_constant_override("separation", 12)
	topics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(topics)

	for topic in TOPIC_KEYS:
		var keys: Array = topic
		var topic_title := Label.new()
		topic_title.text = tr(String(keys[0]))
		topic_title.add_theme_font_size_override("font_size", 15)
		topics.add_child(topic_title)

		var topic_text := Label.new()
		topic_text.text = tr(String(keys[1]))
		topic_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		topic_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		topics.add_child(topic_text)

	var dismiss_button := Button.new()
	dismiss_button.text = tr("UI_ONBOARD_DISMISS")
	dismiss_button.pressed.connect(_on_dismiss_pressed)
	vbox.add_child(dismiss_button)

## Perdeye tıklamak da kapatır: oyuncunun ilk refleksi kenara tıklamak
## oluyor ve hiçbir şey olmaması ekranı kilitlenmiş gösteriyordu.
func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_dismiss_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_dismiss_pressed()
		get_viewport().set_input_as_handled()

func _on_dismiss_pressed() -> void:
	dismissed.emit()
	queue_free()
