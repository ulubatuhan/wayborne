class_name CardDrift
extends RefCounted

## Olay kartının resmi açılırken yavaşça yaklaşır ve kayar (görev Y-G21).
## Resim kendi kırpılmış çerçevesinin içinde büyür; `scale` ve `pivot_offset`
## ile, çünkü çerçeve resmin konumunu çapalarla yönetiyor (Art Rules: çapayla
## doğrudan konum yazımı karıştırılmaz). Hareket durgundan başlar ve hızı
## sıfıra inerek biter (Motion Rules); Reduce Motion açıkken hiç oynamaz.

const SECONDS: float = 4.5
const ZOOM: float = 0.06
## Yaklaşmanın odağı resmin bu payında başlar ve şuraya kayar.
const PIVOT_FROM: float = 0.38
const PIVOT_TO: float = 0.62

## Saf eğri: u = 0..1 süre payı. Yumuşak çıkış (hız sonda sıfır).
static func eased(u: float) -> float:
	var v := clampf(u, 0.0, 1.0)
	return 1.0 - pow(1.0 - v, 3.0)

static func scale_at(u: float) -> float:
	return 1.0 + ZOOM * eased(u)

static func pivot_share_at(u: float) -> float:
	return lerpf(PIVOT_FROM, PIVOT_TO, eased(u))

## Kırpılmış çerçevenin içindeki resme uygular.
static func attach(picture: Control, reduce_motion: bool) -> void:
	if reduce_motion:
		return
	var tween := picture.create_tween()
	tween.tween_method(func(u: float) -> void:
		picture.pivot_offset = Vector2(picture.size.x * pivot_share_at(u), picture.size.y * 0.5)
		var s := scale_at(u)
		picture.scale = Vector2(s, s), 0.0, 1.0, SECONDS)
