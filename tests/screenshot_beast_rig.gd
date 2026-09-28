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
## Beyaz at/eşek/erkek geyik/geyik/husky henüz hiçbir oyun mekaniğine
## bağlanmadı (bkz. CLAUDE.md Ana Hedefler) - `WalkFigure`/`CombatFigure`
## hâlâ yalnızca at/öküz/kurt biliyor. `BeastProbe` bu beşini o bağlanmayı
## beklemeden, `BeastRig`'in çizdiği yerden doğrudan gösteriyor - aynı
## `_draw_beast_sprites()` deseni (yer noktası, `draw_pose`, `draw_species`),
## yeni bir çizim yolu değil.
##
## **Ayrı bir kareye, ayrı bir dosyaya basılıyorlar - sekiz türün tamamını
## (at/öküz/kurt/beyaz at/eşek/erkek geyik/geyik/husky) tek bir karede
## toplamak ölçülerek terk edildi.** Yazılım rasterleyicisi (llvmpipe,
## Vulkan'sız bu ortamda çalışan) aynı karede yirmi dörtten fazla ayrı
## `Texture2D` etkin olduğunda bir dokuyu değil - her sütunun son çizilen
## türünü, kendinden bir önceki türün dokusuyla çiziyordu: eşek/geyik/
## erkek geyik/beyaz at/husky sırayla en sona konunca en son konan hep
## kendinden öncekinin resmiyle çıktı, kod ya da veri tarafında hiçbir hata
## yokken (her ihtimal tek tek doğrulandı: köşe verisi, doku RID'i, doku
## piksel içeriği - hatta husky'nin dokusu kırmızıya boyanıp yeniden
## denendi, yine de bir önceki türün rengiyle çıktı). Sekiz tür + üç katman
## + sekiz sütun aynı karede otuzun üstünde eşsiz doku demekti; beş yeni
## türü kendi karesine ayırmak (on beş doku) sorunu tamamen ortadan
## kaldırdı - `five_only` denemesi bunu doğruladı.
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

## `WalkFigure._draw_beast_sprites()`'ın aynısı, bir tür WalkFigure'a hiç
## bağlanmadan da sınanabilsin diye - motoru koşturan bir düğüm bağlanmıyor,
## yalnızca `BeastRig`'in zaten sözleşme testlerinden geçmiş çizim kapısı.
class BeastProbe extends Control:
	var species: String = ""
	var phase: float = 0.0
	var motion: float = 1.0
	var facing: float = 1.0

	func _draw() -> void:
		var h := size.y * 0.70
		var ground := Vector2(size.x * 0.5, size.y * 0.94)
		var joints := BeastRig.draw_pose(species, ground, h, phase, motion, facing)
		var span := h * BeastRig.body_span(species)
		ArtDraw.ellipse(self, ground, Vector2(span * 0.75, h * 0.030), Color(0.0, 0.0, 0.0, 0.24))
		BeastRig.draw_species(self, species, joints, h, facing, Color(1.0, 1.0, 1.0, 1.0))

func _init() -> void:
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	await _shoot_original_three()
	await _shoot_new_five()
	quit()

## At, öküz, kurt - `WalkFigure`/`CombatFigure` üzerinden, gerçek oyun
## çizim yolu.
func _shoot_original_three() -> void:
	var cols := PHASES
	var rows := 3
	var view_size := Vector2i(int(CELL.x * cols), int(CELL.y * rows))
	_resize(view_size)

	var root := get_root()
	root.add_child(_backdrop())

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
	_clear_root()
	await process_frame

## Beyaz at, eşek, erkek geyik, geyik, husky - `BeastProbe` üzerinden,
## `BeastRig`'in kendisi. Kendi karesi: bkz. dosya başındaki not.
func _shoot_new_five() -> void:
	var cols := PHASES
	var probe_species := ["horse_white", "donkey", "stag", "deer", "husky"]
	var view_size := Vector2i(int(CELL.x * cols), int(CELL.y * probe_species.size()))
	_resize(view_size)

	var root := get_root()
	root.add_child(_backdrop())

	for col in range(cols):
		var phase := TAU * float(col) / float(cols)
		for row in probe_species.size():
			var probe := BeastProbe.new()
			probe.species = probe_species[row]
			probe.phase = phase
			probe.size = CELL * 0.62
			probe.position = Vector2(col * CELL.x + CELL.x * 0.19, CELL.y * row + CELL.y * 0.16)
			root.add_child(probe)

	await _settle()
	_save("beast_gait_sweep_new_species.png")
	_clear_root()

func _resize(view_size: Vector2i) -> void:
	var root := get_root()
	root.size = view_size
	DisplayServer.window_set_size(view_size)

func _backdrop() -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.55, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	return bg

func _clear_root() -> void:
	for child in get_root().get_children():
		child.queue_free()

func _settle() -> void:
	for i in range(6):
		await process_frame

func _save(name: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png(SHOT_DIR.path_join(name))
	print("saved ", ProjectSettings.globalize_path(SHOT_DIR.path_join(name)))
