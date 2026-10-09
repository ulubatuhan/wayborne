## Giyilip çıkarılabilen kıyafetler, yürüyüş boyunca: her satır bir beden x
## takım, sütunlar yürüyüşün sekiz fazı ve dört aksiyon klibi. Kesilmiş ya da
## kare kare bindirilen her içerik bir fazda değil, döngü boyunca kanıtlanır
## (bkz. CLAUDE.md Wardrobe & Rig Rules) - bilekte/dizde açılan bir boşluk,
## kayan bir paça ancak böyle görünür.
##
##   godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_outfits.gd [-- body_male_average ...]
extends SceneTree

const SETS: Array[Dictionary] = [
	{"shirt": "peasant_shirt", "pants": "peasant_pants", "shoes": "peasant_shoes"},
	{"shirt": "peasant_shirt", "jacket": "ranger_jacket", "pants": "ranger_pants",
		"shoes": "ranger_boots", "hat": "ranger_hood"},
]
const PHASES: int = 8
const ACTIONS: Array[String] = ["idle", "attack_swing", "hit", "dead"]
const CELL: Vector2 = Vector2(110.0, 230.0)
const FIGURE_H: float = 190.0
const MARGIN: float = 16.0
const OUT: String = "user://outfits.png"

func _init() -> void:
	WaybookTheme.install()
	var bodies: Array[String] = []
	for arg in OS.get_cmdline_user_args():
		bodies.append(String(arg))
	if bodies.is_empty():
		bodies = ["body_male_average", "body_female_average", "body_male_heavy", "body_female_lean"]
	var rows := bodies.size() * SETS.size()
	var cols := PHASES + ACTIONS.size()
	var size := Vector2(MARGIN * 2.0 + CELL.x * cols, MARGIN * 2.0 + CELL.y * rows)
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.82, 0.80, 0.76)
	bg.size = size
	root.add_child(bg)
	var row := 0
	for body in bodies:
		for outfit in SETS:
			var ground_y := MARGIN + CELL.y * (row + 1) - 12.0
			var line := ColorRect.new()
			line.color = Color(0.45, 0.40, 0.36)
			line.size = Vector2(size.x - MARGIN * 2.0, 2.0)
			line.position = Vector2(MARGIN, ground_y)
			root.add_child(line)
			for col in cols:
				var f := WalkFigure.new()
				f.size = Vector2(CELL.x, FIGURE_H)
				f.position = Vector2(MARGIN + CELL.x * col, ground_y - FIGURE_H)
				f.set_kind(WalkFigure.KIND_PERSON, "guard", 1.0,
					CharacterData.get_skin_tone_color(1), false, outfit, body)
				if col < PHASES:
					f.set_phase_offset(TAU * float(col) / float(PHASES))
					f.advance(0.0, 1.0)
				else:
					f.set_standing()
					var action := ACTIONS[col - PHASES]
					if action != "idle":
						f.set_action(action, 0.6)
				root.add_child(f)
			row += 1
	get_root().add_child(root)
	get_root().content_scale_size = Vector2i(size)
	await process_frame
	await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " ", image.get_size())
	quit()
