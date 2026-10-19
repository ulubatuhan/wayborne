class_name NodeUtil
extends RefCounted

## Bir kabın bütün çocuklarını hemen ayırıp serbest bırakır. Sekiz ekranda
## birebir aynı `_clear_children` vardı. `remove_child` önce gelir: `queue_free`
## kareyi bekler, o ana kadar eski çocuklar yeni içerikle yan yana durup
## kabın boyutunu şişirir.
## Oyuncu "Hareketi azalt"ı açtı mı (UserSettings). Dört ekranda aynı
## satırlar vardı (görev 4.3). İki kopya bilerek yerinde: SceneInk otomatik
## yükleniyor, ButtonFeedback'i de otomatik yüklenen UiTheme kuruyor; ikisi
## bir `class_name`'e başvuramaz (CLAUDE.md, autoload kuralı).
static func reduce_motion(context: Node) -> bool:
	if context == null or not context.is_inside_tree():
		return false
	var settings := context.get_node_or_null("/root/UserSettings")
	return settings != null and bool(settings.get("reduce_motion"))

## Ortam animasyonlarının (kül, duman, fener, sıvı göstergesi) çizim temposu:
## görünmeyen bir düğüm çizilmez, görünen en çok saniyede bu kadar çizilir.
## Zamanı çağıran yürütür; burası yalnızca "şimdi çiz mi" der (görev 5.1, O-8).
const AMBIENT_REDRAW_HZ: float = 30.0

## `wait` bir önceki çizimden beri geçen süre; dönen değer yeni `wait`.
static func ambient_redraw(item: CanvasItem, wait: float, delta: float) -> float:
	if not item.is_visible_in_tree():
		return wait
	wait += delta
	if wait < 1.0 / AMBIENT_REDRAW_HZ:
		return wait
	item.queue_redraw()
	return 0.0

static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
