extends RefCounted

## Düşman çeşitliliği (Faz 8 PR-B): vahşi hayvanlar, bölgesel haydut
## reskin'leri, şehir muhafızları - EnemyCatalog.build_squad'ın tek giriş
## noktasından erişilir, EventEffect.Type.TRIGGER_COMBAT'in text_value'su
## hangi kadronun kurulacağını taşır (bkz. event_effect_applier.gd).

func suite_name() -> String:
	return "EnemyVariety"

func run(t) -> void:
	_test_wildlife_squad_composition(t)
	_test_wildlife_squad_never_mixes_species(t)
	_test_wildlife_squad_biome_composition(t)
	_test_hunt_squad_composition(t)
	_test_guard_squad_composition(t)
	_test_bandit_squad_region_reskin(t)
	_test_build_squad_dispatches_by_kind(t)
	_test_grant_equipment_effect_still_works_alongside_combat_kind(t)
	_test_trigger_combat_carries_kind(t)
	_test_kind_labels(t)
	_test_encounter_log_uses_enemy_label(t)
	_test_wolf_pack_leader(t)

func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng

## Kurt ailesi: sıradan kurt ve iki sürü reisi (bkz. EnemyCatalog.
## WOLF_ALPHA_WHITE/_BLACK) artık kendi adlarını taşıyor, ama genetik
## olarak aynı hayvan - "tek türden" kuralı burada "tek görünen ad" değil
## "tek aile" anlamına geliyor. Ayı/domuz/kurt üçü yine asla karışmıyor,
## bu yalnızca kurdun kendi ailesini bir bütün sayıyor.
const _WOLF_FAMILY_NAMES: Array[String] = ["Kurt", "Kırağı Kurdu", "Zifir Kurdu"]

func _species_family(display_name: String) -> String:
	if display_name in _WOLF_FAMILY_NAMES:
		return "wolf"
	return display_name

## Kadro türü çeşitlendiği hâlde savaş kayıtları/panel başlığı sabit
## "Haydutlar" diyordu - bir ayı sürüsü de muhafız devriyesi de haydut
## diye anılıyordu. Etiket artık kadro türünden geliyor.
func _test_kind_labels(t) -> void:
	t.eq(EnemyCatalog.get_kind_label(EnemyCatalog.KIND_BANDIT), "Haydutlar", "haydut kadrosunun adı")
	t.eq(EnemyCatalog.get_kind_label(EnemyCatalog.KIND_WILDLIFE), "Vahşi hayvanlar", "vahşi hayvan kadrosunun adı")
	t.eq(EnemyCatalog.get_kind_label(EnemyCatalog.KIND_GUARD), "Şehir muhafızları", "muhafız kadrosunun adı")
	t.eq(EnemyCatalog.get_kind_label(EnemyCatalog.KIND_HUNT), "Av hayvanları", "av kadrosunun adı")

	# Boş text_value "bandit" sayılıyor (bkz. event_effect_applier.gd), bu
	# yüzden bilinmeyen bir tür de haydut etiketine düşmeli.
	t.eq(EnemyCatalog.get_kind_label(""), "Haydutlar", "boş tür haydut etiketine düşer")
	t.eq(EnemyCatalog.get_kind_label("bilinmeyen"), "Haydutlar", "bilinmeyen tür haydut etiketine düşer")

func _test_encounter_log_uses_enemy_label(t) -> void:
	var default_encounter := CombatEncounter.new(_label_party(), _label_enemies(), _seeded_rng(7))
	t.eq(default_encounter.enemy_label, "Haydutlar", "etiket verilmezse haydut varsayılanı kalır")

	var label := EnemyCatalog.get_kind_label(EnemyCatalog.KIND_WILDLIFE)
	var encounter := CombatEncounter.new(_label_party(), _label_enemies(), _seeded_rng(7), label)
	t.eq(encounter.enemy_label, label, "verilen etiket motora taşınır")

	# Lambda dış yereli değere göre yakaladığı için paylaşılan kutu deseni
	# (bkz. CLAUDE.md, test_stress.gd'deki aynı kullanım).
	var opening := [""]
	encounter.log_added.connect(func(line): opening[0] = opening[0] if not opening[0].is_empty() else line)
	encounter.start()
	t.ok(label in opening[0], "açılış kaydı kadro türünün adını kullanır")
	t.not_ok("Haydutlar" in opening[0], "vahşi hayvan savaşı artık haydut demiyor")

