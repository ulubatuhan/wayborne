extends SceneTree

## Savaş ekranının görsel doğrulama aracı. **Test değil** - hiçbir şeyi
## doğrulamaz, üç PNG basar (bkz. simulate_journeys.gd deseni).
##
## Var olma sebebi: bu depo headless koşuyor ve bir arayüz değişikliğinin
## gerçekten *nasıl göründüğü* uzun süre hiç görülemedi. Savaş alanı ilk
## yazıldığında ekran görüntüsü alınmadan "yapısal testler geçiyor" diye
## bitmiş sayıldı; alınan görüntü figürlerin renkli dikdörtgen, ışığın
## ekranı yutan turuncu bir küre olduğunu gösterdi. Yapı testi düzeni
## doğrular, görüntüyü doğrulamaz.
##
## Koşturmak (sanal ekran ve yazılım rasterizer gerekiyor, çünkü ortamda
## Vulkan yok):
##
##   godot --headless --import
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1600x900x24" \
##     godot --path . --rendering-driver opengl3 \
##     --script res://tests/screenshot_combat.gd
##
## Çıktı `user://combat_shots/` altına düşer; Godot bunu
## `~/.local/share/godot/app_userdata/<proje>/` içinde tutar ve yol
## koşu sonunda basılır.

const SHOT_DIR: String = "user://combat_shots"
const VIEW_SIZE: Vector2i = Vector2i(1600, 900)
const SEED_VALUE: int = 4242

func _init() -> void:
	# Görüntüler kaynak dilde alınsın: UserSettings autoload'u birkaç kare
	# sonra sistem dilini uyguluyor, yoksa kareler farklı dillerde çıkıyor.
	TranslationServer.set_locale("tr")
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)

	var root := get_root()
	root.size = VIEW_SIZE

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	root.add_child(margin)

	var panel := CombatPanel.new()
	margin.add_child(panel)

	var rng := RandomNumberGenerator.new()
	rng.seed = SEED_VALUE
	panel.start_combat(_build_party(), 0.65, rng, "bandit", "")

	await _settle()
	_save("01_acilis.png")

	_select_first_usable_skill(panel)
	await _settle()
	_save("02_hedef_secimi.png")

	# Lideri kıyıya sokuyoruz: silüetin duruşu, rengi ve durum işareti
	# gerçekten değişiyor mu?
	panel._encounter.player_units[0].apply_damage(9999)
	panel._refresh()
	await _settle()
	_save("03_olumun_kiyisi.png")

	# Hareket katmanı (bkz. CombatFx): bir kritik anı, bir durum halkası ve
	# bir düşüşün ortası. Zaman burada donduruluyor - `_process` kapalı,
	# kare `_animate`'e sabit bir an verilerek çiziliyor, yoksa yazılımsal
	# rasterleştiricinin yavaşlığı her çalıştırmada başka bir anı yakalar.
	var enemies: Array[CombatUnit] = panel._encounter.enemy_units
	var start := Time.get_ticks_msec()
	enemies[0].current_hp -= 7
	panel._on_unit_barked(enemies[0], tr("CBT_BARK_CRIT"), CombatEncounter.BARK_CRIT)
	panel._on_unit_barked(enemies[1], "", CombatEncounter.BARK_STATUS_BLEED)
	panel._refresh()
	panel.set_process(false)
	panel._flash_states[enemies[0]]["start"] = start
	panel._ring_states[enemies[1]]["start"] = start
	panel._shake["start"] = start
	panel._numbers[panel._numbers.size() - 1]["start"] = start
	await _settle()
	panel._animate(start + 90)
	await _settle()
	_save("04_kritik_ani.png")

	var victim := enemies[enemies.size() - 1]
	victim.apply_damage(9999)
	panel._on_unit_barked(victim, tr("CBT_BARK_KILLED"), CombatEncounter.BARK_KILLED)
	panel._refresh()
	panel.set_process(false)
	var fall_start := Time.get_ticks_msec()
	panel._fall_states[victim]["start"] = fall_start
	await _settle()
	panel._animate(fall_start + 170)
	await _settle()
	_save("05_dusus_ortasi.png")

	print("Görüntüler: ", ProjectSettings.globalize_path(SHOT_DIR))
	quit(0)

## Parti bilerek karışık sınıflı: dört sınıfın silüeti tek karede
## görülebilsin, hepsi aynı çizilmiyor mu diye bakılabilsin.
func _build_party() -> Array[CharacterData]:
	var party: Array[CharacterData] = []
	var culture := CultureCatalog.get_cultures()[0]
	var classes := [
		ClassCatalog.GUARD, ClassCatalog.HUNTER, ClassCatalog.BREAKER, ClassCatalog.CLERK
	]
	for index in classes.size():
		var character := CharacterData.create(
			culture.name_pool[index % culture.name_pool.size()],
			culture.culture_id, CharacterStats.new(),
			CharacterData.DEFAULT_HEIGHT_CM, 1, String(classes[index])
		)
		if index == 0:
			character.is_player = true
		party.append(character)
	return party

func _select_first_usable_skill(panel) -> void:
	var active: CombatUnit = panel._encounter.get_active_unit()
	for skill in active.skills:
		if active.can_use_skill(skill) and not panel._encounter.get_valid_targets(active, skill).is_empty():
			panel._on_skill_pressed(skill)
			return

## Kapsayıcıların boyutlanıp `_draw()`'ların koşması için birkaç kare.
func _settle() -> void:
	for _frame in 6:
		await process_frame

func _save(file_name: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png("%s/%s" % [SHOT_DIR, file_name])
	print("  -> ", file_name, " ", image.get_size())
