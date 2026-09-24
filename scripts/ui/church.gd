extends Control

## Kilise: huy arındırmaya adanmış tek mekân. Taverna da aynı hizmeti
## verir (bir kadeh içip unutmak) ama daha pahalıya - burası ucuz, çünkü
## işin uzmanı (bkz. PurificationPanel, tavern.gd).
##
## Faz 17 PR-9: iki yaratılış efsanesinin evi. Şehir siluetinin hiçbir
## zaman bir ibadet simgesi taşımadığı bilerek kurulmuş bir kural (bkz.
## CLAUDE.md Art Rules'un cami/minare geri alımı - "Wayborne'un böyle bir
## kurumu yok, ufuktaki bir ibadet yeri oyunun kendi lore'unun dışından bir
## şey söyler"); o kural mimariye ait, metne değil - kilisenin **içindeki**
## bu ekran zaten var olan, salt metinsel bir mekân, oyuncu buraya kendi
## isteğiyle giriyor. İki efsane de tek bir kurumsal dine ait değil, iki
## ayrı sözlü gelenek (bkz. CultureCatalog: HIGHLAND ve FISHER'ın İnanç
## eğilimli olmasının gerekçesi) - kilise ikisini de anlatır, birini
## seçmez, tıpkı beş kültürün hiçbirinin oyunun "resmi" kültürü olmaması
## gibi.
const PURIFICATION_COST: int = 35

var _session: GameSession
var _purification_panel: PurificationPanel

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	$MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/InfoLabel.text = tr("UI_CHURCH_HINT")
	_session = GameState.get_session()
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)

	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = tr("UI_CITY_CHURCH") if location == null else tr("UI_CHURCH_TITLE_CITY") % location.location_name

	_purification_panel = PurificationPanel.new()
	_content.add_child(_purification_panel)
	_purification_panel.setup(_session, tr("UI_PURIFY_TRAIT"), PURIFICATION_COST)

	_build_myths()

	_session.wallet.balance_changed.connect(_on_wallet_changed)

## İki efsane kod içinde kuruluyor, `.tscn`'e elle iki `Label` eklemek
## yerine - `autowrap_mode` unutmak (bkz. CLAUDE.md Art Rules'un
## `TitleLabel`/`InfoLabel` tarihi) gerçek prose taşıyan her yeni label'da
## tekrar edebilecek bir hata, burada tek bir yardımcı fonksiyonun içine
## kapatılıyor.
func _build_myths() -> void:
	var heading := Label.new()
	heading.text = tr("UI_CHURCH_MYTHS_HEADING")
	heading.add_theme_font_size_override("font_size", 16)
	_content.add_child(heading)

	_add_myth_label(tr("MYTH_HIGHLAND_TITLE"), tr("MYTH_HIGHLAND_TEXT"))
	_add_myth_label(tr("MYTH_FISHER_TITLE"), tr("MYTH_FISHER_TEXT"))

func _add_myth_label(title_text: String, body_text: String) -> void:
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 14)
	_content.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	_content.add_child(body)

func _on_wallet_changed(_new_balance: int) -> void:
	_purification_panel.refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.back())
