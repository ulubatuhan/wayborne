class_name MerchantDialoguePanel
extends CanvasLayer

## Kervana kabul edilmiş (eskort) bir tüccarla yolda açılan sohbet - bkz.
## CLAUDE.md Ana Hedefler'in "#11" notu. F2 emir menüsünün "Tüccarla
## Konuş" komutuyla açılıyor (bkz. road_journey.gd).
##
## Birden çok tüccar eskort edilebildiği için önce bir liste gösteriliyor;
## birine "Konuş" demek o tüccarın kendi görünümüne geçiyor. İzin isteme
## adımı otomatik: görünüme geçildiği an mizaca göre ya izin verilir ya
## reddedilir (bkz. GameSession.merchant_grants_permission). Reddedilirse
## üç yol açılır - Zorla Bak / Tekrar İkna Et / Vazgeç - tıpkı kullanıcının
## kendi tarifiyle: "izin verirse görüntüleriz, izin vermezse zor
## kullanarak bakabilir, tekrar ikna etmeye çalışabilir ya da vazgeçebiliriz."
##
## Ödül bilgi: mizaç (Sezgi eşiğiyle okunabildiği kadarıyla, bkz.
## GameSession.get_merchant_disposition_label) **ve** vagonun gerçek yükü
## (bkz. GameSession.get_merchant_cargo_entries, CaravanState.
## merchant_cargo_by_name) - #22'nin orijinal notu "gerçek bir cargo
## modeli" istiyordu, tek başına mizaç etiketi onu karşılamıyordu.
## `WagonPanel`'in aksine burada yazılabilecek bir envanter yok: bu
## `Inventory` hiçbir zaman `GameSession.wagon_inventories`'e girmez, salt
## okuma bile ekonomiye sızmıyor.

signal closed

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.6)
const PANEL_BACKGROUND: Color = Color(0.09, 0.08, 0.07)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.28)
const PANEL_WIDTH: float = 480.0
const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const OK_COLOR: Color = Color(0.55, 0.80, 0.55)
const REFUSED_COLOR: Color = Color(0.90, 0.55, 0.45)

var _session: GameSession
var _rng: RandomNumberGenerator
var _list_body: VBoxContainer
var _detail_body: VBoxContainer
var _list_holder: Control
var _detail_holder: Control
var _selected_merchant: String = ""

func setup(session: GameSession, rng: RandomNumberGenerator = null) -> void:
	_session = session
	_rng = rng if rng != null else RandomNumberGenerator.new()
	layer = 65

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var backdrop := ColorRect.new()
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BACKGROUND
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_MERCHANT_DIALOGUE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	_list_holder = VBoxContainer.new()
	_list_body = VBoxContainer.new()
	_list_body.add_theme_constant_override("separation", 6)
	_list_holder.add_child(_list_body)
	vbox.add_child(_list_holder)

	_detail_holder = VBoxContainer.new()
	_detail_body = VBoxContainer.new()
	_detail_body.add_theme_constant_override("separation", 8)
	_detail_holder.add_child(_detail_body)
	vbox.add_child(_detail_holder)

	vbox.add_child(HSeparator.new())

	var close_button := Button.new()
	close_button.text = tr("UI_CRAFT_CLOSE")
	close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(close_button)

	_refresh()

func _refresh() -> void:
	if _selected_merchant.is_empty():
		_list_holder.visible = true
		_detail_holder.visible = false
		_refresh_list()
	else:
		_list_holder.visible = false
		_detail_holder.visible = true
		_refresh_detail()

func _refresh_list() -> void:
	for child in _list_body.get_children():
		_list_body.remove_child(child)
		child.queue_free()

	var names := _session.caravan.merchant_names
	if names.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("UI_MERCHANT_DIALOGUE_NONE")
		empty_label.modulate = HINT_COLOR
		_list_body.add_child(empty_label)
		return

	for merchant_name in names:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var name_label := Label.new()
		# tr() sıradan bir tüccar ismini (CSV'de tanımlı değil) olduğu gibi
		# bırakır - yalnızca loncanın özel vagon görevlerinin gerçek
		# anahtarını çözer (bkz. caravan_planner.gd'nin aynı satırı).
		name_label.text = tr(merchant_name)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		if _session.is_merchant_known(merchant_name):
			var known_label := Label.new()
			var disposition_label := _session.get_merchant_disposition_label(merchant_name)
			known_label.text = disposition_label if not disposition_label.is_empty() else tr("UI_MERCHANT_DIALOGUE_UNREADABLE")
			known_label.modulate = OK_COLOR if not disposition_label.is_empty() else HINT_COLOR
			row.add_child(known_label)

		var talk_button := Button.new()
		talk_button.text = tr("UI_MERCHANT_DIALOGUE_TALK")
		talk_button.pressed.connect(_on_talk_pressed.bind(merchant_name))
		row.add_child(talk_button)

		_list_body.add_child(row)

