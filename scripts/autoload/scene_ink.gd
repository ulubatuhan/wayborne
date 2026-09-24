extends CanvasLayer

## Autoload: sahneler arası geçişin tek kapısı. Oyunun bütün gezinmesi
## `change_scene_to_file()` ve her biri ekranı tek karede kesiyordu - defterin
## bir sayfasından ötekine geçmek gibi değil, projektörün slaytı değiştirmesi
## gibi.
##
## İki yarısı var:
## - **Gidiş (`go`)**: eski ekranın son karesi bir resim olarak alınır, sahne
##   *hemen* değişir (yeni sahnenin `_ready`'si hiç gecikmez), sonra resim
##   canlandırılarak kaldırılır. Köke gidiş (yol, şehir, ana menü) mürekkebe
##   batar ve oradan belirir; yığında derine inmek sayfayı sola çevirir,
##   geri dönmek sağa. Hangisinin olacağını çağıran söylemez - `Nav`'ın son
##   hareketi zaten söylüyor (`transition_kind`), yani 45 çağrı yerinin
##   hiçbiri bir tür seçmek zorunda değil.
## - **Geliş**: bu kapıdan geçmeyen bir sahne değişikliği (açılış) eskisi
##   gibi mürekkepten belirir - katman `current_scene`'i kendisi izliyor.
##
## Varış anı daha uzun tutuluyor (`hold_next`): yoldan şehre girmek oyunun
## "vardık" dediği tek yer (bkz. Audio Rules'un crossfade gerekçesi).
##
## `class_name` anmıyor (autoload kuralı); palet ve Nav `load()` ile okunuyor.

const PALETTE_PATH: String = "res://scripts/ui/art_palette.gd"
const NAV_PATH: String = "res://scripts/world/nav.gd"
const SETTINGS_PATH: String = "res://scripts/autoload/user_settings.gd"
const FADE_SECONDS: float = 0.45
const DARKEN_SECONDS: float = 0.2
const SLIDE_SECONDS: float = 0.28
const LAYER: int = 120

enum Kind { FADE, SLIDE_IN, SLIDE_BACK }

var _ink: ColorRect
var _page: TextureRect
var _last_scene_id: int = 0
var _hold_seconds: float = 0.0
var _tween: Tween
## `go()` kendi geçişini yönetiyor; `_process` aynı değişikliği bir kez
## daha "açılış" sanıp üstüne mürekkep basmasın.
var _handled_change: bool = false

func _ready() -> void:
	layer = LAYER
	_page = TextureRect.new()
	_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.stretch_mode = TextureRect.STRETCH_SCALE
	_page.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_page.visible = false
	add_child(_page)
	_ink = ColorRect.new()
	_ink.color = load(PALETTE_PATH).INK
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.modulate.a = 0.0
	add_child(_ink)
	var scene := get_tree().current_scene
	_last_scene_id = scene.get_instance_id() if scene != null else 0

## Bir sonraki sahne mürekkepte bu kadar daha beklesin (şehre varış).
func hold_next(seconds: float) -> void:
	_hold_seconds = maxf(_hold_seconds, seconds)

## Geçişin türü Nav'ın son hareketinden: derine inmek sayfayı sola çevirir,
## geri dönmek sağa, köke gitmek mürekkebe batar. Saf fonksiyon - testler
## sahne ağacı olmadan okuyabilsin diye.
static func transition_kind(move: String, reduce_motion: bool = false) -> Kind:
	if reduce_motion:
		return Kind.FADE
	match move:
		"open":
			return Kind.SLIDE_IN
		"back":
			return Kind.SLIDE_BACK
	return Kind.FADE

## Sahne değiştirmenin tek yolu. `path` bir `Nav` çağrısının sonucu - yığın
## o çağrıda zaten güncellendi, son hareketin türü de onunla birlikte.
func go(path: String) -> void:
	var kind := transition_kind(String(load(NAV_PATH).last_move), _reduce_motion())
	var snapshot := _capture()
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		return
	_handled_change = true
	if snapshot == null:
		# Resim alınamadıysa (başsız sürücü) eski davranış: mürekkepten belir.
		_handled_change = false
		return
	_play(kind, snapshot)

func _reduce_motion() -> bool:
	var settings := get_node_or_null("/root/UserSettings")
	if settings == null:
		return false
	return bool(settings.get("reduce_motion"))

## Eski ekranın son karesi. Web'de bu bir GPU okuması (bir kerelik, geçiş
## anında, başka hiçbir şeyin canlanmadığı bir karede).
func _capture() -> ImageTexture:
	var viewport := get_viewport()
	if viewport == null or viewport.get_texture() == null:
		return null
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)

func _play(kind: Kind, snapshot: ImageTexture) -> void:
	_kill_tween()
	var screen := get_viewport().get_visible_rect().size
	# Çapa değil doğrudan boyut: CanvasLayer bir Control değil (bkz. Art
	# Rules'un çapa tuzağı).
	_page.texture = snapshot
	_page.size = screen
	_page.position = Vector2.ZERO
	_page.modulate = Color.WHITE
	_page.visible = true
	_ink.size = screen
	_ink.modulate.a = 0.0
	_tween = create_tween()
	match kind:
		Kind.SLIDE_IN, Kind.SLIDE_BACK:
			var target := -screen.x if kind == Kind.SLIDE_IN else screen.x
			_tween.tween_property(_page, "position:x", target, SLIDE_SECONDS) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			_tween.tween_callback(_hide_page)
		_:
			# Eski sayfa mürekkebe batar, yeni sayfa mürekkepten belirir.
			_tween.tween_property(_ink, "modulate:a", 1.0, DARKEN_SECONDS) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			_tween.tween_callback(_hide_page)
			if _hold_seconds > 0.0:
				_tween.tween_interval(_hold_seconds)
				_hold_seconds = 0.0
			_tween.tween_property(_ink, "modulate:a", 0.0, FADE_SECONDS) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _hide_page() -> void:
	_page.visible = false
	_page.texture = null

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_id := scene.get_instance_id() if scene != null else 0
	# change_scene_to_file eski sahneyi bir kare önce kaldırıyor: arada
	# `current_scene` null. O ara kare bir "geliş" değil - bayrak ancak yeni
	# sahne gerçekten gelince tüketiliyor, yoksa geliş go()'nun kendi
	# geçişini öldürüp üstüne mürekkep basıyordu (ölçüldü).
	if scene_id == _last_scene_id or scene_id == 0:
		return
	_last_scene_id = scene_id
	if _handled_change:
		_handled_change = false
		return
	_reveal()

func _reveal() -> void:
	_kill_tween()
	_ink.size = get_viewport().get_visible_rect().size
	_ink.modulate.a = 1.0
	_tween = create_tween()
	if _hold_seconds > 0.0:
		_tween.tween_interval(_hold_seconds)
		_hold_seconds = 0.0
	_tween.tween_property(_ink, "modulate:a", 0.0, FADE_SECONDS)
