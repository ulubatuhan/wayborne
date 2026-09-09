class_name OnboardingPanel
extends CanvasLayer

## Karakter oluşturmadan sonraki ilk şehir varışında bir kereye mahsus
## gösterilen atlanabilir ipucu katmanı - stres/görev/huy/ekipman
## sistemlerini yeni oyuncuya tanıtır (bkz. city_map.gd, GameSession.
## ONBOARDING_FLAG). PulseBar gibi sahnesiz: .new() ile kurulur, tek
## kullanımlık olduğu için _ensure_built() yerine doğrudan _ready()'de
## inşa edilir.

signal dismissed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const PANEL_SIZE: Vector2 = Vector2(520, 420)
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
	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.size = PANEL_SIZE
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position -= PANEL_SIZE * 0.5
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_ONBOARD_TITLE")
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	for topic in TOPIC_KEYS:
		var keys: Array = topic
		var topic_title := Label.new()
		topic_title.text = tr(String(keys[0]))
		topic_title.add_theme_font_size_override("font_size", 15)
		vbox.add_child(topic_title)

		var topic_text := Label.new()
		topic_text.text = tr(String(keys[1]))
		topic_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(topic_text)

	var dismiss_button := Button.new()
	dismiss_button.text = tr("UI_ONBOARD_DISMISS")
	dismiss_button.pressed.connect(_on_dismiss_pressed)
	vbox.add_child(dismiss_button)

func _on_dismiss_pressed() -> void:
	dismissed.emit()
	queue_free()
