class_name WaybookPanel
extends CanvasLayer

## Kervanın defteri, açık hâliyle: kuruluştan bugüne her satır, kuşak kuşak.
## `CaravanLedger` hiçbir satırı silmiyor (bkz. Lineage Rules) ama bugüne
## kadar yalnızca son birkaç satırı gösteren dar dökümlerde görünüyordu
## (`CaravanStatusPanel`, şehir brifinginin son hatırası). Burada kitabın
## kendisi var: sol sayfada bütün satırlar - ölen ve ayrılanın adı mürekkeple
## çizili (`StruckLine`) - her kuşağın başında bir kurdele; sağ sayfada adı
## bugün kimin taşıdığı ve kaç kişinin geride kaldığı.
##
## Karar vermiyor, yalnızca okuyor (`CaravanStatusPanel`'in kuralı). Sahnesiz
## bir `CanvasLayer` (`OnboardingPanel` deseni): yoldan ve şehirden aynı
## örnek açılıyor, `Nav` yığınına hiç dokunmuyor. Kapat düğmesi kaydırma
## kutusunun dışında (World Navigation Rules); perde ve Esc de kapatıyor.

signal dismissed

const BOOK_FILE: String = "l1_ledger.jpg"
const RIBBON_FILE: String = "l2_ribbon.png"
const BOOK_VIEW_RATIO: float = 0.94
## Sayfa bölgeleri l1_ledger.jpg üstünde ölçüldü. Sağ sayfanın solundan
## ipek bir şerit sarkıyor; yazı onun sağında başlıyor.
const LEFT_PAGE: Rect2 = Rect2(0.115, 0.11, 0.35, 0.77)
const RIGHT_PAGE: Rect2 = Rect2(0.645, 0.11, 0.245, 0.77)
const RIBBON_HEIGHT: float = 34.0
const ENTRY_FONT_SIZE: int = 19

var _session: GameSession
var _book: TextureRect
var _left: ScrollContainer
var _right: VBoxContainer
var _root: Control
var _backdrop: ColorRect
var _dismissing: bool = false

func setup(session: GameSession) -> WaybookPanel:
	_session = session
	return self

func _ready() -> void:
	layer = 55
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	_root = root

	var backdrop := ColorRect.new()
	backdrop.color = ArtPalette.UI_BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(_on_backdrop_input)
	root.add_child(backdrop)
	_backdrop = backdrop

	_book = TextureRect.new()
	_book.texture = WaybookTheme.texture(BOOK_FILE)
	_book.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_book.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(_book)

	_left = ScrollContainer.new()
	_left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_book.add_child(_left)
	var entries := VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation", 4)
	_left.add_child(entries)
	_fill_entries(entries)

	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 8)
	_book.add_child(_right)
	_fill_summary(_right)

	root.resized.connect(_layout)
	_layout()
	WaybookTheme.present(_book, _backdrop, self)

func _layout() -> void:
	var view := _book.get_viewport_rect().size
	var tex := _book.texture.get_size()
	var scale := minf(view.x * BOOK_VIEW_RATIO / tex.x, view.y * BOOK_VIEW_RATIO / tex.y)
	_book.size = tex * scale
	_book.position = (view - _book.size) * 0.5
	for pair in [[_left, LEFT_PAGE], [_right, RIGHT_PAGE]]:
		var control: Control = pair[0]
		var ratio: Rect2 = pair[1]
		control.position = ratio.position * _book.size
		control.size = ratio.size * _book.size

## Satırlar kronolojik: defter baştan okunur, kuruluştan bugüne. Her kuşak
## değişiminde bir kurdele - "N. kuşak" üstünde canlı metin.
func _fill_entries(box: VBoxContainer) -> void:
	var ledger := _session.ledger if _session != null else null
	if ledger == null or ledger.entries.is_empty():
		box.add_child(_page_label(tr("UI_WAYBOOK_EMPTY")))
		return
	var generation := -1
	for entry in ledger.entries:
		var entry_generation := int(entry.get("generation", 1))
		if entry_generation != generation:
			generation = entry_generation
			box.add_child(_ribbon(generation))
		var text := CaravanLedger.describe(entry)
		if ledger.is_struck(entry):
			var struck := StruckLine.new().setup(text, false).set_on_page(true)
			struck.label.add_theme_font_size_override("font_size", ENTRY_FONT_SIZE)
			box.add_child(struck)
		else:
			box.add_child(_page_label(text))

func _ribbon(generation: int) -> Control:
	var ribbon := WaybookTheme.picture(RIBBON_FILE, RIBBON_HEIGHT)
	ribbon.stretch_mode = TextureRect.STRETCH_SCALE
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	# Kurucunun satırı 0. kuşakta: adı oyuncudan önce taşıyan (bkz.
	# Lineage Rules'un "The ledger never starts empty" maddesi).
	label.text = tr("UI_WAYBOOK_FOUNDING") if generation <= 0 else tr("UI_WAYBOOK_GENERATION") % generation
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ribbon.add_child(label)
	return ribbon

func _fill_summary(box: VBoxContainer) -> void:
	var heading := _page_label(tr("UI_WAYBOOK_TITLE"))
	heading.theme_type_variation = WaybookTheme.PAGE_HEADING
	heading.add_theme_font_size_override("font_size", 26)
	box.add_child(heading)
	if _session != null:
		var name_label := _page_label(_session.caravan_name)
		name_label.add_theme_font_size_override("font_size", 22)
		box.add_child(name_label)
		box.add_child(_page_label(tr("UI_WAYBOOK_GENERATION") % _session.lineage_generation))
		var leader := _session.get_player_character()
		if leader != null:
			box.add_child(_page_label(tr("UI_WAYBOOK_LEADER") % leader.character_name))
		box.add_child(_page_label(tr("UI_WAYBOOK_DIED") % _session.ledger.count_of(CaravanLedger.KIND_DIED)))
		box.add_child(_page_label(tr("UI_WAYBOOK_DEPARTED") % _session.ledger.count_of(CaravanLedger.KIND_DEPARTED)))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var close := Button.new()
	close.text = tr("UI_WAYBOOK_CLOSE")
	close.pressed.connect(_close)
	box.add_child(close)

func _page_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = WaybookTheme.PAGE_LABEL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", ENTRY_FONT_SIZE)
	return label

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	if _dismissing:
		return
	_dismissing = true
	WaybookTheme.dismiss(_book, _backdrop, self, func():
		dismissed.emit()
		queue_free()
	)
