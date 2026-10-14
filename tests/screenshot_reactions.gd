extends SceneTree

## Tepki ve büyü kliplerinin gerçek 3B kareleri (test değil): her satır bir
## klip, sütunlar klibin ilerleyişi. Giyinik bir muhafız ve büyücü.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1600x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_reactions.gd

const CLIPS: Array[String] = ["hit_pierce", "hit_slash", "dodge", "defend", "react_burn", "react_freeze", "react_poison", "attack_cast"]
const STEPS: Array[float] = [0.0, 0.3, 0.55, 0.8]
const CELL: Vector2 = Vector2(150.0, 200.0)
const OUT: String = "user://reactions.png"

func _init() -> void:
	WaybookTheme.install()
	var cols := STEPS.size() * 2
	var size := Vector2(150.0 + CELL.x * cols, 20.0 + CELL.y * CLIPS.size())
	get_root().size = Vector2i(size)
	var root := Control.new()
	root.size = size
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.14, 0.13)
	bg.size = size
	root.add_child(bg)
	get_root().add_child(root)
	for r in CLIPS.size():
		var label := Label.new()
		label.text = CLIPS[r]
		label.position = Vector2(8, 20 + r * CELL.y + CELL.y * 0.4)
		root.add_child(label)
		for c in cols:
			var fig := CombatFigure.new()
			fig.size = CELL - Vector2(10, 10)
			fig.position = Vector2(150.0 + c * CELL.x, 20.0 + r * CELL.y)
			root.add_child(fig)
			if c < STEPS.size():
				fig.setup("guard", true, "ok", 0.0, {"shirt": "linen_tunic", "pants": "viking_pants", "shoes": "riding_boots"},
					PackedStringArray(), CharacterData.get_skin_tone_color(1), 1.0, "body_female_average")
			else:
				fig.setup("rogue_mage", false, "ok", 0.0, {"jacket": "mage_robe", "hat": "wizard_hat", "shoes": "felt_shoes"},
					PackedStringArray(), CombatFigure.SKIN_PALE, 1.0, "body_male_lean")
			fig.set_action(CLIPS[r], STEPS[c % STEPS.size()])
	for i in 4:
		await process_frame
	get_root().get_texture().get_image().save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT))
	quit()
