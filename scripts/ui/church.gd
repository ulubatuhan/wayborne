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
	WaybookTheme.fit_desk_workspace(self)
	$MarginContainer/VBoxContainer/ScrollContainer/ContentContainer/InfoLabel.text = tr("UI_CHURCH_HINT")
	_session = GameState.get_session()
	_back_button.text = Nav.back_label()
	_back_button.pressed.connect(_on_back_pressed)

	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = tr("UI_CITY_CHURCH") if location == null else tr("UI_CHURCH_TITLE_CITY") % location.location_name

	_purification_panel = PurificationPanel.new()
	_content.add_child(_purification_panel)
	_purification_panel.setup(_session, tr("UI_PURIFY_TRAIT"), PURIFICATION_COST)

	_build_doctor()
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

## Hekim (görev Y-C05): şehrin sınırlı ilaç stoğuyla dertleri iyileştirir.
## Stok yoksa düğme sebebiyle kilitli; iksir satan kervan stoğu artırır.
var _doctor_box: VBoxContainer

func _build_doctor() -> void:
	_doctor_box = VBoxContainer.new()
	_doctor_box.add_theme_constant_override("separation", 4)
	_content.add_child(_doctor_box)
	_refresh_doctor()

func _refresh_doctor() -> void:
	NodeUtil.clear_children(_doctor_box)
	var heading := Label.new()
	heading.text = tr("UI_DOCTOR_HEADING") % _session.market.get_medicine(_session.current_location_id)
	heading.add_theme_font_size_override("font_size", 16)
	_doctor_box.add_child(heading)
	var any := false
	for character in _session.get_party():
		for id in character.ailments:
			any = true
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var label := Label.new()
			label.text = tr("UI_DOCTOR_ROW") % [character.character_name, tr(String(CharacterData.AILMENTS[id]["key"])), int(character.ailments[id])]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var button := Button.new()
			var reason := _session.get_doctor_block_reason(character, String(id))
			button.text = tr("UI_DOCTOR_TREAT") % _session.doctor_fee(String(id)) if reason.is_empty() else tr(reason)
			button.disabled = not reason.is_empty()
			var who := character
			var ailment := String(id)
			button.pressed.connect(func():
				if _session.treat_ailment(who, ailment):
					_refresh_doctor())
			row.add_child(button)
			_doctor_box.add_child(row)
	if not any:
		var none := Label.new()
		none.text = tr("UI_DOCTOR_NONE")
		_doctor_box.add_child(none)

func _on_wallet_changed(_new_balance: int) -> void:
	_purification_panel.refresh()
	_refresh_doctor()

func _on_back_pressed() -> void:
	SceneInk.go(Nav.back())
