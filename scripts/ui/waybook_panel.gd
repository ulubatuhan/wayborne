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
## İkinci açılım "Düşenler" (görev 9.11, onaylı taslak y_911_dusenler): solda
## kurucu ve ölenler, adın yanında rütbesine göre süslenmiş bir mezar işareti
## (`GraveMark`) ve altında rolü, sebebi, yeri; sağda hikâye satırları - ateş
## başında anlatılanlar ve yolun anıtları.
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
## Sağ sayfanın altından ip ve etiket geçiyor: düğmeler onun üstünde, dar
## ve sola yaslı duruyor (9.11 denetimi: ip düğmelerin üstünden geçiyordu).
const RIGHT_PAGE: Rect2 = Rect2(0.645, 0.11, 0.245, 0.70)
const BUTTON_WIDTH: float = 230.0
const RIBBON_HEIGHT: float = 34.0
const ENTRY_FONT_SIZE: int = 19
const FALLEN_NAME_SIZE: int = 23
const FALLEN_DETAIL_SIZE: int = 18
const GRAVE_MARK_HEIGHT: float = 64.0

var _session: GameSession
var _book: TextureRect
var _left: ScrollContainer
var _right: VBoxContainer
var _root: Control
var _backdrop: ColorRect
var _dismissing: bool = false
var _entries: VBoxContainer
var _share: Button
var _close_button: Button
var _share_note: Label
var _summary: VBoxContainer
var _fallen_toggle: Button
var _showing_fallen: bool = false

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
	_entries = entries
	_fill_entries(entries)

	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 8)
	_book.add_child(_right)
	_fill_summary(_right)

	root.resized.connect(_layout)
	_layout()
	WaybookTheme.present(_book, _backdrop, self)
	AudioManager.play_sfx(AudioManager.SFX_UI_BOOK_OPEN)

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
		var text := ledger_text(entry)
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
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	_summary = VBoxContainer.new()
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.add_theme_constant_override("separation", 8)
	scroll.add_child(_summary)
	_fill_overview(_summary)
	# Paylaşılabilir sayfa (Y-E07): sol sayfa soyun özetine döner, kitap PNG
	# olarak kaydedilir, sonra defter geri gelir.
	_share_note = _page_label("")
	_share_note.visible = false
	box.add_child(_share_note)
	_fallen_toggle = Button.new()
	_fallen_toggle.text = tr("UI_WAYBOOK_FALLEN_OPEN")
	_fallen_toggle.disabled = _session == null
	_fallen_toggle.pressed.connect(_toggle_fallen)
	box.add_child(_fallen_toggle)
	_fallen_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_fallen_toggle.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	_share = Button.new()
	_share.text = tr("UI_WAYBOOK_SHARE")
	_share.disabled = _session == null
	_share.pressed.connect(_on_share_pressed)
	box.add_child(_share)
	_share.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_share.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	var close := Button.new()
	close.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	close.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	close.text = tr("UI_WAYBOOK_CLOSE")
	close.pressed.connect(_close)
	box.add_child(close)
	_close_button = close

func _fill_overview(box: VBoxContainer) -> void:
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

## Defter ile Düşenler arasında: iki sayfa birlikte döner.
func _toggle_fallen() -> void:
	set_fallen_page(not _showing_fallen)

func set_fallen_page(fallen: bool) -> void:
	if fallen != _showing_fallen:
		AudioManager.play_sfx(AudioManager.SFX_UI_PAGE)
	_showing_fallen = fallen
	for box in [_entries, _summary]:
		for child in (box as Node).get_children():
			child.queue_free()
	if fallen:
		_fill_fallen(_entries)
		_fill_stories(_summary)
	else:
		_fill_entries(_entries)
		_fill_overview(_summary)
	_fallen_toggle.text = tr("UI_WAYBOOK_FALLEN_CLOSE") if fallen else tr("UI_WAYBOOK_FALLEN_OPEN")
	# Paylaşılan sayfa soyun özeti; Düşenler açıkken düğme yok.
	_share.visible = not fallen
	_share_note.visible = false

func _fill_fallen(box: VBoxContainer) -> void:
	box.add_child(_page_heading(tr("UI_WAYBOOK_FALLEN_TITLE")))
	var fallen: Array[Dictionary] = _session.ledger.fallen() if _session != null else []
	if fallen.is_empty():
		box.add_child(_page_label(tr("UI_WAYBOOK_FALLEN_EMPTY")))
		return
	var leaders := _session.ledger.leader_generations()
	for entry in fallen:
		box.add_child(_fallen_row(entry, leaders))

func _fallen_row(entry: Dictionary, leaders: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var rank := GraveMark.rank_for(entry, leaders)
	var mark := GraveMark.new().setup(rank, GRAVE_MARK_HEIGHT)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	row.add_child(text)
	var name_line := StruckLine.new().setup(String(entry.get("name", "")), false).set_on_page(true)
	name_line.label.add_theme_font_size_override("font_size", FALLEN_NAME_SIZE)
	text.add_child(name_line)
	var detail := _page_label(_fallen_detail(entry, rank, leaders))
	detail.add_theme_font_size_override("font_size", FALLEN_DETAIL_SIZE)
	text.add_child(detail)
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.add_child(row)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 22)
	wrap.add_child(gap)
	return wrap

