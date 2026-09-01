extends Control

## Kervansaray: hasarlı vagon onarımı ve yeni vagon alımı. İş mantığı
## GameSession'da (get_repair_cost/repair_wagons, get_next_wagon_cost/
## can_buy_wagon/buy_wagon) - burada yalnızca gösterim var.

const MESSAGE_COLOR: Color = Color(0.9, 0.45, 0.35)

var _session: GameSession

@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var _message_label: Label = $MarginContainer/VBoxContainer/MessageLabel
@onready var _repair_button: Button = $MarginContainer/VBoxContainer/RepairButton
@onready var _buy_wagon_button: Button = $MarginContainer/VBoxContainer/BuyWagonButton
@onready var _back_button: Button = $MarginContainer/VBoxContainer/BackButton

func _ready() -> void:
	_session = GameState.get_session()
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_session.wallet.balance_changed.connect(_on_wallet_changed)
	_repair_button.pressed.connect(_on_repair_pressed)
	_buy_wagon_button.pressed.connect(_on_buy_wagon_pressed)
	_back_button.text = Nav.return_label()
	_back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	_status_label.text = "Sahip olduğun vagon: %d / %d · Hasarlı: %d" % [
		_session.owned_wagon_count, CaravanPlan.DEFAULT_MAX_WAGONS, _session.owned_wagon_damaged
	]

	if _session.owned_wagon_damaged > 0:
		var repair_cost := _session.get_repair_cost()
		_repair_button.text = "Tümünü Onar (%d GG)" % repair_cost
		_repair_button.disabled = not _session.wallet.can_afford(repair_cost)
	else:
		_repair_button.text = "Hasar Yok"
		_repair_button.disabled = true

	if _session.can_buy_wagon():
		var next_cost := _session.get_next_wagon_cost()
		_buy_wagon_button.text = "Yeni Vagon Al (%d GG)" % next_cost
		_buy_wagon_button.disabled = not _session.wallet.can_afford(next_cost)
	else:
		_buy_wagon_button.text = "Vagon Limiti Doldu (%d)" % CaravanPlan.DEFAULT_MAX_WAGONS
		_buy_wagon_button.disabled = true

func _on_repair_pressed() -> void:
	if not _session.repair_wagons():
		_show_message("Onarım için yeterli kesen yok.")
		return
	_clear_message()
	_refresh()

func _on_buy_wagon_pressed() -> void:
	if not _session.buy_wagon():
		_show_message("Yeni vagon için yeterli kesen yok ya da limit doldu.")
		return
	_clear_message()
	_refresh()

func _on_wallet_changed(_new_balance: int) -> void:
	_refresh()

func _show_message(text: String) -> void:
	_message_label.text = text
	_message_label.modulate = MESSAGE_COLOR

func _clear_message() -> void:
	_message_label.text = ""

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(Nav.return_scene)
