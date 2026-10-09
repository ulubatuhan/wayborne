## Kare kümelerinin oyundaki hâli: insanın savaş klipleri (silah eldeyken),
## yolda sırttaki silah ve heybe, botlu yürüyüş, ölü/yerde pozları; altta
## her hayvanın yürüyüş/saldırı/darbe/ölü kareleri. Pozun kendisini
## (çubuk figür) tests/screenshot_poses.gd basıyor; bu, render'ın oyunun
## kendi çizicisinden (WalkFigure) geçmiş hâli.
##
##   godot --path . --rendering-driver opengl3 --script res://tests/screenshot_actions.gd [-- body_female_lean]
extends SceneTree

const CELL: Vector2 = Vector2(150.0, 210.0)
const FIGURE_H: float = 160.0
const OUT: String = "user://actions.png"

## [etiket, arketip, aksiyon, zaman, savaş duruşu, heybe, kıyafet, hareket]
const HUMAN_ROWS: Array = [
	[["yay bekler", "hunter", "", 0.0, true, false, {}, 0.0],
	 ["yay nişan", "hunter", "aim_bow", 0.0, true, false, {}, 0.0],
	 ["yay atış", "hunter", "attack_bow", 0.5, true, false, {}, 0.0],
	 ["kılıç kalkış", "bandit", "attack_swing", 0.3, true, false, {}, 0.0],
	 ["kılıç vuruş", "bandit", "attack_swing", 0.65, true, false, {}, 0.0],
	 ["mızrak", "guard", "attack_thrust", 0.6, true, false, {}, 0.0],
	 ["darbe", "breaker", "hit", 0.35, true, false, {}, 0.0],
	 ["savunma", "guard", "defend", 1.0, true, false, {}, 0.0]],
	[["yolda yay sırtta", "hunter", "", 0.0, false, false, {}, 1.0],
	 ["yolda kılıç belde", "bandit", "", 0.0, false, false, {}, 1.0],
	 ["yolda mızrak", "guard", "", 0.0, false, false, {}, 1.0],
	 ["heybe", "clerk", "", 0.0, false, true, {}, 1.0],
	 ["çizme", "clerk", "", 0.0, false, false, {"shoes": "ranger_boots"}, 1.0],
	 ["ölü", "guard", "dead", 0.0, true, false, {}, 0.0],
	 ["yerde", "guard", "downed", 0.0, true, false, {}, 0.0]],
]
const BEASTS: Array[String] = ["horse", "ox", "wolf", "bear", "boar", "stag", "deer", "donkey", "husky", "horse_white"]
const BEAST_CLIPS: Array = [["walk", 0.0, 1.0], ["attack", 0.5, 0.0], ["hit", 0.5, 0.0], ["downed", 0.0, 0.0], ["dead", 0.0, 0.0]]

func _init() -> void:
	WaybookTheme.install()
	var args := OS.get_cmdline_user_args()
	var body := String(args[0]) if args.size() > 0 else "body_male_average"
	var rows := HUMAN_ROWS.size() + BEASTS.size()
	var size := Vector2(20.0 + CELL.x * 8.0, 20.0 + CELL.y * HUMAN_ROWS.size() + CELL.y * 0.62 * BEASTS.size())
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.82, 0.80, 0.74)
	bg.size = size
	root.add_child(bg)
	var y := 10.0
	for r in HUMAN_ROWS.size():
		var row: Array = HUMAN_ROWS[r]
		for c in row.size():
			var spec: Array = row[c]
			var f := WalkFigure.new()
			f.size = Vector2(CELL.x, FIGURE_H)
			f.position = Vector2(10.0 + CELL.x * c, y + CELL.y - 20.0 - FIGURE_H)
			f.set_kind(WalkFigure.KIND_PERSON, spec[1], 1.0, CharacterData.get_skin_tone_color(1),
				spec[5], spec[6], body)
			f.set_combat_stance(spec[4])
			f.set_action(spec[2], spec[3])
			f.set_phase_offset(1.3)
			f.advance(0.0, spec[7])
			if spec[7] == 0.0:
				f.set_standing()
			root.add_child(f)
			_label(root, spec[0], Vector2(10.0 + CELL.x * c + 8.0, y + CELL.y - 18.0))
		_ground(root, y + CELL.y - 20.0, size.x)
		y += CELL.y
	var beast_h := CELL.y * 0.62
	for b in BEASTS.size():
		for c in BEAST_CLIPS.size():
			var clip: Array = BEAST_CLIPS[c]
			var f := WalkFigure.new()
			f.size = Vector2(CELL.x * 1.5, beast_h * 0.9)
			f.position = Vector2(10.0 + CELL.x * 1.5 * c, y + beast_h - 10.0 - f.size.y)
			var kind := WalkFigure.KIND_DOG if BEASTS[b] == "husky" else WalkFigure.KIND_DONKEY
			f.set_kind(kind, "bandit")
			f.set_action("" if clip[0] == "walk" else String(clip[0]), float(clip[1]))
			f.advance(0.0, float(clip[2]))
			f.set_beast_species(BEASTS[b])
			root.add_child(f)
		_label(root, BEASTS[b], Vector2(10.0 + CELL.x * 7.6, y + beast_h * 0.4))
		_ground(root, y + beast_h - 10.0, size.x)
		y += beast_h
	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(size)
	get_root().size = Vector2i(size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size(), " satir ", rows)
	quit()

func _label(root: Control, text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", 13)
	root.add_child(l)

func _ground(root: Control, y: float, w: float) -> void:
	var g := ColorRect.new()
	g.color = Color(0.45, 0.4, 0.35)
	g.size = Vector2(w, 2.0)
	g.position = Vector2(0.0, y)
	root.add_child(g)
