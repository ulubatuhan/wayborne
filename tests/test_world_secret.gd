extends RefCounted

## Dünya sırrı (Y-E04): en az on beş ipucu, hepsi çevrilmiş, bölgesine göre
## sırayla duyulur, bir kez duyulur ve kayda girer.

func suite_name() -> String:
	return "Sır"

func run(t) -> void:
	t.ge(WorldSecret.CLUES.size(), 15, "en az on beş ipucu")
	var regions := {}
	for clue in WorldSecret.CLUES:
		var key := String(clue["key"])
		t.ne(TranslationServer.translate(key), key, "ipucu çevrilmiş: %s" % key)
		regions[String(clue["region"])] = true
	t.ge(regions.size(), 8, "ipuçları bölgelere dağılmış")
	var seen: Array = []
	var first := WorldSecret.next_clue(seen, "dag_maden")
	t.eq(first, "CLUE_STONES", "önce her yolda duyulan")
	seen.append(first)
	seen.append("CLUE_FIRST_GRASS")
	t.eq(WorldSecret.next_clue(seen, "dag_maden"), "CLUE_GALLERIES", "sonra bölgenin ipucu")
	t.ne(WorldSecret.next_clue(seen, "vadi"), "CLUE_GALLERIES", "başka bölgede o ipucu duyulmaz")
	var session := GameSession.new(200, 20, 1)
	session.secret_clues = ["CLUE_STONES"]
	var data := session.to_save_dict()
	var loaded := GameSession.new(200, 20, 1)
	loaded.load_from_dict(data)
	t.eq(loaded.secret_clues, ["CLUE_STONES"], "duyulan ipuçları kayıtta")
