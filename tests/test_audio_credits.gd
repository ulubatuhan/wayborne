extends RefCounted

## Ses künyesi (görev Y-J05): `data/assets/audio/` altındaki her ses dosyası
## `KUNYE.tsv`'de bir satırla durur, ve hiçbir satırın lisansı ticari kullanımı
## yasaklamaz (NC, NonCommercial, Sampling+). Kaynağı bilinmeyen satır
## "BEKLENİYOR" diye açıkça işaretlenir; yayın öncesi bunların sayısı sıfıra
## inmeli (test yalnızca sayıyı söyler, düşürmez: kaynak kullanıcının işi).
## Künye .tsv: Godot her .csv'yi çeviri tablosu olarak içe aktarır.

const DIR: String = "res://data/assets/audio/"
const CREDITS: String = "res://data/assets/audio/KUNYE.tsv"
const AUDIO_EXT: Array[String] = ["wav", "ogg", "mp3"]

func suite_name() -> String:
	return "AudioCredits"

func run(t) -> void:
	t.ok(FileAccess.file_exists(CREDITS), "ses künyesi var")
	var forbidden := RegEx.new()
	forbidden.compile("(?i)(\\bnc\\b|noncommercial|sampling\\+)")
	var listed := {}
	var pending: Array[String] = []
	var lines := FileAccess.get_file_as_string(CREDITS).split("\n", false)
	for i in range(1, lines.size()):
		var cells := lines[i].split("\t")
		t.eq(cells.size(), 8, "künye satırı sekiz sütun: %s" % cells[0])
		if cells.size() < 8:
			continue
		listed[cells[0]] = true
		t.ok(forbidden.search(cells[4]) == null,
			"ticari kullanımı yasaklayan lisans yok: %s (%s)" % [cells[0], cells[4]])
		if cells[1] == "BEKLENİYOR":
			pending.append(cells[0])
	var dir := DirAccess.open(DIR)
	var files := 0
	for name in dir.get_files():
		if AUDIO_EXT.has(name.get_extension()):
			files += 1
			t.ok(listed.has(name), "ses dosyası künyede: %s" % name)
	t.ge(float(files), 1.0, "ses klasörü okundu")
	# Bilgi: kaynağı bekleyen parçalar (yayın öncesi sıfır olmalı, Y-J05).
	if not pending.is_empty():
		print("  [AudioCredits] kaynağı bekleyen: ", pending)
