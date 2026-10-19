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

static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
