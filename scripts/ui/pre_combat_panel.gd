class_name PreCombatPanel
extends CanvasLayer

## Savaş artık kimin katılacağını ve hangi sırayla dizileceğini soruyor -
## eskiden `_open_combat()` oturumun tüm partisini olduğu gibi savaşa
## sürüyordu, oyuncunun hiç seçimi yoktu. Artık kalıcı ölüm herkesi
## bulabildiği için (bkz. CombatUnit.can_enter_deaths_door) kimi bu
## çarpışmaya sokacağın gerçek bir bahis - biri yaralıyken ya da
## kırılmışken onu bu sefer geride tutmak isteyebilirsin.
##
## Sıra burada seçilen sıra **bu savaşa özel**: `party.tscn`'deki genel
## parti sırası (marş/varsayılan mevki sırası) değişmiyor, yalnızca bu
## çarpışmanın mevki dizilişi. `SuccessionPanel`in sahnesiz deseni.

signal confirmed(ordered)  # Array[CharacterData]

const BACKDROP_COLOR: Color = Color(0.0, 0.0, 0.0, 0.75)
const PANEL_BACKGROUND: Color = Color(0.09, 0.08, 0.07)
const PANEL_BORDER: Color = Color(0.55, 0.45, 0.28)
const PANEL_WIDTH: float = 480.0

var _order: Array[CharacterData] = []
var _included: Dictionary = {}  # CharacterData -> bool
var _rows_container: VBoxContainer
var _confirm_button: Button

func setup(party: Array[CharacterData]) -> void:
	_order = party.duplicate()
	for character in _order:
		_included[character] = true

	layer = 66

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
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = tr("UI_PRECOMBAT_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = ArtPalette.GOLD
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = tr("UI_PRECOMBAT_HINT")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hint)

	vbox.add_child(HSeparator.new())

	_rows_container = VBoxContainer.new()
	_rows_container.add_theme_constant_override("separation", 4)
	vbox.add_child(_rows_container)

	vbox.add_child(HSeparator.new())

	_confirm_button = Button.new()
	_confirm_button.text = tr("UI_PRECOMBAT_CONFIRM")
	_confirm_button.pressed.connect(_on_confirm_pressed)
	vbox.add_child(_confirm_button)

	_refresh_rows()

## Her satır: yukarı/aşağı ile bu savaşa özel mevki sırası, kutu ile
## katılıp katılmayacağı. En az bir kişi katılmalı - hepsi çıkarsa
## "Onayla" kilitlenir, boş bir savaş açılamaz.
func _refresh_rows() -> void:
	for child in _rows_container.get_children():
		_rows_container.remove_child(child)
		child.queue_free()

	var included_count := 0
	for index in _order.size():
		var character := _order[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var up_button := Button.new()
		up_button.text = "^"
		up_button.disabled = index == 0
		up_button.pressed.connect(_move_row.bind(index, -1))
		row.add_child(up_button)

		var down_button := Button.new()
		down_button.text = "v"
		down_button.disabled = index == _order.size() - 1
		down_button.pressed.connect(_move_row.bind(index, 1))
		row.add_child(down_button)

		var check := CheckBox.new()
		check.text = character.character_name
		check.button_pressed = bool(_included.get(character, true))
		if check.button_pressed:
			included_count += 1
		check.toggled.connect(_on_include_toggled.bind(character))
		row.add_child(check)

		if character.is_stressed():
			var flag := Label.new()
			flag.text = tr("UI_PRECOMBAT_STRESSED")
			flag.modulate = Color(0.78, 0.62, 0.35)
			row.add_child(flag)

		_rows_container.add_child(row)

	_confirm_button.disabled = included_count <= 0

func _move_row(index: int, direction: int) -> void:
	var target := index + direction
	if target < 0 or target >= _order.size():
		return
	var moved := _order[index]
	_order.remove_at(index)
	_order.insert(target, moved)
	_refresh_rows()

func _on_include_toggled(pressed: bool, character: CharacterData) -> void:
	_included[character] = pressed
	_refresh_rows()

func _on_confirm_pressed() -> void:
	var chosen: Array[CharacterData] = []
	for character in _order:
		if _included.get(character, true):
			chosen.append(character)
	confirmed.emit(chosen)
	queue_free()
