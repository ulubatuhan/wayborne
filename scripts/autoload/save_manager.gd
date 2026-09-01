extends Node

## Autoload: GameSession'ı user://save.json'a yazar/okur. Serileştirme
## bilgisinin kendisi GameSession.to_save_dict()/load_from_dict()'te -
## burada yalnızca dosya G/Ç'si var.
##
## Bu dosyada bilerek hiçbir class_name'e başvurulmuyor (bkz. CLAUDE.md
## Autoload rule): GameSession yalnızca load() ile çalışma anında
## çözülüyor, sonra üzerinde normal örnek metotları çağrılıyor.

const SAVE_PATH: String = "user://save.json"
const GAME_SESSION_PATH: String = "res://scripts/autoload/game_session.gd"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_session(session) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(session.to_save_dict()))
	file.close()
	return true

## Kayıt yoksa ya da bozuksa null döner.
func load_session():
	if not has_save():
		return null

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null

	var session_script := load(GAME_SESSION_PATH)
	# Sıfır başlangıç erzağı: kalan erzak zaten kayıttaki envanterden geliyor.
	var session = session_script.new(0, 0)
	session.load_from_dict(parsed)
	return session

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