func _on_talk_pressed(merchant_name: String) -> void:
	_selected_merchant = merchant_name
	_refresh()

## Detay görünümüne her girişte mizaç yeniden sorulmaz - bir kez bilinen
## bir mizaç sefer boyunca bilinir (bkz. GameSession.is_merchant_known).
func _refresh_detail() -> void:
	for child in _detail_body.get_children():
		_detail_body.remove_child(child)
		child.queue_free()

	var name_label := Label.new()
	name_label.text = _selected_merchant
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = ArtPalette.GOLD
	_detail_body.add_child(name_label)

	if not _session.is_merchant_known(_selected_merchant):
		_ask_permission()

	if _session.is_merchant_known(_selected_merchant):
		_show_result()
	else:
		_show_refused_choices()

	var back_button := Button.new()
	back_button.text = tr("UI_MERCHANT_DIALOGUE_BACK")
	back_button.pressed.connect(_on_back_pressed)
	_detail_body.add_child(back_button)

func _ask_permission() -> void:
	if _session.merchant_grants_permission(_selected_merchant):
		_session.grant_merchant_look(_selected_merchant)

func _show_result() -> void:
	var disposition_label := _session.get_merchant_disposition_label(_selected_merchant)
	var result_label := Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if disposition_label.is_empty():
		result_label.text = tr("UI_MERCHANT_DIALOGUE_VAGUE")
		result_label.modulate = HINT_COLOR
	else:
		result_label.text = tr("UI_MERCHANT_DIALOGUE_RESULT") % disposition_label
		result_label.modulate = OK_COLOR
	_detail_body.add_child(result_label)

	_detail_body.add_child(HSeparator.new())
	_show_cargo()

## #22'nin orijinal tasarım notunun istediği "gerçek envanter" - mizacın
## ötesinde, vagonun içinde ne olduğunu gösteren salt-okunur bir liste
## (bkz. GameSession.get_merchant_cargo_entries). Hiçbir satır tıklanabilir
## değil, hiçbir "al/sat" düğmesi yok - #22'nin kendi garantisi ("yazma
## yolu hiç yok, ekonomiye sızma riski yok") burada da geçerli.
func _show_cargo() -> void:
	var cargo_title := Label.new()
	cargo_title.text = tr("UI_MERCHANT_DIALOGUE_CARGO_TITLE")
	cargo_title.modulate = ArtPalette.GOLD
	_detail_body.add_child(cargo_title)

	var entries := _session.get_merchant_cargo_entries(_selected_merchant)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("UI_MERCHANT_DIALOGUE_CARGO_EMPTY")
		empty_label.modulate = HINT_COLOR
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_detail_body.add_child(empty_label)
		return

	for entry in entries:
		var item: Item = entry.item
		var item_label := Label.new()
		item_label.text = tr("UI_STATUS_CARGO_ITEM") % [item.item_name, int(entry.quantity)]
		item_label.modulate = HINT_COLOR
		_detail_body.add_child(item_label)

func _show_refused_choices() -> void:
	var refused_label := Label.new()
	refused_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	refused_label.text = tr("UI_MERCHANT_DIALOGUE_REFUSED")
	refused_label.modulate = REFUSED_COLOR
	_detail_body.add_child(refused_label)

	var force_button := Button.new()
	force_button.text = tr("UI_MERCHANT_DIALOGUE_FORCE") % GameSession.FORCE_LOOK_MERCHANT_REPUTATION_PENALTY
	force_button.pressed.connect(_on_force_pressed)
	_detail_body.add_child(force_button)

	var persuade_button := Button.new()
	persuade_button.text = tr("UI_MERCHANT_DIALOGUE_PERSUADE")
	persuade_button.pressed.connect(_on_persuade_pressed)
	_detail_body.add_child(persuade_button)

func _on_force_pressed() -> void:
	_session.force_look_merchant_wagon(_selected_merchant)
	_refresh()

func _on_persuade_pressed() -> void:
	if _session.attempt_merchant_persuasion(_rng):
		_session.grant_merchant_look(_selected_merchant)
	_refresh()

func _on_back_pressed() -> void:
	_selected_merchant = ""
	_refresh()

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
