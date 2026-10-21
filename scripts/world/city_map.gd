extends Control

## Şehir ekranı. Şehir kart tabanlı değil: her lokasyon kendi ekranını
## açar, oyuncu neyle etkileşime gireceğini kendisi seçer.
##
## Ekranın tamamı şehrin kendi resmi (bkz. CityFront): önden bakılan,
## render edilmiş bir kasaba, solda mekân levhaları, sağda kadro kartları,
## altta kaynak şeridi. Bu ekranın işi resmi kurmak, brifingi yanına koymak
## ve **gezinmeyi yapmak**: CityFront yalnızca neye basıldığını bildiriyor,
## sahne değiştirmeyi burası yapıyor - gezinme yığınını iten taraf her
## zaman gönderen ekrandır (bkz. Nav).

## Yerleşimin kendi resim klasörü (data/assets/ui/towns/<kimlik>/, görev
## P17). Henüz kendi resmi olmayan yer, bölgesine en yakın eski kasaba
## resmine düşer - geçici.
const REGION_FALLBACK_DIRS: Dictionary = {
	"imparatorluk": "demirkapi",
	"dag": "kurtbogazi",
	"dag_maden": "kurtbogazi",
	"vadi": "ipekevi",
	"guney": "yesilova",
	"ahit": "ipekevi",
	"sinir": "karakonak",
	"gocebe": "karakonak",
}
const SEASON_KEYS: Array = ["SEASON_SPRING", "SEASON_SUMMER", "SEASON_AUTUMN", "SEASON_WINTER"]
const BRIEF_WIDTH: float = 380.0
const EDGE: float = 26.0

var _session: GameSession
var _front: CityFront
var _brief_panel: CityBriefPanel

func _ready() -> void:
	_session = GameState.get_session()
	Nav.go_root(Nav.CITY_MAP)
	# Şehrin kendi parçası: varış hissi. Şehir içindeki ekranlar
	# (pazar, lonca...) parçayı değiştirmiyor - play_track aynı parçayı
	# ikinci kez çalmıyor, o yüzden ekran gezmek müziği baştan başlatmaz.
	AudioManager.play_track(AudioManager.TRACK_CITY)
	# Kapı sesi yalnızca gerçek bir girişte - bkz. Nav.city_gate_opening'in
	# notu. Bayrak tüketiliyor (hemen false'a dönüyor), yoksa pazar/lonca
	# gibi bir alt ekrandan geri dönmek de aynı sahneyi yeniden yükler ve
	# kapı her seferinde bir daha "açılırdı".
	var arriving := Nav.city_gate_opening
	if Nav.city_gate_opening:
		Nav.city_gate_opening = false
		AudioManager.play_sfx(AudioManager.SFX_GATE)
	_build_front()
	_build_brief()
	_maybe_show_onboarding()
	# Kapının resmi bir an ekranı kaplar, şehir arkasından belirir (12.2a).
	if arriving and GateArrival.available(_session.current_location_id):
		add_child(GateArrival.new().setup(_session.current_location_id, _session.last_clock_hour))

func _build_front() -> void:
	_front = CityFront.new()
	add_child(_front)
	_front.setup(town_dir(_session.current_location_id), build_model(_session))
	_front.venue_pressed.connect(_on_spot_pressed)
	_front.nav_pressed.connect(_on_nav_pressed)

static func town_dir(location_id: String) -> String:
	if ResourceLoader.exists(CityFront.TOWNS_DIR + location_id + "/background.jpg") or FileAccess.file_exists(CityFront.TOWNS_DIR + location_id + "/background.jpg"):
		return location_id
	var location := WorldMapData.get_location_by_id(location_id)
	var region := location.region if location != null else ""
	return String(REGION_FALLBACK_DIRS.get(region, "karakonak"))

## CityFront'un okuduğu tek sözlük. Sayıların hepsi oturumun zaten
## yayınladığı değerler - ekran hiçbir şeyi kendisi hesaplamıyor.
static func build_model(session: GameSession) -> Dictionary:
	var location := WorldMapData.get_location_by_id(session.current_location_id)
	var party: Array = []
	for c in session.get_party():
		var cls := c.get_character_class()
		party.append({
			"name": c.character_name, "hp": c.current_hp, "max_hp": c.get_max_hp(), "stress": c.stress,
			"class": c.class_id, "class_key": cls.display_name_key if cls != null else "", "level": c.level,
		})
	var daily := maxi(1, session.get_daily_provision_consumption())
	var day := session.total_days_elapsed
	return {
		"city_name": location.location_name if location != null else TranslationServer.translate("UI_CITY_FALLBACK_NAME"),
		"day": day + 1,
		"hour": session.last_clock_hour,
		"mood": CityFront.mood_for(session.is_city_in_crisis(session.current_location_id),
			session.current_location_id, day),
		"season_key": SEASON_KEYS[int(MarketConditions.get_season(day))],
		"gold": session.wallet.balance,
		"debt": session.get_total_debt(),
		"provisions": session.get_provisions(),
		"provisions_days": session.get_provisions() / daily,
		"party": party,
		"venue_lines": venue_lines(session),
		"facilities": SettlementRules.facilities(location.settlement_type) if location != null else [],
	}