## "rol · sebep, yer (gün N)": rol rütbeden, sebep defterin kendi satırından.
func _fallen_detail(entry: Dictionary, rank: int, leaders: Dictionary) -> String:
	var role := ""
	match rank:
		GraveMark.Rank.FOUNDER:
			role = tr("UI_FALLEN_ROLE_FOUNDER")
		GraveMark.Rank.LEADER:
			var id := String(entry.get("id", ""))
			var key := id if not id.is_empty() else "name:" + String(entry.get("name", ""))
			role = tr("UI_FALLEN_ROLE_LEADER") % int(leaders.get(key, 1))
		GraveMark.Rank.COMPANION:
			var character_class := ClassCatalog.get_character_class(String(entry.get("role", "")))
			role = character_class.display_name if character_class != null else tr("UI_FALLEN_ROLE_COMPANION")
		_:
			role = tr("UI_FALLEN_ROLE_CREW")
	var cause := CaravanLedger.describe_cause(entry)
	return role if cause.is_empty() else tr("UI_FALLEN_DETAIL") % [role, cause]

func _fill_stories(box: VBoxContainer) -> void:
	box.add_child(_page_heading(tr("UI_WAYBOOK_STORIES_TITLE")))
	var lines: Array[Dictionary] = _session.ledger.story_lines() if _session != null else []
	if lines.is_empty():
		box.add_child(_page_label(tr("UI_WAYBOOK_STORIES_EMPTY")))
		return
	for entry in lines:
		var line := _page_label(story_text(entry))
		box.add_child(line)

## Hikâye satırı: anlatılan bölümün kısa özeti ("Gün 12: Selin ... anlattı");
## özeti olmayan satır (anıt, karar) defterin kendi biçimiyle.
static func story_text(entry: Dictionary) -> String:
	var summary := _story_summary(entry)
	if summary.is_empty():
		return CaravanLedger.describe(entry)
	return String(TranslationServer.translate("UI_WAYBOOK_STORY_LINE")) % [int(entry.get("day", 0)), summary]

## Defterin kendi satırı; ateş başı hikâyesi tam paragraf değil, kısa özetiyle.
static func ledger_text(entry: Dictionary) -> String:
	var summary := _story_summary(entry)
	if summary.is_empty():
		return CaravanLedger.describe(entry)
	return String(TranslationServer.translate("LEDGER_CAUSE_DAY")) % [summary, int(entry.get("day", 0))]

static func _story_summary(entry: Dictionary) -> String:
	# Günün satırı (Y-B08) zaten kısa bir cümle.
	if String(entry.get("kind", "")) == CaravanLedger.KIND_DIARY:
		return CaravanLedger.diary_text(entry)
	var cause := String(entry.get("cause", ""))
	var summary_key := cause + "_LINE"
	if String(entry.get("kind", "")) != CaravanLedger.KIND_STORY or cause.is_empty() \
			or String(TranslationServer.translate(summary_key)) == summary_key:
		return ""
	return String(TranslationServer.translate(summary_key)) % String(entry.get("name", ""))

func _page_heading(text: String) -> Label:
	var heading := _page_label(text)
	heading.theme_type_variation = WaybookTheme.PAGE_HEADING
	heading.add_theme_font_size_override("font_size", 30)
	return heading

func _on_share_pressed() -> void:
	if _showing_fallen:
		return
	_share.disabled = true
	_fallen_toggle.visible = false
	for child in _entries.get_children():
		child.queue_free()
	for line in LedgerPage.lines(_session):
		_entries.add_child(_page_label(line))
	_share.visible = false
	_close_button.visible = false
	_share_note.visible = false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := _save_book_image()
	for child in _entries.get_children():
		child.queue_free()
	_fill_entries(_entries)
	_share.visible = true
	_fallen_toggle.visible = true
	_close_button.visible = true
	_share.disabled = false
	_share_note.visible = true
	_share_note.text = tr("UI_WAYBOOK_SHARED") % ProjectSettings.globalize_path(path) if not path.is_empty() else tr("UI_WAYBOOK_SHARE_FAILED")

## Kitabın ekrandaki dikdörtgeni PNG olarak; görüntü alanı ölçeklenmişse
## pencere pikseline çevrilir.
func _save_book_image() -> String:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		return ""
	var view := get_viewport().get_visible_rect().size
	var factor := Vector2(image.get_size()) / view
	var rect := Rect2i(Vector2i(_book.global_position * factor), Vector2i(_book.size * factor))
	rect = rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if rect.size.x <= 0 or rect.size.y <= 0:
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LedgerPage.DIR))
	var path := LedgerPage.file_path(_session)
	return path if image.get_region(rect).save_png(path) == OK else ""

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
	AudioManager.play_sfx(AudioManager.SFX_UI_BOOK_CLOSE)
	WaybookTheme.dismiss(_book, _backdrop, self, func():
		dismissed.emit()
		queue_free()
	)
