extends SceneTree

## İmlecin oyundaki görüntüsü (tools/cursor_art.py). Sistem imleci bir ekran görüntüsüne
## girmiyor; kumanda imleci aynı resmi oyunun içinde çizdiği için onu ana menünün ve
## şehrin üstünde gösteriyor. Test değil, resim.
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . \
##     --rendering-driver opengl3 --script res://tests/screenshot_cursor.gd

const OUT_DIR: String = "user://screenshots"
const SPOTS: Array = [Vector2(760, 520), Vector2(1180, 640)]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	for i in 40:
		await process_frame
	var pad = root.get_node("GamepadCursor")
	var icon: Control = pad._icon
	icon.visible = true
	for k in SPOTS.size():
		icon.position = SPOTS[k]
		icon.queue_redraw()
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("%s/cursor_%d.png" % [OUT_DIR, k])
	print("cursor screenshots -> ", ProjectSettings.globalize_path(OUT_DIR))
	quit()
