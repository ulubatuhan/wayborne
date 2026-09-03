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
const TOPICS: Array[Dictionary] = [
	{
		"title": "Stres",
		"text": "Moral her seferde sıfırdan başlar, ama stres kervanla \
birlikte kalıcı olarak birikir - yalnızca şehirde dinlenmek ya da yolda \
kamp kurmak azaltır. Çok gerilen bir yoldaş şehre varışta bir huy \
kazanabilir, hatta kervandan ayrılabilir.",
	},
	{
		"title": "Görev",
		"text": "Parti üyelerine Muhafız, İzci, Levazımcı, Arabacı, Tellal \
ya da Otacı gibi bir kervan görevi ver - Parti ekranından. Sınıfıyla \
uyuşan biri o görevi daha iyi yapar; boş bırakılan bir görev asla ceza \
getirmez.",
	},
	{
		"title": "Huy",
		"text": "Her karakterin en fazla üç huyu olabilir - kimi bir \
erdem, kimi bir zaaf. Yeni kazanılmış (taze) bir huy Kilise'de ya da \
Taverna'da arındırılabilir; kökleşmiş bir huya artık dokunulamaz.",
	},
	{
		"title": "Ekipman",
		"text": "Silah ve zırhı Kervan Avlusu'ndaki Demirci'den satın al; \
yüzük ve kolye gibi tılsımları yolda bulursun. Karakter ekranından tak \
ya da çıkar.",
	},
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
	title.text = "Kervana Hoş Geldin"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	for topic in TOPICS:
		var topic_title := Label.new()
		topic_title.text = topic.title
		topic_title.add_theme_font_size_override("font_size", 15)
		vbox.add_child(topic_title)

		var topic_text := Label.new()
		topic_text.text = topic.text
		topic_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(topic_text)

	var dismiss_button := Button.new()
	dismiss_button.text = "Anladım, Devam Et"
	dismiss_button.pressed.connect(_on_dismiss_pressed)
	vbox.add_child(dismiss_button)

func _on_dismiss_pressed() -> void:
	dismissed.emit()
	queue_free()
