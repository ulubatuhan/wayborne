extends SceneTree

## BeastRig'in görsel doğrulama aracı - screenshot_combat.gd'nin deseni:
## hiçbir şeyi doğrulamaz, PNG basar. `has_sprites()` true olan türler için
## gerçek WalkFigure/CombatFigure çizimini gösteriyor - bir tür sanata
## kavuştuğunda pivot/ölçek/döndürme hatası ilk burada görünür, yapısal
## testler (`test_beast_rig.gd`) yalnızca sözleşmeyi doğrular, görüntüyü
## değil (bkz. CLAUDE.md Testing bölümü).
##
## Hayvanlar parça parça değil, tek parça bir deri (`BeastSkin`) olarak
## çiziliyor: resim kemiklere ağırlıkla bağlı bir ağa gerili, eklem bükülünce
## ağ da bükülüyor. At/öküz (yolda gerçekten yürüyen, KIND_HORSE/OX) tam bir
## yürüyüş çevriminin sekiz fazında taranıyor - dinlenme pozu resmin kendisi,
## bir kıvrım ya da gerilme ancak yürürken görünür.
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_beast_rig.gd
##
## Çıktı user://beast_check/ altına düşer.

const SHOT_DIR: String = "user://beast_check"
const CELL: Vector2 = Vector2(260, 200)
const PHASES: int = 8

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var cols := PHASES
	var rows := 3  # horse, ox, wolf (wolf: CombatFigure, always rest pose)
	var view_size := Vector2i(int(CELL.x * cols), int(CELL.y * rows))

	var root := get_root()
	root.size = view_size

	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.55, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	for col in range(cols):
		var phase := TAU * float(col) / float(cols)

		var horse := WalkFigure.new()
		horse.size = CELL * 0.62
		horse.position = Vector2(col * CELL.x + CELL.x * 0.19, CELL.y * 0.3)
		root.add_child(horse)
		horse.set_kind(WalkFigure.KIND_HORSE, "bandit")
		horse.set_phase_offset(phase)

		var ox := WalkFigure.new()
		ox.size = CELL * 0.62
		ox.position = Vector2(col * CELL.x + CELL.x * 0.19, CELL.y * 1.3)
		root.add_child(ox)
		ox.set_kind(WalkFigure.KIND_OX, "bandit")
		ox.set_phase_offset(phase)

		var wolf := CombatFigure.new()
		wolf.size = CELL * 0.8
		wolf.position = Vector2(col * CELL.x + CELL.x * 0.1, CELL.y * 2.1)
		root.add_child(wolf)
		wolf.setup("wolf", true, "", 0.0)

	await _settle()
	_save("beast_gait_sweep.png")
	quit()

func _settle() -> void:
	for i in range(6):
		await process_frame

func _save(name: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png(SHOT_DIR.path_join(name))
	print("saved ", ProjectSettings.globalize_path(SHOT_DIR.path_join(name)))
