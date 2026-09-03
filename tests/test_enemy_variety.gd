extends RefCounted

## Düşman çeşitliliği (Faz 8 PR-B): vahşi hayvanlar, bölgesel haydut
## reskin'leri, şehir muhafızları - EnemyCatalog.build_squad'ın tek giriş
## noktasından erişilir, EventEffect.Type.TRIGGER_COMBAT'in text_value'su
## hangi kadronun kurulacağını taşır (bkz. event_effect_applier.gd).

func suite_name() -> String:
	return "EnemyVariety"

func run(t) -> void:
	_test_wildlife_squad_composition(t)
	_test_guard_squad_composition(t)
	_test_bandit_squad_region_reskin(t)
	_test_build_squad_dispatches_by_kind(t)
	_test_grant_equipment_effect_still_works_alongside_combat_kind(t)
	_test_trigger_combat_carries_kind(t)

func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

func _test_wildlife_squad_composition(t) -> void:
	var calm := EnemyCatalog.build_wildlife_squad(0.1, 4, _seeded_rng(1))
	t.eq(calm.size(), 2, "düşük tehlikede iki kişilik bir sürü")
	for unit in calm:
		t.eq(unit.display_name, "Kurt", "düşük tehlikede yalnızca kurt çıkar")

	var mid := EnemyCatalog.build_wildlife_squad(0.4, 4, _seeded_rng(1))
	t.eq(mid.size(), 3, "orta tehlikede domuz katılır")

	# Ayı nadir (%35) ve tekil - kırk bağımsız tohumda en az bir kez
	# çıkması ezici olasılıkla beklenir (bkz. test_traits.gd'nin aynı
	# gerekçeli seed dağıtım testi).
	var bear_seen := false
	for seed_value in 40:
		var squad := EnemyCatalog.build_wildlife_squad(0.6, 4, _seeded_rng(4000 + seed_value))
		for unit in squad:
			if unit.display_name == "Ayı":
				bear_seen = true
	t.ok(bear_seen, "kırk denemede en az bir kez ayı çıkar")

func _test_guard_squad_composition(t) -> void:
	var pair := EnemyCatalog.build_guard_squad(0.2, 1, _seeded_rng(1))
	t.eq(pair.size(), 2, "tek başına yola çıkan iki muhafızla karşılaşır")
	for unit in pair:
		t.eq(unit.display_name, "Şehir Muhafızı", "düşük tehlikede çavuş yok")

	var with_sergeant := EnemyCatalog.build_guard_squad(0.5, 4, _seeded_rng(1))
	var names: Array[String] = []
	for unit in with_sergeant:
		names.append(unit.display_name)
	t.ok(names.has("Muhafız Çavuşu"), "yüksek tehlikede çavuş katılır")

func _test_bandit_squad_region_reskin(t) -> void:
	var default_squad := EnemyCatalog.build_bandit_squad(0.6, 4, _seeded_rng(3), 1, "")
	var mountain_squad := EnemyCatalog.build_bandit_squad(0.6, 4, _seeded_rng(3), 1, EnemyCatalog.MOUNTAIN_REGION_ID)
	var garrison_squad := EnemyCatalog.build_bandit_squad(0.6, 4, _seeded_rng(3), 1, EnemyCatalog.GARRISON_REGION_ID)

	t.eq(default_squad[0].display_name, "Haydut Kesicisi", "bölgesiz kadro varsayılan kesici")
	t.eq(mountain_squad[0].display_name, "Dağ Haydutu", "Kurtboğazı çevresinde dağ haydutu çıkar")

	var garrison_names: Array[String] = []
	for unit in garrison_squad:
		garrison_names.append(unit.display_name)
	t.ok(garrison_names.has("Silahlı Eşkıya"), "Demirkapı çevresinde silahlı eşkıya çıkar")
	t.not_ok(garrison_names.has("Haydut Okçusu"), "Demirkapı çevresinde varsayılan okçu yerini alır")

func _test_build_squad_dispatches_by_kind(t) -> void:
	var bandit := EnemyCatalog.build_squad("bandit", "", 0.6, 4, _seeded_rng(3), 1)
	var wildlife := EnemyCatalog.build_squad("wildlife", "", 0.1, 4, _seeded_rng(1), 1)
	var guard := EnemyCatalog.build_squad("guard", "", 0.2, 1, _seeded_rng(1), 1)
	var fallback := EnemyCatalog.build_squad("", "", 0.6, 4, _seeded_rng(3), 1)

	t.eq(bandit[0].display_name, "Haydut Kesicisi", "\"bandit\" kadrosu haydut çıkarır")
	t.eq(wildlife[0].display_name, "Kurt", "\"wildlife\" kadrosu hayvan çıkarır")
	t.eq(guard[0].display_name, "Şehir Muhafızı", "\"guard\" kadrosu muhafız çıkarır")
	t.eq(fallback[0].display_name, "Haydut Kesicisi", "bilinmeyen/boş kind haydut kadrosuna düşer")

func _test_grant_equipment_effect_still_works_alongside_combat_kind(t) -> void:
	# Faz 8 PR-B, EventEffectApplier.Result'a combat_kinds ekledi -
	# GRANT_EQUIPMENT gibi combat_kinds'e hiç dokunmayan etkilerin
	# regresyona uğramadığını doğruluyor.
	var session := GameSession.new(100, 0, 1)
	var result := EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.GRANT_EQUIPMENT, 0, EquipmentCatalog.RING_MARKSMAN),
	], session)
	t.eq(session.get_equipment_count(EquipmentCatalog.RING_MARKSMAN), 1, "GRANT_EQUIPMENT hâlâ çalışıyor")
	t.ok(result.combat_kinds.is_empty(), "savaşsız etkilerde combat_kinds boş kalır")

func _test_trigger_combat_carries_kind(t) -> void:
	var session := GameSession.new(100, 0, 1)

	var default_result := EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0),
	], session)
	t.eq(default_result.combat_kinds, ["bandit"], "boş text_value \"bandit\" sayılır - eski olay tanımları bozulmaz")

	var wildlife_result := EventEffectApplier.apply([
		EventEffect.make(EventEffect.Type.TRIGGER_COMBAT, 0, "wildlife"),
	], session)
	t.eq(wildlife_result.combat_kinds, ["wildlife"], "text_value combat_kinds'e taşınır")