func _label_party() -> Array[CombatUnit]:
	var hero := CharacterData.create("Etiket", CultureCatalog.VALLEY, CharacterStats.new(), 174, 1)
	var units: Array[CombatUnit] = [CombatUnit.from_character(hero, 1)]
	return units

func _label_enemies() -> Array[CombatUnit]:
	var units: Array[CombatUnit] = [
		CombatUnit.from_enemy(EnemyCatalog.get_enemy(EnemyCatalog.WOLF), 1)
	]
	return units

func _test_wildlife_squad_composition(t) -> void:
	var calm := EnemyCatalog.build_wildlife_squad(0.1, 4, _seeded_rng(1))
	t.eq(calm.size(), 2, "düşük tehlikede iki kişilik bir sürü")
	for unit in calm:
		t.eq(_species_family(unit.display_name), "wolf", "düşük tehlikede yalnızca kurt ailesi çıkar")

	# Oyuncunun oynanış testinde bildirdiği hata: bir sürüde kurt ve domuz
	# birlikte çıkıyordu (bkz. build_wildlife_squad'ın kendi notu - eskiden
	# domuz mevcut kurt sürüsüne *ekleniyordu*). Artık orta tehlikede tür
	# tamamen domuza dönüşüyor, kurtla karışmıyor.
	var mid := EnemyCatalog.build_wildlife_squad(0.4, 4, _seeded_rng(1))
	t.eq(mid.size(), 2, "orta tehlikede iki kişilik bir domuz sürüsü")
	for unit in mid:
		t.eq(unit.display_name, "Yaban Domuzu", "orta tehlikede yalnızca domuz çıkar, kurtla karışmaz")

	# Ayı nadir (%35) ve tekil - kırk bağımsız tohumda en az bir kez
	# çıkması ezici olasılıkla beklenir (bkz. test_traits.gd'nin aynı
	# gerekçeli seed dağıtım testi).
	var bear_seen := false
	for seed_value in 40:
		var squad := EnemyCatalog.build_wildlife_squad(0.6, 4, _seeded_rng(4000 + seed_value))
		var has_bear := false
		var has_other := false
		for unit in squad:
			if unit.display_name == "Ayı":
				has_bear = true
				bear_seen = true
			else:
				has_other = true
		t.ok(not (has_bear and has_other), "ayı çıktığında sürüde başka tür bulunmaz (seed %d)" % seed_value)
	t.ok(bear_seen, "kırk denemede en az bir kez ayı çıkar")

## Kadro her zaman tek türden - hiçbir tehlike/parti büyüklüğü
## kombinasyonu türleri karıştırmaz. Kullanıcının doğrudan bildirdiği
## "kurt ve yaban domuzu mix bir seri" hatasının regresyon kilidi.
func _test_wildlife_squad_never_mixes_species(t) -> void:
	for danger_tenth in range(1, 10):
		var danger := danger_tenth / 10.0
		for party_size in range(1, 5):
			for seed_value in 5:
				var squad := EnemyCatalog.build_wildlife_squad(
					danger, party_size, _seeded_rng(9000 + seed_value), 1
				)
				var families := {}
				for unit in squad:
					families[_species_family(unit.display_name)] = true
				t.eq(
					families.size(), 1,
					"tehlike %.1f, parti %d: sürü tek türden (bulunan: %s)" % [danger, party_size, families.keys()]
				)

