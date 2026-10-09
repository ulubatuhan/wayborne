## config/build.json'daki her klibi oyunun kendi pozlarıyla karelere örnekler:
## yürüyüş klipleri `FigureActions.walk_pose()` (FigureRig.pose + bilek + yük),
## aksiyon klipleri `FigureActions.pose()` (anahtar kareler). Kemik açılarını
## (ekran: x sağa, y aşağı; radyan), eklemleri, ayak açılarını, silah yönünü,
## kirişin çekilmişliğini ve kalçanın zemine göre x'ini
## build/figures/clips/<klip>.json'a yazar.
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
		var kind := String(clip.get("kind", "walk"))
		var n: int = int(clip["frames"])
		var seated := bool(clip.get("seated", false))
		var frames: Array = []
		for i in n:
			var phase := TAU * float(i) / float(n)
			var j: Dictionary
			if kind == "action":
				j = FigureActions.pose(String(clip["action"]), i, Vector2.ZERO, h, float(cfg["facing"]), float(cfg["bulk"]))
			else:
				j = FigureActions.walk_pose(Vector2.ZERO, h, phase, float(clip["motion"]), float(cfg["facing"]),
					float(clip.get("ankle_range", 0.0)), bool(clip.get("laden", false)), seated, float(cfg["bulk"]))
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
				if k != "draw":
					joints[k] = [j[k].x, j[k].y]
			frames.append({
				"index": i, "phase": phase, "bones": bones, "joints": joints,
				"foot_front": (Vector2(j["toe_front"]) - Vector2(j["ankle_front"])).angle(),
				"foot_back": (Vector2(j["toe_back"]) - Vector2(j["ankle_back"])).angle(),
				"weapon": (Vector2(j["weapon_tip"]) - Vector2(j["hand_front"])).angle(),
				"draw": float(j["draw"].x),
				# kalçanın zemin noktasına göre x'i, figür boyu cinsinden: saldırıda
				# kalça öne gider, ayaklar yerinde kalır.
				"root_x": float(j["hip"].x) / h,
			})
		var out := {"source": "FigureActions (scripts/character/figure_actions.gd)", "ref_h": h,
			"hip_ratio": FigureRig.HIP_RATIO, "weapon_ratio": FigureRig.WEAPON_RATIO,
			"angle_convention": "ekran: x saga, y asagi; atan2(dy, dx) radyan; figur saga bakiyor",
			"clip": clip_name, "kind": kind, "frames_per_cycle": n, "seated": seated, "frames": frames}
		var path := OUT_DIR.path_join(String(clip_name) + ".json")
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(out, " "))
		f.close()
		print("yazildi: ", clip_name, " kare=", n)
	quit()
