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
	# Geri hedefi return_scene değil, mekânın yazdığı recruit_return_scene:
	# aksi halde geri dönülen mekânın kendi geri tuşu kendisine dönüyor
	# (bkz. Nav.recruit_return_scene).
	_back_button.text = Nav.label_for(Nav.close_recruit())
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
			return tr("UI_CITY_GUILD_LEDGER")
		RecruitCatalog.VENUE_MARKET:
			return tr("UI_RECRUIT_CANDIDATES")
		_:
			return tr("UI_CITY_TAVERN")

func _refresh_wallet() -> void:
	_wallet_label.text = tr("UI_PURSE") % _session.wallet.balance

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh_wallet()
	_panel.refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.close_recruit())
