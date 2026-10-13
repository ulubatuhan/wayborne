class_name PropSheet
extends Resource

## `tools/figure_pipeline/props/pack_props.py`'nin yazdığı eşya dizini:
## id -> {ppm, view, layers: {katman: [sol, üst]}, pivots: {ad: [x, y]},
## size_m}. Bütün konumlar render pikselinde ve eşyanın yere bastığı orta
## noktaya göre. .json değil, çünkü Web ihracı yalnız kaynakları taşıyor
## (BeastSkin'in aynı sebebi).
@export var props: Dictionary = {}
