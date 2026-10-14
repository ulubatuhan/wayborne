class_name CombatFxLayer
extends Control

## Savaş sahnesinin üstündeki geçici efektler: uçan ok ve bıçak, ateş oku,
## buz ışını, büyülü füzeler, zehir bulutu, alev yelpazesi, büyü kalkanı ve
## vuruşun çarpması (kıvılcım, kesik izi, kan, alev patlaması, kırağı
## kırığı). Slotlar her tazelemede yeniden kurulduğu için efekt onlarda
## değil, sahnenin kendi katmanında yaşıyor - yüzen sayılarla aynı gerekçe.
##
## Her efekt bir başlangıç zamanı ve süreyle tutuluyor; konumu saf bir
## zaman fonksiyonu (`travel_point`), test sahnesiz okuyabilsin. Parçacık
## dokuları `StatusFx.texture` önbelleğinden (Kenney, CC0).

const TRAVEL_MSEC: Dictionary = {
	"arrow": 240, "thrown": 260, "sling": 240, "flask": 320,
	"bolt": 300, "missiles": 360, "ray": 160, "spray": 280, "cone": 220, "aura": 0,
}
const IMPACT_MSEC: int = 380
const RAY_HOLD_MSEC: int = 260
const AURA_MSEC: int = 520

var _effects: Array = []

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

static func travel_msec(delivery: String) -> int:
	return int(TRAVEL_MSEC.get(delivery, 0))

## Uçan bir şeyin `u` (0..1) anındaki yeri: düz çizgi üstünde hafif bir
## yay - ok ve taş yükselip iniyor, büyü dümdüz gidiyor.
static func travel_point(from: Vector2, to: Vector2, u: float, delivery: String) -> Vector2:
	var p := from.lerp(to, u)
	var arc := 0.0
	match delivery:
		"arrow", "sling", "flask", "thrown":
			arc = from.distance_to(to) * 0.12
	return p - Vector2(0.0, arc * 4.0 * u * (1.0 - u))

## Bir saldırı: mermi (varsa) `from`'dan `to`'ya, sonra çarpma. Iskalanan
## bir saldırının mermisi hedefin yanından geçiyor, çarpma yok.
func play_attack(from: Vector2, to: Vector2, delivery: String, style: String, hit: bool, now: int) -> void:
	var travel := travel_msec(delivery)
	if delivery == "aura":
		_effects.append({"type": "aura", "at": from, "style": style, "start": now, "duration": AURA_MSEC})
	elif travel > 0:
		var end := to if hit else to + Vector2((to.x - from.x) * 0.25, -18.0)
		_effects.append({"type": "travel", "from": from, "to": end, "delivery": delivery, "style": style,
			"start": now, "duration": travel + (RAY_HOLD_MSEC if delivery == "ray" else 0)})
	if hit and delivery != "aura":
		_effects.append({"type": "impact", "at": to, "style": style, "start": now + travel, "duration": IMPACT_MSEC,
			"dir": signf(to.x - from.x)})
	elif not hit and delivery != "aura":
		_effects.append({"type": "whoosh", "at": to, "start": now + travel, "duration": 260, "dir": signf(to.x - from.x)})
	set_process(true)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var kept: Array = []
	for fx in _effects:
		if now < int(fx.start) + int(fx.duration):
			kept.append(fx)
	_effects = kept
	queue_redraw()
	if _effects.is_empty():
		set_process(false)

## Çizim durumdan değil zamandan: aynı `now` hep aynı kareyi verir
## (ekran görüntüsü aracı da bunu kullanıyor).
func draw_at(now: int) -> void:
	_now_override = now
	queue_redraw()

var _now_override: int = -1

func _draw() -> void:
	var now := _now_override if _now_override >= 0 else Time.get_ticks_msec()
	for fx in _effects:
		var u := CombatFx.progress(int(fx.start), int(fx.duration), now)
		if now < int(fx.start) or u >= 1.0:
			continue
		match String(fx.type):
			"travel": _draw_travel(fx, u)
			"impact": _draw_impact(fx, u)
			"aura": _draw_aura(fx, u)
			"whoosh": _draw_whoosh(fx, u)