## Faz 17 PR-6: "vahşi hayvan sürüsü" artık geçtiği araziye bağlı - orman
## kurt sürüsünü büyütür, dağ ayı ihtimalini artırır. biome verilmezse
## (varsayılan) eski davranış birebir sürmeli - önceki testin kendisi
## bunu zaten kilitliyor, burada yalnızca biome verildiğinde değişeni
## sınıyoruz. Düşük tehlike (0.1) kasıtlı: tür karışmasın kuralı (bkz.
## `_test_wildlife_squad_never_mixes_species`) gereği 0.3 ve üstünde tür
## artık domuza dönüyor - orman bonusu yalnızca kurt sürüsüne uygulanıyor,
## o yüzden karşılaştırma türün hâlâ kurt kaldığı bir tehlikede yapılmalı.
func _test_wildlife_squad_biome_composition(t) -> void:
	var default_calm := EnemyCatalog.build_wildlife_squad(0.1, 4, _seeded_rng(1))
	var forest_calm := EnemyCatalog.build_wildlife_squad(0.1, 4, _seeded_rng(1), 1, ArtPalette.BIOME_FOREST)
	t.ok(
		forest_calm.size() > default_calm.size(),
		"orman aynı tohumda daha kalabalık bir sürü verir"
	)
	var wolf_count := 0
	for unit in forest_calm:
		if _species_family(unit.display_name) == "wolf":
			wolf_count += 1
	t.eq(wolf_count, forest_calm.size(), "orman sürüsü de yalnızca kurt ailesinden oluşur")
	t.ge(wolf_count, 3, "orman sürüsü en az üç kurt taşır")

	# Ayı dağda çok daha olası (bkz. bear_chance) - kırk bağımsız tohumda
	# ölçülebilir bir fark bekleniyor, tek bir seferin zarına güvenmeden
	# (aynı overwhelming-margin deseni, bkz. _test_wildlife_squad_composition).
	var mountain_bear_count := 0
	var plain_bear_count := 0
	for seed_value in 40:
		var mountain_squad := EnemyCatalog.build_wildlife_squad(
			0.6, 4, _seeded_rng(5000 + seed_value), 1, ArtPalette.BIOME_MOUNTAIN
		)
		var plain_squad := EnemyCatalog.build_wildlife_squad(0.6, 4, _seeded_rng(5000 + seed_value))
		for unit in mountain_squad:
			if unit.display_name == "Ayı":
				mountain_bear_count += 1
				break
		for unit in plain_squad:
			if unit.display_name == "Ayı":
				plain_bear_count += 1
				break
	t.ok(mountain_bear_count > plain_bear_count, "dağda ayı düz araziden daha sık çıkar")

## Av kadrosu her zaman tam bir erkek geyik taşır (bkz. build_hunt_squad'ın
## kendi notu) - o kadronun tek gerçek tehdidi. Geyik sayısı parti
## büyüklüğüne/zara göre bir ya da iki.
func _test_hunt_squad_composition(t) -> void:
	for party_size in [1, 2, 4]:
		for seed_value in 10:
			var squad := EnemyCatalog.build_hunt_squad(0.3, party_size, _seeded_rng(6000 + seed_value))
			var stag_count := 0
			var deer_count := 0
			for unit in squad:
				if unit.display_name == "Erkek Geyik":
					stag_count += 1
				elif unit.display_name == "Geyik":
					deer_count += 1
			t.eq(stag_count, 1, "av kadrosu tam bir erkek geyik taşır (parti %d)" % party_size)
			t.ge(deer_count, 1, "av kadrosunda en az bir geyik var (parti %d)" % party_size)
			t.le(deer_count, 2, "av kadrosunda en fazla iki geyik var (parti %d)" % party_size)

	# Kalabalık bir parti (3+) her zaman iki geyikle karşılaşır - build_
	# hunt_squad'ın kendi kuralı.
	var crowded := EnemyCatalog.build_hunt_squad(0.3, 4, _seeded_rng(1))
	var crowded_deer := 0
	for unit in crowded:
		if unit.display_name == "Geyik":
			crowded_deer += 1
	t.eq(crowded_deer, 2, "kalabalık parti her zaman iki geyikle karşılaşır")

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
	var hunt := EnemyCatalog.build_squad("hunt", "", 0.3, 4, _seeded_rng(1), 1)
	var fallback := EnemyCatalog.build_squad("", "", 0.6, 4, _seeded_rng(3), 1)

	t.eq(bandit[0].display_name, "Haydut Kesicisi", "\"bandit\" kadrosu haydut çıkarır")
	t.eq(_species_family(wildlife[0].display_name), "wolf", "\"wildlife\" kadrosu hayvan çıkarır")
	t.eq(guard[0].display_name, "Şehir Muhafızı", "\"guard\" kadrosu muhafız çıkarır")
	t.eq(hunt[0].display_name, "Erkek Geyik", "\"hunt\" kadrosu av hayvanı çıkarır")
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

