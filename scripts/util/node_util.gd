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

## Perdeli kart (modal panel iskeleti): tam ekran bir kök, altında perde,
## ortasında sabit genişlikte bir kart. Dokuz panel bu on üç satırı birebir
## kopyalıyordu (CampActionsPanel, CampStoryPanel, DiaryPanel,
## InheritancePanel, InGameMenu, CaravanCargoPanel, CaravanOverviewPanel,
## MealDistributionPanel, WagonPanel). Kopyanın bedeli görünmezdi ama
## gerçekti: kökün `MOUSE_FILTER_STOP` olması altındaki ekranın tıklama
## almamasını, ortalayıcının `IGNORE` olması da kartın dışındaki perdenin
## tıklanabilir kalmasını sağlıyor - birini atlayan panel ya arkasına tıklatır
## ya da perdeyi sağırlaştırır, ikisi de yalnızca elle fark edilir.
##
## Dönen: {"root": Control, "backdrop": ColorRect, "card": PanelContainer}.
static func modal_card(host: CanvasLayer, backdrop_color: Color, card_width: float) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = backdrop_color
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(card_width, 0.0)
	center.add_child(card)
	return {"root": root, "backdrop": backdrop, "card": card}

## Satır içi panelin başlığı: bir başlık, bir açıklama. `PurificationPanel` ve
## `RecruitPanel` bu on satırı birebir kopyalıyordu; ikisi de aynı ekranda
## yan yana durduğu için punto ya da renk birinde değişince fark ediliyordu.
## Dönen: {"title": Label, "info": Label}.
static func panel_header(host: Control, hint_color: Color, separation: int = 6, title_size: int = 18) -> Dictionary:
	host.add_theme_constant_override("separation", separation)

	var title := Label.new()
	title.add_theme_font_size_override("font_size", title_size)
	host.add_child(title)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.modulate = hint_color
	host.add_child(info)
	return {"title": title, "info": info}
