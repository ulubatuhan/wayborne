extends SceneTree

## Kamp kurulup kalkarken kervan (test değil, PNG basar): arabacı koltuktan
## iner, lider attan iner, ikisi de ateşe yürür; kamp kalkınca yürüyüp
## yeniden biner/koltuğa çıkar. Zaman elle sürülüyor (sabit adım), yoksa
## yazılım çiziminin kare süresi hangi anın yakalandığını belirlerdi.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1600x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_camp.gd

const OUT: String = "user://camp_sequence.png"
const BAND: Vector2i = Vector2i(1920, 900)
const DT: float = 1.0 / 30.0
## Zaman çizelgesi: [etiket, kampta mı, o ana kadar geçen saniye].
const MOMENTS: Array = [
	["0.2 sn: iniş başlıyor", true, 0.2],
	["0.8 sn: iniş ortası", true, 0.8],
	["1.4 sn: yere iniyor", true, 1.4],
	["ateşe yürüyüş", true, 2.0],
	["ateşe varmadan: yalnızca odun", true, 2.6],
	["ilk figür vardı: tutuşuyor", true, 2.85],
	["ateş oturdu", true, 4.2],
	["kamp kalktı: dönüş", false, 1.0],
	["binmeden önce", false, 3.0],
	["yerinde, yürümeye hazır", false, 6.0],
]

var _band: TravelBand
var _caravan: RoadCaravan

func _init() -> void:
	TranslationServer.set_locale("tr")
	WaybookTheme.install()
	var root := get_root()
	root.size = Vector2i(BAND.x, BAND.y)
	_band = TravelBand.new()
	_band.size = Vector2(BAND)
	root.add_child(_band)
	_caravan = RoadCaravan.new()
	_band.add_actor_layer(_caravan)
	_band.ground_line_changed.connect(_caravan.set_ground_line)
	_caravan.column_length_changed.connect(_band.set_column_length)
	_caravan.configure(_build_session())
	_caravan.set_process(false)
	_band.set_phase(JourneyClock.Phase.EVENING, 0.6)
	_caravan.set_light(_band.get_light())
	for _frame in 6:
		await process_frame

	var shots: Array[Image] = []
	var labels: Array[String] = []
	var elapsed := 0.0
	var camping := false
	var arrival := -1.0
	for moment in MOMENTS:
		if bool(moment[1]) != camping:
			camping = bool(moment[1])
			_band.set_camping(camping)
			_caravan.set_camping(camping)
			elapsed = 0.0
		while elapsed < float(moment[2]):
			_caravan._process(DT)
			elapsed += DT
			if camping and arrival < 0.0 and _caravan.get_fire_ignite(0) > 0.0:
				arrival = elapsed
				print("ilk ateş tutuştu: ", snapped(elapsed, 0.01), " sn")
		_caravan.queue_redraw()
		for child in _caravan.get_children():
			(child as CanvasItem).queue_redraw()
		for _frame in 3:
			await process_frame
		shots.append(root.get_texture().get_image())
		labels.append(String(moment[0]))
	_compose(shots, labels)
	await _closeup()
	quit()

## Yakın plan: liderin inişi ve yeniden binişi, ateşe yürüyüş hariç.
func _closeup() -> void:
	_caravan.configure(_build_session())
	_caravan.set_process(false)
	for _frame in 4:
		await process_frame
	var leader := _caravan.get_leader_figure()
	var centre := leader.get_global_rect().get_center()
	var side := int(leader.size.y * 1.3)
	var crop := Rect2i(int(centre.x) - side / 2, int(centre.y) - side / 2, side, side)
	var strip := Image.create(side * 8, side * 2, false, Image.FORMAT_RGBA8)
	_band.set_camping(true)
	_caravan.set_camping(true)
	for row in 2:
		for i in 8:
			var img := get_root().get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			strip.blit_rect(img, crop, Vector2i(side * i, side * row))
			for _step in int(RoadCaravan.TRANSITION_SECONDS / 7.0 / DT):
				_caravan._process(DT)
			for child in _caravan.get_children():
				(child as CanvasItem).queue_redraw()
			for _frame in 2:
				await process_frame
		if row == 0:
			# Ateşe yürüyüp geri dön, binişin başına kadar.
			for _step in int(_caravan.settle_seconds() / DT) + 30:
				_caravan._process(DT)
			_band.set_camping(false)
			_caravan.set_camping(false)
			for _step in int(_caravan.gather_seconds() / DT) + 2:
				_caravan._process(DT)
			for _frame in 2:
				await process_frame
	strip.save_png("user://camp_closeup.png")
	print("yazildi: camp_closeup")

## Kervanın ön yarısı (lider, ilk vagon, ateşi) her an için bir satır.
func _compose(shots: Array[Image], labels: Array[String]) -> void:
	var crop := Rect2i(0, int(BAND.y * 0.35), int(BAND.x * 0.62), int(BAND.y * 0.62))
	var sheet := Image.create(crop.size.x, crop.size.y * shots.size(), false, Image.FORMAT_RGBA8)
	for i in shots.size():
		var img := shots[i]
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, crop, Vector2i(0, crop.size.y * i))
	sheet.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", labels)

func _build_session() -> GameSession:
	var session := GameSession.new()
	session.owned_wagon_count = 1
	var player := CharacterData.create(
		"Kervanbaşı", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 1, ClassCatalog.GUARD, CharacterData.GENDER_MALE
	)
	player.is_player = true
	session.party.append(player)
	var companion := CharacterData.create(
		"Yoldaş", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 2, ClassCatalog.GUARD, CharacterData.GENDER_MALE
	)
	session.party.append(companion)
	return session