## Kurt sürüsü reisi (bkz. EnemyCatalog.WOLF_ALPHA_WHITE/_BLACK, kullanıcının
## kendi isteği - "sürü lideri gibi", statları daha yüksek, kendi adları,
## beyaz/kara asla birlikte çıkmaz). Genetik olarak aynı tür sayılır ama
## artık kendi `display_name_key`'leri var - `_species_family()` bu ikisini
## "Kurt"la aynı aileye koyduğu için `_test_wildlife_squad_never_mixes_
## species` hiç kırılmadan geçiyor; bu test dört iddiayı doğrudan sınıyor.
func _test_wolf_pack_leader(t) -> void:
	var wolf := EnemyCatalog.get_enemy(EnemyCatalog.WOLF)
	var white := EnemyCatalog.get_enemy(EnemyCatalog.WOLF_ALPHA_WHITE)
	var black := EnemyCatalog.get_enemy(EnemyCatalog.WOLF_ALPHA_BLACK)
	t.ne(white, null, "beyaz sürü reisi katalogda var")
	t.ne(black, null, "kara sürü reisi katalogda var")

	# "Statları buna göre daha yüksek olmalı" - sıradan kurdun katına.
	t.ok(white.max_hp > wolf.max_hp, "beyaz reisin canı sıradan kurttan yüksek")
	t.ok(white.damage_bonus > wolf.damage_bonus, "beyaz reisin hasarı sıradan kurttan yüksek")
	t.ok(black.max_hp > wolf.max_hp, "kara reisin canı sıradan kurttan yüksek")
	t.ok(black.damage_bonus > wolf.damage_bonus, "kara reisin hasarı sıradan kurttan yüksek")

	# "İsimlerini de düzenle, 'kara börü' demeyin" - artık kendi adları var,
	# sıradan kurttan farklı, ve "kara börü" değil.
	t.eq(white.display_name, "Kırağı Kurdu", "beyaz reis kendi adıyla anons edilir")
	t.eq(black.display_name, "Zifir Kurdu", "kara reis kendi adıyla anons edilir")
	t.ne(white.display_name, wolf.display_name, "beyaz reisin adı sıradan kurttan farklı")
	t.ne(black.display_name, wolf.display_name, "kara reisin adı sıradan kurttan farklı")
	t.not_ok("kara börü" in black.display_name.to_lower(), "kara reis \"kara börü\" diye anılmaz")

	# Genetik olarak yine kurt ailesi - "tek türden" kuralı bunları
	# birbirinden ya da sıradan kurttan ayırmıyor, yalnızca ayı/domuzdan.
	t.eq(_species_family(white.display_name), _species_family(wolf.display_name), "beyaz reis kurt ailesinden sayılır")
	t.eq(_species_family(black.display_name), _species_family(wolf.display_name), "kara reis kurt ailesinden sayılır")

	# Kırk bağımsız tohumda hem beyaz hem kara en az bir kez çıkmalı
	# (overwhelming-margin deseni, bkz. test_traits.gd'nin seed dağıtımı),
	# ve hiçbir sürüde ikisi birlikte bulunmamalı - tek bir zar, tek bir
	# yerine koyma (bkz. build_wildlife_squad'ın kendi yorumu).
	var white_seen := false
	var black_seen := false
	for seed_value in 60:
		var squad := EnemyCatalog.build_wildlife_squad(0.1, 4, _seeded_rng(7000 + seed_value))
		var has_white := false
		var has_black := false
		for unit in squad:
			if unit.figure_kind == EnemyCatalog.WOLF_ALPHA_WHITE:
				has_white = true
				white_seen = true
			elif unit.figure_kind == EnemyCatalog.WOLF_ALPHA_BLACK:
				has_black = true
				black_seen = true
		t.not_ok(has_white and has_black, "beyaz ve kara reis aynı sürüde birlikte çıkmaz (seed %d)" % seed_value)
	t.ok(white_seen, "altmış denemede en az bir kez beyaz reis çıkar")
	t.ok(black_seen, "altmış denemede en az bir kez kara reis çıkar")
