extends RefCounted

## Faz 6 CharacterData'ya yeni alanlar (seviye, XP, yetkinlik, ikinci sınıf,
## görev) ekledi. Faz 5'ten kalan kayıtlarda bu alanlar yok - eski bir
## kayıt yüklendiğinde çökmemeli, makul varsayılanlara düşmeli.

func suite_name() -> String:
	return "SaveMigration"

func run(t) -> void:
	_test_old_character_dict_loads_with_defaults(t)
	_test_old_session_save_loads(t)

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
