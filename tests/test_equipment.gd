extends RefCounted

## Ekipman (Equipment): katalog şekli, slot doğrulaması, tek parça/slot
## kuralı, türetilmiş değerlere yansıması ve kayıt gidiş-dönüşü.

func suite_name() -> String:
	return "Equipment"

func run(t) -> void:
	_test_catalog_shape(t)
	_test_equip_rejects_wrong_slot(t)
	_test_equip_replaces_previous(t)
	_test_unequip(t)
	_test_derived_values_include_equipment(t)
	_test_dict_round_trip(t)
	_test_level_gate(t)
	_test_synergy(t)
	_test_cursed_and_cost(t)

func _test_catalog_shape(t) -> void:
	var all_equipment := EquipmentCatalog.get_all_equipment()
	t.ok(all_equipment.size() >= 35, "en az 35 parça (görev Y-C06)")

	var seen_ids: Dictionary = {}
	for equipment_resource in all_equipment:
		t.not_ok(seen_ids.has(equipment_resource.equipment_id), "ekipman kimliği tekil: %s" % equipment_resource.equipment_id)
		seen_ids[equipment_resource.equipment_id] = true
		t.ok(EquipmentCatalog.ALL_SLOTS.has(equipment_resource.slot), "slot geçerli bir EquipmentCatalog.SLOT_* değeri")

	t.eq(EquipmentCatalog.get_equipment_for_slot(EquipmentCatalog.SLOT_WEAPON).size(), 6, "altı silah")
	t.eq(EquipmentCatalog.get_equipment_for_slot(EquipmentCatalog.SLOT_ARMOR).size(), 6, "altı zırh")
	t.eq(EquipmentCatalog.get_equipment_for_slot(EquipmentCatalog.SLOT_RING).size(), 12, "on iki yüzük")
	t.eq(EquipmentCatalog.get_equipment_for_slot(EquipmentCatalog.SLOT_AMULET).size(), 12, "on iki kolye")
	for piece in all_equipment:
		t.ok(ResourceLoader.exists("res://data/assets/ui/waybook/eq_%s.png" % piece.equipment_id),
			"%s ikonu var" % piece.equipment_id)
		t.ok(not TranslationServer.translate(piece.display_name_key).begins_with("EQUIP_"), "%s adı çevrilmiş" % piece.equipment_id)
		if not piece.synergy_trait.is_empty():
			t.ok(TraitCatalog.get_trait(piece.synergy_trait) != null, "%s sinerjisi gerçek bir huy" % piece.equipment_id)
		# Lanetli ve bedelli parçalar satılmaz: yalnız bulunur.
		if piece.cursed or piece.daily_stress > 0:
			t.eq(piece.price, 0, "%s satılmaz" % piece.equipment_id)
		t.ok(not EquipmentCatalog.bonus_line(piece).is_empty(), "%s ekranda bir satır okur" % piece.equipment_id)

func _make_character() -> CharacterData:
	return CharacterData.create("Deneme", CultureCatalog.VALLEY, CharacterStats.new())

func _test_equip_rejects_wrong_slot(t) -> void:
	var character := _make_character()
	t.not_ok(
		character.equip(EquipmentCatalog.SLOT_ARMOR, EquipmentCatalog.WEAPON_TIER_1),
		"silah zırh slotuna takılamaz"
	)
	t.not_ok(character.equip(EquipmentCatalog.SLOT_WEAPON, "yok_boyle_bir_ekipman"), "katalogda olmayan parça reddedilir")
	t.eq(character.get_equipped(EquipmentCatalog.SLOT_WEAPON), null, "reddedilen istekte slot boş kalır")

func _test_equip_replaces_previous(t) -> void:
	var character := _make_character()
	t.ok(character.equip(EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_1), "ilk silah takılır")
	t.eq(character.get_equipped_id(EquipmentCatalog.SLOT_WEAPON), EquipmentCatalog.WEAPON_TIER_1, "takılan parça doğru")

	t.ok(character.equip(EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_2), "yükseltme aynı slotu değiştirir")
	t.eq(character.get_equipped_id(EquipmentCatalog.SLOT_WEAPON), EquipmentCatalog.WEAPON_TIER_2, "eski parçanın yerini alır")

