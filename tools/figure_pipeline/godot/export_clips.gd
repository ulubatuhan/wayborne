## Faz 2: config/build.json'daki her klibi oyunun kendi FigureRig.pose()'u ile
## karelere örnekler; kemik açılarını (ekran koordinatı: x sağa, y aşağı; radyan)
## ve eklemleri build/figures/clips/<klip>.json'a yazar.
##   godot --headless --path . --script res://tools/figure_pipeline/godot/export_clips.gd
##
## Oturan binicide FigureRig arka bacağı hiç çözmüyor (oyunda atın arkasında
## kalıyor, bones_for(true)); 3B render'da yine de bir arka bacak gerekiyor,
## o yüzden ön bacağın açıları kopyalanıyor - iki bacak da atın iki yanında.
extends SceneTree

const BUILD_CFG := "res://tools/figure_pipeline/config/build.json"
const OUT_DIR := "res://build/figures/clips"

func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BUILD_CFG))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var h: float = FigureRig.REF_H
	for clip_name in cfg["clips"]:
		var clip: Dictionary = cfg["clips"][clip_name]
		var n: int = int(clip["frames"])
		var seated := bool(clip["seated"])
		var frames: Array = []
		for i in n:
			var phase := TAU * float(i) / float(n)
			var j := FigureRig.pose(Vector2.ZERO, h, phase, float(clip["motion"]), float(cfg["facing"]),
				float(cfg["lean"]), seated, float(cfg["bulk"]))
			if seated:
				for side_joint in ["knee", "ankle", "toe"]:
					j[side_joint + "_back"] = j[side_joint + "_front"]
			var bones := {}
			for bone in FigureRig.BONES:
				if bone == FigureRig.WEAPON:
					continue
				var spec: Dictionary = FigureRig.BONES[bone]
				bones[bone] = (Vector2(j[spec.b]) - Vector2(j[spec.a])).angle()
			var joints := {}
			for k in j:
				joints[k] = [j[k].x, j[k].y]
			frames.append({"index": i, "phase": phase, "bones": bones, "joints": joints})
		var out := {"source": "FigureRig.pose (scripts/character/figure_rig.gd)", "ref_h": h,
			"angle_convention": "ekran: x saga, y asagi; atan2(dy, dx) radyan; figur saga bakiyor",
			"clip": clip_name, "frames_per_cycle": n, "seated": seated, "frames": frames}
		var path := OUT_DIR.path_join(String(clip_name) + ".json")
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(out, " "))
		f.close()
		print("yazildi: ", clip_name, " kare=", n)
	quit()
