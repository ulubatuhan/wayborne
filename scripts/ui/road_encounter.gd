class_name RoadEncounter
extends Control

## Yaklaşan bir günün olayının yoldaki önizlemesi - kart hiç açılmadan önce
## "önümüzde bir şey var" izlenimi verir. `CombatFigure`'ı olduğu gibi
## kullanıyor: savaşta gördüğün kurdu/muhafızı yolda da aynı fırça çiziyor
## (bkz. Art Rules, "paletler savaşla paylaşılıyor" - `WalkFigure`'ın
## `CombatFigure.ARCHETYPES`'ı okumasıyla aynı gerekçe), yani bu dosya
## kendi silüetini icat etmiyor.
##
## Tamamen dekoratif: hiçbir mekaniği tetiklemiyor ve fare olaylarını
## yutmuyor. `road_journey.gd` kervan yeterince yaklaşınca bu düğümü
## kaldırıp kartı kendisi açıyor (bkz. Road Encounter Rules, CLAUDE.md).

const FIGURE_HEIGHT: float = TravelBand.BAND_HEIGHT * 0.26
const FIGURE_WIDTH: float = FIGURE_HEIGHT * 0.65

var _figure: CombatFigure

## `_ready()` değil `_init()`: `road_journey.gd` `setup()`'ı bu düğüm henüz
## ağaca eklenmeden (`add_actor_layer()`'dan önce) çağırıyor, ve `_ready()`
## yalnızca ağaca girince çalışır. `_figure` `_ready()`'ye bırakılsaydı
## `setup()` onu `null` üzerinde çağırıp "Nonexistent function" hatası
## verirdi - sessizce değil, ama yine de her seferinde.
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(FIGURE_WIDTH, FIGURE_HEIGHT)
	_figure = CombatFigure.new()
	_figure.size = size
	_figure.custom_minimum_size = size
	add_child(_figure)

## `kind` bir `CombatFigure.ARCHETYPES` anahtarı (wolf/bandit/guard/clerk/...).
## Tanınmayan bir anahtar `CombatFigure`'ın kendi düşüşüyle (FALLBACK_KIND)
## haydut silüetine iner - burada da çizimsiz kalan bir tür olmuyor.
func setup(kind: String) -> void:
	# Kervan sağa yürür, dünya sola akar: işaret gelen kervana baksın diye
	# sola bakıyor - CombatFigure'ın "oyuncu sağa, düşman sola" kuralının
	# aynısı (bkz. combat_figure.gd).
	_figure.setup(kind, false, "normal", 0.0)

## Ayaklarının bastığı nokta `target`'a otursun diye - `CombatFigure` kendi
## kutusunun tabanına çiziyor (ground ≈ %95.5), kutunun sol üstüne değil.
func set_screen_position(target: Vector2) -> void:
	position = target - Vector2(size.x * 0.5, size.y)
