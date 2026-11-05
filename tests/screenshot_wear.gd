extends SceneTree

## Açlık ve yorgunluğun bedende görünmesini (P16) fotoğraflayan araç.
## **Test değil** - PNG basar.
##
## Neden gerekli: değişen şey duruş, adım ve ten rengi. Testler sayıların
## yönünü doğruluyor; "bakınca aşınmış görünüyor mu, yoksa çizim hatası
## gibi mi duruyor" sorusunu yalnız ekran cevaplar (Y-K01). Kar ve ıslaklık
## turunda tam bu soruda dört deneme düşmüştü.
##
## Koşturmak:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_wear.gd

const SHOT_DIR: String = "user://wear_shots"
const VIEW: Vector2i = Vector2i(1280, 720)
const FIGURE_BOX: Vector2 = Vector2(260, 560)

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var root := get_root()
	root.size = VIEW
	DisplayServer.window_set_size(VIEW)
	await _settle()

	# Dört hâl yan yana: tok · aç · yorgun · ikisi birden. Yan yana
	# olmazsa fark görülmüyor - tek kare aşınmayı değil figürü gösterir.
	var holder := HBoxContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.add_theme_constant_override("separation", 40)
	root.add_child(holder)
	var states := [
		["tok", 0.0, 0.0],
		["ac", 1.0, 0.0],
		["yorgun", 0.0, 1.0],
		["ikisi", 1.0, 1.0],
	]
	for state in states:
		var figure := WalkFigure.new()
		figure.custom_minimum_size = FIGURE_BOX
		# HBox çocuğa kendi boyunu veriyor; figür `size.y`'den ölçtüğü için
		# kutuyu büyütünce figür taşıyordu.
		figure.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		figure.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		holder.add_child(figure)
		figure.set_kind(
			WalkFigure.KIND_PERSON, "guard", 1.0, WalkFigure.FALLBACK_SKIN, false,
			OutfitCatalog.with_rolled_hair({}, CharacterData.GENDER_MALE, 7919), BodyFrames.CREW_BODY
		)
		# Aynı adım anı: fark duruşta görülsün, yürüyüşün rastgele yerinde değil.
		figure.set_phase_offset(0.0)
		figure.set_wear(float(state[1]), float(state[2]))
	await _settle()
	_save("01_asinma_dizisi.png")
	print("sıra: tok · aç · yorgun · ikisi birden")
	print("bitti")
	quit()

func _settle() -> void:
	for _frame in 8:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name)
