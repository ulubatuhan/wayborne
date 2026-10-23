class_name PurificationPanel
extends VBoxContainer

## tr("UI_PURIFY_TRAIT") bölümü: taze (bkz. CharacterData.is_trait_fresh) huyları
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

var _session: GameSession
var _cost: int = 0

var _title_label: Label
var _info_label: Label
var _list: VBoxContainer
var _built: bool = false
## Lanet çözme (görev Y-C06) yalnız kilisede: taverna arındırır ama bağ koparamaz.
var _curse_enabled: bool = false
var _curse_list: VBoxContainer

func setup(session: GameSession, title: String, cost: int) -> void:
	_ensure_built()
	_session = session
	_cost = cost
	_title_label.text = title
	refresh()
	# Kendi perdesi yok - salt gövde, Taverna/Kilise'nin sekmesine gömülü.
	WaybookTheme.present(self, null, self)

func enable_curse_lifting() -> void:
	_ensure_built()
	_curse_enabled = true
	refresh()

func refresh() -> void:
	if _session == null:
		return
	NodeUtil.clear_children(_list)
	_refresh_curses()

	var any_fresh := false
	for character in _session.get_party():
		for trait_resource in character.get_traits():
			if not character.is_trait_fresh(trait_resource.trait_id, _session.total_days_elapsed):
				continue
			any_fresh = true
			_list.add_child(_build_row(character, trait_resource))

	_info_label.text = tr("UI_PURIFY_HINT") % [
		_cost, CharacterData.TRAIT_FRESH_WINDOW_DAYS
	]
	if not any_fresh:
		var empty_label := Label.new()
		empty_label.text = tr("UI_PURIFY_NONE")
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
		button.text = tr("UI_PURIFY_ACTION") % _cost
		button.pressed.connect(_on_purify_pressed.bind(character, trait_resource.trait_id))
	else:
		# `modulate` düğmenin dokusunu ve yazısını birlikte karartıp sebebi
		# okunaksız kılıyordu; `disabled = true` temanın kendi ölçülmüş
		# kontrastını zaten sağlıyor.
		button.text = tr("UI_NOT_ENOUGH_GOLD")
		button.disabled = true
	row.add_child(button)

	return row

func _on_purify_pressed(character: CharacterData, trait_id: String) -> void:
	if not _session.wallet.can_afford(_cost):
		return
	_session.wallet.spend(_cost)
	character.remove_trait(trait_id)
	refresh()
	trait_removed.emit()

func _refresh_curses() -> void:
	NodeUtil.clear_children(_curse_list)
	_curse_list.visible = _curse_enabled
	if not _curse_enabled:
		return
	var heading := Label.new()
	heading.text = tr("UI_CHURCH_CURSE_HEADING")
	heading.add_theme_font_size_override("font_size", 18)
	_curse_list.add_child(heading)
	var any := false
	for character in _session.get_party():
		for slot in EquipmentCatalog.ALL_SLOTS:
			if not character.is_slot_cursed(slot):
				continue
			any = true
			var piece := character.get_equipped(slot)
			var button := Button.new()
			button.text = tr("UI_CHURCH_CURSE_LIFT") % [character.character_name, piece.display_name,
				GameSession.CURSE_LIFT_PRICE]
			button.tooltip_text = piece.description
			if _session.wallet.can_afford(GameSession.CURSE_LIFT_PRICE):
				button.pressed.connect(_on_lift_pressed.bind(character, slot))
			else:
				button.disabled = true
				button.tooltip_text = tr("UI_CHURCH_CURSE_NO_GOLD")
			_curse_list.add_child(button)
	if not any:
		var empty_label := Label.new()
		empty_label.text = tr("UI_CHURCH_CURSE_NONE")
		empty_label.modulate = HINT_COLOR
		_curse_list.add_child(empty_label)

func _on_lift_pressed(character: CharacterData, slot: String) -> void:
	if _session.lift_curse(character, slot):
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

	_curse_list = VBoxContainer.new()
	_curse_list.add_theme_constant_override("separation", 6)
	_curse_list.visible = false
	add_child(_curse_list)
