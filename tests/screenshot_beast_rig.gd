extends SceneTree

## BeastRig'in görsel doğrulama aracı - screenshot_combat.gd'nin deseni:
## hiçbir şeyi doğrulamaz, PNG basar. `has_sprites()` true olan türler için
## gerçek WalkFigure/CombatFigure çizimini gösteriyor - bir tür sanata
## kavuştuğunda pivot/ölçek/döndürme hatası ilk burada görünür, yapısal
## testler (`test_beast_rig.gd`) yalnızca sözleşmeyi doğrular, görüntüyü
## değil (bkz. CLAUDE.md Testing bölümü).
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_beast_rig.gd
##
## Çıktı user://beast_check/ altına düşer.

const SHOT_DIR: String = "user://beast_check"
const VIEW_SIZE: Vector2i = Vector2i(1400, 700)

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE

	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.55, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var horse := WalkFigure.new()
	horse.size = Vector2(220, 160)
	horse.position = Vector2(60, 100)
	root.add_child(horse)
	horse.set_kind(WalkFigure.KIND_HORSE, "bandit")

	var ox := WalkFigure.new()
	ox.size = Vector2(220, 160)
	ox.position = Vector2(340, 100)
	root.add_child(ox)
	ox.set_kind(WalkFigure.KIND_OX, "bandit")

	var wolf := CombatFigure.new()
	wolf.size = Vector2(200, 200)
	wolf.position = Vector2(640, 80)
	root.add_child(wolf)
	wolf.setup("wolf", true, "", 0.0)

	# İkinci satır: BeastRig.PAINT_PHASE'e yakın bir yürüyüş anı (bacaklar
	# ayrık) - kurt ayrıca sola bakıyor, ayna testi.
	var horse2 := WalkFigure.new()
	horse2.size = Vector2(220, 160)
	horse2.position = Vector2(60, 340)
	root.add_child(horse2)
	horse2.set_kind(WalkFigure.KIND_HORSE, "bandit")
	horse2.set_phase_offset(PI * 0.25)

	var ox2 := WalkFigure.new()
	ox2.size = Vector2(220, 160)
	ox2.position = Vector2(340, 340)
	root.add_child(ox2)
	ox2.set_kind(WalkFigure.KIND_OX, "bandit")
	ox2.set_phase_offset(PI * 0.25)

	var wolf2 := CombatFigure.new()
	wolf2.size = Vector2(200, 200)
	wolf2.position = Vector2(640, 320)
	root.add_child(wolf2)
	wolf2.setup("wolf", false, "", 0.0)

	await _settle()
	_save("beasts.png")
	quit()

func _settle() -> void:
	for i in range(6):
		await process_frame

func _save(name: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png(SHOT_DIR.path_join(name))
	print("saved ", ProjectSettings.globalize_path(SHOT_DIR.path_join(name)))
