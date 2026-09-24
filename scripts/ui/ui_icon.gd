class_name UiIcon
extends Control

## Arayüzün küçük işaretleri, tek yerden çizilir.
##
## **Bir şekli fonttan dilenmek yanlış kapıydı.** Mevki belirteçleri
## (`●○`), parti sıralama tuşları (`↑↓`), hedef tiki (`✓`) ve yol
## ayırıcıları hep Unicode karakterdi; Godot'un varsayılan fontu
## Geometric Shapes ve Arrows bloklarını taşımadığı için hepsi ekranda
## boş kutu olarak çıkıyordu. Bir playtest yalnızca savaş ekranındakini
## fotoğrafladı, ama aynı hata on iki oyuncu-yüzlü yerdeydi ve hiçbir
## test göremezdi: metin *doğru*ydu, yalnızca çizilemiyordu.
##
## Oyunun zaten tek bir çizim dili var (bkz. `ArtDraw`) ve her şeyi
## `_draw()` ile çiziyor. Bu bileşen o dili arayüze getiriyor: aynı şekil
## iki yerde iki farklı şey olmasın (`ArtDraw.wagon()`'un var olma
## gerekçesiyle aynı), boyut ve renk çağıranın olsun.
##
## Sahnesiz, `PulseBar` gibi: `.new()` + `setup()`.

enum Kind {
	PIPS,       ## bir dizi dolu/boş nokta - savaşın mevki belirteci
	CHEVRON_UP,
	CHEVRON_DOWN,
	CHEVRON_LEFT,
	CHEVRON_RIGHT,
	CHECK,
}

const DEFAULT_SIZE: float = 12.0
const PIP_SPACING: float = 1.6

var _kind: int = Kind.CHECK
var _color: Color = Color.WHITE
var _glyph_size: float = DEFAULT_SIZE

## PIPS için: kaç nokta ve hangileri dolu.
var _pip_count: int = 0
var _pip_filled: Array[int] = []

func setup(kind: int, color: Color, glyph_size: float = DEFAULT_SIZE) -> void:
	_kind = kind
	_color = color
	_glyph_size = glyph_size
	_apply_minimum_size()
	queue_redraw()

## `filled` 1'den başlayan sıra numaraları taşır (mevki numarasıyla aynı
## dil), dizi indisi değil - savaş motoru da mevkileri öyle konuşuyor.
func setup_pips(count: int, filled: Array[int], color: Color, glyph_size: float = DEFAULT_SIZE) -> void:
	_kind = Kind.PIPS
	_pip_count = maxi(0, count)
	_pip_filled = filled
	_color = color
	_glyph_size = glyph_size
	_apply_minimum_size()
	queue_redraw()

## Ebeveyninin çerçevesini benimser - bir `Button`'ın içine yerleşmenin
## tek güvenli yolu. `PRESET_FULL_RECT` **yetmiyor**: anchor preset boyu
## yalnızca ebeveyn *yeniden boyutlandığında* aktarıyor, ebeveyn zaten
## boyutlanmışken eklenen çocuk o bildirimi hiç almıyor ve (0,0)'da
## kalıyor. Bu proje o tuzağa üç kez düştü (bkz. CLAUDE.md Art Rules);
## burada hem mevcut boy alınıyor hem sonraki değişiklikler dinleniyor.
##
## `add_child`'dan **sonra** çağrılmalı.
func fill_parent() -> void:
	var parent := get_parent() as Control
	if parent == null:
		return
	if not parent.resized.is_connected(_adopt_parent_size):
		parent.resized.connect(_adopt_parent_size)
	_adopt_parent_size()

func _adopt_parent_size() -> void:
	var parent := get_parent() as Control
	if parent == null:
		return
	position = Vector2.ZERO
	size = parent.size
	queue_redraw()

func _apply_minimum_size() -> void:
	# Kendi yerini istemesi gerekiyor: bir `Control`'ün asgari boyu yoksa
	# `HBoxContainer` onu sıfıra sıkıştırır ve çizim görünmez olur.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _kind == Kind.PIPS:
		var step := _glyph_size + PIP_SPACING
		custom_minimum_size = Vector2(step * float(maxi(1, _pip_count)), _glyph_size)
	else:
		custom_minimum_size = Vector2(_glyph_size, _glyph_size)

func _draw() -> void:
	var centre := size * 0.5
	match _kind:
		Kind.PIPS:
			_draw_pips()
		Kind.CHEVRON_UP:
			ArtDraw.chevron(self, centre, _glyph_size * 0.7, _color, -1)
		Kind.CHEVRON_DOWN:
			ArtDraw.chevron(self, centre, _glyph_size * 0.7, _color, 1)
		Kind.CHEVRON_LEFT:
			ArtDraw.chevron(self, centre, _glyph_size * 0.7, _color, -1, true)
		Kind.CHEVRON_RIGHT:
			ArtDraw.chevron(self, centre, _glyph_size * 0.7, _color, 1, true)
		Kind.CHECK:
			ArtDraw.check(self, centre, _glyph_size * 0.8, _color)

func _draw_pips() -> void:
	var radius := _glyph_size * 0.3
	var step := _glyph_size + PIP_SPACING
	for index in _pip_count:
		var centre := Vector2(step * (float(index) + 0.5), size.y * 0.5)
		ArtDraw.pip(self, centre, radius, _color, _pip_filled.has(index + 1))