func _sprite(name: String, centre: Vector2, size_px: float, color: Color, angle: float = 0.0) -> void:
	var tex := StatusFx.texture(name)
	if tex == null:
		return
	draw_set_transform(centre, angle, Vector2.ONE)
	draw_texture_rect(tex, Rect2(Vector2(-size_px, -size_px) * 0.5, Vector2(size_px, size_px)), false, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func element_color(style: String) -> Color:
	match style:
		"fire": return ArtPalette.FX_FIRE
		"frost": return ArtPalette.FX_FROST
		"poison": return ArtPalette.FX_POISON
		"arcane": return ArtPalette.FX_ARCANE
		"sleep": return ArtPalette.FX_SLEEP
	return ArtPalette.FX_SPARK

func _draw_travel(fx: Dictionary, u: float) -> void:
	var from: Vector2 = fx.from
	var to: Vector2 = fx.to
	var delivery := String(fx.delivery)
	var color := element_color(String(fx.style))
	var span := float(TRAVEL_MSEC.get(delivery, 1))
	var total := float(fx.duration)
	var move_u := clampf(u * total / maxf(span, 1.0), 0.0, 1.0)
	var p := travel_point(from, to, move_u, delivery)
	var ahead := travel_point(from, to, minf(1.0, move_u + 0.05), delivery)
	var dir := (ahead - p).normalized() if ahead != p else (to - from).normalized()
	match delivery:
		"arrow":
			var tail := p - dir * 46.0
			draw_line(tail, p, ArtPalette.INK, 4.0)
			draw_line(tail, p, Color(0.55, 0.40, 0.22), 2.2)
			var side := Vector2(-dir.y, dir.x) * 5.0
			draw_colored_polygon(PackedVector2Array([p + dir * 6.0, p + side * 0.6, p - side * 0.6]), ArtPalette.STEEL)
			draw_colored_polygon(PackedVector2Array([tail, tail - dir * 9.0 + side, tail + dir * 3.0]), Color(0.86, 0.82, 0.74))
			draw_colored_polygon(PackedVector2Array([tail, tail - dir * 9.0 - side, tail + dir * 3.0]), Color(0.78, 0.74, 0.66))
		"thrown":
			var spin := move_u * TAU * 3.0
			var blade := Vector2.RIGHT.rotated(spin) * 16.0
			draw_line(p - blade, p + blade, ArtPalette.INK, 4.0)
			draw_line(p, p + blade, ArtPalette.STEEL, 2.4)
			draw_line(p - blade, p, Color(0.36, 0.24, 0.14), 2.4)
		"sling":
			draw_circle(p, 7.0, ArtPalette.INK)
			draw_circle(p, 5.5, Color(0.52, 0.50, 0.46))
		"flask":
			var spin2 := move_u * TAU * 2.0
			draw_set_transform(p, spin2, Vector2.ONE)
			draw_rect(Rect2(-5, -8, 10, 13), ArtPalette.INK)
			draw_rect(Rect2(-4, -7, 8, 11), ArtPalette.FX_POISON.darkened(0.25))
			draw_rect(Rect2(-2, -11, 4, 4), Color(0.45, 0.32, 0.20))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bolt":
			for k in 5:
				var back := travel_point(from, to, maxf(0.0, move_u - 0.04 * k), delivery)
				_sprite("fire_01", back, 34.0 - k * 5.0, Color(color, 0.8 - k * 0.14), move_u * 5.0 + k)
			_sprite("light_01", p, 50.0, Color(ArtPalette.FX_FIRE_CORE, 0.8))
			_sprite("flame_03", p, 30.0, Color(ArtPalette.FX_FIRE_CORE, 0.9), dir.angle() + PI * 0.5)
		"missiles":
			for k in 3:
				var off := float(k - 1) * 22.0
				var wave := Vector2(0.0, sin(move_u * PI * 2.0 + k * 2.1) * 18.0 * (1.0 - move_u) + off * (1.0 - move_u))
				var q := travel_point(from, to, clampf(move_u * (1.0 + k * 0.08), 0.0, 1.0), delivery) + wave
				for t in 4:
					var trail := q - dir * float(t) * 7.0
					_sprite("light_02", trail, 28.0 - t * 4.0, Color(color, 0.7 - t * 0.15))
				_sprite("star_04", q, 30.0, Color(1, 1, 1, 0.95), move_u * 8.0)
		"ray":
			var reach := clampf(u * total / maxf(span, 1.0), 0.0, 1.0)
			var tip := from.lerp(to, reach)
			var fade := 1.0 - clampf((u * total - span) / float(RAY_HOLD_MSEC), 0.0, 1.0)
			for k in 6:
				_sprite("light_02", from.lerp(tip, (float(k) + 0.5) / 6.0), 40.0, Color(color, 0.45 * fade))
			draw_line(from, tip, Color(color, 0.35 * fade), 14.0)
			draw_line(from, tip, Color(color, 0.8 * fade), 6.0)
			draw_line(from, tip, Color(1, 1, 1, 0.9 * fade), 2.0)
			for k in 5:
				var q := from.lerp(tip, float(k + 1) / 6.0)
				_sprite("star_06", q + Vector2(0, sin(u * 20.0 + k) * 5.0), 16.0, Color(color, 0.8 * fade), u * 6.0 + k)
		"spray":
			for k in 6:
				var q := from.lerp(to, clampf(move_u - 0.07 * k, 0.0, 1.0))
				var spread := Vector2(0.0, (float(k % 3) - 1.0) * 14.0 * move_u)
				_sprite("smoke_05", q + spread, 26.0 + move_u * 36.0, Color(color, 0.55 * (1.0 - 0.12 * k)), k + move_u * 2.0)
		"cone":
			var length := from.distance_to(to) * move_u
			var axis := (to - from).normalized()
			for k in 9:
				var a := (float(k) / 8.0 - 0.5) * 0.7
				var ray := axis.rotated(a)
				var q := from + ray * length * (0.55 + 0.45 * fposmod(k * 0.37, 1.0))
				_sprite("flame_0%d" % (1 + k % 6), q, 26.0 + 20.0 * move_u, Color(ArtPalette.FX_FIRE, 0.8),
					ray.angle() + PI * 0.5)
			_sprite("light_01", from, 40.0, Color(ArtPalette.FX_FIRE_CORE, 0.7))

func _draw_impact(fx: Dictionary, u: float) -> void:
	var at: Vector2 = fx.at
	var style := String(fx.style)
	var dir := float(fx.get("dir", 1.0))
	var fade := 1.0 - u
	var grow := 0.6 + 0.6 * u
	match style:
		"pierce":
			_sprite("spark_06", at, 80.0 * grow, Color(ArtPalette.FX_SPARK, fade))
			_blood_spray(at, dir, u, 4)
		"slash":
			_sprite("slash_02", at, 92.0, Color(1, 1, 1, 0.9 * fade), -0.6 * dir)
			_sprite("slash_02", at + Vector2(4, 2), 86.0, Color(ArtPalette.FX_BLOOD, 0.7 * fade), -0.6 * dir)
			_blood_spray(at, dir, u, 7)
		"blunt":
			_sprite("circle_02", at, 70.0 * grow, Color(ArtPalette.FX_SPARK, 0.8 * fade))
			_sprite("dirt_01", at + Vector2(0, 10), 48.0 * grow, Color(ArtPalette.FX_SMOKE, 0.6 * fade), u)
		"fire":
			_sprite("fire_02", at, 90.0 * grow, Color(ArtPalette.FX_FIRE, fade))
			_sprite("light_01", at, 110.0 * grow, Color(ArtPalette.FX_FIRE_CORE, 0.6 * fade))
			for k in 6:
				var a := TAU * float(k) / 6.0
				_sprite("spark_05", at + Vector2.RIGHT.rotated(a) * 50.0 * u, 18.0, Color(ArtPalette.FX_FIRE_CORE, fade))
		"frost":
			_sprite("light_03", at, 90.0 * grow, Color(ArtPalette.FX_FROST, 0.7 * fade))
			for k in 7:
				var a := TAU * float(k) / 7.0 + 0.3
				_sprite("star_06", at + Vector2.RIGHT.rotated(a) * 46.0 * u, 22.0, Color(ArtPalette.FX_FROST, fade), a)
		"poison":
			for k in 4:
				var a := TAU * float(k) / 4.0
				_sprite("smoke_07", at + Vector2.RIGHT.rotated(a) * 22.0 * u, 60.0 * grow, Color(ArtPalette.FX_POISON, 0.6 * fade), a + u)
		"arcane":
			_sprite("magic_03", at, 100.0 * grow, Color(ArtPalette.FX_ARCANE, fade), u * 3.0)
			_sprite("star_04", at, 50.0, Color(1, 1, 1, fade))
		"sleep":
			_sprite("twirl_02", at, 80.0 * grow, Color(ArtPalette.FX_SLEEP, fade), u * 4.0)
			_sprite("twirl_01", at - Vector2(0, 30), 50.0 * grow, Color(ArtPalette.FX_SLEEP, 0.7 * fade), -u * 4.0)

func _blood_spray(at: Vector2, dir: float, u: float, count: int) -> void:
	for k in count:
		var a := deg_to_rad(-60.0 + 120.0 * float(k) / float(maxi(1, count - 1)))
		var v := Vector2(dir * cos(a), sin(a) - 0.6) * (40.0 + 12.0 * float(k % 3))
		var q := at + v * u + Vector2(0.0, 60.0 * u * u)
		draw_circle(q, 3.5 * (1.0 - u * 0.5), Color(ArtPalette.FX_BLOOD, 1.0 - u))

func _draw_aura(fx: Dictionary, u: float) -> void:
	var at: Vector2 = fx.at
	var color := element_color(String(fx.style))
	_sprite("circle_05", at, 140.0 * (0.7 + 0.4 * u), Color(color, 0.8 * (1.0 - u)))
	_sprite("magic_04", at, 120.0, Color(color, 0.6 * (1.0 - u)), u * 2.0)

func _draw_whoosh(fx: Dictionary, u: float) -> void:
	var at: Vector2 = fx.at
	var dir := float(fx.get("dir", 1.0))
	_sprite("trace_03", at + Vector2(dir * 30.0 * u, -10.0), 70.0, Color(1, 1, 1, 0.6 * (1.0 - u)), PI * 0.5)
