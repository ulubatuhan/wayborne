extends Node

## Autoload: GameSession'ı disk yuvalarına yazar/okur. Serileştirme
## bilgisinin kendisi GameSession.to_save_dict()/load_from_dict()'te -
## burada yalnızca dosya G/Ç'si ve yuva numaralandırması var.
##
## Bu dosyada bilerek hiçbir class_name'e başvurulmuyor (bkz. CLAUDE.md
## Autoload rule): GameSession yalnızca load() ile çalışma anında
## çözülüyor, sonra üzerinde normal örnek metotları çağrılıyor.
##
## **Yuva 0 otomatik kayıt, diğerleri elle.** Şehre her varışta
## (`finish_journey()` sonrası) sessizce yuva 0'a yazılır - bu hep böyleydi
## ve "Devam Et" hâlâ doğrudan onu okur, davranış değişmedi. `SLOT_COUNT - 1`
## elle kayıt yuvası da oyun-içi menüden "Kayıtlar" ekranıyla doldurulabilir/
## okunabilir/silinebilir - tek bir otomatik kayıda bağlı kalmak, kervan
## mahvolduğunda (bkz. Ruin Rules) geri dönecek hiçbir yer bırakmıyordu.
##
## **Sefer ortasında kayıt yok, kasıtlı.** `to_save_dict()` `journey_*`
## alanlarını hiç taşımıyor (yalnızca `finish_journey()` sonrası çağrılır,
## o an kervan/sefer alanları zaten sıfırlanmış oluyor) - bir yuvaya
## sefer ortasında yazmak sefer bilgisini sessizce kaybederdi. Ekranlar
## bu yüzden `Kaydet`i yalnızca `not GameSession.is_journey_active()`
## iken sunar (bkz. InGameMenu).

const SAVE_DIR: String = "user://saves"
const AUTOSAVE_SLOT: int = 0
const SLOT_COUNT: int = 4
const GAME_SESSION_PATH: String = "res://scripts/autoload/game_session.gd"

func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

func has_save(slot: int = AUTOSAVE_SLOT) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func has_any_save() -> bool:
	for slot in SLOT_COUNT:
		if has_save(slot):
			return true
	return false

func save_session(session, slot: int = AUTOSAVE_SLOT) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(session.to_save_dict()))
	file.close()
	return true

## Kayıt yoksa ya da bozuksa null döner.
func load_session(slot: int = AUTOSAVE_SLOT):
	var parsed := _read_slot(slot)
	if parsed.is_empty():
		return null

	var session_script := load(GAME_SESSION_PATH)
	# Sıfır başlangıç erzağı: kalan erzak zaten kayıttaki envanterden geliyor.
	var session = session_script.new(0, 0)
	session.load_from_dict(parsed)
	return session

func delete_save(slot: int = AUTOSAVE_SLOT) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(_slot_path(slot))

## Bir kayıt satırının özeti - `Kayıtlar` ekranı `SLOT_COUNT` tane tam
## `GameSession` kurup atmak yerine yalnızca birkaç alanı okuyor. Boş
## sözlük, boş ya da bozuk bir yuva demek.
func get_summary(slot: int) -> Dictionary:
	var parsed := _read_slot(slot)
	if parsed.is_empty():
		return {}
	return {
		"caravan_name": String(parsed.get("caravan_name", "")),
		"lineage_generation": maxi(1, int(parsed.get("lineage_generation", 1))),
		"total_days_elapsed": int(parsed.get("total_days_elapsed", 0)),
		"gold": int(parsed.get("gold", 0)),
		"current_location_id": String(parsed.get("current_location_id", "")),
	}

func _read_slot(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
