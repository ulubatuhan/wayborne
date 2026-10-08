## godot_equals_blender icin: oynaticiyi Blender karesiyle ayni tuvalde (ayni boyut,
## ayni capa, opak ayni zemin rengi) her karede ciziip PNG'ye yazar.
##   xvfb-run ... godot --path . --rendering-driver opengl3 --script res://tools/figure_pipeline/godot/capture_player.gd
extends SceneTree

## Varsayilan atlas/ve cikti; "-- flat" ile duz tonlu atlas_flat -> godot_flat.
var ATLAS := "res://build/figures/faz1/atlas"
var OUT := "res://build/figures/faz1/godot"
const BG := Color8(58, 54, 50)

func _init() -> void:
	if "flat" in OS.get_cmdline_user_args():
		ATLAS += "_flat"
		OUT += "_flat"
	var atlas_dir := ProjectSettings.globalize_path(ATLAS)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(atlas_dir.path_join("atlas.json")))
	var canvas := Vector2i(int(meta["canvas"][0]), int(meta["canvas"][1]))
	var vp := SubViewport.new()
	vp.size = canvas
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	get_root().add_child(vp)
	var bg := ColorRect.new()
	bg.color = BG
	bg.size = Vector2(canvas)
	vp.add_child(bg)
	var player: Node2D = load("res://tools/figure_pipeline/godot/figure_player.gd").new()
	vp.add_child(player)
	player.setup(atlas_dir)
	player.position = Vector2(meta["anchor_px"][0], meta["anchor_px"][1])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for i in player.frame_count():
		player.set_frame(i)
		await process_frame
		await process_frame
		var img := vp.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT).path_join("f%02d.png" % int(meta["frames"][i])))
	print("yakalandi: ", player.frame_count(), " kare")
	quit()