func _test_unequip(t) -> void:
	var character := _make_character()
	character.equip(EquipmentCatalog.SLOT_RING, EquipmentCatalog.RING_MARKSMAN)
	t.ok(character.unequip(EquipmentCatalog.SLOT_RING), "takılı parça çıkarılabilir")
	t.eq(character.get_equipped(EquipmentCatalog.SLOT_RING), null, "çıkarılan slot boş")
	t.not_ok(character.unequip(EquipmentCatalog.SLOT_RING), "boş slot tekrar çıkarılamaz")

func _test_derived_values_include_equipment(t) -> void:
	var character := _make_character()
	var base_hp := character.get_max_hp()
	var base_dodge := character.get_dodge()
	var base_accuracy := character.get_accuracy()
	var base_damage := character.get_damage_bonus()

	character.equip(EquipmentCatalog.SLOT_ARMOR, EquipmentCatalog.ARMOR_TIER_1)
	character.equip(EquipmentCatalog.SLOT_RING, EquipmentCatalog.RING_MARKSMAN)

	t.eq(character.get_max_hp(), base_hp + 4, "Deri Zırh canı artırır")
	t.eq(character.get_accuracy(), base_accuracy + 5, "Nişancı Yüzüğü isabeti artırır")
	t.eq(character.get_dodge(), maxi(0, base_dodge - 2), "Nişancı Yüzüğü'nün ödünü kaçınmayı düşürür")
	t.eq(character.get_damage_bonus(), base_damage, "ilgisiz parça hasarı değiştirmez")

func _test_dict_round_trip(t) -> void:
	var original := _make_character()
	original.equip(EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_2)
	original.equip(EquipmentCatalog.SLOT_AMULET, EquipmentCatalog.AMULET_WARD)

	var restored := CharacterData.from_dict(original.to_dict())

	t.eq(restored.get_equipped_id(EquipmentCatalog.SLOT_WEAPON), EquipmentCatalog.WEAPON_TIER_2, "silah korunur")
	t.eq(restored.get_equipped_id(EquipmentCatalog.SLOT_AMULET), EquipmentCatalog.AMULET_WARD, "kolye korunur")
	t.eq(restored.get_max_hp(), original.get_max_hp(), "gidiş-dönüşten sonra türetilen değerler eşleşir")

## Seviye kapısı: seviye stat vermez, teçhizatın
## kapısını açar. Kapı olmadığında tek engel paraydı ve seviye ekipman
## ekseninde hiçbir şey ifade etmiyordu.
func _test_level_gate(t) -> void:
	var session := GameSession.new(5000, 100)
	var rookie := CharacterData.create("Çırak", CultureCatalog.VALLEY, CharacterStats.new())
	session.party.clear()
	rookie.is_player = true
	session.party.append(rookie)

	session.add_equipment(EquipmentCatalog.WEAPON_TIER_1, 1)
	session.add_equipment(EquipmentCatalog.WEAPON_TIER_2, 1)
	session.add_equipment(EquipmentCatalog.WEAPON_TIER_3, 1)

	t.ok(
		session.can_equip(rookie, EquipmentCatalog.WEAPON_TIER_1),
		"ilk kademe seviye 1'de kuşanılabilir"
	)
	t.not_ok(
		session.can_equip(rookie, EquipmentCatalog.WEAPON_TIER_2),
		"ikinci kademe seviye ister"
	)
	t.not_ok(
		session.can_equip(rookie, EquipmentCatalog.WEAPON_TIER_3),
		"üçüncü kademe daha da fazla seviye ister"
	)

	# Reddedilen kuşanma depoyu bozmamalı: parça ne kaybolur ne çoğalır.
	t.not_ok(
		session.equip_to_character(rookie, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_3),
		"seviyesi yetmeyen kuşanamaz"
	)
	t.eq(
		session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_3), 1,
		"reddedilen parça depoda kalır"
	)
	t.eq(rookie.get_equipped(EquipmentCatalog.SLOT_WEAPON), null, "slot boş kalır")

	rookie.level = EquipmentCatalog.TIER_3_LEVEL
	t.ok(
		session.equip_to_character(rookie, EquipmentCatalog.SLOT_WEAPON, EquipmentCatalog.WEAPON_TIER_3),
		"seviye yetince kuşanılabilir"
	)

	# Kademeler arasında sıra bozulmamalı, yoksa merdiven anlamsızlaşır.
	var tier_1 := EquipmentCatalog.get_equipment(EquipmentCatalog.WEAPON_TIER_1)
	var tier_2 := EquipmentCatalog.get_equipment(EquipmentCatalog.WEAPON_TIER_2)
	var tier_3 := EquipmentCatalog.get_equipment(EquipmentCatalog.WEAPON_TIER_3)
	t.ok(tier_1.required_level < tier_2.required_level, "kademe arttıkça seviye şartı artar")
	t.ok(tier_2.required_level < tier_3.required_level, "üçüncü kademe en yüksek şartı taşır")

	# Tılsımlar (yüzük/kolye) olaylardan geliyor ve seviye istemiyor: bulunan
	# bir şeyi kuşanamamak bulgu mantığına ters olurdu.
	for equipment_id in [EquipmentCatalog.RING_MARKSMAN, EquipmentCatalog.AMULET_WOLF_FANG]:
		t.eq(
			EquipmentCatalog.get_equipment(equipment_id).required_level, 1,
			"tılsımlar seviye istemez"
		)

