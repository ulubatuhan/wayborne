extends RefCounted

## Her tuşun ekranda bir karşılığı var: tuş yalnızca kısayol. Dokunmatik
## ekranda (Web, telefon) klavye yok - F2'nin arkasında saklanan emir menüsü
## ve A/D'ye bağlı yürüme orada hiç erişilemiyordu. Bu test her ekran
## betiğinde geçen `KEY_*` sabitini tarar ve aynı betikte o tuşun ekrandaki
## karşılığının izini arar. Tabloda olmayan yeni bir tuş testi kırar: önce
## ekrandaki karşılığını kur, sonra buraya yaz.

## Tuş -> aynı betikte bulunması gereken izlerden biri.
const EVIDENCE: Dictionary = {
	"KEY_TAB": ["UI_STATUS_OPEN"],
	"KEY_F3": ["UI_HELP_OPEN"],
	"KEY_L": ["UI_WAYBOOK_OPEN"],
	"KEY_F2": ["_pace_buttons"],
	"KEY_1": ["_pace_buttons"],
	"KEY_E": ["_try_interact_at"],
	"KEY_A": ["leader_offset_for_x", "_walk_to"],
	"KEY_D": ["leader_offset_for_x", "_walk_to"],
	# Esc her zaman görünen bir geri/menü düğmesinin kısayolu (bkz. World
	# Navigation Rules - her ekranın görünür bir çıkışı var, orada sınanıyor).
	"KEY_ESCAPE": [],
}
## Oyuncuya ulaşmayan ya da tuş sabitini veri olarak tutan betikler.
const EXEMPT: Array[String] = [
	"res://scripts/autoload/dev_panel.gd",
	"res://scripts/autoload/gamepad_cursor.gd",
]

func suite_name() -> String:
	return "TouchParity"

func run(t) -> void:
	var regex := RegEx.new()
	regex.compile("\\bKEY_[A-Z0-9]+\\b")
	var checked := 0
	for path in _scripts("res://scripts"):
		if EXEMPT.has(path):
			continue
		var source := FileAccess.get_file_as_string(path)
		var seen := {}
		for match in regex.search_all(source):
			seen[match.get_string()] = true
		for key in seen:
			checked += 1
			if not EVIDENCE.has(key):
				t.ok(false, "%s: %s tablo dışında - ekrandaki karşılığı nerede?" % [path, key])
				continue
			var marks: Array = EVIDENCE[key]
			if marks.is_empty():
				continue
			var found := false
			for mark in marks:
				found = found or source.contains(String(mark))
			t.ok(found, "%s: %s kısayolunun ekranda karşılığı var" % [path, key])
	t.ok(checked > 0, "tarama gerçekten tuş buldu")

func _scripts(root: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(root)
	if dir == null:
		return found
	for file in dir.get_files():
		if file.ends_with(".gd"):
			found.append(root.path_join(file))
	for sub in dir.get_directories():
		found.append_array(_scripts(root.path_join(sub)))
	return found
