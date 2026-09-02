extends Control

## Kilise: huy arındırmaya adanmış tek mekân. Taverna da aynı hizmeti
## verir (bir kadeh içip unutmak) ama daha pahalıya - burası ucuz, çünkü
## işin uzmanı (bkz. PurificationPanel, tavern.gd).

const PURIFICATION_COST: int = 35

var _session: GameSession
var _purification_panel: PurificationPanel

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _content: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ContentContainer
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)

	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	_title_label.text = "Kilise" if location == null else "%s Kilisesi" % location.location_name

	_purification_panel = PurificationPanel.new()
	_content.add_child(_purification_panel)
	_purification_panel.setup(_session, "Huy Arındır", PURIFICATION_COST)

	_session.wallet.balance_changed.connect(_on_wallet_changed)

func _on_wallet_changed(_new_balance: int) -> void:
	_purification_panel.refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
