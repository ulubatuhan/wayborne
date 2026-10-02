extends SceneTree

## Hub'ın iki düzeltmesinin görsel doğrulaması. **Test değil** - PNG basar.
##
## 1. `oran.png` - insan, köpek ve eşek aynı zemin çizgisinde, üstlerinde
##    diz/bel/omuz kılavuz çizgileriyle. İstenen ölçü sözle verilmişti
##    ("eşeğin kafası omuzda, köpek diz ile bel arasında"), yani doğrulama
##    da o çizgilere bakarak yapılmalı - sayı tablosu bunu gösteremez.
## 2. `donus.png` - dönüş dalgasının iki saniyesi, kare kare. Tek kare bir
##    dönüşün *anında* mı yoksa sırayla mı olduğunu söyleyemez; zaten
##    oyuncunun bildirdiği hata tam olarak buydu.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_hub_motion.gd

const SHOT_DIR: String = "user://hub_motion"
const VIEW: Vector2i = Vector2i(1000, 360)
const GROUND_Y: float = 300.0
const FRAMES: int = 8
const SECONDS: float = 1.6

var _hub: GDScript = load("res://scripts/world/world_hub.gd")

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = VIEW
	await _proportions()
	await _turn_wave()
	print("Görüntüler: ", ProjectSettings.globalize_path(SHOT_DIR))
	quit(0)

## İnsan / köpek / eşek yan yana, insanın diz-bel-omuz hizaları çizili.
func _proportions() -> void:
	var root := _fresh()
	var person_h: float = _hub.CREW_BODY_HEIGHT
	var guides := GuideLines.new()
	guides.set_anchors_preset(Control.PRESET_FULL_RECT)
	guides.setup(GROUND_Y, person_h)
	root.add_child(guides)

	_figure(root, WalkFigure.KIND_PERSON, 180.0, Vector2(46.0, person_h))
	var dog: Vector2 = _hub.pack_box(true)
	_figure(root, WalkFigure.KIND_DOG, 330.0, dog)
	var donkey: Vector2 = _hub.pack_box(false)
	_figure(root, WalkFigure.KIND_DONKEY, 520.0, donkey)
	# İkinci bir insan: eşeğin kafasının gerçekten bir omza denk gelip
	# gelmediği ancak yanında biri dururken okunuyor.
	_figure(root, WalkFigure.KIND_PERSON, 700.0, Vector2(46.0, person_h))

	await _settle()
	_save("oran.png")

## Dalganın iki saniyesi: başta lider, arkasında dört figür.
func _turn_wave() -> void:
	var root := _fresh()
	var figures: Array[WalkFigure] = []
	var xs := [760.0, 620.0, 480.0, 340.0, 200.0]
	for index in xs.size():
		var box := Vector2(46.0, float(_hub.CREW_BODY_HEIGHT))
		if index == 3:
			box = _hub.pack_box(false)
		elif index == 4:
			box = _hub.pack_box(true)
		var kind := WalkFigure.KIND_PERSON
		if index == 3:
			kind = WalkFigure.KIND_DONKEY
		elif index == 4:
			kind = WalkFigure.KIND_DOG
		figures.append(_figure(root, kind, float(xs[index]), box))

	var frames: Array[Image] = []
	var head: float = float(xs[0])
	var span: float = head - float(xs[xs.size() - 1])
	for shot in FRAMES:
		var elapsed := SECONDS * float(shot) / float(FRAMES - 1)
		for index in figures.size():
			var figure := figures[index]
			var along := (head - float(xs[index])) / span
			# Hedef sola dönmek: dalga sağdan (-target) başlayıp sola biter.
			var facing: float = _hub.turn_facing(-1.0, elapsed, along)
			figure.pivot_offset = Vector2(figure.size.x * 0.5, figure.size.y)
			figure.scale = Vector2(maxf(absf(facing), 0.06), 1.0)
			figure.set_facing(1.0 if facing >= 0.0 else -1.0)
		await _settle()
		frames.append(get_root().get_texture().get_image())

	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var sheet := Image.create(w, h * frames.size(), false, frames[0].get_format())
	for index in frames.size():
		sheet.blit_rect(frames[index], Rect2i(0, 0, w, h), Vector2i(0, h * index))
	sheet.save_png("%s/donus.png" % SHOT_DIR)
	print("  -> donus.png ", sheet.get_size(), " (%.2f sn, %d kare)" % [SECONDS, FRAMES])

func _figure(root: Node, kind: String, centre_x: float, box: Vector2) -> WalkFigure:
	var figure := WalkFigure.new()
	figure.size = box
	figure.position = Vector2(centre_x - box.x * 0.5, GROUND_Y - box.y)
	root.add_child(figure)
	figure.set_kind(kind, "bandit")
	return figure

func _fresh() -> Node:
	for child in get_root().get_children():
		get_root().remove_child(child)
		child.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.80, 0.76, 0.66)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(bg)
	return get_root()

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())

func _settle() -> void:
	for _frame in 3:
		await process_frame

## İnsanın diz / bel / omuz hizaları. Ayrı bir `Control`, çünkü figürlerin
## *üstüne* çizilmesi gerekiyor.
class GuideLines:
	extends Control
	var _ground: float = 0.0
	var _person: float = 0.0

	func setup(ground: float, person: float) -> void:
		_ground = ground
		_person = person
		z_index = 50
		queue_redraw()

	func _draw() -> void:
		# İnsan oranları: diz %28, bel %60, omuz %82.
		for row in [[0.28, "diz"], [0.60, "bel"], [0.82, "omuz"]]:
			var y := _ground - _person * float(row[0])
			draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.75, 0.2, 0.15, 0.75), 1.0)
			draw_string(
				ThemeDB.fallback_font, Vector2(6.0, y - 3.0), String(row[1]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.12, 0.08)
			)
		draw_line(
			Vector2(0.0, _ground), Vector2(size.x, _ground), Color(0.25, 0.2, 0.15), 2.0
		)
