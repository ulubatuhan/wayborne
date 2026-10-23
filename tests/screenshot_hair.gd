extends SceneTree

## Saç (Y-G03) ve büst portreleri (Y-G04): her stil, birkaç renk, şapkalı biri
## (şapka saçı örter) ve aynı kişilerin büstü. Test değil, resim.
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --script res://tests/screenshot_hair.gd -- [beden]

const OUT_DIR: String = "user://screenshots"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	WaybookTheme.install()
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var args := OS.get_cmdline_user_args()
	var body := args[0] if args.size() > 0 else "body_male_average"
	var gender := CharacterData.GENDER_FEMALE if body.contains("female") else CharacterData.GENDER_MALE
	var canvas := ColorRect.new()
	canvas.color = Color(0.20, 0.19, 0.18)
	canvas.size = Vector2(1920, 1080)
	root.add_child(canvas)
	var looks: Array = []
	for i in OutfitCatalog.HAIR_STYLES.size():
		looks.append({"hair": OutfitCatalog.HAIR_STYLES[i], "color": i % OutfitCatalog.HAIR_COLORS.size(), "hat": ""})
	looks.append({"hair": "hair_long01", "color": 3, "hat": "wide_hat"})
	var x := 20.0
	for look in looks:
		var outfit := OutfitCatalog.with_modesty_layer({})
		if not String(look.hat).is_empty():
			outfit[OutfitCatalog.SLOT_HAT] = look.hat
		outfit = OutfitCatalog.with_hair(outfit, String(look.hair), OutfitCatalog.get_hair_color(int(look.color)))
		var fig := FigurePreview.new()
		fig.position = Vector2(x, 20)
		fig.size = Vector2(220, 560)
		canvas.add_child(fig)
		fig.show_look("villager", 1.0, CharacterData.get_skin_tone_color(int(look.color) % 4), outfit,
			PackedStringArray(), body)
		var bust := BustPortrait.new()
		bust.position = Vector2(x + 30, 640)
		bust.size = Vector2(160, 200)
		canvas.add_child(bust)
		bust.show_look(1.0, CharacterData.get_skin_tone_color(int(look.color) % 4), outfit, body, x)
		var label := Label.new()
		label.text = "%s · %s" % [OutfitCatalog.get_hair_style_name(String(look.hair)),
			OutfitCatalog.get_hair_color_name(int(look.color))]
		label.position = Vector2(x, 860)
		canvas.add_child(label)
		x += 236.0
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png("%s/hair_%s.png" % [OUT_DIR, body])
	print("hair screenshot -> ", ProjectSettings.globalize_path(OUT_DIR))
	quit()
