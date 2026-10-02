extends RefCounted

## Boy süs değil: uzun daha çok can taşır, kısa daha iyi kaçınır. Kayıt
## gidiş-dönüşü de burada, çünkü parti artık kayda giriyor.

func suite_name() -> String:
	return "CharacterData"

func run(t) -> void:
	_test_height_affects_body(t)
	_test_max_hp_composition(t)
	_test_dict_round_trip(t)
	_test_class_and_skills(t)
	_test_wisdom_and_faith(t)
	_test_gender_and_body_weight(t)
	_test_condition_label_bands(t)

## Faz 17: iki yeni stat, ikisi de tabanda (5) eski davranışı birebir korur -
## dosyanın her formülünün kendi kuralı, burada da geçerli.
func _test_wisdom_and_faith(t) -> void:
	var baseline := CharacterData.create("Taban", CultureCatalog.NOMAD, CharacterStats.new())
	baseline.stats.wisdom = CharacterStats.BASE_VALUE
	baseline.stats.faith = CharacterStats.BASE_VALUE
	t.eq(baseline.get_xp_bonus_percent(), 0, "Bilgelik tabanda XP'ye dokunmaz")
	t.eq(baseline.get_deathblow_resist_bonus(), 0, "İnanç tabanda ölüm zarına dokunmaz")
	t.eq(baseline.gain_xp(CharacterData.xp_required_for_level(1)), 1, "tabanda XP kazancı eski formülle birebir aynı")

	var wise := CharacterData.create("Bilge", CultureCatalog.NOMAD, CharacterStats.new())
	wise.stats.wisdom = 15
	t.ok(wise.get_xp_bonus_percent() > 0, "yüksek Bilgelik XP kazancını artırır")
	t.le(float(wise.get_xp_bonus_percent()), float(CharacterData.MAX_XP_BONUS_PERCENT), "XP bonusu tavanı aşmaz")

	var devout := CharacterData.create("Sadık", CultureCatalog.NOMAD, CharacterStats.new())
	devout.stats.faith = 15
	t.ok(devout.get_deathblow_resist_bonus() > 0, "yüksek İnanç ölüm zarını güçlendirir")

	var faithless := CharacterData.create("İnançsız", CultureCatalog.NOMAD, CharacterStats.new())
	faithless.stats.faith = CharacterStats.MIN_VALUE
	t.ok(faithless.get_deathblow_resist_bonus() < 0, "düşük İnanç ölüm zarını zayıflatır")

func _test_height_affects_body(t) -> void:
	var base := CharacterStats.new()

	var tall := CharacterData.create("Uzun", CultureCatalog.HIGHLAND, base, 195, 0)
	var short := CharacterData.create("Kısa", CultureCatalog.HIGHLAND, base, 158, 0)
	var middling := CharacterData.create("Orta", CultureCatalog.HIGHLAND, base, 174, 0)

	t.ge(float(tall.get_height_hp_bonus()), 1.0, "uzun boy can ekler")
	t.le(float(tall.get_height_dodge_bonus()), -1.0, "uzun boy kaçınmayı düşürür")
	t.le(float(short.get_height_hp_bonus()), -1.0, "kısa boy can düşürür")
	t.ge(float(short.get_height_dodge_bonus()), 1.0, "kısa boy kaçınma ekler")
	t.eq(middling.get_height_hp_bonus(), 0, "orta boy nötr")
	t.eq(middling.get_height_dodge_bonus(), 0, "orta boy kaçınmada da nötr")

	t.ge(float(tall.get_max_hp()), float(short.get_max_hp()) + 1.0, "uzun daha dayanıklı")
	t.ge(float(short.get_dodge()), float(tall.get_dodge()) + 1.0, "kısa daha çevik kaçar")

func _test_max_hp_composition(t) -> void:
	var character := CharacterData.create("Deneme", CultureCatalog.NOMAD, CharacterStats.new(), 174, 1)

	var expected := (
		character.stats.get_max_hp()
		+ character.get_character_class().bonus_max_hp
		+ character.get_height_hp_bonus()
		+ character.get_gender_hp_bonus()
		+ character.get_body_weight_hp_bonus()
	)
	t.eq(character.get_max_hp(), expected, "can = stat + sınıf + boy + beden")
	t.eq(character.current_hp, character.get_max_hp(), "yeni karakter tam canla başlar")

	character.apply_damage(9999)
	t.eq(character.current_hp, 0, "can sıfırın altına inmez")
	t.not_ok(character.is_alive(), "canı sıfırsa ayakta değil")

	character.apply_heal(9999)
	t.eq(character.current_hp, character.get_max_hp(), "can tavanı aşmaz")