## Brifingin ihtiyaçları, hangi mekân çözüyorsa o mekânın levhasına da
## yazılır: "erzak az" pazarın, "vagon hasarlı" avlunun altında.
static func venue_lines(session: GameSession) -> Dictionary:
	var by_scene := {}
	for v in CityFront.VENUES:
		by_scene[String(v["scene"])] = String(v["key"])
	var lines := {}
	for need in CityBriefModel.build_needs(session):
		var key := String(by_scene.get(String(need.get("scene", "")), ""))
		if key.is_empty():
			continue
		if not lines.has(key):
			lines[key] = []
		(lines[key] as Array).append({"text": String(need.get("text", "")),
			"kind": "bad" if bool(need.get("urgent", false)) else ""})
	return lines

## Şehir artık bir kapı listesi değil, kararın verildiği yer: kervanın
## neye ihtiyacı olduğu ve bugün nereye gidilebileceği burada okunuyor
## (bkz. CityBriefPanel). Resmin üstünde, kadronun yanında koyu bir sütun.
func _build_brief() -> void:
	var holder := PanelContainer.new()
	holder.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	holder.offset_left = -(CityFront.CARD_SIZE.x + EDGE * 2.0 + BRIEF_WIDTH)
	holder.offset_right = -(CityFront.CARD_SIZE.x + EDGE * 2.0)
	holder.offset_top = 30.0
	holder.offset_bottom = -(CityFront.STRIP_HEIGHT + 18.0)
	# Okunacak metin düz koyu zeminde (dokunun üstüne yazı yazılmaz).
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ArtPalette.GRIM_CHARCOAL, 0.86)
	box.border_color = Color(ArtPalette.GRIM_AMBER, 0.35)
	box.set_border_width_all(1)
	box.set_content_margin_all(14)
	holder.add_theme_stylebox_override("panel", box)
	add_child(holder)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	holder.add_child(col)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_brief_panel = CityBriefPanel.new()
	_brief_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_brief_panel)
	_brief_panel.screen_requested.connect(_on_spot_pressed)
	_brief_panel.planner_requested.connect(_on_planner_requested)
	_brief_panel.setup(_session)

func _on_planner_requested(destination_id: String) -> void:
	TravelContext.selected_destination_id = destination_id
	SceneInk.go(Nav.open(Nav.CITY_MAP, Nav.CARAVAN_PLANNER))

## Alt şeridin düğmeleri. "Yola Çık" kapıya, yani dış alana gider -
## yola çıkış kararını planlayıcı veriyor, bu yalnızca kapıdan çıkmak.
func _on_nav_pressed(key: String) -> void:
	match key:
		"UI_GRIM_NAV_PARTY":
			SceneInk.go(Nav.open(Nav.CITY_MAP, Nav.PARTY))
		"UI_GRIM_NAV_LEDGER":
			_show_waybook()
		"UI_GRIM_NAV_MAP":
			SceneInk.go(Nav.open(Nav.CITY_MAP, Nav.TRAVEL))
		"UI_GRIM_NAV_CARAVAN":
			_show_caravan()
		"UI_GRIM_EMBARK":
			SceneInk.go(Nav.go_root(Nav.WORLD_HUB))

## Karakter oluşturmadan sonra ilk kez şehre varan oyuncuya bir kereye
## mahsus babadan devir sahnesini gösterir (bkz. GameSession.ONBOARDING_FLAG).
func _maybe_show_onboarding() -> void:
	if _session.has_flag(GameSession.ONBOARDING_FLAG):
		return
	_session.set_flag(GameSession.ONBOARDING_FLAG)
	# Öğretici ve yardım paneli şimdilik yok (kullanıcı kararı, 2026-10-21):
	# sonra eklenecek. Devir sahnesi yeni oyunun ilk anı (görev Y-C14).
	if _session.debts.get_debt(GameSession.FATHER_DEBT_ID) != null:
		add_child(InheritancePanel.new().setup(_session))

## Defterin tamamı (bkz. WaybookPanel) - yolda da aynı panel, aynı tuş;
## ekrandaki karşılığı şeridin "Defter" düğmesi (UI_WAYBOOK_OPEN).
func _show_waybook() -> void:
	for child in get_children():
		if child is WaybookPanel:
			return
	add_child(WaybookPanel.new().setup(_session))

func _show_caravan() -> void:
	for child in get_children():
		if child is CaravanOverviewPanel:
			return
	var panel := CaravanOverviewPanel.new()
	add_child(panel)
	panel.setup(_session)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			_show_waybook()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_cancel"):
		_open_in_game_menu()
		get_viewport().set_input_as_handled()

## Sefer hiçbir zaman burada canlı olamaz (yol yalnızca `Nav.JOURNEY`'de
## yaşanıyor), o yüzden kayıt hep açık - bkz. InGameMenu'nün başındaki not.
func _open_in_game_menu() -> void:
	if has_node("InGameMenu"):
		return
	var menu := InGameMenu.new()
	menu.name = "InGameMenu"
	add_child(menu)
	# Kader Modu'nda elle kayıt yok (Y-D01).
	menu.setup(_session.can_save_manually())

func _on_spot_pressed(scene_path: String) -> void:
	SceneInk.go(Nav.open(Nav.CITY_MAP, scene_path))
