class_name NodeUtil
extends RefCounted

## Bir kabın bütün çocuklarını hemen ayırıp serbest bırakır. Sekiz ekranda
## birebir aynı `_clear_children` vardı. `remove_child` önce gelir: `queue_free`
## kareyi bekler, o ana kadar eski çocuklar yeni içerikle yan yana durup
## kabın boyutunu şişirir.
static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