## A2 (bkz. akademik kaynak önerileri): can barının yanına eklenen sıfat -
## sayının **yerine** değil, sayının yanına (bkz. CharacterData.
## get_condition_label_key'in kendi yorumu). Dört bant, dört eşik.
func _test_condition_label_bands(t) -> void:
	var character := CharacterData.create("Deneme", CultureCatalog.NOMAD, CharacterStats.new(), 174, 1)
	var max_hp := character.get_max_hp()

	character.current_hp = max_hp
	t.eq(character.get_condition_label_key(), "UI_HP_BAND_HEALTHY", "tam canda dinç")

	character.current_hp = maxi(1, int(round(max_hp * 0.6)))
	t.eq(character.get_condition_label_key(), "UI_HP_BAND_WOUNDED", "%60 canda yaralı")

	character.current_hp = maxi(1, int(round(max_hp * 0.4)))
	t.eq(character.get_condition_label_key(), "UI_HP_BAND_BADLY_WOUNDED", "%40 canda ağır yaralı")

	character.current_hp = maxi(1, int(round(max_hp * 0.1)))
	t.eq(character.get_condition_label_key(), "UI_HP_BAND_CRITICAL", "%10 canda ölümün kıyısında")

	# Sayı hiçbir zaman silinmiyor - bkz. get_max_hp/current_hp'nin kendisi
	# hâlâ okunabilir ve sıfatla birlikte gösteriliyor (character.gd).
	t.eq(character.current_hp, maxi(1, int(round(max_hp * 0.1))), "ham can sayısı hâlâ okunuyor")

func _test_dict_round_trip(t) -> void:
	var stats := CharacterStats.new()
	stats.perception = 8

	var original := CharacterData.create("Bozkurt", CultureCatalog.PORT, stats, 188, 3)
	original.hire_cost = 145
	original.apply_damage(7)

	var restored := CharacterData.from_dict(original.to_dict())

	t.eq(restored.character_name, original.character_name, "isim korunur")
	t.eq(restored.culture_id, original.culture_id, "kültür korunur")
	t.eq(restored.class_id, original.class_id, "sınıf korunur")
	t.eq(restored.height_cm, original.height_cm, "boy korunur")
	t.eq(restored.skin_tone, original.skin_tone, "ten rengi korunur")
	t.eq(restored.gender, original.gender, "cinsiyet korunur")
	t.eq(restored.body_weight, original.body_weight, "vücut tipi korunur")
	t.eq(restored.hire_cost, original.hire_cost, "ücret korunur")
	t.eq(restored.current_hp, original.current_hp, "anlık can korunur")
	t.eq(restored.get_max_hp(), original.get_max_hp(), "tavan can yeniden hesaplanır")

	# Kültür bonusu kayda girmiş hâliyle saklanıyor; yüklerken ikinci kez
	# uygulanmamalı, yoksa her kayıt/yükleme karakteri güçlendirirdi.
	t.eq(restored.stats.get_value(CharacterStats.Kind.CHARISMA),
		original.stats.get_value(CharacterStats.Kind.CHARISMA),
		"kültür bonusu yüklemede tekrar uygulanmaz")

func _test_class_and_skills(t) -> void:
	var character := CharacterData.create("Muhafız", CultureCatalog.VALLEY, CharacterStats.new())

	t.eq(character.class_id, ClassCatalog.GUARD, "varsayılan sınıf Sıra Neferi")
	t.eq(character.get_skills().size(), 4, "sıra neferinin dört yeteneği var")
	t.ne(ClassCatalog.get_character_class_or_default("yok"), null, "sınıf çözümlemesi null dönmez")

	var height_clamped := CharacterData.create("Dev", CultureCatalog.NOMAD, CharacterStats.new(), 999, 0)
	t.eq(height_clamped.height_cm, CharacterData.MAX_HEIGHT_CM, "boy tavanda kırpılır")

