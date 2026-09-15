extends RefCounted

## Faz 6 CharacterData'ya yeni alanlar (seviye, XP, yetkinlik, ikinci sınıf,
## görev) ekledi. Faz 5'ten kalan kayıtlarda bu alanlar yok - eski bir
## kayıt yüklendiğinde çökmemeli, makul varsayılanlara düşmeli.

func suite_name() -> String:
	return "SaveMigration"

func run(t) -> void:
	_test_old_character_dict_loads_with_defaults(t)
	_test_old_session_save_loads(t)
	_test_current_hp_is_clamped_to_max(t)
	_test_v1_party_stress_spreads_to_members(t)

## Faz 5'te yazılmış olabilecek, yeni alanları hiç bilmeyen bir kayıt.
func _old_character_dict() -> Dictionary:
	return {
		"name": "Eski Kayıt",
		"culture_id": CultureCatalog.NOMAD,
		"class_id": ClassCatalog.GUARD,
		"height_cm": 180,
		"skin_tone": 2,
		"stats": {"strength": 6, "agility": 5, "endurance": 7, "intellect": 4, "perception": 5, "charisma": 3},
		"current_hp": 30,
		"hire_cost": 0,
		"is_player": true,
	}

func _test_old_character_dict_loads_with_defaults(t) -> void:
	var character := CharacterData.from_dict(_old_character_dict())

	t.eq(character.character_name, "Eski Kayıt", "temel alanlar korunur")
	t.eq(character.level, 1, "seviyesi olmayan kayıt seviye 1'e düşer")
	t.eq(character.xp, 0, "XP'si olmayan kayıt sıfırdan başlar")
	t.eq(character.unspent_stat_points, 0, "birikmiş puan varsayılan sıfır")
	t.eq(character.unspent_skill_points, 0, "birikmiş yetkinlik puanı varsayılan sıfır")
	t.ok(character.skill_proficiency.is_empty(), "yetkinlik sözlüğü boş başlar")
	t.eq(character.second_class_id, "", "ikinci sınıf yok")
	t.eq(character.duty_id, "", "görev atanmamış")
	t.ok(character.auto_allocate, "otomatik dağıtım varsayılan açık")
	t.ok(character.equipped.is_empty(), "ekipman sözlüğü boş başlar (Faz 7'den önceki kayıt)")

	# Yeni sistemler eski kaydı çökertmeden çalışmalı.
	t.ok(character.get_skills().size() > 0, "yetenekler hâlâ okunabilir")
	t.not_ok(character.can_multiclass(), "seviye 1 multiclass açmaz")

func _test_old_session_save_loads(t) -> void:
	var old_save := {
		"version": 1,
		"gold": 150,
		"inventory": [],
		"current_location_id": WorldMapData.START_LOCATION_ID,
		"reputation": 2,
		"flags": {},
		"owned_wagon_count": 1,
		"owned_wagon_damaged": 0,
		"known_routes": {},
		"total_days_elapsed": 5,
		"accepted_contracts": {},
		"party": [_old_character_dict()],
	}

	var session := GameSession.new(0, 0)
	session.load_from_dict(old_save)

	t.eq(session.wallet.balance, 150, "altın yüklenir")
	t.eq(session.get_party().size(), 1, "eski partili kayıt yüklenir")
	t.eq(session.get_player_character().level, 1, "yüklenen karakter seviye 1'den başlar")
	t.eq(session.get_duty_holder(DutyCatalog.MUHAFIZ), null, "eski kayıtta kimse görevli değildir")
	t.eq(session.get_equipment_count(EquipmentCatalog.WEAPON_TIER_1), 0, "ekipman deposu olmayan kayıt boş depoyla yüklenir")

## Kayıt dosyası dış sınır: saklanan can, kayıt alındıktan sonra ekipman
## çıkarılmış ya da huy silinmişse artık ulaşılamayacak kadar yüksek
## olabilir; elle düzenlenmiş bir kayıt negatif de gelebilir.
func _test_current_hp_is_clamped_to_max(t) -> void:
	var inflated := _old_character_dict()
	inflated["current_hp"] = 9999
	var healed := CharacterData.from_dict(inflated)
	t.eq(healed.current_hp, healed.get_max_hp(), "maksimumu aşan can tavana kenetlenir")

	var negative := _old_character_dict()
	negative["current_hp"] = -50
	var downed := CharacterData.from_dict(negative)
	t.eq(downed.current_hp, 0, "negatif can sıfıra kenetlenir")

	var intact := _old_character_dict()
	intact["current_hp"] = 12
	t.eq(CharacterData.from_dict(intact).current_hp, 12, "aralıktaki can olduğu gibi korunur")

## v1 -> v2: stres kadronun tek bir sayısıyken kişiye taşındı. Bu, bir
## alanın **anlamının** değiştiği ilk durum - `.get` varsayılanlarının
## karşılayamadığı ve `_migrate_save`'in var olma sebebi olan tam olarak
## bu. Eski ortalama kadronun her üyesine dağıtılıyor; kimin ne kadar
## yıprandığını geriye dönük uydurmak, olmayan bir bilgiyi uydurmak olurdu.
func _test_v1_party_stress_spreads_to_members(t) -> void:
	var session := GameSession.new(100, 0, 1)
	var first := _old_character_dict()
	first["name"] = "Kıdemli"
	first["is_player"] = true
	var second := _old_character_dict()
	second["name"] = "Yoldaş"

	session.load_from_dict({
		"version": 1,
		"gold": 100,
		"current_location_id": WorldMapData.START_LOCATION_ID,
		"party": [first, second],
		"party_stress": 64,
	})

	t.eq(session.party.size(), 2, "göç kadroyu bozmaz")
	for character in session.party:
		t.eq(character.stress, 64, "eski ortalama her üyeye dağıtılır")
	t.eq(session.party_stress, 64, "mercek aynı ortalamayı geri verir")

	# v2 kaydı dokunulmadan geçmeli: göç yalnızca eski sürümde çalışır,
	# yoksa her yüklemede kişilerin kendi değerlerini ortalamaya ezerdi.
	var fresh := GameSession.new(100, 0, 1)
	var tired := _old_character_dict()
	tired["name"] = "Bitkin"
	tired["is_player"] = true
	tired["stress"] = 90
	var rested := _old_character_dict()
	rested["name"] = "Dinç"
	rested["stress"] = 10
	fresh.load_from_dict({
		"version": GameSession.SAVE_VERSION,
		"gold": 100,
		"current_location_id": WorldMapData.START_LOCATION_ID,
		"party": [tired, rested],
	})
	t.eq(fresh.party[0].stress, 90, "güncel kayıtta kişinin kendi stresi korunur")
	t.eq(fresh.party[1].stress, 10, "kadrodaki ikinci kişi ayrı bir değer taşır")
