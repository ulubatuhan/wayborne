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
## **Sefer ortası: yalnızca otomatik kayıt, yalnızca sakin anlarda.** Yol
## ekranı günün kararı çözüldükten sonra (kart, savaş, pazarlık açıkken
## değil) yuva 0'a yazar; kayıt `GameSession.to_save_dict()`'in "journey"
## bloğunu ve `JourneyController`'ın anlık görüntüsünü taşır, "Devam Et" yola
## döner (bkz. Nav.resume_scene). Elle kayıt sefer boyunca hâlâ kapalı
## (bkz. InGameMenu) - bir kararın hemen önüne elle kayıt almak, sonucu
## beğenmeyince yeniden denemenin kapısı olurdu.

const SAVE_DIR: String = "user://saves"
const AUTOSAVE_SLOT: int = 0
const SLOT_COUNT: int = 4
const GAME_SESSION_PATH: String = "res://scripts/autoload/game_session.gd"

func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

func has_save(slot: int = AUTOSAVE_SLOT) -> bool:
	var path := _slot_path(slot)
	return FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")

func has_any_save() -> bool:
	for slot in SLOT_COUNT:
		if has_save(slot):
			return true
	return false

## Yazım atomik: önce `.tmp`'ye yazılır, mevcut kayıt `.bak`'a kopyalanır,
## sonra `.tmp` asıl dosyanın yerine taşınır. Yazım ortasında kapanan bir
## sekme (Web) ya da dolan bir kota yarım bir JSON bırakmasın diye - bir
## soyun tek kaydı olan otomatik kaydı kesik bir dosyaya kaybetmek, kalıcı
## kaybı konu alan bir oyunda en ağır hata.
func save_session(session, slot: int = AUTOSAVE_SLOT) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path := _slot_path(slot)
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(session.to_save_dict()))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp_path, path) == OK

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
	var path := _slot_path(slot)
	for candidate in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(candidate)

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

## Asıl dosya bozuk ya da eksikse bir önceki kayda (`.bak`) düşer.
func _read_slot(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	var parsed := _read_json(path)
	if parsed.is_empty():
		parsed = _read_json(path + ".bak")
	return parsed

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	# `JSON.parse_string` bozuk bir dosyada hata basıyor; kesik bir kayıt
	# burada beklenen bir durum (yedeğe düşülecek), gürültü değil.
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data
