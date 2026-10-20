extends SceneTree

## Yol balonunu fotoğraflayan araç (test değil, PNG basar). Kısa, orta ve uzun
## bir söz: balon metnin genişliğinde mi, uzun söz satıra mı kırılıyor, harf
## harf dikey bir şeride dönüyor mu (eski hata).

const SHOT: String = "user://journey_shots/balon.png"

func _init() -> void:
	TranslationServer.set_locale("tr")
	get_root().size = Vector2i(1920, 1080)
	WaybookTheme.install()
	var ground := ColorRect.new()
	ground.color = Color(0.32, 0.30, 0.26)
	ground.size = Vector2(1920, 1080)
	get_root().add_child(ground)
	var texts := ["Hm.", "Yağmur yine bastırdı, değil mi?",
		"Babamın tarlası bu yolun öbür ucunda kaldı; bir gün dönüp bakacağım, ama bugün değil."]
	for i in texts.size():
		var figure := Control.new()
		figure.position = Vector2(300 + i * 600, 500)
		figure.size = Vector2(40, 80)
		ground.add_child(figure)
		var balloon := RoadBalloon.new().setup(figure, texts[i])
		ground.add_child(balloon)
	for _frame in 10:
		await process_frame
	DirAccess.make_dir_recursive_absolute("user://journey_shots")
	get_root().get_texture().get_image().save_png(SHOT)
	print("  -> balon.png")
	quit()
