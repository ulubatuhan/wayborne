extends Control

## Şehir ekranı. Şehir kart tabanlı değil: her lokasyon kendi ekranını
## açar, oyuncu neyle etkileşime gireceğini kendisi seçer.
##
## Haritanın kendisi artık beş buton değil, üstten bakışlı izometrik bir
## kasaba (bkz. CityView). Bu ekranın işi kasabayı kurmak, başlığı basmak
## ve **gezinmeyi yapmak**: `CityView` yalnızca hangi mekâna basıldığını
## bildiriyor, sahne değiştirmeyi burası yapıyor - gezinme yığınını iten
## taraf her zaman gönderen ekrandır (bkz. Nav).

@onready var _map_panel: Control = $MarginContainer/VBoxContainer/MainRow/MapPanel
@onready var _brief_container: VBoxContainer = $MarginContainer/VBoxContainer/MainRow/BriefScroll/BriefContainer
@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _info_label: Label = $MarginContainer/VBoxContainer/InfoLabel
@onready var _party_button: Button = $MarginContainer/VBoxContainer/PartyButton
@onready var _gate_button: Button = $MarginContainer/VBoxContainer/GateButton

var _session: GameSession
var _brief_panel: CityBriefPanel
var _city_view: CityView

func _ready() -> void:
	_session = GameState.get_session()
	Nav.go_root(Nav.CITY_MAP)
	# Sahne dosyasındaki yazı yalnızca editörde ne olduğunu görmek için;
	# oyuncunun gördüğü metin her zaman koddan, anahtarla gelir - yoksa
	# ekran hangi dile geçilirse geçilsin Türkçe kalır.
	_info_label.text = tr("UI_CITY_INFO")
	_party_button.text = tr("UI_CITY_VIEW_PARTY")
	_gate_button.text = tr("UI_CITY_LEAVE_BY_GATE")
	_party_button.pressed.connect(_on_party_pressed)
	_gate_button.pressed.connect(_on_gate_pressed)
	_refresh_title()
	_build_spots()
	_build_brief()
	_maybe_show_onboarding()

## Şehir artık bir kapı listesi değil, kararın verildiği yer: kervanın
## neye ihtiyacı olduğu ve bugün nereye gidilebileceği burada okunuyor
## (bkz. CityBriefPanel). Ekran değiştirmeyi panel değil bu ekran yapıyor -
## gezinme yığınını iten taraf her zaman gönderen ekrandır (bkz. Nav).
func _build_brief() -> void:
	_brief_panel = CityBriefPanel.new()
	_brief_container.add_child(_brief_panel)
	_brief_panel.screen_requested.connect(_on_spot_pressed)
	_brief_panel.planner_requested.connect(_on_planner_requested)
	_brief_panel.setup(_session)

func _on_planner_requested(destination_id: String) -> void:
	TravelContext.selected_destination_id = destination_id
	get_tree().change_scene_to_file(Nav.open(Nav.CITY_MAP, Nav.CARAVAN_PLANNER))

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

## Kasabayı kurar. Mekânların *yeri* artık burada yazmıyor: yerleşim
## şehrin kendi tohumundan çıkıyor (bkz. CityView), yani Karakonak ile
## Demirkapı aynı kasaba değil. Elle konmuş beş koordinat hem her şehri
## aynı gösteriyordu hem de yeni bir mekân eklemek altıncı bir koordinat
## uydurmak anlamına geliyordu.
func _build_spots() -> void:
	_city_view = CityView.new()
	_city_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_panel.add_child(_city_view)
	_city_view.venue_pressed.connect(_on_spot_pressed)
	_city_view.setup(_session)

	# Fare ile keşfedilen bir ekranın kendini bir kez anlatması lazım:
	# tıklanabilir olduğu belli olmayan bir kasaba, dekordan ibaret kalır.
	var hint := Label.new()
	hint.text = tr("UI_CITY_HOVER_HINT")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.modulate = Color(0.72, 0.70, 0.64)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 10.0
	hint.offset_right = -10.0
	hint.offset_top = -30.0
	hint.offset_bottom = -6.0
	_map_panel.add_child(hint)

func _on_spot_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.CITY_MAP, scene_path))

func _on_party_pressed() -> void:
	get_tree().change_scene_to_file(Nav.open(Nav.CITY_MAP, Nav.PARTY))

func _on_gate_pressed() -> void:
	get_tree().change_scene_to_file(Nav.go_root(Nav.WORLD_HUB))
