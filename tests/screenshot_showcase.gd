extends SceneTree

## Kimliği tanımlayan beş ana görsel (görev Y-G13): mağaza sayfası ve
## fragman bunlardan çıkar. Test değil, PNG basar. Hepsi oyunun kendi
## ekranları - yol sahnesi gerçek `road_journey.tscn`, harita gerçek
## `WorldMapView`, devir gerçek `SuccessionPanel`; boyanmış ayrı bir
## pazarlama resmi yok. Yol karelerinde HUD gizli ve kadraj gökyüzüyle
## birlikte tam ekran (sinematik kare); olay kartı ise oyunun kendi
## yerleşimiyle, HUD'u açık.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_showcase.gd [-- 1 3 5]
##
## Çıktı: user://showcase/*.png, ayrıca docs/steam/vitrin/*.jpg (depoya giren kopya).

const SHOT_DIR: String = "user://showcase"
const DOC_DIR: String = "res://docs/steam/vitrin"
const VIEW_SIZE: Vector2i = Vector2i(1920, 1080)
const JPG_QUALITY: float = 0.9

var _session: GameSession

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DOC_DIR))
	get_root().size = VIEW_SIZE
	DisplayServer.window_set_size(VIEW_SIZE)
	await _frames(8)
	# UserSettings dili ilk karede kendi kaydından kuruyor; vitrin Türkçe.
	TranslationServer.set_locale("tr")
	WaybookTheme.install()
	_session = get_root().get_node("GameState").call("get_session")
	var only := OS.get_cmdline_user_args()
	if only.is_empty() or only.has("1"):
		await _night_map()
	if only.is_empty() or only.has("2"):
		await _campfire()
	if only.is_empty() or only.has("3"):
		await _event_card()
	if only.is_empty() or only.has("4"):
		await _broken_seal()
	if only.is_empty() or only.has("5"):
		await _gate_arrival()
	quit()

## 1. Gece haritası ve fenerli atlı: yerleşimlerin ışıkları, geçmiş yolların
## mürekkep izi, kamp yerleri, yolda bir mezar.
func _night_map() -> void:
	var view := WorldMapView.new()
	view.size = Vector2(VIEW_SIZE)
	view.current_location_id = "tolvarin"
	view.focused_location_id = "akavan"
	view.journey_path = WorldMapData.get_route_path("tolvarin", "akavan")
	view.journey_progress = 0.55
	view.hour = 22.5
	view.trail = [{"from": "kirsavel", "to": "tolvarin"}]
	view.camps = []
	for key in [["kirsavel", "tolvarin", 0.45]]:
		var path := WorldMapData.get_route_path(String(key[0]), String(key[1]))
		if path.size() >= 2:
			var at := WorldMapView.point_along(path, float(key[2]))
			view.camps.append([at.x, at.y])
	view.graves = [{"route": RouteConditions.route_key("kirsavel", "tolvarin"), "share": 0.7, "old": false}]
	get_root().add_child(view)
	await _frames(4)
	view.focus_caravan(0.36)
	await _frames(90)
	_save("01_gece_haritasi")
	view.queue_free()
	await _frames(4)

## 2. Kamp ateşi panoraması: dört kişi, üç vagon, gece, herkes ateşin başında.
func _campfire() -> void:
	var screen := await _road("tolvarin", "akavan", 0.45, 20.6, true, 0.72)
	var caravan: RoadCaravan = screen.get("_caravan")
	# Lider kolonun ortasına geri sürüyor: yakınlaştırmanın merkezi o, ateşler
	# kadrajın ortasına gelsin.
	var middle := -caravan.get_column_length() * 0.08
	screen.set("_leader_offset", middle)
	screen.set("_leader_target", middle)
	caravan.set_leader_offset(middle)
	await _frames(20)
	screen.call("_on_camp_pressed")
	for _i in 900:
		await process_frame
		_close_panel(screen, "_camp_panel")
		if caravan.is_camp_settled():
			break
	for _i in 60:
		await process_frame
		_close_panel(screen, "_camp_panel")
	_save("02_kamp_atesi")
	await _close(screen)

## 3. Olay kartı: tuzaklı, savaşa açılan seçenekli kart, oyunun kendi yerleşimiyle.
func _event_card() -> void:
	var screen := await _road("caramine", "ilsande", 0.35, 18.6, false)
	var shown: GameEvent = null
	for event in EventCatalog.get_road_events():
		if event.event_id == "evt_wild_animal":
			shown = event
	screen.call("_present_event", shown if shown != null else EventCatalog.get_road_events()[0])
	await _frames(40)
	_save("03_olay_karti")
	await _close(screen)

