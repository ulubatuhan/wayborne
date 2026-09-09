extends Control

## Placeholder şehir haritası. Şehir kart tabanlı değil: her lokasyon kendi
## ekranını açar, oyuncu neyle etkileşime gireceğini kendisi seçer.

const SPOT_SIZE: Vector2 = Vector2(190, 76)

@onready var _map_panel: Control = $MarginContainer/VBoxContainer/MapPanel
@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _party_button: Button = $MarginContainer/VBoxContainer/PartyButton
@onready var _gate_button: Button = $MarginContainer/VBoxContainer/GateButton

var _session: GameSession

func _ready() -> void:
	_session = GameState.get_session()
	_party_button.pressed.connect(_on_party_pressed)
	_gate_button.pressed.connect(_on_gate_pressed)
	_refresh_title()
	_build_spots()
	_maybe_show_onboarding()

## Karakter oluşturmadan sonra ilk kez şehre varan oyuncuya bir kereye
## mahsus, atlanabilir bir ipucu katmanı gösterir (bkz. OnboardingPanel,
## GameSession.ONBOARDING_FLAG).
func _maybe_show_onboarding() -> void:
	if _session.has_flag(GameSession.ONBOARDING_FLAG):
		return
	_session.set_flag(GameSession.ONBOARDING_FLAG)
	add_child(OnboardingPanel.new())

func _refresh_title() -> void:
	var location := WorldMapData.get_location_by_id(_session.current_location_id)
	var city_name := tr("UI_CITY_FALLBACK_NAME") if location == null else location.location_name
	var wagon_note := tr("UI_PLANNER_WAGONS") % _session.owned_wagon_count
	if _session.owned_wagon_damaged > 0:
		wagon_note += tr("UI_CITY_DAMAGED_SUFFIX") % _session.owned_wagon_damaged
	# Borç görünmezse oyuncu batmakta olduğunu ancak lonca ekranına
	# girdiğinde fark eder (bkz. DebtPanel).
	var debt_note := ""
	if _session.get_total_debt() > 0:
		debt_note = tr("UI_HUD_DEBT") % _session.get_total_debt()
	_title_label.text = (tr("UI_CITY_HUD") + debt_note) % [
		city_name,
		_session.wallet.balance,
		_session.get_provisions(),
		wagon_note,
		_session.get_party().size(),
		_session.get_party_capacity(),
	]

func _build_spots() -> void:
	_add_spot(
		tr("UI_CITY_MARKET"),
		tr("UI_CITY_MARKET_DESC"),
		Vector2(60, 40),
		Nav.ECONOMY
	)
	_add_spot(
		tr("UI_GUILD_TITLE"),
		tr("UI_CITY_GUILD_DESC"),
		Vector2(340, 150),
		Nav.GUILD
	)
	_add_spot(
		tr("UI_TAVERN_TITLE"),
		tr("UI_CITY_TAVERN_DESC"),
		Vector2(80, 260),
		Nav.TAVERN
	)
	_add_spot(
		tr("UI_CITY_YARD"),
		tr("UI_CITY_YARD_DESC"),
		Vector2(400, 330),
		Nav.CARAVAN_YARD
	)
	_add_spot(
		tr("UI_CITY_CHURCH"),
		tr("UI_CITY_CHURCH_DESC"),
		Vector2(400, 40),
		Nav.CHURCH
	)

func _add_spot(spot_name: String, description: String, position: Vector2, scene_path: String) -> void:
	var button := Button.new()
	button.text = "%s\n%s" % [spot_name, description]
	button.custom_minimum_size = SPOT_SIZE
	button.size = SPOT_SIZE
	button.position = position
	button.disabled = scene_path.is_empty()
	if not button.disabled:
		button.pressed.connect(_on_spot_pressed.bind(scene_path))
	_map_panel.add_child(button)

func _on_spot_pressed(scene_path: String) -> void:
	Nav.return_scene = Nav.CITY_MAP
	get_tree().change_scene_to_file(scene_path)

func _on_party_pressed() -> void:
	Nav.return_scene = Nav.CITY_MAP
	get_tree().change_scene_to_file(Nav.PARTY)

func _on_gate_pressed() -> void:
	Nav.return_scene = Nav.WORLD_HUB
	get_tree().change_scene_to_file(Nav.WORLD_HUB)
