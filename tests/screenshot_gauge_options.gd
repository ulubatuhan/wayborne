extends SceneTree

## Gösterge önerileri (kullanıcı, 2026-10-22: "sıcaklık hariç diğer göstergeleri hiç
## beğenmedim, şişe istemiyorum"). Moral, stres, tehlike ve takat için üçer nesne,
## her biri iyi / orta / kötü hâlde - alevin dili: değeri nesnenin hâli söylüyor,
## sayı altında kalıyor. Test değil, bir taslak sayfası:
##   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 1920x1080x24" \
##     godot --path . --rendering-driver opengl3 --script res://tests/screenshot_gauge_options.gd

const OUT: String = "res://proje_takibi/referans/taslaklar/y_gosterge_onerileri.png"
const CELL: Vector2 = Vector2(144, 168)
const STATES: Array[float] = [1.0, 0.5, 0.08]
const ROWS: Array = [
	["Moral", ["Sancak", "Mühür", "Güneş"], ["banner", "seal", "sun"]],
	["Stres", ["Halat", "Taş levha", "Bulut"], ["rope", "stone", "storm"]],
	["Tehlike", ["Kurt gözleri", "Kuzgunlar", "Kılıç ve kın"], ["eyes", "ravens", "sword"]],
	["Takat", ["Kum saati", "Ayak izleri", "Yolcu"], ["hourglass", "steps", "walker"]],
]