## 4. Defter ve kırık mühür: lider düştü, kıdemli değil başkası seçiliyor.
func _broken_seal() -> void:
	var screen := await _road("tolvarin", "akavan", 0.6, 19.5, true)
	var session := _session
	var candidates: Array[CharacterData] = []
	for character in session.party:
		if not character.is_player:
			candidates.append(character)
	var leader := session.get_player_character()
	var succession := SuccessionPanel.new()
	var testimony := {}
	for index in candidates.size():
		testimony[candidates[index]] = {"served_days": 61 - index * 17, "benched": index == 1}
	var line := CaravanLedger.describe({"kind": CaravanLedger.KIND_DIED, "name": leader.character_name,
		"day": 61, "cause": "LEDGER_CAUSE_COMBAT_BANDIT", "location": "akavan"})
	succession.setup(session.caravan_name, leader.character_name, line, candidates, 3, testimony)
	get_root().add_child(succession)
	await _seconds(2.4)
	if candidates.size() > 1:
		succession.select(candidates[candidates.size() - 1])
	await _seconds(0.8)
	_save("04_defter_kirik_muhur")
	succession.queue_free()
	await _close(screen)

## 5. Şehir kapısına varış: akşam, meşaleler yanıyor, geçit liderin önünde.
func _gate_arrival() -> void:
	var screen := await _road("tolvarin", "akavan", 0.0, 19.8, true)
	var journey: JourneyController = screen.get("_journey")
	var band: TravelBand = screen.get("_band")
	journey.days_covered = maxf(0.0, float(journey.journey_length_days)
		- 0.12 * VIEW_SIZE.x / maxf(1.0, band.get_pixels_per_day()))
	_set_hour(screen, 19.8)
	screen.call("_refresh_time_ui")
	await _frames(60)
	_save("05_kapiya_varis")
	await _close(screen)

## Yol sahnesi: dört kişilik, üç vagonlu bir kervan; `cinematic` HUD'u
## kaldırıp gökyüzünü kadraja geri katar.
func _road(origin: String, destination_id: String, share: float, hour: float, cinematic: bool,
		zoom: float = 1.0) -> Control:
	_start_journey(origin, destination_id)
	var screen: Control = load("res://scenes/game/road_journey.tscn").instantiate()
	get_root().add_child(screen)
	screen.set("_zoom_target", zoom)
	screen.set("_zoom", zoom)
	await _frames(8)
	screen.set("_pace", 0.0)
	# Yazılım çiziminde bir kare yarım saniye sürebiliyor; saat akarsa
	# istenen saat çekime kadar kayıyor. Otomatik duraklama saati durduruyor,
	# figürler ve ateş yine canlı.
	screen.set("_auto_paused", true)
	var journey: JourneyController = screen.get("_journey")
	journey.days_covered = float(journey.journey_length_days) * share
	_set_hour(screen, hour)
	screen.call("_refresh_time_ui")
	if cinematic:
		var hud: Control = screen.get("_hud")
		hud.visible = false
		var world: Control = screen.get("_world")
		world.offset_top = 0.0
		world.offset_bottom = 0.0
	await _frames(30)
	return screen

## Kampın emir paneli kendiliğinden açılıyor; vitrin karesinde ateş görünsün.
func _close_panel(screen: Control, field: String) -> void:
	var panel: Node = screen.get(field)
	if panel != null:
		panel.queue_free()
		screen.set(field, null)

func _close(screen: Control) -> void:
	screen.set("_zoom_target", 1.0)
	screen.queue_free()
	await _frames(4)

func _start_journey(origin: String, destination_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	_session.start_playthrough(CharacterData.create("Tuğrul", CultureCatalog.NOMAD, CharacterStats.new(),
		178, 1, ClassCatalog.GUARD, CharacterData.GENDER_MALE), rng)
	_session.owned_wagon_count = 3
	var crew := [
		["Elif", 166, 0, ClassCatalog.CLERK, CharacterData.GENDER_FEMALE],
		["Mert", 183, 2, ClassCatalog.BREAKER, CharacterData.GENDER_MALE],
		["Ayşe", 170, 1, ClassCatalog.HUNTER, CharacterData.GENDER_FEMALE],
	]
	while _session.party.size() > 1:
		_session.party.remove_at(_session.party.size() - 1)
	for row in crew:
		var person := CharacterData.create(String(row[0]), CultureCatalog.NOMAD, CharacterStats.new(),
			int(row[1]), int(row[2]), String(row[3]), int(row[4]))
		RecruitCatalog._dress(person)
		_session.add_to_party(person)
	_session.current_location_id = origin
	var destination := WorldMapData.get_location_by_id(destination_id)
	var days := WorldMapData.get_route(origin, destination_id).travel_days
	_session.start_journey(destination_id, days, 0.38, CaravanPlan.new(destination, days))

func _set_hour(screen: Control, hour: float) -> void:
	var clock: JourneyClock = screen.get("_clock")
	if clock != null:
		clock.total_hours = floor(clock.total_hours / 24.0) * 24.0 + hour

func _frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _seconds(value: float) -> void:
	await create_timer(value).timeout

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s.png" % [SHOT_DIR, file_name])
	image.save_jpg(ProjectSettings.globalize_path("%s/%s.jpg" % [DOC_DIR, file_name]), JPG_QUALITY)
	print("  -> ", file_name)
