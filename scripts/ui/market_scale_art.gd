class_name MarketScaleArt
extends RefCounted

## tools/ui_scenes/market_scale_scene.py yazar, elle değiştirme. Resim pikseli, sol üstten.

const DIR: String = "res://data/assets/ui/market_scale/"
const PPU: float = 400.0
const COLUMN_PIVOT: Vector2 = Vector2(240.0, 160.0)
const COLUMN_FOOT: Vector2 = Vector2(240.0, 808.0)
const BEAM_PIVOT: Vector2 = Vector2(416.0, 152.0)
## Sol askı; sağ askı mile göre aynası.
const BEAM_LEFT_HOOK: Vector2 = Vector2(48.0, 168.0)
const PAN_HOOK: Vector2 = Vector2(172.0, 40.0)
## Kefenin içinde malın oturduğu yer (orta) ve yarıçapı (piksel).
const PAN_FLOOR: Vector2 = Vector2(172.0, 310.0)
const PAN_RADIUS: float = 118.1