class Glyph extends Control:
	var kind: String = ""
	## 1 iyi, 0 kötü (stres ve tehlikede de: 0 = en yüksek stres/tehlike).
	var good: float = 1.0

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), ArtPalette.GRIM_CHARCOAL)
		draw_rect(Rect2(Vector2.ZERO, size), Color(ArtPalette.GRIM_RUST, 0.6), false, 1.0)
		# Çizimler 96x112'lik kutuya göre; hücre büyüyünce ölçekleniyor.
		var k := size.x / 96.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		call("_" + kind, Rect2(Vector2.ZERO, size / k))

	func _ink(points: PackedVector2Array, fill: Color, line: float = 1.6) -> void:
		draw_colored_polygon(points, fill)
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, ArtPalette.INK, line, true)

	func _circle(c: Vector2, r: float, fill: Color, line: float = 1.6) -> void:
		draw_circle(c, r, fill)
		draw_arc(c, r, 0.0, TAU, 32, ArtPalette.INK, line, true)

	# --- Moral ---------------------------------------------------------------
	## Sancak direkte: moral yüksekken tepede dalgalanır, düştükçe iner, sarkar, yırtılır.
	func _banner(b: Rect2) -> void:
		var pole_x := b.position.x + 26.0
		draw_line(Vector2(pole_x, b.position.y + 8), Vector2(pole_x, b.end.y - 6), ArtPalette.GRIM_RUST, 3.0)
		_circle(Vector2(pole_x, b.position.y + 8), 3.0, ArtPalette.GRIM_AMBER, 1.0)
		var attach := Vector2(pole_x + 1.5, lerpf(b.position.y + 62, b.position.y + 12, good))
		var a := deg_to_rad(lerpf(78.0, 6.0, good))
		var dir := Vector2(cos(a), sin(a))
		var perp := Vector2(-dir.y, dir.x)
		var length := lerpf(40.0, 54.0, good)
		var width := 22.0
		var pts := PackedVector2Array()
		var steps := 10
		for i in steps + 1:
			var u := float(i) / steps
			var wave := sin(u * 6.0) * 3.0 * good * u
			pts.append(attach + dir * u * length + perp * wave)
		# Kırlangıç kuyruk ve (düşük moralde) yırtık kenar.
		pts.append(attach + dir * (length - 9.0) + perp * (width * 0.5))
		for i in range(steps, -1, -1):
			var u := float(i) / steps
			var wave := sin(u * 6.0) * 3.0 * good * u
			var tear := 0.0
			if good < 0.6 and i % 3 == 1:
				tear = (0.6 - good) * 14.0
			pts.append(attach + dir * u * length + perp * (width - tear + wave))
		_ink(pts, ArtPalette.GRIM_CRIMSON.darkened(0.35 * (1.0 - good)))

	## Balmumu mühür: bütün, çatlak, ikiye bölünmüş.
	func _seal(b: Rect2) -> void:
		var c := b.get_center() + Vector2(0, -4)
		var r := 28.0
		var split := 0.0 if good > 0.2 else 5.0
		for half in [-1, 1]:
			var pts := PackedVector2Array()
			for i in 25:
				var t: float = PI * float(i) / 24.0 + (PI * 0.5 if half > 0 else -PI * 0.5)
				var rr := r + sin(t * 7.0) * 2.0
				pts.append(c + Vector2(cos(t), sin(t)) * rr + Vector2(split * half, 0))
			_ink(pts, ArtPalette.GRIM_CRIMSON.darkened(0.15))
		draw_arc(c, r * 0.62, 0.0, TAU, 28, Color(ArtPalette.INK, 0.6), 1.4, true)
		# Damga: fener.
		draw_rect(Rect2(c + Vector2(-5, -8), Vector2(10, 14)), Color(ArtPalette.GRIM_AMBER, 0.8))
		draw_rect(Rect2(c + Vector2(-5, -8), Vector2(10, 14)), ArtPalette.INK, false, 1.2)
		draw_line(c + Vector2(-6, -11), c + Vector2(6, -11), ArtPalette.INK, 2.0)
		if good < 0.75:
			var crack := PackedVector2Array([c + Vector2(-4, -r), c + Vector2(2, -14), c + Vector2(-3, -4),
				c + Vector2(4, 8), c + Vector2(0, r)])
			var n := 2 + int((0.75 - good) * 6.0)
			draw_polyline(crack.slice(0, mini(n, crack.size())), ArtPalette.INK, 2.0, true)
		if good < 0.4:
			draw_polyline(PackedVector2Array([c + Vector2(r, 4), c + Vector2(14, 2), c + Vector2(6, 9)]), ArtPalette.INK, 1.8, true)

	## Güneş ve bulut: moral düştükçe bulut güneşi örter, sonunda yağmur.
	func _sun(b: Rect2) -> void:
		var c := b.get_center() + Vector2(-8, -8)
		if good > 0.3:
			for i in 10:
				var t := TAU * i / 10.0
				draw_line(c + Vector2(cos(t), sin(t)) * 20.0, c + Vector2(cos(t), sin(t)) * (24.0 + 6.0 * good),
					ArtPalette.GRIM_AMBER, 2.0)
		_circle(c, 16.0, ArtPalette.GRIM_AMBER.darkened(0.5 * (1.0 - good)))
		var cover := 1.0 - good
		var cloud := c + Vector2(lerpf(30.0, 4.0, cover), lerpf(16.0, 4.0, cover))
		var shade := ArtPalette.GRIM_ASH.darkened(0.55 * cover)
		for off in [Vector2(-14, 4), Vector2(0, -4), Vector2(14, 4), Vector2(0, 8)]:
			draw_circle(cloud + off, 12.0, shade)
		for off in [Vector2(-14, 4), Vector2(0, -4), Vector2(14, 4)]:
			draw_arc(cloud + off, 12.0, PI * 0.9, PI * 2.1, 14, ArtPalette.INK, 1.4, true)
		if good < 0.2:
			for i in 5:
				var x := cloud.x - 16.0 + i * 8.0
				draw_line(Vector2(x, cloud.y + 22), Vector2(x - 4, cloud.y + 34), ArtPalette.GRIM_SLATE_LIGHT, 1.4)

	# --- Stres ---------------------------------------------------------------
	## Halat: stres arttıkça ortası incelir, lifler kopar, sonunda tek lif kalır.
	func _rope(b: Rect2) -> void:
		var x := b.get_center().x
		var top := b.position.y + 8.0
		var bottom := b.end.y - 8.0
		var mid := (top + bottom) * 0.5
		var bad := 1.0 - good
		var strands := 3
		for s in strands:
			var phase := TAU * s / strands
			var pts := PackedVector2Array()
			var broken := bad > 0.35 and s > 0 and (s == 1 or bad > 0.75)
			for i in 41:
				var y := lerpf(top, bottom, i / 40.0)
				var near := 1.0 - clampf(absf(y - mid) / 22.0, 0.0, 1.0)
				var thin := 1.0 - 0.7 * bad * near
				if broken and absf(y - mid) < 6.0:
					if pts.size() > 1:
						draw_polyline(pts, ArtPalette.GRIM_PARCHMENT_DIM, 4.0 * thin, true)
					pts = PackedVector2Array()
					continue
				pts.append(Vector2(x + sin(y * 0.35 + phase) * 6.0 * thin, y))
			if pts.size() > 1:
				draw_polyline(pts, ArtPalette.GRIM_PARCHMENT_DIM.darkened(0.15 * s), 4.0, true)
		if bad > 0.3:
			for i in int(bad * 9.0):
				var side := -1.0 if i % 2 == 0 else 1.0
				var y := mid - 6.0 + float(i % 4) * 4.0
				draw_line(Vector2(x, y), Vector2(x + side * (6.0 + i * 1.5), y + (i % 3 - 1) * 4.0),
					ArtPalette.GRIM_PARCHMENT, 1.0)

	## Taş levha: stres çatlağı yukarıdan aşağı yayar, en kötüsünde bir parça düşer.
	func _stone(b: Rect2) -> void:
		var r := Rect2(b.position + Vector2(18, 10), Vector2(b.size.x - 36, b.size.y - 24))
		var pts := PackedVector2Array([r.position + Vector2(6, 0), Vector2(r.end.x - 6, r.position.y),
			Vector2(r.end.x, r.position.y + 8), r.end - Vector2(0, 4), Vector2(r.position.x + 4, r.end.y),
			r.position + Vector2(0, 8)])
		var bad := 1.0 - good
		if bad > 0.85:
			pts = PackedVector2Array([pts[0], Vector2(r.get_center().x + 6, r.position.y), Vector2(r.get_center().x - 2, r.position.y + 24),
				Vector2(r.end.x, r.position.y + 36), pts[3], pts[4], pts[5]])
		_ink(pts, ArtPalette.GRIM_ASH.darkened(0.35))
		var crack := PackedVector2Array([Vector2(r.get_center().x + 4, r.position.y), Vector2(r.get_center().x - 3, r.position.y + 18),
			Vector2(r.get_center().x + 6, r.position.y + 34), Vector2(r.get_center().x - 2, r.position.y + 52),
			Vector2(r.get_center().x + 3, r.end.y)])
		var n := int(round(bad * (crack.size() - 1))) + 1
		if n >= 2:
			draw_polyline(crack.slice(0, n), ArtPalette.INK, 2.0, true)
		if bad > 0.45:
			draw_polyline(PackedVector2Array([crack[1], crack[1] + Vector2(-14, 6), crack[1] + Vector2(-20, 4)]), ArtPalette.INK, 1.4, true)
			draw_polyline(PackedVector2Array([crack[2], crack[2] + Vector2(12, 8)]), ArtPalette.INK, 1.4, true)

	## Fırtına bulutu: beyaz küçük bulut, gri yağmur, kara bulut ve şimşek.
	func _storm(b: Rect2) -> void:
		var bad := 1.0 - good
		var c := b.get_center() + Vector2(0, -14)
		var scale := lerpf(0.7, 1.15, bad)
		var shade := ArtPalette.GRIM_PARCHMENT.lerp(ArtPalette.GRIM_CHARCOAL_SOFT, bad)
		for off in [Vector2(-16, 4), Vector2(0, -6), Vector2(16, 4), Vector2(0, 8)]:
			draw_circle(c + off * scale, 13.0 * scale, shade)
		for off in [Vector2(-16, 4), Vector2(0, -6), Vector2(16, 4)]:
			draw_arc(c + off * scale, 13.0 * scale, PI * 0.9, PI * 2.1, 14, ArtPalette.INK, 1.4, true)
		if bad > 0.3:
			for i in 6:
				var x := c.x - 20.0 + i * 8.0
				draw_line(Vector2(x, c.y + 22), Vector2(x - 5, c.y + 38), ArtPalette.GRIM_SLATE_LIGHT, 1.3)
		if bad > 0.7:
			_ink(PackedVector2Array([c + Vector2(2, 16), c + Vector2(-8, 34), c + Vector2(0, 34), c + Vector2(-6, 52),
				c + Vector2(10, 28), c + Vector2(2, 28), c + Vector2(10, 16)]), ArtPalette.GRIM_AMBER, 1.2)

	# --- Tehlike -------------------------------------------------------------
	## Karanlıkta kurt gözleri: tehlike büyüdükçe çift çift artar, yaklaşır.
	func _eyes(b: Rect2) -> void:
		var bad := 1.0 - good
		draw_rect(b.grow(-4), Color(0.02, 0.02, 0.03))
		var spots := [Vector2(0.30, 0.40), Vector2(0.70, 0.55), Vector2(0.45, 0.72), Vector2(0.22, 0.65),
			Vector2(0.75, 0.30), Vector2(0.52, 0.30)]
		var count := int(round(bad * spots.size()))
		if count == 0:
			draw_arc(b.get_center(), 3.0, 0.0, TAU, 12, Color(ArtPalette.GRIM_ASH, 0.25), 1.0)
		for i in count:
			var p: Vector2 = b.position + b.size * Vector2(spots[i])
			var r := 2.2 + bad * 1.6
			for dx in [-r * 1.8, r * 1.8]:
				draw_circle(p + Vector2(dx, 0), r * 2.6, Color(ArtPalette.GRIM_AMBER, 0.12))
				var eye := PackedVector2Array([p + Vector2(dx - r * 1.4, 0), p + Vector2(dx, -r * 0.8),
					p + Vector2(dx + r * 1.4, 0), p + Vector2(dx, r * 0.6)])
				draw_colored_polygon(eye, ArtPalette.GRIM_AMBER)
				draw_line(p + Vector2(dx, -r * 0.6), p + Vector2(dx, r * 0.4), ArtPalette.INK, 1.0)

	## Dalda kuzgunlar: tehlike büyüdükçe biri, sonra dördü konar.
	func _ravens(b: Rect2) -> void:
		var bad := 1.0 - good
		var y := b.get_center().y + 14.0
		draw_line(Vector2(b.position.x + 6, y + 4), Vector2(b.end.x - 4, y - 2), ArtPalette.GRIM_RUST, 4.0)
		draw_line(Vector2(b.position.x + 40, y + 2), Vector2(b.position.x + 54, y + 14), ArtPalette.GRIM_RUST, 2.5)
		var count := int(round(bad * 4.0))
		for i in count:
			var p := Vector2(b.position.x + 16 + i * 21, y - 2 - i * 1.5)
			var body := PackedVector2Array([p + Vector2(-8, -2), p + Vector2(-2, -12), p + Vector2(5, -12),
				p + Vector2(8, -4), p + Vector2(2, 2), p + Vector2(-12, 4)])
			_ink(body, ArtPalette.INK.lightened(0.08), 1.0)
			_circle(p + Vector2(4, -15), 4.5, ArtPalette.INK.lightened(0.08), 1.0)
			draw_colored_polygon(PackedVector2Array([p + Vector2(8, -16), p + Vector2(14, -14), p + Vector2(8, -13)]), ArtPalette.GRIM_IRON)
			draw_circle(p + Vector2(5, -16), 0.9, ArtPalette.GRIM_AMBER)

	## Kın ve kılıç: tehlike büyüdükçe kılıç kından çıkar.
	func _sword(b: Rect2) -> void:
		var bad := 1.0 - good
		var x := b.get_center().x
		var sheath := Rect2(Vector2(x - 6, b.position.y + 54), Vector2(12, 50))
		_ink(PackedVector2Array([sheath.position, Vector2(sheath.end.x, sheath.position.y), Vector2(sheath.end.x, sheath.end.y - 6),
			Vector2(x, sheath.end.y), Vector2(sheath.position.x, sheath.end.y - 6)]), ArtPalette.GRIM_RUST.darkened(0.2))
		var out := bad * 30.0
		var guard_y := sheath.position.y - 2.0 - out
		if out > 2.0:
			_ink(PackedVector2Array([Vector2(x - 3, guard_y + 2), Vector2(x + 3, guard_y + 2),
				Vector2(x + 3, sheath.position.y), Vector2(x - 3, sheath.position.y)]), ArtPalette.GRIM_FROST.darkened(0.25), 1.0)
		draw_line(Vector2(x - 12, guard_y), Vector2(x + 12, guard_y), ArtPalette.GRIM_IRON, 4.0)
		draw_rect(Rect2(Vector2(x - 2.5, guard_y - 16), Vector2(5, 16)), ArtPalette.GRIM_RUST)
		_circle(Vector2(x, guard_y - 18), 3.5, ArtPalette.GRIM_AMBER, 1.0)
		if bad > 0.8:
			draw_line(Vector2(x + 6, guard_y + 10), Vector2(x + 6, guard_y + 30), Color(1, 1, 1, 0.35), 1.0)

	# --- Takat ---------------------------------------------------------------
	## Kum saati: üstteki kum takatin kendisi.
	func _hourglass(b: Rect2) -> void:
		var c := b.get_center()
		var hw := 22.0
		var hh := 38.0
		var top := PackedVector2Array([c + Vector2(-hw, -hh), c + Vector2(hw, -hh), c + Vector2(3, -2), c + Vector2(-3, -2)])
		var bottom := PackedVector2Array([c + Vector2(-3, 2), c + Vector2(3, 2), c + Vector2(hw, hh), c + Vector2(-hw, hh)])
		draw_colored_polygon(top, Color(ArtPalette.GRIM_FROST, 0.10))
		draw_colored_polygon(bottom, Color(ArtPalette.GRIM_FROST, 0.10))
		var sand := ArtPalette.GRIM_AMBER.darkened(0.15)
		var level := lerpf(-4.0, -hh + 4.0, good)
		var tw := hw * (absf(level) / hh)
		if good > 0.03:
			draw_colored_polygon(PackedVector2Array([c + Vector2(-tw, level), c + Vector2(tw, level), c + Vector2(3, -3), c + Vector2(-3, -3)]), sand)
			draw_line(c + Vector2(0, -2), c + Vector2(0, hh - 2), Color(sand, 0.8), 1.2)
		var pile := lerpf(hh - 2.0, 6.0, 1.0 - good)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-hw + 2, hh - 1), c + Vector2(hw - 2, hh - 1), c + Vector2(0, pile)]), sand)
		for poly in [top, bottom]:
			var closed: PackedVector2Array = poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, ArtPalette.GRIM_SLATE_LIGHT, 1.4, true)
		draw_rect(Rect2(c + Vector2(-hw - 5, -hh - 6), Vector2(hw * 2 + 10, 6)), ArtPalette.GRIM_RUST)
		draw_rect(Rect2(c + Vector2(-hw - 5, hh), Vector2(hw * 2 + 10, 6)), ArtPalette.GRIM_RUST)

	## Ayak izleri: dinç adımlar keskin ve uzun, yorgun adımlar sürünür, silikleşir.
	func _steps(b: Rect2) -> void:
		var count := 2 + int(round(good * 4.0))
		var stride := lerpf(10.0, 15.0, good)
		for i in count:
			var p := Vector2(b.position.x + 34 + (i % 2) * 16, b.end.y - 14 - i * stride)
			var alpha := clampf(0.35 + 0.65 * good - i * 0.06 * (1.0 - good), 0.12, 1.0)
			var col := Color(ArtPalette.GRIM_PARCHMENT_DIM, alpha)
			if good < 0.3:
				draw_line(p + Vector2(0, 6), p + Vector2(2, -4), col, 4.0)
			else:
				var foot := PackedVector2Array()
				for k in 12:
					var t := TAU * k / 12.0
					foot.append(p + Vector2(cos(t) * 4.0, sin(t) * 7.0))
				draw_colored_polygon(foot, col)
				draw_circle(p + Vector2(0, -10), 3.0, col)

	## Yolcu: dik yürür, asaya yaslanır, diz çöker.
	func _walker(b: Rect2) -> void:
		var ground := b.end.y - 10.0
		var x := b.get_center().x
		draw_line(Vector2(b.position.x + 8, ground), Vector2(b.end.x - 8, ground), ArtPalette.GRIM_RUST, 1.5)
		var lean := deg_to_rad(lerpf(38.0, 4.0, good))
		var hip_h := lerpf(16.0, 34.0, clampf(good * 1.6, 0.0, 1.0))
		var hip := Vector2(x - 4, ground - hip_h)
		var neck := hip + Vector2(sin(lean), -cos(lean)) * 30.0
		var col := ArtPalette.GRIM_PARCHMENT
		draw_line(hip, neck, col, 4.0)
		_circle(neck + Vector2(sin(lean), -cos(lean)) * 8.0, 7.0, col, 1.2)
		if good < 0.25:
			draw_line(hip, hip + Vector2(12, 4), col, 3.5)
			draw_line(hip + Vector2(12, 4), Vector2(x + 10, ground), col, 3.5)
			draw_line(hip, Vector2(x - 12, ground), col, 3.5)
		else:
			var stride := 10.0 * good
			draw_line(hip, Vector2(x - 4 + stride, ground), col, 3.5)
			draw_line(hip, Vector2(x - 4 - stride, ground), col, 3.5)
		var hand := neck + Vector2(10, 14)
		draw_line(neck, hand, col, 3.0)
		if good < 0.75:
			draw_line(Vector2(hand.x + 2, hand.y - 12), Vector2(hand.x + 6, ground), ArtPalette.GRIM_RUST, 2.5)

