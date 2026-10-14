extends SceneTree

## Savaş efektlerinin inceleme sayfası (test değil): üst sırada mankenler
## süren durumlarıyla (kanama, yanma, zehir, üşüme, sersemlik) ve üstlerinde
## saplı kalan oklar/bıçakla; alt sıralarda büyülerin ve vuruşların
## uçuşta ve çarpmada dondurulmuş kareleri.
##
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1600x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_combat_fx.gd

const OUT: String = "user://combat_fx.png"
const W: int = 1800
const H: int = 1180
const FIG: Vector2 = Vector2(170.0, 250.0)

func _init() -> void:
	TranslationServer.set_locale("tr")
	WaybookTheme.install()
	get_root().size = Vector2i(W, H)
	var root := Control.new()
	root.size = Vector2(W, H)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.14, 0.13)
	bg.size = root.size
	root.add_child(bg)
	get_root().add_child(root)

	var outfit := {"shirt": "linen_tunic", "pants": "viking_pants", "shoes": "riding_boots"}
	var rows := [
		["(yok)", PackedStringArray(), []],
		["kanama", PackedStringArray([CombatUnit.STATUS_BLEED]), []],
		["yanma", PackedStringArray([CombatUnit.STATUS_BURN]), []],
		["zehir", PackedStringArray([CombatUnit.STATUS_BLIGHT]), []],
		["üşüme", PackedStringArray([CombatUnit.STATUS_CHILL]), []],
		["sersem", PackedStringArray([CombatUnit.STATUS_STUN]), []],
		["2 ok + bıçak", PackedStringArray(), ["arrow", "arrow", "dagger"]],
		["büyücü", PackedStringArray(), []],
	]
	for i in rows.size():
		var fig := CombatFigure.new()
		fig.size = FIG
		fig.position = Vector2(20.0 + i * (FIG.x + 50.0), 40.0)
		root.add_child(fig)
		if i == rows.size() - 1:
			fig.setup("rogue_mage", false, "ok", 0.0, {"jacket": "mage_robe", "hat": "wizard_hat", "shoes": "felt_shoes"},
				PackedStringArray(), CombatFigure.SKIN_PALE, 1.0, "body_male_lean")
		else:
			fig.setup("guard", true, "ok", 0.0, outfit, PackedStringArray(), CharacterData.get_skin_tone_color(1), 1.0, "body_male_average")
		var unit := CombatUnit.new()
		for k in rows[i][2]:
			unit.add_stuck(String(k))
		fig.set_conditions(rows[i][1], unit.stuck)
		fig.set_stunned(rows[i][1].has(CombatUnit.STATUS_STUN))
		_label(root, String(rows[i][0]), fig.position + Vector2(0, -26))

	var layer := CombatFxLayer.new()
	layer.size = root.size
	root.add_child(layer)
	var now := 100000
	var y1 := 400.0
	var travels := [["ok", "arrow", "pierce"], ["bıçak", "thrown", "pierce"], ["sapan", "sling", "blunt"],
		["şişe", "flask", "poison"], ["Ateş Oku", "bolt", "fire"], ["Büyülü Füze", "missiles", "arcane"],
		["Ayaz Işını", "ray", "frost"], ["Uyku", "ray", "sleep"], ["Zehir Püskürtme", "spray", "poison"],
		["Yakıcı Eller", "cone", "fire"]]
	for i in travels.size():
		var col := i % 5
		var row := i / 5
		var from := Vector2(60.0 + col * 350.0, y1 + row * 190.0)
		var to := from + Vector2(260.0, 0.0)
		var delivery := String(travels[i][1])
		var span := CombatFxLayer.travel_msec(delivery)
		layer.play_attack(from, to, delivery, String(travels[i][2]), true, now - int(span * 0.55))
		_label(root, String(travels[i][0]), from + Vector2(0, -70))
	var styles := [["delici", "pierce"], ["kesici", "slash"], ["ezici", "blunt"], ["ateş", "fire"], ["buz", "frost"],
		["zehir", "poison"], ["büyü", "arcane"], ["uyku", "sleep"]]
	for i in styles.size():
		var at := Vector2(110.0 + i * 210.0, 900.0)
		layer.play_attack(at - Vector2(100, 0), at, "", String(styles[i][1]), true, now - 120)
		_label(root, String(styles[i][0]), at + Vector2(-40, 70))
	layer.play_attack(Vector2(1700, 1080), Vector2(1700, 1080), "aura", "arcane", true, now - 150)
	_label(root, "Büyü Kalkanı", Vector2(1640, 1130))
	layer.play_attack(Vector2(1300, 1080), Vector2(1480, 1080), "", "pierce", false, now - 120)
	_label(root, "ıskalama (kaçındı)", Vector2(1360, 1130))
	layer.draw_at(now)
	for i in 6:
		await process_frame
	get_root().get_texture().get_image().save_png(OUT)
	print("yazildi: ", ProjectSettings.globalize_path(OUT))
	quit()

func _label(root: Control, text: String, at: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	root.add_child(l)
