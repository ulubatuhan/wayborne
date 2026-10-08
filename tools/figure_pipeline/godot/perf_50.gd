## Faz 5: 50 figür, kare kümesinden (BodyFrames), yürürken. Tek komut:
##
##   godot --path . --script res://tools/figure_pipeline/godot/perf_50.gd [-- 50 600]
##
## Argümanlar: figür sayısı (50), ölçülen kare sayısı (600), isteğe bağlı
## "legacy" (karşılaştırma: eski parça mankeni, aynı koşulda). Isınma 60 kare.
## Rapor: ortalama / p95 / en kötü kare süresi (ms), çizim çağrısı ve video
## belleği. Altı varyant ve üç klip karışık; boylar ve fazlar dağıtılmış,
## yani her figür farklı bir kareyi gösteriyor (önbellek lehine hile yok).
extends SceneTree

const WARMUP: int = 60
const VARIANTS: Array[String] = [
	"body_male_average", "body_female_average", "body_male_lean",
	"body_male_heavy", "body_female_lean", "body_female_heavy",
]

var _figures: Array[WalkFigure] = []
var _times: Array[float] = []
var _frame: int = 0
var _count: int = 50
var _measure: int = 600
var _last: int = 0

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		_count = int(args[0])
	if args.size() >= 2:
		_measure = int(args[1])
	var legacy := args.size() >= 3 and args[2] == "legacy"
	WaybookTheme.install()
	var root := Control.new()
	root.size = Vector2(1600, 900)
	var bg := ColorRect.new()
	bg.color = Color(0.55, 0.6, 0.5)
	bg.size = root.size
	root.add_child(bg)
	var cols := 10
	for i in _count:
		var f := WalkFigure.new()
		f.size = Vector2(150, 170)
		f.position = Vector2(10 + (i % cols) * 158, 10 + (i / cols) * 176)
		f.set_kind(
			WalkFigure.KIND_PERSON, "guard", 0.9 + 0.05 * (i % 5),
			CharacterData.get_skin_tone_color(i % 4), false, {},
			"" if legacy else VARIANTS[i % VARIANTS.size()]
		)
		f.set_phase_offset(float(i) * 0.37)
		root.add_child(f)
		_figures.append(f)
	get_root().add_child(root)
	_last = Time.get_ticks_usec()

func _process(delta: float) -> bool:
	for i in _figures.size():
		var f := _figures[i]
		# Üçte biri durur (idle klibi), geri kalanı yürür.
		f.advance(delta, 0.0 if i % 3 == 0 else 1.0)
	var now := Time.get_ticks_usec()
	if _frame >= WARMUP:
		_times.append(float(now - _last) / 1000.0)
	_last = now
	_frame += 1
	if _frame >= WARMUP + _measure:
		_report()
		return true
	return false

func _report() -> void:
	var sorted := _times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in _times:
		total += t
	var missing := 0
	for v in VARIANTS:
		if BodyFrames.for_body(v) == null:
			missing += 1
	print("figur=%d kare=%d ort=%.2f ms p95=%.2f ms en_kotu=%.2f ms cizim_cagrisi=%d video_bellek=%.1f MB eksik_varyant=%d" % [
		_count, _times.size(), total / _times.size(),
		sorted[int(sorted.size() * 0.95)], sorted[-1],
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1e6, missing,
	])
