extends RefCounted

## Sıkışma yok (görev Y-H04): ekran üstüne açılan her panel (CanvasLayer)
## Esc'i kendisi ele alır - kapatır, ya da karar paneliyse yalnızca yutar.
## Ele almayan bir panel açıkken Esc, UiTheme'in "alt ekrandan geri" kuralına
## düşüp paneli değil altındaki ekranı kapatıyordu.

const DIRS: Array[String] = ["res://scripts/ui", "res://scripts/ui/grim"]

func suite_name() -> String:
	return "EscPanels"

func run(t) -> void:
	var panels := 0
	for dir_path in DIRS:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for name in dir.get_files():
			if name.get_extension() != "gd":
				continue
			var text := FileAccess.get_file_as_string(dir_path.path_join(name))
			if not text.contains("\nextends CanvasLayer") and not text.begins_with("extends CanvasLayer"):
				continue
			panels += 1
			t.ok(text.contains("ui_cancel") or text.contains("KEY_ESCAPE"),
				"panel Esc'i ele alıyor: %s" % name)
	t.ge(float(panels), 10.0, "panel taraması en az on panel buldu")
