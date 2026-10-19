extends RefCounted

## Ganimet (Y-C03), sarf malzemesi (Y-C04) ve atölye döngüsü (Y-F03):
## tablolardaki her kimlik gerçek, zar tohumlu, ganimet kervana ve dolaba
## düşer; sargı ve iksir savaşta işler ve kampta sargı harcanır; her tarifin
## bir tüketicisi var.

func suite_name() -> String:
	return "LootAndCraft"

func run(t) -> void:
	_test_loot_tables(t)
	_test_consumables(t)
	_test_recipes_have_consumers(t)

func _session() -> GameSession:
	var session := GameSession.new(500, 30, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	session.start_playthrough(CharacterData.create("Kurucu", CultureCatalog.VALLEY, CharacterStats.new()), rng)
	return session

func _test_loot_tables(t) -> void:
	for kind in ["bandit", "wildlife", "guard", "hunt"]:
		var table := LootTable.table_for(kind)
		t.ok(not table.is_empty(), "%s ganimet tablosu var" % kind)
		for entry in table:
			var id := String(entry["id"])
			match String(entry["type"]):
				"item":
					t.ok(ItemCatalog.get_item(id) != null, "eşya gerçek: %s" % id)
				"outfit":
					t.ok(OutfitCatalog.get_piece(id) != null, "kıyafet gerçek: %s" % id)
				"equipment":
					t.ok(EquipmentCatalog.get_equipment(id) != null, "ekipman gerçek: %s" % id)
	var a := RandomNumberGenerator.new()
	a.seed = 5
	var b := RandomNumberGenerator.new()
	b.seed = 5
	t.eq(LootTable.roll("bandit", 0.5, a), LootTable.roll("bandit", 0.5, b), "aynı tohum aynı ganimet")
	var session := _session()
	var drops: Array[Dictionary] = [
		{"type": "item", "id": "test_furs", "qty": 2},
		{"type": "outfit", "id": "fur_hat", "qty": 1},
		{"type": "equipment", "id": EquipmentCatalog.AMULET_WOLF_FANG, "qty": 1},
	]
	var lines := LootTable.apply(session, drops)
	t.eq(lines.size(), 3, "üç ganimet de kondu")
	t.eq(session.get_total_quantity("test_furs"), 2, "eşya kargoda")
	t.ok(int(session.outfit_inventory.get("fur_hat", 0)) >= 1, "kıyafet dolapta")
	t.eq(session.get_equipment_count(EquipmentCatalog.AMULET_WOLF_FANG), 1, "ekipman dolapta")
	var effects: Array[EventEffect] = [EventEffect.make(EventEffect.Type.GRANT_OUTFIT, 1, "leather_cap")]
	EventEffectApplier.apply(effects, session)
	t.ok(int(session.outfit_inventory.get("leather_cap", 0)) >= 1, "olaydan kıyafet dolaba düşer")

func _test_consumables(t) -> void:
	var hurt := CombatUnit.new()
	hurt.display_name = "Yaralı"
	hurt.is_player_side = true
	hurt.max_hp = 30
	hurt.current_hp = 5
	hurt.initiative = 99
	hurt.apply_status(CombatUnit.STATUS_BLEED, 2, 3)
	var foe := CombatUnit.new()
	foe.display_name = "Düşman"
	foe.max_hp = 20
	foe.current_hp = 20
	foe.initiative = 0
	var party: Array[CombatUnit] = [hurt]
	var foes: Array[CombatUnit] = [foe]
	var encounter := CombatEncounter.new(party, foes, RandomNumberGenerator.new())
	encounter.start()
	if encounter.is_player_turn():
		t.ok(encounter.use_consumable(CombatEncounter.CONSUMABLE_BANDAGE, hurt), "sargı kullanılır")
		t.ok(hurt.current_hp >= 5 + CombatEncounter.BANDAGE_HEAL - 6, "sargı can verir")
		t.not_ok(hurt.has_status(CombatUnit.STATUS_BLEED), "sargı kanamayı durdurur")
	t.not_ok(encounter.use_consumable("uydurma", hurt), "bilinmeyen sarf kullanılmaz")
	var session := _session()
	var someone := session.get_party()[0]
	someone.current_hp = 1
	session.add_to_cargo(ItemCatalog.get_item(CombatEncounter.CONSUMABLE_BANDAGE), 1)
	session.apply_camp_actions([GameSession.CAMP_ACTION_WOUNDS])
	t.eq(session.get_total_quantity(CombatEncounter.CONSUMABLE_BANDAGE), 0, "kampta sargı harcanır")
	t.ok(someone.current_hp >= 1 + int(ceil(someone.get_max_hp() * GameSession.CAMP_WOUND_HEAL_SHARE * 2.0)) - 1, "sargıyla bakım iki kat")

func _test_recipes_have_consumers(t) -> void:
	for recipe in RecipeCatalog.get_recipes():
		var output := "wagon_repair" if recipe.effect == CraftingRecipe.Effect.WAGON_REPAIR else recipe.output_item_id
		t.ok(RecipeCatalog.OUTPUT_USES.has(output), "%s tarifinin çıktısını tüketen var" % recipe.recipe_id)
	var session := _session()
	var wagon := session.wagon_inventories[0]
	wagon.add_item(ItemCatalog.get_item("test_furs"), 2)
	t.ok(session.craft_in_wagon(0, RecipeCatalog.SEW_FUR_HAT), "kürk başlık dikilir")
	t.ok(int(session.outfit_inventory.get("fur_hat", 0)) >= 1, "başlık dolapta")
	wagon.add_item(ItemCatalog.get_item("fish"), 2)
	t.ok(session.craft_in_wagon(0, RecipeCatalog.RENDER_FISH_OIL), "balık yağı kaynar")
	session.add_to_cargo(ItemCatalog.get_item(ItemCatalog.LANTERN), 1)
	t.ok(session.light_for_night(GameSession.LIGHT_LANTERN), "yağ fenerde yanar")
	wagon.add_item(ItemCatalog.get_item("test_cloth"), 1)
	t.ok(session.craft_in_wagon(0, RecipeCatalog.MAKE_TORCHES), "meşale sarılır")
	t.ok(session.light_for_night(GameSession.LIGHT_TORCH), "meşale gecede yanar")
