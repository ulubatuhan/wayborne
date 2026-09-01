extends Control

## Tayfa ekranı. Hangi mekândan girildiği Nav.recruit_venue'de durur -
## aynı ekran meydandan, tavernadan ve loncadan farklı adaylar gösterir
## (bkz. RecruitCatalog).

var _session: GameSession
var _panel: RecruitPanel

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _wallet_label: Label = $MarginContainer/VBoxContainer/WalletLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_title_label.text = _venue_title()

	_panel = RecruitPanel.new()
	_content.add_child(_panel)
	_panel.party_changed.connect(_refresh_wallet)
	_panel.setup(_session, Nav.recruit_venue, _venue_title())

	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_refresh_wallet()

func _venue_title() -> String:
	match Nav.recruit_venue:
		RecruitCatalog.VENUE_GUILD:
			return "Lonca Kayıt Defteri"
		RecruitCatalog.VENUE_MARKET:
			return "Meydanda Bekleyenler"
		_:
			return "Taverna Köşesi"

func _refresh_wallet() -> void:
	_wallet_label.text = "Kese: %d GG" % _session.wallet.balance

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh_wallet()
	_panel.refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
