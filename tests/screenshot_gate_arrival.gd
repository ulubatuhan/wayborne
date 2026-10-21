extends SceneTree

## Şehir kapısı karşılama resmi (GateArrival): birkaç şehir, gündüz ve gece.
## Çıktı: user://gate_shots/

const SHOT_DIR: String = "user://gate_shots/"
const CITIES: Array = ["vastrevar", "kirsavel", "belvanor"]
const HOURS: Array = [12.0, 22.0]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	get_root().size = Vector2i(1600, 900)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	await process_frame
	await process_frame
	for city in CITIES:
		for hour in HOURS:
			var gate := GateArrival.new().setup(String(city), float(hour))
			get_root().add_child(gate)
			for _i in 12:
				await process_frame
			var file := "%s_%d.png" % [city, int(hour)]
			get_root().get_texture().get_image().save_png(SHOT_DIR + file)
			print("  -> ", file)
			gate.queue_free()
			await process_frame
	quit()
