extends SceneTree

## Yol tepkilerini (N31d) giyinik figürle fotoğraflar - test değil, PNG basar.
## Her satır bir beden, sütunlar: duruş, ileri bakış, yorgun bekleyiş.

const SHOT: String = "user://journey_shots/tepkiler.png"
const CLIPS: Array[String] = ["", "look_ahead", "idle_tired"]

func _init() -> void:
	get_root().size = Vector2i(1200, 800)
	var ground := ColorRect.new()
	ground.color = Color(0.62, 0.58, 0.50)
	ground.size = Vector2(1200, 800)
	get_root().add_child(ground)
	var rows := [[CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_AVERAGE], [CharacterData.GENDER_FEMALE, CharacterData.BODY_WEIGHT_AVERAGE]]
	for r in rows.size():
		var character := CharacterData.create("Deneme", CultureCatalog.NOMAD, CharacterStats.new(),
			CharacterData.DEFAULT_HEIGHT_CM, 1, ClassCatalog.GUARD, int(rows[r][0]), int(rows[r][1]))
		for c in CLIPS.size():
			var figure := WalkFigure.new()
			figure.size = Vector2(300, 360)
			figure.position = Vector2(60 + c * 380, 20 + r * 390)
			ground.add_child(figure)
			figure.set_kind(WalkFigure.KIND_PERSON, "villager", 1.0, CharacterData.get_skin_tone_color(character.skin_tone),
				false, character.get_appearance_outfit(), character.get_body_variant_id())
			figure.set_loadout(Wardrobe.loadout_of(character.outfit, character.equipped))
			figure.set_standing()
			figure.set_facing(1.0)
			figure.set_action(CLIPS[c])
	for _frame in 10:
		await process_frame
	DirAccess.make_dir_recursive_absolute("user://journey_shots")
	get_root().get_texture().get_image().save_png(SHOT)
	print("  -> tepkiler.png")
	quit()
