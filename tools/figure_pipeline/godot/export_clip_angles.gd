## Faz 1.2: oyunun kendi FigureRig.pose()'u ile bir klibi karelere ornekler, her karede
## kemik acilarini (ekran koordinati: x saga, y asagi; radyan) ve eklemleri yazar.
##   godot --headless --path . --script res://tools/figure_pipeline/godot/export_clip_angles.gd
extends SceneTree

const CLIP_CFG := "res://tools/figure_pipeline/config/clip.json"
const OUT := "res://build/figures/faz1/clip_walk.json"

func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CLIP_CFG))
	var n: int = int(cfg["frames_per_cycle"])
	var h: float = FigureRig.REF_H
	var frames: Array = []
	for i in n:
		var phase := TAU * float(i) / float(n)
		var j := FigureRig.pose(Vector2.ZERO, h, phase, float(cfg["motion"]), float(cfg["facing"]),
			float(cfg["lean"]), bool(cfg["seated"]), float(cfg["bulk"]))
		var bones := {}
		for bone in FigureRig.BONES:
			if bone == FigureRig.WEAPON:
				continue
			var spec: Dictionary = FigureRig.BONES[bone]
			var a: Vector2 = j[spec.a]
			var b: Vector2 = j[spec.b]
			bones[bone] = (b - a).angle()
		var joints := {}
		for k in j:
			joints[k] = [j[k].x, j[k].y]
		frames.append({"index": i, "phase": phase, "bones": bones, "joints": joints})
	var rest := FigureRig.pose(Vector2.ZERO, h, 0.0, 0.0, 1.0)
	var rest_bones := {}
	for bone in FigureRig.BONES:
		if bone == FigureRig.WEAPON:
			continue
		var spec: Dictionary = FigureRig.BONES[bone]
		rest_bones[bone] = (Vector2(rest[spec.b]) - Vector2(rest[spec.a])).angle()
	var out := {"source": "FigureRig.pose (scripts/character/figure_rig.gd:112)", "ref_h": h,
		"angle_convention": "ekran: x saga, y asagi; atan2(dy, dx) radyan; figur saga bakiyor",
		"clip": cfg["clip"], "frames_per_cycle": n, "rest_bones": rest_bones, "frames": frames}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/figures/faz1"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	print("yazildi: ", ProjectSettings.globalize_path(OUT), " kare=", n)
	quit()