## Sinerji yalnız huy varsa eklenir, aynı türetilmiş değere.
func _test_synergy(t) -> void:
	var character := _make_character()
	character.equip(EquipmentCatalog.SLOT_RING, EquipmentCatalog.RING_IRON_BAND)
	var without := character.get_max_hp()
	character.grant_trait(TraitCatalog.IRON_CONSTITUTION, 0)
	var trait_only := CharacterData.create("Deneme", CultureCatalog.VALLEY, CharacterStats.new())
	trait_only.grant_trait(TraitCatalog.IRON_CONSTITUTION, 0)
	var base_trait := CharacterData.create("Deneme", CultureCatalog.VALLEY, CharacterStats.new())
	var trait_gain := trait_only.get_max_hp() - base_trait.get_max_hp()
	t.eq(character.get_max_hp() - without, trait_gain + 2, "demir halka demir bünyeyle +2 can daha")

## Lanetli parça çıkmaz, üstüne takılmaz, kilise bağı ücretle çözer; bedelli
## parça yolda her gün stres yazar.
func _test_cursed_and_cost(t) -> void:
	var session := GameSession.new()
	session.wallet.earn(500)
	var character := _make_character()
	session.add_to_party(character)
	session.add_equipment(EquipmentCatalog.RING_DEBTOR, 1)
	session.add_equipment(EquipmentCatalog.RING_MARKSMAN, 1)
	t.ok(session.equip_to_character(character, EquipmentCatalog.SLOT_RING, EquipmentCatalog.RING_DEBTOR), "lanetli takılır")
	t.not_ok(session.unequip_from_character(character, EquipmentCatalog.SLOT_RING), "lanetli çıkmaz")
	t.eq(session.get_unequip_block_reason(character, EquipmentCatalog.SLOT_RING), "UI_EQUIP_CURSED_LOCK", "sebebiyle")
	t.not_ok(session.equip_to_character(character, EquipmentCatalog.SLOT_RING, EquipmentCatalog.RING_MARKSMAN),
		"lanetlinin üstüne takılmaz")
	var gold := session.wallet.balance
	t.ok(session.lift_curse(character, EquipmentCatalog.SLOT_RING), "kilise bağı çözer")
	t.eq(session.wallet.balance, gold - GameSession.CURSE_LIFT_PRICE, "ücretle")
	t.eq(character.get_equipped_id(EquipmentCatalog.SLOT_RING), "", "parça gömüldü")
	t.eq(session.get_equipment_count(EquipmentCatalog.RING_DEBTOR), 0, "depoya dönmedi")

	var cost := _make_character()
	cost.equip(EquipmentCatalog.SLOT_AMULET, EquipmentCatalog.AMULET_ASH_LOCKET)
	cost.equip(EquipmentCatalog.SLOT_RING, EquipmentCatalog.RING_WIDOW)
	t.eq(cost.get_equipment_daily_stress(), 3, "bedeller toplanır")