## Cinsiyet/kilo hem görsel (altı mankenin - 2 cinsiyet x 3 kilo - sanatı
## var, yani her karakter kendi varyantını buluyor; sanatı olmayan bir
## varyant düz "body"ye düşerdi, bkz. test_wardrobe'un fikstürlü testi)
## hem de mekanik: boyun kurduğu aileye katılıyor. Kilitlenen iddia
## "şu kadar bonus var" değil, **yönü**: kadın kaçınır/kritik vurur, erkek
## dayanır/sert vurur, iri yavaşlar ve çok yer, ince tersi - ve ortanın
## tam nötr olduğu.
func _test_gender_and_body_weight(t) -> void:
	var baseline := CharacterData.create("Taban", CultureCatalog.NOMAD, CharacterStats.new())
	t.eq(baseline.gender, CharacterData.GENDER_FEMALE, "varsayılan cinsiyet kadın")
	t.eq(baseline.body_weight, CharacterData.BODY_WEIGHT_AVERAGE, "varsayılan vücut tipi orta")
	t.eq(baseline.get_body_variant_id(), "body_female_average",
		"varsayılan karakter kendi mankenini buluyor (tools/wardrobe_mannequin.py)")

	var male_heavy := CharacterData.create(
		"Devasa", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD,
		CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_HEAVY
	)
	t.eq(male_heavy.gender, CharacterData.GENDER_MALE, "erkek seçimi korunur")
	t.eq(male_heavy.body_weight, CharacterData.BODY_WEIGHT_HEAVY, "iri seçimi korunur")
	t.eq(male_heavy.get_body_variant_id(), "body_male_heavy",
		"iri erkek kendi mankeniyle çiziliyor")

	var clamped := CharacterData.create(
		"Sınır", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD, 99, -5
	)
	t.eq(clamped.gender, CharacterData.GENDER_MALE, "cinsiyet index tavanda kırpılır")
	t.eq(clamped.body_weight, CharacterData.BODY_WEIGHT_LEAN, "vücut tipi index tabanda kırpılır")

	# Aynı statlar, iki uç beden: iri erkek dayanır ve sert vurur, ince
	# kadın kaçar ve kritik yapar. Sayıya değil **yöne** bakılıyor, ki
	# büyüklükler ölçümle ayarlanabilsin ama yön kazara ters çevrilemesin.
	var female_lean := CharacterData.create(
		"Kontrol", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD,
		CharacterData.GENDER_FEMALE, CharacterData.BODY_WEIGHT_LEAN
	)
	t.ok(male_heavy.get_max_hp() > female_lean.get_max_hp(),
		"iri erkek daha çok can taşır (%d > %d)" % [
			male_heavy.get_max_hp(), female_lean.get_max_hp()])
	t.ok(female_lean.get_dodge() > male_heavy.get_dodge(),
		"ince kadın daha iyi kaçınır (%d > %d)" % [
			female_lean.get_dodge(), male_heavy.get_dodge()])
	t.ok(female_lean.get_crit_chance() > male_heavy.get_crit_chance(),
		"kadının kritik şansı daha yüksek")
	t.ok(male_heavy.get_damage_bonus() > female_lean.get_damage_bonus(),
		"iri erkek daha sert vurur")
	t.ok(male_heavy.get_provision_weight() > female_lean.get_provision_weight(),
		"iri bir beden daha çok yer")

	# Ortanın tam nötr olması bu dosyanın her yerde uyguladığı kural:
	# varsayılan bir karakter bu sistem hiç yokmuş gibi davranır. Kilonun
	# payı sıfır, yani yalnızca cinsiyet kalır.
	t.eq(baseline.get_body_weight_hp_bonus(), 0, "orta kilo cana dokunmaz")
	t.eq(baseline.get_body_weight_dodge_bonus(), 0, "orta kilo kaçınmaya dokunmaz")
	t.eq(baseline.get_body_weight_damage_bonus(), 0, "orta kilo hasara dokunmaz")
	t.almost(baseline.get_provision_weight(), 1.0, "orta kilo + orta boy tam bir pay", 0.001)

	# Cinsiyetin iki kolu birbirinin aynası - karışık bir parti ortalamada
	# ne kazanır ne kaybeder, fark yalnızca kimin ne yaptığında.
	var male := CharacterData.create(
		"Erkek", CultureCatalog.NOMAD, CharacterStats.new(),
		CharacterData.DEFAULT_HEIGHT_CM, 0, ClassCatalog.GUARD,
		CharacterData.GENDER_MALE, CharacterData.BODY_WEIGHT_AVERAGE
	)
	t.eq(baseline.get_gender_hp_bonus() + male.get_gender_hp_bonus(), 0,
		"cinsiyetin can payı toplamda sıfır")
	t.eq(baseline.get_gender_dodge_bonus() + male.get_gender_dodge_bonus(), 0,
		"cinsiyetin kaçınma payı toplamda sıfır")

	# Check eğilimi: "rogue benzeri" bir savaş sayısı değil, bir zar
	# eğilimi - huyların zaten kullandığı vokabüler (bkz.
	# GameSession.get_best_effective_stat). Bedene ait olmayan dört stat
	# (Zeka/Karizma/Bilgelik/İnanç) kasıtlı olarak hiç etkilenmiyor.
	t.ok(female_lean.get_body_check_modifier(CharacterStats.Kind.AGILITY)
		> male_heavy.get_body_check_modifier(CharacterStats.Kind.AGILITY),
		"ince kadın çeviklik check'inde önde")
	t.ok(male_heavy.get_body_check_modifier(CharacterStats.Kind.STRENGTH)
		> female_lean.get_body_check_modifier(CharacterStats.Kind.STRENGTH),
		"iri erkek güç check'inde önde")
	for kind in [
		CharacterStats.Kind.INTELLECT, CharacterStats.Kind.CHARISMA,
		CharacterStats.Kind.WISDOM, CharacterStats.Kind.FAITH,
	]:
		t.almost(male_heavy.get_body_check_modifier(kind), 0.0,
			"beden %s check'ine karışmaz" % CharacterStats.kind_name(kind), 0.001)
		t.almost(female_lean.get_body_check_modifier(kind), 0.0,
			"beden %s check'ine karışmaz" % CharacterStats.kind_name(kind), 0.001)
