class_name PurificationPanel
extends VBoxContainer

## "Huy Arındır" bölümü: taze (bkz. CharacterData.is_trait_fresh) huyları
## ücret karşılığı siler. Taverna ve Kilise aynı paneli farklı ücretle
## kurar (bkz. RecruitPanel deseni) - arındırma tek bir sistem, iki mekân
## yalnızca fiyatla ayrışıyor.
##
## Panel kendini kodda kurar (bkz. HagglingPanel/CombatPanel/RecruitPanel
## deseni), bu yüzden ekranların .tscn dosyalarına düğüm eklemeye gerek yok.

signal trait_removed()

const HINT_COLOR: Color = Color(0.7, 0.72, 0.78)
const POSITIVE_COLOR: Color = Color(0.6, 0.85, 0.6)
const NEGATIVE_COLOR: Color = Color(0.9, 0.6, 0.55)
const LOCKED_COLOR: Color = Color(0.65, 0.6, 0.55)

var _session: GameSession
var _cost: int = 0

var _title_label: Label
var _info_label: Label
var _list: VBoxContainer
var _built: bool = false

func setup(session: GameSession, title: String, cost: int) -> void:
	_ensure_built()
	_session = session
	_cost = cost
	_title_label.text = title
	refresh()

func refresh() -> void:
	if _session == null:
		return
	_clear_children(_list)

	var any_fresh := false
	for character in _session.get_party():
		for trait_resource in character.get_traits():
			if not character.is_trait_fresh(trait_resource.trait_id, _session.total_days_elapsed):
				continue
			any_fresh = true
			_list.add_child(_build_row(character, trait_resource))

	_info_label.text = "Arındırma ücreti: %d GG. Yalnızca son %d gün içinde kazanılan huylar silinebilir." % [
		_cost, CharacterData.TRAIT_FRESH_WINDOW_DAYS
	]
	if not any_fresh:
		var empty_label := Label.new()
		empty_label.text = "Şu an arındırılabilecek taze bir huy yok."
		empty_label.modulate = HINT_COLOR
		_list.add_child(empty_label)

func _build_row(character: CharacterData, trait_resource: Trait) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "%s — %s" % [character.character_name, trait_resource.display_name]
	label.tooltip_text = trait_resource.description
	label.modulate = POSITIVE_COLOR if trait_resource.is_positive else NEGATIVE_COLOR
	label.custom_minimum_size = Vector2(320, 0)
	row.add_child(label)

	var button := Button.new()
	if _session.wallet.can_afford(_cost):
		button.text = "Arındır (%d GG)" % _cost
		button.pressed.connect(_on_purify_pressed.bind(character, trait_resource.trait_id))
	else:
		button.text = "Kese yetmiyor"
		button.disabled = true
		button.modulate = LOCKED_COLOR
	row.add_child(button)

	return row

func _on_purify_pressed(character: CharacterData, trait_id: String) -> void:
	if not _session.wallet.can_afford(_cost):
		return
	_session.wallet.spend(_cost)
	character.remove_trait(trait_id)
	refresh()
	trait_removed.emit()

func _ensure_built() -> void:
	if _built:
		return
	_built = true

	add_theme_constant_override("separation", 6)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 18)
	add_child(_title_label)

	_info_label = Label.new()
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_label.modulate = HINT_COLOR
	add_child(_info_label)

	_list = VBoxContainer.new()
	add_child(_list)

func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