func _initialize() -> void:
	TranslationServer.set_locale("tr")
	var view := Vector2i(1920, 1080)
	get_root().size = view
	DisplayServer.window_set_size(view)
	var bg := ColorRect.new()
	bg.color = ArtPalette.GRIM_CHARCOAL_SOFT
	bg.size = Vector2(view)
	get_root().add_child(bg)
	_label("Gösterge önerileri (şişesiz) - her nesne iyi / orta / kötü", Vector2(24, 12), 22)
	var x0 := 130.0
	var col_w := CELL.x * 3 + 40
	for r in ROWS.size():
		var row: Array = ROWS[r]
		var y := 80.0 + r * (CELL.y + 70)
		_label(String(row[0]), Vector2(16, y + CELL.y * 0.4), 20)
		for o in 3:
			var ox := x0 + o * col_w
			_label("%s) %s" % [["A", "B", "C"][o], String(row[1][o])], Vector2(ox, y - 26), 17)
			for s in STATES.size():
				var g := Glyph.new()
				g.kind = String(row[2][o])
				g.good = STATES[s]
				g.position = Vector2(ox + s * (CELL.x + 6), y)
				g.size = CELL
				g.clip_contents = true
				get_root().add_child(g)
	_shoot.call_deferred()

func _label(text: String, at: Vector2, font_size: int) -> void:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", ArtPalette.GRIM_PARCHMENT)
	get_root().add_child(l)

func _shoot() -> void:
	for i in 4:
		await process_frame
	var image := get_root().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT))
	print("  -> ", OUT, " ", image.get_size())
	quit()
